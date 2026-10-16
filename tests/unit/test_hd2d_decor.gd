extends GutTest
## (HD-2D) Le décor en images : chaque décor de src/world/props/ est un panneau
## (DecorPanel) ou un bâtiment (Building) dont l'image est à 96 px par mètre ; ce qui bloque garde
## sa collision (couche 1) ; les bâtiments ont une façade à la taille de leur mur et une collision
## qui couvre leur emprise ; dans les cartes, les décors sont fondus par image ; les shaders du
## monde et du post-traitement compilent ; (H5) les images du monde sont filtrées (pixel art net de
## près, sans moiré au loin) et le sol lit un atlas à mipmaps qui ne mélangent pas ses tuiles.
## (F1) L'ancienne île est partie : le fondu se vérifie sur les cartes de l'île n° 68 et d'essai,
## la lumière sur une carte faite ici qui porte ses propres nœuds. (H9) Un décor peut aussi être
## un décalque au sol (GroundDecal, sans collision) ou un panneau animé (une image de la bande) ;
## les formats eux-mêmes sont vérifiés par test_hd2d_formats.gd.

const PROPS_DIR := "res://src/world/props"
## (F1) Cartes en plein air dont le décor est fondu par image.
const BATCHED_MAPS: Array[StringName] = [&"essai", &"port", &"village", &"colline", &"sentier"]
const POST_SHADER := preload("res://src/player/post_fx.gdshader")
## Décors qu'on traverse (fleurs, herbes, objets au sol, décor lointain) : sans collision, comme
## avant le passage au HD-2D.
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
]
## Images (matériaux) au plus par carte (autrefois par zone) : un draw call par image et par case
## visible ; les vues mesurées restent sous 75 draw calls (tests/integration/demo_hd2d.gd, budget :
## 200). (P0) 44 au port avec les flancs des bâtiments et les hélices des navires. (Pose du cahier
## n° 2) Relevé : la variété demandée (3 à 6 variantes par famille) dépasse 48 images par zone, mais
## une vue n'en montre qu'une partie ; la vraie limite, ≤ 200 draw calls par vue, est mesurée par le
## test de chaque zone sous plusieurs angles.
const MAX_IMAGES_PER_ZONE := 140
## (P0) Métadonnée des scènes du cahier n° 2 (tools/hd2d_scenes.py) : leur collision et leur
## densité suivent leur catégorie et le manifeste, vérifiées par test_hd2d_scenes.gd.
const SCENES_META := &"hd2d_category"
const SHADERS: Array[String] = [
	"res://src/world/shaders/panel.gdshader",
	"res://src/world/shaders/map_ground.gdshader",
	"res://src/world/shaders/map_ground_cliff.gdshader",
	"res://src/world/shaders/cloud_sea.gdshader",
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


func test_map_decor_is_batched_by_image() -> void:
	for map_id: StringName in BATCHED_MAPS:
		var map := (load(Map.scene_path(map_id)) as PackedScene).instantiate() as Map
		add_child(map)
		await wait_process_frames(1)
		var geometry := map.get_node(^"Geometry")
		var batches := 0
		var images := {}
		for child: Node in geometry.get_children():
			if child is MeshInstance3D and String(child.name).begins_with("Batch"):
				batches += 1
				images[(child as MeshInstance3D).material_override] = true
		assert_gt(batches, 0, "%s : décor fondu" % map_id)
		assert_lte(images.size(), MAX_IMAGES_PER_ZONE, "%s : %d images" % [map_id, images.size()])
		var loose := 0
		for mesh: Node in geometry.find_children("*", "MeshInstance3D", true, false):
			var instance := mesh as MeshInstance3D
			if instance.is_visible_in_tree() and not String(instance.name).begins_with("Batch"):
				loose += 1
		assert_eq(loose, 0, "%s : aucun panneau oublié par le PropBatcher" % map_id)
		map.free()


func test_world_and_post_shaders_compile() -> void:
	for path in SHADERS:
		var shader := load(path) as Shader
		assert_not_null(shader, path)
		if shader != null:
			# Un shader qui ne compile pas n'expose aucun uniforme (et écrit SHADER ERROR).
			assert_gt(shader.get_shader_uniform_list().size(), 0, "%s compile" % path)
	assert_not_null(MapGround.ATLAS, "atlas du sol des cartes")


# --- (H5) Filtrage du pixel art : ni moiré ni scintillement -----------------------------------


func test_world_images_are_filtered_not_point_sampled() -> void:
	# Au plus proche voisin et sans mipmaps, des images plus denses que l'écran (96 px par mètre)
	# font du moiré au loin et scintillent quand la caméra glisse.
	var code := (load("res://src/world/shaders/panel.gdshader") as Shader).code
	assert_string_contains(code, "pixel_art.gdshaderinc", "panneaux")
	assert_false(code.contains("filter_nearest"), "panneaux : images filtrées")
	var terrain := FileAccess.get_file_as_string(
		"res://src/world/shaders/map_ground_atlas.gdshaderinc"
	)
	assert_string_contains(terrain, "filter_linear_mipmap", "sol : mipmaps")
	assert_string_contains(terrain, "textureLod", "sol : niveau tiré des dérivées continues")


func test_ground_atlas_mipmaps_keep_tiles_apart() -> void:
	# Deux tuiles de 384 px (rouge, bleue) : aucune mipmap utile ne les mélange.
	var tile := GroundAtlas.ATLAS_TILE
	var source := Image.create(tile * 2, tile, false, Image.FORMAT_RGBA8)
	source.fill_rect(Rect2i(0, 0, tile, tile), Color.RED)
	source.fill_rect(Rect2i(tile, 0, tile, tile), Color.BLUE)
	var image := GroundAtlas.mipmapped_image(source)
	assert_true(image.has_mipmaps(), "mipmaps")
	assert_false(source.has_mipmaps(), "l'image source n'est pas touchée")
	var data := image.get_data()
	for level in range(1, 8):
		var width := (tile * 2) >> level
		var height := tile >> level
		var offset := image.get_mipmap_offset(level)
		var mixed := 0
		for y: int in height:
			for x: int in width:
				var at := offset + (y * width + x) * 4
				var want := Color.RED if x < width / 2.0 else Color.BLUE
				var got := Color8(data[at], data[at + 1], data[at + 2], data[at + 3])
				if not got.is_equal_approx(want):
					mixed += 1
		assert_eq(mixed, 0, "niveau %d : tuiles séparées" % level)


func test_map_ground_reads_a_mipmapped_atlas() -> void:
	var atlas := GroundAtlas.mipmapped_atlas(MapGround.ATLAS)
	assert_not_null(atlas, "atlas du sol")
	if atlas != null:
		var image := atlas.get_image()
		assert_true(image != null and image.has_mipmaps(), "atlas avec mipmaps en jeu")
		# (H9) 12 tuiles (cahier n° 1) ou 27 (cahier n° 2) : 4 colonnes de 384 px, 3 ou 7 rangées.
		assert_eq(atlas.get_width(), 1536, "quatre colonnes")
		assert_true(atlas.get_height() in [1152, 2688], "3 ou 7 rangées : %d" % atlas.get_height())


# --- (H5) Réglages de lumière ; (E9) préréglages de data/lighting/ (couchant par défaut) ---------


func _lighting(preset: String) -> HD2DLighting:
	return HD2DLighting.preset(StringName(preset))


## (F1) Carte faite ici qui porte ses propres nœuds de lumière (environnement, soleil, lanterne,
## mer de nuages), comme l'ancienne île.
func _own_light_map() -> Node3D:
	var holder := Node3D.new()
	holder.name = "own_light"
	var world := WorldEnvironment.new()
	world.name = "WorldEnvironment"
	world.environment = Environment.new()
	var panorama := PanoramaSkyMaterial.new()
	panorama.panorama = load("res://assets/hd2d/sky/sky.png") as Texture2D
	world.environment.sky = Sky.new()
	world.environment.sky.sky_material = panorama
	world.environment.background_mode = Environment.BG_SKY
	holder.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	holder.add_child(sun)
	var lamp := OmniLight3D.new()
	lamp.name = "Lantern"
	holder.add_child(lamp)
	var water := MeshInstance3D.new()
	water.name = "Water"
	water.mesh = PlaneMesh.new()
	var clouds := ShaderMaterial.new()
	clouds.shader = HD2DLightTargets.CLOUD_SEA_SHADER
	clouds.set_shader_parameter(&"clouds", load("res://assets/hd2d/sky/cloud_sea.png"))
	water.material_override = clouds
	holder.add_child(water)
	return holder


func test_sunset_lighting_is_the_post_processing_default() -> void:
	# Le réglage du couchant reprend les valeurs par défaut de post_fx.gdshader.
	var sunset := _lighting("couchant")
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


func test_night_lighting_changes_a_copy_of_the_map_environment() -> void:
	var island := _own_light_map()
	add_child(island)
	var world := island.get_node(^"WorldEnvironment") as WorldEnvironment
	var shared := world.environment
	var shared_ambient := shared.ambient_light_color
	var lamps := island.find_children("*", "OmniLight3D", true, false)
	assert_gt(lamps.size(), 0, "lanterne de la carte")
	var lamp_energy := (lamps[0] as OmniLight3D).light_energy
	var night := _lighting("nuit")
	night.apply(island)
	assert_ne(world.environment, shared, "environnement copié")
	assert_eq(
		shared.ambient_light_color, shared_ambient, "l'environnement d'origine n'est pas touché"
	)
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
	var sunset := _lighting("couchant")
	sunset.apply(island)
	assert_almost_eq(
		(lamps[0] as OmniLight3D).light_energy, lamp_energy * sunset.lamp_energy, 0.001
	)
	assert_eq(world.environment.ambient_light_color, sunset.ambient_color)
	island.free()


func test_lighting_presets_set_the_post_processing() -> void:
	var material := ShaderMaterial.new()
	material.shader = POST_SHADER
	for preset: String in ["aube", "matin", "apres_midi", "couchant", "nuit", "interieur"]:
		var lighting := _lighting(preset)
		assert_not_null(lighting, preset)
		lighting.apply_post(material)
		for key: StringName in lighting.post_parameters():
			assert_eq(
				material.get_shader_parameter(key),
				lighting.post_parameters()[key],
				"%s : %s" % [preset, key]
			)
	var night := _lighting("nuit")
	var sunset := _lighting("couchant")
	assert_lt(night.sun_energy, sunset.sun_energy, "la nuit est plus sombre")
	assert_gt(night.lamp_energy, sunset.lamp_energy, "les lanternes portent la nuit")
	assert_lt(night.saturation, sunset.saturation)


func test_day_phase_sets_the_map_lighting() -> void:
	# La carte reste au couchant tant que l'histoire n'annonce pas un autre moment ; (E9)
	# l'ancienne phase de la journée donne son moment (Atmosphere), qui pose son réglage sur la
	# carte ; les personnages, non éclairés, reçoivent la teinte du réglage.
	var island := _own_light_map()
	add_child(island)
	GameState.reset()
	Atmosphere.dress(island)
	var world := island.get_node(^"WorldEnvironment") as WorldEnvironment
	var sunset := _lighting("couchant")
	assert_eq(world.environment.ambient_light_color, sunset.ambient_color, "couchant au départ")
	EventBus.day_phase_changed.emit(&"night")
	Atmosphere.step(Atmosphere.transition_time + 1.0)
	var night := _lighting("nuit")
	assert_eq(world.environment.ambient_light_color, night.ambient_color, "nuit")
	assert_eq(HD2DLighting.active_sprite_tint(), night.sprite_tint, "personnages de nuit")
	assert_lt(night.sprite_tint.v, 0.95, "la nuit assombrit les personnages")
	EventBus.day_phase_changed.emit(&"morning")
	Atmosphere.step(Atmosphere.transition_time + 1.0)
	assert_eq(world.environment.fog_light_color, _lighting("matin").fog_color, "matin")
	EventBus.day_phase_changed.emit(&"evening")
	Atmosphere.step(Atmosphere.transition_time + 1.0)
	assert_eq(world.environment.ambient_light_color, sunset.ambient_color, "retour au couchant")
	assert_eq(HD2DLighting.active_sprite_tint(), Color.WHITE, "personnages au naturel")
	Atmosphere.dress(null)
	island.free()
	GameState.reset()
