@tool
class_name IslandRock
extends RefCounted
## Roche de l'île flottante (docs/lore/MONDE.md, section 2.8), construite une fois en code :
##
## - la lèvre de pierre, accrochée au bord exact du sol (IslandTerrain.rim_segments) : pas de
##   jour entre le sol et la roche ;
## - la falaise (une quinzaine de mètres), puis le dessous de l'île, cône de roche inversé dont
##   les strates claires et sombres sont peintes par shaders/rock.gdshader ;
## - des racines qui pendent sous la lèvre.
## Un seul mesh aux normales lissées (un draw call, face avant vers l'extérieur), sans collision :
## un corps qui saute du bord tombe le long de la falaise jusqu'à la KillZone de island.tscn.
##
## Aussi : la barrière du bord (couche 8 enemy_barrier, comme celle du village) qui retient les
## Timeres sur l'île sans gêner le joueur, et le mesh de la cascade du ruisseau.

## Anneaux de la roche sous la lèvre, du haut vers la pointe : (profondeur y, facteur du rayon du
## bord, variation du rayon en m, variation de la profondeur en m). Le premier, juste sous la
## lèvre, est sans variation et un peu en retrait : la lèvre le recouvre.
const RINGS: Array[Vector4] = [
	Vector4(-0.8, 1.0, 0.0, 0.0),
	Vector4(-4.5, 1.0, 0.5, 0.8),
	Vector4(-9.0, 0.985, 0.7, 1.2),
	Vector4(-15.0, 0.955, 0.8, 1.5),
	Vector4(-20.0, 0.88, 1.2, 1.5),
	Vector4(-26.0, 0.76, 1.6, 2.0),
	Vector4(-32.0, 0.6, 1.8, 2.0),
	Vector4(-38.0, 0.42, 1.6, 2.0),
	Vector4(-43.0, 0.24, 1.2, 1.5),
]
## Retrait (m) du premier anneau sous le bord ; avancée et hauteur de la lèvre (m).
const RING_INSET := 0.05
const LIP_OVERHANG := Vector2(0.12, 0.3)
const LIP_DEPTH := Vector2(0.9, 0.7)
## Angle (degrés) au-delà duquel une arête reste vive quand on lisse les normales.
const CREASE_ANGLE := 55.0
## Échantillons sur le tour, pointe du cône.
const SEGMENTS := 128
const TIP := Vector3(4.0, -47.0, -6.0)
## Racines : nombre, longueur (min, écart), rayon à la base.
const ROOTS := 56
const ROOT_LENGTH := Vector2(1.4, 2.6)
const ROOT_RADIUS := 0.2

## Barrière du bord : retrait sous le bord (m), bas et haut (m), nombre de segments.
const BARRIER_INSET := 0.8
const BARRIER_BOTTOM := -3.0
const BARRIER_TOP := 6.0
const BARRIER_SEGMENTS := 256

## Cascade du ruisseau : direction (angle atan2(z, x)) du point du bord où elle tombe, largeur,
## hauteur de la chute, avancée au bas de la chute (m), subdivisions verticales.
const WATERFALL_ANGLE := -2.3
const WATERFALL_SIZE := Vector2(3.0, 34.0)
const WATERFALL_REACH := 6.0
const WATERFALL_STEPS := 12

const MATERIAL := preload("res://src/world/materials/rock.tres")

static var _mesh_cache: ArrayMesh = null


## Trois sommets par triangle, couleur (rouge : racine) ; normales lissées par smooth().
class Builder:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	## Normale de chaque triangle, non normée (pondération par l'aire).
	var faces := PackedVector3Array()

	## Triangle (a, b, c) tourné pour que sa face avant regarde vers `front`.
	func triangle(a: Vector3, b: Vector3, c: Vector3, front: Vector3, color: Color) -> void:
		var normal := (c - a).cross(b - a)
		if normal.dot(front) < 0.0:
			var swap := b
			b = c
			c = swap
			normal = -normal
		faces.append(normal)
		var unit := normal.normalized()
		vertices.append_array(PackedVector3Array([a, b, c]))
		normals.append_array(PackedVector3Array([unit, unit, unit]))
		colors.append_array(PackedColorArray([color, color, color]))

	## Normales lissées : chaque sommet prend la moyenne (pondérée par l'aire) des normales des
	## triangles qui partagent sa position et s'écartent de moins de CREASE_ANGLE du sien ; les
	## arêtes plus vives (racines) restent nettes.
	func smooth() -> void:
		var groups: Dictionary[Vector3i, Array] = {}
		var keys: Array[Vector3i] = []
		keys.resize(vertices.size())
		for v in vertices.size():
			var key := Vector3i((vertices[v] * 64.0).round())
			keys[v] = key
			if not groups.has(key):
				groups[key] = []
			groups[key].append(faces[floori(v / 3.0)])
		var crease := cos(deg_to_rad(CREASE_ANGLE))
		for v in vertices.size():
			var own := normals[v]
			var sum := Vector3.ZERO
			for face: Vector3 in groups[keys[v]]:
				if face.normalized().dot(own) > crease:
					sum += face
			if sum.length_squared() > 0.0:
				normals[v] = sum.normalized()

	## Quadrilatère a b c d (dans l'ordre du tour), face avant vers l'extérieur de l'axe vertical.
	func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color) -> void:
		var center := (a + b + c + d) * 0.25
		var front := Vector3(center.x, 0.0, center.z)
		triangle(a, b, c, front, color)
		triangle(a, c, d, front, color)

	func mesh(material: Material) -> ArrayMesh:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_COLOR] = colors
		var result := ArrayMesh.new()
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		result.surface_set_material(0, material)
		return result


## Mesh de la roche (lèvre, falaise, dessous, racines), calculé une fois.
static func rock_mesh() -> ArrayMesh:
	if _mesh_cache != null:
		return _mesh_cache
	var builder := Builder.new()
	_add_lip(builder)
	_add_underside(builder)
	_add_roots(builder)
	builder.smooth()
	_mesh_cache = builder.mesh(MATERIAL)
	return _mesh_cache


## Lèvre : de chaque segment du bord du sol, une bande de pierre qui avance un peu et descend.
static func _add_lip(builder: Builder) -> void:
	var rim := IslandTerrain.rim_segments()
	for n in range(0, rim.size(), 2):
		var p := rim[n]
		var q := rim[n + 1]
		builder.quad(p, q, _lip_bottom(q), _lip_bottom(p), Color.BLACK)


## Bas de la lèvre sous le point p du bord : ne dépend que de p (segments voisins raccordés).
static func _lip_bottom(p: Vector3) -> Vector3:
	var outward := Vector3(p.x, 0.0, p.z).normalized()
	var push := LIP_OVERHANG.x + LIP_OVERHANG.y * _hash(p.x, p.z)
	var depth := LIP_DEPTH.x + LIP_DEPTH.y * _hash(p.z + 3.1, p.x - 7.7)
	return Vector3(p.x, p.y - depth, p.z) + outward * push


## Falaise et cône : anneaux de SEGMENTS points sous le bord, refermés sur la pointe.
static func _add_underside(builder: Builder) -> void:
	var rings: Array[PackedVector3Array] = []
	for r in RINGS.size():
		var ring := PackedVector3Array()
		ring.resize(SEGMENTS)
		var spec := RINGS[r]
		for i in SEGMENTS:
			var angle := TAU * i / SEGMENTS
			var edge := IslandTerrain.edge_point(angle)
			var radius := edge.length() * spec.y + spec.z * (2.0 * _hash(i, r) - 1.0)
			if r == 0:
				radius -= RING_INSET
			var depth := spec.x + spec.w * (2.0 * _hash(r + 0.5, i + 0.25) - 1.0)
			ring[i] = Vector3(cos(angle) * radius, depth, sin(angle) * radius)
		rings.append(ring)
	for r in rings.size() - 1:
		var top := rings[r]
		var bottom := rings[r + 1]
		for i in SEGMENTS:
			var j := (i + 1) % SEGMENTS
			builder.quad(top[i], top[j], bottom[j], bottom[i], Color.BLACK)
	var last := rings[rings.size() - 1]
	for i in SEGMENTS:
		var a := last[i]
		var b := last[(i + 1) % SEGMENTS]
		var front := (a + b) * 0.5 - TIP
		builder.triangle(a, b, TIP, Vector3(front.x, -1.0, front.z), Color.BLACK)


## Racines : petites pyramides à trois faces qui pendent sous la lèvre.
static func _add_roots(builder: Builder) -> void:
	for n in ROOTS:
		var angle := TAU * (n + 0.8 * _hash(n, 41.0)) / ROOTS
		var edge := IslandTerrain.edge_point(angle)
		var center := Vector3(edge.x, -0.6, edge.y) * 0.997
		var outward := Vector3(edge.x, 0.0, edge.y).normalized()
		var length := ROOT_LENGTH.x + ROOT_LENGTH.y * _hash(n, 7.0)
		var tip := center + outward * 0.35 + Vector3.DOWN * length
		var base: Array[Vector3] = []
		for k in 3:
			var around := TAU * k / 3.0 + angle
			base.append(center + Vector3(cos(around), 0.0, sin(around)) * ROOT_RADIUS)
		for k in 3:
			var a := base[k]
			var b := base[(k + 1) % 3]
			var front := (a + b) * 0.5 - center
			builder.triangle(a, b, tip, front, Color.RED)


## Barrière du bord : ruban vertical BARRIER_INSET m en deçà du bord, sur la couche 8 (voir
## island.tscn) ; les deux faces arrêtent.
static func edge_barrier_shape() -> ConcavePolygonShape3D:
	var faces := PackedVector3Array()
	for i in BARRIER_SEGMENTS:
		var a := _inset_point(TAU * i / BARRIER_SEGMENTS)
		var b := _inset_point(TAU * (i + 1) / BARRIER_SEGMENTS)
		var a0 := Vector3(a.x, BARRIER_BOTTOM, a.y)
		var b0 := Vector3(b.x, BARRIER_BOTTOM, b.y)
		var a1 := Vector3(a.x, BARRIER_TOP, a.y)
		var b1 := Vector3(b.x, BARRIER_TOP, b.y)
		faces.append_array(PackedVector3Array([a0, b0, b1, a0, b1, a1]))
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	return shape


static func _inset_point(angle: float) -> Vector2:
	var p := IslandTerrain.edge_point(angle)
	return p - p.normalized() * BARRIER_INSET


## Cascade : ruban vertical (UV.y de 0 en haut à 1 en bas) qui part du bord vers WATERFALL_ANGLE
## et s'écarte de la falaise en tombant ; coordonnées de l'île.
static func waterfall_mesh() -> ArrayMesh:
	var edge := IslandTerrain.edge_point(WATERFALL_ANGLE)
	var outward := Vector3(edge.x, 0.0, edge.y).normalized()
	var across := Vector3(-outward.z, 0.0, outward.x) * WATERFALL_SIZE.x * 0.5
	var top := Vector3(edge.x, 0.02, edge.y) - outward * 0.6
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	for s in WATERFALL_STEPS + 1:
		var t := float(s) / WATERFALL_STEPS
		var center := (
			top + outward * WATERFALL_REACH * sqrt(t) + Vector3.DOWN * (WATERFALL_SIZE.y * t)
		)
		var spread := 1.0 + 0.8 * t
		vertices.append_array(
			PackedVector3Array([center - across * spread, center + across * spread])
		)
		normals.append_array(PackedVector3Array([outward, outward]))
		uvs.append_array(PackedVector2Array([Vector2(0.0, t), Vector2(1.0, t)]))
	var indices := PackedInt32Array()
	for s in WATERFALL_STEPS:
		var k := s * 2
		indices.append_array(PackedInt32Array([k, k + 1, k + 2, k + 1, k + 3, k + 2]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Bruit stable dans [0, 1[ tiré de deux nombres.
static func _hash(a: float, b: float) -> float:
	var n := sin(a * 12.9898 + b * 78.233) * 43758.5453
	return n - floorf(n)
