extends CharacterBody3D
## (U1) Joueur factice des signes d'interaction (groupe player, sans class_name) : expose
## current_interactable() comme Player, et la liste des cibles à portée que le vrai joueur tire
## du groupe « interactable » proches de lui (interactables_in_range).

## Cible de l'interaction (null : aucune).
var target: Node3D
## Cibles à portée (signes pâles).
var in_range: Array[Node3D] = []


func _enter_tree() -> void:
	add_to_group(&"player")


func current_interactable() -> Node3D:
	return target if is_instance_valid(target) else null


func interactables_in_range() -> Array[Node3D]:
	return in_range
