@tool
class_name Building
extends Node3D
## Bâtiment HD-2D (docs/ASSETS_HD2D.md, section 6) : un volume simple, murs et toit recouverts de
## matières sans raccord (192 px = 2 m), et sa façade sud en image debout devant le mur (la caméra
## fixe regarde le nord). Origine : centre de l'emprise au sol ; la façade est posée sur son ancre
## (milieu du bord bas) au milieu du mur sud. Racine des scènes de bâtiments de src/world/props/ ;
## la collision (enfant « Collision », couche 1) reste dans la scène. Propriétaire : L2 (monde).
##
## Toit « long » (gable_front faux) : faîtage est-ouest, pignons à l'est et à l'ouest, la façade
## s'arrête à l'égout. Toit « pignon » (gable_front vrai) : faîtage nord-sud, la façade comprend le
## triangle du pignon. Enfants internes « Walls », « Roof » et « Facade », recréés au chargement.

## Taille d'une matière répétée (m) : 192 px à 96 px par mètre.
const MATERIAL_SPAN := 2.0
## Léger retrait du mur sud derrière la façade (m), pour qu'elle ne scintille pas avec lui.
const FACADE_GAP := 0.03
## Part du relief dans l'éclairage des murs et des toits (hd2d_light.gdshaderinc).
const WALL_RELIEF := 0.6
const ROOF_RELIEF := 1.0
## (H5) Groupe des bâtiments en jeu : la caméra du joueur (camera_rig.gd) cadre leur façade sud.
const GROUP := &"hd2d_buildings"

## Matériaux partagés : clé (matière, relief) → ShaderMaterial.
static var _materials: Dictionary = {}

## Image de la façade sud (élévation de face, fond transparent).
@export var facade: Texture2D:
	set(value):
		facade = value
		_queue_rebuild()
## Matière des murs et des pignons (sans raccord).
@export var wall_texture: Texture2D:
	set(value):
		wall_texture = value
		_queue_rebuild()
## Matière du toit (rangées parallèles au bas de l'image, le long de l'égout).
@export var roof_texture: Texture2D:
	set(value):
		roof_texture = value
		_queue_rebuild()
## Emprise au sol : largeur (x, est-ouest) et profondeur (z), m.
@export var footprint: Vector2 = Vector2(8.0, 6.0):
	set(value):
		footprint = value
		_queue_rebuild()
## Hauteur des murs à l'égout (m).
@export var wall_height: float = 3.0:
	set(value):
		wall_height = value
		_queue_rebuild()
## Hauteur du faîtage (m).
@export var ridge_height: float = 5.0:
	set(value):
		ridge_height = value
		_queue_rebuild()
## Pignon en façade (faîtage nord-sud) au lieu d'un toit long (faîtage est-ouest).
@export var gable_front: bool = false:
	set(value):
		gable_front = value
		_queue_rebuild()
## Débord du toit au-delà des murs (m).
@export var overhang: float = 0.3:
	set(value):
		overhang = value
		_queue_rebuild()
## Lueur des fenêtres de la façade (pixels couleur cristal).
@export_range(0.0, 4.0) var window_glow: float = 0.8:
	set(value):
		window_glow = value
		_queue_rebuild()

var _walls: MeshInstance3D
var _roof: MeshInstance3D
var _facade: MeshInstance3D
var _queued: bool = false


func _ready() -> void:
	if not Engine.is_editor_hint():
		add_to_group(GROUP)
	rebuild()


## Recrée murs, toit et façade à partir des données.
func rebuild() -> void:
	_queued = false
	if _walls == null:
		_walls = _internal_mesh(&"Walls")
		_roof = _internal_mesh(&"Roof")
		_facade = _internal_mesh(&"Facade")
	_walls.mesh = _walls_mesh()
	_walls.material_override = surface_material(wall_texture, WALL_RELIEF)
	_roof.mesh = _roof_mesh()
	_roof.material_override = surface_material(roof_texture, ROOF_RELIEF)
	_facade.visible = facade != null
	if facade != null:
		var size := Vector2(facade.get_size()) / DecorPanel.PIXELS_PER_METER
		_facade.mesh = DecorPanel.quad_mesh(size)
		_facade.material_override = DecorPanel.material_for(facade, Color.WHITE, window_glow)
		_facade.position = Vector3(0.0, 0.0, footprint.y / 2.0 + FACADE_GAP)


## Matériau partagé d'une matière de mur ou de toit (panel.gdshader, relief lisible).
static func surface_material(texture: Texture2D, relief: float) -> Material:
	if texture == null:
		return null
	var key := "%s|%.2f" % [texture.get_rid(), relief]
	if not _materials.has(key):
		var material := ShaderMaterial.new()
		material.shader = DecorPanel.PANEL_SHADER
		material.set_shader_parameter(&"albedo_texture", texture)
		material.set_shader_parameter(&"hd2d_relief", relief)
		_materials[key] = material
	return _materials[key]


## Murs : quatre faces verticales (le sud est caché derrière la façade) et les deux pignons.
func _walls_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hx := footprint.x / 2.0
	var hz := footprint.y / 2.0
	var h := wall_height
	_quad(st, Vector3(-hx, 0, -hz), Vector3(hx, 0, -hz), Vector3(hx, h, -hz), Vector3(-hx, h, -hz))
	_quad(st, Vector3(hx, 0, -hz), Vector3(hx, 0, hz), Vector3(hx, h, hz), Vector3(hx, h, -hz))
	_quad(st, Vector3(-hx, 0, hz), Vector3(-hx, 0, -hz), Vector3(-hx, h, -hz), Vector3(-hx, h, hz))
	_quad(st, Vector3(hx, 0, hz), Vector3(-hx, 0, hz), Vector3(-hx, h, hz), Vector3(hx, h, hz))
	if gable_front:
		_triangle(st, Vector3(-hx, h, -hz), Vector3(hx, h, -hz), Vector3(0, ridge_height, -hz))
		_triangle(st, Vector3(hx, h, hz), Vector3(-hx, h, hz), Vector3(0, ridge_height, hz))
	else:
		_triangle(st, Vector3(hx, h, -hz), Vector3(hx, h, hz), Vector3(hx, ridge_height, 0))
		_triangle(st, Vector3(-hx, h, hz), Vector3(-hx, h, -hz), Vector3(-hx, ridge_height, 0))
	return st.commit()


## Toit : deux pans de l'égout au faîtage, avec débord.
func _roof_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var o := overhang
	var hx := footprint.x / 2.0
	var hz := footprint.y / 2.0
	var h := wall_height
	var r := ridge_height
	if gable_front:
		# Pans est et ouest ; v descend le long de la pente, u suit l'égout (nord-sud).
		var drop := o * (r - h) / maxf(hx, 0.01)
		_roof_plane(
			st,
			Vector3(0, r, hz + o),
			Vector3(0, r, -hz - o),
			Vector3(-hx - o, h - drop, -hz - o),
			Vector3(-hx - o, h - drop, hz + o)
		)
		_roof_plane(
			st,
			Vector3(0, r, -hz - o),
			Vector3(0, r, hz + o),
			Vector3(hx + o, h - drop, hz + o),
			Vector3(hx + o, h - drop, -hz - o)
		)
	else:
		var drop := o * (r - h) / maxf(hz, 0.01)
		_roof_plane(
			st,
			Vector3(-hx - o, r, 0),
			Vector3(hx + o, r, 0),
			Vector3(hx + o, h - drop, hz + o),
			Vector3(-hx - o, h - drop, hz + o)
		)
		_roof_plane(
			st,
			Vector3(hx + o, r, 0),
			Vector3(-hx - o, r, 0),
			Vector3(-hx - o, h - drop, -hz - o),
			Vector3(hx + o, h - drop, -hz - o)
		)
	return st.commit()


## Pan de toit a b (faîtage), c d (égout) : u le long du faîtage, v le long de la pente ; normale
## vers le ciel.
static func _roof_plane(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	var along := a.distance_to(b) / MATERIAL_SPAN
	var down := a.distance_to(d) / MATERIAL_SPAN
	var normal := (b - a).cross(d - a).normalized()
	if normal.y < 0.0:
		normal = -normal
	var uvs: Array[Vector2] = [
		Vector2(0, 0), Vector2(along, 0), Vector2(along, down), Vector2(0, down)
	]
	var points: Array[Vector3] = [a, b, c, d]
	for k: int in [0, 1, 2, 0, 2, 3]:
		st.set_normal(normal)
		st.set_uv(uvs[k])
		st.add_vertex(points[k])


## Mur a b c d (bas gauche, bas droite, haut droite, haut gauche vus de l'extérieur) : normale
## vers l'extérieur.
static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	var axis := (b - a).normalized()
	var normal := Vector3.UP.cross(axis).normalized()
	var points: Array[Vector3] = [a, b, c, d]
	for k: int in [0, 2, 1, 0, 3, 2]:
		var p := points[k]
		st.set_normal(normal)
		st.set_uv(Vector2((p - a).dot(axis), -p.y) / MATERIAL_SPAN)
		st.add_vertex(p)


## Pignon a b (base, de gauche à droite vu de l'extérieur), c (sommet).
static func _triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var axis := (b - a).normalized()
	var normal := Vector3.UP.cross(axis).normalized()
	for p: Vector3 in [a, c, b]:
		st.set_normal(normal)
		st.set_uv(Vector2((p - a).dot(axis), -p.y) / MATERIAL_SPAN)
		st.add_vertex(p)


func _internal_mesh(node_name: StringName) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance, false, Node.INTERNAL_MODE_FRONT)
	return instance


func _queue_rebuild() -> void:
	if _queued or not is_inside_tree():
		return
	_queued = true
	rebuild.call_deferred()
