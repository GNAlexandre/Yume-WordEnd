class_name AtmosphereRig
extends Node3D
## (E9) Ce que la lumière ajoute à la carte courante, posé par Atmosphere (src/autoload/
## atmosphere.gd) comme enfant « AtmosphereRig » de la carte (libéré avec elle) :
## - si la carte n'a pas les siens : un WorldEnvironment (ciel peint, ambiance, brouillard :
##   (R1) dans une carte intérieure, fond uni InteriorRoom.VOID_COLOR) et
##   un soleil (« Sun », DirectionalLight3D sans ombre ; dedans, la lumière d'ensemble des
##   fenêtres). Les cartes ne portent plus leur lumière (anciens src/world/map_light.tscn et
##   interior_light.tscn) ; une carte qui a les siens les garde, réglés de même ;
## - la lumière magique du joueur (V1, « L'Homme sans Marque » : les fées allument une petite
##   lumière dans la main) : PlayerLight (OmniLight3D douce) et Orb (l'orbe, bande animée
##   assets/hd2d/anim/fairy_light.png), à côté du joueur (groupe « player »), la nuit dehors ;
## - la pluie : Rain (RainFall : gouttes et éclaboussures dans le monde) et RainCurtain
##   (CanvasLayer 0, au-dessus du post-traitement et sous l'interface : le rideau de pluie à
##   l'écran, rain_curtain.gdshader).
## - (RD) le soleil des ombres peintes des décors (DecorPanel.set_shadow_sun) : leur traîne part à
##   l'opposé du soleil (ou de la lune), d'autant plus longue qu'il est bas ; plus pâle la nuit et
##   sous la pluie, nulle dans un intérieur (le cœur au pied, l'occlusion, reste).
## Ses lumières et ses meshes sont dans le groupe HD2DLightTargets.IGNORE_GROUP : le relevé des
## lanternes et des matériaux de la carte les ignore.

const NODE_NAME := &"AtmosphereRig"
const SKY_SHADER := preload("res://src/world/shaders/sky.gdshader")
const CURTAIN_SHADER := preload("res://src/world/shaders/rain_curtain.gdshader")
const ORB_TEXTURE := preload("res://assets/hd2d/anim/fairy_light.png")
const DRIZZLE_TEXTURE := preload("res://assets/hd2d/anim/rain_drizzle.png")
const CURTAIN_TEXTURE := preload("res://assets/hd2d/anim/rain_curtain.png")
## Bandes animées : images et cadences (cahier n° 3, section 8.3 et 8.5).
const ORB_FRAMES := 4
const ORB_FPS := 6.0
const CURTAIN_FRAMES := 4
const DRIZZLE_FPS := 10.0
const CURTAIN_FPS := 12.0
## Couche du rideau de pluie : au-dessus du post-traitement (−1), sous l'interface (1).
const CURTAIN_LAYER := 0
## Soleil d'une carte sans le sien : hauteur d'où il éclaire (m).
const SUN_HEIGHT := 40.0
## Taille d'un pixel de l'orbe (m) : un peu plus grande que le décor, pour qu'elle se voie.
const ORB_PIXEL_SIZE := 1.0 / 64.0
## Opacité du rideau à l'averse : il double les gouttes du monde, il ne les cache pas.
const CURTAIN_OPACITY := 0.8
## (RD) Hauteur du soleil (degrés) où la traîne des ombres a sa longueur de référence, et bornes de
## son allongement ; part de la traîne et du cœur qui reste la nuit noire, sous l'averse.
const SHADOW_REFERENCE_ELEVATION := 20.0
const SHADOW_LENGTH_RANGE := Vector2(0.3, 1.8)
const SHADOW_NIGHT_TAIL := 0.35
const SHADOW_NIGHT_CORE := 0.75
const SHADOW_RAIN_TAIL := 0.25

## Lumière du joueur : énergie et portée à pleine force, couleur (blanc bleuté de l'orbe),
## hauteur (m, la main levée) et écart de côté (m, vers où il regarde).
var light_energy: float = 1.5
var light_range: float = 7.5
var light_color: Color = Color(0.8, 0.88, 1.0)
var light_height: float = 1.25
var light_side: float = 0.35

var player_light: OmniLight3D
var orb: Sprite3D
var rain: RainFall
var curtain_layer: CanvasLayer
var curtain: ColorRect

var _curtain_material: ShaderMaterial
## (RD) Carte intérieure : pas de traîne d'ombre (la lumière vient des fenêtres et des lampes).
var _interior: bool = false
var _light_amount: float = 0.0
var _rain_amount: float = 0.0
var _time: float = 0.0


## Le rig de la carte (créé s'il n'y est pas encore).
static func dress(map: Node) -> AtmosphereRig:
	var rig := map.get_node_or_null(NodePath(String(NODE_NAME))) as AtmosphereRig
	if rig != null and not rig.is_queued_for_deletion():
		return rig
	rig = AtmosphereRig.new()
	rig.name = NODE_NAME
	rig.setup(map)
	map.add_child(rig)
	return rig


## Crée les nœuds ; un environnement et un soleil seulement si la carte n'en a pas.
func setup(map: Node) -> void:
	_interior = map is Map and (map as Map).interior
	if map.find_children("*", "WorldEnvironment", true, false).is_empty():
		add_child(_make_environment(map is Map and (map as Map).interior))
	if map.find_children("*", "DirectionalLight3D", true, false).is_empty():
		add_child(_make_sun())
	player_light = OmniLight3D.new()
	player_light.name = &"PlayerLight"
	player_light.top_level = true
	player_light.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	player_light.shadow_enabled = false
	player_light.light_specular = 0.3
	player_light.visible = false
	player_light.add_to_group(HD2DLightTargets.IGNORE_GROUP)
	add_child(player_light)
	orb = Sprite3D.new()
	orb.name = &"Orb"
	orb.texture = ORB_TEXTURE
	orb.hframes = ORB_FRAMES
	orb.pixel_size = ORB_PIXEL_SIZE
	orb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	orb.shaded = false
	orb.transparent = true
	orb.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	orb.top_level = true
	orb.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	orb.visible = false
	orb.add_to_group(HD2DLightTargets.IGNORE_GROUP)
	add_child(orb)
	rain = RainFall.new()
	rain.name = &"Rain"
	rain.add_to_group(HD2DLightTargets.IGNORE_GROUP)
	add_child(rain)
	curtain_layer = CanvasLayer.new()
	curtain_layer.name = &"RainCurtain"
	curtain_layer.layer = CURTAIN_LAYER
	curtain_layer.visible = false
	curtain = ColorRect.new()
	curtain.name = &"Screen"
	curtain.set_anchors_preset(Control.PRESET_FULL_RECT)
	curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_curtain_material = ShaderMaterial.new()
	_curtain_material.shader = CURTAIN_SHADER
	_curtain_material.set_shader_parameter(&"strip", DRIZZLE_TEXTURE)
	_curtain_material.set_shader_parameter(&"strip_heavy", CURTAIN_TEXTURE)
	_curtain_material.set_shader_parameter(&"frames", float(CURTAIN_FRAMES))
	_curtain_material.set_shader_parameter(&"fps", DRIZZLE_FPS)
	_curtain_material.set_shader_parameter(&"fps_heavy", CURTAIN_FPS)
	curtain.material = _curtain_material
	curtain_layer.add_child(curtain)
	add_child(curtain_layer)


## Pose la part du réglage qui revient au rig : lumière du joueur (light_part, 0..1 : déjà
## multipliée par le préréglage et le choix d'Atmosphere) et pluie.
func apply(lighting: HD2DLighting, light_part: float) -> void:
	_light_amount = clampf(light_part, 0.0, 1.0)
	var lit := _light_amount > 0.01
	player_light.visible = lit
	orb.visible = lit
	player_light.light_energy = light_energy * _light_amount
	player_light.omni_range = light_range
	player_light.light_color = light_color
	orb.modulate = Color(1.0, 1.0, 1.0, _light_amount)
	_rain_amount = lighting.rain
	rain.intensity = lighting.rain
	rain.tint = Color(lighting.ambient_color.lerp(Color(0.86, 0.9, 0.98), 0.6), 0.75)
	curtain_layer.visible = lighting.rain > 0.01
	_curtain_material.set_shader_parameter(&"intensity", lighting.rain * CURTAIN_OPACITY)
	_curtain_material.set_shader_parameter(&"heavy", smoothstep(0.45, 0.9, lighting.rain))
	set_process(lit or curtain_layer.visible)
	if lit:
		_follow_player()
	apply_shadow_sun(lighting, _interior)


## (RD) Pose le soleil d'un réglage sur les ombres peintes des décors : direction opposée au soleil
## dans le plan du sol, allongement (tan 20° / tan hauteur, borné), force de la traîne (plus pâle
## la nuit et sous la pluie, nulle dedans) et du cœur.
static func apply_shadow_sun(lighting: HD2DLighting, interior: bool = false) -> void:
	var toward := lighting.toward_sun()
	var elevation := deg_to_rad(clampf(lighting.sun_elevation_deg, 3.0, 85.0))
	var length := clampf(
		tan(deg_to_rad(SHADOW_REFERENCE_ELEVATION)) / tan(elevation),
		SHADOW_LENGTH_RANGE.x,
		SHADOW_LENGTH_RANGE.y
	)
	var tail := lerpf(1.0, SHADOW_NIGHT_TAIL, lighting.night_amount)
	tail *= lerpf(1.0, SHADOW_RAIN_TAIL, lighting.rain)
	if interior:
		tail = 0.0
	var core := lerpf(1.0, SHADOW_NIGHT_CORE, lighting.night_amount)
	DecorPanel.set_shadow_sun(Vector2(-toward.x, -toward.z), length, tail, core)


## Part de la lumière du joueur posée en dernier (0 : éteinte).
func light_amount() -> float:
	return _light_amount if player_light.visible else 0.0


## Vrai si la pluie tombe (gouttes, rideau).
func is_raining() -> bool:
	return rain.is_raining()


func _process(delta: float) -> void:
	_time += delta
	if curtain_layer.visible:
		_curtain_material.set_shader_parameter(&"rain_time", _time)
	if orb.visible:
		orb.frame = int(_time * ORB_FPS) % ORB_FRAMES
		_follow_player()


## Lumière et orbe à côté du joueur, à sa place affichée, du côté où il regarde ; l'orbe
## flotte un peu.
func _follow_player() -> void:
	var player := get_tree().get_first_node_in_group(DecorPanel.PLAYER_GROUP) as Node3D
	if player == null:
		return
	var feet := DecorPanel.displayed_transform(player).origin
	var side := 1.0
	if player.has_method(&"aim_direction"):
		var aim: Vector3 = player.call(&"aim_direction")
		side = -1.0 if aim.x < -0.1 else 1.0
	var hand := feet + Vector3(side * light_side, light_height, 0.12)
	orb.global_position = hand + Vector3.UP * 0.06 * sin(_time * 2.2)
	player_light.global_position = hand + Vector3.UP * 0.25


## Environnement d'une carte : le ciel peint dehors ; (R1) dedans, un fond uni, celui du vide
## autour du bâtiment (InteriorRoom.VOID_COLOR) : aucun ciel ne se voit, rien à dessiner.
func _make_environment(interior: bool) -> WorldEnvironment:
	var sky_material := ShaderMaterial.new()
	sky_material.shader = SKY_SHADER
	var sky := Sky.new()
	sky.sky_material = sky_material
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	if interior:
		environment.background_mode = Environment.BG_COLOR
		environment.background_color = InteriorRoom.VOID_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.fog_enabled = true
	environment.fog_sun_scatter = 0.2
	environment.fog_sky_affect = 0.0
	environment.fog_height = -8.0
	environment.fog_height_density = 0.015
	var world := WorldEnvironment.new()
	world.name = &"WorldEnvironment"
	world.environment = environment
	return world


func _make_sun() -> DirectionalLight3D:
	var sun := DirectionalLight3D.new()
	sun.name = &"Sun"
	sun.shadow_enabled = false
	sun.position = Vector3.UP * SUN_HEIGHT
	return sun
