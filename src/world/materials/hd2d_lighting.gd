@tool
class_name HD2DLighting
extends Resource
## Préréglage de lumière HD-2D, d'un bloc (H5, étendu par E9) : soleil (ou lune), ciel, mer de
## nuages, ambiance, brouillard, lanternes, lueur des fenêtres et des cristaux, images de nuit,
## lumière du joueur, pluie et sol mouillé, teinte des personnages et étalonnage du
## post-traitement de la caméra du joueur (src/player/post_fx.gdshader : flou de profondeur,
## lueur, étalonnage).
##
## (E9) Les préréglages sont des données : data/lighting/<id>.tres (preset(id)).
## - Un par moment de la journée (GameState.MOMENTS) : aube, matin, apres_midi, couchant (le
##   monde de toujours : les valeurs d'island.tscn et de post_fx.gdshader, testé) et nuit ;
## - interieur et interieur_nuit : la lumière chaude d'un intérieur de jour (lampes éteintes) et
##   de nuit (lampes, cheminées et cristaux), mêlées selon la part de nuit du moment du dehors,
##   qui donne aussi le jour des fenêtres (window_light, window_tint ; Atmosphere) ;
## - le temps qu'il fait (pluie, averse) est un HD2DWeather qui modifie un préréglage
##   (data/lighting/<temps>.tres, src/world/materials/hd2d_weather.gd).
## Atmosphere (src/autoload/atmosphere.gd) choisit le préréglage, le mêle au précédent pendant
## une transition (blend_into) et le pose sur la carte courante (HD2DLightTargets). apply(carte)
## le pose d'un coup sur une carte, sans transition (ancienne API de H5, gardée).
## Les planches des personnages ne sont pas éclairées (AnimatedSprite3D non ombré) :
## active_sprite_tint() dit la teinte que le dernier réglage posé leur donne ; (R1)
## CharacterVisual la pose sur son sprite à chaque image.

## Méta d'une Light3D : son énergie avant tout réglage (lanterns × lamp_energy).
const BASE_ENERGY_META := &"hd2d_base_energy"
## Méta d'une ressource déjà copiée par apply().
const OWN_META := &"hd2d_lighting_copy"
## (E9) Dossier des préréglages (un .tres par identifiant) et préréglage par défaut.
const PRESETS_DIR := "res://data/lighting"
const DEFAULT_PRESET := &"couchant"
## (E9) Préréglages des intérieurs : de jour (fenêtres) et de nuit (lampes et cristaux).
const INTERIOR := &"interieur"
const INTERIOR_NIGHT := &"interieur_nuit"
## (E9) Ciel par défaut (sky_texture vide) : le couchant peint.
const DEFAULT_SKY_PATH := "res://assets/hd2d/sky/sky.png"
## Moment de chaque ancienne phase de la journée (EventBus.day_phase_changed, M3).
const PHASE_MOMENTS := {
	&"morning": &"matin",
	&"day": &"apres_midi",
	&"evening": &"couchant",
	&"night": &"nuit",
}
## (E9) Seuil de night_amount à partir duquel les images de nuit et les vitres éclairées
## remplacent celles du jour.
const NIGHT_IMAGES_FROM := 0.5

## Teinte des personnages du dernier réglage posé (une couleur, pas la ressource : rien ne reste
## chargé à la sortie).
static var _active_sprite_tint: Color = Color.WHITE
## (E9) Propriétés interpolées par blend_into : [nom, type], lues une fois.
static var _blend_properties: Array = []

@export_group("Soleil")
## Couleur et énergie de la DirectionalLight3D « Sun » (le soleil, ou la lune la nuit).
@export var sun_color: Color = Color(1.0, 0.86, 0.68)
@export var sun_energy: float = 0.75
## Hauteur au-dessus de l'horizon (degrés) et direction d'où vient la lumière (degrés depuis le
## nord, sens horaire : 90 = est, 270 = ouest).
@export_range(-10.0, 90.0) var sun_elevation_deg: float = 20.0
@export_range(0.0, 360.0) var sun_azimuth_deg: float = 253.3

@export_group("Ciel")
## (E9) Panorama du ciel (vide : sky.png, le couchant) ; teinte multipliée et énergie.
@export var sky_texture: Texture2D
@export var sky_tint: Color = Color.WHITE
## Énergie du ciel peint.
@export var sky_energy: float = 1.0

@export_group("Mer de nuages")
## (E9) Image de la mer de nuages (vide : celle de la carte, cloud_sea.png).
@export var clouds_texture: Texture2D
## Teinte de la mer de nuages (cloud_sea.gdshader, non éclairée).
@export var clouds_tint: Color = Color.WHITE
## (E9) Couleur du côté du soleil (le couchant : orangé ; la nuit : argent froid).
@export var clouds_warm: Color = Color(0.99, 0.78, 0.55)
## (E9) Étoiles dans les creux de la mer de nuages (0..1) : la caméra, inclinée, ne voit jamais
## le ciel au-dessus de l'horizon ; la nuit, ses étoiles se voient là.
@export_range(0.0, 1.0) var clouds_stars: float = 0.0

@export_group("Ambiance")
@export var ambient_color: Color = Color(0.78, 0.72, 0.86)
@export var ambient_energy: float = 0.62
@export var fog_color: Color = Color(0.86, 0.72, 0.74)
@export var fog_density: float = 0.0016

@export_group("Lanternes")
## Facteur de l'énergie des lumières ponctuelles de la carte (lampes de cristal, portail, lampes
## et cheminées des intérieurs).
@export var lamp_energy: float = 1.0
## (E9) Facteur de la lueur propre des panneaux (glow : fenêtres, cristaux, lampadaires).
@export var window_glow: float = 1.0
## (E9) Part de nuit (0 : plein jour, 1 : nuit noire) : à partir de NIGHT_IMAGES_FROM, les images
## <nom>_night.png remplacent les <nom>.png et les vitres éclairées (window_lit_*) s'allument ;
## mêle aussi les intérieurs de jour et de nuit.
@export_range(0.0, 1.0) var night_amount: float = 0.0
## (E9) Lumière magique du joueur (0 : éteinte, 1 : pleine ; Atmosphere en règle l'énergie).
@export_range(0.0, 1.0) var player_light: float = 0.0

@export_group("Intérieurs")
## (R1) Jour qui entre par les fenêtres d'un intérieur (InteriorRoom : flaques de lumière devant
## elles, lueur des vitres) : énergie (0 : aucun ; le matin le plus fort, la nuit un peu de lune)
## et couleur. Dans un moment (aube… nuit), c'est la lumière du dehors à ce moment : un intérieur
## sous le préréglage « interieur » prend celle du moment du dehors (Atmosphere.interior_for),
## pendant que ses lampes, cheminées et cristaux suivent lamp_energy (part de nuit).
@export var window_light: float = 1.0
@export var window_tint: Color = Color(1.0, 0.93, 0.8)

@export_group("Pluie")
## (E9) Pluie (0 : aucune, 1 : averse) et sol mouillé (0 : sec, 1 : trempé) ; posés par le temps
## qu'il fait (HD2DWeather), jamais par un moment.
@export_range(0.0, 1.0) var rain: float = 0.0
@export_range(0.0, 1.0) var wetness: float = 0.0

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
## (E9) Teinte de la lueur et flou de profondeur (px au haut et au bas de l'écran).
@export var glow_tint: Color = Color(1.0, 0.86, 0.66)
@export var top_blur_px: float = 5.5
@export var bottom_blur_px: float = 2.5


## Réglage d'une phase de la journée (EventBus.day_phase_changed : morning|day|evening|night) :
## celui du moment correspondant (PHASE_MOMENTS ; inconnue : le couchant).
static func for_phase(phase: StringName) -> HD2DLighting:
	return preset(PHASE_MOMENTS.get(phase, DEFAULT_PRESET))


## (E9) Chemin du préréglage id.
static func preset_path(id: StringName) -> String:
	return "%s/%s.tres" % [PRESETS_DIR, id]


## (E9) Vrai si data/lighting/<id>.tres existe.
static func has_preset(id: StringName) -> bool:
	return not id.is_empty() and ResourceLoader.exists(preset_path(id))


## (E9) Préréglage id (data/lighting/<id>.tres), null s'il n'existe pas ou n'en est pas un.
static func preset(id: StringName) -> HD2DLighting:
	if not has_preset(id):
		return null
	return load(preset_path(id)) as HD2DLighting


## Teinte des planches des personnages sous le dernier réglage posé (blanc : le couchant).
static func active_sprite_tint() -> Color:
	return _active_sprite_tint


## (E9) Retient la teinte des personnages du réglage posé (Atmosphere, apply).
static func set_active_sprite_tint(tint: Color) -> void:
	_active_sprite_tint = tint


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


## (E9) Panorama du ciel : sky_texture, ou sky.png.
func sky_image() -> Texture2D:
	if sky_texture != null:
		return sky_texture
	return load(DEFAULT_SKY_PATH) as Texture2D


## (E9) Vrai si les images de nuit et les vitres éclairées remplacent celles du jour.
func uses_night_images() -> bool:
	return night_amount >= NIGHT_IMAGES_FROM


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
		&"glow_tint": glow_tint,
		&"top_blur_px": top_blur_px,
		&"bottom_blur_px": bottom_blur_px,
	}


## Pose le réglage d'un coup sur une carte (WorldEnvironment, Sun, mer de nuages, lanternes,
## lueurs, images de nuit, sol mouillé : HD2DLightTargets) et sur le post-traitement de la
## caméra courante de sa vue, s'il y en a un (CameraRig/PostFX/Screen). Les ressources de la
## carte (environnement, mer de nuages) sont copiées avant d'être changées : la scène ne change
## pas. Sans transition ni pluie (Atmosphere les ajoute).
func apply(island: Node3D) -> void:
	var targets := HD2DLightTargets.scan(island)
	targets.apply(self)
	if island.is_inside_tree():
		apply_post(post_material(island.get_viewport().get_camera_3d()))


## Pose l'étalonnage sur un matériau de post_fx.gdshader (sans effet si null).
func apply_post(material: ShaderMaterial) -> void:
	if material == null:
		return
	var values := post_parameters()
	for key: StringName in values:
		material.set_shader_parameter(key, values[key])


## (E9) Copie indépendante (rien n'est partagé avec le préréglage chargé).
func copy() -> HD2DLighting:
	return duplicate() as HD2DLighting


## (E9) Réglage à mi-chemin de self (t = 0) à other (t = 1) : nouvelle ressource.
func blended(other: HD2DLighting, t: float) -> HD2DLighting:
	var result := HD2DLighting.new()
	blend_into(result, self, other, t)
	return result


## (E9) Pose dans out le mélange de from (t = 0) et to (t = 1) : couleurs et nombres interpolés
## (l'azimut du soleil par le plus court chemin), images de from jusqu'à mi-chemin puis de to
## (le ciel et la mer de nuages se fondent dans leur shader, Atmosphere).
static func blend_into(out: HD2DLighting, from: HD2DLighting, to: HD2DLighting, t: float) -> void:
	t = clampf(t, 0.0, 1.0)
	for entry: Array in _properties():
		var property: StringName = entry[0]
		var a: Variant = from.get(property)
		var b: Variant = to.get(property)
		match int(entry[1]):
			TYPE_FLOAT:
				if property == &"sun_azimuth_deg":
					var angle := rad_to_deg(lerp_angle(deg_to_rad(a), deg_to_rad(b), t))
					out.set(property, fposmod(angle, 360.0))
				else:
					out.set(property, lerpf(a, b, t))
			TYPE_COLOR:
				out.set(property, (a as Color).lerp(b as Color, t))
			_:
				out.set(property, a if t < 0.5 else b)


## Propriétés exportées du script (nom, type), sans les groupes.
static func _properties() -> Array:
	if _blend_properties.is_empty():
		for info: Dictionary in HD2DLighting.new().get_property_list():
			var usage := int(info["usage"])
			if usage & PROPERTY_USAGE_SCRIPT_VARIABLE and usage & PROPERTY_USAGE_STORAGE:
				_blend_properties.append([StringName(info["name"]), int(info["type"])])
	return _blend_properties


## Matériau du post-traitement de la caméra (CameraRig/PostFX/Screen), null s'il n'y en a pas.
static func post_material(camera: Camera3D) -> ShaderMaterial:
	if camera == null or camera.get_parent() == null:
		return null
	var screen := camera.get_parent().get_node_or_null(^"PostFX/Screen") as CanvasItem
	return screen.material as ShaderMaterial if screen != null else null


## La ressource elle-même si elle a déjà été copiée, sinon une copie marquée.
static func own(resource: Resource, deep: bool) -> Resource:
	if resource.has_meta(OWN_META):
		return resource
	var copy_of := resource.duplicate(deep)
	copy_of.set_meta(OWN_META, true)
	return copy_of
