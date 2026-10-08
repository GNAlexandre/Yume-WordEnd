extends GutTest
## Emplacements de l'acte 1 (docs/lore/HISTOIRE.md, section 3.3) sur l'île n° 68 telle que la
## laisse le décor, quel que soit l'état des fichiers d'emplacement (le contenu de l'acte 1 les
## remplit à part) : chaque PNJ, objet et déclencheur du tableau a une place praticable :
##
## - sur l'île, à 3 m au moins du vide (MONDE.md, section 2.8) ;
## - au sol, à la hauteur du tableau (PNJ 0,2 m au-dessus du sol, objets au ras du sol, sommet de
##   la colline à 8 m) ;
## - hors du décor : aucune collision dans la capsule du joueur, aucun triangle des décors fondus
##   entre 0,3 et 1,7 m au-dessus du sol tout autour (sauf les baies, posées sur leur buisson) ;
## - relié à pied au Spawn du village (grille de 0,5 m, décor de la couche world).
##
## Un déclencheur est praticable si une partie de son disque l'est.

const FIXTURE := preload("res://tests/stubs/l2_island_fixture.gd")

## PNJ : zone, position locale (y = 0,2 m au-dessus du sol).
const NPCS := {
	"Nygglatho": [&"village", Vector3(-9.0, 0.2, -8.5)],
	"Willem": [&"village", Vector3(-13.5, 0.2, 0.0)],
	"Nephren": [&"village", Vector3(-4.0, 0.2, -9.5)],
	"Ithea": [&"village", Vector3(3.0, 0.2, 2.5)],
	"Tiat": [&"village", Vector3(-3.5, 0.2, 5.0)],
	"Collon": [&"village", Vector3(10.0, 0.2, -10.0)],
	"Lakhesh": [&"village", Vector3(-12.0, 0.2, -6.0)],
	"Almita": [&"village", Vector3(11.0, 0.2, 7.0)],
	"Pannibal": [&"forest", Vector3(-20.0, 0.2, -3.0)],
	"WillemTraining": [&"forest", Vector3(-9.0, 0.2, 10.0)],
	"GardeLookout": [&"dunes", Vector3(-14.0, 0.2, -10.0)],
	"Limeskin": [&"beach", Vector3(-20.0, 0.2, 12.0)],
	"CatWaiter": [&"beach", Vector3(-14.0, 0.2, -6.5)],
	"EggVendor": [&"beach", Vector3(-24.0, 0.2, 2.0)],
	"SnackVendor": [&"beach", Vector3(-6.0, 0.2, 1.0)],
	"Ramikeldi": [&"beach", Vector3(26.0, 0.2, -6.5)],
	"Ferryman": [&"beach", Vector3(12.0, 0.2, 13.0)],
	"Baker": [&"beach", Vector3(-4.0, 0.2, -7.0)],
	"WillemStars": [&"hill", Vector3(3.0, 8.2, 0.0)],
}
## Objets : zone, position locale (au ras du sol). « Inchangées » dans le tableau : positions des
## fichiers d'emplacement d'avant l'acte 1.
const PICKUPS := {
	"village_flower_1": [&"village", Vector3(17.0, 0.0, 5.0)],
	"forest_page_1": [&"forest", Vector3(-3.0, 0.0, 2.0)],
	"forest_page_2": [&"forest", Vector3(4.0, 0.0, 5.0)],
	"forest_page_3": [&"forest", Vector3(1.0, 0.0, -8.0)],
	"forest_page_4": [&"forest", Vector3(-12.0, 0.0, -13.0)],
	"forest_page_5": [&"forest", Vector3(11.0, 0.0, -7.0)],
	"forest_berries_1": [&"forest", Vector3(14.0, 0.0, -12.0)],
	"forest_berries_2": [&"forest", Vector3(-16.0, 0.0, 12.0)],
	"forest_berries_3": [&"forest", Vector3(20.0, 0.0, 6.0)],
	"forest_sheet_1": [&"forest", Vector3(3.0, 0.0, 24.0)],
	"forest_comb_1": [&"forest", Vector3(-32.0, 0.0, -8.0)],
	"forest_flower_1": [&"forest", Vector3(-8.0, 0.0, 18.0)],
	"dunes_sheet_1": [&"dunes", Vector3(-16.0, 0.0, 1.0)],
	"dunes_gear_1": [&"dunes", Vector3(-15.0, 0.0, -7.0)],
	"dunes_gear_2": [&"dunes", Vector3(-5.0, 0.0, -18.0)],
	"dunes_flower_1": [&"dunes", Vector3(8.0, 0.0, 19.0)],
	"beach_sheet_1": [&"beach", Vector3(-25.0, 0.0, 13.0)],
	"beach_sheet_2": [&"beach", Vector3(27.0, 0.0, 14.0)],
	"beach_gear_1": [&"beach", Vector3(30.0, 0.0, 10.0)],
	"hill_flower_1": [&"hill", Vector3(-19.0, 0.0, 7.0)],
	"hill_flower_2": [&"hill", Vector3(10.0, 0.0, 19.5)],
	"hill_flower_3": [&"hill", Vector3(-22.0, 0.0, -10.0)],
	"hill_sheet_1": [&"hill", Vector3(-2.0, 8.0, -3.0)],
}
## Objets posés sur leur décor (HISTOIRE.md : baies « sur des buissons à baies ») : le buisson,
## sans collision, peut les toucher.
const ON_DECOR: Array[String] = ["forest_berries_1", "forest_berries_2", "forest_berries_3"]
## Déclencheurs : zone, position locale (au sol), rayon.
const TRIGGERS := {
	"couchant_edge": [&"dunes", Vector3(-21.0, 0.0, -12.0), 3.0],
	"hill_summit": [&"hill", Vector3(1.0, 8.0, -3.0), 4.0],
}
## Distance minimale au vide (m) ; capsule du joueur ; marche franchie ; grille du chemin.
const EDGE_MARGIN := 3.0
const PLAYER_RADIUS := 0.35
const PLAYER_HEIGHT := 1.5
const STEP_UP := 0.2
const GRID_STEP := 0.5
## Rayon dégagé de tout triangle de décor entre 0,3 et 1,7 m au-dessus du sol : PNJ, objet.
const NPC_CLEARANCE := 0.45
const PICKUP_CLEARANCE := 0.35
const CLEAR_FROM := 0.3
const CLEAR_TO := 1.7
## Case (m) du rangement des triangles des décors fondus.
const BUCKET := 4.0

var _island: Node3D
var _space: PhysicsDirectSpaceState3D
var _ground: Node
var _walkable := PackedByteArray()
var _reached := PackedByteArray()
var _cells := 0
var _buckets: Dictionary[Vector2i, Array] = {}


func before_all() -> void:
	_island = FIXTURE.island()
	add_child(_island)
	await wait_physics_frames(2)
	_space = _island.get_world_3d().direct_space_state
	_ground = _island.get_node(^"Ground")
	_bucket_decor()
	_build_walk_map()


func after_all() -> void:
	_island.free()


func test_npc_spots_are_on_the_ground_clear_and_reachable() -> void:
	var problems: Array[String] = []
	for npc: String in NPCS:
		var spec: Array = NPCS[npc]
		var at := _global(spec[0] as StringName, spec[1] as Vector3)
		problems.append_array(_check_spot(npc, at, at.y - 0.2, 0.25, NPC_CLEARANCE))
	assert_true(problems.is_empty(), "places des PNJ : %s" % "; ".join(problems))


func test_pickup_spots_are_on_the_ground_clear_and_reachable() -> void:
	var problems: Array[String] = []
	for pickup: String in PICKUPS:
		var spec: Array = PICKUPS[pickup]
		var at := _global(spec[0] as StringName, spec[1] as Vector3)
		var clearance := 0.0 if pickup in ON_DECOR else PICKUP_CLEARANCE
		problems.append_array(_check_spot(pickup, at, at.y, 0.1, clearance))
	assert_true(problems.is_empty(), "places des objets : %s" % "; ".join(problems))


func test_trigger_discs_have_open_ground_reachable_on_foot() -> void:
	for trigger: String in TRIGGERS:
		var spec: Array = TRIGGERS[trigger]
		var center := _global(spec[0] as StringName, spec[1] as Vector3)
		var radius: float = spec[2]
		assert_true(
			IslandTerrain.distance_to_edge(center.x, center.z) >= EDGE_MARGIN,
			"%s : centre à %.1f m au moins du vide" % [trigger, EDGE_MARGIN]
		)
		assert_almost_eq(_floor_height(center), center.y, 0.25, "%s : sol au centre" % trigger)
		var open := 0
		for ring: float in [0.0, radius / 3.0, radius * 2.0 / 3.0]:
			for angle in range(0, 360, 45):
				var at := center + Vector3.FORWARD.rotated(Vector3.UP, deg_to_rad(angle)) * ring
				if _decor_at(at).is_empty() and _is_reached(at):
					open += 1
		assert_gt(
			open, 8, "%s : disque praticable et relié au village (%d points)" % [trigger, open]
		)


func test_walk_map_reaches_every_zone() -> void:
	for zone: Node in _island.get_node(^"Zones").get_children():
		var spawn := (zone.get_node(^"Spawn") as Node3D).global_position
		assert_true(_is_reached(spawn), "%s : Spawn relié au village à pied" % zone.name)


# --- Outils ------------------------------------------------------------------------------------


func _global(zone_id: StringName, local: Vector3) -> Vector3:
	return (_island.get_node(NodePath("Zones/" + zone_id)) as Node3D).to_global(local)


## Problèmes d'une place (vide si elle est praticable) : bord, hauteur du sol, collision, décor
## visible, chemin à pied.
func _check_spot(
	label: String, at: Vector3, floor_expected: float, tolerance: float, clearance: float
) -> Array[String]:
	var problems: Array[String] = []
	var edge := IslandTerrain.distance_to_edge(at.x, at.z)
	if edge < EDGE_MARGIN:
		problems.append("%s : à %.1f m du vide" % [label, edge])
	var floor_y := _floor_height(at)
	if absf(floor_y - floor_expected) > tolerance:
		problems.append("%s : sol à %.2f m (attendu %.2f)" % [label, floor_y, floor_expected])
	var blocking := _decor_at(at)
	if not blocking.is_empty():
		problems.append("%s : dans le décor (%s)" % [label, blocking])
	var meshes := _decor_mesh_near(at, floor_y, clearance) if clearance > 0.0 else ""
	if not meshes.is_empty():
		problems.append("%s : décor visible tout près (%s)" % [label, meshes])
	if not _is_reached(at):
		problems.append("%s : inaccessible à pied" % label)
	return problems


## Hauteur du sol (corps Ground) sous le point ; -INF dans le vide.
func _floor_height(at: Vector3) -> float:
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(at.x, 40.0, at.z), Vector3(at.x, -40.0, at.z), 1
	)
	var excluded: Array[RID] = []
	for _attempt in 6:
		query.exclude = excluded
		var hit := _space.intersect_ray(query)
		if hit.is_empty():
			return -INF
		if hit["collider"] == _ground:
			return (hit["position"] as Vector3).y
		excluded.append(hit["rid"] as RID)
	return -INF


## Décor (couche world, hors sol) qui touche une capsule de joueur debout en `at`.
func _decor_at(at: Vector3) -> String:
	var capsule := CapsuleShape3D.new()
	capsule.radius = PLAYER_RADIUS
	capsule.height = PLAYER_HEIGHT
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = 1
	var y := _floor_height(at) + STEP_UP + PLAYER_HEIGHT / 2.0
	query.transform = Transform3D(Basis.IDENTITY, Vector3(at.x, y, at.z))
	var names: Array[String] = []
	for hit: Dictionary in _space.intersect_shape(query, 4):
		if hit["collider"] != _ground:
			var collider := hit["collider"] as Node
			names.append("%s/%s" % [collider.get_parent().name, collider.name])
	return ", ".join(names)


## Triangles des décors fondus (Batch* des nœuds Geometry des zones), en coordonnées de l'île,
## rangés par case de BUCKET m (un triangle dans chaque case que couvre sa boîte).
func _bucket_decor() -> void:
	for zone: Node in _island.get_node(^"Zones").get_children():
		for child: Node in zone.get_node(^"Geometry").get_children():
			var batch := child as MeshInstance3D
			if batch == null or batch.mesh == null or not batch.name.begins_with("Batch"):
				continue
			var xform := batch.global_transform
			var vertices: PackedVector3Array = batch.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			for t in range(0, vertices.size() - 2, 3):
				var a := xform * vertices[t]
				var b := xform * vertices[t + 1]
				var c := xform * vertices[t + 2]
				var lo := a.min(b).min(c)
				var hi := a.max(b).max(c)
				for i in range(floori(lo.x / BUCKET), floori(hi.x / BUCKET) + 1):
					for j in range(floori(lo.z / BUCKET), floori(hi.z / BUCKET) + 1):
						var key := Vector2i(i, j)
						if not _buckets.has(key):
							_buckets[key] = []
						_buckets[key].append_array([a, b, c])


## Noms des boîtes de triangles de décor qui touchent la colonne de rayon `clearance` autour du
## point, entre CLEAR_FROM et CLEAR_TO m au-dessus du sol.
func _decor_mesh_near(at: Vector3, floor_y: float, clearance: float) -> String:
	var box := AABB(
		Vector3(at.x - clearance, floor_y + CLEAR_FROM, at.z - clearance),
		Vector3(clearance * 2.0, CLEAR_TO - CLEAR_FROM, clearance * 2.0)
	)
	var found: Array[String] = []
	for i in range(floori(box.position.x / BUCKET), floori(box.end.x / BUCKET) + 1):
		for j in range(floori(box.position.z / BUCKET), floori(box.end.z / BUCKET) + 1):
			var triangles: Array = _buckets.get(Vector2i(i, j), [])
			for t in range(0, triangles.size() - 2, 3):
				var a: Vector3 = triangles[t]
				var b: Vector3 = triangles[t + 1]
				var c: Vector3 = triangles[t + 2]
				var lo := a.min(b).min(c)
				var tri := AABB(lo, a.max(b).max(c) - lo)
				if tri.intersects(box) and _triangle_meets_box(a, b, c, box):
					var center := ((a + b + c) / 3.0).snapped(Vector3.ONE * 0.1)
					found.append("triangle près de %s" % center)
					if found.size() >= 3:
						return ", ".join(found)
	return ", ".join(found)


## Vrai si le triangle a un point dans la boîte : un sommet, ou un point de ses côtés ou de sa
## surface échantillonné tous les ~10 cm.
func _triangle_meets_box(a: Vector3, b: Vector3, c: Vector3, box: AABB) -> bool:
	var longest := maxf(a.distance_to(b), maxf(b.distance_to(c), c.distance_to(a)))
	var steps := clampi(ceili(longest / 0.1), 1, 200)
	for i in steps + 1:
		for j in steps + 1 - i:
			var u := float(i) / steps
			var v := float(j) / steps
			if box.has_point(a + (b - a) * u + (c - a) * v):
				return true
	return false


## Grille praticable (sur l'île, sans décor) et cases atteintes depuis le Spawn du village.
func _build_walk_map() -> void:
	_cells = int(IslandTerrain.SIZE / GRID_STEP)
	_walkable.resize(_cells * _cells)
	_reached.resize(_cells * _cells)
	for j in _cells:
		for i in _cells:
			var at := _cell_center(i, j)
			var on_island := IslandTerrain.is_land(at.x, at.z)
			_walkable[j * _cells + i] = 1 if on_island and _decor_at(at).is_empty() else 0
	var spawn := (_island.get_node(^"Zones/village/Spawn") as Node3D).global_position
	var start := _cell_index(spawn)
	_reached[start] = 1
	var queue: Array[int] = [start]
	var head := 0
	while head < queue.size():
		var cell := queue[head]
		head += 1
		var ci := cell % _cells
		var cj := floori(float(cell) / _cells)
		for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var ni := ci + step.x
			var nj := cj + step.y
			if ni < 0 or nj < 0 or ni >= _cells or nj >= _cells:
				continue
			var next := nj * _cells + ni
			if _reached[next] == 0 and _walkable[next] == 1:
				_reached[next] = 1
				queue.append(next)


func _cell_center(i: int, j: int) -> Vector3:
	var half := IslandTerrain.HALF
	return Vector3(-half + (i + 0.5) * GRID_STEP, 0.0, -half + (j + 0.5) * GRID_STEP)


func _cell_index(at: Vector3) -> int:
	var half := IslandTerrain.HALF
	var i := clampi(floori((at.x + half) / GRID_STEP), 0, _cells - 1)
	var j := clampi(floori((at.z + half) / GRID_STEP), 0, _cells - 1)
	return j * _cells + i


## Vrai si la case du point, ou une case voisine (on parle ou ramasse au contact), est atteinte.
func _is_reached(at: Vector3) -> bool:
	for offset: Vector3 in [
		Vector3.ZERO,
		Vector3(0.5, 0, 0),
		Vector3(-0.5, 0, 0),
		Vector3(0, 0, 0.5),
		Vector3(0, 0, -0.5)
	]:
		if _reached[_cell_index(at + offset)] == 1:
			return true
	return false
