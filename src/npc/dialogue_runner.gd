class_name DialogueRunner
extends Node
## Déroule un dialogue JSON (format de PLAN.md section 4). Propriétaire : L6.
## Un par PNJ : enfant « DialogueRunner » de npc.tscn.
##
## Protocole (EventBus) : start() émet dialogue_started puis dialogue_line ; la boîte de
## dialogue répond par dialogue_choice_made(index) (-1 = « suite ») ; le runner émet la ligne
## suivante ou dialogue_ended. Seul le runner actif réagit à dialogue_choice_made.
## Squelette du Lot 0 : affiche le nœud de départ puis termine. L6 ajoute nœuds, choix,
## conditions (flag, not_flag, count, quest, best_score) et effets (set_flag, start_quest,
## complete_quest via GameState.set_quest_state).

var _npc_id: StringName = &""
var _running: bool = false


func _ready() -> void:
	EventBus.dialogue_choice_made.connect(_on_dialogue_choice_made)


func is_running() -> bool:
	return _running


## Démarre le dialogue du PNJ (NpcData.dialogue_path).
func start(npc: NpcData) -> void:
	_npc_id = npc.id
	_running = true
	EventBus.dialogue_started.emit(_npc_id)
	var dialogue := _load_dialogue(npc.dialogue_path)
	var nodes: Dictionary = dialogue.get("nodes", {})
	var node: Dictionary = nodes.get(str(dialogue.get("start", "")), {})
	var speaker := str(node.get("speaker", npc.display_name))
	var text := str(node.get("text", "…"))
	var choices: Array[String] = []
	EventBus.dialogue_line.emit(speaker, text, choices)


## Termine le dialogue en cours.
func stop() -> void:
	if not _running:
		return
	_running = false
	EventBus.dialogue_ended.emit(_npc_id)


func _load_dialogue(path: String) -> Dictionary:
	if path.is_empty() or not ResourceLoader.exists(path):
		return {}
	var json := load(path) as JSON
	return json.data if json != null and json.data is Dictionary else {}


func _on_dialogue_choice_made(_index: int) -> void:
	stop()
