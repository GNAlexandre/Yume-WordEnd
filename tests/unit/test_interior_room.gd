extends GutTest
## (E3) Intérieurs (src/world/interior_room.gd, interior_layout.gd, interior_panel.gd ; format :
## docs/INTERIEURS.md) :
## - le format : l'étage d'essai est valide, chaque faute est relevée (clé inconnue, chevauchement,
##   image absente, porte hors d'un mur ou contre un angle, éléments qui se chevauchent, lampe
##   hors de sa pièce…) ;
## - les murs se déduisent des pièces, le mur nord-sud porte le poteau des angles, les portes
##   praticables trouent le mur sous un linteau ;
## - la coupe : première limite de pièce au sud du joueur, suivie à chaque image, partagée avec
##   les meubles ; ce qui est au sud n'est dessiné que sous sa hauteur de coupe ;
## - la lumière reste dans sa pièce ; fenêtres et lampes suivent le moment de la journée ;
## - un mesh par matière ; collisions de la couche 1 ;
## - les meubles et tapis du lot I ont leur scène (InteriorPanel, GroundDecal) et leur collision.

const LAYOUT := "res://data/maps/entrepot_rdc_essai/interior.json"
const MANIFEST := "res://tools/hd2d_manifest.json"
const PROPS_DIR := "res://src/world/props"
const NO_CUT := InteriorLayout.NO_CUT
const HALF := 0.125


func _example() -> Dictionary:
	var json := JSON.new()
	assert_eq(json.parse(FileAccess.get_file_as_string(LAYOUT)), OK, "interior.json lisible")
	return json.data


## Deux pièces côte à côte (a à l'ouest, b à l'est), une porte entre elles, une vers le sud.
func _small() -> Dictionary:
	return {
		"size": [10, 6],
		"rooms":
		{
			"a":
			{"rects": [[1, 1, 4, 4]], "floor": "floor_planks_worn", "wall": "wall_plaster_worn"},
			"b":
			{
				"rects": [[5, 1, 4, 4]],
				"floor": "floor_tiles_bath",
				"wall": "wall_kitchen_tiles",
				"wallcut": "wallcut_stone",
			},
		},
		"doors":
		[
			{"between": ["a", "b"], "z": 3.0, "image": "door_frame_wood"},
			{"id": "dehors", "room": "a", "side": "S", "x": 3.0, "image": "door_room"},
		],
		"windows": [{"room": "a", "side": "N", "x": 3.0, "image": "window_cross_small"}],
		"wall_items":
		[{"room": "b", "side": "N", "x": 7.0, "y": 1.5, "image": "wallitem_wall_clock"}],
		"lights": [{"room": "b", "at": [7.0, 2.0], "radius": 2.5}],
	}


func _room(data: Dictionary) -> InteriorRoom:
	var json := JSON.new()
	json.data = data
	var room := InteriorRoom.new()
	room.layout = json
	add_child_autofree(room)
	return room


func _problems(data: Dictionary) -> String:
	return "; ".join(InteriorLayout.from_data(data).problems)


# --- Format ----------------------------------------------------------------------------------


func test_example_floor_is_valid() -> void:
	var plan := InteriorLayout.from_data(_example())
	assert_eq(plan.problems, [] as Array[String], "rez-de-chaussée d'essai sans faute")
	assert_eq(plan.map_size, Vector2i(40, 24))
	assert_eq(plan.rooms.size(), 11, "onze pièces")
	assert_eq(plan.doors.size(), 14, "quatorze portes")
	assert_eq(plan.windows.size(), 11)
	assert_eq(plan.wall_items.size(), 17)
	assert_eq(plan.lights.size(), 14)
	assert_eq(plan.room_at(Vector3(8.0, 0.0, 5.0)), &"refectoire")
	assert_eq(plan.room_at(Vector3(36.5, 0.0, 8.0)), &"couloir", "couloir en L")
	assert_eq(plan.room_at(Vector3(20.0, 0.0, 23.0)), &"", "le vide hors des pièces")
	assert_eq(_problems(_small()), "", "petit étage valide")


func test_each_mistake_is_reported() -> void:
	var cases := {
		"clé inconnue « sise »": func(d: Dictionary) -> void: d["sise"] = 1,
		"clé inconnue « flor »": func(d: Dictionary) -> void: d["rooms"]["a"]["flor"] = 1,
		"déjà prise": func(d: Dictionary) -> void: d["rooms"]["b"]["rects"] = [[4, 1, 4, 4]],
		"hors de la carte": func(d: Dictionary) -> void: d["rooms"]["b"]["rects"] = [[5, 1, 9, 4]],
		"image absente": func(d: Dictionary) -> void: d["rooms"]["a"]["floor"] = "floor_nope",
		"image wall_": func(d: Dictionary) -> void: d["rooms"]["a"]["wall"] = "floor_planks_worn",
		"aucun mur": func(d: Dictionary) -> void: d["doors"][0] = {"between": ["a", "b"], "x": 3.0},
		"angle": func(d: Dictionary) -> void: d["doors"][0]["z"] = 1.6,
		"chevauchent":
		func(d: Dictionary) -> void: d["windows"][0] = d["windows"][0].merged({"side": "S"}, true),
		"hors de sa pièce": func(d: Dictionary) -> void: d["lights"][0]["at"] = [2.0, 2.0],
		"dépasse du mur": func(d: Dictionary) -> void: d["windows"][0]["sill"] = 2.5,
		"room et side": func(d: Dictionary) -> void: d["doors"][1]["side"] = "E",
	}
	for expected: String in cases:
		var data := _small().duplicate(true)
		(cases[expected] as Callable).call(data)
		assert_string_contains(_problems(data), expected, expected)
	var commented := _small()
	commented["_comment"] = "permis"
	commented["rooms"]["a"]["_note"] = "permis aussi"
	assert_eq(_problems(commented), "", "les clés « _… » sont des commentaires")


# --- Murs ------------------------------------------------------------------------------------


func _pieces_on(plan: InteriorLayout, axis: int, line: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for piece: Dictionary in plan.pieces:
		if int(piece["axis"]) == axis and int(piece["line"]) == line:
			out.append(piece)
	out.sort_custom(func(p: Dictionary, q: Dictionary) -> bool: return p["a"] < q["a"])
	return out


func _spans(pieces: Array[Dictionary]) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for piece in pieces:
		out.append(Vector3(float(piece["a"]), float(piece["b"]), float(piece["y0"])))
	return out


func test_walls_are_deduced_from_the_rooms() -> void:
	var plan := InteriorLayout.from_data(_small())
	var h := InteriorLayout.HORIZONTAL
	var v := InteriorLayout.VERTICAL
	# Mur nord : un morceau par pièce, arrêtés contre les murs nord-sud (qui portent les angles).
	assert_eq(
		_spans(_pieces_on(plan, h, 1)),
		[Vector3(1.0 + HALF, 5.0 - HALF, 0.0), Vector3(5.0 + HALF, 9.0 - HALF, 0.0)],
		"mur nord de a et de b"
	)
	# Mur ouest : prolongé d'un demi-mur au nord et au sud (les poteaux des angles).
	assert_eq(_spans(_pieces_on(plan, v, 1)), [Vector3(1.0 - HALF, 5.0 + HALF, 0.0)], "mur ouest")
	# Cloison entre a et b, trouée par la porte (1,1 m centrée en z = 3) sous un linteau.
	assert_eq(
		_spans(_pieces_on(plan, v, 5)),
		[
			Vector3(1.0 - HALF, 2.45, 0.0),
			Vector3(2.45, 3.55, InteriorLayout.DOOR_HEIGHT),
			Vector3(3.55, 5.0 + HALF, 0.0),
		],
		"cloison et porte"
	)
	# Mur sud de a : la porte vers le dehors.
	assert_eq(
		_spans(_pieces_on(plan, h, 5)),
		[
			Vector3(1.0 + HALF, 2.45, 0.0),
			Vector3(2.45, 3.55, InteriorLayout.DOOR_HEIGHT),
			Vector3(3.55, 5.0 - HALF, 0.0),
			Vector3(5.0 + HALF, 9.0 - HALF, 0.0),
		],
		"mur sud"
	)
	var outside := plan.door(&"dehors")
	assert_eq(
		InteriorLayout.opening_center(outside), Vector3(3.0, 0.0, 5.0), "porte vers le dehors"
	)
	assert_eq(int(outside["low"]), plan.room_index(&"a"))
	assert_eq(int(outside["high"]), -1, "le vide au sud")


func test_a_closed_door_keeps_its_wall() -> void:
	var data := _small()
	data["doors"][1]["passable"] = false
	var plan := InteriorLayout.from_data(data)
	assert_eq(
		_spans(_pieces_on(plan, InteriorLayout.HORIZONTAL, 5)),
		[Vector3(1.0 + HALF, 5.0 - HALF, 0.0), Vector3(5.0 + HALF, 9.0 - HALF, 0.0)],
		"porte fermée : le mur reste, l'image le couvre"
	)


# --- Coupe -----------------------------------------------------------------------------------


func test_cut_line_is_the_first_room_limit_south_of_the_player() -> void:
	var plan := InteriorLayout.from_data(_example())
	var spots := {
		"réfectoire": [Vector3(8.0, 0.0, 5.0), 10.0],
		"porte du réfectoire, côté réfectoire": [Vector3(8.5, 0.0, 9.9), 10.0],
		"porte du réfectoire, côté couloir": [Vector3(8.5, 0.0, 10.1), 13.0],
		"couloir": [Vector3(20.0, 0.0, 11.5), 13.0],
		"couloir en L, vers la descente": [Vector3(36.5, 0.0, 7.0), 13.0],
		"descente": [Vector3(36.5, 0.0, 4.0), 6.0],
		"infirmerie": [Vector3(12.0, 0.0, 17.0), 21.0],
		"dehors, au sud": [Vector3(19.0, 0.0, 22.5), NO_CUT],
	}
	for label: String in spots:
		var spot: Array = spots[label]
		assert_eq(plan.cut_line_at(spot[0] as Vector3), float(spot[1]), label)


func test_cut_follows_the_player_and_reaches_the_furniture() -> void:
	var room := _room(_example())
	var player := Node3D.new()
	player.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	player.add_to_group(InteriorRoom.PLAYER_GROUP)
	add_child_autofree(player)
	player.position = Vector3(8.0, 0.0, 5.0)
	room._process(0.016)
	assert_eq(room.cut_line(), 10.0, "première image : la coupe se pose sur la limite")
	var chair := load("%s/chair_wood.tscn" % PROPS_DIR) as PackedScene
	var panel := chair.instantiate() as InteriorPanel
	add_child_autofree(panel)
	var material := (panel.get_child(0, true) as MeshInstance3D).material_override as ShaderMaterial
	assert_eq(material.get_shader_parameter(&"cut_line"), 10.0, "les meubles suivent la coupe")
	player.position = Vector3(8.5, 0.0, 11.5)
	room._process(0.1)
	assert_almost_eq(room.cut_line(), 10.0 + InteriorRoom.CUT_SPEED * 0.1, 0.001, "elle glisse")
	for _i in 10:
		room._process(0.1)
	assert_eq(room.cut_line(), 13.0, "puis se pose sur la limite suivante")
	assert_eq(material.get_shader_parameter(&"cut_line"), 13.0)
	room.cut_enabled = false
	room._process(0.1)
	assert_eq(room.cut_line(), NO_CUT, "sans coupe")


func _max_height(triangles: PackedVector3Array, region: AABB) -> float:
	var top := 0.0
	for point in triangles:
		var flat := Vector3(point.x, region.position.y, point.z)
		if region.grow(0.001).has_point(flat):
			top = maxf(top, point.y)
	return top


func test_walls_south_of_the_cut_keep_only_their_thickness() -> void:
	var room := _room(_small())
	var whole := room.occluder_triangles(NO_CUT)
	var south_wall := AABB(Vector3(1.0, 0.0, 4.8), Vector3(8.0, 0.0, 0.4))
	var partition_south := AABB(Vector3(4.8, 0.0, 4.75), Vector3(0.4, 0.0, 0.5))
	var partition_north := AABB(Vector3(4.8, 0.0, 1.0), Vector3(0.4, 0.0, 1.0))
	assert_eq(_max_height(whole, south_wall), 3.0, "sans coupe, murs entiers")
	var cut := room.occluder_triangles(5.0)
	assert_almost_eq(_max_height(cut, south_wall), InteriorRoom.CUT_HEIGHT, 0.001, "mur sud coupé")
	assert_almost_eq(
		_max_height(cut, partition_south), InteriorRoom.CUT_HEIGHT, 0.001, "bout sud de la cloison"
	)
	assert_eq(_max_height(cut, partition_north), 3.0, "la cloison reste entière au nord")


# --- Lumière ---------------------------------------------------------------------------------


func test_light_stays_in_its_room() -> void:
	var room := _room(_small())
	assert_gt(room.light_at(Vector3(7.0, 0.0, 2.0)).r, 0.5, "sous la lampe")
	assert_gt(room.light_at(Vector3(5.4, 0.0, 2.0)).r, 0.0, "la lampe éclaire sa pièce")
	assert_eq(room.light_at(Vector3(4.6, 0.0, 2.0)), Color.BLACK, "pas à travers la cloison")
	assert_gt(room.light_at(Vector3(3.0, 0.0, 1.5)).g, 0.3, "le jour devant la fenêtre")
	assert_eq(room.light_at(Vector3(3.0, 0.0, 4.6)), Color.BLACK, "loin de la fenêtre")
	room.set_daylight(Color.WHITE, 0.0)
	assert_eq(room.light_at(Vector3(3.0, 0.0, 1.5)), Color.BLACK, "nuit noire")


func test_day_phases_change_windows_and_lamps() -> void:
	var room := _room(_small())
	var day := room.light_at(Vector3(3.0, 0.0, 1.5))
	EventBus.day_phase_changed.emit(&"night")
	assert_eq(room.lamp_energy, float(InteriorRoom.PHASES[&"night"][2]), "lampes de la nuit")
	assert_lt(room.light_at(Vector3(3.0, 0.0, 1.5)).g, day.g, "moins de jour la nuit")
	assert_gt(room.light_at(Vector3(7.0, 0.0, 2.0)).r, 1.0, "les lampes portent la lumière")
	var surface := room.surfaces()[0].material_override as ShaderMaterial
	assert_eq(surface.get_shader_parameter(&"lamp_energy"), room.lamp_energy, "uniforme posé")
	room.apply_phase(&"inconnue")
	assert_eq(room.lamp_energy, float(InteriorRoom.PHASES[&"night"][2]), "phase inconnue : rien")


# --- Meshes, matériaux, collisions -----------------------------------------------------------


func test_one_mesh_per_material() -> void:
	var room := _room(_example())
	var plan := room.plan
	var expected := {"Void": true}
	for opening: Dictionary in plan.doors:
		if not String(opening["image"]).is_empty():
			expected["Panel_" + String(opening["image"])] = true
	for placed: Dictionary in plan.windows + plan.wall_items:
		expected["Panel_" + String(placed["image"])] = true
	for item: Dictionary in plan.rooms:
		expected["Floor_" + String(item["floor"])] = true
		expected["Walls_" + String(item["wall"])] = true
		expected["Tops_" + String(item["wallcut"])] = true
	var names := {}
	for surface in room.surfaces():
		names[String(surface.name)] = true
		assert_eq(surface.mesh.get_surface_count(), 1, "%s : une surface" % surface.name)
		assert_not_null(surface.material_override, "%s : son matériau" % surface.name)
	assert_eq(names.size(), room.surfaces().size(), "un mesh par matière, noms uniques")
	assert_eq(names.keys().size(), expected.size(), "meshes : %s" % ", ".join(names.keys()))
	for key: String in expected:
		assert_true(names.has(key), "mesh %s" % key)
	# Un par image : 5 sols, 5 murs, 2 dessus, 4 portes, 3 fenêtres, 12 éléments de mur, le vide.
	assert_lt(room.surfaces().size(), 40, "%d draw calls pour l'étage nu" % room.surfaces().size())


func test_collisions_are_the_floor_and_the_walls() -> void:
	var room := _room(_example())
	assert_eq(room.collision_layer, 1, "couche world")
	assert_eq(room.collision_mask, 0)
	assert_eq(room.get_child_count(), 0, "tout est interne : rien ne s'enregistre dans la scène")
	var internal: Array[CollisionShape3D] = []
	for child: Node in room.get_children(true):
		if child is CollisionShape3D:
			internal.append(child as CollisionShape3D)
	assert_eq(internal.size(), room.plan.pieces.size() + 1, "une dalle et une boîte par morceau")
	for shape in internal:
		assert_true(shape.shape is BoxShape3D, "boîtes")


func test_queries_like_the_outdoor_ground() -> void:
	var room := _room(_small())
	assert_eq(room.height_at(3.0, 3.0), 0.0, "étage plat")
	assert_eq(room.material_at(2.5, 2.5), &"floor_planks_worn")
	assert_eq(room.material_at(6.0, 2.0), &"floor_tiles_bath")
	assert_eq(room.material_at(0.5, 0.5), &"", "hors des pièces")
	assert_eq(room.room_at(6.0, 2.0), &"b")
	assert_true(room.is_walkable(3.0, 3.0), "dans la pièce")
	assert_false(room.is_walkable(5.0, 2.0), "dans la cloison")
	assert_true(room.is_walkable(3.0, 4.95), "dans la porte vers le dehors")
	assert_false(room.is_walkable(2.0, 4.95), "dans le mur sud")
	assert_false(room.is_walkable(0.5, 3.0), "dehors")


## Construction de l'étage d'essai (40 × 24 m, 11 pièces) : rapide, aussi pour le Web.
func test_floor_builds_quickly() -> void:
	var json := JSON.new()
	json.data = _example()
	var times: Array[float] = []
	for _i in 3:
		var room := InteriorRoom.new()
		room.layout = json
		var start := Time.get_ticks_usec()
		add_child(room)
		times.append((Time.get_ticks_usec() - start) / 1000.0)
		room.free()
	times.sort()
	gut.p("construction de l'étage d'essai : %.1f ms (médiane de 3)" % times[1])
	assert_lt(times[1], 400.0, "construction en moins de 400 ms (bureau, sans écran)")


func test_door_position_is_on_its_wall() -> void:
	var room := _room(_example())
	assert_eq(room.door_position(&"entree"), Vector3(19.0, 0.0, 21.0), "porte d'entrée")
	assert_eq(room.door_position(&"crypte"), Vector3(36.5, 0.0, 2.0), "descente vers la crypte")
	assert_eq(room.door_position(&"nulle_part"), Vector3.INF)


func test_interior_shaders_compile() -> void:
	for path: String in [
		"res://src/world/shaders/interior.gdshader",
		"res://src/world/shaders/interior_panel.gdshader"
	]:
		var shader := load(path) as Shader
		var names: Array[String] = []
		for uniform: Dictionary in shader.get_shader_uniform_list():
			names.append(String(uniform["name"]))
		for wanted: String in ["cut_line", "window_light", "lamp_light", "albedo_texture"]:
			assert_has(names, wanted, "%s : %s" % [path, wanted])
		assert_string_contains(shader.code, "pixel_art", "%s : pixel art filtré" % path)


# --- Meubles du lot I ------------------------------------------------------------------------


func _furniture_entries() -> Array[Dictionary]:
	var json := JSON.new()
	json.parse(FileAccess.get_file_as_string(MANIFEST))
	var out: Array[Dictionary] = []
	for entry: Dictionary in json.data["images"]:
		var path := String(entry["path"])
		var rug := path.begins_with("assets/hd2d/decals/") and String(entry.get("lot", "")) == "I"
		if path.begins_with("assets/hd2d/interior/props/") or rug:
			out.append(entry)
	return out


func test_furniture_scenes_are_interior_panels_with_their_footprint() -> void:
	var entries := _furniture_entries()
	assert_gt(entries.size(), 40, "meubles et tapis du lot I")
	var problems: Array[String] = []
	for entry in entries:
		var image_name := String(entry["path"]).get_file().get_basename()
		var path := "%s/%s.tscn" % [PROPS_DIR, image_name]
		if not ResourceLoader.exists(path):
			problems.append("%s absente" % path)
			continue
		var node := (load(path) as PackedScene).instantiate()
		add_child(node)
		problems.append_array(_furniture_problems(node, entry, image_name))
		node.free()
	assert_eq(problems, [] as Array[String])


func _furniture_problems(node: Node, entry: Dictionary, label: String) -> Array[String]:
	var problems: Array[String] = []
	var image := "res://" + String(entry["path"])
	if String(entry["kind"]) == "decal":
		var decal := node as GroundDecal
		if decal == null or decal.texture.resource_path != image or decal.follow_ground:
			problems.append("%s : GroundDecal à plat sur son image" % label)
		if node.get_node_or_null(^"Collision") != null:
			problems.append("%s : un tapis se traverse" % label)
		return problems
	var panel := node as InteriorPanel
	if panel == null or panel.texture == null or panel.texture.resource_path != image:
		problems.append("%s : InteriorPanel sur son image" % label)
		return problems
	var body := node.get_node_or_null(^"Collision") as StaticBody3D
	var shape: CollisionShape3D = body.get_child(0) as CollisionShape3D if body != null else null
	var box: BoxShape3D = shape.shape as BoxShape3D if shape != null else null
	if box == null or body.collision_layer != 1 or body.collision_mask != 0:
		problems.append("%s : boîte de collision, couche 1, masque 0" % label)
		return problems
	var size := panel.size_m()
	if not is_equal_approx(box.size.z, panel.image_offset.z * 2.0) or box.size.x > size.x:
		problems.append("%s : l'emprise va de l'image (bord sud) vers le nord" % label)
	if not is_equal_approx(shape.position.y, box.size.y / 2.0) or box.size.y < size.y - 0.01:
		problems.append("%s : boîte posée au sol, de la hauteur de l'image" % label)
	var wall_mounted := box.size.z < 0.3
	var cut_like_wall := is_equal_approx(panel.cut_height, InteriorRoom.CUT_HEIGHT)
	if wall_mounted != cut_like_wall:
		problems.append("%s : coupé comme le mur si et seulement s'il y est plaqué" % label)
	var quad := panel.get_child(0, true) as MeshInstance3D
	var material := quad.material_override as ShaderMaterial
	if material == null or material.shader != InteriorRoom.PANEL_SHADER:
		problems.append("%s : matériau des intérieurs" % label)
	var uv2: PackedVector2Array = quad.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV2]
	if uv2.is_empty() or not is_equal_approx(uv2[0].x, panel.front_z()):
		problems.append("%s : coordonnée de coupe = bord sud" % label)
	return problems
