extends "res://tests/stubs/c1_exterior_test.gd"
## (CF) La carte foret_profonde, la forêt profonde de l'île n° 68 (src/world/maps/foret_profonde/,
## plan de docs/lore/CARTE.md, section 8, écrite par tools/exterior_maps.py d'après
## tools/exterior_recipes/foret_profonde.py). Base commune tests/stubs/c1_exterior_test.gd (plan,
## sorties, marqueurs, points, circulation à pied, rien ne cache le joueur, densité, sol nu, draw
## calls, aucune lumière), plus :
## - la sortie vers l'entrepôt (à pied), Spawn et le marqueur d'arrivée ; la sortie vers la
##   montagne, posée dès que la carte existe (sinon un écriteau ferme le sentier de l'est) ;
## - le relief : deux ressauts rocheux à +1 m aux contours irréguliers, la rivière peinte au ras du
##   sol, praticable ;
## - la règle de pose des lisières : aucun bout de pan de forêt à découvert (un pan plus proche le
##   recouvre, ou un grand tronc de premier plan) ;
## - le refuge de Chtholly (le chêne creux), ses points pour la scène 10.2 ;
## - les décors et les remplaçants du plan, inscrits au manifeste (lot R5) ;
## - les objets à examiner et leurs textes ; la faune (E5) ; les places de la vie en plus du plan ;
## - aucune lumière : Atmosphere éclaire.

const EXTRA_PLACES: Array[String] = [
	"vers_entrepot",
	"course_entree",
	"fourche_refuge",
	"gue_nord",
	"gue_sud",
	"refuge_seuil",
	"refuge_ithea",
	"refuge_retour",
	"renard_berge",
	"clairiere_cerfs_centre",
]
const EXAMINABLES: Array[String] = [
	"refuge_creux",
	"mare_cachee",
	"gue",
	"lisiere_riviere",
	"cerfs",
	"souille",
	"loups",
]
const TEXTS := "res://data/texts/foret_profonde.json"
## Images du lot R5 (cahier n° 5, 7.1 et 7.2) que la forêt pose et que le cahier n'a pas livrées.
const R5_IMAGES: Array[String] = [
	"refuge_oak",
	"forest_wall_deep",
	"grove_dense",
	"fallen_pine",
	"rowan",
	"hidden_pool_a",
	"hidden_pool_b",
	"log_bridge_b",
	"river_bank",
	"river_rapids",
]
## Le corps opaque d'un pan de forêt : de 0,7 m à 15,3 m sur 16 (65 et 1 470 px sur 1 536) ; champ
## de la caméra en x.
const WALL_VISIBLE := Vector2(-6.5, 86.5)
const SEAM_MARGIN := 1.2

var _wall_bodies: Dictionary = {}


func before_all() -> void:
	map_id = "foret_profonde"
	# Les vues de la série standard (tools/qc_views.json) : l'entrée, le sentier, les cerfs, le gué,
	# la rivière, le
	# refuge, la mare, la souille, le sentier de l'est, les loups.
	density = {
		"entrée": [Vector3(40.0, 0.0, 6.0), 40, 100],
		"sentier": [Vector3(41.0, 0.0, 16.0), 40, 100],
		"cerfs": [Vector3(62.0, 0.0, 14.0), 40, 100],
		"gué": [Vector3(44.0, 0.0, 28.5), 40, 100],
		"rivière nord": [Vector3(16.0, 0.0, 14.0), 40, 100],
		"refuge": [Vector3(16.0, 0.0, 41.0), 40, 100],
		"mare": [Vector3(29.5, 0.0, 46.0), 40, 100],
		"souille": [Vector3(24.0, 0.0, 51.0), 40, 100],
		"sentier est": [Vector3(70.0, 0.0, 46.5), 40, 100],
		"loups": [Vector3(68.0, 0.0, 52.5), 40, 100],
	}
	walk_spots = [
		Vector3(40.0, 0.0, 3.0),
		Vector3(40.0, 0.0, 12.0),
		Vector3(43.0, 0.0, 22.0),
		Vector3(44.5, 0.0, 28.0),
		Vector3(50.0, 0.0, 38.0),
		Vector3(64.0, 0.0, 46.0),
		Vector3(77.0, 0.0, 46.5),
		Vector3(62.0, 0.0, 12.5),
		Vector3(16.0, 0.0, 41.0),
		Vector3(24.0, 0.0, 50.0),
		Vector3(8.0, 0.0, 10.0),
		Vector3(70.0, 0.0, 34.0),
	]
	min_walk_area = 2500.0
	min_checked_places = 2200
	await super()


# --- Le plan -------------------------------------------------------------------------------------


func test_the_plan_has_what_the_chapter_needs() -> void:
	assert_eq(_lines("sortie").size(), 2, "vers l'entrepôt, vers la montagne")
	assert_eq(_lines("marqueur").size(), 3, "Spawn, from_entrepot, from_montagne")
	assert_eq(
		_lines("point").size(),
		7,
		"refuge_creux, mare_cachee, gue, cerfs, souille, loups, lisiere_riviere"
	)
	assert_eq(_lines("place").size(), 3, "refuge, clairiere_cerfs, clairiere_loups")


func test_the_exit_to_the_warehouse_is_on_foot() -> void:
	var exit := _map.get_node(^"Exits/vers_entrepot") as MapExit
	assert_eq([exit.target_map, exit.target_marker], [&"entrepot", &"from_foret_profonde"])
	assert_eq(exit.prompt, "", "on passe en marchant")
	assert_true(Map.exists(&"entrepot"), "l'entrepôt existe")
	assert_not_null(_map.marker(&"from_entrepot"), "arrivée de l'entrepôt")
	assert_lt(
		_map.spawn().global_position.distance_to(_map.marker(&"from_entrepot").global_position),
		1.0,
		"Spawn à côté de l'arrivée"
	)
	var shape := _map.get_node(^"Exits/vers_entrepot/CollisionShape3D") as CollisionShape3D
	assert_almost_eq(shape.global_position.x, 40.0, 0.05, "au milieu de la trouée (x 37 → 43)")
	assert_lt(shape.global_position.z, 1.0, "au bord nord de la carte")


func test_the_exit_to_the_mountain_waits_for_its_map() -> void:
	var waits := not Map.exists(&"montagne")
	assert_eq(_map.get_node_or_null(^"Exits/vers_montagne") == null, waits)
	assert_not_null(_map.marker(&"from_montagne"), "le marqueur d'arrivée est là, la sortie ou non")
	assert_eq(
		_map.get_node(^"Exits").get_child_count(),
		1 + int(not waits),
		"les sorties dont la carte existe"
	)
	if waits:
		var sign_node := _map.find_child("SignMontagne", true, false)
		assert_not_null(sign_node, "le sentier de l'est est fermé d'un écriteau")
		if sign_node != null:
			assert_not_null(sign_node.get_node_or_null(^"Reader"), "on le lit")
			assert_true(_is_reached(Vector3(76.0, 0.0, 46.5)), "on va jusqu'au bout du sentier")
	else:
		var exit := _map.get_node(^"Exits/vers_montagne") as MapExit
		assert_eq([exit.target_map, exit.target_marker], [&"montagne", &"from_foret_profonde"])


# --- Le relief
# -------------------------------------------------------------------------------------


func test_two_rocky_ledges_at_plus_one_metre_with_irregular_outlines() -> void:
	assert_almost_eq(_ground.height_at(64.0, 4.0), 1.0, 0.05, "le ressaut nord-est, +1 m")
	assert_almost_eq(_ground.height_at(4.0, 52.0), 1.0, 0.05, "le ressaut sud-ouest, +1 m")
	assert_almost_eq(
		_ground.height_at(64.0, 14.0), 0.0, 0.05, "la clairière des cerfs au pied du ressaut"
	)
	assert_almost_eq(_ground.height_at(24.0, 51.0), 0.0, 0.05, "la souille à plat")
	assert_false(_is_reached(Vector3(64.0, 1.0, 4.0)), "on ne gravit pas le ressaut (1 m)")
	# Des contours irréguliers : le bord sud du ressaut nord-est n'est pas une droite (plusieurs z
	# de falaise).
	var edges := {}
	for x in range(54, 78):
		for z in range(5, 11):
			var up := _ground.height_at(float(x) + 0.5, float(z) + 0.01)
			var down := _ground.height_at(float(x) + 0.5, float(z) + 1.01)
			if up - down > 0.8:
				edges[z] = true
	assert_gte(
		edges.size(), 3, "le bord du ressaut est en tronçons décalés (z %s)" % [edges.keys()]
	)


func test_the_river_is_painted_level_with_the_ground_and_one_wades_through_it() -> void:
	for spot: Vector2 in [
		Vector2(8.4, 4.0),
		Vector2(18.0, 13.2),
		Vector2(30.0, 20.8),
		Vector2(44.0, 26.6),
		Vector2(60.0, 30.6),
		Vector2(75.0, 34.2),
	]:
		assert_eq(_ground.material_at(spot.x, spot.y), &"eau_basse", "l'eau, en %s" % spot)
		assert_almost_eq(
			_ground.height_at(spot.x, spot.y), 0.0, 0.05, "au ras du sol, en %s" % spot
		)
		assert_true(_ground.is_walkable(spot.x, spot.y), "on y marche, en %s" % spot)
		assert_true(_is_reached(Vector3(spot.x, 0.0, spot.y)), "on y va à pied, en %s" % spot)
	# Le gué : le sentier passe d'une rive à l'autre sans marche.
	assert_true(_is_reached(Vector3(43.0, 0.0, 22.0)), "la rive nord du gué")
	assert_true(_is_reached(Vector3(45.6, 0.0, 31.2)), "la rive sud du gué")


# --- La règle de pose des lisières
# ---------------------------------------------------------------------


## Aucune image de lisière ou de mur de forêt dont le bord vertical est opaque n'est seule dans le
## champ : l'image est pleine
## jusqu'à ses bords dans sa moitié basse (le sous-bois) et son corps haut (la voûte) s'arrête à 0,7
## m des bords ; chaque bout
## de pan (à ±8 m du centre) est recouvert par le corps haut d'un pan plus proche de la caméra (à
## 1,2 m de ses bords), ou par un
## grand tronc de premier plan (au nord) ou grand conifère (à l'ouest et à l'est) posé sur lui, ou
## sort du champ de la caméra.
func test_no_forest_wall_ends_in_the_open() -> void:
	var walls: Array[Dictionary] = []
	var trunks: Array[Vector3] = []
	for element: Array in _elements:
		var panel := element[0] as DecorPanel
		if panel == null:
			continue
		var image := String(element[1]).get_file().get_basename()
		var at: Vector3 = element[2]
		if image.begins_with("forest_wall") or image.begins_with("treeline"):
			var half := float(panel.texture.get_width()) / 192.0
			(
				walls
				. append(
					{
						"name": panel.name,
						"x": at.x,
						"half": half,
						"inner": _wall_inner(panel.texture),
						"z": at.z,
					}
				)
			)
		elif (
			image.begins_with("fg_trunk")
			or image.begins_with("tree_old_pine")
			or image.begins_with("pine_tall_b")
		):
			trunks.append(at)
	assert_gte(walls.size(), 15, "trois chaînes de pans de forêt")
	var open_ends: Array[String] = []
	var checked := 0
	for wall in walls:
		for side: float in [-1.0, 1.0]:
			var end: float = float(wall["x"]) + side * float(wall["half"])
			if end < WALL_VISIBLE.x or end > WALL_VISIBLE.y:
				continue
			checked += 1
			var covered := false
			for other in walls:
				var reach: float = float(other["inner"])
				if (
					other["z"] > wall["z"] + 0.05
					and end > float(other["x"]) - reach + SEAM_MARGIN
					and end < float(other["x"]) + reach - SEAM_MARGIN
				):
					covered = true
			for trunk in trunks:
				if absf(trunk.x - end) < 0.8 and trunk.z > float(wall["z"]):
					covered = true
			if not covered:
				open_ends.append("%s : bout en x = %.1f" % [wall["name"], end])
	gut.p("%d bouts de pan dans le champ" % checked)
	assert_gt(checked, 8, "des bouts de pan à couvrir")
	assert_eq(open_ends, [] as Array[String], "aucun bout de pan à découvert")


## Demi-largeur (m) du corps haut d'une image de pan : première et dernière colonne opaque (alpha ≥
## 0,5) sur des rangées de la
## voûte (de 19 % à 38 % de la hauteur), en mètres depuis le milieu de l'image.
func _wall_inner(texture: Texture2D) -> float:
	var path := texture.resource_path
	if _wall_bodies.has(path):
		return _wall_bodies[path]
	var image := texture.get_image()
	var width := image.get_width()
	var first := width
	var last := 0
	for y in range(int(image.get_height() * 0.19), int(image.get_height() * 0.38), 12):
		for x in width:
			if image.get_pixel(x, y).a >= 0.5:
				first = mini(first, x)
				break
		for x in range(width - 1, -1, -1):
			if image.get_pixel(x, y).a >= 0.5:
				last = maxi(last, x)
				break
	var inner := float(last + 1 - first) / 192.0
	_wall_bodies[path] = inner
	return inner


# --- Le refuge
# ---------------------------------------------------------------------------------------


func test_the_refuge_oak_stands_over_its_place_with_the_hollow_to_the_south() -> void:
	var oak := _map.find_child("RefugeOak", true, false) as DecorPanel
	assert_not_null(oak, "le chêne creux du refuge")
	if oak == null:
		return
	assert_almost_eq(oak.global_position.x, 16.0, 0.01, "le plan : (16 ; 36)")
	assert_almost_eq(oak.global_position.z, 36.0, 0.01)
	assert_eq(oak.texture.get_size(), Vector2(768.0, 960.0), "8 × 10 m (CARTE.md 8, cahier n° 3)")
	assert_true(
		oak.foreground,
		"il cacherait la forêt au nord de lui : premier plan, il s'efface devant le joueur"
	)
	var place_area := _map.get_node(^"Life/Areas/refuge") as Marker3D
	assert_eq(
		place_area.get_meta(&"area", Rect2()), Rect2(10.0, 38.0, 12.0, 8.0), "la place du refuge"
	)
	assert_eq(_blocking_in(Rect2(10.5, 38.5, 11.0, 7.0)), [] as Array[String], "rien n'y bloque")
	# Les points de la scène 10.2 : le creux, la place où Chtholly s'assied, où Ithea s'assoit, par
	# où elles repartent.
	var hollow := _map.get_node(^"Life/Places/refuge_creux") as Marker3D
	for place_name: String in ["refuge_seuil", "refuge_ithea", "refuge_retour"]:
		var at := (_map.get_node(NodePath("Life/Places/" + place_name)) as Marker3D).global_position
		assert_lt(
			Vector2(at.x, at.z).distance_to(
				Vector2(hollow.global_position.x, hollow.global_position.z)
			),
			8.0,
			"%s : près du creux" % place_name
		)
	# Le chemin du refuge, depuis le sentier : on y va à pied d'un bout à l'autre.
	for spot: Vector3 in [
		Vector3(43.0, 0.0, 22.0), Vector3(32.0, 0.0, 30.0), Vector3(20.0, 0.0, 40.0)
	]:
		assert_true(_is_reached(spot), "%s : sur le chemin du refuge" % spot)


# --- Les décors et les images
# ------------------------------------------------------------------------


func test_the_decors_of_the_plan_are_there() -> void:
	var images := {}
	for element: Array in _elements:
		images[String(element[1]).get_file().get_basename()] = true
	for kind: String in ["decor", "arbre"]:
		for words in _lines(kind):
			var found := false
			for suffix: String in ["", "_fg", "_forest", "_libre"]:
				found = found or images.has(words[1] + suffix)
			assert_true(found, "%s %s (ligne du plan)" % [kind, words[1]])


func test_the_replacement_images_are_in_the_manifest_and_used() -> void:
	var manifest: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://tools/hd2d_manifest.json")
	)
	var listed := {}
	for entry: Dictionary in manifest["images"]:
		listed[String(entry["path"]).get_file().get_basename()] = String(entry.get("lot", ""))
	var images := {}
	for element: Array in _elements:
		images[String(element[1]).get_file().get_basename()] = true
	for image_name in R5_IMAGES:
		assert_eq(listed.get(image_name, ""), "R5", "%s au manifeste, lot R5" % image_name)
		assert_true(images.has(image_name), "%s posée dans la carte" % image_name)
	for element: Array in _elements:
		var path := String(element[1])
		assert_true(ResourceLoader.exists(path), "%s existe" % path)


## Ce qui se dresse au sud d'un endroit où l'on marche est de premier plan : le refuge, le sapin
## abattu, les arbres.
func test_tall_decors_where_one_walks_are_foreground_panels() -> void:
	var fading := 0
	for element: Array in _elements:
		var panel := element[0] as DecorPanel
		if panel != null and panel.foreground:
			fading += 1
	assert_gte(
		fading, 20, "des arbres et des troncs de premier plan, qui s'effacent devant le joueur"
	)


# --- Les objets à examiner
# ----------------------------------------------------------------------------


func test_the_things_to_examine_have_their_text() -> void:
	var root := _map.get_node_or_null(^"Examine")
	assert_not_null(root, "les objets à examiner")
	if root == null:
		return
	assert_eq(root.get_child_count(), EXAMINABLES.size())
	var json := JSON.new()
	assert_eq(json.parse(FileAccess.get_file_as_string(TEXTS)), OK, "foret_profonde.json lisible")
	assert_eq(DialogueRunner.story_problem(json.data), "", "format des textes de l'histoire")
	for key in EXAMINABLES:
		var item := root.get_node_or_null(NodePath(key)) as Examinable
		assert_not_null(item, "objet %s" % key)
		if item == null:
			continue
		assert_eq(item.text_key, "foret_profonde/" + key)
		assert_eq(item.texts_path, TEXTS)
		assert_false(item.text_value().is_empty(), "%s : un texte" % key)
		assert_true(item.is_in_group(&"interactable"), "%s : interactable" % key)
		assert_true(_is_reached(item.global_position), "%s : on s'en approche à pied" % key)


# --- La faune
# ------------------------------------------------------------------------------------------


func test_the_forest_has_its_wildlife_node_and_markers() -> void:
	var fauna := _map.get_node_or_null(^"Life/Fauna")
	assert_not_null(fauna, "le nœud Life/Fauna d'E5")
	assert_true(fauna is FaunaPopulator)
	var entries := FaunaRules.entries_for(&"foret_profonde")
	assert_gt(entries.size(), 0, "le peuplement de la forêt est écrit (peuplement.json, maps)")
	var species := {}
	for entry: Dictionary in entries:
		species[String(entry["species"])] = true
		if entry.has("at"):
			assert_not_null(
				_map.find_child(String(entry["at"]), true, false), "%s : son marqueur" % entry["id"]
			)
		if entry.has("rect"):
			var rect := entry["rect"] as Array
			assert_true(
				float(rect[0]) >= 0.0 and float(rect[2]) <= 80.0, "%s : dans la carte" % entry["id"]
			)
	for expected: String in ["deer", "fox", "squirrel", "crow", "boar", "wolf", "frog", "owl"]:
		assert_true(species.has(expected), "VIE.md 6.2 : %s dans la forêt" % expected)
	assert_eq(
		FaunaRules.problems(&"ile_68"), PackedStringArray(), "le peuplement de l'île est sans faute"
	)
	assert_false(FaunaRules.is_banned(&"foret_profonde"), "on y croise des bêtes")
	assert_false(
		(FaunaRules.population(&"ile_68")["planned"] as Dictionary).has("foret_profonde"),
		"la forêt n'est plus « prévue » : elle est peuplée"
	)


func test_the_forest_is_in_the_island() -> void:
	assert_true(
		WorldAtlas.maps_of(&"ile_68").has(&"foret_profonde"),
		"foret_profonde dans les cartes de l'île"
	)
	assert_eq(WorldAtlas.island_of(&"foret_profonde"), &"ile_68")
	assert_eq(WorldAtlas.place_of(&"foret_profonde"), &"foret_profonde")
	assert_eq(WorldManager.map_display_name(&"foret_profonde"), "La forêt profonde")


# --- La vie
# --------------------------------------------------------------------------------------------


func test_the_extra_life_places_are_named_and_reached() -> void:
	for place_name in EXTRA_PLACES:
		var place := _map.get_node_or_null(NodePath("Life/Places/" + place_name)) as Marker3D
		assert_not_null(place, "place de la vie %s" % place_name)
		if place != null:
			assert_true(_is_reached(place.global_position), "%s : on y va" % place_name)
	assert_eq(
		_map.get_node(^"Life/Places").get_child_count(),
		_lines("point").size() + EXTRA_PLACES.size(),
		"les points du plan et les places en plus"
	)
	var departure := _map.get_node(^"Life/Places/vers_entrepot") as Marker3D
	var exit_at := (_map.get_node(^"Exits/vers_entrepot") as MapExit).global_position
	assert_lt(
		Vector2(departure.global_position.x, departure.global_position.z).distance_to(
			Vector2(exit_at.x, exit_at.z)
		),
		3.0,
		"vers_entrepot : devant la sortie"
	)


## Les places que VIE.md et ACTE1.md citent par leur nom (foret_profonde:refuge, :refuge_creux,
## :mare_cachee…).
func test_the_places_of_the_other_documents_exist() -> void:
	for place_name: String in [
		"refuge",
		"refuge_creux",
		"mare_cachee",
		"gue",
		"cerfs",
		"souille",
		"loups",
		"lisiere_riviere",
		"clairiere_cerfs",
		"clairiere_loups",
	]:
		var found := _map.get_node_or_null(NodePath("Life/Places/" + place_name))
		if found == null:
			found = _map.get_node_or_null(NodePath("Life/Areas/" + place_name))
		assert_not_null(found, place_name)


# --- La lumière
# ---------------------------------------------------------------------------------------


func test_the_map_light_is_left_to_atmosphere() -> void:
	assert_eq(
		_map.light_preset, &"", "le préréglage du moment : le jour vert et or, le soir bleu sombre"
	)
	assert_null(_map.get_node_or_null(^"Lights"), "pas de nœud de lumières")
