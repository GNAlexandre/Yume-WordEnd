extends "res://tests/stubs/t2_map_test.gd"
## (T2) La salle des armes, sous l'entrepôt (src/world/maps/salle_des_armes/, plan de
## docs/lore/CARTE.md, 3.4) : base commune tests/stubs/t2_map_test.gd (plan, circulation, rien ne
## cache le joueur, draw calls, objets à examiner), plus l'escalier qui remonte vers la porte
## rivetée (vue de dedans, en haut des marches), les épées contre le mur nord, les deux piliers
## (premier plan qui s'efface devant le joueur) et aucune lumière de la carte (le préréglage
## « noir » d'E9 n'existe pas : celui des intérieurs, docs/DECISIONS.md).


func before_all() -> void:
	map_id = "salle_des_armes"
	expected_light_preset = ""
	await super()


func test_map_follows_the_contract_and_its_plan() -> void:
	check_contract()
	check_rooms_and_openings()
	assert_true(_map.interior, "un intérieur : préréglage « interieur » d'Atmosphere")
	assert_eq(
		_room.plan.lights, [] as Array[Dictionary], "crypte sans lumière : ni lampe ni cristal"
	)


func test_every_piece_of_furniture_of_the_plan_is_in_place() -> void:
	check_furniture()
	for pillar_name: String in ["crypt_pillar_1", "crypt_pillar_2"]:
		var pillar := _map.find_child(pillar_name, true, false) as DecorPanel
		assert_not_null(pillar, pillar_name)
		if pillar != null:
			assert_true(pillar.foreground, "%s : s'efface devant le joueur" % pillar_name)
	var door := _map.find_child("door_armory_inside_1", true, false) as Node3D
	assert_not_null(door, "la porte rivetée vue de dedans, en haut des marches")
	if door != null:
		assert_almost_eq(_map.to_local(door.global_position).x, 2.5, 0.01, "au-dessus des marches")


func test_markers_exits_and_named_points() -> void:
	check_markers_exits_points()
	var up := _map.get_node(^"Exits/remonter") as MapExit
	assert_eq(
		[up.target_map, up.target_marker, up.prompt],
		[&"entrepot_rdc", &"from_salle_des_armes", "Remonter"]
	)
	assert_true(up.needs_interaction(), "on remonte par l'invite, au pied des marches")


func test_every_room_is_reached_and_every_exit_is_within_reach() -> void:
	check_reach()


func test_walls_stop_a_walking_body_and_doors_let_it_through() -> void:
	check_doors_pass()
	assert_true(blocked(Vector3(2.5, 0.0, 2.0)), "les marches : on n'y monte pas à pied")
	assert_true(blocked(Vector3(7.0, 0.0, 0.6)), "le mur nord")


func test_no_wall_or_tall_furniture_hides_the_player() -> void:
	check_nothing_hides_the_player()


func test_each_view_stays_within_the_draw_call_budget() -> void:
	check_draw_calls()


func test_objects_to_examine_have_their_text() -> void:
	check_examinables(2)
