@tool
class_name MapGroundCoast
extends RefCounted
## Côte du sol en relief d'une carte (MapGroundBuilder) : les segments du bord du vide enchaînés,
## le rideau de roche qui pend dessous (la lèvre, puis la falaise qui se resserre en descendant,
## comme la roche de l'île, IslandRock) et les barrières (mur invisible, deux faces) le long de la
## côte et des bords « land » de la carte. Le rideau va dans le mesh des faces du builder (style
## roche), sans collision.

## Lèvre sous la côte : avancée (m, plus un bruit) et hauteur (m, plus un bruit), comme IslandRock.
const LIP_PUSH := Vector2(0.12, 0.3)
const LIP_DEPTH := Vector2(0.9, 0.7)
## Bord de la lèvre un peu relevé : normales penchées vers le ciel en haut de la lèvre.
const LIP_TILT := 0.4
## Anneaux du rideau sous la lèvre : (y absolu, retrait vers la terre en m, bruit du retrait,
## bruit de la profondeur).
const RINGS: Array[Vector4] = [
	Vector4(-3.5, -0.1, 0.4, 0.6),
	Vector4(-8.0, 0.5, 0.7, 1.0),
	Vector4(-14.0, 1.4, 0.9, 1.4),
	Vector4(-21.0, 2.8, 1.2, 1.5),
	Vector4(-29.0, 4.6, 1.5, 2.0),
	Vector4(-38.0, 7.0, 1.6, 2.0),
]
## Un point sur DECIMATE de la côte pour les anneaux sous la lèvre.
const DECIMATE := 4
## Barrière : sous et au-dessus du bord (m).
const BARRIER_BELOW := 1.5
const BARRIER_ABOVE := 4.0


## Chaînes de la côte, rideau et barrières du builder (segments de côte déjà dans builder.rim).
static func build(builder: MapGroundBuilder, data: MapGroundData, levels: Vector2i) -> void:
	builder.chains = chain(builder.rim)
	for points in builder.chains:
		_curtain(builder, points)
	if data.barrier:
		_barriers(builder, data, levels)


## Clé d'un point de la côte (quantifiée).
static func _key(p: Vector3) -> Vector3i:
	return Vector3i(roundi(p.x * 4096.0), roundi(p.y * 64.0), roundi(p.z * 4096.0))


## Enchaîne les segments (p, q) en chaînes ouvertes (au bout du prolongement) ou fermées (premier
## point répété au bout).
static func chain(rim: PackedVector3Array) -> Array[PackedVector3Array]:
	var by_start := {}
	var ends := {}
	for n in range(0, rim.size(), 2):
		var start := _key(rim[n])
		if not by_start.has(start):
			by_start[start] = PackedInt32Array()
		var list: PackedInt32Array = by_start[start]
		list.append(n)
		by_start[start] = list
		ends[_key(rim[n + 1])] = true
	var used := PackedByteArray()
	used.resize(rim.size() >> 1)
	var starts := PackedInt32Array()
	for n in range(0, rim.size(), 2):
		if not ends.has(_key(rim[n])):
			starts.append(n)
	for n in range(0, rim.size(), 2):
		starts.append(n)
	var chains: Array[PackedVector3Array] = []
	for first in starts:
		if used[first >> 1] == 1:
			continue
		var points := PackedVector3Array([rim[first]])
		var current := first
		while current >= 0 and used[current >> 1] == 0:
			used[current >> 1] = 1
			points.append(rim[current + 1])
			current = _next_segment(by_start, rim[current + 1], used)
		if points.size() >= 2:
			chains.append(points)
	return chains


static func _next_segment(by_start: Dictionary, at: Vector3, used: PackedByteArray) -> int:
	var key := _key(at)
	if not by_start.has(key):
		return -1
	for n: int in by_start[key]:
		if used[n >> 1] == 0:
			return n
	return -1


## Rideau sous une chaîne : la lèvre à pleine résolution (elle suit le bord du sol au point près),
## puis les anneaux, un point sur DECIMATE.
static func _curtain(builder: MapGroundBuilder, points: PackedVector3Array) -> void:
	var count := points.size()
	var closed := _key(points[0]) == _key(points[count - 1])
	var top := points[0].y
	var base := builder.cliff_vertices.size()
	var arc := PackedFloat32Array()
	arc.resize(count)
	var outward := PackedVector3Array()
	outward.resize(count)
	var lip := PackedVector3Array()
	lip.resize(count)
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	# Rangée 0 : la côte (haut de la lèvre, normales penchées vers le ciel).
	var up := Vector3.UP * LIP_TILT
	for n in count:
		if n > 0:
			arc[n] = arc[n - 1] + points[n - 1].distance_to(points[n])
		var o := _outward(points, n, closed)
		outward[n] = o
		var p := points[n]
		var push := LIP_PUSH.x + LIP_PUSH.y * _noise(p.x, p.z, 1.0)
		var depth := LIP_DEPTH.x + LIP_DEPTH.y * _noise(p.z, p.x, 2.0)
		lip[n] = Vector3(p.x, p.y - depth, p.z) + o * push
		vertices.append(p)
		normals.append((o + up).normalized())
		uvs.append(Vector2(arc[n], 0.0))
	# Rangée 1 : le bas de la lèvre.
	for n in count:
		vertices.append(lip[n])
		normals.append(outward[n])
		uvs.append(Vector2(arc[n], top - lip[n].y))
	# Sens des triangles (face avant vers le vide), le même pour toute la chaîne.
	var flip := (lip[1] - points[0]).cross(points[1] - points[0]).dot(outward[0] + outward[1]) < 0.0
	var indices := PackedInt32Array()
	for n in count - 1:
		_quad_indices(indices, base + n, base + n + 1, base + count + n + 1, base + count + n, flip)
	var picks := PackedInt32Array()
	for n in range(0, count, DECIMATE):
		picks.append(n)
	if picks[picks.size() - 1] != count - 1:
		picks.append(count - 1)
	var upper_rows := PackedInt32Array()
	var upper := PackedVector3Array()
	for n in picks:
		upper_rows.append(base + count + n)
		upper.append(lip[n])
	# Anneaux : un sommet par point choisi, bande raccordée à la rangée du dessus.
	for r in RINGS.size():
		var lower := _ring(points, outward, picks, upper, r)
		var row := base + vertices.size()
		for m in picks.size():
			vertices.append(lower[m])
			normals.append(outward[picks[m]])
			uvs.append(Vector2(arc[picks[m]], top - lower[m].y))
		for m in picks.size() - 1:
			_quad_indices(indices, upper_rows[m], upper_rows[m + 1], row + m + 1, row + m, flip)
		for m in picks.size():
			upper_rows[m] = row + m
		upper = lower
	var styles := PackedVector2Array()
	styles.resize(vertices.size())
	styles.fill(Vector2(MapGroundData.Face.ROCK, 0.0))
	builder.cliff_vertices.append_array(vertices)
	builder.cliff_normals.append_array(normals)
	builder.cliff_uvs.append_array(uvs)
	builder.cliff_uv2s.append_array(styles)
	builder.cliff_indices.append_array(indices)


## Indices des deux triangles du quadrilatère a b c d (dans l'ordre du tour), retournés si flip.
static func _quad_indices(
	indices: PackedInt32Array, a: int, b: int, c: int, d: int, flip: bool
) -> void:
	if flip:
		indices.append_array(PackedInt32Array([a, c, b, a, d, c]))
	else:
		indices.append_array(PackedInt32Array([a, b, c, a, c, d]))


## Anneau r du rideau sous les points picks : à sa profondeur (plus bas que l'anneau du dessus),
## rentré vers la terre.
static func _ring(
	points: PackedVector3Array,
	outward: PackedVector3Array,
	picks: PackedInt32Array,
	upper: PackedVector3Array,
	r: int
) -> PackedVector3Array:
	var spec := RINGS[r]
	var lower := PackedVector3Array()
	lower.resize(picks.size())
	for m in picks.size():
		var n := picks[m]
		var p := points[n]
		var inset := spec.y + spec.z * (2.0 * _noise(p.x + r * 7.1, p.z, 3.0) - 1.0)
		var y := spec.x + spec.w * (2.0 * _noise(p.z, p.x + r * 3.3, 4.0) - 1.0)
		lower[m] = Vector3(p.x, minf(y, upper[m].y - 1.0), p.z) - outward[n] * inset
	return lower


## Direction (horizontale, unitaire) du vide au point n de la chaîne : à gauche du sens de la
## chaîne (la terre est à droite), sur les deux segments voisins.
static func _outward(points: PackedVector3Array, n: int, closed: bool) -> Vector3:
	var count := points.size()
	var prev := n - 1
	var next := n + 1
	if closed:
		prev = count - 2 if n == 0 else n - 1
		next = 1 if n == count - 1 else n + 1
	prev = maxi(prev, 0)
	next = mini(next, count - 1)
	var along := points[next] - points[prev]
	along.y = 0.0
	if along.length_squared() < 0.000001:
		return Vector3.FORWARD
	along = along.normalized()
	return Vector3(along.z, 0.0, -along.x)


## Barrière le long de la côte, et le long des bords « land » de la carte (une sortie se pose en
## deçà du bord).
static func _barriers(builder: MapGroundBuilder, data: MapGroundData, levels: Vector2i) -> void:
	var rim := builder.rim
	for n in range(0, rim.size(), 2):
		var p := rim[n]
		var q := rim[n + 1]
		_wall(
			builder, Vector2(p.x, p.z), Vector2(q.x, q.z), p.y - BARRIER_BELOW, p.y + BARRIER_ABOVE
		)
	var bottom := levels.x * MapGroundData.LEVEL_HEIGHT - BARRIER_BELOW
	var top := levels.y * MapGroundData.LEVEL_HEIGHT + BARRIER_ABOVE
	var w := float(data.width)
	var d := float(data.depth)
	var corners: Array[Vector2] = [
		Vector2(0.0, 0.0), Vector2(w, 0.0), Vector2(w, d), Vector2(0.0, d)
	]
	for side in 4:
		if data.edges[MapGroundData.SIDES[side]] == "land":
			_wall(builder, corners[side], corners[(side + 1) % 4], bottom, top)


static func _wall(
	builder: MapGroundBuilder, a: Vector2, b: Vector2, bottom: float, top: float
) -> void:
	var a0 := Vector3(a.x, bottom, a.y)
	var b0 := Vector3(b.x, bottom, b.y)
	var a1 := Vector3(a.x, top, a.y)
	var b1 := Vector3(b.x, top, b.y)
	builder.barrier.append_array(PackedVector3Array([a0, b0, b1, a0, b1, a1]))


## Bruit stable dans [0, 1[ (comme IslandRock._hash).
static func _noise(a: float, b: float, seed_value: float) -> float:
	var n := sin(a * 12.9898 + b * 78.233 + seed_value * 37.719) * 43758.5453
	return n - floorf(n)
