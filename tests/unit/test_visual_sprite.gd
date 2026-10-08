extends GutTest
## CharacterVisual (L3), variante planche : frame_changed pour chaque image à la cadence ips
## (le temps avance par advance()), animation_finished, play sans relance, show_frame,
## set_facing selon la caméra, ancres au sol, échelle et ombre, changement de skin à chaud.

const VISUAL := preload("res://src/visuals/character_visual.tscn")
const PLAYER := preload("res://src/player/player.tscn")
const CHTHOLLY := preload("res://data/skins/chtholly.tres")
const TIMERE := preload("res://data/enemies/visuals/timere.tres")
const NEPHREN := preload("res://data/npcs/visuals/nephren.tres")
const PLAYER_ANIMS: Array[StringName] = [
	&"repos", &"marche", &"course", &"attaque", &"charge", &"degats", &"mort"
]
## Marque de animation_finished dans _events.
const FINISHED := -1
## Dossier de skins temporaire (Chtholly est le seul skin jouable de data/skins).
const SKINS_TEST_DIR := "user://act1_skins"

## Signaux reçus, dans l'ordre : [anim, image] ou [anim, FINISHED].
var _events: Array = []


func after_each() -> void:
	GameState.reset()


## Visuel dans l'arbre, horloge à l'arrêt (le temps n'avance que par advance()).
func _visual(skin: SkinData) -> CharacterVisual:
	var visual: CharacterVisual = add_child_autofree(VISUAL.instantiate())
	visual.set_process(false)
	visual.set_skin(skin)
	_events.clear()
	visual.frame_changed.connect(
		func(anim: StringName, frame: int) -> void: _events.append([anim, frame])
	)
	visual.animation_finished.connect(
		func(anim: StringName) -> void: _events.append([anim, FINISHED])
	)
	return visual


func _sprite(visual: CharacterVisual) -> AnimatedSprite3D:
	return visual.get_node(^"Sprite") as AnimatedSprite3D


func test_skin_has_its_animations_and_starts_idle() -> void:
	var visual := _visual(CHTHOLLY)
	for anim in PLAYER_ANIMS:
		assert_true(visual.has_animation(anim), String(anim))
	assert_false(visual.has_animation(&"fouet"))
	assert_eq(visual.current_animation(), &"repos")
	assert_true(visual.is_playing())
	var sprite := _sprite(visual)
	assert_almost_eq(sprite.pixel_size, 1.5 / 144.0, 1e-6, "1,5 m pour 144 px")
	assert_eq(sprite.billboard, BaseMaterial3D.BILLBOARD_FIXED_Y, "billboard axe Y")
	assert_eq(sprite.texture_filter, BaseMaterial3D.TEXTURE_FILTER_NEAREST, "pixel art net")
	assert_eq(sprite.alpha_cut, SpriteBase3D.ALPHA_CUT_DISCARD, "alpha scissor, pas de tri")
	assert_eq(sprite.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	assert_false(sprite.is_playing(), "l'horloge est celle du visuel")


func test_attack_emits_each_frame_at_its_rate_then_finishes() -> void:
	var visual := _visual(CHTHOLLY)
	visual.play(&"attaque")
	assert_eq(_events, [[&"attaque", 0]], "image 0 émise au lancement")
	var frame_time := 1.0 / 14.0
	for i in range(1, 4):
		visual.advance(frame_time * 0.5)
		assert_eq(_events.size(), i, "rien avant 1 / ips")
		visual.advance(frame_time * 0.5)
		assert_eq(_events.back(), [&"attaque", i], "image %d" % i)
	visual.advance(frame_time * 0.98)
	assert_eq(_events.size(), 4, "la dernière image dure aussi 1 / ips")
	visual.advance(frame_time * 0.04)
	assert_eq(_events.back(), [&"attaque", FINISHED], "fin après 4 / 14 s")
	visual.advance(1.0)
	assert_eq(_events.size(), 5, "plus rien après la fin")
	assert_eq(visual.current_frame(), 3, "reste sur la dernière image")
	assert_false(visual.is_playing())


func test_loop_emits_every_frame_including_frame_zero() -> void:
	var visual := _visual(CHTHOLLY)
	visual.play(&"marche")
	for i in 20:
		visual.advance(0.05)
	var frames: Array = []
	for event: Array in _events:
		frames.append(event[1])
	assert_eq(frames, [0, 1, 2, 3, 4, 5, 0, 1, 2, 3, 4], "1 s à 10 ips : 10 images après l'image 0")
	_events.clear()
	visual.play(&"course", true)
	visual.advance(10.0)
	assert_eq(_events.size(), 6, "grand saut : image 0 puis un tour au plus")
	assert_eq(visual.current_frame(), 140 % 5)


func test_every_animation_runs_at_its_rate() -> void:
	for skin: SkinData in [CHTHOLLY, TIMERE]:
		var visual := _visual(skin)
		var anims := SheetLoader.animations(SheetLoader.read_sheet(skin))
		for anim: String in anims:
			var count: int = anims[anim]["images"].size()
			var frame_time := 1.0 / float(anims[anim]["ips"])
			var expected: Array = []
			for i in range(1, count):
				expected.append([StringName(anim), i])
			expected.append([StringName(anim), 0 if anims[anim]["boucle"] else FINISHED])
			visual.play(StringName(anim), true)
			_events.clear()
			for i in count:
				visual.advance(frame_time)
			assert_eq(_events, expected, "%s / %s : une image toutes les 1 / ips" % [skin.id, anim])


func test_long_delta_emits_skipped_frames_in_order() -> void:
	var visual := _visual(TIMERE)
	visual.play(&"fouet")
	visual.advance(1.0)
	assert_eq(
		_events,
		[[&"fouet", 0], [&"fouet", 1], [&"fouet", 2], [&"fouet", 3], [&"fouet", FINISHED]],
		"les images « coup » ne sont jamais sautées"
	)


func test_play_does_not_restart_the_current_animation() -> void:
	var visual := _visual(CHTHOLLY)
	visual.play(&"marche")
	visual.advance(0.25)
	_events.clear()
	visual.play(&"marche")
	assert_eq(_events, [], "pas de relance")
	assert_eq(visual.current_frame(), 2)
	visual.play(&"marche", true)
	assert_eq(_events, [[&"marche", 0]], "restart relance depuis l'image 0")
	visual.play(&"degats")
	visual.advance(0.5)
	_events.clear()
	visual.play(&"degats")
	visual.advance(0.6)
	assert_eq(_events, [[&"degats", FINISHED]], "en cours : pas de relance, une seule fin")
	_events.clear()
	visual.play(&"degats")
	assert_eq(_events, [[&"degats", 0]], "finie : play la relance (comme AnimatedSprite3D)")
	visual.play(&"fouet")
	assert_eq(visual.current_animation(), &"degats", "animation absente du skin : sans effet")


func test_show_frame_freezes_and_play_resumes() -> void:
	var visual := _visual(CHTHOLLY)
	visual.show_frame(&"charge", 2)
	assert_eq(_events, [[&"charge", 2]])
	visual.advance(1.0)
	assert_eq(visual.current_frame(), 2, "figée")
	visual.show_frame(&"charge", 2)
	assert_eq(_events.size(), 1, "même image : pas de signal")
	visual.show_frame(&"charge", 1)
	visual.show_frame(&"charge", 99)
	assert_eq(_events.slice(1), [[&"charge", 1], [&"charge", 3]], "image bornée à la dernière")
	visual.show_frame(&"charge", 2)
	_events.clear()
	visual.play(&"charge")
	visual.advance(0.1)
	visual.advance(0.1)
	assert_eq(_events, [[&"charge", 3], [&"charge", FINISHED]], "reprend à l'image 2")


func test_hit_and_wave_frames_come_from_the_sheet() -> void:
	var visual := _visual(CHTHOLLY)
	assert_eq(visual.hit_frames(&"attaque"), [1, 2, 3] as Array[int])
	assert_eq(visual.wave_frame(&"charge"), 3)
	assert_eq(visual.wave_frame(&"attaque"), -1)
	visual.set_skin(TIMERE)
	assert_eq(visual.hit_frames(&"fouet"), [1, 2] as Array[int])
	assert_eq(visual.hit_frames(&"morsure"), [1, 2] as Array[int])
	assert_eq(visual.hit_frames(&"attaque"), [] as Array[int])


func test_set_facing_flips_relative_to_the_camera() -> void:
	# Planche d'une seule vue (easter egg, remplaçants) : le profil, retourné ou non ; les trois
	# vues (H6) sont dans test_visual_views.gd.
	var side_only := CHTHOLLY.duplicate() as SkinData
	side_only.front_sheet = null
	side_only.back_sheet = null
	var visual := _visual(side_only)
	var sprite := _sprite(visual)
	visual.set_facing(Vector3.LEFT)
	assert_true(sprite.flip_h, "sans caméra : la gauche est -X")
	visual.set_facing(Vector3(0.05, 0.0, -1.0))
	assert_true(sprite.flip_h, "face ou dos à la caméra : garde son côté")
	visual.set_facing(Vector3.RIGHT)
	assert_false(sprite.flip_h, "les planches regardent vers la droite")
	var camera := Camera3D.new()
	add_child_autofree(camera)
	camera.rotation.y = PI
	camera.make_current()
	visual.set_facing(Vector3.RIGHT)
	assert_true(sprite.flip_h, "caméra tournée vers +Z : +X est à gauche de l'écran")
	camera.rotation.y = 0.0
	visual.set_process(true)
	await wait_process_frames(2)
	assert_false(sprite.flip_h, "réévalué quand la caméra tourne")


func test_anchor_stays_at_the_origin_on_every_frame() -> void:
	for skin: SkinData in [CHTHOLLY, TIMERE]:
		var visual := _visual(skin)
		var sprite := _sprite(visual)
		# AABB serré du quad (en billboard, Godot l'élargit pour couvrir la rotation autour de Y ;
		# la géométrie du quad, offset et retournement compris, ne change pas).
		sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		var size := sprite.pixel_size
		var anims := SheetLoader.animations(SheetLoader.read_sheet(skin))
		for flipped: bool in [false, true]:
			visual.set_facing(Vector3.LEFT if flipped else Vector3.RIGHT)
			for anim: String in anims:
				var images: Array = anims[anim]["images"]
				for i in images.size():
					visual.show_frame(StringName(anim), i)
					await wait_process_frames(1)
					var image: Array = images[i]
					var aabb := sprite.get_aabb()
					var anchor_x: float = image[2] - image[4] if flipped else image[4]
					var label := "%s / %s / %d / retourné %s" % [skin.id, anim, i, flipped]
					assert_almost_eq(aabb.position.x + anchor_x * size, 0.0, 1e-4, label)
					assert_almost_eq(aabb.end.y - float(image[5]) * size, 0.0, 1e-4, label)
		visual.show_frame(&"repos", 0)
		await wait_process_frames(1)
		assert_almost_eq(sprite.get_aabb().size.y, skin.height_m, 1e-3, "%s debout" % skin.id)


func test_sprite_and_shadow_follow_the_node_scale() -> void:
	var visual := _visual(TIMERE)
	visual.scale = Vector3.ONE * 1.3
	var shadow := visual.get_node(^"Shadow") as MeshInstance3D
	assert_true(shadow.visible)
	assert_almost_eq(shadow.position.y, 0.02, 0.001, "au ras du sol")
	assert_almost_eq(_sprite(visual).global_transform.basis.get_scale().y, 1.3, 1e-4)
	var timere_radius := 0.75 * 44.0 * TIMERE.height_m / 99.0
	var radius := shadow.global_transform.basis.get_scale().x / 2.0
	assert_almost_eq(radius, 1.3 * timere_radius, 1e-3, "ombre à l'échelle du Timere")
	visual.set_skin(CHTHOLLY)
	radius = shadow.global_transform.basis.get_scale().x / 2.0
	assert_almost_eq(radius, 1.3 * 0.75 * 46.0 * 1.5 / 144.0, 1e-3, "demi-largeur du corps, 46 px")


func test_skin_change_keeps_the_running_animation() -> void:
	var visual := _visual(CHTHOLLY)
	var sprite := _sprite(visual)
	visual.play(&"marche")
	visual.advance(0.35)
	_events.clear()
	visual.set_skin(NEPHREN)
	assert_eq([visual.current_animation(), visual.current_frame()], [&"marche", 3], "même instant")
	assert_eq(_events, [], "pas de signal au changement de skin")
	assert_same(sprite.sprite_frames, SheetLoader.frames_for(NEPHREN))
	assert_eq([sprite.animation, sprite.frame], [&"marche", 3])
	assert_almost_eq(
		sprite.pixel_size, SheetLoader.pixel_size(NEPHREN, NEPHREN.frames_json.data), 1e-6
	)
	visual.advance(0.1)
	assert_eq(_events, [[&"marche", 4]], "l'animation continue")
	visual.play(&"attaque", true)
	visual.set_skin(TIMERE)
	assert_eq(visual.current_animation(), &"repos", "pas d'attaque chez le Timere : repos")
	assert_eq(_events.back(), [&"repos", 0])
	visual.set_skin(null)
	assert_false(visual.has_animation(&"repos"))
	assert_false(sprite.visible)
	visual.play(&"repos")
	visual.set_skin(CHTHOLLY)
	assert_eq(visual.current_animation(), &"repos")
	assert_true(sprite.visible)


func test_player_visual_follows_the_active_skin() -> void:
	# Acte 1 : Chtholly est le seul skin jouable de data/skins ; un second skin le temps du test.
	DirAccess.make_dir_recursive_absolute(SKINS_TEST_DIR)
	var second := NEPHREN.duplicate() as SkinData
	second.id = &"second"
	assert_eq(ResourceSaver.save(CHTHOLLY, SKINS_TEST_DIR + "/chtholly.tres"), OK)
	assert_eq(ResourceSaver.save(second, SKINS_TEST_DIR + "/second.tres"), OK)
	SkinRegistry.skins_dir = SKINS_TEST_DIR
	SkinRegistry.reload()
	var player: Node3D = add_child_autofree(PLAYER.instantiate())
	var visual := player.get_node(^"Visual") as CharacterVisual
	assert_eq(visual.skin.id, &"chtholly", "skin par défaut")
	GameState.skin_id = &"second"
	assert_eq(visual.skin.id, &"second", "skin_changed appliqué à chaud")
	assert_eq(visual.current_animation(), &"repos")
	GameState.skin_id = &""
	assert_eq(visual.skin.id, &"chtholly")
	GameState.skin_id = &"enfant"
	assert_eq(visual.skin.id, &"chtholly", "skin retiré (ancienne sauvegarde) : Chtholly")
	SkinRegistry.skins_dir = SkinRegistry.SKINS_DIR
	SkinRegistry.reload()
	for file_name: String in ["chtholly.tres", "second.tres"]:
		DirAccess.remove_absolute(SKINS_TEST_DIR.path_join(file_name))
	DirAccess.remove_absolute(SKINS_TEST_DIR)


func test_clock_runs_in_process() -> void:
	var visual := _visual(CHTHOLLY)
	visual.play(&"course")
	visual.set_process(true)
	await wait_seconds(0.3)
	assert_gt(_events.size(), 1, "les images avancent toutes seules")
