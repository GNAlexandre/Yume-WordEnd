extends GutTest
## (E8) L'entraînement au bâton sur la clairière de l'entrepôt (game.tscn, le vrai Player) : la
## parade en rythme (bloquer, dévier, esquiver), l'enchaînement, la jauge de touches, la fatigue, la
## réussite et l'échec de chaque phase, la variante du jour 10 ; aucun vrai dégât ; le bâton n'a pas
## de charge de venenum. L'exercice est avancé à la main (set_physics_process(false)), plus vite que
## le temps ; la parade est la touche de charge (PlayerCombat.charge_begin / charge_release).

const GAME_SCENE := preload("res://src/game.tscn")
const MAP := &"entrepot"
const DT := 1.0 / 60.0

var _game: Node3D
var _player: Player
var _training: StaffTraining
var _outcomes: Array[StringName] = []
var _results: Array[Dictionary] = []
## Le directeur de la vie avance aussi (les aînées marchent) : seulement quand il le faut (lent).
var _life_on: bool = false


func before_all() -> void:
	GameState.reset()
	WorldManager.fade_time = 0.0
	_game = GAME_SCENE.instantiate() as Node3D
	add_child(_game)
	_player = _game.get_node(^"Player") as Player
	LifeDirector.set_slot(&"matin", 0.0)
	assert_true(WorldManager.enter_map(MAP))


func after_all() -> void:
	WorldManager.fade_time = WorldManager.DEFAULT_FADE_TIME
	_game.free()
	LifeDirector.attach(null)
	Atmosphere.dress(null)
	GameState.reset()
	GameRules.clear_cache()


func before_each() -> void:
	GameRules.clear_cache()
	LifeDirector.set_slot(&"matin", 0.0)
	LifeDirector.attach(WorldManager.current_map_node())
	LifeDirector.build_nav_now()
	_player.global_position = Vector3(30.0, 0.0, 40.0)
	_player.velocity = Vector3.ZERO
	_player.set_weapon(PlayerCombat.WEAPON_SENIORIOUS)
	_player.hold_pose(&"", 0.0)
	_outcomes.clear()
	_results.clear()
	_life_on = false


func after_each() -> void:
	if is_instance_valid(_training):
		_training.free()
	_training = null


func _start(options: Dictionary = {}) -> StaffTraining:
	var merged := options.duplicate(true)
	merged["place_player"] = true
	_training = MiniGames.start_staff_training(merged)
	assert_not_null(_training, "l'entraînement démarre")
	_training.set_physics_process(false)
	_training.resolved.connect(
		func(kind: StringName, outcome: StringName) -> void:
			if kind == &"blow" or kind == &"counter":
				_outcomes.append(outcome)
	)
	_training.finished.connect(func(found: Dictionary) -> void: _results.append(found))
	return _training


## Avance l'exercice (et la vie) de seconds s, ou jusqu'à ce que until soit vrai.
func _run(seconds: float, until: Callable = Callable()) -> void:
	for _i: int in roundi(seconds / DT):
		_step()
		if until.is_valid() and until.call():
			return


func _step() -> void:
	_training.advance(DT)
	if _life_on:
		LifeDirector._physics_process(DT)


func _to_phase_a() -> void:
	_run(5.0, func() -> bool: return _training.phase == &"a")
	assert_eq(_training.phase, &"a", "phase A")


## Avance jusqu'à ce qu'un coup soit annoncé, renvoie-le.
func _next_blow() -> Dictionary:
	_run(5.0, func() -> bool: return not _training.current_blow().is_empty())
	assert_false(_training.current_blow().is_empty(), "un coup est annoncé")
	return _training.current_blow().duplicate()


func _impact_done(count: int) -> Callable:
	return func() -> bool: return _outcomes.size() >= count


## Une réponse : block (parade tenue), deflect (relâchée dans la fenêtre), dodge (hors du cercle),
## none. Joue jusqu'à l'impact et renvoie l'issue.
func _respond(how: StringName) -> StringName:
	var blow := _next_blow()
	var before := _outcomes.size()
	match how:
		&"block":
			_player.combat.charge_begin()
		&"deflect":
			_player.combat.charge_begin()
			_run(float(blow["impact"]) - _training.game_time() - 0.07)
			_player.combat.charge_release()
		&"dodge":
			var away := (_player.global_position - Vector3(blow["target"])).normalized()
			if away.length() < 0.1:
				away = Vector3.RIGHT
			_player.global_position += away * 1.6
	_run(2.0, func() -> bool: return _outcomes.size() > before)
	_player.combat.charge_release()
	return _outcomes[before] if _outcomes.size() > before else &""


func test_the_stick_has_no_charge_and_seniorious_comes_back() -> void:
	assert_eq(_player.weapon(), &"seniorious", "Seniorious par défaut (l'ancienne île)")
	assert_true(_player.combat.can_charge())
	_start()
	assert_eq(_player.weapon(), &"baton", "le bâton pendant l'exercice")
	assert_false(_player.combat.can_charge(), "pas de charge de venenum")
	var charges: Array[float] = []
	EventBus.charge_progress.connect(func(ratio: float) -> void: charges.append(ratio))
	_player.combat.charge_begin()
	_run(1.0)
	assert_eq(_player.combat.current_state(), &"idle", "la touche de charge ne charge rien")
	assert_true(_player.combat.is_guarding(), "elle lève la parade")
	assert_eq(charges.size(), 0, "aucune jauge de charge")
	_player.combat.charge_release()
	_training.stop()
	assert_eq(_player.weapon(), &"seniorious", "l'arme d'avant revient")


func test_the_phases_follow_each_other_and_willem_waits_for_the_blow() -> void:
	_start()
	assert_eq(_training.phase, &"intro")
	assert_eq(
		LifeDirector.actor(&"willem").state, LifeActor.State.GAME, "Willem est mené par l'exercice"
	)
	_to_phase_a()
	var blow := _next_blow()
	assert_almost_eq(float(blow["impact"]) - float(blow["start"]), 0.5, 0.02, "annoncé 0,5 s avant")
	assert_eq(blow["kind"], &"blow")
	assert_true(blow["side"] in [&"gauche", &"droite", &"haut", &"estoc"])
	# Le cercle au sol, à l'endroit où Chtholly se tenait.
	var ring := _training.get_node(^"Telegraph")
	assert_not_null(ring)


func test_holding_the_guard_blocks_and_keeps_the_rhythm() -> void:
	_start()
	_to_phase_a()
	assert_eq(_respond(&"block"), &"blocked")
	assert_eq(_training.streak, 1)
	assert_eq(_training.touches, 0)
	assert_eq(_player.health.current, _player.health.max_hp, "aucun vrai dégât")


func test_releasing_the_guard_just_before_the_blow_deflects_and_opens_willem() -> void:
	_start()
	_to_phase_a()
	assert_eq(_respond(&"deflect"), &"deflected")
	assert_eq(_training.streak, 1)
	assert_eq(_training.streak_deflections, 1)
	assert_gt(_training.open_until, _training.game_time(), "la garde de Willem s'ouvre")
	assert_almost_eq(_training.open_until - _training.game_time(), 0.5, 0.05, "0,5 s")


func test_releasing_too_early_or_not_guarding_gets_hit_and_breaks_the_streak() -> void:
	_start()
	_to_phase_a()
	assert_eq(_respond(&"block"), &"blocked")
	assert_eq(_respond(&"block"), &"blocked")
	assert_eq(_training.streak, 2)
	# Trop tôt : la parade est baissée 0,3 s avant le coup.
	var blow := _next_blow()
	_player.combat.charge_begin()
	_run(float(blow["impact"]) - _training.game_time() - 0.3)
	_player.combat.charge_release()
	_run(1.0, func() -> bool: return _outcomes.size() >= 3)
	assert_eq(_outcomes[2], &"hit", "reçu")
	assert_eq(_training.streak, 0, "le compte revient à zéro")
	assert_eq(_training.touches, 1, "la jauge de touches")
	assert_eq(_respond(&"none"), &"hit", "sans parade non plus")
	assert_eq(_training.touches, 2)
	assert_eq(_player.health.current, _player.health.max_hp, "toujours aucun vrai dégât")


func test_stepping_out_of_the_circle_dodges() -> void:
	_start()
	_to_phase_a()
	assert_eq(_respond(&"dodge"), &"dodged")
	assert_eq(_training.streak, 1)


func test_the_rhythm_speeds_up_from_1_2_to_0_8_seconds() -> void:
	_start()
	_to_phase_a()
	assert_almost_eq(_training._tempo(0.0), 1.2, 0.001, "50 coups par minute")
	assert_almost_eq(_training._tempo(30.0), 1.0, 0.001)
	assert_almost_eq(_training._tempo(60.0), 0.8, 0.001, "75 coups par minute")
	assert_almost_eq(_training._tempo(200.0), 0.8, 0.001, "plafonné")
	# Mesuré sur deux coups de suite.
	var impacts: Array[float] = []
	for _i: int in 2:
		var blow := _next_blow()
		impacts.append(float(blow["impact"]))
		_player.combat.charge_begin()
		_run(2.0, func() -> bool: return _training.current_blow().is_empty())
		_player.combat.charge_release()
	assert_almost_eq(impacts[1] - impacts[0], 1.2, 0.05)


func test_the_deflect_window_shrinks_by_a_fifth_every_thirty_seconds() -> void:
	_start()
	_to_phase_a()
	assert_almost_eq(_training.deflect_window(), 0.15, 0.001)
	_training._fatigue_level = 1
	assert_almost_eq(_training.deflect_window(), 0.12, 0.001, "−20 %")
	_training._fatigue_level = 2
	assert_almost_eq(_training.deflect_window(), 0.09, 0.001)


func test_twelve_answers_in_a_row_with_three_deflections_succeed_phase_a() -> void:
	_start()
	_to_phase_a()
	for i: int in 12:
		var how := &"deflect" if i % 4 == 3 else &"block"
		assert_ne(_respond(how), &"hit", "réponse %d" % (i + 1))
	assert_eq(_training.phase, &"link", "phase A réussie : les aînées se lèvent")
	assert_eq(_training.streak, 12)
	assert_eq(_training.streak_deflections, 3)
	assert_true(_training.best_streak >= 12)


func test_twelve_blocked_but_no_deflection_is_not_enough() -> void:
	_start()
	_to_phase_a()
	for _i: int in 14:
		_respond(&"block")
	assert_eq(_training.phase, &"a", "il faut au moins trois déviations")
	assert_gte(_training.streak, 14)


func test_sitting_down_at_90_seconds_ends_the_exercise_without_defeat() -> void:
	_start()
	_to_phase_a()
	# Sans rien faire que bloquer : pas de déviation, jusqu'à la fatigue.
	_player.combat.charge_begin()
	_run(100.0, func() -> bool: return _training.phase == &"ended")
	_player.combat.charge_release()
	assert_eq(_training.phase, &"ended")
	assert_eq(_results.size(), 1, "finished une fois")
	assert_eq(_results[0]["ended_by"], &"fatigue")
	assert_false(_results[0]["success"])
	assert_true(_player.is_posing(), "Chtholly s'assoit, essoufflée")
	assert_eq(_player.health.current, _player.health.max_hp, "sans une égratignure")
	assert_eq(_player.weapon(), &"seniorious", "le bâton est rendu")


func test_too_many_touches_end_phase_a() -> void:
	_start()
	_to_phase_a()
	for _i: int in 6:
		_respond(&"none")
	assert_eq(_training.phase, &"ended")
	assert_eq(_results[0]["ended_by"], &"touches")
	assert_eq(_results[0]["touches"], 6)
	assert_eq(_results[0]["phase_a"]["hits"], 6)


func test_phase_b_is_three_against_one_and_counters_are_dodged_or_deflected() -> void:
	_start()
	_pass_phase_a()
	assert_eq(_training.phase, &"b", "trois contre un")
	var ithea := LifeDirector.actor(&"ithea")
	var nephren := LifeDirector.actor(&"nephren")
	var willem := LifeDirector.actor(&"willem")
	# Elles sont de part et d'autre de Willem, à portée de bâton.
	assert_lt(
		(
			Vector2(
				ithea.position().x - willem.position().x, ithea.position().z - willem.position().z
			)
			. length()
		),
		2.6
	)
	assert_lt(
		(
			Vector2(
				nephren.position().x - willem.position().x,
				nephren.position().z - willem.position().z
			)
			. length()
		),
		2.6
	)
	# Une contre sur Chtholly : la parade tenue ne suffit pas.
	var counter := _next_counter_on_player()
	_player.combat.charge_begin()
	_run(2.0, func() -> bool: return _training.current_blow().is_empty())
	_player.combat.charge_release()
	assert_eq(_outcomes[_outcomes.size() - 1], &"hit", "bloquer ne sert à rien")
	assert_eq(_training.counters, 1)
	assert_eq(counter["kind"], &"counter")
	assert_almost_eq(
		float(counter["impact"]) - float(counter["start"]), 0.4, 0.02, "annoncée 0,4 s avant"
	)
	# L'esquiver.
	counter = _next_counter_on_player()
	_player.global_position += Vector3(2.0, 0.0, 0.0)
	_run(2.0, func() -> bool: return _training.current_blow().is_empty())
	assert_eq(_outcomes[_outcomes.size() - 1], &"dodged")
	assert_eq(_training.counters, 1)


func test_phase_b_holding_for_sixty_seconds_with_few_counters_succeeds() -> void:
	_start({"overrides": {"phase_b/success_time": 20}})
	_pass_phase_a()
	# Toujours hors du cercle : aucune contre ne touche.
	for _i: int in 25 * 60:
		_step()
		var blow := _training.current_blow()
		if not blow.is_empty() and blow.get("ally") == null:
			_player.global_position = Vector3(blow["target"]) + Vector3(2.0, 0.0, 0.0)
		if _training.phase == &"ended":
			break
	assert_eq(_training.phase, &"ended")
	assert_true(_results[0]["success"], "tenir 60 s (ici 20)")
	assert_eq(_results[0]["ended_by"], &"success")
	assert_true(_results[0]["phase_b"]["survived"])
	assert_eq(_training.counters, 0)


func test_phase_b_four_counters_end_it() -> void:
	_start({"overrides": {"phase_b/counter_interval": 0.5}})
	_pass_phase_a()
	_run(60.0, func() -> bool: return _training.phase == &"ended")
	assert_eq(_training.phase, &"ended", "trop de contres reçus")
	assert_false(_results[0]["success"])
	assert_eq(_results[0]["phase_b"]["counters"], 4, "plus de trois")
	assert_eq(_results[0]["ended_by"], &"touches")


func test_phase_b_touching_willem_when_uncovered_wins() -> void:
	_start({"overrides": {"phase_b/ally_deflect_chance": 1.0, "phase_b/counter_interval": 0.8}})
	_pass_phase_a()
	var willem := LifeDirector.actor(&"willem")
	# Chtholly se tient à portée de Willem, tournée vers lui, et frappe dès qu'il est découvert.
	var struck := false
	for _i: int in 60 * 40:
		var blow := _training.current_blow()
		if not blow.is_empty() and blow.get("ally") == null:
			_player.global_position = Vector3(blow["target"]) + Vector3(2.5, 0.0, 0.0)
		elif blow.is_empty():
			_player.global_position = willem.position() + Vector3(0.0, 0.0, 1.2)
		_player.set_aim_direction(willem.position() - _player.global_position)
		if _training.open_until > _training.game_time() + 0.2 and not struck:
			_player.combat.emit_signal(&"attack_started", null)
			struck = true
		_step()
		if _training.phase == &"ended":
			break
	assert_eq(_training.phase, &"ended")
	assert_true(_results[0]["success"], "touché !")
	assert_true(_results[0]["phase_b"]["touched_willem"])


func test_striking_willem_when_he_is_covered_does_nothing() -> void:
	_start({"overrides": {"phase_b/ally_deflect_chance": 0.0}})
	_pass_phase_a()
	var willem := LifeDirector.actor(&"willem")
	_player.global_position = willem.position() + Vector3(0.0, 0.0, 1.2)
	_player.set_aim_direction(willem.position() - _player.global_position)
	_player.combat.emit_signal(&"attack_started", null)
	_run(0.5)
	assert_false(_training.touched_willem, "il pare")
	assert_eq(_training.phase, &"b")


func test_the_day_10_variant_closes_the_window_and_stops_at_the_third_miss() -> void:
	_start({"variant": &"jour10"})
	var closed: Array = []
	_training.window_closed.connect(func() -> void: closed.append(1))
	_to_phase_a()
	assert_gt(_training.deflect_window(), 0.0)
	# Il bloque tout (aucun raté) jusqu'à ce que la fenêtre se ferme, au bout de 15 s.
	while closed.is_empty() and _training.phase == &"a":
		_respond(&"block")
	assert_eq(closed.size(), 1, "le rythme tremble")
	assert_eq(_training.deflect_window(), 0.0, "plus de déviation possible")
	# Même une parade relâchée à temps ne dévie plus : c'est un coup reçu.
	var outcome := _respond(&"deflect")
	assert_eq(outcome, &"hit")
	_respond(&"deflect")
	_respond(&"deflect")
	assert_eq(_training.phase, &"ended", "au troisième raté")
	assert_eq(_results[0]["ended_by"], &"misses")


func test_the_exercise_gives_the_hand_back_to_the_villagers() -> void:
	_start()
	_to_phase_a()
	var willem := LifeDirector.actor(&"willem")
	assert_eq(willem.npc.get_prompt(), "", "pas d'invite « Parler » pendant l'exercice")
	assert_eq(LifeDirector.npc(&"ithea").get_prompt(), "")
	# (U1) L'invite est un signe posé au-dessus de la cible : aucun sur les participants.
	assert_eq(InteractSign.kind_of(willem.npc), &"", "pas de signe pendant l'exercice")
	assert_eq(InteractSign.kind_of(LifeDirector.npc(&"ithea")), &"")
	_training.stop()
	assert_eq(_results[0]["ended_by"], &"stopped")
	_run(4.0)
	await wait_physics_frames(2)
	assert_ne(willem.state, LifeActor.State.GAME, "Willem n'est plus mené par l'exercice")
	assert_eq(willem.npc.get_prompt(), "Parler", "on peut de nouveau lui parler")
	assert_eq(InteractSign.kind_of(willem.npc), InteractSign.TALK, "le signe « parler » revient")
	assert_null(MiniGames.staff_training(), "l'exercice est libéré")


func test_no_enemy_is_hurt_and_no_health_is_touched() -> void:
	_start()
	_to_phase_a()
	for _i: int in 3:
		_respond(&"none")
	for node: Node in get_tree().get_nodes_in_group(&"enemies"):
		assert_true(false, "aucun ennemi : %s" % node)
	assert_eq(_player.health.current, _player.health.max_hp)


## Réussit la phase A (douze réponses, trois déviations) pour passer à la B.
func _pass_phase_a() -> void:
	_to_phase_a()
	for i: int in 12:
		_respond(&"deflect" if i % 4 == 3 else &"block")
	assert_eq(_training.phase, &"link")
	_life_on = true
	_run(12.0, func() -> bool: return _training.phase == &"b")


## Avance jusqu'à une contre dirigée vers Chtholly et la renvoie.
func _next_counter_on_player() -> Dictionary:
	for _i: int in 60 * 20:
		var blow := _training.current_blow()
		if not blow.is_empty() and blow["kind"] == &"counter" and blow.get("ally") == null:
			return blow.duplicate()
		_step()
	assert_true(false, "une contre vise Chtholly")
	return {}
