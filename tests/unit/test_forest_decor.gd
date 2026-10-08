extends GutTest
## (Lot P1) Le décor des bois du marais (src/world/zones/forest/forest.tscn ; cahier n° 2,
## docs/ASSETS_HD2D_MONDE.md, sections 0 et 14), dans l'île sans le contenu des emplacements
## (tests/stubs/l2_island_fixture.gd) :
##
## - densité : dans chaque vue des bois (sol vu à l'écran autour du joueur), au moins 40 décors,
##   dix arbres ou plus de trois espèces au moins ; le terrain d'entraînement reste dégagé (rien
##   de bloquant dans le cercle de 15 m que les buts et le râtelier, rien de plus haut que le
##   banc hors de son bord) ;
## - variété : jamais deux images identiques côte à côte (le plus proche voisin de chaque panneau
##   et de chaque décalque a une autre image ; exceptions : le cercle de champignons et le
##   caillebotis, faits d'une même image par nature) ;
## - chemins : les chemins des bois (portail nord → terrain, branche du marais) sont libres sur
##   toute leur largeur (3 m), et le gué du ruisseau aussi ;
## - lisières : d'un seul tenant le long du bord nord, et personne ne passe derrière ;
## - draw calls : depuis la caméra du joueur (camera_rig.tscn), les décors fondus vus dans chaque
##   vue des bois restent sous DECOR_BUDGET (200 au total avec le sol, le ciel, les personnages
##   et l'interface) ; ceux des bois vus depuis la cour et la colline restent peu nombreux
##   (budget de chaque vue voisine).
##
## Les places de l'acte 1 restent vérifiées par test_world_story_spots.gd.

const FIXTURE := preload("res://tests/stubs/l2_island_fixture.gd")
const CAMERA_RIG := preload("res://src/player/camera_rig.tscn")
## Vues des bois : position du joueur (local à la forêt).
const VIEWS := {
	"entrée": Vector3(0.5, 0.0, 24.0),
	"marais": Vector3(-24.0, 0.0, 3.0),
	"cascade": Vector3(-58.0, 0.0, -3.0),
	"ours": Vector3(44.0, 0.0, 4.0),
	"est": Vector3(24.0, 0.0, 4.0),
	"ouest": Vector3(-44.0, 0.0, 12.0),
	"ruisseau": Vector3(-8.0, 0.0, -9.0),
	"nord-est": Vector3(22.0, 0.0, -8.0),
	"bord est": Vector3(62.0, 0.0, 12.0),
	"bord ouest": Vector3(-64.0, 0.0, 8.0),
	"sud": Vector3(-20.0, 0.0, 22.0),
	"sud-est": Vector3(20.0, 0.0, 22.0),
}
## Vues où l'on se tient dans le sous-bois (dix arbres ou plus à l'écran).
const WOODS: Array[String] = [
	"marais", "ours", "est", "ouest", "nord-est", "bord est", "bord ouest", "sud", "sud-est"
]
## Vues mesurées en draw calls : celles des bois, plus le terrain d'entraînement et le nord.
const CAMERA_VIEWS := {
	"terrain": Vector3(1.0, 0.0, 9.0),
	"nord": Vector3(0.0, 0.0, -12.0),
}
## Vues des zones voisines (tests/integration/demo_hd2d.gd) : zone, position, recul de la caméra.
## Images des bois vues au plus (bande sud des bois vue de la cour, sud-est vu de la colline ;
## mesuré par hd2d_shots.sh : cour +21 draw calls, colline +27 par rapport au départ du lot P1).
const NEIGHBOR_VIEWS := {
	"village": [&"village", Vector3(-5.0, 0.0, -2.5), 21.0, 25],
	"entrepot": [&"village", Vector3(-10.5, 0.0, -6.5), 25.0, 25],
	"dialogue": [&"village", Vector3(-7.2, 0.0, -6.2), 21.0, 25],
	"hill": [&"hill", Vector3(1.0, 8.0, 3.0), 21.0, 50],
}
## Sol vu à l'écran autour du joueur (m) : de 5 m au sud à 20 m au nord, 7 m de demi-largeur au
## bas de l'écran, 18 m en haut.
const SEEN_SOUTH := 5.0
const SEEN_NORTH := 20.0
const SEEN_HALF_NEAR := 7.0
const SEEN_HALF_FAR := 18.0
const MIN_ELEMENTS := 40
const MIN_TREES := 10
const MIN_SPECIES := 3
## Espèces d'arbres, par préfixe d'image.
const SPECIES := {
	"oak_": "chêne",
	"tree_autumn.": "chêne",
	"beech_": "hêtre",
	"maple_": "érable",
	"tree_autumn_": "érable",
	"birch_": "bouleau",
	"sapling_": "bouleau",
	"pine_": "sapin",
	"tree_pine": "sapin",
	"tree_old_pine": "sapin",
	"willow": "saule",
}
## Terrain d'entraînement : centre (local), rayon, décors bloquants permis dans le cercle.
const CLEARING_RADIUS := 15.0
const CLEARING_BLOCKERS: Array[String] = ["GoalNorth", "GoalSouth", "StickRack"]
const CLEARING_MAX_HEIGHT := 2.1
## Images faites pour se répéter côte à côte.
const MODULAR: Array[String] = ["boardwalk.png"]
const MODULAR_NODES: Array[String] = ["FairyRing"]
## Chemins des bois (local), largeur praticable de part et d'autre de l'axe (m).
const PATHS: Array = [
	[Vector2(0.0, 27.0), Vector2(1.5, 18.0), Vector2(0.7, 15.6)],
	[Vector2(1.0, 21.0), Vector2(-8.0, 13.0), Vector2(-15.0, 5.0), Vector2(-19.0, -0.5)],
]
const PATH_HALF_WIDTH := 1.1
## Budgets de draw calls des décors fondus (le reste de l'image : sol, ciel, mer de nuages,
## personnages, interface, environ 30).
const DECOR_BUDGET := 165
const PLAYER_RADIUS := 0.35
const PLAYER_HEIGHT := 1.5
## Demi-profondeur de la collision des lisières (P0 : 1,6 m).
const WALL_BACK := 0.8
## Recouvrement de deux lisières voisines, au plus (m).
const WALL_OVERLAP := 1.5

var _island: Node3D
var _forest: Node3D
var _space: PhysicsDirectSpaceState3D
var _ground: Node
## Décors posés : [position locale, image, nœud porteur, panneau ?, hauteur (m)].
var _decor: Array = []
var _viewport: SubViewport
var _camera: Camera3D


func before_all() -> void:
	_island = FIXTURE.island()
	add_child(_island)
	await wait_physics_frames(2)
	_forest = _island.get_node(^"Zones/forest") as Node3D
	_space = _island.get_world_3d().direct_space_state
	_ground = _island.get_node(^"Ground")
	_collect(_forest.get_node(^"Geometry"), "")
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(1280, 720)
	add_child(_viewport)
	_camera = Camera3D.new()
	# Posée plusieurs fois sans attendre d'image : son champ suit sa place, pas un lissage.
	_camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_viewport.add_child(_camera)


func after_all() -> void:
	_viewport.free()
	_island.free()


# --- Densité et variété ---------------------------------------------------------------------------


func test_every_woods_view_is_dense_with_trees_of_several_species() -> void:
	for view: String in VIEWS:
		var at: Vector3 = VIEWS[view]
		var elements := 0
		var trees := 0
		var species := {}
		for item: Array in _decor:
			if not _seen(at, item[0] as Vector3):
				continue
			elements += 1
			var kind := _species(item[1] as String)
			if not kind.is_empty() and float(item[4]) > 3.0:
				trees += 1
				species[kind] = true
		assert_gte(elements, MIN_ELEMENTS, "vue %s : %d décors à l'écran" % [view, elements])
		if view in WOODS:
			assert_gte(trees, MIN_TREES, "vue %s : %d arbres" % [view, trees])
			assert_gte(species.size(), MIN_SPECIES, "vue %s : espèces %s" % [view, species.keys()])


func test_no_two_neighbors_share_an_image() -> void:
	assert_gt(_decor.size(), 600, "décors des bois relevés")
	var same: Array[String] = []
	for i in _decor.size():
		var item: Array = _decor[i]
		if (item[1] as String).get_file() in MODULAR or item[2] in MODULAR_NODES:
			continue
		var at := item[0] as Vector3
		var best := -1
		var best_distance := INF
		for j in _decor.size():
			if j == i or _decor[j][3] != item[3]:
				continue
			var other := _decor[j][0] as Vector3
			var d := Vector2(other.x - at.x, other.z - at.z).length_squared()
			if d < best_distance:
				best_distance = d
				best = j
		if best >= 0 and _decor[best][1] == item[1]:
			var file := (item[1] as String).get_file()
			same.append("%s (%s) en %s" % [file, item[2], at.snapped(Vector3.ONE * 0.1)])
	assert_eq(same, [] as Array[String], "deux images identiques côte à côte")


# --- Jouabilité -----------------------------------------------------------------------------------


func test_training_ground_is_open() -> void:
	var blocked: Array[String] = []
	var r := 0.0
	while r <= CLEARING_RADIUS:
		var steps := maxi(1, ceili(TAU * r / 1.0))
		for k in steps:
			var angle := TAU * k / steps
			var at := _forest.to_global(Vector3(cos(angle) * r, 0.0, sin(angle) * r))
			for hit: String in _decor_at(at):
				if not CLEARING_BLOCKERS.any(func(n: String) -> bool: return hit.contains(n)):
					blocked.append("%s en %s" % [hit, at])
		r += 1.0
	assert_eq(blocked, [] as Array[String], "rien de bloquant dans le cercle de 15 m")
	for item: Array in _decor:
		var at := item[0] as Vector3
		if Vector2(at.x, at.z).length() < CLEARING_RADIUS - 1.0 and item[3]:
			assert_lte(float(item[4]), CLEARING_MAX_HEIGHT, "%s bas dans le cercle" % item[1])


func test_woods_paths_are_open_on_their_whole_width() -> void:
	for path: Array in PATHS:
		var blocked: Array[String] = []
		for k in path.size() - 1:
			var a: Vector2 = path[k]
			var b: Vector2 = path[k + 1]
			var side := (b - a).orthogonal().normalized()
			var steps := ceili(a.distance_to(b) / 0.5)
			for s in steps + 1:
				var p := a.lerp(b, float(s) / steps)
				for offset: float in [-PATH_HALF_WIDTH, 0.0, PATH_HALF_WIDTH]:
					var q := p + side * offset
					for hit: String in _decor_at(_forest.to_global(Vector3(q.x, 0.0, q.y))):
						blocked.append("%s en %s" % [hit, q])
		assert_eq(blocked, [] as Array[String], "chemin %s libre" % [path])


func test_forest_walls_close_the_north_rim_in_one_piece() -> void:
	var walls: Array[Node3D] = []
	for child: Node in _forest.get_node(^"Geometry").get_children():
		if String(child.name).begins_with("ForestWall"):
			walls.append(child as Node3D)
	assert_gte(walls.size(), 7, "lisières le long du bord nord")
	walls.sort_custom(func(a: Node3D, b: Node3D) -> bool: return a.position.x < b.position.x)
	for i in walls.size():
		var wall := walls[i] as DecorPanel
		assert_true(wall.keep_orientation, "%s suit le bord" % wall.name)
		if i > 0:
			var previous := walls[i - 1] as DecorPanel
			assert_ne(previous.texture, wall.texture, "%s : autre image que sa voisine" % wall.name)
			# Jointive : les deux pans se recouvrent (1 m) sans trou entre eux.
			var gap := _wall_end(previous, 1.0).distance_to(_wall_end(wall, -1.0))
			assert_lt(
				gap, WALL_OVERLAP, "%s : jointif avec %s (%.2f m)" % [wall.name, previous.name, gap]
			)
		# Derrière la lisière : entre l'arrière de sa collision et le bord, à ses deux bouts (les
		# seules entrées), un passage plus étroit que le joueur.
		var back := -wall.global_basis.z.normalized() * WALL_BACK
		for side: float in [-1.0, 1.0]:
			var corner := _wall_end(wall, side * 0.98) + back
			var gap := IslandTerrain.edge_distance(corner.x, corner.z)
			assert_lt(
				gap,
				PLAYER_RADIUS * 2.0,
				"%s : on ne passe pas derrière (%.2f m)" % [wall.name, gap]
			)


# --- Draw calls -----------------------------------------------------------------------------------


func test_draw_calls_of_the_woods_views_stay_in_budget() -> void:
	var views := VIEWS.duplicate()
	views.merge(CAMERA_VIEWS)
	for view: String in views:
		_aim(_forest.to_global(views[view] as Vector3), 21.0)
		var seen := _seen_batches(_island.get_node(^"Zones"))
		gut.p("vue %s : %d décors fondus à l'écran" % [view, seen.size()])
		assert_lte(seen.size(), DECOR_BUDGET, "vue %s : %d images à l'écran" % [view, seen.size()])


func test_neighbor_views_see_few_woods_images() -> void:
	for view: String in NEIGHBOR_VIEWS:
		var spec: Array = NEIGHBOR_VIEWS[view]
		var zone := _island.get_node(NodePath("Zones/%s" % spec[0])) as Node3D
		_aim(zone.to_global(spec[1] as Vector3), float(spec[2]))
		var seen := _seen_batches(_forest)
		gut.p("vue %s : %d images des bois" % [view, seen.size()])
		assert_lte(seen.size(), int(spec[3]), "vue %s : %d images des bois" % [view, seen.size()])


# --- Outils ---------------------------------------------------------------------------------------


## Relève les panneaux et décalques posés (enfants internes des PropScatter compris), avec le
## nom du nœud de Geometry qui les porte.
func _collect(node: Node, holder: String) -> void:
	for child: Node in node.get_children(true):
		var label := holder if not holder.is_empty() else String(child.name)
		if child is DecorPanel:
			var panel := child as DecorPanel
			var height := panel.size_m().y * panel.global_basis.get_scale().y
			_decor.append(
				[
					_forest.to_local(panel.global_position),
					panel.texture.resource_path,
					label,
					true,
					height
				]
			)
		elif child is GroundDecal:
			var decal := child as GroundDecal
			_decor.append(
				[
					_forest.to_local(decal.global_position),
					decal.texture.resource_path,
					label,
					false,
					0.0
				]
			)
		else:
			_collect(child, label)


## Vrai si le sol en `at` (local) est à l'écran du joueur en `player` (local).
func _seen(player: Vector3, at: Vector3) -> bool:
	var north := player.z - at.z
	if north < -SEEN_SOUTH or north > SEEN_NORTH:
		return false
	var share := (north + SEEN_SOUTH) / (SEEN_SOUTH + SEEN_NORTH)
	return absf(at.x - player.x) <= lerpf(SEEN_HALF_NEAR, SEEN_HALF_FAR, share)


func _species(image: String) -> String:
	var file := image.get_file()
	var found := ""
	var longest := 0
	for prefix: String in SPECIES:
		if file.begins_with(prefix.trim_suffix(".")) and prefix.length() > longest:
			if prefix.ends_with(".") and not file.begins_with(prefix):
				continue
			found = SPECIES[prefix]
			longest = prefix.length()
	return found


## Décors (couche world, hors sol) qui touchent la capsule du joueur debout en `at`.
func _decor_at(at: Vector3) -> Array[String]:
	var capsule := CapsuleShape3D.new()
	capsule.radius = PLAYER_RADIUS
	capsule.height = PLAYER_HEIGHT
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = 1
	var y := IslandTerrain.height_at(at.x, at.z) + 0.2 + PLAYER_HEIGHT / 2.0
	query.transform = Transform3D(Basis.IDENTITY, Vector3(at.x, y, at.z))
	var names: Array[String] = []
	for hit: Dictionary in _space.intersect_shape(query, 4):
		if hit["collider"] != _ground:
			var collider := hit["collider"] as Node
			names.append(String(collider.get_parent().get_path()))
	return names


## Bout gauche (side -1) ou droit (+1) du pied d'une lisière (monde).
func _wall_end(wall: DecorPanel, side: float) -> Vector3:
	var half := wall.size_m().x / 2.0 * wall.global_basis.get_scale().x
	return wall.global_position + wall.global_basis.x.normalized() * half * side


## Pose la caméra du joueur (camera_rig.tscn : tangage, champ, point visé au nord) pour des
## pieds en `feet`, à `distance` m du point visé.
func _aim(feet: Vector3, distance: float) -> void:
	var rig := CAMERA_RIG.instantiate()
	var pitch := deg_to_rad(float(rig.get(&"pitch_deg")))
	var focus := (
		feet
		+ Vector3.UP * float(rig.get(&"focus_height"))
		+ Vector3.FORWARD * float(rig.get(&"focus_ahead"))
	)
	_camera.fov = float(rig.get(&"fov_deg"))
	rig.free()
	var eye := focus + Vector3(0.0, sin(pitch), cos(pitch)) * distance
	_camera.look_at_from_position(eye, focus)


## Meshes fondus (« Batch… ») sous `root` dont la boîte coupe le champ de la caméra : un draw
## call chacun.
func _seen_batches(root: Node) -> Array[MeshInstance3D]:
	var planes := _camera.get_frustum()
	var inside := _camera.global_position - _camera.global_basis.z * 10.0
	var signs: Array[float] = []
	for plane: Plane in planes:
		signs.append(signf(plane.distance_to(inside)))
	var seen: Array[MeshInstance3D] = []
	for node: Node in root.find_children("Batch*", "MeshInstance3D", true, false):
		var batch := node as MeshInstance3D
		if batch.mesh == null or not batch.is_visible_in_tree():
			continue
		var box := batch.global_transform * batch.get_aabb()
		var out := false
		for p in planes.size():
			var all_out := true
			for c in 8:
				if signf(planes[p].distance_to(box.get_endpoint(c))) == signs[p]:
					all_out = false
					break
			if all_out:
				out = true
				break
		if not out:
			seen.append(batch)
	return seen
