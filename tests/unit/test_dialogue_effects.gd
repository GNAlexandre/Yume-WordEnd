extends GutTest
## Effets des dialogues (DialogueRunner, docs/DIALOGUES.md), repris des tests de quêtes du Lot Q
## quand les quêtes sont parties avec l'ancienne île (F1) : give_item, take_item (tout ou rien),
## set_flag et clear_flag ; ordre d'application des effets ; texte et choix calculés après les
## effets du nœud ; clés et effets vérifiés à la lecture (les effets de quête sont inconnus) ;
## dialogues de l'île n° 68 toujours valides.

const DIR := "user://test_dialogue_effects"

## Événements reçus pendant test_effects_apply_in_the_documented_order.
var _log: Array[String] = []
var _lines: Array[String] = []
var _runner: DialogueRunner


func before_each() -> void:
	GameState.reset()
	DirAccess.make_dir_recursive_absolute(DIR)
	_log.clear()
	_lines.clear()
	_runner = add_child_autofree(DialogueRunner.new())
	EventBus.dialogue_line.connect(_on_line)


func after_each() -> void:
	if is_instance_valid(_runner):
		_runner.stop()
	EventBus.dialogue_line.disconnect(_on_line)
	for file_name: String in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(file_name))
	GameState.reset()


func _on_line(_speaker: String, text: String, _choices: Array[String]) -> void:
	_lines.append(text)


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


func _log_inventory() -> void:
	_log.append("inventaire")


func _log_flag(flag: StringName, value: bool) -> void:
	_log.append("%s:%s" % [flag, value])


func test_effects_apply_in_the_documented_order() -> void:
	GameState.add_item(&"page_fragment", 1)
	GameState.set_flag(&"old")
	_log.clear()
	EventBus.inventory_changed.connect(_log_inventory)
	EventBus.flag_changed.connect(_log_flag)
	# Clés écrites à l'envers : l'ordre d'application ne dépend pas de l'ordre d'écriture.
	(
		DialogueRunner
		. apply_effects(
			{
				"clear_flag": "old",
				"set_flag": "new",
				"give_item": "shell",
				"take_item": "page_fragment",
			}
		)
	)
	EventBus.inventory_changed.disconnect(_log_inventory)
	EventBus.flag_changed.disconnect(_log_flag)
	assert_eq(
		_log,
		["inventaire", "inventaire", "new:true", "old:false"] as Array[String],
		"take_item, give_item, set_flag puis clear_flag"
	)


func test_node_text_and_choices_follow_its_own_effects() -> void:
	var npc_data := _npc_with(
		{
			"start": "a",
			"nodes":
			{
				"a":
				{
					"text": "Tu as {count:shell} exemplaire.",
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
	_runner.start(npc_data)
	assert_eq(_lines, ["Tu as 1 exemplaire."] as Array[String], "texte après give_item")
	EventBus.dialogue_choice_made.emit(0)
	assert_false(_runner.is_running(), "un seul choix proposé (index 0)")


func test_validation_rejects_unknown_keys_and_malformed_effects() -> void:
	var cases := {
		"clé inconnue « strat_quest » dans le nœud « a »": {"a": {"strat_quest": "q"}},
		"clé inconnue « speaker » dans le choix": {"a": {"choices": [{"speaker": "x"}]}},
		"« give_item » attend un objet": {"a": {"give_item": ["shell", 0]}},
		"« take_item » attend un objet": {"a": {"take_item": {"shell": "deux"}}},
		"« clear_flag » attend un nom": {"a": {"clear_flag": []}},
		"condition inconnue « quest_stage »": {"a": {"if": {"quest_stage": ["q", "a"]}}},
		# (F1) Les effets de quête sont partis avec l'ancienne île.
		"clé inconnue « start_quest » dans le nœud « a »": {"a": {"start_quest": "q"}},
		"clé inconnue « advance_quest » dans le nœud « a »": {"a": {"advance_quest": "q"}},
		"clé inconnue « complete_quest » dans le choix":
		{"a": {"choices": [{"text": "x", "complete_quest": "q"}]}},
	}
	for expected: String in cases:
		var problem := DialogueRunner.validate({"start": "a", "nodes": cases[expected]})
		assert_string_contains(problem, expected, false)
	var commented := {"start": "a", "nodes": {"a": {"_note": "commentaire", "text": "A."}}}
	assert_eq(DialogueRunner.validate(commented), "", "clés « _… » : commentaires")


func test_game_and_example_dialogues_are_valid() -> void:
	var count := 0
	for dir: String in ["res://data/dialogues/ile_68", "res://data/dialogues/ile_68/talk"]:
		for file_name: String in DirAccess.get_files_at(dir):
			if file_name.ends_with(".json"):
				var dialogue := DialogueRunner.load_dialogue(dir.path_join(file_name))
				assert_false(dialogue.is_empty(), "%s valide" % file_name)
				count += 1
	assert_gt(count, 10, "les dialogues de l'île n° 68 sont lus")
	assert_true(
		DirAccess.get_files_at("res://data/dialogues").is_empty(),
		"(F1) plus aucun dialogue de quête de l'ancienne île à la racine de data/dialogues"
	)
