extends GutTest
## (Systèmes et textes) Portrait par orateur (HISTOIRE.md, développement n° 5) : la clé de nœud
## "speaker_id" nomme le PNJ qui dit ce nœud (data/npcs/<id>.tres, DialogueRunner.find_npc) ; son
## portrait (skin → portrait) s'affiche et son nom devient l'orateur par défaut ; sans elle,
## portrait et nom du PNJ du dialogue. Un speaker_id inconnu : avertissement et repli.

const BOX := preload("res://src/ui/dialogue_box.tscn")
const DIR := "user://test_dialogue_speaker"
const NPCS_DIR := DIR + "/npcs"

var _runner: DialogueRunner
var _lines: Array[Dictionary] = []


func before_each() -> void:
	GameState.reset()
	DirAccess.make_dir_recursive_absolute(NPCS_DIR)
	_save_npc(&"sys_willem", "Willem", Vector2(40, 40))
	_save_npc(&"sys_nephren", "Nephren", Vector2(30, 50))
	DialogueRunner.add_npc_dir(NPCS_DIR)
	_lines.clear()
	EventBus.dialogue_line.connect(_on_line)
	_runner = add_child_autofree(DialogueRunner.new())


func after_each() -> void:
	if is_instance_valid(_runner):
		_runner.stop()
	EventBus.dialogue_line.disconnect(_on_line)
	DialogueRunner.remove_npc_dir(NPCS_DIR)
	for dir: String in [NPCS_DIR, DIR]:
		for file_name: String in DirAccess.get_files_at(dir):
			DirAccess.remove_absolute(dir.path_join(file_name))
	GameState.reset()


func _on_line(speaker: String, text: String, _choices: Array[String]) -> void:
	_lines.append(
		{"speaker": speaker, "text": text, "speaker_id": DialogueRunner.current_speaker_id()}
	)


## PNJ de test (user://) : skin au portrait propre (taille distincte), dialogue commun.
func _save_npc(npc_id: StringName, display_name: String, portrait_size: Vector2) -> void:
	var portrait := PlaceholderTexture2D.new()
	portrait.size = portrait_size
	var skin := SkinData.new()
	skin.id = StringName("%s_visual" % npc_id)
	skin.portrait = portrait
	var npc := NpcData.new()
	npc.id = npc_id
	npc.display_name = display_name
	npc.skin = skin
	npc.dialogue_path = DIR.path_join("scene.json")
	assert_eq(ResourceSaver.save(npc, NPCS_DIR.path_join("%s.tres" % npc_id)), OK)


## Scène à deux voix de Willem (étape 8 de l'acte 1, dans l'esprit) : Nephren parle au 2e et au
## 3e nœud (au 3e, sous un autre nom).
func _write_scene(extra: Dictionary = {}) -> void:
	var nodes := {
		"a": {"text": "Dors, maintenant.", "next": "b"},
		"b": {"speaker_id": "sys_nephren", "text": "Archives. Toute la nuit.", "next": "c"},
		"c": {"speaker_id": "sys_nephren", "speaker": "Ren", "text": "Mm.", "next": "d"},
		"d": {"text": "Bonne nuit.", "next": null},
	}
	nodes.merge(extra, true)
	var file := FileAccess.open(DIR.path_join("scene.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"start": "a", "nodes": nodes}))
	file.close()


func _willem() -> NpcData:
	return DialogueRunner.find_npc(&"sys_willem")


func test_find_npc_looks_in_the_npc_dirs() -> void:
	assert_not_null(_willem(), "dossier ajouté")
	assert_eq(_willem().display_name, "Willem")
	assert_null(DialogueRunner.find_npc(&"inconnu"))
	assert_null(DialogueRunner.find_npc(&""))
	assert_null(DialogueRunner.find_npc(&"../secret"), "pas de chemin")
	DialogueRunner.remove_npc_dir(NPCS_DIR)
	assert_null(DialogueRunner.find_npc(&"sys_willem"), "dossier retiré")
	DialogueRunner.remove_npc_dir(DialogueRunner.NPCS_DIR)
	DialogueRunner.add_npc_dir(NPCS_DIR)
	assert_not_null(_willem(), "data/npcs reste toujours")


func test_speaker_id_gives_name_and_speaker_of_each_line() -> void:
	_write_scene()
	_runner.start(_willem())
	for _next in 3:
		EventBus.dialogue_choice_made.emit(-1)
	var expected: Array = [
		["Willem", &"sys_willem"],
		["Nephren", &"sys_nephren"],
		["Ren", &"sys_nephren"],
		["Willem", &"sys_willem"],
	]
	assert_eq(_lines.size(), 4)
	for index: int in mini(_lines.size(), expected.size()):
		assert_eq(_lines[index]["speaker"], expected[index][0], "nom, nœud %d" % index)
		assert_eq(_lines[index]["speaker_id"], expected[index][1], "orateur, nœud %d" % index)
	EventBus.dialogue_choice_made.emit(-1)
	assert_eq(DialogueRunner.current_speaker_id(), &"", "hors dialogue")


func test_unknown_speaker_id_warns_and_falls_back_to_the_npc() -> void:
	_write_scene({"b": {"speaker_id": "sys_personne", "text": "…", "next": null}})
	_runner.start(_willem())
	EventBus.dialogue_choice_made.emit(-1)
	assert_push_warning("aucun PNJ de ce nom")
	assert_eq(_lines[1]["speaker"], "Willem", "nom du PNJ du dialogue")
	assert_eq(_lines[1]["speaker_id"], &"sys_willem", "portrait du PNJ du dialogue")


func test_speaker_id_is_validated() -> void:
	var cases := {
		"« speaker_id » du nœud « a » doit être un id de PNJ": {"a": {"speaker_id": 3}},
		"clé inconnue « speaker_id » dans le choix":
		{"a": {"choices": [{"text": "Oui", "speaker_id": "x"}]}},
	}
	for expected: String in cases:
		var problem := DialogueRunner.validate({"start": "a", "nodes": cases[expected]})
		assert_string_contains(problem, expected, false)
	var valid := {"start": "a", "nodes": {"a": {"speaker_id": "nephren", "text": "Mm."}}}
	assert_eq(DialogueRunner.validate(valid), "", "speaker_id : un id de PNJ")


func test_dialogue_box_shows_the_portrait_of_who_speaks() -> void:
	var box: DialogueBox = add_child_autofree(BOX.instantiate())
	box.characters_per_second = 0.0
	_write_scene()
	var willem := _willem()
	var nephren := DialogueRunner.find_npc(&"sys_nephren")
	var portrait := box.get_node(^"%Portrait") as TextureRect
	var name_label := box.get_node(^"%NameLabel") as Label
	_runner.start(willem)
	assert_eq(box.portrait_npc(), &"sys_willem", "1re réplique : Willem")
	assert_eq(portrait.texture, DialogueBox.portrait_of(willem.skin))
	EventBus.dialogue_choice_made.emit(-1)
	assert_eq(box.portrait_npc(), &"sys_nephren", "speaker_id : Nephren")
	assert_eq(portrait.texture, DialogueBox.portrait_of(nephren.skin), "portrait du 2e orateur")
	assert_eq(name_label.text, "Nephren", "son nom par défaut")
	EventBus.dialogue_choice_made.emit(-1)
	assert_eq(box.portrait_npc(), &"sys_nephren")
	assert_eq(name_label.text, "Ren", "« speaker » garde la main sur le nom")
	EventBus.dialogue_choice_made.emit(-1)
	assert_eq(box.portrait_npc(), &"sys_willem", "sans speaker_id : retour au PNJ du dialogue")
	assert_eq(portrait.texture, DialogueBox.portrait_of(willem.skin))
	assert_true(box.get_node(^"%PortraitFrame").visible)
	EventBus.dialogue_choice_made.emit(-1)
	assert_false(box.is_open(), "fin du dialogue")
	assert_eq(box.portrait_npc(), &"")
