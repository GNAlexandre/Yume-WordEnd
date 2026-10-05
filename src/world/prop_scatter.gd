@tool
class_name PropScatter
extends Node3D
## Pose plusieurs exemplaires d'un décor (scène de src/world/props/) : un point par exemplaire,
## posé sur le relief de l'île (IslandTerrain.height_at), lacet et taille variés de façon
## stable (graine). Les exemplaires sont des enfants internes recréés au chargement (aussi dans
## l'éditeur) : seules les données ci-dessous sont enregistrées dans la scène. Le PropBatcher
## de la zone les regroupe ensuite en MultiMesh avec le reste du décor.

## Décor à poser (scène : meshes partagés + collision éventuelle).
@export var prop: PackedScene:
	set(value):
		prop = value
		_queue_rebuild()
## Positions locales des exemplaires ; y = hauteur au-dessus du sol.
@export var points: PackedVector3Array = PackedVector3Array():
	set(value):
		points = value
		_queue_rebuild()
## Lacet (degrés) de chaque exemplaire ; au-delà de la liste, lacet tiré au hasard.
@export var yaw_degrees: PackedFloat32Array = PackedFloat32Array():
	set(value):
		yaw_degrees = value
		_queue_rebuild()
## Échelle uniforme tirée entre x et y.
@export var scale_range: Vector2 = Vector2.ONE:
	set(value):
		scale_range = value
		_queue_rebuild()
## Graine du tirage des lacets et des échelles.
@export var random_seed: int = 0:
	set(value):
		random_seed = value
		_queue_rebuild()
## Poser chaque exemplaire sur le relief de l'île (sinon y local tel quel).
@export var follow_ground: bool = true:
	set(value):
		follow_ground = value
		_queue_rebuild()

var _instances: Array[Node3D] = []
var _queued := false


func _ready() -> void:
	rebuild()


## Recrée les exemplaires à partir des données.
func rebuild() -> void:
	_queued = false
	for node in _instances:
		if is_instance_valid(node):
			remove_child(node)
			node.queue_free()
	_instances.clear()
	if prop == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = random_seed
	for i in points.size():
		var yaw := deg_to_rad(yaw_degrees[i]) if i < yaw_degrees.size() else rng.randf() * TAU
		var size := rng.randf_range(scale_range.x, scale_range.y)
		var point := points[i]
		if follow_ground:
			point.y += _ground_offset(point)
		var node := prop.instantiate() as Node3D
		node.transform = Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * size), point)
		add_child(node, false, Node.INTERNAL_MODE_BACK)
		_instances.append(node)


## Hauteur du relief sous le point local (x, z), relative au y local 0.
func _ground_offset(point: Vector3) -> float:
	var world := global_transform * Vector3(point.x, 0.0, point.z)
	return IslandTerrain.height_at(world.x, world.z) - world.y


func _queue_rebuild() -> void:
	if _queued or not is_inside_tree():
		return
	_queued = true
	rebuild.call_deferred()
