extends GutTest
## PlayerCombat : is_busy() dans chaque état, dégâts (1,2 s d'invincibilité, clignotement,
## état « dégâts »), mort et réapparition, relais EventBus (PV initiaux différés, soin, PV max)
## et animations jouées sur le Visual.

const RIG := preload("res://tests/stubs/l4_player_rig.tscn")
const HITBOX := preload("res://src/combat/hitbox.tscn")
const BITE := preload("res://data/attacks/bite.tres")
const WHIP := preload("res://data/attacks/whip.tres")

var _rig: Node3D
var _combat: PlayerCombat
var _visual: CharacterVisual
var _health: Health
var _source: Node3D


func before_each() -> void:
	GameState.reset()
	_rig = add_child_autofree(RIG.instantiate())
	_combat = _rig.get_node(^"Combat") as PlayerCombat
	_visual = _rig.get_node(^"Visual") as CharacterVisual
	_health = _rig.get_node(^"Health") as Health
	_source = add_child_autofree(Node3D.new())
	_combat.wave_launched.connect(func(wave: Node3D) -> void: autofree(wave))


func after_all() -> void:
	GameState.reset()


## Morsure d'un Timere : Hitbox d'équipe enemy posée sur le joueur.
func _enemy_bite() -> Hitbox:
	var hitbox: Hitbox = add_child_autofree(HITBOX.instantiate())
	hitbox.attack = BITE
	hitbox.team = &"enemy"
	hitbox.source = _source
	hitbox.position = Vector3(0, 0.7, 0)
	return hitbox


func test_enemy_attacks_push_back_at_3_m_s() -> void:
	assert_almost_eq(BITE.knockback, 3.0, 0.001, "morsure : recul 3 m/s")
	assert_almost_eq(WHIP.knockback, 3.0, 0.001, "fouet : recul 3 m/s")


func test_is_busy_in_every_state() -> void:
	assert_false(_combat.is_busy(), "repos")
	_combat.attack()
	assert_true(_combat.is_busy(), "attaque")
	_visual.call(&"finish", &"attaque")
	assert_false(_combat.is_busy(), "fin du coup")
	_combat.charge_begin()
	assert_true(_combat.is_busy(), "charge")
	simulate(_combat, 1, 0.6)
	_combat.charge_release()
	assert_eq(_combat.current_state(), &"wave")
	assert_true(_combat.is_busy(), "onde")
	simulate(_combat, 1, 0.5)
	assert_false(_combat.is_busy(), "après l'onde")
	_health.take_damage(1, _source)
	assert_eq(_combat.current_state(), &"hurt")
	assert_true(_combat.is_busy(), "dégâts")
	simulate(_combat, 1, _combat.hurt_time + 0.01)
	assert_false(_combat.is_busy(), "après hurt_time")
	simulate(_rig, 13, 0.1)
	_health.take_damage(5, _source)
	assert_eq(_combat.current_state(), &"dead")
	assert_true(_combat.is_busy(), "mort")
	simulate(_combat, 10, 0.5)
	assert_true(_combat.is_busy(), "toujours mort tant que player_respawned n'arrive pas")


func test_player_refuses_two_hits_within_1_2_s() -> void:
	watch_signals(EventBus)
	var bite := _enemy_bite()
	await wait_physics_frames(3)
	bite.activate()
	await wait_physics_frames(2)
	assert_eq(_health.current, 4, "première morsure")
	bite.deactivate()
	bite.activate()
	await wait_physics_frames(3)
	assert_eq(_health.current, 4, "seconde morsure dans les 1,2 s : refusée")
	assert_signal_emit_count(EventBus, "player_damaged", 1)
	assert_signal_emitted_with_parameters(EventBus, "player_damaged", [1, _source])
	bite.deactivate()
	simulate(_health, 13, 0.1)
	bite.activate()
	await wait_physics_frames(2)
	assert_eq(_health.current, 3, "après 1,2 s : de nouveau vulnérable")


func test_refused_hit_lands_when_invincibility_ends_in_same_activation() -> void:
	var bite := _enemy_bite()
	_health.take_damage(1, _source)
	await wait_physics_frames(3)
	bite.activate()
	await wait_physics_frames(2)
	assert_eq(_health.current, 4, "invincible : refusé")
	simulate(_health, 13, 0.1)
	await wait_physics_frames(2)
	assert_eq(_health.current, 3, "même activation : le coup porte à la fin de l'invincibilité")


func test_blinks_during_invincibility() -> void:
	_health.take_damage(1, _source)
	var seen := {}
	for _i in 24:
		simulate(_rig, 1, 1.0 / 24.0)
		seen[_visual.visible] = true
	assert_true(seen.has(true) and seen.has(false), "Visual.visible basculé")
	simulate(_rig, 4, 0.1)
	assert_false(_health.is_invincible())
	assert_true(_visual.visible, "visible après l'invincibilité")


func test_death_emits_player_died_and_respawn_restores() -> void:
	watch_signals(EventBus)
	_health.take_damage(1, _source)
	simulate(_rig, 2, 0.1)
	_health.invincibility_time = 0.0
	simulate(_rig, 12, 0.1)
	_health.take_damage(4, _source)
	assert_signal_emit_count(EventBus, "player_died", 1)
	assert_eq(_combat.current_state(), &"dead")
	assert_true(_visual.visible, "pas de clignotement pendant la mort")
	_combat.attack()
	_combat.charge_begin()
	assert_eq(_combat.current_state(), &"dead", "ni épée ni charge une fois mort")
	EventBus.player_respawned.emit()
	assert_eq(_health.current, 5, "PV pleins")
	assert_false(_health.is_dead())
	assert_false(_combat.is_busy())
	assert_signal_emitted_with_parameters(EventBus, "player_health_changed", [5, 5])
	simulate(_combat, 1, 0.1)
	assert_eq(_combat.current_state(), &"idle", "la charge tenue avant la mort est oubliée")


func test_heal_and_max_hp_relays() -> void:
	watch_signals(EventBus)
	_health.take_damage(2, _source)
	assert_signal_emitted_with_parameters(EventBus, "player_health_changed", [3, 5])
	EventBus.player_heal_requested.emit(1)
	assert_eq(_health.current, 4, "player_heal_requested → heal")
	GameState.max_hp = 6
	assert_eq(_health.max_hp, 6, "max_hp_changed → nouveau maximum")
	assert_eq(_health.current, 4, "le maximum n'est pas un soin")
	assert_signal_emitted_with_parameters(EventBus, "player_health_changed", [4, 6])
	EventBus.player_respawned.emit()
	assert_eq(_health.current, 6, "réapparition : PV pleins au nouveau maximum")


func test_initial_health_is_emitted_deferred() -> void:
	GameState.max_hp = 6
	watch_signals(EventBus)
	var rig: Node3D = add_child_autofree(RIG.instantiate())
	assert_eq((rig.get_node(^"Health") as Health).current, 6, "Health.max_hp = GameState.max_hp")
	assert_signal_not_emitted(EventBus, "player_health_changed", "pas avant la fin de l'image")
	await wait_process_frames(1)
	assert_signal_emitted_with_parameters(EventBus, "player_health_changed", [6, 6])


func test_plays_combat_animations_on_the_visual() -> void:
	_visual.set_skin(SkinRegistry.default_skin())
	_combat.attack()
	assert_eq(_visual.current_animation(), &"attaque")
	_combat.attack()
	_visual.call(&"finish", &"attaque")
	assert_eq(_visual.current_animation(), &"attaque", "2e coup : attaque relancée")
	_health.take_damage(1, _source)
	assert_eq(_visual.current_animation(), &"degats")
	simulate(_combat, 1, 0.5)
	_combat.charge_begin()
	assert_eq(_visual.current_animation(), &"charge")
	_combat.charge_release()
	_health.invincibility_time = 0.0
	simulate(_rig, 14, 0.1)
	_health.take_damage(5, _source)
	assert_eq(_visual.current_animation(), &"mort")
