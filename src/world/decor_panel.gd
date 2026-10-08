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
##
## (H9) Formats du cahier n° 2 (docs/ASSETS_HD2D_MONDE.md, sections 3.4 et 3.7) :
## - bande animée (frames > 1) : images côte à côte, la taille du panneau est celle d'une image ;
##   l'image change dans le shader (TIME, fps), décalée d'une phase tirée de la position du
##   panneau (strip_phase), portée par UV2.x des sommets : le PropBatcher fond toujours tous les
##   panneaux d'une même image en un draw call, animés compris ; l'animation continue en pause ;
## - flip_h : image retournée (variantes de PropScatter) ;
## - depth_offset : le panneau est dessiné comme s'il était depth_offset m plus près de la caméra
##   (UV2.y, sans bouger à l'écran) : cheminée, lucarne, lierre, enseigne posés contre un mur ou
##   sur un pan de toit passent devant lui sans scintiller ;
## - foreground : premier plan, qui s'efface en trame autour du joueur quand il passe devant lui
##   (panel_foreground.gdshader ; centre posé à chaque image par update_foreground).

## Densité des images du monde (Chtholly : 1,5 m = 144 px).
const PIXELS_PER_METER := 96.0
const PANEL_SHADER := preload("res://src/world/shaders/panel.gdshader")
## (H9) Variante de premier plan, qui s'efface devant le joueur.
const FOREGROUND_SHADER := preload("res://src/world/shaders/panel_foreground.gdshader")
## Variante à alpha doux (soft_alpha : fumée, vapeur, cascade, nuages, brume, rais de lumière).
const SOFT_SHADER := preload("res://src/world/shaders/panel_soft.gdshader")
const SHADOW_TEXTURE := preload("res://assets/hd2d/fx/shadow.png")
## Hauteur de l'ombre au-dessus du sol (m) : pas de scintillement avec le sol.
const SHADOW_LIFT := 0.04
## (H5) Ombre douce : opacité au cœur de la tache (fx/shadow.png y est presque opaque : des trous
## noirs sous les garde-corps), et la tache poussée vers l'est d'une part de sa largeur, plus
## large d'autant (le soleil couchant est à l'ouest : MONDE.md 5.4, ombres longues vers l'est).
const SHADOW_OPACITY := 0.55
const SHADOW_EAST := 0.12
## (H9) Pas de la phase des bandes animées (une phase sur PHASE_STEPS) : peu de meshes différents.
const PHASE_STEPS := 32
## (H9) Hauteur du centre de l'effacement du premier plan au-dessus des pieds du joueur (m).
const FOREGROUND_HEIGHT := 0.8
## (H9) Groupe du joueur (PLAN.md section 3, conventions).
const PLAYER_GROUP := &"player"

## Matériaux partagés : clé (image, teinte, lueur) → ShaderMaterial.
static var _materials: Dictionary = {}
## Meshes partagés : clé (taille) → QuadMesh ; (H9) clé (taille, retournement, phase, décalage)
## → ArrayMesh.
static var _quads: Dictionary = {}
static var _panel_meshes: Dictionary = {}
## (H9) Matériaux de premier plan, et image où leur centre a été posé pour la dernière fois.
static var _foreground_materials: Array[ShaderMaterial] = []
static var _foreground_frame: int = -1
## Panneaux de premier plan dans l'arbre : seul le premier a un _process (un appel par image au
## lieu d'un par panneau, plusieurs centaines dans l'île posée) ; s'il quitte l'arbre, le
## suivant prend le relais.
static var _foreground_panels: Array[Node] = []
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
## (H9) Bande animée : nombre d'images côte à côte dans texture (1 : image fixe).
@export_range(1, 64) var frames: int = 1:
	set(value):
		frames = maxi(value, 1)
		_queue_rebuild()
## (H9) Cadence de la bande (images par seconde) ; 0 : chaque exemplaire garde l'image de sa phase.
@export_range(0.0, 60.0) var fps: float = 0.0:
	set(value):
		fps = maxf(value, 0.0)
		_queue_rebuild()
## (H9) Image retournée gauche-droite.
@export var flip_h: bool = false:
	set(value):
		flip_h = value
		_queue_rebuild()
## (H9) Décalage vers la caméra (m) : un panneau posé contre un mur ou sur un pan de toit passe
## devant lui (0,05 à 0,1 suffisent).
@export_range(0.0, 1.0) var depth_offset: float = 0.0:
	set(value):
		depth_offset = maxf(value, 0.0)
		_queue_rebuild()
## (H9) Premier plan : s'efface en trame autour du joueur quand il passe devant lui.
@export var foreground: bool = false:
	set(value):
		foreground = value
		_queue_rebuild()
## Alpha doux : la transparence de l'image est mélangée (dégradés de la fumée, de la brume, des
## nuages, des rais de lumière) au lieu d'être découpée à 0,5 (panel_soft.gdshader). Sans effet
## sur un panneau de premier plan, qui garde sa trame.
@export var soft_alpha: bool = false:
	set(value):
		soft_alpha = value
		_queue_rebuild()

var _quad: MeshInstance3D
var _shadow: MeshInstance3D
var _queued: bool = false


func _ready() -> void:
	rebuild()


## Taille du panneau dans le monde (m) : celle de l'image à pixels_per_meter ; (H9) d'une seule
## image pour une bande animée.
func size_m() -> Vector2:
	if texture == null:
		return Vector2.ZERO
	var image := Vector2(texture.get_size()) / Vector2(frames, 1.0)
	return image / pixels_per_meter


## (H9) Phase de la bande animée de ce panneau (0..1, par pas de 1 / PHASE_STEPS), tirée de sa
## position : stable d'un lancement à l'autre, différente d'un panneau à son voisin.
func strip_phase() -> float:
	return phase_at(global_position if is_inside_tree() else position)


## (H9) Phase tirée d'une position (m, au centimètre près).
static func phase_at(at: Vector3) -> float:
	var key := Vector3i((at * 100.0).round())
	return float(posmod(hash(key), PHASE_STEPS)) / PHASE_STEPS


## Recrée le panneau et son ombre à partir des données.
func rebuild() -> void:
	_queued = false
	if _quad == null:
		_quad = _internal_mesh(&"Quad")
		_shadow = _internal_mesh(&"Shadow")
	var size := size_m()
	_quad.visible = texture != null
	_shadow.visible = texture != null and shadow_width > 0.0
	_set_foreground_active(foreground and texture != null and not Engine.is_editor_hint())
	if texture == null:
		return
	var phase := strip_phase() if frames > 1 else 0.0
	_quad.mesh = panel_mesh(size, flip_h, phase, depth_offset)
	_quad.material_override = material_for(texture, tint, glow, frames, fps, foreground, soft_alpha)
	_shadow.mesh = shadow_mesh()
	_shadow.material_override = shadow_material()
	var shadow_size := Vector2(size.x * shadow_width, size.x * shadow_width * shadow_depth)
	shadow_size.x *= 1.0 + SHADOW_EAST
	if not is_inside_tree():
		return
	var scale_world := global_basis.get_scale()
	_quad.global_basis = global_basis if keep_orientation else Basis.from_scale(scale_world)
	_quad.global_position = global_position + image_offset * scale_world
	var flat := Vector3(shadow_size.x * scale_world.x, 1.0, shadow_size.y * scale_world.z)
	var east := Vector3.RIGHT * flat.x * SHADOW_EAST / 2.0
	_shadow.global_transform = Transform3D(
		Basis.from_scale(flat) * Basis(Vector3.RIGHT, -PI / 2.0),
		global_position + east + Vector3.UP * SHADOW_LIFT
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


## (H9) Mesh d'un panneau de taille size (m), ancre au milieu du bord bas, face vers +Z, image
## retournée si flip, phase de bande animée (UV2.x) et décalage vers la caméra (UV2.y, m) ;
## partagé : le QuadMesh de quad_mesh() quand rien de cela ne sert.
static func panel_mesh(
	size: Vector2, flip: bool = false, phase: float = 0.0, offset: float = 0.0
) -> Mesh:
	if not flip and phase == 0.0 and offset == 0.0:
		return quad_mesh(size)
	var key := "%.4f|%.4f|%d|%.4f|%.3f" % [size.x, size.y, int(flip), phase, offset]
	if not _panel_meshes.has(key):
		var half := size.x / 2.0
		var corners: Array[Vector3] = [
			Vector3(-half, 0.0, 0.0),
			Vector3(half, 0.0, 0.0),
			Vector3(half, size.y, 0.0),
			Vector3(-half, size.y, 0.0),
		]
		var left := 1.0 if flip else 0.0
		var corner_uvs: Array[Vector2] = [
			Vector2(left, 1.0),
			Vector2(1.0 - left, 1.0),
			Vector2(1.0 - left, 0.0),
			Vector2(left, 0.0)
		]
		var vertices := PackedVector3Array()
		var uvs := PackedVector2Array()
		for k: int in [0, 2, 1, 0, 3, 2]:
			vertices.append(corners[k])
			uvs.append(corner_uvs[k])
		var normals := PackedVector3Array()
		normals.resize(6)
		normals.fill(Vector3.BACK)
		var uv2s := PackedVector2Array()
		uv2s.resize(6)
		uv2s.fill(Vector2(phase, offset))
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_TEX_UV] = uvs
		arrays[Mesh.ARRAY_TEX_UV2] = uv2s
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		_panel_meshes[key] = mesh
	return _panel_meshes[key]


## Matériau partagé d'une image (panel.gdshader : nearest, alpha découpé, éclairage plat) ;
## (H9) bande animée de frame_count images à frame_rate images par seconde, premier plan
## (panel_foreground.gdshader) ; alpha doux (panel_soft.gdshader), sauf au premier plan.
static func material_for(
	image: Texture2D,
	color: Color = Color.WHITE,
	glow_amount: float = 0.0,
	frame_count: int = 1,
	frame_rate: float = 0.0,
	in_foreground: bool = false,
	soft: bool = false
) -> Material:
	var blended := soft and not in_foreground
	var key := "%s|%s|%.2f" % [image.get_rid(), color.to_html(), glow_amount]
	if frame_count > 1 or in_foreground or blended:
		key += "|%d|%.3f|%d|%d" % [frame_count, frame_rate, int(in_foreground), int(blended)]
	if not _materials.has(key):
		var material := ShaderMaterial.new()
		material.shader = (
			FOREGROUND_SHADER if in_foreground else (SOFT_SHADER if blended else PANEL_SHADER)
		)
		material.set_shader_parameter(&"albedo_texture", image)
		material.set_shader_parameter(&"tint", color)
		material.set_shader_parameter(&"hd2d_relief", 0.0)
		material.set_shader_parameter(&"glow_strength", glow_amount)
		if frame_count > 1:
			material.set_shader_parameter(&"frames", float(frame_count))
			material.set_shader_parameter(&"fps", frame_rate)
		if in_foreground:
			_foreground_materials.append(material)
		_materials[key] = material
	return _materials[key]


## (H9) Pose le centre de l'effacement des panneaux de premier plan sur le corps du joueur (groupe
## « player »), une fois par image quel que soit le nombre de panneaux ; sans joueur, rien ne
## s'efface. Appelé à chaque image par le premier panneau de premier plan de l'arbre.
static func update_foreground(tree: SceneTree) -> void:
	var frame := Engine.get_process_frames()
	if frame == _foreground_frame:
		return
	_foreground_frame = frame
	var player := tree.get_first_node_in_group(PLAYER_GROUP) as Node3D
	var strength := 0.0
	var center := Vector3.ZERO
	if player != null:
		strength = 1.0
		center = displayed_transform(player).origin + Vector3.UP * FOREGROUND_HEIGHT
	for material: ShaderMaterial in _foreground_materials:
		material.set_shader_parameter(&"foreground_center", center)
		material.set_shader_parameter(&"foreground_strength", strength)


## (H9) Place affichée d'un nœud qui bouge à l'image physique (joueur, caméra) : lissée entre
## deux images physiques quand le lissage physique est actif, sinon sa place.
static func displayed_transform(node: Node3D) -> Transform3D:
	if node.is_physics_interpolated_and_enabled():
		return node.get_global_transform_interpolated()
	return node.global_transform


## Matériau de l'ombre douce au sol (fx/shadow.png, mélangée, non éclairée).
static func shadow_material() -> StandardMaterial3D:
	if _shadow_material == null:
		_shadow_material = StandardMaterial3D.new()
		_shadow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_shadow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_shadow_material.albedo_texture = SHADOW_TEXTURE
		_shadow_material.albedo_color = Color(1.0, 1.0, 1.0, SHADOW_OPACITY)
		_shadow_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_shadow_material.render_priority = -1
	return _shadow_material


## Mesh unité de l'ombre (mis à l'échelle par le nœud).
static func shadow_mesh() -> QuadMesh:
	if _shadow_mesh == null:
		_shadow_mesh = QuadMesh.new()
		_shadow_mesh.size = Vector2.ONE
	return _shadow_mesh


func _process(_delta: float) -> void:
	if foreground:
		update_foreground(get_tree())


func _internal_mesh(node_name: StringName) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance, false, Node.INTERNAL_MODE_FRONT)
	return instance


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and Engine.is_editor_hint():
		_queue_rebuild()
	elif what == NOTIFICATION_EXIT_TREE:
		_set_foreground_active(false)
	elif what == NOTIFICATION_ENTER_TREE and _quad != null:
		_set_foreground_active(foreground and texture != null and not Engine.is_editor_hint())


## Inscrit (ou retire) ce panneau parmi ceux de premier plan ; seul le premier inscrit traite
## l'image (_process), le suivant prend le relais quand il part.
func _set_foreground_active(active: bool) -> void:
	var index := _foreground_panels.find(self)
	if active and is_inside_tree():
		if index < 0:
			_foreground_panels.append(self)
	elif index >= 0:
		_foreground_panels.remove_at(index)
		if index == 0 and not _foreground_panels.is_empty():
			_foreground_panels[0].set_process(true)
	set_process(not _foreground_panels.is_empty() and _foreground_panels[0] == self)


func _queue_rebuild() -> void:
	if _queued or not is_inside_tree():
		return
	_queued = true
	rebuild.call_deferred()
