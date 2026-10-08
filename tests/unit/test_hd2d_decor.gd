extends GutTest
## (HD-2D) Le décor de l'île en images : chaque décor de src/world/props/ est un panneau
## (DecorPanel) ou un bâtiment (Building) dont l'image est à 96 px par mètre ; ce qui bloque garde
## sa collision (couche 1) ; les bâtiments ont une façade à la taille de leur mur et une collision
## qui couvre leur emprise ; dans l'île, les décors sont fondus par image ; les shaders du monde et
## du post-traitement compilent ; (H5) les images du monde sont filtrées (pixel art net de près,
## sans moiré au loin) et le sol lit un atlas à mipmaps qui ne mélangent pas ses tuiles. Les places
## de HISTOIRE.md 3.3 restent vérifiées par test_world_story_spots.gd. (H9) Un décor peut aussi être
## un décalque au sol (GroundDecal, sans collision) ou un panneau animé (une image de la bande) ;
## les formats eux-mêmes sont vérifiés par test_hd2d_formats.gd.

const PROPS_DIR := "res://src/world/props"
const FIXTURE := preload("res://tests/stubs/l2_island_fixture.gd")
const TERRAIN_MATERIAL := "res://src/world/materials/terrain.tres"
const POST_SHADER := preload("res://src/player/post_fx.gdshader")
## Décors qu'on traverse (fleurs, herbes, objets au sol, décor lointain, la cloche gérée par
## arena.tscn) : sans collision, comme avant le passage au HD-2D.
const NON_BLOCKING: Array[String] = [
	"airship_barocupot",
	"airship_ferry",
	"ball",
	"bench",
	"berry_bush",
	"bush",
	"distant_island_a",
	"distant_island_b",
	"distant_island_c",
	"fallen_lantern",
	"floating_rock",
	"flower_bed",
	"grass_tuft",
	"mushroom",
	"myosotis",
	"reeds",
	"ring_stone",
	"tall_grass",
	"vegetable_patch",
	"vigil_bell",
]
## Images (matériaux) au plus par zone : un draw call par image et par case visible ; les vues
## mesurées restent sous 75 draw calls (tests/integration/demo_hd2d.gd, budget : 200). (P0) 44 au
## port avec les flancs des bâtiments et les hélices des navires.
const MAX_IMAGES_PER_ZONE := 48
## (P0) Métadonnée des scènes du cahier n° 2 (tools/hd2d_scenes.py) : leur collision et leur
## densité suivent leur catégorie et le manifeste, vérifiées par test_hd2d_scenes.gd.
const SCENES_META := &"hd2d_category"
const SHADERS: Array[String] = [
	"res://src/world/shaders/panel.gdshader",
	"res://src/world/shaders/terrain.gdshader",
	"res://src/world/shaders/rock.gdshader",
	"res://src/world/shaders/cloud_sea.gdshader",
	"res://src/world/shaders/waterfall.gdshader",
	"res://src/player/post_fx.gdshader",
	"res://src/world/shaders/panel_foreground.gdshader",
	"res://src/world/shaders/ground_decal.gdshader",
	"res://src/world/shaders/ground_decal_soft.gdshader",
	"res://src/world/shaders/sky_drift.gdshader",
	"res://src/world/shaders/ambient_sprites.gdshader",
]


func _props() -> Array[String]:
	var names: Array[String] = []
	for file_name: String in ResourceLoader.list_directory(PROPS_DIR):
		if file_name.ends_with(".tscn"):
			names.append(file_name.get_basename())
	return names


func _instance(prop: String) -> Node3D:
	var node := (load("%s/%s.tscn" % [PROPS_DIR, prop]) as PackedScene).instantiate() as Node3D
	add_child(node)
	return node


## Panneaux, bâtiments et (H9) décalques d'un décor (la racine, ou ses enfants pour un décor
## composé).
func _parts(node: Node) -> Array[Node]:
	var parts: Array[Node] = []
	if _is_part(node):
		parts.append(node)
	for child: Node in node.get_children():
		if _is_part(child):
			parts.append(child)
	return parts


func _is_part(node: Node) -> bool:
	return node is DecorPanel or node is Building or node is GroundDecal


func test_every_prop_is_a_panel_or_a_building() -> void:
	var props := _props()
	assert_gt(props.size(), 60, "les décors de l'acte 1")
	for prop in props:
		var node := _instance(prop)
		var parts := _parts(node)
		assert_false(parts.is_empty(), "%s : panneau ou bâtiment" % prop)
		for part in parts:
			if part is DecorPanel:
				assert_not_null((part as DecorPanel).texture, "%s : image" % prop)
			elif part is GroundDecal:
				assert_not_null((part as GroundDecal).texture, "%s : image" % prop)
			else:
				var building := part as Building
				assert_true(
					building.wall_texture != null and building.roof_texture != null,
					"%s : matières du volume" % prop
				)
		var meshes := node.find_children("*", "MeshInstance3D", true, false)
		for mesh: Node in meshes:
			assert_true(
				_is_part(mesh.get_parent()),
				"%s : aucun maillage 3D hors des panneaux (%s)" % [prop, mesh.name]
			)
		node.free()


func test_blocking_decor_keeps_its_collision() -> void:
	for prop in _props():
		var node := _instance(prop)
		var body := node.get_node_or_null(^"Collision") as StaticBody3D
		if node.has_meta(SCENES_META):
			node.free()
			continue
		if prop in NON_BLOCKING or node is GroundDecal:
			assert_null(body, "%s : se traverse" % prop)
		else:
			assert_not_null(body, "%s : collision" % prop)
			if body != null:
				assert_eq(body.collision_layer, 1, "%s : couche world" % prop)
				var shapes := body.find_children("*", "CollisionShape3D", false, false)
				assert_false(shapes.is_empty(), "%s : au moins une forme" % prop)
				for shape: Node in shapes:
					assert_not_null((shape as CollisionShape3D).shape, "%s : forme" % prop)
		node.free()


func test_panels_are_sized_from_their_image() -> void:
	for prop in _props():
		var node := _instance(prop)
		for part in _parts(node):
			var panel := part as DecorPanel
			if panel == null or panel.texture == null:
				continue
			var image := Vector2(panel.texture.get_size()) / Vector2(panel.frames, 1.0)
			var want := image / panel.pixels_per_meter
			assert_almost_eq(panel.size_m(), want, Vector2.ONE * 0.001, prop)
			var quad := panel.get_child(0, true) as MeshInstance3D
			var aabb := quad.mesh.get_aabb()
			assert_almost_eq(Vector2(aabb.size.x, aabb.size.y), want, Vector2.ONE * 0.001, prop)
			assert_true(
				(
					panel.pixels_per_meter == DecorPanel.PIXELS_PER_METER
					or prop.contains("island")
					or prop.contains("airship")
					or prop.contains("floating")
					or node.has_meta(SCENES_META)
				),
				"%s : 96 px par mètre (décor lointain à part)" % prop
			)
		node.free()


func test_buildings_match_their_facade_and_collision() -> void:
	var found := 0
	for prop in _props():
		var node := _instance(prop)
		for part in _parts(node):
			var building := part as Building
			if building == null or building.facade == null:
				continue
			found += 1
			var facade := Vector2(building.facade.get_size()) / DecorPanel.PIXELS_PER_METER
			assert_almost_eq(facade.x, building.footprint.x, 0.02, "%s : largeur" % prop)
			var top := building.ridge_height if building.gable_front else building.wall_height
			assert_almost_eq(facade.y, top, 0.03, "%s : hauteur de la façade" % prop)
			var body := node.get_node_or_null(^"Collision") as StaticBody3D
			var covered := Vector2.ZERO
			for shape: Node in body.find_children("*", "CollisionShape3D", false, false):
				var box := (shape as CollisionShape3D).shape as BoxShape3D
				if box != null:
					covered = covered.max(Vector2(box.size.x, box.size.z))
			assert_almost_eq(covered, building.footprint, Vector2.ONE * 0.05, "%s : emprise" % prop)
		node.free()
	assert_gte(found, 9, "les bâtiments de l'entrepôt et du port")


func test_island_decor_is_batched_by_image() -> void:
	var island := FIXTURE.island()
	add_child(island)
	await wait_process_frames(1)
	for zone: Node in island.get_node(^"Zones").get_children():
		var geometry := zone.get_node(^"Geometry")
		var batches := 0
		var images := {}
		for child: Node in geometry.get_children():
			if child is MeshInstance3D and String(child.name).begins_with("Batch"):
				batches += 1
				images[(child as MeshInstance3D).material_override] = true
		assert_gt(batches, 0, "%s : décor fondu" % zone.name)
		assert_lte(
			images.size(), MAX_IMAGES_PER_ZONE, "%s : %d images" % [zone.name, images.size()]
		)
		var loose := 0
		for mesh: Node in geometry.find_children("*", "MeshInstance3D", true, false):
			var instance := mesh as MeshInstance3D
			if instance.is_visible_in_tree() and not String(instance.name).begins_with("Batch"):
				loose += 1
		assert_eq(loose, 0, "%s : aucun panneau oublié par le PropBatcher" % zone.name)
	island.free()


func test_world_and_post_shaders_compile() -> void:
	for path in SHADERS:
		var shader := load(path) as Shader
		assert_not_null(shader, path)
		if shader != null:
			# Un shader qui ne compile pas n'expose aucun uniforme (et écrit SHADER ERROR).
			assert_gt(shader.get_shader_uniform_list().size(), 0, "%s compile" % path)
	var terrain := load(TERRAIN_MATERIAL) as ShaderMaterial
	assert_not_null(terrain.get_shader_parameter(&"ground_atlas"), "atlas du sol branché")
	var rock := load("res://src/world/materials/rock.tres") as ShaderMaterial
	for texture: StringName in [&"lip_texture", &"cliff_texture", &"underside_texture"]:
		assert_not_null(rock.get_shader_parameter(texture), "roche : %s" % texture)


# --- (H5) Filtrage du pixel art : ni moiré ni scintillement -----------------------------------


func test_world_images_are_filtered_not_point_sampled() -> void:
	# Au plus proche voisin et sans mipmaps, des images plus denses que l'écran (96 px par mètre)
	# font du moiré au loin et scintillent quand la caméra glisse.
	for path: String in [
		"res://src/world/shaders/panel.gdshader",
		"res://src/world/shaders/rock.gdshader",
	]:
		var code := (load(path) as Shader).code
		assert_string_contains(code, "pixel_art.gdshaderinc", path)
		assert_false(code.contains("filter_nearest"), "%s : images filtrées" % path)
	var terrain := (load("res://src/world/shaders/terrain.gdshader") as Shader).code
	assert_string_contains(terrain, "filter_linear_mipmap", "sol : mipmaps")
	assert_string_contains(terrain, "textureLod", "sol : niveau tiré des dérivées continues")


func test_ground_atlas_mipmaps_keep_tiles_apart() -> void:
	# Deux tuiles de 384 px (rouge, bleue) : aucune mipmap utile ne les mélange.
	var tile := IslandTerrain.ATLAS_TILE
	var source := Image.create(tile * 2, tile, false, Image.FORMAT_RGBA8)
	source.fill_rect(Rect2i(0, 0, tile, tile), Color.RED)
	source.fill_rect(Rect2i(tile, 0, tile, tile), Color.BLUE)
	var image := IslandTerrain.mipmapped_image(source)
	assert_true(image.has_mipmaps(), "mipmaps")
	assert_false(source.has_mipmaps(), "l'image source n'est pas touchée")
	var data := image.get_data()
	for level in range(1, 8):
		var width := (tile * 2) >> level
		var height := tile >> level
		var offset := image.get_mipmap_offset(level)
		var mixed := 0
		for y in height:
			for x in width:
				var at := offset + (y * width + x) * 4
				var want := Color.RED if x < width / 2.0 else Color.BLUE
				var got := Color8(data[at], data[at + 1], data[at + 2], data[at + 3])
				if not got.is_equal_approx(want):
					mixed += 1
		assert_eq(mixed, 0, "niveau %d : tuiles séparées" % level)


func test_island_ground_reads_a_mipmapped_atlas() -> void:
	var island := FIXTURE.island()
	add_child(island)
	var terrain := load(TERRAIN_MATERIAL) as ShaderMaterial
	var atlas := terrain.get_shader_parameter(&"ground_atlas") as Texture2D
	assert_not_null(atlas, "atlas du sol")
	if atlas != null:
		var image := atlas.get_image()
		assert_true(image != null and image.has_mipmaps(), "atlas avec mipmaps en jeu")
		# (H9) 12 tuiles (cahier n° 1) ou 27 (cahier n° 2) : 4 colonnes de 384 px, 3 ou 7 rangées.
		assert_eq(atlas.get_width(), 1536, "quatre colonnes")
		assert_true(atlas.get_height() in [1152, 2688], "3 ou 7 rangées : %d" % atlas.get_height())
	island.free()


# --- (H5) Réglages de lumière : couchant (défaut), crépuscule, nuit ----------------------------


func _lighting(preset: String) -> HD2DLighting:
	return load("res://src/world/materials/lighting_%s.tres" % preset) as HD2DLighting


func test_sunset_lighting_is_the_island_default() -> void:
	# Le réglage du couchant reprend exactement island.tscn et post_fx.gdshader : un réglage de
	# nuit puis celui du couchant rendent l'île de l'acte 1.
	var sunset := _lighting("sunset")
	var island := FIXTURE.island()
	var sun := island.get_node(^"Sun") as DirectionalLight3D
	var environment := (island.get_node(^"WorldEnvironment") as WorldEnvironment).environment
	assert_almost_eq(sunset.sun_basis().z, sun.basis.z, Vector3.ONE * 0.002, "soleil au WSO")
	assert_almost_eq(sunset.sun_basis().x, sun.basis.x, Vector3.ONE * 0.002, "soleil sans roulis")
	assert_eq(sunset.sun_color, sun.light_color)
	assert_almost_eq(sunset.sun_energy, sun.light_energy, 0.001)
	assert_eq(sunset.ambient_color, environment.ambient_light_color)
	assert_almost_eq(sunset.ambient_energy, environment.ambient_light_energy, 0.001)
	assert_eq(sunset.fog_color, environment.fog_light_color)
	assert_almost_eq(sunset.fog_density, environment.fog_density, 0.00001)
	var defaults := _shader_defaults(POST_SHADER.code)
	var values := sunset.post_parameters()
	for key: StringName in values:
		assert_true(defaults.has(key), "post : %s" % key)
		var want: Variant = values[key]
		var got: PackedFloat64Array = defaults.get(key, PackedFloat64Array())
		var numbers := (
			PackedFloat64Array([want.r, want.g, want.b, want.a])
			if want is Color
			else PackedFloat64Array([float(want)])
		)
		assert_eq(got.size(), numbers.size(), "post : %s" % key)
		for n in mini(got.size(), numbers.size()):
			assert_almost_eq(got[n], numbers[n], 0.0001, "post : %s" % key)
	island.free()


## Valeurs par défaut des uniformes float et vec4 d'un shader, lues dans son code.
func _shader_defaults(code: String) -> Dictionary:
	var defaults := {}
	var pattern := RegEx.create_from_string(
		"uniform\\s+(?:float|vec4)\\s+(\\w+)[^=;]*=\\s*(?:vec4\\()?([-0-9., ]+)\\)?;"
	)
	for found: RegExMatch in pattern.search_all(code):
		var numbers := PackedFloat64Array()
		for part: String in found.get_string(2).split(","):
			numbers.append(float(part))
		defaults[StringName(found.get_string(1))] = numbers
	return defaults


func test_night_lighting_changes_a_copy_of_the_island() -> void:
	var island := FIXTURE.island()
	add_child(island)
	var world := island.get_node(^"WorldEnvironment") as WorldEnvironment
	var shared := world.environment
	var shared_ambient := shared.ambient_light_color
	var lamps := island.find_children("*", "OmniLight3D", true, false)
	assert_gt(lamps.size(), 0, "lanternes de l'île")
	var lamp_energy := (lamps[0] as OmniLight3D).light_energy
	var night := _lighting("night")
	night.apply(island)
	assert_ne(world.environment, shared, "environnement copié")
	assert_eq(shared.ambient_light_color, shared_ambient, "island.tscn n'est pas touchée")
	assert_eq(world.environment.ambient_light_color, night.ambient_color)
	var sun := island.get_node(^"Sun") as DirectionalLight3D
	assert_eq(sun.light_color, night.sun_color, "lune")
	assert_gt(sun.global_basis.z.x, 0.5, "la lumière vient de l'est")
	assert_almost_eq(
		(lamps[0] as OmniLight3D).light_energy, lamp_energy * night.lamp_energy, 0.001, "lanternes"
	)
	var water := island.get_node(^"Water") as MeshInstance3D
	var clouds := water.material_override as ShaderMaterial
	assert_not_null(clouds, "mer de nuages copiée")
	assert_eq(clouds.get_shader_parameter(&"tint"), night.clouds_tint, "nuages de nuit")
	# Retour au couchant : les lanternes reprennent leur énergie de départ.
	_lighting("sunset").apply(island)
	assert_almost_eq((lamps[0] as OmniLight3D).light_energy, lamp_energy, 0.001)
	assert_eq(world.environment.ambient_light_color, shared_ambient)
	island.free()


func test_lighting_presets_set_the_post_processing() -> void:
	var material := ShaderMaterial.new()
	material.shader = POST_SHADER
	for preset: String in ["sunset", "dusk", "night"]:
		var lighting := _lighting(preset)
		assert_not_null(lighting, preset)
		lighting.apply_post(material)
		for key: StringName in lighting.post_parameters():
			assert_eq(
				material.get_shader_parameter(key),
				lighting.post_parameters()[key],
				"%s : %s" % [preset, key]
			)
	var night := _lighting("night")
	var sunset := _lighting("sunset")
	assert_lt(night.sun_energy, sunset.sun_energy, "la nuit est plus sombre")
	assert_gt(night.lamp_energy, sunset.lamp_energy, "les lanternes portent la nuit")
	assert_lt(night.saturation, sunset.saturation)


func test_day_phase_sets_the_island_lighting() -> void:
	# L'île reste au couchant tant que l'histoire n'annonce pas une autre phase de la journée ;
	# la nuit (la promesse sur la colline) et le soir posent leur réglage, le jour revient au
	# couchant ; les personnages, non éclairés, reçoivent la teinte du réglage.
	var island := FIXTURE.island()
	add_child(island)
	var world := island.get_node(^"WorldEnvironment") as WorldEnvironment
	var sunset := _lighting("sunset")
	assert_eq(world.environment.ambient_light_color, sunset.ambient_color, "couchant au départ")
	EventBus.day_phase_changed.emit(&"night")
	var night := _lighting("night")
	assert_eq(world.environment.ambient_light_color, night.ambient_color, "nuit")
	assert_eq(HD2DLighting.active_sprite_tint(), night.sprite_tint, "personnages de nuit")
	assert_lt(night.sprite_tint.v, 0.9, "la nuit assombrit les personnages")
	EventBus.day_phase_changed.emit(&"evening")
	assert_eq(world.environment.fog_light_color, _lighting("dusk").fog_color, "crépuscule")
	EventBus.day_phase_changed.emit(&"day")
	assert_eq(world.environment.ambient_light_color, sunset.ambient_color, "retour au couchant")
	assert_eq(HD2DLighting.active_sprite_tint(), Color.WHITE, "personnages au naturel")
	island.free()
