extends GutTest
## (E4) Les tenues : chaque tenue est une SkinData complète à trois vues (data/npcs/outfits/) ;
## une planche complémentaire (`<id>_life`) ajoute ses animations à la planche de base, vue par vue,
## à la même échelle ; changer de tenue à chaud garde l'animation, l'image et le sens ; une planche
## n'est gardée en mémoire que tant qu'un visuel l'affiche ; la tenue de la maison du joueur.

const VISUAL := preload("res://src/visuals/character_visual.tscn")
const OUTFITS_DIR := "res://data/npcs/outfits"
const WILLEM := preload("res://data/npcs/willem.tres")
const TIAT := preload("res://data/npcs/tiat.tres")


func _visual(skin: SkinData) -> CharacterVisual:
	var visual: CharacterVisual = add_child_autofree(VISUAL.instantiate())
	visual.set_process(false)
	visual.set_skin(skin)
	return visual


func test_every_outfit_is_a_complete_three_view_sheet() -> void:
	var count := 0
	for file_name: String in ResourceLoader.list_directory(OUTFITS_DIR):
		if not file_name.ends_with(".tres"):
			continue
		count += 1
		var skin := load(OUTFITS_DIR.path_join(file_name)) as SkinData
		assert_not_null(skin, file_name)
		assert_eq(String(skin.id), file_name.get_basename(), "id = fichier")
		assert_null(SkinRegistry.get_skin(skin.id), "%s : pas jouable" % skin.id)
		for view: StringName in [SheetLoader.FRONT, SheetLoader.BACK]:
			assert_eq(SheetLoader.view_problem(skin, view), "", "%s / %s" % [skin.id, view])
			assert_true(SheetLoader.has_view(skin, view), "%s / %s" % [skin.id, view])
		var sheet := SheetLoader.read_sheet(skin)
		var size := SheetLoader.pixel_size(skin, sheet)
		assert_almost_eq(size, 1.0 / 96.0, 0.0004, "%s : 96 px par mètre" % skin.id)
		var anims := SheetLoader.animations(sheet)
		for anim: String in ["repos"]:
			assert_true(anims.has(anim), "%s : %s" % [skin.id, anim])
	assert_eq(
		count,
		30,
		"23 tenues du lot J, willem_duel (E8b), S1b (willem_marsh, snack_vendor_work), S2 (4)"
	)


func test_complement_sheet_adds_its_animations() -> void:
	var life := load("res://data/npcs/outfits/tiat_life.tres") as SkinData
	var base := TIAT.skin
	var anims := SheetLoader.animations(SheetLoader.read_sheet(life))
	for anim: String in [
		"repos", "marche", "parle", "course", "saut", "grimpe", "assis", "lit", "tombe"
	]:
		assert_true(anims.has(anim), "tiat_life : %s" % anim)
	assert_true(
		bool((anims["course"] as Dictionary).get(SheetLoader.EXTRA_KEY, false)),
		"course : complément"
	)
	assert_false(
		(anims["repos"] as Dictionary).has(SheetLoader.EXTRA_KEY), "repos : planche de base"
	)
	assert_almost_eq(
		SheetLoader.pixel_size(life, SheetLoader.read_sheet(life)),
		SheetLoader.pixel_size(base, SheetLoader.read_sheet(base)),
		0.00001,
		"même échelle que la planche de base"
	)
	var frames := SheetLoader.frames_for(life)
	assert_true(frames.has_animation(&"course") and frames.has_animation(&"marche"))
	var course := frames.get_frame_texture(&"course", 0) as AtlasTexture
	assert_eq(course.atlas, life.extra_sheet, "les images du complément viennent de sa planche")
	var marche := frames.get_frame_texture(&"marche", 0) as AtlasTexture
	assert_eq(marche.atlas, life.sprite_sheet)
	assert_eq(SheetLoader.hit_frames(SheetLoader.read_sheet(life), &"frappe"), [2] as Array[int])
	# Sans complément de face, la face perd « course » : le profil reste.
	var partial := life.duplicate() as SkinData
	partial.extra_front_sheet = null
	assert_false(SheetLoader.has_view(partial, SheetLoader.FRONT))


func test_outfit_change_keeps_animation_and_facing() -> void:
	var home := WILLEM.load_outfit(&"maison")
	var cook := WILLEM.load_outfit(&"cuisine")
	assert_eq(home.id, &"willem_home")
	assert_eq(cook.id, &"willem_cook")
	var visual := _visual(home)
	visual.play(&"marche")
	visual.advance(0.25)
	visual.set_facing(Vector3.LEFT)
	var frame := visual.current_frame()
	var view := visual.current_view()
	var sprite := visual.get_node(^"Sprite") as AnimatedSprite3D
	var flipped := sprite.flip_h
	var events: Array = []
	visual.frame_changed.connect(func(anim: StringName, f: int) -> void: events.append([anim, f]))
	visual.set_skin(cook)
	assert_eq(visual.skin.id, &"willem_cook")
	assert_eq(visual.current_animation(), &"marche", "même animation")
	assert_eq(visual.current_frame(), frame, "même image")
	assert_eq(visual.current_view(), view, "même vue")
	assert_eq(sprite.flip_h, flipped, "même sens")
	assert_eq(events, [], "sans saut d'image ni signal")
	visual.set_facing(Vector3.BACK)
	visual.set_skin(home)
	assert_eq(visual.current_view(), SheetLoader.FRONT, "la face reste la face")


func test_unknown_outfit_falls_back_to_the_default_skin() -> void:
	assert_eq(WILLEM.load_outfit(&""), WILLEM.skin)
	assert_eq(WILLEM.load_outfit(&"smoking"), WILLEM.skin)
	assert_true(WILLEM.has_outfit(&"manteau"))
	assert_false(WILLEM.has_outfit(&"smoking"))


func test_sheets_are_freed_when_no_visual_shows_them() -> void:
	SheetLoader.clear_cache()
	var skin := load("res://data/npcs/outfits/fairy_05.tres") as SkinData
	var visual := _visual(skin)
	assert_gt(SheetLoader.cached_count(), 0)
	visual.free()
	skin = null
	await wait_frames(2)
	assert_eq(SheetLoader.cached_count(), 0, "cache en références faibles")


func test_player_home_outfit_needs_combat_animations() -> void:
	var map := Map.new()
	map.interior = true
	map.region = &"entrepot"
	var chtholly := SkinRegistry.default_skin()
	# chtholly_home (livrée) n'a pas attaque, charge, degats, mort : le joueur garde sa planche.
	assert_null(LifeDirector.player_home_outfit(map, chtholly))
	map.interior = false
	assert_null(LifeDirector.player_home_outfit(map, chtholly), "dehors : jamais")
	map.free()
	var home := load("res://data/npcs/outfits/chtholly_home.tres") as SkinData
	var anims := SheetLoader.animations(SheetLoader.read_sheet(home))
	assert_false(anims.has("attaque"), "si elle les gagne, la tenue de la maison sera portée")
