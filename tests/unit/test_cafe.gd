extends "res://tests/stubs/t2_map_test.gd"
## (C2) Le café du village (src/world/maps/cafe/, plan de docs/lore/CARTE.md, 5.3) : base commune
## tests/stubs/t2_map_test.gd (plan, circulation, rien ne cache le joueur, draw calls, objets à examiner),
## plus la salle et son arrière-boutique (le rideau rayé sur la cloison), le comptoir (vitrine à gâteaux, étagère
## aux bouteilles), les deux tables de deux chaises et celle des buveurs, les verres de jus de la table des
## aînées (jour 9), la sortie vers le village, la clochette et les places de la vie en plus du plan.


func before_all() -> void:
	map_id = "cafe"
	expected_light_preset = "interieur"
	expected_region = "village"
	texts_path = "res://data/texts/village.json"
	await super()


func test_map_follows_the_contract_and_its_plan() -> void:
	check_contract()
	check_rooms_and_openings()
	assert_eq(_room.plan.rooms.size(), 2, "la salle et l'arrière-boutique")


func test_every_piece_of_furniture_of_the_plan_is_in_place() -> void:
	check_furniture()


func test_markers_exits_and_named_points() -> void:
	check_markers_exits_points()
	for point_name: String in ["comptoir", "table_fees", "table_buveurs", "arriere"]:
		assert_not_null(
			_map.get_node_or_null(NodePath("Life/Places/" + point_name)), "point %s" % point_name
		)


func test_the_door_leads_back_to_the_village_by_walking() -> void:
	var door := _map.get_node(^"Exits/vers_village") as MapExit
	assert_eq([door.target_map, door.target_marker], [&"village", &"from_cafe"])
	assert_false(door.needs_interaction(), "on sort en marchant, par la porte du mur sud")
	assert_eq(_room.door_position(&"sortie"), Vector3(4.75, 0.0, 9.0), "la porte, au mur sud")
	if Map.exists(&"village"):
		var village := (load(Map.scene_path(&"village")) as PackedScene).instantiate() as Map
		var enter := village.get_node(^"Exits/porte_cafe") as MapExit
		assert_eq([enter.target_map, enter.target_marker], [&"cafe", &"from_village"])
		assert_not_null(village.marker(&"from_cafe"), "le village a le marqueur d'arrivée")
		village.free()


func test_the_counter_the_tables_and_the_juice() -> void:
	var counter := _map.find_child("cafe_counter_1", true, false) as InteriorPanel
	assert_not_null(counter, "le comptoir")
	if counter != null:
		assert_almost_eq(counter.global_position.x, 4.0, 0.01)
	assert_not_null(_map.find_child("cafe_cake_case_1", true, false), "la vitrine à gâteaux")
	assert_not_null(_map.find_child("cafe_bottle_shelf_1", true, false), "l'étagère aux bouteilles")
	assert_not_null(_map.find_child("crystal_pendant_1", true, false), "la suspension à cristal")
	for chair_place: String in ["salle_chaise_a01", "salle_chaise_a02", "salle_chaise_b01", "salle_chaise_b02"]:
		assert_not_null(_map.get_node_or_null(NodePath("Life/Places/" + chair_place)), chair_place)
	var tables := 0
	var chairs := 0
	for entry: Array in decors():
		match String(entry[1]):
			"cafe_table_heavy":
				tables += 1
			"chair_wood", "chair_wood_back":
				chairs += 1
	assert_eq(tables, 2, "deux tables carrées")
	assert_eq(chairs, 4, "deux chaises à chacune")
	# Les verres de jus (VEX : offerts « pour la maison ») sont sur la table des aînées (x = 6,2).
	var juice := _map.find_child("juice_glasses_1", true, false) as Node3D
	assert_not_null(juice, "les verres de jus")
	if juice != null:
		assert_almost_eq(juice.global_position.x, 6.2, 0.01, "sur la table des aînées")
		assert_almost_eq(juice.global_position.y, 0.8, 0.01, "à la hauteur du plateau")


func test_the_backroom_curtain_is_the_door_between_the_two_rooms() -> void:
	var curtains := 0
	for opening: Dictionary in _room.plan.doors:
		if String(opening["image"]) == "door_backroom":
			curtains += 1
			assert_almost_eq(float(opening["line"]), 8.5, 0.01, "sur la cloison, x = 8,5")
			assert_almost_eq(float(opening["center"]), 3.0, 0.01, "à z = 3")
	assert_eq(curtains, 1, "le rideau rayé de l'arrière-boutique")


func test_the_extra_life_places_are_named() -> void:
	for place_name: String in ["comptoir_arriere", "entree"]:
		var place := _map.get_node_or_null(NodePath("Life/Places/" + place_name)) as Marker3D
		assert_not_null(place, "place %s" % place_name)
		if place != null:
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
	check_examinables(7)
