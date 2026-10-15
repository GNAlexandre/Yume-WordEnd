@tool
class_name Ship
extends Node3D
## (E7) Navire volant en volume (docs/REFONTE.md, 7, lot E7) : un assemblage de panneaux, comme
## les bâtiments, racine des scènes de src/world/props/ships/<id>.tscn. Origine : la quille, au
## milieu du flanc sud (le bas de l'image du flanc), proue à l'est. Propriétaire : E7.
##
## Enfants nommés (la scène les pose ; tous facultatifs sauf Hull) :
## - Hull : le flanc face à la caméra (DecorPanel, ships/<id>_side, moyeux nus) ;
## - Deck : le pont vu de dessus, couché à la hauteur du pont et tiré vers le nord (DecorPanel à
##   plat, keep_orientation) ; la caméra le voit derrière le bastingage du flanc ;
## - Rotors : ses enfants ShipStrip (bandes du rotor, posées sur les moyeux du flanc) ;
## - Hatch : la trappe (ShipStrip, bande non bouclée : 0 fermée → dernière image ouverte) ;
## - Searchlight : le cône du projecteur (ShipStrip à alpha doux, sous la coque), et Glare :
##   l'éblouissement devant la coque, qui en cache la silhouette tant que le projecteur aveugle ;
## - Gangway : la passerelle, pivot au seuil de la trappe ; son enfant Ramp (Building, le plancher
##   tiré vers le sud) et sa collision Collision (StaticBody3D, couche 1, active une fois
##   déployée) ;
## - Collision : la coque (StaticBody3D, couche 1).
## Le navire ne s'anime pas seul : son poste d'amarrage (ShipBerth) ou le récit (ShipControl) le
## pilote par set_flight, set_rotor_speed, set_hatch, set_gangway et set_searchlight. Les données
## (vitesses, durées, hauteurs) sont dans data/ships/<ship_id>.json (ShipControl.data).

## Identifiant du navire (data/ships/<ship_id>.json).
@export var ship_id: StringName = &""
## Longueur (m) et pente de la passerelle déployée : du seuil de la trappe au quai.
@export var gangway_length: float = 3.4
@export var gangway_drop: float = 1.0

var _rest := Transform3D.IDENTITY
var _rest_known: bool = false
var _rotor_speed: float = 0.0
var _hatch_open: float = 0.0
var _gangway: float = 0.0


func _ready() -> void:
	_remember_rest()
	set_gangway(0.0)
	set_searchlight(0.0)
	set_hatch(0.0)
	set_physics_process(not Engine.is_editor_hint())


func _physics_process(delta: float) -> void:
	for rotor in rotors():
		rotor.speed = _rotor_speed
		rotor.advance(delta)


## Place de repos (amarré) dans le repère du parent : celle de la scène.
func rest_transform() -> Transform3D:
	_remember_rest()
	return _rest


## Écart au repos : déplacement (m, repère du parent) et roulis (degrés, autour de l'axe nord-sud :
## positif, la proue s'abaisse).
func set_flight(offset: Vector3, roll_degrees: float = 0.0) -> void:
	_remember_rest()
	var roll := Basis(Vector3.BACK, deg_to_rad(-roll_degrees))
	transform = Transform3D(_rest.basis * roll, _rest.origin + offset)


## Écart actuel au repos (m).
func flight_offset() -> Vector3:
	_remember_rest()
	return position - _rest.origin


## Rotors : vitesse de la bande (images par seconde ; 0 : arrêtés).
func set_rotor_speed(frames_per_second: float) -> void:
	_rotor_speed = maxf(frames_per_second, 0.0)
	for rotor in rotors():
		rotor.speed = _rotor_speed


func rotor_speed() -> float:
	return _rotor_speed


func rotors() -> Array[ShipStrip]:
	var found: Array[ShipStrip] = []
	var holder := get_node_or_null(^"Rotors")
	if holder != null:
		for child: Node in holder.get_children():
			if child is ShipStrip:
				found.append(child as ShipStrip)
	return found


## Trappe : 0 fermée, 1 grande ouverte (l'image de la bande).
func set_hatch(amount: float) -> void:
	_hatch_open = clampf(amount, 0.0, 1.0)
	var hatch := get_node_or_null(^"Hatch") as ShipStrip
	if hatch != null:
		hatch.frame = roundi(_hatch_open * float(hatch.frames - 1))


func hatch_amount() -> float:
	return _hatch_open


## Passerelle : 0 rentrée (cachée dans la coque), 0,5 sortie à l'horizontale, 1 posée sur le quai.
## Sa collision ne sert qu'une fois posée.
func set_gangway(amount: float) -> void:
	_gangway = clampf(amount, 0.0, 1.0)
	var gangway := get_node_or_null(^"Gangway") as Node3D
	if gangway == null:
		return
	var slide := minf(_gangway * 2.0, 1.0)
	var tilt := maxf(_gangway * 2.0 - 1.0, 0.0)
	var angle := atan2(gangway_drop, gangway_length) * tilt
	var ramp := gangway.get_node_or_null(^"Ramp") as Node3D
	if ramp != null:
		ramp.position.z = -gangway_length * (1.0 - slide)
	gangway.rotation = Vector3(angle, 0.0, 0.0)
	gangway.visible = _gangway > 0.001
	var body := gangway.get_node_or_null(^"Collision") as CollisionObject3D
	if body != null:
		body.collision_layer = 1 if is_equal_approx(_gangway, 1.0) else 0


func gangway_amount() -> float:
	return _gangway


## Projecteur : opacité du cône et de l'éblouissement (0 : éteint).
func set_searchlight(amount: float) -> void:
	for part: NodePath in [^"Searchlight", ^"Glare"]:
		var light := get_node_or_null(part) as ShipStrip
		if light != null:
			light.opacity = amount
			light.visible = amount > 0.001


## Présent ou parti : caché, sans collision ni défilement.
func set_present(present: bool) -> void:
	visible = present
	var body := get_node_or_null(^"Collision") as CollisionObject3D
	if body != null:
		body.collision_layer = 1 if present else 0
	set_physics_process(present and not Engine.is_editor_hint())
	if not present:
		set_gangway(0.0)


## Haut de la passerelle (seuil de la trappe), repère du monde.
func gangway_top() -> Vector3:
	var gangway := get_node_or_null(^"Gangway") as Node3D
	return gangway.global_position if gangway != null else global_position


## Pied de la passerelle déployée, repère du monde.
func gangway_foot() -> Vector3:
	var gangway := get_node_or_null(^"Gangway") as Node3D
	if gangway == null:
		return global_position
	var flat := Vector3(0.0, -gangway_drop, gangway_length)
	return gangway.global_position + global_basis * flat


func _remember_rest() -> void:
	if not _rest_known:
		_rest = transform
		_rest_known = true
