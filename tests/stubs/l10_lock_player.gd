extends Node3D
## Joueur factice du Lot 10 (groupe player, sans class_name) : expose locked_target() comme
## Player (L1), pour le marqueur de cible du HUD dans les tests et la démo.

## Cible verrouillée renvoyée par locked_target() (null : aucune).
var target: Node3D


func _enter_tree() -> void:
	add_to_group(&"player")


func locked_target() -> Node3D:
	return target if is_instance_valid(target) else null
