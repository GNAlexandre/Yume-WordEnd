extends GutTest
## (T2) Grille d'un demi-mètre des intérieurs (InteriorLayout.GRID) : les plans de
## docs/lore/CARTE.md, section 3, posent des cloisons à x = 5,5 ou z = 8,5 (cuisine de 4,5 m,
## couloir de z 8,5 à 10,5). Pièces, portes, fenêtres et lampes s'y lisent en mètres ; les murs
## se déduisent sur les lignes au demi-mètre ; la coupe s'y arrête ; la colonne de coupe reconnaît
## un mur nord-sud au demi-mètre (InteriorRoom.part_code, interior.gdshader) ; la lumière reste
## dans sa pièce. Les étages au mètre (carte d'essai d'E3) ne changent pas : test_interior_room.gd.

const HALF := 0.125


## Deux pièces côte à côte sur des lignes au demi-mètre (a : x 1 → 5,5 ; b : x 5,5 → 9), une
## bande au sud (c : z 5 → 7,5), une porte entre a et b, une entre a et c, une fenêtre au nord
## de b, une lampe dans b.
func _layout() -> Dictionary:
	return {
		"size": [10, 9],
		"rooms":
		{
			"a":
			{"rects": [[1, 1, 4.5, 4]], "floor": "floor_planks_worn", "wall": "wall_plaster_worn"},
			"b":
			{
				"rects": [[5.5, 1, 3.5, 4]],
				"floor": "floor_tiles_bath",
				"wall": "wall_kitchen_tiles"
			},
			"c": {"rects": [[1, 5, 8, 2.5]], "floor": "floor_planks_dark", "wall": "wall_wainscot"},
		},
		"doors":
		[
			{"between": ["a", "b"], "z": 3.0, "width": 1.2, "image": "door_frame_wood"},
			{"between": ["a", "c"], "x": 3.25, "width": 1.2, "image": "door_frame_wood"},
		],
		"windows": [{"room": "b", "side": "N", "x": 7.25, "image": "window_cross_small"}],
		"lights": [{"room": "b", "at": [7.25, 3.0], "radius": 2.5}],
	}


func _room(data: Dictionary) -> InteriorRoom:
	var json := JSON.new()
	json.data = data
	var room := InteriorRoom.new()
	room.layout = json
	add_child_autofree(room)
	return room


func _pieces_on(plan: InteriorLayout, axis: int, line: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for piece: Dictionary in plan.pieces:
		if int(piece["axis"]) == axis and is_equal_approx(float(piece["line"]), line):
			out.append(piece)
	out.sort_custom(func(p: Dictionary, q: Dictionary) -> bool: return p["a"] < q["a"])
	return out


func test_half_metre_rooms_are_valid_and_found() -> void:
	var plan := InteriorLayout.from_data(_layout())
	assert_eq(plan.problems, [] as Array[String], "agencement au demi-mètre sans faute")
	assert_eq(plan.cell(5.4, 2.0), plan.room_index(&"a"), "a jusqu'à x = 5,5")
	assert_eq(plan.cell(5.6, 2.0), plan.room_index(&"b"), "b dès x = 5,5")
	assert_eq(plan.room_at(Vector3(4.0, 0.0, 7.4)), &"c", "c jusqu'à z = 7,5")
	assert_eq(plan.room_at(Vector3(4.0, 0.0, 7.6)), &"", "le vide au-delà")
	var bad := _layout()
	bad["rooms"]["a"]["rects"] = [[1, 1, 4.3, 4]]
	assert_string_contains(
		"; ".join(InteriorLayout.from_data(bad).problems), "multiples de 0.5", "4,3 m refusé"
	)


func test_walls_stand_on_half_metre_lines() -> void:
	var plan := InteriorLayout.from_data(_layout())
	var v := InteriorLayout.VERTICAL
	var h := InteriorLayout.HORIZONTAL
	var partition := _pieces_on(plan, v, 5.5)
	assert_eq(partition.size(), 3, "cloison a-b : deux morceaux et le linteau de la porte")
	assert_almost_eq(float(partition[0]["a"]), 1.0 - HALF, 0.001, "poteau de l'angle nord")
	assert_almost_eq(float(partition[1]["a"]), 2.4, 0.001, "porte de 1,2 m centrée en z = 3")
	assert_almost_eq(float(partition[1]["y0"]), InteriorLayout.DOOR_HEIGHT, 0.001, "linteau")
	assert_almost_eq(float(partition[2]["b"]), 5.0 + HALF, 0.001, "poteau de l'angle sud")
	var south := _pieces_on(plan, h, 7.5)
	assert_eq(south.size(), 1, "mur sud de c, sur la ligne z = 7,5")
	var door := plan.doors[1]
	assert_almost_eq(float(door["line"]), 5.0, 0.001, "porte a-c sur la ligne z = 5")
	assert_eq(
		InteriorLayout.opening_center(plan.doors[0]), Vector3(5.5, 0.0, 3.0), "porte a-b en x = 5,5"
	)
	assert_almost_eq(float(plan.windows[0]["line"]), 1.0, 0.001, "fenêtre sur le mur nord de b")


func test_cut_line_stops_on_a_half_metre_limit() -> void:
	var plan := InteriorLayout.from_data(_layout())
	assert_eq(plan.cut_line_at(Vector3(3.0, 0.0, 2.0)), 5.0, "dans a : sa limite sud")
	assert_eq(plan.cut_line_at(Vector3(3.0, 0.0, 6.0)), 7.5, "dans c : z = 7,5")
	assert_eq(plan.cut_line_at(Vector3(3.0, 0.0, 7.7)), InteriorLayout.NO_CUT, "au sud de tout")


func test_cut_column_recognises_a_half_metre_partition() -> void:
	# interior.gdshader : line_x = (floor(code / 4) − 1) × 0,5 ; la partie reste code mod 4.
	for line: float in [0.0, 1.0, 5.5, 18.5, 30.5]:
		for part: float in [InteriorRoom.PART_FACE, InteriorRoom.PART_TOP, InteriorRoom.PART_LOW]:
			var code := InteriorRoom.part_code(part, line)
			assert_eq(fmod(code, 4.0), part, "partie gardée")
			assert_almost_eq((floorf(code / 4.0) - 1.0) * InteriorLayout.GRID, line, 0.001, "ligne")
	assert_eq(
		InteriorRoom.part_code(InteriorRoom.PART_TOP, -1.0), InteriorRoom.PART_TOP, "mur est-ouest"
	)
	var room := _room(_layout())
	var triangles := room.occluder_triangles(InteriorLayout.NO_CUT, Vector3(5.5, 0.0, 3.0))
	var south_of_door := 0.0
	for point in triangles:
		if absf(point.x - 5.5) < 0.2 and point.z > 3.55 and point.z < 4.8:
			south_of_door = maxf(south_of_door, point.y)
	assert_almost_eq(
		south_of_door, InteriorRoom.CUT_HEIGHT, 0.001, "colonne de coupe sous le joueur"
	)


func test_light_stays_behind_a_half_metre_partition() -> void:
	var room := _room(_layout())
	assert_gt(room.light_at(Vector3(7.25, 0.0, 3.0)).r, 0.5, "sous la lampe, dans b")
	assert_gt(room.light_at(Vector3(5.7, 0.0, 3.4)).r, 0.0, "b jusqu'à sa cloison")
	assert_eq(room.light_at(Vector3(5.3, 0.0, 3.4)), Color.BLACK, "pas dans a, de l'autre côté")
	assert_eq(room.material_at(5.6, 2.0), &"floor_tiles_bath")
	assert_eq(room.material_at(5.4, 2.0), &"floor_planks_worn")
	assert_true(room.is_walkable(5.5, 3.0), "dans la porte")
	assert_false(room.is_walkable(5.5, 2.0), "dans la cloison")


## (T2) InteriorPanel.cut_offset : un meuble haut adossé au mur sud recule sa ligne de coupe
## jusqu'au mur et se coupe avec lui ; sans décalage, il reste entier quand la coupe passe au mur.
func test_cut_offset_cuts_a_wardrobe_with_the_south_wall() -> void:
	var panel := InteriorPanel.new()
	panel.texture = load("res://assets/hd2d/interior/props/wardrobe_chtholly.png") as Texture2D
	panel.image_offset = Vector3(0.0, 0.0, 0.3)
	panel.position = Vector3(7.35, 0.0, 8.075)
	add_child_autofree(panel)
	var wall_line := 8.5 + InteriorRoom.CUT_MARGIN + 0.01
	assert_almost_eq(panel.cut_z(), 8.375, 0.001, "sans décalage : la coupe à l'image")
	var whole := panel.occluder_triangles(wall_line)
	assert_almost_eq(whole[2].y, panel.size_m().y, 0.001, "entier quand la coupe passe au mur")
	panel.cut_offset = 0.175
	assert_almost_eq(panel.cut_z(), 8.55, 0.001, "la coupe au-delà du mur sud")
	var cut := panel.occluder_triangles(wall_line)
	assert_almost_eq(cut[2].y, panel.cut_height, 0.001, "coupé avec le mur")
	assert_almost_eq(cut[0].z, 8.375, 0.001, "l'image ne bouge pas")
