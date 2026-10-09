class_name HD2DLightTargets
extends RefCounted
## (E9) Ce que la lumière règle dans une carte, relevé une fois (scan) puis réglé à chaque
## préréglage ou image d'une transition (apply) :
## - l'environnement (WorldEnvironment de la carte, ou celui d'AtmosphereRig) : ambiance,
##   brouillard, et le ciel, remplacé par src/world/shaders/sky.gdshader (deux panoramas qui se
##   fondent) ; l'environnement est copié, la scène ne change pas ;
## - le soleil (première DirectionalLight3D) ;
## - les mers de nuages (matériaux de cloud_sea.gdshader, copiés) : teinte, côté du soleil,
##   image ;
## - les lumières ponctuelles (OmniLight3D, SpotLight3D) : énergie de départ × lamp_energy ;
## - les matériaux des décors (ShaderMaterial des panneaux, bâtiments, sol, roche) :
##   - glow_strength (lueur des fenêtres et des cristaux) : valeur de départ × window_glow ;
##   - hd2d_wetness (hd2d_light.gdshaderinc) : wetness ; un StandardMaterial3D mouillé devient
##     un peu brillant (rugosité, spéculaire) ;
##   - images de nuit (format confirmé du cahier n° 3, section 8.4) : si l'image d'un matériau
##     (albedo_texture) <dossier>/<nom>.png a une sœur <dossier>/<nom>_night.png, celle-ci la
##     remplace quand night_amount ≥ HD2DLighting.NIGHT_IMAGES_FROM (fenêtres de nuit des
##     intérieurs, au même cadrage) ; une vitre éclairée (image window_lit_*, posée sur une
##     fenêtre de jour) ne se montre que la nuit (alpha_cut au-delà de 1 le jour).
## Les matériaux des décors sont partagés entre les cartes (caches de DecorPanel, Building,
## GroundDecal) : leur valeur de départ est gardée en méta, chaque carte les règle à son entrée.
## Les nœuds du groupe IGNORE_GROUP (la lumière du joueur d'AtmosphereRig) ne sont pas relevés.

const SKY_SHADER := preload("res://src/world/shaders/sky.gdshader")
const CLOUD_SEA_SHADER := preload("res://src/world/shaders/cloud_sea.gdshader")
## Nœuds que le relevé ignore (lumières propres d'AtmosphereRig).
const IGNORE_GROUP := &"atmosphere_rig"
## Métas des matériaux : lueur, image de jour, seuil d'alpha, rugosité et spéculaire de départ.
const BASE_GLOW_META := &"hd2d_base_glow"
const DAY_TEXTURE_META := &"hd2d_day_texture"
const BASE_ALPHA_CUT_META := &"hd2d_base_alpha_cut"
const DRY_ROUGHNESS_META := &"hd2d_dry_roughness"
const DRY_SPECULAR_META := &"hd2d_dry_specular"
## Suffixe des images de nuit et préfixe des vitres éclairées (cahier n° 3, section 8.4).
const NIGHT_SUFFIX := "_night"
const LIT_PREFIX := "window_lit_"
## alpha_cut d'une vitre éclairée le jour : rien ne passe.
const HIDDEN_ALPHA_CUT := 1.01
## Un StandardMaterial3D trempé : rugosité et spéculaire.
const WET_ROUGHNESS := 0.3
const WET_SPECULAR := 0.6

var world: WorldEnvironment
var environment: Environment
var sky_material: ShaderMaterial
var sun: DirectionalLight3D
var clouds: Array[ShaderMaterial] = []
var lamps: Array[Light3D] = []
var glow_materials: Array[ShaderMaterial] = []
var wet_materials: Array[ShaderMaterial] = []
var wet_standard: Array[BaseMaterial3D] = []
## Matériaux qui ont une image de nuit, et leurs images de nuit (même ordre).
var night_materials: Array[ShaderMaterial] = []
var night_images: Array[Texture2D] = []
var lit_materials: Array[ShaderMaterial] = []

## Dernières valeurs posées (on ne repose pas ce qui n'a pas changé).
var _glow: float = -1.0
var _wetness: float = -1.0
var _night: int = -1


## Relève ce que la lumière règle dans map (et ses descendants).
static func scan(map: Node) -> HD2DLightTargets:
	var targets := HD2DLightTargets.new()
	targets._scan(map)
	return targets


## Nombre de matériaux et de lumières réglés (mesures, tests).
func counts() -> Dictionary:
	return {
		"clouds": clouds.size(),
		"lamps": lamps.size(),
		"glow": glow_materials.size(),
		"wet": wet_materials.size() + wet_standard.size(),
		"night": night_materials.size(),
		"lit": lit_materials.size(),
	}


## Pose le réglage. sky_from : panorama de départ d'une transition (null : aucun), qui se fond
## dans celui du réglage selon mix (0..1) ; clouds_from de même pour la mer de nuages.
func apply(
	lighting: HD2DLighting,
	sky_from: Texture2D = null,
	mix: float = 1.0,
	clouds_from: Texture2D = null
) -> void:
	HD2DLighting.set_active_sprite_tint(lighting.sprite_tint)
	if environment != null:
		environment.ambient_light_color = lighting.ambient_color
		environment.ambient_light_energy = lighting.ambient_energy
		environment.fog_light_color = lighting.fog_color
		environment.fog_density = lighting.fog_density
	if sky_material != null:
		var image := lighting.sky_image()
		sky_material.set_shader_parameter(&"panorama", image)
		var from := sky_from if sky_from != null else image
		sky_material.set_shader_parameter(&"panorama_from", from)
		sky_material.set_shader_parameter(&"blend", mix if from != image else 1.0)
		sky_material.set_shader_parameter(&"tint", lighting.sky_tint)
		sky_material.set_shader_parameter(&"energy", lighting.sky_energy)
	if is_instance_valid(sun):
		sun.light_color = lighting.sun_color
		sun.light_energy = lighting.sun_energy
		if sun.is_inside_tree():
			sun.global_basis = lighting.sun_basis()
		else:
			sun.basis = lighting.sun_basis()
	_apply_clouds(lighting, clouds_from, mix)
	for lamp: Light3D in lamps:
		if is_instance_valid(lamp):
			lamp.light_energy = float(lamp.get_meta(HD2DLighting.BASE_ENERGY_META)) * lighting.lamp_energy
	_apply_materials(lighting)


func _apply_clouds(lighting: HD2DLighting, clouds_from: Texture2D, mix: float) -> void:
	var flat := Vector2(lighting.toward_sun().x, lighting.toward_sun().z)
	for material: ShaderMaterial in clouds:
		material.set_shader_parameter(&"tint", lighting.clouds_tint)
		material.set_shader_parameter(&"warm", lighting.clouds_warm)
		if flat.length() > 0.01:
			material.set_shader_parameter(&"sun_direction", flat.normalized())
		var base := material.get_meta(DAY_TEXTURE_META) as Texture2D
		var image := lighting.clouds_texture if lighting.clouds_texture != null else base
		var from := clouds_from if clouds_from != null else image
		if from == image or mix >= 1.0:
			material.set_shader_parameter(&"clouds", image)
			material.set_shader_parameter(&"clouds_mix", 0.0)
		else:
			material.set_shader_parameter(&"clouds", from)
			material.set_shader_parameter(&"clouds_next", image)
			material.set_shader_parameter(&"clouds_mix", mix)


func _apply_materials(lighting: HD2DLighting) -> void:
	if not is_equal_approx(_glow, lighting.window_glow):
		_glow = lighting.window_glow
		for material: ShaderMaterial in glow_materials:
			var base := float(material.get_meta(BASE_GLOW_META))
			material.set_shader_parameter(&"glow_strength", base * lighting.window_glow)
	if absf(_wetness - lighting.wetness) > 0.002:
		_wetness = lighting.wetness
		for material: ShaderMaterial in wet_materials:
			material.set_shader_parameter(&"hd2d_wetness", lighting.wetness)
		for material: BaseMaterial3D in wet_standard:
			var dry_roughness := float(material.get_meta(DRY_ROUGHNESS_META))
			var dry_specular := float(material.get_meta(DRY_SPECULAR_META))
			material.roughness = lerpf(dry_roughness, WET_ROUGHNESS, lighting.wetness)
			material.metallic_specular = lerpf(dry_specular, WET_SPECULAR, lighting.wetness)
	var night := 1 if lighting.uses_night_images() else 0
	if night != _night:
		_night = night
		for i in night_materials.size():
			var material := night_materials[i]
			var day := material.get_meta(DAY_TEXTURE_META) as Texture2D
			material.set_shader_parameter(&"albedo_texture", night_images[i] if night else day)
		for material: ShaderMaterial in lit_materials:
			var cut := float(material.get_meta(BASE_ALPHA_CUT_META))
			material.set_shader_parameter(&"alpha_cut", cut if night else HIDDEN_ALPHA_CUT)


# --- Relevé -----------------------------------------------------------------------------------


func _scan(map: Node) -> void:
	for node: Node in map.find_children("*", "WorldEnvironment", true, false):
		if not node.is_in_group(IGNORE_GROUP):
			_take_environment(node as WorldEnvironment)
			break
	for node: Node in map.find_children("*", "DirectionalLight3D", true, false):
		if not node.is_in_group(IGNORE_GROUP):
			sun = node as DirectionalLight3D
			break
	for node: Node in map.find_children("*", "Light3D", true, false):
		if node is DirectionalLight3D or node.is_in_group(IGNORE_GROUP):
			continue
		var lamp := node as Light3D
		if not lamp.has_meta(HD2DLighting.BASE_ENERGY_META):
			lamp.set_meta(HD2DLighting.BASE_ENERGY_META, lamp.light_energy)
		lamps.append(lamp)
	var materials: Dictionary = {}
	var uniforms: Dictionary = {}
	var exists: Dictionary = {}
	for node: Node in map.find_children("*", "GeometryInstance3D", true, false):
		if node.is_in_group(IGNORE_GROUP):
			continue
		var instance := node as GeometryInstance3D
		var mesh_instance := instance as MeshInstance3D
		if mesh_instance != null and _is_cloud_sea(mesh_instance):
			_take_clouds(mesh_instance)
			continue
		for material: Material in _materials_of(instance):
			if materials.has(material):
				continue
			materials[material] = true
			_sort(material, uniforms, exists)


func _take_environment(node: WorldEnvironment) -> void:
	if node.environment == null:
		return
	world = node
	node.environment = HD2DLighting.own(node.environment, true) as Environment
	environment = node.environment
	if environment.sky == null:
		environment.sky = Sky.new()
	var old := environment.sky.sky_material
	if old is ShaderMaterial and (old as ShaderMaterial).shader == SKY_SHADER:
		sky_material = old as ShaderMaterial
		return
	sky_material = ShaderMaterial.new()
	sky_material.shader = SKY_SHADER
	var panorama: Texture2D = null
	if old is PanoramaSkyMaterial:
		panorama = (old as PanoramaSkyMaterial).panorama
	if panorama != null:
		sky_material.set_shader_parameter(&"panorama", panorama)
		sky_material.set_shader_parameter(&"panorama_from", panorama)
	environment.sky.sky_material = sky_material


static func _is_cloud_sea(instance: MeshInstance3D) -> bool:
	if instance.mesh == null or instance.mesh.get_surface_count() == 0:
		return false
	var material := instance.get_active_material(0) as ShaderMaterial
	return material != null and material.shader == CLOUD_SEA_SHADER


func _take_clouds(instance: MeshInstance3D) -> void:
	var material := HD2DLighting.own(instance.get_active_material(0), false) as ShaderMaterial
	instance.material_override = material
	if not material.has_meta(DAY_TEXTURE_META):
		material.set_meta(DAY_TEXTURE_META, material.get_shader_parameter(&"clouds"))
	clouds.append(material)


## Matériaux d'une instance : override, overlay, ceux des surfaces (et de leur override).
static func _materials_of(instance: GeometryInstance3D) -> Array[Material]:
	var result: Array[Material] = []
	if instance.material_override != null:
		result.append(instance.material_override)
	if instance.material_overlay != null:
		result.append(instance.material_overlay)
	var mesh_instance := instance as MeshInstance3D
	if mesh_instance != null and mesh_instance.mesh != null:
		for surface in mesh_instance.mesh.get_surface_count():
			var material := mesh_instance.get_surface_override_material(surface)
			if material == null:
				material = mesh_instance.mesh.surface_get_material(surface)
			if material != null:
				result.append(material)
	return result


## Range un matériau dans les listes qui le concernent (uniforms : noms des uniformes de chaque
## shader ; exists : images de nuit déjà cherchées).
func _sort(material: Material, uniforms: Dictionary, exists: Dictionary) -> void:
	var standard := material as BaseMaterial3D
	if standard != null:
		if standard.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED:
			if not standard.has_meta(DRY_ROUGHNESS_META):
				standard.set_meta(DRY_ROUGHNESS_META, standard.roughness)
				standard.set_meta(DRY_SPECULAR_META, standard.metallic_specular)
			wet_standard.append(standard)
		return
	var shader_material := material as ShaderMaterial
	if shader_material == null or shader_material.shader == null:
		return
	var names := _uniform_names(shader_material.shader, uniforms)
	if names.has(&"hd2d_wetness"):
		wet_materials.append(shader_material)
	if names.has(&"glow_strength"):
		if not shader_material.has_meta(BASE_GLOW_META):
			var glow: Variant = shader_material.get_shader_parameter(&"glow_strength")
			shader_material.set_meta(BASE_GLOW_META, float(glow) if glow != null else 0.0)
		if float(shader_material.get_meta(BASE_GLOW_META)) > 0.0:
			glow_materials.append(shader_material)
	if names.has(&"albedo_texture"):
		_sort_image(shader_material, names, exists)


func _sort_image(material: ShaderMaterial, names: Dictionary, exists: Dictionary) -> void:
	var day: Texture2D = null
	if material.has_meta(DAY_TEXTURE_META):
		day = material.get_meta(DAY_TEXTURE_META) as Texture2D
	else:
		day = material.get_shader_parameter(&"albedo_texture") as Texture2D
	if day == null or day.resource_path.is_empty():
		return
	var path := day.resource_path
	if path.get_file().begins_with(LIT_PREFIX) and names.has(&"alpha_cut"):
		if not material.has_meta(BASE_ALPHA_CUT_META):
			var cut: Variant = material.get_shader_parameter(&"alpha_cut")
			material.set_meta(BASE_ALPHA_CUT_META, float(cut) if cut != null else 0.5)
		lit_materials.append(material)
		return
	var night_path := "%s%s.%s" % [path.get_basename(), NIGHT_SUFFIX, path.get_extension()]
	if not exists.has(night_path):
		exists[night_path] = ResourceLoader.exists(night_path)
	if exists[night_path]:
		material.set_meta(DAY_TEXTURE_META, day)
		night_materials.append(material)
		night_images.append(load(night_path) as Texture2D)


static func _uniform_names(shader: Shader, cache: Dictionary) -> Dictionary:
	if cache.has(shader):
		return cache[shader]
	var names := {}
	for info: Dictionary in shader.get_shader_uniform_list():
		names[StringName(info["name"])] = true
	cache[shader] = names
	return names
