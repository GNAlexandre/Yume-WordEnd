extends GutTest
## (E4) Navigation des PNJ (LifeNav, LifeActor, LifeDirector) : d'une pièce à l'autre par la porte
## (intérieur d'essai), autour d'un meuble, deux PNJ qui se croisent dans un couloir d'un mètre et
## demi, jamais coincés (délai, puis on se replace) ; praticabilité relevée = celle du sol
## (InteriorRoom.is_walkable, MapGround.is_walkable).

const RDC_SCENE := "res://src/world/maps/entrepot_rdc_essai/entrepot_rdc_essai.tscn"
const RELIEF_SCENE := "res://src/world/maps/essai_relief/essai_relief.tscn"
const PROP_BATCHER := preload("res://src/world/prop_batcher.gd")

var _map: Map


func before_each() -> void:
	GameState.reset()


func after_each() -> void:
	LifeDirector.attach(null)
	_map = null


func _instance(path: String) -> Map:
	var map := (load(path) as PackedScene).instantiate() as Map
	add_child_autofree(map)
	return map


## Carte plate de 20 × 6 m : un couloir est-ouest d'1,5 m de large (murs en z 1,3-1,5 et
## 3,0-3,2), une table de 2 × 1 m dans une salle au sud (z 4 à 6), ouverte sur le couloir à l'est.
func _corridor_map() -> Map:
	var map := Map.new()
	map.name = "essai_couloir"
	map.size = Vector2(20.0, 8.0)
	var ground := StaticBody3D.new()
	ground.name = "Ground"
	ground.add_child(_shape(Vector3(20.0, 0.2, 8.0), Vector3(10.0, -0.1, 4.0)))
	map.add_child(ground)
	var geometry := Node3D.new()
	geometry.name = "Geometry"
	geometry.set_script(PROP_BATCHER)
	map.add_child(geometry)
	for wall: Array in [
		[Vector3(20.0, 2.0, 0.2), Vector3(10.0, 1.0, 1.4)],
		[Vector3(16.0, 2.0, 0.2), Vector3(8.0, 1.0, 3.1)],
		[Vector3(2.0, 1.0, 1.0), Vector3(8.0, 0.5, 5.5)],
	]:
		var body := StaticBody3D.new()
		body.add_child(_shape(wall[0], wall[1]))
		geometry.add_child(body)
	for child_name: String in ["Markers", "Exits", "Life"]:
		var node := Node3D.new()
		node.name = child_name
		map.add_child(node)
	add_child_autofree(map)
	return map


func _shape(box_size: Vector3, at: Vector3) -> CollisionShape3D:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = box_size
	shape.shape = box
	shape.position = at
	return shape


func _path_is_clear(nav: LifeNav, from: Vector3, path: PackedVector3Array) -> bool:
	var previous := from
	for point: Vector3 in path:
		if not nav.line_clear(previous, point):
			gut.p("segment bloqué %s → %s" % [previous, point])
			return false
		previous = point
	return true


func test_walkability_matches_the_interior_ground() -> void:
	_map = _instance(RDC_SCENE)
	var room := _map.get_node(^"Ground") as InteriorRoom
	var nav := LifeNav.for_map(_map)
	nav.build_now()
	assert_true(nav.ready)
	assert_eq(nav.cell, LifeNav.INDOOR_CELL, "un demi-mètre dedans")
	var mismatches := 0
	for i: int in 400:
		var x := 2.0 + fmod(i * 7.37, 36.0)
		var z := 2.0 + fmod(i * 3.11, 20.0)
		if nav._sample_walkable(x, z) != room.is_walkable(x, z):
			mismatches += 1
	assert_eq(mismatches, 0, "relevé = InteriorRoom.is_walkable")
	gut.p("intérieur : %d cases libres, %.1f ms" % [nav.open_count(), nav.build_usec / 1000.0])


func test_walkability_matches_the_outdoor_ground() -> void:
	_map = _instance(RELIEF_SCENE)
	var ground := _map.get_node(^"Ground") as MapGround
	var nav := LifeNav.for_map(_map)
	nav.build_now()
	assert_eq(nav.cell, LifeNav.OUTDOOR_CELL, "un mètre dehors")
	for i: int in 200:
		var x := fmod(i * 7.37, 60.0)
		var z := fmod(i * 3.11, 45.0)
		assert_eq(nav._sample_walkable(x, z), ground.is_walkable(x, z), "(%.1f, %.1f)" % [x, z])
	# De la prairie au belvédère : par l'escalier et la rampe, jamais par la falaise.
	var path := nav.find_path(Vector3(31.5, 0.0, 42.0), Vector3(44.0, 3.0, 7.5))
	assert_false(path.is_empty(), "un chemin jusqu'au plateau")
	assert_true(_path_is_clear(nav, Vector3(31.5, 0.0, 42.0), path))
	var on_stairs := false
	for point: Vector3 in path:
		on_stairs = (
			on_stairs or (point.x > 23.5 and point.x < 27.5 and point.z > 27.5 and point.z < 31.5)
		)
	assert_true(on_stairs, "par l'escalier de dalles")
	gut.p("dehors : %d cases libres, %.1f ms" % [nav.open_count(), nav.build_usec / 1000.0])


func test_from_room_to_room_through_the_door() -> void:
	_map = _instance(RDC_SCENE)
	var nav := LifeNav.for_map(_map)
	nav.build_now()
	var from := Vector3(5.0, 0.0, 6.5)
	var to := Vector3(24.5, 0.0, 8.5)
	var path := nav.find_path(from, to)
	assert_false(path.is_empty(), "du réfectoire à la salle de lecture")
	assert_true(_path_is_clear(nav, from, path), "aucun segment ne traverse un mur")
	assert_false(nav.line_clear(from, to), "en ligne droite, le mur")
	var in_corridor := false
	for point: Vector3 in path:
		in_corridor = in_corridor or (point.z > 10.0 and point.z < 13.0)
	assert_true(in_corridor, "par le couloir")


func test_around_a_piece_of_furniture() -> void:
	_map = _corridor_map()
	var nav := LifeNav.for_map(_map)
	nav.build_now()
	var from := Vector3(8.0, 0.0, 4.4)
	var to := Vector3(8.0, 0.0, 6.6)
	assert_false(nav.line_clear(from, to), "la table entre les deux")
	var path := nav.find_path(from, to)
	assert_false(path.is_empty())
	assert_true(_path_is_clear(nav, from, path), "autour de la table")
	assert_gt(path.size(), 1, "un détour")


func test_two_npcs_cross_in_a_corridor_one_and_a_half_meters_wide() -> void:
	_map = _corridor_map()
	LifeDirector.attach(_map)
	LifeDirector.build_nav_now()
	var west := LifeDirector.spawn_actor(&"fairy_01", Vector3(2.0, 0.0, 2.25))
	var east := LifeDirector.spawn_actor(&"fairy_02", Vector3(14.0, 0.0, 2.25))
	assert_not_null(west)
	assert_not_null(east)
	west.walk_to(Vector3(14.0, 0.0, 2.25), Vector3.RIGHT, &"marche", Callable())
	east.walk_to(Vector3(2.0, 0.0, 2.25), Vector3.LEFT, &"marche", Callable())
	var closest := INF
	for _i: int in 900:
		await wait_physics_frames(1)
		closest = minf(closest, west.position().distance_to(east.position()))
		if not west.is_moving() and not east.is_moving():
			break
	assert_false(west.is_moving() or east.is_moving(), "toutes deux arrivées")
	assert_lt(west.position().distance_to(Vector3(14.0, 0.0, 2.25)), 0.1)
	assert_lt(east.position().distance_to(Vector3(2.0, 0.0, 2.25)), 0.1)
	assert_gt(closest, 0.3, "elles se sont écartées (au plus près : %.2f m)" % closest)
	for who: LifeActor in [west, east]:
		assert_lt(who.stuck_time, 100.0)


func test_never_stuck_a_delay_then_back_in_place() -> void:
	_map = _corridor_map()
	LifeDirector.attach(_map)
	LifeDirector.build_nav_now()
	# Une petite arrêtée au milieu d'un couloir d'une case : impossible de passer.
	var blocker := LifeDirector.spawn_actor(&"fairy_03", Vector3(8.0, 0.0, 2.25))
	var walker := LifeDirector.spawn_actor(&"fairy_04", Vector3(3.0, 0.0, 2.25))
	assert_not_null(blocker)
	walker.stuck_time = 1.5
	walker.walk_to(Vector3(13.0, 0.0, 2.25), Vector3.RIGHT, &"marche", Callable())
	var arrived := false
	for _i: int in 600:
		await wait_physics_frames(1)
		if not walker.is_moving():
			arrived = true
			break
	assert_true(arrived, "pas coincée pour toujours")
	assert_lt(walker.position().distance_to(Vector3(13.0, 0.0, 2.25)), 0.1, "replacée au but")
