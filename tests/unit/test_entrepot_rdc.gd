extends "res://tests/stubs/t2_map_test.gd"
## (T2) Le rez-de-chaussée de l'entrepôt des fées (src/world/maps/entrepot_rdc/, plan de
## docs/lore/CARTE.md, 3.1) : base commune tests/stubs/t2_map_test.gd (plan, circulation, rien ne
## cache le joueur, draw calls, objets à examiner), plus la correspondance des portes avec le
## dehors (dedans = dehors − (29, 11) : porte d'entrée en (13 ; 15), porte de service en
## (1 ; 9,5)), l'escalier vers l'étage, la porte rivetée vers la salle des armes (fermée : on
## l'ouvre par son invite) et la place sous le haut de l'escalier (on n'y entre pas).


func before_all() -> void:
	map_id = "entrepot_rdc"
	expected_light_preset = "interieur"
	await super()


func test_map_follows_the_contract_and_its_plan() -> void:
	check_contract()
	check_rooms_and_openings()


func test_every_piece_of_furniture_of_the_plan_is_in_place() -> void:
	check_furniture()
	var mirror := _map.find_child("mirror_large_1", true, false) as InteriorPanel
	assert_not_null(mirror, "grand miroir sur le mur ouest des bains")
	if mirror != null:
		assert_true(mirror.keep_orientation, "tourné vers l'est")
		assert_almost_eq(mirror.position.z, 13.0, 0.01, "en z = 13 (plan)")


func test_markers_exits_and_named_points() -> void:
	check_markers_exits_points()


func test_doors_match_the_outside() -> void:
	assert_eq(_room.door_position(&"entree"), Vector3(13.0, 0.0, 15.0), "porte d'entrée")
	assert_eq(_room.door_position(&"service"), Vector3(1.0, 0.0, 9.5), "porte de service")
	assert_eq(_room.door_position(&"armes"), Vector3(21.5, 0.0, 1.0), "porte rivetée, au nord")
	var front := _map.get_node(^"Exits/vers_dehors") as MapExit
	var back := _map.get_node(^"Exits/vers_arriere") as MapExit
	assert_false(front.needs_interaction(), "on sort par l'entrée en marchant")
	assert_false(back.needs_interaction(), "et par la porte de service")
	if Map.exists(&"entrepot"):
		assert_eq([front.target_map, front.target_marker], [&"entrepot", &"from_entrepot_rdc"])
		assert_eq(
			[back.target_map, back.target_marker], [&"entrepot", &"from_entrepot_rdc_service"]
		)
	else:
		# Provisoire : la carte du dehors (lot T1) n'est pas encore là (docs/DECISIONS.md, T2).
		for exit: MapExit in [front, back]:
			assert_eq(exit.target_map, &"essai", "%s : provisoirement vers l'essai" % exit.name)
	var up := _map.get_node(^"Exits/vers_etage") as MapExit
	assert_eq(
		[up.target_map, up.target_marker, up.prompt],
		[&"entrepot_etage", &"from_entrepot_rdc", "Monter"]
	)
	var crypt := _map.get_node(^"Exits/vers_armes") as MapExit
	assert_eq(
		[crypt.target_map, crypt.target_marker, crypt.prompt],
		[&"salle_des_armes", &"from_entrepot_rdc", "Ouvrir"]
	)
	assert_true(blocked(Vector3(17.5, 0.0, 1.9)), "sous le haut de l'escalier : on n'y entre pas")


func test_every_room_is_reached_and_every_exit_is_within_reach() -> void:
	check_reach()


func test_walls_stop_a_walking_body_and_doors_let_it_through() -> void:
	check_doors_pass()


func test_no_wall_or_tall_furniture_hides_the_player() -> void:
	check_nothing_hides_the_player()


func test_each_view_stays_within_the_draw_call_budget() -> void:
	check_draw_calls()


func test_objects_to_examine_have_their_text() -> void:
	check_examinables(25)
