@tool
class_name IslandTerrain
extends StaticBody3D
## Sol de l'île flottante n° 68 : nœud « Ground » de island.tscn (couche 1). Propriétaire : L2,
## repris pour l'acte 1 (docs/lore/MONDE.md, sections 2.7 et 2.8).
##
## Le relief est une fonction de (x, z) en coordonnées de l'île (repères de PLAN.md section 3 :
## sol à y = 0, 160 × 160 m centrés sur l'origine, nord = −Z, ouest = −X). L'île est une dalle de
## pierre qui flotte au-dessus d'une mer de nuages : son bord (superellipse un peu ondulée,
## encoche du quai au sud, avancée du Couchant à l'ouest) est une lèvre nette au niveau du sol ;
## au-delà, le vide (height_at() y vaut VOID_HEIGHT).
##
## - surface praticable : grille de STEP m découpée sur la ligne exacte du bord (une case qui le
##   traverse est coupée au point où edge_distance() s'annule) ; un bloc plat de BLOCK × BLOCK
##   cases n'y fait que deux triangles. Les mêmes triangles font le mesh visible (un draw call,
##   couleurs au pixel par shaders/terrain.gdshader) et la collision (ConcavePolygonShape3D) :
##   on marche exactement sur ce qu'on voit, sans trou, et rien ne porte au-delà du bord ;
## - roche (IslandRock, enfant interne « Rock ») : lèvre, falaise et dessous de l'île, accrochés
##   au bord exact de la surface ;
## - relief : cercle de veille plat sur ARENA_FLAT_RADIUS m, dunes basses au-delà, colline à
##   l'est avec un plateau au sommet (belvédère), bosses douces dans les bois, butte au vent du
##   port ; il s'efface sur les RIM_FADE derniers mètres : la lèvre est partout à y = 0.
##   Pentes ≤ 40° (tests/unit/test_world_terrain.gd).
##
## La forme du bord est reprise telle quelle par shaders/terrain.gdshader (edge_distance) :
## garder edge_radius() identique dans les deux.

## Côté du carré de l'île (m) et nombre d'échantillons par côté ; un échantillon tous les STEP m.
const SIZE := 160.0
const HALF := SIZE / 2.0
const RESOLUTION := 129
const STEP := SIZE / (RESOLUTION - 1)
## Taille (en cases) des blocs du mesh ; un bloc plat entièrement sur l'île y fait deux triangles.
const BLOCK := 4

## Hauteur renvoyée hors de l'île : le vide, sous la KillZone (y < −10) et sous la roche.
const VOID_HEIGHT := -100.0

## Bord : rayon moyen de la superellipse (puissance 4), encoche du quai au sud, avancée du
## Couchant à l'ouest (même tracé que l'ancienne côte : les zones ne bougent pas).
const EDGE_RADIUS := 74.5
const BAY_DEPTH := 6.0
const WEST_BULGE := 2.5
## Le relief s'efface entre RIM_FADE et RIM_FLAT m du bord ; le dernier mètre est plat, à y = 0.
const RIM_FLAT := 1.0
const RIM_FADE := 8.0

## Cercle de veille (arène du Couchant) : centre (x, z) de l'île, rayon des bornes de l'arène,
## rayon plat et largeur de la rampe au-delà de laquelle les dunes s'élèvent.
const ARENA_CENTER := Vector2(-51.0, 0.0)
const ARENA_RADIUS := 12.0
const ARENA_FLAT_RADIUS := 15.0
const ARENA_RAMP := 5.0

## Colline des étoiles : centre (x, z), rayon au pied, rayon du plateau, hauteur du plateau.
const HILL_CENTER := Vector2(52.0, -3.0)
const HILL_RADIUS := 21.0
const HILL_TOP_RADIUS := 4.0
const HILL_HEIGHT := 8.0

## Cour de l'entrepôt (disque de terre battue et de vieilles dalles, peint par le shader du sol).
const PLAZA_RADIUS := 9.0

## Dunes basses du Couchant, au-delà de la rampe de l'arène : (x, z, rayon, hauteur), profil en
## cosinus (pente max h·π/2r). Les creux gardent au ras du sol les emplacements de l'acte 1
## (ruines, engrenages, drap, myosotis, déclencheur couchant_edge : HISTOIRE.md, section 3.3).
const DUNES: Array[Vector4] = [
	Vector4(-70.0, 12.0, 7.0, 3.0),
	Vector4(-60.0, 22.0, 8.0, 2.8),
	Vector4(-48.0, 27.5, 6.5, 2.2),
	Vector4(-35.0, 24.5, 6.0, 1.6),
	Vector4(-63.0, -27.0, 8.0, 2.6),
	Vector4(-46.0, -28.0, 7.0, 2.2),
	Vector4(-74.0, -25.0, 6.0, 2.0),
	Vector4(-34.0, -15.0, 5.0, 1.2),
	Vector4(-33.0, 14.0, 5.0, 1.0),
]
## Bosses douces des bois et du port (même format), loin des chemins et des emplacements.
const MOUNDS: Array[Vector4] = [
	Vector4(-48.0, -42.0, 8.0, 1.4),
	Vector4(28.0, -34.0, 6.0, 0.8),
	Vector4(40.0, -60.0, 9.0, 1.2),
	Vector4(-17.0, -71.0, 5.0, 0.7),
	Vector4(58.0, -34.0, 7.0, 0.9),
	Vector4(22.0, -66.0, 6.0, 0.8),
	Vector4(-31.0, 56.0, 6.5, 2.8),
	Vector4(-56.0, 44.0, 7.0, 0.8),
	Vector4(60.0, 40.0, 8.0, 0.9),
]

## Matériau du sol : couleurs au pixel (src/world/shaders/terrain.gdshader).
const MATERIAL := preload("res://src/world/materials/terrain.tres")
## (H5) Côté d'une tuile de l'atlas du sol (px) : ses mipmaps ne mélangent pas deux tuiles tant
## que le côté reste divisible (384 = 3 × 2^7 : niveaux 0 à 7).
const ATLAS_TILE := 384

## Surface (sommets, normales, triangles, bord), mesh et collision, calculés une fois : le relief
## ne dépend que des constantes.
static var _surface_cache: Surface = null
static var _mesh_cache: ArrayMesh = null
static var _shape_cache: ConcavePolygonShape3D = null
## (H5) Atlas du sol avec ses mipmaps, calculé une fois en jeu.
static var _atlas_cache: Texture2D = null

var _mesh_instance: MeshInstance3D
var _rock_instance: MeshInstance3D
var _collision: CollisionShape3D


## Surface praticable découpée au bord : sommets de la grille (ceux hors de l'île ne servent à
## aucun triangle), puis points de coupe sur la ligne du bord ; triangles dans le sens horaire vu
## du dessus (face avant vers le ciel) ; rim : segments du bord (p, q) par paires d'indices, la
## terre à droite de p → q vu du dessus.
class Surface:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	var rim := PackedInt32Array()
	## Distance au bord de chaque sommet de la grille (> 0 sur l'île).
	var edge := PackedFloat32Array()
	var _crossings: Dictionary[Vector2i, int] = {}

	## Ajoute le triangle (a, b, c) de la grille, découpé au bord s'il le traverse.
	func triangle(a: int, b: int, c: int) -> void:
		var in_a := edge[a] >= 0.0
		var in_b := edge[b] >= 0.0
		var in_c := edge[c] >= 0.0
		var inside := int(in_a) + int(in_b) + int(in_c)
		if inside == 3:
			indices.append_array(PackedInt32Array([a, b, c]))
		elif inside == 1:
			if in_b:
				_one_inside(b, c, a)
			elif in_c:
				_one_inside(c, a, b)
			else:
				_one_inside(a, b, c)
		elif inside == 2:
			if not in_a:
				_two_inside(b, c, a)
			elif not in_b:
				_two_inside(c, a, b)
			else:
				_two_inside(a, b, c)

	## a sur l'île, b et c dans le vide (ordre du triangle conservé).
	func _one_inside(a: int, b: int, c: int) -> void:
		var p := _crossing(a, b)
		var q := _crossing(c, a)
		indices.append_array(PackedInt32Array([a, p, q]))
		rim.append_array(PackedInt32Array([p, q]))

	## a et b sur l'île, c dans le vide.
	func _two_inside(a: int, b: int, c: int) -> void:
		var p := _crossing(b, c)
		var q := _crossing(c, a)
		indices.append_array(PackedInt32Array([a, b, p, a, p, q]))
		rim.append_array(PackedInt32Array([p, q]))

	## Point du bord sur l'arête (u, v) de la grille (l'un sur l'île, l'autre non), partagé par
	## les deux triangles de part et d'autre : fausse position sur edge_distance().
	func _crossing(u: int, v: int) -> int:
		var key := Vector2i(mini(u, v), maxi(u, v))
		if _crossings.has(key):
			return _crossings[key]
		var inner := u if edge[u] >= 0.0 else v
		var outer := v if inner == u else u
		var a := Vector2(vertices[inner].x, vertices[inner].z)
		var b := Vector2(vertices[outer].x, vertices[outer].z)
		var t0 := 0.0
		var e0 := edge[inner]
		var t1 := 1.0
		var e1 := edge[outer]
		var t := e0 / (e0 - e1)
		for _iteration in 5:
			var probe := a.lerp(b, t)
			var e := IslandTerrain.edge_distance(probe.x, probe.y)
			if absf(e) < 0.0002:
				break
			if e > 0.0:
				t0 = t
				e0 = e
			else:
				t1 = t
				e1 = e
			t = t0 + e0 / (e0 - e1) * (t1 - t0)
		var p := a.lerp(b, t)
		var index := vertices.size()
		vertices.append(Vector3(p.x, IslandTerrain.land_height(p.x, p.y), p.y))
		normals.append(Vector3.UP)
		_crossings[key] = index
		return index


func _ready() -> void:
	build()


## Construit le mesh visible, la roche et, en jeu, la forme de collision (enfants internes,
## jamais enregistrés dans la scène).
func build() -> void:
	if _mesh_instance == null:
		_mesh_instance = _internal_mesh(&"Mesh")
		_rock_instance = _internal_mesh(&"Rock")
	apply_shape_uniforms(MATERIAL)
	if not Engine.is_editor_hint():
		# En jeu seulement : dans l'éditeur, le matériau enregistré garderait la copie.
		MATERIAL.set_shader_parameter(
			&"ground_atlas", mipmapped_atlas(MATERIAL.get_shader_parameter(&"ground_atlas"))
		)
	_mesh_instance.mesh = terrain_mesh()
	_rock_instance.mesh = IslandRock.rock_mesh()
	if Engine.is_editor_hint() or _collision != null:
		return
	_collision = CollisionShape3D.new()
	_collision.name = &"CollisionShape3D"
	_collision.shape = collision_shape()
	add_child(_collision, false, Node.INTERNAL_MODE_FRONT)


func _internal_mesh(node_name: StringName) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance, false, Node.INTERNAL_MODE_FRONT)
	return instance


# --- Bord -------------------------------------------------------------------------------------


## Rayon du bord dans la direction angle = atan2(z, x) (sud = +π/2, ouest = π), en norme 4
## (superellipse). Formule reprise par terrain.gdshader.
static func edge_radius(angle: float) -> float:
	var radius := EDGE_RADIUS
	radius += 1.2 * sin(3.0 * angle + 0.4) + 0.8 * sin(5.0 * angle + 2.1)
	radius += 0.4 * sin(9.0 * angle + 0.7)
	var bay := angle_difference(angle, PI / 2.0) / 0.32
	var bulge := angle_difference(angle, PI) / 0.45
	return radius - BAY_DEPTH * exp(-bay * bay) + WEST_BULGE * exp(-bulge * bulge)


## Distance (m, approchée) du point au bord : > 0 sur l'île, < 0 dans le vide.
static func edge_distance(x: float, z: float) -> float:
	var x2 := x * x
	var z2 := z * z
	var norm := sqrt(sqrt(x2 * x2 + z2 * z2))
	return edge_radius(atan2(z, x)) - norm


## Point (x, z) du bord dans la direction angle = atan2(z, x).
static func edge_point(angle: float) -> Vector2:
	var direction := Vector2.from_angle(angle)
	var x2 := direction.x * direction.x
	var z2 := direction.y * direction.y
	return direction * edge_radius(angle) / sqrt(sqrt(x2 * x2 + z2 * z2))


## True si le point est sur l'île (en deçà du bord).
static func is_land(x: float, z: float) -> bool:
	return edge_distance(x, z) > 0.0


# --- Relief -----------------------------------------------------------------------------------


## Hauteur du sol au point (x, z) de l'île ; VOID_HEIGHT au-delà du bord.
static func height_at(x: float, z: float) -> float:
	if edge_distance(x, z) < 0.0:
		return VOID_HEIGHT
	return land_height(x, z)


## Hauteur du relief en (x, z), prolongée au-delà du bord (0) : sert aux normales et aux points
## de coupe du bord.
static func land_height(x: float, z: float) -> float:
	var fade := smoothstep(RIM_FLAT, RIM_FADE, edge_distance(x, z))
	if fade <= 0.0:
		return 0.0
	var relief := _bumps(x, z, MOUNDS)
	var arena := Vector2(x, z).distance_to(ARENA_CENTER)
	if arena > ARENA_FLAT_RADIUS:
		var flat := smoothstep(ARENA_FLAT_RADIUS, ARENA_FLAT_RADIUS + ARENA_RAMP, arena)
		relief += _bumps(x, z, DUNES) * flat
	var hill := Vector2(x, z).distance_to(HILL_CENTER)
	if hill < HILL_RADIUS:
		var t := clampf((HILL_RADIUS - hill) / (HILL_RADIUS - HILL_TOP_RADIUS), 0.0, 1.0)
		relief += HILL_HEIGHT * t * t * (3.0 - 2.0 * t)
	return relief * fade


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


# --- Grille, surface, mesh, collision -----------------------------------------------------------


## Hauteurs de la grille (RESOLUTION × RESOLUTION, ligne par ligne du nord au sud) :
## height_at() en chaque sommet (VOID_HEIGHT hors de l'île).
static func heights() -> PackedFloat32Array:
	var s := surface()
	var data := PackedFloat32Array()
	data.resize(RESOLUTION * RESOLUTION)
	for k in data.size():
		data[k] = s.vertices[k].y if s.edge[k] >= 0.0 else VOID_HEIGHT
	return data


## Surface praticable (calculée une fois).
static func surface() -> Surface:
	if _surface_cache != null:
		return _surface_cache
	var s := Surface.new()
	var count := RESOLUTION * RESOLUTION
	s.vertices.resize(count)
	s.normals.resize(count)
	s.edge.resize(count)
	var land := PackedFloat32Array()
	land.resize(count)
	for j in RESOLUTION:
		var z := -HALF + j * STEP
		for i in RESOLUTION:
			var x := -HALF + i * STEP
			var k := j * RESOLUTION + i
			s.edge[k] = edge_distance(x, z)
			land[k] = land_height(x, z)
			s.vertices[k] = Vector3(x, land[k], z)
	var last := RESOLUTION - 1
	for j in RESOLUTION:
		for i in RESOLUTION:
			var k := j * RESOLUTION + i
			var h := land[k]
			var west := land[k - 1] if i > 0 else h
			var east := land[k + 1] if i < last else h
			var north := land[k - RESOLUTION] if j > 0 else h
			var south := land[k + RESOLUTION] if j < last else h
			s.normals[k] = Vector3(west - east, 2.0 * STEP, north - south).normalized()
	# Blocs de BLOCK × BLOCK cases : un bloc plat entièrement sur l'île devient deux triangles ;
	# ses sommets de bord restent alignés, donc pas de fissure avec les blocs voisins détaillés.
	var blocks := floori(float(last) / BLOCK)
	for bj in blocks:
		for bi in blocks:
			var i0 := bi * BLOCK
			var j0 := bj * BLOCK
			if _block_is_flat(s, i0, j0):
				s.indices.append_array(_quad(j0 * RESOLUTION + i0, BLOCK, BLOCK * RESOLUTION))
				continue
			for j in range(j0, j0 + BLOCK):
				for i in range(i0, i0 + BLOCK):
					var k := j * RESOLUTION + i
					s.triangle(k, k + 1, k + RESOLUTION)
					s.triangle(k + 1, k + RESOLUTION + 1, k + RESOLUTION)
	_surface_cache = s
	return s


## Mesh du sol (une seule surface ; couleurs calculées par le shader du sol).
static func terrain_mesh() -> ArrayMesh:
	if _mesh_cache != null:
		return _mesh_cache
	var s := surface()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = s.vertices
	arrays[Mesh.ARRAY_NORMAL] = s.normals
	arrays[Mesh.ARRAY_INDEX] = s.indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, MATERIAL)
	_mesh_cache = mesh
	return mesh


## Collision du sol : les triangles mêmes du mesh visible (face avant vers le ciel).
static func collision_shape() -> ConcavePolygonShape3D:
	if _shape_cache != null:
		return _shape_cache
	var s := surface()
	var faces := PackedVector3Array()
	faces.resize(s.indices.size())
	for n in s.indices.size():
		faces[n] = s.vertices[s.indices[n]]
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	_shape_cache = shape
	return shape


## Segments du bord exact de la surface : paires de points (p, q), la terre à droite de p → q
## vu du dessus.
static func rim_segments() -> PackedVector3Array:
	var s := surface()
	var points := PackedVector3Array()
	points.resize(s.rim.size())
	for n in s.rim.size():
		points[n] = s.vertices[s.rim[n]]
	return points


## True si les (BLOCK + 1)² sommets du bloc de coin (i0, j0) sont sur l'île et à la même hauteur.
static func _block_is_flat(s: Surface, i0: int, j0: int) -> bool:
	var h := s.vertices[j0 * RESOLUTION + i0].y
	for j in range(j0, j0 + BLOCK + 1):
		for i in range(i0, i0 + BLOCK + 1):
			var k := j * RESOLUTION + i
			if s.edge[k] < 0.0 or absf(s.vertices[k].y - h) > 0.0001:
				return false
	return true


## Indices des deux triangles (sens horaire vu du dessus : face avant vers le ciel) du
## quadrilatère de coin k, de `across` sommets de large et `down` d'indice de profondeur.
static func _quad(k: int, across: int, down: int) -> PackedInt32Array:
	return PackedInt32Array([k, k + across, k + down, k + across, k + down + across, k + down])


## (H5) Atlas du sol avec ses mipmaps, pour que le sol se filtre au loin au lieu de scintiller
## (moiré) : les images importées n'en ont pas. Calculé une fois ; rend l'atlas tel quel si son
## image est illisible ou s'il a déjà des mipmaps.
static func mipmapped_atlas(atlas: Texture2D) -> Texture2D:
	if atlas == null or atlas == _atlas_cache:
		return atlas
	if _atlas_cache == null:
		var image := atlas.get_image()
		if image == null or image.is_empty() or image.has_mipmaps():
			return atlas
		_atlas_cache = ImageTexture.create_from_image(mipmapped_image(image))
	return _atlas_cache


## (H5) Copie de l'image (RGBA8) avec ses mipmaps : moyenne 2 × 2 par niveau, qui ne mélange
## jamais deux tuiles de ATLAS_TILE px jusqu'au niveau 7 (le shader du sol s'arrête avant).
static func mipmapped_image(source: Image) -> Image:
	var image := source.duplicate() as Image
	if image.is_compressed():
		image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	image.generate_mipmaps()
	return image


## Recopie les constantes de forme dans les uniformes d'un shader de l'île.
static func apply_shape_uniforms(material: ShaderMaterial) -> void:
	material.set_shader_parameter(&"edge_radius", EDGE_RADIUS)
	material.set_shader_parameter(&"bay_depth", BAY_DEPTH)
	material.set_shader_parameter(&"west_bulge", WEST_BULGE)
	material.set_shader_parameter(&"arena_center", ARENA_CENTER)
	material.set_shader_parameter(&"arena_radius", ARENA_RADIUS)
	material.set_shader_parameter(&"plaza_radius", PLAZA_RADIUS)
	material.set_shader_parameter(&"hill_center", HILL_CENTER)
	material.set_shader_parameter(&"hill_height", HILL_HEIGHT)
