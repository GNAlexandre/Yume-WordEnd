extends Area3D
## (T1) L'écriteau « Plus loin, bientôt » des cartes d'attente (village, colline, sentier,
## forêt profonde), provisoires jusqu'aux lots de la phase 3 (docs/DECISIONS.md, T1). Zone
## d'interaction (couche 6, groupe interactable) de src/world/props/waiting_sign.tscn : on le lit
## comme on parle à un PNJ ; le texte s'affiche dans la boîte de dialogue, sans portrait, par le
## protocole de l'EventBus (dialogue_started, dialogue_line, dialogue_choice_made, dialogue_ended).
## Textes : data/texts/story.json, section « maps/waiting » (DialogueRunner.story_text).

## Identifiant de l'orateur (aucun PNJ de ce nom : pas de portrait).
const SIGN_ID := &"ecriteau"
const TEXT_KEY := "maps/waiting/"

var _reading: bool = false


func _ready() -> void:
	add_to_group(&"interactable")


func get_prompt() -> String:
	return "" if _reading else DialogueRunner.story_text(TEXT_KEY + "prompt", "Lire")


func interact(_player: Node3D) -> void:
	if _reading or DialogueRunner.is_any_running():
		return
	_reading = true
	EventBus.dialogue_choice_made.connect(_on_dialogue_choice_made)
	EventBus.dialogue_started.emit(SIGN_ID)
	var speaker := DialogueRunner.story_text(TEXT_KEY + "speaker", "Écriteau")
	var text := DialogueRunner.story_text(TEXT_KEY + "text", "Plus loin, bientôt.")
	EventBus.dialogue_line.emit(speaker, text, [] as Array[String])


## Vrai pendant la lecture (boîte ouverte).
func is_reading() -> bool:
	return _reading


func _on_dialogue_choice_made(_index: int) -> void:
	_close()


func _exit_tree() -> void:
	_close()


func _close() -> void:
	if not _reading:
		return
	_reading = false
	if EventBus.dialogue_choice_made.is_connected(_on_dialogue_choice_made):
		EventBus.dialogue_choice_made.disconnect(_on_dialogue_choice_made)
	EventBus.dialogue_ended.emit(SIGN_ID)
