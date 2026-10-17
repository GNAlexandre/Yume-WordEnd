extends GutTest
## (F0) Export Web allégé sans perte visible (docs/DECISIONS.md, F0 ; PLAN.md section 9) :
## - chaque image est importée « Lossless » (WebP sans perte), sans mipmaps : jamais de VRAM
##   compressée (floue, avec perte) ni de mipmaps sur le pixel art ;
## - les nouvelles images reçoivent ces réglages de project.godot ([importer_defaults], détection
##   3D coupée) et tools/import.sh ramène les .import plus anciens ;
## - l'encodeur WebP sans perte fait plus d'effort que celui par défaut de Godot (méthode 2,
##   facteur 25), et le WebP n'est pas remplacé par le PNG ;
## - les fichiers que le jeu ne lit jamais (tuiles du sol, sources de l'atlas ; plans des cartes,
##   sources de tools/exterior_maps.py) restent hors du paquet, et rien ne les cite en jeu.

## Dossiers dont les .import ne sont pas les nôtres (GUT) ou ne sont pas exportés.
const SKIPPED_DIRS: Array[String] = [
	"res://.godot", "res://.git", "res://.claude", "res://build", "res://addons"
]
## Réglages imposés à toute texture (clé du .import, valeur attendue).
const TEXTURE_PARAMS := {
	"compress/mode": 0,
	"mipmaps/generate": false,
}
## (F2) Les fonds peints et opaques du ciel (panoramas sky*, mers de nuages cloud_sea*) sont en
## WebP avec perte, à cette qualité ; tout le reste reste sans perte : le pixel art, et les images
## détourées (la perte grise leurs bords).
const LOSSY_DIR := "res://assets/hd2d/sky/"
const LOSSY_PREFIXES: Array[String] = ["sky", "cloud_sea"]
const LOSSY_QUALITY := 0.9
## Effort minimal de l'encodeur WebP sans perte (project.godot, F0).
const WEBP_METHOD_MIN := 4
const WEBP_FACTOR_MIN := 90.0
## Exclusions de F0 dans les trois préréglages d'export.
const F0_EXCLUDED: Array[String] = [
	"data/maps/*/plan.json",
	"assets/hd2d/ground/cobble.png",
	"assets/hd2d/ground/cobble_b.png",
	"assets/hd2d/ground/flagstone.png",
	"assets/hd2d/ground/flagstone_b.png",
	"assets/hd2d/ground/forest_floor.png",
	"assets/hd2d/ground/forest_floor_b.png",
	"assets/hd2d/ground/garden_soil.png",
	"assets/hd2d/ground/grass_b.png",
	"assets/hd2d/ground/grass_dry.png",
	"assets/hd2d/ground/grass_dry_b.png",
	"assets/hd2d/ground/gravel.png",
	"assets/hd2d/ground/leaf_litter.png",
	"assets/hd2d/ground/meadow_flowers.png",
	"assets/hd2d/ground/metal.png",
	"assets/hd2d/ground/moss.png",
	"assets/hd2d/ground/mud.png",
	"assets/hd2d/ground/path_dirt_b.png",
	"assets/hd2d/ground/peat.png",
	"assets/hd2d/ground/planks.png",
	"assets/hd2d/ground/rock.png",
	"assets/hd2d/ground/rock_b.png",
	"assets/hd2d/ground/sand.png",
	"assets/hd2d/ground/sand_b.png",
	"assets/hd2d/ground/stream_bed.png",
	"assets/hd2d/ground/water.png",
]
## Fichiers que le jeu lit toujours (ne doivent tomber sous aucune exclusion).
const KEPT: Array[String] = [
	"assets/hd2d/ground/atlas/ground_atlas.png",
	"assets/hd2d/ground/grass.png",
	"assets/hd2d/ground/path_dirt.png",
	"data/maps/ville_haute/map.json",
	"data/maps/ville_haute/materials.png",
]
## Fichiers du jeu où chercher une citation d'un fichier exclu.
const RUNTIME_DIRS: Array[String] = ["res://src", "res://data", "res://assets"]
const RUNTIME_EXTENSIONS: Array[String] = [
	"gd", "tscn", "tres", "json", "gdshader", "gdshaderinc", "cfg"
]


func _files(dir: String, extensions: Array[String], out: Array[String]) -> void:
	if dir in SKIPPED_DIRS:
		return
	for file: String in DirAccess.get_files_at(dir):
		if file.get_extension() in extensions:
			out.append(dir.path_join(file))
	for sub: String in DirAccess.get_directories_at(dir):
		_files(dir.path_join(sub), extensions, out)


func _exclude_filters() -> Dictionary:
	var presets := ConfigFile.new()
	assert_eq(presets.load("res://export_presets.cfg"), OK, "export_presets.cfg lisible")
	var filters := {}
	for section: String in presets.get_sections():
		if section.begins_with("preset.") and not section.ends_with(".options"):
			var name_value: String = presets.get_value(section, "name", section)
			var patterns: Array[String] = []
			for pattern: String in str(presets.get_value(section, "exclude_filter", "")).split(","):
				if not pattern.strip_edges().is_empty():
					patterns.append(pattern.strip_edges())
			filters[name_value] = patterns
	return filters


func _excluded_files() -> Array[String]:
	var all: Array[String] = []
	for dir: String in ["res://assets/hd2d/ground", "res://data/maps"]:
		_files(dir, ["png", "json"] as Array[String], all)
	var excluded: Array[String] = []
	for path: String in all:
		var relative := path.trim_prefix("res://")
		for pattern: String in F0_EXCLUDED:
			if relative.matchn(pattern):
				excluded.append(relative)
				break
	return excluded


func _is_lossy(import_path: String) -> bool:
	if not import_path.begins_with(LOSSY_DIR):
		return false
	for prefix: String in LOSSY_PREFIXES:
		if import_path.get_file().begins_with(prefix):
			return true
	return false


func test_every_texture_is_lossless_without_mipmaps() -> void:
	var imports: Array[String] = []
	_files("res://", ["import"] as Array[String], imports)
	var textures := 0
	var wrong: Array[String] = []
	for path: String in imports:
		var config := ConfigFile.new()
		if config.load(path) != OK:
			wrong.append("%s illisible" % path)
			continue
		if config.get_value("remap", "importer", "") != "texture":
			continue
		textures += 1
		var expected := TEXTURE_PARAMS.duplicate()
		if _is_lossy(path):
			expected["compress/mode"] = 1
			expected["compress/lossy_quality"] = LOSSY_QUALITY
		for key: String in expected:
			var value: Variant = config.get_value("params", key, null)
			if value != expected[key]:
				wrong.append("%s : %s=%s" % [path.trim_prefix("res://"), key, value])
	assert_gt(textures, 1000, "les images du jeu sont toutes vues (%d)" % textures)
	assert_true(
		wrong.is_empty(),
		(
			"images importées avec perte ou mipmaps (lance tools/import.sh) : %s"
			% ", ".join(wrong.slice(0, 20))
		)
	)


func test_new_images_get_the_same_settings() -> void:
	var defaults: Dictionary = ProjectSettings.get_setting("importer_defaults/texture", {})
	assert_eq(defaults.get("compress/mode", -1), 0, "Lossless par défaut")
	assert_eq(defaults.get("mipmaps/generate", true), false, "pas de mipmaps par défaut")
	assert_eq(defaults.get("detect_3d/compress_to", -1), 0, "pas de passage en VRAM compressée")
	var script := FileAccess.get_file_as_string("res://tools/import.sh")
	assert_string_contains(script, "normalize_textures")
	assert_string_contains(script, "detect_3d/compress_to=0")
	assert_string_contains(script, "compress/mode=0")
	assert_string_contains(script, 'LOSSY_DIR="assets/hd2d/sky/"', "(F2) le ciel avec perte")
	assert_string_contains(script, "mipmaps/generate=false")


func test_webp_lossless_encoder_effort() -> void:
	assert_false(
		ProjectSettings.get_setting("rendering/textures/lossless_compression/force_png", true),
		"WebP sans perte, plus léger que le PNG"
	)
	assert_gte(
		int(ProjectSettings.get_setting("rendering/textures/webp_compression/compression_method")),
		WEBP_METHOD_MIN
	)
	assert_gte(
		float(
			ProjectSettings.get_setting(
				"rendering/textures/webp_compression/lossless_compression_factor"
			)
		),
		WEBP_FACTOR_MIN
	)


func test_presets_exclude_the_unread_files() -> void:
	var filters := _exclude_filters()
	for preset: String in ["Web", "Windows Desktop", "Linux"]:
		assert_true(filters.has(preset), "préréglage %s" % preset)
		var patterns: Array = filters.get(preset, [])
		for pattern: String in F0_EXCLUDED:
			assert_true(pattern in patterns, "%s : %s hors du paquet" % [preset, pattern])
		for path: String in KEPT:
			for pattern: String in patterns:
				assert_false(path.matchn(pattern), "%s reste dans le paquet (%s)" % [path, pattern])
	var tiles := 0
	var plans := 0
	for path: String in _excluded_files():
		if path.ends_with("/plan.json"):
			plans += 1
		else:
			tiles += 1
	assert_eq(tiles, F0_EXCLUDED.size() - 1, "25 tuiles du sol, sources de l'atlas")
	assert_gt(plans, 0, "plans des cartes")


func test_nothing_in_game_reads_an_excluded_file() -> void:
	var excluded := _excluded_files()
	assert_false(excluded.is_empty())
	var sources: Array[String] = []
	for dir: String in RUNTIME_DIRS:
		_files(dir, RUNTIME_EXTENSIONS, sources)
	sources.append("res://project.godot")
	var cited: Array[String] = []
	for source: String in sources:
		var text := FileAccess.get_file_as_string(source)
		for path: String in excluded:
			if text.contains(path):
				cited.append("%s cite %s" % [source.trim_prefix("res://"), path])
		if source.get_extension() != "gd":
			continue
		# Un chemin fabriqué : une tuile du sol par son nom, un plan de carte par son dossier.
		if text.contains("hd2d/ground/%") or text.contains('hd2d/ground/" +'):
			cited.append("%s fabrique le chemin d'une tuile du sol" % source.trim_prefix("res://"))
		if text.contains("plan.json"):
			cited.append("%s lit un plan de carte" % source.trim_prefix("res://"))
	assert_true(cited.is_empty(), "fichiers hors du paquet lus en jeu : %s" % ", ".join(cited))
