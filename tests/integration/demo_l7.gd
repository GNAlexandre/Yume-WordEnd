extends Node3D
## Démo du Lot 7 : objets flottants autour d'un joueur factice et inventaire ouvert avec des
## objets (capture : tools/screenshot.sh res://tests/integration/demo_l7.tscn
## build/shots/l7.png). Jouable dans l'éditeur (F6) : actions move_* pour marcher, ramassage
## au contact ou avec interact (E / A), inventory (I / Y) pour ouvrir et fermer l'inventaire.
## Repart d'une partie neuve (GameState.reset()) remplie avec starting_items.

## Objets donnés au lancement, pour que l'inventaire ne soit pas vide.
@export var starting_items: Dictionary[StringName, int] = {
	&"page_fragment": 2, &"shell": 1, &"flower_blue": 3, &"bookmark": 1
}
## Ouvre l'inventaire au lancement (capture).
@export var open_inventory_on_start: bool = true
## Vitesse du joueur factice (m/s) et portée de l'action interact (m).
@export var speed: float = 4.0
@export var interact_range: float = 1.6

var _camera_offset: Vector3

@onready var _player: CharacterBody3D = $Player
@onready var _camera: Camera3D = $Camera3D
@onready var _inventory: Control = $UI/Inventory
@onready var _prompt: Label = $UI/Prompt


func _ready() -> void:
	GameState.reset()
	for item_id: StringName in starting_items:
		GameState.add_item(item_id, starting_items[item_id])
	var visual := _player.get_node_or_null(^"Visual")
	if visual != null and visual.has_method(&"set_skin"):
		visual.call(&"set_skin", SkinRegistry.default_skin())
	_camera_offset = _camera.global_position - _player.global_position
	if open_inventory_on_start:
		_inventory.call(&"open")


func _physics_process(_delta: float) -> void:
	var input := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	_player.velocity = Vector3(input.x, 0.0, input.y) * speed
	_player.move_and_slide()
	_camera.global_position = _player.global_position + _camera_offset
	var target := _nearest_interactable()
	_prompt.text = "E / A : %s" % target.call(&"get_prompt") if target != null else ""


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"interact"):
		var target := _nearest_interactable()
		if target != null:
			target.call(&"interact", _player)


func _nearest_interactable() -> Node3D:
	var best: Node3D = null
	var best_distance := interact_range
	for node: Node in get_tree().get_nodes_in_group(&"interactable"):
		var candidate := node as Node3D
		if candidate == null or candidate.is_queued_for_deletion():
			continue
		var distance := candidate.global_position.distance_to(_player.global_position)
		if distance <= best_distance:
			best = candidate
			best_distance = distance
	return best
