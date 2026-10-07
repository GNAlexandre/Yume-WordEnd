extends "res://tests/stubs/q_quest_test.gd"
## Lot Q, dialogues et quêtes (DialogueRunner) : conditions quest_step et quest « available »,
## effets advance_quest, give_item, take_item, clear_flag ; ordre d'application des effets ; texte
## et choix calculés après les effets du nœud ; clés et effets vérifiés à la lecture ; dialogues
## du jeu toujours valides.

const DIR := "user://test_quest_dialogue"

## Événements reçus pendant test_effects_apply_in_the_documented_order.
var _log: Array[String] = []


func before_each() -> void:
	super()
	DirAccess.make_dir_recursive_absolute(DIR)


func after_each() -> void:
	for file_name: String in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(file_name))
	super()


## PNJ child dont le dialogue est dialogue (écrit dans user://).
func _npc_with(dialogue: Dictionary) -> NpcData:
	var path := DIR.path_join("dialogue.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(dialogue))
	file.close()
	var data := NpcData.new()
	data.id = &"child"
	data.display_name = "Enfant"
	data.dialogue_path = path
	return data


func _quest_two_steps() -> void:
	write_quest(
		{
			"id": "q",
			"title": "Q",
			"giver": "child",
			"steps":
			[
				{"id": "a", "type": "talk", "npc": "blacksmith", "objective": "A"},
				{"id": "b", "type": "flag", "flag": "b_done", "objective": "B"},
			],
		}
	)


func test_quest_step_condition() -> void:
	_quest_two_steps()
	var at_a := {"quest_step": ["q", "a"]}
	var at_b := {"quest_step": ["q", "b"]}
	assert_false(DialogueRunner.evaluate(at_a), "pas commencée")
	start_quest(&"q")
	assert_true(DialogueRunner.evaluate(at_a))
	assert_false(DialogueRunner.evaluate(at_b))
	chat(&"blacksmith")
	assert_true(DialogueRunner.evaluate(at_b), "étape suivante")
	GameState.set_flag(&"b_done")
	assert_false(DialogueRunner.evaluate(at_b), "terminée : plus d'étape")
	assert_false(DialogueRunner.evaluate({"quest_step": ["q", 2]}))
	assert_push_warning("attend [identifiant, valeur]")


func test_quest_available_condition_follows_prerequisites() -> void:
	write_quest(
		{
			"id": "q",
			"title": "Q",
			"requires": {"flags": ["met"]},
			"steps": [{"id": "a", "type": "flag", "flag": "x", "objective": "A"}],
		}
	)
	var available := {"quest": ["q", "available"]}
	var never_started := {"quest": ["q", ""]}
	assert_false(DialogueRunner.evaluate(available), "verrouillée")
	assert_true(DialogueRunner.evaluate(never_started), '"" : jamais commencée')
	GameState.set_flag(&"met")
	assert_true(DialogueRunner.evaluate(available), "prérequis remplis")
	assert_true(DialogueRunner.evaluate(never_started))
	start_quest(&"q")
	assert_false(DialogueRunner.evaluate(available))
	assert_false(DialogueRunner.evaluate(never_started))
	assert_true(DialogueRunner.evaluate({"quest": ["q", "active"]}))


func test_give_and_take_item_effects() -> void:
	DialogueRunner.apply_effects({"give_item": "shell"})
	assert_eq(GameState.count(&"shell"), 1, "un nom : 1 exemplaire")
	DialogueRunner.apply_effects({"give_item": ["shell", 3]})
	assert_eq(GameState.count(&"shell"), 4, "[objet, quantité]")
	DialogueRunner.apply_effects({"give_item": {"shell": 1, "flower_blue": 2.0}})
	assert_eq(GameState.items(), {&"shell": 5, &"flower_blue": 2}, "{objet: quantité}")
	DialogueRunner.apply_effects({"take_item": {"shell": 2, "flower_blue": 1}})
	assert_eq(GameState.items(), {&"shell": 3, &"flower_blue": 1})
	DialogueRunner.apply_effects({"take_item": {"shell": 1, "flower_blue": 2}})
	assert_push_warning("rien n'est retiré")
	assert_eq(GameState.items(), {&"shell": 3, &"flower_blue": 1}, "tout ou rien")


func test_set_and_clear_flag_effects() -> void:
	DialogueRunner.apply_effects({"set_flag": ["a", "b"]})
	assert_true(GameState.has_flag(&"a") and GameState.has_flag(&"b"))
	watch_signals(EventBus)
	DialogueRunner.apply_effects({"clear_flag": "a"})
	assert_false(GameState.has_flag(&"a"))
	assert_true(GameState.has_flag(&"b"))
	assert_signal_emitted_with_parameters(EventBus, "flag_changed", [&"a", false])


func test_advance_quest_effect() -> void:
	_quest_two_steps()
	start_quest(&"q")
	watch_signals(EventBus)
	DialogueRunner.apply_effects({"advance_quest": ["q", "b"]})
	assert_signal_emitted_with_parameters(EventBus, "quest_advance_requested", [&"q", &"b"])
	assert_eq(step_of(&"q"), &"a", "garde [quête, étape] : pas l'étape courante")
	DialogueRunner.apply_effects({"advance_quest": "q"})
	assert_eq(step_of(&"q"), &"b", "étape courante validée")
	DialogueRunner.apply_effects({"advance_quest": ["q", "b"]})
	assert_eq(GameState.quest_state(&"q"), &"done")


func _log_inventory() -> void:
	_log.append("inventaire")


func _log_flag(flag: StringName, _value: bool) -> void:
	_log.append(String(flag))


func _log_quest(quest_id: StringName, state: StringName) -> void:
	_log.append("%s:%s" % [quest_id, state])


func _log_advance(_quest_id: StringName, _step_id: StringName) -> void:
	_log.append("avance")


func test_effects_apply_in_the_documented_order() -> void:
	_quest_two_steps()
	GameState.add_item(&"page_fragment", 1)
	_log.clear()
	EventBus.inventory_changed.connect(_log_inventory)
	EventBus.flag_changed.connect(_log_flag)
	EventBus.quest_updated.connect(_log_quest)
	EventBus.quest_advance_requested.connect(_log_advance)
	# Clés écrites à l'envers : l'ordre d'application ne dépend pas de l'ordre d'écriture.
	(
		DialogueRunner
		. apply_effects(
			{
				"complete_quest": "q",
				"advance_quest": "q",
				"start_quest": "q",
				"clear_flag": "old",
				"set_flag": "new",
				"give_item": "shell",
				"take_item": "page_fragment",
			}
		)
	)
	EventBus.inventory_changed.disconnect(_log_inventory)
	EventBus.flag_changed.disconnect(_log_flag)
	EventBus.quest_updated.disconnect(_log_quest)
	EventBus.quest_advance_requested.disconnect(_log_advance)
	assert_eq(_log.slice(0, 2), ["inventaire", "inventaire"] as Array[String], "take puis give")
	assert_eq(_log.slice(2, 3), ["new"] as Array[String], "set_flag (clear_flag : rien à retirer)")
	assert_eq(_log[3], "q:active", "start_quest")
	assert_gt(_log.find("avance"), 3, "puis advance_quest")
	assert_eq(_log[_log.size() - 1], "q:done", "complete_quest en dernier")
	assert_eq(GameState.quest_state(&"q"), &"done")


func test_node_text_and_choices_follow_its_own_effects() -> void:
	var npc_data := _npc_with(
		{
			"start": "a",
			"nodes":
			{
				"a":
				{
					"text": "Tu as {count:shell} coquillage.",
					"give_item": "shell",
					"choices":
					[
						{"text": "Merci !", "if": {"count": ["shell", 1]}, "next": null},
						{"text": "Rien.", "if": {"count": ["shell", 2]}, "next": null},
					],
				},
			},
		}
	)
	dialogue_runner.start(npc_data)
	assert_eq(dialogue_lines, ["Tu as 1 coquillage."] as Array[String], "texte après give_item")
	EventBus.dialogue_choice_made.emit(0)
	assert_false(dialogue_runner.is_running(), "un seul choix proposé (index 0)")


func test_dialogue_quest_flow_with_conditions_and_effects() -> void:
	_quest_two_steps()
	var npc_data := _npc_with(
		{
			"start": "hello",
			"entries": ["thanks", "step_b", "offer"],
			"nodes":
			{
				"hello": {"text": "Bonjour.", "next": null},
				"offer":
				{
					"if": {"quest": ["q", "available"]},
					"text": "Une quête ?",
					"choices": [{"text": "Oui", "start_quest": "q", "next": null}],
				},
				"step_b":
				{
					"if": {"quest_step": ["q", "b"]},
					"text": "Merci d'avoir vu le forgeron.",
					"set_flag": "b_done",
					"give_item": ["shell", 2],
					"next": null,
				},
				"thanks": {"if": {"quest": ["q", "done"]}, "text": "Encore merci.", "next": null},
			},
		}
	)
	assert_eq(talk(npc_data, [0])[0], "Une quête ?")
	assert_eq(step_of(&"q"), &"a")
	assert_eq(talk(npc_data)[0], "Bonjour.", "étape a : rien de spécial")
	chat(&"blacksmith")
	assert_eq(talk(npc_data, [-1])[0], "Merci d'avoir vu le forgeron.")
	assert_eq(GameState.quest_state(&"q"), &"done", "set_flag valide l'étape flag")
	assert_eq(GameState.count(&"shell"), 2)
	assert_eq(talk(npc_data)[0], "Encore merci.")


func test_validation_rejects_unknown_keys_and_malformed_effects() -> void:
	var cases := {
		"clé inconnue « strat_quest » dans le nœud « a »": {"a": {"strat_quest": "q"}},
		"clé inconnue « speaker » dans le choix": {"a": {"choices": [{"speaker": "x"}]}},
		"« give_item » attend un objet": {"a": {"give_item": ["shell", 0]}},
		"« take_item » attend un objet": {"a": {"take_item": {"shell": "deux"}}},
		"« advance_quest » attend un id": {"a": {"advance_quest": ["q", "b", "c"]}},
		"« start_quest » attend un id de quête": {"a": {"start_quest": 3}},
		"« clear_flag » attend un nom": {"a": {"clear_flag": []}},
		"condition inconnue « quest_stage »": {"a": {"if": {"quest_stage": ["q", "a"]}}},
	}
	for expected: String in cases:
		var problem := DialogueRunner.validate({"start": "a", "nodes": cases[expected]})
		assert_string_contains(problem, expected, false)
	var commented := {"start": "a", "nodes": {"a": {"_note": "commentaire", "text": "A."}}}
	assert_eq(DialogueRunner.validate(commented), "", "clés « _… » : commentaires")


func test_game_and_example_dialogues_are_valid() -> void:
	for dir: String in ["res://data/dialogues", "res://tests/data/dialogues"]:
		for file_name: String in DirAccess.get_files_at(dir):
			if file_name.ends_with(".json"):
				var dialogue := DialogueRunner.load_dialogue(dir.path_join(file_name))
				assert_false(dialogue.is_empty(), "%s valide" % file_name)
