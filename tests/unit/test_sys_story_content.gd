extends GutTest
## (Systèmes et textes) Le contenu du jeu emploie bien les développements de ce lot : chaque
## "speaker_id" des dialogues nomme un PNJ de data/npcs, chaque NpcData.visible_if est une
## condition valide, les textes de quête qui citent {player} tiennent encore dans le HUD une fois
## le plus long prénom de skin mis à sa place, et aucun texte ne cite plus « Seniolis ».
## À relancer après avoir écrit des dialogues, des PNJ ou des quêtes :
##   tools/test.sh tests/unit/test_sys_story_content.gd

const DIALOGUES_DIR := "res://data/dialogues"
const NPCS_DIR := "res://data/npcs"
const QUESTS_DIR := "res://data/quests"
## Longueurs maximales du HUD (docs/QUETES.md ; tests/unit/test_quest_content.gd).
const MAX_TITLE := 40
const MAX_OBJECTIVE := 70

var _problems: Array[String] = []


func before_each() -> void:
	_problems.clear()


func _json_files(dir: String) -> Array[String]:
	var paths: Array[String] = []
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


func test_player_name_fits_in_quest_texts() -> void:
	# {player} est le prénom du skin (DialogueRunner.first_name : sans la variante « · 3D »).
	var longest := DialogueRunner.DEFAULT_PLAYER_NAME
	for skin: SkinData in SkinRegistry.all():
		var first := DialogueRunner.first_name(skin.display_name)
		if first.length() > longest.length():
			longest = first
	var quests := 0
	for path: String in _json_files(QUESTS_DIR):
		var quest: Variant = _read_json(path)
		if not quest is Dictionary:
			continue
		quests += 1
		_check_length(path, "titre", str(quest.get("title", "")), MAX_TITLE, longest)
		for step: Variant in quest.get("steps", []):
			if step is Dictionary:
				var objective := str((step as Dictionary).get("objective", ""))
				_check_length(path, "objectif", objective, MAX_OBJECTIVE, longest)
	assert_gt(quests, 0, "des quêtes dans data/quests")
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


func _check_length(path: String, what: String, text: String, limit: int, player: String) -> void:
	var shown := text.replace(DialogueRunner.PLAYER_TOKEN, player)
	if text.contains(DialogueRunner.PLAYER_TOKEN) and shown.length() > limit:
		_problems.append(
			(
				"%s : %s trop long avec « %s » (%d > %d) : %s"
				% [path, what, player, shown.length(), limit, text]
			)
		)
