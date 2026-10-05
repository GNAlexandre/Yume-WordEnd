class_name Pickup
extends Area3D
## Objet à ramasser dans le monde (PLAN.md section 4). Propriétaire : L7.
##
## Structure figée de pickup.tscn : racine Area3D (couche 7 pickup, masque 2 player) du groupe
## "interactable", enfants CollisionShape3D et Mesh. collect() : GameState.add_item(), marque
## l'objet comme pris (s'il est persistant), émet EventBus.item_collected, puis disparaît.
## Un pickup persistant déjà pris (GameState.is_pickup_collected) disparaît à son _ready.

## Objet donné (ItemData.id).
@export var item_id: StringName
## Quantité donnée.
@export var quantity: int = 1
## true : objet unique placé dans une zone, retenu par la sauvegarde (collected_pickups) sous
## son pickup_id (le nom du nœud, unique sur l'île). false : objet lâché par un ennemi.
@export var persistent: bool = true


func _ready() -> void:
	if persistent and GameState.is_pickup_collected(pickup_id()):
		queue_free()


## Identifiant de sauvegarde : le nom du nœud.
func pickup_id() -> StringName:
	return StringName(name)


func get_prompt() -> String:
	return "Ramasser"


func interact(_player: Node3D) -> void:
	collect()


func collect() -> void:
	if item_id.is_empty() or is_queued_for_deletion():
		return
	GameState.add_item(item_id, quantity)
	if persistent:
		GameState.mark_pickup_collected(pickup_id())
	EventBus.item_collected.emit(item_id, quantity)
	queue_free()
