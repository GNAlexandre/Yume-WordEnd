extends GutTest
## (H9) Formats du décor du cahier n° 2 (docs/ASSETS_HD2D_MONDE.md, sections 3 et 17), avec des
## images faites à l'exécution : bandes animées (DecorPanel.frames, une image de large, phase par
## exemplaire, fondues par image), retournement et décalage vers la caméra, premier plan qui
## s'efface devant le joueur, décalques au sol (GroundDecal) couchés sur le relief sans
## collision, flancs des bâtiments (Building.side_facade) retournés à l'ouest, variantes de
## PropScatter sans voisin identique, sol à 27 tuiles et repli à 12, ciel qui dérive (SkyDrift),
## petites vies (AmbientSprites), shaders compilés.

const TERRAIN_SHADER := "res://src/world/shaders/terrain.gdshader"
const PLAYER_STUB := preload("res://tests/stubs/player_stub.tscn")
const SHADERS: Array[String] = [
	"res://src/world/shaders/panel.gdshader",
	"res://src/world/shaders/panel_foreground.gdshader",
	"res://src/world/shaders/ground_decal.gdshader",
	"res://src/world/shaders/ground_decal_soft.gdshader",
	"res://src/world/shaders/sky_drift.gdshader",
	"res://src/world/shaders/ambient_sprites.gdshader",
	"res://src/world/shaders/terrain.gdshader",
]
## Sur le flanc ouest de la colline des étoiles : une pente.
const SLOPE := Vector3(40.5, 0.0, -2.0)

var _interpolation: bool


func before_each() -> void:
	_interpolation = get_tree().physics_interpolation


func after_each() -> void:
	get_tree().physics_interpolation = _interpolation
	ProjectSettings.set_setting(&"physics/common/physics_interpolation", _interpolation)


## Image unie de w × h px par image, frames images côte à côte (couleur différente par image).
func _strip(w: int, h: int, frames: int = 1) -> ImageTexture:
	var image := Image.create(w * frames, h, false, Image.FORMAT_RGBA8)
	for k in frames:
		image.fill_rect(Rect2i(k * w, 0, w, h), Color.from_hsv(float(k) / frames, 0.8, 0.9))
	return ImageTexture.create_from_image(image)


func _panel(texture: Texture2D, at: Vector3, frames: int = 1, parent: Node = null) -> DecorPanel:
	var panel := DecorPanel.new()
	panel.texture = texture
	panel.frames = frames
	panel.fps = 6.0 if frames > 1 else 0.0
	panel.position = at
	(parent if parent != null else self).add_child(panel)
	return panel


func _quad(panel: DecorPanel) -> MeshInstance3D:
	return panel.get_child(0, true) as MeshInstance3D


func _uv2s(mesh: Mesh) -> PackedVector2Array:
	var arrays := mesh.surface_get_arrays(0)
	var uv2: Variant = arrays[Mesh.ARRAY_TEX_UV2]
	return uv2 if uv2 != null else PackedVector2Array()


# --- Bandes animées, retournement, décalage, premier plan --------------------------------------


func test_strip_panel_is_one_frame_wide() -> void:
	var panel := _panel(_strip(48, 96, 4), Vector3(1.0, 0.0, 2.0), 4)
	await wait_process_frames(1)
	assert_almost_eq(panel.size_m(), Vector2(0.5, 1.0), Vector2.ONE * 0.0001, "une image")
	var aabb := _quad(panel).mesh.get_aabb()
	assert_almost_eq(aabb.size.x, 0.5, 0.0001, "mesh : largeur d'une image")
	assert_almost_eq(aabb.size.y, 1.0, 0.0001, "mesh : hauteur")
	assert_almost_eq(aabb.position.y, 0.0, 0.0001, "ancre au bas")
	var material := _quad(panel).material_override as ShaderMaterial
	assert_eq(material.get_shader_parameter(&"frames"), 4.0, "nombre d'images")
	assert_eq(material.get_shader_parameter(&"fps"), 6.0, "cadence")
	panel.free()


func test_strip_phase_differs_between_instances() -> void:
	var texture := _strip(16, 32, 6)
	var phases := {}
	var panels: Array[DecorPanel] = []
	for i in 8:
		var panel := _panel(texture, Vector3(i * 1.7, 0.0, -i * 0.9), 6)
		panels.append(panel)
		var phase := panel.strip_phase()
		assert_between(phase, 0.0, 1.0, "phase entre 0 et 1")
		assert_eq(phase, DecorPanel.phase_at(panel.global_position), "tirée de la position")
		phases[phase] = true
		var uv2s := _uv2s(_quad(panel).mesh)
		if phase > 0.0:
			assert_eq(uv2s.size(), 6, "phase dans les sommets")
			for uv2 in uv2s:
				assert_almost_eq(uv2.x, phase, 0.0001)
	assert_gt(phases.size(), 4, "les exemplaires ne battent pas ensemble : %s" % [phases.keys()])
	assert_ne(panels[0].strip_phase(), panels[1].strip_phase(), "deux voisins décalés")
	assert_eq(DecorPanel.phase_at(Vector3(3, 0, 1)), DecorPanel.phase_at(Vector3(3, 0, 1)))
	for panel in panels:
		panel.free()


func test_batcher_keeps_one_draw_call_per_image_with_strips() -> void:
	var batcher := PropBatcher.new()
	add_child(batcher)
	var strip := _strip(16, 32, 4)
	var still := _strip(20, 20)
	for i in 6:
		_panel(strip, Vector3(i * 2.3, 0.0, i * 0.7), 4, batcher)
	for i in 3:
		_panel(still, Vector3(-i * 2.0, 0.0, 3.0), 1, batcher)
	var created := batcher.batch()
	assert_eq(created, 3, "une image animée, une fixe, les ombres")
	var animated := DecorPanel.material_for(strip, Color.WHITE, 0.0, 4, 6.0)
	var phases := {}
	var found := 0
	for child: Node in batcher.get_children():
		var batch := child as MeshInstance3D
		if batch == null or not String(batch.name).begins_with("Batch"):
			continue
		if batch.material_override == animated:
			found += 1
			assert_eq(batch.mesh.get_surface_count(), 1)
			assert_eq(batch.mesh.surface_get_array_len(0), 36, "six panneaux")
			for uv2 in _uv2s(batch.mesh):
				phases[uv2.x] = true
	assert_eq(found, 1, "les panneaux animés en un seul mesh")
	assert_gt(phases.size(), 2, "chaque panneau garde sa phase dans le mesh fondu")
	batcher.free()


func test_flip_and_depth_offset_live_in_the_vertices() -> void:
	var texture := _strip(32, 32)
	var plain := _panel(texture, Vector3.ZERO)
	assert_true(_quad(plain).mesh is QuadMesh, "panneau ordinaire : mesh partagé d'avant")
	var flipped := _panel(texture, Vector3(2.0, 0.0, 0.0))
	flipped.flip_h = true
	flipped.depth_offset = 0.08
	flipped.rebuild()
	var arrays := _quad(flipped).mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	for k in vertices.size():
		var left := vertices[k].x < 0.0
		assert_eq(uvs[k].x, 1.0 if left else 0.0, "image retournée")
	for uv2 in _uv2s(_quad(flipped).mesh):
		assert_almost_eq(uv2.y, 0.08, 0.0001, "décalage vers la caméra dans les sommets")
	plain.free()
	flipped.free()


func test_foreground_panel_fades_around_the_player() -> void:
	var panel := _panel(_strip(64, 256), Vector3(0.0, 0.0, 4.0))
	panel.foreground = true
	panel.rebuild()
	var material := _quad(panel).material_override as ShaderMaterial
	assert_eq(material.shader, DecorPanel.FOREGROUND_SHADER, "shader du premier plan")
	assert_ne(
		material,
		DecorPanel.material_for(panel.texture, Color.WHITE, 0.0),
		"matériau à part du même panneau ordinaire"
	)
	assert_true(panel.is_processing(), "pose le centre à chaque image")
	await wait_process_frames(2)
	assert_eq(material.get_shader_parameter(&"foreground_strength"), 0.0, "sans joueur")
	# Avec le lissage physique (contrat de l'orchestrateur) : la place affichée du joueur.
	get_tree().physics_interpolation = true
	ProjectSettings.set_setting(&"physics/common/physics_interpolation", true)
	var player := add_child_autofree(PLAYER_STUB.instantiate()) as Node3D
	player.global_position = Vector3(0.5, 0.0, -3.0)
	player.reset_physics_interpolation()
	await wait_physics_frames(2)
	await wait_process_frames(2)
	assert_eq(material.get_shader_parameter(&"foreground_strength"), 1.0, "joueur présent")
	var center: Vector3 = material.get_shader_parameter(&"foreground_center")
	var shown := DecorPanel.displayed_transform(player).origin
	assert_almost_eq(center, shown + Vector3.UP * DecorPanel.FOREGROUND_HEIGHT, Vector3.ONE * 0.01)
	assert_almost_eq(center, Vector3(0.5, 0.8, -3.0), Vector3.ONE * 0.01, "corps du joueur")
	panel.free()


# --- Décalques au sol -------------------------------------------------------------------------


func _decal(texture: Texture2D, at: Vector3, yaw_deg: float = 0.0) -> GroundDecal:
	var decal := GroundDecal.new()
	decal.texture = texture
	decal.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_deg)), at)
	add_child(decal)
	return decal


func test_decal_lies_on_a_slope_without_collision() -> void:
	var decal := _decal(_strip(192, 144), SLOPE, 30.0)
	var mesh := (decal.get_child(0, true) as MeshInstance3D).mesh
	assert_not_null(mesh, "mesh couché sur le sol")
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	assert_gt(vertices.size(), 12, "découpé sur les triangles du sol")
	var low := INF
	var high := -INF
	for k in vertices.size():
		var v := vertices[k]
		assert_almost_eq(v.y, IslandTerrain.surface_height(v.x, v.z), 0.002, "sur le sol en %s" % v)
		assert_almost_eq(v.y, IslandTerrain.height_at(v.x, v.z), 0.08, "relief en %s" % v)
		assert_between(uvs[k].x, -0.0001, 1.0001)
		assert_between(uvs[k].y, -0.0001, 1.0001)
		low = minf(low, v.y)
		high = maxf(high, v.y)
	assert_gt(high - low, 0.3, "une pente : %.2f m de dénivelé" % (high - low))
	# Aire couverte (plan du sol) : exactement l'image, 2 × 1,5 m.
	var area := 0.0
	for n in range(0, vertices.size(), 3):
		var a := Vector2(vertices[n].x, vertices[n].z)
		var b := Vector2(vertices[n + 1].x, vertices[n + 1].z)
		var c := Vector2(vertices[n + 2].x, vertices[n + 2].z)
		area += absf((b - a).cross(c - a)) / 2.0
	assert_almost_eq(area, 3.0, 0.01, "aire du décalque")
	assert_eq(
		decal.find_children("*", "CollisionObject3D", true, false).size(), 0, "sans collision"
	)
	var material := (decal.get_child(0, true) as MeshInstance3D).material_override
	assert_eq((material as ShaderMaterial).shader, GroundDecal.HARD_SHADER, "alpha découpé")
	decal.free()


func test_decal_flat_soft_and_layers() -> void:
	var texture := _strip(96, 96)
	var flat := GroundDecal.new()
	flat.texture = texture
	flat.follow_ground = false
	flat.soft_alpha = true
	flat.layer = 3
	flat.flip_h = true
	flat.position = Vector3(5.0, 2.0, 5.0)
	add_child(flat)
	var instance := flat.get_child(0, true) as MeshInstance3D
	var arrays := instance.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	assert_eq(vertices.size(), 6, "deux triangles à plat")
	for k in vertices.size():
		assert_almost_eq(vertices[k].y, 2.0, 0.0001, "à la hauteur du nœud")
		assert_almost_eq(uvs[k].x, 0.0 if vertices[k].x > 5.0 else 1.0, 0.0001, "retourné")
		assert_almost_eq(uvs[k].y, 0.0 if vertices[k].z < 5.0 else 1.0, 0.0001, "haut au nord")
	for uv2 in _uv2s(instance.mesh):
		assert_eq(uv2.y, 3.0, "couche dans les sommets")
		assert_eq(uv2.x, DecorPanel.phase_at(flat.global_position), "part de l'exemplaire")
	var material := instance.material_override as ShaderMaterial
	assert_eq(material.shader, GroundDecal.SOFT_SHADER, "alpha doux")
	assert_eq(material.render_priority, GroundDecal.SOFT_PRIORITY + 3, "ordre des couches")
	assert_lt(
		material.render_priority, DecorPanel.shadow_material().render_priority, "sous les ombres"
	)
	# Fondus par image : deux décalques durs de couches différentes, un seul matériau.
	assert_eq(
		GroundDecal.material_for(texture, Color.WHITE, false, 0),
		GroundDecal.material_for(texture, Color.WHITE, false, 5),
		"décalques durs : la couche est dans les sommets"
	)
	flat.free()


func test_decals_are_batched_by_image() -> void:
	var batcher := PropBatcher.new()
	add_child(batcher)
	var texture := _strip(96, 64)
	for i in 4:
		var decal := GroundDecal.new()
		decal.texture = texture
		decal.layer = i % 2
		decal.position = Vector3(10.0 + i * 1.5, 0.0, 10.0)
		batcher.add_child(decal)
	assert_eq(batcher.batch(), 1, "un mesh pour l'image")
	batcher.free()


# --- Flancs des bâtiments ---------------------------------------------------------------------


func _building(gable_front: bool, side: Texture2D) -> Building:
	var building := Building.new()
	building.footprint = Vector2(6.0, 4.0)
	building.wall_height = 3.0
	building.ridge_height = 5.0
	building.gable_front = gable_front
	building.wall_texture = _strip(16, 16)
	building.roof_texture = _strip(16, 16)
	building.side_facade = side
	add_child(building)
	return building


func _sides(building: Building) -> MeshInstance3D:
	for child: Node in building.get_children(true):
		if child.name == &"Sides":
			return child as MeshInstance3D
	return null


func test_side_facade_on_both_flanks_mirrored_to_the_west() -> void:
	# Toit long : flanc en pignon, profondeur × faîtage (4 × 5 m).
	var building := _building(false, _strip(384, 480))
	assert_eq(building.side_contract_size(), Vector2(4.0, 5.0), "pignon : jusqu'au faîtage")
	assert_eq(building.side_size_m(), Vector2(4.0, 5.0))
	var sides := _sides(building)
	assert_true(sides.visible, "flancs posés")
	var arrays := sides.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	assert_eq(vertices.size(), 12, "deux flancs")
	var aabb := sides.mesh.get_aabb()
	assert_almost_eq(aabb.size.z, 4.0, 0.001, "largeur du flanc")
	assert_almost_eq(aabb.size.y, 5.0, 0.001, "hauteur du flanc")
	var reading := {}
	for k in vertices.size():
		var v := vertices[k]
		var east := v.x > 0.0
		assert_almost_eq(absf(v.x), 3.0 + Building.FACADE_GAP, 0.0001, "devant le mur")
		var outward := Vector3.RIGHT if east else Vector3.LEFT
		assert_almost_eq(normals[k], outward, Vector3.ONE * 0.001, "vers l'extérieur")
		assert_eq(uvs[k].x, 0.0 if v.z > 0.0 else 1.0, "côté gauche de l'image au sud")
		assert_eq(uvs[k].y, 0.0 if v.y > 0.0 else 1.0, "bas de l'image au sol")
		# Sens de lecture vu de l'extérieur : la droite du regard est (−normale) × haut.
		var right := (-normals[k]).cross(Vector3.UP)
		reading[east] = signf(right.z) * (1.0 if v.z > 0.0 else -1.0) * (uvs[k].x - 0.5)
	assert_gt(reading[true], 0.0, "à l'est, l'image se lit de gauche à droite")
	assert_lt(reading[false], 0.0, "à l'ouest, retournée")
	var material := sides.material_override as ShaderMaterial
	assert_eq(material.get_shader_parameter(&"hd2d_relief"), Building.WALL_RELIEF, "comme les murs")
	assert_eq(material.get_shader_parameter(&"glow_strength"), building.window_glow, "fenêtres")
	building.free()


func test_side_facade_of_a_gable_front_building_and_none() -> void:
	var gable := _building(true, _strip(384, 288))
	assert_eq(gable.side_contract_size(), Vector2(4.0, 3.0), "gouttereau : jusqu'à l'égout")
	assert_almost_eq(_sides(gable).mesh.get_aabb().size.y, 3.0, 0.001)
	gable.free()
	var plain := _building(false, null)
	assert_false(_sides(plain).visible, "sans image, la matière des murs")
	plain.free()


# --- Variantes --------------------------------------------------------------------------------


func _variant_scene(color: Color) -> PackedScene:
	var image := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	image.fill(color)
	var panel := DecorPanel.new()
	panel.texture = ImageTexture.create_from_image(image)
	var scene := PackedScene.new()
	scene.pack(panel)
	panel.free()
	return scene


func _points(count: int, seed_value: int) -> PackedVector3Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var points := PackedVector3Array()
	for _i in count:
		points.append(Vector3(rng.randf_range(-10.0, 10.0), 0.0, rng.randf_range(-10.0, 10.0)))
	return points


func test_variants_never_match_the_nearest_neighbor() -> void:
	var scatter := PropScatter.new()
	scatter.follow_ground = false
	scatter.points = _points(60, 7)
	scatter.prop = _variant_scene(Color.RED)
	var variants: Array[PackedScene] = [_variant_scene(Color.GREEN), _variant_scene(Color.BLUE)]
	scatter.variants = variants
	scatter.random_flip = true
	scatter.random_seed = 4
	add_child(scatter)
	var instances := scatter.get_children(true)
	assert_eq(instances.size(), 60)
	var picks := scatter.variant_indices()
	var used := {}
	var flips := {}
	for i in instances.size():
		var panel := instances[i] as DecorPanel
		var nearest := PropScatter.nearest_neighbor(scatter.points, i)
		var other := instances[nearest] as DecorPanel
		assert_ne(panel.texture, other.texture, "point %d : pas la variante de son voisin" % i)
		var probe := scatter.pool()[picks[i]].instantiate() as DecorPanel
		assert_eq(panel.texture, probe.texture, "point %d : la scène tirée" % i)
		probe.free()
		used[picks[i]] = true
		flips[panel.flip_h] = true
	assert_eq(used.size(), 3, "les trois formes servent")
	assert_eq(flips.size(), 2, "retournées au hasard")
	assert_eq(scatter.variant_indices(), picks, "tirage stable")
	# Les lacets et les échelles ne changent pas avec les variantes.
	var alone := PropScatter.new()
	alone.follow_ground = false
	alone.points = scatter.points
	alone.prop = scatter.prop
	alone.scale_range = Vector2(0.8, 1.2)
	alone.random_seed = 4
	scatter.scale_range = Vector2(0.8, 1.2)
	scatter.rebuild()
	add_child(alone)
	for i in 60:
		assert_eq(
			(alone.get_children(true)[i] as Node3D).transform,
			(scatter.get_children(true)[i] as Node3D).transform,
			"même lacet et même échelle (point %d)" % i
		)
	scatter.free()
	alone.free()


func test_pick_variants_on_clusters_and_pairs() -> void:
	for seed_value in 20:
		var points := _points(40, 100 + seed_value)
		# Des grappes serrées : chaque point a un voisin tout près.
		for i in 20:
			points.append(points[i] + Vector3(0.05, 0.0, 0.03))
		var picks := PropScatter.pick_variants(points, 2, seed_value)
		for i in points.size():
			var nearest := PropScatter.nearest_neighbor(points, i)
			assert_ne(picks[i], picks[nearest], "graine %d, point %d" % [seed_value, i])
	assert_eq(PropScatter.pick_variants(_points(5, 1), 1, 3), PackedInt32Array([0, 0, 0, 0, 0]))


# --- Sol à 27 tuiles --------------------------------------------------------------------------


func test_ground_atlas_layers_and_fallback_to_twelve_tiles() -> void:
	assert_eq(IslandTerrain.GROUND_LAYERS.size(), 27, "27 tuiles")
	assert_eq(IslandTerrain.atlas_tile_count(Vector2i(1536, 1152)), 12, "atlas actuel")
	assert_eq(IslandTerrain.atlas_tile_count(Vector2i(1536, 2688)), 27, "atlas du cahier n° 2")
	for layer: StringName in IslandTerrain.GROUND_LAYERS:
		var index := IslandTerrain.GROUND_LAYERS.find(layer)
		var twelve := IslandTerrain.ground_layer(layer, 12)
		if index < 12:
			assert_eq(twelve, layer, "%s : dans l'atlas actuel" % layer)
		else:
			assert_true(IslandTerrain.GROUND_FALLBACK.has(layer), "%s : repli" % layer)
			assert_eq(twelve, IslandTerrain.GROUND_FALLBACK[layer], "%s : tuile d'origine" % layer)
			assert_lt(IslandTerrain.GROUND_LAYERS.find(twelve), 12, "%s : repli présent" % layer)
		assert_eq(IslandTerrain.ground_layer(layer, 27), layer, "%s : 27 tuiles" % layer)
	var expected := {
		&"grass_b": &"grass",
		&"leaf_litter": &"forest_floor",
		&"moss": &"forest_floor",
		&"meadow_flowers": &"grass",
		&"gravel": &"path_dirt",
		&"garden_soil": &"mud",
		&"planks": &"path_dirt",
		&"stream_bed": &"water",
	}
	for layer: StringName in expected:
		assert_eq(IslandTerrain.GROUND_FALLBACK[layer], expected[layer], "contrat : %s" % layer)


func test_terrain_shader_follows_the_atlas_contract() -> void:
	var code := (load(TERRAIN_SHADER) as Shader).code
	# Indices des tuiles : ceux de GROUND_LAYERS.
	for index in IslandTerrain.GROUND_LAYERS.size():
		var constant := String(IslandTerrain.GROUND_LAYERS[index]).to_upper()
		assert_string_contains(code, "const int %s = %d;" % [constant, index])
	# Table de repli : celle de GROUND_FALLBACK.
	var found := RegEx.create_from_string("FALLBACK\\[LAYER_COUNT\\] = int\\[\\]\\(([0-9, ]+)\\)")
	var table := found.search(code)
	assert_not_null(table, "table FALLBACK")
	if table != null:
		var values := table.get_string(1).split(",")
		assert_eq(values.size(), 27)
		for index in values.size():
			var layer := IslandTerrain.GROUND_LAYERS[index]
			var want := IslandTerrain.ground_layer(layer, 12)
			assert_eq(int(values[index]), IslandTerrain.GROUND_LAYERS.find(want), String(layer))
	assert_false(code.contains("ATLAS_ROWS"), "rangées lues dans la taille de l'atlas")
	assert_string_contains(code, "textureSize(ground_atlas, 0)")


# --- Ciel qui dérive, petites vies, shaders ---------------------------------------------------


func test_sky_drift_moves_in_the_shader_one_mesh_per_image() -> void:
	var batcher := PropBatcher.new()
	add_child(batcher)
	var sky := SkyDrift.new()
	var textures: Array[Texture2D] = [_strip(96, 48), _strip(48, 48)]
	sky.textures = textures
	sky.count = 5
	sky.span = 500.0
	sky.speed_range = Vector2(2.0, 3.0)
	batcher.add_child(sky)
	var meshes := sky.meshes()
	assert_eq(meshes.size(), 2, "un mesh (un draw call) par image")
	assert_eq(meshes[0].mesh.surface_get_array_len(0), 18, "trois voyageurs sur la 1re image")
	for node in meshes:
		assert_null(node.material_override, "matériau dans le mesh")
		assert_not_null(node.mesh.surface_get_material(0))
		assert_gte(node.custom_aabb.size.x, 500.0, "boîte du trajet entier")
		for uv2 in _uv2s(node.mesh):
			assert_between(uv2.x, 0.0, 500.0, "départ sur le trajet")
			assert_between(uv2.y, 2.0, 3.0, "vitesse")
	assert_eq(batcher.batch(), 0, "le PropBatcher ne le fond pas")
	assert_eq(sky.meshes()[0].mesh.surface_get_array_len(0), 18, "intact")
	assert_eq(sky.find_children("*", "CollisionObject3D", true, false).size(), 0, "sans collision")
	# D'ouest en est, puis retour en boucle.
	assert_almost_eq(SkyDrift.drift_x(0.0, 2.0, 10.0, 500.0), -230.0, 0.001)
	assert_almost_eq(SkyDrift.drift_x(0.0, 2.0, 260.0, 500.0), -230.0, 0.001, "boucle")
	assert_gt(SkyDrift.drift_x(0.0, 2.0, 20.0, 500.0), SkyDrift.drift_x(0.0, 2.0, 10.0, 500.0))
	batcher.free()


func test_island_has_a_sky_drift_with_existing_images() -> void:
	var island := (load("res://src/world/island.tscn") as PackedScene).instantiate()
	var sky := island.get_node_or_null(^"Decor/SkyDrift") as SkyDrift
	assert_not_null(sky, "ciel qui dérive dans Decor")
	if sky != null:
		assert_false(sky.textures.is_empty(), "images existantes en attendant les nuages")
		for texture: Texture2D in sky.textures:
			assert_true(ResourceLoader.exists(texture.resource_path), texture.resource_path)
		assert_true(sky.pixels_per_meter in [24.0, 48.0], "densité du lointain")
	island.free()


func test_ambient_sprites_without_image_do_nothing() -> void:
	var lives := AmbientSprites.new()
	add_child(lives)
	var mesh := lives.get_child(0, true) as MeshInstance3D
	assert_null(mesh.mesh, "sans image, rien")
	assert_false(mesh.visible)
	assert_false(lives.is_processing())
	lives.free()


func test_ambient_sprites_are_one_draw_call_around_the_camera() -> void:
	get_tree().physics_interpolation = true
	ProjectSettings.set_setting(&"physics/common/physics_interpolation", true)
	var camera := Camera3D.new()
	camera.transform = Transform3D(
		Basis(Vector3.RIGHT, deg_to_rad(-32.0)), Vector3(4.0, 11.128, 17.809)
	)
	add_child(camera)
	camera.make_current()
	camera.reset_physics_interpolation()
	var lives := AmbientSprites.new()
	lives.texture = _strip(16, 16, 8)
	lives.frames = 8
	lives.density = 5.0
	lives.area = Vector3(20.0, 8.0, 10.0)
	add_child(lives)
	assert_eq(lives.sprite_count(), 10, "densité : 5 pour 100 m²")
	assert_almost_eq(lives.sprite_size(), Vector2(16, 16) / 96.0, Vector2.ONE * 0.0001)
	var mesh := lives.get_child(0, true) as MeshInstance3D
	assert_eq(mesh.mesh.get_surface_count(), 1, "un draw call")
	assert_eq(mesh.mesh.surface_get_array_len(0), 60, "dix sprites")
	assert_null(mesh.material_override, "matériau dans le mesh : jamais fondu")
	assert_eq(mesh.physics_interpolation_mode, Node.PHYSICS_INTERPOLATION_MODE_OFF)
	await wait_process_frames(2)
	var view := DecorPanel.displayed_transform(camera)
	var forward := -view.basis.z.normalized()
	var want := view.origin + forward * (-view.origin.y / forward.y)
	assert_almost_eq(lives.focus_point(), want, Vector3.ONE * 0.01, "point visé par la caméra")
	assert_almost_eq(want, Vector3(4.0, 0.0, 0.0), Vector3.ONE * 0.05)
	var material := mesh.mesh.surface_get_material(0) as ShaderMaterial
	var center: Vector3 = material.get_shader_parameter(&"box_center")
	assert_almost_eq(center, want + Vector3.UP * 4.0, Vector3.ONE * 0.05, "boîte sur le point visé")
	assert_gt(material.get_shader_parameter(&"ambient_time"), 0.0, "le temps passe")
	# Hors de leur région, rien ; en pause, ils se figent (le nœud suit la pause).
	lives.region_size = Vector2(10.0, 10.0)
	lives.position = Vector3(100.0, 0.0, 0.0)
	lives.update_box(lives.focus_point())
	assert_false(mesh.visible, "hors de la région")
	assert_eq(lives.process_mode, Node.PROCESS_MODE_INHERIT, "suit la pause")
	lives.free()
	camera.free()


func test_format_shaders_compile() -> void:
	for path in SHADERS:
		var shader := load(path) as Shader
		assert_not_null(shader, path)
		if shader != null:
			# Un shader qui ne compile pas n'expose aucun uniforme (et écrit SHADER ERROR).
			assert_gt(shader.get_shader_uniform_list().size(), 0, "%s compile" % path)
	var panel := (load("res://src/world/shaders/panel.gdshader") as Shader).code
	var foreground := (load("res://src/world/shaders/panel_foreground.gdshader") as Shader).code
	assert_string_contains(panel, "void fragment()", "la découpe du village s'y ajoute")
	assert_string_contains(foreground, "foreground_amount", "premier plan")
