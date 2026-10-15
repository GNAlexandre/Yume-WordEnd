extends GutTest
## (E8c) L'embuscade de Pannibal sur le sentier (game.tscn, le vrai Player, la nuit) : le bond
## annoncé qu'on esquive d'un pas de côté, les taillades qu'on pare ou qu'on esquive, la riposte, la
## jauge des points, la réussite et l'échec, les feintes à partir du jour 5, les deux lignes d'aide
## du jour 1, la graine fixe ; aucun vrai dégât ; Pannibal muette et sans signe pendant le jeu,
## tout rendu à la fin. Le jeu est avancé à la main (set_physics_process(false)), plus vite que le
## temps ; la parade est la touche de charge (PlayerCombat.charge_begin / charge_release).

const GAME_SCENE := preload("res://src/game.tscn")
const MAP := &"sentier"
const DT := 1.0 / 60.0

var _game: Node3D
var _player: Player
var _ambush: Ambush
var _outcomes: Array[Array] = []
var _results: Array[Dictionary] = []


func before_all() -> void:
	GameState.reset()
	WorldManager.fade_time = 0.0
	_game = GAME_SCENE.instantiate() as Node3D
	add_child(_game)
	_player = _game.get_node(^"Player") as Player
	LifeDirector.set_slot(&"nuit", 0.0)
	assert_true(WorldManager.enter_map(MAP))


func after_all() -> void:
	WorldManager.fade_time = WorldManager.DEFAULT_FADE_TIME
	_game.free()
	LifeDirector.attach(null)
	Atmosphere.dress(null)
	GameState.reset()
	GameRules.clear_cache()
	DialogueBox.set_presentation(DialogueBox.PRESENTATION_NUIT)


func before_each() -> void:
	GameRules.clear_cache()
	LifeDirector.set_slot(&"nuit", 0.0)
	LifeDirector.attach(WorldManager.current_map_node())
	LifeDirector.build_nav_now()
	var places := LifeDirector.places()
	_player.global_position = places.center(&"premiere_embuscade") + Vector3(0.0, 0.1, 0.0)
	_player.velocity = Vector3.ZERO
	_player.set_weapon(PlayerCombat.WEAPON_SENIORIOUS)
	_player.hold_pose(&"", 0.0)
	_player.set_story_hold(false)
	_player.set_aim_direction(Vector3.RIGHT)
	_player.combat.charge_release()
	var pannibal := LifeDirector.actor(&"pannibal")
	if pannibal != null:
		pannibal.set_position(_player.global_position + Vector3(1.2, 0.0, -0.4))
	_outcomes.clear()
	_results.clear()


func after_each() -> void:
	if is_instance_valid(_ambush):
		_ambush.stop()
		_ambush.free()
	_ambush = null
	_player.combat.charge_release()


func _start(options: Dictionary = {}) -> Ambush:
	var merged := options.duplicate(true)
	if not merged.has("seed"):
		merged["seed"] = 68
	_ambush = MiniGames.start_ambush(merged)
	assert_not_null(_ambush, "l'embuscade démarre")
	_ambush.set_physics_process(false)
	_ambush.resolved.connect(
		func(kind: StringName, outcome: StringName) -> void: _outcomes.append([kind, outcome])
	)
	_ambush.finished.connect(func(found: Dictionary) -> void: _results.append(found))
	return _ambush


## Avance le jeu de seconds s, ou jusqu'à ce que until soit vrai.
func _run(seconds: float, until: Callable = Callable()) -> void:
	for _i: int in roundi(seconds / DT):
		_ambush.advance(DT)
		if until.is_valid() and until.call():
			return


func _pannibal() -> LifeActor:
	return LifeDirector.actor(&"pannibal")


func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


## Avance jusqu'à l'annonce d'une attaque de cette sorte et la renvoie.
func _next_attack(kind: StringName) -> Dictionary:
	_run(
		6.0,
		func() -> bool:
			var attack := _ambush.current_attack()
			return not attack.is_empty() and attack["kind"] == kind
	)
	var found := _ambush.current_attack()
	assert_false(found.is_empty(), "une attaque %s est annoncée" % kind)
	return found.duplicate()


## Joue jusqu'à la prochaine issue et la renvoie ([sorte, issue]).
func _until_outcome() -> Array:
	var before := _outcomes.size()
	_run(3.0, func() -> bool: return _outcomes.size() > before)
	return _outcomes[before] if _outcomes.size() > before else []


## Esquive le bond annoncé : un pas de côté, hors du cercle.
func _dodge_leap() -> Array:
	var leap := _next_attack(&"leap")
	var target: Vector3 = leap["target"]
	var side := Vector3(0.0, 0.0, 1.4)
	_player.global_position = Vector3(target.x, _player.global_position.y, target.z) + side
	return _until_outcome()


## Pare une taillade : la parade tenue à l'impact.
func _parry_slash() -> Array:
	_next_attack(&"slash")
	_player.combat.charge_begin()
	var outcome := _until_outcome()
	_player.combat.charge_release()
	return outcome


func test_the_ambush_starts_with_the_stick_and_pannibal_leaps_from_four_metres() -> void:
	assert_eq(_player.weapon(), &"seniorious")
	DialogueBox.set_presentation(DialogueBox.PRESENTATION_BANDEAU)
	_player.set_story_hold(true)
	_start()
	assert_eq(_player.weapon(), &"baton", "le bâton pendant l'embuscade")
	assert_false(_player.is_story_held(), "le joueur a la main le temps du combat")
	assert_eq(DialogueBox.presentation(), DialogueBox.PRESENTATION_NUIT, "présentation « nuit »")
	assert_eq(_ambush.phase, &"intro")
	var pannibal := _pannibal()
	assert_not_null(pannibal, "Pannibal est sur le sentier")
	assert_eq(pannibal.npc.get_prompt(), "", "pas d'invite « Parler » pendant l'embuscade")
	assert_eq(InteractSign.kind_of(pannibal.npc), &"", "pas de signe sur Pannibal")
	var leap := _next_attack(&"leap")
	assert_eq(_ambush.phase, &"leap")
	assert_almost_eq(float(leap["impact"]) - float(leap["start"]), 0.8, 0.02, "annoncé 0,8 s avant")
	assert_almost_eq(
		_flat_distance(pannibal.position(), _player.global_position), 4.0, 0.3, "lancé de 4 m"
	)
	assert_true(_ambush.get_node(^"Light").visible, "la lumière qui zigzague")
	assert_eq(_ambush.get_node(^"Telegraph").call(&"mode"), &"strike", "le cercle au sol")


func test_a_side_step_dodges_the_leap_and_opens_pannibal() -> void:
	_start()
	assert_eq(_dodge_leap(), [&"leap", &"dodged"])
	assert_eq(_ambush.streak, 1)
	assert_gt(_ambush.open_until, _ambush.game_time(), "Pannibal est découverte")
	assert_eq(_ambush.phase, &"slash", "les taillades suivent")


func test_holding_the_guard_does_not_stop_the_leap() -> void:
	_start()
	_next_attack(&"leap")
	var before := _player.global_position
	_player.combat.charge_begin()
	assert_eq(_until_outcome(), [&"leap", &"hit"], "la parade ne suffit pas au bond")
	_player.combat.charge_release()
	assert_eq(_ambush.points, 1, "un point pour Pannibal")
	assert_eq(_ambush.streak, 0)
	assert_almost_eq(
		_flat_distance(_player.global_position, before), 0.5, 0.2, "Chtholly recule de 0,5 m"
	)
	assert_eq(_player.health.current, _player.health.max_hp, "aucun vrai dégât")
	assert_eq(_ambush.phase, &"rest", "la série s'arrête, Pannibal recule")


func test_slashes_are_parried_with_the_guard_or_dodged_out_of_reach() -> void:
	_start()
	_dodge_leap()
	var slash := _next_attack(&"slash")
	assert_almost_eq(float(slash["impact"]) - float(slash["start"]), 0.25, 0.02)
	_player.combat.charge_begin()
	assert_eq(_until_outcome(), [&"slash", &"parried"])
	_player.combat.charge_release()
	# La suivante, 0,35 s plus tard : hors de portée, esquivée.
	var next := _next_attack(&"slash")
	assert_almost_eq(float(next["impact"]) - float(slash["impact"]), 0.35, 0.03, "0,35 s d'écart")
	var away := (_player.global_position - _pannibal().position()) * Vector3(1, 0, 1)
	_player.global_position += away.normalized() * 2.0
	assert_eq(_until_outcome(), [&"slash", &"dodged"])
	assert_eq(_ambush.streak, 3)


func test_a_slash_taken_scores_a_point_and_ends_the_series() -> void:
	_start()
	_dodge_leap()
	_next_attack(&"slash")
	assert_eq(_until_outcome(), [&"slash", &"hit"])
	assert_eq(_ambush.points, 1)
	assert_eq(_ambush.phase, &"rest")
	assert_eq(_player.health.current, _player.health.max_hp, "aucun vrai dégât")


func test_five_answers_in_a_row_win_and_pannibal_falls() -> void:
	_start()
	assert_eq(_dodge_leap()[1], &"dodged")
	for _i: int in 3:
		assert_eq(_parry_slash()[1], &"parried")
	assert_eq(_dodge_leap()[1], &"dodged")
	assert_eq(_ambush.phase, &"ended", "cinq de suite")
	assert_true(_ambush.result()["success"])
	assert_eq(_ambush.result()["ended_by"], &"streak")
	assert_eq(_pannibal().npc.visual.current_animation(), &"tombe", "à plat ventre")
	assert_eq(_results.size(), 0, "finished après la pose de fin")
	_run(2.0)
	assert_eq(_results.size(), 1, "finished une fois")
	assert_eq(_player.weapon(), &"seniorious", "l'arme d'avant revient")
	assert_eq(_player.health.current, _player.health.max_hp)


func test_three_points_for_pannibal_end_it_without_defeat() -> void:
	DialogueBox.set_presentation(DialogueBox.PRESENTATION_BANDEAU)
	_player.set_story_hold(true)
	_start()
	_run(30.0, func() -> bool: return _ambush.phase == &"ended")
	assert_eq(_ambush.phase, &"ended")
	assert_false(_ambush.result()["success"])
	assert_eq(_ambush.result()["ended_by"], &"points")
	assert_eq(_ambush.result()["points"], 3)
	assert_true(
		_pannibal().npc.visual.current_animation() in [&"lance", &"frappe"],
		"elle lève son épée et proclame sa victoire"
	)
	_run(2.0)
	assert_eq(_results.size(), 1)
	assert_eq(_player.health.current, _player.health.max_hp, "toujours aucun vrai dégât")
	assert_true(_player.is_story_held(), "la scène reprend la main comme avant le jeu")
	assert_eq(DialogueBox.presentation(), DialogueBox.PRESENTATION_BANDEAU, "présentation rendue")
	assert_eq(_pannibal().npc.get_prompt(), "Parler", "on peut de nouveau lui parler")
	assert_eq(InteractSign.kind_of(_pannibal().npc), InteractSign.TALK, "son signe revient")
	assert_null(MiniGames.ambush(), "le jeu est libéré")


func test_a_riposte_after_a_dodge_touches_her() -> void:
	_start()
	_dodge_leap()
	var pannibal := _pannibal()
	_player.global_position = pannibal.position() + Vector3(0.0, 0.0, 1.0)
	_player.set_aim_direction(pannibal.position() - _player.global_position)
	_player.combat.emit_signal(&"attack_started", null)
	_run(0.3)
	assert_has(_outcomes, [&"riposte", &"touched"])
	assert_eq(_ambush.phase, &"ended")
	assert_eq(_ambush.result()["ended_by"], &"riposte")
	assert_true(_ambush.result()["touched"])


func test_striking_her_when_she_is_covered_she_evades() -> void:
	_start()
	_next_attack(&"leap")
	var pannibal := _pannibal()
	_player.global_position = pannibal.position() + Vector3(0.0, 0.0, 1.0)
	_player.set_aim_direction(pannibal.position() - _player.global_position)
	_player.combat.emit_signal(&"attack_started", null)
	_run(0.2)
	assert_has(_outcomes, [&"riposte", &"evaded"], "elle esquive")
	assert_true(_ambush.is_running())


func test_day_one_shows_the_two_help_lines_once() -> void:
	_start({"help": true, "day": 1})
	var shown: Array[StringName] = []
	_ambush.help_shown.connect(func(key: StringName) -> void: shown.append(key))
	_next_attack(&"leap")
	assert_eq(shown, [&"dodge"])
	assert_string_contains(_ambush.hud_text(), "pas de côté")
	_dodge_leap()
	_next_attack(&"slash")
	assert_eq(shown, [&"dodge", &"guard"])
	assert_string_contains(_ambush.hud_text(), "parade")
	_until_outcome()
	_run(8.0, func() -> bool: return _ambush.leaps >= 2 and _ambush.phase == &"slash")
	assert_eq(shown, [&"dodge", &"guard"], "une seule fois")


func test_from_day_five_one_leap_in_three_is_a_feint() -> void:
	_start({"day": 5, "overrides": {"touch_limit": 9, "success_streak": 99}})
	var seen: Array[bool] = []
	for _i: int in 3:
		seen.append(bool(_next_attack(&"leap")["feint"]))
		_run(1.0, func() -> bool: return _ambush.phase != &"leap")
	assert_eq(seen, [false, false, true])
	assert_has(_outcomes, [&"leap", &"feint"])
	assert_eq(_ambush.feints, 1)


func test_day_one_has_no_feint() -> void:
	_start({"day": 1, "overrides": {"touch_limit": 9, "success_streak": 99}})
	for _i: int in 3:
		assert_false(bool(_next_attack(&"leap")["feint"]))
		_run(1.0, func() -> bool: return _ambush.phase != &"leap")


func test_the_same_seed_replays_the_same_ambush() -> void:
	var timelines: Array = []
	for _round: int in 2:
		_start({"seed": 7})
		var timeline: Array[float] = []
		for _i: int in 3:
			timeline.append(snappedf(float(_next_attack(&"leap")["impact"]), 0.001))
			_run(1.0, func() -> bool: return _ambush.phase != &"leap")
		timelines.append(timeline)
		_ambush.stop()
		_ambush.free()
		_ambush = null
	assert_eq(timelines[0], timelines[1], "même graine, mêmes temps de repos")


func test_stopping_gives_everything_back() -> void:
	DialogueBox.set_presentation(DialogueBox.PRESENTATION_BANDEAU)
	_start()
	_next_attack(&"leap")
	_ambush.stop()
	assert_eq(_results.size(), 1)
	assert_eq(_results[0]["ended_by"], &"stopped")
	assert_eq(_player.weapon(), &"seniorious")
	assert_eq(DialogueBox.presentation(), DialogueBox.PRESENTATION_BANDEAU)
	assert_eq(_pannibal().npc.get_prompt(), "Parler")


func test_without_pannibal_or_player_it_does_not_start() -> void:
	assert_null(MiniGames.start_ambush({"npc": &"inconnue"}), "personne à qui se battre")
	assert_true(StoryDirector.has_game(MiniGames.STORY_AMBUSH), "inscrite au récit")
