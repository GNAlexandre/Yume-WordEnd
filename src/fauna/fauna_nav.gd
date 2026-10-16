class_name FaunaNav
extends RefCounted
## Navigation de la faune (lot E5) : où un animal peut poser le pied, par la praticabilité du sol
## de la carte (MapGround.is_walkable, level_at), jamais par une grille à part. Une carte sans
## MapGround (sol plat d'essai) laisse tout permis : seule la collision compte.
##
## Un pas est permis si la case d'arrivée est praticable (ni vide, ni eau dormante, ni hors de la
## carte) et si le palier ne change pas de plus d'un cran (0,5 m : une pente, pas une falaise ;
## les escaliers et les rampes, eux, sont des volées de cases à paliers voisins).

## Pas de sondage (m) devant l'animal, et angles essayés pour contourner (degrés, autour du but).
const PROBE_M := 1.1
const ANGLES: Array[float] = [
	0.0, 25.0, -25.0, 50.0, -50.0, 80.0, -80.0, 110.0, -110.0, 140.0, -140.0
]


## Sol en relief de la carte qui contient node (celle que WorldManager a posée si node n'est pas
## dans une carte) ; null s'il n'y en a pas.
static func ground_of(node: Node) -> MapGround:
	var map := WorldAtlas.map_of_node(node)
	if map == null and node != null and node.is_inside_tree():
		map = WorldManager.current_map_node()
	if map == null:
		return null
	return map.get_node_or_null(^"Ground") as MapGround


## Peut-on se tenir en at ? (Sans sol en relief : oui.)
static func can_stand(ground: MapGround, at: Vector3) -> bool:
	return ground == null or ground.is_walkable(at.x, at.z)


## Peut-on passer de from à to d'un pas ?
static func can_step(ground: MapGround, from: Vector3, to: Vector3) -> bool:
	if ground == null:
		return true
	if not ground.is_walkable(to.x, to.z):
		return false
	var here := ground.level_at(from.x, from.z)
	var there := ground.level_at(to.x, to.z)
	return here == MapGroundData.VOID_LEVEL or absi(there - here) <= 1


## Direction praticable la plus proche de desired (vecteur horizontal) : desired lui-même, ou tourné
## de plus en plus ; ZERO s'il n'y en a aucune (acculé).
static func steer(ground: MapGround, from: Vector3, desired: Vector3) -> Vector3:
	var flat := Vector3(desired.x, 0.0, desired.z)
	if flat.length_squared() < 0.0001:
		return Vector3.ZERO
	flat = flat.normalized()
	if ground == null:
		return flat
	for angle: float in ANGLES:
		var candidate := flat.rotated(Vector3.UP, deg_to_rad(angle))
		if (
			can_step(ground, from, from + candidate * PROBE_M)
			and can_step(ground, from, from + candidate * PROBE_M * 2.0)
		):
			return candidate
	return Vector3.ZERO


## Point praticable au hasard dans le disque (center, radius) ; center s'il n'y en a pas. La hauteur
## est celle du sol (plus un peu : l'animal retombe).
static func random_spot(
	ground: MapGround, center: Vector3, radius: float, rng: RandomNumberGenerator
) -> Vector3:
	for _try in 16:
		var angle := rng.randf() * TAU
		var spot := center + Vector3(cos(angle), 0.0, sin(angle)) * sqrt(rng.randf()) * radius
		if can_stand(ground, spot):
			return on_ground(ground, spot)
	return on_ground(ground, center)


## at posé sur le sol de la carte (légèrement au-dessus).
static func on_ground(ground: MapGround, at: Vector3) -> Vector3:
	if ground != null:
		var height := ground.height_at(at.x, at.z)
		if height > MapGround.VOID_HEIGHT:
			return Vector3(at.x, height + 0.05, at.z)
	return at
