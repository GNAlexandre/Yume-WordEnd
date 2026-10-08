@tool
class_name IslandRock
extends RefCounted
## Roche de l'île flottante (docs/lore/MONDE.md, section 2.8), construite une fois en code :
##
## - la lèvre de pierre, accrochée au bord exact du sol (IslandTerrain.rim_loop) : pas de jour
##   entre le sol et la roche ;
## - la falaise (une quinzaine de mètres), puis le dessous de l'île, cône de roche inversé.
## (HD-2D) Les strates, les racines et la lèvre sont des images de pixel art (assets/hd2d/cliff/,
## shaders/rock.gdshader) plaquées le long du tour : UV.x en mètres le long du bord (couture au
## nord, face cachée à la caméra fixe), UV.y en mètres sous le sol.
## Un seul mesh aux normales lissées (un draw call, face avant vers l'extérieur), sans collision :
## un corps qui saute du bord tombe le long de la falaise jusqu'à la KillZone de island.tscn.
##
## (B1) Le bord est une côte irrégulière (IslandTerrain : caps, éperon, anses, ébréchures). La
## lèvre et le premier anneau suivent le bord exact du sol, point par point ; les anneaux plus
## bas suivent la côte de plus en plus lissée (les ébréchures s'effacent en descendant), à
## RING_SEGMENTS points chacun, raccordés d'un anneau à l'autre par angle croissant (bandes de
## triangles sans croisement : tous les anneaux sont étoilés autour de l'axe). UV.x : longueur du
## bord depuis le nord (IslandEdge.arc), ramenée à uv_turn(), un nombre entier de
## textures : pas de couture visible et pas d'étirement, quel que soit le périmètre.
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
## (B1) Points de chaque anneau sous le premier (qui a ceux du bord du sol), et part des
## ébréchures du bord qu'il garde (1 : le bord exact, 0 : la côte lissée).
const RING_SEGMENTS: Array[int] = [0, 384, 256, 192, 192, 128, 128, 128, 128]
const RING_CHIPS: Array[float] = [1.0, 0.6, 0.3, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
## Retrait (m) du premier anneau sous le bord ; avancée et hauteur de la lèvre (m).
const RING_INSET := 0.05
const LIP_OVERHANG := Vector2(0.12, 0.3)
const LIP_DEPTH := Vector2(0.9, 0.7)
## Angle (degrés) au-delà duquel une arête reste vive quand on lisse les normales.
const CREASE_ANGLE := 80.0
## Cases du bruit des anneaux sur le tour (une tous les 4 m environ), pointe du cône.
const SEGMENTS := 128
const TIP := Vector3(4.0, -47.0, -6.0)
## Tour de l'île plaqué de texture : un nombre entier de textures de 4 m (couture invisible), voir
## uv_turn().
const TEXTURE_METERS := 4.0

## Barrière du bord : retrait sous le bord (m), bas et haut (m), nombre de segments.
const BARRIER_INSET := 0.8
const BARRIER_BOTTOM := -3.0
const BARRIER_TOP := 6.0
const BARRIER_SEGMENTS := 1024

## Cascade du ruisseau : largeur, hauteur de la chute, avancée au bas de la chute (m),
## subdivisions verticales ; elle tombe du bord en IslandEdge.WATERFALL_ANGLE, au bout du lit.
const WATERFALL_ANGLE := IslandEdge.WATERFALL_ANGLE
const WATERFALL_SIZE := Vector2(3.0, 34.0)
const WATERFALL_REACH := 6.0
const WATERFALL_STEPS := 12

const MATERIAL := preload("res://src/world/materials/rock.tres")

static var _mesh_cache: ArrayMesh = null


## Trois sommets par triangle ; normales lissées par smooth() ; UV calculés par mesh().
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

	## UV de chaque sommet : (mètres le long du tour depuis le nord, mètres sous le sol) ; un
	## triangle à cheval sur la couture du nord est ramené d'un seul côté.
	func uvs() -> PackedVector2Array:
		var turn := IslandRock.uv_turn()
		var scale := turn / IslandEdge.length()
		var result := PackedVector2Array()
		result.resize(vertices.size())
		for t in range(0, vertices.size(), 3):
			var us: Array[float] = []
			for k in 3:
				var p := vertices[t + k]
				us.append(IslandEdge.arc(atan2(p.z, p.x)) * scale)
			var top := maxf(us[0], maxf(us[1], us[2]))
			for k in 3:
				var u := us[k]
				if top - u > turn / 2.0:
					u += turn
				result[t + k] = Vector2(u, -vertices[t + k].y)
		return result

	## Quadrilatère a b c d (dans l'ordre du tour), face avant vers `front`.
	func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, front: Vector3, color: Color) -> void:
		triangle(a, b, c, front, color)
		triangle(a, c, d, front, color)

	func mesh(material: Material) -> ArrayMesh:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_TEX_UV] = uvs()
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
	builder.smooth()
	_mesh_cache = builder.mesh(MATERIAL)
	return _mesh_cache


## (B1) Longueur (m) du tour plaquée de texture : le périmètre du bord arrondi à un nombre entier de
## textures de TEXTURE_METERS m (la couture du nord ne se voit pas).
static func uv_turn() -> float:
	return maxf(roundf(IslandEdge.length() / TEXTURE_METERS), 1.0) * TEXTURE_METERS


## Lèvre : de chaque segment du bord du sol, une bande de pierre qui avance un peu et descend.
static func _add_lip(builder: Builder) -> void:
	var rim := IslandTerrain.rim_loop()
	for n in rim.size():
		var p := rim[n]
		var q := rim[(n + 1) % rim.size()]
		builder.quad(p, q, _lip_bottom(q), _lip_bottom(p), _front(p, q), Color.BLACK)


## Bas de la lèvre sous le point p du bord : ne dépend que de p (segments voisins raccordés).
static func _lip_bottom(p: Vector3) -> Vector3:
	var normal := IslandEdge.normal(atan2(p.z, p.x))
	var outward := Vector3(normal.x, 0.0, normal.y)
	var push := LIP_OVERHANG.x + LIP_OVERHANG.y * _hash(p.x, p.z)
	var depth := LIP_DEPTH.x + LIP_DEPTH.y * _hash(p.z + 3.1, p.x - 7.7)
	return Vector3(p.x, p.y - depth, p.z) + outward * push


## Face avant d'un morceau de roche entre les points a et b : la normale de la côte lissée.
static func _front(a: Vector3, b: Vector3) -> Vector3:
	var middle := a + b
	var normal := IslandEdge.normal(atan2(middle.z, middle.x), true)
	return Vector3(normal.x, 0.0, normal.y)


## Falaise et cône : le premier anneau sous le bord du sol, puis des anneaux de plus en plus
## lissés et resserrés, refermés sur la pointe.
static func _add_underside(builder: Builder) -> void:
	var rings: Array[PackedVector3Array] = []
	for r in RINGS.size():
		rings.append(_top_ring() if r == 0 else _ring(r))
	for r in rings.size() - 1:
		_stitch(builder, rings[r], rings[r + 1])
	var last := rings[rings.size() - 1]
	for i in last.size():
		var a := last[i]
		var b := last[(i + 1) % last.size()]
		var front := (a + b) * 0.5 - TIP
		builder.triangle(a, b, TIP, Vector3(front.x, -1.0, front.z), Color.BLACK)


## Premier anneau : les points du bord du sol, en retrait de RING_INSET m, à la profondeur RINGS[0].
static func _top_ring() -> PackedVector3Array:
	var rim := IslandTerrain.rim_loop()
	var ring := PackedVector3Array()
	ring.resize(rim.size())
	for n in rim.size():
		var p := rim[n]
		var normal := IslandEdge.normal(atan2(p.z, p.x))
		ring[n] = Vector3(p.x - normal.x * RING_INSET, RINGS[0].x, p.z - normal.y * RING_INSET)
	return ring


## Anneau r : RING_SEGMENTS[r] points à angles réguliers (depuis le nord), rayon de la côte (plus
## ou moins lissée) réduit par RINGS[r].y, variations de rayon et de profondeur d'un bruit lisse.
static func _ring(r: int) -> PackedVector3Array:
	var spec := RINGS[r]
	var count := RING_SEGMENTS[r]
	var ring := PackedVector3Array()
	ring.resize(count)
	for i in count:
		var angle := -PI / 2.0 + TAU * i / count
		var rough := IslandTerrain.edge_radius(angle)
		var smooth := IslandEdge.smooth_radius(angle)
		var radius := lerpf(smooth, rough, RING_CHIPS[r]) * spec.y
		radius += spec.z * (2.0 * _noise(angle, r) - 1.0)
		var depth := spec.x + spec.w * (2.0 * _noise(angle, r + 0.5) - 1.0)
		ring[i] = Vector3(cos(angle) * radius, depth, sin(angle) * radius)
	return ring


## Raccorde deux anneaux (points dans le sens des angles croissants, départ au nord) par une
## bande de triangles : on avance sur celui dont le point suivant vient le premier.
static func _stitch(builder: Builder, top: PackedVector3Array, bottom: PackedVector3Array) -> void:
	var top_angles := _unwrapped_angles(top)
	var bottom_angles := _unwrapped_angles(bottom)
	var i := 0
	var j := 0
	var n := top.size()
	var m := bottom.size()
	while i < n or j < m:
		var a := top[i % n]
		var b := bottom[j % m]
		if j == m or (i < n and top_angles[i + 1] <= bottom_angles[j + 1]):
			var c := top[(i + 1) % n]
			builder.triangle(a, c, b, _front(a, c), Color.BLACK)
			i += 1
		else:
			var d := bottom[(j + 1) % m]
			builder.triangle(a, d, b, _front(b, d), Color.BLACK)
			j += 1


## Angles des points d'un anneau, croissants depuis le nord (−π/2), plus le premier refermé au
## bout (+ TAU).
static func _unwrapped_angles(ring: PackedVector3Array) -> PackedFloat64Array:
	var angles := PackedFloat64Array()
	angles.resize(ring.size() + 1)
	for k in ring.size():
		var p := ring[k]
		angles[k] = -PI / 2.0 + fposmod(atan2(p.z, p.x) + PI / 2.0, TAU)
	# Le premier point peut être juste avant le nord : il ouvre le tour.
	if angles[0] > angles[ring.size() - 1]:
		angles[0] -= TAU
	angles[ring.size()] = angles[0] + TAU
	return angles


## Bruit lisse dans [0, 1] le long du tour (SEGMENTS cases, raccord en cosinus) : le même quel que
## soit le nombre de points de l'anneau.
static func _noise(angle: float, seed_value: float) -> float:
	var u := fposmod((angle + PI / 2.0) / TAU, 1.0) * SEGMENTS
	var i := floori(u)
	var f := u - i
	var a := _hash(posmod(i, SEGMENTS), seed_value)
	var b := _hash(posmod(i + 1, SEGMENTS), seed_value)
	return lerpf(a, b, 0.5 - 0.5 * cos(PI * f))


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


## Point du bord rentré de BARRIER_INSET m le long de la normale de la côte lissée.
static func _inset_point(angle: float) -> Vector2:
	return IslandTerrain.edge_point(angle) - IslandEdge.normal(angle, true) * BARRIER_INSET


## Cascade : ruban vertical (UV.y de 0 en haut à 1 en bas) qui part du bord en WATERFALL_ANGLE, au
## bout du lit du ruisseau, et s'écarte de la falaise en tombant ; coordonnées de l'île.
static func waterfall_mesh() -> ArrayMesh:
	var edge := IslandTerrain.edge_point(WATERFALL_ANGLE)
	var normal := IslandEdge.normal(WATERFALL_ANGLE, true)
	var outward := Vector3(normal.x, 0.0, normal.y)
	var across := Vector3(-outward.z, 0.0, outward.x) * WATERFALL_SIZE.x * 0.5
	# Le haut du ruban affleure sous la lèvre : vu de la caméra, pas de trait clair sur le lit.
	var top := Vector3(edge.x, -0.05, edge.y) + outward * 0.05
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
