extends GutTest
## (E2) Le vrai joueur (player.tscn, appuis réels) sur la carte de démonstration du sol en relief
## (essai_relief) : il gravit l'escalier et la rampe, la falaise et le muret l'arrêtent, il ne
## marche pas sur l'eau dormante, ne tombe pas dans le vide ; il saute sur une butte de 0,5 m.

const MAP_SCENE := "res://src/world/maps/essai_relief/essai_relief.tscn"
const PLAYER_SCENE := preload("res://src/player/player.tscn")
const MOVES: Array[StringName] = [&"move_left", &"move_right", &"move_forward", &"move_back"]

var _map: Node3D
var _ground: MapGround
var _player: Player


func before_each() -> void:
	GameState.reset()
	_map = (load(MAP_SCENE) as PackedScene).instantiate() as Node3D
	add_child_autofree(_map)
	_ground = _map.get_node(^"Ground") as MapGround
	_player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(_player)
	await wait_physics_frames(2)


func after_each() -> void:
	for action: StringName in MOVES:
		Input.action_release(action)
	Input.action_release(&"jump")


## Pose le joueur au sol en (x, z), immobile.
func _place(x: float, z: float) -> void:
	_player.global_position = Vector3(x, _ground.height_at(x, z) + 0.05, z)
	_player.velocity = Vector3.ZERO
	_player.reset_physics_interpolation()


## Marche vers direction (plan x, z) pendant frames images physiques.
func _walk(direction: Vector2, frames: int) -> void:
	var flat := direction.normalized()
	_hold(&"move_right", flat.x)
	_hold(&"move_left", -flat.x)
	_hold(&"move_back", flat.y)
	_hold(&"move_forward", -flat.y)
	await wait_physics_frames(frames)
	for action: StringName in MOVES:
		Input.action_release(action)
	await wait_physics_frames(20)


func _hold(action: StringName, strength: float) -> void:
	if strength > 0.001:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)


func test_the_player_climbs_the_stairs() -> void:
	_place(25.5, 33.5)
	await wait_physics_frames(5)
	assert_almost_eq(_player.global_position.y, 0.0, 0.05, "au pied de l'escalier")
	await _walk(Vector2(0.0, -1.0), 150)
	var at := _player.global_position
	assert_lt(at.z, 27.0, "en haut de l'escalier (z = %.2f)" % at.z)
	assert_almost_eq(at.y, 1.5, 0.05, "sur la terrasse à 1,5 m")


func test_the_player_walks_up_the_ramp() -> void:
	_place(47.5, 18.0)
	await wait_physics_frames(5)
	await _walk(Vector2(0.0, -1.0), 130)
	var at := _player.global_position
	assert_lt(at.z, 11.5, "en haut de la rampe (z = %.2f)" % at.z)
	assert_almost_eq(at.y, 3.0, 0.05, "sur le plateau à 3 m")


func test_the_rock_cliff_and_the_wall_stop_the_player() -> void:
	_place(10.0, 21.0)
	await wait_physics_frames(5)
	await _walk(Vector2(0.0, -1.0), 90)
	var at := _player.global_position
	assert_gt(at.z, 18.2, "arrêté au pied de la falaise (z = %.2f)" % at.z)
	assert_almost_eq(at.y, 0.0, 0.05, "toujours en bas")
	_place(45.0, 33.0)
	await wait_physics_frames(5)
	await _walk(Vector2(0.0, -1.0), 90)
	at = _player.global_position
	assert_gt(at.z, 30.2, "arrêté au pied du muret (z = %.2f)" % at.z)
	assert_almost_eq(at.y, 0.0, 0.05, "toujours en bas")


func test_still_water_and_the_void_stop_the_player() -> void:
	_place(10.5, 36.5)
	await wait_physics_frames(5)
	await _walk(Vector2(0.0, -1.0), 90)
	var at := _player.global_position
	assert_true(_ground.is_walkable(at.x, at.z), "jamais sur l'eau (%.2f, %.2f)" % [at.x, at.z])
	assert_gt(at.z, 32.5, "arrêté au bord de la mare")
	_place(45.0, 6.5)
	await wait_physics_frames(5)
	await _walk(Vector2(0.0, -1.0), 120)
	at = _player.global_position
	assert_almost_eq(at.y, 3.0, 0.05, "toujours sur le plateau")
	assert_ne(_ground.height_at(at.x, at.z), MapGround.VOID_HEIGHT, "pas dans le vide")
	assert_true(_player.is_on_floor(), "au sol")


func test_a_half_meter_step_is_jumped() -> void:
	_place(42.0, 39.0)
	await wait_physics_frames(5)
	assert_almost_eq(_player.global_position.y, 0.0, 0.05, "au pied de la butte")
	# Sans sauter, le talus de 0,5 m arrête.
	await _walk(Vector2(1.0, 0.0), 60)
	assert_almost_eq(_player.global_position.y, 0.0, 0.05, "le talus arrête la marche")
	# En sautant, on monte sur la butte.
	_hold(&"move_right", 1.0)
	Input.action_press(&"jump")
	await wait_physics_frames(3)
	Input.action_release(&"jump")
	await wait_physics_frames(60)
	Input.action_release(&"move_right")
	await wait_physics_frames(20)
	assert_almost_eq(_player.global_position.y, 0.5, 0.05, "sur la butte à 0,5 m")
