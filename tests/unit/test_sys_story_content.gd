extends GutTest
## (Systèmes et textes) Le contenu du jeu emploie bien les développements de ce lot : chaque
## "speaker_id" des dialogues (data/dialogues et ses sous-dossiers) nomme un PNJ de data/npcs,
## chaque NpcData.visible_if est une condition valide, et aucun texte ne cite plus « Seniolis ».
## (F1) Les textes de quête du HUD sont partis avec l'ancienne île.
## À relancer après avoir écrit des dialogues ou des PNJ :
##   tools/test.sh tests/unit/test_sys_story_content.gd

const DIALOGUES_DIR := "res://data/dialogues"
const NPCS_DIR := "res://data/npcs"

var _problems: Array[String] = []


func before_each() -> void:
	_problems.clear()


## Fichiers JSON de dir et de ses sous-dossiers.
func _json_files(dir: String) -> Array[String]:
	var paths: Array[String] = []
	for sub: String in DirAccess.get_directories_at(dir):
		paths.append_array(_json_files(dir.path_join(sub)))
	for file_name: String in DirAccess.get_files_at(dir):
		if file_name.ends_with(".json"):
			paths.append(dir.path_join(file_name))
	return paths


func _read_json(path: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func test_every_speaker_id_names_an_npc() -> void:
	var speakers := 0
	for path: String in _json_files(DIALOGUES_DIR):
		var dialogue: Variant = _read_json(path)
		var nodes: Variant = dialogue.get("nodes") if dialogue is Dictionary else null
		if not nodes is Dictionary:
			continue
		for node_id: Variant in nodes:
			var node: Variant = nodes[node_id]
			if not node is Dictionary or not (node as Dictionary).has("speaker_id"):
				continue
			speakers += 1
			var speaker := StringName(str(node["speaker_id"]))
			if DialogueRunner.find_npc(speaker) == null:
				_problems.append("%s, nœud « %s » : aucun PNJ « %s »" % [path, node_id, speaker])
			elif DialogueBox.portrait_for(speaker) == null:
				_problems.append(
					"%s, nœud « %s » : « %s » sans portrait" % [path, node_id, speaker]
				)
	assert_gt(_json_files(DIALOGUES_DIR).size(), 0, "des dialogues dans data/dialogues")
	assert_eq(_problems, [] as Array[String], "\n".join(_problems))
	gut.p("%d nœud(s) avec speaker_id" % speakers)


func test_every_npc_presence_condition_is_valid() -> void:
	var npcs := 0
	for file_name: String in DirAccess.get_files_at(NPCS_DIR):
		if not file_name.ends_with(".tres"):
			continue
		var npc := load(NPCS_DIR.path_join(file_name)) as NpcData
		if npc == null:
			continue
		npcs += 1
		var problem := npc.visible_if_problem()
		if not problem.is_empty():
			_problems.append("%s : visible_if : %s" % [file_name, problem])
	assert_gt(npcs, 0, "des PNJ dans data/npcs")
	assert_eq(_problems, [] as Array[String], "\n".join(_problems))


## Textes de ce lot : crédits, menu, textes de l'histoire, README, plan, générateur d'images.
## (Les dialogues relèvent du contenu de l'acte 1 et de ses propres tests.)
func test_no_text_of_this_lot_still_says_seniolis() -> void:
	var paths: Array[String] = [
		"res://src/ui/credits.tscn",
		"res://src/ui/main_menu.tscn",
		DialogueRunner.STORY_PATH,
		"res://README.md",
		"res://PLAN.md",
		"res://tools/gen_branding.py",
	]
	for path: String in paths:
		var text := FileAccess.get_file_as_string(path)
		assert_false(text.is_empty(), "%s lu" % path)
		if text.contains("Seniolis"):
			_problems.append("%s : « Seniolis » (graphie de la traduction : Seniorious)" % path)
	assert_eq(_problems, [] as Array[String], "\n".join(_problems))
