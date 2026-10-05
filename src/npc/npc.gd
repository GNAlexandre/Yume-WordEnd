class_name Npc
extends CharacterBody3D
## Personnage non joueur (PLAN.md section 4). Propriétaire : L6.
##
## Structure figée de npc.tscn : racine CharacterBody3D (couche 1 world) du groupe
## "interactable", enfants CollisionShape3D, Visual (CharacterVisual), InteractArea (Area3D,
## couche 6 interactable : c'est elle que détecte le joueur) et DialogueRunner.

## Données du PNJ (data/npcs/*.tres).
@export var data: NpcData

@onready var visual: CharacterVisual = $Visual
@onready var runner: DialogueRunner = $DialogueRunner


func _ready() -> void:
	if data != null and data.skin != null:
		visual.set_skin(data.skin)


func get_prompt() -> String:
	return "Parler"


func interact(_player: Node3D) -> void:
	if data != null and not runner.is_running():
		runner.start(data)
