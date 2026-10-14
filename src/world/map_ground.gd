@tool
class_name MapGround
extends StaticBody3D
## Sol en relief d'une carte extérieure (lot E2) : le nœud « Ground » d'une carte (Map,
## docs/REFONTE.md section 7.1), couche 1 (world). Format des données et mode d'emploi : PLAN.md,
## « Format du sol des cartes extérieures ».
##
## Au chargement, il lit data/maps/<map_id>/ (MapGroundData : map.json, heights.png,
## materials.png, structures.png) et construit (MapGroundBuilder), en enfants internes jamais
## enregistrés dans la scène :
## - Mesh : le sol, un draw call (shaders/map_ground.gdshader : tuiles de l'atlas du sol de l'île,
##   bords tramés, bordures, eau, lèvre de pierre au bord du vide, ombres des falaises) ;
## - Cliffs : les faces verticales (falaises, talus, murets, contremarches) et le rideau de roche
##   sous la côte, un draw call (shaders/map_ground_cliff.gdshader) ;
## - CloudSea : la mer de nuages de l'île (shaders/cloud_sea.gdshader), si la carte touche le vide ;
## - CollisionShape3D : les triangles mêmes du sol et des faces (on marche exactement sur ce qu'on
##   voit) ; Barrier : un mur invisible le long de la côte et des bords « land » de la carte.
##
## Requêtes (coordonnées de la carte : origine au coin nord-ouest, x vers l'est, z vers le sud ;
## la carte est à l'origine du monde) : height_at(), material_at(), is_walkable(), level_at(),
## triangles_in() (décalques au sol), map_size(). Mesures : stats().

const VOID_HEIGHT := MapGroundData.VOID_HEIGHT
const GROUND_SHADER := preload("res://src/world/shaders/map_ground.gdshader")
const CLIFF_SHADER := preload("res://src/world/shaders/map_ground_cliff.gdshader")
const CLOUD_SHADER := preload("res://src/world/shaders/cloud_sea.gdshader")
const ATLAS := preload("res://assets/hd2d/ground/atlas/ground_atlas.png")
const LIP_IMAGE := preload("res://assets/hd2d/cliff/lip.png")
const CLIFF_IMAGE := preload("res://assets/hd2d/cliff/cliff.png")
const UNDERSIDE_IMAGE := preload("res://assets/hd2d/cliff/underside.png")
const BANK_IMAGE := preload("res://assets/hd2d/cliff/bank_earth.png")
const WALL_IMAGE := preload("res://assets/hd2d/buildings/materials/wall_stone_b.png")
const CLOUD_IMAGE := preload("res://assets/hd2d/sky/cloud_sea.png")
## Mer de nuages : profondeur sous le sol (m) et côté (m), comme le nœud Water de l'île.
const CLOUD_SEA_DEPTH := -60.0
const CLOUD_SEA_SIZE := 3000.0
## Soleil par défaut (vers lui) : celui de l'île (island.tscn, Sun).
const DEFAULT_TOWARD_SUN := Vector3(-0.900073, 0.34202, 0.269984)

## Matériau partagé des faces (mêmes images pour toutes les cartes), en référence faible : une
## carte quittée le libère (règle des caches statiques des cartes, PLAN.md, « (E1) Créer une
## carte »).
static var _cliff_material: WeakRef = null

## Carte dont lire les données ; vide : le nom du nœud parent (la Map, nommée comme son map_id).
@export var map_id: StringName = &""
## Dossier des cartes (les tests en lisent d'autres).
@export var data_root: String = MapGroundData.DATA_ROOT

## Données lues (null avant build()).
var data: MapGroundData = null
## Durée de la dernière construction (ms) : lecture, triangles, meshes, collision.
var build_msec: float = 0.0

var _builder: MapGroundBuilder = null
var _mesh: MeshInstance3D = null
var _cliffs: MeshInstance3D = null
var _clouds: MeshInstance3D = null
var _shape: CollisionShape3D = null
var _barrier: CollisionShape3D = null
var _ground_material: ShaderMaterial = null


func _ready() -> void:
	# Déjà construit si un décalque de la carte l'a demandé avant (triangles_in).
	if _builder == null:
		build()
	if not Engine.is_editor_hint():
		_follow_sun.call_deferred()


## Lit les données et construit le sol, ses faces, la mer de nuages et la collision.
func build() -> void:
	var start := Time.get_ticks_usec()
	var id := map_id
	if id == &"" and get_parent() != null:
		id = StringName(get_parent().name)
	var loaded := MapGroundData.load_map(id, data_root)
	if not loaded.problems.is_empty():
		push_error("MapGround %s : %s" % [id, "; ".join(loaded.problems)])
	build_from(loaded, start)


## Construit le sol de données déjà lues (start : début de la mesure, Time.get_ticks_usec()).
func build_from(source: MapGroundData, start: int = -1) -> void:
	if start < 0:
		start = Time.get_ticks_usec()
	data = source
	if data.width <= 0 or data.depth <= 0:
		return
	_builder = MapGroundBuilder.new()
	_builder.build(data)
	if _mesh == null:
		_mesh = _internal_mesh(&"Mesh")
		_cliffs = _internal_mesh(&"Cliffs")
	_ground_material = _make_ground_material()
	_mesh.mesh = _builder.ground_mesh(_ground_material)
	_cliffs.mesh = _builder.cliff_mesh(cliff_material())
	_build_clouds()
	if not Engine.is_editor_hint():
		_build_collision()
	build_msec = (Time.get_ticks_usec() - start) / 1000.0


func _internal_mesh(node_name: StringName) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance, false, Node.INTERNAL_MODE_FRONT)
	return instance


func _build_collision() -> void:
	if _shape == null:
		_shape = CollisionShape3D.new()
		_shape.name = &"CollisionShape3D"
		add_child(_shape, false, Node.INTERNAL_MODE_FRONT)
		_barrier = CollisionShape3D.new()
		_barrier.name = &"Barrier"
		add_child(_barrier, false, Node.INTERNAL_MODE_FRONT)
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(_builder.collision_faces())
	_shape.shape = shape
	_barrier.shape = null
	if not _builder.barrier.is_empty():
		var wall := ConcavePolygonShape3D.new()
		wall.backface_collision = true
		wall.set_faces(_builder.barrier)
		_barrier.shape = wall


func _build_clouds() -> void:
	if not data.has_void():
		if _clouds != null:
			_clouds.visible = false
		return
	if _clouds == null:
		_clouds = _internal_mesh(&"CloudSea")
		var plane := PlaneMesh.new()
		plane.size = Vector2(CLOUD_SEA_SIZE, CLOUD_SEA_SIZE)
		var material := ShaderMaterial.new()
		material.shader = CLOUD_SHADER
		material.set_shader_parameter(&"clouds", CLOUD_IMAGE)
		plane.material = material
		_clouds.mesh = plane
	_clouds.visible = true
	_clouds.position = Vector3(data.width * 0.5, CLOUD_SEA_DEPTH, data.depth * 0.5)


## Matériau du sol de cette carte : atlas du sol et images de données (matières, table, paliers).
func _make_ground_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = GROUND_SHADER
	var atlas: Texture2D = ATLAS
	if not Engine.is_editor_hint():
		atlas = IslandTerrain.mipmapped_atlas(ATLAS)
	material.set_shader_parameter(&"ground_atlas", atlas)
	material.set_shader_parameter(&"material_map", ImageTexture.create_from_image(material_image()))
	material.set_shader_parameter(&"material_table", ImageTexture.create_from_image(table_image()))
	material.set_shader_parameter(&"height_map", ImageTexture.create_from_image(height_image()))
	material.set_shader_parameter(&"materials_scale", float(data.materials_scale))
	material.set_shader_parameter(&"level_height", MapGroundData.LEVEL_HEIGHT)
	material.set_shader_parameter(&"toward_sun", DEFAULT_TOWARD_SUN)
	return material


## Matériau partagé des faces et du rideau (gardé tant qu'une carte s'en sert).
static func cliff_material() -> ShaderMaterial:
	var material: ShaderMaterial = null
	if _cliff_material != null:
		material = _cliff_material.get_ref() as ShaderMaterial
	if material == null:
		material = ShaderMaterial.new()
		material.shader = CLIFF_SHADER
		var atlas: Texture2D = ATLAS
		if not Engine.is_editor_hint():
			atlas = IslandTerrain.mipmapped_atlas(ATLAS)
		material.set_shader_parameter(&"ground_atlas", atlas)
		material.set_shader_parameter(&"lip_texture", LIP_IMAGE)
		material.set_shader_parameter(&"cliff_texture", CLIFF_IMAGE)
		material.set_shader_parameter(&"underside_texture", UNDERSIDE_IMAGE)
		material.set_shader_parameter(&"bank_texture", BANK_IMAGE)
		material.set_shader_parameter(&"wall_texture", WALL_IMAGE)
		_cliff_material = weakref(material)
	return material


## Image des matières pour le shader (R8 : indice de matière par pixel de materials.png).
func material_image() -> Image:
	var size := Vector2i(data.width, data.depth) * data.materials_scale
	return Image.create_from_data(size.x, size.y, false, Image.FORMAT_R8, data.pixel_materials)


## Table des matières pour le shader (RGBA8, une colonne par matière) : rangée 0 (tuile, drapeaux,
## tuile de bordure, largeur de bordure en cm), 1 (teinte / 2), 2 (teinte de bordure / 2).
func table_image() -> Image:
	var count := maxi(data.material_specs.size(), 1)
	var image := Image.create_empty(count, 3, false, Image.FORMAT_RGBA8)
	for index in data.material_specs.size():
		var spec := data.material_specs[index]
		var flags := (
			int(spec["variant"])
			| int(spec["sharp"]) << 1
			| int(spec["ripple"]) << 2
			| int(int(spec["border_layer"]) >= 0) << 3
		)
		var border := maxi(int(spec["border_layer"]), 0)
		var width := clampi(roundi(float(spec["border_width"]) * 100.0), 0, 255)
		image.set_pixel(index, 0, Color8(int(spec["layer"]), flags, border, width))
		var tint: Color = spec["tint"]
		var border_tint: Color = spec["border_tint"]
		image.set_pixel(index, 1, Color(tint.r * 0.5, tint.g * 0.5, tint.b * 0.5))
		image.set_pixel(
			index, 2, Color(border_tint.r * 0.5, border_tint.g * 0.5, border_tint.b * 0.5)
		)
	return image


## Paliers pour le shader (R8 par case : 0 le vide, 255 escalier ou rampe, sinon palier + 64).
func height_image() -> Image:
	var bytes := PackedByteArray()
	bytes.resize(data.width * data.depth)
	for c in bytes.size():
		var level := data.levels[c]
		if level == MapGroundData.VOID_LEVEL:
			bytes[c] = 0
		elif data.kinds[c] != MapGroundData.Kind.FLAT:
			bytes[c] = 255
		else:
			bytes[c] = clampi(level + 64, 1, 254)
	return Image.create_from_data(data.width, data.depth, false, Image.FORMAT_R8, bytes)


## Le soleil de la scène (première DirectionalLight3D) donne la direction des ombres des falaises
## et le côté chaud de la mer de nuages.
func _follow_sun() -> void:
	if not is_inside_tree():
		return
	var lights := get_tree().root.find_children("*", "DirectionalLight3D", true, false)
	if lights.is_empty():
		return
	set_sun((lights[0] as Node3D).global_basis.z)


## Direction du soleil (vers lui) : ombres portées des falaises, côté chaud des nuages.
func set_sun(toward_sun: Vector3) -> void:
	if _ground_material != null:
		_ground_material.set_shader_parameter(&"toward_sun", toward_sun.normalized())
	if _clouds != null and _clouds.mesh != null:
		var clouds := (_clouds.mesh as PlaneMesh).material as ShaderMaterial
		var flat := Vector2(toward_sun.x, toward_sun.z)
		if clouds != null and flat.length_squared() > 0.0001:
			clouds.set_shader_parameter(&"sun_direction", flat.normalized())


# --- Requêtes -----------------------------------------------------------------------------------


## Hauteur du sol en (x, z), telle qu'on la voit et qu'on y marche ; VOID_HEIGHT dans le vide.
func height_at(x: float, z: float) -> float:
	return VOID_HEIGHT if data == null else data.surface_height(x, z)


## Matière peinte en (x, z) (&"herbe", &"sentier"…) ; &"" dans le vide.
func material_at(x: float, z: float) -> StringName:
	if data == null or height_at(x, z) == VOID_HEIGHT:
		return &""
	return data.material_name(data.material_index_at(x, z))


## Vrai si l'on peut se tenir en (x, z) : dans la carte, sur la terre, matière praticable (pas
## l'eau dormante).
func is_walkable(x: float, z: float) -> bool:
	return data != null and data.is_walkable(x, z)


## Palier (pas de LEVEL_HEIGHT m) de la case sous (x, z) ; MapGroundData.VOID_LEVEL dans le vide.
func level_at(x: float, z: float) -> int:
	return MapGroundData.VOID_LEVEL if data == null else data.level_at(x, z)


## Largeur et profondeur de la carte (m).
func map_size() -> Vector2i:
	return Vector2i.ZERO if data == null else Vector2i(data.width, data.depth)


## Triangles du sol qui touchent le rectangle rect (plan x, z) : [sommets par triangles, face
## avant vers le ciel ; normales], comme IslandTerrain.triangles_in (décalques au sol). Un décalque
## prêt avant le sol (posé avant lui dans l'arbre) le fait construire.
func triangles_in(rect: Rect2) -> Array[PackedVector3Array]:
	var points := PackedVector3Array()
	var normals := PackedVector3Array()
	if _builder == null and is_inside_tree():
		build()
	if _builder == null:
		return [points, normals]
	var vertices := _builder.ground_vertices
	var indices := _builder.ground_indices
	for n in range(0, indices.size(), 3):
		var a := vertices[indices[n]]
		var b := vertices[indices[n + 1]]
		var c := vertices[indices[n + 2]]
		var box := Rect2(Vector2(a.x, a.z), Vector2.ZERO).expand(Vector2(b.x, b.z)).expand(
			Vector2(c.x, c.z)
		)
		if not box.intersects(rect, true):
			continue
		for k in 3:
			points.append(vertices[indices[n + k]])
			normals.append(_builder.ground_normals[indices[n + k]])
	return [points, normals]


## Mesh du sol, mesh des faces (tests, mesures).
func ground_mesh() -> ArrayMesh:
	return null if _mesh == null else _mesh.mesh as ArrayMesh


func cliff_mesh() -> ArrayMesh:
	return null if _cliffs == null else _cliffs.mesh as ArrayMesh


## Triangles de la collision (sol et faces), de la barrière.
func collision_faces() -> PackedVector3Array:
	return PackedVector3Array() if _builder == null else _builder.collision_faces()


func barrier_faces() -> PackedVector3Array:
	return PackedVector3Array() if _builder == null else _builder.barrier


## Segments de la côte (p, q), la terre à droite de p → q vu du dessus.
func rim_segments() -> PackedVector3Array:
	return PackedVector3Array() if _builder == null else _builder.rim


## Mesures : temps de construction (ms), triangles du sol, des faces, de la collision, de la
## barrière, draw calls du sol (sol, faces, mer de nuages).
func stats() -> Dictionary:
	if _builder == null:
		return {}
	var draw_calls := 0
	for instance: MeshInstance3D in [_mesh, _cliffs, _clouds]:
		if instance != null and instance.visible and instance.mesh != null:
			draw_calls += instance.mesh.get_surface_count()
	return {
		"build_msec": build_msec,
		"ground_triangles": _builder.ground_indices.size() / 3.0,
		"cliff_triangles": _builder.cliff_indices.size() / 3.0,
		"collision_triangles": _builder.collision_faces().size() / 3.0,
		"barrier_triangles": _builder.barrier.size() / 3.0,
		"draw_calls": draw_calls,
	}
