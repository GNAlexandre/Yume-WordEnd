extends GutTest
## (AN) Allure et pas de CharacterVisual : cadence de « marche » et de « course » proportionnelle à
## la vitesse au sol réelle (match_stride : pas de patinage), mesurée d'image en image ; fin du pas
## avant le repos (settle) ; changement de vue (et de côté de l'épée) au début d'un pas, jamais en
## plein pas ; planche lue « nette mais lissée » (character_sprite.gdshader) sur la planche de
## l'image affichée.

const VISUAL := preload("res://src/visuals/character_visual.tscn")
const CHTHOLLY := preload("res://data/skins/chtholly.tres")
const SPRITE_SHADER := preload("res://src/visuals/character_sprite.gdshader")
const DT := 1.0 / 60.0


## Visuel dans l'arbre, horloge à l'arrêt (les tests l'avancent), sans caméra.
func _visual(match_stride: bool = true) -> CharacterVisual:
	var visual: CharacterVisual = add_child_autofree(VISUAL.instantiate())
	visual.set_process(false)
	visual.match_stride = match_stride
	visual.set_skin(CHTHOLLY)
	return visual


func _sprite(visual: CharacterVisual) -> AnimatedSprite3D:
	return visual.get_node(^"Sprite") as AnimatedSprite3D


func test_drawn_speeds_match_the_sheet() -> void:
	var visual := _visual()
	# Chtholly : 84 px de planche par cycle de marche (6 images à 10 i/s), 147 par cycle de course
	# (5 images à 14 i/s), 0,0104 m par pixel.
	assert_almost_eq(visual.drawn_speed(&"marche"), 1.46, 0.02, "marche dessinée : 1,46 m/s")
	assert_almost_eq(visual.drawn_speed(&"course"), 4.29, 0.03, "course dessinée : 4,3 m/s")
	assert_eq(visual.drawn_speed(&"repos"), 0.0, "le repos ne se déplace pas")
	assert_eq(visual.step_frames(&"marche"), [0, 3] as Array[int], "deux pas par cycle")
	assert_eq(visual.step_frames(&"course"), [0, 3] as Array[int])


func test_walk_cadence_follows_the_ground_speed() -> void:
	var visual := _visual()
	visual.play(&"marche")
	visual.set_ground_speed(visual.drawn_speed(&"marche") * 2.0)
	assert_almost_eq(visual.stride_rate(), 2.0, 0.001, "deux fois plus vite, deux fois plus de pas")
	visual.advance(0.25)
	# 10 i/s × 2 × 0,25 s = 5 images : les pieds parcourent le sol à la vitesse du corps.
	assert_eq(visual.current_frame(), 5, "cadence doublée")
	visual.set_ground_speed(visual.drawn_speed(&"marche") * 0.5)
	visual.advance(0.2)
	assert_eq(visual.current_frame(), 0, "à mi-vitesse, une image en 0,2 s")
	visual.set_ground_speed(0.0)
	assert_almost_eq(visual.stride_rate(), 0.5, 0.001, "à l'arrêt, la dernière cadence reste")
	visual.set_ground_speed(100.0)
	assert_eq(visual.stride_rate(), CharacterVisual.MAX_STRIDE_RATE, "bornée")


func test_without_match_stride_the_json_cadence_stays() -> void:
	var visual := _visual(false)
	visual.play(&"marche")
	visual.set_ground_speed(visual.drawn_speed(&"marche") * 2.0)
	visual.advance(0.25)
	assert_eq(visual.current_frame(), 2, "10 i/s, comme le JSON (ennemis, faune)")


func test_ground_speed_is_measured_from_the_motion() -> void:
	var visual := _visual()
	visual.play(&"course")
	for _i in 60:
		visual.position.x += 5.8 * DT
		visual._process(DT)
	assert_almost_eq(visual.ground_speed(), 5.8, 0.05, "vitesse au sol mesurée")
	assert_almost_eq(
		visual.stride_rate(), 5.8 / visual.drawn_speed(&"course"), 0.02, "cadence de course"
	)
	var rate := visual.stride_rate()
	visual.position.x += 40.0
	visual._process(DT)
	assert_almost_eq(visual.ground_speed(), 5.8, 0.05, "une téléportation ne compte pas")
	assert_almost_eq(visual.stride_rate(), rate, 0.001)


func test_settle_finishes_the_step_before_idling() -> void:
	var visual := _visual()
	visual.play(&"marche")
	visual.set_ground_speed(visual.drawn_speed(&"marche"))
	visual.advance(0.1)
	assert_eq(visual.current_frame(), 1, "en plein pas")
	visual.settle(&"repos")
	assert_eq(visual.current_animation(), &"marche", "la foulée continue")
	assert_eq(visual.settling_to(), &"repos")
	visual.advance(0.1)
	assert_eq(visual.current_animation(), &"marche", "image 2 : toujours en l'air")
	visual.advance(0.1)
	assert_eq(visual.current_animation(), &"repos", "image 3 : pied posé, repos")
	assert_eq(visual.settling_to(), &"")
	# Déjà à une image de contact : tout de suite.
	visual.play(&"marche")
	visual.settle(&"repos")
	assert_eq(visual.current_animation(), &"repos", "à l'image 0, le repos vient aussitôt")
	# Un play() entre-temps annule l'attente.
	visual.play(&"marche")
	visual.advance(0.1)
	visual.settle(&"repos")
	visual.play(&"marche")
	assert_eq(visual.settling_to(), &"", "annulé")
	visual.advance(0.3)
	assert_eq(visual.current_animation(), &"marche")


func test_view_changes_wait_for_the_start_of_a_step() -> void:
	var visual := _visual()
	visual.set_facing(Vector3.RIGHT)
	visual.play(&"marche")
	visual.set_ground_speed(visual.drawn_speed(&"marche"))
	visual.advance(0.1)
	assert_eq(visual.current_frame(), 1)
	visual.set_facing(Vector3.FORWARD)
	assert_eq(visual.current_view(), SheetLoader.SIDE, "en plein pas : la vue attend")
	visual.advance(0.1)
	visual._update_facing()
	assert_eq(visual.current_view(), SheetLoader.SIDE, "image 2 : elle attend encore")
	visual.advance(0.1)
	visual._update_facing()
	assert_eq(visual.current_view(), SheetLoader.BACK, "image 3 : le pas commence, le dos")
	# Un demi-tour de profil se retourne tout de suite.
	visual.set_facing(Vector3.RIGHT)
	visual.advance(0.1)
	visual._update_facing()
	assert_eq(visual.current_frame(), 4)
	visual.set_facing(Vector3.LEFT)
	assert_true(_sprite(visual).flip_h, "retourné sans attendre")
	# Au repos, la vue change aussitôt.
	visual.play(&"repos")
	visual.set_facing(Vector3.BACK)
	assert_eq(visual.current_view(), SheetLoader.FRONT, "au repos : aussitôt")


func test_sprite_reads_the_sheet_smoothed() -> void:
	var visual := _visual()
	var material := _sprite(visual).material_override as ShaderMaterial
	assert_not_null(material, "matériau propre au sprite")
	assert_eq(material.shader, SPRITE_SHADER, "planche nette mais lissée")
	assert_true(SPRITE_SHADER.code.contains("pixel_art.gdshaderinc"), "même lissage que le décor")
	var image := _sprite(visual).sprite_frames.get_frame_texture(
		visual.current_animation(), visual.current_frame()
	)
	assert_eq(
		material.get_shader_parameter(&"sheet"), (image as AtlasTexture).atlas, "planche du profil"
	)
	visual.set_facing(Vector3.BACK)
	image = _sprite(visual).sprite_frames.get_frame_texture(
		visual.current_animation(), visual.current_frame()
	)
	assert_eq(
		material.get_shader_parameter(&"sheet"), (image as AtlasTexture).atlas, "planche de face"
	)
	assert_ne(material.get_shader_parameter(&"sheet"), CHTHOLLY.sprite_sheet, "pas celle du profil")
	var other: CharacterVisual = _visual()
	assert_ne(
		_sprite(other).material_override as ShaderMaterial, material, "un matériau par visuel"
	)
