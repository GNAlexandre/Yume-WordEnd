class_name IslandGrass
extends Node3D
## Herbe en touffes de l'île n° 68 (nœud « Grass » de island.tscn) : des milliers de petites
## touffes de brins, une MultiMeshInstance3D par case de CHUNK m (un draw call par case visible),
## sans collision ni ombre portée, qui se balancent au vent (shaders/grass.gdshader) et
## s'aplatissent au loin jusqu'au sol avant de disparaître (pas d'apparition brutale).
##
## Où pousse l'herbe : partout sur l'herbe de l'île, à pleine densité dans les prairies et sur la
## colline (herbe haute dorée), clairsemée sous les arbres des bois, sur le terrain
## d'entraînement piétiné et sur la pierre du Couchant ; jamais sur les chemins, la cour, le
## cercle de veille, la rue, la place, le quai, le marais, le ruisseau, le potager, l'aire de
## jeux, sous le porche, la descente de la salle des armes, le plateau du belvédère, ni sur la
## lèvre de pierre du bord. Les tracés (chemins, ruisseau, zones peintes) sont ceux de
## shaders/terrain.gdshader : garder les deux identiques.
##
## Les touffes sont tirées une fois (graine fixe) puis gardées pour tout le processus.

## Taille d'une case de MultiMesh (m), côté de la grille de densité (cases de 1 m).
const CHUNK := 16.0
const GRID := 160
## Touffes par m² à pleine densité.
const DENSITY := 2.2
## Les touffes s'aplatissent entre ces deux distances à la caméra (m), puis la case disparaît.
const FADE := Vector2(18.0, 27.0)

## Densités relatives : sous-bois, terrain d'entraînement, pierre du Couchant.
const FOREST_DENSITY := 0.12
const TRAMPLED_DENSITY := 0.35
const COUCHANT_DENSITY := 0.04

## Teintes des touffes (sRGB) : prairie, prairie sèche, sous-bois, colline dorée, herbe piétinée.
const MEADOW := Color(0.47, 0.58, 0.27)
const MEADOW_DRY := Color(0.64, 0.6, 0.33)
const FOREST := Color(0.36, 0.4, 0.22)
const GOLDEN := Color(0.72, 0.64, 0.36)
const TRAMPLED := Color(0.52, 0.56, 0.32)

## Chemins (x1, z1, x2, z2) et ruisseau : mêmes tracés que shaders/terrain.gdshader.
const PATHS: Array[Vector4] = [
	Vector4(0.0, -9.0, 0.0, -24.0),
	Vector4(0.0, -24.0, 1.5, -33.0),
	Vector4(1.5, -33.0, 0.0, -37.5),
	Vector4(1.0, -30.0, -8.0, -38.0),
	Vector4(-8.0, -38.0, -15.0, -46.0),
	Vector4(-15.0, -46.0, -19.0, -51.5),
	Vector4(-9.0, 0.0, -24.0, 0.0),
	Vector4(-24.0, 0.0, -31.0, 1.0),
	Vector4(-31.0, 1.0, -37.0, 0.0),
	Vector4(9.0, 0.0, 24.0, 0.0),
	Vector4(24.0, 0.0, 31.0, -1.5),
	Vector4(31.0, -1.5, 38.0, -10.0),
	Vector4(38.0, -10.0, 42.0, 4.0),
	Vector4(42.0, 4.0, 47.0, -8.0),
	Vector4(47.0, -8.0, 50.5, -4.0),
	Vector4(0.0, 9.0, 0.0, 24.0),
	Vector4(0.0, 24.0, 1.5, 33.0),
	Vector4(1.5, 33.0, 1.0, 43.5),
	Vector4(1.0, 46.5, 1.5, 55.0),
	Vector4(1.5, 55.0, 2.0, 60.0),
	Vector4(-34.0, 45.0, -40.0, 37.0),
	Vector4(-40.0, 37.0, -41.0, 26.0),
	Vector4(-41.0, 26.0, -46.0, 15.0),
	Vector4(34.0, 45.0, 40.0, 33.0),
	Vector4(40.0, 33.0, 44.0, 19.0),
]
const STREAM: Array[Vector2] = [
	Vector2(40.0, -22.0),
	Vector2(36.0, -30.0),
	Vector2(30.0, -38.0),
	Vector2(24.0, -46.0),
	Vector2(16.0, -64.0),
	Vector2(5.0, -70.0),
	Vector2(-8.0, -69.0),
	Vector2(-17.0, -64.0),
	Vector2(-24.0, -60.0),
	Vector2(-32.0, -56.0),
	Vector2(-42.0, -57.5),
	Vector2(-52.0, -60.0),
	Vector2(-62.5, -62.5),
]
## Disques sans herbe (x, z, rayon) : cercle de veille (combat lisible), cour, aire de jeux,
## place du marché, échoppe, plateau du belvédère, descente de la salle des armes.
const BARE_DISCS: Array[Vector3] = [
	Vector3(-51.0, 0.0, 15.0),
	Vector3(0.0, 0.0, 9.6),
	Vector3(-12.0, 11.0, 4.2),
	Vector3(-23.0, 50.0, 7.0),
	Vector3(-6.0, 54.0, 2.2),
	Vector3(52.0, -3.0, 4.8),
	Vector3(-16.0, -1.35, 2.0),
]
## Rectangles sans herbe (x min, z min, x max, z max) : potager, rue du Port, porche, quai.
const BARE_RECTS: Array[Rect2] = [
	Rect2(10.0, -6.0, 6.0, 4.0),
	Rect2(-34.6, 42.4, 69.2, 5.2),
	Rect2(-12.3, -11.2, 6.6, 3.0),
	Rect2(-33.6, 57.6, 67.2, 20.0),
]

const MATERIAL := preload("res://src/world/materials/grass.tres")

## Tampons des MultiMesh par case (calculés une fois) et mesh d'une touffe.
static var _buffers: Dictionary[Vector2i, PackedFloat32Array] = {}
static var _tuft: ArrayMesh = null


func _ready() -> void:
	build()


## Crée les MultiMeshInstance3D des cases (enfants internes, jamais enregistrés).
func build() -> void:
	if get_child_count(true) > 0:
		return
	var buffers := chunk_buffers()
	for key: Vector2i in buffers:
		var data := buffers[key]
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_colors = true
		multimesh.mesh = tuft_mesh()
		multimesh.instance_count = floori(data.size() / 16.0)
		multimesh.buffer = data
		var instance := MultiMeshInstance3D.new()
		instance.name = "Chunk_%d_%d" % [key.x, key.y]
		instance.multimesh = multimesh
		instance.material_override = MATERIAL
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		instance.visibility_range_end = FADE.y + CHUNK * 0.75
		add_child(instance, false, Node.INTERNAL_MODE_FRONT)


## Nombre total de touffes.
static func tuft_count() -> int:
	var total := 0
	for data: PackedFloat32Array in chunk_buffers().values():
		total += floori(data.size() / 16.0)
	return total


## Tampons des cases : par touffe, la transformation (3 lignes de 4) puis la teinte (RGBA).
static func chunk_buffers() -> Dictionary[Vector2i, PackedFloat32Array]:
	if not _buffers.is_empty():
		return _buffers
	var density := density_grid()
	var surface := IslandTerrain.surface()
	var rng := RandomNumberGenerator.new()
	rng.seed = 68
	var dry := FastNoiseLite.new()
	dry.seed = 68
	dry.frequency = 0.05
	var half := IslandTerrain.HALF
	var cells := roundi(CHUNK)
	var chunks := floori(GRID / CHUNK)
	for cz in chunks:
		for cx in chunks:
			var data := PackedFloat32Array()
			for j in range(cz * cells, (cz + 1) * cells):
				for i in range(cx * cells, (cx + 1) * cells):
					var d := density[j * GRID + i]
					if d <= 0.0:
						continue
					for n in floori(d * DENSITY + rng.randf()):
						var x := -half + i + rng.randf()
						var z := -half + j + rng.randf()
						if d < 1.0 and IslandTerrain.edge_distance(x, z) < 1.6:
							continue
						var y := _ground(surface, x, z)
						var tint := _tint(x, z, dry.get_noise_2d(x, z), rng)
						var height := rng.randf_range(0.75, 1.3) * (1.0 + 0.6 * _hill(x, z))
						var yaw := rng.randf() * TAU
						var width := rng.randf_range(0.85, 1.2)
						var c := cos(yaw) * width
						var s := sin(yaw) * width
						data.append_array(PackedFloat32Array([c, 0.0, s, x, 0.0, height, 0.0, y]))
						data.append_array(
							PackedFloat32Array([-s, 0.0, c, z, tint.r, tint.g, tint.b, 1])
						)
			if not data.is_empty():
				_buffers[Vector2i(cx, cz)] = data
	return _buffers


## Densité relative (0 à 1) de chaque case de 1 m de la grille (ligne par ligne du nord au sud).
static func density_grid() -> PackedFloat32Array:
	var grid := PackedFloat32Array()
	grid.resize(GRID * GRID)
	var half := IslandTerrain.HALF
	for j in GRID:
		for i in GRID:
			var x := -half + i + 0.5
			var z := -half + j + 0.5
			var edge := IslandTerrain.edge_distance(x, z)
			if edge < 1.6:
				continue
			var d := smoothstep(1.6, 2.6, edge)
			d *= lerpf(1.0, FOREST_DENSITY, 1.0 - smoothstep(-31.0, -25.0, z))
			var field := Vector2(x, z).distance_to(Vector2(0.0, -51.0))
			d *= lerpf(1.0, TRAMPLED_DENSITY, 1.0 - smoothstep(13.5, 15.5, field))
			d *= lerpf(1.0, COUCHANT_DENSITY, _couchant(x, z))
			var marsh := ((Vector2(x, z) - Vector2(-32.0, -56.0)) / Vector2(10.0, 8.0)).length()
			d *= smoothstep(0.9, 1.2, marsh)
			grid[j * GRID + i] = d
	for path: Vector4 in PATHS:
		_clear_segment(grid, Vector2(path.x, path.y), Vector2(path.z, path.w), 1.9, 0.7)
	for k in STREAM.size() - 1:
		_clear_segment(grid, STREAM[k], STREAM[k + 1], 1.5, 0.6)
	for disc: Vector3 in BARE_DISCS:
		_clear_segment(grid, Vector2(disc.x, disc.y), Vector2(disc.x, disc.y), disc.z, 0.6)
	for rect: Rect2 in BARE_RECTS:
		_clear_rect(grid, rect)
	return grid


## Mesh d'une touffe : sept brins (un triangle chacun) penchés autour du pied, 0,25 à 0,4 m de
## haut ; UV.y de 0 au pied à 1 à la pointe ; normales vers le ciel (éclairés comme le sol).
static func tuft_mesh() -> ArrayMesh:
	if _tuft != null:
		return _tuft
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	## (direction en radians, hauteur, écart du pied) de chaque brin.
	var blades: Array[Vector3] = [
		Vector3(0.0, 0.4, 0.05),
		Vector3(0.9, 0.3, 0.13),
		Vector3(1.8, 0.36, 0.08),
		Vector3(2.7, 0.27, 0.15),
		Vector3(3.6, 0.38, 0.1),
		Vector3(4.5, 0.29, 0.14),
		Vector3(5.4, 0.34, 0.07),
	]
	for blade: Vector3 in blades:
		var out := Vector3(cos(blade.x), 0.0, sin(blade.x))
		var side := Vector3(-out.z, 0.0, out.x) * 0.032
		var foot := out * blade.z
		var tip := foot + out * 0.12 + side * 1.5 + Vector3.UP * blade.y
		vertices.append_array(PackedVector3Array([foot - side, tip, foot + side]))
		uvs.append_array(
			PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.5, 1.0), Vector2(1.0, 0.0)])
		)
	var normals := PackedVector3Array()
	normals.resize(vertices.size())
	normals.fill(Vector3.UP)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	_tuft = ArrayMesh.new()
	_tuft.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return _tuft


## Hauteur du sol visible en (x, z) : triangles de la grille du terrain (même découpe).
static func _ground(surface: IslandTerrain.Surface, x: float, z: float) -> float:
	var res := IslandTerrain.RESOLUTION
	var fx := (x + IslandTerrain.HALF) / IslandTerrain.STEP
	var fz := (z + IslandTerrain.HALF) / IslandTerrain.STEP
	var i := clampi(floori(fx), 0, res - 2)
	var j := clampi(floori(fz), 0, res - 2)
	var u := fx - i
	var v := fz - j
	var k := j * res + i
	var h00 := surface.vertices[k].y
	var h10 := surface.vertices[k + 1].y
	var h01 := surface.vertices[k + res].y
	var h11 := surface.vertices[k + res + 1].y
	if u + v <= 1.0:
		return h00 + u * (h10 - h00) + v * (h01 - h00)
	return h11 + (1.0 - u) * (h01 - h11) + (1.0 - v) * (h10 - h11)


## Teinte d'une touffe : prairie plus ou moins sèche, sous-bois, colline dorée, herbe piétinée.
static func _tint(x: float, z: float, dry: float, rng: RandomNumberGenerator) -> Color:
	var tint := MEADOW.lerp(MEADOW_DRY, smoothstep(-0.1, 0.5, dry) * 0.6)
	tint = tint.lerp(FOREST, 1.0 - smoothstep(-31.0, -25.0, z))
	var field := Vector2(x, z).distance_to(Vector2(0.0, -51.0))
	tint = tint.lerp(TRAMPLED, 1.0 - smoothstep(13.5, 15.5, field))
	tint = tint.lerp(GOLDEN, _hill(x, z) * 0.85)
	tint = tint.lerp(MEADOW_DRY, _couchant(x, z))
	return tint * rng.randf_range(0.9, 1.1)


## 1 sur la colline des étoiles, 0 au-delà de son pied.
static func _hill(x: float, z: float) -> float:
	var hill := Vector2(x, z).distance_to(IslandTerrain.HILL_CENTER)
	return 1.0 - smoothstep(19.0, 23.0, hill)


## 1 sur la pierre et le sable du Couchant (même contour lobé que le shader du sol).
static func _couchant(x: float, z: float) -> float:
	var q := (Vector2(x, z) - IslandTerrain.ARENA_CENTER) / Vector2(1.0, 1.2)
	if q.length() > 33.0:
		return 0.0
	var lobe := q.angle()
	var shape := q.length() + 2.5 * sin(lobe * 3.0 + 0.7) + 1.5 * sin(lobe * 5.0 + 2.0)
	return 1.0 - smoothstep(25.0, 28.5, shape)


## Retire l'herbe à moins de half_width (m) du segment ab, en fondu sur ramp m au-delà.
static func _clear_segment(
	grid: PackedFloat32Array, a: Vector2, b: Vector2, half_width: float, ramp: float
) -> void:
	var reach := half_width + ramp
	var half := IslandTerrain.HALF
	var i0 := clampi(floori(minf(a.x, b.x) - reach + half), 0, GRID - 1)
	var i1 := clampi(floori(maxf(a.x, b.x) + reach + half), 0, GRID - 1)
	var j0 := clampi(floori(minf(a.y, b.y) - reach + half), 0, GRID - 1)
	var j1 := clampi(floori(maxf(a.y, b.y) + reach + half), 0, GRID - 1)
	for j in range(j0, j1 + 1):
		for i in range(i0, i1 + 1):
			var p := Vector2(-half + i + 0.5, -half + j + 0.5)
			var nearest := Geometry2D.get_closest_point_to_segment(p, a, b)
			var keep := smoothstep(half_width, reach, p.distance_to(nearest))
			grid[j * GRID + i] *= keep


## Retire l'herbe dans le rectangle (sans fondu).
static func _clear_rect(grid: PackedFloat32Array, rect: Rect2) -> void:
	var half := IslandTerrain.HALF
	var i0 := clampi(floori(rect.position.x + half), 0, GRID - 1)
	var i1 := clampi(floori(rect.end.x + half), 0, GRID - 1)
	var j0 := clampi(floori(rect.position.y + half), 0, GRID - 1)
	var j1 := clampi(floori(rect.end.y + half), 0, GRID - 1)
	for j in range(j0, j1 + 1):
		for i in range(i0, i1 + 1):
			grid[j * GRID + i] = 0.0
