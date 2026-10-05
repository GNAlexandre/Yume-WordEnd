extends GutTest
## Lot 1 — déplacement du joueur : vecteur relatif à la caméra, marche et course, accélération,
## saut, obstacles et pentes, blocages (Combat.is_busy(), dialogue), relais de combat, visée,
## animations, recul et réapparition. Le joueur est piloté par tick() avec des commandes
## fabriquées, enchaînés dans une même image physique (vraie physique, pas d'attente) ; Combat
## est le stub l1_combat_stub.

const PLAYER := preload("res://src/player/player.tscn")
const CombatStub := preload("res://tests/stubs/l1_combat_stub.gd")
const DT := 1.0 / 60.0
const EPS := Vector3(0.001, 0.001, 0.001)
const FORWARD_INPUT := Vector2(0, -1)


func before_each() -> void:
	GameState.reset()


func after_each() -> void:
	Input.action_release(&"move_forward")


func after_all() -> void:
	GameState.reset()


# --- Outils -----------------------------------------------------------------------------------


func _spawn_player(at: Vector3 = Vector3.ZERO) -> Player:
	var player: Player = PLAYER.instantiate()
	player.get_node(^"Combat").set_script(CombatStub)
	player.position = at
	add_child_autofree(player)
	player.set_physics_process(false)
	return player


## move_and_slide() n'avance du pas physique (1/60 s) que dans une image physique (ailleurs, il
## prend le delta de l'image idle) : les tests en attendent une, puis enchaînent les tick().
func _in_physics_frame() -> void:
	await wait_physics_frames(1)
	assert_true(Engine.is_in_physics_frame(), "tick() appelé dans une image physique")


func _stub(player: Player) -> CombatStub:
	return player.combat as CombatStub


func _add_box(size: Vector3, xform: Transform3D, layer: int = 1) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = layer
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.transform = xform
	add_child_autofree(body)
	return body


func _add_floor() -> void:
	_add_box(Vector3(80, 1, 80), Transform3D(Basis.IDENTITY, Vector3(0, -0.5, 0)))


## Rampe de angle_deg degrés qui monte vers −Z ; son bord bas est au sol en z = -2.
func _add_ramp(angle_deg: float) -> void:
	var theta := deg_to_rad(angle_deg)
	var length := 8.0
	var thickness := 0.5
	var center_y := length * 0.5 * sin(theta) - thickness * 0.5 * cos(theta)
	var center_z := -2.0 - (thickness * 0.5 * sin(theta) + length * 0.5 * cos(theta))
	_add_box(
		Vector3(3, thickness, length),
		Transform3D(Basis(Vector3.RIGHT, theta), Vector3(0, center_y, center_z))
	)


func _commands(move: Vector2 = Vector2.ZERO, run: bool = false) -> Player.Commands:
	var commands := Player.Commands.new()
	commands.move = move
	commands.run = run
	return commands


func _ticks(player: Player, count: int, move: Vector2 = Vector2.ZERO, run: bool = false) -> void:
	for _i in count:
		player.tick(DT, _commands(move, run))


func _horizontal_speed(player: Player) -> float:
	return Vector2(player.velocity.x, player.velocity.z).length()


# --- Vecteur de déplacement relatif à la caméra (fonction pure) --------------------------------


func test_move_direction_follows_camera_yaw() -> void:
	var north := Basis.IDENTITY
	assert_almost_eq(Player.move_direction(FORWARD_INPUT, north), Vector3(0, 0, -1), EPS)
	assert_almost_eq(Player.move_direction(Vector2(1, 0), north), Vector3(1, 0, 0), EPS)
	assert_almost_eq(Player.move_direction(Vector2(0, 1), north), Vector3(0, 0, 1), EPS)
	var west := Basis(Vector3.UP, PI / 2.0)
	assert_almost_eq(Player.move_direction(FORWARD_INPUT, west), Vector3(-1, 0, 0), EPS)
	assert_almost_eq(Player.move_direction(Vector2(1, 0), west), Vector3(0, 0, -1), EPS)
	assert_almost_eq(Player.move_direction(Vector2(-1, 0), west), Vector3(0, 0, 1), EPS)


func test_move_direction_stays_on_ground_plane_and_keeps_stick_strength() -> void:
	var south_looking_down := Basis(Vector3.UP, PI) * Basis(Vector3.RIGHT, deg_to_rad(-60))
	assert_almost_eq(
		Player.move_direction(FORWARD_INPUT, south_looking_down), Vector3(0, 0, 1), EPS
	)
	var top_down := Basis(Vector3.RIGHT, deg_to_rad(-90))
	assert_almost_eq(
		Player.move_direction(FORWARD_INPUT, top_down), Vector3(0, 0, -1), EPS, "vue de dessus"
	)
	var half := Player.move_direction(Vector2(0, -0.5), Basis.IDENTITY)
	assert_almost_eq(half.length(), 0.5, 0.001, "stick à moitié incliné : demi-vitesse")
	var diagonal := Player.move_direction(Vector2(1, -1).normalized(), Basis.IDENTITY)
	assert_almost_eq(diagonal.length(), 1.0, 0.001, "diagonale : pas plus rapide")
	assert_eq(Player.move_direction(Vector2.ZERO, Basis.IDENTITY), Vector3.ZERO)


# --- Marche, course, accélération, saut ---------------------------------------------------------


func test_walks_at_4_and_runs_at_7_relative_to_camera() -> void:
	_add_floor()
	var player := _spawn_player()
	await _in_physics_frame()
	_ticks(player, 60, FORWARD_INPUT)
	assert_almost_eq(_horizontal_speed(player), 4.0, 0.01, "marche à 4 m/s")
	assert_lt(player.position.z, -3.0, "avance vers l'avant de la caméra (−Z)")
	assert_false(player.is_running())
	_ticks(player, 60, FORWARD_INPUT, true)
	assert_almost_eq(_horizontal_speed(player), 7.0, 0.01, "course à 7 m/s")
	assert_true(player.is_running())
	player.camera_rig.rotate_view(PI / 2.0, 0.0)
	_ticks(player, 30, FORWARD_INPUT)
	assert_almost_eq(player.velocity.normalized(), Vector3(-1, 0, 0), EPS * 10, "caméra tournée")


func test_acceleration_is_smooth_but_reactive() -> void:
	_add_floor()
	var player := _spawn_player()
	await _in_physics_frame()
	_ticks(player, 1)
	_ticks(player, 2, FORWARD_INPUT, true)
	var early := _horizontal_speed(player)
	assert_between(early, 0.5, 3.0, "démarrage progressif")
	_ticks(player, 10, FORWARD_INPUT, true)
	assert_almost_eq(_horizontal_speed(player), 7.0, 0.01, "pleine vitesse en moins de 0,25 s")
	_ticks(player, 2)
	assert_between(_horizontal_speed(player), 3.0, 6.5, "arrêt progressif")
	_ticks(player, 8)
	assert_almost_eq(
		_horizontal_speed(player), 0.0, 0.001, "arrêt en moins de 0,2 s : pas de glisse"
	)


func test_jump_then_gravity_brings_player_back_to_floor() -> void:
	_add_floor()
	var player := _spawn_player()
	await _in_physics_frame()
	_ticks(player, 2)
	assert_true(player.is_on_floor(), "au sol")
	var jump := _commands()
	jump.jump = true
	jump.jump_held = true
	player.tick(DT, jump)
	assert_almost_eq(player.velocity.y, player.jump_velocity, 0.5, "impulsion du saut")
	var highest := 0.0
	for _i in 90:
		player.tick(DT, _commands())
		highest = maxf(highest, player.position.y)
	assert_between(highest, 0.8, 1.2, "saut d'environ 1 m")
	assert_true(player.is_on_floor(), "retombé au sol")
	assert_almost_eq(player.position.y, 0.0, 0.05)


func test_real_input_drives_player_through_physics_process() -> void:
	_add_floor()
	var player: Player = PLAYER.instantiate()
	player.get_node(^"Combat").set_script(CombatStub)
	add_child_autofree(player)
	await wait_physics_frames(2)
	var start := player.global_position
	Input.action_press(&"move_forward")
	await wait_physics_frames(30)
	Input.action_release(&"move_forward")
	assert_lt(player.global_position.z, start.z - 1.0, "l'action move_forward fait avancer")
	assert_eq(player.visual.current_animation(), &"marche")


func test_game_state_position_follows_player_on_floor() -> void:
	_add_floor()
	var player := _spawn_player(Vector3(2, 0, 3))
	await _in_physics_frame()
	_ticks(player, 20, Vector2(1, 0))
	assert_true(player.is_on_floor())
	assert_almost_eq(GameState.position, player.global_position, EPS)


func test_joypad_run_button_latches_until_player_stops() -> void:
	_add_floor()
	var player := _spawn_player()
	await _in_physics_frame()
	var button := InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_LEFT_STICK
	button.pressed = true
	player._unhandled_input(button)
	_ticks(player, 30, FORWARD_INPUT)
	assert_true(player.is_running(), "L3 : course sans maintenir le bouton")
	assert_almost_eq(_horizontal_speed(player), 7.0, 0.01)
	_ticks(player, 2)
	_ticks(player, 30, FORWARD_INPUT)
	assert_false(player.is_running(), "la course s'arrête avec le joueur")


# --- Obstacles et pentes ------------------------------------------------------------------------


func test_does_not_go_through_obstacles() -> void:
	_add_floor()
	_add_box(Vector3(6, 2, 0.5), Transform3D(Basis.IDENTITY, Vector3(0, 1, -3)))
	var player := _spawn_player()
	await _in_physics_frame()
	_ticks(player, 120, FORWARD_INPUT, true)
	assert_gt(player.position.z, -2.8, "arrêté devant le mur (face avant en z = -2,75)")
	assert_lt(player.position.z, -2.3, "collé au mur")


func test_climbs_a_40_degree_slope() -> void:
	_add_floor()
	_add_ramp(40.0)
	var player := _spawn_player()
	await _in_physics_frame()
	var highest := 0.0
	for _i in 150:
		player.tick(DT, _commands(FORWARD_INPUT))
		highest = maxf(highest, player.position.y)
	assert_gt(highest, 2.0, "monte la pente de 40°")


func test_cannot_climb_a_50_degree_slope() -> void:
	_add_floor()
	_add_ramp(50.0)
	var player := _spawn_player()
	await _in_physics_frame()
	var highest := 0.0
	for _i in 150:
		player.tick(DT, _commands(FORWARD_INPUT, true))
		highest = maxf(highest, player.position.y)
	assert_lt(highest, 0.5, "bloqué au pied de la pente de 50°")
	assert_gt(player.position.z, -2.5, "pas de passage à travers la pente")


# --- Blocages -----------------------------------------------------------------------------------


func test_busy_combat_blocks_movement_jump_and_combat_input() -> void:
	_add_floor()
	var player := _spawn_player()
	await _in_physics_frame()
	_ticks(player, 2)
	var combat_stub := _stub(player)
	combat_stub.busy = true
	var start := player.position
	for _i in 30:
		var commands := _commands(FORWARD_INPUT, true)
		commands.jump = true
		commands.attack = true
		commands.charge_pressed = true
		commands.charge = true
		player.tick(DT, commands)
	assert_almost_eq(player.position, start, EPS, "immobile tant que Combat.is_busy()")
	assert_true(player.is_on_floor(), "pas de saut")
	assert_eq(combat_stub.calls, [] as Array[StringName], "ni attaque ni charge")
	var release := _commands()
	release.charge_released = true
	player.tick(DT, release)
	assert_eq(combat_stub.calls, [&"charge_release"] as Array[StringName], "le relâchement passe")
	combat_stub.busy = false
	combat_stub.calls.clear()
	var attack := _commands()
	attack.attack = true
	player.tick(DT, attack)
	assert_eq(
		combat_stub.calls, [&"attack"] as Array[StringName], "attaque dès que Combat est libre"
	)
	_ticks(player, 30, FORWARD_INPUT)
	assert_lt(player.position.z, start.z - 1.0, "repart quand Combat est libre")


func test_charge_held_during_attack_starts_when_combat_is_free() -> void:
	var player := _spawn_player()
	await _in_physics_frame()
	var combat_stub := _stub(player)
	combat_stub.busy = true
	for _i in 5:
		var held := _commands()
		held.charge = true
		player.tick(DT, held)
	assert_eq(combat_stub.calls, [] as Array[StringName])
	combat_stub.busy = false
	for _i in 5:
		var held := _commands()
		held.charge = true
		player.tick(DT, held)
	assert_eq(
		combat_stub.calls, [&"charge_begin"] as Array[StringName], "une seule fois, comme jeu.js"
	)
	var press := _commands()
	press.charge = true
	press.charge_pressed = true
	press.attack = true
	player.tick(DT, press)
	assert_eq(
		combat_stub.calls[-1], &"attack", "attaque prioritaire sur la charge dans la même image"
	)


func test_dialogue_blocks_movement_and_combat_input() -> void:
	_add_floor()
	var player := _spawn_player()
	await _in_physics_frame()
	_ticks(player, 10, FORWARD_INPUT)
	EventBus.dialogue_started.emit(&"l1_test")
	assert_true(player.is_in_dialogue())
	var start := player.position
	for _i in 20:
		var commands := _commands(FORWARD_INPUT, true)
		commands.attack = true
		commands.jump = true
		player.tick(DT, commands)
	assert_almost_eq(player.position, start, EPS, "le joueur s'arrête pendant le dialogue")
	assert_eq(_stub(player).calls, [] as Array[StringName], "pas d'attaque pendant le dialogue")
	EventBus.dialogue_ended.emit(&"l1_test")
	assert_false(player.is_in_dialogue())
	_ticks(player, 30, FORWARD_INPUT)
	assert_lt(player.position.z, start.z - 1.0, "il repart après dialogue_ended")


# --- Visée, animations ------------------------------------------------------------------------


func test_aim_follows_last_move_direction_and_turns_combat() -> void:
	_add_floor()
	var player := _spawn_player()
	await _in_physics_frame()
	assert_almost_eq(-player.combat.global_basis.z, Vector3(0, 0, -1), EPS, "visée initiale")
	_ticks(player, 5, Vector2(1, 0))
	assert_almost_eq(player.aim_direction(), Vector3(1, 0, 0), EPS)
	assert_almost_eq(-player.combat.global_basis.z, Vector3(1, 0, 0), EPS, "Combat −Z vers +X")
	assert_almost_eq(-player.interaction_area.global_basis.z, Vector3(1, 0, 0), EPS)
	_ticks(player, 20)
	assert_almost_eq(player.aim_direction(), Vector3(1, 0, 0), EPS, "garde la dernière direction")


func test_animations_follow_movement_only_when_combat_is_free() -> void:
	_add_floor()
	var player := _spawn_player()
	await _in_physics_frame()
	_ticks(player, 2)
	assert_eq(player.visual.current_animation(), &"repos")
	_ticks(player, 20, FORWARD_INPUT)
	assert_eq(player.visual.current_animation(), &"marche")
	_ticks(player, 20, FORWARD_INPUT, true)
	assert_eq(player.visual.current_animation(), &"course")
	_stub(player).busy = true
	player.visual.play(&"attaque", true)
	_ticks(player, 10)
	assert_eq(player.visual.current_animation(), &"attaque", "Combat occupé : animation de L4")


# --- Recul et réapparition --------------------------------------------------------------------


func test_knockback_pushes_away_from_source() -> void:
	_add_floor()
	var player := _spawn_player()
	await _in_physics_frame()
	_ticks(player, 2)
	var source: Node3D = add_child_autofree(Node3D.new())
	source.global_position = Vector3(0, 0, -1)
	var bite := load("res://data/attacks/bite.tres") as AttackData
	player.hurtbox.hit_taken.emit(bite, source)
	player.tick(DT, _commands())
	assert_gt(player.velocity.z, bite.knockback * 0.8, "repoussé à l'opposé de la source")
	_ticks(player, 60)
	assert_almost_eq(_horizontal_speed(player), 0.0, 0.001, "le recul s'amortit")


func test_respawn_resets_velocity_knockback_lock_and_camera() -> void:
	_add_floor()
	var player := _spawn_player()
	await _in_physics_frame()
	_ticks(player, 20, Vector2(1, 0), true)
	var source: Node3D = add_child_autofree(Node3D.new())
	source.global_position = Vector3(-1, 0, 0)
	player.hurtbox.hit_taken.emit(load("res://data/attacks/sword_3.tres") as AttackData, source)
	player.camera_rig.rotate_view(1.0, -0.4)
	EventBus.player_respawned.emit()
	assert_eq(player.velocity, Vector3.ZERO, "vitesse à zéro")
	player.tick(DT, _commands())
	assert_almost_eq(_horizontal_speed(player), 0.0, 0.001, "plus de recul ni d'élan")
	var rig := player.camera_rig
	assert_almost_eq(rig.forward(), player.aim_direction(), EPS, "caméra derrière le joueur")
	assert_almost_eq(rig.pitch(), rig.default_pitch(), 0.001, "tangage par défaut")
