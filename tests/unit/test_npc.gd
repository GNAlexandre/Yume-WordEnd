extends GutTest
## Lot 6, puis acte 1 : PNJ (src/npc/npc.tscn), données data/npcs/*.tres (les PNJ de l'acte 1 et
## leurs visuels non jouables data/npcs/visuals/). (F1) Les PNJ de l'ancienne île (boulanger,
## passeur, marchande d'œufs, guetteur, Willem de la forêt et de la colline), ses emplacements et
## ses déclencheurs de quête sont partis ; une conversation hors scène est celle de
## data/dialogues/ile_68/talk/<id>.json.

const NPC_SCENE := preload("res://src/npc/npc.tscn")
const PLAYER_STUB := preload("res://tests/stubs/player_stub.tscn")
const NYGGLATHO := preload("res://data/npcs/nygglatho.tres")
const NPCS_DIR := "res://data/npcs"
const VISUALS_DIR := "res://data/npcs/visuals"
## PNJ de l'acte 1 : nom affiché, visuel, conversation hors scène (data/dialogues/ile_68/talk).
const NPCS := {
	&"nygglatho": ["Nygglatho", &"nygglatho", true],
	&"willem": ["Willem", &"willem", true],
	&"ithea": ["Ithea", &"ithea", true],
	&"nephren": ["Nephren", &"nephren", true],
	&"tiat": ["Tiat", &"tiat", true],
	&"pannibal": ["Pannibal", &"pannibal", true],
	&"collon": ["Collon", &"collon", true],
	&"lakhesh": ["Lakhesh", &"lakhesh", true],
	&"almita": ["Almita", &"almita", true],
	&"limeskin": ["Limeskin", &"limeskin", false],
	&"cat_waiter": ["Serveur", &"cat_waiter", false],
	&"ramikeldi": ["M.\u00a0Rami", &"ramikeldi", false],
	&"snack_vendor": ["Cuistot du snack", &"snack_vendor", false],
}
## PNJ et visuels de l'ancienne île, retirés.
const REMOVED: Array[String] = [
	"baker", "ferryman", "egg_vendor", "garde_lookout", "willem_training", "willem_stars"
]
## Tailles (m) des visuels : HISTOIRE.md 5.1 et 5.2, BIBLE.md section 5.
const HEIGHTS := {
	&"nygglatho": 1.85,
	&"willem": 1.75,
	&"ithea": 1.45,
	&"nephren": 1.3,
	&"tiat": 1.1,
	&"pannibal": 1.25,
	&"collon": 1.2,
	&"lakhesh": 1.2,
	&"almita": 0.95,
	&"limeskin": 2.8,
	&"cat_waiter": 1.65,
	&"ramikeldi": 1.7,
	&"snack_vendor": 1.6,
}
var _started: Array[StringName] = []


func before_each() -> void:
	GameState.reset()
	_started.clear()
	EventBus.dialogue_started.connect(_on_started)


func after_each() -> void:
	EventBus.dialogue_started.disconnect(_on_started)


func after_all() -> void:
	GameState.reset()


func _on_started(npc_id: StringName) -> void:
	_started.append(npc_id)


func _npc(data: NpcData = NYGGLATHO) -> Npc:
	var npc: Npc = NPC_SCENE.instantiate()
	npc.data = data
	return add_child_autofree(npc)


func test_prompt_is_parler() -> void:
	assert_eq(_npc().get_prompt(), "Parler")
	assert_true(_npc().is_in_group(&"interactable"))


func test_npc_without_data_does_not_crash() -> void:
	var npc := _npc(null)
	var player: Node3D = add_child_autofree(PLAYER_STUB.instantiate())
	await wait_physics_frames(3)
	assert_eq(npc.get_prompt(), "Parler")
	npc.interact(player)
	assert_eq(_started, [] as Array[StringName], "pas de dialogue sans data")
	assert_false(npc.runner.is_running())


func test_interact_starts_its_own_runner_once() -> void:
	var npc := _npc()
	var player: Node3D = add_child_autofree(PLAYER_STUB.instantiate())
	npc.interact(player)
	assert_eq(_started, [&"nygglatho"] as Array[StringName])
	assert_true(npc.runner.is_running(), "le DialogueRunner du PNJ")
	npc.interact(player)
	assert_eq(_started.size(), 1, "pas de relance pendant le dialogue")
	npc.runner.stop()


func test_interact_ignored_just_after_dialogue_end() -> void:
	var npc := _npc()
	npc.interact(null)
	npc.runner.stop()
	npc.interact(null)
	assert_eq(_started.size(), 1, "la touche qui ferme le dialogue ne le relance pas")
	npc.talk_cooldown = 0.0
	npc.interact(null)
	assert_eq(_started.size(), 2, "relance possible après le délai")
	npc.runner.stop()


func test_visual_uses_skin_and_idles() -> void:
	var npc := _npc()
	assert_eq(npc.visual.skin, NYGGLATHO.skin, "skin data.skin")
	assert_eq(npc.visual.current_animation(), &"repos")
	await wait_seconds(0.4)
	assert_ne(npc.visual.scale.y, 1.0, "respiration au repos")
	assert_almost_eq(npc.visual.scale.y, 1.0, npc.breath_amount + 0.001)


func test_data_can_be_set_after_ready() -> void:
	var npc := _npc(null)
	npc.data = NYGGLATHO
	assert_eq(npc.visual.skin, NYGGLATHO.skin)
	npc.interact(null)
	assert_eq(_started, [&"nygglatho"] as Array[StringName])
	npc.runner.stop()


func test_looks_at_player_within_four_meters() -> void:
	var npc := _npc()
	assert_eq(npc.look_distance, 4.0)
	assert_true(npc.look_toward(Vector3(3.9, 0.0, 0.0)), "à 3,9 m")
	assert_true(npc.look_toward(Vector3(-2.0, 5.0, 2.0)), "la hauteur ne compte pas")
	assert_false(npc.look_toward(Vector3(4.1, 0.0, 0.0)), "à 4,1 m")
	assert_false(npc.look_toward(Vector3.ZERO), "sur le PNJ : pas de direction")


func test_settles_on_floor_then_stops() -> void:
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(10.0, 1.0, 10.0)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position = Vector3(0.0, -0.4, 0.0)
	add_child_autofree(floor_body)
	var npc: Npc = NPC_SCENE.instantiate()
	npc.data = NYGGLATHO
	npc.position = Vector3(0.0, 0.6, 0.0)
	add_child_autofree(npc)
	await wait_physics_frames(40)
	assert_almost_eq(npc.global_position.y, 0.1, 0.05, "posé sur le sol (dessus à y = 0,1)")
	assert_false(npc.is_physics_processing(), "immobile une fois posé")


func test_npc_data_files() -> void:
	for npc_id: StringName in NPCS:
		var data := load("%s/%s.tres" % [NPCS_DIR, npc_id]) as NpcData
		assert_not_null(data, "data/npcs/%s.tres" % npc_id)
		if data == null:
			continue
		var fields: Array = NPCS[npc_id]
		assert_eq(data.id, npc_id, "id = nom du fichier")
		assert_eq(data.display_name, fields[0])
		assert_not_null(data.skin, "%s : visuel" % npc_id)
		if data.skin != null:
			assert_eq(data.skin.id, fields[1], "%s : visuel" % npc_id)
			assert_eq(
				data.skin.resource_path,
				"%s/%s.tres" % [VISUALS_DIR, fields[1]],
				"visuel non jouable"
			)
		if fields[2]:
			assert_eq(data.dialogue_path, "res://data/dialogues/ile_68/talk/%s.json" % npc_id)
			assert_true(FileAccess.file_exists(data.dialogue_path), "%s : dialogue" % npc_id)
		else:
			assert_eq(data.dialogue_path, "", "%s : pas de conversation hors scène" % npc_id)
	for file_name: String in ResourceLoader.list_directory(NPCS_DIR):
		if file_name.ends_with(".tres"):
			assert_has(NPCS, StringName(file_name.get_basename()), "PNJ attendu : %s" % file_name)
	for old_id: String in ["librarian", "blacksmith", "child"] + REMOVED:
		assert_false(ResourceLoader.exists("%s/%s.tres" % [NPCS_DIR, old_id]), "%s retiré" % old_id)
		assert_false(
			ResourceLoader.exists("%s/%s.tres" % [VISUALS_DIR, old_id]), "visuel %s retiré" % old_id
		)


func test_npc_visuals_are_not_playable_skins() -> void:
	for visual_id: StringName in HEIGHTS:
		var skin := load("%s/%s.tres" % [VISUALS_DIR, visual_id]) as SkinData
		assert_not_null(skin, "data/npcs/visuals/%s.tres" % visual_id)
		if skin == null:
			continue
		assert_eq(skin.id, visual_id, "id = nom du fichier")
		assert_null(SkinRegistry.get_skin(visual_id), "%s : pas dans le menu" % visual_id)
		assert_almost_eq(skin.height_m, float(HEIGHTS[visual_id]), 0.001, "%s : taille" % visual_id)
		assert_not_null(skin.portrait, "%s : portrait" % visual_id)
		var sheet := SheetLoader.read_sheet(skin)
		var animations := SheetLoader.animations(sheet)
		# (H1) Planches livrées : un PNJ a repos, marche et parle (docs/ASSETS_HD2D.md 3.2 ; Willem
		# n'a pas encore « parle ») ; Ithea et Nephren, jouables, ont aussi le combat de la fée.
		for anim: String in ["repos", "marche"]:
			assert_true(animations.has(anim), "%s : animation %s" % [visual_id, anim])
		if visual_id != &"willem":
			assert_true(animations.has("parle"), "%s : parle" % visual_id)
		if animations.has("attaque"):
			assert_eq(SheetLoader.hit_frames(sheet, &"attaque"), [1, 2, 3] as Array[int])
			assert_eq(SheetLoader.wave_frame(sheet, &"charge"), 3)
	var sheet_skins := SkinRegistry.all().filter(
		func(playable: SkinData) -> bool: return playable.sprite_sheet != null
	)
	assert_eq(
		sheet_skins.size(), SkinRegistry.all().size(), "(HD-2D) tous les skins sont des planches"
	)
