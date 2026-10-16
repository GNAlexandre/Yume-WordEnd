extends GutTest
## (RD) Rendu de la profondeur : genres des décors (DecorGenre), ombre peinte à la taille du panneau
## et tournée par le soleil (DecorPanel.shadow_mesh_for, AtmosphereRig.apply_shadow_sun), vent des
## seuls végétaux (wind_px du matériau), variation de teinte portée par le mesh fondu
## (DecorPanel.tone, PropBatcher), variation automatique et règle de la rangée de PropScatter,
## matériaux mélangés qui se floutent eux-mêmes (DepthFocus).

const OAK := preload("res://assets/hd2d/props/oak_a.png")
const RAILING := preload("res://assets/hd2d/props/town_railing.png")
const OAK_SCENE := preload("res://src/world/props/oak_a.tscn")
const BEECH_SCENE := preload("res://src/world/props/beech_a.tscn")
const MAPLE_SCENE := preload("res://src/world/props/maple_a.tscn")


func _panel(texture: Texture2D, at: Vector3 = Vector3.ZERO) -> DecorPanel:
	var panel := DecorPanel.new()
	panel.texture = texture
	panel.position = at
	add_child_autofree(panel)
	return panel


func _shapes(mesh: ArrayMesh) -> Array[int]:
	var shapes: Array[int] = []
	var uvs: PackedVector2Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]
	for k in range(0, uvs.size(), 6):
		shapes.append(floori(uvs[k].x * 0.5 + 0.001))
	return shapes


func test_genres_from_category_and_image_name() -> void:
	assert_eq(DecorGenre.of("res://assets/hd2d/props/oak_a.png"), DecorGenre.TREE)
	assert_eq(DecorGenre.of("res://assets/hd2d/props/reeds_b.png"), DecorGenre.REED)
	assert_eq(DecorGenre.of("res://assets/hd2d/props/cattails.png"), DecorGenre.REED)
	assert_eq(DecorGenre.of("res://assets/hd2d/props/thicket_a.png"), DecorGenre.BUSH)
	assert_eq(DecorGenre.of("res://assets/hd2d/props/grass_clump_a.png"), DecorGenre.GRASS)
	assert_eq(DecorGenre.of("res://assets/hd2d/props/town_railing.png"), DecorGenre.FENCE)
	assert_eq(DecorGenre.of("res://assets/hd2d/props/forest_wall_a.png"), DecorGenre.LISIERE)
	assert_eq(DecorGenre.of("res://assets/hd2d/props/boulder_a.png"), DecorGenre.ROCK)
	assert_eq(DecorGenre.of("res://assets/hd2d/props/crate.png"), DecorGenre.PROP)
	assert_eq(DecorGenre.of("res://assets/hd2d/props/flower_pots.png"), DecorGenre.PROP)
	assert_eq(DecorGenre.of(""), DecorGenre.NONE, "image sans nom : aucun genre")
	assert_eq(DecorGenre.of("res://x/oak.png", &"plant_low"), DecorGenre.GRASS, "catégorie")
	assert_eq(DecorGenre.of("res://x/oak.png", &"wall_detail"), DecorGenre.NONE, "contre un mur")
	for windy: StringName in [DecorGenre.TREE, DecorGenre.GRASS, DecorGenre.REED, DecorGenre.BUSH]:
		assert_true(DecorGenre.is_windy(windy), String(windy))
	for still: StringName in [DecorGenre.FENCE, DecorGenre.ROCK, DecorGenre.PROP, DecorGenre.NONE]:
		assert_false(DecorGenre.is_windy(still), String(still))
	# La scène porte sa catégorie (metadata/hd2d_category) : elle passe avant le nom.
	var scene_panel := OAK_SCENE.instantiate() as DecorPanel
	assert_eq(scene_panel.current_genre(), DecorGenre.TREE)
	scene_panel.genre = DecorGenre.ROCK
	assert_eq(scene_panel.current_genre(), DecorGenre.ROCK, "genre forcé")
	scene_panel.free()


func test_tone_code_round_trip() -> void:
	assert_eq(DecorPanel.tone_code(Vector2.ZERO), 0, "sans variation : rien dans UV2")
	var codes := {}
	for bright: float in [-0.06, -0.03, 0.0, 0.025, 0.06]:
		for hue: float in [-0.03, 0.0, 0.015, 0.03]:
			var tone := Vector2(bright, hue)
			if tone.is_zero_approx():
				continue
			var code := DecorPanel.tone_code(tone)
			assert_between(code, 1, DecorPanel.TONE_LEVELS * DecorPanel.TONE_HUE_LEVELS)
			var back := DecorPanel.tone_from_code(code)
			assert_almost_eq(back.x, bright, DecorPanel.TONE_BRIGHT / 24.0 + 0.0001)
			assert_almost_eq(back.y, hue, DecorPanel.TONE_HUE / 12.0 + 0.0001)
			codes[code] = true
	assert_gt(codes.size(), 15, "des codes différents")
	var clamped := DecorPanel.tone_from_code(DecorPanel.tone_code(Vector2(0.5, -0.5)))
	assert_almost_eq(clamped, Vector2(0.06, -0.03), Vector2.ONE * 0.0001, "borné")


func test_wind_only_for_vegetation() -> void:
	var oak := _panel(OAK)
	var railing := _panel(RAILING, Vector3(6, 0, 0))
	var oak_material := oak.get_node(^"Quad").material_override as ShaderMaterial
	var oak_wind := float(oak_material.get_shader_parameter(&"wind_px"))
	assert_between(oak_wind, 1.0, 5.0, "la cime d'un arbre se balance (px de l'image)")
	assert_lt(float(oak_material.get_shader_parameter(&"wind_from")), 0.6, "le tronc reste")
	var railing_material := railing.get_node(^"Quad").material_override as ShaderMaterial
	var railing_wind: Variant = railing_material.get_shader_parameter(&"wind_px")
	assert_true(railing_wind == null or float(railing_wind) == 0.0, "une clôture ne bouge pas")
	assert_ne(oak_material, railing_material)
	var building := Building.new()
	building.facade = RAILING
	add_child_autofree(building)
	var facade := building.get_node(^"Facade").material_override as ShaderMaterial
	var facade_wind: Variant = facade.get_shader_parameter(&"wind_px")
	assert_true(facade_wind == null or float(facade_wind) == 0.0, "jamais un bâtiment")
	# Le vent est dans le shader des panneaux, fondus compris.
	var core := FileAccess.get_file_as_string("res://src/world/shaders/panel_core.gdshaderinc")
	assert_string_contains(core, "panel_wind_uv")
	for shader_name: String in ["panel", "panel_soft", "panel_foreground"]:
		var code := FileAccess.get_file_as_string(
			"res://src/world/shaders/%s.gdshader" % shader_name
		)
		assert_string_contains(code, "panel_wind_uv(", shader_name)
		assert_string_contains(code, "panel_apply_tone(", shader_name)


func test_painted_shadow_sized_to_the_panel() -> void:
	var oak := _panel(OAK)
	var shadow := oak.get_node(^"Shadow") as MeshInstance3D
	var mesh := shadow.mesh as ArrayMesh
	assert_not_null(mesh, "ombre peinte")
	assert_eq(shadow.material_override, DecorPanel.shadow_material(), "un matériau pour toutes")
	assert_eq(
		_shapes(mesh), [DecorPanel.SHADOW_CORE, DecorPanel.SHADOW_TAIL], "cœur ovale et traîne"
	)
	var size := oak.size_m()
	var aabb := mesh.get_aabb()
	assert_almost_eq(aabb.position.x, -size.x * oak.shadow_width / 2.0, 0.01, "à la largeur")
	var tail := minf(size.y * float(DecorGenre.settings(DecorGenre.TREE)["tail"]), 6.0)
	assert_almost_eq(aabb.end.x, tail, 0.01, "traîne vers l'est, d'une part de la hauteur")
	assert_true(shadow.global_basis.is_equal_approx(Basis.IDENTITY), "sans rotation")
	# Décor long : bande au pied et ombre portée en parallélogramme.
	var railing := _panel(RAILING, Vector3(8, 0, 0))
	var long_mesh := (railing.get_node(^"Shadow") as MeshInstance3D).mesh as ArrayMesh
	assert_eq(_shapes(long_mesh), [DecorPanel.SHADOW_STRIP, DecorPanel.SHADOW_TAIL_LONG], "bande")
	# Plus grand panneau, plus grande ombre ; sans ombre, pas de mesh.
	var big := _panel(OAK, Vector3(-8, 0, 0))
	big.scale = Vector3.ONE * 1.5
	big.rebuild()
	var big_aabb := ((big.get_node(^"Shadow") as MeshInstance3D).mesh as ArrayMesh).get_aabb()
	assert_gt(big_aabb.size.z, aabb.size.z * 1.4, "à l'échelle de l'exemplaire")
	oak.shadow_width = 0.0
	oak.rebuild()
	assert_null(shadow.mesh, "shadow_width 0 : pas d'ombre")
	assert_false(shadow.visible)


func test_shadow_follows_the_sun() -> void:
	var material := DecorPanel.shadow_material()
	AtmosphereRig.apply_shadow_sun(HD2DLighting.preset(&"couchant"))
	var evening: Vector2 = material.get_shader_parameter(&"sun_away")
	assert_gt(evening.x, 0.8, "au couchant, les ombres partent vers l'est")
	var evening_length := float(material.get_shader_parameter(&"sun_length"))
	AtmosphereRig.apply_shadow_sun(HD2DLighting.preset(&"matin"))
	var morning: Vector2 = material.get_shader_parameter(&"sun_away")
	assert_lt(morning.x, -0.5, "le matin, vers l'ouest")
	AtmosphereRig.apply_shadow_sun(HD2DLighting.preset(&"apres_midi"))
	assert_lt(
		float(material.get_shader_parameter(&"sun_length")), evening_length, "soleil haut : courte"
	)
	AtmosphereRig.apply_shadow_sun(HD2DLighting.preset(&"nuit"))
	assert_lt(float(material.get_shader_parameter(&"tail_strength")), 0.5, "la nuit, pâle")
	assert_gt(float(material.get_shader_parameter(&"core_strength")), 0.5, "le pied reste")
	AtmosphereRig.apply_shadow_sun(HD2DLighting.preset(&"couchant"), true)
	assert_eq(float(material.get_shader_parameter(&"tail_strength")), 0.0, "dedans : pas de traîne")
	AtmosphereRig.apply_shadow_sun(HD2DLighting.preset(&"couchant"))
	var building := Building.new()
	building.facade = RAILING
	building.footprint = Vector2(6, 4)
	add_child_autofree(building)
	var foot := building.get_node(^"Shadow") as MeshInstance3D
	assert_not_null(foot.mesh, "ombre au pied d'un bâtiment")
	assert_eq(foot.material_override, material)
	assert_eq(
		_shapes(foot.mesh as ArrayMesh), [DecorPanel.SHADOW_STRIP, DecorPanel.SHADOW_TAIL_LONG]
	)
	assert_almost_eq(foot.global_position.z, 2.0, 0.01, "au pied de la façade sud")


func test_batcher_keeps_one_mesh_per_image_with_tones() -> void:
	var batcher := PropBatcher.new()
	add_child_autofree(batcher)
	var tones: Array[Vector2] = [Vector2(0.06, 0.0), Vector2(-0.03, 0.03), Vector2.ZERO]
	for k in tones.size():
		var panel := DecorPanel.new()
		panel.texture = OAK
		panel.tone = tones[k]
		panel.shadow_width = 0.0
		panel.position = Vector3(k * 20.0, 0.0, 0.0)
		batcher.add_child(panel)
	var created := batcher.batch()
	assert_eq(created, 1, "un mesh pour l'image, quelles que soient les teintes")
	var merged: MeshInstance3D
	for child in batcher.get_children():
		if child is MeshInstance3D and String(child.name).begins_with("Batch"):
			merged = child
	var arrays := merged.mesh.surface_get_arrays(0)
	var uv2s: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2]
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for n in vertices.size():
		var k := roundi(vertices[n].x / 20.0)
		assert_eq(floori(uv2s[n].x), DecorPanel.tone_code(tones[k]), "sommet %d" % n)


func test_scatter_varies_by_position_and_breaks_rows() -> void:
	var scatter := PropScatter.new()
	scatter.follow_ground = false
	var row := PackedVector3Array()
	for i in 24:
		row.append(Vector3(i * 4.1, 0.0, 0.0))
	scatter.points = row
	scatter.prop = OAK_SCENE
	var others: Array[PackedScene] = [BEECH_SCENE, MAPLE_SCENE]
	scatter.variants = others
	scatter.random_seed = 3
	add_child_autofree(scatter)
	var instances := scatter.get_children(true)
	assert_eq(instances.size(), 24)
	var settings := DecorGenre.settings(DecorGenre.TREE)
	var tone_range: Vector2 = settings["tone"]
	var scales: Vector2 = settings["scale"]
	var tones := {}
	for i in instances.size():
		var panel := instances[i] as DecorPanel
		assert_lte(absf(panel.tone.x), tone_range.x + 0.0001, "luminosité ± 6 %")
		assert_lte(absf(panel.tone.y), tone_range.y + 0.0001, "teinte ± 3 %")
		tones[panel.tone] = true
		var size := panel.transform.basis.get_scale().x
		assert_between(size, scales.x - 0.001, scales.y + 0.001, "échelle du genre")
		assert_lte(absf(panel.position.z), float(settings["jitter"]) + 0.001, "léger recul")
		assert_lte(panel.position.y, 0.0, "enfoncé, jamais en l'air")
		if i > 0:
			assert_ne(
				panel.texture,
				(instances[i - 1] as DecorPanel).texture,
				"jamais deux fois la même image de suite (%d)" % i
			)
	assert_gt(tones.size(), 18, "une teinte par exemplaire")
	# Tirée de la position seule : la même avec une autre graine.
	var first := PropScatter.variation_at(row[5], DecorGenre.TREE)
	assert_eq(PropScatter.variation_at(row[5], DecorGenre.TREE), first, "stable")
	assert_ne(PropScatter.variation_at(row[6], DecorGenre.TREE), first, "par position")
	scatter.random_seed = 9
	scatter.rebuild()
	assert_eq((scatter.get_children(true)[5] as DecorPanel).tone, first["tone"])
	# Sans genre (image sans nom) ni variation automatique : rien ne bouge.
	scatter.auto_variation = false
	scatter.rebuild()
	for node in scatter.get_children(true):
		assert_eq((node as DecorPanel).tone, Vector2.ZERO)
		assert_eq((node as Node3D).position.z, 0.0)


func test_avoid_runs_keeps_the_nearest_neighbor_rule() -> void:
	for seed_value in 15:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var points := PackedVector3Array()
		for i in 30:
			points.append(Vector3(i * 2.0 + rng.randf_range(-0.5, 0.5), 0, rng.randf_range(-1, 1)))
		var picks := PropScatter.pick_variants(points, 3, seed_value)
		var fixed := PropScatter.avoid_runs(points, picks, 3)
		var order := PropScatter.row_order(points)
		for k in range(1, order.size()):
			assert_ne(fixed[order[k]], fixed[order[k - 1]], "graine %d, rang %d" % [seed_value, k])
		for i in points.size():
			var nearest := PropScatter.nearest_neighbor(points, i)
			assert_ne(fixed[i], fixed[nearest], "plus proche voisin (graine %d)" % seed_value)


func test_blended_materials_blur_themselves() -> void:
	var soft := DecorPanel.material_for(OAK, Color.WHITE, 0.0, 1, 0.0, false, true)
	assert_true(DepthFocus.is_registered(soft as ShaderMaterial), "panneau à alpha doux")
	var decal := GroundDecal.material_for(OAK, Color.WHITE, true, 1)
	assert_true(DepthFocus.is_registered(decal as ShaderMaterial), "décalque doux")
	assert_true(DepthFocus.is_registered(DecorPanel.shadow_material()), "ombres")
	var before := DepthFocus.current()
	DepthFocus.apply({&"focus_depth": 33.0})
	assert_almost_eq(
		float((soft as ShaderMaterial).get_shader_parameter(&"focus_depth")), 33.0, 0.001
	)
	assert_eq(DepthFocus.apply({&"focus_depth": 33.001}), 0, "valeur inchangée : rien recopié")
	DepthFocus.apply(before)
	# La courbe : nette autour du joueur, floue devant, adoucie au loin.
	assert_eq(DepthFocus.radius_px(21.0), 0.0)
	assert_almost_eq(DepthFocus.radius_px(21.0 - 1.8 - 3.5), 7.0, 0.001, "premier plan")
	assert_almost_eq(DepthFocus.radius_px(21.0 + 4.0 + 16.0), 5.0, 0.001, "lointain")
