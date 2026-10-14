extends GutTest
## (E2) Sol en relief des cartes : format des données (data/maps/<map_id>/, MapGroundData) et
## vérifications ; requêtes de hauteur, de matière et de pas sur des cartes faites en mémoire.
## Le format : PLAN.md, « Format du sol des cartes extérieures ».

const MAPS := ["essai_relief"]
const TEST_ROOT := "res://tests/data/maps"
const TEST_MAPS := ["mesure_80x60"]
## Couleurs de peinture des cartes en mémoire (bibliothèque data/maps/ground_materials.json).
const PAINT := {
	"h": "#5aa83c",
	"s": "#e0b070",
	"d": "#b4b4a0",
	"e": "#3060c0",
}
const PALETTE := {
	"#5aa83c": "herbe",
	"#e0b070": "sentier",
	"#b4b4a0": "dalles",
	"#3060c0": "eau",
}
## Structures : escaliers (^ > v <), rampes (A : vers le nord), muret (w).
const STRUCTURE_PAINT := {
	"^": "#e02020",
	">": "#e06020",
	"v": "#e0a020",
	"<": "#e02080",
	"A": "#2040e0",
	"w": "#404040",
}


func _spec(width: int, depth: int, extra: Dictionary = {}) -> Dictionary:
	var spec := {
		"format": "map_ground",
		"version": 1,
		"size": [width, depth],
		"palette": PALETTE,
		"skirt": 4,
	}
	spec.merge(extra, true)
	return spec


## Image d'une grille de caractères : chaque caractère donne la couleur de son pixel (« . » ou
## « » : transparent).
func _image(rows: Array, colors: Callable) -> Image:
	var image := Image.create_empty(
		String(rows[0]).length(), rows.size(), false, Image.FORMAT_RGBA8
	)
	for j in rows.size():
		var row := String(rows[j])
		for i in row.length():
			image.set_pixel(i, j, colors.call(row[i]))
	return image


func _level_color(ch: String) -> Color:
	if ch == ".":
		return Color(0, 0, 0, 0)
	var value := int(ch) * MapGroundData.DEFAULT_STEP_VALUE
	return Color8(value, value, value, 255)


func _paint_color(ch: String) -> Color:
	return Color(0, 0, 0, 0) if not PAINT.has(ch) else Color.html(PAINT[ch])


func _structure_color(ch: String) -> Color:
	return Color(0, 0, 0, 0) if not STRUCTURE_PAINT.has(ch) else Color.html(STRUCTURE_PAINT[ch])


## Carte en mémoire : paliers (chiffres, « . » le vide), matières (par défaut de l'herbe partout
## sur la terre), structures.
func _data(
	levels: Array, materials: Array = [], structures: Array = [], extra: Dictionary = {}
) -> MapGroundData:
	var width := String(levels[0]).length()
	var paint := materials.duplicate()
	if paint.is_empty():
		for row: String in levels:
			var line := ""
			for ch: String in row:
				line += "." if ch == "." else "h"
			paint.append(line)
	var structure_image: Image = null
	if not structures.is_empty():
		structure_image = _image(structures, _structure_color)
	return MapGroundData.from_images(
		_spec(width, levels.size(), extra),
		_image(levels, _level_color),
		_image(paint, _paint_color),
		structure_image,
		&"essai_memoire"
	)


func _has_problem(data: MapGroundData, fragment: String) -> bool:
	for problem: String in data.problems:
		if problem.contains(fragment):
			return true
	return false


# --- Bibliothèque et cartes livrées ---------------------------------------------------------------


func test_library_names_atlas_tiles_and_distinct_colors() -> void:
	var library := MapGroundData.library()
	var materials: Dictionary = library.get("materials", {})
	assert_gt(materials.size(), 12, "matières de la bibliothèque")
	var colors := {}
	for material: String in materials.keys():
		var spec: Dictionary = materials[material]
		assert_true(
			IslandTerrain.GROUND_LAYERS.has(StringName(String(spec.get("layer", "")))),
			"%s : tuile de l'atlas" % material
		)
		var color := String(spec.get("color", ""))
		assert_true(
			Color.html_is_valid(color) and color.length() == 7, "%s : couleur #rrggbb" % material
		)
		assert_false(colors.has(color), "%s : couleur de peinture propre" % material)
		colors[color] = true
	for wanted: String in ["herbe", "herbe_haute", "terre_battue", "sentier", "paves", "dalles"]:
		assert_true(materials.has(wanted), "matière %s" % wanted)
	for wanted: String in ["boue", "tourbe", "eau", "sable", "roche", "sous_bois"]:
		assert_true(materials.has(wanted), "matière %s" % wanted)
	assert_false(bool(materials["eau"].get("walkable", true)), "l'eau dormante ne se foule pas")
	var structures: Dictionary = library.get("structures", {})
	var kinds := {}
	for color: String in structures.keys():
		assert_false(colors.has(color), "%s : couleur de structure distincte des matières" % color)
		var entry: Dictionary = structures[color]
		kinds["%s/%s" % [entry.get("kind", entry.get("face", "")), entry.get("dir", "")]] = true
	for kind: String in ["stairs/north", "stairs/south", "ramp/east", "ramp/west", "wall/"]:
		assert_true(kinds.has(kind), "structure %s" % kind)


func test_shipped_maps_are_valid() -> void:
	for map_id: String in MAPS:
		var data := MapGroundData.load_map(StringName(map_id))
		assert_eq(data.problems, PackedStringArray(), "%s sans problème" % map_id)
		assert_gt(data.width, 0, map_id)
	for map_id: String in TEST_MAPS:
		var data := MapGroundData.load_map(StringName(map_id), TEST_ROOT)
		assert_eq(data.problems, PackedStringArray(), "%s sans problème" % map_id)


func test_every_ground_map_folder_is_valid() -> void:
	# Toute carte de data/maps au format du sol en relief se lit sans problème.
	var dir := DirAccess.open(MapGroundData.DATA_ROOT)
	assert_not_null(dir, "data/maps")
	if dir == null:
		return
	var checked := 0
	for folder: String in dir.get_directories():
		var path := MapGroundData.DATA_ROOT.path_join(folder).path_join("map.json")
		if not FileAccess.file_exists(path):
			continue
		var json := JSON.new()
		if json.parse(FileAccess.get_file_as_string(path)) != OK:
			fail_test("%s illisible" % path)
			continue
		if not json.data is Dictionary or json.data.get("format", "") != MapGroundData.FORMAT:
			continue
		var data := MapGroundData.load_map(StringName(folder))
		assert_eq(data.problems, PackedStringArray(), "%s sans problème" % folder)
		checked += 1
	assert_gte(checked, 1, "au moins la carte de démonstration")


func test_demo_map_has_everything_the_mission_asks() -> void:
	var data := MapGroundData.load_map(&"essai_relief")
	assert_eq(Vector2i(data.width, data.depth), Vector2i(60, 45), "60 × 45 m")
	assert_eq(data.edges["north"], "void", "le vide au nord")
	var levels := {}
	var stairs := 0
	var ramps := 0
	var walls := 0
	for c in data.width * data.depth:
		if data.levels[c] != MapGroundData.VOID_LEVEL and data.kinds[c] == MapGroundData.Kind.FLAT:
			levels[data.levels[c]] = true
		stairs += int(data.kinds[c] == MapGroundData.Kind.STAIRS)
		ramps += int(data.kinds[c] == MapGroundData.Kind.RAMP)
		walls += int(data.faces[c] == MapGroundData.Face.WALL)
	assert_gte(levels.size(), 3, "trois paliers au moins")
	assert_gt(stairs, 0, "un escalier")
	assert_gt(ramps, 0, "une rampe")
	assert_gt(walls, 0, "un muret")
	for wanted: StringName in [&"sentier", &"eau", &"tourbe", &"herbe"]:
		assert_true(data.material_names.has(wanted), "matière %s" % wanted)
	assert_true(data.has_void(), "un bord d'île")


# --- Vérifications ------------------------------------------------------------------------------


func test_a_clean_map_has_no_problem() -> void:
	var data := _data(["0000", "0000", "0000", "0000"])
	assert_eq(data.problems, PackedStringArray())
	assert_eq(data.surface_height(1.5, 1.5), 0.0)


func test_format_errors_are_reported() -> void:
	var levels := Image.create_empty(4, 4, false, Image.FORMAT_RGBA8)
	levels.fill(Color8(0, 0, 0, 255))
	var materials := Image.create_empty(4, 4, false, Image.FORMAT_RGBA8)
	materials.fill(Color.html("#5aa83c"))
	var spec := _spec(4, 4, {"format": "autre", "taille": [4, 4]})
	var data := MapGroundData.from_images(spec, levels, materials)
	assert_true(_has_problem(data, "format"), "format inconnu")
	assert_true(_has_problem(data, "clé inconnue « taille »"), "clé inconnue")
	data = MapGroundData.from_images(_spec(5, 4), levels, materials)
	assert_true(_has_problem(data, "heights.png : 4 × 4 px au lieu de 5 × 4"), "taille d'image")
	data = MapGroundData.from_images(_spec(4, 4, {"materials_scale": 2}), levels, materials)
	assert_true(
		_has_problem(data, "materials.png : 4 × 4 px au lieu de 8 × 8"), "échelle des matières"
	)


func test_unknown_colors_and_heights_off_the_step_are_reported() -> void:
	var data := _data(["0000", "0000", "0000", "0000"], ["hhhh", "hhhh", "hhxh", "hhhh"])
	assert_true(_has_problem(data, "transparent"), "pixel sans matière sur la terre")
	var levels := _image(["0000", "0000", "0000", "0000"], _level_color)
	levels.set_pixel(1, 1, Color8(10, 10, 10, 255))
	var materials := _image(["hhhh", "hhhh", "hhhh", "hhhh"], _paint_color)
	materials.set_pixel(2, 2, Color8(1, 2, 3, 255))
	data = MapGroundData.from_images(_spec(4, 4), levels, materials)
	assert_true(_has_problem(data, "hors palier"), "gris hors palier")
	assert_true(_has_problem(data, "#010203 hors palette"), "couleur hors palette")


func test_stairs_must_join_two_flat_levels() -> void:
	# Un escalier de deux cases qui monte au nord, de 0 à 2 (1 m) : valide.
	var good := _data(
		["22222", "22222", "00000", "00000", "00000", "00000"],
		[],
		["     ", "     ", "  ^  ", "  ^  ", "     ", "     "]
	)
	assert_eq(good.problems, PackedStringArray(), "escalier valide")
	assert_eq(good.run_length[2 * 5 + 2], 2, "volée de deux cases")
	assert_almost_eq(good.run_high[2 * 5 + 2], 1.0, 0.001, "haut de la volée")
	# Sans case plus haute au bout : refusé.
	var flat := _data(
		["00000", "00000", "00000", "00000", "00000", "00000"],
		[],
		["     ", "     ", "  ^  ", "  ^  ", "     ", "     "]
	)
	assert_true(_has_problem(flat, "escalier en (2, 3)"), "escalier qui ne monte nulle part")


func test_slopes_steeper_than_40_degrees_are_refused() -> void:
	# Rampe d'une case pour 1 m : 45°.
	var steep := _data(
		["22222", "22222", "00000", "00000", "00000"],
		[],
		["     ", "     ", "  A  ", "     ", "     "]
	)
	assert_true(_has_problem(steep, "pente de 45°"), "rampe trop raide")
	# Deux cases pour 1 m : 26,6°.
	var gentle := _data(
		["22222", "22222", "00000", "00000", "00000", "00000"],
		[],
		["     ", "     ", "  A  ", "  A  ", "     ", "     "]
	)
	assert_eq(gentle.problems, PackedStringArray(), "rampe praticable")


func test_paths_never_climb_more_than_a_step_without_stairs() -> void:
	var cliff := _data(["3333", "3333", "0000", "0000"], ["hssh", "hssh", "hssh", "hssh"])
	assert_true(_has_problem(cliff, "marche(s) de plus de 0.5 m sans escalier"), "chemin coupé")
	var step := _data(["1111", "1111", "0000", "0000"], ["hssh", "hssh", "hssh", "hssh"])
	assert_eq(step.problems, PackedStringArray(), "une marche d'un palier se franchit")
	var grass := _data(["3333", "3333", "0000", "0000"])
	assert_eq(grass.problems, PackedStringArray(), "une falaise hors des chemins")


func test_structures_keep_away_from_the_void_and_the_border() -> void:
	var near_void := _data(
		["......", "222222", "000000", "000000", "000000", "000000"],
		[],
		["      ", "      ", "  ^   ", "  ^   ", "      ", "      "]
	)
	assert_true(_has_problem(near_void, "à moins de 2 m du vide"), "escalier au bord du vide")
	var border := _data(
		["22222", "22222", "00000", "00000", "00000"],
		[],
		["     ", "     ", "^    ", "     ", "     "]
	)
	assert_true(_has_problem(border, "au bord de la carte"), "escalier au bord de la carte")


func test_spawn_must_be_walkable() -> void:
	var data := _data(
		["0000", "0000", "0000", "0000"], ["hhhh", "heeh", "heeh", "hhhh"], [], {"spawn": [1, 1]}
	)
	assert_true(_has_problem(data, "spawn"), "départ dans l'eau")


# --- Requêtes -------------------------------------------------------------------------------------


func test_heights_follow_levels_ramps_and_steps() -> void:
	var data := _data(
		["444444", "444444", "000000", "000000", "000000", "000000", "000000"],
		[],
		["      ", "      ", "  ^ A ", "  ^ A ", "  ^ A ", "  ^ A ", "      "]
	)
	assert_eq(data.problems, PackedStringArray())
	# Paliers.
	assert_almost_eq(data.surface_height(0.5, 0.5), 2.0, 0.0001, "palier 4 : 2 m")
	assert_almost_eq(data.surface_height(0.5, 6.5), 0.0, 0.0001, "palier 0")
	# Rampe de 4 cases pour 2 m, du bas (z = 6) au haut (z = 2) : 0,5 m par mètre.
	assert_almost_eq(data.surface_height(4.5, 6.0), 0.0, 0.0001, "pied de la rampe")
	assert_almost_eq(data.surface_height(4.5, 5.0), 0.5, 0.0001, "rampe à 1 m")
	assert_almost_eq(data.surface_height(4.5, 3.5), 1.25, 0.0001, "rampe à 2,5 m")
	# Escalier : 20 marches de 0,1 m sur 4 m (0,2 m de giron), la première au pied.
	assert_eq(data.stair_steps(2 * 6 + 2), 20, "vingt marches")
	assert_almost_eq(data.surface_height(2.5, 5.95), 0.1, 0.0001, "première marche")
	assert_almost_eq(data.surface_height(2.5, 5.75), 0.2, 0.0001, "deuxième marche")
	assert_almost_eq(data.surface_height(2.5, 2.05), 2.0, 0.0001, "dernière marche")


func test_void_materials_and_walkability() -> void:
	var data := _data(
		["......", "000000", "000000", "000000", "000000"],
		["......", "hhhhhh", "hheehh", "hssssh", "hhhhhh"],
		[],
		{"edges": {"north": "void"}}
	)
	assert_eq(data.problems, PackedStringArray())
	assert_eq(data.surface_height(3.0, 0.2), MapGroundData.VOID_HEIGHT, "le vide")
	assert_eq(data.surface_height(3.0, -3.0), MapGroundData.VOID_HEIGHT, "au-delà du bord nord")
	assert_eq(data.surface_height(3.0, 4.5), 0.0, "la terre")
	assert_eq(data.material_name(data.material_index_at(2.5, 2.5)), &"eau")
	assert_eq(data.material_name(data.material_index_at(2.5, 3.5)), &"sentier")
	assert_false(data.is_walkable(2.5, 2.5), "l'eau dormante")
	assert_true(data.is_walkable(2.5, 3.5), "le sentier")
	assert_false(data.is_walkable(3.0, 0.2), "le vide")
	assert_false(data.is_walkable(-1.0, 3.0), "hors de la carte (prolongement)")
	# Au-delà d'un bord « land », le sol se prolonge (prolongement de la case du bord).
	assert_eq(data.surface_height(-2.0, 3.5), 0.0, "prolongement à l'ouest")
	assert_eq(data.surface_height(-9.0, 3.5), MapGroundData.VOID_HEIGHT, "au-delà du prolongement")


func test_the_coast_is_not_a_staircase() -> void:
	# Le vide au nord : la côte passe près de la ligne peinte (z = 1), mais à des distances
	# variées (bruit), et ses coins sont arrondis.
	var row_void := ""
	var row_land := ""
	for _i in 24:
		row_void += "."
		row_land += "0"
	var data := _data(
		[row_void, row_land, row_land, row_land, row_land], [], [], {"edges": {"north": "void"}}
	)
	var shallow := INF
	var deep := 0.0
	for i in 100:
		var x := 0.5 + i * 0.23
		var z := 0.0
		while z < 3.0 and data.surface_height(x, z) == MapGroundData.VOID_HEIGHT:
			z += 0.02
		assert_between(z, 0.4, 1.8, "côte près de la ligne peinte en x = %.2f" % x)
		shallow = minf(shallow, z)
		deep = maxf(deep, z)
	assert_gt(deep - shallow, 0.3, "la côte ondule (%.2f à %.2f m)" % [shallow, deep])
