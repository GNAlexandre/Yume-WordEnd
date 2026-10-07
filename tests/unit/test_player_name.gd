extends "res://tests/stubs/q_quest_test.gd"
## (Systèmes et textes) {player} (HISTOIRE.md, développement n° 2) : le nom affiché du skin
## choisi (GameState.skin_id, sinon le skin par défaut, Chtholly) remplace {player} dans les
## répliques, les choix et le nom de l'orateur, et dans les textes de quête du HUD et du journal
## (titres, résumé, objectifs, aides), sans casser {count:…}, {left:…} et {best:…}.

const HUD := preload("res://src/ui/hud.tscn")
const HudScript := preload("res://src/ui/hud.gd")
const DIR := "user://test_player_name"
const SKINS_DIR := DIR + "/skins"

var _lines: Array[Dictionary] = []


func before_each() -> void:
	super()
	DirAccess.make_dir_recursive_absolute(SKINS_DIR)
	_lines.clear()
	EventBus.dialogue_line.connect(_on_line)
	get_tree().paused = false


func after_each() -> void:
	get_tree().paused = false
	EventBus.dialogue_line.disconnect(_on_line)
	if SkinRegistry.skins_dir != SkinRegistry.SKINS_DIR:
		SkinRegistry.skins_dir = SkinRegistry.SKINS_DIR
		SkinRegistry.reload()
	for dir: String in [SKINS_DIR, DIR]:
		for file_name: String in DirAccess.get_files_at(dir):
			DirAccess.remove_absolute(dir.path_join(file_name))
	super()


func _on_line(speaker: String, text: String, choices: Array[String]) -> void:
	var plain: Array = []
	plain.assign(choices)
	_lines.append({"speaker": speaker, "text": text, "choices": plain})


## Registre de skins de test (user://) : Chtholly et une fée de la communauté, « Lyra ».
func _with_lyra() -> void:
	for entry: Array in [[&"chtholly", "Chtholly"], [&"sys_lyra", "Lyra"]]:
		var skin := SkinData.new()
		skin.id = entry[0]
		skin.display_name = entry[1]
		assert_eq(ResourceSaver.save(skin, SKINS_DIR.path_join("%s.tres" % entry[0])), OK)
	SkinRegistry.skins_dir = SKINS_DIR
	SkinRegistry.reload()


func _npc(nodes: Dictionary) -> NpcData:
	var path := DIR.path_join("dialogue.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"start": "a", "nodes": nodes}))
	file.close()
	var npc := NpcData.new()
	npc.id = &"sys_teller"
	npc.display_name = "Conteuse"
	npc.dialogue_path = path
	return npc


## Quête dont tous les textes affichés citent {player} (étapes flag : aucun PNJ requis).
func _player_quest() -> void:
	write_quest(
		{
			"id": "sys_name",
			"title": "La veille de {player}",
			"summary": "Tiat inscrit les veilles de {player} dans son carnet.",
			"steps":
			[
				{
					"id": "first",
					"type": "flag",
					"flag": "sys_first",
					"objective": "Montrer le carnet à {player}",
				},
				{
					"id": "second",
					"type": "collect",
					"item": "page_fragment",
					"count": 3,
					"objective": "{player} : réunir {left:page_fragment:3} pages",
					"hint": "Mademoiselle {player} en a {count:page_fragment}.",
				},
			],
		}
	)


func test_player_name_is_the_chosen_skin_display_name() -> void:
	GameState.skin_id = &""
	assert_eq(DialogueRunner.player_name(), "Chtholly", "skin par défaut")
	assert_eq(DialogueRunner.format_text("{player}"), "Chtholly")
	_with_lyra()
	GameState.skin_id = &"sys_lyra"
	assert_eq(DialogueRunner.player_name(), "Lyra", "nom affiché du skin choisi")
	GameState.skin_id = &"inconnu"
	assert_eq(DialogueRunner.player_name(), "Chtholly", "skin inconnu : celui par défaut")


func test_format_keeps_the_other_variables() -> void:
	_with_lyra()
	GameState.skin_id = &"sys_lyra"
	GameState.add_item(&"page_fragment", 2)
	GameState.record_score(&"dunes", 420, 4)
	var text := (
		"{player}, {count:page_fragment} pages, encore {left:page_fragment:5}, "
		+ "record {best:dunes} ; bravo {player} !"
	)
	assert_eq(
		DialogueRunner.format_text(text), "Lyra, 2 pages, encore 3, record 420 ; bravo Lyra !"
	)
	assert_eq(DialogueRunner.format_text("Sans variable."), "Sans variable.")
	assert_eq(DialogueRunner.format_text("{joueur} reste tel quel"), "{joueur} reste tel quel")


func test_line_choices_and_speaker_use_the_player_name() -> void:
	_with_lyra()
	GameState.skin_id = &"sys_lyra"
	var npc := _npc(
		{
			"a":
			{
				"text": "Te voilà, {player}. Tu as {count:page_fragment} pages ?",
				"choices":
				[
					{"text": "Je suis {player}.", "next": "b"},
					{"text": "Laisse-moi.", "next": null},
				],
			},
			"b": {"speaker": "{player}", "text": "C'est moi, {player} !", "next": null},
		}
	)
	dialogue_runner.start(npc)
	assert_eq(_lines[0]["speaker"], "Conteuse")
	assert_eq(_lines[0]["text"], "Te voilà, Lyra. Tu as 0 pages ?", "réplique")
	assert_eq(_lines[0]["choices"], ["Je suis Lyra.", "Laisse-moi."], "choix")
	EventBus.dialogue_choice_made.emit(0)
	assert_eq(_lines[1]["speaker"], "Lyra", "la protagoniste parle : son nom")
	assert_eq(_lines[1]["text"], "C'est moi, Lyra !")
	dialogue_runner.stop()


func test_hud_shows_quest_texts_with_the_player_name() -> void:
	_with_lyra()
	GameState.skin_id = &"sys_lyra"
	_player_quest()
	var hud: HudScript = add_child_autofree(HUD.instantiate())
	start_quest(&"sys_name")
	await wait_process_frames(2)
	assert_eq(hud.quest_title(&"sys_name"), "La veille de Lyra", "titre")
	assert_eq(hud.quest_objective(&"sys_name"), "Montrer le carnet à Lyra", "objectif")
	GameState.set_flag(&"sys_first")
	GameState.add_item(&"page_fragment")
	await wait_process_frames(2)
	assert_eq(hud.quest_objective(&"sys_name"), "Lyra : réunir 2 pages", "variables mêlées")
	# Changer de skin met le texte à jour.
	GameState.skin_id = &"chtholly"
	await wait_process_frames(2)
	assert_eq(hud.quest_title(&"sys_name"), "La veille de Chtholly", "skin_changed")
	assert_eq(hud.quest_objective(&"sys_name"), "Chtholly : réunir 2 pages")


func test_journal_shows_quest_texts_with_the_player_name() -> void:
	_with_lyra()
	GameState.skin_id = &"sys_lyra"
	_player_quest()
	var hud: HudScript = add_child_autofree(HUD.instantiate())
	start_quest(&"sys_name")
	GameState.set_flag(&"sys_first")
	GameState.add_item(&"page_fragment")
	await wait_process_frames(1)
	var journal := hud.get_node(^"%Journal")
	journal.call(&"open")
	assert_true(journal.call(&"is_open"), "journal ouvert")
	assert_eq((journal.get_node(^"%QuestTitle") as Label).text, "La veille de Lyra", "titre")
	assert_eq(
		(journal.get_node(^"%Summary") as Label).text,
		"Tiat inscrit les veilles de Lyra dans son carnet.",
		"résumé"
	)
	var list := journal.get_node(^"%List").find_child("Quest_sys_name", true, false) as Button
	assert_eq(list.text, "La veille de Lyra", "titre dans la liste")
	var steps: Array[Dictionary] = journal.call(&"shown_steps")
	assert_eq(steps.size(), 2)
	assert_eq(steps[0]["objective"], "Montrer le carnet à Lyra", "étape validée")
	assert_eq(steps[1]["objective"], "Lyra : réunir 2 pages", "étape courante")
	var texts: Array[String] = []
	for label: Node in journal.get_node(^"%Steps").find_children("*", "Label", true, false):
		texts.append((label as Label).text)
	assert_has(texts, "Mademoiselle Lyra en a 1.", "aide de l'étape")
	for text: String in texts:
		assert_false(text.contains("{player}"), "plus de {player} : %s" % text)
	journal.call(&"close")
