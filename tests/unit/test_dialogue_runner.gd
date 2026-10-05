extends GutTest
## Lot 6 : DialogueRunner (PLAN.md section 4, « Format de dialogue ») — conditions, choix du
## nœud d'entrée, choix et effets, enchaînement "next", signaux dans l'ordre, fichiers invalides.
## Les dialogues de test sont écrits dans user:// (aucun JSON invalide dans le dépôt).

const DIR := "user://test_dialogue_runner"

var _runner: DialogueRunner
var _log: Array = []
var _lines: Array[Dictionary] = []


func before_each() -> void:
	GameState.reset()
	DirAccess.make_dir_recursive_absolute(DIR)
	_log.clear()
	_lines.clear()
	EventBus.dialogue_started.connect(_on_started)
	EventBus.dialogue_line.connect(_on_line)
	EventBus.dialogue_ended.connect(_on_ended)
	_runner = add_child_autofree(DialogueRunner.new())


func after_each() -> void:
	if is_instance_valid(_runner):
		_runner.stop()
	EventBus.dialogue_started.disconnect(_on_started)
	EventBus.dialogue_line.disconnect(_on_line)
	EventBus.dialogue_ended.disconnect(_on_ended)
	for file_name: String in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(file_name))


func after_all() -> void:
	GameState.reset()


# --- Outils -----------------------------------------------------------------------------------


func _on_started(npc_id: StringName) -> void:
	_log.append("started:%s" % npc_id)


func _on_line(speaker: String, text: String, choices: Array) -> void:
	_log.append("line:%s" % text)
	var plain: Array = []
	plain.assign(choices)
	_lines.append({"speaker": speaker, "text": text, "choices": plain})


func _on_ended(npc_id: StringName) -> void:
	_log.append("ended:%s" % npc_id)


func _write_text(text: String, file_name: String = "dialogue.json") -> String:
	var path := DIR.path_join(file_name)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()
	return path


func _write(dialogue: Dictionary, file_name: String = "dialogue.json") -> String:
	return _write_text(JSON.stringify(dialogue, "  "), file_name)


func _npc(path: String, id: StringName = &"tester") -> NpcData:
	var npc := NpcData.new()
	npc.id = id
	npc.display_name = "Testeur"
	npc.dialogue_path = path
	return npc


func _start(dialogue: Dictionary) -> void:
	_runner.start(_npc(_write(dialogue)))


## Dialogue d'exemple de PLAN.md section 4 (hello → ask → choix ; done si 5 pages).
func _example() -> Dictionary:
	return {
		"id": "example",
		"start": "hello",
		"nodes":
		{
			"hello":
			{
				"speaker": "Bibliothécaire",
				"text": "Les Timeres ont emporté des pages…",
				"next": "ask"
			},
			"ask":
			{
				"speaker": "Bibliothécaire",
				"text": "Peux-tu m'en rapporter cinq ?",
				"choices":
				[
					{
						"text": "Je m'en occupe.",
						"set_flag": "quest_pages_accepted",
						"start_quest": "pages",
						"next": null
					},
					{"text": "Plus tard.", "next": null},
				],
			},
			"done":
			{
				"if": {"count": ["page_fragment", 5]},
				"speaker": "Bibliothécaire",
				"text": "Merci ! Tiens, un marque-page.",
				"complete_quest": "pages",
				"next": null,
			},
		},
	}


# --- Conditions -------------------------------------------------------------------------------


func test_missing_or_empty_condition_is_true() -> void:
	assert_true(DialogueRunner.evaluate(null))
	assert_true(DialogueRunner.evaluate({}))


func test_flag_condition() -> void:
	assert_false(DialogueRunner.evaluate({"flag": "met"}), "drapeau absent")
	GameState.set_flag(&"met")
	assert_true(DialogueRunner.evaluate({"flag": "met"}), "drapeau présent")
	assert_false(DialogueRunner.evaluate({"flag": ["met", "other"]}), "liste : tous requis")
	GameState.set_flag(&"other")
	assert_true(DialogueRunner.evaluate({"flag": ["met", "other"]}))
	GameState.set_flag(&"met", false)
	assert_false(DialogueRunner.evaluate({"flag": "met"}), "drapeau remis à faux")


func test_not_flag_condition() -> void:
	assert_true(DialogueRunner.evaluate({"not_flag": "met"}), "drapeau absent")
	GameState.set_flag(&"met")
	assert_false(DialogueRunner.evaluate({"not_flag": "met"}), "drapeau présent")
	assert_true(DialogueRunner.evaluate({"not_flag": ["a", "b"]}))
	assert_false(DialogueRunner.evaluate({"not_flag": ["a", "met"]}), "liste : aucun présent")


func test_count_condition() -> void:
	var condition := {"count": ["page_fragment", 5]}
	assert_false(DialogueRunner.evaluate(condition), "aucune page")
	GameState.add_item(&"page_fragment", 4)
	assert_false(DialogueRunner.evaluate(condition), "4 pages")
	GameState.add_item(&"page_fragment")
	assert_true(DialogueRunner.evaluate(condition), "5 pages")
	GameState.add_item(&"page_fragment")
	assert_true(DialogueRunner.evaluate(condition), "6 pages")
	assert_true(DialogueRunner.evaluate({"count": ["page_fragment", 6.0]}), "nombre JSON (float)")


func test_quest_condition() -> void:
	assert_false(DialogueRunner.evaluate({"quest": ["pages", "active"]}), "quête inconnue")
	assert_true(DialogueRunner.evaluate({"quest": ["pages", ""]}), "état vide = inconnue")
	GameState.set_quest_state(&"pages", &"active")
	assert_true(DialogueRunner.evaluate({"quest": ["pages", "active"]}))
	assert_false(DialogueRunner.evaluate({"quest": ["pages", "done"]}))
	GameState.set_quest_state(&"pages", &"done")
	assert_false(DialogueRunner.evaluate({"quest": ["pages", "active"]}))
	assert_true(DialogueRunner.evaluate({"quest": ["pages", "done"]}))


func test_best_score_condition() -> void:
	var condition := {"best_score": ["dunes", 300]}
	assert_false(DialogueRunner.evaluate(condition), "jamais joué")
	GameState.record_score(&"dunes", 299, 4)
	assert_false(DialogueRunner.evaluate(condition), "299")
	GameState.record_score(&"dunes", 300, 5)
	assert_true(DialogueRunner.evaluate(condition), "300")
	assert_false(DialogueRunner.evaluate({"best_score": ["forest", 1]}), "autre arène")


func test_combined_conditions_must_all_hold() -> void:
	var condition := {
		"flag": "met",
		"not_flag": "angry",
		"count": ["page_fragment", 2],
		"quest": ["pages", "active"],
		"best_score": ["dunes", 10],
	}
	GameState.set_flag(&"met")
	GameState.add_item(&"page_fragment", 2)
	GameState.set_quest_state(&"pages", &"active")
	assert_false(DialogueRunner.evaluate(condition), "score manquant")
	GameState.record_score(&"dunes", 10, 1)
	assert_true(DialogueRunner.evaluate(condition), "toutes vraies")
	GameState.set_flag(&"angry")
	assert_false(DialogueRunner.evaluate(condition), "not_flag faux")
	GameState.set_flag(&"angry", false)
	GameState.remove_item(&"page_fragment")
	assert_false(DialogueRunner.evaluate(condition), "count faux")


func test_malformed_conditions_are_false_with_warning() -> void:
	assert_false(DialogueRunner.evaluate({"flg": "met"}))
	assert_push_warning("condition inconnue")
	assert_false(DialogueRunner.evaluate({"count": "page_fragment"}))
	assert_push_warning("attend [identifiant, valeur]")
	assert_false(DialogueRunner.evaluate({"best_score": ["dunes", "beaucoup"]}))
	assert_push_warning("attend [identifiant, valeur]")
	assert_false(DialogueRunner.evaluate({"flag": 3}))
	assert_push_warning("drapeau invalide")
	assert_false(DialogueRunner.evaluate("met"))
	assert_push_warning("objet attendu")


# --- Nœud d'entrée ----------------------------------------------------------------------------


func test_entry_is_done_when_its_condition_holds_else_start() -> void:
	var dialogue := _example()
	assert_eq(DialogueRunner.pick_entry(dialogue), "hello", "4 pages ou moins : start")
	GameState.add_item(&"page_fragment", 5)
	assert_eq(DialogueRunner.pick_entry(dialogue), "done", "5 pages : done")


func test_entries_are_tried_in_order_between_done_and_start() -> void:
	var dialogue := {
		"start": "hello",
		"entries": ["thanks", "progress"],
		"nodes":
		{
			"hello": {"text": "Bonjour."},
			"progress": {"if": {"quest": ["pages", "active"]}, "text": "En cours."},
			"thanks": {"if": {"quest": ["pages", "done"]}, "text": "Merci."},
			"done":
			{"if": {"quest": ["pages", "active"], "count": ["page", 5]}, "text": "Terminé."},
		},
	}
	assert_eq(DialogueRunner.pick_entry(dialogue), "hello")
	GameState.set_quest_state(&"pages", &"active")
	assert_eq(DialogueRunner.pick_entry(dialogue), "progress")
	GameState.add_item(&"page", 5)
	assert_eq(DialogueRunner.pick_entry(dialogue), "done", "done passe avant entries")
	GameState.set_quest_state(&"pages", &"done")
	assert_eq(DialogueRunner.pick_entry(dialogue), "thanks")


func test_no_true_entry_warns_and_does_not_start() -> void:
	_start({"start": "hello", "nodes": {"hello": {"if": {"flag": "never"}, "text": "…"}}})
	assert_push_warning("aucun nœud d'entrée")
	assert_false(_runner.is_running())
	assert_eq(_log, [], "aucun signal")


# --- Déroulement ------------------------------------------------------------------------------


func test_start_emits_started_then_first_line() -> void:
	_start(_example())
	assert_true(_runner.is_running())
	assert_true(DialogueRunner.is_any_running())
	assert_eq(_log, ["started:tester", "line:Les Timeres ont emporté des pages…"])
	assert_eq(_lines[0]["speaker"], "Bibliothécaire")
	assert_eq(_lines[0]["choices"], [], "pas de choix : « suite »")


func test_speaker_defaults_to_npc_display_name() -> void:
	_start({"start": "a", "nodes": {"a": {"text": "Salut."}}})
	assert_eq(_lines[0]["speaker"], "Testeur")


func test_next_chains_nodes_then_ends_in_order() -> void:
	_start(
		{
			"start": "one",
			"nodes":
			{
				"one": {"text": "Un.", "next": "two"},
				"two": {"text": "Deux.", "next": "three"},
				"three": {"text": "Trois.", "next": null},
			},
		}
	)
	EventBus.dialogue_choice_made.emit(-1)
	EventBus.dialogue_choice_made.emit(-1)
	assert_true(_runner.is_running(), "toujours en cours sur le dernier nœud")
	EventBus.dialogue_choice_made.emit(-1)
	assert_eq(_log, ["started:tester", "line:Un.", "line:Deux.", "line:Trois.", "ended:tester"])
	assert_false(_runner.is_running())
	assert_false(DialogueRunner.is_any_running())


func test_missing_next_or_empty_next_ends() -> void:
	_start({"start": "a", "nodes": {"a": {"text": "A.", "next": ""}}})
	EventBus.dialogue_choice_made.emit(-1)
	assert_eq(_log.back(), "ended:tester")


func test_choice_effects_and_next() -> void:
	var dialogue := _example()
	dialogue["nodes"]["ask"]["choices"][0]["next"] = "after"
	dialogue["nodes"]["after"] = {"text": "Merci de ton aide."}
	_start(dialogue)
	EventBus.dialogue_choice_made.emit(-1)
	assert_eq(_lines[1]["choices"], ["Je m'en occupe.", "Plus tard."])
	assert_false(GameState.has_flag(&"quest_pages_accepted"), "rien avant le choix")
	EventBus.dialogue_choice_made.emit(0)
	assert_true(GameState.has_flag(&"quest_pages_accepted"), "set_flag")
	assert_eq(GameState.quest_state(&"pages"), &"active", "start_quest")
	assert_eq(_log.back(), "line:Merci de ton aide.", "next du choix")
	EventBus.dialogue_choice_made.emit(-1)
	assert_eq(_log.back(), "ended:tester")


func test_other_choice_has_no_effect() -> void:
	_start(_example())
	EventBus.dialogue_choice_made.emit(-1)
	EventBus.dialogue_choice_made.emit(1)
	assert_false(GameState.has_flag(&"quest_pages_accepted"))
	assert_eq(GameState.quest_state(&"pages"), &"")
	assert_eq(_log.back(), "ended:tester", "next null : fin")


func test_node_effects_apply_when_shown() -> void:
	watch_signals(EventBus)
	GameState.set_quest_state(&"pages", &"active")
	GameState.add_item(&"page_fragment", 5)
	_start(_example())
	assert_eq(_lines[0]["text"], "Merci ! Tiens, un marque-page.")
	assert_eq(GameState.quest_state(&"pages"), &"done", "complete_quest")
	assert_signal_emitted_with_parameters(EventBus, "quest_updated", [&"pages", &"done"])


func test_set_flag_accepts_a_list() -> void:
	_start({"start": "a", "nodes": {"a": {"text": "A.", "set_flag": ["one", "two"]}}})
	assert_true(GameState.has_flag(&"one") and GameState.has_flag(&"two"))


func test_out_of_range_choice_is_ignored() -> void:
	_start(_example())
	EventBus.dialogue_choice_made.emit(-1)
	EventBus.dialogue_choice_made.emit(2)
	assert_push_warning("hors limites")
	EventBus.dialogue_choice_made.emit(-1)
	assert_push_warning("hors limites")
	assert_true(_runner.is_running(), "toujours sur la question")
	assert_eq(_lines.size(), 2)
	EventBus.dialogue_choice_made.emit(0)
	assert_false(_runner.is_running())


func test_conditional_choices_and_choice_limit() -> void:
	_start(
		{
			"start": "q",
			"nodes":
			{
				"q":
				{
					"text": "Alors ?",
					"choices":
					[
						{"text": "Secret", "if": {"flag": "knows"}, "next": "secret"},
						{"text": "Oui", "next": "yes"},
						{"text": "Non"},
						{"text": "Peut-être"},
					],
				},
				"secret": {"text": "Chut."},
				"yes": {"text": "Super."},
			},
		}
	)
	assert_eq(_lines[0]["choices"], ["Oui", "Non"], "choix au « if » faux masqué, 2 au plus")
	assert_push_warning("plus de 2 choix")
	EventBus.dialogue_choice_made.emit(0)
	assert_eq(_log.back(), "line:Super.", "l'index désigne les choix proposés")


func test_stop_ends_once() -> void:
	_start(_example())
	_runner.stop()
	_runner.stop()
	assert_eq(_log, ["started:tester", "line:Les Timeres ont emporté des pages…", "ended:tester"])
	EventBus.dialogue_choice_made.emit(-1)
	assert_eq(_lines.size(), 1, "un runner arrêté ne réagit plus")


func test_only_one_dialogue_at_a_time() -> void:
	var other: DialogueRunner = add_child_autofree(DialogueRunner.new())
	_start(_example())
	other.start(_npc(_write({"start": "a", "nodes": {"a": {"text": "Autre."}}}, "b.json"), &"b"))
	assert_false(other.is_running(), "refusé pendant un autre dialogue")
	assert_eq(_log.count("started:b"), 0)
	EventBus.dialogue_choice_made.emit(-1)
	assert_eq(_lines[1]["text"], "Peux-tu m'en rapporter cinq ?", "seul le runner actif réagit")


func test_dialogue_stopped_by_an_effect_listener_ends_cleanly() -> void:
	var stopper := func(_quest_id: StringName, _state: StringName) -> void: _runner.stop()
	EventBus.quest_updated.connect(stopper)
	var dialogue := _example()
	dialogue["nodes"]["ask"]["choices"][0]["next"] = "hello"
	_start(dialogue)
	EventBus.dialogue_choice_made.emit(-1)
	EventBus.dialogue_choice_made.emit(0)
	assert_eq(_log.back(), "ended:tester", "arrêté pendant l'effet du choix")
	assert_eq(_log.size(), 4, "pas de réplique après la fin")
	_log.clear()
	GameState.set_quest_state(&"pages", &"active")
	GameState.add_item(&"page_fragment", 5)
	_start(dialogue)
	assert_eq(_log, ["started:tester", "ended:tester"], "arrêté pendant l'effet du nœud")
	EventBus.quest_updated.disconnect(stopper)


func test_runner_leaving_tree_ends_dialogue() -> void:
	_start(_example())
	remove_child(_runner)
	assert_eq(_log.back(), "ended:tester", "le joueur n'est pas bloqué")
	assert_false(DialogueRunner.is_any_running())


func test_text_placeholders() -> void:
	GameState.add_item(&"page_fragment", 2)
	GameState.record_score(&"dunes", 150, 3)
	assert_eq(
		DialogueRunner.format_text("{count:page_fragment}/{left:page_fragment:5}/{best:dunes}"),
		"2/3/150"
	)
	GameState.add_item(&"page_fragment", 9)
	assert_eq(DialogueRunner.format_text("{left:page_fragment:5}"), "0", "jamais négatif")
	assert_eq(DialogueRunner.format_text("Sans accolade."), "Sans accolade.")
	assert_eq(DialogueRunner.format_text("{left:page_fragment}"), "{left:page_fragment}")
	assert_push_warning("{left:objet:total}")
	_start({"start": "a", "nodes": {"a": {"text": "Encore {left:page_fragment:20}."}}})
	assert_eq(_lines[0]["text"], "Encore 9.", "texte émis déjà remplacé")


# --- Fichiers invalides -----------------------------------------------------------------------


func test_invalid_json_warns_and_does_not_start() -> void:
	_runner.start(_npc(_write_text('{\n  "start": "a",\n  "nodes": {\n}')))
	assert_push_warning("JSON invalide")
	assert_false(_runner.is_running())
	assert_eq(_log, [], "aucun signal : le joueur n'est jamais bloqué")


func test_missing_file_or_path_warns() -> void:
	_runner.start(_npc(DIR.path_join("absent.json")))
	assert_push_warning("introuvable")
	_runner.start(_npc(""))
	assert_push_warning("sans dialogue")
	_runner.start(null)
	assert_push_warning("sans NpcData")
	assert_false(_runner.is_running())
	assert_eq(_log, [])


func test_structure_errors_are_explained() -> void:
	var cases := {
		"racine": [],
		"« nodes »": {"start": "a", "nodes": {}},
		"« start »": {"start": "b", "nodes": {"a": {"text": "A."}}},
		"« entries »": {"start": "a", "entries": "a", "nodes": {"a": {}}},
		"ne nomme aucun nœud : b": {"start": "a", "nodes": {"a": {"next": "b"}}},
		"l'entrée": {"start": "a", "entries": ["zz"], "nodes": {"a": {}}},
		"doit être un objet": {"start": "a", "nodes": {"a": "texte"}},
		"« choices »": {"start": "a", "nodes": {"a": {"choices": "oui"}}},
		"condition inconnue « flg »": {"start": "a", "nodes": {"a": {"if": {"flg": "x"}}}},
		"choix du nœud « a »":
		{"start": "a", "nodes": {"a": {"choices": [{"text": "x", "next": "nulle_part"}]}}},
	}
	for expected: String in cases:
		var problem := DialogueRunner.validate(cases[expected])
		assert_string_contains(problem, expected, false)
	assert_eq(DialogueRunner.validate(_example()), "", "l'exemple du plan est valide")


func test_invalid_structure_in_file_warns_and_does_not_start() -> void:
	_start({"start": "a", "nodes": {"a": {"text": "A.", "next": "b"}}})
	assert_push_warning("dialogue invalide")
	assert_false(_runner.is_running())
	assert_eq(_log, [])
