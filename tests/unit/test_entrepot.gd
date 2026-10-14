extends GutTest
## (T1) La carte entrepot, l'entrepôt des fées vu du dehors (docs/lore/CARTE.md, section 2 ; le
## bloc « plan » de 2.12 est lu ici même, il fait foi) :
##
## - exports de la Map (nom, lieu, taille, bornes de caméra) ;
## - sorties, marqueurs, places réservées et points nommés du plan, à leur place ; les portes du
##   bâtiment là où le plan les met (dehors = dedans + (29, 11)) ; tant que le rez-de-chaussée
##   (lot T2) n'existe pas, elles mènent à la carte d'essai des intérieurs et gardent leur cible
##   du plan en métadonnée ;
## - le bâtiment : deux volumes aux emprises et hauteurs du plan ;
## - tout s'atteint à pied depuis Spawn (capsule du joueur, marches de 0,5 m sautées) ;
## - règle de caméra (CARTE.md 0.3) : depuis la caméra du jeu, bornée comme CameraRig.limits, aucun
##   mur ni toit ne cache le joueur où qu'il se tienne, et aucun décor opaque (hors premier plan,
##   qui s'efface autour de lui, décalques et alpha doux) ne cache sa tête (1,4 m) ;
## - densité (2.11) mesurée par écran, de la vie dans chaque vue ;
## - draw calls : les décors fondus dans le champ, sur une grille de points de vue, plus le reste
##   (sol, personnages, interface, post-traitement), tiennent dans le budget (200).

const MAP_ID := &"entrepot"
const CARTE := "res://docs/lore/CARTE.md"
const CAMERA_RIG := preload("res://src/player/camera_rig.tscn")
const ASPECT := 16.0 / 9.0
## Grille de la marche (m), capsule du joueur, marche qu'on franchit (en sautant : 0,5 m).
const GRID := 0.5
const PLAYER_RADIUS := 0.35
const PLAYER_HEIGHT := 1.5
const JUMP := 0.55
## Points du corps vus par la caméra (m au-dessus des pieds) ; la tête, pour les décors.
const BODY: Array[float] = [0.25, 0.8, 1.4]
const HEAD := 1.4
## Grille (m) des places relevées pour l'occlusion.
const OCCLUSION_STEP := 1.0
## Draw calls hors des décors fondus et budget d'une vue ; pas de la grille des points de vue.
const OTHER_DRAW_CALLS := 45
const DRAW_CALL_BUDGET := 200
const VIEW_STEP := 6.0
## Correspondance dehors-dedans (CARTE.md 2.4) : dedans = dehors − OFFSET.
const INSIDE_OFFSET := Vector2(29.0, 11.0)
const RDC := &"entrepot_rdc"
## Vues de la densité (2.11) : place du joueur, éléments à l'écran (décors debout et décalques).
const DENSITY := {
	"cour": [Vector3(44.0, 0.0, 34.0), 70, 110],
	"abords ouest": [Vector3(33.0, 0.0, 30.0), 70, 110],
	"abords est": [Vector3(57.0, 0.0, 30.0), 70, 110],
	"champ": [Vector3(75.0, -0.5, 22.0), 40, 60],
	"clairiere": [Vector3(15.0, 0.5, 17.0), 40, 60],
	"bois": [Vector3(30.0, 0.0, 52.0), 90, 120],
	"marais": [Vector3(8.0, 0.0, 36.0), 90, 120],
	"riviere": [Vector3(16.0, 0.0, 48.0), 90, 120],
}
const DIRECTIONS := {
	"N": Vector3(0.0, 0.0, -1.0),
	"S": Vector3(0.0, 0.0, 1.0),
	"E": Vector3(1.0, 0.0, 0.0),
	"O": Vector3(-1.0, 0.0, 0.0),
}

var _map: Map
var _ground: MapGround
var _space: PhysicsDirectSpaceState3D
var _plan: Array[PackedStringArray] = []
var _pitch := 32.0
var _fov := 30.0
var _distance := 21.0
var _focus_height := 0.8
var _focus_ahead := 2.5
var _bounds := Rect2()
## Cases atteintes à pied depuis Spawn (clé : case de la grille ; valeur : hauteur du sol).
var _reached: Dictionary = {}
## Décors posés (racines : panneau, bâtiment, décalque) : [nœud, image, position].
var _elements: Array = []
## Triangles qui peuvent cacher le joueur : [vertices, uvs, image, frames] par lot, rangés par
## case de 4 m en x et z.
var _walls: Dictionary = {}
var _panels: Dictionary = {}


func before_all() -> void:
	_plan = plan_lines()
	_map = (load(Map.scene_path(MAP_ID)) as PackedScene).instantiate() as Map
	add_child(_map)
	await wait_physics_frames(2)
	_space = _map.get_world_3d().direct_space_state
	_ground = _map.get_node(^"Ground") as MapGround
	_bounds = _map.bounds()
	var rig := CAMERA_RIG.instantiate()
	_pitch = rig.get(&"pitch_deg")
	_fov = rig.get(&"fov_deg")
	_distance = rig.get(&"distance")
	_focus_height = rig.get(&"focus_height")
	_focus_ahead = rig.get(&"focus_ahead")
	rig.free()
	_collect(_map.get_node(^"Geometry"))
	_walk()
	_collect_occluders()


func after_all() -> void:
	_map.free()


## Instructions du bloc « plan » de la carte entrepot (CARTE.md 2.12), mots par ligne (les
## textes entre guillemets en un mot, sans les guillemets).
static func plan_lines() -> Array[PackedStringArray]:
	var lines: Array[PackedStringArray] = []
	var inside := false
	var ours := false
	for raw: String in FileAccess.get_file_as_string(CARTE).split("\n"):
		var line := raw.strip_edges()
		if line.begins_with("```"):
			inside = line == "```plan"
			ours = false
			continue
		if not inside or line.is_empty() or line.begins_with("#"):
			continue
		var words := _words(line)
		if words[0] == "carte":
			ours = words[1] == String(MAP_ID)
		elif ours:
			lines.append(words)
	return lines


static func _words(line: String) -> PackedStringArray:
	var words := PackedStringArray()
	var current := ""
	var quoted := false
	for character: String in line:
		if character == '"':
			quoted = not quoted
			if not quoted:
				words.append(current)
				current = ""
		elif character == " " and not quoted:
			if not current.is_empty():
				words.append(current)
			current = ""
		else:
			current += character
	if not current.is_empty():
		words.append(current)
	return words


func _lines(kind: String) -> Array[PackedStringArray]:
	var found: Array[PackedStringArray] = []
	for words in _plan:
		if words[0] == kind:
			found.append(words)
	return found


# --- La carte et le plan ------------------------------------------------------------------------


func test_the_plan_is_read() -> void:
	assert_eq(_lines("sortie").size(), 6, "six sorties")
	assert_eq(_lines("marqueur").size(), 8, "huit marqueurs")
	assert_eq(_lines("point").size(), 19, "dix-neuf points nommés")
	assert_eq(_lines("place").size(), 5, "cinq places réservées")


func test_map_exports_follow_the_plan() -> void:
	assert_eq(_map.display_name, "L'entrepôt des fées")
	assert_eq(_map.region, &"entrepot")
	assert_eq(_map.size, Vector2(88, 60))
	assert_eq(_map.camera_bounds, Rect2(10, 9, 68, 43), "bornes de caméra de CARTE.md 2.2")
	assert_false(_map.interior)
	assert_eq(Map.problems(_map), PackedStringArray(), "contrat des cartes")
	assert_eq(_ground.map_size(), Vector2i(88, 60), "sol de la taille de la carte")


func test_exits_follow_the_plan() -> void:
	for words in _lines("sortie"):
		var exit := _map.get_node_or_null(NodePath("Exits/" + words[1])) as MapExit
		assert_not_null(exit, "sortie %s" % words[1])
		if exit == null:
			continue
		var rect := Rect2(float(words[2]), float(words[3]), 0.0, 0.0).expand(
			Vector2(float(words[4]), float(words[5]))
		)
		var shape := exit.get_node(^"CollisionShape3D") as CollisionShape3D
		var box := shape.shape as BoxShape3D
		var center := shape.global_position
		assert_almost_eq(
			Vector2(center.x, center.z), rect.get_center(), Vector2.ONE * 0.01, words[1]
		)
		assert_true(
			box.size.x >= rect.size.x - 0.01 and box.size.z >= rect.size.y - 0.01,
			"%s couvre sa zone" % words[1]
		)
		assert_eq(exit.prompt, words[8] if words.size() > 8 else "", "%s : invite" % words[1])
		var target := StringName(words[6])
		var marker := StringName(words[7])
		if target == RDC and not Map.exists(RDC):
			# Provisoire (docs/DECISIONS.md, T1) : le lot T2 construit le rez-de-chaussée.
			assert_eq(exit.get_meta(&"plan_target_map", &""), RDC, "%s : cible du plan" % words[1])
			assert_eq(exit.get_meta(&"plan_target_marker", &""), marker, words[1])
			assert_true(Map.exists(exit.target_map), "%s : cible provisoire" % words[1])
		else:
			assert_eq(exit.target_map, target, "%s : carte cible" % words[1])
			assert_eq(exit.target_marker, marker, "%s : marqueur d'arrivée" % words[1])


func test_markers_follow_the_plan() -> void:
	for words in _lines("marqueur"):
		var marker := _map.marker(StringName(words[1]))
		assert_not_null(marker, "marqueur %s" % words[1])
		if marker == null:
			continue
		var at := marker.global_position
		assert_almost_eq(
			Vector2(at.x, at.z), Vector2(float(words[2]), float(words[3])), Vector2.ONE * 0.01
		)
		assert_almost_eq(at.y, _ground.height_at(at.x, at.z) + 0.2, 0.06, "%s à 0,2 m" % words[1])
		var look: Vector3 = DIRECTIONS[words[4]]
		assert_almost_eq(-marker.global_basis.z, look, Vector3.ONE * 0.001, "%s regarde" % words[1])
		assert_true(_is_reached(at), "%s : on y marche" % words[1])


func test_places_and_named_points_follow_the_plan() -> void:
	for words in _lines("point"):
		var point := _map.get_node_or_null(NodePath("Life/Places/" + words[1])) as Marker3D
		assert_not_null(point, "point %s" % words[1])
		if point == null:
			continue
		var at := point.global_position
		assert_almost_eq(
			Vector2(at.x, at.z), Vector2(float(words[2]), float(words[3])), Vector2.ONE * 0.01
		)
		assert_true(_is_reached(at), "%s : on y va à pied" % words[1])
	for words in _lines("place"):
		var area := _map.get_node_or_null(NodePath("Life/Areas/" + words[1])) as Marker3D
		assert_not_null(area, "place %s" % words[1])
		if area == null:
			continue
		var rect := Rect2(float(words[2]), float(words[3]), 0.0, 0.0).expand(
			Vector2(float(words[4]), float(words[5]))
		)
		assert_eq(area.get_meta(&"area", Rect2()), rect, "%s : rectangle" % words[1])
		assert_true(_is_reached(area.global_position), "%s : on y va à pied" % words[1])
		assert_eq(
			_blocking_in(rect.grow(-0.4)), [] as Array[String], "%s : rien n'y bloque" % words[1]
		)


func test_the_building_and_its_doors_are_where_the_plan_puts_them() -> void:
	var volumes := {"EntrepotOuest": "entrepot_ouest", "EntrepotEst": "entrepot_est"}
	for node_name: String in volumes:
		var building := _map.get_node(NodePath("Geometry/Building/" + node_name)) as Building
		var words := PackedStringArray()
		for line in _lines("bati"):
			if line[1] == volumes[node_name]:
				words = line
		var rect := Rect2(float(words[2]), float(words[3]), 0.0, 0.0).expand(
			Vector2(float(words[4]), float(words[5]))
		)
		var at := building.global_position
		assert_almost_eq(Vector2(at.x, at.z), rect.get_center(), Vector2.ONE * 0.01, node_name)
		assert_eq(building.footprint, rect.size, "%s : emprise" % node_name)
		assert_almost_eq(building.wall_height, 6.5, 0.01, "%s : murs de 6,5 m" % node_name)
	var west := _map.get_node(^"Geometry/Building/EntrepotOuest") as Building
	var east := _map.get_node(^"Geometry/Building/EntrepotEst") as Building
	assert_almost_eq(west.ridge_height, 10.0, 0.01, "faîte du volume ouest")
	assert_almost_eq(east.ridge_height, east.wall_height, 0.01, "toit plat en terrasse à l'est")
	# Porte d'entrée en (42 ; 26) dehors, (13 ; 15) dedans ; porte de service au pignon ouest.
	var front := (_map.get_node(^"Exits/porte_entree") as Node3D).global_position
	assert_almost_eq(front.x, 42.0, 0.01, "porte d'entrée à x = 42")
	assert_almost_eq(front.x - INSIDE_OFFSET.x, 13.0, 0.01, "au centre de l'entrée du dedans")
	assert_between(front.z, 25.4, 26.0, "dans la façade sud (z = 26)")
	var service := (_map.get_node(^"Exits/porte_service") as Node3D).global_position
	assert_almost_eq(service.x, 29.7, 0.05, "porte de service au pignon ouest (x = 30)")
	assert_between(service.z - INSIDE_OFFSET.y, 8.4, 10.6, "dans le couloir du dedans")
	# Le porche, devant la porte : son banc et ses poteaux de part et d'autre du seuil.
	var porch := _map.get_node(^"Geometry/Porch/Porch") as Node3D
	assert_almost_eq(
		Vector2(porch.global_position.x, porch.global_position.z),
		Vector2(42, 27.2),
		Vector2.ONE * 0.01
	)
	# Les deux portes s'atteignent : leur zone d'interaction touche une case où l'on marche.
	for exit_name: String in ["porte_entree", "porte_service"]:
		var exit := _map.get_node(NodePath("Exits/" + exit_name)) as MapExit
		var reached := false
		for dx: float in [-0.5, 0.0, 0.5]:
			for dz: float in [-1.0, -0.5, 0.5, 1.0]:
				var probe := exit.global_position + Vector3(dx, 0.0, dz)
				if exit_name == "porte_service":
					probe = exit.global_position + Vector3(dz, 0.0, dx)
				reached = reached or _is_reached(probe)
		assert_true(reached, "%s : on s'en approche" % exit_name)


## Le marqueur qui ramène par une sortie (from_<carte cible>, ou from_<carte cible>_<suffixe> si
## plusieurs sorties mènent à la même carte : le plus proche) est à 2 ou 3 m d'elle.
func test_exit_markers_stand_clear_of_their_exits() -> void:
	for words in _lines("sortie"):
		var exit := _map.get_node(NodePath("Exits/" + words[1])) as MapExit
		var back := "from_" + words[6]
		var nearest := INF
		var found := ""
		for marker_name: StringName in _map.marker_names():
			if String(marker_name) != back and not String(marker_name).begins_with(back + "_"):
				continue
			var at := _map.marker(marker_name).global_position
			var distance := Vector2(at.x, at.z).distance_to(
				Vector2(exit.global_position.x, exit.global_position.z)
			)
			if distance < nearest:
				nearest = distance
				found = String(marker_name)
		assert_between(nearest, 1.2, 4.0, "%s à 2 ou 3 m de %s" % [found, words[1]])


# --- Marche ---------------------------------------------------------------------------


func test_every_band_of_the_map_is_reached_on_foot() -> void:
	var cells := 0
	for key: Vector2i in _reached:
		if _reached[key] != null:
			cells += 1
	assert_gt(cells * GRID * GRID, 2600.0, "plus de 2 600 m² où l'on marche")
	for spot: Vector3 in [
		Vector3(75, 0, 18),
		Vector3(15, 0, 15),
		Vector3(3, 0, 12),
		Vector3(9.5, 0, 48),
		Vector3(44, 0, 50),
		Vector3(14, 0, 2.5),
		Vector3(86, 0, 38),
		Vector3(2, 0, 40),
	]:
		assert_true(_is_reached(spot), "%s atteint à pied" % spot)


# --- Règle de caméra ---------------------------------------------------------------------------


func test_no_wall_roof_or_opaque_decor_hides_the_player() -> void:
	assert_gt(_walls.size(), 0, "murs et toits relevés")
	assert_gt(_panels.size(), 0, "décors relevés")
	var hidden: Array[String] = []
	var checked := 0
	var x := 0.5
	while x < _map.size.x:
		var z := 0.5
		while z < _map.size.y:
			var feet := Vector3(x, 0.0, z)
			if _is_reached(feet):
				checked += 1
				feet.y = _ground.height_at(x, z)
				var eye := _camera(feet).origin
				for height: float in BODY:
					var hit := _occluder(_walls, eye, feet + Vector3.UP * height)
					if hit.is_empty() and height >= HEAD:
						hit = _occluder(_panels, eye, feet + Vector3.UP * height)
					if not hit.is_empty() and hidden.size() < 12:
						hidden.append("(%.1f ; %.1f) %.2f m : %s" % [x, z, height, hit])
						break
			z += OCCLUSION_STEP
		x += OCCLUSION_STEP
	gut.p("%d places vérifiées" % checked)
	assert_gt(checked, 2000, "toute la carte où l'on marche")
	assert_eq(hidden, [] as Array[String], "joueur caché")


# --- Densité ---------------------------------------------------------------------------


func test_each_view_shows_its_density_and_some_life() -> void:
	for view: String in DENSITY:
		var spec: Array = DENSITY[view]
		var at: Vector3 = spec[0]
		at.y = _ground.height_at(at.x, at.z)
		# Un écran ≈ 20 × 20 m de sol (CARTE.md 0.4) : autour du point visé, 7 m au sud et 13 au
		# nord, ce que la vue montre sans le lointain.
		var focus := _camera(at).origin - Basis(Vector3.RIGHT, deg_to_rad(-_pitch)).z * _distance
		var screen := Rect2(focus.x - 10.0, focus.z - 13.0, 20.0, 20.0)
		var standing := 0
		var decals := 0
		var moving := 0
		for element: Array in _elements:
			var where: Vector3 = element[2]
			if not screen.has_point(Vector2(where.x, where.z)):
				continue
			if element[0] is GroundDecal:
				decals += 1
			else:
				standing += 1
			var panel := element[0] as DecorPanel
			if panel != null and panel.frames > 1:
				moving += 1
		var ambient := 0
		for node: Node in _map.get_node(^"Ambience").get_children():
			var sprites := node as AmbientSprites
			var region := Rect2(
				(
					Vector2(sprites.global_position.x, sprites.global_position.z)
					- sprites.region_size / 2.0
				),
				sprites.region_size
			)
			if (
				not sprites.region_size.is_zero_approx()
				and not region.grow(4.0).has_point(Vector2(at.x, at.z))
			):
				continue
			ambient += 1
		var total := standing + decals
		gut.p(
			(
				"%s : %d éléments (%d debout, %d décalques), %d qui bougent, %d vies ambiantes"
				% [view, total, standing, decals, moving, ambient]
			)
		)
		assert_between(total, spec[1], spec[2], "%s : %d éléments à l'écran" % [view, total])
		assert_gt(moving + ambient, 0, "%s : de la vie à l'écran" % view)


func test_no_bare_ground_wider_than_six_metres_outside_the_places() -> void:
	var places: Array[Rect2] = []
	for words in _lines("place"):
		places.append(
			Rect2(float(words[2]), float(words[3]), 0.0, 0.0).expand(
				Vector2(float(words[4]), float(words[5]))
			)
		)
	var bare: Array[String] = []
	var x := 3.0
	while x < _map.size.x - 3.0:
		var z := 3.0
		while z < _map.size.y - 3.0:
			var square := Rect2(x - 3.0, z - 3.0, 6.0, 6.0)
			var in_place := false
			for place in places:
				in_place = in_place or place.intersects(square)
			if not in_place and _is_reached(Vector3(x, 0, z)) and _elements_in(square) == 0:
				bare.append("(%.0f ; %.0f)" % [x, z])
			z += 2.0
		x += 2.0
	assert_eq(bare, [] as Array[String], "sol nu de 6 × 6 m hors des places")


# --- Draw calls ---------------------------------------------------------------------------


func test_batched_decor_in_each_view_stays_within_the_draw_call_budget() -> void:
	var batches: Array[MeshInstance3D] = []
	for child: Node in _map.get_node(^"Geometry").get_children():
		var mesh := child as MeshInstance3D
		if mesh != null and mesh.mesh != null and String(mesh.name).begins_with("Batch"):
			batches.append(mesh)
	assert_gt(batches.size(), 50, "décors fondus par image")
	var worst := 0
	var worst_at := Vector3.ZERO
	var views := 0
	var x := 3.0
	while x < _map.size.x:
		var z := 3.0
		while z < _map.size.y:
			var feet := Vector3(x, 0.0, z)
			if _is_reached(feet):
				views += 1
				feet.y = _ground.height_at(x, z)
				var camera := _camera(feet)
				var drawn := 0
				for mesh in batches:
					if _box_on_screen(camera, mesh.global_transform * mesh.get_aabb()):
						drawn += 1
				if drawn > worst:
					worst = drawn
					worst_at = feet
			z += VIEW_STEP
		x += VIEW_STEP
	gut.p("%d vues ; au plus %d lots de décor dans le champ, en %s" % [views, worst, worst_at])
	assert_gt(views, 60, "une grille de points de vue")
	assert_lte(worst + OTHER_DRAW_CALLS, DRAW_CALL_BUDGET, "au plus 200 draw calls par vue")


# --- Outils ---------------------------------------------------------------------------


func _collect(node: Node) -> void:
	for child: Node in node.get_children(true):
		var image: Texture2D = null
		if child is DecorPanel:
			image = (child as DecorPanel).texture
		elif child is Building:
			image = (child as Building).facade
		elif child is GroundDecal:
			image = (child as GroundDecal).texture
		if image != null:
			_elements.append([child, image.resource_path, (child as Node3D).global_position])
			continue
		if not (child is MeshInstance3D):
			_collect(child)


func _elements_in(rect: Rect2) -> int:
	var count := 0
	for element: Array in _elements:
		var at: Vector3 = element[2]
		if rect.has_point(Vector2(at.x, at.z)):
			count += 1
	return count


## Noms des décors bloquants (couche world, hors sol) dont la collision touche rect (à mi-hauteur).
func _blocking_in(rect: Rect2) -> Array[String]:
	var found: Array[String] = []
	var box := BoxShape3D.new()
	box.size = Vector3(rect.size.x, 1.0, rect.size.y)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = box
	query.collision_mask = 1
	var center := rect.get_center()
	query.transform = Transform3D(
		Basis.IDENTITY, Vector3(center.x, _ground.height_at(center.x, center.y) + 1.0, center.y)
	)
	for hit: Dictionary in _space.intersect_shape(query, 32):
		if hit["collider"] != _ground:
			found.append(String((hit["collider"] as Node).get_parent().name))
	return found


## Cases atteintes depuis Spawn : la capsule du joueur posée au sol ne touche aucun décor ; on
## passe d'une case à sa voisine si le sol ne change pas de plus de JUMP (marche sautée).
func _walk() -> void:
	var capsule := CapsuleShape3D.new()
	capsule.radius = PLAYER_RADIUS
	capsule.height = PLAYER_HEIGHT
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = 1
	var spawn := _map.spawn().global_position
	var start := _cell(spawn)
	_reached[start] = _ground.height_at(spawn.x, spawn.z)
	var queue: Array[Vector2i] = [start]
	var head := 0
	while head < queue.size():
		var cell := queue[head]
		head += 1
		var from_height: float = _reached[cell]
		for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var next := cell + step
			if _reached.has(next):
				continue
			var x := next.x * GRID
			var z := next.y * GRID
			if x < PLAYER_RADIUS or z < PLAYER_RADIUS or x > _map.size.x - PLAYER_RADIUS:
				continue
			if z > _map.size.y - PLAYER_RADIUS or not _ground.is_walkable(x, z):
				continue
			var height := _ground.height_at(x, z)
			if absf(height - from_height) > JUMP:
				continue
			query.transform = Transform3D(
				Basis.IDENTITY, Vector3(x, height + 0.25 + PLAYER_HEIGHT / 2.0, z)
			)
			var free := true
			for hit: Dictionary in _space.intersect_shape(query, 16):
				if hit["collider"] != _ground:
					free = false
					break
			if free:
				_reached[next] = height
				queue.append(next)


func _cell(at: Vector3) -> Vector2i:
	return Vector2i(roundi(at.x / GRID), roundi(at.z / GRID))


func _is_reached(at: Vector3) -> bool:
	for dx: int in [-1, 0, 1]:
		for dz: int in [-1, 0, 1]:
			if _reached.has(_cell(at) + Vector2i(dx, dz)):
				return true
	return false


## Caméra du jeu quand le joueur se tient en feet : point visé (focus_ahead au nord) borné aux
## bornes de la carte, comme CameraRig.limits.
func _camera(feet: Vector3) -> Transform3D:
	var tilt := Basis(Vector3.RIGHT, deg_to_rad(-_pitch))
	var focus := feet + Vector3(0.0, _focus_height, -_focus_ahead)
	focus.x = clampf(focus.x, _bounds.position.x, _bounds.end.x)
	focus.z = clampf(focus.z, _bounds.position.y, _bounds.end.y)
	return Transform3D(tilt, focus + tilt.z * _distance)


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


## Vrai si la boîte n'est pas écartée par le tri de la caméra : écartée si ses huit coins sont du
## mauvais côté d'un même plan du cadre (proche, gauche, droite, haut, bas ; sans le loin).
func _box_on_screen(camera: Transform3D, box: AABB) -> bool:
	var half := tan(deg_to_rad(_fov) / 2.0)
	var inverse := camera.affine_inverse()
	var outside := [0, 0, 0, 0, 0]
	for i in 8:
		var local := inverse * box.get_endpoint(i)
		var depth := -local.z
		outside[0] += 1 if depth < 0.05 else 0
		outside[1] += 1 if local.x < -depth * half * ASPECT else 0
		outside[2] += 1 if local.x > depth * half * ASPECT else 0
		outside[3] += 1 if local.y < -depth * half else 0
		outside[4] += 1 if local.y > depth * half else 0
	return not outside.has(8)


## Triangles fondus qui peuvent cacher le joueur : murs et toits (matières des bâtiments,
## façades et flancs), et panneaux opaques (ni décalques, ni alpha doux, ni premier plan).
func _collect_occluders() -> void:
	var images := {}
	for child: Node in _map.get_node(^"Geometry").get_children():
		var batch := child as MeshInstance3D
		if batch == null or batch.mesh == null or not String(batch.name).begins_with("Batch"):
			continue
		var material := batch.material_override as ShaderMaterial
		if material == null:
			continue
		if (
			material.shader
			in [
				GroundDecal.HARD_SHADER,
				GroundDecal.SOFT_SHADER,
				DecorPanel.SOFT_SHADER,
				DecorPanel.FOREGROUND_SHADER
			]
		):
			continue
		var texture := material.get_shader_parameter(&"albedo_texture") as Texture2D
		if texture == null:
			continue
		var path := texture.resource_path
		var wall := path.contains("/buildings/")
		if not images.has(path):
			images[path] = texture.get_image()
		var frames_value: Variant = material.get_shader_parameter(&"frames")
		var frames := maxi(roundi(float(frames_value)), 1) if frames_value != null else 1
		var arrays := batch.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var xform := batch.global_transform
		for t in range(0, vertices.size() - 2, 3):
			var tri := PackedVector3Array(
				[xform * vertices[t], xform * vertices[t + 1], xform * vertices[t + 2]]
			)
			var entry := [
				tri,
				uvs.slice(t, t + 3),
				images[path],
				frames,
				path.get_file().get_basename(),
				tri[0].min(tri[1]).min(tri[2]),
				tri[0].max(tri[1]).max(tri[2]),
			]
			_bucket(_walls if wall else _panels, entry)


## Range un triangle par mètre en x de son emprise.
func _bucket(buckets: Dictionary, entry: Array) -> void:
	var low: Vector3 = entry[5]
	var high: Vector3 = entry[6]
	for i in range(floori(low.x), floori(high.x) + 1):
		if not buckets.has(i):
			buckets[i] = []
		(buckets[i] as Array).append(entry)


## Image d'un triangle dont un pixel opaque coupe le segment caméra → point (à plus de 0,3 m du
## point) ; vide sinon. Murs (matières répétées) : opaques partout.
func _occluder(buckets: Dictionary, from: Vector3, to: Vector3) -> String:
	var direction := (to - from).normalized()
	var limit := from.distance_to(to) - 0.3
	var low := from.min(to)
	var high := from.max(to)
	for i in range(floori(low.x), floori(high.x) + 1):
		for entry: Array in buckets.get(i, []):
			var box_low: Vector3 = entry[5]
			var box_high: Vector3 = entry[6]
			if (
				box_high.z < low.z
				or box_low.z > high.z
				or box_high.y < low.y
				or box_low.y > high.y
				or box_high.x < low.x
				or box_low.x > high.x
			):
				continue
			var tri: PackedVector3Array = entry[0]
			var hit: Variant = Geometry3D.ray_intersects_triangle(
				from, direction, tri[0], tri[1], tri[2]
			)
			if hit == null or from.distance_to(hit as Vector3) > limit:
				continue
			if String(entry[4]).begins_with("wall_"):
				return String(entry[4])
			if _alpha_at(entry, hit as Vector3) >= 0.5:
				return String(entry[4])
	return ""


## Opacité de l'image du triangle au point p (coordonnées barycentriques, UV répétées ; bande
## animée : la plus forte de ses images).
func _alpha_at(entry: Array, p: Vector3) -> float:
	var tri: PackedVector3Array = entry[0]
	var uvs: PackedVector2Array = entry[1]
	var image: Image = entry[2]
	var frames: int = entry[3]
	var v0 := tri[1] - tri[0]
	var v1 := tri[2] - tri[0]
	var v2 := p - tri[0]
	var d00 := v0.dot(v0)
	var d01 := v0.dot(v1)
	var d11 := v1.dot(v1)
	var d20 := v2.dot(v0)
	var d21 := v2.dot(v1)
	var denom := d00 * d11 - d01 * d01
	if absf(denom) < 1e-9:
		return 0.0
	var v := (d11 * d20 - d01 * d21) / denom
	var w := (d00 * d21 - d01 * d20) / denom
	var uv := uvs[0] * (1.0 - v - w) + uvs[1] * v + uvs[2] * w
	var y := clampi(floori(fposmod(uv.y, 1.0) * image.get_height()), 0, image.get_height() - 1)
	var alpha := 0.0
	for frame in frames:
		var u := (float(frame) + fposmod(uv.x, 1.0)) / frames
		var x := clampi(floori(u * image.get_width()), 0, image.get_width() - 1)
		alpha = maxf(alpha, image.get_pixel(x, y).a)
	return alpha
