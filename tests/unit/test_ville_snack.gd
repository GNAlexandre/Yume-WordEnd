extends "res://tests/stubs/t2_map_test.gd"
## (CV) Le snack-bar de la ville haute (src/world/maps/ville_snack/, plan de docs/lore/CARTE.md,
## 9.4) : base
## commune tests/stubs/t2_map_test.gd (plan, circulation, rien ne cache le joueur, draw calls,
## objets à
## examiner), plus :
## - la salle de 7 × 5 m, ses murs de pierre apparente et son sol de dalles claires ;
## - le comptoir (plaque, poêle), l'étagère, les trois tabourets, la table lourde et son plateau (V1
##   : lard
##   épais, petit pain, soupe) ;
## - la porte du mur sud, qu'on franchit en marchant, et le retour vers la ville haute ;
## - les points et les places que le récit lit (ACTE1.md 3.3 : `snack_tabouret`, `snack_table`,
##   `snack_vendor`).

const EXTRA_PLACES: Array[String] = [
	"snack_vendor",
	"snack_tabouret_ouest",
	"snack_tabouret_est",
	"snack_table_nord",
	"snack_table_nord_est",
	"snack_entree",
]


func before_all() -> void:
	map_id = "ville_snack"
	expected_light_preset = "interieur"
	expected_region = "ville"
	texts_path = "res://data/texts/ville.json"
	await super()


func test_map_follows_the_contract_and_its_plan() -> void:
	check_contract()
	check_rooms_and_openings()
	assert_eq(_room.plan.rooms.size(), 1, "une seule salle")
	var room: Dictionary = _room.plan.rooms[0]
	assert_eq(room["id"], "salle")
	assert_eq(room["floor"], "floor_stone_town", "dalles claires")
	assert_eq(room["wall"], "wall_stone_inside", "pierre apparente")
	assert_eq(room["name"], "Salle du snack-bar", "le nom de la pièce n'est pas celui du café")
	# (QC-14, QC-15) Le soir, la plaque de cuisson et une applique éclairent la salle.
	assert_eq(_room.plan.lights.size(), 2, "la plaque de cuisson et l'applique")


func test_every_piece_of_furniture_of_the_plan_is_in_place() -> void:
	check_furniture()


func test_markers_exits_and_named_points() -> void:
	check_markers_exits_points()
	for point_name: String in ["snack_tabouret", "snack_table"]:
		assert_not_null(
			_map.get_node_or_null(NodePath("Life/Places/" + point_name)), "point %s" % point_name
		)


func test_the_door_leads_back_to_the_street_by_walking() -> void:
	var door := _map.get_node(^"Exits/vers_rue") as MapExit
	assert_eq([door.target_map, door.target_marker], [&"ville_haute", &"from_ville_snack"])
	assert_false(door.needs_interaction(), "on sort en marchant, par la porte du mur sud")
	assert_eq(_room.door_position(&"sortie"), Vector3(6.0, 0.0, 6.0), "la porte, au mur sud")
	var street := (load(Map.scene_path(&"ville_haute")) as PackedScene).instantiate() as Map
	var enter := street.get_node(^"Exits/porte_snack") as MapExit
	assert_eq([enter.target_map, enter.target_marker], [&"ville_snack", &"from_ville_haute"])
	assert_eq(enter.prompt, "Entrer")
	assert_not_null(street.marker(&"from_ville_snack"), "la rue a le marqueur d'arrivée")
	street.free()


func test_the_counter_the_shelf_the_stools_the_table_and_the_tray() -> void:
	var counter := _map.find_child("snack_counter_1", true, false) as InteriorPanel
	assert_not_null(counter, "le comptoir")
	if counter != null:
		assert_almost_eq(counter.global_position.x, 4.5, 0.01)
	assert_not_null(_map.find_child("snack_shelf_1", true, false), "l'étagère")
	assert_not_null(_map.find_child("snack_stools_1", true, false), "les tabourets")
	var table := _map.find_child("cafe_table_heavy_1", true, false) as Node3D
	assert_not_null(table, "la lourde table")
	var tray := _map.find_child("snack_meal_tray_1", true, false) as Node3D
	assert_not_null(tray, "le plateau du repas (lard, petit pain, soupe)")
	if tray != null and table != null:
		assert_almost_eq(tray.global_position.x, table.global_position.x, 0.01, "sur la table")
		assert_almost_eq(tray.global_position.y, 0.8, 0.01, "à la hauteur du plateau")


## Le serveur derrière son comptoir : entre l'étagère et le comptoir, 0,35 m de passage (il y tient,
## le joueur
## non) ; la place est face au sud, vers la salle.
func test_the_vendor_stands_behind_the_counter() -> void:
	var vendor := _map.get_node(^"Life/Places/snack_vendor") as Marker3D
	assert_not_null(vendor)
	assert_almost_eq(vendor.global_position.x, 4.5, 0.01)
	var counter := _map.find_child("snack_counter_1", true, false) as Node3D
	assert_lt(vendor.global_position.z, counter.global_position.z, "au nord du comptoir")
	assert_false(reached_near(flat(vendor.global_position), 0.2), "le joueur n'y passe pas")
	assert_almost_eq(
		-vendor.global_basis.z, Vector3.BACK, Vector3.ONE * 0.01, "il regarde la salle"
	)


func test_the_extra_life_places_are_named_and_reached() -> void:
	for place_name in EXTRA_PLACES:
		var place := _map.get_node_or_null(NodePath("Life/Places/" + place_name)) as Marker3D
		assert_not_null(place, "place %s" % place_name)
		if place == null or place_name == "snack_vendor":
			continue
		assert_true(reached_near(flat(place.global_position), 0.6), "%s : on y va" % place_name)


func test_every_room_is_reached_and_every_exit_is_within_reach() -> void:
	check_reach()


func test_walls_stop_a_walking_body_and_doors_let_it_through() -> void:
	check_doors_pass()


func test_no_wall_or_tall_furniture_hides_the_player() -> void:
	check_nothing_hides_the_player()


func test_each_view_stays_within_the_draw_call_budget() -> void:
	check_draw_calls()


func test_objects_to_examine_have_their_text() -> void:
	check_examinables(4)
