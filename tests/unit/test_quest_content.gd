extends GutTest
## Lot Q, contenu des quêtes : chaque quête de data/quests (et chaque quête d'exemple des tests,
## tests/data/quests) est un JSON valide dont les renvois existent : PNJ (data/npcs, avec un
## dialogue), objets (data/items), ennemis (data/enemies), zones (src/world/zones), arènes
## (data/waves), déclencheurs posés dans un fichier d'emplacement, quêtes prérequises (sans
## cycle) ; chaque quête qui ne démarre pas seule est proposée par un dialogue ; les dialogues
## ne nomment que des quêtes, étapes et objets qui existent. Textes courts pour le HUD.
## À lancer après chaque quête écrite (docs/QUETES.md) :
##   tools/test.sh tests/unit/test_quest_content.gd
## Chaque échec liste tous les problèmes trouvés, avec le fichier en cause.

## Le jeu : ses quêtes ne renvoient qu'à ses propres données.
const GAME := {
	"quests": "res://data/quests",
	"dialogues": ["res://data/dialogues"],
	"npcs": ["res://data/npcs"],
	"placements": ["res://src/npc/placements", "res://src/items/placements"],
}
## Les quêtes d'exemple des tests : leurs PNJ, dialogues et emplacements, puis ceux du jeu.
const FIXTURES := {
	"quests": "res://tests/data/quests",
	"dialogues": ["res://tests/data/dialogues", "res://data/dialogues"],
	"npcs": ["res://tests/data/npcs", "res://data/npcs"],
	"placements":
	["res://tests/data/placements", "res://src/npc/placements", "res://src/items/placements"],
}
## Longueurs maximales (caractères) : titre et objectif tiennent dans le panneau du HUD.
const MAX_TITLE := 40
const MAX_OBJECTIVE := 70
## Quêtes de l'acte 1 (docs/lore/HISTOIRE.md, sections 3.1 et 3.2).
const ACT1_QUESTS: Array[String] = [
	"act1_main",
	"picture_book",
	"special_dessert",
	"flying_laundry",
	"vigil_register",
	"old_clock",
	"forget_me_nots",
]

var _problems: Array[String] = []


func test_game_quests_are_valid_and_their_references_exist() -> void:
	var quests := _check_quests(GAME)
	for quest_id: String in ACT1_QUESTS:
		assert_has(quests.keys(), quest_id, "acte 1 : %s est dans data/quests" % quest_id)
	assert_does_not_have(quests.keys(), "pages", "le livre d'images remplace les pages")
	assert_eq(_problems, [] as Array[String], "\n".join(_problems))


func test_example_quests_are_valid_and_their_references_exist() -> void:
	var quests := _check_quests(FIXTURES)
	for quest_id: String in ["example_patrol", "demo_tour", "demo_followup"]:
		assert_has(quests.keys(), quest_id)
	assert_eq(_problems, [] as Array[String], "\n".join(_problems))


func test_problems_are_reported_with_their_file() -> void:
	var dir := "user://test_quest_content"
	DirAccess.make_dir_recursive_absolute(dir.path_join("quests"))
	DirAccess.make_dir_recursive_absolute(dir.path_join("dialogues"))
	var broken := {
		"id": "broken",
		"title": "Un titre beaucoup trop long pour le panneau du HUD, vraiment",
		"giver": "nobody",
		"requires": {"quests": ["ghost", "loop"]},
		"steps":
		[
			{"id": "a", "type": "collect", "item": "gold", "objective": "Trouver de l'or"},
			{"id": "b", "type": "kill", "enemy": "dragon", "objective": "Vaincre le dragon"},
			{"id": "c", "type": "reach", "zone": "moon", "objective": "Aller sur la lune"},
			{"id": "d", "type": "reach", "trigger": "nowhere", "objective": "Aller nulle part"},
			{"id": "e", "type": "arena", "arena": "colosseum", "wave": 2, "objective": "Arène"},
			{"id": "f", "type": "talk", "npc": "nephren", "objective": "x".repeat(80)},
		],
		"rewards": {"items": {"diamond": 1}},
	}
	var loop := {
		"id": "loop",
		"title": "Boucle",
		"requires": {"quests": ["broken"]},
		"steps": [{"id": "a", "type": "flag", "flag": "x", "objective": "X"}],
	}
	var dialogue := {
		"start": "a",
		"nodes":
		{
			"a":
			{
				"if": {"quest_step": ["loop", "zz"], "count": ["ruby", 1]},
				"start_quest": "loop",
				"advance_quest": ["unknown_quest", "a"],
				"give_item": {"emerald": 2},
				"text": "A.",
			},
		},
	}
	_write(dir.path_join("quests/broken.json"), broken)
	_write(dir.path_join("quests/loop.json"), loop)
	_write(dir.path_join("dialogues/bad.json"), dialogue)
	_check_quests(
		{
			"quests": dir.path_join("quests"),
			"dialogues": [dir.path_join("dialogues")],
			"npcs": ["res://data/npcs"],
			"placements": ["res://src/npc/placements"],
		}
	)
	var report := "\n".join(_problems)
	for expected: String in [
		"quête broken : titre de plus de 40 caractères",
		"giver : PNJ inconnu « nobody »",
		"requires.quests nomme une quête inconnue « ghost »",
		"quête broken : aucun dialogue ne la propose",
		"étape a : objet inconnu « gold »",
		"étape b : ennemi inconnu « dragon »",
		"étape c : zone inconnue « moon »",
		"étape d : déclencheur « nowhere » posé nulle part",
		"étape e : arène inconnue « colosseum »",
		"étape f : objectif de plus de 70 caractères",
		"récompense : objet inconnu « diamond »",
		"elle se requiert elle-même",
		"la quête loop n'a pas d'étape « zz »",
		"condition count : objet inconnu « ruby »",
		"quête inconnue « unknown_quest »",
		"give_item : objet inconnu « emerald »",
	]:
		assert_string_contains(report, expected, false)
	assert_false(report.contains("quête loop : aucun dialogue"), "loop est proposée par bad.json")
	for file: String in ["quests/broken.json", "quests/loop.json", "dialogues/bad.json"]:
		DirAccess.remove_absolute(dir.path_join(file))
	_problems.clear()


func _write(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()


func test_trigger_ids_are_unique_in_the_game() -> void:
	var seen: Dictionary[StringName, String] = {}
	var duplicates: Array[String] = []
	for trigger: Array in _triggers(GAME["placements"]):
		var trigger_id: StringName = trigger[0]
		if seen.has(trigger_id):
			duplicates.append("%s : dans %s et %s" % [trigger_id, seen[trigger_id], trigger[1]])
		seen[trigger_id] = trigger[1]
	assert_eq(duplicates, [] as Array[String], "déclencheurs en double")


# --- Vérifications ------------------------------------------------------------------------------


## Vérifie toutes les quêtes d'un ensemble (jeu ou exemples) ; les problèmes vont dans _problems.
## Renvoie les quêtes lues : id → données JSON.
func _check_quests(where: Dictionary) -> Dictionary:
	_problems.clear()
	var quests := {}
	var dir: String = where["quests"]
	for file_name: String in DirAccess.get_files_at(dir):
		if not file_name.ends_with(".json"):
			continue
		var path := dir.path_join(file_name)
		var json := JSON.new()
		if json.parse(FileAccess.get_file_as_string(path)) != OK:
			_problems.append("%s : JSON invalide, ligne %d" % [path, json.get_error_line() + 1])
			continue
		var problem := QuestData.problem(json.data, file_name.get_basename())
		if not problem.is_empty():
			_problems.append("%s : %s" % [path, problem])
			continue
		quests[file_name.get_basename()] = json.data
	var known_quests := quests.keys()
	if dir != GAME["quests"]:
		known_quests.append_array(_quest_ids(GAME["quests"]))
	var triggers := {}
	for trigger: Array in _triggers(where["placements"]):
		triggers[String(trigger[0])] = true
	var dialogues := _dialogues(where["dialogues"])
	var started := _started_quests(dialogues)
	for quest_id: String in quests:
		_check_quest(quests[quest_id], where, known_quests, triggers, started)
	_check_cycles(quests)
	for path: String in dialogues:
		_check_dialogue(path, dialogues[path], quests, known_quests)
	return quests


func _check_quest(
	quest: Dictionary,
	where: Dictionary,
	known_quests: Array,
	triggers: Dictionary,
	started: Dictionary
) -> void:
	var label := "quête %s" % quest["id"]
	if (quest["title"] as String).length() > MAX_TITLE:
		_problems.append("%s : titre de plus de %d caractères" % [label, MAX_TITLE])
	if quest.has("giver"):
		_check_npc(label + ", giver", quest["giver"], where)
	for required: Variant in QuestStep.read_names(_dig(quest, ["requires", "quests"], [])):
		if not known_quests.has(String(required)):
			_problems.append(
				"%s : requires.quests nomme une quête inconnue « %s »" % [label, required]
			)
	if not quest.get("auto_start", false) and not started.has(quest["id"]):
		_problems.append(
			"%s : aucun dialogue ne la propose (start_quest), et elle n'a pas auto_start" % label
		)
	_check_rewards(label, quest.get("rewards", {}))
	for step: Dictionary in quest["steps"]:
		_check_step("%s, étape %s" % [label, step["id"]], step, where, triggers)


func _check_step(label: String, step: Dictionary, where: Dictionary, triggers: Dictionary) -> void:
	if (step["objective"] as String).length() > MAX_OBJECTIVE:
		_problems.append("%s : objectif de plus de %d caractères" % [label, MAX_OBJECTIVE])
	if step.has("npc"):
		_check_npc(label, step["npc"], where)
	if step.has("item"):
		_check_item(label, step["item"])
	if step.has("enemy") and step["enemy"] != "any":
		if not ResourceLoader.exists("res://data/enemies/%s.tres" % step["enemy"]):
			_problems.append("%s : ennemi inconnu « %s » (data/enemies)" % [label, step["enemy"]])
	if step.has("zone"):
		var zone_path := "res://src/world/zones/{0}/{0}.tscn".format([step["zone"]])
		if not ResourceLoader.exists(zone_path):
			_problems.append("%s : zone inconnue « %s »" % [label, step["zone"]])
	if step.has("trigger") and not triggers.has(step["trigger"]):
		_problems.append(
			(
				"%s : déclencheur « %s » posé nulle part (src/npc/placements/<zone>.tscn)"
				% [label, step["trigger"]]
			)
		)
	if step.has("arena") and not FileAccess.file_exists("res://data/waves/%s.json" % step["arena"]):
		_problems.append("%s : arène inconnue « %s » (data/waves)" % [label, step["arena"]])
	_check_rewards(label, step.get("rewards", {}))


func _check_rewards(label: String, rewards: Dictionary) -> void:
	for item_id: Variant in rewards.get("items", {}):
		_check_item(label + ", récompense", item_id)


func _check_npc(label: String, npc_id: Variant, where: Dictionary) -> void:
	var npc := _find_npc(StringName(str(npc_id)), where["npcs"])
	if npc == null:
		_problems.append("%s : PNJ inconnu « %s » (data/npcs)" % [label, npc_id])
	elif npc.dialogue_path.is_empty():
		_problems.append("%s : le PNJ « %s » n'a pas de dialogue" % [label, npc_id])


## PNJ d'identifiant npc_id : <dossier>/<id>.tres d'abord, sinon une fiche du dossier qui porte
## cet id (une fiche dont le nom de fichier diffère de son id).
func _find_npc(npc_id: StringName, dirs: Array) -> NpcData:
	for dir: String in dirs:
		var path := dir.path_join("%s.tres" % npc_id)
		if ResourceLoader.exists(path):
			return load(path) as NpcData
	for dir: String in dirs:
		for file_name: String in DirAccess.get_files_at(dir):
			if file_name.ends_with(".tres"):
				var npc := load(dir.path_join(file_name)) as NpcData
				if npc != null and npc.id == npc_id:
					return npc
	return null


func _check_item(label: String, item_id: Variant) -> void:
	if ItemData.find(StringName(str(item_id))) == null:
		_problems.append("%s : objet inconnu « %s » (data/items)" % [label, item_id])


## Aucune quête ne se requiert elle-même, même par un détour (A → B → A).
func _check_cycles(quests: Dictionary) -> void:
	for quest_id: String in quests:
		var seen := {quest_id: true}
		var queue: Array = QuestStep.read_names(_dig(quests[quest_id], ["requires", "quests"], []))
		while not queue.is_empty():
			var next := String(queue.pop_back())
			if next == quest_id:
				_problems.append(
					"quête %s : elle se requiert elle-même (cycle de prérequis)" % quest_id
				)
				break
			if seen.has(next) or not quests.has(next):
				continue
			seen[next] = true
			queue.append_array(QuestStep.read_names(_dig(quests[next], ["requires", "quests"], [])))


## Quêtes, étapes et objets nommés par un dialogue.
func _check_dialogue(path: String, dialogue: Dictionary, quests: Dictionary, known: Array) -> void:
	for node_id: Variant in dialogue.get("nodes", {}):
		var node: Dictionary = dialogue["nodes"][node_id]
		var steps: Array[Dictionary] = [node]
		for choice: Variant in node.get("choices", []):
			steps.append(choice as Dictionary)
		for step: Dictionary in steps:
			_check_dialogue_step("%s, nœud %s" % [path, node_id], step, quests, known)


func _check_dialogue_step(
	label: String, step: Dictionary, quests: Dictionary, known: Array
) -> void:
	var condition: Dictionary = step.get("if", {}) if step.get("if") is Dictionary else {}
	var quest_refs: Array = []
	if _is_pair(condition.get("quest")):
		quest_refs.append([condition["quest"][0], ""])
	if _is_pair(condition.get("quest_step")):
		quest_refs.append(condition["quest_step"])
	for key: String in ["start_quest", "complete_quest"]:
		if step.has(key):
			quest_refs.append([step[key], ""])
	if step.has("advance_quest"):
		var target: Variant = step["advance_quest"]
		quest_refs.append(target if _is_pair(target) else [target, ""])
	for ref: Array in quest_refs:
		var quest_id := str(ref[0])
		if not known.has(quest_id) and not quests.has(quest_id):
			# Une quête du jeu nommée par un dialogue d’exemple est permise (ex. picture_book).
			_problems.append("%s : quête inconnue « %s »" % [label, quest_id])
			continue
		var step_id := str(ref[1])
		if not step_id.is_empty() and quests.has(quest_id):
			var ids: Array = (quests[quest_id]["steps"] as Array).map(
				func(s: Dictionary) -> String: return s["id"]
			)
			if not ids.has(step_id):
				_problems.append(
					"%s : la quête %s n'a pas d'étape « %s »" % [label, quest_id, step_id]
				)
	if _is_pair(condition.get("count")):
		_check_item(label + ", condition count", condition["count"][0])
	for key: String in ["give_item", "take_item"]:
		if step.has(key):
			var value: Variant = step[key]
			var item_ids: Array = []
			if value is String:
				item_ids = [value]
			elif value is Array:
				item_ids = [value[0]]
			elif value is Dictionary:
				item_ids = (value as Dictionary).keys()
			for item_id: Variant in item_ids:
				_check_item("%s, %s" % [label, key], item_id)


# --- Lecture ------------------------------------------------------------------------------------


func _quest_ids(dir: String) -> Array:
	var ids: Array = []
	for file_name: String in DirAccess.get_files_at(dir):
		if file_name.ends_with(".json"):
			ids.append(file_name.get_basename())
	return ids


## Dialogues valides des dossiers : chemin → dialogue (un dialogue invalide est un problème).
func _dialogues(dirs: Array) -> Dictionary:
	var result := {}
	for dir: String in dirs:
		for file_name: String in DirAccess.get_files_at(dir):
			if not file_name.ends_with(".json"):
				continue
			var path := dir.path_join(file_name)
			var json := JSON.new()
			if json.parse(FileAccess.get_file_as_string(path)) != OK:
				_problems.append("%s : JSON invalide" % path)
				continue
			var problem := DialogueRunner.validate(json.data)
			if not problem.is_empty():
				_problems.append("%s : %s" % [path, problem])
				continue
			result[path] = json.data
	return result


## Quêtes proposées par un dialogue (start_quest d'un nœud ou d'un choix).
func _started_quests(dialogues: Dictionary) -> Dictionary:
	var started := {}
	for path: String in dialogues:
		for node: Variant in (dialogues[path]["nodes"] as Dictionary).values():
			var steps: Array = [node]
			steps.append_array((node as Dictionary).get("choices", []))
			for step: Variant in steps:
				if (step as Dictionary).has("start_quest"):
					started[str(step["start_quest"])] = true
	return started


## Déclencheurs posés dans les fichiers d'emplacement : [[trigger_id, fichier], …].
func _triggers(dirs: Array) -> Array[Array]:
	var result: Array[Array] = []
	for dir: String in dirs:
		for file_name: String in DirAccess.get_files_at(dir):
			if not file_name.ends_with(".tscn"):
				continue
			var path := dir.path_join(file_name)
			var root := (load(path) as PackedScene).instantiate()
			for node: Node in root.find_children("*", "Area3D", true, false):
				if node is QuestTrigger:
					result.append([(node as QuestTrigger).id(), path])
			root.free()
	return result


func _is_pair(value: Variant) -> bool:
	return value is Array and (value as Array).size() == 2


func _dig(data: Dictionary, keys: Array, default: Variant) -> Variant:
	var value: Variant = data
	for key: String in keys:
		if not value is Dictionary or not (value as Dictionary).has(key):
			return default
		value = value[key]
	return value
