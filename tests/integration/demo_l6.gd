extends Node3D
## Démo du Lot 6 : la bibliothécaire, un joueur factice et la boîte de dialogue.
## La conversation démarre seule. La présentation termine la 1re réplique, passe à la question
## puis l'affiche en entier avec ses deux choix ; elle compte les images (et non le temps) pour
## que la capture soit toujours la même :
##   tools/screenshot.sh res://tests/integration/demo_l6.tscn build/shots/l6.png 380
## Ensuite : E, Entrée ou clic pour continuer, flèches (ou ZS) et souris pour choisir ; une fois la
## conversation finie, E la relance (ce qu'elle dit dépend de GameState : quête, pages).

## Images (process) où la présentation termine la 1re réplique, passe à la suivante, puis
## termine la question (≈ 2,5 s, 4,5 s et 5,8 s à 60 images/s).
const PRESENTATION_FRAMES: Array[int] = [150, 270, 350]

## Déroule le début de la conversation tout seul (s'arrête à la question).
@export var presentation: bool = true

var _frame: int = 0

@onready var npc: Npc = $Librarian
@onready var player: Node3D = $Player
@onready var box: DialogueBox = $UI/DialogueBox


func _ready() -> void:
	_talk.call_deferred()


func _process(_delta: float) -> void:
	if not presentation:
		return
	_frame += 1
	if _frame == PRESENTATION_FRAMES[0] and box.is_typing():
		box.complete_line()
	elif _frame == PRESENTATION_FRAMES[1] and box.is_waiting():
		box.advance()
	elif _frame >= PRESENTATION_FRAMES[2]:
		if box.is_typing():
			box.complete_line()
		presentation = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"interact") and not DialogueRunner.is_any_running():
		_talk()


func _talk() -> void:
	npc.interact(player)
