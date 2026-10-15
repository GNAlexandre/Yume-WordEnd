extends "res://tests/stubs/t2_map_test.gd"
## (C2) La maison Limashenka (src/world/maps/maison_limashenka/, plan de docs/lore/CARTE.md, 5.3) : base commune
## tests/stubs/t2_map_test.gd (plan, circulation, rien ne cache le joueur, draw calls, objets à examiner), plus
## le vestibule et le salon, l'horloge à peigne doré (le point `horloge` où Willem la répare au jour 11 ;
## ses images : fermée, ouverte, son balancier, au manifeste), le canapé et le fauteuil sous un drap, la sortie
## vers le village et ce que la carte garde pour le récit (ACTE1.md 11.3).


func before_all() -> void:
	map_id = "maison_limashenka"
	expected_light_preset = "interieur"
	expected_region = "village"
	texts_path = "res://data/texts/village.json"
	await super()


func test_map_follows_the_contract_and_its_plan() -> void:
	check_contract()
	check_rooms_and_openings()
	assert_eq(_room.plan.rooms.size(), 2, "le vestibule et le salon")


func test_every_piece_of_furniture_of_the_plan_is_in_place() -> void:
	check_furniture()
	assert_not_null(_map.find_child("rug_salon_1", true, false), "le tapis du salon")


func test_markers_exits_and_named_points() -> void:
	check_markers_exits_points()
	for point_name: String in ["horloge", "rami", "canape"]:
		assert_not_null(
			_map.get_node_or_null(NodePath("Life/Places/" + point_name)), "point %s" % point_name
		)


func test_the_door_leads_back_to_the_village() -> void:
	var door := _map.get_node(^"Exits/vers_village") as MapExit
	assert_eq([door.target_map, door.target_marker], [&"village", &"from_maison_limashenka"])
	assert_false(door.needs_interaction(), "on sort en marchant")
	if Map.exists(&"village"):
		var village := (load(Map.scene_path(&"village")) as PackedScene).instantiate() as Map
		var enter := village.get_node(^"Exits/porte_limashenka") as MapExit
		assert_eq([enter.target_map, enter.target_marker], [&"maison_limashenka", &"from_village"])
		assert_eq(int(enter.get_meta(&"open_from_day", 0)), 11, "ouverte au jour 11")
		village.free()


## L'horloge est sur le mur nord du salon, au-dessus du point où Willem la répare ; ses deux autres états et son
## balancier (récit, jour 11) existent au manifeste.
func test_the_clock_and_its_other_states_are_ready_for_the_story() -> void:
	var clock: Dictionary = {}
	for item: Dictionary in _room.plan.wall_items:
		if String(item["image"]) == "wallitem_clock_limashenka":
			clock = item
	assert_false(clock.is_empty(), "l'horloge murale du salon")
	assert_eq(String(clock["room"]), "salon")
	var point := _map.get_node(^"Life/Places/horloge") as Marker3D
	assert_almost_eq(float(clock["center"]), point.global_position.x, 0.1, "Willem est sous l'horloge")
	for image_name: String in [
		"wallitem_clock_limashenka", "wallitem_clock_limashenka_open", "clock_limashenka_swing"
	]:
		assert_true(_in_manifest(image_name), "%s au manifeste (lot R3)" % image_name)
	assert_true(
		FileAccess.file_exists("res://assets/hd2d/interior/wallitem_clock_limashenka_open.png")
	)
	assert_true(FileAccess.file_exists("res://assets/hd2d/anim/clock_limashenka_swing.png"))
	assert_true(
		ResourceLoader.exists("res://src/world/props/interior/clock_limashenka_swing.tscn"),
		"la scène du balancier, pour le récit"
	)


func _in_manifest(image_name: String) -> bool:
	var manifest: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://tools/hd2d_manifest.json")
	)
	for entry: Dictionary in manifest["images"]:
		if String(entry["path"]).get_file().get_basename() == image_name:
			return String(entry.get("lot", "")) == "R3"
	return false


func test_the_extra_life_places_are_named() -> void:
	# Le siège du canapé est sur le canapé (on s'y assoit : la case est prise) ; la place du vestibule se marche.
	assert_not_null(_map.get_node_or_null(^"Life/Places/salon_canape_assise"), "le siège du canapé")
	var door_place := _map.get_node_or_null(^"Life/Places/vestibule_porte") as Marker3D
	assert_not_null(door_place, "la place devant la porte")
	if door_place != null:
		assert_true(reached_near(flat(door_place.global_position), 0.6), "on y va")


func test_every_room_is_reached_and_every_exit_is_within_reach() -> void:
	check_reach()


func test_walls_stop_a_walking_body_and_doors_let_it_through() -> void:
	check_doors_pass()


func test_no_wall_or_tall_furniture_hides_the_player() -> void:
	check_nothing_hides_the_player()


func test_each_view_stays_within_the_draw_call_budget() -> void:
	check_draw_calls()


func test_objects_to_examine_have_their_text() -> void:
	check_examinables(6)
