extends GutTest
## Health (src/combat/health.gd) : dégâts, invincibilité, soin, mort, PV max.

var _source: Node3D


func before_each() -> void:
	_source = autofree(Node3D.new())


func _health(max_hp: int, invincibility: float = 0.0) -> Health:
	var health: Health = add_child_autofree(Health.new())
	health.max_hp = max_hp
	health.invincibility_time = invincibility
	return health


func test_starts_full() -> void:
	var health := _health(5)
	assert_eq(health.current, 5)
	assert_false(health.is_dead())


func test_take_damage_emits_and_returns_true() -> void:
	var health := _health(5)
	watch_signals(health)
	assert_true(health.take_damage(2, _source))
	assert_eq(health.current, 3)
	assert_signal_emitted_with_parameters(health, "changed", [3, 5])
	assert_signal_emitted_with_parameters(health, "damaged", [2, _source])
	assert_signal_not_emitted(health, "died")


func test_invincibility_refuses_second_hit() -> void:
	var health := _health(5, 1.2)
	assert_true(health.take_damage(1, _source))
	assert_true(health.is_invincible())
	assert_false(health.take_damage(1, _source), "deux dégâts en moins de 1,2 s refusés")
	assert_eq(health.current, 4)
	simulate(health, 13, 0.1)
	assert_false(health.is_invincible())
	assert_true(health.take_damage(1, _source))
	assert_eq(health.current, 3)


func test_enemies_have_no_invincibility() -> void:
	var health := _health(3)
	assert_true(health.take_damage(1, _source))
	assert_true(health.take_damage(1, _source))
	assert_eq(health.current, 1)


func test_death() -> void:
	var health := _health(2)
	watch_signals(health)
	assert_true(health.take_damage(5, _source))
	assert_eq(health.current, 0)
	assert_true(health.is_dead())
	assert_signal_emit_count(health, "died", 1)
	assert_false(health.take_damage(1, _source), "un mort ne prend plus de dégâts")
	health.heal(1)
	assert_eq(health.current, 0, "heal ne ressuscite pas")


func test_heal_and_reset() -> void:
	var health := _health(5)
	health.take_damage(3, _source)
	health.heal(1)
	assert_eq(health.current, 3)
	health.heal(10)
	assert_eq(health.current, 5, "pas au-delà de max_hp")
	health.take_damage(5, _source)
	health.reset()
	assert_eq(health.current, 5)
	assert_false(health.is_dead())


func test_zero_or_negative_amounts_are_ignored() -> void:
	var health := _health(5)
	assert_false(health.take_damage(0, _source))
	assert_false(health.take_damage(-2, _source))
	assert_eq(health.current, 5)


func test_max_hp_changes() -> void:
	var health: Health = autofree(Health.new())
	health.max_hp = 5
	assert_eq(health.current, 5, "PV pleins tant qu'aucun dégât n'a été pris")
	health.take_damage(1, _source)
	health.max_hp = 6
	assert_eq(health.current, 4, "après un dégât, augmenter max_hp ne soigne pas")
	health.max_hp = 2
	assert_eq(health.current, 2, "PV ramenés au nouveau maximum")


func test_invincibility_left_counts_down_and_reset_clears_it() -> void:
	var health := _health(5, 1.2)
	health.take_damage(1, _source)
	assert_almost_eq(health.invincibility_left(), 1.2, 0.001)
	simulate(health, 5, 0.1)
	assert_almost_eq(health.invincibility_left(), 0.7, 0.001)
	watch_signals(health)
	health.reset()
	assert_false(health.is_invincible(), "reset : plus d'invincibilité")
	assert_eq(health.current, 5)
	assert_signal_emitted_with_parameters(health, "changed", [5, 5])
