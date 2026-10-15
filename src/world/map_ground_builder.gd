@tool
class_name MapGroundBuilder
extends RefCounted
## Construction du sol en relief d'une carte extérieure (MapGround) à partir de ses données
## (MapGroundData) : triangles du sol, faces verticales, collision ; la côte, son rideau de roche
## et les barrières viennent de MapGroundCoast. Tout est en coordonnées de la carte (origine au
## coin nord-ouest, x vers l'est, z vers le sud).
##
## - Sol (un mesh, un draw call) : les cases plates fondues en grands rectangles par palier ; les
##   cases que la côte peut couper (coast_value() = 0 : MapGroundData) découpées en
##   COAST_SUBDIV × COAST_SUBDIV et coupées sur la côte ; les rampes (un plan incliné par volée
##   large) ; les marches des escaliers. UV.x : distance approchée au vide (m, COAST_FAR loin de la
##   côte), pour la lèvre de pierre du shader.
## - Faces (un mesh avec le rideau, un draw call) : entre deux cases de paliers différents, sur la
##   ligne de la grille, tournées vers la plus basse (fondues le long d'une ligne) ; contremarches ;
##   joues des escaliers et des rampes. Les faces tournées vers le nord, que la caméra fixe ne voit
##   jamais, ne vont que dans la collision. UV : (m le long de la face, m sous son arête haute) ;
##   UV2 : (style MapGroundData.Face, tuile de l'atlas ou hauteur de la face).
## - Collision : les triangles du sol et des faces, les mêmes que l'on voit.

## Valeur de UV.x loin de la côte (m).
const COAST_FAR := 4.0
## Types de case du prolongement.
const NONE := 0
const FLAT := 1
const RIM := 2
const STRUCTURE := 3
## Marge (cases) de la grille de travail autour du prolongement : fenêtres de la côte et coins.
const MARGIN := MapGroundData.RIM_ZONE + 1

var ground_vertices := PackedVector3Array()
var ground_normals := PackedVector3Array()
var ground_uvs := PackedVector2Array()
var ground_indices := PackedInt32Array()
var cliff_vertices := PackedVector3Array()
var cliff_normals := PackedVector3Array()
var cliff_uvs := PackedVector2Array()
var cliff_uv2s := PackedVector2Array()
var cliff_indices := PackedInt32Array()
## Triangles des faces pour la collision (trois sommets chacun, face avant vers le bas du palier).
var collision := PackedVector3Array()
## Triangles de la barrière (collision des deux côtés).
var barrier := PackedVector3Array()
## Segments de la côte (p, q), la terre à droite de p → q vu du dessus.
var rim := PackedVector3Array()
## Chaînes de la côte (MapGroundCoast.chain).
var chains: Array[PackedVector3Array] = []

var _data: MapGroundData
## Prolongement (cases bâties) : coin nord-ouest, taille.
var _x0: int = 0
var _z0: int = 0
var _w: int = 0
var _d: int = 0
## Grille de travail (prolongement plus MARGIN) : palier et case de la carte de chaque case
## (VOID_LEVEL, -1 : le vide), table cumulée des cases vides, champ lisse de la côte aux coins.
var _gx0: int = 0
var _gz0: int = 0
var _gw: int = 0
var _gd: int = 0
var _glevel := PackedInt32Array()
var _gcell := PackedInt32Array()
var _sat := PackedInt32Array()
var _corners := PackedFloat32Array()
var _corner_known := PackedByteArray()
## Par case du prolongement : type, palier, case de la carte (-1 : aucune, ou débord de la côte).
var _type := PackedByteArray()
var _level := PackedInt32Array()
var _cell := PackedInt32Array()
var _level_min: int = 0
var _level_max: int = 0


## Construit tout à partir des données.
func build(data: MapGroundData) -> void:
	_data = data
	var reach := MapGroundData.RIM_ZONE
	_x0 = -data.ext_left if data.edges["west"] == "land" else -reach
	_z0 = -data.ext_top if data.edges["north"] == "land" else -reach
	var x1 := data.width + (data.ext_right if data.edges["east"] == "land" else reach)
	var z1 := data.depth + (data.ext_bottom if data.edges["south"] == "land" else reach)
	_w = x1 - _x0
	_d = z1 - _z0
	_grid()
	_classify()
	_flat_rectangles()
	_rim_cells()
	_structures()
	_faces()
	MapGroundCoast.build(self, data, Vector2i(_level_min, _level_max))
	if data.barrier:
		_closed_barriers()


# --- Grille, vide, côte ---------------------------------------------------------------------------


## Grille de travail : chaque case y vaut la case de la carte qui la représente
## (MapGroundData.lookup, sans limite de prolongement), ou le vide.
func _grid() -> void:
	var data := _data
	_gx0 = _x0 - MARGIN
	_gz0 = _z0 - MARGIN
	_gw = _w + 2 * MARGIN
	_gd = _d + 2 * MARGIN
	var cols := PackedInt32Array()
	cols.resize(_gw)
	for gi in _gw:
		cols[gi] = _clamp_axis(_gx0 + gi, data.width, data.edges["west"], data.edges["east"])
	var rows := PackedInt32Array()
	rows.resize(_gd)
	for gj in _gd:
		rows[gj] = _clamp_axis(_gz0 + gj, data.depth, data.edges["north"], data.edges["south"])
	_glevel.resize(_gw * _gd)
	_gcell.resize(_gw * _gd)
	var stride := _gw + 1
	_sat.resize(stride * (_gd + 1))
	_sat.fill(0)
	for gj in _gd:
		var row := rows[gj]
		var run := 0
		for gi in _gw:
			var g := gj * _gw + gi
			var level := MapGroundData.VOID_LEVEL
			var c := -1
			if row >= 0 and cols[gi] >= 0:
				c = row * data.width + cols[gi]
				level = data.levels[c]
			_glevel[g] = level
			_gcell[g] = c
			if level == MapGroundData.VOID_LEVEL:
				run += 1
			_sat[(gj + 1) * stride + gi + 1] = _sat[gj * stride + gi + 1] + run
	_corners.resize(stride * (_gd + 1))
	_corner_known.resize(stride * (_gd + 1))
	_corner_known.fill(0)


## Indice sur un axe de la carte (0 à size − 1) de la position p, prolongée du côté « land »,
## -1 du côté « void ».
static func _clamp_axis(p: int, size: int, before: String, after: String) -> int:
	if p < 0:
		return -1 if before == "void" else 0
	if p >= size:
		return -1 if after == "void" else size - 1
	return p


## Cases vides dans le rectangle de cases [i0, i1] × [j0, j1] (bornes comprises, coordonnées de la
## carte, dans la grille de travail).
func _voids(i0: int, j0: int, i1: int, j1: int) -> int:
	var stride := _gw + 1
	var a := i0 - _gx0
	var b := j0 - _gz0
	var c := i1 - _gx0 + 1
	var d := j1 - _gz0 + 1
	return _sat[d * stride + c] - _sat[b * stride + c] - _sat[d * stride + a] + _sat[b * stride + a]


## Champ lisse de la côte au coin (ci, cj), comme MapGroundData.coast_base().
func _corner(ci: int, cj: int) -> float:
	var k := (cj - _gz0) * (_gw + 1) + ci - _gx0
	if _corner_known[k] == 0:
		_corners[k] = (16 - _voids(ci - 2, cj - 2, ci + 1, cj + 1)) / 16.0 - 0.5
		_corner_known[k] = 1
	return _corners[k]


## Champ de la côte au sommet (x, z) du découpage, comme MapGroundData.coast_vertex().
func _coast(x: float, z: float) -> float:
	var i := floori(x)
	var j := floori(z)
	var fx := x - i
	var fz := z - j
	var top := lerpf(_corner(i, j), _corner(i + 1, j), fx)
	var bottom := lerpf(_corner(i, j + 1), _corner(i + 1, j + 1), fx)
	return lerpf(top, bottom, fz) + MapGroundData.COAST_WOBBLE * MapGroundData.coast_noise(x, z)


## Palier commun de la terre plate autour de (x, z), comme MapGroundData.fill_level_at().
func _fill_level(x: int, z: int) -> int:
	var found := MapGroundData.VOID_LEVEL
	var reach := MapGroundData.RIM_ZONE
	for dj in range(-reach, reach + 1):
		var row := (z + dj - _gz0) * _gw - _gx0
		for di in range(-reach, reach + 1):
			var g := row + x + di
			var level := _glevel[g]
			if level == MapGroundData.VOID_LEVEL:
				continue
			if _data.kinds[_gcell[g]] != MapGroundData.Kind.FLAT:
				return MapGroundData.VOID_LEVEL
			if found != MapGroundData.VOID_LEVEL and level != found:
				return MapGroundData.VOID_LEVEL
			found = level
	return found


## Type de chaque case du prolongement : plate (entière), coupée par la côte, volée, ou rien.
func _classify() -> void:
	var count := _w * _d
	_type.resize(count)
	_level.resize(count)
	_cell.resize(count)
	_level_min = 1 << 20
	_level_max = -(1 << 20)
	var reach := MapGroundData.RIM_ZONE
	var window := (2 * reach + 1) * (2 * reach + 1)
	var wobble := MapGroundData.COAST_WOBBLE
	var kinds := _data.kinds
	var stride := _gw + 1
	# Fenêtre (2 reach + 1)² de la table cumulée, autour de la case (i, j) : coins décalés.
	var low_offset := (MARGIN - reach) * stride + MARGIN - reach
	var span := 2 * reach + 1
	var near := PackedByteArray()
	near.resize(count)
	for j in _d:
		var z := _z0 + j
		for i in _w:
			var k := j * _w + i
			var x := _x0 + i
			var g := (j + MARGIN) * _gw + i + MARGIN
			var level := _glevel[g]
			var c := _gcell[g]
			var s := j * stride + i + low_offset
			var voids := (
				_sat[s + span * stride + span] - _sat[s + span] - _sat[s + span * stride] + _sat[s]
			)
			near[k] = int(voids > 0)
			_type[k] = NONE
			_level[k] = level
			_cell[k] = c
			if level != MapGroundData.VOID_LEVEL and kinds[c] != MapGroundData.Kind.FLAT:
				_type[k] = STRUCTURE
			elif voids == 0:
				_type[k] = FLAT
			elif level != MapGroundData.VOID_LEVEL:
				_type[k] = FLAT if _corner_min(x, z) - wobble >= 0.0 else RIM
			elif voids < window and _corner_max(x, z) + wobble > 0.0:
				# Le vide près de la terre d'un seul palier : la côte y déborde.
				var fill := _fill_level(x, z)
				if fill != MapGroundData.VOID_LEVEL:
					_level[k] = fill
					_cell[k] = -1
					_type[k] = FLAT if _corner_min(x, z) - wobble >= 0.0 else RIM
			if _type[k] != NONE:
				_level_min = mini(_level_min, _level[k])
				_level_max = maxi(_level_max, _level[k])
	# Une case plate qui touche une case sans sol (vide sans débord possible) est bordée de côte.
	for k in count:
		if near[k] == 0 or _type[k] != FLAT:
			continue
		var i := k % _w
		var j := floori(float(k) / _w)
		if (
			(i > 0 and _type[k - 1] == NONE)
			or (i + 1 < _w and _type[k + 1] == NONE)
			or (j > 0 and _type[k - _w] == NONE)
			or (j + 1 < _d and _type[k + _w] == NONE)
		):
			_type[k] = RIM


func _corner_min(x: int, z: int) -> float:
	return minf(
		minf(_corner(x, z), _corner(x + 1, z)), minf(_corner(x, z + 1), _corner(x + 1, z + 1))
	)


func _corner_max(x: int, z: int) -> float:
	return maxf(
		maxf(_corner(x, z), _corner(x + 1, z)), maxf(_corner(x, z + 1), _corner(x + 1, z + 1))
	)


func _height(k: int) -> float:
	return _level[k] * MapGroundData.LEVEL_HEIGHT


# --- Sol ------------------------------------------------------------------------------------------


## Ajoute au sol le rectangle horizontal [x0, x1] × [z0, z1] à la hauteur y (deux triangles, face
## avant vers le ciel), UV.x = COAST_FAR.
func _ground_rect(x0: float, z0: float, x1: float, z1: float, y: float) -> void:
	var base := ground_vertices.size()
	ground_vertices.append_array(
		PackedVector3Array(
			[Vector3(x0, y, z0), Vector3(x1, y, z0), Vector3(x1, y, z1), Vector3(x0, y, z1)]
		)
	)
	var far := Vector2(COAST_FAR, 0.0)
	ground_normals.append_array(
		PackedVector3Array([Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP])
	)
	ground_uvs.append_array(PackedVector2Array([far, far, far, far]))
	# Nord-ouest, nord-est, sud-ouest ; nord-est, sud-est, sud-ouest (sens horaire vu du dessus).
	ground_indices.append_array(
		PackedInt32Array([base, base + 1, base + 3, base + 1, base + 2, base + 3])
	)


## Cases plates entières : rectangles d'un même palier, étendus le long de la rangée, puis vers le
## sud tant que la rangée suivante est libre et du même palier sur toute la largeur.
func _flat_rectangles() -> void:
	# Clé de chaque case : palier + 1 pour une case plate entière, 0 sinon ; mise à 0 une fois
	# prise dans un rectangle.
	var keys := PackedInt32Array()
	keys.resize(_w * _d)
	for k in keys.size():
		keys[k] = _level[k] - MapGroundData.VOID_LEVEL + 1 if _type[k] == FLAT else 0
	for j in _d:
		var row := j * _w
		var i := 0
		while i < _w:
			var key := keys[row + i]
			if key == 0:
				i += 1
				continue
			var i1 := i
			while i1 + 1 < _w and keys[row + i1 + 1] == key:
				i1 += 1
			var j1 := j
			var span := keys.slice(row + i, row + i1 + 1)
			while j1 + 1 < _d and keys.slice((j1 + 1) * _w + i, (j1 + 1) * _w + i1 + 1) == span:
				j1 += 1
			for jj in range(j, j1 + 1):
				for ii in range(i, i1 + 1):
					keys[jj * _w + ii] = 0
			var y := (key - 1 + MapGroundData.VOID_LEVEL) * MapGroundData.LEVEL_HEIGHT
			_ground_rect(_x0 + i, _z0 + j, _x0 + i1 + 1, _z0 + j1 + 1, y)
			i = i1 + 1


## Cases coupées par la côte : découpées, coupées sur la côte ; segments de la côte (sur la ligne
## coupée, et le long des côtés qui touchent une case sans sol).
func _rim_cells() -> void:
	var n := MapGroundData.COAST_SUBDIV
	var step := 1.0 / n
	var wobble := MapGroundData.COAST_WOBBLE
	var values := PackedFloat32Array()
	values.resize((n + 1) * (n + 1))
	for j in _d:
		for i in _w:
			var k := j * _w + i
			if _type[k] != RIM:
				continue
			var x0 := _x0 + i
			var z0 := _z0 + j
			var y := _height(k)
			var b00 := _corner(x0, z0)
			var b10 := _corner(x0 + 1, z0)
			var b01 := _corner(x0, z0 + 1)
			var b11 := _corner(x0 + 1, z0 + 1)
			var base := ground_vertices.size()
			for b in n + 1:
				var fz := b * step
				var pz := z0 + fz
				for a in n + 1:
					var fx := a * step
					var px := x0 + fx
					var top := lerpf(b00, b10, fx)
					var bottom := lerpf(b01, b11, fx)
					var v := lerpf(top, bottom, fz) + wobble * MapGroundData.coast_noise(px, pz)
					values[b * (n + 1) + a] = v
					ground_vertices.append(Vector3(px, y, pz))
					ground_normals.append(Vector3.UP)
					ground_uvs.append(
						Vector2(clampf(v / MapGroundData.COAST_GRADIENT, 0.0, COAST_FAR), 0.0)
					)
			var cut := {}
			for b in n:
				for a in n:
					var g := b * (n + 1) + a
					var v00 := values[g]
					var v10 := values[g + 1]
					var v01 := values[g + n + 1]
					var v11 := values[g + n + 2]
					if v00 >= 0.0 and v10 >= 0.0 and v01 >= 0.0 and v11 >= 0.0:
						# Sous-case entière (le plus souvent) : ses deux triangles tels quels.
						var q := base + g
						ground_indices.append_array(
							PackedInt32Array([q, q + 1, q + n + 1, q + 1, q + n + 2, q + n + 1])
						)
					elif v00 >= 0.0 or v10 >= 0.0 or v01 >= 0.0 or v11 >= 0.0:
						_clip(base, values, Vector3i(g, g + 1, g + n + 1), y, cut)
						_clip(base, values, Vector3i(g + 1, g + n + 2, g + n + 1), y, cut)
			_rim_sides(i, j, values, y)


## Triangle (corners : indices locaux, sens horaire vu du dessus) gardé là où la côte est
## positive ; le segment coupé va dans rim, la terre à droite.
func _clip(
	base: int, values: PackedFloat32Array, corners: Vector3i, y: float, cut: Dictionary
) -> void:
	var a := corners.x
	var b := corners.y
	var c := corners.z
	var in_a := values[a] >= 0.0
	var in_b := values[b] >= 0.0
	var in_c := values[c] >= 0.0
	var inside := int(in_a) + int(in_b) + int(in_c)
	if inside == 3:
		ground_indices.append_array(PackedInt32Array([base + a, base + b, base + c]))
	elif inside == 1:
		var lone := Vector3i(a, b, c)
		if in_b:
			lone = Vector3i(b, c, a)
		elif in_c:
			lone = Vector3i(c, a, b)
		var p := _crossing(base, values, lone.x, lone.y, y, cut)
		var q := _crossing(base, values, lone.z, lone.x, y, cut)
		ground_indices.append_array(PackedInt32Array([base + lone.x, p, q]))
		rim.append_array(PackedVector3Array([ground_vertices[p], ground_vertices[q]]))
	elif inside == 2:
		var pair := Vector3i(a, b, c)
		if not in_a:
			pair = Vector3i(b, c, a)
		elif not in_b:
			pair = Vector3i(c, a, b)
		var p := _crossing(base, values, pair.y, pair.z, y, cut)
		var q := _crossing(base, values, pair.z, pair.x, y, cut)
		ground_indices.append_array(
			PackedInt32Array([base + pair.x, base + pair.y, p, base + pair.x, p, q])
		)
		rim.append_array(PackedVector3Array([ground_vertices[p], ground_vertices[q]]))


## Sommet de la côte sur l'arête (u, v) du découpage (un bout dedans, l'autre dehors), partagé par
## les deux triangles qui la bordent ; interpolé depuis le bout du plus petit (x, z), pour que la
## case voisine trouve le même point.
func _crossing(
	base: int, values: PackedFloat32Array, u: int, v: int, y: float, cut: Dictionary
) -> int:
	var key := mini(u, v) * 1024 + maxi(u, v)
	if cut.has(key):
		return cut[key]
	var pu := ground_vertices[base + u]
	var pv := ground_vertices[base + v]
	var at := cross_point(Vector2(pu.x, pu.z), values[u], Vector2(pv.x, pv.z), values[v])
	var index := ground_vertices.size()
	ground_vertices.append(Vector3(at.x, y, at.y))
	ground_normals.append(Vector3.UP)
	ground_uvs.append(Vector2.ZERO)
	cut[key] = index
	return index


## Point où la côte (valeurs vp en p, vq en q, de signes opposés) coupe le segment p q, interpolé
## depuis le bout du plus petit (x, z) : le même point, au bit près, pour les deux cases qui
## partagent l'arête et pour les faces qui s'y arrêtent.
static func cross_point(p: Vector2, vp: float, q: Vector2, vq: float) -> Vector2:
	if q.x < p.x or (q.x == p.x and q.y < p.y):
		return q.lerp(p, vq / (vq - vp))
	return p.lerp(q, vp / (vp - vq))


## Côtés d'une case coupée qui touchent une case sans sol : la part positive de chaque arête du
## découpage va dans rim (parcours horaire : la terre à droite).
func _rim_sides(i: int, j: int, values: PackedFloat32Array, y: float) -> void:
	var n := MapGroundData.COAST_SUBDIV
	var x0 := float(_x0 + i)
	var z0 := float(_z0 + j)
	for side in 4:
		var dir := MapGroundData.DIRECTIONS[side]
		var ni := i + dir.x
		var nj := j + dir.y
		if ni >= 0 and nj >= 0 and ni < _w and nj < _d and _type[nj * _w + ni] != NONE:
			continue
		for s in n:
			# Sommets locaux (a, b) des deux bouts de la s-ième arête du côté, dans le sens horaire.
			var ends := _side_edge(side, s, n)
			var va := values[ends.y * (n + 1) + ends.x]
			var vb := values[ends.w * (n + 1) + ends.z]
			if va < 0.0 and vb < 0.0:
				continue
			var a := Vector2(x0 + float(ends.x) / n, z0 + float(ends.y) / n)
			var b := Vector2(x0 + float(ends.z) / n, z0 + float(ends.w) / n)
			if va < 0.0:
				a = cross_point(a, va, b, vb)
			elif vb < 0.0:
				b = cross_point(a, va, b, vb)
			rim.append_array(PackedVector3Array([Vector3(a.x, y, a.y), Vector3(b.x, y, b.y)]))


## Les deux bouts (sommets locaux (x, y) puis (z, w)) de la s-ième arête du côté side d'une case
## découpée en n, dans le sens horaire vu du dessus : nord d'ouest en est, est du nord au sud, sud
## d'est en ouest, ouest du sud au nord.
static func _side_edge(side: int, s: int, n: int) -> Vector4i:
	match side:
		0:
			return Vector4i(s, 0, s + 1, 0)
		1:
			return Vector4i(n, s, n, s + 1)
		2:
			return Vector4i(n - s, n, n - s - 1, n)
		_:
			return Vector4i(0, n - s, 0, n - s - 1)


# --- Escaliers et rampes --------------------------------------------------------------------------


## Point de la volée qui part de la case start dans la direction dir, à l'abscisse s (cases, depuis
## le bas) et à la position w en travers (x pour une volée nord-sud, z pour une volée est-ouest).
static func run_point(start: Vector2i, dir: int, s: float, w: float, y: float) -> Vector3:
	match dir:
		0:
			return Vector3(w, y, start.y + 1 - s)
		1:
			return Vector3(start.x + s, y, w)
		2:
			return Vector3(w, y, start.y + s)
		_:
			return Vector3(start.x + 1 - s, y, w)


## Volées larges : cases de départ voisines en travers, de même profil, regroupées ; puis leur
## sol, leurs contremarches et leurs joues.
func _structures() -> void:
	var data := _data
	var done := {}
	for c in data.width * data.depth:
		if data.kinds[c] == MapGroundData.Kind.FLAT or data.run_index[c] != 0 or done.has(c):
			continue
		if data.run_low[c] >= data.run_high[c]:
			continue
		var dir := int(data.directions[c])
		var across := Vector2i(1, 0) if dir % 2 == 0 else Vector2i(0, 1)
		var start := Vector2i(c % data.width, floori(float(c) / data.width))
		var last := start
		done[c] = true
		while true:
			var next := last + across
			if not data.in_map(next.x, next.y):
				break
			var k := next.y * data.width + next.x
			if not _same_profile(c, k):
				break
			done[k] = true
			last = next
		var w0 := float(start.x if dir % 2 == 0 else start.y)
		var w1 := float(last.x if dir % 2 == 0 else last.y) + 1.0
		if data.kinds[c] == MapGroundData.Kind.RAMP:
			_ramp(c, start, dir, Vector2(w0, w1))
		else:
			_stairs(c, start, dir, Vector2(w0, w1))
		_run_sides(c, start, dir, Vector2(w0 - 1.0, w0), -1.0)
		_run_sides(c, start, dir, Vector2(w1, w1), 1.0)


func _same_profile(c: int, k: int) -> bool:
	var data := _data
	return (
		data.kinds[k] == data.kinds[c]
		and data.directions[k] == data.directions[c]
		and data.run_index[k] == 0
		and data.run_length[k] == data.run_length[c]
		and data.run_low[k] == data.run_low[c]
		and data.run_high[k] == data.run_high[c]
	)


## Rampe : un plan incliné sur la largeur across (w0, w1).
func _ramp(c: int, start: Vector2i, dir: int, across: Vector2) -> void:
	var count := float(_data.run_length[c])
	var low := _data.run_low[c]
	var high := _data.run_high[c]
	var a := run_point(start, dir, 0.0, across.x, low)
	var b := run_point(start, dir, 0.0, across.y, low)
	var e := run_point(start, dir, count, across.y, high)
	var f := run_point(start, dir, count, across.x, high)
	var normal := (e - a).cross(b - a).normalized()
	if normal.y < 0.0:
		normal = -normal
	_ground_quad(PackedVector3Array([a, b, e, f]), normal)


## Escalier : marches (au sol) et contremarches (faces, tuile de la matière de la volée).
func _stairs(c: int, start: Vector2i, dir: int, across: Vector2) -> void:
	var data := _data
	var steps := data.stair_steps(c)
	var tread := float(data.run_length[c]) / steps
	var low := data.run_low[c]
	var layer := int(data.material_specs[data.cell_material(start.x, start.y)]["layer"])
	var back := Vector3(-MapGroundData.DIRECTIONS[dir].x, 0.0, -MapGroundData.DIRECTIONS[dir].y)
	for m in steps:
		var y0 := low + MapGroundData.STAIR_RISER * m
		var y1 := low + MapGroundData.STAIR_RISER * (m + 1)
		var s0 := tread * m
		var s1 := tread * (m + 1)
		_ground_quad(
			PackedVector3Array(
				[
					run_point(start, dir, s0, across.x, y1),
					run_point(start, dir, s0, across.y, y1),
					run_point(start, dir, s1, across.y, y1),
					run_point(start, dir, s1, across.x, y1),
				]
			),
			Vector3.UP
		)
		var p := run_point(start, dir, s0, across.x, 0.0)
		var q := run_point(start, dir, s0, across.y, 0.0)
		_face(
			PackedVector2Array([Vector2(p.x, p.z), Vector2(q.x, q.z)]),
			Vector4(y0, y0, y1, y1),
			back,
			Vector2i(MapGroundData.Face.ATLAS, layer)
		)


## Joues d'une volée d'un côté (place : (position en travers de la case voisine, position de la
## joue)) : face entre le profil de la volée et le sol plat d'à côté, tournée vers le plus bas des
## deux. outward : sens (−1 ou 1) de la voisine en travers.
func _run_sides(c: int, start: Vector2i, dir: int, place: Vector2, outward: float) -> void:
	var data := _data
	var d := MapGroundData.DIRECTIONS[dir]
	var side := Vector3(absf(d.y) * outward, 0.0, absf(d.x) * outward)
	for k in data.run_length[c]:
		var cell := Vector2i(start.x + d.x * k, start.y + d.y * k)
		var neighbor := (
			Vector2i(int(place.x), cell.y) if dir % 2 == 0 else Vector2i(cell.x, int(place.x))
		)
		var e := _ext(neighbor.x, neighbor.y)
		if e < 0 or (_type[e] != FLAT and _type[e] != RIM):
			continue
		var ground := _height(e)
		var cuts := PackedFloat32Array([float(k)])
		if data.kinds[c] == MapGroundData.Kind.STAIRS:
			var tread := float(data.run_length[c]) / data.stair_steps(c)
			var m := floori(k / tread) + 1
			while m * tread < k + 1 - 0.0001:
				cuts.append(m * tread)
				m += 1
		else:
			var rise := data.run_high[c] - data.run_low[c]
			var t := (ground - data.run_low[c]) / rise * data.run_length[c]
			if t > k + 0.0001 and t < k + 0.9999:
				cuts.append(t)
		cuts.append(float(k + 1))
		for n in cuts.size() - 1:
			_side_piece(c, start, dir, Vector3(place.y, cuts[n], cuts[n + 1]), ground, side, e)


## Morceau de joue (span : position de la joue, abscisses s0 et s1) : la volée au-dessus du sol
## voisin (face tournée vers lui), ou le sol voisin au-dessus de la volée (face tournée vers la
## volée).
func _side_piece(
	c: int, start: Vector2i, dir: int, span: Vector3, ground: float, side: Vector3, neighbor: int
) -> void:
	var data := _data
	var stairs := data.kinds[c] == MapGroundData.Kind.STAIRS
	var y0 := data.run_height(c, span.y + 0.00001) if stairs else data.run_height(c, span.y)
	var y1 := y0 if stairs else data.run_height(c, span.z)
	var mid := (y0 + y1) * 0.5
	if absf(mid - ground) < 0.001:
		return
	var p := run_point(start, dir, span.y, span.x, 0.0)
	var q := run_point(start, dir, span.z, span.x, 0.0)
	var line := PackedVector2Array([Vector2(p.x, p.z), Vector2(q.x, q.z)])
	if mid > ground:
		var style: int = MapGroundData.Face.WALL if stairs else MapGroundData.Face.EARTH
		if data.faces[c] != MapGroundData.NO_FACE:
			style = data.faces[c]
		_face(line, Vector4(ground, ground, y0, y1), side, Vector2i(style, 0))
	else:
		var style := data.face_style(_cell[neighbor], ground - minf(y0, y1))
		_face(line, Vector4(y0, y1, ground, ground), -side, Vector2i(style, 0))


## Quadrilatère du sol (corners dans l'ordre du tour), face avant vers normal.
func _ground_quad(corners: PackedVector3Array, normal: Vector3) -> void:
	var base := ground_vertices.size()
	ground_vertices.append_array(corners)
	var far := Vector2(COAST_FAR, 0.0)
	ground_normals.append_array(PackedVector3Array([normal, normal, normal, normal]))
	ground_uvs.append_array(PackedVector2Array([far, far, far, far]))
	var a := corners[0]
	if (corners[2] - a).cross(corners[1] - a).dot(normal) > 0.0:
		ground_indices.append_array(
			PackedInt32Array([base, base + 1, base + 2, base, base + 2, base + 3])
		)
	else:
		ground_indices.append_array(
			PackedInt32Array([base, base + 2, base + 1, base, base + 3, base + 2])
		)


# --- Faces verticales -----------------------------------------------------------------------------


## Indice de la case (x, z) du prolongement, ou -1 en dehors.
func _ext(x: int, z: int) -> int:
	var i := x - _x0
	var j := z - _z0
	if i < 0 or j < 0 or i >= _w or j >= _d:
		return -1
	return j * _w + i


## Face verticale sur le segment line[0] → line[1] (plan x, z) ; heights : (bas en a, bas en b,
## haut en a, haut en b) ; tournée vers normal (horizontale, unitaire) ; look : (style, tuile).
## Elle va dans la collision ; dans le mesh des faces si la caméra fixe (vers le nord) peut la voir.
func _face(line: PackedVector2Array, heights: Vector4, normal: Vector3, look: Vector2i) -> void:
	if heights.z - heights.x < 0.0001 and heights.w - heights.y < 0.0001:
		return
	var a := line[0]
	var b := line[1]
	var pa := Vector3(a.x, heights.x, a.y)
	var pb := Vector3(b.x, heights.y, b.y)
	var qb := Vector3(b.x, heights.w, b.y)
	var qa := Vector3(a.x, heights.z, a.y)
	var front := (qb - pa).cross(pb - pa).dot(normal) >= 0.0
	if front:
		collision.append_array(PackedVector3Array([pa, pb, qb, pa, qb, qa]))
	else:
		collision.append_array(PackedVector3Array([pa, qb, pb, pa, qa, qb]))
	if normal.z < -0.5:
		return
	# u croît vers la droite de qui regarde la face (vers −normal).
	var right := Vector2(-normal.z, normal.x)
	var base := cliff_vertices.size()
	cliff_vertices.append_array(PackedVector3Array([pa, pb, qb, qa]))
	cliff_normals.append_array(PackedVector3Array([normal, normal, normal, normal]))
	var ua := right.dot(a)
	var ub := right.dot(b)
	(
		cliff_uvs
		. append_array(
			PackedVector2Array(
				[
					Vector2(ua, heights.z - heights.x),
					Vector2(ub, heights.w - heights.y),
					Vector2(ub, 0.0),
					Vector2(ua, 0.0),
				]
			)
		)
	)
	# UV2.y : tuile de l'atlas (contremarche), sinon hauteur de la face (ombre à son pied).
	var atlas := look.x == MapGroundData.Face.ATLAS
	var ha := float(look.y) if atlas else heights.z - heights.x
	var hb := float(look.y) if atlas else heights.w - heights.y
	cliff_uv2s.append_array(
		PackedVector2Array(
			[Vector2(look.x, ha), Vector2(look.x, hb), Vector2(look.x, hb), Vector2(look.x, ha)]
		)
	)
	if front:
		cliff_indices.append_array(
			PackedInt32Array([base, base + 1, base + 2, base, base + 2, base + 3])
		)
	else:
		cliff_indices.append_array(
			PackedInt32Array([base, base + 2, base + 1, base, base + 3, base + 2])
		)


## Faces entre cases plates (entières ou coupées) de paliers différents, sur les lignes de la
## grille ; celles des cases entières fondues le long d'une ligne quand elles se suivent à
## l'identique.
func _faces() -> void:
	# Une ligne dont les deux rangées (ou colonnes) ont les mêmes paliers n'a pas de face.
	var above := _level.slice(0, _w)
	for j in range(1, _d):
		var below := _level.slice(j * _w, (j + 1) * _w)
		_face_line(j, true, above, below)
		above = below
	var columns := PackedInt32Array()
	columns.resize(_w * _d)
	for j in _d:
		for i in _w:
			columns[i * _d + j] = _level[j * _w + i]
	var west := columns.slice(0, _d)
	for i in range(1, _w):
		var east := columns.slice(i * _d, (i + 1) * _d)
		_face_line(i, false, west, east)
		west = east


## Ligne de la grille : horizontale (z = _z0 + line, entre la rangée du nord et celle du sud) ou
## verticale (x = _x0 + line, entre la colonne de l'ouest et celle de l'est).
func _face_line(
	line: int, horizontal: bool, first_levels: PackedInt32Array, second_levels: PackedInt32Array
) -> void:
	if first_levels == second_levels:
		return
	var count := _w if horizontal else _d
	var run_start := -1
	var run_key := Vector3i.ZERO
	for t in count + 1:
		var key := Vector3i.ZERO
		var mergeable := false
		if t < count and first_levels[t] != second_levels[t]:
			var first := (line - 1) * _w + t if horizontal else t * _w + line - 1
			var second := line * _w + t if horizontal else t * _w + line
			var ta := _type[first]
			var tb := _type[second]
			if (
				ta != NONE
				and tb != NONE
				and ta != STRUCTURE
				and tb != STRUCTURE
				and _level[first] != _level[second]
			):
				if ta == RIM or tb == RIM:
					_clipped_face(line, t, horizontal, Vector2i(first, second))
				else:
					var high := first if _level[first] > _level[second] else second
					var style := _data.face_style(
						_cell[high], absf(_height(first) - _height(second))
					)
					key = Vector3i(_level[first], _level[second], style)
					mergeable = true
		if run_start >= 0 and (not mergeable or key != run_key):
			_line_face(line, horizontal, Vector2i(run_start, t), run_key)
			run_start = -1
		if mergeable and run_start < 0:
			run_start = t
			run_key = key


## Face fondue de la ligne, des positions span.x à span.y, entre les paliers de key (premier côté :
## nord ou ouest ; puis style).
func _line_face(line: int, horizontal: bool, span: Vector2i, key: Vector3i) -> void:
	var first := key.x * MapGroundData.LEVEL_HEIGHT
	var second := key.y * MapGroundData.LEVEL_HEIGHT
	var a := Vector2(_x0 + span.x, _z0 + line) if horizontal else Vector2(_x0 + line, _z0 + span.x)
	var b := Vector2(_x0 + span.y, _z0 + line) if horizontal else Vector2(_x0 + line, _z0 + span.y)
	var toward_second := Vector3(0.0, 0.0, 1.0) if horizontal else Vector3(1.0, 0.0, 0.0)
	var low := minf(first, second)
	var high := maxf(first, second)
	var normal := toward_second if first > second else -toward_second
	_face(PackedVector2Array([a, b]), Vector4(low, low, high, high), normal, Vector2i(key.z, 0))


## Face entre deux cases (cells : celle du nord ou de l'ouest, l'autre) dont l'une au moins est
## coupée par la côte : coupée elle aussi, arête par arête du découpage (mêmes sommets que le sol).
func _clipped_face(line: int, t: int, horizontal: bool, cells: Vector2i) -> void:
	var n := MapGroundData.COAST_SUBDIV
	var y_first := _height(cells.x)
	var y_second := _height(cells.y)
	var high_k := cells.x if y_first > y_second else cells.y
	var style := _data.face_style(_cell[high_k], absf(y_first - y_second))
	var toward_second := Vector3(0.0, 0.0, 1.0) if horizontal else Vector3(1.0, 0.0, 0.0)
	var normal := toward_second if y_first > y_second else -toward_second
	var low := minf(y_first, y_second)
	var high := maxf(y_first, y_second)
	var origin := Vector2(_x0 + t, _z0 + line) if horizontal else Vector2(_x0 + line, _z0 + t)
	var along := Vector2(1.0 / n, 0.0) if horizontal else Vector2(0.0, 1.0 / n)
	for s in n:
		var a := origin + along * s
		var b := origin + along * (s + 1)
		var va := _coast(a.x, a.y)
		var vb := _coast(b.x, b.y)
		if va < 0.0 and vb < 0.0:
			continue
		if va < 0.0:
			a = cross_point(a, va, b, vb)
		elif vb < 0.0:
			b = cross_point(a, va, b, vb)
		_face(PackedVector2Array([a, b]), Vector4(low, low, high, high), normal, Vector2i(style, 0))


## Barrière autour des matières qu'on ne foule pas (eau dormante) : le long de chaque côté de pixel
## de materials.png entre une matière praticable et une qui ne l'est pas, sur une case plate.
func _closed_barriers() -> void:
	var data := _data
	var s := data.materials_scale
	var w := data.width * s
	var h := data.depth * s
	var pixels := data.pixel_materials
	var size := 1.0 / s
	for index in data.material_specs.size():
		if bool(data.material_specs[index]["walkable"]):
			continue
		var p := pixels.find(index)
		while p >= 0:
			var x := p % w
			var y := floori(float(p) / w)
			var c := floori(float(y) / s) * data.width + floori(float(x) / s)
			if (
				data.levels[c] != MapGroundData.VOID_LEVEL
				and data.kinds[c] == MapGroundData.Kind.FLAT
			):
				var floor_y := data.levels[c] * MapGroundData.LEVEL_HEIGHT
				var x0 := x * size
				var z0 := y * size
				if x > 0 and _walkable_pixel(pixels[p - 1]):
					_barrier_wall(Vector2(x0, z0), Vector2(x0, z0 + size), floor_y)
				if x + 1 < w and _walkable_pixel(pixels[p + 1]):
					_barrier_wall(Vector2(x0 + size, z0), Vector2(x0 + size, z0 + size), floor_y)
				if y > 0 and _walkable_pixel(pixels[p - w]):
					_barrier_wall(Vector2(x0, z0), Vector2(x0 + size, z0), floor_y)
				if y + 1 < h and _walkable_pixel(pixels[p + w]):
					_barrier_wall(Vector2(x0, z0 + size), Vector2(x0 + size, z0 + size), floor_y)
			p = pixels.find(index, p + 1)


func _walkable_pixel(index: int) -> bool:
	return bool(_data.material_specs[index]["walkable"])


## Mur invisible de la barrière sur le segment a → b, du sol floor_y − 1 à floor_y + 2 m.
func _barrier_wall(a: Vector2, b: Vector2, floor_y: float) -> void:
	var a0 := Vector3(a.x, floor_y - 1.0, a.y)
	var b0 := Vector3(b.x, floor_y - 1.0, b.y)
	var a1 := Vector3(a.x, floor_y + 2.0, a.y)
	var b1 := Vector3(b.x, floor_y + 2.0, b.y)
	barrier.append_array(PackedVector3Array([a0, b0, b1, a0, b1, a1]))


# --- Sorties --------------------------------------------------------------------------------------


## Mesh du sol (une surface).
func ground_mesh(material: Material) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = ground_vertices
	arrays[Mesh.ARRAY_NORMAL] = ground_normals
	arrays[Mesh.ARRAY_TEX_UV] = ground_uvs
	arrays[Mesh.ARRAY_INDEX] = ground_indices
	var mesh := ArrayMesh.new()
	if not ground_indices.is_empty():
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(0, material)
	return mesh


## Mesh des faces et du rideau (une surface).
func cliff_mesh(material: Material) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = cliff_vertices
	arrays[Mesh.ARRAY_NORMAL] = cliff_normals
	arrays[Mesh.ARRAY_TEX_UV] = cliff_uvs
	arrays[Mesh.ARRAY_TEX_UV2] = cliff_uv2s
	arrays[Mesh.ARRAY_INDEX] = cliff_indices
	var mesh := ArrayMesh.new()
	if not cliff_indices.is_empty():
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(0, material)
	return mesh


## Triangles de la collision : le sol (mêmes triangles que son mesh), puis les faces.
func collision_faces() -> PackedVector3Array:
	var faces := PackedVector3Array()
	faces.resize(ground_indices.size())
	for n in ground_indices.size():
		faces[n] = ground_vertices[ground_indices[n]]
	faces.append_array(collision)
	return faces
