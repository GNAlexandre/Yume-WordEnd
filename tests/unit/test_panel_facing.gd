extends GutTest
## (I1) Vues d'un meuble selon son orientation (docs/ASSETS_HD2D_ILE68.md, section 2.7) :
## - un meuble tourné vers l'est montre son image de flanc (<nom>_side), vers l'ouest la même,
##   retournée, vers le nord son dos (<nom>_back) ou, pour un lit, son pied (<nom>_foot), vers le
##   sud sa face ; sans l'image de la vue, il garde sa face, comme avant ;
## - l'orientation est celle du nœud (sa face est son +Z) ou, si elle est posée, `facing` ;
## - la collision suit la rotation du nœud, la taille du panneau celle de l'image affichée ;
## - les murs de la pièce disent d'où un meuble regarde (InteriorLayout.facing_against_wall), et la
##   carte de l'entrepôt le pose : meubles marqués « regard=… » dans docs/lore/CARTE.md, tournés
##   quand l'image de leur vue existe (images d'essai : tests/data/views/).

const CHEST := preload("res://tests/data/views/chest.png")
const BED := preload("res://tests/data/views/bed.png")
const TABLE := preload("res://tests/data/views/table.png")
const SOFA_SCENE := "res://src/world/props/sofa_beige.tscn"
const MAPS: Array[String] = ["entrepot_rdc", "entrepot_etage"]
const STUB := "res://tests/stubs/t2_map_test.gd"


func _panel(texture: Texture2D, facing: StringName = &"") -> InteriorPanel:
	var panel := InteriorPanel.new()
	panel.texture = texture
	panel.facing = facing
	add_child_autofree(panel)
	return panel


func _shown(panel: DecorPanel) -> String:
	return panel.displayed_texture().resource_path.get_file()


func _first_uv_x(panel: DecorPanel) -> float:
	var quad := panel.get_child(0, true) as MeshInstance3D
	var uvs: PackedVector2Array = quad.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]
	return uvs[0].x


# --- Le choix de la vue -----------------------------------------------------------------------


func test_east_shows_the_side_view_and_the_panel_takes_its_size() -> void:
	var panel := _panel(CHEST, &"east")
	assert_eq(panel.view_name(), &"side")
	assert_eq(_shown(panel), "chest_side.png")
	assert_false(panel.view_flipped())
	assert_eq(panel.texture, CHEST, "la face reste l'image du meuble")
	assert_eq(panel.size_m(), Vector2(48.0, 144.0) / 96.0, "la taille de l'image affichée")
	assert_eq(_first_uv_x(panel), 0.0, "image à l'endroit")


func test_west_shows_the_side_view_flipped() -> void:
	var panel := _panel(CHEST, &"west")
	assert_eq(panel.view_name(), &"side")
	assert_eq(_shown(panel), "chest_side.png")
	assert_true(panel.view_flipped())
	assert_eq(_first_uv_x(panel), 1.0, "image retournée gauche-droite")
	var plain := DecorPanel.new()
	plain.texture = CHEST
	plain.facing = &"west"
	plain.flip_h = true
	add_child_autofree(plain)
	assert_false(plain.view_flipped() != plain.flip_h, "le retournement du flanc s'ajoute à flip_h")


func test_south_keeps_the_front_view() -> void:
	for facing: StringName in [&"south", &""]:
		var panel := _panel(CHEST, facing)
		assert_eq(panel.view_name(), &"front", "face au sud")
		assert_eq(_shown(panel), "chest.png")
		assert_false(panel.view_flipped())


func test_north_shows_the_back_or_the_foot_of_a_bed() -> void:
	assert_eq(_shown(_panel(CHEST, &"north")), "chest_back.png", "le dos")
	var bed := _panel(BED, &"north")
	assert_eq(bed.view_name(), &"foot", "le lit se voit par le pied")
	assert_eq(_shown(bed), "bed_foot.png")
	assert_eq(bed.size_m(), Vector2(96.0, 150.0) / 96.0)


func test_without_the_view_the_front_stays() -> void:
	for facing: StringName in [&"east", &"west", &"north"]:
		var panel := _panel(TABLE, facing)
		assert_eq(panel.view_name(), &"front", "table sans vue, vers %s" % facing)
		assert_eq(_shown(panel), "table.png")
		assert_false(panel.view_flipped(), "pas de retournement sans vue")
		assert_eq(panel.size_m(), Vector2(2.0, 1.0))
	assert_eq(_shown(_panel(BED, &"east")), "bed.png", "un lit n'a pas de flanc livré : sa face")


func test_the_view_follows_the_rotation_of_the_node() -> void:
	var expected := {0.0: &"front", 90.0: &"side", -90.0: &"side", 180.0: &"back"}
	for yaw: float in expected:
		var panel := InteriorPanel.new()
		panel.texture = CHEST
		add_child_autofree(panel)
		panel.rotation_degrees.y = yaw
		panel.rebuild()
		assert_eq(panel.view_name(), expected[yaw], "lacet de %d°" % yaw)
		assert_eq(panel.view_flipped(), yaw == -90.0, "retourné à l'ouest seulement")
	assert_eq(DecorPanel.facing_of(Vector3(0, 0, 1)), &"south")
	assert_eq(DecorPanel.facing_of(Vector3(1, 0, 0)), &"east")
	assert_eq(DecorPanel.facing_of(Vector3(-1, 0, 0.3)), &"west")
	assert_eq(DecorPanel.facing_of(Vector3(0.2, 0, -1)), &"north")
	assert_eq(DecorPanel.facing_of(Vector3.UP), &"south", "sans direction : le sud")


func test_facing_set_on_the_panel_wins_over_the_rotation() -> void:
	var panel := InteriorPanel.new()
	panel.texture = CHEST
	panel.facing = &"east"
	add_child_autofree(panel)
	panel.rotation_degrees.y = 180.0
	panel.rebuild()
	assert_eq(panel.view_name(), &"side")


func test_a_panel_that_keeps_its_orientation_or_animates_keeps_its_front() -> void:
	var kept := _panel(CHEST, &"east")
	kept.keep_orientation = true
	kept.rebuild()
	assert_eq(kept.view_name(), &"front", "keep_orientation : l'image tourne avec le nœud")
	var strip := _panel(CHEST, &"east")
	strip.frames = 2
	strip.rebuild()
	assert_eq(strip.view_name(), &"front", "une bande animée n'a pas de vue")


func test_a_decor_panel_outdoors_picks_its_view_the_same_way() -> void:
	var panel := DecorPanel.new()
	panel.texture = CHEST
	panel.facing = &"east"
	add_child_autofree(panel)
	assert_eq(panel.view_name(), &"side")
	assert_eq(panel.size_m(), Vector2(0.5, 1.5))
	assert_null(DecorPanel.view_texture(CHEST, &"foot"), "pas de vue par le pied pour ce coffre")
	assert_not_null(DecorPanel.view_texture(CHEST, &"side"))
	assert_null(DecorPanel.view_texture(null, &"side"))


# --- Collision et image -----------------------------------------------------------------------


func test_the_collision_and_the_image_follow_the_turned_node() -> void:
	var sofa := (load(SOFA_SCENE) as PackedScene).instantiate() as InteriorPanel
	sofa.facing = &"east"
	sofa.rotation_degrees.y = 90.0
	sofa.image_offset = Vector3(0.0, 0.0, 1.0)
	add_child_autofree(sofa)
	var shape := sofa.get_node(^"Collision/CollisionShape3D") as CollisionShape3D
	var box := (shape.shape as BoxShape3D).size
	var aabb := shape.global_transform * AABB(-box / 2.0, box)
	assert_almost_eq(aabb.size.x, box.z, 0.001, "la profondeur du canapé devient sa largeur en x")
	assert_almost_eq(aabb.size.z, box.x, 0.001, "sa largeur devient sa profondeur en z")
	assert_eq(sofa.view_name(), &"side")
	var side := sofa.displayed_texture()
	assert_eq(Vector2i(side.get_size()), Vector2i(86, 175), "la taille du cahier n° 5 (R0.3)")
	assert_almost_eq(sofa.size_m().x, 86.0 / 96.0, 0.001)
	# L'occulteur est l'image de flanc, posée au bord sud de l'emprise tournée.
	var triangles := sofa.occluder_triangles(InteriorLayout.NO_CUT)
	var lo := INF
	var hi := -INF
	for point in triangles:
		lo = minf(lo, point.x)
		hi = maxf(hi, point.x)
	assert_almost_eq(hi - lo, 86.0 / 96.0, 0.001, "largeur de l'image de flanc")


# --- Les murs disent d'où un meuble regarde ---------------------------------------------------


func _layout() -> InteriorLayout:
	return InteriorLayout.from_data(
		{
			"size": [10, 8],
			"rooms":
			{
				"salle":
				{
					"rects": [[0, 0, 10, 8]],
					"floor": "floor_planks_worn",
					"wall": "wall_plaster_worn"
				}
			}
		}
	)


func test_walls_give_the_facing_of_a_piece_against_them() -> void:
	var plan := _layout()
	assert_eq(plan.problems, [] as Array[String])
	assert_eq(plan.facing_against_wall(Rect2(0.13, 3.0, 0.9, 2.0)), &"east", "au mur ouest")
	assert_eq(plan.facing_against_wall(Rect2(8.97, 3.0, 0.9, 2.0)), &"west", "au mur est")
	assert_eq(plan.facing_against_wall(Rect2(4.0, 0.13, 2.0, 0.6)), &"south", "au mur nord")
	assert_eq(plan.facing_against_wall(Rect2(4.0, 3.0, 2.0, 0.6)), &"", "au milieu : aucune")
	assert_eq(plan.facing_against_wall(Rect2(20.0, 3.0, 1.0, 1.0)), &"", "hors des pièces")


## Vue qu'un meuble de ce regard montre : celle dont l'image existe (flanc pour E et O, dos ou pied
## pour N), sinon sa face.
func _expected_view(planner: GDScript, image: String, regard: String) -> StringName:
	if regard in ["E", "O"]:
		return &"side" if not planner.view_path(image, "side").is_empty() else &"front"
	if not planner.view_path(image, "back").is_empty():
		return &"back"
	return &"foot" if not planner.view_path(image, "foot").is_empty() else &"front"


# --- La carte de l'entrepôt -------------------------------------------------------------------


func test_marked_furniture_of_the_warehouse_has_its_facing_and_is_turned_with_its_view() -> void:
	var planner: GDScript = load(STUB)
	var turned_count := 0
	var marked_count := 0
	for map_id: String in MAPS:
		var map := (
			(load("res://src/world/maps/%s/%s.tscn" % [map_id, map_id]) as PackedScene)
			. instantiate()
		)
		add_child_autofree(map)
		var room := map.get_node(^"Ground") as InteriorRoom
		var plan: Dictionary = planner.read_plan(map_id)
		var wanted := {"E": &"east", "O": &"west", "N": &"north"}
		var by_image := {}
		for panel: Node in map.get_node(^"Geometry").find_children(
			"*", "InteriorPanel", true, false
		):
			var image := (panel as InteriorPanel).texture.resource_path.get_file().get_basename()
			if not by_image.has(image):
				by_image[image] = []
			(by_image[image] as Array).append(panel)
		for item: Dictionary in plan["furniture"]:
			var regard := String(item["regard"])
			if regard.is_empty() or regard == "S":
				continue
			marked_count += 1
			var found: InteriorPanel = null
			for candidate: InteriorPanel in by_image.get(item["image"], []):
				if (
					absf(candidate.position.z - float(item["z"])) < 2.0
					and (absf(candidate.position.x - float(item["x"])) < 2.0)
				):
					found = candidate
			assert_not_null(found, "%s %s : posé" % [map_id, item["image"]])
			if found == null:
				continue
			assert_eq(found.facing, wanted[regard], "%s %s : facing" % [map_id, item["image"]])
			var turned: bool = planner.is_turned(item)
			assert_eq(
				not is_zero_approx(found.rotation.y),
				turned,
				"%s %s : tourné si et seulement si sa vue existe" % [map_id, item["image"]]
			)
			assert_eq(
				found.view_name(),
				_expected_view(planner, String(item["image"]), regard),
				"%s %s : la vue qui existe est montrée" % [map_id, item["image"]]
			)
			if regard != "N":
				assert_eq(
					room.facing_against_wall(found),
					wanted[regard],
					(
						"%s %s : les murs de la pièce le font regarder %s"
						% [map_id, item["image"], regard]
					)
				)
			if turned:
				turned_count += 1
	assert_gt(marked_count, 15, "meubles marqués du plan")
	assert_gt(turned_count, 2, "au moins le canapé, la bibliothèque et l'armoire tournés")
