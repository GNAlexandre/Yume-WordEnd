extends GutTest
## (Systèmes et textes) {player} (HISTOIRE.md, développement n° 2) : le nom affiché du skin
## choisi (GameState.skin_id, sinon le skin par défaut, Chtholly) remplace {player} dans les
## répliques, les choix et le nom de l'orateur, sans casser {count:…} et {left:…}. (F1) Les textes
## de quête du HUD et du journal sont partis avec l'ancienne île.

const DIR := "user://test_player_name"
const SKINS_DIR := DIR + "/skins"

var dialogue_runner: DialogueRunner
var _lines: Array[Dictionary] = []


func before_each() -> void:
	GameState.reset()
	DirAccess.make_dir_recursive_absolute(SKINS_DIR)
	_lines.clear()
	EventBus.dialogue_line.connect(_on_line)
	dialogue_runner = add_child_autofree(DialogueRunner.new())
	get_tree().paused = false


func after_each() -> void:
	get_tree().paused = false
	if is_instance_valid(dialogue_runner):
		dialogue_runner.stop()
	EventBus.dialogue_line.disconnect(_on_line)
	if SkinRegistry.skins_dir != SkinRegistry.SKINS_DIR:
		SkinRegistry.skins_dir = SkinRegistry.SKINS_DIR
		SkinRegistry.reload()
	for dir: String in [SKINS_DIR, DIR]:
		for file_name: String in DirAccess.get_files_at(dir):
			DirAccess.remove_absolute(dir.path_join(file_name))
	GameState.reset()


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


func test_player_name_is_the_chosen_skin_display_name() -> void:
	GameState.skin_id = &""
	assert_eq(DialogueRunner.player_name(), "Chtholly", "skin par défaut")
	assert_eq(DialogueRunner.format_text("{player}"), "Chtholly")
	_with_lyra()
	GameState.skin_id = &"sys_lyra"
	assert_eq(DialogueRunner.player_name(), "Lyra", "nom affiché du skin choisi")
	GameState.skin_id = &"inconnu"
	assert_eq(DialogueRunner.player_name(), "Chtholly", "skin inconnu : celui par défaut")


## Les skins 3D s'appellent « Chtholly Nota Seniorious · 3D », « Ithea Myse Valgulious · 3D » :
## {player} n'en garde que le prénom, sans la variante (docs/DIALOGUES.md, « Le nom du joueur »).
func test_player_name_is_the_first_name_without_the_skin_variant() -> void:
	assert_eq(DialogueRunner.first_name("Chtholly Nota Seniorious · 3D"), "Chtholly")
	assert_eq(DialogueRunner.first_name("Ithea Myse Valgulious · 3D"), "Ithea")
	assert_eq(DialogueRunner.first_name("Willem Kmetsch · 3D"), "Willem")
	assert_eq(DialogueRunner.first_name("Lyra"), "Lyra")
	assert_eq(DialogueRunner.first_name("  Lyra  Ko  Aurea  "), "Lyra")
	assert_eq(DialogueRunner.first_name(" · 3D"), "", "pas de nom avant la variante")
	assert_eq(DialogueRunner.first_name(""), "")
	for entry: Array in [
		[&"chtholly", "Chtholly"],
		[&"sys_chtholly_3d", "Chtholly Nota Seniorious · 3D"],
		[&"sys_lyra_3d", "Lyra Ko Aurea · 3D"],
		[&"sys_nameless", " · 3D"],
	]:
		var skin := SkinData.new()
		skin.id = entry[0]
		skin.display_name = entry[1]
		assert_eq(ResourceSaver.save(skin, SKINS_DIR.path_join("%s.tres" % entry[0])), OK)
	SkinRegistry.skins_dir = SKINS_DIR
	SkinRegistry.reload()
	GameState.skin_id = &"sys_chtholly_3d"
	assert_eq(DialogueRunner.player_name(), "Chtholly", "Chtholly en 3D : son prénom")
	var line := "Alors reviens, {player}, et je t’en ferai manger une montagne."
	assert_eq(
		DialogueRunner.format_text(line),
		"Alors reviens, Chtholly, et je t’en ferai manger une montagne.",
		"une réplique de l'acte 1"
	)
	GameState.skin_id = &"sys_lyra_3d"
	assert_eq(DialogueRunner.format_text("Mlle {player}"), "Mlle Lyra", "fée adulte : le prénom")
	GameState.skin_id = &"sys_nameless"
	assert_eq(DialogueRunner.player_name(), "Chtholly", "nom vide : Chtholly")


## Aucun skin du jeu ne donne à {player} sa variante ni plus d'un mot.
func test_every_game_skin_gives_a_first_name() -> void:
	var skins := SkinRegistry.all()
	assert_gt(skins.size(), 0, "des skins dans data/skins")
	for skin: SkinData in skins:
		GameState.skin_id = skin.id
		var name_text := DialogueRunner.player_name()
		assert_false(name_text.is_empty(), "%s : un prénom" % skin.id)
		assert_false(
			name_text.contains("·") or name_text.contains(" "), "%s : %s" % [skin.id, name_text]
		)
		assert_true(skin.display_name.begins_with(name_text), "%s : le début de son nom" % skin.id)


func test_format_keeps_the_other_variables() -> void:
	_with_lyra()
	GameState.skin_id = &"sys_lyra"
	GameState.add_item(&"page_fragment", 2)
	var text := (
		"{player}, {count:page_fragment} pages, encore {left:page_fragment:5}, "
		+ "record {best:dunes} ; bravo {player} !"
	)
	assert_eq(
		DialogueRunner.format_text(text),
		"Lyra, 2 pages, encore 3, record {best:dunes} ; bravo Lyra !"
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
