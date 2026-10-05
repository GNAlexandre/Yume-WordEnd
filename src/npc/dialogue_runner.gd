class_name DialogueRunner
extends Node
## Déroule un dialogue JSON (format de PLAN.md section 4). Propriétaire : L6.
## Un par PNJ : enfant « DialogueRunner » de npc.tscn ; un seul dialogue à la fois dans le jeu.
##
## Protocole (EventBus) : start() émet dialogue_started puis la première dialogue_line ; la boîte
## de dialogue répond par dialogue_choice_made(index) (-1 = « suite ») ; le runner applique les
## effets du choix, suit "next" et émet la ligne suivante ou dialogue_ended. Seul le runner actif
## est branché sur dialogue_choice_made (le temps de son dialogue).
##
## Format (data/dialogues/<id>.json) :
##   { "id", "start": nœud de départ, "entries": [autres nœuds d'entrée], "nodes": { id: nœud } }
##   nœud : "speaker" (défaut : NpcData.display_name), "text", "if", effets, puis "next" (id du
##     nœud suivant, null ou absent pour finir) ou "choices" : [{ "text", "if", effets, "next" }]
##     (2 au plus ; un choix dont le "if" est faux n'est pas proposé).
##   entrée : premier nœud dont le "if" est vrai parmi "done", "entries" (dans l'ordre) et start.
##   conditions ("if" : objet, toutes doivent être vraies) : "flag" et "not_flag" (un nom ou une
##     liste), "count" [objet, minimum], "quest" [id, état], "best_score" [arène, minimum].
##   effets : "set_flag" (un nom ou une liste), "start_quest" et "complete_quest" (id de quête,
##     via GameState.set_quest_state) ; ceux d'un nœud s'appliquent quand il s'affiche, ceux d'un
##     choix quand il est choisi.
##   textes : {count:objet}, {left:objet:total} (total moins possédés, au moins 0) et
##     {best:arène} sont remplacés par les valeurs de GameState.
## Un fichier invalide (JSON, structure, "next" ou condition inconnus) donne un push_warning
## qui dit pourquoi, et aucun dialogue.

## Nœud d'entrée prioritaire (PLAN.md section 4) : nom réservé, toujours essayé en premier.
const DONE_NODE := "done"
## Nombre de choix que la boîte de dialogue sait afficher.
const MAX_CHOICES := 2
## Clés acceptées dans un "if".
const CONDITION_KEYS: Array[String] = ["flag", "not_flag", "count", "quest", "best_score"]

## Runner dont le dialogue est en cours (un seul à la fois dans le jeu).
static var _active: DialogueRunner = null

var _npc_id: StringName = &""
var _speaker: String = ""
var _nodes: Dictionary = {}
var _node: Dictionary = {}
var _choices: Array[Dictionary] = []
var _running: bool = false


func _exit_tree() -> void:
	# Un PNJ retiré en pleine conversation ne laisse pas le joueur bloqué.
	stop()


func is_running() -> bool:
	return _running


## true si un dialogue est en cours, quel que soit le PNJ.
static func is_any_running() -> bool:
	return is_instance_valid(_active) and _active.is_running()


## Démarre le dialogue du PNJ (NpcData.dialogue_path). Sans effet si un dialogue est déjà en
## cours ; push_warning et aucun signal si le fichier est invalide ou si aucune entrée n'est vraie.
func start(npc: NpcData) -> void:
	if npc == null:
		push_warning("DialogueRunner : start() sans NpcData")
		return
	if is_any_running():
		return
	var dialogue := load_dialogue(npc.dialogue_path)
	if dialogue.is_empty():
		return
	var entry := pick_entry(dialogue)
	if entry.is_empty():
		push_warning("DialogueRunner : aucun nœud d'entrée n'est vrai dans %s" % npc.dialogue_path)
		return
	_npc_id = npc.id
	_speaker = npc.display_name
	_nodes = dialogue["nodes"]
	_running = true
	_active = self
	EventBus.dialogue_choice_made.connect(_on_dialogue_choice_made)
	EventBus.dialogue_started.emit(_npc_id)
	_enter(entry)


## Termine le dialogue en cours (émet dialogue_ended).
func stop() -> void:
	if not _running:
		return
	_running = false
	_nodes = {}
	_node = {}
	_choices.clear()
	if _active == self:
		_active = null
	if EventBus.dialogue_choice_made.is_connected(_on_dialogue_choice_made):
		EventBus.dialogue_choice_made.disconnect(_on_dialogue_choice_made)
	EventBus.dialogue_ended.emit(_npc_id)


# --- Lecture et validation --------------------------------------------------------------------


## Lit et valide un dialogue ; {} (et un push_warning qui dit pourquoi) s'il est invalide.
## Lecture brute puis JSON.parse : un fichier invalide ne produit jamais d'erreur moteur.
static func load_dialogue(path: String) -> Dictionary:
	if path.is_empty():
		push_warning("DialogueRunner : PNJ sans dialogue (NpcData.dialogue_path vide)")
		return {}
	if not FileAccess.file_exists(path):
		push_warning("DialogueRunner : dialogue introuvable : %s" % path)
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		push_warning(
			(
				"DialogueRunner : JSON invalide dans %s, ligne %d : %s"
				% [path, json.get_error_line() + 1, json.get_error_message()]
			)
		)
		return {}
	var problem := validate(json.data)
	if not problem.is_empty():
		push_warning("DialogueRunner : dialogue invalide dans %s : %s" % [path, problem])
		return {}
	return json.data


## Problème de structure d'un dialogue déjà lu, "" s'il est valide.
static func validate(data: Variant) -> String:
	if not data is Dictionary:
		return "la racine doit être un objet"
	var dialogue: Dictionary = data
	var nodes: Variant = dialogue.get("nodes")
	if not nodes is Dictionary or (nodes as Dictionary).is_empty():
		return "« nodes » doit être un objet non vide"
	var problem := _validate_entries(dialogue, nodes)
	for node_id: Variant in nodes:
		if problem.is_empty():
			problem = _validate_node(nodes, str(node_id))
	return problem


## Premier nœud d'entrée dont le "if" est vrai : "done", puis "entries", puis start ("" si aucun).
static func pick_entry(dialogue: Dictionary) -> String:
	var nodes: Dictionary = dialogue.get("nodes", {})
	var candidates: Array = [DONE_NODE]
	var entries: Variant = dialogue.get("entries", [])
	if entries is Array:
		candidates.append_array(entries)
	candidates.append(dialogue.get("start", ""))
	for candidate: Variant in candidates:
		var node: Variant = nodes.get(str(candidate))
		if node is Dictionary and evaluate((node as Dictionary).get("if")):
			return str(candidate)
	return ""


static func _validate_entries(dialogue: Dictionary, nodes: Dictionary) -> String:
	var start_id: Variant = dialogue.get("start")
	if not start_id is String or not nodes.has(start_id):
		return "« start » doit nommer un nœud de « nodes »"
	var entries: Variant = dialogue.get("entries", [])
	if not entries is Array:
		return "« entries » doit être une liste de nœuds"
	for entry: Variant in entries:
		if not entry is String or not nodes.has(entry):
			return "l'entrée %s ne nomme aucun nœud" % [entry]
	return ""


static func _validate_node(nodes: Dictionary, node_id: String) -> String:
	var node: Variant = nodes[node_id]
	if not node is Dictionary:
		return "le nœud « %s » doit être un objet" % node_id
	var where := "nœud « %s »" % node_id
	var problem := _validate_step(nodes, node, where)
	var choices: Variant = (node as Dictionary).get("choices", [])
	if problem.is_empty() and not choices is Array:
		problem = "« choices » du %s doit être une liste" % where
	elif problem.is_empty():
		for choice: Variant in choices:
			if problem.is_empty():
				problem = _validate_step(nodes, choice, "choix du " + where)
	return problem


## Un nœud ou un choix : objet, "if" connu, "next" vers un nœud existant (ou null / "").
static func _validate_step(nodes: Dictionary, step: Variant, where: String) -> String:
	if not step is Dictionary:
		return "chaque élément de « choices » doit être un objet (%s)" % where
	var condition: Variant = (step as Dictionary).get("if")
	if condition != null and not condition is Dictionary:
		return "« if » du %s doit être un objet" % where
	if condition is Dictionary:
		for key: Variant in condition:
			if not CONDITION_KEYS.has(str(key)):
				return "condition inconnue « %s » dans le %s" % [key, where]
	var next: Variant = (step as Dictionary).get("next")
	if next == null or (next is String and ((next as String).is_empty() or nodes.has(next))):
		return ""
	return "« next » du %s ne nomme aucun nœud : %s" % [where, next]


# --- Conditions, effets et textes (testables sans scène) --------------------------------------


## Vrai si la condition d'un "if" est remplie (null = pas de condition, donc vraie). Toutes les
## clés doivent être vraies ; une clé inconnue ou mal formée est fausse (avec un push_warning).
static func evaluate(condition: Variant) -> bool:
	if condition == null:
		return true
	if not condition is Dictionary:
		push_warning(
			"DialogueRunner : condition « if » invalide (objet attendu) : %s" % [condition]
		)
		return false
	for key: Variant in condition:
		if not _test(str(key), (condition as Dictionary)[key]):
			return false
	return true


## Applique les effets d'un nœud ou d'un choix (set_flag, start_quest, complete_quest).
static func apply_effects(step: Dictionary) -> void:
	if step.has("set_flag"):
		var flags := _names(step["set_flag"])
		if flags.is_empty():
			push_warning("DialogueRunner : « set_flag » attend un nom ou une liste de noms")
		for flag: String in flags:
			GameState.set_flag(StringName(flag))
	if step.has("start_quest"):
		GameState.set_quest_state(StringName(str(step["start_quest"])), &"active")
	if step.has("complete_quest"):
		GameState.set_quest_state(StringName(str(step["complete_quest"])), &"done")


## Choix proposés par un nœud : ceux dont le "if" est vrai, MAX_CHOICES au plus.
static func visible_choices(node: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for choice: Variant in node.get("choices", []):
		if choice is Dictionary and evaluate((choice as Dictionary).get("if")):
			result.append(choice)
	if result.size() > MAX_CHOICES:
		push_warning("DialogueRunner : plus de %d choix, les suivants sont ignorés" % MAX_CHOICES)
		result.resize(MAX_CHOICES)
	return result


## Remplace {count:objet}, {left:objet:total} et {best:arène} par les valeurs de GameState.
static func format_text(text: String) -> String:
	if not text.contains("{"):
		return text
	var pattern := RegEx.create_from_string("\\{(count|left|best):([^{}]+)\\}")
	var result := ""
	var cursor := 0
	for found: RegExMatch in pattern.search_all(text):
		result += text.substr(cursor, found.get_start() - cursor)
		result += _placeholder(found.get_string(1), found.get_string(2))
		cursor = found.get_end()
	return result + text.substr(cursor)


static func _test(key: String, value: Variant) -> bool:
	match key:
		"flag":
			return _test_flags(value, true)
		"not_flag":
			return _test_flags(value, false)
		"count", "best_score", "quest":
			return _test_pair(key, value)
	push_warning("DialogueRunner : condition inconnue « %s »" % key)
	return false


## "flag" / "not_flag" : tous les drapeaux nommés présents (expected = true) ou tous absents.
static func _test_flags(value: Variant, expected: bool) -> bool:
	var flags := _names(value)
	if flags.is_empty():
		push_warning("DialogueRunner : drapeau invalide (nom ou liste de noms) : %s" % [value])
		return false
	for flag: String in flags:
		if GameState.has_flag(StringName(flag)) != expected:
			return false
	return true


## "count" [objet, minimum], "best_score" [arène, minimum], "quest" [id, état].
static func _test_pair(key: String, value: Variant) -> bool:
	var pair: Array = value if value is Array else []
	var valid := pair.size() == 2 and pair[0] is String
	if valid and key != "quest":
		valid = pair[1] is int or pair[1] is float
	if not valid:
		push_warning("DialogueRunner : « %s » attend [identifiant, valeur] : %s" % [key, value])
		return false
	var target := StringName(pair[0])
	if key == "quest":
		return GameState.quest_state(target) == StringName(str(pair[1]))
	var amount := GameState.count(target) if key == "count" else GameState.best_score(target)
	return amount >= int(pair[1])


## Un nom, ou une liste de noms ([] si la valeur est mal formée).
static func _names(value: Variant) -> Array[String]:
	var result: Array[String] = []
	var items: Array = value if value is Array else [value]
	for item: Variant in items:
		if not item is String or (item as String).is_empty():
			result.clear()
			break
		result.append(item)
	return result


static func _placeholder(kind: String, arguments: String) -> String:
	var parts := arguments.split(":")
	var item := StringName(parts[0])
	if kind == "count":
		return str(GameState.count(item))
	if kind == "best":
		return str(GameState.best_score(item))
	if parts.size() != 2 or not parts[1].is_valid_int():
		push_warning("DialogueRunner : {left:objet:total} attendu, reçu {left:%s}" % arguments)
		return "{left:%s}" % arguments
	return str(maxi(0, parts[1].to_int() - GameState.count(item)))


# --- Déroulement ------------------------------------------------------------------------------


func _enter(node_id: String) -> void:
	# Un auditeur (quest_updated, dialogue_started…) peut avoir arrêté le dialogue entre-temps.
	if not _running:
		return
	_node = _nodes[node_id]
	apply_effects(_node)
	if not _running:
		return
	_choices = visible_choices(_node)
	var texts: Array[String] = []
	for choice: Dictionary in _choices:
		texts.append(format_text(str(choice.get("text", ""))))
	var speaker := str(_node.get("speaker", _speaker))
	EventBus.dialogue_line.emit(speaker, format_text(str(_node.get("text", ""))), texts)


func _on_dialogue_choice_made(index: int) -> void:
	if not _running:
		return
	var next: Variant = _node.get("next")
	if not _choices.is_empty():
		if index < 0 or index >= _choices.size():
			push_warning("DialogueRunner : choix %d hors limites (%d)" % [index, _choices.size()])
			return
		var choice := _choices[index]
		apply_effects(choice)
		next = choice.get("next")
	if next == null or str(next).is_empty() or not _running:
		stop()
	else:
		_enter(str(next))
