extends GutTest
## Lot 1 — verrouillage de cible (lock_target) : l'ennemi vivant du groupe "enemies" le plus
## proche dans le rayon ; le joueur et Combat lui font face, la caméra le reçoit ; nouvel appui
## = déverrouillage ; verrou perdu si la cible quitte le groupe, meurt, est libérée ou
## s'éloigne trop ; sans cible, l'appui replace la caméra derrière le joueur.

const PLAYER := preload("res://src/player/player.tscn")
const CombatStub := preload("res://tests/stubs/l1_combat_stub.gd")
const DUMMY := preload("res://tests/stubs/dummy.tscn")
const DT := 1.0 / 60.0
const EPS := Vector3(0.001, 0.001, 0.001)


func before_each() -> void:
	GameState.reset()


# --- Outils -----------------------------------------------------------------------------------


func _spawn_player() -> Player:
	var player: Player = PLAYER.instantiate()
	player.get_node(^"Combat").set_script(CombatStub)
	add_child_autofree(player)
	player.set_physics_process(false)
	return player


func _add_dummy(at: Vector3) -> CharacterBody3D:
	var dummy: CharacterBody3D = DUMMY.instantiate()
	dummy.position = at
	add_child_autofree(dummy)
	return dummy


## tick() (move_and_slide) doit tourner dans une image physique.
func _in_physics_frame() -> void:
	await wait_physics_frames(1)
	assert_true(Engine.is_in_physics_frame(), "tick() appelé dans une image physique")


func _press_lock() -> Player.Commands:
	var commands := Player.Commands.new()
	commands.lock = true
	return commands


func _idle(player: Player) -> void:
	player.tick(DT, Player.Commands.new())


func _kill(dummy: Node) -> void:
	(dummy.get_node(^"Health") as Health).take_damage(100, null)


# --- Choix de la cible (fonction pure) -----------------------------------------------------------


func test_pick_lock_target_takes_nearest_living_enemy_in_radius() -> void:
	var near := _add_dummy(Vector3(3, 0, 0))
	_add_dummy(Vector3(0, 0, -5))
	var gone := _add_dummy(Vector3(2, 0, 0))
	gone.remove_from_group(&"enemies")
	var dead := _add_dummy(Vector3(0, 0, 2.5))
	_kill(dead)
	var dying := _add_dummy(Vector3(-1, 0, 1))
	dying.queue_free()
	var far := _add_dummy(Vector3(20, 0, 0))
	assert_eq(
		Player.pick_lock_target(Vector3.ZERO, get_tree().get_nodes_in_group(&"enemies"), 12.0),
		near,
		"le plus proche des vivants"
	)
	var tricky: Array[Node] = [gone, dead, dying, near]
	assert_eq(Player.pick_lock_target(Vector3.ZERO, tricky, 12.0), near, "morts écartés")
	var out_of_range: Array[Node] = [far]
	assert_null(Player.pick_lock_target(Vector3.ZERO, out_of_range, 12.0), "hors du rayon")
	var none: Array[Node] = []
	assert_null(Player.pick_lock_target(Vector3.ZERO, none, 12.0))
	assert_false(Player.is_lockable(gone), "hors du groupe")
	assert_false(Player.is_lockable(dead), "Health morte")
	assert_false(Player.is_lockable(dying), "en cours de libération")
	assert_true(Player.is_lockable(near))


# --- Verrouillage en jeu ------------------------------------------------------------------------


func test_lock_faces_nearest_enemy_turns_combat_and_toggles_off() -> void:
	var player := _spawn_player()
	var target := _add_dummy(Vector3(4, 0, 0))
	_add_dummy(Vector3(0, 0, 7))
	await _in_physics_frame()
	player.tick(DT, _press_lock())
	assert_eq(player.locked_target(), target, "verrouille le plus proche")
	assert_almost_eq(player.aim_direction(), Vector3(1, 0, 0), EPS, "le joueur fait face")
	assert_almost_eq(-player.combat.global_basis.z, Vector3(1, 0, 0), EPS, "Combat −Z vers elle")
	assert_eq(player.camera_rig.lock_target, target, "la caméra la cadre")
	var strafe := Player.Commands.new()
	strafe.move = Vector2(0, -1)
	for _i in 10:
		player.tick(DT, strafe)
	target.position = Vector3(0, 0, -4)
	_idle(player)
	var to_target := (target.global_position - player.global_position) * Vector3(1, 0, 1)
	assert_almost_eq(
		player.aim_direction(), to_target.normalized(), EPS, "la visée suit la cible qui bouge"
	)
	assert_almost_eq(-player.combat.global_basis.z, to_target.normalized(), EPS)
	player.tick(DT, _press_lock())
	assert_null(player.locked_target(), "nouvel appui : déverrouillé")
	assert_null(player.camera_rig.lock_target)


func test_lock_lost_when_target_leaves_group_dies_or_is_freed() -> void:
	var player := _spawn_player()
	var leaver := _add_dummy(Vector3(2, 0, 0))
	var victim := _add_dummy(Vector3(0, 0, -3))
	var freed := _add_dummy(Vector3(-4, 0, 0))
	var queued := _add_dummy(Vector3(0, 0, 5))
	await _in_physics_frame()
	player.tick(DT, _press_lock())
	assert_eq(player.locked_target(), leaver)
	leaver.remove_from_group(&"enemies")
	_idle(player)
	assert_null(player.locked_target(), "quitte le groupe (mort d'un Enemy)")
	player.tick(DT, _press_lock())
	assert_eq(player.locked_target(), victim)
	_kill(victim)
	_idle(player)
	assert_null(player.locked_target(), "Health morte")
	player.tick(DT, _press_lock())
	assert_eq(player.locked_target(), freed)
	freed.free()
	_idle(player)
	assert_null(player.locked_target(), "libérée")
	assert_null(player.camera_rig.lock_target)
	player.tick(DT, _press_lock())
	assert_eq(player.locked_target(), queued)
	queued.queue_free()
	_idle(player)
	assert_null(player.locked_target(), "libération demandée")


func test_lock_lost_when_target_moves_too_far() -> void:
	var player := _spawn_player()
	var target := _add_dummy(Vector3(0, 0, -5))
	await _in_physics_frame()
	player.tick(DT, _press_lock())
	assert_eq(player.locked_target(), target)
	target.position = Vector3(0, 0, -player.lock_break_distance + 1.0)
	_idle(player)
	assert_eq(player.locked_target(), target, "encore à portée")
	target.position = Vector3(0, 0, -player.lock_break_distance - 1.0)
	_idle(player)
	assert_null(player.locked_target(), "trop loin")


func test_lock_without_enemy_keeps_the_fixed_camera() -> void:
	# (HD-2D) La caméra fixe regarde toujours le nord : un verrouillage sans ennemi à portée ne
	# la fait pas tourner, elle reste centrée sur le joueur.
	var player := _spawn_player()
	_add_dummy(Vector3(0, 0, -30))
	await _in_physics_frame()
	player.set_aim_direction(Vector3(1, 0, 0))
	player.tick(DT, _press_lock())
	assert_null(player.locked_target(), "aucun ennemi dans le rayon")
	for _i in 60:
		player.camera_rig.update_camera(DT)
	assert_eq(player.camera_rig.forward(), Vector3.FORWARD, "la caméra regarde le nord")
	assert_almost_eq(
		player.camera_rig.focus(),
		player.global_position + Vector3.UP * player.camera_rig.focus_height,
		Vector3.ONE * 0.05,
		"centrée sur le joueur"
	)


func test_lock_released_when_player_dies() -> void:
	var player := _spawn_player()
	var target := _add_dummy(Vector3(3, 0, 0))
	await _in_physics_frame()
	player.tick(DT, _press_lock())
	assert_eq(player.locked_target(), target)
	player.health.take_damage(player.health.max_hp, null)
	_idle(player)
	assert_null(player.locked_target(), "joueur mort : verrou levé")
	player.tick(DT, _press_lock())
	assert_null(player.locked_target(), "pas de verrouillage une fois mort")
