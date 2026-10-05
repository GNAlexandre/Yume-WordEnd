extends GutTest
## Relief de l'île (IslandTerrain, src/world/terrain.gd) : repères à y = 0, arène plate,
## pentes praticables (≤ 45°) sur toute la terre ferme, côte à l'intérieur des murs.

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
	assert_gt(highest, 2.0, "des dunes de plus de 2 m entourent la cuvette")


func test_every_heightmap_facet_on_land_is_walkable() -> void:
	# Triangles de la HeightMapShape3D : quatre par case (les deux diagonales possibles).
	var data := IslandTerrain.heights()
	var n := IslandTerrain.RESOLUTION
	var step := IslandTerrain.STEP
	assert_eq(data.size(), n * n, "grille de %d × %d" % [n, n])
	var steepest := 0.0
	var where := Vector2.ZERO
	for j in n - 1:
		for i in n - 1:
			var k := j * n + i
			var p00 := Vector3(0.0, data[k], 0.0)
			var p10 := Vector3(step, data[k + 1], 0.0)
			var p01 := Vector3(0.0, data[k + n], step)
			var p11 := Vector3(step, data[k + n + 1], step)
			if maxf(maxf(p00.y, p10.y), maxf(p01.y, p11.y)) < IslandTerrain.WATER_LEVEL:
				continue
			var slope := maxf(
				maxf(_slope(p00, p10, p01), _slope(p10, p11, p01)),
				maxf(_slope(p00, p10, p11), _slope(p00, p11, p01))
			)
			if slope > steepest:
				steepest = slope
				where = Vector2(-IslandTerrain.HALF + i * step, -IslandTerrain.HALF + j * step)
	assert_lt(steepest, 40.0, "pente max %.1f° en %s (≤ 45° praticable)" % [steepest, where])


func test_heightmap_samples_match_height_function() -> void:
	var data := IslandTerrain.heights()
	var n := IslandTerrain.RESOLUTION
	for ij: Vector2i in [Vector2i(0, 0), Vector2i(64, 64), Vector2i(20, 64), Vector2i(100, 40)]:
		var x := -IslandTerrain.HALF + ij.x * IslandTerrain.STEP
		var z := -IslandTerrain.HALF + ij.y * IslandTerrain.STEP
		assert_almost_eq(data[ij.y * n + ij.x], IslandTerrain.height_at(x, z), 0.0001)


func test_coast_stays_inside_the_walls() -> void:
	for angle in range(0, 360, 2):
		var radius := IslandTerrain.coast_radius(deg_to_rad(angle))
		assert_between(radius, 60.0, 78.0, "côte à %d° : %.1f m" % [angle, radius])
	for p: Vector2 in [Vector2(79.0, 0.0), Vector2(0.0, -79.0), Vector2(-79.0, 79.0)]:
		assert_false(IslandTerrain.is_land(p.x, p.y), "%s : dans l'eau" % p)
		assert_lt(
			IslandTerrain.height_at(p.x, p.y), IslandTerrain.WATER_LEVEL, "%s : sous l'eau" % p
		)


func test_sea_floor_is_shallow_inside_the_walls() -> void:
	# Pas de fosse : on peut patauger jusqu'aux murs sans tomber.
	for t in range(-79, 80, 3):
		for p: Vector2 in [
			Vector2(t, 79.0), Vector2(t, -79.0), Vector2(79.0, t), Vector2(-79.0, t)
		]:
			assert_gte(IslandTerrain.height_at(p.x, p.y), IslandTerrain.SEA_FLOOR - 0.001)


## Pente (degrés) du triangle p0 p1 p2.
func _slope(p0: Vector3, p1: Vector3, p2: Vector3) -> float:
	var normal := (p1 - p0).cross(p2 - p0).normalized()
	return rad_to_deg(acos(clampf(absf(normal.y), 0.0, 1.0)))
