extends "res://tests/stubs/c1_exterior_test.gd"
## (CP) La carte port, le port de l'île n° 68 (src/world/maps/port/, plan de docs/lore/CARTE.md,
## section 6.2, écrite par tools/exterior_maps.py d'après tools/exterior_recipes/port.py). Base
## commune
## tests/stubs/c1_exterior_test.gd (plan, sorties, marqueurs, points, circulation à pied, rien ne
## cache
## le joueur, densité, sol nu, draw calls), plus :
## - les sorties : le sentier à l'ouest (à pied) ; la route de la ville (→ ville_marche) et la
##   passerelle
##   (→ transport_garde) sont posées dès que leur carte existe, sinon omises (un écriteau ferme la
## route) ;
## - le vide au nord, le quai de tôle au garde-fou, le poste d'amarrage ouvert, les trois bras
##   d'ancrage ;
## - le navire à quai : le grand panneau de coque (remplaçant, E7 le remplace), la passerelle, le
##   point
##   `navire_quai` à son pied ;
## - la colline ventée : trois terrasses (+1, +2, +3 m) montées à pied par trois rampes ;
## - les trois bâtiments du plan, à leur emprise ; les images du lot R3 et R7 au manifeste et
##   posées ;
## - les décors hauts qui passent en premier plan (le panneau aux flèches rouges, les lanternes de
##   quai) ;
## - les places de la vie en plus du plan, les objets à examiner et leurs textes ;
## - aucune lumière : Atmosphere éclaire (les lanternes de quai sont des images).

const EXTRA_PLACES: Array[String] = [
	"quai_ouest",
	"quai_est",
	"rue_ouest",
	"rue_centre",
	"rue_est",
	"bureau_porte",
	"cabane_porte",
	"sifflet_poste",
	"bitte_corbeau_1",
	"bitte_corbeau_2",
	"hangar_porte",
	"aire_ouest",
	"aire_est",
	"route_depart",
	"banc_colline",
	"colline_pied",
	"panneau_sud",
]
## Images des lots R3 et R7 (cahier n° 5, 5.6 et 9.1) que le port emploie et que le cahier n'a pas
## livrées.
const R3_IMAGES: Array[String] = [
	"mooring_arm_open",
	"steam_whistle",
	"capstan",
	"signpost_port",
	"wind_fence",
	"cargo_cart_a",
	"cargo_cart_b",
	"port_house_b",
]
const EXAMINABLES: Array[String] = [
	"panneau",
	"bord_du_vide",
	"guichet",
	"longue_vue",
	"bras_d_ancrage",
	"sifflet",
	"caisses_cristaux",
	"manche_a_air",
]
const TEXTS := "res://data/texts/port.json"


func before_all() -> void:
	map_id = "port"
	# Les vues du plan (60 à 100 éléments par écran, CARTE.md 6.2) : le quai ouest et le bureau,
	# le
	# poste d'amarrage, le bord du vide, le hangar, la rue et le panneau, l'aire-port, la colline,
	# la
	# route de la ville. Un peu moins sur la colline nue.
	density = {
		"quai_ouest": [Vector3(12.0, 0.0, 12.5), 50, 125],
		"accostage": [Vector3(30.0, 0.0, 11.5), 40, 125],
		"bord_du_vide": [Vector3(17.5, 0.0, 6.5), 40, 125],
		"hangar": [Vector3(46.0, 0.0, 12.5), 50, 125],
		"panneau": [Vector3(6.0, 0.0, 19.5), 40, 125],
		"rue": [Vector3(30.0, 0.0, 17.0), 40, 125],
		"aire_port": [Vector3(30.0, 0.0, 24.0), 40, 125],
		"aire_ouest": [Vector3(12.0, 0.0, 26.0), 40, 125],
		"colline": [Vector3(62.0, 1.0, 22.0), 40, 125],
		"sommet": [Vector3(65.0, 3.0, 12.2), 40, 125],
		"route_ville": [Vector3(62.0, 0.0, 31.5), 40, 125],
	}
	walk_spots = [
		Vector3(4.0, 0.0, 17.0),
		Vector3(17.5, 0.0, 6.4),
		Vector3(32.5, 0.0, 7.6),
		Vector3(30.0, 0.0, 9.5),
		Vector3(50.0, 0.0, 17.0),
		Vector3(30.0, 0.0, 23.5),
		Vector3(61.0, 0.5, 25.5),
		Vector3(64.0, 1.0, 25.8),
		Vector3(67.0, 2.0, 20.5),
		Vector3(65.0, 3.0, 12.2),
		Vector3(62.0, 0.0, 32.0),
		Vector3(67.0, 0.0, 32.0),
	]
	expected_camera_bounds = Rect2(10, 6, 50, 24)
	min_walk_area = 1500.0
	min_checked_places = 1200
	await super()


# --- Le plan
# -------------------------------------------------------------------------------------


func test_the_plan_has_what_the_chapter_needs() -> void:
	assert_eq(_lines("sortie").size(), 3, "le sentier, la ville, la passerelle")
	assert_eq(
		_lines("marqueur").size(), 4, "Spawn, from_sentier, from_ville_marche, from_transport_garde"
	)
	assert_eq(
		_lines("point").size(),
		7,
		"bord_du_vide, accostage, navire_quai, panneau, guichet, colline_sommet, charrettes"
	)
	assert_eq(_lines("place").size(), 2, "accostage, aire_port")
	assert_eq(_lines("bati").size(), 3, "le bureau, la cabane du gardien, le hangar")


func test_the_exit_to_the_path_is_on_foot_and_the_others_wait_for_their_map() -> void:
	var to_path := _map.get_node(^"Exits/vers_sentier") as MapExit
	assert_eq([to_path.target_map, to_path.target_marker], [&"sentier", &"from_port"])
	assert_eq(to_path.prompt, "", "on passe en marchant")
	var back := _map.get_node(^"Exits/vers_sentier/CollisionShape3D") as CollisionShape3D
	assert_almost_eq(back.global_position.x, 0.3, 0.05, "au bord ouest de la rue")
	assert_almost_eq(back.global_position.z, 17.0, 0.05, "au milieu de la rue (z 14 → 20)")
	# La route de la ville et la passerelle : leur carte n'existe pas encore (ville_marche,
	# transport_garde).
	var waits_for_the_town := not Map.exists(&"ville_marche")
	assert_eq(_map.get_node_or_null(^"Exits/vers_ville") == null, waits_for_the_town)
	var waits_for_the_ship := not Map.exists(&"transport_garde")
	assert_eq(_map.get_node_or_null(^"Exits/passerelle") == null, waits_for_the_ship)
	if waits_for_the_town:
		var sign_node := _map.find_child("EcriteauVille", true, false)
		assert_not_null(sign_node, "la route de la ville est fermée d'un écriteau")
		if sign_node != null:
			var reader := sign_node.get_node_or_null(^"Reader") as Area3D
			assert_not_null(reader, "on le lit")
	assert_eq(
		_map.get_node(^"Exits").get_child_count(),
		1 + int(not waits_for_the_town) + int(not waits_for_the_ship),
		"les sorties dont la carte existe, pas une de plus"
	)
	# Le marqueur d'arrivée du sentier et ceux que les autres cartes viseront.
	for marker_name: StringName in [&"from_sentier", &"from_ville_marche", &"from_transport_garde"]:
		assert_not_null(_map.marker(marker_name), "marqueur %s" % marker_name)


# --- Le vide, le quai, le navire -------------------------------------------------------------


func test_the_island_ends_in_the_void_to_the_north() -> void:
	for x: float in [5.0, 20.0, 30.0, 45.0, 60.0, 68.0]:
		assert_false(_ground.is_walkable(x, 2.0), "le vide au nord, x = %.0f" % x)
	assert_true(_ground.is_walkable(20.0, 6.0), "le quai se marche jusqu'à son garde-fou")
	assert_almost_eq(_ground.height_at(20.0, 10.0), 0.0, 0.05, "le quai est au niveau du sol")
	var sky := _map.get_node_or_null(^"Geometry/Sky")
	assert_not_null(sky, "des îles, des nuages et des dirigeables au loin")
	if sky != null:
		assert_gt(sky.get_child_count(), 10)
		var far_ships := 0
		for child: Node in sky.get_children():
			if String((child as Node).name).begins_with("Vide") and child is DecorPanel:
				var panel := child as DecorPanel
				if panel.texture.resource_path.contains("airship_far"):
					far_ships += 1
		assert_gte(far_ships, 1, "un dirigeable de passage")


func test_the_berth_has_three_arms_a_gangway_and_the_ship_hull() -> void:
	var quay := _map.get_node(^"Geometry/Quay")
	for arm_name: String in ["BrasAncrage1", "BrasAncrage2", "BrasAncrage3"]:
		var arm := quay.get_node_or_null(NodePath(arm_name)) as DecorPanel
		assert_not_null(arm, arm_name)
		if arm != null:
			assert_true(
				arm.texture.resource_path.ends_with("mooring_arm_open.png"),
				"%s : bras déployé" % arm_name
			)
	var arm_xs: Array[float] = []
	for arm_name: String in ["BrasAncrage1", "BrasAncrage2", "BrasAncrage3"]:
		arm_xs.append((quay.get_node(NodePath(arm_name)) as Node3D).global_position.x)
	assert_eq(arm_xs, [23.5, 29.5, 36.5] as Array[float], "x des bras d'ancrage du plan")
	var deck := quay.get_node_or_null(^"Passerelle") as Building
	assert_not_null(deck, "la passerelle (un plancher du quai à la coque)")
	if deck != null:
		assert_almost_eq(deck.global_position.x, 32.5, 0.01, "au droit du plan (x 32,5)")
		assert_lt(deck.global_position.z, 6.4, "elle va vers le navire, au nord")
	var hull := _map.get_node_or_null(^"Geometry/Ship/TransportGarde") as DecorPanel
	assert_not_null(hull, "le grand panneau de coque du transport de la Garde")
	if hull != null:
		var size := Vector2(hull.texture.get_size()) / 96.0
		assert_eq(size, Vector2(16.0, 7.0), "16 × 7 m (CARTE.md 6.2)")
		assert_true(hull.texture.resource_path.ends_with("ships/garde_transport_side.png"))
		assert_almost_eq(hull.global_position.x, 30.0, 0.01, "de x 22 à 38")
		assert_lt(hull.global_position.y, 0.0, "la quille sous le niveau du quai")
		assert_null(hull.get_node_or_null(^"Collision"), "libre : sans collision")


func test_the_named_point_at_the_foot_of_the_gangway() -> void:
	var point := _map.get_node(^"Life/Places/navire_quai") as Marker3D
	assert_almost_eq(point.global_position.x, 32.5, 0.01)
	assert_almost_eq(point.global_position.z, 7.6, 0.01)
	assert_true(_is_reached(point.global_position), "on y va à pied")
	var gangway := _map.get_node(^"Geometry/Quay/Passerelle") as Node3D
	assert_lt(
		absf(point.global_position.x - gangway.global_position.x), 1.0, "au pied de la passerelle"
	)
	# On monte sur la passerelle (collision du plancher) depuis le quai : le bord du vide (z < 5)
	# est fermé, on n'entre
	# pas dans la coque ; la scène y fait descendre Willem sans le contrôle.
	var capsule := CapsuleShape3D.new()
	capsule.radius = PLAYER_RADIUS
	capsule.height = PLAYER_HEIGHT
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = 1
	query.transform = Transform3D(
		Basis.IDENTITY, Vector3(32.5, 0.08 + 0.25 + PLAYER_HEIGHT / 2.0, 6.0)
	)
	var inside: Array[String] = []
	for hit: Dictionary in _space.intersect_shape(query, 16):
		if hit["collider"] != _ground:
			inside.append(String(_map.get_path_to(hit["collider"] as Node)))
	assert_eq(inside, [] as Array[String], "la capsule du joueur passe sur la passerelle")


# --- Les bâtiments, les décors et les images ----------------------------------------------------


func test_every_building_of_the_plan_is_in_place() -> void:
	var houses := _map.get_node(^"Geometry/Houses")
	for words in _lines("bati"):
		var rect := _rect(words, 2)
		var found: Building = null
		for child: Node in houses.get_children():
			var building := child as Building
			if (
				building != null
				and building.facade.resource_path.get_file().get_basename() == String(words[7])
			):
				found = building
		assert_not_null(found, "bâtiment %s (%s)" % [words[1], words[7]])
		if found == null:
			continue
		assert_almost_eq(
			Vector2(found.global_position.x, found.global_position.z),
			rect.get_center(),
			Vector2.ONE * 0.01,
			"%s : au centre de son emprise" % words[1]
		)
		assert_almost_eq(found.footprint.x, rect.size.x, 0.01, "%s : largeur du plan" % words[1])
		assert_almost_eq(found.ridge_height, float(words[6]), 0.01, "%s : faîte du plan" % words[1])
		assert_not_null(found.side_facade, "%s : un flanc" % words[1])
	# Rien de haut au sud d'où l'on marche : les trois sont au nord de la rue (z < 14).
	for words in _lines("bati"):
		assert_lt(_rect(words, 2).end.y, 14.0, "%s : au nord de la rue" % words[1])


func test_the_decors_of_the_plan_are_there() -> void:
	var images := {}
	for element: Array in _elements:
		images[String(element[1]).get_file().get_basename()] = true
	var aliases := {"wind_sock": "windsock_wave", "gangway": "gangway_quay"}
	for words in _lines("decor"):
		var found := false
		for suffix: String in ["", "_fg", "_forest", "_libre"]:
			found = found or images.has(words[1] + suffix)
		if aliases.has(words[1]):
			found = found or images.has(aliases[words[1]])
		# La passerelle est un plancher (Building : matière de ses murs), le navire une image.
		found = found or (words[1] == "gangway" and _map.has_node(^"Geometry/Quay/Passerelle"))
		assert_true(found, "décor %s (ligne du plan)" % words[1])


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
	for image_name in R3_IMAGES:
		assert_eq(listed.get(image_name, ""), "R3", "%s au manifeste, lot R3" % image_name)
		assert_true(images.has(image_name), "%s posée dans la carte" % image_name)
	assert_eq(listed.get("garde_transport_side", ""), "R7", "le navire : lot R7 (E7)")
	assert_true(images.has("garde_transport_side"), "garde_transport_side posée")
	assert_true(listed.has("port_house_b_side"), "le flanc de la cabane")
	for path: String in [
		"res://assets/hd2d/props/mooring_arm_open.png",
		"res://assets/hd2d/props/signpost_port.png",
		"res://assets/hd2d/buildings/port_house_b.png",
		"res://assets/hd2d/ships/garde_transport_side.png",
	]:
		assert_true(FileAccess.file_exists(path), "%s existe" % path)


## Ce qui dépasse 1,2 m au sud d'un endroit où l'on marche passe en premier plan : le panneau aux
## flèches
## rouges, les lanternes de quai, la charrette chargée.
func test_tall_decors_where_one_walks_are_foreground_panels() -> void:
	for node_name: String in ["PanneauFlechesRouges", "LanterneQuai1", "LanterneQuai2"]:
		var panel := _map.find_child(node_name, true, false) as DecorPanel
		assert_not_null(panel, node_name)
		if panel != null:
			assert_true(
				panel.foreground, "%s : premier plan, il s'efface devant le joueur" % node_name
			)
	var sign_panel := _map.find_child("PanneauFlechesRouges", true, false) as DecorPanel
	assert_almost_eq(sign_panel.global_position.x, 6.0, 0.01, "le panneau du plan (6 ; 21,2)")
	assert_almost_eq(sign_panel.global_position.z, 21.2, 0.01)
	assert_true(
		sign_panel.texture.resource_path.ends_with("signpost_port.png"),
		"le panneau aux flèches rouges"
	)


# --- La colline ventée
# ------------------------------------------------------------------------------


func test_the_windy_hill_has_three_terraces_reached_on_foot() -> void:
	assert_almost_eq(_ground.height_at(59.0, 12.0), 1.0, 0.05, "première terrasse, +1 m")
	assert_almost_eq(_ground.height_at(66.0, 19.0), 2.0, 0.55, "deuxième terrasse (z 16 → 22)")
	assert_almost_eq(_ground.height_at(65.0, 12.0), 3.0, 0.05, "le sommet, +3 m")
	assert_almost_eq(_ground.height_at(56.0, 12.0), 0.0, 0.05, "la rue au pied de la colline")
	for spot: Vector3 in [
		Vector3(61.0, 0.5, 25.5),
		Vector3(64.0, 1.0, 25.8),
		Vector3(67.0, 2.0, 20.5),
		Vector3(65.0, 3.0, 12.2)
	]:
		assert_true(_is_reached(spot), "%s : on monte à pied, sans sauter" % spot)
	var sock := _map.find_child("MancheAAir", true, false) as DecorPanel
	assert_not_null(sock, "la manche à air du sommet")
	if sock != null:
		assert_gt(sock.frames, 1, "elle claque au vent")
		assert_almost_eq(sock.global_position.y, 3.0, 0.05, "posée au sommet (+3 m)")


func test_the_street_and_the_yard_are_walkable_on_the_flat() -> void:
	for spot: Vector3 in [
		Vector3(30.0, 0.0, 17.0), Vector3(30.0, 0.0, 24.0), Vector3(40.0, 0.0, 33.0)
	]:
		assert_almost_eq(_ground.height_at(spot.x, spot.z), 0.0, 0.05)
		assert_true(_is_reached(spot), "%s" % spot)


# --- La vie
# ---------------------------------------------------------------------------------------


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


## Les places que VIE.md et ACTE1.md citent par leur nom (port:charrettes, port:guichet,
## port:panneau…).
func test_the_places_of_the_other_documents_exist() -> void:
	for place_name: String in [
		"charrettes",
		"aire_port",
		"guichet",
		"colline_sommet",
		"accostage",
		"panneau",
		"bord_du_vide",
		"navire_quai",
	]:
		var found := _map.get_node_or_null(NodePath("Life/Places/" + place_name))
		if found == null:
			found = _map.get_node_or_null(NodePath("Life/Areas/" + place_name))
		assert_not_null(found, place_name)


func test_the_things_to_examine_have_their_text() -> void:
	var root := _map.get_node_or_null(^"Examine")
	assert_not_null(root, "les objets à examiner")
	if root == null:
		return
	assert_eq(root.get_child_count(), EXAMINABLES.size())
	var json := JSON.new()
	assert_eq(json.parse(FileAccess.get_file_as_string(TEXTS)), OK, "port.json lisible")
	assert_eq(DialogueRunner.story_problem(json.data), "", "format des textes de l'histoire")
	for key in EXAMINABLES:
		var item := root.get_node_or_null(NodePath(key)) as Examinable
		assert_not_null(item, "objet %s" % key)
		if item == null:
			continue
		assert_eq(item.text_key, "port/" + key)
		assert_eq(item.texts_path, TEXTS)
		assert_false(item.text_value().is_empty(), "%s : un texte" % key)
		assert_true(item.is_in_group(&"interactable"), "%s : interactable" % key)
		assert_true(_is_reached(item.global_position), "%s : on s'en approche à pied" % key)
	var sign_text := (
		(
			(JSON.parse_string(FileAccess.get_file_as_string(TEXTS)) as Dictionary)["port"]
			as Dictionary
		)["panneau"]
		as String
	)
	assert_string_contains(sign_text, "deux mille", "le panneau : la ville à 2 000 marmer")
	assert_string_contains(sign_text, "cinq cents", "le panneau : l'entrepôt à 500 marmer")


# --- Aucune lumière
# ---------------------------------------------------------------------------------


## Aucune lampe dans la carte : Atmosphere éclaire. Les lanternes de quai du plan sont l'image
## `dock_lamp`
## (elle brille la nuit par son `glow`, comme la lanterne du café du village) : aucune Light3D,
## aucun
## nœud `Lights`, aucun autre décor de lampe.
func test_the_map_carries_no_light() -> void:
	var own: Array[String] = []
	for light: Node in _map.find_children("*", "Light3D", true, false):
		if not String(_map.get_path_to(light)).contains("AtmosphereRig"):
			own.append(String(_map.get_path_to(light)))
	assert_eq(own, [] as Array[String], "aucune lampe dans la carte")
	assert_null(_map.get_node_or_null(^"Lights"), "pas de nœud de lumières")
	for element: Array in _elements:
		var image: String = element[1]
		var file := image.get_file().get_basename()
		for lamp: String in ["lampadaire", "torch", "crystal_lamp"]:
			assert_false(file.contains(lamp), "%s : un décor de lampe" % image)
		if file.contains("lamp"):
			assert_true(
				file.begins_with("dock_lamp"), "%s : une lanterne de quai, rien d'autre" % image
			)


func test_the_map_light_is_left_to_atmosphere() -> void:
	assert_eq(_map.light_preset, &"", "le préréglage du moment")
