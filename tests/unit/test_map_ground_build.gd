extends GutTest
## (E2) Sol en relief des cartes : construction (MapGround, MapGroundBuilder, MapGroundCoast) sur
## la carte de démonstration essai_relief et sur la carte de mesure de 80 × 60 m.
## - un draw call pour le sol, un pour les faces ; la collision est faite des triangles mêmes du
##   sol visible ; on marche exactement à la hauteur que donnent les requêtes ;
## - le sol est praticable partout (pentes de 40° au plus), les contremarches font 0,1 m au plus ;
## - la côte : rideau de roche sans collision, barrière, mer de nuages ;
## - la construction d'une carte de 80 × 60 m prend moins de 50 ms.

const DEMO_SCENE := "res://src/world/maps/essai_relief/essai_relief.tscn"
const TEST_ROOT := "res://tests/data/maps"
## Temps de construction maximal d'une carte de 80 × 60 m (ms), meilleur de BUILD_RUNS essais.
const BUILD_BUDGET_MSEC := 50.0
const BUILD_RUNS := 5

var _map: Node3D
var _ground: MapGround


func before_each() -> void:
	_map = (load(DEMO_SCENE) as PackedScene).instantiate() as Node3D
	add_child_autofree(_map)
	_ground = _map.get_node(^"Ground") as MapGround


func _triangle_normal(a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	return (c - a).cross(b - a)


func test_map_scene_follows_the_contract() -> void:
	assert_true(_map is Map, "racine Map (src/world/map.gd)")
	assert_eq(Map.problems(_map), PackedStringArray(), "contrat des cartes")
	for node_name: String in ["Ground", "Geometry", "Markers", "Markers/Spawn", "Exits", "Life"]:
		assert_true(_map.has_node(NodePath(node_name)), "enfant %s" % node_name)
	assert_true(_map.get_node(^"Ground") is MapGround, "Ground : MapGround")
	assert_true(_map.get_node(^"Geometry") is PropBatcher, "Geometry : PropBatcher")
	assert_eq(_ground.collision_layer, 1, "couche 1 (world)")
	var size: Vector2 = _map.get(&"size")
	assert_eq(Vector2i(size), _ground.map_size(), "taille de la carte = taille des données")
	var spawn := (_map.get_node(^"Markers/Spawn") as Marker3D).position
	assert_true(_ground.is_walkable(spawn.x, spawn.z), "départ praticable")
	assert_almost_eq(spawn.y, _ground.height_at(spawn.x, spawn.z), 0.01, "départ au sol")


func test_ground_is_one_draw_call_and_faces_one_more() -> void:
	var ground := _ground.ground_mesh()
	var cliffs := _ground.cliff_mesh()
	assert_eq(ground.get_surface_count(), 1, "le sol : une surface")
	assert_eq(cliffs.get_surface_count(), 1, "les faces et le rideau : une surface")
	var stats := _ground.stats()
	assert_lte(int(stats["draw_calls"]), 3, "sol, faces, mer de nuages")
	gut.p("essai_relief : %s" % stats)


func test_every_ground_triangle_faces_the_sky_and_is_walkable() -> void:
	var mesh := _ground.ground_mesh()
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	assert_gt(indices.size(), 300, "sol non vide")
	var steepest := 0.0
	var down := 0
	for n in range(0, indices.size(), 3):
		var normal := _triangle_normal(
			vertices[indices[n]], vertices[indices[n + 1]], vertices[indices[n + 2]]
		)
		if normal.length() < 0.0000001:
			continue
		normal = normal.normalized()
		if normal.y <= 0.0:
			down += 1
			continue
		steepest = maxf(steepest, rad_to_deg(acos(clampf(normal.y, 0.0, 1.0))))
	assert_eq(down, 0, "face avant vers le ciel")
	assert_lte(steepest, 40.0 + 0.01, "pente maximale %.1f°" % steepest)
	assert_gt(steepest, 15.0, "la rampe penche")


func test_collision_is_made_of_the_visible_triangles() -> void:
	var mesh := _ground.ground_mesh()
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var faces := _ground.collision_faces()
	assert_gte(faces.size(), indices.size(), "le sol et les faces")
	var same := true
	for n in indices.size():
		if faces[n] != vertices[indices[n]]:
			same = false
			break
	assert_true(same, "le sol de la collision : les triangles du mesh, dans l'ordre")
	# Chaque face visible est aussi dans la collision (le rideau sous la côte excepté).
	var solid := {}
	for n in range(indices.size(), faces.size(), 3):
		solid[_tri_key(faces[n], faces[n + 1], faces[n + 2])] = true
	var cliff_arrays := _ground.cliff_mesh().surface_get_arrays(0)
	var cliff_vertices: PackedVector3Array = cliff_arrays[Mesh.ARRAY_VERTEX]
	var cliff_uv2s: PackedVector2Array = cliff_arrays[Mesh.ARRAY_TEX_UV2]
	var cliff_uvs: PackedVector2Array = cliff_arrays[Mesh.ARRAY_TEX_UV]
	var cliff_indices: PackedInt32Array = cliff_arrays[Mesh.ARRAY_INDEX]
	var missing := 0
	var checked := 0
	for n in range(0, cliff_indices.size(), 3):
		var a := cliff_indices[n]
		# Le rideau (roche sans hauteur de face, UV2.y = 0) n'a pas de collision.
		if int(cliff_uv2s[a].x) == MapGroundData.Face.ROCK and cliff_uv2s[a].y == 0.0:
			continue
		checked += 1
		var key := _tri_key(
			cliff_vertices[a],
			cliff_vertices[cliff_indices[n + 1]],
			cliff_vertices[cliff_indices[n + 2]]
		)
		if not solid.has(key):
			missing += 1
	assert_gt(checked, 50, "faces vérifiées")
	assert_eq(missing, 0, "faces visibles sans collision")
	assert_eq(cliff_uvs.size(), cliff_vertices.size())


## Clé d'un triangle, quel que soit l'ordre de ses sommets.
func _tri_key(a: Vector3, b: Vector3, c: Vector3) -> String:
	var keys: Array[String] = []
	for p: Vector3 in [a, b, c]:
		keys.append("%.3f/%.3f/%.3f" % [p.x, p.y, p.z])
	keys.sort()
	return "|".join(keys)


func test_we_walk_exactly_on_what_we_see() -> void:
	await wait_physics_frames(2)
	var space := _map.get_world_3d().direct_space_state
	var size := _ground.map_size()
	var checked := 0
	var voids := 0
	var worst := 0.0
	var where := Vector2.ZERO
	var x := 0.137
	while x < size.x:
		var z := 0.211
		while z < size.y:
			var expected := _ground.height_at(x, z)
			# À deux centimètres de la côte, le point peut tomber d'un côté ou de l'autre.
			if absf(_ground.data.coast_value(x, z)) >= 0.005:
				var hit := _ground_hit(space, x, z)
				if expected == MapGround.VOID_HEIGHT:
					voids += 1
					assert_true(hit.is_empty(), "rien sous (%.2f, %.2f) : le vide" % [x, z])
				elif hit.is_empty():
					fail_test("pas de sol sous (%.2f, %.2f), attendu %.2f" % [x, z, expected])
				else:
					checked += 1
					var gap := absf((hit["position"] as Vector3).y - expected)
					if gap > worst:
						worst = gap
						where = Vector2(x, z)
			z += 0.53
		x += 0.71
	assert_gt(checked, 4000, "points vérifiés")
	assert_gt(voids, 20, "points dans le vide")
	assert_lt(worst, 0.002, "écart maximal %.4f m en %s" % [worst, where])


## Point du sol (le corps du MapGround seulement, pas les collisions des décors) sous (x, z) : le
## résultat d'intersect_ray, vide s'il n'y a rien.
func _ground_hit(space: PhysicsDirectSpaceState3D, x: float, z: float) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(Vector3(x, 20.0, z), Vector3(x, -60.0, z), 1)
	var excluded: Array[RID] = []
	for _attempt in 6:
		query.exclude = excluded
		var hit := space.intersect_ray(query)
		if hit.is_empty() or hit["collider"] == _ground:
			return hit
		excluded.append(hit["rid"] as RID)
	return {}


func test_stair_risers_are_low_enough_to_walk_up() -> void:
	var arrays := _ground.cliff_mesh().surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uv2s: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var risers := 0
	var tallest := 0.0
	for n in range(0, indices.size(), 3):
		if int(uv2s[indices[n]].x) != MapGroundData.Face.ATLAS:
			continue
		risers += 1
		var low := INF
		var high := -INF
		for k in 3:
			low = minf(low, vertices[indices[n + k]].y)
			high = maxf(high, vertices[indices[n + k]].y)
		tallest = maxf(tallest, high - low)
	assert_gt(risers, 10, "contremarches de l'escalier")
	assert_lte(tallest, MapGroundData.STAIR_RISER + 0.0001, "contremarche la plus haute")
	# La capsule du joueur (rayon 0,35 m, sol à 45° au plus) monte une marche de moins de 0,1025 m.
	assert_lt(MapGroundData.STAIR_RISER, 0.35 * (1.0 - cos(deg_to_rad(45.0))))


func test_faces_the_camera_never_sees_are_only_in_the_collision() -> void:
	var arrays := _ground.cliff_mesh().surface_get_arrays(0)
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uv2s: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2]
	var faces := 0
	var north := 0
	for n in normals.size():
		# Faces des paliers et des volées (le rideau de la côte : UV2.y = 0, style roche).
		if uv2s[n].y > 0.0 or int(uv2s[n].x) == MapGroundData.Face.ATLAS:
			faces += 1
			north += int(normals[n].z <= -0.5)
	assert_gt(faces, 100, "faces des paliers")
	assert_eq(north, 0, "aucune face tournée vers le nord dans le mesh")
	# Elles sont pourtant dans la collision : la falaise du plateau vue du nord arrête aussi.
	var collision := _ground.collision_faces()
	var facing_north := 0
	for n in range(0, collision.size(), 3):
		var normal := _triangle_normal(collision[n], collision[n + 1], collision[n + 2])
		if normal.length() > 0.0001 and normal.normalized().z < -0.9:
			facing_north += 1
	assert_gt(facing_north, 4, "faces tournées vers le nord dans la collision")


func test_the_coast_has_its_curtain_barrier_and_cloud_sea() -> void:
	var rim := _ground.rim_segments()
	assert_gt(rim.size(), 200, "segments de la côte")
	for n in range(0, rim.size(), 2):
		assert_lt(rim[n].z, 8.0, "la côte est au nord")
	assert_gt(_ground.barrier_faces().size(), rim.size(), "barrière le long de la côte")
	var clouds := _ground.get_node_or_null(^"CloudSea") as MeshInstance3D
	assert_not_null(clouds, "mer de nuages")
	if clouds != null:
		assert_lt(clouds.position.y, -40.0, "loin sous l'île")
	# Le rideau : de la roche jusqu'à plus de 30 m sous la côte.
	var arrays := _ground.cliff_mesh().surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var lowest := 0.0
	for p: Vector3 in vertices:
		lowest = minf(lowest, p.y)
	assert_lt(lowest, -30.0, "le rideau descend sous l'île")


func test_still_water_is_fenced_off() -> void:
	# La mare : une barrière la borde (on ne marche pas sur l'eau dormante).
	var barrier := _ground.barrier_faces()
	var around_pond := 0
	for p: Vector3 in barrier:
		if p.x > 4.0 and p.x < 17.0 and p.z > 26.0 and p.z < 36.0:
			around_pond += 1
	assert_gt(around_pond, 30, "barrière autour de la mare")
	assert_false(_ground.is_walkable(10.5, 31.0), "eau dormante")
	assert_eq(_ground.material_at(10.5, 31.0), &"eau")


func test_triangles_for_ground_decals() -> void:
	var triangles := _ground.triangles_in(Rect2(30.0, 40.0, 3.0, 3.0))
	var points: PackedVector3Array = triangles[0]
	var normals: PackedVector3Array = triangles[1]
	assert_gt(points.size(), 0, "triangles sous le rectangle")
	assert_eq(points.size() % 3, 0, "par triangles")
	assert_eq(normals.size(), points.size(), "une normale par sommet")
	for n in range(0, points.size(), 3):
		assert_gt(
			_triangle_normal(points[n], points[n + 1], points[n + 2]).y, 0.0, "face vers le ciel"
		)
	# Un décalque de la carte se couche sur ce sol (ici sur la rampe), pas sur le relief de l'île.
	assert_true((_map.get_node(^"Geometry/LilyPads") as GroundDecal).follow_ground)
	var decal := GroundDecal.new()
	decal.texture = load("res://assets/hd2d/decals/lily_pads.png") as Texture2D
	decal.position = Vector3(48.0, 2.0, 14.0)
	_map.get_node(^"Geometry").add_child(decal)
	var arrays := decal.draped_mesh().surface_get_arrays(0)
	var draped: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	assert_gt(draped.size(), 6, "décalque couché")
	var worst := 0.0
	var highest := 0.0
	for p: Vector3 in draped:
		worst = maxf(worst, absf(p.y - _ground.height_at(p.x, p.z)))
		highest = maxf(highest, p.y)
	assert_lt(worst, 0.01, "sur le sol de la carte")
	assert_gt(highest, 1.6, "il monte avec la rampe")


func test_an_80_by_60_map_builds_in_under_50_ms() -> void:
	# Caches statiques (atlas avec ses mipmaps, matériau des faces) : une fois par partie ; le
	# matériau des faces est gardé ici (référence faible ailleurs) pour toute la mesure.
	IslandTerrain.mipmapped_atlas(MapGround.ATLAS)
	var keep := MapGround.cliff_material()
	assert_not_null(keep, "matériau des faces")
	var best := INF
	var stats := {}
	for _run in BUILD_RUNS:
		var holder := Node3D.new()
		holder.name = "mesure_80x60"
		var ground := MapGround.new()
		ground.name = "Ground"
		ground.data_root = TEST_ROOT
		holder.add_child(ground)
		ground.build()
		if ground.build_msec < best:
			best = ground.build_msec
			stats = ground.stats()
		holder.free()
	gut.p("mesure_80x60 : meilleur temps %.1f ms ; %s" % [best, stats])
	assert_lt(best, BUILD_BUDGET_MSEC, "construction d'une carte de 80 × 60 m (lecture comprise)")
	assert_gt(float(stats.get("ground_triangles", 0)), 500.0, "carte complète")
