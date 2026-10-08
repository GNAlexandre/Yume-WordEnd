@tool
class_name PropScatter
extends Node3D
## Pose plusieurs exemplaires d'un décor (scène de src/world/props/) : un point par exemplaire,
## posé sur le relief de l'île (IslandTerrain.height_at), lacet et taille variés de façon
## stable (graine). Les exemplaires sont des enfants internes recréés au chargement (aussi dans
## l'éditeur) : seules les données ci-dessous sont enregistrées dans la scène. Le PropBatcher
## de la zone les regroupe ensuite en MultiMesh avec le reste du décor.
##
## (H9) Variantes (docs/ASSETS_HD2D_MONDE.md, section 3.2) : chaque exemplaire tire une scène parmi
## prop et variants, de façon stable (graine), sans jamais prendre celle de son plus proche voisin
## (variant_indices) ; random_flip retourne au hasard l'image des exemplaires dont la racine est un
## DecorPanel (flip_h). Ces tirages ont leur propre suite de nombres : les lacets et les échelles
## d'un PropScatter sans variantes ne changent pas.

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
## (H9) Autres formes du même décor, tirées avec prop (une scène par exemplaire).
@export var variants: Array[PackedScene] = []:
	set(value):
		variants = value
		_queue_rebuild()
## (H9) Retourner au hasard l'image des exemplaires (racine DecorPanel : flip_h).
@export var random_flip: bool = false:
	set(value):
		random_flip = value
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
	var scenes := pool()
	if scenes.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = random_seed
	var picks := variant_indices()
	var flips := RandomNumberGenerator.new()
	flips.seed = hash([random_seed, &"flip"])
	for i in points.size():
		var yaw := deg_to_rad(yaw_degrees[i]) if i < yaw_degrees.size() else rng.randf() * TAU
		var size := rng.randf_range(scale_range.x, scale_range.y)
		var point := points[i]
		if follow_ground:
			point.y += _ground_offset(point)
		var node := scenes[picks[i]].instantiate() as Node3D
		node.transform = Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * size), point)
		var flip := flips.randf() < 0.5
		if random_flip and node is DecorPanel:
			(node as DecorPanel).flip_h = flip
		add_child(node, false, Node.INTERNAL_MODE_BACK)
		_instances.append(node)


## (H9) Scènes tirées : prop (s'il y en a une) puis variants, sans les vides.
func pool() -> Array[PackedScene]:
	var scenes: Array[PackedScene] = []
	for scene: PackedScene in [prop] + variants:
		if scene != null:
			scenes.append(scene)
	return scenes


## (H9) Indice dans pool() de la scène de chaque point : tirage stable (graine) où chaque point
## diffère de son plus proche voisin, dès que pool() a deux scènes.
func variant_indices() -> PackedInt32Array:
	return pick_variants(points, pool().size(), hash([random_seed, &"variants"]))


## (H9) Tire count variantes pour des points (x, z) : graphe des plus proches voisins (une forêt),
## parcouru en largeur ; chaque point évite la variante du point qui l'a atteint, son seul voisin
## déjà tiré : aucun point n'a la variante de son plus proche voisin si count ≥ 2.
static func pick_variants(at: PackedVector3Array, count: int, seed_value: int) -> PackedInt32Array:
	var picks := PackedInt32Array()
	picks.resize(at.size())
	picks.fill(-1)
	if count <= 1:
		picks.fill(0)
		return picks
	var links: Array[PackedInt32Array] = []
	links.resize(at.size())
	for i in at.size():
		links[i] = PackedInt32Array()
	for i in at.size():
		var nearest := nearest_neighbor(at, i)
		if nearest >= 0:
			links[i].append(nearest)
			links[nearest].append(i)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for start in at.size():
		if picks[start] >= 0:
			continue
		picks[start] = rng.randi_range(0, count - 1)
		var queue := PackedInt32Array([start])
		var head := 0
		while head < queue.size():
			var from := queue[head]
			head += 1
			for to: int in links[from]:
				if picks[to] >= 0:
					continue
				# Une variante parmi count - 1 : toutes sauf celle du point qui l'atteint.
				var pick := rng.randi_range(0, count - 2)
				picks[to] = pick + 1 if pick >= picks[from] else pick
				queue.append(to)
	return picks


## (H9) Indice du point le plus proche de at[i] dans le plan (x, z) ; à égalité, le premier ; -1
## s'il est seul.
static func nearest_neighbor(at: PackedVector3Array, i: int) -> int:
	var best := -1
	var best_distance := INF
	for j in at.size():
		if j == i:
			continue
		var d := Vector2(at[j].x - at[i].x, at[j].z - at[i].z).length_squared()
		if d < best_distance:
			best_distance = d
			best = j
	return best


## Hauteur du relief sous le point local (x, z), relative au y local 0.
func _ground_offset(point: Vector3) -> float:
	var world := global_transform * Vector3(point.x, 0.0, point.z)
	return IslandTerrain.height_at(world.x, world.z) - world.y


func _queue_rebuild() -> void:
	if _queued or not is_inside_tree():
		return
	_queued = true
	rebuild.call_deferred()
