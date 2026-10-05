class_name Hitbox
extends Area3D
## Zone qui inflige une attaque (couche 4 hitbox, masque 5 hurtbox). Propriétaire : L4.
##
## Inactive par défaut. Le propriétaire l'active sur les images « coup » de l'animation
## (CharacterVisual.frame_changed + hit_frames) et la désactive ensuite. Pendant une
## activation, chaque Hurtbox d'une autre équipe n'est touchée qu'une fois (comme jeu.js) :
## la liste des touchés n'est vidée que par activate(). Un coup refusé par la cible (joueur
## invincible) n'entre pas dans la liste : il peut encore porter pendant la même activation,
## comme dans jeu.js où le Timere ne « touche » que si le joueur n'est plus invincible.

signal hit_landed(hurtbox: Hurtbox)

## Pas angulaire maximal entre deux points de l'arc d'un secteur, en degrés.
const SECTOR_STEP_DEG := 12.0

## Attaque appliquée (data/attacks/*.tres).
@export var attack: AttackData
## Équipe de l'attaquant (&"player" ou &"enemy").
@export var team: StringName = &""

## Attaquant transmis à Health.take_damage ; par défaut le propriétaire de la scène (owner).
var source: Node3D

var _active: bool = false
var _already_hit: Array[Hurtbox] = []


## Points d'un secteur horizontal extrudé (prisme convexe) : pointe à l'origine, ouvert vers
## -Z, de rayon radius, d'ouverture arc_deg (bornée à 180° pour rester convexe) et de hauteur
## height centrée sur y = 0.
static func sector_points(radius: float, arc_deg: float, height: float) -> PackedVector3Array:
	var points := PackedVector3Array()
	var arc := clampf(arc_deg, 1.0, 180.0)
	var half := deg_to_rad(arc) / 2.0
	var segments := maxi(2, ceili(arc / SECTOR_STEP_DEG))
	for y: float in [-height / 2.0, height / 2.0]:
		points.append(Vector3(0.0, y, 0.0))
		for i in segments + 1:
			var angle := -half + 2.0 * half * i / segments
			points.append(Vector3(sin(angle) * radius, y, -cos(angle) * radius))
	return points


## Démarre une activation : la liste des cibles déjà touchées est vidée.
func activate() -> void:
	_already_hit.clear()
	_active = true


## Reprend l'activation en cours sans vider la liste des touchés (images « coup » non
## contiguës d'une même attaque).
func resume() -> void:
	_active = true


func deactivate() -> void:
	_active = false


func is_active() -> bool:
	return _active


## Remplace la forme par un secteur (épée : 90° × 1,2 m) dont la pointe est en apex
## (coordonnées locales de la Hitbox), ouvert vers -Z, de hauteur height centrée sur apex.y.
func set_sector_shape(apex: Vector3, radius: float, arc_deg: float, height: float) -> void:
	var collision := get_node_or_null(^"CollisionShape3D") as CollisionShape3D
	if collision == null or radius <= 0.0 or height <= 0.0:
		return
	var to_shape := collision.transform.affine_inverse()
	var points := PackedVector3Array()
	for point: Vector3 in sector_points(radius, arc_deg, height):
		points.append(to_shape * (apex + point))
	var shape := ConvexPolygonShape3D.new()
	shape.points = points
	collision.shape = shape


func _physics_process(_delta: float) -> void:
	if not _active or attack == null:
		return
	var attacker := source if is_instance_valid(source) else owner as Node3D
	for area: Area3D in get_overlapping_areas():
		var hurtbox := area as Hurtbox
		if hurtbox == null or hurtbox.team == team or _already_hit.has(hurtbox):
			continue
		if hurtbox.receive_hit(attack, attacker):
			_already_hit.append(hurtbox)
			hit_landed.emit(hurtbox)
