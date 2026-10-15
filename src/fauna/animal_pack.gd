class_name AnimalPack
extends RefCounted
## Une meute (lot E5) : des bêtes qui chassent ensemble (les loups, docs/lore/ACTE1.md 3.5).
##
## - Elle encercle : chaque membre actif a un créneau sur un cercle autour du joueur (rayon
##   AnimalData.ring_radius_m), que la meute fait tourner lentement ; seul le porteur du jeton
##   s'approche pour attaquer, les autres tournent ;
## - elle attaque un par un : le jeton passe à un autre membre dès que le porteur a frappé (après
##   AnimalData.attack_gap_s), a été touché ou a fui ;
## - elle se débande : quand la moitié de la meute (au départ) a fui, le reste suit.
## Le temps est celui de la physique (images physiques), donc figé avec l'arbre en pause.

## La meute reste alertée (chasse tout entière) ce temps après le dernier repérage (s).
const ALERT_TIME := 4.0

var members: Array[Animal] = []
## Effectif au départ (la moitié qui a fui fait fuir le reste).
var initial_size: int = 0
var fled: int = 0
var routed: bool = false
var _token: Animal = null
var _token_free_at: float = 0.0
var _ring_base: float = NAN
var _alert_until: float = 0.0


## Ajoute une bête à la meute (et la lui donne : Animal.pack).
func add(animal: Animal) -> void:
	if animal in members:
		return
	members.append(animal)
	animal.pack = self
	initial_size = maxi(initial_size, members.size())


## Membres encore dans la partie : dans l'arbre, ni en fuite ni libérés.
func active() -> Array[Animal]:
	var result: Array[Animal] = []
	for member: Animal in members:
		if is_instance_valid(member) and member.is_inside_tree() and not member.is_leaving():
			result.append(member)
	return result


func _now() -> float:
	return Engine.get_physics_frames() / float(Engine.physics_ticks_per_second)


## La bête peut-elle attaquer maintenant ? Un seul porteur du jeton à la fois ; un jeton libre
## se donne à la première qui le demande, une fois la pause de la meute écoulée.
func request_attack(animal: Animal) -> bool:
	if _token == animal:
		return true
	if is_instance_valid(_token) and not _token.is_leaving() and _token.is_inside_tree():
		return false
	_token = null
	if _now() < _token_free_at:
		return false
	_token = animal
	return true


## La bête rend le jeton (elle a frappé, a été touchée, a fui) ; la meute attend attack_gap_s.
func release(animal: Animal) -> void:
	if _token != animal:
		return
	_token = null
	var species := animal.species()
	var gap := species.attack_gap_s if species != null else 0.0
	_token_free_at = _now() + gap


## Un membre a repéré le joueur : toute la meute chasse pendant ALERT_TIME secondes.
func raise_alert() -> void:
	_alert_until = _now() + ALERT_TIME


func is_alert() -> bool:
	return _now() < _alert_until


## Porteur du jeton (null si personne).
func token_holder() -> Animal:
	return _token if is_instance_valid(_token) else null


## Point du cercle où la bête doit tourner : son créneau parmi les membres actifs, sur le cercle de
## rayon radius centré en center. Le cercle tourne de ring_speed rad/s ; au premier appel, le
## créneau 0 est là où se trouve le premier membre actif (la meute encercle à partir d'où elle
## arrive).
func ring_point(animal: Animal, center: Vector3, radius: float, speed: float) -> Vector3:
	var alive := active()
	var index := maxi(alive.find(animal), 0)
	if is_nan(_ring_base):
		var first := alive[0] if not alive.is_empty() else animal
		var offset := first.global_position - center
		_ring_base = atan2(offset.z, offset.x) - speed * _now()
	var angle := _ring_base + speed * _now() + TAU * index / maxf(alive.size(), 1.0)
	return center + Vector3(cos(angle), 0.0, sin(angle)) * radius


## Remet le cercle à zéro (le joueur est sorti de la poursuite).
func reset_ring() -> void:
	_ring_base = NAN


## Une bête vaincue a pris la fuite : la moitié de la meute partie, tout le reste suit.
func report_fled(animal: Animal) -> void:
	release(animal)
	fled += 1
	if routed or fled * 2 < initial_size:
		return
	routed = true
	for member: Animal in active():
		if member != animal:
			member.rout(animal)
