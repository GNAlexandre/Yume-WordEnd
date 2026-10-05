extends Node3D
## Interactable factice du Lot 1 (pas de class_name) : racine du groupe "interactable" dont
## l'enfant Area3D « Zone » (couche 6 interactable) est ce que détecte le joueur, comme un PNJ.
## Retient les joueurs qui ont interagi ; avec dialogue_seconds > 0, simule un dialogue
## (dialogue_started, puis dialogue_ended après ce délai) pour la démo.

## Invite renvoyée par get_prompt().
@export var prompt: String = "Examiner"
## Durée du faux dialogue lancé par interact() (0 : aucun).
@export var dialogue_seconds: float = 0.0

## Joueurs passés à interact(), dans l'ordre.
var interactions: Array[Node3D] = []


func get_prompt() -> String:
	return prompt


func interact(player: Node3D) -> void:
	interactions.append(player)
	if dialogue_seconds <= 0.0:
		return
	EventBus.dialogue_started.emit(StringName(name))
	await get_tree().create_timer(dialogue_seconds, false).timeout
	EventBus.dialogue_ended.emit(StringName(name))
