extends GutTest
## (E8b) Les effets de la vision accélérée (GameVision) : les réglages ajoutés au post-traitement
## (pale_amount, pale_center, pale_radius, flash_color : nuls par défaut, sans effet) ; begin()
## retient leur état et end() le rend tel quel ; le ralenti des visuels (leur horloge menée par
## tick, rendue à la fin).

const POST_SHADER := preload("res://src/player/post_fx.gdshader")
const VISUAL := preload("res://src/visuals/character_visual.tscn")
const SKIN := preload("res://data/npcs/outfits/willem_duel.tres")


func _material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = POST_SHADER
	return material


func _uniform_defaults() -> Dictionary:
	var found := {}
	for entry: Dictionary in POST_SHADER.get_shader_uniform_list():
		found[StringName(entry["name"])] = entry
	return found


func test_the_post_shader_has_the_game_effects_off_by_default() -> void:
	var uniforms := _uniform_defaults()
	for key: StringName in GameVision.UNIFORMS:
		assert_true(uniforms.has(key), "uniforme %s" % key)
	# Valeurs par défaut lues dans le code (le rendu headless ne les donne pas).
	var code := POST_SHADER.code
	assert_string_contains(code, "uniform float pale_amount = 0.0;", "aucune pâleur")
	assert_string_contains(code, "uniform float pale_radius = 0.0;")
	assert_string_contains(
		code, "uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 0.0);", "aucun blanc"
	)
	assert_string_contains(code, "if (pale_amount > 0.0)", "sans effet à zéro")
	assert_string_contains(code, "c = mix(c, flash_color.rgb, flash_color.a);")
	# Atmosphere ne pose jamais ces uniformes (ils ne sont pas des réglages de lumière).
	var lighting := HD2DLighting.new()
	for key: StringName in GameVision.UNIFORMS:
		assert_false(lighting.post_parameters().has(key), "%s hors de l'étalonnage" % key)


func test_effects_apply_then_the_post_processing_returns_to_its_state() -> void:
	var material := _material()
	material.set_shader_parameter(&"pale_center", Vector2(0.2, 0.7))
	material.set_shader_parameter(&"saturation", 1.2)
	var before := {}
	for key: StringName in GameVision.UNIFORMS:
		before[key] = material.get_shader_parameter(key)
	var vision := GameVision.new()
	vision.begin(material)
	assert_true(vision.is_active())
	vision.set_pale(0.6, Vector2(0.4, 0.55), 0.16)
	vision.set_flash(1.0)
	assert_almost_eq(float(material.get_shader_parameter(&"pale_amount")), 0.6, 0.0001)
	assert_eq(material.get_shader_parameter(&"pale_center"), Vector2(0.4, 0.55))
	assert_almost_eq(float(material.get_shader_parameter(&"pale_radius")), 0.16, 0.0001)
	assert_eq(material.get_shader_parameter(&"flash_color"), Color(1, 1, 1, 1), "écran blanc")
	assert_eq(vision.pale(), 0.6)
	assert_eq(vision.flash(), 1.0)
	vision.end()
	assert_false(vision.is_active())
	for key: StringName in GameVision.UNIFORMS:
		assert_eq(material.get_shader_parameter(key), before[key], "%s rendu" % key)
	assert_eq(material.get_shader_parameter(&"saturation"), 1.2, "le reste n'est pas touché")
	assert_eq(vision.pale(), 0.0)


func test_without_post_processing_the_effects_are_only_remembered() -> void:
	var vision := GameVision.new()
	assert_null(GameVision.post_material(null))
	vision.begin(null)
	vision.set_pale(0.6)
	vision.set_flash(0.5)
	assert_eq(vision.pale(), 0.6)
	assert_eq(vision.flash(), 0.5)
	vision.end()


func test_slowed_visuals_follow_the_vision_clock_then_get_theirs_back() -> void:
	var visual: CharacterVisual = add_child_autofree(VISUAL.instantiate())
	visual.set_skin(SKIN)
	visual.play(&"marche", true)
	var vision := GameVision.new()
	var slowed: Array[CharacterVisual] = [visual]
	vision.slow(slowed, 0.6)
	assert_false(visual.is_processing(), "son horloge est menée par la vision")
	assert_eq(vision.time_scale, 0.6)
	# marche : 10 images par seconde ; 1 s de vision n'en montre que 6.
	vision.tick(1.0 - 0.05)
	assert_eq(visual.current_frame(), 5, "au ralenti : 0,57 s d'animation")
	vision.end()
	assert_true(visual.is_processing(), "rendue")
	assert_eq(vision.time_scale, 1.0)
	assert_true(vision.slowed().is_empty())
