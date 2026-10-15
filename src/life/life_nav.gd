class_name LifeNav
extends RefCounted
## (E4) Navigation des PNJ sur une carte : une grille (1 m dehors, 0,5 m dedans), un graphe
## AStar2D (C++, compatible Web mono-thread) et des chemins lissés. Propriétaire : E4.
##
## Praticabilité d'un point : celle du sol de la carte (MapGround.is_walkable dehors ;
## InteriorRoom dedans : une pièce, hors de l'épaisseur des murs debout, ce que fait
## InteriorRoom.is_walkable, relevé une fois en bitmap pour aller vite), et hors des collisions
## des meubles et décors (formes de la couche 1 hors du sol, élargies de PROP_MARGIN). Deux
## cases voisines sont reliées si les points entre elles le sont et que le sol ne monte ni ne
## descend de plus de MAX_RISE d'un point au suivant (escaliers et rampes oui, falaises, talus
## et murets non) ; une diagonale, si ses deux côtés le sont (on ne coupe pas les coins). La
## construction est découpée (build_step, budget en microsecondes par image) : pas de pic
## d'image à l'entrée d'une carte ; find_path attend ready.

enum Kind { FLAT, OUTDOOR, INTERIOR }

const OUTDOOR_CELL := 1.0
const INDOOR_CELL := 0.5
## Montée ou descente permise d'un point de mesure au suivant (m) : marches de 0,1 à 0,17 m,
## rampes ; un talus de 0,5 m (qu'on franchit en sautant) arrête.
const MAX_RISE := 0.3
## Pas des mesures le long d'une arête et d'une ligne droite (m).
const SAMPLE_STEP := 0.25
## Pas des mesures le long d'une arête du graphe (m) : assez fin pour qu'une marche de talus
## (0,5 m d'un coup) dépasse MAX_RISE, assez large pour construire vite.
const EDGE_STEP := 0.34
## Élargissement des collisions des meubles (m) : le corps du PNJ.
const PROP_MARGIN := 0.2
## Une collision ne gêne que si elle occupe cette tranche au-dessus du sol (m) : ni un tapis, ni
## un auvent.
const BODY_LOW := 0.12
const BODY_HIGH := 1.5
## Résolution du relevé des murs d'un intérieur (m).
const WALL_RES := 0.125
## Lissage : on regarde au plus SMOOTH_LOOKAHEAD points plus loin (coût borné par chemin).
const SMOOTH_LOOKAHEAD := 40
## Cases mesurées ou reliées par pas de construction (un morceau de rangée) : un pas reste
## court même dans le build Web (WebAssembly, plusieurs fois plus lent).
const SEGMENT_COLS := 8
const STAGE_WALLS := 0
const STAGE_CELLS := 1
const STAGE_BOXES := 2
const STAGE_PROPS := 3
const STAGE_GRAPH := 4
const STAGE_DIAGONALS := 5
const STAGE_DONE := 6

## Taille d'une case (m) et nombre de cases.
var cell: float = OUTDOOR_CELL
var size: Vector2i = Vector2i.ZERO
var kind: Kind = Kind.FLAT
## Vrai quand la grille et le graphe sont prêts.
var ready: bool = false
## Mesures : durée de construction (µs de travail), nombre d'images, cases praticables.
var build_usec: int = 0
var build_frames: int = 0
## Pas de construction le plus long (µs) : la mesure du découpage.
var build_max_usec: int = 0

var _map: Node3D
var _ground: Node
var _area: Rect2
var _walk := PackedByteArray()
var _height := PackedFloat32Array()
var _prop := PackedByteArray()
var _wall := PackedByteArray()
var _wall_size := Vector2i.ZERO
var _boxes: Array[AABB] = []
var _astar := AStar2D.new()
var _stage: int = STAGE_WALLS
var _row: int = 0
var _col: int = 0
## Pièce de mur ou boîte de décor en cours (étapes WALLS et PROPS : une par pas).
var _item: int = 0
var _disabled: Array[int] = []
## Cases évitées pendant le calcul d'un chemin (find_path, avoid) : le lissage non plus.
var _avoided: Dictionary = {}


## Grille d'une carte (Map) : le type de sol décide de la taille des cases ; rien n'est encore
## mesuré (build_step, build_now).
static func for_map(map: Node3D) -> LifeNav:
	var nav := LifeNav.new()
	nav._map = map
	nav._ground = map.get_node_or_null(^"Ground") if map != null else null
	var area := Rect2(0.0, 0.0, 40.0, 30.0)
	if map is Map:
		area = (map as Map).area()
	nav._area = area
	if nav._ground is InteriorRoom:
		nav.kind = Kind.INTERIOR
		nav.cell = INDOOR_CELL
	elif nav._ground is MapGround:
		nav.kind = Kind.OUTDOOR
		nav.cell = OUTDOOR_CELL
	else:
		nav.kind = Kind.FLAT
		nav.cell = OUTDOOR_CELL
	nav.size = Vector2i(ceili(area.size.x / nav.cell), ceili(area.size.y / nav.cell))
	nav._walk.resize(nav.size.x * nav.size.y)
	nav._height.resize(nav.size.x * nav.size.y)
	nav._prop.resize(nav.size.x * nav.size.y)
	return nav


## Avance la construction d'au plus budget_usec µs ; vrai quand tout est prêt.
func build_step(budget_usec: int) -> bool:
	if ready:
		return true
	var started := Time.get_ticks_usec()
	build_frames += 1
	while not ready and Time.get_ticks_usec() - started < budget_usec:
		match _stage:
			STAGE_WALLS:
				if _wall_step():
					_item = 0
					_stage = STAGE_CELLS
			STAGE_CELLS:
				_measure_row(_row, _col, _segment_end())
				if _next_segment():
					_stage = STAGE_BOXES
			STAGE_BOXES:
				_collect_props()
				_item = 0
				_stage = STAGE_PROPS
			STAGE_PROPS:
				if _item >= _boxes.size():
					_stage = STAGE_GRAPH
				else:
					_mark_box(_item)
					_item += 1
			STAGE_GRAPH:
				_graph_row(_row, _col, _segment_end())
				if _next_segment():
					_stage = STAGE_DIAGONALS
			STAGE_DIAGONALS:
				_diagonal_row(_row, _col, _segment_end())
				if _next_segment():
					_stage = STAGE_DONE
					ready = true
	var spent := Time.get_ticks_usec() - started
	build_usec += spent
	build_max_usec = maxi(build_max_usec, spent)
	return ready


## Construit tout d'un coup (tests, démonstrations).
func build_now() -> void:
	while not build_step(1_000_000):
		pass


# --- Requêtes ---------------------------------------------------------------------------------


## Case d'un point (repère de la carte, x et z).
func cell_of(point: Vector3) -> Vector2i:
	return Vector2i(
		floori((point.x - _area.position.x) / cell), floori((point.z - _area.position.y) / cell)
	)


## Centre d'une case, à la hauteur du sol.
func center(at: Vector2i) -> Vector3:
	var x := _area.position.x + (at.x + 0.5) * cell
	var z := _area.position.y + (at.y + 0.5) * cell
	return Vector3(x, height_at(x, z), z)


## Vrai si la case existe et qu'on peut s'y tenir (sol et meubles).
func is_open(at: Vector2i) -> bool:
	if at.x < 0 or at.y < 0 or at.x >= size.x or at.y >= size.y:
		return false
	var index := at.y * size.x + at.x
	return _walk[index] == 1 and _prop[index] == 0


## Vrai si l'on peut se tenir au point (x, z) : sol praticable, hors des meubles.
func is_walkable_point(x: float, z: float) -> bool:
	if not _sample_walkable(x, z):
		return false
	var at := cell_of(Vector3(x, 0.0, z))
	if at.x < 0 or at.y < 0 or at.x >= size.x or at.y >= size.y:
		return false
	return not ready or _prop[at.y * size.x + at.x] == 0


## Hauteur du sol en (x, z).
func height_at(x: float, z: float) -> float:
	match kind:
		Kind.OUTDOOR:
			var h := (_ground as MapGround).height_at(x, z)
			return h if h > MapGround.VOID_HEIGHT + 1.0 else 0.0
		Kind.INTERIOR:
			return (_ground as InteriorRoom).height_at(x, z)
	return 0.0


## Vrai si l'on va de a à b en ligne droite (mesures tous les SAMPLE_STEP : sol, meubles, pas de
## marche trop haute).
func line_clear(a: Vector3, b: Vector3) -> bool:
	var flat := Vector2(b.x - a.x, b.z - a.z)
	var steps := maxi(1, ceili(flat.length() / SAMPLE_STEP))
	var previous := height_at(a.x, a.z)
	for i: int in range(1, steps + 1):
		var t := float(i) / steps
		var x := lerpf(a.x, b.x, t)
		var z := lerpf(a.z, b.z, t)
		if not is_walkable_point(x, z):
			return false
		if not _avoided.is_empty() and _avoided.has(cell_of(Vector3(x, 0.0, z))):
			return false
		var h := height_at(x, z)
		if absf(h - previous) > MAX_RISE:
			return false
		previous = h
	return true


## Vrai si un mur debout (relevé WALL_RES) coupe le segment de a à b, dedans ; jamais dehors.
func _wall_between(a: Vector3, b: Vector3) -> bool:
	if kind != Kind.INTERIOR or _wall.is_empty():
		return false
	var steps := maxi(1, ceili(Vector2(b.x - a.x, b.z - a.z).length() / (WALL_RES * 0.5)))
	for i: int in range(1, steps):
		var t := float(i) / steps
		var wx := floori(lerpf(a.x, b.x, t) / WALL_RES)
		var wz := floori(lerpf(a.z, b.z, t) / WALL_RES)
		if wx < 0 or wz < 0 or wx >= _wall_size.x or wz >= _wall_size.y:
			continue
		# Un mur de 0,25 m n'a souvent que des pixels « à cheval sur son bord » (1) : tout pixel de mur
		# compte.
		if _wall[wz * _wall_size.x + wx] > 0:
			return true
	return false


## Case praticable reliée au graphe la plus proche d'un point (à moins de max_cells cases) ;
## Vector2i(-1, -1) sinon.
func nearest_open(point: Vector3, max_cells: int = 6) -> Vector2i:
	var origin := cell_of(point)
	if is_open(origin) and _astar.has_point(_id(origin)):
		return origin
	var best := Vector2i(-1, -1)
	var best_distance := INF
	for radius: int in range(1, max_cells + 1):
		for dz: int in range(-radius, radius + 1):
			for dx: int in range(-radius, radius + 1):
				if absi(dx) != radius and absi(dz) != radius:
					continue
				var at := origin + Vector2i(dx, dz)
				if not is_open(at) or not _astar.has_point(_id(at)):
					continue
				var d := center(at).distance_squared_to(point)
				# (V1) Dedans, la case la plus proche est dans la même pièce : jamais à travers un mur
				# (un lit contre la porte d'un dortoir ne finit pas dans le couloir d'à côté).
				if d < best_distance and _wall_between(point, center(at)):
					continue
				if d < best_distance:
					best_distance = d
					best = at
		if best.x >= 0:
			return best
	return best


## Chemin de from à to (repère de la carte) : points au sol, lissé (lignes droites quand elles
## sont libres), du premier point après from jusqu'au centre de la case libre la plus proche de
## to (le dernier pas, vers un siège, se fait à part). avoid : cases à éviter (PNJ arrêtés, le
## joueur). Vide si pas de chemin (ou grille pas prête).
func find_path(from: Vector3, to: Vector3, avoid: Array[Vector2i] = []) -> PackedVector3Array:
	var result := PackedVector3Array()
	if not ready:
		return result
	var start := nearest_open(from)
	var goal := nearest_open(to)
	if start.x < 0 or goal.x < 0:
		return result
	_avoided.clear()
	for at: Vector2i in avoid:
		_avoided[at] = true
		var id := _id(at)
		if at != start and at != goal and _astar.has_point(id) and not _astar.is_point_disabled(id):
			_astar.set_point_disabled(id, true)
			_disabled.append(id)
	var ids := _astar.get_id_path(_id(start), _id(goal))
	for id: int in _disabled:
		_astar.set_point_disabled(id, false)
	_disabled.clear()
	if ids.is_empty():
		return result
	var raw := PackedVector3Array()
	raw.append(from)
	for id: int in ids:
		raw.append(center(Vector2i(id % size.x, floori(float(id) / size.x))))
	var smoothed := _smooth(raw)
	_avoided.clear()
	return smoothed


## Nombre de cases praticables (mesures).
func open_count() -> int:
	var count := 0
	for i: int in _walk.size():
		if _walk[i] == 1 and _prop[i] == 0:
			count += 1
	return count


# --- Construction -----------------------------------------------------------------------------


func _id(at: Vector2i) -> int:
	return at.y * size.x + at.x


## Praticabilité du sol seul au point (x, z).
func _sample_walkable(x: float, z: float) -> bool:
	if not _area.has_point(Vector2(x, z)):
		return false
	match kind:
		Kind.OUTDOOR:
			return (_ground as MapGround).is_walkable(x, z)
		Kind.INTERIOR:
			var room := _ground as InteriorRoom
			if room.plan == null or room.room_at(x, z).is_empty():
				return false
			var wx := floori(x / WALL_RES)
			var wz := floori(z / WALL_RES)
			if wx < 0 or wz < 0 or wx >= _wall_size.x or wz >= _wall_size.y:
				return false
			# Dans un mur : non ; au bord d'un mur : la réponse exacte du sol.
			var wall := _wall[wz * _wall_size.x + wx]
			return wall == 0 or (wall == 1 and room.is_walkable(x, z))
	return true


## Relevé des murs debout d'un intérieur (les pièces de mur au sol, comme
## InteriorRoom.is_walkable), une pièce par appel ; vrai quand tout est relevé (ou sans murs).
func _wall_step() -> bool:
	var room := _ground as InteriorRoom
	if kind != Kind.INTERIOR or room == null or room.plan == null:
		return true
	if _wall.is_empty():
		_wall_size = Vector2i(ceili(_area.end.x / WALL_RES) + 1, ceili(_area.end.y / WALL_RES) + 1)
		_wall.resize(_wall_size.x * _wall_size.y)
		_wall.fill(0)
		_item = 0
	if _item >= room.plan.pieces.size():
		return true
	_wall_piece(room, room.plan.pieces[_item])
	_item += 1
	return false


func _wall_piece(room: InteriorRoom, piece: Dictionary) -> void:
	if float(piece["y0"]) <= 0.0:
		var box := room.plan.piece_box(piece)
		var x0 := maxi(0, floori((box.position.x - 0.001) / WALL_RES))
		var x1 := mini(_wall_size.x - 1, floori((box.end.x + 0.001) / WALL_RES))
		var z0 := maxi(0, floori((box.position.z - 0.001) / WALL_RES))
		var z1 := mini(_wall_size.y - 1, floori((box.end.z + 0.001) / WALL_RES))
		for wz: int in range(z0, z1 + 1):
			for wx: int in range(x0, x1 + 1):
				# 2 : pixel tout entier dans le mur ; 1 : à cheval sur son bord.
				var inside := (
					wx * WALL_RES > box.position.x + 0.001
					and (wx + 1) * WALL_RES < box.end.x - 0.001
					and wz * WALL_RES > box.position.z + 0.001
					and (wz + 1) * WALL_RES < box.end.z - 0.001
				)
				var index := wz * _wall_size.x + wx
				_wall[index] = 2 if inside else maxi(_wall[index], 1)


func _segment_end() -> int:
	return mini(_col + SEGMENT_COLS, size.x)


## Passe au morceau de rangée suivant ; vrai (et retour au début) à la fin de la grille.
func _next_segment() -> bool:
	_col += SEGMENT_COLS
	if _col >= size.x:
		_col = 0
		_row += 1
	if _row >= size.y:
		_row = 0
		return true
	return false


func _measure_row(row: int, col0: int, col1: int) -> void:
	for col: int in range(col0, col1):
		var x := _area.position.x + (col + 0.5) * cell
		var z := _area.position.y + (row + 0.5) * cell
		var index := row * size.x + col
		_walk[index] = 1 if _sample_walkable(x, z) else 0
		_height[index] = height_at(x, z) if _walk[index] == 1 else 0.0


## Collisions des décors et meubles (couche 1, hors du sol, de la vie et des sorties), en
## boîtes dans le repère de la carte ; _mark_box les pose ensuite une par une.
func _collect_props() -> void:
	_boxes.clear()
	if _map == null:
		return
	var skip: Array[Node] = []
	for child_name: String in ["Ground", "Life", "Exits", "Markers"]:
		var node := _map.get_node_or_null(NodePath(child_name))
		if node != null:
			skip.append(node)
	_collect_boxes(_map, skip)
	var inverse := (_map as Node3D).global_transform.affine_inverse()
	for i: int in _boxes.size():
		_boxes[i] = inverse * _boxes[i]


## Une boîte élargie marque les cases qu'elle couvre dans la tranche du corps.
func _mark_box(index: int) -> void:
	var box := _boxes[index]
	var x0 := maxi(0, floori((box.position.x - PROP_MARGIN - _area.position.x) / cell))
	var x1 := mini(size.x - 1, floori((box.end.x + PROP_MARGIN - _area.position.x) / cell))
	var z0 := maxi(0, floori((box.position.z - PROP_MARGIN - _area.position.y) / cell))
	var z1 := mini(size.y - 1, floori((box.end.z + PROP_MARGIN - _area.position.y) / cell))
	for row: int in range(z0, z1 + 1):
		for col: int in range(x0, x1 + 1):
			var c := center(Vector2i(col, row))
			var inside_x := c.x > box.position.x - PROP_MARGIN and c.x < box.end.x + PROP_MARGIN
			var inside_z := c.z > box.position.z - PROP_MARGIN and c.z < box.end.z + PROP_MARGIN
			var ground := _height[row * size.x + col]
			var overlaps := box.end.y > ground + BODY_LOW and box.position.y < ground + BODY_HIGH
			if inside_x and inside_z and overlaps:
				_prop[row * size.x + col] = 1


func _collect_boxes(node: Node, skip: Array[Node]) -> void:
	if skip.has(node):
		return
	if node is CollisionShape3D and not (node as CollisionShape3D).disabled:
		var owner_body := node.get_parent() as CollisionObject3D
		if owner_body != null and owner_body.collision_layer & 1:
			var shape := (node as CollisionShape3D).shape
			if shape != null:
				_boxes.append((node as Node3D).global_transform * shape_box(shape))
	for child: Node in node.get_children():
		_collect_boxes(child, skip)


## Boîte d'une forme dans son repère, sans construire son maillage de débogage (lent) pour les
## formes simples.
static func shape_box(shape: Shape3D) -> AABB:
	if shape is BoxShape3D:
		var half := (shape as BoxShape3D).size * 0.5
		return AABB(-half, half * 2.0)
	if shape is SphereShape3D:
		var r := (shape as SphereShape3D).radius
		return AABB(-Vector3.ONE * r, Vector3.ONE * r * 2.0)
	if shape is CapsuleShape3D:
		var capsule := shape as CapsuleShape3D
		var half_c := Vector3(capsule.radius, capsule.height * 0.5, capsule.radius)
		return AABB(-half_c, half_c * 2.0)
	if shape is CylinderShape3D:
		var cylinder := shape as CylinderShape3D
		var half_y := Vector3(cylinder.radius, cylinder.height * 0.5, cylinder.radius)
		return AABB(-half_y, half_y * 2.0)
	return shape.get_debug_mesh().get_aabb()


func _graph_row(row: int, col0: int, col1: int) -> void:
	for col: int in range(col0, col1):
		var at := Vector2i(col, row)
		if not is_open(at):
			continue
		var id := _id(at)
		var c := center(at)
		_astar.add_point(id, Vector2(c.x, c.z))
		for step: Vector2i in [Vector2i(-1, 0), Vector2i(0, -1)]:
			var other := at + step
			if is_open(other) and _edge_clear(at, other):
				_astar.connect_points(id, _id(other))


## Diagonales d'une rangée, une fois toutes les arêtes droites posées : une diagonale si les
## quatre côtés du carré sont reliés (on ne coupe pas les coins).
func _diagonal_row(row: int, col0: int, col1: int) -> void:
	for col: int in range(col0, col1):
		var at := Vector2i(col, row)
		var id := _id(at)
		if not _astar.has_point(id):
			continue
		for step: Vector2i in [Vector2i(-1, -1), Vector2i(1, -1)]:
			var other := at + step
			var side_a := at + Vector2i(step.x, 0)
			var side_b := at + Vector2i(0, step.y)
			if (
				_connected(at, side_a)
				and _connected(at, side_b)
				and _connected(side_a, other)
				and _connected(side_b, other)
			):
				_astar.connect_points(id, _id(other))


func _connected(a: Vector2i, b: Vector2i) -> bool:
	var id_a := _id(a)
	var id_b := _id(b)
	if a.x < 0 or a.y < 0 or b.x < 0 or b.y < 0 or a.x >= size.x or b.x >= size.x:
		return false
	return (
		_astar.has_point(id_a)
		and _astar.has_point(id_b)
		and _astar.are_points_connected(id_a, id_b)
	)


## Arête entre deux cases voisines : mesures le long du segment (sol, marches).
func _edge_clear(a: Vector2i, b: Vector2i) -> bool:
	var pa := center(a)
	var pb := center(b)
	var steps := maxi(2, ceili(cell / EDGE_STEP))
	var previous := pa.y
	for i: int in range(1, steps):
		var t := float(i) / steps
		var x := lerpf(pa.x, pb.x, t)
		var z := lerpf(pa.z, pb.z, t)
		if not _sample_walkable(x, z):
			return false
		var h := height_at(x, z)
		if absf(h - previous) > MAX_RISE:
			return false
		previous = h
	return absf(pb.y - previous) <= MAX_RISE


## Lissage : du premier point, on va aussi loin que la ligne droite le permet, et ainsi de suite.
func _smooth(raw: PackedVector3Array) -> PackedVector3Array:
	var result := PackedVector3Array()
	var i := 0
	while i < raw.size() - 1:
		var j := i + 1
		while j + 1 < raw.size() and j - i < SMOOTH_LOOKAHEAD and cells_clear(raw[i], raw[j + 1]):
			j += 1
		# Le segment retenu, mesuré pour de bon (un montant de porte, un coin de meuble) : on
		# recule jusqu'à ce qu'il soit libre (le pas suivant du chemin brut l'est toujours).
		while j > i + 1 and not line_clear(raw[i], raw[j]):
			j -= 1
		result.append(raw[j])
		i = j
	return result


## Vrai si la ligne droite de a à b ne passe que par des cases du graphe reliées entre elles
## (parcours des cases traversées, DDA ; les arêtes du graphe portent déjà murs, portes,
## marches et meubles) : bien plus rapide que line_clear, pour le lissage. La case de départ
## peut être hors du graphe (un siège).
func cells_clear(a: Vector3, b: Vector3) -> bool:
	var current := cell_of(a)
	var goal := cell_of(b)
	var x0 := (a.x - _area.position.x) / cell
	var z0 := (a.z - _area.position.y) / cell
	var dx := (b.x - a.x) / cell
	var dz := (b.z - a.z) / cell
	var step_x := 1 if dx > 0.0 else -1
	var step_z := 1 if dz > 0.0 else -1
	var next_x := (floorf(x0) + (1.0 if dx > 0.0 else 0.0) - x0) / dx if absf(dx) > 1e-6 else INF
	var next_z := (floorf(z0) + (1.0 if dz > 0.0 else 0.0) - z0) / dz if absf(dz) > 1e-6 else INF
	var delta_x := absf(1.0 / dx) if absf(dx) > 1e-6 else INF
	var delta_z := absf(1.0 / dz) if absf(dz) > 1e-6 else INF
	var first := true
	var guard := 0
	while current != goal and guard < 4 * (size.x + size.y):
		guard += 1
		var moves: Array[Vector2i] = []
		if next_x < next_z - 1e-6:
			moves.append(Vector2i(step_x, 0))
			next_x += delta_x
		elif next_z < next_x - 1e-6:
			moves.append(Vector2i(0, step_z))
			next_z += delta_z
		else:
			# Par un coin : les deux côtés doivent être libres.
			if not _linked_cells(current, current + Vector2i(step_x, 0), first):
				return false
			if not _linked_cells(current, current + Vector2i(0, step_z), first):
				return false
			moves.append(Vector2i(step_x, 0))
			moves.append(Vector2i(0, step_z))
			next_x += delta_x
			next_z += delta_z
		for move: Vector2i in moves:
			var following := current + move
			if not _linked_cells(current, following, first):
				return false
			current = following
			first = false
	return current == goal


func _linked_cells(a: Vector2i, b: Vector2i, leaving: bool) -> bool:
	if not is_open(b) or _avoided.has(b):
		return false
	var id_b := _id(b)
	if not _astar.has_point(id_b):
		return false
	var id_a := _id(a)
	if not _astar.has_point(id_a):
		return leaving
	return _astar.are_points_connected(id_a, id_b)
