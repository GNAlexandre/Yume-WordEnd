class_name QuestTrigger
extends Area3D
## Déclencheur de lieu (Lot Q) : src/quests/quest_trigger.tscn, à poser dans le fichier
## d'emplacement d'une zone, src/npc/placements/<zone>.tscn (coordonnées locales à la zone).
## Quand le joueur (groupe player, couche 2) y entre, pose set_flag s'il est donné puis émet
## EventBus.trigger_entered(trigger_id) : le QuestTracker valide les étapes « reach » qui le
## nomment. Si une étape qui le nomme devient l'étape courante alors que le joueur est déjà
## dedans, il se redéclenche (pas besoin de ressortir). Volume : cylindre vertical de radius m et
## height m posé sur le sol (forme propre à chaque déclencheur). Mode d'emploi : docs/QUETES.md.

const PLAYER_GROUP := &"player"
## Couche « player » (2) : seul le joueur est détecté.
const PLAYER_MASK := 2

## Identifiant nommé par les étapes reach ("trigger") ; vide : le nom du nœud.
@export var trigger_id: StringName = &""
## Rayon (m) et hauteur (m) du cylindre.
@export var radius: float = 2.0:
	set(value):
		radius = maxf(value, 0.1)
		_apply_shape()
@export var height: float = 3.0:
	set(value):
		height = maxf(value, 0.1)
		_apply_shape()
## Drapeau posé (à vrai) chaque fois que le joueur entre ; vide : aucun.
@export var set_flag: StringName = &""

@onready var _shape_node: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	collision_layer = 0
	collision_mask = PLAYER_MASK
	monitorable = false
	_shape_node.shape = (_shape_node.shape as CylinderShape3D).duplicate()
	_apply_shape()
	body_entered.connect(_on_body_entered)
	EventBus.quest_step_updated.connect(_on_quest_step_updated)


## Identifiant effectif (trigger_id, sinon le nom du nœud).
func id() -> StringName:
	return trigger_id if not trigger_id.is_empty() else StringName(name)


## Vrai si le joueur est dedans (au moins une image physique après son entrée).
func has_player() -> bool:
	for body: Node3D in get_overlapping_bodies():
		if body.is_in_group(PLAYER_GROUP):
			return true
	return false


func _apply_shape() -> void:
	if not is_node_ready():
		return
	var cylinder := _shape_node.shape as CylinderShape3D
	cylinder.radius = radius
	cylinder.height = height
	_shape_node.position = Vector3(0.0, height * 0.5, 0.0)


func _fire() -> void:
	if not set_flag.is_empty():
		GameState.set_flag(set_flag)
	EventBus.trigger_entered.emit(id())


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group(PLAYER_GROUP):
		_fire()


func _on_quest_step_updated(quest_id: StringName, step_id: StringName, _count: int) -> void:
	if step_id.is_empty() or not has_player():
		return
	var quest := QuestData.find(quest_id)
	var step := quest.find_step(step_id) if quest != null else null
	if step != null and step.type == QuestStep.REACH and step.trigger == id():
		# Après le traitement en cours du QuestTracker (qui a annoncé cette étape).
		_fire.call_deferred()
