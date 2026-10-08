extends GutTest
## Face/dos/côté relatifs à la caméra, même horloge et mêmes fenêtres de combat.

const VISUAL := preload("res://src/visuals/character_visual.tscn")

var _events: Array = []


func _sheet(y: int, anchor_x: float) -> JSON:
	var data := {"animations": {}}
	for anim: String in ["repos", "marche", "attaque", "charge"]:
		var images: Array = []
		var count := 2 if anim == "repos" else 4
		for frame in count:
			images.append([frame * 32, y, 32, 48, anchor_x, 47])
		data["animations"][anim] = {
			"ips": 8, "boucle": anim in ["repos", "marche"], "images": images
		}
	data["animations"]["attaque"]["coup"] = [1, 2]
	data["animations"]["charge"]["onde"] = 3
	var json := JSON.new()
	json.data = data
	return json


func _skin() -> SkinData:
	var skin := SkinData.new()
	skin.sprite_sheet = ImageTexture.create_from_image(
		Image.create(192, 192, false, Image.FORMAT_RGBA8)
	)
	skin.frames_json = _sheet(0, 8)
	skin.directional_frames_json["front"] = _sheet(64, 10)
	skin.directional_frames_json["back"] = _sheet(128, 12)
	skin.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	return skin


func _visual(skin: SkinData) -> CharacterVisual:
	var visual: CharacterVisual = add_child_autofree(VISUAL.instantiate())
	visual.set_process(false)
	visual.set_skin(skin)
	_events.clear()
	visual.frame_changed.connect(
		func(anim: StringName, frame: int) -> void: _events.append([anim, frame])
	)
	visual.animation_finished.connect(func(anim: StringName) -> void: _events.append([anim, -1]))
	return visual


func _sprite(visual: CharacterVisual) -> AnimatedSprite3D:
	return visual.get_node("Sprite") as AnimatedSprite3D


func test_four_facings_choose_front_back_right_and_mirror_left() -> void:
	var visual := _visual(_skin())
	var sprite := _sprite(visual)
	visual.set_facing(Vector3.BACK)
	assert_eq(visual.current_direction(), "front")
	assert_false(sprite.flip_h)
	assert_eq(sprite.offset, Vector2(-10, -1), "ancre propre à la vue de face")
	visual.set_facing(Vector3.FORWARD)
	assert_eq(visual.current_direction(), "back")
	assert_false(sprite.flip_h)
	assert_eq(sprite.offset, Vector2(-12, -1))
	visual.set_facing(Vector3.RIGHT)
	assert_eq(visual.current_direction(), "right")
	assert_false(sprite.flip_h)
	visual.set_facing(Vector3.LEFT)
	assert_eq(visual.current_direction(), "right")
	assert_true(sprite.flip_h)
	assert_eq(sprite.offset, Vector2(8 - 32, -1), "miroir conservant l'ancre")
	assert_eq(sprite.texture_filter, BaseMaterial3D.TEXTURE_FILTER_LINEAR)
	assert_eq(_events, [], "changer d'angle ne rejoue aucune frame de gameplay")


func test_viewpoint_follows_yaw_of_a_pitched_orthographic_camera() -> void:
	var visual := _visual(_skin())
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	add_child_autofree(camera)
	camera.rotation = Vector3(-PI / 5.0, PI / 2.0, 0.0)
	camera.make_current()
	visual.set_facing(Vector3.RIGHT)
	assert_eq(visual.current_direction(), "front")
	visual.set_facing(Vector3.LEFT)
	assert_eq(visual.current_direction(), "back")
	visual.set_facing(Vector3.BACK)
	assert_eq(visual.current_direction(), "right")
	assert_true(_sprite(visual).flip_h)
	visual.set_process(true)
	camera.rotation.y = 0.0
	await wait_process_frames(2)
	assert_eq(visual.current_direction(), "front", "angle réévalué après rotation de caméra")


func test_turning_mid_attack_keeps_fractional_time_hits_and_finish_event() -> void:
	var visual := _visual(_skin())
	visual.play(&"attaque")
	visual.advance(0.1875)
	_events.clear()
	visual.set_facing(Vector3.BACK)
	assert_eq(visual.current_frame(), 1)
	assert_true(visual.is_playing())
	assert_eq(visual.hit_frames(&"attaque"), [1, 2] as Array[int])
	visual.advance(0.0625)
	assert_eq(_events, [[&"attaque", 2]], "fraction d'intervalle conservée lors du virage")
	visual.set_facing(Vector3.FORWARD)
	visual.advance(0.25)
	assert_eq(_events, [[&"attaque", 2], [&"attaque", 3], [&"attaque", -1]])
	visual.set_facing(Vector3.RIGHT)
	assert_false(visual.is_playing(), "animation terminée reste terminée")
	assert_eq(visual.current_frame(), 3)
	visual.advance(0.5)
	assert_eq(_events.size(), 3, "aucun deuxième signal de fin")


func test_direction_switch_keeps_frozen_charge_and_wave_frame() -> void:
	var visual := _visual(_skin())
	visual.show_frame(&"charge", 2)
	_events.clear()
	visual.set_facing(Vector3.BACK)
	visual.advance(1.0)
	assert_eq(visual.current_frame(), 2)
	assert_false(visual.is_playing())
	assert_eq(visual.wave_frame(&"charge"), 3)
	assert_eq(_events, [])
	visual.play(&"charge")
	visual.advance(0.125)
	assert_eq(_events, [[&"charge", 3]], "charge reprend exactement depuis sa pause")


func test_incompatible_direction_cannot_change_combat_windows() -> void:
	var skin := _skin()
	skin.directional_frames_json["front"].data["animations"]["attaque"]["coup"] = [0]
	var visual := _visual(skin)
	visual.play(&"attaque")
	visual.advance(0.1875)
	visual.set_facing(Vector3.BACK)
	assert_eq(visual.current_direction(), "right", "vue rejetée si les coups sont déplacés")
	assert_eq(visual.current_frame(), 1)
	assert_eq(visual.hit_frames(&"attaque"), [1, 2] as Array[int])


func test_missing_direction_uses_legacy_sheet_and_null_skin_is_safe() -> void:
	var skin := _skin()
	skin.directional_frames_json.erase("back")
	var visual := _visual(skin)
	visual.set_facing(Vector3.BACK)
	assert_eq(visual.current_direction(), "front")
	visual.set_facing(Vector3.FORWARD)
	assert_eq(visual.current_direction(), "right", "dos absent : repli sur la planche principale")
	visual.set_skin(null)
	assert_false(_sprite(visual).visible)


func test_loader_caches_each_direction_and_texture_independently() -> void:
	var skin := _skin()
	var right := SheetLoader.frames_for(skin)
	var front := SheetLoader.frames_for(skin, "front")
	assert_not_same(right, front)
	assert_same(front, SheetLoader.frames_for(skin, "front"))
	var atlas := front.get_frame_texture(&"repos", 0) as AtlasTexture
	assert_eq(atlas.region.position.y, 64.0)
	assert_same(atlas.atlas, skin.sprite_sheet, "PNJ : une même texture pour trois directions")
	var second_texture := ImageTexture.create_from_image(
		Image.create(192, 192, false, Image.FORMAT_RGBA8)
	)
	skin.directional_sheets["front"] = second_texture
	var next := SheetLoader.frames_for(skin, "front")
	assert_not_same(front, next)
	assert_same((next.get_frame_texture(&"repos", 0) as AtlasTexture).atlas, second_texture)
