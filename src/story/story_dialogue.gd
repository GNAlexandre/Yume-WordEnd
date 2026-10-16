class_name StoryDialogue
extends DialogueRunner
## (E6) Dialogue du récit : un fichier de data/dialogues/<île>/ (format de DialogueRunner : nœuds,
## choix, effets, conditions, speaker_id et portraits) ouvert à un nœud donné, par le protocole
## des dialogues (dialogue_started, dialogue_line, dialogue_ended). Propriétaire : E6.
##
## - Dans une scène : identifiant de dialogue « story_<scène> » (aucun PNJ ne s'arrête pour le
##   joueur), orateur et portrait de chaque nœud par speaker_id.
## - Conversation libre (hors scène) : identifiant = id du PNJ (il s'arrête, joue « parle »),
##   entrée choisie comme d'ordinaire (pick_entry : « done », « entries », puis « start »).

## (X-L2) Le nœud affiché (current_node).
var _current_node: String = ""


## Ouvre le dialogue path au nœud node ; dialogue_id est l'identifiant des signaux ; npc (ou
## null) donne le nom et le portrait par défaut. Faux (rien d'émis) si un dialogue est en cours,
## si le fichier est invalide ou si le nœud manque.
func play(path: String, node: String, dialogue_id: StringName, npc: NpcData = null) -> bool:
	if is_any_running():
		return false
	var dialogue := load_dialogue(path)
	if dialogue.is_empty():
		return false
	if node.is_empty():
		node = pick_entry(dialogue)
	if not (dialogue["nodes"] as Dictionary).has(node):
		push_warning("StoryDialogue : nœud « %s » absent de %s" % [node, path])
		return false
	_npc_id = dialogue_id
	_speaker = npc.display_name if npc != null else ""
	_line_speaker_id = npc.id if npc != null else &""
	_nodes = dialogue["nodes"]
	_running = true
	_active = self
	EventBus.dialogue_choice_made.connect(_on_dialogue_choice_made)
	EventBus.dialogue_started.emit(_npc_id)
	_enter(node)
	return true


## Une séquence passée d'une touche : les effets des nœuds suivis depuis node (par « next ») sont
## appliqués sans rien afficher. (X-L2) choices : un nœud à choix ne l'arrête plus, le premier choix
## proposé est suivi ; ses effets s'appliquent si choice_effects (sinon la clé « skip » de la scène
## les remplace : StorySkip). entered : node est déjà affiché (ses effets appliqués : un dialogue
## passé en pleine réplique). Vrai si un choix qui change l'état (EFFECT_KEYS, l'un des choix
## proposés) a été passé.
static func apply_silently(
	path: String,
	node: String,
	choices: bool = false,
	choice_effects: bool = true,
	entered: bool = false
) -> bool:
	var dialogue := load_dialogue(path)
	if dialogue.is_empty():
		return false
	var nodes: Dictionary = dialogue["nodes"]
	var seen := {}
	var current: Variant = node
	var crossed := false
	while current is String and nodes.has(current) and not seen.has(current):
		seen[current] = true
		var entry: Dictionary = nodes[current]
		if not (entered and current == node):
			apply_effects(entry)
		current = entry.get("next")
		var shown: Array[Dictionary] = []
		if choices:
			shown = visible_choices(entry)
		if shown.is_empty():
			continue
		for choice: Dictionary in shown:
			crossed = crossed or _changes_state(choice)
		if choice_effects:
			apply_effects(shown[0])
		current = shown[0].get("next")
		if current is String and (current as String).is_empty():
			current = null
	return crossed


## (X-L2) Le nœud affiché (« » hors dialogue) : un dialogue passé en pleine réplique reprend là.
func current_node() -> String:
	return _current_node if is_running() else ""


func _enter(node_id: String) -> void:
	_current_node = node_id
	super(node_id)


static func _changes_state(step: Dictionary) -> bool:
	for key: String in EFFECT_KEYS:
		if step.has(key):
			return true
	return false
