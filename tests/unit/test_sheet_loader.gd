extends GutTest
## SheetLoader (L3) : planches de l'easter egg lues telles quelles (Chtholly, Timere),
## SpriteFrames construit (un AtlasTexture par image, ancre en métadonnée) et mis en cache,
## taille d'un pixel, données invalides ignorées.

const CHTHOLLY := preload("res://data/skins/chtholly.tres")
const TIMERE := preload("res://data/enemies/visuals/timere.tres")

## Animation → [images, ips, boucle] (PLAN.md section 5).
const CHTHOLLY_ANIMS := {
	"repos": [2, 2, true],
	"marche": [6, 10, true],
	"course": [5, 14, true],
	"attaque": [4, 14, false],
	"charge": [4, 10, false],
	"degats": [1, 1, false],
	"mort": [1, 1, false],
}
const TIMERE_ANIMS := {
	"repos": [5, 6, true],
	"marche": [4, 7, true],
	"course": [6, 12, true],
	"fouet": [4, 8, false],
	"morsure": [4, 8, false],
	"degats": [5, 12, false],
	"mort": [6, 8, false],
}


func _assert_sheet(skin: SkinData, expected: Dictionary) -> void:
	var sheet := SheetLoader.read_sheet(skin)
	var anims := SheetLoader.animations(sheet)
	var frames := SheetLoader.build_frames(skin.sprite_sheet, sheet)
	assert_eq(anims.size(), expected.size(), "%s : nombre d'animations" % skin.id)
	assert_eq(frames.get_animation_names().size(), expected.size())
	for anim: String in expected:
		var info: Array = expected[anim]
		var label := "%s / %s" % [skin.id, anim]
		assert_true(anims.has(anim), label)
		assert_eq(frames.get_frame_count(anim), info[0], label + " : images")
		assert_almost_eq(frames.get_animation_speed(anim), float(info[1]), 0.001, label + " : ips")
		assert_eq(frames.get_animation_loop(anim), info[2], label + " : boucle")


func test_chtholly_sheet_is_read_as_is() -> void:
	_assert_sheet(CHTHOLLY, CHTHOLLY_ANIMS)
	var sheet := SheetLoader.read_sheet(CHTHOLLY)
	assert_eq(int(sheet["version"]), 1)
	var size: Array = sheet["planche"]
	assert_eq(Vector2(size[0], size[1]), CHTHOLLY.sprite_sheet.get_size(), "planche = PNG")
	assert_eq(SheetLoader.hit_frames(sheet, &"attaque"), [1, 2, 3] as Array[int])
	assert_eq(SheetLoader.wave_frame(sheet, &"charge"), 3)
	assert_eq(SheetLoader.hit_frames(sheet, &"marche"), [] as Array[int], "pas de coup")
	assert_eq(SheetLoader.wave_frame(sheet, &"attaque"), -1, "pas d'onde")


func test_timere_sheet_is_read_as_is() -> void:
	_assert_sheet(TIMERE, TIMERE_ANIMS)
	var sheet := SheetLoader.read_sheet(TIMERE)
	assert_eq(SheetLoader.hit_frames(sheet, &"fouet"), [1, 2] as Array[int])
	assert_eq(SheetLoader.hit_frames(sheet, &"morsure"), [1, 2] as Array[int])
	assert_eq(SheetLoader.wave_frame(sheet, &"fouet"), -1)
	assert_eq(SheetLoader.hit_frames(sheet, &"inconnue"), [] as Array[int])


func test_each_frame_is_an_atlas_region_with_its_anchor() -> void:
	for skin: SkinData in [CHTHOLLY, TIMERE]:
		var anims := SheetLoader.animations(SheetLoader.read_sheet(skin))
		var frames := SheetLoader.frames_for(skin)
		for anim: String in anims:
			var images: Array = anims[anim]["images"]
			for i in images.size():
				var image: Array = images[i]
				var atlas := frames.get_frame_texture(anim, i) as AtlasTexture
				var label := "%s / %s / %d" % [skin.id, anim, i]
				assert_eq(atlas.atlas, skin.sprite_sheet, label)
				assert_eq(atlas.region, Rect2(image[0], image[1], image[2], image[3]), label)
				assert_eq(atlas.margin, Rect2(), label + " : pas de marge")
				assert_eq(atlas.get_meta(SheetLoader.ANCHOR_META), Vector2(image[4], image[5]))


func test_frames_are_cached_per_sheet() -> void:
	SheetLoader.clear_cache()
	var frames := SheetLoader.frames_for(CHTHOLLY)
	assert_same(SheetLoader.frames_for(CHTHOLLY), frames, "une planche, un seul SpriteFrames")
	var copy := CHTHOLLY.duplicate() as SkinData
	assert_same(SheetLoader.frames_for(copy), frames, "même planche vue par un autre skin")
	assert_not_same(SheetLoader.frames_for(TIMERE), frames)
	assert_null(SheetLoader.frames_for(SkinData.new()), "pas de planche")
	SheetLoader.clear_cache()
	assert_not_same(SheetLoader.frames_for(CHTHOLLY), frames, "cache vidé")


func test_pixel_size_and_shadow_footprint() -> void:
	var sheet := SheetLoader.read_sheet(CHTHOLLY)
	assert_almost_eq(SheetLoader.pixel_size(CHTHOLLY, sheet), 1.5 / 144.0, 1e-6, "144 px = 1,5 m")
	var timere_sheet := SheetLoader.read_sheet(TIMERE)
	# Hauteur debout : du haut de l'image aux pieds (ancre à 97 px ; le cadre en fait 99).
	assert_almost_eq(SheetLoader.pixel_size(TIMERE, timere_sheet), TIMERE.height_m / 97.0, 1e-6)
	assert_almost_eq(SheetLoader.pixel_size(null, {}), SheetLoader.DEFAULT_PIXEL_SIZE, 1e-6)
	# (H1) Planches livrées (PR n° 2), ancres entre les pieds (tools/hd2d_sheets.py anchors).
	assert_eq(SheetLoader.body_half_width(sheet), 46.0, "côté sans épée de la 1re image de repos")
	assert_eq(SheetLoader.body_half_width(timere_sheet), 44.0)


func test_invalid_entries_are_ignored() -> void:
	var sheet := {
		"animations":
		{
			"vide": {"ips": 5, "images": []},
			"cassee": {"images": [[0, 0, 0, 10, 0, 0], [1, 2]]},
			"texte": "pas une animation",
			"ok": {"images": [[0, 0, 4, 4, 2, 4]]},
		}
	}
	var frames := SheetLoader.build_frames(CHTHOLLY.sprite_sheet, sheet)
	assert_eq(Array(frames.get_animation_names()), ["ok"])
	assert_almost_eq(frames.get_animation_speed(&"ok"), 10.0, 0.001, "ips par défaut")
	assert_false(frames.get_animation_loop(&"ok"), "sans boucle par défaut")
	assert_eq(SheetLoader.read_sheet(null), {})
	assert_eq(SheetLoader.animations({"animations": 3}), {})
	assert_eq(SheetLoader.body_half_width({}), 0.0)
	assert_eq(SheetLoader.build_frames(null, sheet).get_animation_names().size(), 0)
