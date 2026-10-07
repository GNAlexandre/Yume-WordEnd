extends "res://tests/stubs/q_quest_test.gd"
## Lot Q, QuestTracker : chaque type d'étape (talk, reach zone ou déclencheur, kill, collect avec
## ou sans PNJ, arena vague ou score, flag), advance_quest, récompenses d'étape et de quête, fin
## forcée (complete_quest) acceptée ou refusée, prérequis et enchaînement (quête rendue
## disponible, auto_start), quête suivie, reprise d'une partie chargée, un seul tracker actif.

const Q := &"q"


## Écrit la quête q (étapes données, champs en plus) et la démarre si start.
func _make(steps: Array, extra: Dictionary = {}, start: bool = true) -> void:
	var data := {"id": String(Q), "title": "Quête", "steps": steps}
	data.merge(extra, true)
	write_quest(data)
	if start:
		start_quest(Q)


func _step(step_id: String, step_type: String, fields: Dictionary = {}) -> Dictionary:
	var step := {"id": step_id, "type": step_type, "objective": "Objectif " + step_id}
	step.merge(fields, true)
	return step


func _flag_end() -> Dictionary:
	return _step("end", "flag", {"flag": "the_end"})


# --- Types d'étapes ----------------------------------------------------------------------------


func test_start_enters_the_first_step_and_tracks_the_quest() -> void:
	watch_signals(EventBus)
	_make([_step("a", "talk", {"npc": "child"}), _flag_end()])
	assert_eq(step_of(Q), &"a")
	assert_eq(count_of(Q), 0)
	assert_eq(GameState.tracked_quest, Q)
	assert_signal_emitted_with_parameters(EventBus, "quest_step_updated", [Q, &"a", 0])
	assert_signal_emitted_with_parameters(EventBus, "tracked_quest_changed", [Q])


func test_talk_step_at_the_end_of_a_conversation() -> void:
	_make([_step("a", "talk", {"npc": "blacksmith"}), _flag_end()])
	chat(&"child")
	assert_eq(step_of(Q), &"a", "un autre PNJ ne compte pas")
	EventBus.dialogue_started.emit(&"blacksmith")
	assert_eq(step_of(Q), &"a", "pas avant la fin du dialogue")
	EventBus.dialogue_ended.emit(&"blacksmith")
	assert_eq(step_of(Q), &"end")


func test_talk_step_ignores_the_conversation_that_started_the_quest() -> void:
	write_quest(
		{"id": "q", "title": "Q", "steps": [_step("a", "talk", {"npc": "child"}), _flag_end()]}
	)
	EventBus.dialogue_started.emit(&"child")
	start_quest(Q)
	EventBus.dialogue_ended.emit(&"child")
	assert_eq(step_of(Q), &"a", "le dialogue qui démarre la quête ne valide pas son étape talk")
	chat(&"child")
	assert_eq(step_of(Q), &"end", "la conversation suivante, oui")


func test_advance_requested_validates_the_current_step() -> void:
	watch_signals(EventBus)
	_make(
		[_step("a", "talk", {"npc": "child"}), _step("b", "reach", {"zone": "beach"}), _flag_end()]
	)
	EventBus.quest_advance_requested.emit(Q, &"b")
	assert_eq(step_of(Q), &"a", "garde : ce n'est pas l'étape b")
	EventBus.quest_advance_requested.emit(Q, &"a")
	assert_eq(step_of(Q), &"b")
	EventBus.quest_advance_requested.emit(Q, &"")
	assert_eq(step_of(Q), &"end", "sans étape : l'étape courante, quelle qu'elle soit")
	assert_signal_emitted_with_parameters(EventBus, "quest_step_completed", [Q, &"b"])
	EventBus.quest_advance_requested.emit(&"inconnue", &"")
	assert_push_warning("n'est pas active")


func test_reach_zone_step() -> void:
	_make([_step("a", "reach", {"zone": "beach"}), _flag_end()])
	enter_zone(&"forest")
	assert_eq(step_of(Q), &"a")
	enter_zone(&"beach")
	assert_eq(step_of(Q), &"end")


func test_reach_zone_step_when_already_there() -> void:
	enter_zone(&"beach")
	_make([_step("a", "reach", {"zone": "beach"}), _flag_end()])
	assert_eq(step_of(Q), &"end", "le joueur est déjà sur la plage")


func test_reach_trigger_step() -> void:
	_make([_step("a", "reach", {"trigger": "rock"}), _flag_end()])
	enter_trigger(&"well")
	assert_eq(step_of(Q), &"a")
	enter_trigger(&"rock")
	assert_eq(step_of(Q), &"end")


func test_kill_step_counts_matching_enemies_in_its_zone() -> void:
	_make(
		[
			_step("any", "kill", {"count": 2}),
			_step("big", "kill", {"enemy": "timere_big", "zone": "dunes"}),
			_flag_end(),
		]
	)
	kill(&"timere_small")
	assert_eq(count_of(Q), 1, "n'importe quel ennemi")
	kill(&"timere_runner")
	assert_eq(step_of(Q), &"big", "deux ennemis : étape suivante")
	assert_eq(count_of(Q), 0, "compteur remis à zéro")
	kill(&"timere_big")
	assert_eq(step_of(Q), &"big", "hors des dunes")
	enter_zone(&"dunes")
	kill(&"timere_normal")
	assert_eq(step_of(Q), &"big", "pas le bon ennemi")
	kill(&"timere_big")
	assert_eq(step_of(Q), &"end")


func test_kills_before_the_step_do_not_count() -> void:
	write_quest({"id": "q", "title": "Q", "steps": [_step("k", "kill", {"count": 2}), _flag_end()]})
	kill(&"timere_small", 3)
	start_quest(Q)
	assert_eq(count_of(Q), 0)
	kill(&"timere_small")
	assert_eq(count_of(Q), 1)


func test_collect_step_on_possession_with_consume() -> void:
	_make([_step("shells", "collect", {"item": "shell", "count": 3, "consume": true}), _flag_end()])
	GameState.add_item(&"shell", 2)
	assert_eq(step_of(Q), &"shells")
	GameState.add_item(&"shell", 2)
	assert_eq(step_of(Q), &"end", "trois coquillages")
	assert_eq(GameState.count(&"shell"), 1, "trois retirés (consume)")


func test_collect_step_without_consume_keeps_the_items() -> void:
	GameState.add_item(&"shell", 2)
	_make([_step("shells", "collect", {"item": "shell", "count": 2}), _flag_end()])
	assert_eq(step_of(Q), &"end", "déjà en poche : validée tout de suite")
	assert_eq(GameState.count(&"shell"), 2)


func test_collect_step_for_an_npc_needs_the_conversation_and_the_items() -> void:
	_make(
		[
			_step(
				"give", "collect", {"item": "shell", "count": 2, "npc": "child", "consume": true}
			),
			_flag_end(),
		]
	)
	GameState.add_item(&"shell", 1)
	chat(&"child")
	assert_eq(step_of(Q), &"give", "pas assez de coquillages")
	GameState.add_item(&"shell", 1)
	assert_eq(step_of(Q), &"give", "il faut les rapporter")
	chat(&"blacksmith")
	assert_eq(step_of(Q), &"give", "au bon PNJ")
	chat(&"child")
	assert_eq(step_of(Q), &"end")
	assert_eq(GameState.count(&"shell"), 0, "rapportés")


func test_consecutive_collect_steps_consume_once_each() -> void:
	_make(
		[
			_step("one", "collect", {"item": "shell", "count": 2, "consume": true}),
			_step("two", "collect", {"item": "shell", "count": 2, "consume": true}),
			_flag_end(),
		]
	)
	GameState.add_item(&"shell", 3)
	assert_eq(step_of(Q), &"two", "la première prend 2, il en reste 1")
	assert_eq(GameState.count(&"shell"), 1)
	GameState.add_item(&"shell", 5)
	assert_eq(step_of(Q), &"end")
	assert_eq(GameState.count(&"shell"), 4, "2 + 2 retirés sur 8, jamais en double")


func test_arena_wave_step() -> void:
	_make([_step("w", "arena", {"arena": "dunes", "wave": 3}), _flag_end()])
	reach_wave(&"other", 5)
	assert_eq(count_of(Q), 0, "autre arène")
	reach_wave(&"dunes", 2)
	assert_eq(count_of(Q), 2, "meilleure vague de l'étape")
	reach_score(&"dunes", 500)
	assert_eq(step_of(Q), &"w", "un score ne compte pas pour une vague")
	reach_wave(&"dunes", 1)
	assert_eq(count_of(Q), 2, "la meilleure vague est gardée")
	reach_wave(&"dunes", 3)
	assert_eq(step_of(Q), &"end")


func test_arena_score_step() -> void:
	_make([_step("s", "arena", {"arena": "dunes", "score": 300}), _flag_end()])
	reach_score(&"dunes", 120)
	assert_eq(count_of(Q), 120)
	reach_wave(&"dunes", 9)
	assert_eq(step_of(Q), &"s", "une vague ne compte pas pour un score")
	EventBus.arena_finished.emit(&"dunes", 310, true)
	assert_eq(step_of(Q), &"end", "score final")


func test_flag_step() -> void:
	_make(
		[
			_step("f", "flag", {"flag": "door_open"}),
			_step("g", "flag", {"flag": "seen"}),
			_flag_end()
		]
	)
	GameState.set_flag(&"other")
	assert_eq(step_of(Q), &"f")
	GameState.set_flag(&"door_open")
	assert_eq(step_of(Q), &"g")
	GameState.set_flag(&"the_end")
	GameState.set_flag(&"seen")
	assert_eq(GameState.quest_state(Q), &"done", "drapeau déjà posé : validée tout de suite")


# --- Fin, récompenses, fin forcée ----------------------------------------------------------------


func test_last_step_completes_the_quest_with_rewards() -> void:
	watch_signals(EventBus)
	watch_signals(tracker)
	_make(
		[
			_step(
				"a",
				"reach",
				{"zone": "beach", "rewards": {"items": {"shell": 1}, "flags": ["half"]}}
			),
			_step("b", "reach", {"zone": "hill"}),
		],
		{"rewards": {"items": {"bookmark": 1}, "flags": ["all"], "max_hp": 7}}
	)
	enter_zone(&"beach")
	assert_eq(GameState.count(&"shell"), 1, "récompense d'étape")
	assert_true(GameState.has_flag(&"half"))
	assert_eq(GameState.count(&"bookmark"), 0, "pas encore celle de la quête")
	enter_zone(&"hill")
	assert_eq(GameState.quest_state(Q), &"done")
	assert_eq(GameState.count(&"bookmark"), 1)
	assert_true(GameState.has_flag(&"all"))
	assert_eq(GameState.max_hp, 7)
	assert_eq(step_of(Q), &"", "avancement effacé")
	assert_signal_emitted_with_parameters(EventBus, "quest_step_completed", [Q, &"b"])
	assert_signal_emitted_with_parameters(EventBus, "quest_updated", [Q, &"done"])
	assert_signal_emitted_with_parameters(tracker, "quest_completed", [Q])
	assert_eq(GameState.tracked_quest, &"", "plus de quête active")


func test_forced_completion_validates_the_remaining_steps() -> void:
	watch_signals(EventBus)
	_make(
		[
			_step("talk", "talk", {"npc": "child"}),
			_step("give", "collect", {"item": "shell", "count": 2, "consume": true}),
		],
		{"rewards": {"items": {"bookmark": 1}}}
	)
	GameState.add_item(&"shell", 2)
	assert_eq(step_of(Q), &"talk", "les coquillages sont pour l'étape suivante")
	GameState.set_quest_state(Q, &"done")
	assert_eq(GameState.quest_state(Q), &"done")
	assert_eq(GameState.count(&"shell"), 0, "objets des étapes collect restantes retirés")
	assert_eq(GameState.count(&"bookmark"), 1)
	assert_signal_emit_count(EventBus, "quest_step_completed", 2, "les deux étapes restantes")
	assert_signal_emitted_with_parameters(EventBus, "quest_step_completed", [Q, &"talk"], 0)
	assert_signal_emitted_with_parameters(EventBus, "quest_step_completed", [Q, &"give"], 1)


func test_forced_completion_is_refused_without_the_items() -> void:
	watch_signals(tracker)
	_make(
		[
			_step("talk", "talk", {"npc": "child"}),
			_step("give", "collect", {"item": "shell", "count": 3, "npc": "child"}),
		]
	)
	chat(&"child")
	GameState.add_item(&"shell", 1)
	GameState.set_quest_state(Q, &"done")
	assert_push_warning("n'est pas terminée")
	assert_eq(GameState.quest_state(Q), &"active", "remise à active")
	assert_eq(step_of(Q), &"give", "à la même étape")
	assert_signal_emitted_with_parameters(tracker, "completion_refused", [Q, {&"shell": 2}])
	assert_signal_not_emitted(tracker, "quest_completed")


# --- Prérequis, enchaînement, quête suivie --------------------------------------------------------


func test_a_finished_quest_makes_the_next_one_available() -> void:
	_make([_step("a", "reach", {"zone": "beach"})])
	write_quest(
		{
			"id": "next",
			"title": "Suite",
			"giver": "child",
			"requires": {"quests": ["q"], "flags": ["ready"]},
			"steps": [_step("b", "talk", {"npc": "child"})],
		}
	)
	assert_eq(QuestData.state_of(&"next"), &"")
	enter_zone(&"beach")
	assert_eq(QuestData.state_of(&"next"), &"", "il manque le drapeau")
	GameState.set_flag(&"ready")
	assert_eq(QuestData.state_of(&"next"), &"available", "disponible")
	assert_eq(GameState.quest_state(&"next"), &"", "jamais écrit dans GameState")
	assert_eq(QuestData.npc_marker(&"child"), QuestData.MARKER_AVAILABLE)


func test_auto_start_chains_acts() -> void:
	_make([_step("a", "reach", {"zone": "beach"})], {"main": true})
	write_quest(
		{
			"id": "act2",
			"title": "Acte 2",
			"main": true,
			"auto_start": true,
			"requires": {"quests": ["q"]},
			"steps": [_step("b", "reach", {"zone": "hill"})],
		}
	)
	assert_eq(GameState.quest_state(&"act2"), &"")
	enter_zone(&"beach")
	assert_eq(GameState.quest_state(Q), &"done")
	assert_eq(GameState.quest_state(&"act2"), &"active", "démarre toute seule")
	assert_eq(step_of(&"act2"), &"b")
	assert_eq(GameState.tracked_quest, &"act2", "et devient la quête suivie")


func test_auto_start_quest_starts_when_a_game_is_loaded() -> void:
	write_quest({"id": "intro", "title": "Intro", "auto_start": true, "steps": [_flag_end()]})
	EventBus.game_loaded.emit()
	assert_eq(GameState.quest_state(&"intro"), &"active")
	assert_eq(GameState.tracked_quest, &"intro")


func test_tracked_quest_follows_starts_and_ends() -> void:
	write_quest({"id": "a", "title": "A", "steps": [_step("x", "reach", {"zone": "beach"})]})
	write_quest({"id": "b", "title": "B", "steps": [_step("y", "reach", {"zone": "hill"})]})
	start_quest(&"a")
	start_quest(&"b")
	assert_eq(GameState.tracked_quest, &"b", "la dernière commencée")
	enter_zone(&"hill")
	assert_eq(GameState.tracked_quest, &"a", "b terminée : la suivante active")
	GameState.set_quest_state(&"a", &"")
	assert_eq(GameState.tracked_quest, &"", "oubliée : plus rien à suivre")
	assert_eq(step_of(&"a"), &"", "son avancement est effacé")


func test_loaded_game_resumes_at_the_saved_step() -> void:
	write_quest(
		{
			"id": "q",
			"title": "Q",
			"steps":
			[_step("a", "talk", {"npc": "child"}), _step("b", "kill", {"count": 3}), _flag_end()],
		}
	)
	(
		GameState
		. from_dict(
			{
				"quests": {"q": "active", "pages": "active"},
				"quest_progress": {"q": {"step": "b", "count": 2}, "pages": {"step": "fantome"}},
				"tracked_quest": "q",
			}
		)
	)
	EventBus.game_loaded.emit()
	assert_eq(step_of(Q), &"b", "étape sauvegardée")
	assert_eq(count_of(Q), 2, "compteur sauvegardé")
	assert_eq(step_of(&"pages"), &"deliver", "étape disparue des données : la première")
	kill(&"timere_small")
	assert_eq(step_of(Q), &"end", "troisième ennemi")


func test_only_the_first_tracker_acts() -> void:
	var second: QuestTracker = add_child_autofree(QuestTracker.new())
	assert_false(second.is_leader())
	assert_true(tracker.is_leader())
	_make([_step("k", "kill", {"count": 5}), _flag_end()])
	kill(&"timere_small")
	assert_eq(count_of(Q), 1, "compté une seule fois")
