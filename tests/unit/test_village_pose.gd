extends GutTest
## (Lot P2) Pose de la cour de l'entrepôt (docs/ASSETS_HD2D_MONDE.md, sections 0 et 14) dans
## l'île sans le contenu des emplacements (tests/stubs/l2_island_fixture.gd), vue par la caméra
## du joueur (camera_rig.tscn) depuis des places qui couvrent la cour :
##
## - densité : à chaque place, DENSITY_MIN à DENSITY_MAX décors dans le champ à moins de
##   DENSITY_REACH m du joueur (les modules de la palissade et les bordures d'herbe ne comptent
##   pas) ;
## - variété : deux décors proches (moins de VARIETY_RADIUS m) n'ont jamais la même image vue du
##   même côté (retournement), sauf les modules faits pour se suivre ;
## - sol cassé : aucun disque de plus de EMPTY_RADIUS m de rayon sans décor dans la cour ;
## - chemins : de la place aux quatre portails, un couloir libre de 3 m au moins ;
## - mouvement : le linge et la fumée sont des bandes animées, les feuilles et les oiseaux des
##   petites vies ;
## - draw calls : les meshes fondus du village (une image par case du PropBatcher) et ses petites
##   vies dans le champ restent sous VILLAGE_DRAW_CALLS à chaque place (la vue entière, île,
##   personnages et interface compris, est mesurée sous 200 par les captures de la pose).
## Les collisions, l'abord des PNJ et l'occlusion restent vérifiés par test_village_decor.gd, les
## places de l'acte 1 par test_world_story_spots.gd.

const FIXTURE := preload("res://tests/stubs/l2_island_fixture.gd")
const CAMERA_RIG := preload("res://src/player/camera_rig.tscn")
## Places du joueur (local au village) : Spawn, porche, potager, aire de jeux, sud, grand arbre,
## ouest, est, chemin nord, linge.
const SPOTS: Array[Vector3] = [
	Vector3(0.0, 0.0, 9.0),
	Vector3(-8.0, 0.0, -4.0),
	Vector3(12.0, 0.0, 2.0),
	Vector3(-9.0, 0.0, 15.0),
	Vector3(6.0, 0.0, 17.5),
	Vector3(8.0, 0.0, -9.0),
	Vector3(-16.0, 0.0, 4.0),
	Vector3(18.0, 0.0, -6.0),
	Vector3(0.0, 0.0, -16.0),
	Vector3(9.0, 0.0, 9.0),
]
## Cahier n° 2, section 0 : 25 à 50 éléments à l'écran, environ 20 m de large autour du joueur,
## dans la cour (le haut de l'écran, au-delà de DENSITY_REACH m, est flou et ne compte pas).
const DENSITY_MIN := 25
const DENSITY_MAX := 60
const DENSITY_REACH := 12.0
## Images qui se suivent par modules (palissade, clôture, bordures, lisière) : hors de la
## densité et de la variété.
const MODULES: Array[String] = [
	"palisade",
	"fence_low",
	"grass_edge_a",
	"grass_edge_b",
	"treeline_autumn_a",
	"treeline_autumn_b",
]
const VARIETY_RADIUS := 2.0
## Plus grand trou sans décor dans la cour (m) : chaque surface de plus de 4 × 4 m est cassée.
const EMPTY_RADIUS := 4.0
const EMPTY_STEP := 1.0
## Ce qui ne casse pas le sol de la cour (le long des bords, ou derrière la palissade).
const EMPTY_IGNORED: Array[String] = ["palisade", "treeline_autumn_a", "treeline_autumn_b"]
## Palissade : à 21,2 m du centre ; place (rayon 9 m).
const FENCE := 21.2
const YARD_RADIUS := 9.0
## Chemins : largeur libre, capsule du joueur, pas des relevés (m).
const PATH_WIDTH := 3.0
const PLAYER_RADIUS := 0.35
const PLAYER_HEIGHT := 1.5
const STEP_UP := 0.2
const PATH_STEP := 0.5
const PROBE_STEP := 0.25
## Draw calls du village dans le champ (budget de la vue entière : 200 ; île, ciel, autres zones,
## personnages et interface en prennent 40 à 60).
const VILLAGE_DRAW_CALLS := 140
## Rapport largeur / hauteur de l'écran.
const ASPECT := 16.0 / 9.0

var _island: Node3D
var _village: Node3D
var _space: PhysicsDirectSpaceState3D
var _ground: Node
var _pitch := 0.0
var _distance := 0.0
var _focus_height := 0.0
var _focus_ahead := 0.0
var _fov := 0.0
## Décors du village : image, place (monde), retournement, hauteur de l'image (m).
var _parts: Array[Dictionary] = []


func before_all() -> void:
	_island = FIXTURE.island()
	add_child(_island)
	await wait_physics_frames(2)
	_village = _island.get_node(^"Zones/village") as Node3D
	_space = _island.get_world_3d().direct_space_state
	_ground = _island.get_node(^"Ground")
	var rig := CAMERA_RIG.instantiate()
	_pitch = deg_to_rad(float(rig.get(&"pitch_deg")))
	_distance = float(rig.get(&"distance"))
	_focus_height = float(rig.get(&"focus_height"))
	_focus_ahead = float(rig.get(&"focus_ahead"))
	_fov = deg_to_rad(float(rig.get(&"fov_deg")))
	rig.free()
	_collect(_village.get_node(^"Geometry"))


func after_all() -> void:
	_island.free()


func test_every_view_of_the_yard_is_dense() -> void:
	var report: Array[String] = []
	for spot: Vector3 in SPOTS:
		var camera := _camera(spot)
		var player := _village.to_global(spot)
		var count := 0
		for part: Dictionary in _parts:
			if String(part["image"]) in MODULES:
				continue
			var at: Vector3 = part["at"]
			if Vector2(at.x - player.x, at.z - player.z).length() > DENSITY_REACH:
				continue
			var top := at + Vector3.UP * float(part["height"]) / 2.0
			if _in_view(camera, at) or _in_view(camera, top):
				count += 1
		report.append("%s : %d" % [spot, count])
		assert_between(count, DENSITY_MIN, DENSITY_MAX, "décors dans le champ en %s" % spot)
	gut.p("Densité : %s" % ", ".join(report))


func test_no_two_neighbours_show_the_same_image() -> void:
	var twins: Array[String] = []
	for i in _parts.size():
		var a := _parts[i]
		if String(a["image"]) in MODULES:
			continue
		for j in range(i + 1, _parts.size()):
			var b := _parts[j]
			if a["image"] != b["image"] or a["flip"] != b["flip"]:
				continue
			var gap := Vector2(a["at"].x - b["at"].x, a["at"].z - b["at"].z).length()
			if gap < VARIETY_RADIUS:
				twins.append("%s en %s et %s" % [a["image"], _local(a["at"]), _local(b["at"])])
	assert_true(twins.is_empty(), "images identiques côte à côte : %s" % ", ".join(twins))


func test_yard_ground_has_no_large_empty_area() -> void:
	# Points de la cour hors des bâtiments et des couloirs fermés : un décor (panneau ou décalque)
	# à moins de EMPTY_RADIUS m.
	var anchors: Array[Vector2] = []
	for part: Dictionary in _parts:
		if String(part["image"]) in EMPTY_IGNORED:
			continue
		var local := _local(part["at"])
		anchors.append(Vector2(local.x, local.z))
	var holes: Array[String] = []
	var x := -FENCE + 1.0
	while x <= FENCE - 1.0:
		var z := -FENCE + 1.0
		while z <= FENCE - 1.0:
			if _open_ground(Vector2(x, z)):
				var near := false
				for anchor: Vector2 in anchors:
					if anchor.distance_to(Vector2(x, z)) <= EMPTY_RADIUS:
						near = true
						break
				if not near:
					holes.append("(%.0f, %.0f)" % [x, z])
			z += EMPTY_STEP
		x += EMPTY_STEP
	assert_true(holes.is_empty(), "sol nu en %s" % ", ".join(holes))


func test_paths_keep_a_three_metre_corridor_to_the_gates() -> void:
	# Du bord de la place à chaque portail, à chaque pas, un couloir libre de PATH_WIDTH m de
	# large (centres de capsule libres sur PATH_WIDTH - 2 × rayon) qui touche le chemin.
	var sides: Array[Vector3] = [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]
	for outward: Vector3 in sides:
		var across := Vector3(absf(outward.z), 0.0, absf(outward.x))
		var t := YARD_RADIUS
		while t <= FENCE - 0.6:
			var corridor := _corridor(outward * t, across)
			assert_gte(
				corridor,
				PATH_WIDTH,
				"chemin %s à %.1f m : couloir de %.2f m" % [outward, t, corridor]
			)
			t += PATH_STEP


func test_something_moves_in_the_yard() -> void:
	var animated: Array[String] = []
	for part: Dictionary in _parts:
		if int(part["frames"]) > 1 and float(part["fps"]) > 0.0:
			animated.append(String(part["image"]))
	assert_has(animated, "laundry_wave", "le linge flotte")
	assert_has(animated, "chimney_smoke", "la cheminée fume")
	var lives: Array[String] = []
	for node: Node in _village.find_children("*", "AmbientSprites", true, false):
		var sprites := node as AmbientSprites
		if sprites.texture != null and sprites.sprite_count() > 0:
			lives.append(sprites.texture.resource_path.get_file().get_basename())
	assert_has(lives, "falling_leaf_gold", "feuilles qui tombent")
	assert_has(lives, "birds_flock", "oiseaux")


func test_village_draw_calls_stay_in_budget() -> void:
	var batches: Array[MeshInstance3D] = []
	for child: Node in _village.get_node(^"Geometry").get_children():
		var batch := child as MeshInstance3D
		if batch != null and batch.mesh != null and String(batch.name).begins_with("Batch"):
			batches.append(batch)
	var lives := _village.find_children("*", "AmbientSprites", true, false).size()
	var report: Array[String] = []
	for spot: Vector3 in SPOTS:
		var camera := _camera(spot)
		var calls := lives
		for batch: MeshInstance3D in batches:
			if _box_in_view(camera, batch.global_transform * batch.get_aabb()):
				calls += 1
		report.append("%s : %d" % [spot, calls])
		assert_lte(calls, VILLAGE_DRAW_CALLS, "draw calls du village en %s" % spot)
	gut.p("Draw calls du village : %s" % ", ".join(report))


# --- Outils -------------------------------------------------------------------------------------


## Relève les décors (panneaux, décalques, bâtiments) sous node, dans l'ordre de l'arbre.
func _collect(node: Node) -> void:
	for child: Node in node.get_children(true):
		var image := ""
		var flip := false
		var height := 0.0
		var frames := 1
		var fps := 0.0
		if child is DecorPanel:
			var panel := child as DecorPanel
			if panel.texture == null:
				continue
			image = panel.texture.resource_path.get_file().get_basename()
			flip = panel.flip_h
			height = panel.size_m().y
			frames = panel.frames
			fps = panel.fps
		elif child is GroundDecal:
			var decal := child as GroundDecal
			if decal.texture == null:
				continue
			image = decal.texture.resource_path.get_file().get_basename()
			flip = decal.flip_h
		elif child is Building:
			var building := child as Building
			image = String(building.name)
			height = building.ridge_height
		else:
			_collect(child)
			continue
		(
			_parts
			. append(
				{
					"image": image,
					"at": (child as Node3D).global_position,
					"flip": flip,
					"height": height,
					"frames": frames,
					"fps": fps,
				}
			)
		)


func _local(at: Vector3) -> Vector3:
	return _village.to_local(at)


## Caméra du joueur posé en spot (local au village) : sans avance ni zoom.
func _camera(spot: Vector3) -> Transform3D:
	var player := _village.to_global(spot)
	var focus := player + Vector3(0.0, _focus_height, -_focus_ahead)
	var basis := Basis(Vector3.RIGHT, -_pitch)
	return Transform3D(basis, focus + basis.z * _distance)


func _in_view(camera: Transform3D, point: Vector3) -> bool:
	var local := camera.affine_inverse() * point
	if local.z > -0.1:
		return false
	var half_v := tan(_fov / 2.0)
	var half_h := half_v * ASPECT
	return absf(local.x / -local.z) <= half_h and absf(local.y / -local.z) <= half_v


## Vrai si la boîte (monde) touche le champ de la caméra (plans des quatre bords et du proche).
func _box_in_view(camera: Transform3D, box: AABB) -> bool:
	var half_v := tan(_fov / 2.0)
	var half_h := half_v * ASPECT
	# Normales sortantes dans le repère de la caméra (elle regarde -Z).
	var normals: Array[Vector3] = [
		Vector3(1.0, 0.0, half_h).normalized(),
		Vector3(-1.0, 0.0, half_h).normalized(),
		Vector3(0.0, 1.0, half_v).normalized(),
		Vector3(0.0, -1.0, half_v).normalized(),
		Vector3(0.0, 0.0, 1.0),
	]
	var inverse := camera.affine_inverse()
	var corners: Array[Vector3] = []
	for k in 8:
		corners.append(inverse * box.get_endpoint(k))
	for normal: Vector3 in normals:
		var outside := true
		for corner: Vector3 in corners:
			if corner.dot(normal) <= 0.0:
				outside = false
				break
		if outside:
			return false
	return true


## Largeur (m) du plus large couloir libre en travers du chemin en axis (local), le long de
## across, qui touche le chemin (PATH_WIDTH de part et d'autre de l'axe au plus).
func _corridor(axis: Vector3, across: Vector3) -> float:
	var best := 0.0
	var first := INF
	var offset := -PATH_WIDTH
	while offset <= PATH_WIDTH + 0.001:
		if _free(axis + across * offset):
			first = minf(first, offset)
			if first <= PATH_WIDTH / 2.0 and offset >= -PATH_WIDTH / 2.0:
				best = maxf(best, offset - first + 2.0 * PLAYER_RADIUS)
		else:
			first = INF
		offset += PROBE_STEP
	return best


## Sol de la cour : dans la palissade, hors des bâtiments, des couloirs fermés derrière le L et
## de l'emprise des décors qui bloquent.
func _open_ground(at: Vector2) -> bool:
	if at.x < -12.6 and at.y < -1.6:
		return false
	if at.y < -10.6 and at.x < -2.6:
		return false
	return _free(Vector3(at.x, 0.0, at.y))


## Aucun décor (couche world, hors sol) dans une capsule de joueur debout en at (local).
func _free(at: Vector3) -> bool:
	var capsule := CapsuleShape3D.new()
	capsule.radius = PLAYER_RADIUS
	capsule.height = PLAYER_HEIGHT
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = 1
	var world := _village.to_global(at)
	query.transform = Transform3D(
		Basis.IDENTITY, Vector3(world.x, world.y + STEP_UP + PLAYER_HEIGHT / 2.0, world.z)
	)
	for hit: Dictionary in _space.intersect_shape(query, 4):
		if hit["collider"] != _ground:
			return false
	return true
