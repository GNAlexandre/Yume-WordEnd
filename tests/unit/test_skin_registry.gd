extends GutTest
## SkinRegistry (L3) et skins jouables de data/skins/ : ordre (Chtholly d'abord), recherche,
## skin par défaut, rechargement ; onze planches 2D dont sept personnages SukaSuka
## directionnels. Les fenêtres de combat restent communes aux trois orientations.

const TEST_DIR := "user://l3_skins"
const PLAYER_ANIMS := {
	"repos": 2, "marche": 6, "course": 5, "attaque": 4, "charge": 4, "degats": 1, "mort": 1
}
const NPC_SKINS: Array[StringName] = [&"bibliothecaire", &"forgeron", &"enfant"]
const PIXEL_SKINS: Array[StringName] = [
	&"sukasuka_chtholly",
	&"sukasuka_ithea",
	&"sukasuka_lillia",
	&"sukasuka_nephren",
	&"sukasuka_nopht",
	&"sukasuka_rhantolk",
	&"sukasuka_willem"
]


func after_each() -> void:
	SkinRegistry.skins_dir = SkinRegistry.SKINS_DIR
	SkinRegistry.reload()


func _ids(skins: Array[SkinData]) -> Array:
	var ids: Array = []
	for skin: SkinData in skins:
		ids.append(skin.id)
	return ids


func test_all_is_sorted_with_chtholly_first() -> void:
	assert_eq(
		_ids(SkinRegistry.all()),
		[
			&"chtholly",
			&"bibliothecaire",
			&"sukasuka_chtholly",
			&"enfant",
			&"forgeron",
			&"sukasuka_ithea",
			&"sukasuka_lillia",
			&"sukasuka_nephren",
			&"sukasuka_nopht",
			&"sukasuka_rhantolk",
			&"sukasuka_willem"
		]
	)
	assert_eq(SkinRegistry.default_skin().id, &"chtholly")
	assert_eq(SkinRegistry.get_skin(&"forgeron").display_name, "Forgeron")
	assert_null(SkinRegistry.get_skin(&"timere"), "un visuel d'ennemi n'est pas jouable")
	assert_null(SkinRegistry.get_skin(&""))
	SkinRegistry.all().clear()
	assert_eq(SkinRegistry.all().size(), 11, "all() renvoie une copie")


func test_four_legacy_skins_keep_their_playable_sheets() -> void:
	var checked := 0
	for skin: SkinData in SkinRegistry.all():
		if skin.id in PIXEL_SKINS:
			continue
		checked += 1
		var label := String(skin.id)
		assert_true(
			ResourceLoader.exists("res://data/skins/%s.tres" % skin.id), label + " : id = fichier"
		)
		var frames := SheetLoader.frames_for(skin)
		assert_not_null(frames, label + " : planche")
		if frames == null:
			continue
		for anim: String in PLAYER_ANIMS:
			assert_eq(frames.get_frame_count(anim), PLAYER_ANIMS[anim], "%s / %s" % [label, anim])
		var sheet := SheetLoader.read_sheet(skin)
		assert_eq(SheetLoader.hit_frames(sheet, &"attaque"), [1, 2, 3] as Array[int], label)
		assert_eq(SheetLoader.wave_frame(sheet, &"charge"), 3, label)
		var size := SheetLoader.pixel_size(skin, sheet)
		assert_almost_eq(size, 1.5 / 144.0, 0.0002, label + " : densité de Chtholly")
		assert_not_null(skin.portrait, label + " : portrait (menu, dialogue)")
		if skin.portrait != null:
			assert_eq(skin.portrait.get_width(), skin.portrait.get_height(), label + " : carré")

	assert_eq(checked, 4, "les quatre planches historiques restent disponibles")


func test_seven_pixel_skins_have_measured_directions_and_square_portrait() -> void:
	var found: Array[StringName] = []
	for skin: SkinData in SkinRegistry.all():
		if skin.id not in PIXEL_SKINS:
			continue
		found.append(skin.id)
		assert_null(skin.mesh_scene, String(skin.id) + " : planche HD-2D")
		assert_not_null(skin.sprite_sheet, String(skin.id) + " : planche importée")
		assert_not_null(skin.portrait, String(skin.id) + " : portrait")
		assert_true(ResourceLoader.exists("res://data/skins/%s.tres" % skin.id), "id = fichier")
		assert_eq(skin.texture_filter, BaseMaterial3D.TEXTURE_FILTER_NEAREST)
		for direction: String in ["front", "back", "right"]:
			assert_true(skin.directional_sheets.has(direction), direction + " : texture")
			assert_true(skin.directional_frames_json.has(direction), direction + " : JSON")
			var sheet := SheetLoader.read_sheet(skin, direction)
			var frames := SheetLoader.frames_for(skin, direction)
			assert_not_null(frames, direction + " : animations chargées")
			for anim: String in PLAYER_ANIMS:
				assert_eq(frames.get_frame_count(anim), PLAYER_ANIMS[anim])
			assert_eq(SheetLoader.hit_frames(sheet, &"attaque"), [1, 2, 3] as Array[int])
			assert_eq(SheetLoader.wave_frame(sheet, &"charge"), 3)
			assert_almost_eq(SheetLoader.pixel_size(skin, sheet), 1.0 / 96.0, 0.00006)
		if skin.portrait != null:
			assert_eq(skin.portrait.get_size(), Vector2(256, 256), "portrait 256 × 256")
	assert_eq(found, PIXEL_SKINS, "sept personnages HD-2D dans l'ordre du registre")


func test_registered_pixel_skins_keep_attack_timing_when_turning() -> void:
	for skin_id: StringName in PIXEL_SKINS:
		var visual: CharacterVisual = add_child_autofree(
			preload("res://src/visuals/character_visual.tscn").instantiate()
		)
		visual.set_process(false)
		visual.set_skin(SkinRegistry.get_skin(skin_id))
		visual.play(&"attaque")
		visual.advance(1.5 / 14.0)
		for facing: Vector3 in [Vector3.BACK, Vector3.FORWARD, Vector3.LEFT]:
			visual.set_facing(facing)
			assert_eq(visual.current_frame(), 1, String(skin_id) + " : temps conservé")
			assert_true(visual.is_playing())
			assert_eq(visual.hit_frames(&"attaque"), [1, 2, 3] as Array[int])
		visual.advance(0.5 / 14.0)
		assert_eq(visual.current_frame(), 2, "fraction d'intervalle conservée")
		assert_true((visual.get_node("Sprite") as AnimatedSprite3D).flip_h)


func test_npc_placeholders_have_distinct_colors() -> void:
	var colors: Array[Color] = []
	for skin_id in NPC_SKINS:
		var skin := SkinRegistry.get_skin(skin_id)
		var idle: Array = SheetLoader.animations(SheetLoader.read_sheet(skin))["repos"]["images"][0]
		var height: float = idle[3]
		var tunic := Vector2i(int(idle[4] - 0.07 * height), int(idle[5] - 0.36 * height))
		colors.append(skin.sprite_sheet.get_image().get_pixelv(tunic))
	for i in colors.size():
		assert_eq(colors[i].a, 1.0, "%s : tenue opaque" % NPC_SKINS[i])
		for j in range(i + 1, colors.size()):
			var gap := Vector3(
				colors[i].r - colors[j].r, colors[i].g - colors[j].g, colors[i].b - colors[j].b
			)
			assert_gt(
				gap.length(), 0.25, "%s et %s : couleurs distinctes" % [NPC_SKINS[i], NPC_SKINS[j]]
			)


func test_reload_reads_skins_dir() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var files: Array[String] = []
	for entry: Array in [["zeta", "Zeta"], ["alpha", "alpha"], ["alpha", "Doublon"]]:
		var skin := SkinData.new()
		skin.id = StringName(entry[0])
		skin.display_name = entry[1]
		files.append("%s/%s_%d.tres" % [TEST_DIR, entry[0], files.size()])
		assert_eq(ResourceSaver.save(skin, files.back()), OK)
	files.append(TEST_DIR + "/autre.tres")
	assert_eq(ResourceSaver.save(Resource.new(), files.back()), OK)
	SkinRegistry.skins_dir = TEST_DIR
	SkinRegistry.reload()
	assert_eq(
		_ids(SkinRegistry.all()), [&"alpha", &"zeta"], "tri sans casse, doublon et non-skin ignorés"
	)
	assert_eq(SkinRegistry.default_skin().id, &"alpha", "sans Chtholly : le premier")
	assert_null(SkinRegistry.get_skin(&"chtholly"))
	for path in files:
		DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(TEST_DIR)
