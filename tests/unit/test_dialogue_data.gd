extends GutTest
## Lot 6, contenu de l'acte 1 : dialogues de data/dialogues/ joués avec les vrais PNJ
## (data/npcs/) et le DialogueRunner seul. Sans QuestTracker, advance_quest n'émet que sa
## demande (EventBus.quest_advance_requested) : on vérifie la demande, et l'étape se règle à la
## main (GameState.set_quest_step). Scénarios complets avec le moteur : tests/unit/test_act1_*.gd.

const DIALOGUES_DIR := "res://data/dialogues"
## Un dialogue par PNJ de l'acte 1 (data/npcs/<id>.tres), et rien d'autre.
const NPC_IDS: Array[String] = [
	"nygglatho",
	"willem",
	"willem_training",
	"willem_stars",
	"ithea",
	"nephren",
	"tiat",
	"pannibal",
	"collon",
	"lakhesh",
	"almita",
	"limeskin",
	"cat_waiter",
	"ramikeldi",
	"snack_vendor",
	"baker",
	"ferryman",
	"egg_vendor",
	"garde_lookout",
]

var _runner: DialogueRunner
var _texts: Array[String] = []
var _speakers: Array[String] = []
var _choices: Array = []
var _ended: int = 0
## Demandes advance_quest reçues depuis le début du test : [quête, étape].
var _advances: Array = []


func before_each() -> void:
	GameState.reset()
	_texts.clear()
	_speakers.clear()
	_choices.clear()
	_ended = 0
	_advances.clear()
	EventBus.dialogue_line.connect(_on_line)
	EventBus.dialogue_ended.connect(_on_ended)
	EventBus.quest_advance_requested.connect(_on_advance_requested)
	_runner = add_child_autofree(DialogueRunner.new())


func after_each() -> void:
	_runner.stop()
	EventBus.dialogue_line.disconnect(_on_line)
	EventBus.dialogue_ended.disconnect(_on_ended)
	EventBus.quest_advance_requested.disconnect(_on_advance_requested)


func after_all() -> void:
	GameState.reset()


func _on_line(speaker: String, text: String, choices: Array) -> void:
	_speakers.append(speaker)
	_texts.append(text)
	var plain: Array = []
	plain.assign(choices)
	_choices.append(plain)


func _on_ended(_npc_id: StringName) -> void:
	_ended += 1


func _on_advance_requested(quest_id: StringName, step_id: StringName) -> void:
	_advances.append([quest_id, step_id])


## Lance le dialogue du PNJ puis répond dans l'ordre (-1 = suite) ; renvoie les textes affichés.
## _speakers, _choices et _ended décrivent ensuite cette conversation seulement.
func _talk(npc_id: StringName, answers: Array[int]) -> Array[String]:
	_runner.stop()
	_texts.clear()
	_speakers.clear()
	_choices.clear()
	_ended = 0
	_runner.start(load("res://data/npcs/%s.tres" % npc_id) as NpcData)
	for answer: int in answers:
		EventBus.dialogue_choice_made.emit(answer)
	return _texts.duplicate()


## act1_main en cours, à l'étape step_id.
func _main_step(step_id: StringName) -> void:
	GameState.set_quest_state(&"act1_main", &"active")
	GameState.set_quest_step(&"act1_main", step_id)


func _asked_to_advance(quest_id: StringName, step_id: StringName) -> void:
	assert_has(_advances, [quest_id, step_id], "advance_quest %s %s" % [quest_id, step_id])


func test_all_dialogue_files_are_valid() -> void:
	var files := ResourceLoader.list_directory(DIALOGUES_DIR)
	for npc_id: String in NPC_IDS:
		assert_has(files, npc_id + ".json", "data/dialogues/%s.json" % npc_id)
	for old_id: String in ["librarian", "blacksmith", "child"]:
		assert_does_not_have(files, old_id + ".json", "ancien dialogue retiré : %s" % old_id)
	var count := 0
	for file_name: String in files:
		if not file_name.ends_with(".json"):
			continue
		count += 1
		var dialogue := DialogueRunner.load_dialogue(DIALOGUES_DIR.path_join(file_name))
		assert_false(dialogue.is_empty(), "%s valide" % file_name)
		assert_eq(str(dialogue.get("id")), file_name.get_basename(), "id = nom du fichier")
		for node: Variant in (dialogue.get("nodes", {}) as Dictionary).values():
			var text := str((node as Dictionary).get("text", ""))
			assert_lt(text.length(), 160, "%s : réplique courte (%s)" % [file_name, text])
			var choices: Array = (node as Dictionary).get("choices", [])
			assert_lte(choices.size(), DialogueRunner.MAX_CHOICES, "%s : 2 choix au plus" % text)
			for choice: Variant in choices:
				assert_lt(str((choice as Dictionary).get("text")).length(), 32, "choix court")
	assert_eq(count, NPC_IDS.size(), "un dialogue par PNJ")


func test_nygglatho_wakes_the_eldest() -> void:
	GameState.set_quest_state(&"act1_main", &"active")
	var texts := _talk(&"nygglatho", [-1, -1, -1, -1, 0, -1])
	assert_eq(texts.size(), 6)
	assert_string_contains(texts[0], "Le vent a hurlé")
	assert_eq(_speakers[0], "Nygglatho")
	assert_eq(_choices[4], ["J’y vais.", "Le nouveau\u00a0?"], "deux réponses")
	assert_string_contains(texts[5], "Willem")
	_asked_to_advance(&"act1_main", &"morning")
	assert_eq(_ended, 1)


func test_willem_gives_his_combat_tips() -> void:
	_main_step(&"new_officer")
	var texts := _talk(&"willem", [-1, 1, -1, 0, -1, -1])
	assert_eq(texts.size(), 6)
	assert_eq(_choices[1], ["On se connaît\u00a0?", "Tu devais m’oublier."])
	assert_string_contains(texts[2], "Ça n’a pas marché", "la réponse choisie")
	assert_eq(_choices[3], ["N’y touche pas."], "elle refuse qu'il touche à l'épée")
	var all := " ".join(texts)
	assert_string_contains(all, "trois coups", "enchaînement d'épée")
	assert_string_contains(all, "Tiens la charge", "charge maintenue")
	assert_string_contains(all, "verrouille ta cible", "verrouillage")
	_asked_to_advance(&"act1_main", &"new_officer")
	assert_eq(_ended, 1)


func test_willem_hints_follow_the_main_quest() -> void:
	assert_string_contains(_talk(&"willem", [-1])[0], "Sous-officier", "réplique par défaut")
	_main_step(&"morning")
	assert_string_contains(_talk(&"willem", [-1])[0], "Sous le porche")
	_main_step(&"training")
	assert_string_contains(_talk(&"willem", [-1])[0], "terrain d’entraînement")
	_main_step(&"promise")
	assert_string_contains(_talk(&"willem", [-1])[0], "sommet de la colline")
	assert_eq(_ended, 1)


func test_willem_reactions_are_said_once() -> void:
	GameState.set_flag(&"book_read")
	assert_string_contains(_talk(&"willem", [-1])[0], "arrêté une fois")
	assert_true(GameState.has_flag(&"willem_book_said"))
	assert_string_contains(_talk(&"willem", [-1])[0], "Sous-officier", "une seule fois")
	GameState.set_flag(&"little_ones_trust_willem")
	assert_string_contains(_talk(&"willem", [-1])[0], "«\u00a0Willie\u00a0»")
	GameState.set_flag(&"act1_done")
	assert_string_contains(_talk(&"willem", [-1])[0], "beurre", "après l'acte 1")


func test_multi_voice_scene_names_each_speaker() -> void:
	_main_step(&"fever")
	var texts := _talk(&"willem", [-1, 0, -1, -1, -1, -1])
	assert_eq(texts.size(), 6)
	assert_eq(_speakers, ["Willem", "Willem", "", "Nephren", "Nephren", "Willem"] as Array[String])
	assert_string_contains(texts[2], "«\u00a0Dors.\u00a0»", "narration sans nom")
	assert_eq(_choices[4], [], "pas de scène secondaire en attente : suite directe")
	_asked_to_advance(&"act1_main", &"fever")
	assert_eq(_ended, 1)


func test_willem_chains_the_waiting_side_scene() -> void:
	_main_step(&"fever")
	GameState.set_quest_state(&"picture_book", &"active")
	GameState.set_quest_step(&"picture_book", &"reading")
	var texts := _talk(&"willem", [-1, 0, -1, -1, 0, -1, -1, -1, -1, -1, -1])
	assert_eq(_choices[4], ["Et le livre d’images\u00a0?"], "la lecture attend")
	assert_string_contains(texts[5], "Le livre d’images, recollé")
	assert_eq(_speakers.slice(6, 9), ["Collon", "Tiat", "Pannibal"] as Array[String])
	_asked_to_advance(&"act1_main", &"fever")
	_asked_to_advance(&"picture_book", &"reading")
	assert_eq(_ended, 1)


func test_nephren_offers_the_picture_book() -> void:
	assert_eq(_talk(&"nephren", [-1])[0], "Chut. Salle de lecture.", "pas avant Willem")
	GameState.set_flag(&"met_willem")
	var texts := _talk(&"nephren", [-1, 0, -1])
	assert_eq(texts[0], "Livre. Vent. Pages.")
	assert_eq(_choices[1], ["Je les retrouve.", "Plus tard."], "accepter / plus tard")
	assert_eq(GameState.quest_state(&"picture_book"), &"active", "quête démarrée")
	assert_string_contains(texts[2], "Salle de lecture")
	assert_eq(_ended, 1)


func test_nephren_later_keeps_the_book_available() -> void:
	GameState.set_flag(&"met_willem")
	var texts := _talk(&"nephren", [-1, 1, -1])
	assert_eq(texts[2], "Mm.")
	assert_eq(GameState.quest_state(&"picture_book"), &"", "rien ne change")
	assert_eq(_talk(&"nephren", [])[0], "Livre. Vent. Pages.", "la proposition revient")


func test_nephren_counts_the_pages() -> void:
	GameState.set_flag(&"met_willem")
	GameState.set_quest_state(&"picture_book", &"active")
	assert_eq(_talk(&"nephren", [-1])[0], "Encore 5. Mm.")
	GameState.add_item(&"page_fragment", 3)
	assert_eq(_talk(&"nephren", [-1])[0], "Encore 2. Mm.")
	GameState.add_item(&"page_fragment", 2)
	var texts := _talk(&"nephren", [-1, -1, -1])
	assert_eq(texts[0], "Cinq. Mm.")
	assert_string_contains(texts[1], "Willem lira")
	_asked_to_advance(&"picture_book", &"pages")


func test_nygglatho_lends_out_the_laundry() -> void:
	GameState.set_flag(&"met_willem")
	var texts := _talk(&"nygglatho", [-1, 0, -1])
	assert_string_contains(texts[0], "draps du toit")
	assert_eq(_choices[1], ["Je m’en occupe.", "Plus tard."])
	assert_eq(GameState.quest_state(&"flying_laundry"), &"active")
	assert_string_contains(texts[2], "Port, Couchant, colline, bois")
	assert_string_contains(_talk(&"nygglatho", [-1])[0], "encore 5")
	GameState.add_item(&"laundry_sheet", 4)
	assert_string_contains(_talk(&"nygglatho", [-1])[0], "encore 1")


func test_nygglatho_tea_and_cheesecake() -> void:
	GameState.set_quest_state(&"flying_laundry", &"active")
	GameState.set_quest_step(&"flying_laundry", &"tea")
	var texts := _talk(&"nygglatho", [-1, -1, -1, 0, -1])
	assert_eq(texts.size(), 5)
	assert_string_contains(texts[2], "précognition")
	assert_eq(_choices[3], ["Du cheese-cake\u00a0?", "Merci, Nygglatho."])
	_asked_to_advance(&"flying_laundry", &"tea")


func test_pannibal_comes_home_with_a_narrated_ambush() -> void:
	_main_step(&"pannibal")
	assert_eq(_talk(&"pannibal", [-1, 1, -1, -1]).size(), 4)
	assert_eq(_choices[1], ["Rentre. Tout de suite.", "Montre-moi ton embuscade."])
	assert_eq(_speakers[2], "", "narration")
	assert_true(GameState.has_flag(&"pannibal_found"))
	_asked_to_advance(&"act1_main", &"pannibal")
	_main_step(&"report")
	assert_string_contains(_talk(&"pannibal", [-1])[0], "Le marais, c’est chez moi")


func test_tiat_keeps_the_vigil_register() -> void:
	assert_string_contains(_talk(&"tiat", [-1])[0], "fée soldat", "avant la première veille")
	GameState.set_flag(&"first_vigil_done")
	var texts := _talk(&"tiat", [-1, 0, -1])
	assert_string_contains(texts[0], "tenir la veille")
	assert_eq(_choices[1], ["Inscris-moi.", "Plus tard, Tiat."])
	assert_eq(GameState.quest_state(&"vigil_register"), &"active")
	GameState.set_quest_step(&"vigil_register", &"score")
	GameState.record_score(&"dunes", 640, 4)
	assert_string_contains(_talk(&"tiat", [-1])[0], "Votre meilleure veille\u00a0: 640 points.")
	GameState.set_quest_step(&"vigil_register", &"record")
	GameState.record_score(&"dunes", 1200, 6)
	assert_string_contains(_talk(&"tiat", [-1, -1, -1])[0], "Votre record\u00a0: 1200.")


func test_willem_promises_under_the_stars() -> void:
	_main_step(&"promise")
	var texts := _talk(&"willem_stars", [-1, -1, -1, 1, -1, 0])
	assert_eq(texts.size(), 6)
	assert_eq(_speakers[1], "", "narration : les talismans")
	assert_eq(_choices[3], ["Épouse-moi.", "Tu fais le gâteau au beurre\u00a0?"])
	assert_string_contains(texts[5], "C’est promis.")
	_asked_to_advance(&"act1_main", &"promise")
	assert_eq(_ended, 1)


func test_limeskin_serves_bitter_tea() -> void:
	assert_string_contains(_talk(&"limeskin", [-1])[0], "Barocupot", "escale, avant l'étape")
	_main_step(&"barocupot")
	var texts := _talk(&"limeskin", [-1, -1, 0, -1, -1])
	assert_eq(texts.size(), 5)
	assert_string_contains(texts[4], "Seniorious")
	assert_true(GameState.has_flag(&"limeskin_tea"))
	_asked_to_advance(&"act1_main", &"barocupot")


func test_after_the_act_lines() -> void:
	GameState.set_flag(&"act1_done")
	var expected := {
		&"nygglatho": "uniformes",
		&"willem": "beurre",
		&"nephren": "Mm.",
		&"tiat": "pages blanches",
		&"pannibal": "marais",
		&"limeskin": "thé brûlant",
		&"willem_stars": "étoiles",
	}
	for npc_id: StringName in expected:
		assert_string_contains(_talk(npc_id, [-1, -1])[0], expected[npc_id], String(npc_id))
