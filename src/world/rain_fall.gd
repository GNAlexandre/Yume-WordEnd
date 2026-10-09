class_name RainFall
extends Node3D
## (E9) Pluie dans le monde, autour du point que regarde la caméra : des gouttes qui tombent en
## traits obliques (vent d'ouest) et des éclaboussures au sol, deux meshes de MAX_DROPS et
## MAX_SPLASHES sprites, un draw call chacun (src/world/shaders/rain.gdshader : tout le
## mouvement est dans le shader ; ici, seulement le temps et la boîte, à chaque image).
## intensity (0..1) dit la part des gouttes qui tombent : 0,35 pour la pluie fine, 1 pour
## l'averse ; à 0, les meshes sont cachés (aucun coût). Images : assets/hd2d/fx/rain_drop.png
## (un trait de pluie) et assets/hd2d/anim/rain_splash.png (bande de 4 images, cahier n° 3,
## lot N). Créé par AtmosphereRig ; sans caméra, la boîte reste sur le nœud.

const SHADER := preload("res://src/world/shaders/rain.gdshader")
const DROP_TEXTURE := preload("res://assets/hd2d/fx/rain_drop.png")
const SPLASH_TEXTURE := preload("res://assets/hd2d/anim/rain_splash.png")
## Images de la bande des éclaboussures et cadence.
const SPLASH_FRAMES := 4
const SPLASH_FPS := 12.0
## Nombre de gouttes et d'éclaboussures à l'averse (intensity = 1).
const MAX_DROPS := 900
const MAX_SPLASHES := 160
## Boîte des gouttes (m : est-ouest, hauteur, nord-sud) autour du point visé, et des
## éclaboussures (au ras du sol, plus petite : elles se voient de près).
const DROP_BOX := Vector3(30.0, 12.0, 28.0)
const SPLASH_BOX := Vector3(24.0, 1.0, 20.0)
## Portée du regard quand la caméra ne vise pas le sol (m).
const FALLBACK_REACH := 24.0

## Part des gouttes qui tombent (0 : pas de pluie).
var intensity: float = 0.0:
	set(value):
		intensity = clampf(value, 0.0, 1.0)
		_update_visibility()
## Teinte des gouttes (alpha : opacité à l'averse) ; posée par le préréglage.
var tint: Color = Color(0.82, 0.88, 0.98, 0.7):
	set(value):
		tint = value
		if _drop_material != null:
			_drop_material.set_shader_parameter(&"tint", tint)
			_splash_material.set_shader_parameter(&"tint", Color(tint, minf(tint.a * 1.4, 1.0)))

var _drops: MeshInstance3D
var _splashes: MeshInstance3D
var _drop_material: ShaderMaterial
var _splash_material: ShaderMaterial
var _time: float = 0.0


func _ready() -> void:
	_drop_material = _material(0, DROP_TEXTURE, DROP_BOX)
	_drop_material.set_shader_parameter(&"sprite_size", _size(DROP_TEXTURE, 1))
	_splash_material = _material(1, SPLASH_TEXTURE, SPLASH_BOX)
	_splash_material.set_shader_parameter(
		&"sprite_size", _size(SPLASH_TEXTURE, SPLASH_FRAMES)
	)
	_splash_material.set_shader_parameter(&"frames", float(SPLASH_FRAMES))
	_splash_material.set_shader_parameter(&"fps", SPLASH_FPS)
	_drops = _mesh_instance(&"Drops", MAX_DROPS, 68, _drop_material)
	_splashes = _mesh_instance(&"Splashes", MAX_SPLASHES, 86, _splash_material)
	tint = tint
	_update_visibility()


func _process(delta: float) -> void:
	_time += delta
	var focus := focus_point()
	_place(_drop_material, _drops, focus + Vector3.UP * (DROP_BOX.y / 2.0 - 1.0), DROP_BOX)
	_place(_splash_material, _splashes, focus + Vector3.UP * SPLASH_BOX.y / 2.0, SPLASH_BOX)


## Point que regarde la caméra, au niveau du joueur (groupe « player ») ou du nœud ; le nœud
## sans caméra. Caméra et joueur sont lus à leur place affichée (lissage physique).
func focus_point() -> Vector3:
	var camera := get_viewport().get_camera_3d() if is_inside_tree() else null
	if camera == null:
		return global_position if is_inside_tree() else position
	var player := get_tree().get_first_node_in_group(DecorPanel.PLAYER_GROUP) as Node3D
	var ground := global_position.y
	if player != null:
		ground = DecorPanel.displayed_transform(player).origin.y
	var view := DecorPanel.displayed_transform(camera)
	var forward := -view.basis.z.normalized()
	if forward.y > -0.05:
		return view.origin + forward * FALLBACK_REACH
	return view.origin + forward * ((ground - view.origin.y) / forward.y)


## Vrai si la pluie se voit (gouttes affichées).
func is_raining() -> bool:
	return _drops != null and _drops.visible


func _place(material: ShaderMaterial, mesh: MeshInstance3D, center: Vector3, box: Vector3) -> void:
	material.set_shader_parameter(&"box_center", center)
	material.set_shader_parameter(&"rain_time", _time)
	mesh.custom_aabb = AABB(center - box / 2.0, box)


func _update_visibility() -> void:
	if _drop_material == null:
		return
	var falling := intensity > 0.001
	_drops.visible = falling
	_splashes.visible = falling
	set_process(falling)
	_drop_material.set_shader_parameter(&"intensity", intensity)
	_splash_material.set_shader_parameter(&"intensity", intensity)


func _material(kind: int, texture: Texture2D, box: Vector3) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter(&"albedo_texture", texture)
	material.set_shader_parameter(&"splash", kind)
	material.set_shader_parameter(&"box_size", box)
	return material


static func _size(texture: Texture2D, frames: int) -> Vector2:
	return Vector2(texture.get_size()) / Vector2(frames, 1.0) / DecorPanel.PIXELS_PER_METER


func _mesh_instance(
	mesh_name: StringName, total: int, seed_value: int, material: ShaderMaterial
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	instance.top_level = true
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var mesh := AmbientSprites.sprites_mesh(total, seed_value)
	mesh.surface_set_material(0, material)
	instance.mesh = mesh
	add_child(instance, false, Node.INTERNAL_MODE_FRONT)
	instance.global_transform = Transform3D.IDENTITY
	return instance
