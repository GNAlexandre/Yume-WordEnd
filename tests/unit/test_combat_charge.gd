extends GutTest
## PlayerCombat, charge magique et onde (charge_wave.tscn) : relâcher avant charge_time = rien,
## au-delà = onde, recharge 1,2 s, jauge EventBus.charge_progress, onde qui traverse les
## mannequins alignés devant (-Z de Combat) et se libère en fin de course, lancée sur l'image
## « onde » de la planche.

const RIG := preload("res://tests/stubs/l4_player_rig.tscn")
const DUMMY := preload("res://tests/stubs/dummy.tscn")
const WAVE_DATA := preload("res://data/attacks/charge_wave.tres")

var _combat: PlayerCombat
var _visual: CharacterVisual
var _waves: Array[Node3D] = []


func before_each() -> void:
	GameState.reset()
	_waves.clear()
	var rig: Node3D = add_child_autofree(RIG.instantiate())
	_combat = rig.get_node(^"Combat") as PlayerCombat
	_visual = rig.get_node(^"Visual") as CharacterVisual
	_combat.wave_launched.connect(_on_wave_launched)


func _on_wave_launched(wave: Node3D) -> void:
	_waves.append(autofree(wave))


func _dummy(at: Vector3, hp: int = 10) -> Node3D:
	var dummy: Node3D = add_child_autofree(DUMMY.instantiate())
	dummy.position = at
	(dummy.get_node(^"Health") as Health).max_hp = hp
	return dummy


func _hp(target: Node) -> int:
	return (target.get_node(^"Health") as Health).current


## Maintient la charge seconds secondes (temps simulé) puis relâche.
func _charge(seconds: float) -> void:
	_combat.charge_begin()
	simulate(_combat, 1, seconds)
	_combat.charge_release()


func test_data_matches_the_rules() -> void:
	assert_eq(WAVE_DATA.damage, 3)
	assert_true(WAVE_DATA.pierces)
	assert_almost_eq(WAVE_DATA.charge_time, 0.55, 0.001)
	assert_almost_eq(WAVE_DATA.cooldown, 1.2, 0.001)
	assert_almost_eq(WAVE_DATA.range_m, 8.0, 0.001)
	assert_almost_eq(WAVE_DATA.width_m, 2.0, 0.001)
	assert_almost_eq(WAVE_DATA.speed * WAVE_DATA.duration, WAVE_DATA.range_m, 0.1, "8 m en 0,42 s")


func test_release_at_0_4_s_does_nothing() -> void:
	_combat.charge_begin()
	assert_eq(_combat.current_state(), &"charge")
	simulate(_combat, 4, 0.1)
	_combat.charge_release()
	assert_true(_waves.is_empty(), "pas d'onde")
	assert_false(_combat.is_busy())
	assert_eq(_combat.wave_cooldown_left(), 0.0, "pas de recharge")
	_combat.charge_begin()
	assert_eq(_combat.current_state(), &"charge", "nouvelle charge possible tout de suite")


func test_full_charge_launches_the_wave() -> void:
	_charge(0.56)
	assert_eq(_waves.size(), 1, "onde lancée")
	assert_eq(_combat.current_state(), &"wave")
	assert_true(_combat.is_busy(), "immobile pendant l'onde")
	simulate(_combat, 1, WAVE_DATA.duration + 0.01)
	assert_false(_combat.is_busy(), "libre après duration")


func test_cooldown_lasts_1_2_s() -> void:
	_charge(0.6)
	simulate(_combat, 5, 0.1)
	_combat.charge_begin()
	assert_eq(_combat.current_state(), &"idle", "0,5 s : en recharge")
	_combat.charge_release()
	simulate(_combat, 6, 0.1)
	_combat.charge_begin()
	assert_eq(_combat.current_state(), &"idle", "1,1 s : toujours en recharge")
	_combat.charge_release()
	simulate(_combat, 2, 0.1)
	_combat.charge_begin()
	assert_eq(_combat.current_state(), &"charge", "1,3 s : recharge finie")


func test_held_charge_starts_when_cooldown_ends() -> void:
	_charge(0.6)
	_combat.charge_begin()
	simulate(_combat, 11, 0.1)
	assert_eq(_combat.current_state(), &"idle")
	simulate(_combat, 2, 0.1)
	assert_eq(_combat.current_state(), &"charge", "touche tenue : la charge reprend seule")


func test_charge_progress_gauge() -> void:
	watch_signals(EventBus)
	_combat.charge_begin()
	assert_signal_emitted_with_parameters(EventBus, "charge_progress", [0.0])
	simulate(_combat, 3, 0.1)
	var half: float = get_signal_parameters(EventBus, "charge_progress")[0]
	assert_almost_eq(half, 0.3 / WAVE_DATA.charge_time, 0.01)
	simulate(_combat, 5, 0.1)
	assert_signal_emitted_with_parameters(EventBus, "charge_progress", [1.0])
	var count: int = get_signal_emit_count(EventBus, "charge_progress")
	simulate(_combat, 5, 0.1)
	assert_signal_emit_count(EventBus, "charge_progress", count, "jauge pleine : plus d'émission")
	_combat.charge_release()
	assert_signal_emitted_with_parameters(EventBus, "charge_progress", [0.0])


func test_wave_pierces_three_aligned_dummies() -> void:
	var dummies: Array[Node3D] = [
		_dummy(Vector3(0, 0, -2)), _dummy(Vector3(0, 0, -4)), _dummy(Vector3(0, 0, -6))
	]
	var beyond := _dummy(Vector3(0, 0, -9.5))
	await wait_physics_frames(3)
	_charge(0.6)
	await wait_physics_frames(40)
	for dummy: Node3D in dummies:
		assert_eq(_hp(dummy), 7, "3 dégâts : %s" % dummy.position)
		assert_eq((dummy.get(&"hits") as Array).size(), 1, "touché une seule fois")
	assert_eq(_hp(beyond), 10, "au-delà des 8 m : intact")
	assert_false(is_instance_valid(_waves[0]), "l'onde s'est libérée en fin de course")


func test_wave_is_2_m_wide() -> void:
	var inside: Array[Node3D] = [_dummy(Vector3(0.8, 0, -3), 3), _dummy(Vector3(-0.8, 0, -5), 3)]
	var outside: Array[Node3D] = [_dummy(Vector3(1.6, 0, -3)), _dummy(Vector3(-1.6, 0, -5))]
	await wait_physics_frames(3)
	_charge(0.6)
	await wait_physics_frames(40)
	for dummy: Node3D in inside:
		assert_true((dummy.get_node(^"Health") as Health).is_dead(), "touché : %s" % dummy.position)
	for dummy: Node3D in outside:
		assert_eq(_hp(dummy), 10, "hors de la largeur : %s" % dummy.position)


func test_wave_follows_combat_forward() -> void:
	var side := _dummy(Vector3(3, 0, 0))
	var former_front := _dummy(Vector3(0, 0, -3))
	_combat.rotation.y = -PI / 2.0
	await wait_physics_frames(3)
	_charge(0.6)
	await wait_physics_frames(40)
	assert_eq(_hp(side), 7, "onde vers -Z de Combat")
	assert_eq(_hp(former_front), 10)


func test_wave_starts_on_the_sheet_wave_frame() -> void:
	_visual.set_skin(SkinRegistry.default_skin())
	var wave_frame := _visual.wave_frame(&"charge")
	assert_eq(wave_frame, 3, "onde de chtholly.json")
	_combat.charge_begin()
	assert_eq(_visual.current_animation(), &"charge", "image de charge maintenue")
	simulate(_combat, 6, 0.1)
	watch_signals(_visual)
	_combat.charge_release()
	assert_signal_emitted_with_parameters(_visual, "frame_changed", [&"charge", wave_frame])
	assert_eq(_waves.size(), 1, "onde lancée sur l'image onde")


func test_damage_cancels_the_charge() -> void:
	watch_signals(EventBus)
	_combat.charge_begin()
	simulate(_combat, 3, 0.1)
	(_combat.get_node(^"../Health") as Health).take_damage(1, null)
	assert_eq(_combat.current_state(), &"hurt")
	assert_signal_emitted_with_parameters(EventBus, "charge_progress", [0.0])
	_combat.charge_release()
	assert_true(_waves.is_empty(), "pas d'onde après une charge interrompue")


func test_charge_released_during_pause_is_released_on_resume() -> void:
	_combat.charge_begin()
	simulate(_combat, 1, 0.6)
	_combat.notification(Node.NOTIFICATION_UNPAUSED)
	assert_eq(_waves.size(), 1, "touche relâchée pendant la pause : l'onde part à la reprise")
