extends GutTest
## Lot 6 : dialogues de data/dialogues/ joués avec les vrais PNJ (data/npcs/) — quête des pages
## de bout en bout, conseils du forgeron, réplique de l'enfant selon le meilleur score des dunes.

const DIALOGUES_DIR := "res://data/dialogues"

var _runner: DialogueRunner
var _texts: Array[String] = []
var _choices: Array = []
var _ended: int = 0


func before_each() -> void:
	GameState.reset()
	_texts.clear()
	_choices.clear()
	_ended = 0
	EventBus.dialogue_line.connect(_on_line)
	EventBus.dialogue_ended.connect(_on_ended)
	_runner = add_child_autofree(DialogueRunner.new())


func after_each() -> void:
	_runner.stop()
	EventBus.dialogue_line.disconnect(_on_line)
	EventBus.dialogue_ended.disconnect(_on_ended)


func after_all() -> void:
	GameState.reset()


func _on_line(_speaker: String, text: String, choices: Array) -> void:
	_texts.append(text)
	var plain: Array = []
	plain.assign(choices)
	_choices.append(plain)


func _on_ended(_npc_id: StringName) -> void:
	_ended += 1


## Lance le dialogue du PNJ puis répond dans l'ordre (-1 = suite) ; renvoie les textes affichés.
## _choices et _ended décrivent ensuite cette conversation seulement.
func _talk(npc_id: StringName, answers: Array[int]) -> Array[String]:
	_runner.stop()
	_texts.clear()
	_choices.clear()
	_ended = 0
	_runner.start(load("res://data/npcs/%s.tres" % npc_id) as NpcData)
	for answer: int in answers:
		EventBus.dialogue_choice_made.emit(answer)
	return _texts.duplicate()


func test_all_dialogue_files_are_valid() -> void:
	var files := ResourceLoader.list_directory(DIALOGUES_DIR)
	for npc_id: String in ["librarian", "blacksmith", "child"]:
		assert_has(files, npc_id + ".json", "data/dialogues/%s.json" % npc_id)
	for file_name: String in files:
		if not file_name.ends_with(".json"):
			continue
		var dialogue := DialogueRunner.load_dialogue(DIALOGUES_DIR.path_join(file_name))
		assert_false(dialogue.is_empty(), "%s valide" % file_name)
		assert_eq(str(dialogue.get("id")), file_name.get_basename(), "id = nom du fichier")
		for node: Variant in (dialogue.get("nodes", {}) as Dictionary).values():
			var text := str((node as Dictionary).get("text", ""))
			assert_lt(text.length(), 160, "%s : réplique courte (%s)" % [file_name, text])
			for choice: Variant in (node as Dictionary).get("choices", []):
				assert_lt(str((choice as Dictionary).get("text")).length(), 32, "choix court")


func test_librarian_offers_the_quest() -> void:
	var texts := _talk(&"librarian", [-1, 0, -1])
	assert_string_contains(texts[0], "Timeres")
	assert_eq(_choices[1], ["Je m’en occupe.", "Plus tard."], "accepter / plus tard")
	assert_true(GameState.has_flag(&"quest_pages_accepted"))
	assert_eq(GameState.quest_state(&"pages"), &"active", "quête démarrée")
	assert_string_contains(texts[2], "forêt")
	assert_eq(_ended, 1)


func test_librarian_later_keeps_quest_available() -> void:
	_talk(&"librarian", [-1, 1, -1])
	assert_eq(GameState.quest_state(&"pages"), &"", "rien ne change")
	assert_false(GameState.has_flag(&"quest_pages_accepted"))
	assert_eq(_ended, 1)
	var texts := _talk(&"librarian", [])
	assert_string_contains(texts[0], "Timeres", "la proposition revient")


func test_librarian_counts_remaining_pages() -> void:
	GameState.set_quest_state(&"pages", &"active")
	assert_string_contains(_talk(&"librarian", [-1])[0], "encore 5 pages")
	GameState.add_item(&"page_fragment", 3)
	assert_string_contains(_talk(&"librarian", [-1])[0], "encore 2 pages")
	GameState.add_item(&"page_fragment")
	assert_string_contains(_talk(&"librarian", [-1])[0], "Plus qu’une seule page")
	assert_eq(GameState.quest_state(&"pages"), &"active")


func test_librarian_completes_quest_then_thanks() -> void:
	watch_signals(EventBus)
	GameState.set_quest_state(&"pages", &"active")
	GameState.add_item(&"page_fragment", 5)
	var texts := _talk(&"librarian", [-1, -1])
	assert_string_contains(texts[0], "marque-page")
	assert_eq(GameState.quest_state(&"pages"), &"done", "complete_quest")
	assert_signal_emitted_with_parameters(EventBus, "quest_updated", [&"pages", &"done"])
	assert_eq(texts.size(), 2, "réplique de récompense")
	assert_eq(_ended, 1)
	GameState.remove_item(&"page_fragment", 5)
	assert_string_contains(_talk(&"librarian", [-1])[0], "dernier tome est complet")
	GameState.add_item(&"page_fragment", 5)
	assert_string_contains(
		_talk(&"librarian", [-1])[0], "dernier tome est complet", "pas de seconde récompense"
	)


func test_blacksmith_gives_three_combat_tips() -> void:
	var texts := _talk(&"blacksmith", [-1, 0, -1, -1, -1, -1])
	var all := " ".join(texts)
	assert_string_contains(all, "Trois coups s’enchaînent", "enchaînement d'épée")
	assert_string_contains(all, "maintiens la touche", "charge maintenue")
	assert_string_contains(all, "verrouille ta cible", "verrouillage")
	assert_string_contains(all, "Seniolis")
	assert_eq(_ended, 1)
	assert_true(GameState.has_flag(&"blacksmith_tips_heard"))
	var again := _talk(&"blacksmith", [0, -1])
	assert_string_contains(again[0], "Te revoilà", "autre accueil une fois les conseils donnés")
	assert_string_contains(again[1], "Trois coups")


func test_blacksmith_can_be_declined() -> void:
	_talk(&"blacksmith", [-1, 1, -1])
	assert_false(GameState.has_flag(&"blacksmith_tips_heard"))
	assert_eq(_ended, 1)


func test_child_talks_about_the_dunes_arena() -> void:
	var texts := _talk(&"child", [-1, 0, -1])
	assert_string_contains(texts[0], "arène")
	assert_string_contains(texts[1], "300")
	assert_eq(_choices[1].size(), 2)
	assert_eq(_ended, 1)


func test_child_line_depends_on_best_score() -> void:
	GameState.record_score(&"dunes", 120, 3)
	assert_string_contains(_talk(&"child", [-1])[0], "120 points", "a déjà joué")
	GameState.record_score(&"dunes", 299, 4)
	assert_false(_talk(&"child", [-1])[0].contains("Tout le village"), "sous 300")
	GameState.record_score(&"dunes", 300, 5)
	var texts := _talk(&"child", [-1, -1])
	assert_string_contains(texts[0], "300 points", "best_score ≥ 300")
	assert_string_contains(texts[0], "Tout le village")
	assert_eq(_ended, 1)
