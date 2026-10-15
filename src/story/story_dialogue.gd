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


## Une séquence passée d'une touche : les effets des nœuds suivis depuis node (sans choix, par
## « next ») sont appliqués sans rien afficher.
static func apply_silently(path: String, node: String) -> void:
	var dialogue := load_dialogue(path)
	if dialogue.is_empty():
		return
	var nodes: Dictionary = dialogue["nodes"]
	var seen := {}
	var current: Variant = node
	while current is String and nodes.has(current) and not seen.has(current):
		seen[current] = true
		var entry: Dictionary = nodes[current]
		apply_effects(entry)
		current = entry.get("next")
