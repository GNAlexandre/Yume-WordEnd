@tool
class_name AmbientSprites
extends Node3D
## (H9) Petites vies (docs/ASSETS_HD2D_MONDE.md, section 12) : sprites animés, une bande animée
## (texture de frames images côte à côte, ancre au centre) qui vivent autour du point que regarde
## la caméra : feuilles qui tombent en tournoyant, oiseaux qui traversent, papillons, lucioles
## (motion). Nombre (count, ou density par 100 m²), boîte autour de la caméra (area, au-dessus du
## sol de lift m), région où ils vivent (region_size autour du nœud : une zone), vitesse et
## ampleur (speed, sway) réglables. Sans image, le nœud ne fait rien.
##
## Un draw call en tout par nœud (deux nœuds pour feuilles et oiseaux) : tout le mouvement est
## dans ambient_sprites.gdshader ; ici, seulement le temps (arrêté pendant la pause : ils se
## figent) et la boîte, à chaque image. Hors de la région, le mesh est caché. Le matériau est
## porté par le mesh : un PropBatcher parent ne le fond pas. Enfant interne « Sprites », en
## coordonnées du monde.

enum Motion { FALL, CROSS, FLUTTER, HOVER }

const SHADER := preload("res://src/world/shaders/ambient_sprites.gdshader")
## Marge (m) de la région au-delà de laquelle le mesh est caché.
const REGION_MARGIN := 16.0
## Hauteur du point visé quand il n'y a pas de joueur (m, au-dessus du nœud) et portée du
## regard quand la caméra ne vise pas le sol (m).
const FALLBACK_REACH := 24.0

## Bande animée (images côte à côte, de même taille, sans marge).
@export var texture: Texture2D:
	set(value):
		texture = value
		_queue_rebuild()
## Nombre d'images de la bande et cadence (images par seconde).
@export_range(1, 64) var frames: int = 1:
	set(value):
		frames = maxi(value, 1)
		_queue_rebuild()
@export var fps: float = 8.0:
	set(value):
		fps = maxf(value, 0.0)
		_queue_rebuild()
## Densité de l'image (px par mètre).
@export var pixels_per_meter: float = DecorPanel.PIXELS_PER_METER:
	set(value):
		pixels_per_meter = maxf(value, 1.0)
		_queue_rebuild()
## Mouvement : feuilles, oiseaux, papillons, lucioles.
@export var motion: Motion = Motion.FALL:
	set(value):
		motion = value
		_queue_rebuild()
## Nombre de sprites dans la boîte.
@export_range(0, 1024) var count: int = 16:
	set(value):
		count = maxi(value, 0)
		_queue_rebuild()
## Densité (sprites par 100 m² de la boîte, x × z) ; si > 0, remplace count.
@export var density: float = 0.0:
	set(value):
		density = maxf(value, 0.0)
		_queue_rebuild()
## Boîte autour du point que regarde la caméra (m : largeur est-ouest, hauteur, profondeur).
@export var area: Vector3 = Vector3(26.0, 9.0, 20.0):
	set(value):
		area = value.max(Vector3.ONE)
		_queue_rebuild()
## Hauteur du bas de la boîte au-dessus du sol (m) : 0 pour les feuilles, plus pour les oiseaux.
@export var lift: float = 0.0
## Région où ils vivent (m, x et z, centrée sur le nœud) ; zéro : partout.
@export var region_size: Vector2 = Vector2.ZERO
## Vitesse (m/s : chute des feuilles, vol des oiseaux ; négative : vers l'ouest) et ampleur des
## écarts (m).
@export var speed: float = 1.0:
	set(value):
		speed = value
		_queue_rebuild()
@export var sway: float = 0.8:
	set(value):
		sway = value
		_queue_rebuild()
## Teinte multipliée et lueur propre (lucioles).
@export var tint: Color = Color.WHITE:
	set(value):
		tint = value
		_queue_rebuild()
@export_range(0.0, 4.0) var glow: float = 0.0:
	set(value):
		glow = value
		_queue_rebuild()
## Graine des tirages.
@export var random_seed: int = 0:
	set(value):
		random_seed = value
		_queue_rebuild()

var _mesh: MeshInstance3D
var _material: ShaderMaterial
var _time: float = 0.0
var _queued: bool = false


func _ready() -> void:
	rebuild()


func _process(delta: float) -> void:
	if _material == null:
		return
	_time += delta
	update_box(focus_point())


## Nombre de sprites : count, ou density par 100 m² de la boîte.
func sprite_count() -> int:
	if density > 0.0:
		return roundi(density * area.x * area.z / 100.0)
	return count


## Taille d'un sprite (m) : une image de la bande.
func sprite_size() -> Vector2:
	if texture == null:
		return Vector2.ZERO
	return Vector2(texture.get_size()) / Vector2(frames, 1.0) / pixels_per_meter


## Recrée le mesh des sprites à partir des données.
func rebuild() -> void:
	_queued = false
	if _mesh == null:
		_mesh = MeshInstance3D.new()
		_mesh.name = &"Sprites"
		_mesh.top_level = true
		_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Rien ne bouge le nœud : la boîte suit la caméra par le shader, à chaque image affichée.
		_mesh.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		add_child(_mesh, false, Node.INTERNAL_MODE_FRONT)
	_material = null
	_mesh.mesh = null
	_mesh.visible = false
	set_process(false)
	var total := sprite_count()
	if texture == null or total <= 0:
		return
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_material.set_shader_parameter(&"albedo_texture", texture)
	_material.set_shader_parameter(&"tint", tint)
	_material.set_shader_parameter(&"glow", glow)
	_material.set_shader_parameter(&"motion", int(motion))
	_material.set_shader_parameter(&"speed", speed)
	_material.set_shader_parameter(&"sway", sway)
	_material.set_shader_parameter(&"sprite_size", sprite_size())
	_material.set_shader_parameter(&"frames", float(frames))
	_material.set_shader_parameter(&"fps", fps)
	_material.set_shader_parameter(&"hd2d_relief", 0.0)
	var mesh := sprites_mesh(total, random_seed)
	mesh.surface_set_material(0, _material)
	_mesh.mesh = mesh
	_mesh.visible = true
	set_process(true)
	if is_inside_tree():
		_mesh.global_transform = Transform3D.IDENTITY
		update_box(focus_point())


## Point que regarde la caméra, au niveau du sol : le rayon du centre de l'écran coupé à la
## hauteur du joueur (groupe « player »), sinon du nœud ; le nœud sans caméra. Caméra et joueur
## sont lus à leur place affichée (lissage physique : DecorPanel.displayed_transform).
func focus_point() -> Vector3:
	var camera := get_viewport().get_camera_3d() if is_inside_tree() else null
	if camera == null:
		return global_position if is_inside_tree() else position
	var player := get_tree().get_first_node_in_group(DecorPanel.PLAYER_GROUP) as Node3D
	var ground := global_position.y
	if player != null:
		ground = DecorPanel.displayed_transform(player).origin.y
	var view := DecorPanel.displayed_transform(camera)
	var origin := view.origin
	var forward := -view.basis.z.normalized()
	if forward.y > -0.05:
		return origin + forward * FALLBACK_REACH
	return origin + forward * ((ground - origin.y) / forward.y)


## Pose la boîte sur le point visé (et le temps) ; cache le mesh hors de la région.
func update_box(focus: Vector3) -> void:
	if _material == null:
		return
	var center := focus + Vector3.UP * (lift + area.y / 2.0)
	_material.set_shader_parameter(&"box_center", center)
	_material.set_shader_parameter(&"box_size", area)
	_material.set_shader_parameter(&"ambient_time", _time)
	var origin := global_position if is_inside_tree() else position
	var half := region_size / 2.0
	var region := Vector4(origin.x, origin.z, half.x, half.y)
	_material.set_shader_parameter(&"region", region)
	var inside := true
	if region_size.x > 0.0 and region_size.y > 0.0:
		var reach := half + Vector2.ONE * REGION_MARGIN
		inside = absf(focus.x - origin.x) < reach.x and absf(focus.z - origin.z) < reach.y
	_mesh.visible = inside
	_mesh.custom_aabb = AABB(center - area / 2.0, area)


## Mesh de total sprites : 6 sommets chacun, sommet = graine 0..1 de sa place dans la boîte, UV =
## coin, UV2 et COLOR = tirages (phase, vitesse, écarts).
static func sprites_mesh(total: int, seed_value: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var uvs: Array[Vector2] = [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
	for _i in total:
		var home := Vector3(rng.randf(), rng.randf(), rng.randf())
		var draws := Vector2(rng.randf(), rng.randf())
		var more := Color(rng.randf(), rng.randf(), rng.randf(), rng.randf())
		for k: int in [0, 2, 1, 0, 3, 2]:
			st.set_uv(uvs[k])
			st.set_uv2(draws)
			st.set_color(more)
			st.set_normal(Vector3.BACK)
			st.add_vertex(home)
	return st.commit()


func _queue_rebuild() -> void:
	if _queued or not is_inside_tree():
		return
	_queued = true
	rebuild.call_deferred()
