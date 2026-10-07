extends GutTest
## (HD-2D) Le décor de l'île en images : chaque décor de src/world/props/ est un panneau
## (DecorPanel) ou un bâtiment (Building) dont l'image est à 96 px par mètre ; ce qui bloque garde
## sa collision (couche 1) ; les bâtiments ont une façade à la taille de leur mur et une collision
## qui couvre leur emprise ; dans l'île, les décors sont fondus par image ; les shaders du monde et
## du post-traitement compilent. Les places de HISTOIRE.md 3.3 restent vérifiées par
## test_world_story_spots.gd.

const PROPS_DIR := "res://src/world/props"
const FIXTURE := preload("res://tests/stubs/l2_island_fixture.gd")
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
## mesurées restent sous 75 draw calls (tests/integration/demo_hd2d.gd, budget : 200).
const MAX_IMAGES_PER_ZONE := 40
const SHADERS: Array[String] = [
	"res://src/world/shaders/panel.gdshader",
	"res://src/world/shaders/terrain.gdshader",
	"res://src/world/shaders/rock.gdshader",
	"res://src/world/shaders/cloud_sea.gdshader",
	"res://src/world/shaders/waterfall.gdshader",
	"res://src/player/post_fx.gdshader",
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


## Panneaux et bâtiments d'un décor (la racine, ou ses enfants pour un décor composé).
func _parts(node: Node) -> Array[Node]:
	var parts: Array[Node] = []
	if node is DecorPanel or node is Building:
		parts.append(node)
	for child: Node in node.get_children():
		if child is DecorPanel or child is Building:
			parts.append(child)
	return parts


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
			else:
				var building := part as Building
				assert_true(
					building.wall_texture != null and building.roof_texture != null,
					"%s : matières du volume" % prop
				)
		var meshes := node.find_children("*", "MeshInstance3D", true, false)
		for mesh: Node in meshes:
			assert_true(
				mesh.get_parent() is DecorPanel or mesh.get_parent() is Building,
				"%s : aucun maillage 3D hors des panneaux (%s)" % [prop, mesh.name]
			)
		node.free()


func test_blocking_decor_keeps_its_collision() -> void:
	for prop in _props():
		var node := _instance(prop)
		var body := node.get_node_or_null(^"Collision") as StaticBody3D
		if prop in NON_BLOCKING:
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
			var want := Vector2(panel.texture.get_size()) / panel.pixels_per_meter
			assert_almost_eq(panel.size_m(), want, Vector2.ONE * 0.001, prop)
			var quad := panel.get_child(0, true) as MeshInstance3D
			assert_almost_eq((quad.mesh as QuadMesh).size, want, Vector2.ONE * 0.001, prop)
			assert_true(
				(
					panel.pixels_per_meter == DecorPanel.PIXELS_PER_METER
					or prop.contains("island")
					or prop.contains("airship")
					or prop.contains("floating")
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
	var terrain := load("res://src/world/materials/terrain.tres") as ShaderMaterial
	assert_not_null(terrain.get_shader_parameter(&"ground_atlas"), "atlas du sol branché")
	var rock := load("res://src/world/materials/rock.tres") as ShaderMaterial
	for texture: StringName in [&"lip_texture", &"cliff_texture", &"underside_texture"]:
		assert_not_null(rock.get_shader_parameter(texture), "roche : %s" % texture)
