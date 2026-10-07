extends GutTest
## Relief de l'île flottante (IslandTerrain, src/world/terrain.gd) : repères à y = 0, arène
## plate, pentes praticables (< 40°) sur toute la surface, surface coupée net au bord (lèvre à
## y = 0, rien au-delà), bord à l'intérieur des murs, vide au-delà.

## Points d'arrivée des zones et de l'arène, en coordonnées de l'île (PLAN.md, repères).
const LANDMARKS := {
	"village": Vector2(0.0, 9.0),
	"dunes": Vector2(-27.0, 0.0),
	"forest": Vector2(0.0, -27.0),
	"beach": Vector2(0.0, 27.0),
	"hill": Vector2(27.0, 0.0),
	"SpawnN": Vector2(-51.0, -13.0),
	"SpawnS": Vector2(-51.0, 13.0),
	"SpawnE": Vector2(-38.0, 0.0),
	"SpawnW": Vector2(-64.0, 0.0),
}
## Haut de la KillZone de island.tscn (m).
const KILL_ZONE_TOP := -10.0


func test_landmarks_are_on_flat_ground_at_zero() -> void:
	for landmark: String in LANDMARKS:
		var p: Vector2 = LANDMARKS[landmark]
		assert_almost_eq(
			IslandTerrain.height_at(p.x, p.y), 0.0, 0.01, "%s : sol à y = 0" % landmark
		)
		assert_true(IslandTerrain.is_land(p.x, p.y), "%s : sur l'île" % landmark)


func test_arena_floor_is_flat() -> void:
	var center := IslandTerrain.ARENA_CENTER
	for radius: float in [0.0, 4.0, 8.0, 12.0, IslandTerrain.ARENA_FLAT_RADIUS]:
		for angle in range(0, 360, 15):
			var p := center + Vector2.from_angle(deg_to_rad(angle)) * radius
			assert_almost_eq(IslandTerrain.height_at(p.x, p.y), 0.0, 0.001, "arène plate en %s" % p)


func test_dunes_rise_around_the_arena() -> void:
	var center := IslandTerrain.ARENA_CENTER
	var highest := 0.0
	for angle in range(0, 360, 10):
		var p := center + Vector2.from_angle(deg_to_rad(angle)) * 23.0
		highest = maxf(highest, IslandTerrain.height_at(p.x, p.y))
	assert_gt(highest, 2.0, "des dunes de plus de 2 m entourent le cercle de veille")


func test_every_surface_facet_is_walkable() -> void:
	# Triangles du mesh et de la collision du sol, découpés au bord compris.
	var surface := IslandTerrain.surface()
	assert_gt(surface.indices.size(), 3000 * 3, "surface non vide")
	var steepest := 0.0
	var where := Vector3.ZERO
	for n in range(0, surface.indices.size(), 3):
		var a := surface.vertices[surface.indices[n]]
		var b := surface.vertices[surface.indices[n + 1]]
		var c := surface.vertices[surface.indices[n + 2]]
		var normal := (c - a).cross(b - a)
		if normal.length() < 0.000001:
			continue
		normal = normal.normalized()
		assert_gt(normal.y, 0.0, "face avant vers le ciel en %s" % a)
		var slope := rad_to_deg(acos(clampf(normal.y, 0.0, 1.0)))
		if slope > steepest:
			steepest = slope
			where = a
	assert_lt(steepest, 40.0, "pente max %.1f° en %s (≤ 45° praticable)" % [steepest, where])


func test_surface_matches_height_function() -> void:
	var data := IslandTerrain.heights()
	var n := IslandTerrain.RESOLUTION
	assert_eq(data.size(), n * n, "grille de %d × %d" % [n, n])
	for ij: Vector2i in [Vector2i(0, 0), Vector2i(64, 64), Vector2i(20, 64), Vector2i(100, 40)]:
		var x := -IslandTerrain.HALF + ij.x * IslandTerrain.STEP
		var z := -IslandTerrain.HALF + ij.y * IslandTerrain.STEP
		assert_almost_eq(data[ij.y * n + ij.x], IslandTerrain.height_at(x, z), 0.0001)
	assert_eq(data[0], IslandTerrain.VOID_HEIGHT, "coin du carré : le vide")


func test_surface_ends_exactly_at_the_edge() -> void:
	var surface := IslandTerrain.surface()
	var beyond := 0
	for index: int in surface.indices:
		var v := surface.vertices[index]
		if IslandTerrain.edge_distance(v.x, v.z) < -0.01:
			beyond += 1
	assert_eq(beyond, 0, "aucun sommet de la surface au-delà du bord")
	# Le bord de la surface : des segments sur la ligne du bord, à y = 0, en boucle fermée.
	var rim := IslandTerrain.rim_segments()
	assert_gt(rim.size(), 600, "bord découpé finement")
	var starts := {}
	var ends := {}
	for k in range(0, rim.size(), 2):
		starts[rim[k]] = true
		ends[rim[k + 1]] = true
	var loose := 0
	for k in rim.size():
		var p := rim[k]
		assert_almost_eq(IslandTerrain.edge_distance(p.x, p.z), 0.0, 0.01, "%s sur le bord" % p)
		assert_almost_eq(p.y, 0.0, 0.001, "lèvre à y = 0 en %s" % p)
		if not (starts.has(p) and ends.has(p)):
			loose += 1
	assert_eq(loose, 0, "bord fermé : chaque point finit un segment et en commence un autre")


func test_the_lip_is_flat_all_around() -> void:
	for angle in range(0, 360, 2):
		var edge := IslandTerrain.edge_point(deg_to_rad(angle))
		var inside := edge - edge.normalized() * 0.6
		assert_true(IslandTerrain.is_land(inside.x, inside.y), "%d° : en deçà du bord" % angle)
		assert_almost_eq(
			IslandTerrain.height_at(inside.x, inside.y), 0.0, 0.01, "%d° : lèvre à y = 0" % angle
		)


func test_edge_stays_inside_the_walls_and_the_void_lies_beyond() -> void:
	for angle in range(0, 360, 2):
		var radius := IslandTerrain.edge_radius(deg_to_rad(angle))
		assert_between(radius, 60.0, 78.0, "bord à %d° : %.1f m" % [angle, radius])
		var edge := IslandTerrain.edge_point(deg_to_rad(angle))
		assert_lt(maxf(absf(edge.x), absf(edge.y)), 78.0, "%d° : dans le carré de ±78 m" % angle)
		var outside := edge + edge.normalized() * 0.6
		assert_false(IslandTerrain.is_land(outside.x, outside.y), "%d° : le vide" % angle)
	for p: Vector2 in [Vector2(79.0, 0.0), Vector2(0.0, -79.0), Vector2(-79.0, 79.0)]:
		assert_false(IslandTerrain.is_land(p.x, p.y), "%s : le vide" % p)
		assert_lt(IslandTerrain.height_at(p.x, p.y), KILL_ZONE_TOP, "%s : sous la KillZone" % p)
