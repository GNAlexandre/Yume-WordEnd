extends GutTest
## (B1) Le bord de l'île (IslandTerrain, IslandRock ; docs/lore/MONDE.md, section 2.8) : une seule
## forme pour le script et le shader du sol, une côte qui n'est droite nulle part sauf au quai,
## qui n'avance qu'au-dehors du tracé d'origine (sauf dans les anses) et reste dans le carré des
## murs, la cascade au bout du lit du ruisseau, la roche qui suit le bord sans se croiser, des
## textures de roche sans couture ni étirement, et un budget de triangles tenu.

const TERRAIN_SHADER := "res://src/world/shaders/terrain.gdshader"
const ISLAND := preload("res://src/world/island.tscn")
## Longueur (m) d'un tronçon de côte et écart minimal (m) de la côte à sa corde (la caméra montre
## environ 20 m de large).
const STRETCH := 20.0
const MIN_BEND := 0.5
## Triangles : sol et roche (mesurés : 11 576 et 3 964 avant B1 ; 12 258 et 6 048 après).
const MAX_GROUND_TRIANGLES := 13000
const MAX_ROCK_TRIANGLES := 6500


func test_shader_reads_the_script_shape() -> void:
	# La texture du shader : la table du script, texel par texel.
	var texture := IslandEdge.texture()
	var image := texture.get_image()
	var table := IslandEdge.table()
	assert_eq(image.get_format(), Image.FORMAT_RGF, "deux flottants 32 bits par texel")
	assert_eq(image.get_size(), Vector2i(IslandEdge.EDGE_SAMPLES, 1), "un texel par angle")
	var different := 0
	for i in table.size():
		if image.get_pixel(i, 0).r != table[i]:
			different += 1
	assert_eq(different, 0, "rayons de la texture = table du script")
	# Le calcul du shader (texelFetch, mix, pente), refait ici sur la texture : la même distance
	# que le script, sur tout le tour, en deçà comme au-delà du bord.
	var worst := 0.0
	var where := 0.0
	for k in 3600:
		var angle := TAU * k / 3600.0 - PI
		var edge := IslandTerrain.edge_point(angle)
		for offset: float in [-2.0, -0.5, 0.0, 0.5, 2.0, 6.0]:
			var p := edge - edge.normalized() * offset
			var gap := absf(_shader_edge_distance(image, p) - IslandTerrain.edge_distance(p.x, p.y))
			if gap > worst:
				worst = gap
				where = rad_to_deg(angle)
	assert_lt(worst, 0.001, "shader et script : même bord (écart %.5f m à %.1f°)" % [worst, where])


func test_shader_has_no_shape_of_its_own() -> void:
	var code := (load(TERRAIN_SHADER) as Shader).code
	assert_string_contains(code, "uniform sampler2D edge_table")
	var start := code.find("float edge_distance(vec2 p)")
	assert_gt(start, -1, "edge_distance() dans le shader")
	var body := code.substr(start, code.find("\n}\n", start) - start)
	assert_string_contains(body, "texelFetch(edge_table")
	for formula: String in ["sin(", "cos(", "exp(", "edge_radius", "bay_depth", "west_bulge"]:
		assert_false(body.contains(formula), "pas de formule propre au shader : %s" % formula)


func test_the_island_gives_the_table_to_the_ground_shader() -> void:
	var island := ISLAND.instantiate() as Node3D
	add_child_autofree(island)
	var material := IslandTerrain.MATERIAL
	assert_eq(
		material.get_shader_parameter(&"edge_table"),
		IslandEdge.texture(),
		"terrain.tres reçoit la table du bord en jeu"
	)


func test_the_coast_is_never_straight_except_at_the_quay() -> void:
	var points := _coast(0.5)
	var arc := _cumulative(points)
	var flattest := INF
	var where := 0.0
	var j := 0
	for i in points.size():
		while arc[j] - arc[i] < STRETCH:
			j += 1
		var middle := points[((i + j) >> 1) % points.size()]
		if _near_port(atan2(middle.y, middle.x)):
			continue
		var bend := 0.0
		for k in range(i + 1, j):
			var p := points[k % points.size()]
			var chord_a := points[i]
			var chord_b := points[j % points.size()]
			bend = maxf(
				bend, Geometry2D.get_closest_point_to_segment(p, chord_a, chord_b).distance_to(p)
			)
		if bend < flattest:
			flattest = bend
			where = rad_to_deg(atan2(middle.y, middle.x))
	assert_gt(
		flattest,
		MIN_BEND,
		(
			"le tronçon de %d m le plus droit s'écarte de %.2f m de sa corde (%.0f°)"
			% [STRETCH, flattest, where]
		)
	)


func test_the_quay_keeps_its_line() -> void:
	var sector := IslandEdge.PORT_SECTOR
	for k in 200:
		var angle := deg_to_rad(lerpf(sector.x, sector.y, k / 199.0))
		assert_almost_eq(
			IslandTerrain.edge_radius(angle),
			IslandEdge.base_radius(angle),
			0.001,
			"quai inchangé à %.1f°" % rad_to_deg(angle)
		)


func test_the_coast_only_moves_out_except_in_coves() -> void:
	var inward := 0.0
	var where := 0.0
	var deepest := 0.0
	for i in IslandEdge.EDGE_SAMPLES:
		var angle := TAU * i / IslandEdge.EDGE_SAMPLES
		var shift := IslandTerrain.edge_radius(angle) - IslandEdge.base_radius(angle)
		var cove := IslandEdge._angle_bumps(IslandEdge.COVES, angle)
		if cove < 0.05 and -shift > inward:
			inward = -shift
			where = rad_to_deg(angle)
		deepest = minf(deepest, shift)
		var edge := IslandTerrain.edge_point(angle)
		assert_lte(
			maxf(absf(edge.x), absf(edge.y)),
			IslandEdge.EDGE_LIMIT,
			"%.1f° : dans le carré des murs" % rad_to_deg(angle)
		)
	assert_lt(inward, 0.02, "hors des anses, jamais en deçà du tracé d'origine (%.0f°)" % where)
	assert_gt(deepest, -4.0, "anses de moins de 4 m")
	assert_lt(IslandEdge.EDGE_LIMIT, 79.5, "le bord reste à distance des murs (±80 m)")


func test_the_waterfall_falls_where_the_stream_ends() -> void:
	var stream := _shader_stream()
	assert_gt(stream.size(), 2, "tracé du ruisseau lu dans le shader")
	var mouth := Vector2.INF
	for k in stream.size() - 1:
		var a := stream[k]
		var b := stream[k + 1]
		if IslandTerrain.is_land(a.x, a.y) and not IslandTerrain.is_land(b.x, b.y):
			mouth = _crossing(a, b)
	assert_ne(mouth, Vector2.INF, "le lit du ruisseau arrive au bord")
	var fall := IslandTerrain.edge_point(IslandEdge.WATERFALL_ANGLE)
	assert_lt(
		mouth.distance_to(fall), 0.5, "la cascade tombe au bout du lit (%s, %s)" % [mouth, fall]
	)
	var vertices: PackedVector3Array = IslandRock.waterfall_mesh().surface_get_arrays(0)[
		Mesh.ARRAY_VERTEX
	]
	var top := (vertices[0] + vertices[1]) * 0.5
	assert_lt(Vector2(top.x, top.z).distance_to(fall), 1.0, "haut de la cascade sur la lèvre")
	var bottom := (vertices[vertices.size() - 1] + vertices[vertices.size() - 2]) * 0.5
	assert_false(IslandTerrain.is_land(bottom.x, bottom.z), "la cascade tombe dans le vide")
	assert_lt(bottom.y, -20.0, "jusque sous la falaise")


func test_the_rock_follows_the_edge_without_crossing() -> void:
	var loop := IslandTerrain.rim_loop()
	var rim := IslandTerrain.rim_segments()
	assert_eq(loop.size() * 2, rim.size(), "le bord du sol : une seule boucle")
	# Premier anneau : sous la lèvre, juste en retrait du bord du sol.
	for point: Vector3 in IslandRock._top_ring():
		var gap := IslandTerrain.distance_to_edge(point.x, point.z)
		assert_between(
			gap, -0.01, 0.3, "premier anneau en %s : %.2f m en deçà du bord" % [point, gap]
		)
	# Les anneaux, l'un sous l'autre sans se chevaucher, chacun étoilé (angles croissants).
	var previous_bottom := 0.0
	for r in range(1, IslandRock.RINGS.size()):
		var ring := IslandRock._ring(r)
		var top := -INF
		var bottom := INF
		var angles := IslandRock._unwrapped_angles(ring)
		for k in ring.size():
			top = maxf(top, ring[k].y)
			bottom = minf(bottom, ring[k].y)
			assert_gt(angles[k + 1], angles[k], "anneau %d : angles croissants" % r)
		assert_lt(top, previous_bottom, "anneau %d sous l'anneau %d" % [r, r - 1])
		previous_bottom = bottom


func test_rock_textures_have_no_seam_and_no_stretch() -> void:
	var turn := IslandRock.uv_turn()
	var length := IslandEdge.length()
	assert_almost_eq(
		fmod(turn, IslandRock.TEXTURE_METERS), 0.0, 0.0001, "un nombre entier de textures"
	)
	assert_lte(absf(turn - length), IslandRock.TEXTURE_METERS / 2.0, "tour plaqué ≈ périmètre")
	# Le long de la lèvre, un mètre de bord = un mètre de texture (à 10 % près ; mesuré : 4 %).
	var mesh := IslandRock.rock_mesh()
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var worst := 0.0
	var measured := 0
	for t in range(0, vertices.size(), 3):
		var top: Array[int] = []
		for k in 3:
			if vertices[t + k].y > -0.01:
				top.append(t + k)
		if top.size() != 2:
			continue
		var a := vertices[top[0]]
		var b := vertices[top[1]]
		var meters := Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))
		if meters < 0.3:
			continue
		measured += 1
		worst = maxf(worst, absf(absf(uvs[top[1]].x - uvs[top[0]].x) / meters - 1.0))
	assert_gt(measured, 500, "segments de la lèvre mesurés")
	assert_lt(worst, 0.1, "étirement des textures le long de la lèvre (%.0f %%)" % (worst * 100.0))


func test_one_draw_call_each_and_a_triangle_budget() -> void:
	var ground := IslandTerrain.terrain_mesh()
	var rock := IslandRock.rock_mesh()
	assert_eq(ground.get_surface_count(), 1, "sol : un draw call")
	assert_eq(rock.get_surface_count(), 1, "roche : un draw call")
	var ground_triangles := IslandTerrain.surface().indices.size() / 3.0
	var rock_triangles := rock.surface_get_array_len(0) / 3.0
	assert_lt(ground_triangles, MAX_GROUND_TRIANGLES, "sol : %.0f triangles" % ground_triangles)
	assert_lt(rock_triangles, MAX_ROCK_TRIANGLES, "roche : %.0f triangles" % rock_triangles)


# --- Outils ------------------------------------------------------------------------------------


## edge_distance() de terrain.gdshader, refait sur l'image de la texture (float 32 bits).
func _shader_edge_distance(image: Image, p: Vector2) -> float:
	var samples := image.get_width()
	var u := fposmod(atan2(p.y, p.x) / TAU, 1.0) * samples
	var i := mini(floori(u), samples - 1)
	var a := image.get_pixel(i, 0)
	var b := image.get_pixel((i + 1) % samples, 0)
	var f := u - floorf(u)
	var radius := lerpf(a.r, b.r, f)
	var slope := lerpf(a.g, b.g, f) / radius
	return (radius - p.length()) / sqrt(1.0 + slope * slope)


## Points du bord tous les step m environ (table rééchantillonnée), dans le sens du tour.
func _coast(step: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var count := ceili(IslandEdge.length() / step)
	var k := 0
	var length := IslandEdge.length()
	for i in IslandEdge.EDGE_SAMPLES * 4:
		var angle := -PI / 2.0 + TAU * i / (IslandEdge.EDGE_SAMPLES * 4.0)
		if IslandEdge.arc(angle) >= k * length / count:
			points.append(IslandTerrain.edge_point(angle))
			k += 1
	return points


## Longueurs cumulées le long des points, plus un tour complet (indices au-delà de la fin).
func _cumulative(points: PackedVector2Array) -> PackedFloat64Array:
	var arc := PackedFloat64Array([0.0])
	for i in points.size() * 2:
		var a := points[i % points.size()]
		var b := points[(i + 1) % points.size()]
		arc.append(arc[arc.size() - 1] + a.distance_to(b))
	return arc


func _near_port(angle: float) -> bool:
	var degrees := fposmod(rad_to_deg(angle), 360.0)
	var sector := IslandEdge.PORT_SECTOR
	var ramp := IslandEdge.PORT_RAMP
	return degrees > sector.x - ramp and degrees < sector.y + ramp


## Tracé du ruisseau (STREAM) lu dans terrain.gdshader.
func _shader_stream() -> PackedVector2Array:
	var code := (load(TERRAIN_SHADER) as Shader).code
	var start := code.find("const vec2 STREAM[STREAM_COUNT] = {")
	var block := code.substr(start, code.find("};", start) - start)
	var points := PackedVector2Array()
	var regex := RegEx.create_from_string("vec2\\(([-0-9.]+), ([-0-9.]+)\\)")
	for found: RegExMatch in regex.search_all(block):
		points.append(Vector2(float(found.get_string(1)), float(found.get_string(2))))
	return points


## Point du bord sur le segment a (sur l'île) → b (dans le vide), par dichotomie.
func _crossing(a: Vector2, b: Vector2) -> Vector2:
	var low := 0.0
	var high := 1.0
	for _step in 40:
		var middle := (low + high) * 0.5
		var p := a.lerp(b, middle)
		if IslandTerrain.is_land(p.x, p.y):
			low = middle
		else:
			high = middle
	return a.lerp(b, low)
