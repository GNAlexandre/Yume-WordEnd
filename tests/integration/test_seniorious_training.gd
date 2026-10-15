extends GutTest
## (E8b) L'entraînement spécial avec Seniorious à la clairière (game.tscn, le vrai Player,
## l'après-midi) : la respiration (cinq cycles, Willem corrige, pas d'échec), les mouvements de base
## (neuf annonces, exécutées en 1,5 s), la Grue de Gossamer (parade parfaite de 0,2 s puis une
## attaque ; trois Grues arrachent l'épée, qui plonge dans le marais), l'épée ramassée : la
## réussite ; douze fends sans trois Grues : l'échec, Chtholly s'assoit ; la graine fixe ; aucun
## dégât ; tout rendu à la fin. L'exercice est avancé à la main (set_physics_process(false)).

const GAME_SCENE := preload("res://src/game.tscn")
const SWORD := preload("res://data/attacks/sword_1.tres")
const MAP := &"entrepot"
const DT := 1.0 / 60.0

var _game: Node3D
var _player: Player
var _training: SenioriousTraining
var _outcomes: Array[Array] = []
var _stages: Array[StringName] = []
var _gestures: Array[StringName] = []
var _results: Array[Dictionary] = []
var _home := Vector3.ZERO


func before_all() -> void:
	GameState.reset()
	WorldManager.fade_time = 0.0
	_game = GAME_SCENE.instantiate() as Node3D
	add_child(_game)
	_player = _game.get_node(^"Player") as Player
	LifeDirector.set_slot(&"apres_midi", 0.0)
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
	LifeDirector.set_slot(&"apres_midi", 0.0)
	LifeDirector.attach(WorldManager.current_map_node())
	LifeDirector.build_nav_now()
	_player.set_weapon(PlayerCombat.WEAPON_STICK)
	_player.hold_pose(&"", 0.0)
	_player.set_story_hold(false)
	_player.combat.charge_release()
	_outcomes.clear()
	_stages.clear()
	_gestures.clear()
	_results.clear()


func after_each() -> void:
	if is_instance_valid(_training):
		_training.stop()
		if is_instance_valid(_training):
			_training.free()
	_training = null
	_player.combat.charge_release()
	_player.set_weapon(PlayerCombat.WEAPON_SENIORIOUS)


func _start(options: Dictionary = {}) -> SenioriousTraining:
	var merged := options.duplicate(true)
	if not merged.has("seed"):
		merged["seed"] = 11
	merged["place_player"] = true
	_training = MiniGames.start_seniorious_training(merged)
	assert_not_null(_training, "l'entraînement démarre")
	_training.set_physics_process(false)
	_training.resolved.connect(
		func(kind: StringName, outcome: StringName) -> void: _outcomes.append([kind, outcome])
	)
	_training.stage_changed.connect(func(next: StringName) -> void: _stages.append(next))
	_training.announced.connect(func(gesture: StringName) -> void: _gestures.append(gesture))
	_training.finished.connect(func(found: Dictionary) -> void: _results.append(found))
	_home = _player.global_position
	return _training


func _run(seconds: float, until: Callable = Callable()) -> void:
	for _i: int in roundi(seconds / DT):
		if not is_instance_valid(_training) or _training.is_done():
			return
		_training.advance(DT)
		if until.is_valid() and until.call():
			return


func _run_until(time: float) -> void:
	_run(maxf(time - _training.game_time(), 0.0) + DT * 0.5)


func _last(kind: StringName) -> Array:
	for index: int in range(_outcomes.size() - 1, -1, -1):
		if _outcomes[index][0] == kind:
			return _outcomes[index]
	return []


## Un souffle : la charge pressée au début du cycle, relâchée à release_offset s de sa fin.
func _breathe(release_offset: float) -> StringName:
	var before := _outcomes.size()
	_run_until(_training.breath_end() - 4.0 + 0.05)
	_player.combat.charge_begin()
	var end := _training.breath_end()
	_run_until(end + release_offset)
	_player.combat.charge_release()
	_run(6.0, func() -> bool: return _outcomes.size() > before)
	return _last(&"breath")[1] if not _last(&"breath").is_empty() else &""


## Exécute le geste annoncé.
func _do_gesture(gesture: StringName) -> void:
	match gesture:
		&"trois_coups":
			for _i: int in 3:
				_player.combat.attack_started.emit(SWORD)
				_run(0.2)
		&"pare":
			_player.combat.charge_begin()
			_run(0.2)
			_player.combat.charge_release()
		&"cote":
			_player.global_position += Vector3(0.0, 0.0, 1.0)
			_run(0.2)
			_player.global_position = _home


## Jusqu'au prochain fend annoncé.
func _next_fend() -> Dictionary:
	_run(5.0, func() -> bool: return not _training.current_fend().is_empty())
	return _training.current_fend().duplicate()


## Une Grue : parade parfaite (0,1 s avant l'impact) puis une attaque.
func _crane() -> Array:
	var fend := _next_fend()
	assert_false(fend.is_empty(), "un fend est annoncé")
	var impact := float(fend["impact"])
	_run_until(impact - 0.1)
	_player.combat.charge_begin()
	_run_until(impact + 0.05)
	_player.combat.charge_release()
	_player.combat.attack_started.emit(SWORD)
	_run(0.3, func() -> bool: return not _last(&"fend").is_empty())
	return _last(&"fend")


func test_the_training_starts_with_seniorious_and_the_breath() -> void:
	_start()
	assert_eq(_player.weapon(), &"seniorious", "Seniorious en main")
	var willem := LifeDirector.actor(&"willem")
	assert_eq(willem.outfit, &"duel", "Willem et le Carillon Percival")
	assert_eq(willem.npc.get_prompt(), "", "on ne lui parle pas pendant l'exercice")
	assert_lt(
		(
			Vector2(
				willem.position().x - _player.global_position.x,
				willem.position().z - _player.global_position.z
			)
			. length()
		),
		2.6,
		"face à Willem"
	)
	_run(2.0, func() -> bool: return _training.stage == &"breath")
	assert_eq(_training.stage, &"breath", "étape 1 : la respiration")
	assert_string_contains(_training.hud_text(), "Souffle")


func test_the_breath_cycles_are_corrected_without_failure() -> void:
	_start()
	_run(2.0, func() -> bool: return _training.stage == &"breath")
	var cycle := _training.breath_end() - _training.game_time()
	assert_almost_eq(cycle, 4.0 + 0.6, 0.05, "inspirer 2 s, expirer 2 s (après un temps)")
	assert_eq(_breathe(0.1), &"good", "relâchée à 0,1 s de la fin")
	assert_eq(_breathe(-1.0), &"early", "plus lent")
	assert_eq(_breathe(0.0), &"good")
	# Un cycle sans rien : Willem corrige, rien n'échoue.
	_run(5.0, func() -> bool: return _last(&"breath") == [&"breath", &"missed"])
	assert_eq(_last(&"breath"), [&"breath", &"missed"])
	_run(5.0, func() -> bool: return _training.stage != &"breath")
	assert_eq(int(_training.breaths[&"cycles"]), 5, "cinq cycles")
	assert_eq(int(_training.breaths[&"good"]), 2)
	assert_true(_training.is_running(), "pas d'échec")
	_run(3.0, func() -> bool: return _training.stage == &"moves")
	assert_eq(_training.stage, &"moves", "étape 2")


func test_the_basic_moves_are_announced_and_must_follow_within_one_and_a_half_seconds() -> void:
	_start({"start_stage": 2})
	_run(2.0, func() -> bool: return _training.stage == &"moves")
	assert_eq(_stages, [&"moves"], "la réussite du jour 9 : directement à l'étape 2")
	for index: int in 9:
		_run(3.0, func() -> bool: return not _training.current_gesture().is_empty())
		var gesture: Dictionary = _training.current_gesture()
		assert_false(gesture.is_empty(), "annonce %d" % index)
		assert_almost_eq(float(gesture["deadline"]) - float(gesture["start"]), 1.5, 0.01)
		if index == 4:
			_run(1.6)
			assert_eq(_last(&"move"), [&"move", &"missed"], "trop tard")
			continue
		_do_gesture(gesture["gesture"])
		_run(0.2)
		assert_eq(_last(&"move"), [&"move", &"done"], "%s exécuté" % gesture["gesture"])
	assert_eq(_gestures.size(), 9, "neuf annonces")
	for kind: StringName in [&"trois_coups", &"pare", &"cote"]:
		assert_eq(_gestures.count(kind), 3, "trois fois %s" % kind)
	assert_eq(int(_training.moves[&"done"]), 8)
	assert_eq(int(_training.moves[&"missed"]), 1)
	_run(4.0, func() -> bool: return _training.stage == &"crane")
	assert_eq(_training.stage, &"crane", "étape 3")


func test_three_cranes_tear_seniorious_away_and_picking_it_up_succeeds() -> void:
	var health := _player.health.current
	_start({"start_stage": 3})
	_run(2.0, func() -> bool: return _training.stage == &"crane")
	var fend := _next_fend()
	assert_almost_eq(float(fend["impact"]) - float(fend["start"]), 0.6, 0.02, "annoncé 0,6 s")
	# Une parade trop tôt : parée, pas de Grue.
	_run_until(float(fend["impact"]) - 0.45)
	_player.combat.charge_begin()
	_run_until(float(fend["impact"]) + 0.05)
	_player.combat.charge_release()
	assert_eq(_last(&"fend"), [&"fend", &"parried"], "hors de la fenêtre de 0,2 s")
	# Rien : touchée à peine, sans dégât.
	_next_fend()
	_run(1.0, func() -> bool: return _last(&"fend") == [&"fend", &"hit"])
	assert_eq(_last(&"fend"), [&"fend", &"hit"])
	assert_eq(_player.health.current, health, "aucun vrai dégât")
	for i: int in 3:
		_player.global_position = _home
		assert_eq(_crane(), [&"fend", &"crane"], "Grue %d" % (i + 1))
	assert_eq(_training.grues, 3)
	assert_eq(_training.stage, &"pickup", "la troisième arrache Seniorious")
	assert_has(_outcomes, [&"sword", &"flew"])
	_run(2.0, func() -> bool: return _training.sword_spot() != Vector3.INF)
	var spot := _training.sword_spot()
	var marsh := LifeDirector.places().center(&"marais_epee")
	assert_almost_eq(Vector2(spot.x - marsh.x, spot.z - marsh.z).length(), 0.0, 0.05, "le marais")
	var area := _training.pickup_area()
	assert_not_null(area, "l'épée se ramasse")
	assert_true(area.is_in_group(&"interactable"))
	assert_eq(area.call(&"get_prompt"), "Ramasser Seniorious")
	area.call(&"interact", _player)
	_run(3.0)
	assert_eq(_results.size(), 1)
	var result := _results[0]
	assert_true(result["success"], "trois Grues et l'épée ramassée")
	assert_eq(result["ended_by"], &"grues")
	assert_true(result["picked_up"])
	assert_eq(result["start_stage"], 3)
	assert_eq(_player.health.current, health)
	assert_eq(_player.weapon(), &"baton", "l'arme d'avant revient")
	assert_ne(LifeDirector.actor(&"willem").outfit, &"duel", "Percival rangé")


func test_without_three_cranes_she_sits_down_exhausted() -> void:
	_start({"start_stage": 3, "overrides": {"crane/max_fends": 3}})
	_run(2.0, func() -> bool: return _training.stage == &"crane")
	_run(20.0, func() -> bool: return _training.stage == &"ended")
	assert_eq(_training.stage, &"ended")
	assert_eq(_training.fends, 3)
	assert_true(_player.is_posing(), "assise dans l'herbe, essoufflée")
	assert_true(_player.visual.current_animation() in [&"assis", &"degats"])
	_run(3.0)
	assert_eq(_results.size(), 1)
	assert_false(_results[0]["success"], "l'échec, sans écran de défaite")
	assert_eq(_results[0]["ended_by"], &"fatigue")
	assert_false(_player.is_posing(), "la pose est rendue")


func test_the_story_can_skip_the_pickup() -> void:
	_start({"start_stage": 3, "pickup": false})
	_run(2.0, func() -> bool: return _training.stage == &"crane")
	for _i: int in 3:
		_player.global_position = _home
		_crane()
	_run(5.0)
	assert_eq(_results.size(), 1)
	assert_true(_results[0]["success"])
	assert_false(_results[0]["picked_up"], "le récit s'en charge")


func test_a_fixed_seed_announces_the_same_gestures() -> void:
	var runs: Array = []
	for _attempt: int in 2:
		_gestures.clear()
		_start({"start_stage": 2, "seed": 99})
		_run(2.0, func() -> bool: return _training.stage == &"moves")
		_run(30.0, func() -> bool: return _gestures.size() >= 9)
		runs.append(_gestures.duplicate())
		_training.stop()
	assert_eq(runs[0].size(), 9)
	assert_eq(runs[0], runs[1], "la même graine : les mêmes annonces")
