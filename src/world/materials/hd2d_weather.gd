@tool
class_name HD2DWeather
extends Resource
## (E9) Temps qu'il fait : pluie fine, averse (data/lighting/<temps>.tres ; « clair » n'a pas de
## fichier : rien ne change). Ne remplace pas le préréglage du moment de la journée
## (HD2DLighting) : il le modifie (applied_to), ce qui donne la pluie au matin, au couchant ou la
## nuit avec le même fichier. Dehors : moins de soleil, ciel et mer de nuages gris, brouillard,
## étalonnage terne, gouttes et sol mouillé ; dedans : seulement la lumière des fenêtres, plus
## faible et plus grise (ni pluie ni sol mouillé).

## Pluie (0..1 : densité des gouttes, du rideau et des éclaboussures) et sol mouillé (0..1).
@export_range(0.0, 1.0) var rain: float = 0.0
@export_range(0.0, 1.0) var wetness: float = 0.0
## (vide : celui du moment) Ciel de pluie, quand le lot N du cahier n° 3 l'aura livré
## (sky_rain.png), et sa part dans le ciel du moment (0..1).
@export var sky_texture: Texture2D
@export_range(0.0, 1.0) var sky_amount: float = 1.0
@export_group("Lumière")
## Facteurs du soleil (ou de la lune) et de la lumière ambiante.
@export var sun_scale: float = 1.0
@export var ambient_scale: float = 1.0
## Couleur vers laquelle tirent le soleil, l'ambiance et les teintes (gris de la pluie), et de
## combien (0..1).
@export var grey: Color = Color(0.62, 0.64, 0.72)
@export_range(0.0, 1.0) var grey_amount: float = 0.0
## Teinte multipliée du ciel et de la mer de nuages.
@export var sky_tint: Color = Color.WHITE
@export var clouds_tint: Color = Color.WHITE
## Facteur des lanternes et de la lueur des fenêtres (elles se voient mieux sous la pluie).
@export var lamp_scale: float = 1.0
## Teinte multipliée des personnages.
@export var sprite_tint: Color = Color.WHITE
@export_group("Brouillard")
@export var fog_add: float = 0.0
@export var fog_color: Color = Color(0.6, 0.62, 0.7)
@export_range(0.0, 1.0) var fog_mix: float = 0.0
@export_group("Post-traitement")
## Facteurs de la saturation et du contraste, ajout à la vignette, voile du lointain (couleur,
## part du mélange et ajout), facteur de la lumière du couchant au bord gauche, flou ajouté au
## haut de l'écran (px).
@export var saturation_scale: float = 1.0
@export var contrast_scale: float = 1.0
@export var vignette_add: float = 0.0
@export var haze_color: Color = Color(0.6, 0.62, 0.7)
@export_range(0.0, 1.0) var haze_mix: float = 0.0
@export var haze_add: float = 0.0
@export var sky_light_scale: float = 1.0
@export var top_blur_add: float = 0.0
@export_group("Dedans")
## Facteur de la lumière des fenêtres (soleil d'un intérieur) par ce temps.
@export var window_light_scale: float = 1.0


## Temps id (data/lighting/<id>.tres), null pour « clair » ou un temps inconnu.
static func preset(id: StringName) -> HD2DWeather:
	if not HD2DLighting.has_preset(id):
		return null
	return load(HD2DLighting.preset_path(id)) as HD2DWeather


## Le préréglage base sous ce temps (nouvelle ressource ; base ne change pas). outdoors : la
## carte est dehors (pluie, sol mouillé, ciel) ; dedans, seule la lumière des fenêtres change.
func applied_to(base: HD2DLighting, outdoors: bool) -> HD2DLighting:
	var result := base.copy()
	if not outdoors:
		result.sun_energy = base.sun_energy * window_light_scale
		result.sun_color = base.sun_color.lerp(grey, grey_amount * 0.5)
		return result
	result.rain = rain
	result.wetness = wetness
	if sky_texture != null and sky_amount >= 0.5:
		result.sky_texture = sky_texture
	result.sun_energy = base.sun_energy * sun_scale
	result.sun_color = base.sun_color.lerp(grey, grey_amount)
	result.ambient_energy = base.ambient_energy * ambient_scale
	result.ambient_color = base.ambient_color.lerp(grey, grey_amount)
	result.sky_tint = base.sky_tint * sky_tint
	result.clouds_tint = base.clouds_tint * clouds_tint
	result.clouds_warm = base.clouds_warm.lerp(grey, grey_amount)
	result.lamp_energy = base.lamp_energy * lamp_scale
	result.window_glow = base.window_glow * lamp_scale
	result.sprite_tint = base.sprite_tint * sprite_tint
	result.fog_density = base.fog_density + fog_add
	result.fog_color = base.fog_color.lerp(fog_color, fog_mix)
	result.saturation = base.saturation * saturation_scale
	result.contrast = base.contrast * contrast_scale
	result.vignette = base.vignette + vignette_add
	result.haze_color = base.haze_color.lerp(haze_color, haze_mix)
	result.haze_strength = base.haze_strength + haze_add
	result.highlight_tint = base.highlight_tint.lerp(grey, grey_amount)
	result.sky_light_strength = base.sky_light_strength * sky_light_scale
	result.top_blur_px = base.top_blur_px + top_blur_add
	return result
