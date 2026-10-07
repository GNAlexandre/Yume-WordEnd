extends GutTest
## SkinRegistry (L3) et skins jouables de data/skins/ : ordre (Chtholly d'abord), recherche,
## skin par défaut, rechargement ; Chtholly (skin par défaut), Nopht et Rhantolk (planches de
## remplacement, HD-2D) sont jouables ; les
## anciens skins de PNJ sont retirés à l'acte 1, les sept modèles 3D de la PR n° 1 au passage au
## HD-2D, et les PNJ ont des visuels non jouables (data/npcs/visuals, même densité que Chtholly).

const TEST_DIR := "user://l3_skins"
const PLAYER_ANIMS := {
	"repos": 2, "marche": 6, "course": 5, "attaque": 4, "charge": 4, "degats": 1, "mort": 1
}
## Skins de remplacement retirés à l'acte 1 (données et planches).
const REMOVED_SKINS: Array[String] = ["bibliothecaire", "forgeron", "enfant"]
## Modèles 3D de la PR n° 1, retirés au passage au HD-2D (planches 2D seulement).
const REMOVED_MESH_SKINS: Array[String] = [
	"sukasuka_chtholly",
	"sukasuka_ithea",
	"sukasuka_lillia",
	"sukasuka_nephren",
	"sukasuka_nopht",
	"sukasuka_rhantolk",
	"sukasuka_willem"
]
const NPC_VISUALS_DIR := "res://data/npcs/visuals"
## (HD-2D) Skins jouables du jeu, dans l'ordre du registre (Chtholly d'abord, puis le nom).
const PLAYABLE: Array[StringName] = [&"chtholly", &"nopht", &"rhantolk"]


func after_each() -> void:
	SkinRegistry.skins_dir = SkinRegistry.SKINS_DIR
	SkinRegistry.reload()


func _ids(skins: Array[SkinData]) -> Array:
	var ids: Array = []
	for skin: SkinData in skins:
		ids.append(skin.id)
	return ids


func test_all_is_sorted_with_chtholly_first() -> void:
	assert_eq(_ids(SkinRegistry.all()), Array(PLAYABLE))
	assert_eq(SkinRegistry.default_skin().id, &"chtholly")
	assert_eq(SkinRegistry.get_skin(&"chtholly").display_name, "Chtholly")
	assert_null(SkinRegistry.get_skin(&"timere"), "un visuel d'ennemi n'est pas jouable")
	assert_null(SkinRegistry.get_skin(&"nygglatho"), "un visuel de PNJ n'est pas jouable")
	assert_null(SkinRegistry.get_skin(&"forgeron"), "ancien skin retiré")
	assert_null(SkinRegistry.get_skin(&""))
	SkinRegistry.all().clear()
	assert_eq(SkinRegistry.all().size(), PLAYABLE.size(), "all() renvoie une copie")


func test_removed_skins_and_sheets_are_gone() -> void:
	for skin_id: String in REMOVED_SKINS:
		assert_false(ResourceLoader.exists("res://data/skins/%s.tres" % skin_id), skin_id)
		assert_false(
			DirAccess.dir_exists_absolute("res://assets/characters/" + skin_id),
			"planche %s retirée" % skin_id
		)
	for skin_id: String in REMOVED_MESH_SKINS:
		assert_false(ResourceLoader.exists("res://data/skins/%s.tres" % skin_id), skin_id)
	assert_false(DirAccess.dir_exists_absolute("res://assets/models"), "modèles 3D retirés")


func test_playable_skins_have_a_full_sheet_at_chtholly_density() -> void:
	var checked := 0
	for skin: SkinData in SkinRegistry.all():
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

	assert_eq(checked, PLAYABLE.size(), "chaque skin jouable est une planche")


func test_npc_visuals_keep_the_player_density() -> void:
	var count := 0
	for file_name: String in ResourceLoader.list_directory(NPC_VISUALS_DIR):
		if not file_name.ends_with(".tres"):
			continue
		count += 1
		var skin := load(NPC_VISUALS_DIR.path_join(file_name)) as SkinData
		assert_not_null(skin, file_name)
		if skin == null:
			continue
		var label := String(skin.id)
		assert_eq(label, file_name.get_basename(), "id = fichier")
		var sheet := SheetLoader.read_sheet(skin)
		var size := SheetLoader.pixel_size(skin, sheet)
		assert_almost_eq(size, 1.5 / 144.0, 0.0003, label + " : densité de Chtholly")
		assert_not_null(skin.portrait, label + " : portrait (dialogue)")
		if skin.portrait != null:
			assert_eq(skin.portrait.get_width(), skin.portrait.get_height(), label + " : carré")
	assert_eq(count, 17, "17 visuels de PNJ (Willem en a un pour ses trois instances)")


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
