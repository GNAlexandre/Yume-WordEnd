class_name Pickup
extends Area3D
## Objet à ramasser dans le monde (PLAN.md section 4). Propriétaire : L7.
##
## Structure figée de pickup.tscn : racine Area3D (couche 7 pickup, masque 2 player) du groupe
## "interactable", enfants CollisionShape3D et Mesh. Mesh est le halo (quad face à la caméra,
## rayons qui tournent, teinte ItemData.color) ; son enfant Icon (Sprite3D billboard) montre
## ItemData.icon ; les deux flottent doucement au-dessus de l'origine (posée au sol), où
## Shadow (disque doux) respire avec le flottement.
## Ramassage au contact du joueur (nœud du groupe "player") ou par interact() (invite
## « Ramasser »). collect() : GameState.add_item(), puis GameState.mark_pickup_collected(
## pickup_id()) s'il est persistant, puis EventBus.item_collected, puis queue_free().
## Un pickup persistant déjà pris disparaît à son _ready et à chaque EventBus.game_loaded.
## Les Timeres (L5) en instancient avec persistent = false (objet lâché, non sauvegardé) : il
## apparaît alors avec un petit rebond.

## Icône d'un objet sans données (data/items/<id>.tres absent).
const UNKNOWN_ICON := preload("res://assets/items/unknown.png")
## Largeur de l'icône dans le monde (m).
const ICON_SIZE := 0.6

## Objet donné (ItemData.id).
@export var item_id: StringName:
	set(value):
		item_id = value
		if is_node_ready():
			_apply_item()
## Quantité donnée.
@export var quantity: int = 1
## true : objet unique placé dans une zone, retenu par la sauvegarde (collected_pickups) sous
## son pickup_id (le nom du nœud, unique sur l'île). false : objet lâché par un ennemi.
@export var persistent: bool = true
## Amplitude (m) et période (s) du flottement.
@export var bob_height: float = 0.08
@export var bob_period: float = 2.4

var _collected: bool = false
var _time: float = 0.0
var _rest_height: float = 0.0

@onready var _mesh: MeshInstance3D = $Mesh
@onready var _icon: Sprite3D = $Mesh/Icon
@onready var _shadow: Node3D = $Shadow


func _ready() -> void:
	if persistent:
		if GameState.is_pickup_collected(pickup_id()):
			queue_free()
			return
		EventBus.game_loaded.connect(_on_game_loaded)
	body_entered.connect(_on_body_entered)
	_rest_height = _mesh.position.y
	_time = absf(global_position.x * 0.7 + global_position.z * 0.3)
	_apply_item()
	if not persistent:
		_mesh.scale = Vector3.ONE * 0.2
		var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(_mesh, ^"scale", Vector3.ONE, 0.3)


func _process(delta: float) -> void:
	_time += delta
	var bob := sin(_time * TAU / bob_period)
	_mesh.position.y = _rest_height + bob * bob_height
	_shadow.scale = Vector3.ONE * (1.0 - 0.12 * bob)


## Identifiant de sauvegarde : le nom du nœud.
func pickup_id() -> StringName:
	return StringName(name)


func get_prompt() -> String:
	return "Ramasser"


func interact(_player: Node3D) -> void:
	collect()


## Donne l'objet au joueur et disparaît (une seule fois).
func collect() -> void:
	if _collected or item_id.is_empty() or quantity <= 0:
		return
	_collected = true
	GameState.add_item(item_id, quantity)
	if persistent:
		GameState.mark_pickup_collected(pickup_id())
	EventBus.item_collected.emit(item_id, quantity)
	queue_free()


func _apply_item() -> void:
	var data := ItemData.find(item_id)
	var icon: Texture2D = data.icon if data != null and data.icon != null else UNKNOWN_ICON
	_icon.texture = icon
	_icon.pixel_size = ICON_SIZE / maxf(icon.get_width(), 1.0)
	var material := _mesh.get_active_material(0) as ShaderMaterial
	if data != null and material != null:
		material = material.duplicate() as ShaderMaterial
		material.set_shader_parameter(&"tint", data.color)
		_mesh.material_override = material


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group(&"player"):
		collect()


func _on_game_loaded() -> void:
	if GameState.is_pickup_collected(pickup_id()):
		queue_free()
