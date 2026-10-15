extends "res://tests/stubs/t2_map_test.gd"
## (T2) Le toit-terrasse de l'entrepôt (src/world/maps/entrepot_toit/, plan de docs/lore/CARTE.md,
## 3.3) : une carte du dehors (MapGround, pas d'InteriorRoom) dont le sol courant est la terrasse,
## la cour 6,5 m plus bas. Base commune tests/stubs/t2_map_test.gd (contrat, marqueurs, sortie,
## points, circulation, rien ne cache le joueur, draw calls), plus les décors du plan à leur place,
## la rambarde (modules de 2 m au nord, à l'est et au sud, le module tordu au sud) qui retient le
## joueur, le pan d'ardoise du volume ouest, la chute de 6,5 m et la lisière en contrebas au nord.

const DROP := 6.5


func before_all() -> void:
	map_id = "entrepot_toit"
	expected_light_preset = ""
	await super()


func test_map_follows_the_contract_and_its_plan() -> void:
	check_contract()
	assert_false(_map.interior, "dehors : ciel, vent, lumière du moment")
	assert_null(_room, "pas d'InteriorRoom : un sol du dehors")
	var ground := _map.get_node(^"Ground") as MapGround
	assert_not_null(ground, "MapGround")
	if ground == null:
		return
	assert_almost_eq(ground.height_at(8.0, 8.0), 0.0, 0.01, "la terrasse au niveau 0")
	assert_almost_eq(ground.height_at(8.0, 0.5), -DROP, 0.01, "la cour 6,5 m plus bas au nord")
	assert_almost_eq(ground.height_at(15.5, 8.0), -DROP, 0.01, "à l'est")
	assert_almost_eq(ground.height_at(8.0, 15.5), -DROP, 0.01, "au sud")


func test_every_decor_of_the_plan_is_in_place() -> void:
	var placed := decors()
	for spec: Dictionary in _plan["decors"]:
		var image := String(spec["image"])
		if image == "drying_frame":
			image = "drying_frame_wave"
		var at: Vector2 = spec["at"]
		var found := false
		for entry: Array in placed:
			if entry[1] != image:
				continue
			var where := flat(_map.to_local((entry[0] as Node3D).global_position))
			# Le module tordu remplace le module de rambarde le plus proche de sa place.
			var tolerance := 1.01 if image == "roof_railing_broken" else 0.011
			found = found or absf(where.x - at.x) < tolerance and absf(where.y - at.y) < 0.6
		assert_true(found, "%s en %s" % [image, at])
	for frame: String in ["drying_frame_wave_1", "drying_frame_wave_2"]:
		var panel := _map.find_child(frame, true, false) as DecorPanel
		assert_not_null(panel, frame)
		if panel != null:
			assert_gt(panel.frames, 1, "%s : linge animé" % frame)
			assert_true(panel.foreground, "%s : s'efface devant le joueur" % frame)
	assert_not_null(_map.find_child("entrepot_volume_ouest", true, false), "le volume ouest")
	assert_gte(_map.get_node(^"Geometry/Lisiere").get_child_count(), 4, "la lisière en contrebas")
	for tree: Node in _map.get_node(^"Geometry/Lisiere").get_children():
		assert_almost_eq((tree as Node3D).position.y, -DROP, 0.01, "%s : en bas" % tree.name)


func test_the_deck_wears_its_own_floor_tile() -> void:
	# (I2) floor_roof_deck (lot R1) : 3 × 4 décalques de 4 × 3,5 m bout à bout sur la terrasse
	# (x 3 → 15, z 1 → 15), sous le sol de MapGround ; les taches de mousse passent d'une couche.
	var tiles := []
	var mosses := []
	for entry: Array in decors():
		if entry[1] == "floor_roof_deck":
			tiles.append(entry[0])
		elif String(entry[1]).begins_with("moss_patch"):
			mosses.append(entry[0])
	assert_eq(tiles.size(), 12, "douze tuiles")
	var covered := Rect2()
	for tile: GroundDecal in tiles:
		assert_eq(tile.layer, 0, "au plus bas")
		var size := Vector2(4.0, 4.0 * tile.scale.z)
		var at := flat(tile.position)
		covered = (
			covered.merge(Rect2(at - size / 2.0, size))
			if covered.has_area()
			else Rect2(at - size / 2.0, size)
		)
	assert_true(
		covered.is_equal_approx(Rect2(3.0, 1.0, 12.0, 14.0)), "toute la terrasse, sans dépasser"
	)
	assert_gt(mosses.size(), 0, "des taches de mousse")
	for moss: GroundDecal in mosses:
		assert_eq(moss.layer, 1, "la mousse reste au-dessus du sol")
	var slate := 0
	for entry: Array in decors():
		if entry[1] == "roof_edge_slate":
			slate += 1
			assert_almost_eq((entry[0] as Node3D).position.z, 15.0, 0.01, "à l'égout sud")
	assert_eq(slate, 2, "deux modules de 4 m")


func test_the_railing_runs_along_three_edges() -> void:
	var north := 0
	var east := 0
	var south := 0
	for entry: Array in decors():
		if not String(entry[1]).begins_with("roof_railing"):
			continue
		var where := flat((entry[0] as Node3D).position)
		north += 1 if absf(where.y - 1.15) < 0.01 else 0
		east += 1 if absf(where.x - 15.15) < 0.01 else 0
		if absf(where.y - 14.85) < 0.01:
			south += 1
			assert_true((entry[0] as DecorPanel).foreground, "au sud : premier plan")
	assert_eq([north, east, south], [6, 7, 6], "modules de 2 m (nord, est, sud)")


func test_markers_exits_and_named_points() -> void:
	check_markers_exits_points()
	var hatch := _map.get_node(^"Exits/trappe") as MapExit
	assert_eq(
		[hatch.target_map, hatch.target_marker, hatch.prompt],
		[&"entrepot_etage", &"from_entrepot_toit", "Descendre"]
	)


func test_every_place_is_reached_and_the_exit_is_within_reach() -> void:
	check_reach()


func test_the_railing_and_the_slate_roof_hold_the_player() -> void:
	# Un corps qui marche vers chaque bord bute (rambarde au nord, à l'est, au sud, module tordu
	# compris ; pan d'ardoise à l'ouest).
	var body := CharacterBody3D.new()
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = PLAYER_RADIUS
	capsule.height = PLAYER_HEIGHT
	shape.shape = capsule
	shape.position.y = PLAYER_HEIGHT / 2.0 + 0.05
	body.add_child(shape)
	body.collision_layer = 2
	body.collision_mask = 1
	_map.add_child(body)
	for walk: Array in [
		[Vector3(8.0, 0.0, 2.0), Vector3(0, 0, -2)],
		[Vector3(14.0, 0.0, 8.0), Vector3(2, 0, 0)],
		[Vector3(8.0, 0.0, 14.0), Vector3(0, 0, 2)],
		[Vector3(11.0, 0.0, 14.0), Vector3(0, 0, 2)],
		[Vector3(4.0, 0.0, 8.0), Vector3(-2, 0, 0)],
	]:
		body.global_position = _map.to_global(walk[0] as Vector3)
		assert_true(
			body.test_move(body.global_transform, walk[1] as Vector3),
			"de %s vers %s : on bute" % [flat(walk[0] as Vector3), flat(walk[1] as Vector3)]
		)
	body.free()
	var stray: Array[String] = []
	for cell: Vector2i in _reached:
		var at := center(cell)
		if at.x < 3.0 or at.x > 15.0 or at.z < 1.0 or at.z > 15.0:
			stray.append(str(flat(at)))
	assert_eq(stray, [] as Array[String], "on reste sur la terrasse")


func test_no_wall_or_tall_decor_hides_the_player() -> void:
	check_nothing_hides_the_player()


func test_each_view_stays_within_the_draw_call_budget() -> void:
	check_draw_calls()


func test_nothing_to_examine_on_the_roof() -> void:
	assert_null(_map.get_node_or_null(^"Examine"), "rien à examiner (CARTE.md 3.3)")
