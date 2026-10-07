@tool
class_name DecorPanel
extends Node3D
## Décor HD-2D en panneau : une image debout (docs/ASSETS_HD2D.md, section 7) posée sur son ancre
## (milieu du bord bas = origine du nœud), à PIXELS_PER_METER px par mètre, tournée vers le sud
## (la caméra fixe regarde le nord) quelle que soit l'orientation du nœud, avec son ombre douce
## au sol. Racine des scènes de src/world/props/ ; la collision (enfant « Collision »,
## StaticBody3D de la couche 1) reste dans la scène et garde l'orientation du nœud. Propriétaire :
## L2 (monde).
##
## Les enfants « Quad » et « Shadow » sont internes, recréés au chargement (aussi dans l'éditeur) :
## seules les données ci-dessous sont enregistrées. Matériaux et meshes sont partagés par image,
## pour que le PropBatcher de la zone fonde tous les panneaux d'une même image en un draw call.

## Densité des images du monde (Chtholly : 1,5 m = 144 px).
const PIXELS_PER_METER := 96.0
const PANEL_SHADER := preload("res://src/world/shaders/panel.gdshader")
const SHADOW_TEXTURE := preload("res://assets/hd2d/fx/shadow.png")
## Hauteur de l'ombre au-dessus du sol (m) : pas de scintillement avec le sol.
const SHADOW_LIFT := 0.04

## Matériaux partagés : clé (image, teinte, lueur) → ShaderMaterial.
static var _materials: Dictionary = {}
## Meshes partagés : clé (taille) → QuadMesh.
static var _quads: Dictionary = {}
static var _shadow_material: StandardMaterial3D
static var _shadow_mesh: QuadMesh

## Image du panneau (PNG à fond transparent, collée au bord bas).
@export var texture: Texture2D:
	set(value):
		texture = value
		_queue_rebuild()
## Densité de l'image (px par mètre) : 96 dans le monde, moins pour le décor lointain.
@export var pixels_per_meter: float = PIXELS_PER_METER:
	set(value):
		pixels_per_meter = maxf(value, 1.0)
		_queue_rebuild()
## Largeur de l'ombre au sol, en fraction de la largeur de l'image (0 : pas d'ombre).
@export_range(0.0, 2.0) var shadow_width: float = 0.8:
	set(value):
		shadow_width = value
		_queue_rebuild()
## Profondeur de l'ombre en fraction de sa largeur.
@export_range(0.05, 2.0) var shadow_depth: float = 0.4:
	set(value):
		shadow_depth = value
		_queue_rebuild()
## Le panneau garde l'orientation du nœud au lieu de se tourner vers le sud (rare : un panneau
## posé de profil).
@export var keep_orientation: bool = false:
	set(value):
		keep_orientation = value
		_queue_rebuild()
## Décalage de l'image par rapport à l'ancre (m, repère du monde ; l'ombre reste à l'ancre) : un
## belvédère dont l'image est posée au fond de sa plateforme, pour qu'on se tienne devant.
@export var image_offset: Vector3 = Vector3.ZERO:
	set(value):
		image_offset = value
		_queue_rebuild()
## Teinte multipliée (variante de couleur sans nouvelle image).
@export var tint: Color = Color.WHITE:
	set(value):
		tint = value
		_queue_rebuild()
## Lueur propre des pixels couleur cristal (lanternes, fenêtres), 0 : aucune.
@export_range(0.0, 4.0) var glow: float = 0.0:
	set(value):
		glow = value
		_queue_rebuild()

var _quad: MeshInstance3D
var _shadow: MeshInstance3D
var _queued: bool = false


func _ready() -> void:
	rebuild()


## Taille du panneau dans le monde (m) : celle de l'image à pixels_per_meter.
func size_m() -> Vector2:
	if texture == null:
		return Vector2.ZERO
	return Vector2(texture.get_size()) / pixels_per_meter


## Recrée le panneau et son ombre à partir des données.
func rebuild() -> void:
	_queued = false
	if _quad == null:
		_quad = _internal_mesh(&"Quad")
		_shadow = _internal_mesh(&"Shadow")
	var size := size_m()
	_quad.visible = texture != null
	_shadow.visible = texture != null and shadow_width > 0.0
	if texture == null:
		return
	_quad.mesh = quad_mesh(size)
	_quad.material_override = material_for(texture, tint, glow)
	_shadow.mesh = shadow_mesh()
	_shadow.material_override = shadow_material()
	var shadow_size := Vector2(size.x * shadow_width, size.x * shadow_width * shadow_depth)
	if not is_inside_tree():
		return
	var scale_world := global_basis.get_scale()
	_quad.global_basis = global_basis if keep_orientation else Basis.from_scale(scale_world)
	_quad.global_position = global_position + image_offset * scale_world
	var flat := Vector3(shadow_size.x * scale_world.x, 1.0, shadow_size.y * scale_world.z)
	_shadow.global_transform = Transform3D(
		Basis.from_scale(flat) * Basis(Vector3.RIGHT, -PI / 2.0),
		global_position + Vector3.UP * SHADOW_LIFT
	)


## Mesh du panneau de taille size (m), ancre au milieu du bord bas, face vers +Z.
static func quad_mesh(size: Vector2) -> QuadMesh:
	var key := "%.4f|%.4f" % [size.x, size.y]
	if not _quads.has(key):
		var mesh := QuadMesh.new()
		mesh.size = size
		mesh.center_offset = Vector3(0.0, size.y / 2.0, 0.0)
		_quads[key] = mesh
	return _quads[key]


## Matériau partagé d'une image (panel.gdshader : nearest, alpha découpé, éclairage plat).
static func material_for(
	image: Texture2D, color: Color = Color.WHITE, glow_amount: float = 0.0
) -> Material:
	var key := "%s|%s|%.2f" % [image.get_rid(), color.to_html(), glow_amount]
	if not _materials.has(key):
		var material := ShaderMaterial.new()
		material.shader = PANEL_SHADER
		material.set_shader_parameter(&"albedo_texture", image)
		material.set_shader_parameter(&"tint", color)
		material.set_shader_parameter(&"hd2d_relief", 0.0)
		material.set_shader_parameter(&"glow_strength", glow_amount)
		_materials[key] = material
	return _materials[key]


## Matériau de l'ombre douce au sol (fx/shadow.png, mélangée, non éclairée).
static func shadow_material() -> StandardMaterial3D:
	if _shadow_material == null:
		_shadow_material = StandardMaterial3D.new()
		_shadow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_shadow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_shadow_material.albedo_texture = SHADOW_TEXTURE
		_shadow_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_shadow_material.render_priority = -1
	return _shadow_material


## Mesh unité de l'ombre (mis à l'échelle par le nœud).
static func shadow_mesh() -> QuadMesh:
	if _shadow_mesh == null:
		_shadow_mesh = QuadMesh.new()
		_shadow_mesh.size = Vector2.ONE
	return _shadow_mesh


func _internal_mesh(node_name: StringName) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance, false, Node.INTERNAL_MODE_FRONT)
	return instance


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and Engine.is_editor_hint():
		_queue_rebuild()


func _queue_rebuild() -> void:
	if _queued or not is_inside_tree():
		return
	_queued = true
	rebuild.call_deferred()
