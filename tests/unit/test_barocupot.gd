extends "res://tests/stubs/t2_map_test.gd"
## (E7) Le Barocupot, à bord (src/world/maps/barocupot/, plan de docs/lore/CARTE.md, 6.3 ; scène
## 8.7 d'ACTE1.md) : base commune tests/stubs/t2_map_test.gd (plan, circulation, rien ne cache le
## joueur, draw calls, objets à examiner), plus :
## - la salle du conseil de guerre, le sas de l'échelle et la coursive, en tôle et planches de bord
##   (lot L) ;
## - la table aux cartes, trois chaises lourdes, le petit service à thé posé sur la table, le meuble
##   à cartes, l'échelle du sas, deux hublots, l'aile peinte, le porte-voix, les tuyaux ;
## - la sortie par l'échelle (« Remonter sur le pont », vers la cour de l'entrepôt) ;
## - les points que la scène lit : Spawn dans la coursive, conseil_chtholly, conseil_limeskin.


func before_all() -> void:
	map_id = "barocupot"
	expected_light_preset = "interieur"
	expected_region = "ciel"
	texts_path = "res://data/texts/barocupot.json"
	await super()


func test_map_follows_the_contract_and_its_plan() -> void:
	check_contract()
	check_rooms_and_openings()
	assert_eq(_room.plan.rooms.size(), 3, "le conseil, le sas, la coursive")
	for room: Dictionary in _room.plan.rooms:
		assert_eq(room["floor"], "floor_ship_planks", "%s : plancher de bord" % room["id"])
		assert_eq(room["wall"], "wall_ship_plate", "%s : cloison de tôle" % room["id"])
	assert_eq(_room.plan.room_at(Vector3(4.0, 0.0, 3.0)), &"conseil")
	assert_eq(_room.plan.room_at(Vector3(7.0, 0.0, 6.0)), &"coursive")
	for room: Dictionary in _room.plan.rooms:
		if room["id"] == "conseil":
			assert_eq(room["name"], "Salle du conseil de guerre")


func test_every_piece_of_furniture_of_the_plan_is_in_place() -> void:
	check_furniture()


func test_the_war_table_the_tea_and_the_chairs() -> void:
	var table := _map.find_child("war_table_1", true, false) as Node3D
	assert_not_null(table, "la table aux cartes")
	var tea := _map.find_child("tea_set_tiny_1", true, false) as Node3D
	assert_not_null(tea, "le thé dans des tasses minuscules")
	if table != null and tea != null:
		assert_almost_eq(tea.global_position.x, table.global_position.x, 0.01, "sur la table")
		assert_almost_eq(tea.global_position.y, 0.8, 0.01, "à la hauteur du plateau")
	var chairs := 0
	for node: Node in _map.find_children("war_chair_*", "", true, false):
		chairs += 1 if node is DecorPanel else 0
	assert_eq(chairs, 3, "trois chaises lourdes (Limeskin reste debout)")
	assert_not_null(_map.find_child("ship_ladder_1", true, false), "l'échelle vers le pont")


func test_markers_exits_and_named_points() -> void:
	check_markers_exits_points()
	var ladder := _map.get_node(^"Exits/echelle") as MapExit
	assert_eq([ladder.target_map, ladder.target_marker], [&"entrepot", &"from_barocupot"])
	assert_eq(ladder.prompt, "Remonter sur le pont")
	for point_name: String in ["conseil_chtholly", "conseil_limeskin", "coursive"]:
		var point := _map.get_node_or_null(NodePath("Life/Places/" + point_name)) as Marker3D
		assert_not_null(point, "point %s" % point_name)
		if point != null:
			assert_true(reached_near(flat(point.global_position), 0.6), "%s : on y va" % point_name)
	var spawn := _map.marker(&"Spawn")
	assert_eq(_room.plan.room_at(spawn.global_position), &"coursive", "réveil dans la coursive")


func test_every_room_is_reached_and_every_exit_is_within_reach() -> void:
	check_reach()


func test_walls_stop_a_walking_body_and_doors_let_it_through() -> void:
	check_doors_pass()


func test_no_wall_or_tall_furniture_hides_the_player() -> void:
	check_nothing_hides_the_player()


func test_each_view_stays_within_the_draw_call_budget() -> void:
	check_draw_calls()


func test_objects_to_examine_have_their_text() -> void:
	check_examinables(5)
