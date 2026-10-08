extends GutTest
## (Lot P3) Le port et le bourg posés (src/world/zones/beach/beach.tscn ; docs/ASSETS_HD2D_MONDE.md,
## sections 0 et 14 ; docs/lore/MONDE.md, 2.5), dans l'île sans le contenu des emplacements :
##
## - densité et variété : de 25 à 80 décors à l'écran depuis la rue, le marché, le quai et la
##   butte, au moins un qui bouge (bande animée), jamais deux images identiques côte à côte
##   (hors modules faits pour se suivre : clôture, garde-corps, bordures, bornes) ;
## - chemins : la rue du Port et les chemins de l'entrepôt et du quai gardent 3 m libres ; tout
##   PNJ, objet et la tête de la passerelle s'atteignent à pied, sans décor bloquant à moins de
##   1 m ; les jardins derrière les maisons du port sont clos ;
## - rien ne cache le joueur : depuis la caméra du jeu, aucun mur ni toit ne passe devant lui, où
##   qu'il se tienne dans le bourg et sur le quai ;
## - navires : le Barocupot (proue à l'ouest) et le navire du passeur (proue à l'est) flottent
##   au-delà du bord, de part et d'autre du quai, dans le champ quand on longe le garde-corps ;
## - draw calls : les décors fondus dans le champ de chaque vue tiennent dans le budget (200).
##
## Les places de HISTOIRE.md 3.3 restent vérifiées par test_world_story_spots.gd.

const FIXTURE := preload("res://tests/stubs/l2_island_fixture.gd")
const CAMERA_RIG := preload("res://src/player/camera_rig.tscn")
const ASPECT := 16.0 / 9.0
## Où se tient le joueur (local au port) pour regarder la zone.
const VIEWS := {
	"rue ouest": Vector3(-9.0, 0.0, -5.0),
	"rue est": Vector3(18.0, 0.0, -5.0),
	"marché": Vector3(-22.0, 0.0, -4.0),
	"quai ouest": Vector3(-26.0, 0.0, 11.0),
	"quai": Vector3(2.0, 0.0, 11.0),
	"quai est": Vector3(24.0, 0.0, 13.0),
	"butte": Vector3(-31.0, 0.0, 5.0),
}
## Décors à l'écran (section 0 du cahier n° 2 : 25 à 50 dans le bourg ; la pose : 15 à 80).
const MIN_ELEMENTS := 25
const MAX_ELEMENTS := 80
## Images faites pour se suivre (modules sans raccord, rangées).
const MODULES: Array[String] = [
	"fence_low", "edge_railing", "grass_edge_a", "grass_edge_b", "bollard", "crystal_lamp"
]
## Deux décors plus proches que cela (m, dans le plan du sol) sont « côte à côte ».
const SIDE_BY_SIDE := 1.6
## Chemins (local au port) qui gardent 3 m libres : la rue du Port, le chemin de l'entrepôt, le
## chemin du quai.
const PATHS := {
	"rue du Port": [Vector2(-33.0, -5.8), Vector2(33.0, -5.8)],
	"chemin de l'entrepôt": [Vector2(0.0, -27.0), Vector2(1.5, -18.0), Vector2(1.0, -8.0)],
	"chemin du quai": [Vector2(1.0, -4.0), Vector2(1.5, 4.0), Vector2(2.0, 8.0)],
}
const PATH_HALF_WIDTH := 1.5
## Places (local au port) à atteindre à pied : PNJ (HISTOIRE.md 3.3), objets, passerelle, marché,
## butte, bouts du quai.
const SPOTS := {
	"Limeskin": Vector3(-20.0, 0.0, 12.0),
	"CatWaiter": Vector3(-14.0, 0.0, -6.5),
	"EggVendor": Vector3(-24.0, 0.0, 2.0),
	"SnackVendor": Vector3(-6.0, 0.0, 1.0),
	"Ramikeldi": Vector3(26.0, 0.0, -6.5),
	"Ferryman": Vector3(12.0, 0.0, 13.0),
	"Baker": Vector3(-4.0, 0.0, -7.0),
	"beach_sheet_1": Vector3(-25.0, 0.0, 13.0),
	"beach_sheet_2": Vector3(27.0, 0.0, 14.0),
	"beach_gear_1": Vector3(30.0, 0.0, 10.0),
}
const OTHER_SPOTS := {
	"passerelle": Vector3(12.0, 0.0, 15.0),
	"fontaine": Vector3(-22.0, 0.0, 1.6),
	"butte": Vector3(-31.0, 0.0, 5.0),
	"bout ouest du quai": Vector3(-31.0, 0.0, 18.0),
	"bout est du quai": Vector3(31.0, 0.0, 17.0),
}
## Jardins clos derrière les maisons du port (local) : le joueur y serait caché par les toits.
const GARDENS: Array[Vector3] = [
	Vector3(7.5, 0.0, 1.0),
	Vector3(16.5, 0.0, 1.0),
	Vector3(23.0, 0.0, 2.0),
	Vector3(37.0, 0.0, 0.0)
]
## Dégagement des PNJ et des objets (m), entre ces hauteurs au-dessus du sol (un plancher, comme
## la passerelle, ne compte pas).
const CLEARANCE := 1.0
const CLEAR_FROM := 0.3
const CLEAR_TO := 1.7
## Grille de la marche (m) et rectangle du bourg et du port (local).
const GRID := 0.5
const TOWN := Rect2(-38.0, -28.0, 84.0, 50.0)
const PLAYER_RADIUS := 0.35
const PLAYER_HEIGHT := 1.5
const STEP_UP := 0.2
## Points du corps du joueur vus par la caméra (m au-dessus des pieds).
const BODY: Array[float] = [0.25, 0.8, 1.4]
## Grille des places relevées pour l'occlusion (m).
const OCCLUSION_STEP := 1.0
## Navires : nœud (sous Geometry/Ships), image retournée (proue à l'ouest), place d'où on les voit
## en longeant le garde-corps (local).
const SHIPS := {
	"Barocupot": [true, Vector3(-30.0, 0.0, 19.5)],
	"Ferry": [false, Vector3(16.0, 0.0, 17.8)],
}
## Draw calls hors des décors fondus (sol, falaises, ciel, mer de nuages, personnages, ombres
## propres, interface, post-traitement) et budget d'une vue.
const OTHER_DRAW_CALLS := 45
const DRAW_CALL_BUDGET := 200

var _island: Node3D
var _beach: Zone
var _space: PhysicsDirectSpaceState3D
var _ground: Node
var _pitch := 32.0
var _fov := 30.0
var _distance := 21.0
var _focus_height := 0.8
var _focus_ahead := 2.5
## Décors de la zone : [nœud, image, position].
var _elements: Array = []
## Cases atteintes à pied depuis la rue (clé : case de la grille).
var _reached: Dictionary = {}


func before_all() -> void:
	_island = FIXTURE.island()
	add_child(_island)
	_beach = _island.get_node(^"Zones/beach") as Zone
	await wait_physics_frames(2)
	_space = _island.get_world_3d().direct_space_state
	_ground = _island.get_node(^"Ground")
	var rig := CAMERA_RIG.instantiate()
	_pitch = rig.get(&"pitch_deg")
	_fov = rig.get(&"fov_deg")
	_distance = rig.get(&"distance")
	_focus_height = rig.get(&"focus_height")
	_focus_ahead = rig.get(&"focus_ahead")
	rig.free()
	_collect(_beach.get_node(^"Geometry"))
	_walk()


func after_all() -> void:
	_island.free()


# --- Densité et variété --------------------------------------------------------------------------


func test_each_view_shows_25_to_80_elements_one_of_them_moving() -> void:
	for view: String in VIEWS:
		var camera := _camera(_global(VIEWS[view]))
		var shown := 0
		var moving := 0
		var decals := 0
		for element: Array in _elements:
			if _on_screen(camera, element[2] as Vector3):
				if element[0] is GroundDecal:
					decals += 1
					continue
				shown += 1
				var panel := element[0] as DecorPanel
				if panel != null and panel.frames > 1:
					moving += 1
		assert_between(
			shown, MIN_ELEMENTS, MAX_ELEMENTS, "%s : %d décors à l'écran" % [view, shown]
		)
		assert_gt(moving, 0, "%s : au moins un décor qui bouge" % view)
		gut.p("%s : %d décors, %d décalques, %d qui bougent" % [view, shown, decals, moving])


func test_no_two_identical_images_side_by_side() -> void:
	var pairs: Array[String] = []
	for i in _elements.size():
		var a: Array = _elements[i]
		if String(a[1]).get_file().get_basename() in MODULES:
			continue
		for j in range(i + 1, _elements.size()):
			var b: Array = _elements[j]
			if a[1] != b[1]:
				continue
			var gap := _flat(a[2] as Vector3).distance_to(_flat(b[2] as Vector3))
			if gap < SIDE_BY_SIDE:
				pairs.append("%s à %.1f m" % [String(a[1]).get_file(), gap])
	assert_eq(pairs, [] as Array[String], "images identiques côte à côte")


func test_street_has_both_sides_and_its_shops() -> void:
	# Rang nord d'un seul tenant (façades jointives, sauf le chemin de l'entrepôt) et maisons du
	# port au bord du quai.
	var north: Array[Building] = []
	var harbor := 0
	for element: Array in _elements:
		var building := element[0] as Building
		if building == null:
			continue
		var at := _beach.to_local(building.global_position)
		if at.z < -9.0 and at.z > -14.0:
			north.append(building)
		elif at.z > 3.0 and at.z < 9.0:
			harbor += 1
	north.sort_custom(func(a: Building, b: Building) -> bool: return a.position.x < b.position.x)
	assert_gte(north.size(), 10, "rang nord de la rue")
	assert_gte(harbor, 4, "maisons du port au bord du quai")
	var holes: Array[String] = []
	for k in range(1, north.size()):
		var west := north[k - 1]
		var east := north[k]
		var gap := (
			(east.position.x - east.footprint.x / 2.0) - (west.position.x + west.footprint.x / 2.0)
		)
		var path_gap := west.position.x < 1.0 and east.position.x > 1.0
		if gap > (6.0 if path_gap else 0.6):
			holes.append("%.1f m entre %s et %s" % [gap, west.name, east.name])
	assert_eq(holes, [] as Array[String], "façades d'un seul tenant")
	for shop: String in ["Cafe", "Bakery", "Bookshop", "ProjectionHall", "LimashenkaHouse"]:
		assert_not_null(_beach.get_node_or_null(NodePath("Geometry/" + shop)), shop)


# --- Chemins, places, jardins ---------------------------------------------------------------------


func test_paths_keep_three_metres_clear() -> void:
	var cylinder := CylinderShape3D.new()
	cylinder.radius = PATH_HALF_WIDTH
	cylinder.height = CLEAR_TO - CLEAR_FROM
	for path: String in PATHS:
		var points: Array = PATHS[path]
		var blocked: Array[String] = []
		for k in points.size() - 1:
			var a: Vector2 = points[k]
			var b: Vector2 = points[k + 1]
			var steps := ceili(a.distance_to(b) / GRID)
			for s in steps + 1:
				var p := a.lerp(b, float(s) / steps)
				var hit := _blocking(cylinder, _global(Vector3(p.x, 0.0, p.y)))
				if not hit.is_empty() and blocked.size() < 6:
					blocked.append("%s (%s)" % [p, hit])
		assert_eq(blocked, [] as Array[String], "%s : 3 m libres" % path)


func test_people_and_objects_are_reachable_with_one_metre_clear() -> void:
	var cylinder := CylinderShape3D.new()
	cylinder.radius = CLEARANCE
	cylinder.height = CLEAR_TO - CLEAR_FROM
	for spot: String in SPOTS:
		var at := _global(SPOTS[spot] as Vector3)
		assert_eq(_blocking(cylinder, at), "", "%s : aucun décor bloquant à moins de 1 m" % spot)
		assert_true(_is_reached(at), "%s : atteint à pied depuis la rue" % spot)
	for spot: String in OTHER_SPOTS:
		assert_true(_is_reached(_global(OTHER_SPOTS[spot] as Vector3)), "%s : à pied" % spot)


func test_ferryman_stands_at_the_head_of_his_gangway() -> void:
	var gangway := _beach.get_node(^"Geometry/Ships/Gangway") as Node3D
	var head := _flat(_beach.to_local(gangway.global_position))
	var ferryman := _flat(SPOTS["Ferryman"] as Vector3)
	assert_between(head.distance_to(ferryman), 0.5, 1.5, "passeur au bout de la passerelle")
	assert_gt(_beach.to_local(gangway.global_position).z, ferryman.y, "passerelle vers le vide")


func test_gardens_behind_the_harbor_houses_are_closed() -> void:
	for garden: Vector3 in GARDENS:
		var at := _global(garden)
		assert_true(IslandTerrain.is_land(at.x, at.z), "%s : sur l'île" % garden)
		assert_false(_is_reached(at), "%s : jardin clos" % garden)


# --- Rien ne cache le joueur ----------------------------------------------------------------------


func test_no_wall_or_roof_hides_the_player_in_town() -> void:
	var walls := _wall_triangles()
	assert_gt(walls.size(), 0, "murs et toits trouvés")
	var hidden: Array[String] = []
	var x := TOWN.position.x
	while x <= TOWN.end.x:
		var z := TOWN.position.y
		while z <= TOWN.end.y:
			var at := _global(Vector3(x, 0.0, z))
			if _reached.get(_cell(at), false):
				var feet := Vector3(at.x, IslandTerrain.height_at(at.x, at.z), at.z)
				var eye := _camera(feet).origin
				for height: float in BODY:
					if _crosses(eye, feet + Vector3.UP * height, walls) and hidden.size() < 6:
						hidden.append("%s (%.2f m)" % [Vector2(x, z), height])
						break
			z += OCCLUSION_STEP
		x += OCCLUSION_STEP
	assert_eq(hidden, [] as Array[String], "joueur caché par un mur ou un toit")


# --- Navires -------------------------------------------------------------------------------------


func test_ships_float_beyond_the_edge_on_either_side_of_the_quay() -> void:
	var tower := _beach.get_node(^"Geometry/Ships/MooringTower") as Node3D
	for ship: String in SHIPS:
		var panel := _beach.get_node(NodePath("Geometry/Ships/" + ship)) as DecorPanel
		var spec: Array = SHIPS[ship]
		assert_eq(
			panel.flip_h, spec[0], "%s : proue à %s" % [ship, "l'ouest" if spec[0] else "l'est"]
		)
		var size := panel.size_m()
		var at := panel.global_position
		for dx: float in [-0.45, 0.0, 0.45]:
			var x := at.x + dx * size.x
			assert_lt(
				IslandTerrain.edge_distance(x, at.z),
				0.0,
				"%s : au-delà du bord en x %.1f" % [ship, x]
			)
		for propeller: Node in panel.get_children():
			if propeller is DecorPanel:
				assert_eq((propeller as DecorPanel).flip_h, panel.flip_h, "%s : hélice" % ship)
				assert_gt((propeller as DecorPanel).frames, 1, "%s : hélice qui tourne" % ship)
		# Dans le champ quand on longe le garde-corps : le pont, à hauteur du quai, à l'écran.
		var camera := _camera(_global(spec[1] as Vector3))
		var deck := Vector3(at.x, 0.8, at.z)
		assert_true(_on_screen(camera, deck), "%s : dans le champ depuis le quai" % ship)
	var baro := _beach.get_node(^"Geometry/Ships/Barocupot") as Node3D
	var ferry := _beach.get_node(^"Geometry/Ships/Ferry") as Node3D
	assert_lt(baro.global_position.x, 0.0, "Barocupot à l'ouest du quai")
	assert_gt(ferry.global_position.x, 0.0, "passeur à l'est")
	assert_lt(
		_flat(tower.global_position).distance_to(_flat(baro.global_position)),
		12.0,
		"Barocupot à son pylône"
	)


# --- Draw calls ----------------------------------------------------------------------------------


func test_batched_decor_in_each_view_stays_within_the_draw_call_budget() -> void:
	var batches: Array[MeshInstance3D] = []
	for zone: Node in _island.get_node(^"Zones").get_children():
		for child: Node in zone.get_node(^"Geometry").get_children():
			var mesh := child as MeshInstance3D
			if mesh != null and mesh.mesh != null and String(mesh.name).begins_with("Batch"):
				batches.append(mesh)
	var spots := VIEWS.duplicate()
	for ship: String in SHIPS:
		spots[ship] = (SHIPS[ship] as Array)[1]
	for view: String in spots:
		var camera := _camera(_global(spots[view] as Vector3))
		var drawn := 0
		for mesh in batches:
			if _box_on_screen(camera, mesh.global_transform * mesh.get_aabb()):
				drawn += 1
		gut.p("%s : %d lots de décor dans le champ" % [view, drawn])
		assert_lte(
			drawn + OTHER_DRAW_CALLS,
			DRAW_CALL_BUDGET,
			"%s : %d lots de décor dans le champ" % [view, drawn]
		)


# --- Outils --------------------------------------------------------------------------------------


func _global(local: Vector3) -> Vector3:
	var at := _beach.to_global(local)
	at.y = maxf(IslandTerrain.height_at(at.x, at.z), 0.0)
	return at


func _flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)


## Décors posés (racines : panneau, bâtiment, décalque), PropScatter compris.
func _collect(node: Node) -> void:
	for child: Node in node.get_children(true):
		var image := ""
		if child is DecorPanel and (child as DecorPanel).texture != null:
			image = (child as DecorPanel).texture.resource_path
		elif child is Building and (child as Building).facade != null:
			image = (child as Building).facade.resource_path
		elif child is GroundDecal and (child as GroundDecal).texture != null:
			image = (child as GroundDecal).texture.resource_path
		if not image.is_empty():
			_elements.append([child, image, (child as Node3D).global_position])
			continue
		if not (child is MeshInstance3D):
			_collect(child)


## Caméra du jeu quand le joueur se tient en feet (CameraRig : point visé, tangage, distance).
func _camera(feet: Vector3) -> Transform3D:
	var tilt := Basis(Vector3.RIGHT, deg_to_rad(-_pitch))
	var focus := feet + Vector3(0.0, _focus_height, -_focus_ahead)
	return Transform3D(tilt, focus + tilt.z * _distance)


## Position à l'écran (x, y de -1 à 1 au bord du cadre) et profondeur d'un point.
func _project(camera: Transform3D, point: Vector3) -> Vector3:
	var local := camera.affine_inverse() * point
	var depth := -local.z
	if depth <= 0.05:
		return Vector3(INF, INF, depth)
	var half := tan(deg_to_rad(_fov) / 2.0)
	return Vector3(local.x / (depth * half * ASPECT), local.y / (depth * half), depth)


func _on_screen(camera: Transform3D, point: Vector3) -> bool:
	var p := _project(camera, point)
	return absf(p.x) <= 1.0 and absf(p.y) <= 1.0


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


## Nom du décor bloquant (couche world, hors sol) dans la forme posée au-dessus du sol en at.
func _blocking(shape: Shape3D, at: Vector3) -> String:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 1
	query.transform = Transform3D(Basis.IDENTITY, at + Vector3.UP * (CLEAR_FROM + CLEAR_TO) / 2.0)
	for hit: Dictionary in _space.intersect_shape(query, 32):
		if hit["collider"] != _ground:
			return String((hit["collider"] as Node).get_parent().name)
	return ""


## Cases atteintes à pied (capsule du joueur, grille GRID) depuis la rue, dans TOWN.
func _walk() -> void:
	var capsule := CapsuleShape3D.new()
	capsule.radius = PLAYER_RADIUS
	capsule.height = PLAYER_HEIGHT
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = 1
	var start := _cell(_global(Vector3(1.0, 0.0, -6.0)))
	var queue: Array[Vector2i] = [start]
	_reached[start] = true
	var head := 0
	while head < queue.size():
		var cell := queue[head]
		head += 1
		for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var next := cell + step
			if _reached.has(next):
				continue
			var x := next.x * GRID
			var z := next.y * GRID
			var local := _beach.to_local(Vector3(x, 0.0, z))
			if not TOWN.has_point(Vector2(local.x, local.z)):
				continue
			if IslandTerrain.edge_distance(x, z) < PLAYER_RADIUS:
				continue
			var y := IslandTerrain.height_at(x, z) + STEP_UP + PLAYER_HEIGHT / 2.0
			query.transform = Transform3D(Basis.IDENTITY, Vector3(x, y, z))
			var free := true
			for hit: Dictionary in _space.intersect_shape(query, 32):
				if hit["collider"] != _ground:
					free = false
					break
			_reached[next] = free
			if free:
				queue.append(next)


func _cell(at: Vector3) -> Vector2i:
	return Vector2i(roundi(at.x / GRID), roundi(at.z / GRID))


func _is_reached(at: Vector3) -> bool:
	for dx: int in [-1, 0, 1]:
		for dz: int in [-1, 0, 1]:
			if _reached.get(_cell(at) + Vector2i(dx, dz), false):
				return true
	return false


## Triangles des murs et des toits fondus (matières de src/world/props/ : leur image est sous
## assets/hd2d/buildings/materials/), en coordonnées de l'île, rangés par mètre en x.
func _wall_triangles() -> Dictionary:
	var buckets := {}
	for child: Node in _beach.get_node(^"Geometry").get_children():
		var batch := child as MeshInstance3D
		if batch == null or batch.mesh == null or not String(batch.name).begins_with("Batch"):
			continue
		var material := batch.material_override as ShaderMaterial
		if material == null:
			continue
		var texture := material.get_shader_parameter(&"albedo_texture") as Texture2D
		if texture == null or not texture.resource_path.contains("/buildings/materials/"):
			continue
		var xform := batch.global_transform
		var vertices: PackedVector3Array = batch.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for t in range(0, vertices.size() - 2, 3):
			var a := xform * vertices[t]
			var b := xform * vertices[t + 1]
			var c := xform * vertices[t + 2]
			var lo := floori(minf(a.x, minf(b.x, c.x)))
			var hi := floori(maxf(a.x, maxf(b.x, c.x)))
			for i in range(lo, hi + 1):
				if not buckets.has(i):
					buckets[i] = []
				(buckets[i] as Array).append_array([a, b, c])
	return buckets


## Vrai si un triangle de mur ou de toit coupe le segment from → to (même tranche de x).
func _crosses(from: Vector3, to: Vector3, walls: Dictionary) -> bool:
	var direction := to - from
	var length := direction.length()
	direction /= length
	var triangles: Array = walls.get(floori(to.x), [])
	for t in range(0, triangles.size() - 2, 3):
		var hit: Variant = Geometry3D.ray_intersects_triangle(
			from, direction, triangles[t], triangles[t + 1], triangles[t + 2]
		)
		if hit != null and from.distance_to(hit as Vector3) < length - 0.05:
			return true
	return false
