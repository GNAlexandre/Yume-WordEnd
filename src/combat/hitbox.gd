class_name Hitbox
extends Area3D
## Zone qui inflige une attaque (couche 4 hitbox, masque 5 hurtbox). Propriétaire : L4.
##
## Inactive par défaut. Le propriétaire l'active sur les images « coup » de l'animation
## (CharacterVisual.frame_changed + hit_frames) et la désactive ensuite. Pendant une
## activation, chaque Hurtbox d'une autre équipe n'est touchée qu'une fois (comme jeu.js).

signal hit_landed(hurtbox: Hurtbox)

## Attaque appliquée (data/attacks/*.tres).
@export var attack: AttackData
## Équipe de l'attaquant (&"player" ou &"enemy").
@export var team: StringName = &""

## Attaquant transmis à Health.take_damage ; par défaut le propriétaire de la scène (owner).
var source: Node3D

var _active: bool = false
var _already_hit: Array[Hurtbox] = []


## Démarre une activation : la liste des cibles déjà touchées est vidée.
func activate() -> void:
	_already_hit.clear()
	_active = true


func deactivate() -> void:
	_active = false


func is_active() -> bool:
	return _active


func _physics_process(_delta: float) -> void:
	if not _active or attack == null:
		return
	var attacker := source if source != null else owner as Node3D
	for area: Area3D in get_overlapping_areas():
		var hurtbox := area as Hurtbox
		if hurtbox == null or hurtbox.team == team or _already_hit.has(hurtbox):
			continue
		_already_hit.append(hurtbox)
		if hurtbox.receive_hit(attack, attacker):
			hit_landed.emit(hurtbox)
