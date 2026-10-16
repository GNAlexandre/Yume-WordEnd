extends GutTest
## WorldManager (L2, (F1) sur une carte : les zones de l'ancienne île sont parties) : enter_map
## sans doublon, joueur posé au sol sous un marqueur (y compris trop haut ou un peu enterré, en
## ignorant les corps non statiques), rattrapage au dernier point sûr, réapparition différée au
## marqueur d'arrivée. La carte d'essai en relief (essai_relief, sol MapGround) sert de terrain.

const PLAYER_STUB := preload("res://tests/stubs/player_stub.tscn")
const RELIEF := &"essai_relief"

var _slot: Node3D
var _player: CharacterBody3D
var _respawn_delay: float


func before_each() -> void:
	GameState.reset()
	_respawn_delay = WorldManager.respawn_delay
	_slot = Node3D.new()
	_slot.name = "World"
	_slot.add_to_group(WorldManager.MAP_SLOT_GROUP)
	add_child(_slot)
	_player = add_child_autofree(PLAYER_STUB.instantiate())
	assert_true(WorldManager.enter_map(RELIEF), "carte posée")
	await wait_physics_frames(2)


func after_each() -> void:
	WorldManager.respawn_delay = _respawn_delay
	_slot.free()
	GameState.reset()


func _map() -> Map:
	return WorldManager.current_map_node()


func _ground() -> MapGround:
	return _map().get_node(^"Ground") as MapGround


## Ajoute un marqueur temporaire à la carte, à la position donnée.
func _add_marker(marker_name: String, at: Vector3) -> Marker3D:
	var marker := Marker3D.new()
	marker.name = marker_name
	_map().get_node(^"Markers").add_child(marker)
	marker.global_position = at
	return marker


## Vrai si le sol est praticable et à la même hauteur dans un rayon de radius m autour de p.
func _flat_around(p: Vector2, radius: float) -> bool:
	var level := _ground().level_at(p.x, p.y)
	for offset: Vector2 in [Vector2.ZERO, Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		var q := p + offset * radius
		if not _ground().is_walkable(q.x, q.y) or _ground().level_at(q.x, q.y) != level:
			return false
	return true


## Point le plus haut du relief, sur un palier plat, loin de tout décor qui bloque.
func _high_point() -> Vector2:
	var best := Vector2(30.0, 22.0)
	var best_height := -INF
	var area := _map().area()
	var blockers: Array[Vector2] = []
	for node: Node in _map().get_node(^"Geometry").find_children("*", "StaticBody3D", true, false):
		var at := (node as Node3D).global_position
		blockers.append(Vector2(at.x, at.z))
	for x: int in range(int(area.position.x) + 6, int(area.end.x) - 6):
		for z: int in range(int(area.position.y) + 6, int(area.end.y) - 6):
			var p := Vector2(x, z)
			var clear := true
			for blocker: Vector2 in blockers:
				if blocker.distance_to(p) < 4.0:
					clear = false
					break
			var height := _ground().height_at(p.x, p.y)
			if clear and _flat_around(p, 2.0) and height > best_height:
				best_height = height
				best = p
	return best


func test_enter_map_keeps_a_single_map() -> void:
	assert_eq(WorldManager.current_map(), RELIEF)
	assert_true(WorldManager.enter_map(RELIEF), "même carte : seul le joueur bouge")
	assert_eq(get_tree().get_nodes_in_group(Map.GROUP).size(), 1, "pas de doublon")
	assert_eq(GameState.map, RELIEF)


func test_marker_in_the_air_lands_on_the_ground() -> void:
	var top := _high_point()
	var ground := _ground().height_at(top.x, top.y)
	assert_gt(ground, 1.0, "un plateau")
	_add_marker("HighMarker", Vector3(top.x, ground + 12.0, top.y))
	assert_true(WorldManager.enter_map(RELIEF, &"HighMarker"))
	assert_almost_eq(_player.global_position.y, ground + WorldManager.GROUND_CLEARANCE, 0.15)
	assert_eq(WorldManager.arrival_marker(), &"HighMarker")


func test_slightly_buried_marker_lands_on_top() -> void:
	var top := _high_point()
	var ground := _ground().height_at(top.x, top.y)
	_add_marker("BuriedMarker", Vector3(top.x, ground - 1.0, top.y))
	assert_true(WorldManager.enter_map(RELIEF, &"BuriedMarker"))
	assert_almost_eq(_player.global_position.y, ground, 0.2, "ressorti au-dessus du sol")


func test_placement_ignores_characters_standing_on_the_marker() -> void:
	var npc := CharacterBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.0, 1.6, 1.0)
	shape.shape = box
	shape.position = Vector3(0.0, 0.8, 0.0)
	npc.add_child(shape)
	add_child_autofree(npc)
	var spawn := _map().spawn()
	var ground := _ground().height_at(spawn.global_position.x, spawn.global_position.z)
	npc.global_position = Vector3(spawn.global_position.x, ground, spawn.global_position.z)
	await wait_physics_frames(2)
	assert_true(WorldManager.enter_map(RELIEF))
	assert_almost_eq(_player.global_position.y, ground, 0.15, "au sol, pas sur la tête du PNJ")


func test_ground_position_without_ground_keeps_the_point() -> void:
	var far := Vector3(500.0, 3.0, 500.0)
	assert_eq(WorldManager.ground_position(far, _player), far)
	assert_eq(WorldManager.ground_position(far, null), far)


func test_rescue_brings_the_player_back_to_the_last_safe_point() -> void:
	var safe := WorldManager.last_safe_point()
	assert_lt(_player.global_position.distance_to(safe), 0.05, "le point d'arrivée est sûr")
	watch_signals(WorldManager)
	_player.global_position = Vector3(500.0, -40.0, 500.0)
	WorldManager.rescue()
	assert_lt(_player.global_position.distance_to(safe), 0.05, "au dernier point sûr")
	assert_signal_emitted_with_parameters(WorldManager, "rescued", [RELIEF])


func test_player_died_respawns_at_the_arrival_marker_after_delay() -> void:
	WorldManager.respawn_delay = 0.1
	var spawn := _map().spawn()
	_player.global_position = spawn.global_position + Vector3(8.0, 0.0, 4.0)
	watch_signals(EventBus)
	EventBus.player_died.emit()
	await wait_physics_frames(1)
	assert_signal_not_emitted(EventBus, "player_respawned", "pas avant le délai")
	await wait_seconds(0.3)
	assert_signal_emitted(EventBus, "player_respawned")
	var flat := Vector2(_player.global_position.x, _player.global_position.z)
	assert_lt(flat.distance_to(Vector2(spawn.global_position.x, spawn.global_position.z)), 0.05)
