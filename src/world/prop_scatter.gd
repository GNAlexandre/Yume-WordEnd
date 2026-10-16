@tool
class_name PropScatter
extends Node3D
## Pose plusieurs exemplaires d'un décor (scène de src/world/props/) : un point par exemplaire,
## posé sur le sol en relief de sa carte (MapGround.height_at ; sans sol en relief, à y = 0), lacet
## et taille variés de façon stable (graine).
## Les exemplaires sont des enfants internes recréés au chargement (aussi dans l'éditeur) :
## seules les données ci-dessous sont enregistrées dans la scène. Le PropBatcher de la zone les
## regroupe ensuite en MultiMesh avec le reste du décor.
##
## (H9) Variantes (docs/ASSETS_HD2D_MONDE.md, section 3.2) : chaque exemplaire tire une scène parmi
## prop et variants, de façon stable (graine), sans jamais prendre celle de son plus proche voisin
## (variant_indices) ; random_flip retourne au hasard l'image des exemplaires dont la racine est un
## DecorPanel (flip_h). Ces tirages ont leur propre suite de nombres : les lacets et les échelles
## d'un PropScatter sans variantes ne changent pas.
## (RD) Variation automatique (auto_variation, vraie par défaut), tirée de la position de chaque
## point (variation_at : stable, sans graine) selon le genre du décor (DecorGenre) : teinte du
## panneau (± 6 % de luminosité, ± 3 % de teinte pour la végétation, moins pour les rochers, les
## clôtures et les objets ; DecorPanel.tone), échelle du genre quand scale_range n'en donne pas,
## léger recul (± z) et léger enfoncement ; rien pour un décor sans genre (ciel, détails de mur).
## Dans une rangée (les points rangés le long de leur grand axe), deux voisins ne prennent jamais
## la même image quand une autre est possible (avoid_runs), en plus de la règle du plus proche
## voisin.

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

## (RD) Variation automatique tirée de la position (teinte, échelle du genre, recul, enfoncement).
@export var auto_variation: bool = true:
	set(value):
		auto_variation = value
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
		var panel := node as DecorPanel
		if auto_variation and panel != null:
			var vary := variation_at(points[i], panel.current_genre())
			panel.tone = vary["tone"]
			if scale_range.is_equal_approx(Vector2.ONE):
				size = vary["scale"]
			point += vary["offset"]
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
## diffère de son plus proche voisin, dès que pool() a deux scènes ; (RD) et, quand c'est
## possible, de ses voisins de rangée (avoid_runs).
func variant_indices() -> PackedInt32Array:
	var count := pool().size()
	var picks := pick_variants(points, count, hash([random_seed, &"variants"]))
	return avoid_runs(points, picks, count)


## (RD) Variation d'un exemplaire posé en at (repère du PropScatter) pour un genre (DecorGenre) :
## « tone » (DecorPanel.tone), « scale » (dans la plage du genre), « offset » (recul en z et
## enfoncement en y, m). Tirée de la position seule (au centimètre près) : stable d'un lancement à
## l'autre, différente d'un point à son voisin.
static func variation_at(at: Vector3, kind: StringName) -> Dictionary:
	var settings := DecorGenre.settings(kind)
	var tone_range: Vector2 = settings["tone"]
	var scales: Vector2 = settings["scale"]
	var key := Vector3i((at * 100.0).round())
	var tone := Vector2(
		(_unit(key, 1) * 2.0 - 1.0) * tone_range.x, (_unit(key, 2) * 2.0 - 1.0) * tone_range.y
	)
	return {
		"tone": tone,
		"scale": lerpf(scales.x, scales.y, _unit(key, 3)),
		"offset":
		Vector3(
			0.0,
			-float(settings["sink"]) * _unit(key, 4),
			(_unit(key, 5) * 2.0 - 1.0) * float(settings["jitter"])
		),
	}


## (RD) Nombre stable dans [0, 1) tiré d'une position (cm) et d'un sel.
static func _unit(key: Vector3i, salt: int) -> float:
	return float(posmod(hash([key, salt]), 65536)) / 65536.0


## (RD) Rangée : les points rangés le long de leur grand axe (plan x, z). Deux voisins de rangée
## qui ont la même scène : le second en prend une autre, différente de celles de ses voisins de
## rangée et de ses voisins les plus proches (pick_variants), s'il en reste une ; sinon il garde
## la sienne (deux scènes seulement : la règle du plus proche voisin passe avant).
static func avoid_runs(
	at: PackedVector3Array, picks: PackedInt32Array, count: int
) -> PackedInt32Array:
	var result := picks.duplicate()
	if count < 2 or at.size() < 2:
		return result
	var order := row_order(at)
	var nearest := PackedInt32Array()
	nearest.resize(at.size())
	for i in at.size():
		nearest[i] = nearest_neighbor(at, i)
	for k in range(1, order.size()):
		var i := order[k]
		var before := order[k - 1]
		if result[i] != result[before]:
			continue
		var taken := {result[before]: true}
		if k + 1 < order.size():
			taken[result[order[k + 1]]] = true
		if nearest[i] >= 0:
			taken[result[nearest[i]]] = true
		for j in at.size():
			if nearest[j] == i:
				taken[result[j]] = true
		for step in range(1, count):
			var candidate := (result[i] + step) % count
			if not taken.has(candidate):
				result[i] = candidate
				break
	return result


## (RD) Indices des points rangés le long de leur grand axe (axe principal des positions x, z).
static func row_order(at: PackedVector3Array) -> PackedInt32Array:
	var center := Vector2.ZERO
	for p in at:
		center += Vector2(p.x, p.z)
	center /= maxf(at.size(), 1.0)
	var cxx := 0.0
	var czz := 0.0
	var cxz := 0.0
	for p in at:
		var d := Vector2(p.x, p.z) - center
		cxx += d.x * d.x
		czz += d.y * d.y
		cxz += d.x * d.y
	var angle := 0.5 * atan2(2.0 * cxz, cxx - czz)
	var axis := Vector2(cos(angle), sin(angle))
	var keyed: Array[Vector2] = []
	for i in at.size():
		keyed.append(Vector2(axis.dot(Vector2(at[i].x, at[i].z)), i))
	keyed.sort()
	var order := PackedInt32Array()
	for item in keyed:
		order.append(int(item.y))
	return order


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


## Hauteur du relief sous le point local (x, z), relative au y local 0 : (T1) le sol en relief
## (MapGround, enfant « Ground ») de la carte qui porte le décor, sinon un sol plat à y = 0.
func _ground_offset(point: Vector3) -> float:
	var world := global_transform * Vector3(point.x, 0.0, point.z)
	var ground := _map_ground()
	if ground != null:
		var local := ground.global_transform.affine_inverse() * world
		var height := ground.height_at(local.x, local.z)
		if height <= MapGround.VOID_HEIGHT:
			return 0.0
		return (ground.global_transform * Vector3(local.x, height, local.z)).y - world.y
	return -world.y


## (T1) Sol en relief (MapGround) du premier ancêtre qui en a un, comme GroundDecal ; null sinon.
func _map_ground() -> MapGround:
	var node := get_parent()
	while node != null:
		var ground := node.get_node_or_null(^"Ground") as MapGround
		if ground != null:
			return ground
		node = node.get_parent()
	return null


func _queue_rebuild() -> void:
	if _queued or not is_inside_tree():
		return
	_queued = true
	rebuild.call_deferred()
