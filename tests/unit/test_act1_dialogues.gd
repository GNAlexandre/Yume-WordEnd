extends GutTest
## Acte 1, relecture des textes (HISTOIRE.md sections 3.6 et 8, docs/QUETES.md) : typographie
## (espace insécable avant ! ? : ; et dans les guillemets, apostrophe ’, points de suspension …) ;
## longueurs (réplique de 140 caractères au plus, choix de moins de 32, deux choix au plus) ;
## nœuds tous atteignables ; chaque étape « parler » ou « rapporter à » a sa scène d'entrée chez
## son PNJ, avant les propositions et les répliques par défaut (une étape « parler » se valide à
## la fin de toute conversation avec le PNJ) ; la voix : jamais le nom de la protagoniste (c'est
## la fée choisie, {player}, avec parcimonie), « Seniorious » ; scènes à plusieurs voix :
## speaker_id d'accord avec speaker. Textes des quêtes, des objets et des PNJ : même typographie.

const DIALOGUES_DIR := "res://data/dialogues"
const NPCS_DIR := "res://data/npcs"
const ITEMS_DIR := "res://data/items"
const NBSP := " "
const NNBSP := " "
## Une réplique tient en deux lignes de la boîte (HISTOIRE.md section 8).
const MAX_LINE := 140
const MAX_CHOICE := 31
## {player} : avec parcimonie (HISTOIRE.md section 8).
const MAX_PLAYER_TOKENS := 4
## Clé du portrait d'un second orateur (DialogueRunner.NODE_KEYS, « Systèmes et textes »).
const SPEAKER_ID_KEY := "speaker_id"
## Jetons remplacés à l'affichage (DialogueRunner.format_text, {player}).
const TOKENS := "\\{(count|left|best|player)(:[^{}]*)?\\}"

var _problems: Array[String] = []


func before_each() -> void:
	_problems.clear()


## Dialogues de l'acte 1 : id → données JSON.
func _dialogues() -> Dictionary:
	var result := {}
	for file_name: String in ResourceLoader.list_directory(DIALOGUES_DIR):
		if file_name.ends_with(".json"):
			var path := DIALOGUES_DIR.path_join(file_name)
			result[file_name.get_basename()] = JSON.parse_string(
				FileAccess.get_file_as_string(path)
			)
	return result


## Textes de nœuds et de choix d'un dialogue : [[étiquette, texte, est un choix], …].
func _texts(npc_id: String, dialogue: Dictionary) -> Array[Array]:
	var result: Array[Array] = []
	var nodes: Dictionary = dialogue["nodes"]
	for node_id: String in nodes:
		var node: Dictionary = nodes[node_id]
		result.append(["%s/%s" % [npc_id, node_id], str(node.get("text", "")), false])
		for choice: Dictionary in node.get("choices", []):
			result.append(["%s/%s (choix)" % [npc_id, node_id], str(choice["text"]), true])
	return result


## Problèmes de typographie d’un texte (jetons {…} remplacés par 0), ajoutés à _problems.
func _check_typography(label: String, text: String) -> void:
	var plain := RegEx.create_from_string(TOKENS).sub(text, "0", true)
	if plain.contains("'"):
		_problems.append("%s : apostrophe droite (’) : %s" % [label, text])
	if plain.contains("..."):
		_problems.append("%s : « ... » au lieu de « … » : %s" % [label, text])
	if plain.contains("  "):
		_problems.append("%s : double espace : %s" % [label, text])
	for i: int in plain.length():
		var character := plain[i]
		var before := plain[i - 1] if i > 0 else ""
		if "!?:;»".contains(character) and not [NBSP, NNBSP, "!", "?"].has(before):
			_problems.append(
				"%s : pas d'espace insécable avant « %s » : %s" % [label, character, text]
			)
		var after := plain[i + 1] if i + 1 < plain.length() else ""
		if character == "«" and not [NBSP, NNBSP].has(after):
			_problems.append("%s : pas d'espace insécable après « « » : %s" % [label, text])


func test_dialogue_typography_and_lengths() -> void:
	var dialogues := _dialogues()
	assert_eq(dialogues.size(), 19, "un dialogue par PNJ de l'acte 1")
	var lines := 0
	for npc_id: String in dialogues:
		for entry: Array in _texts(npc_id, dialogues[npc_id]):
			var text: String = entry[1]
			_check_typography(entry[0], text)
			var limit := MAX_CHOICE if entry[2] else MAX_LINE
			if text.length() > limit:
				_problems.append(
					"%s : %d caractères (%d au plus)" % [entry[0], text.length(), limit]
				)
			lines += 1
		for node: Dictionary in (dialogues[npc_id]["nodes"] as Dictionary).values():
			if (node.get("choices", []) as Array).size() > DialogueRunner.MAX_CHOICES:
				_problems.append("%s : plus de deux choix" % npc_id)
	assert_gt(lines, 300, "toutes les scènes de l'acte 1")
	assert_eq(_problems, [] as Array[String], "\n".join(_problems))


func test_every_node_is_reachable() -> void:
	var dialogues := _dialogues()
	for npc_id: String in dialogues:
		var dialogue: Dictionary = dialogues[npc_id]
		var nodes: Dictionary = dialogue["nodes"]
		var seen := {}
		var queue: Array = (dialogue.get("entries", []) as Array).duplicate()
		queue.append(dialogue["start"])
		while not queue.is_empty():
			var node_id := str(queue.pop_back())
			if seen.has(node_id) or not nodes.has(node_id):
				continue
			seen[node_id] = true
			var node: Dictionary = nodes[node_id]
			if node.get("next") != null:
				queue.append(node["next"])
			for choice: Dictionary in node.get("choices", []):
				if choice.get("next") != null:
					queue.append(choice["next"])
		for node_id: String in nodes:
			if not seen.has(node_id):
				_problems.append("%s/%s : nœud jamais atteint" % [npc_id, node_id])
		var start: Dictionary = nodes[dialogue["start"]]
		if start.has("if"):
			_problems.append("%s : le nœud start doit marcher sans condition" % npc_id)
	assert_eq(_problems, [] as Array[String], "\n".join(_problems))


func test_each_talk_step_has_its_scene_before_the_rest() -> void:
	var dialogues := _dialogues()
	var targets := {}
	for quest: QuestData in QuestData.all():
		for step: QuestStep in quest.steps:
			if step.npc.is_empty():
				continue
			targets[[String(quest.id), String(step.id)]] = String(step.npc)
	assert_gt(targets.size(), 20, "étapes « parler » et « rapporter à » de l'acte 1")
	for key: Array in targets:
		var npc_id: String = targets[key]
		var npc := load("%s/%s.tres" % [NPCS_DIR, npc_id]) as NpcData
		var dialogue_id := npc.dialogue_path.get_file().get_basename() if npc != null else npc_id
		if not dialogues.has(dialogue_id):
			_problems.append("%s/%s : pas de dialogue pour %s" % [key[0], key[1], npc_id])
			continue
		var entries: Array = dialogues[dialogue_id]["entries"]
		var nodes: Dictionary = dialogues[dialogue_id]["nodes"]
		var scene := -1
		var last_scene := -1
		var first_other := entries.size()
		for index: int in entries.size():
			var condition: Variant = (nodes[entries[index]] as Dictionary).get("if", {})
			var step_key: Variant = (condition as Dictionary).get("quest_step")
			var is_scene: bool = step_key is Array and targets.get(step_key, "") == npc_id
			if is_scene:
				last_scene = index
			elif first_other == entries.size():
				first_other = index
			if step_key == key:
				scene = index if scene < 0 else scene
		if scene < 0:
			_problems.append("%s/%s : aucune scène d'entrée chez %s" % [key[0], key[1], npc_id])
		if last_scene > first_other:
			_problems.append("%s : une scène d'étape après « %s »" % [npc_id, entries[first_other]])
	assert_eq(_problems, [] as Array[String], "\n".join(_problems))


func test_the_heroine_is_the_chosen_fairy() -> void:
	var dialogues := _dialogues()
	var tokens := 0
	for npc_id: String in dialogues:
		for entry: Array in _texts(npc_id, dialogues[npc_id]):
			var text: String = entry[1]
			if text.contains("Chtholly"):
				_problems.append("%s : la protagoniste est {player} : %s" % [entry[0], text])
			if text.contains("Seniolis"):
				_problems.append("%s : « Seniorious » : %s" % [entry[0], text])
			tokens += text.count("{player}")
	assert_eq(_problems, [] as Array[String], "\n".join(_problems))
	assert_between(tokens, 1, MAX_PLAYER_TOKENS, "{player} avec parcimonie")


func test_second_speakers_name_their_npc() -> void:
	var dialogues := _dialogues()
	var voices := 0
	for npc_id: String in dialogues:
		var own := load("%s/%s.tres" % [NPCS_DIR, npc_id]) as NpcData
		for node_id: String in dialogues[npc_id]["nodes"]:
			var node: Dictionary = dialogues[npc_id]["nodes"][node_id]
			var label := "%s/%s" % [npc_id, node_id]
			var speaker: Variant = node.get("speaker")
			if node.has(SPEAKER_ID_KEY):
				voices += 1
				var other := load("%s/%s.tres" % [NPCS_DIR, node[SPEAKER_ID_KEY]]) as NpcData
				if other == null:
					_problems.append("%s : PNJ inconnu %s" % [label, node[SPEAKER_ID_KEY]])
				elif speaker != other.display_name:
					_problems.append("%s : speaker « %s » pour %s" % [label, speaker, other.id])
			elif speaker is String and speaker != "" and speaker != own.display_name:
				_problems.append(
					"%s : « %s » sans %s (portrait)" % [label, speaker, SPEAKER_ID_KEY]
				)
	assert_eq(_problems, [] as Array[String], "\n".join(_problems))
	assert_gte(voices, 7, "scènes à plusieurs voix : fièvre, lecture, assaut")
	assert_true(DialogueRunner.NODE_KEYS.has(SPEAKER_ID_KEY), "clé connue du DialogueRunner")


func test_quest_item_and_npc_texts_typography() -> void:
	for quest: QuestData in QuestData.all():
		_check_typography("quête %s, titre" % quest.id, quest.title)
		_check_typography("quête %s, résumé" % quest.id, quest.summary)
		for step: QuestStep in quest.steps:
			var label := "quête %s, étape %s" % [quest.id, step.id]
			_check_typography(label, step.objective)
			_check_typography(label + ", aide", step.hint)
			if step.objective.length() > 60:
				_problems.append("%s : objectif de plus de 60 caractères" % label)
	for file_name: String in ResourceLoader.list_directory(ITEMS_DIR):
		var item := load(ITEMS_DIR.path_join(file_name)) as ItemData
		if item != null:
			_check_typography("objet %s" % item.id, item.display_name)
			_check_typography("objet %s, description" % item.id, item.description)
	for file_name: String in ResourceLoader.list_directory(NPCS_DIR):
		if file_name.ends_with(".tres"):
			var npc := load(NPCS_DIR.path_join(file_name)) as NpcData
			_check_typography("PNJ %s" % npc.id, npc.display_name)
	assert_eq(_problems, [] as Array[String], "\n".join(_problems))
