@tool
class_name IslandTerrain
extends StaticBody3D
## Sol de l'île : nœud « Ground » de island.tscn (couche 1). Propriétaire : L2.
##
## Le relief est une fonction de (x, z) en coordonnées de l'île (repères de PLAN.md section 3 :
## sol à y = 0, 160 × 160 m centrés sur l'origine, nord = −Z, ouest = −X).
## Un seul mesh (un draw call ; couleurs au pixel par src/world/shaders/terrain.gdshader) et une
## HeightMapShape3D tirés de la même grille : on marche exactement sur ce qu'on voit, sans trou.
## Pentes ≤ 45° partout.
##
## - côte en carré arrondi (superellipse) un peu ondulée, baie au sud (plage), avancée à
##   l'ouest (dunes) ; plage en pente douce jusqu'à l'eau, puis haut-fond jusqu'aux murs ;
## - dunes en cuvette autour de l'arène (plate sur ARENA_FLAT_RADIUS m), ouverte vers le village ;
## - colline à l'est avec un plateau au sommet (belvédère), quelques bosses douces ailleurs ;
## - chemins de terre du village vers chaque zone, place pavée, sable, sous-bois.
##
## La forme de la côte est reprise telle quelle par les shaders du sol et de l'eau : garder
## coast_radius() identique dans terrain.gdshader et water.gdshader.

## Côté de l'île (m) et nombre d'échantillons par côté (2^7 + 1 : HeightMapShape3D native de
## Jolt) ; un échantillon tous les STEP m.
const SIZE := 160.0
const HALF := SIZE / 2.0
const RESOLUTION := 129
const STEP := SIZE / (RESOLUTION - 1)
## Taille (en cases) des blocs du mesh visible ; un bloc plat n'y fait que deux triangles.
const BLOCK := 4

## Niveau de l'eau, fond du haut-fond, largeur de la plage et du talus sous l'eau (m).
const WATER_LEVEL := -0.6
const SEA_FLOOR := -1.3
const BEACH_WIDTH := 8.0
const SHELF_WIDTH := 6.0

## Côte : rayon moyen de la superellipse (puissance 4), baie au sud, avancée à l'ouest.
const COAST_RADIUS := 74.5
const BAY_DEPTH := 6.0
const WEST_BULGE := 2.5

## Arène des dunes : centre (x, z) de l'île, rayon de l'arène, rayon plat et largeur de la
## rampe au-delà de laquelle les dunes s'élèvent.
const ARENA_CENTER := Vector2(-51.0, 0.0)
const ARENA_RADIUS := 12.0
const ARENA_FLAT_RADIUS := 15.0
const ARENA_RAMP := 5.0

## Colline : centre (x, z), rayon au pied, rayon du plateau, hauteur du plateau.
const HILL_CENTER := Vector2(52.0, -3.0)
const HILL_RADIUS := 21.0
const HILL_TOP_RADIUS := 4.0
const HILL_HEIGHT := 8.0

## Place du village (disque pavé, dessiné par le shader du sol).
const PLAZA_RADIUS := 9.0

## Dunes et petites bosses : (x, z, rayon, hauteur), profil en cosinus (pente max h·π/2r).
const DUNES: Array[Vector4] = [
	Vector4(-70.0, -13.0, 8.0, 2.4),
	Vector4(-70.5, 10.0, 7.5, 2.0),
	Vector4(-60.0, -23.0, 10.0, 3.4),
	Vector4(-45.0, -24.0, 8.5, 2.6),
	Vector4(-59.0, 23.0, 10.0, 3.2),
	Vector4(-44.0, 23.5, 8.0, 2.4),
	Vector4(-72.0, -27.0, 7.0, 2.4),
	Vector4(-72.0, 26.0, 7.0, 2.2),
	Vector4(-33.0, -15.0, 5.0, 1.2),
	Vector4(-33.0, 15.0, 5.0, 1.0),
]
const MOUNDS: Array[Vector4] = [
	Vector4(-24.0, -58.0, 8.0, 1.0),
	Vector4(22.0, -42.0, 7.0, 0.8),
	Vector4(40.0, -60.0, 9.0, 1.2),
	Vector4(-12.0, -68.0, 6.0, 0.7),
	Vector4(58.0, -34.0, 7.0, 0.9),
	Vector4(30.0, 38.0, 8.0, 0.6),
	Vector4(-28.0, 40.0, 7.0, 0.7),
	Vector4(-56.0, 44.0, 7.0, 0.8),
	Vector4(60.0, 40.0, 8.0, 0.9),
]

## Matériau du sol : couleurs au pixel (src/world/shaders/terrain.gdshader).
const MATERIAL := preload("res://src/world/materials/terrain.tres")

## Grille des hauteurs et mesh, calculés une fois (le relief ne dépend que des constantes).
static var _heights_cache: PackedFloat32Array = PackedFloat32Array()
static var _mesh_cache: ArrayMesh = null

var _mesh_instance: MeshInstance3D
var _collision: CollisionShape3D


func _ready() -> void:
	build()


## Construit le mesh visible et, en jeu, la forme de collision (enfants internes, jamais
## enregistrés dans la scène).
func build() -> void:
	if _mesh_instance == null:
		_mesh_instance = MeshInstance3D.new()
		_mesh_instance.name = &"Mesh"
		_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_mesh_instance, false, Node.INTERNAL_MODE_FRONT)
	apply_shape_uniforms(MATERIAL)
	_mesh_instance.mesh = terrain_mesh()
	if Engine.is_editor_hint() or _collision != null:
		return
	var shape := HeightMapShape3D.new()
	shape.map_width = RESOLUTION
	shape.map_depth = RESOLUTION
	shape.map_data = heights()
	_collision = CollisionShape3D.new()
	_collision.name = &"CollisionShape3D"
	_collision.shape = shape
	_collision.scale = Vector3(STEP, 1.0, STEP)
	add_child(_collision, false, Node.INTERNAL_MODE_FRONT)


# --- Relief -----------------------------------------------------------------------------------


## Hauteur du sol au point (x, z) de l'île.
static func height_at(x: float, z: float) -> float:
	return _height(x, z, coast_distance(x, z))


## Distance (m, approchée) du point à la ligne d'eau : > 0 sur l'île, < 0 en mer.
static func coast_distance(x: float, z: float) -> float:
	var x2 := x * x
	var z2 := z * z
	var norm := sqrt(sqrt(x2 * x2 + z2 * z2))
	return coast_radius(atan2(z, x)) - norm


## Rayon de la côte dans la direction angle = atan2(z, x) (sud = +π/2, ouest = π).
## Formule reprise par terrain.gdshader et water.gdshader.
static func coast_radius(angle: float) -> float:
	var radius := COAST_RADIUS
	radius += 1.2 * sin(3.0 * angle + 0.4) + 0.8 * sin(5.0 * angle + 2.1)
	radius += 0.4 * sin(9.0 * angle + 0.7)
	var bay := angle_difference(angle, PI / 2.0) / 0.32
	var bulge := angle_difference(angle, PI) / 0.45
	return radius - BAY_DEPTH * exp(-bay * bay) + WEST_BULGE * exp(-bulge * bulge)


## True si le point est sur la terre ferme (au-dessus de l'eau).
static func is_land(x: float, z: float) -> bool:
	return coast_distance(x, z) > 0.0


## Normale du sol (différences finies), pour mesurer les pentes.
static func normal_at(x: float, z: float) -> Vector3:
	var e := 0.25
	var dx := height_at(x + e, z) - height_at(x - e, z)
	var dz := height_at(x, z + e) - height_at(x, z - e)
	return Vector3(-dx, 2.0 * e, -dz).normalized()


static func _height(x: float, z: float, coast: float) -> float:
	var h := 0.0
	if coast >= 0.0:
		h = WATER_LEVEL * (1.0 - smoothstep(0.0, BEACH_WIDTH, coast))
	else:
		h = WATER_LEVEL + (SEA_FLOOR - WATER_LEVEL) * smoothstep(0.0, SHELF_WIDTH, -coast)
	var land := smoothstep(1.0, 8.0, coast)
	if land <= 0.0:
		return h
	var relief := _bumps(x, z, MOUNDS)
	var arena := Vector2(x, z).distance_to(ARENA_CENTER)
	if arena > ARENA_FLAT_RADIUS:
		var flat := smoothstep(ARENA_FLAT_RADIUS, ARENA_FLAT_RADIUS + ARENA_RAMP, arena)
		relief += _bumps(x, z, DUNES) * flat
	var hill := Vector2(x, z).distance_to(HILL_CENTER)
	if hill < HILL_RADIUS:
		var t := clampf((HILL_RADIUS - hill) / (HILL_RADIUS - HILL_TOP_RADIUS), 0.0, 1.0)
		relief += HILL_HEIGHT * t * t * (3.0 - 2.0 * t)
	return h + relief * land


## Somme de bosses en cosinus (x, z, rayon, hauteur).
static func _bumps(x: float, z: float, bumps: Array[Vector4]) -> float:
	var h := 0.0
	for bump: Vector4 in bumps:
		var dx := x - bump.x
		var dz := z - bump.y
		var d2 := dx * dx + dz * dz
		if d2 < bump.z * bump.z:
			h += bump.w * (0.5 + 0.5 * cos(PI * sqrt(d2) / bump.z))
	return h


# --- Grille, mesh -----------------------------------------------------------------------------


## Hauteurs de la grille (RESOLUTION × RESOLUTION, ligne par ligne du nord au sud), dans le
## format de HeightMapShape3D.map_data.
static func heights() -> PackedFloat32Array:
	if _heights_cache.is_empty():
		var data := PackedFloat32Array()
		data.resize(RESOLUTION * RESOLUTION)
		for j in RESOLUTION:
			var z := -HALF + j * STEP
			for i in RESOLUTION:
				data[j * RESOLUTION + i] = height_at(-HALF + i * STEP, z)
		_heights_cache = data
	return _heights_cache


## Mesh du sol (une seule surface ; couleurs calculées par le shader du sol).
static func terrain_mesh() -> ArrayMesh:
	if _mesh_cache != null:
		return _mesh_cache
	var data := heights()
	var count := RESOLUTION * RESOLUTION
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	vertices.resize(count)
	normals.resize(count)
	var last := RESOLUTION - 1
	for j in RESOLUTION:
		var z := -HALF + j * STEP
		for i in RESOLUTION:
			var k := j * RESOLUTION + i
			var x := -HALF + i * STEP
			var h := data[k]
			vertices[k] = Vector3(x, h, z)
			var west := data[k - 1] if i > 0 else h
			var east := data[k + 1] if i < last else h
			var north := data[k - RESOLUTION] if j > 0 else h
			var south := data[k + RESOLUTION] if j < last else h
			normals[k] = Vector3(west - east, 2.0 * STEP, north - south).normalized()
	# Blocs de BLOCK × BLOCK cases : un bloc parfaitement plat (village, sous-bois, fond marin)
	# devient deux triangles ; ses sommets de bord restent alignés, donc pas de fissure avec
	# les blocs voisins détaillés. La collision garde la grille complète.
	var indices := PackedInt32Array()
	var blocks := floori(float(last) / BLOCK)
	for bj in blocks:
		for bi in blocks:
			var i0 := bi * BLOCK
			var j0 := bj * BLOCK
			if _block_is_flat(data, i0, j0):
				indices.append_array(_quad(j0 * RESOLUTION + i0, BLOCK, BLOCK * RESOLUTION))
				continue
			for j in range(j0, j0 + BLOCK):
				for i in range(i0, i0 + BLOCK):
					indices.append_array(_quad(j * RESOLUTION + i, 1, RESOLUTION))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, MATERIAL)
	_mesh_cache = mesh
	return mesh


## True si les (BLOCK + 1)² hauteurs du bloc de coin (i0, j0) sont égales (bloc plat).
static func _block_is_flat(data: PackedFloat32Array, i0: int, j0: int) -> bool:
	var h := data[j0 * RESOLUTION + i0]
	for j in range(j0, j0 + BLOCK + 1):
		for i in range(i0, i0 + BLOCK + 1):
			if absf(data[j * RESOLUTION + i] - h) > 0.0001:
				return false
	return true


## Indices des deux triangles (sens horaire vu du dessus : face avant vers le ciel) du
## quadrilatère de coin k, de `across` sommets de large et `down` d'indice de profondeur.
static func _quad(k: int, across: int, down: int) -> PackedInt32Array:
	return PackedInt32Array([k, k + across, k + down, k + across, k + down + across, k + down])


## Recopie les constantes de forme dans les uniformes d'un shader de l'île (sol, eau).
static func apply_shape_uniforms(material: ShaderMaterial) -> void:
	material.set_shader_parameter(&"coast_radius", COAST_RADIUS)
	material.set_shader_parameter(&"bay_depth", BAY_DEPTH)
	material.set_shader_parameter(&"west_bulge", WEST_BULGE)
	material.set_shader_parameter(&"water_level", WATER_LEVEL)
	material.set_shader_parameter(&"sea_floor", SEA_FLOOR)
	material.set_shader_parameter(&"arena_center", ARENA_CENTER)
	material.set_shader_parameter(&"arena_radius", ARENA_RADIUS)
	material.set_shader_parameter(&"plaza_radius", PLAZA_RADIUS)
	material.set_shader_parameter(&"hill_height", HILL_HEIGHT)
