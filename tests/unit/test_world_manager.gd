extends GutTest
## WorldManager (L2) : load_zone sans doublon, téléportation posée au sol (y compris depuis un
## marqueur trop haut ou un peu enterré, en ignorant les corps non statiques), rattrapage,
## réapparition différée au village, noms affichés.

const FIXTURE := preload("res://tests/stubs/l2_island_fixture.gd")
const PLAYER_STUB := preload("res://tests/stubs/player_stub.tscn")

var _island: Node3D
var _player: CharacterBody3D
var _respawn_delay: float
var _markers: Array[Node] = []


func before_all() -> void:
	_island = FIXTURE.island()
	add_child(_island)


func after_all() -> void:
	_island.free()
	GameState.reset()


func before_each() -> void:
	GameState.reset()
	_respawn_delay = WorldManager.respawn_delay
	_player = add_child_autofree(PLAYER_STUB.instantiate())
	await wait_physics_frames(2)


func after_each() -> void:
	WorldManager.respawn_delay = _respawn_delay
	for marker in _markers:
		marker.free()
	_markers.clear()


## Ajoute un marqueur temporaire à la zone, à la position globale donnée.
func _add_marker(zone_id: String, marker_name: String, at: Vector3) -> Marker3D:
	var marker := Marker3D.new()
	marker.name = marker_name
	_island.get_node("Zones/" + zone_id).add_child(marker)
	marker.global_position = at
	_markers.append(marker)
	return marker


func test_load_zone_is_a_no_op_when_the_zone_is_present() -> void:
	var before := get_tree().get_nodes_in_group(&"zones").size()
	WorldManager.load_zone(&"forest")
	WorldManager.load_zone(&"")
	assert_eq(get_tree().get_nodes_in_group(&"zones").size(), before, "pas de doublon")


func test_teleport_from_a_marker_in_the_air_lands_on_the_ground() -> void:
	var top := IslandTerrain.HILL_CENTER
	_add_marker("hill", "HighMarker", Vector3(top.x + 2.0, 14.0, top.y + 0.5))
	WorldManager.teleport(&"hill", &"HighMarker")
	var ground := IslandTerrain.height_at(top.x + 2.0, top.y + 0.5)
	assert_almost_eq(ground, IslandTerrain.HILL_HEIGHT, 0.01, "sommet de la colline")
	assert_almost_eq(_player.global_position.y, ground + WorldManager.GROUND_CLEARANCE, 0.15)


func test_teleport_from_a_slightly_buried_marker_lands_on_top() -> void:
	var p := Vector2(44.0, -3.0)
	var ground := IslandTerrain.height_at(p.x, p.y)
	assert_gt(ground, 2.0, "flanc de la colline")
	_add_marker("hill", "BuriedMarker", Vector3(p.x, ground - 1.0, p.y))
	WorldManager.teleport(&"hill", &"BuriedMarker")
	assert_almost_eq(_player.global_position.y, ground, 0.2, "ressorti au-dessus du sol")


func test_teleport_ignores_characters_standing_on_the_marker() -> void:
	var npc := CharacterBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.0, 1.6, 1.0)
	shape.shape = box
	shape.position = Vector3(0.0, 0.8, 0.0)
	npc.add_child(shape)
	add_child_autofree(npc)
	var spawn := _island.get_node(^"Zones/village/Spawn") as Node3D
	npc.global_position = Vector3(spawn.global_position.x, 0.0, spawn.global_position.z)
	await wait_physics_frames(2)
	WorldManager.teleport(&"village")
	assert_almost_eq(_player.global_position.y, 0.0, 0.15, "au sol, pas sur la tête du PNJ")


func test_ground_position_without_ground_keeps_the_point() -> void:
	var far := Vector3(500.0, 3.0, 500.0)
	assert_eq(WorldManager.ground_position(far, _player), far)
	assert_eq(WorldManager.ground_position(far, null), far)


func test_rescue_falls_back_to_the_village_for_an_unknown_zone() -> void:
	EventBus.zone_entered.emit(&"nowhere")
	_player.global_position = Vector3(60.0, 5.0, -60.0)
	WorldManager.rescue()
	var spawn := _island.get_node(^"Zones/village/Spawn") as Node3D
	var flat := Vector2(_player.global_position.x, _player.global_position.z)
	assert_lt(flat.distance_to(Vector2(spawn.global_position.x, spawn.global_position.z)), 0.05)


func test_player_died_respawns_at_village_after_delay() -> void:
	WorldManager.respawn_delay = 0.1
	WorldManager.teleport(&"dunes", &"SpawnW")
	await wait_physics_frames(2)
	watch_signals(EventBus)
	EventBus.player_died.emit()
	await wait_physics_frames(1)
	assert_signal_not_emitted(EventBus, "player_respawned", "pas avant le délai")
	await wait_seconds(0.3)
	assert_signal_emitted(EventBus, "player_respawned")
	var spawn := _island.get_node(^"Zones/village/Spawn") as Node3D
	var flat := Vector2(_player.global_position.x, _player.global_position.z)
	assert_lt(flat.distance_to(Vector2(spawn.global_position.x, spawn.global_position.z)), 0.05)


func test_zone_display_name_falls_back_to_the_id() -> void:
	assert_eq(WorldManager.zone_display_name(&"dunes"), "Dunes au couchant")
	assert_eq(WorldManager.zone_display_name(&"nowhere"), "nowhere")
