extends GutTest
## (E3) Le rez-de-chaussée d'essai de l'entrepôt des fées (src/world/maps/entrepot_rdc_essai/,
## data/maps/entrepot_rdc_essai/interior.json), carte intérieure du contrat des cartes
## (docs/REFONTE.md, section 7.1) :
## - structure : racine Map (stub de E1), Ground (InteriorRoom), Geometry (PropBatcher, meubles
##   InteriorPanel), Markers (Spawn, from_*), Exits (MapExit devant leur porte), Life ;
## - circulation : depuis Spawn, à la taille du joueur, on atteint chaque pièce par ses portes,
##   on ne sort du bâtiment que par la porte d'entrée ; un corps qui marche passe une porte et
##   bute contre un mur ; la porte de la crypte est fermée ;
## - rien ne cache le joueur : de toute case praticable, la caméra du jeu (bornée à
##   camera_bounds) voit ses pieds, sa taille et sa tête, compte tenu de la coupe (murs, cloisons
##   et meubles au sud de la limite qui suit le joueur) ;
## - draw calls : un par matière (meubles fondus par image), au plus 200 par vue meublée.

const MAP_SCENE := preload("res://src/world/maps/entrepot_rdc_essai/entrepot_rdc_essai.tscn")
const CAMERA_RIG := preload("res://src/player/camera_rig.tscn")
const NO_CUT := InteriorLayout.NO_CUT
const ASPECT := 16.0 / 9.0
const PLAYER_RADIUS := 0.35
const PLAYER_HEIGHT := 1.5
## Grille de la marche (m) : assez fine pour passer une porte de 1,1 m avec le rayon du joueur.
const GRID := 0.25
## Points du corps du joueur vus par la caméra (m au-dessus des pieds).
const BODY: Array[float] = [0.25, 0.8, 1.4]
## Hauteur au-delà de laquelle rien ne peut cacher le joueur (le plus haut meuble : 2,1 m).
const OCCLUDER_TOP := 3.05
## Draw calls hors des matériaux de l'étage (personnages, ombres propres, interface,
## post-traitement) et budget d'une vue.
const OTHER_DRAW_CALLS := 30
const DRAW_CALL_BUDGET := 200
## Une case praticable hors des pièces doit être à moins de cela d'une porte vers l'extérieur.
const EXIT_REACH := 3.0

var _map: Node3D
var _room: InteriorRoom
var _space: PhysicsDirectSpaceState3D
var _pitch := 32.0
var _fov := 30.0
var _distance := 21.0
var _focus_height := 0.8
var _focus_ahead := 2.5
var _bounds := Rect2()
## Cases atteintes à pied depuis Spawn (clé : Vector2i de la grille).
var _reached: Dictionary = {}
## Triangles qui peuvent cacher le joueur, par ligne de coupe : {cut: {case 1 m: triangles}}.
var _occluders: Dictionary = {}


func before_all() -> void:
	_map = MAP_SCENE.instantiate() as Node3D
	add_child(_map)
	await wait_physics_frames(2)
	_room = _map.get_node(^"Ground") as InteriorRoom
	_space = _map.get_world_3d().direct_space_state
	var rig := CAMERA_RIG.instantiate()
	_pitch = rig.get(&"pitch_deg")
	_fov = rig.get(&"fov_deg")
	_distance = rig.get(&"distance")
	_focus_height = rig.get(&"focus_height")
	_focus_ahead = rig.get(&"focus_ahead")
	rig.free()
	_bounds = _map.get(&"camera_bounds")
	_walk()


func after_all() -> void:
	_map.free()


# --- Structure -------------------------------------------------------------------------------


func test_map_follows_the_contract() -> void:
	assert_eq(String(_map.name), "entrepot_rdc_essai", "racine nommée comme son map_id")
	assert_true(_map.get(&"interior"), "carte intérieure")
	assert_eq(_map.get(&"light_preset"), &"interieur", "préréglage de lumière des intérieurs")
	assert_eq(_map.get(&"region"), &"entrepot")
	assert_false(String(_map.get(&"display_name")).is_empty(), "nom affiché")
	var size: Vector2 = _map.get(&"size")
	assert_eq(Vector2i(size), _room.plan.map_size, "Map.size = size de interior.json")
	assert_true(Rect2(Vector2.ZERO, size).encloses(_bounds), "bornes de la caméra dans la carte")
	assert_eq(_room.plan.problems, [] as Array[String], "agencement sans faute")
	assert_true(_map.get_node(^"Geometry") is PropBatcher, "Geometry : PropBatcher")
	for child: String in ["Markers/Spawn", "Exits", "Life"]:
		assert_not_null(_map.get_node_or_null(NodePath(child)), child)
	var furniture := _map.get_node(^"Geometry").find_children("*", "InteriorPanel", true, false)
	assert_gt(furniture.size(), 40, "étage meublé")


func test_markers_stand_inside_and_exits_face_their_doors() -> void:
	for marker: Node in _map.get_node(^"Markers").get_children():
		var at := (marker as Marker3D).global_position
		assert_ne(_room.plan.room_at(at), &"", "%s dans une pièce" % marker.name)
		assert_true(_reached.has(_cell(at)), "%s atteint à pied" % marker.name)
		for exit: Node in _map.get_node(^"Exits").get_children():
			var gap := Vector2(at.x, at.z).distance_to(_flat((exit as Node3D).global_position))
			assert_gt(gap, 1.5, "%s à l'écart de la sortie %s" % [marker.name, exit.name])
	var exits := {"vers_entrepot": &"entree", "vers_crypte": &"crypte"}
	for exit_name: String in exits:
		var exit := _map.get_node(NodePath("Exits/" + exit_name)) as Area3D
		assert_false(StringName(exit.get(&"target_map")).is_empty(), "%s : carte visée" % exit_name)
		assert_eq(exit.collision_layer, 0, "%s : couche 0" % exit_name)
		assert_eq(exit.collision_mask, 2, "%s : masque player" % exit_name)
		var door := _room.door_position(exits[exit_name] as StringName)
		var gap := _flat(exit.global_position).distance_to(_flat(door))
		assert_lt(gap, 1.5, "%s devant sa porte" % exit_name)
	var closed := _map.get_node(^"Exits/vers_crypte")
	assert_false(String(closed.get(&"prompt")).is_empty(), "porte fermée : une interaction")
	assert_true(_blocked(_room.door_position(&"crypte")), "la porte de la crypte est fermée")


# --- Circulation -----------------------------------------------------------------------------


func test_every_room_is_reached_through_its_doors() -> void:
	var rooms := {}
	var outside: Array[String] = []
	var entrance := _room.door_position(&"entree")
	for cell: Vector2i in _reached:
		var at := _center(cell)
		var room := _room.plan.room_at(at)
		if room.is_empty():
			if _flat(at).distance_to(_flat(entrance)) > EXIT_REACH and outside.size() < 5:
				outside.append(str(_flat(at)))
		else:
			rooms[room] = true
	for item: Dictionary in _room.plan.rooms:
		assert_true(rooms.has(item["id"]), "%s atteinte à pied" % item["id"])
	assert_eq(outside, [] as Array[String], "hors du bâtiment seulement par la porte d'entrée")
	gut.p("%d cases praticables" % _reached.size())


func test_walls_stop_a_walking_body_and_doors_let_it_through() -> void:
	var body := CharacterBody3D.new()
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = PLAYER_RADIUS
	capsule.height = PLAYER_HEIGHT
	shape.shape = capsule
	shape.position.y = PLAYER_HEIGHT / 2.0 + 0.05
	body.add_child(shape)
	body.collision_layer = 2
	body.collision_mask = 1
	_map.add_child(body)
	var walks := {
		"porte du réfectoire": [Vector3(8.5, 0.0, 11.5), Vector3(0.0, 0.0, -3.0), false],
		"mur du réfectoire": [Vector3(6.0, 0.0, 11.5), Vector3(0.0, 0.0, -3.0), true],
		"porte de la cuisine": [Vector3(18.0, 0.0, 11.5), Vector3(0.0, 0.0, -2.5), false],
		"cloison réfectoire-cuisine": [Vector3(14.0, 0.0, 7.0), Vector3(3.0, 0.0, 0.0), true],
		"porte réfectoire-cuisine": [Vector3(14.0, 0.0, 4.0), Vector3(2.0, 0.0, 0.0), false],
		"porte de l'infirmerie": [Vector3(12.0, 0.0, 11.5), Vector3(0.0, 0.0, 3.5), false],
		"mur de l'infirmerie": [Vector3(10.0, 0.0, 11.5), Vector3(0.0, 0.0, 3.5), true],
		"porte d'entrée": [Vector3(19.0, 0.0, 19.0), Vector3(0.0, 0.0, 4.0), false],
		"mur de l'entrée": [Vector3(17.5, 0.0, 19.0), Vector3(0.0, 0.0, 4.0), true],
		"mur ouest": [Vector3(4.0, 0.0, 11.5), Vector3(-3.0, 0.0, 0.0), true],
	}
	for label: String in walks:
		var walk: Array = walks[label]
		body.global_position = walk[0] as Vector3
		var hits := body.test_move(body.global_transform, walk[1] as Vector3)
		assert_eq(hits, bool(walk[2]), label)
	body.free()


# --- Rien ne cache le joueur ------------------------------------------------------------------


func test_no_wall_or_furniture_hides_the_player() -> void:
	var hidden: Array[String] = []
	var checked := 0
	for cell: Vector2i in _reached:
		var feet := _center(cell)
		if _room.plan.room_at(feet).is_empty():
			continue
		var cut := _room.plan.cut_line_at(feet)
		var eye := _camera(feet).origin
		var buckets := _buckets_for(feet, cut)
		for height: float in BODY:
			checked += 1
			var target := feet + Vector3.UP * height
			var hit := _first_hit(eye, target, buckets)
			if not hit.is_empty() and hidden.size() < 8:
				hidden.append("%s à %.2f m : %s" % [_flat(feet), height, hit])
				break
	gut.p("%d rayons" % checked)
	assert_gt(checked, 6000, "toutes les cases praticables")
	assert_eq(hidden, [] as Array[String], "joueur caché par un mur ou un meuble")


func test_without_the_cut_walls_would_hide_the_player() -> void:
	# Le test d'occlusion voit bien les murs : sans coupe, le joueur du réfectoire, juste au nord
	# du mur du couloir, serait caché.
	var feet := Vector3(6.0, 0.0, 9.4)
	var eye := _camera(feet).origin
	var target := feet + Vector3.UP * 0.8
	assert_false(_first_hit(eye, target, _buckets(NO_CUT)).is_empty(), "sans coupe")
	assert_true(_first_hit(eye, target, _buckets(10.0)).is_empty(), "avec la coupe")
	# Dans la porte de la cloison réfectoire-cuisine, le bout de cloison au sud le cacherait,
	# vu par la tranche, sans la colonne de coupe.
	var door := Vector3(15.0, 0.0, 4.0)
	var eye_door := _camera(door).origin
	var cut := _room.plan.cut_line_at(door)
	var at_door := door + Vector3.UP * 0.8
	assert_false(_first_hit(eye_door, at_door, _buckets(cut)).is_empty(), "sans colonne")
	assert_true(_first_hit(eye_door, at_door, _buckets_for(door, cut)).is_empty(), "avec")


# --- Draw calls ------------------------------------------------------------------------------


func test_furniture_is_batched_by_image() -> void:
	var images := {}
	for panel: Node in _map.get_node(^"Geometry").find_children("*", "DecorPanel", true, false):
		images[(panel as DecorPanel).texture.resource_path] = true
	for decal: Node in _map.get_node(^"Geometry").find_children("*", "GroundDecal", true, false):
		images[(decal as GroundDecal).texture.resource_path] = true
	var batches := _batches()
	# Une image par lot, plus les ombres douces des meubles (un matériau partagé).
	assert_eq(batches.size(), images.size() + 1, "un draw call par image de meuble")


func test_each_furnished_view_stays_within_the_draw_call_budget() -> void:
	var meshes: Array[MeshInstance3D] = _batches()
	meshes.append_array(_room.surfaces())
	for item: Dictionary in _room.plan.rooms:
		var rect: Rect2i = (item["rects"] as Array)[0]
		var feet := Vector3(rect.get_center().x, 0.0, rect.get_center().y)
		var camera := _camera(feet)
		var drawn := 0
		for mesh in meshes:
			if _box_on_screen(camera, mesh.global_transform * mesh.get_aabb()):
				drawn += 1
		gut.p("%s : %d matériaux dans le champ" % [item["id"], drawn])
		assert_lte(drawn + OTHER_DRAW_CALLS, DRAW_CALL_BUDGET, "%s" % item["id"])


# --- Outils ----------------------------------------------------------------------------------


func _batches() -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for child: Node in _map.get_node(^"Geometry").get_children():
		var mesh := child as MeshInstance3D
		if mesh != null and mesh.mesh != null and String(mesh.name).begins_with("Batch"):
			out.append(mesh)
	return out


func _flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)


func _cell(at: Vector3) -> Vector2i:
	return Vector2i(floori(at.x / GRID), floori(at.z / GRID))


func _center(cell: Vector2i) -> Vector3:
	return Vector3((cell.x + 0.5) * GRID, 0.0, (cell.y + 0.5) * GRID)


## Vrai si le joueur (sa capsule) ne tient pas en at : un mur, un meuble.
func _blocked(at: Vector3) -> bool:
	var capsule := CapsuleShape3D.new()
	capsule.radius = PLAYER_RADIUS
	capsule.height = PLAYER_HEIGHT
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = 1
	query.transform = Transform3D(Basis.IDENTITY, at + Vector3.UP * (PLAYER_HEIGHT / 2.0 + 0.05))
	return not _space.intersect_shape(query, 1).is_empty()


## Vrai si at est dans une sortie qu'on franchit en marchant (prompt vide) : on change de carte.
func _leaves(at: Vector3) -> bool:
	for exit: Node in _map.get_node(^"Exits").get_children():
		if not String(exit.get(&"prompt")).is_empty():
			continue
		var shape := exit.get_child(0) as CollisionShape3D
		var box := (shape.shape as BoxShape3D).size
		var local := shape.global_transform.affine_inverse() * (at + Vector3.UP)
		if AABB(-box / 2.0, box).has_point(local):
			return true
	return false


## Cases atteintes à pied depuis Spawn, dans la carte ; on s'arrête dans une sortie.
func _walk() -> void:
	var start := _cell((_map.get_node(^"Markers/Spawn") as Node3D).global_position)
	var size: Vector2 = _map.get(&"size")
	var limit := Vector2i((size / GRID).ceil())
	var queue: Array[Vector2i] = [start]
	_reached[start] = true
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_back()
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := cell + step
			if next.x < 0 or next.y < 0 or next.x >= limit.x or next.y >= limit.y:
				continue
			if _reached.has(next) or _blocked(_center(next)):
				continue
			_reached[next] = true
			if not _leaves(_center(next)):
				queue.append(next)


## Caméra du jeu quand le joueur se tient en feet : le point visé (focus_ahead au nord du joueur)
## borné à camera_bounds, comme CameraRig.limits.
func _camera(feet: Vector3) -> Transform3D:
	var tilt := Basis(Vector3.RIGHT, deg_to_rad(-_pitch))
	var focus := feet + Vector3(0.0, _focus_height, -_focus_ahead)
	focus.x = clampf(focus.x, _bounds.position.x, _bounds.end.x)
	focus.z = clampf(focus.z, _bounds.position.y, _bounds.end.y)
	return Transform3D(tilt, focus + tilt.z * _distance)


## Premier obstacle entre eye et target parmi les triangles rangés (buckets) : « mur »,
## « meuble <nom> », ou vide.
func _first_hit(eye: Vector3, target: Vector3, buckets: Dictionary) -> String:
	# Seule la fin du rayon descend sous OCCLUDER_TOP : on n'y cherche que là.
	var t0 := clampf((eye.y - OCCLUDER_TOP) / maxf(eye.y - target.y, 0.001), 0.0, 1.0)
	var from := eye.lerp(target, t0)
	var lo := Vector2i(floori(minf(from.x, target.x)), floori(minf(from.z, target.z)))
	var hi := Vector2i(floori(maxf(from.x, target.x)), floori(maxf(from.z, target.z)))
	for x in range(lo.x, hi.x + 1):
		for z in range(lo.y, hi.y + 1):
			for entry: Array in buckets.get(Vector2i(x, z), []):
				var tri: PackedVector3Array = entry[1]
				for i in range(0, tri.size(), 3):
					if Geometry3D.segment_intersects_triangle(
						from, target, tri[i], tri[i + 1], tri[i + 2]
					):
						return String(entry[0])
	return ""


## Triangles qui peuvent cacher un joueur en feet (limite de coupe cut) : ceux de la coupe seule,
## ou, si un mur nord-sud passe sous lui (porte d'une cloison), avec sa colonne de coupe.
func _buckets_for(feet: Vector3, cut: float) -> Dictionary:
	var line := roundi(feet.x)
	if absf(feet.x - line) >= InteriorRoom.COLUMN_HALF:
		return _buckets(cut)
	var from := feet.z + InteriorRoom.COLUMN_FRONT
	for piece: Dictionary in _room.plan.pieces:
		if (
			int(piece["axis"]) == InteriorLayout.VERTICAL
			and int(piece["line"]) == line
			and float(piece["b"]) > from
			and float(piece["a"]) < from + InteriorRoom.COLUMN_LENGTH
		):
			return _buckets(cut, feet)
	return _buckets(cut)


## Triangles qui peuvent cacher le joueur pour une coupe donnée (murs d'InteriorRoom, meubles),
## rangés par case d'un mètre de leur emprise ; player : place du joueur pour la colonne de
## coupe (Vector3.INF : sans colonne, gardés pour chaque coupe).
func _buckets(cut: float, player: Vector3 = Vector3.INF) -> Dictionary:
	if not player.is_finite() and _occluders.has(cut):
		return _occluders[cut]
	var buckets := {}
	var cut_world := NO_CUT if cut >= NO_CUT else _room.to_global(Vector3(0.0, 0.0, cut)).z
	var walls := _room.occluder_triangles(cut_world, player)
	for i in range(0, walls.size(), 3):
		_bucket(buckets, "mur", walls.slice(i, i + 3))
	for panel: Node in _map.get_node(^"Geometry").find_children("*", "InteriorPanel", true, false):
		var quad := (panel as InteriorPanel).occluder_triangles(cut_world)
		_bucket(buckets, "meuble %s" % panel.name, quad)
	if not player.is_finite():
		_occluders[cut] = buckets
	return buckets


func _bucket(buckets: Dictionary, label: String, tri: PackedVector3Array) -> void:
	var box := AABB(tri[0], Vector3.ZERO)
	for point in tri:
		box = box.expand(point)
	for x in range(floori(box.position.x), floori(box.end.x) + 1):
		for z in range(floori(box.position.z), floori(box.end.z) + 1):
			var key := Vector2i(x, z)
			if not buckets.has(key):
				buckets[key] = []
			(buckets[key] as Array).append([label, tri])


## Position à l'écran (x, y de -1 à 1 au bord du cadre) et profondeur d'un point.
func _project(camera: Transform3D, point: Vector3) -> Vector3:
	var local := camera.affine_inverse() * point
	var depth := -local.z
	if depth <= 0.05:
		return Vector3(INF, INF, depth)
	var half := tan(deg_to_rad(_fov) / 2.0)
	return Vector3(local.x / (depth * half * ASPECT), local.y / (depth * half), depth)


## Vrai si la boîte n'est pas écartée par le cadre (comme le tri de la caméra, sans le loin).
func _box_on_screen(camera: Transform3D, box: AABB) -> bool:
	var outside := [0, 0, 0, 0]
	for i in 8:
		var p := _project(camera, box.get_endpoint(i))
		if p.z <= 0.05:
			return true
		outside[0] += 1 if p.x < -1.0 else 0
		outside[1] += 1 if p.x > 1.0 else 0
		outside[2] += 1 if p.y < -1.0 else 0
		outside[3] += 1 if p.y > 1.0 else 0
	return not outside.has(8)
