extends "res://tests/stubs/t2_map_test.gd"
## (T2) L'étage de l'entrepôt des fées (src/world/maps/entrepot_etage/, plan de docs/lore/CARTE.md,
## 3.2) : base commune tests/stubs/t2_map_test.gd (plan, circulation, rien ne cache le joueur,
## draw calls, objets à examiner), plus les chambres de Willem, de Chtholly et de Nygglatho et ce
## qui les distingue, le couloir qui fuit (seau, goutte animée, échelle du toit), l'escalier vers
## le rez-de-chaussée et la trappe vers le toit.


func before_all() -> void:
	map_id = "entrepot_etage"
	expected_light_preset = "interieur"
	await super()


func test_map_follows_the_contract_and_its_plan() -> void:
	check_contract()
	check_rooms_and_openings()


func test_every_piece_of_furniture_of_the_plan_is_in_place() -> void:
	check_furniture()
	# L'armoire de Chtholly est au plan contre le mur sud, à l'est de la porte : sa face de 1 m,
	# au milieu du mur est, aurait caché le joueur (docs/DECISIONS.md, T2 puis I1) ; elle se coupe
	# avec le mur sud, de face comme de flanc.
	var wardrobe := _map.find_child("wardrobe_chtholly_1", true, false) as InteriorPanel
	assert_not_null(wardrobe, "l'armoire de Chtholly")
	if wardrobe != null:
		assert_gt(wardrobe.front_z(), 8.1, "contre le mur sud")
		assert_gt(wardrobe.cut_z(), 8.5, "coupée avec le mur sud")


func test_markers_exits_and_named_points() -> void:
	check_markers_exits_points()


func test_rooms_of_willem_chtholly_and_nygglatho() -> void:
	# Ce qui fait chaque chambre (CARTE.md 3.2) : posé dans sa pièce.
	var expected := {
		"willem": ["wardrobe_plain", "bed_plain", "footlocker"],
		"chtholly": ["desk_chtholly", "bed_chtholly", "wardrobe_chtholly", "wallitem_calendar"],
		"nygglatho":
		["fireplace", "comm_crystal", "desk_nygglatho", "bed_nygglatho", "tea_tray_cheesecake"],
	}
	var plan := _room.plan
	for room: String in expected:
		var images := {}
		for entry: Array in decors():
			var where := _map.to_local((entry[0] as Node3D).global_position)
			if String(plan.room_at(where + Vector3(0, 0, -0.05))) == room:
				images[entry[1]] = true
		for item: Dictionary in plan.wall_items:
			if String(item["room"]) == room:
				images[item["image"]] = true
		for image: String in expected[room]:
			assert_true(images.has(image), "%s : %s dans la chambre" % [room, image])


func test_the_leaking_corridor_and_the_way_to_the_roof() -> void:
	var drip := _map.find_child("leak_drip_1", true, false) as DecorPanel
	assert_not_null(drip, "la goutte qui tombe du plafond")
	if drip != null:
		assert_gt(drip.frames, 1, "goutte animée")
		assert_almost_eq(flat(drip.position), Vector2(30.45, 10.0), Vector2.ONE * 1.0, "au seau")
	assert_not_null(_map.find_child("leak_bucket_1", true, false), "le seau sous la fuite")
	assert_not_null(_map.find_child("roof_ladder_1", true, false), "l'échelle du toit")
	var up := _map.get_node(^"Exits/vers_toit") as MapExit
	assert_eq(
		[up.target_map, up.target_marker, up.prompt],
		[&"entrepot_toit", &"from_entrepot_etage", "Monter sur le toit"]
	)
	var down := _map.get_node(^"Exits/vers_rdc") as MapExit
	assert_eq(
		[down.target_map, down.target_marker, down.prompt],
		[&"entrepot_rdc", &"from_entrepot_etage", "Descendre"]
	)
	assert_true(
		blocked(Vector3(17.5, 0.0, 4.0)), "dans la trémie, la volée qui descend : on n'y marche pas"
	)


func test_every_room_is_reached_and_every_exit_is_within_reach() -> void:
	check_reach()


func test_walls_stop_a_walking_body_and_doors_let_it_through() -> void:
	check_doors_pass()


func test_no_wall_or_tall_furniture_hides_the_player() -> void:
	check_nothing_hides_the_player()


func test_each_view_stays_within_the_draw_call_budget() -> void:
	check_draw_calls()


func test_objects_to_examine_have_their_text() -> void:
	check_examinables(16)
