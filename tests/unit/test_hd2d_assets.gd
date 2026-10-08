extends GutTest
## (HD-2D) Images du monde (docs/ASSETS_HD2D.md, tools/hd2d_manifest.json) : chaque image du
## manifeste existe à sa taille exacte, les panneaux et façades ont un alpha net et touchent le
## bord bas (ancre au sol), les tuiles sont opaques, l'atlas du sol est à jour, le cahier des
## charges nomme chaque image, et le poids des images tient dans le budget de l'export Web.

const MANIFEST := "res://tools/hd2d_manifest.json"
const DOC := "res://docs/ASSETS_HD2D.md"
const ATLAS := "res://assets/hd2d/ground/atlas/ground_atlas.png"
## Ordre des tuiles dans l'atlas (GROUND_LAYERS de tools/hd2d_assets.py, terrain.gdshader).
const GROUND_LAYERS: Array[String] = [
	"grass",
	"grass_dry",
	"forest_floor",
	"path_dirt",
	"flagstone",
	"cobble",
	"sand",
	"rock",
	"peat",
	"water",
	"mud",
	"metal"
]
const ATLAS_COLUMNS := 4
const TILE := 384
## Budget des images HD-2D (PNG sources, Mo) : l'export Web vise 25 Mo compressés en tout.
## (H1) Images livrées (PR n° 2 et 3) : 15 Mo de PNG, que l'import réduit à 40 % environ (WebP
## sans perte) ; tools/check.sh mesure l'export lui-même (tools/build_size.sh).
const IMAGES_BUDGET_MB := 16.0

var _manifest: Dictionary = {}


func before_all() -> void:
	var json := JSON.new()
	assert_eq(json.parse(FileAccess.get_file_as_string(MANIFEST)), OK, "manifeste lisible")
	_manifest = json.data if json.data is Dictionary else {}


func _image(res_path: String) -> Image:
	return Image.load_from_file(ProjectSettings.globalize_path(res_path))


func _entries() -> Array:
	return _manifest.get("images", [])


func test_manifest_lists_every_category() -> void:
	assert_eq(int(_manifest.get("px_per_m", 0)), 96, "96 px par mètre")
	var folders := {}
	for entry: Dictionary in _entries():
		folders[String(entry["path"]).split("/")[2]] = true
	for folder: String in ["ground", "cliff", "buildings", "props", "sky", "fx"]:
		assert_true(folders.has(folder), "catégorie %s" % folder)
	assert_gt(_entries().size(), 90, "toutes les images de l'acte 1")


func test_every_image_exists_at_its_exact_size() -> void:
	var problems: Array[String] = []
	for entry: Dictionary in _entries():
		var path := "res://" + String(entry["path"])
		var image := _image(path)
		if image == null:
			problems.append("%s absente" % path)
			continue
		var want := Vector2i(int(entry["size"][0]), int(entry["size"][1]))
		if image.get_size() != want:
			problems.append("%s : %s au lieu de %s" % [path, image.get_size(), want])
	assert_true(problems.is_empty(), "; ".join(problems))


func test_panels_have_hard_alpha_and_stand_on_their_bottom_edge() -> void:
	var problems: Array[String] = []
	for entry: Dictionary in _entries():
		var kind := String(entry["kind"])
		var path := "res://" + String(entry["path"])
		var image := _image(path)
		if image == null:
			continue
		image.convert(Image.FORMAT_RGBA8)
		if kind in ["tile", "tile_h", "panorama"]:
			if image.detect_alpha() != Image.ALPHA_NONE:
				problems.append("%s : doit être opaque" % path)
			continue
		if not kind in ["panel", "facade"]:
			continue
		var used := image.get_used_rect()
		if used.end.y != image.get_height():
			problems.append("%s : ne touche pas le bord bas" % path)
		if kind == "facade" and (used.position.x > 0 or used.end.x < image.get_width()):
			problems.append("%s : façade qui ne touche pas les bords" % path)
		if image.detect_alpha() == Image.ALPHA_BLEND:
			problems.append("%s : alpha flou (0 ou 255 seulement)" % path)
	assert_true(problems.is_empty(), "; ".join(problems))


func test_ground_atlas_is_up_to_date() -> void:
	var atlas := _image(ATLAS)
	assert_not_null(atlas, "atlas du sol")
	if atlas == null:
		return
	atlas.convert(Image.FORMAT_RGBA8)
	var rows := ceili(float(GROUND_LAYERS.size()) / ATLAS_COLUMNS)
	assert_eq(atlas.get_size(), Vector2i(ATLAS_COLUMNS * TILE, rows * TILE))
	for i in GROUND_LAYERS.size():
		var tile := _image("res://assets/hd2d/ground/%s.png" % GROUND_LAYERS[i])
		tile.convert(Image.FORMAT_RGBA8)
		var cell := atlas.get_region(
			Rect2i((i % ATLAS_COLUMNS) * TILE, floori(float(i) / ATLAS_COLUMNS) * TILE, TILE, TILE)
		)
		assert_eq(
			cell.get_data(),
			tile.get_data(),
			"%s à jour dans l'atlas (python3 tools/hd2d_assets.py atlas)" % GROUND_LAYERS[i]
		)


func test_specification_names_every_image() -> void:
	var doc := FileAccess.get_file_as_string(DOC)
	assert_false(doc.is_empty(), "docs/ASSETS_HD2D.md")
	var missing: Array[String] = []
	for entry: Dictionary in _entries():
		var image_name := String(entry["path"]).get_file().get_basename()
		var size := "%d × %d" % [int(entry["size"][0]), int(entry["size"][1])]
		if not doc.contains("`%s" % image_name):
			missing.append(image_name)
		elif String(entry["kind"]) in ["panel", "facade"] and not doc.contains(size):
			missing.append("%s (%s)" % [image_name, size])
	assert_true(missing.is_empty(), "absentes du cahier des charges : %s" % ", ".join(missing))


func test_images_fit_the_web_budget() -> void:
	var total := 0
	for entry: Dictionary in _entries():
		var file := FileAccess.open("res://" + String(entry["path"]), FileAccess.READ)
		if file != null:
			total += file.get_length()
	var megabytes := total / 1048576.0
	assert_lt(megabytes, IMAGES_BUDGET_MB, "images HD-2D : %.1f Mo" % megabytes)
	assert_false(DirAccess.dir_exists_absolute("res://assets/models"), "plus de modèles 3D")
