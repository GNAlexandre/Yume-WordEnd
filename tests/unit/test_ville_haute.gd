extends "res://tests/stubs/c1_exterior_test.gd"
## (CV) La ville haute (src/world/maps/ville_haute/, plan de docs/lore/CARTE.md, section 9.2, écrite
## par
## tools/exterior_maps.py). Base commune tests/stubs/c1_exterior_test.gd (plan, sorties, marqueurs,
## points,
## circulation à pied, rien ne cache le joueur, densité, sol nu, draw calls), plus :
## - les six sorties : le sentier à l'ouest (à pied), la place du marché au sud (à pied), les portes
##   du snack, du
##   café, de la librairie et de la salle de projection (à invite), qu'on rejoint toutes à pied ;
## - la salle de projection, close jusqu'au jour 5 (métadonnées `open_from_day` et
##   `closed_text_key`, lues par le
##   récit) ; les autres portes, toujours ouvertes ;
## - les trois terrasses (+2, +1, 0), les deux volées d'escalier de la grand-rue, les murets des
##   paliers ;
## - les maisons et les boutiques du plan, à leur emprise ; les images de remplacement du lot R4 ;
## - les places de la vie en plus du plan, les objets à examiner et leurs textes ;
## - aucune lumière : Atmosphere éclaire.

const EXTRA_PLACES: Array[String] = [
	"rue_haute_ouest",
	"rue_haute_est",
	"rue_haute_trottoir_nord",
	"rue_haute_trottoir_sud",
	"banc_haut",
	"grand_rue_nord",
	"grand_rue_milieu",
	"carrefour_centre",
	"carrefour_ouest",
	"carrefour_est",
	"snack_terrasse",
	"porte_snack",
	"cafe_devant",
	"bas_de_ville_centre",
	"rue_basse_ouest",
	"rue_basse_est",
	"vers_marche",
	"depuis_sentier",
]
## Images du lot R4 (cahier n° 5, 6.4 et 6.5) que la ville emploie et que le cahier n'a pas livrées.
const R4_IMAGES: Array[String] = [
	"town_house_a",
	"town_house_b",
	"town_house_c",
	"town_house_d",
	"town_house_e",
	"town_house_f",
	"cafe_town",
	"shop_snack",
	"shop_accessories",
	"shop_apothecary",
	"hanging_sign_pan",
	"hanging_sign_cup",
	"town_planter_stone",
	"town_wall_fountain",
	"town_doorsteps",
	"town_cellar_hatch",
	"town_wall_low",
	"town_railing",
	"town_roofs_a",
	"town_roofs_b",
]
const EXAMINABLES: Array[String] = [
	"fontaine",
	"enseigne_poele",
	"enseigne_tasse",
	"porte_accessoires",
	"porte_apothicaire",
	"trappe_cave",
	"caisses_pommes",
	"banc_haut",
]
const TEXTS := "res://data/texts/ville.json"
const DOORS: Array[String] = ["porte_snack", "porte_cafe", "porte_librairie", "porte_projection"]


func before_all() -> void:
	map_id = "ville_haute"
	# Les vues du plan (80 à 120 éléments par écran, CARTE.md 9.2) : l'arrivée du sentier, la rue
	# haute, la fontaine,
	# le haut de la grand-rue, le carrefour, le snack, le café, la librairie, le bas de la ville, la
	# rue basse.
	density = {
		"arrivée": [Vector3(6.0, 2.0, 13.0), 40, 140],
		"rue haute": [Vector3(20.0, 2.0, 13.0), 40, 140],
		"fontaine": [Vector3(30.0, 2.0, 13.0), 40, 140],
		"grand-rue": [Vector3(30.0, 1.0, 26.0), 40, 140],
		"carrefour": [Vector3(30.0, 1.0, 32.0), 40, 140],
		"snack": [Vector3(38.0, 1.0, 32.0), 40, 140],
		"café": [Vector3(22.0, 1.0, 32.0), 40, 140],
		"librairie": [Vector3(14.0, 1.0, 32.0), 40, 140],
		"bas de la ville": [Vector3(30.0, 0.0, 55.0), 40, 140],
		"rue basse": [Vector3(47.0, 0.0, 55.0), 40, 140],
	}
	walk_spots = [
		Vector3(4.0, 2.0, 13.0),
		Vector3(54.0, 2.0, 13.0),
		Vector3(30.0, 2.0, 11.0),
		Vector3(30.0, 1.0, 25.0),
		Vector3(7.0, 1.0, 32.0),
		Vector3(53.0, 1.0, 32.0),
		Vector3(30.0, 0.0, 45.0),
		Vector3(7.0, 0.0, 55.0),
		Vector3(53.0, 0.0, 55.0),
		Vector3(30.0, 0.0, 58.5),
	]
	min_walk_area = 1000.0
	min_checked_places = 900
	await super()


# --- Le plan -------------------------------------------------------------------------------------


func test_the_plan_has_what_the_town_needs() -> void:
	assert_eq(_lines("sortie").size(), 6, "le sentier, le marché, quatre portes de boutiques")
	assert_eq(
		_lines("marqueur").size(),
		7,
		"Spawn, from_sentier, from_ville_marche et quatre retours de boutiques"
	)
	assert_eq(
		_lines("point").size(),
		6,
		"snack_comptoir, cafe_porte, librairie_porte, projection_porte, …"
	)
	assert_eq(_lines("place").size(), 2, "carrefour, bas_de_ville")
	assert_eq(_lines("bati").size(), 14, "trois rangées de maisons et de boutiques")


func test_the_exits_lead_to_the_path_the_market_and_the_shops() -> void:
	var to_path := _map.get_node(^"Exits/vers_sentier") as MapExit
	assert_eq([to_path.target_map, to_path.target_marker], [&"sentier", &"from_ville_haute"])
	assert_eq(to_path.prompt, "", "on passe en marchant")
	var to_market := _map.get_node(^"Exits/vers_marche") as MapExit
	assert_eq(
		[to_market.target_map, to_market.target_marker], [&"ville_marche", &"from_ville_haute"]
	)
	assert_eq(to_market.prompt, "", "on passe en marchant")
	for door: String in DOORS:
		var exit := _map.get_node(NodePath("Exits/" + door)) as MapExit
		assert_eq(exit.prompt, "Entrer", "%s : par interaction" % door)
		assert_eq(exit.target_marker, &"from_ville_haute", "%s : marqueur d'arrivée" % door)
		assert_true(
			Map.exists(exit.target_map), "%s : la carte %s existe" % [door, exit.target_map]
		)
	assert_eq(_map.get_node(^"Exits").get_child_count(), 6, "six sorties, pas une de plus")


## On marche jusqu'à chaque sortie et chaque porte (la case devant elle est atteinte depuis Spawn).
func test_every_exit_and_door_is_reached_on_foot() -> void:
	for exit_node: Node in _map.get_node(^"Exits").get_children():
		var at := (exit_node as Node3D).global_position
		var found := false
		for dz: float in [-1.0, -0.5, 0.0, 0.5, 1.0, 1.5, 2.0]:
			for dx: float in [-1.0, 0.0, 1.0]:
				found = found or _is_reached(Vector3(at.x + dx, 0.0, at.z + dz))
		assert_true(found, "%s : on y marche depuis l'arrivée du sentier" % exit_node.name)
	for marker_name: StringName in _map.marker_names():
		assert_true(
			_is_reached(_map.marker(marker_name).global_position), "%s : on y marche" % marker_name
		)


## Le marqueur d'arrivée de chaque boutique, vu de l'autre carte : chacune ramène à sa porte.
func test_every_shop_leads_back_to_its_door() -> void:
	for door: String in DOORS:
		var exit := _map.get_node(NodePath("Exits/" + door)) as MapExit
		var inside := (load(Map.scene_path(exit.target_map)) as PackedScene).instantiate() as Map
		var back_exit: MapExit = null
		for candidate: Node in inside.get_node(^"Exits").get_children():
			if (candidate as MapExit).target_map == &"ville_haute":
				back_exit = candidate as MapExit
		assert_not_null(back_exit, "%s : une sortie vers la rue" % exit.target_map)
		if back_exit != null:
			assert_eq(
				back_exit.target_marker, StringName("from_" + String(exit.target_map)), "retour"
			)
			assert_not_null(
				_map.marker(back_exit.target_marker),
				"%s existe dans la rue" % back_exit.target_marker
			)
		inside.free()


## La salle de projection ne s'ouvre qu'au jour 5 (ACTE1.md, 1.3 : « Pas sans un adulte. »).
func test_the_projection_door_carries_the_day_five_condition() -> void:
	var door := _map.get_node(^"Exits/porte_projection") as MapExit
	assert_eq(int(door.get_meta(&"open_from_day", 0)), 5, "ouverte à partir du jour 5")
	var key := String(door.get_meta(&"closed_text_key", ""))
	assert_eq(key, "ville/projection_close", "le texte de la porte close")
	var texts: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TEXTS))
	assert_eq(String((texts["ville"] as Dictionary)["projection_close"]), "Pas sans un adulte.")
	for other: String in [
		"porte_snack", "porte_cafe", "porte_librairie", "vers_sentier", "vers_marche"
	]:
		assert_false(
			_map.get_node(NodePath("Exits/" + other)).has_meta(&"open_from_day"),
			"%s : sans condition" % other
		)


# --- Le relief
# ---------------------------------------------------------------------------------------


func test_the_town_climbs_by_three_terraces() -> void:
	assert_almost_eq(_ground.height_at(20.0, 13.0), 2.0, 0.05, "la rue haute, +2 m")
	assert_almost_eq(_ground.height_at(20.0, 32.0), 1.0, 0.05, "la rue du café, +1 m")
	assert_almost_eq(_ground.height_at(20.0, 55.0), 0.0, 0.05, "la rue basse, 0")
	assert_gte(_level_count(), 3, "au moins trois niveaux de relief")


## Les deux volées de la grand-rue sont de vrais escaliers : on les monte à pied, sans sauter ;
## ailleurs, entre deux
## terrasses, un muret de 1 m ferme le passage.
func test_the_grand_street_is_the_only_way_between_the_terraces() -> void:
	assert_true(_is_reached(Vector3(30.0, 1.5, 16.5)), "la volée du haut, à pied")
	assert_true(_is_reached(Vector3(30.0, 0.5, 34.5)), "la volée du bas, à pied")
	assert_true(_is_reached(Vector3(30.0, 0.0, 45.0)), "le bas de la grand-rue")
	for x: float in [8.0, 14.0, 44.0, 52.0]:
		assert_gt(
			absf(_ground.height_at(x, 15.5) - _ground.height_at(x, 16.5)),
			0.9,
			"x = %.0f : un muret de 1 m" % x
		)
	var mid_height := _ground.height_at(30.0, 16.5)
	assert_between(mid_height, 1.05, 1.95, "à mi-volée du haut")


func _level_count() -> int:
	var levels := {}
	for x in range(1, int(_map.size.x), 3):
		for z in range(1, int(_map.size.y), 3):
			levels[snappedf(_ground.height_at(float(x), float(z)), 0.5)] = true
	return levels.size()


# --- Les maisons, les décors et les images
# ----------------------------------------------------------


func test_every_house_of_the_plan_is_in_place() -> void:
	var houses := _map.get_node(^"Geometry/Houses")
	for words in _lines("bati"):
		var rect := _rect(words, 2)
		var found: Building = null
		for child: Node in houses.get_children():
			var building := child as Building
			if (
				building != null
				and building.facade.resource_path.get_file().get_basename() == String(words[7])
				and (
					Vector2(building.global_position.x, building.global_position.z).distance_to(
						rect.get_center()
					)
					< 0.01
				)
			):
				found = building
		assert_not_null(found, "bâtiment %s (%s)" % [words[1], words[7]])
		if found == null:
			continue
		assert_almost_eq(found.footprint.x, rect.size.x, 0.01, "%s : largeur du plan" % words[1])
		assert_almost_eq(found.footprint.y, rect.size.y, 0.01, "%s : profondeur du plan" % words[1])
		assert_almost_eq(found.ridge_height, float(words[6]), 0.01, "%s : faîte du plan" % words[1])
		assert_not_null(found.side_facade, "%s : un flanc" % words[1])
		assert_almost_eq(
			found.global_position.y,
			_ground.height_at(rect.get_center().x, rect.get_center().y),
			0.05,
			"%s : posé" % words[1]
		)


func test_the_decors_of_the_plan_are_there() -> void:
	var images := {}
	for element: Array in _elements:
		images[String(element[1]).get_file().get_basename()] = true
	for words in _lines("decor"):
		var found := false
		for suffix: String in ["", "_fg", "_forest", "_libre"]:
			found = found or images.has(words[1] + suffix)
		assert_true(found, "décor %s (ligne du plan)" % words[1])


func test_the_replacement_images_of_lot_r4_are_in_the_manifest_and_used() -> void:
	var manifest: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://tools/hd2d_manifest.json")
	)
	var listed := {}
	for entry: Dictionary in manifest["images"]:
		listed[String(entry["path"]).get_file().get_basename()] = String(entry.get("lot", ""))
	var images := {}
	for element: Array in _elements:
		images[String(element[1]).get_file().get_basename()] = true
	for image_name in R4_IMAGES:
		assert_eq(listed.get(image_name, ""), "R4", "%s au manifeste, lot R4" % image_name)
		assert_true(images.has(image_name), "%s posée dans la carte" % image_name)
		assert_true(
			(
				FileAccess.file_exists("res://assets/hd2d/props/%s.png" % image_name)
				or FileAccess.file_exists("res://assets/hd2d/buildings/%s.png" % image_name)
			),
			"%s existe" % image_name
		)
	assert_eq(listed.get("wall_stone_town", ""), "R4", "la matière de pierre de la ville")


## Un décor de plus de 1,2 m au sud d'un endroit où l'on marche est de premier plan : le réverbère
## double.
func test_the_street_lamp_is_a_foreground_panel() -> void:
	var lamp := _map.find_child("Reverbere", true, false) as DecorPanel
	assert_not_null(lamp, "le réverbère double du carrefour")
	if lamp != null:
		assert_true(lamp.foreground, "premier plan : il s'efface devant le joueur")
		assert_almost_eq(lamp.global_position.x, 25.4, 0.01)


# --- La vie, les objets à examiner
# ----------------------------------------------------------------------


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


## Les places que VIE.md et ACTE1.md citent par leur nom (ville_haute:carrefour, haut_de_rue,
## fontaine,
## snack_comptoir, porte_snack…).
func test_the_places_of_the_other_documents_exist() -> void:
	for place_name: String in [
		"haut_de_rue", "fontaine", "snack_comptoir", "cafe_porte", "projection_porte"
	]:
		assert_not_null(_map.get_node_or_null(NodePath("Life/Places/" + place_name)), place_name)
	assert_not_null(_map.get_node_or_null(^"Life/Areas/carrefour"), "carrefour")
	assert_not_null(_map.get_node_or_null(^"Exits/porte_snack"), "porte_snack")


func test_the_things_to_examine_have_their_text() -> void:
	var root := _map.get_node_or_null(^"Examine")
	assert_not_null(root, "les objets à examiner")
	if root == null:
		return
	assert_eq(root.get_child_count(), EXAMINABLES.size())
	var json := JSON.new()
	assert_eq(json.parse(FileAccess.get_file_as_string(TEXTS)), OK, "ville.json lisible")
	assert_eq(DialogueRunner.story_problem(json.data), "", "format des textes de l'histoire")
	for key in EXAMINABLES:
		var item := root.get_node_or_null(NodePath(key)) as Examinable
		assert_not_null(item, "objet %s" % key)
		if item == null:
			continue
		assert_eq(item.text_key, "ville_haute/" + key)
		assert_eq(item.texts_path, TEXTS)
		assert_false(item.text_value().is_empty(), "%s : un texte" % key)
		assert_true(item.is_in_group(&"interactable"), "%s : interactable" % key)
		assert_true(_is_reached(item.global_position), "%s : on s'en approche à pied" % key)


# --- Aucune lumière
# ------------------------------------------------------------------------------------


## Aucune lampe dans la carte : Atmosphere éclaire. Les images de lanterne et de réverbère du plan
## sont posées,
## sans lumière.
func test_the_map_carries_no_light() -> void:
	var own: Array[String] = []
	for light: Node in _map.find_children("*", "Light3D", true, false):
		if not String(_map.get_path_to(light)).contains("AtmosphereRig"):
			own.append(String(_map.get_path_to(light)))
	assert_eq(own, [] as Array[String], "aucune lampe dans la carte")
	assert_null(_map.get_node_or_null(^"Lights"), "pas de nœud de lumières")
	assert_eq(_map.light_preset, &"", "le préréglage du moment")
