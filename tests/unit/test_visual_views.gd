extends GutTest
## (H6) Trois vues d'une planche (face, dos, profil ; profil gauche en miroir) : vue choisie selon
## la direction par rapport à la caméra fixe, zone morte autour des diagonales, changement de vue
## sans signal ni changement d'horloge (le combat ne voit rien), taille debout gardée d'une vue à
## l'autre, ancre au sol dans chaque vue, vues incohérentes ou absentes ignorées (planches d'une
## seule vue : easter egg, remplaçants). Toutes les planches branchées ont des vues cohérentes.

const VISUAL := preload("res://src/visuals/character_visual.tscn")
const CHTHOLLY := preload("res://data/skins/chtholly.tres")
const TIMERE := preload("res://data/enemies/visuals/timere.tres")
const NPC_VISUALS_DIR := "res://data/npcs/visuals"
const SKINS_DIR := "res://data/skins"

## Signaux reçus, dans l'ordre : [anim, image].
var _events: Array = []


## Visuel dans l'arbre, horloge à l'arrêt, sans caméra (la droite de l'écran est +X).
func _visual(skin: SkinData) -> CharacterVisual:
	var visual: CharacterVisual = add_child_autofree(VISUAL.instantiate())
	visual.set_process(false)
	visual.set_skin(skin)
	_events.clear()
	visual.frame_changed.connect(
		func(anim: StringName, frame: int) -> void: _events.append([anim, frame])
	)
	return visual


func _sprite(visual: CharacterVisual) -> AnimatedSprite3D:
	return visual.get_node(^"Sprite") as AnimatedSprite3D


## Direction au sol à angle_deg au-dessus de l'axe gauche-droite de l'écran, vers la caméra
## (toward = true, le bas de l'écran, +Z) ou vers le fond (le haut de l'écran, −Z).
func _direction(angle_deg: float, toward: bool, right: bool = true) -> Vector3:
	var angle := deg_to_rad(angle_deg)
	return Vector3(
		cos(angle) * (1.0 if right else -1.0), 0.0, sin(angle) * (1.0 if toward else -1.0)
	)


func test_delivered_sheets_have_consistent_views() -> void:
	var skins: Array[SkinData] = [CHTHOLLY, TIMERE]
	for dir: String in [NPC_VISUALS_DIR, SKINS_DIR]:
		for file_name: String in ResourceLoader.list_directory(dir):
			if file_name.ends_with(".tres"):
				skins.append(load(dir.path_join(file_name)) as SkinData)
	assert_gt(skins.size(), 20, "Chtholly, Timere, PNJ de l'acte 1, skins jouables")
	for skin: SkinData in skins:
		for view: StringName in [SheetLoader.FRONT, SheetLoader.BACK]:
			var label := "%s / %s" % [skin.id, view]
			assert_eq(SheetLoader.view_problem(skin, view), "", label)
			assert_true(SheetLoader.has_view(skin, view), label)
			var frames := SheetLoader.frames_for(skin, view)
			assert_not_null(frames, label)
			assert_not_same(frames, SheetLoader.frames_for(skin), label + " : autre planche")
			assert_same(frames, SheetLoader.frames_for(skin, view), label + " : en cache")


func test_view_follows_the_direction_on_screen() -> void:
	var visual := _visual(CHTHOLLY)
	var sprite := _sprite(visual)
	assert_eq(visual.current_view(), SheetLoader.SIDE, "sans direction : le profil")
	visual.set_facing(Vector3.BACK)
	assert_eq(visual.current_view(), SheetLoader.FRONT, "vers le bas de l'écran : la face")
	assert_same(sprite.sprite_frames, SheetLoader.frames_for(CHTHOLLY, SheetLoader.FRONT))
	assert_false(sprite.flip_h, "face : jamais retournée")
	visual.set_facing(Vector3.FORWARD)
	assert_eq(visual.current_view(), SheetLoader.BACK, "vers le haut de l'écran : le dos")
	assert_same(sprite.sprite_frames, SheetLoader.frames_for(CHTHOLLY, SheetLoader.BACK))
	visual.set_facing(Vector3.LEFT)
	assert_eq(visual.current_view(), SheetLoader.SIDE)
	assert_same(sprite.sprite_frames, SheetLoader.frames_for(CHTHOLLY))
	assert_true(sprite.flip_h, "profil gauche : le profil droit en miroir")
	visual.set_facing(Vector3.BACK)
	assert_false(sprite.flip_h)
	visual.set_facing(Vector3.RIGHT)
	assert_eq(visual.current_view(), SheetLoader.SIDE)
	assert_false(sprite.flip_h, "profil droit")


func test_dead_zone_around_the_diagonals() -> void:
	var visual := _visual(CHTHOLLY)
	var low := CharacterVisual.VIEW_ANGLE_DEG - CharacterVisual.VIEW_DEAD_ZONE_DEG
	var high := CharacterVisual.VIEW_ANGLE_DEG + CharacterVisual.VIEW_DEAD_ZONE_DEG
	visual.set_facing(Vector3.RIGHT)
	visual.set_facing(_direction(high - 2.0, true))
	assert_eq(visual.current_view(), SheetLoader.SIDE, "de profil, la diagonale reste profil")
	visual.set_facing(_direction(high + 2.0, true))
	assert_eq(visual.current_view(), SheetLoader.FRONT, "franchement vers le bas : la face")
	visual.set_facing(_direction(low + 2.0, true, false))
	assert_eq(visual.current_view(), SheetLoader.FRONT, "de face, la diagonale reste face")
	visual.set_facing(_direction(low - 2.0, true, false))
	assert_eq(visual.current_view(), SheetLoader.SIDE, "franchement sur le côté : le profil")
	assert_true(_sprite(visual).flip_h, "vers la gauche")
	visual.set_facing(_direction(high + 2.0, false))
	assert_eq(visual.current_view(), SheetLoader.BACK)
	visual.set_facing(_direction(low + 2.0, true))
	assert_eq(visual.current_view(), SheetLoader.FRONT, "du dos à la face sans passer le profil")
	for i in 40:
		var wobble := _direction(CharacterVisual.VIEW_ANGLE_DEG + (3.0 if i % 2 else -3.0), true)
		visual.set_facing(wobble)
		assert_eq(visual.current_view(), SheetLoader.FRONT, "pas de clignotement (%d)" % i)


func test_view_change_keeps_the_clock_and_emits_nothing() -> void:
	var visual := _visual(CHTHOLLY)
	var sprite := _sprite(visual)
	visual.play(&"attaque")
	visual.advance(1.0 / 14.0)
	assert_eq(_events, [[&"attaque", 0], [&"attaque", 1]])
	_events.clear()
	for direction: Vector3 in [Vector3.BACK, Vector3.FORWARD, Vector3.LEFT, Vector3.BACK]:
		visual.set_facing(direction)
		assert_eq([visual.current_animation(), visual.current_frame()], [&"attaque", 1])
		assert_eq([sprite.animation, sprite.frame], [&"attaque", 1], "même image dans la vue")
	assert_eq(_events, [], "changer de vue n'émet rien")
	assert_eq(visual.hit_frames(&"attaque"), [1, 2, 3] as Array[int], "coup du profil")
	assert_eq(visual.wave_frame(&"charge"), 3)
	visual.advance(1.0 / 14.0)
	assert_eq(_events, [[&"attaque", 2]], "l'horloge continue")
	visual.show_frame(&"charge", 2)
	visual.set_facing(Vector3.FORWARD)
	assert_eq([sprite.animation, sprite.frame], [&"charge", 2], "image figée gardée")
	assert_false(visual.is_playing())


func test_standing_height_and_anchor_in_every_view() -> void:
	for skin: SkinData in [CHTHOLLY, TIMERE]:
		var visual := _visual(skin)
		var sprite := _sprite(visual)
		sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		var side_sheet := SheetLoader.read_sheet(skin)
		var side_size := SheetLoader.pixel_size(skin, side_sheet)
		var side_idle: Array = SheetLoader.animations(side_sheet)["repos"]["images"][0]
		for entry: Array in [
			[SheetLoader.FRONT, Vector3.BACK], [SheetLoader.BACK, Vector3.FORWARD]
		]:
			var view: StringName = entry[0]
			visual.set_facing(entry[1])
			assert_eq(visual.current_view(), view)
			var sheet := SheetLoader.read_sheet(skin, view)
			var size := sprite.pixel_size
			assert_almost_eq(size, SheetLoader.pixel_size(skin, side_sheet, sheet), 1e-7)
			var idle: Array = SheetLoader.animations(sheet)["repos"]["images"][0]
			assert_almost_eq(
				float(idle[5]) * size,
				float(side_idle[5]) * side_size,
				1e-4,
				"%s / %s : même taille debout que le profil" % [skin.id, view]
			)
			var anims := SheetLoader.animations(sheet)
			for anim: String in anims:
				var images: Array = anims[anim]["images"]
				for i in images.size():
					visual.show_frame(StringName(anim), i)
					await wait_process_frames(1)
					var image: Array = images[i]
					var aabb := sprite.get_aabb()
					var label := "%s / %s / %s / %d" % [skin.id, view, anim, i]
					assert_almost_eq(aabb.position.x + float(image[4]) * size, 0.0, 1e-4, label)
					assert_almost_eq(aabb.end.y - float(image[5]) * size, 0.0, 1e-4, label)
	assert_almost_eq(
		SheetLoader.pixel_size(CHTHOLLY, SheetLoader.read_sheet(CHTHOLLY)),
		1.5 / 144.0,
		1e-7,
		"profil : 96 px par mètre"
	)


func test_view_is_relative_to_the_camera() -> void:
	var visual := _visual(CHTHOLLY)
	var camera := Camera3D.new()
	add_child_autofree(camera)
	camera.rotation_degrees = Vector3(-32.0, 0.0, 0.0)
	camera.make_current()
	visual.set_facing(Vector3.BACK)
	assert_eq(visual.current_view(), SheetLoader.FRONT, "caméra inclinée vers le nord : face")
	camera.rotation_degrees = Vector3(-32.0, 180.0, 0.0)
	visual.set_process(true)
	await wait_process_frames(2)
	assert_eq(visual.current_view(), SheetLoader.BACK, "caméra retournée : le dos")


func test_sheets_without_views_or_with_wrong_views_keep_the_profile() -> void:
	var side_only := CHTHOLLY.duplicate() as SkinData
	side_only.front_sheet = null
	side_only.back_json = null
	assert_false(SheetLoader.has_view(side_only, SheetLoader.FRONT), "planche absente")
	assert_false(SheetLoader.has_view(side_only, SheetLoader.BACK), "JSON absent")
	var visual := _visual(side_only)
	for direction: Vector3 in [Vector3.BACK, Vector3.FORWARD]:
		visual.set_facing(direction)
		assert_eq(visual.current_view(), SheetLoader.SIDE, "une seule vue : le profil")
	# Vue de face dont l'attaque a une image de moins : refusée (l'horloge et les images « coup »
	# ne doivent jamais dépendre de la vue).
	var wrong := CHTHOLLY.duplicate() as SkinData
	var data: Dictionary = (CHTHOLLY.front_json.data as Dictionary).duplicate(true)
	(data["animations"]["attaque"]["images"] as Array).pop_back()
	wrong.front_json = JSON.new()
	wrong.front_json.data = data
	assert_string_contains(SheetLoader.view_problem(wrong, SheetLoader.FRONT), "attaque")
	assert_false(SheetLoader.has_view(wrong, SheetLoader.FRONT))
	assert_true(SheetLoader.has_view(wrong, SheetLoader.BACK), "le dos reste bon")
	var other := _visual(wrong)
	other.set_facing(Vector3.BACK)
	assert_eq(other.current_view(), SheetLoader.SIDE, "face refusée : le profil")
	other.set_facing(Vector3.FORWARD)
	assert_eq(other.current_view(), SheetLoader.BACK)
	var extra: Dictionary = (CHTHOLLY.front_json.data as Dictionary).duplicate(true)
	(extra["animations"] as Dictionary)["salut"] = extra["animations"]["repos"]
	wrong.front_json.data = extra
	assert_string_contains(SheetLoader.view_problem(wrong, SheetLoader.FRONT), "en trop")
	assert_eq(SheetLoader.view_problem(null, SheetLoader.FRONT), "vue front absente")
