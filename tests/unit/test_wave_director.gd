extends GutTest
## WaveDirector (src/enemies/wave_director.gd) : compose(n) (3 + 2n, Coureur dès la vague 2,
## Grand dès la vague 3), bonus de vitesse (plafond +50 %) et de PV (Normal dès la vague 6),
## bonus 50 × n, soin toutes les 2 vagues, Grand jamais deux à la fois, fin de série
## (record_score puis arena_finished) sur mort du joueur, changement de zone ou sortie des bornes.

const ARENA_SCENE := preload("res://src/enemies/arena.tscn")
const PLAYER_STUB := preload("res://tests/stubs/player_stub.tscn")
const DUNES := "res://data/waves/dunes.json"
## Délais nuls : une série se joue en quelques images (un ennemi par image).
const FAST_TIMING := {
	"start_delay": 0.0,
	"wave_pause": 0.0,
	"first_spawn_delay": 0.0,
	"spawn_interval": 0.0,
	"spawn_interval_per_wave": 0.0,
	"spawn_interval_min": 0.0,
	"spawn_jitter": [1.0, 1.0],
}

var _zone_before: StringName


func before_each() -> void:
	GameState.reset()
	_zone_before = WorldManager.current_zone()


func after_each() -> void:
	if WorldManager.current_zone() != _zone_before:
		EventBus.zone_entered.emit(_zone_before)
	GameState.reset()


func _director() -> WaveDirector:
	var director: WaveDirector = autofree(WaveDirector.new())
	assert_eq(director.load_config(DUNES), OK)
	return director


## arena.tscn (dunes) dans une scène avec sol et SpawnN/S/E/W à 6 m, délais nuls ; dans une Zone
## « l5_arena_zone » si in_zone.
func _arena(in_zone: bool = false) -> Arena:
	var root: Node3D = add_child_autofree(Node3D.new())
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(60.0, 1.0, 60.0)
	shape.shape = box
	ground.add_child(shape)
	ground.position = Vector3(0.0, -0.5, 0.0)
	root.add_child(ground)
	var parent: Node3D = root
	if in_zone:
		var zone := Zone.new()
		zone.name = "l5_arena_zone"
		zone.add_to_group(&"zones")
		root.add_child(zone)
		parent = zone
	var markers := {
		"SpawnN": Vector3(0, 0.5, -6),
		"SpawnS": Vector3(0, 0.5, 6),
		"SpawnE": Vector3(6, 0.5, 0),
		"SpawnW": Vector3(-6, 0.5, 0),
	}
	for marker_name: String in markers:
		var marker := Marker3D.new()
		marker.name = marker_name
		marker.position = markers[marker_name]
		parent.add_child(marker)
	var arena := ARENA_SCENE.instantiate() as Arena
	arena.arena_id = &"dunes"
	parent.add_child(arena)
	var director := arena.director()
	var config := director.config()
	config["timing"] = FAST_TIMING
	director.set_config(config)
	director.random_seed = 3
	return arena


func _counts(ids: Array[StringName]) -> Dictionary:
	var counts := {}
	for enemy_id: StringName in ids:
		counts[enemy_id] = int(counts.get(enemy_id, 0)) + 1
	return counts


func _alive_of(director: WaveDirector, enemy_id: StringName) -> int:
	var total := 0
	for enemy: Enemy in director.alive_enemies():
		if enemy.enemy_id() == enemy_id:
			total += 1
	return total


## Tue tous les ennemis vivants de la série ; renvoie la somme de leurs points.
func _kill_all(director: WaveDirector) -> int:
	var points := 0
	for enemy: Enemy in director.alive_enemies():
		points += enemy.data.points
		enemy.health.take_damage(99, null)
	return points


func _wait_alive(director: WaveDirector, count: int) -> bool:
	return await wait_until(func() -> bool: return director.alive_enemies().size() == count, 2.0)


# --- compose et règles pures -------------------------------------------------------------------


func test_compose_counts_three_plus_two_n() -> void:
	var director := _director()
	assert_eq(director.compose(4).size(), 11, "vague 4 : 11 Timeres")
	for wave in range(1, 31):
		assert_eq(director.compose(wave).size(), 3 + 2 * wave, "vague %d : 3 + 2n" % wave)
	assert_true(director.compose(0).is_empty())


func test_listed_waves_are_played_as_written() -> void:
	var director := _director()
	assert_eq_deep(_counts(director.compose(1)), {&"timere_small": 3, &"timere_normal": 2})
	assert_eq_deep(
		_counts(director.compose(3)),
		{&"timere_small": 4, &"timere_normal": 3, &"timere_runner": 1, &"timere_big": 1}
	)
	assert_does_not_have(director.compose(1), &"timere_runner", "pas de Coureur en vague 1")
	assert_does_not_have(director.compose(2), &"timere_big", "pas de Grand en vague 2")


func test_generator_holds_back_runner_and_big() -> void:
	var director := _director()
	var config := director.config()
	config["waves"] = []
	director.set_config(config)
	var runner_seen := false
	var big_seen := false
	for candidate in range(1, 60):
		director.random_seed = candidate
		assert_does_not_have(director.compose(1), &"timere_runner", "graine %d" % candidate)
		assert_does_not_have(director.compose(1), &"timere_big", "graine %d" % candidate)
		assert_does_not_have(director.compose(2), &"timere_big", "graine %d" % candidate)
		runner_seen = runner_seen or director.compose(2).has(&"timere_runner")
		big_seen = big_seen or director.compose(3).has(&"timere_big")
	assert_true(runner_seen, "le Coureur arrive en vague 2")
	assert_true(big_seen, "le Grand arrive en vague 3")


func test_compose_is_pure_for_a_seed() -> void:
	var director := _director()
	director.random_seed = 7
	var first := director.compose(9)
	assert_eq(director.compose(9), first, "même graine, même vague : même liste")
	var other := _director()
	other.random_seed = 7
	assert_eq(other.compose(9), first, "indépendant de l'instance")


func test_speed_bonus_is_capped_at_fifty_percent() -> void:
	var director := _director()
	assert_almost_eq(director.speed_multiplier(1), 1.04, 0.0001)
	assert_almost_eq(director.speed_multiplier(10), 1.4, 0.0001)
	assert_almost_eq(director.speed_multiplier(13), 1.5, 0.0001)
	assert_almost_eq(director.speed_multiplier(40), 1.5, 0.0001, "plafond : +50 %")


func test_normal_gains_one_hp_from_wave_six() -> void:
	var director := _director()
	assert_eq(director.hp_bonus(&"timere_normal", 5), 0)
	assert_eq(director.hp_bonus(&"timere_normal", 6), 1)
	assert_eq(director.hp_bonus(&"timere_normal", 15), 1)
	assert_eq(director.hp_bonus(&"timere_small", 15), 0, "seul le Normal")


func test_bonus_heal_interval_and_limits() -> void:
	var director := _director()
	for wave in range(1, 9):
		assert_eq(director.wave_bonus(wave), 50 * wave, "bonus 50 × %d" % wave)
		assert_eq(director.heal_after(wave), 1 if wave % 2 == 0 else 0, "soin vague %d" % wave)
	assert_almost_eq(director.spawn_interval(1), 2.05, 0.0001, "2,2 − 0,15 n")
	assert_almost_eq(director.spawn_interval(20), 0.5, 0.0001, "au moins 0,5 s")
	assert_eq(director.max_alive(&"timere_big"), 1)
	assert_eq(director.max_alive(&"timere_small"), -1)


# --- Série en scène ------------------------------------------------------------------------------


func test_series_scores_points_bonus_and_heals() -> void:
	var director := _arena().director()
	watch_signals(EventBus)
	director.start()
	assert_true(director.is_running())
	assert_signal_emitted_with_parameters(EventBus, "arena_score_changed", [&"dunes", 0])
	assert_true(await _wait_alive(director, 5), "vague 1 : 5 Timeres")
	assert_signal_emitted_with_parameters(EventBus, "wave_started", [&"dunes", 1, 5])
	for enemy: Enemy in director.alive_enemies():
		assert_true(enemy.is_in_group(&"enemies"))
		assert_false(enemy.drops_enabled, "pas de drops dans l'arène")
		assert_true(enemy.always_chase)
	var points := _kill_all(director)
	assert_true(await wait_until(func() -> bool: return director.current_wave() == 2, 2.0))
	assert_signal_emitted_with_parameters(EventBus, "wave_cleared", [&"dunes", 1, 50])
	assert_eq(director.score(), points + 50, "points + bonus 50 × 1")
	assert_signal_not_emitted(EventBus, "player_heal_requested", "pas de soin après la vague 1")
	assert_true(await _wait_alive(director, 7), "vague 2 : 7 Timeres")
	points += _kill_all(director)
	assert_true(await wait_until(func() -> bool: return director.current_wave() == 3, 2.0))
	assert_signal_emitted_with_parameters(EventBus, "wave_cleared", [&"dunes", 2, 100])
	assert_signal_emit_count(EventBus, "player_heal_requested", 1, "soin après la vague 2")
	assert_signal_emitted_with_parameters(EventBus, "player_heal_requested", [1])
	assert_eq(director.score(), points + 150)
	assert_signal_emitted_with_parameters(
		EventBus, "arena_score_changed", [&"dunes", director.score()]
	)


func test_big_never_has_a_living_twin() -> void:
	var director := _arena().director()
	var config := director.config()
	config["waves"] = [{"enemies": {"timere_big": 3, "timere_small": 1}}]
	director.set_config(config)
	director.start()
	await wait_physics_frames(10)
	assert_eq(_alive_of(director, &"timere_big"), 1, "un seul Grand vivant")
	assert_eq(_alive_of(director, &"timere_small"), 1, "les autres types n'attendent pas")
	for remaining: int in [2, 1]:
		for enemy: Enemy in director.alive_enemies():
			if enemy.enemy_id() == &"timere_big":
				enemy.health.take_damage(99, null)
		await wait_physics_frames(3)
		assert_eq(
			_alive_of(director, &"timere_big"), 1, "le Grand suivant (%d restants)" % remaining
		)


func test_spawned_enemies_get_wave_bonuses() -> void:
	var director := _arena().director()
	var config := director.config()
	config["waves"] = []
	config["generator"]["weights"] = {"timere_normal": 1}
	config["generator"]["hp_bonus"] = {"timere_normal": {"from_wave": 1, "amount": 1}}
	director.set_config(config)
	director.start()
	assert_true(await _wait_alive(director, 5))
	var enemy := director.alive_enemies()[0]
	assert_almost_eq(enemy.speed_multiplier, 1.04, 0.0001, "+4 % en vague 1")
	assert_eq(enemy.health.max_hp, 3, "Normal : 2 PV + 1")
	var arena := director.get_parent() as Arena
	assert_eq(enemy.get_parent(), arena.get_node(^"Spawned"))
	var nearest := INF
	for marker_name: String in ["SpawnN", "SpawnS", "SpawnE", "SpawnW"]:
		var marker := arena.spawn_point(StringName(marker_name))
		nearest = minf(nearest, enemy.global_position.distance_to(marker.global_position))
	assert_lt(nearest, 2.5, "apparu près d'un point d'apparition")


func test_player_death_ends_the_series() -> void:
	var director := _arena().director()
	director.start()
	assert_true(await _wait_alive(director, 5))
	var survivors := director.alive_enemies()
	var victim: Enemy = survivors.pop_back()
	var points := victim.data.points
	victim.health.take_damage(99, null)
	watch_signals(EventBus)
	EventBus.player_died.emit()
	assert_false(director.is_running())
	assert_signal_emitted_with_parameters(EventBus, "arena_finished", [&"dunes", points, true])
	assert_eq(GameState.best_score(&"dunes"), points, "record_score avant arena_finished")
	assert_eq(int(GameState.to_dict()["best_scores"]["dunes"]["wave"]), 1)
	await wait_process_frames(2)
	for enemy: Enemy in survivors:
		assert_freed(enemy, "ennemi restant retiré")
	assert_true(director.alive_enemies().is_empty())


func test_another_zone_ends_the_series() -> void:
	var director := _arena(true).director()
	director.start()
	watch_signals(EventBus)
	EventBus.zone_entered.emit(&"l5_arena_zone")
	assert_true(director.is_running(), "la zone de l'arène ne compte pas")
	EventBus.zone_entered.emit(&"l5_elsewhere")
	assert_false(director.is_running(), "fuite dans une autre zone")
	assert_signal_emitted_with_parameters(EventBus, "arena_finished", [&"dunes", 0, false])


func test_leaving_bounds_ends_the_series_only_between_waves() -> void:
	var arena := _arena()
	var director := arena.director()
	var player := PLAYER_STUB.instantiate() as Node3D
	arena.get_parent().add_child(player)
	director.start()
	assert_true(await _wait_alive(director, 5))
	player.position = Vector3(20.0, 0.0, 0.0)
	assert_false(arena.contains(player.global_position))
	await wait_physics_frames(3)
	assert_true(director.is_running(), "pendant une vague, la série continue")
	watch_signals(EventBus)
	var points := _kill_all(director)
	await wait_physics_frames(3)
	assert_false(director.is_running(), "hors des bornes entre deux vagues : fin")
	assert_signal_emitted_with_parameters(EventBus, "arena_finished", [&"dunes", points + 50, true])
	assert_eq(GameState.best_score(&"dunes"), points + 50)
