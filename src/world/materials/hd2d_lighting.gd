@tool
class_name HD2DLighting
extends Resource
## Réglage de lumière HD-2D de l'île (H5), d'un bloc : soleil (ou lune), ambiance, brouillard,
## ciel, mer de nuages, lanternes et étalonnage du post-traitement de la caméra du joueur
## (src/player/post_fx.gdshader). Trois réglages dans src/world/materials/ :
## - lighting_sunset.tres : fin d'après-midi d'automne, l'île de l'acte 1 (MONDE.md 5.4 : toujours
##   au couchant) ; ce sont les valeurs d'island.tscn et de post_fx.gdshader (testé) ;
## - lighting_dusk.tres : crépuscule, le soleil sous l'horizon, ciel violet ;
## - lighting_night.tres : nuit claire (la promesse de l'acte 1 sur la colline ; cycle jour/nuit
##   de M3) : lune froide venue de l'est, lanternes et fenêtres qui portent la lumière.
## apply(island) les pose sur une île (et sur la caméra qui la regarde). Le nœud « Lighting »
## d'island.tscn (day_phase_lighting.gd) les pose quand l'histoire émet
## EventBus.day_phase_changed (for_phase : evening → crépuscule, night → nuit, sinon couchant) ;
## rien ne l'émet encore : l'île reste au couchant. apply() travaille sur des copies
## (environnement, mer de nuages) : les ressources partagées d'island.tscn ne changent pas.
## Les planches des personnages ne sont pas éclairées (AnimatedSprite3D non ombré) :
## active_sprite_tint() dit la teinte que le dernier réglage posé leur donne (CONTRACT_REQUESTS,
## H6).

## Méta d'une OmniLight3D : son énergie avant tout réglage (lanterns × lamp_energy).
const BASE_ENERGY_META := &"hd2d_base_energy"
## Méta d'une ressource déjà copiée par apply().
const OWN_META := &"hd2d_lighting_copy"
## Réglage de chaque phase de la journée (EventBus.day_phase_changed) ; les autres : le couchant.
const PHASE_PRESETS := {
	&"evening": "res://src/world/materials/lighting_dusk.tres",
	&"night": "res://src/world/materials/lighting_night.tres",
}
const DEFAULT_PRESET := "res://src/world/materials/lighting_sunset.tres"

## Teinte des personnages du dernier réglage posé par apply() (une couleur, pas la ressource :
## rien ne reste chargé à la sortie).
static var _active_sprite_tint: Color = Color.WHITE

@export_group("Soleil")
## Couleur et énergie de la DirectionalLight3D « Sun » (le soleil, ou la lune la nuit).
@export var sun_color: Color = Color(1.0, 0.86, 0.68)
@export var sun_energy: float = 0.75
## Hauteur au-dessus de l'horizon (degrés) et direction d'où vient la lumière (degrés depuis le
## nord, sens horaire : 90 = est, 270 = ouest).
@export_range(-10.0, 90.0) var sun_elevation_deg: float = 20.0
@export_range(0.0, 360.0) var sun_azimuth_deg: float = 253.3

@export_group("Ambiance")
@export var ambient_color: Color = Color(0.78, 0.72, 0.86)
@export var ambient_energy: float = 0.62
@export var fog_color: Color = Color(0.86, 0.72, 0.74)
@export var fog_density: float = 0.0016
## Énergie du ciel peint (PanoramaSkyMaterial).
@export var sky_energy: float = 1.0
## Teinte de la mer de nuages (cloud_sea.gdshader, non éclairée).
@export var clouds_tint: Color = Color.WHITE

@export_group("Lanternes")
## Facteur de l'énergie des OmniLight3D de l'île (lampes de cristal, portail).
@export var lamp_energy: float = 1.0

@export_group("Personnages")
## Teinte des planches des personnages, que la lumière de la scène n'éclaire pas.
@export var sprite_tint: Color = Color.WHITE

@export_group("Post-traitement")
@export var grade: Color = Color(1.04, 0.99, 0.92)
@export var shadow_tint: Color = Color(0.47, 0.4, 0.62)
@export var highlight_tint: Color = Color(1.0, 0.8, 0.55)
@export var split_strength: float = 0.12
@export var contrast: float = 1.06
@export var saturation: float = 1.06
@export var vignette: float = 0.3
@export var haze_color: Color = Color(0.95, 0.78, 0.7)
@export var haze_strength: float = 0.14
## Lumière du ciel au bord gauche de l'écran (l'ouest : le couchant).
@export var sky_light_color: Color = Color(1.0, 0.72, 0.42)
@export var sky_light_strength: float = 0.1
@export var glow_threshold: float = 0.7
@export var glow_strength: float = 0.6


## Réglage d'une phase de la journée (EventBus.day_phase_changed : morning|day|evening|night).
static func for_phase(phase: StringName) -> HD2DLighting:
	return load(PHASE_PRESETS.get(phase, DEFAULT_PRESET)) as HD2DLighting


## Teinte des planches des personnages sous le dernier réglage posé (blanc : le couchant).
static func active_sprite_tint() -> Color:
	return _active_sprite_tint


## Direction (unitaire) d'où vient la lumière : vers le soleil.
func toward_sun() -> Vector3:
	var elevation := deg_to_rad(sun_elevation_deg)
	var azimuth := deg_to_rad(sun_azimuth_deg)
	return Vector3(sin(azimuth) * cos(elevation), sin(elevation), -cos(azimuth) * cos(elevation))


## Base du soleil : la lumière d'une DirectionalLight3D va selon −Z, donc Z pointe vers le soleil.
func sun_basis() -> Basis:
	var z := toward_sun()
	var x := Vector3.UP.cross(z).normalized()
	return Basis(x, z.cross(x), z)


## Uniformes du post-traitement (post_fx.gdshader) et leurs valeurs.
func post_parameters() -> Dictionary:
	return {
		&"grade": grade,
		&"shadow_tint": shadow_tint,
		&"highlight_tint": highlight_tint,
		&"split_strength": split_strength,
		&"contrast": contrast,
		&"saturation": saturation,
		&"vignette": vignette,
		&"haze_color": haze_color,
		&"haze_strength": haze_strength,
		&"sun_color": sky_light_color,
		&"sun_strength": sky_light_strength,
		&"glow_threshold": glow_threshold,
		&"glow_strength": glow_strength,
	}


## Pose le réglage sur une île (WorldEnvironment, Sun, Water, lanternes) et sur le
## post-traitement de la caméra courante de sa vue, s'il y en a un (CameraRig/PostFX/Screen).
func apply(island: Node3D) -> void:
	_active_sprite_tint = sprite_tint
	var world := island.get_node_or_null(^"WorldEnvironment") as WorldEnvironment
	if world != null and world.environment != null:
		world.environment = _own(world.environment, true) as Environment
		_apply_environment(world.environment)
	var sun := island.get_node_or_null(^"Sun") as DirectionalLight3D
	if sun != null:
		sun.light_color = sun_color
		sun.light_energy = sun_energy
		sun.global_basis = sun_basis()
	var water := island.get_node_or_null(^"Water") as MeshInstance3D
	if water != null:
		var clouds := water.get_active_material(0) as ShaderMaterial
		if clouds != null:
			water.material_override = _own(clouds, false)
			var own := water.material_override as ShaderMaterial
			own.set_shader_parameter(&"tint", clouds_tint)
			var flat := Vector2(toward_sun().x, toward_sun().z)
			if flat.length() > 0.01:
				own.set_shader_parameter(&"sun_direction", flat.normalized())
	for node: Node in island.find_children("*", "OmniLight3D", true, false):
		var lamp := node as OmniLight3D
		if not lamp.has_meta(BASE_ENERGY_META):
			lamp.set_meta(BASE_ENERGY_META, lamp.light_energy)
		lamp.light_energy = float(lamp.get_meta(BASE_ENERGY_META)) * lamp_energy
	if island.is_inside_tree():
		apply_post(_post_material(island.get_viewport().get_camera_3d()))


## Pose l'étalonnage sur un matériau de post_fx.gdshader (sans effet si null).
func apply_post(material: ShaderMaterial) -> void:
	if material == null:
		return
	var values := post_parameters()
	for key: StringName in values:
		material.set_shader_parameter(key, values[key])


func _apply_environment(environment: Environment) -> void:
	environment.ambient_light_color = ambient_color
	environment.ambient_light_energy = ambient_energy
	environment.fog_light_color = fog_color
	environment.fog_density = fog_density
	var sky := environment.sky
	if sky != null and sky.sky_material is PanoramaSkyMaterial:
		(sky.sky_material as PanoramaSkyMaterial).energy_multiplier = sky_energy


## Matériau du post-traitement de la caméra (CameraRig/PostFX/Screen), null s'il n'y en a pas.
static func _post_material(camera: Camera3D) -> ShaderMaterial:
	if camera == null or camera.get_parent() == null:
		return null
	var screen := camera.get_parent().get_node_or_null(^"PostFX/Screen") as CanvasItem
	return screen.material as ShaderMaterial if screen != null else null


## La ressource elle-même si apply() l'a déjà copiée, sinon une copie marquée.
static func _own(resource: Resource, deep: bool) -> Resource:
	if resource.has_meta(OWN_META):
		return resource
	var copy := resource.duplicate(deep)
	copy.set_meta(OWN_META, true)
	return copy
