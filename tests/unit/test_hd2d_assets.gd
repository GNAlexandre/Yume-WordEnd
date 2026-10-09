extends GutTest
## (HD-2D) Images du monde (docs/ASSETS_HD2D.md, docs/ASSETS_HD2D_MONDE.md,
## tools/hd2d_manifest.json) : chaque image du manifeste existe à sa taille exacte (une bande
## animée : frames × la largeur d'une image), les panneaux, façades, flancs et bandes ont un alpha
## net (sauf « alpha doux ») et touchent le bord bas (ancre au sol) ou restent centrés (sprites qui
## volent), les décalques ne sont coupés par aucun bord, les flancs ont la forme de leur toit, les
## tuiles sont opaques, les bordures et les tuiles _b se raccordent, l'atlas du sol (27 tuiles) est
## à jour, les deux cahiers nomment chaque image, et le poids des images tient dans le budget de
## l'export Web. tools/hd2d_assets.py check fait les mêmes vérifications, plus finement.

const MANIFEST := "res://tools/hd2d_manifest.json"
## (E3) Les intérieurs (lot I) : conventions de docs/REFONTE.md (section 8.1), liste et tailles de
## docs/INTERIEURS.md, en attendant le cahier n° 3.
const DOCS: Array[String] = [
	"res://docs/ASSETS_HD2D.md",
	"res://docs/ASSETS_HD2D_MONDE.md",
	"res://docs/REFONTE.md",
	"res://docs/INTERIEURS.md",
]
const CAHIER2_LOTS: Array[String] = ["A", "B", "C", "D", "E", "F", "G"]
const ATLAS := "res://assets/hd2d/ground/atlas/ground_atlas.png"
## Ordre des tuiles dans l'atlas (GROUND_LAYERS de tools/hd2d_assets.py, terrain.gdshader) : les
## 12 du cahier n° 1, puis les 15 du cahier n° 2.
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
	"metal",
	"grass_b",
	"forest_floor_b",
	"path_dirt_b",
	"leaf_litter",
	"moss",
	"grass_dry_b",
	"flagstone_b",
	"cobble_b",
	"meadow_flowers",
	"gravel",
	"garden_soil",
	"sand_b",
	"rock_b",
	"planks",
	"stream_bed"
]
const ATLAS_COLUMNS := 4
const TILE := 384
## Budget des images HD-2D (PNG sources, Mo) : l'export Web vise 100 Mo compressés en tout.
## (H1) Images livrées (PR n° 2 à 4) : 15 Mo de PNG, que l'import réduit à 40 % environ (WebP
## sans perte : aucune perte de qualité) ; le cahier n° 2 (docs/ASSETS_HD2D_MONDE.md) en ajoute
## 40 à 45 Mo (H10 : 15 Mo de remplaçants). Toutes ses images livrées : 74,8 Mo de PNG, export
## Web de 73,5 Mo compressés. tools/check.sh mesure l'export lui-même (tools/build_size.sh).
const IMAGES_BUDGET_MB := 100.0
## Part d'un bord au-delà de laquelle une silhouette y est coupée net (tools/hd2d_assets.py,
## CUT_COVER).
const CUT_COVER := 0.12
## Raccord : écart moyen des bords opposés rapporté au plus grand écart entre deux colonnes
## voisines de l'intérieur (échantillonnées) ; plus large que SEAM_LIMIT de hd2d_assets.py, qui
## mesure toutes les colonnes.
const SEAM_LIMIT := 2.0
const STANDING_KINDS: Array[String] = ["panel", "facade", "side", "anim"]

var _manifest: Dictionary = {}
var _by_path: Dictionary = {}


func before_all() -> void:
	var json := JSON.new()
	assert_eq(json.parse(FileAccess.get_file_as_string(MANIFEST)), OK, "manifeste lisible")
	_manifest = json.data if json.data is Dictionary else {}
	for entry: Dictionary in _entries():
		_by_path[String(entry["path"])] = entry


func _image(res_path: String) -> Image:
	return Image.load_from_file(ProjectSettings.globalize_path(res_path))


func _entries() -> Array:
	return _manifest.get("images", [])


func _frames(entry: Dictionary) -> int:
	return int(entry.get("frames", 1))


func _frame_size(entry: Dictionary) -> Vector2i:
	return Vector2i(int(entry["size"][0]), int(entry["size"][1]))


## Image RGBA8 d'une entrée, ou null si elle manque ou n'a pas sa taille.
func _loaded(entry: Dictionary) -> Image:
	var image := _image("res://" + String(entry["path"]))
	if image == null:
		return null
	var size := _frame_size(entry)
	if image.get_size() != Vector2i(size.x * _frames(entry), size.y):
		return null
	image.convert(Image.FORMAT_RGBA8)
	return image


func test_manifest_lists_every_category() -> void:
	assert_eq(int(_manifest.get("px_per_m", 0)), 96, "96 px par mètre")
	var folders := {}
	var lots := {}
	for entry: Dictionary in _entries():
		folders[String(entry["path"]).split("/")[2]] = true
		if entry.has("lot"):
			lots[String(entry["lot"])] = true
	for folder: String in [
		"ground", "cliff", "buildings", "props", "sky", "fx", "decals", "anim", "interior"
	]:
		assert_true(folders.has(folder), "catégorie %s" % folder)
	for lot: String in CAHIER2_LOTS:
		assert_true(lots.has(lot), "lot %s du cahier n° 2" % lot)
	assert_true(lots.has("I"), "lot I (intérieurs, cahier n° 3)")
	assert_gt(_entries().size(), 390, "les images des deux cahiers")


func test_every_image_exists_at_its_exact_size() -> void:
	var problems: Array[String] = []
	for entry: Dictionary in _entries():
		var path := "res://" + String(entry["path"])
		var image := _image(path)
		if image == null:
			problems.append("%s absente" % path)
			continue
		var size := _frame_size(entry)
		var want := Vector2i(size.x * _frames(entry), size.y)
		if image.get_size() != want:
			problems.append("%s : %s au lieu de %s" % [path, image.get_size(), want])
		if String(entry["kind"]) == "anim":
			if _frames(entry) < 2 or float(entry.get("fps", 0)) <= 0.0:
				problems.append("%s : bande sans frames ni fps" % path)
	assert_true(problems.is_empty(), "; ".join(problems))


## Part de la ligne de pixels extérieure d'un bord (« left », « right », « top », « bottom »)
## couverte par la silhouette (alpha ≥ 128).
func _edge_cover(image: Image, side: String) -> float:
	var horizontal := side in ["top", "bottom"]
	var count := image.get_width() if horizontal else image.get_height()
	var covered := 0
	for i in count:
		var at := Vector2i(i, 0)
		match side:
			"bottom":
				at = Vector2i(i, image.get_height() - 1)
			"left":
				at = Vector2i(0, i)
			"right":
				at = Vector2i(image.get_width() - 1, i)
		if image.get_pixelv(at).a >= 0.5:
			covered += 1
	return float(covered) / maxf(1.0, count)


## Bord où la silhouette est coupée net : plus de CUT_COVER de sa ligne extérieure couverte (une
## image cadrée au plus juste le touche sur quelques pixels, ce qui ne se voit pas).
func _cut(image: Image, side: String) -> bool:
	return _edge_cover(image, side) > CUT_COVER


## Problèmes d'ancrage d'une image debout (ou d'une image d'une bande) : collée au bord bas, ou
## centrée sans être coupée par un bord (sprites qui volent) ; un lointain qui flotte (anchor
## free : île, rai de lumière) n'a pas d'ancre.
func _standing_problems(image: Image, entry: Dictionary, label: String) -> Array[String]:
	var problems: Array[String] = []
	var used := image.get_used_rect()
	if used.size == Vector2i.ZERO:
		problems.append("%s : image vide" % label)
		return problems
	var wrap_axis := String(entry.get("wrap", ""))
	if String(entry.get("anchor", "")) == "free":
		return problems
	if String(entry.get("anchor", "")) == "center":
		var touches_x := _cut(image, "left") or _cut(image, "right")
		var touches_y := _cut(image, "top") or _cut(image, "bottom")
		if (touches_x and wrap_axis != "x") or (touches_y and wrap_axis != "y"):
			problems.append("%s : sprite centré coupé par un bord" % label)
		var offset := Vector2(used.get_center()) - Vector2(image.get_size()) / 2.0
		if wrap_axis != "x" and absf(offset.x) > 0.2 * image.get_width():
			problems.append("%s : pas centré" % label)
		if wrap_axis != "y" and absf(offset.y) > 0.2 * image.get_height():
			problems.append("%s : pas centré" % label)
		return problems
	if used.end.y != image.get_height():
		problems.append("%s : ne touche pas le bord bas" % label)
	var kind := String(entry["kind"])
	if kind in ["facade", "side"] and (used.position.x > 0 or used.end.x < image.get_width()):
		problems.append("%s : mur qui ne touche pas les bords" % label)
	return problems


func test_panels_have_hard_alpha_and_stand_on_their_bottom_edge() -> void:
	var problems: Array[String] = []
	for entry: Dictionary in _entries():
		var kind := String(entry["kind"])
		var path := "res://" + String(entry["path"])
		var image := _loaded(entry)
		if image == null:
			continue
		if kind in ["tile", "tile_h", "panorama"]:
			if image.detect_alpha() != Image.ALPHA_NONE:
				problems.append("%s : doit être opaque" % path)
			continue
		if not kind in STANDING_KINDS and kind != "decal":
			continue
		if not entry.get("soft_alpha", false) and image.detect_alpha() == Image.ALPHA_BLEND:
			problems.append("%s : alpha flou (0 ou 255 seulement)" % path)
		if kind == "decal":
			continue
		var size := _frame_size(entry)
		for i in _frames(entry):
			var frame := image.get_region(Rect2i(i * size.x, 0, size.x, size.y))
			problems.append_array(_standing_problems(frame, entry, "%s (image %d)" % [path, i + 1]))
	assert_true(problems.is_empty(), "; ".join(problems))


func test_decals_fade_into_the_ground_away_from_their_edges() -> void:
	var problems: Array[String] = []
	var count := 0
	for entry: Dictionary in _entries():
		if String(entry["kind"]) != "decal":
			continue
		if String(entry.get("lot", "")) in CAHIER2_LOTS:
			count += 1
		var path := "res://" + String(entry["path"])
		var image := _loaded(entry)
		if image == null:
			continue
		var used := image.get_used_rect()
		var wrap_axis := String(entry.get("wrap", ""))
		var solid := String(entry.get("solid_edge", ""))
		var cut: Array[String] = []
		if _cut(image, "left") and wrap_axis != "x":
			cut.append("gauche")
		if _cut(image, "right") and wrap_axis != "x":
			cut.append("droit")
		if _cut(image, "top") and wrap_axis != "y" and solid != "top":
			cut.append("haut")
		if _cut(image, "bottom") and wrap_axis != "y":
			cut.append("bas")
		if not cut.is_empty():
			problems.append("%s : coupé par le bord %s" % [path, ", ".join(cut)])
		if wrap_axis.is_empty() and solid.is_empty():
			# Bord irrégulier : la silhouette ne remplit pas sa boîte (pas un rectangle plein).
			var filled := 0
			var samples := 0
			for y in range(used.position.y, used.end.y, 3):
				for x in range(used.position.x, used.end.x, 3):
					samples += 1
					if image.get_pixel(x, y).a > 0.5:
						filled += 1
			if samples > 0 and filled > 0.95 * samples:
				problems.append("%s : rectangle plein" % path)
	assert_eq(count, 45, "45 décalques (cahier n° 2, section 5)")
	assert_true(problems.is_empty(), "; ".join(problems))


func test_building_sides_have_the_shape_of_their_roof() -> void:
	var problems: Array[String] = []
	var count := 0
	for entry: Dictionary in _entries():
		if String(entry["kind"]) != "side":
			continue
		count += 1
		var path := "res://" + String(entry["path"])
		var image := _loaded(entry)
		if image == null:
			continue
		var w := image.get_width()
		var h := image.get_height()
		if String(entry.get("roof", "")) == "gable":
			var wall := roundi(float(entry["wall_m"]) * 96.0)
			if image.get_pixel(0, 0).a > 0.5 or image.get_pixel(w - 1, 0).a > 0.5:
				problems.append("%s : pignon aux coins du haut pleins" % path)
			# Le faîtage touche le haut de l'image quelque part dans son tiers central (un épi de
			# faîtage ou une pointe un peu décentrée suffit, comme tools/hd2d_assets.py).
			var apex := image.get_region(Rect2i(floori(w / 3.0), 0, w - 2 * floori(w / 3.0), 2))
			if apex.get_used_rect().size == Vector2i.ZERO:
				problems.append("%s : pignon qui n'atteint pas le faîtage" % path)
			var y := h - floori(wall / 2.0)
			if image.get_pixel(0, y).a < 0.5 or image.get_pixel(w - 1, y).a < 0.5:
				problems.append("%s : mur du pignon pas plein" % path)
		else:
			for y: int in [floori(h / 4.0), floori(h / 2.0), h - 2]:
				if image.get_pixel(0, y).a < 0.5 or image.get_pixel(w - 1, y).a < 0.5:
					problems.append("%s : mur gouttereau pas plein" % path)
	assert_eq(count, 19, "19 flancs (cahier n° 2, 9.1 et 9.2)")
	assert_true(problems.is_empty(), "; ".join(problems))


## Couleur d'un pixel posée sur un gris moyen (l'alpha compte dans les écarts).
func _flat(image: Image, x: int, y: int) -> Color:
	var c := image.get_pixel(x, y)
	return Color(0.5, 0.5, 0.5).lerp(Color(c.r, c.g, c.b), c.a)


## Écart moyen (0..255) entre la colonne xa de a et la colonne xb de b (rangées si axis = "y").
func _line_diff(a: Image, xa: int, b: Image, xb: int, axis: String) -> float:
	var length := a.get_height() if axis == "x" else a.get_width()
	var total := 0.0
	var n := 0
	for t in range(0, length, 2):
		var ca := _flat(a, xa, t) if axis == "x" else _flat(a, t, xa)
		var cb := _flat(b, xb, t) if axis == "x" else _flat(b, t, xb)
		total += (absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b)) / 3.0
		n += 1
	return 255.0 * total / maxf(1.0, n)


## Raccord bord à bord de a puis b (et b puis a), rapporté aux écarts intérieurs échantillonnés.
func _seam_score(a: Image, b: Image, axis: String) -> float:
	var size := a.get_width() if axis == "x" else a.get_height()
	var step := maxi(1, floori(size / 48.0))
	var inner := 4.0
	for x in range(0, size - 1, step):
		inner = maxf(inner, _line_diff(a, x, a, x + 1, axis))
		inner = maxf(inner, _line_diff(b, x, b, x + 1, axis))
	var seam := maxf(_line_diff(a, size - 1, b, 0, axis), _line_diff(b, size - 1, a, 0, axis))
	return seam / inner


func test_borders_and_variant_tiles_join_seamlessly() -> void:
	var problems: Array[String] = []
	var checked := 0
	for entry: Dictionary in _entries():
		var wrap_axis := String(entry.get("wrap", ""))
		var other := String(entry.get("variant_of", entry.get("pairs_with", "")))
		if wrap_axis.is_empty() and other.is_empty():
			continue
		var path := "res://" + String(entry["path"])
		var image := _loaded(entry)
		if image == null:
			continue
		if String(entry["kind"]) == "anim":
			image = image.get_region(Rect2i(Vector2i.ZERO, _frame_size(entry)))
		checked += 1
		if not wrap_axis.is_empty() and _seam_score(image, image, wrap_axis) > SEAM_LIMIT:
			problems.append("%s : raccord %s visible" % [path, wrap_axis])
		# L'image d'origine est dans le même dossier (ground/rock, pas props/rock).
		var other_path := "%s/%s.png" % [String(entry["path"]).get_base_dir(), other]
		if other.is_empty() or not _by_path.has(other_path):
			continue
		var origin := _loaded(_by_path[other_path])
		if origin == null or origin.get_size() != image.get_size():
			problems.append("%s : %s absente ou d'une autre taille" % [path, other])
			continue
		var axes: Array[String] = ["x"]
		if String(entry["kind"]) == "tile":
			axes.append("y")
		for axis: String in axes:
			if _seam_score(origin, image, axis) > SEAM_LIMIT:
				problems.append("%s : raccord %s avec %s visible" % [path, axis, other])
	assert_gt(checked, 20, "bordures, lisières et tuiles _b vérifiées")
	assert_true(problems.is_empty(), "; ".join(problems))


func test_ground_atlas_is_up_to_date() -> void:
	var atlas := _image(ATLAS)
	assert_not_null(atlas, "atlas du sol")
	if atlas == null:
		return
	atlas.convert(Image.FORMAT_RGBA8)
	var rows := ceili(float(GROUND_LAYERS.size()) / ATLAS_COLUMNS)
	assert_eq(rows, 7, "27 tuiles : 7 rangées de 4")
	assert_eq(atlas.get_size(), Vector2i(ATLAS_COLUMNS * TILE, rows * TILE))
	for i in GROUND_LAYERS.size():
		var tile := _image("res://assets/hd2d/ground/%s.png" % GROUND_LAYERS[i])
		assert_not_null(tile, GROUND_LAYERS[i])
		if tile == null:
			continue
		tile.convert(Image.FORMAT_RGBA8)
		var cell := atlas.get_region(
			Rect2i((i % ATLAS_COLUMNS) * TILE, floori(float(i) / ATLAS_COLUMNS) * TILE, TILE, TILE)
		)
		# Comparaison directe : assert_eq mettrait en forme deux tableaux de 590 Ko (lent).
		assert_true(
			cell.get_data() == tile.get_data(),
			"%s à jour dans l'atlas (python3 tools/hd2d_assets.py atlas)" % GROUND_LAYERS[i]
		)


func test_specification_names_every_image() -> void:
	var doc := ""
	for path: String in DOCS:
		var text := FileAccess.get_file_as_string(path)
		assert_false(text.is_empty(), path)
		doc += text + "\n"
	var missing: Array[String] = []
	for entry: Dictionary in _entries():
		var image_name := String(entry["path"]).get_file().get_basename()
		var size := "%d × %d" % [int(entry["size"][0]), int(entry["size"][1])]
		if not doc.contains("`%s" % image_name):
			missing.append(image_name)
		elif String(entry["kind"]) in STANDING_KINDS + ["decal"] and not doc.contains(size):
			missing.append("%s (%s)" % [image_name, size])
	assert_true(missing.is_empty(), "absentes des cahiers des charges : %s" % ", ".join(missing))


func test_images_fit_the_web_budget() -> void:
	var total := 0
	for entry: Dictionary in _entries():
		var file := FileAccess.open("res://" + String(entry["path"]), FileAccess.READ)
		if file != null:
			total += file.get_length()
	var megabytes := total / 1048576.0
	assert_lt(megabytes, IMAGES_BUDGET_MB, "images HD-2D : %.1f Mo" % megabytes)
	assert_false(DirAccess.dir_exists_absolute("res://assets/models"), "plus de modèles 3D")
