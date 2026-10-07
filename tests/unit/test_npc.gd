extends GutTest
## Lot 6, puis acte 1 : PNJ (src/npc/npc.tscn), données data/npcs/*.tres (les PNJ de l'acte 1 et
## leurs visuels non jouables data/npcs/visuals/), emplacements de HISTOIRE.md section 3.3.

const NPC_SCENE := preload("res://src/npc/npc.tscn")
const PLAYER_STUB := preload("res://tests/stubs/player_stub.tscn")
const NYGGLATHO := preload("res://data/npcs/nygglatho.tres")
const NPCS_DIR := "res://data/npcs"
const VISUALS_DIR := "res://data/npcs/visuals"
## PNJ de l'acte 1 : nom affiché, visuel, quête donnée, zone (HISTOIRE.md 3.3, 5.1 et 5.2).
const NPCS := {
	&"nygglatho": ["Nygglatho", &"nygglatho", &"act1_main", &"village"],
	&"willem": ["Willem", &"willem", &"special_dessert", &"village"],
	&"willem_training": ["Willem", &"willem", &"", &"forest"],
	&"willem_stars": ["Willem", &"willem", &"", &"hill"],
	&"ithea": ["Ithea", &"ithea", &"old_clock", &"village"],
	&"nephren": ["Nephren", &"nephren", &"picture_book", &"village"],
	&"tiat": ["Tiat", &"tiat", &"vigil_register", &"village"],
	&"pannibal": ["Pannibal", &"pannibal", &"", &"forest"],
	&"collon": ["Collon", &"collon", &"", &"village"],
	&"lakhesh": ["Lakhesh", &"lakhesh", &"", &"village"],
	&"almita": ["Almita", &"almita", &"", &"village"],
	&"limeskin": ["Limeskin", &"limeskin", &"", &"beach"],
	&"cat_waiter": ["Serveur", &"cat_waiter", &"", &"beach"],
	&"ramikeldi": ["M. Rami", &"ramikeldi", &"", &"beach"],
	&"snack_vendor": ["Cuistot du snack", &"snack_vendor", &"", &"beach"],
	&"baker": ["Boulanger", &"baker", &"", &"beach"],
	&"ferryman": ["Passeur", &"ferryman", &"", &"beach"],
	&"egg_vendor": ["Marchande d’œufs", &"egg_vendor", &"", &"beach"],
	&"garde_lookout": ["Guetteur", &"garde_lookout", &"", &"dunes"],
}
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
	&"baker": 2.0,
	&"ferryman": 1.7,
	&"egg_vendor": 1.55,
	&"garde_lookout": 1.9,
}
## Emplacements (nœud, PNJ, position locale à la zone) de HISTOIRE.md 3.3. Deux écarts notés dans
## docs/DECISIONS.md pour le décor actuel : le guetteur s'écarte de la ruine (prévu en (−14 ; −10))
## et Willem se tient sur le plateau du belvédère, entre sa rambarde et le banc (prévu en (3 ; 0)).
const PLACEMENTS := {
	"village":
	[
		["Nygglatho", &"nygglatho", Vector3(-9, 0.2, -8.5)],
		["Willem", &"willem", Vector3(-13.5, 0.2, 0)],
		["Nephren", &"nephren", Vector3(-4, 0.2, -9.5)],
		["Ithea", &"ithea", Vector3(3, 0.2, 2.5)],
		["Tiat", &"tiat", Vector3(-3.5, 0.2, 5)],
		["Collon", &"collon", Vector3(10, 0.2, -10)],
		["Lakhesh", &"lakhesh", Vector3(-12, 0.2, -6)],
		["Almita", &"almita", Vector3(11, 0.2, 7)],
	],
	"forest":
	[
		["Pannibal", &"pannibal", Vector3(-20, 0.2, -3)],
		["WillemTraining", &"willem_training", Vector3(-9, 0.2, 10)],
	],
	"dunes": [["GardeLookout", &"garde_lookout", Vector3(-13, 0.2, -12)]],
	"beach":
	[
		["Limeskin", &"limeskin", Vector3(-20, 0.2, 12)],
		["CatWaiter", &"cat_waiter", Vector3(-14, 0.2, -6.5)],
		["EggVendor", &"egg_vendor", Vector3(-24, 0.2, 2)],
		["SnackVendor", &"snack_vendor", Vector3(-6, 0.2, 1)],
		["Ramikeldi", &"ramikeldi", Vector3(26, 0.2, -6.5)],
		["Ferryman", &"ferryman", Vector3(12, 0.2, 13)],
		["Baker", &"baker", Vector3(-4, 0.2, -7)],
	],
	"hill": [["WillemStars", &"willem_stars", Vector3(1, 8.2, -0.8)]],
}
## Déclencheurs de la quête principale (HISTOIRE.md 3.3) : zone, id, position, rayon, hauteur.
## couchant_edge est posé sur le sol actuel (0,1 m ; 0 dans HISTOIRE.md).
const TRIGGERS: Array[Array] = [
	["dunes", &"couchant_edge", Vector3(-21, 0.1, -12), 3.0, 3.0],
	["hill", &"hill_summit", Vector3(1, 8, -3), 4.0, 3.0],
]
## Spawn du village (PLAN.md section 3, repères de l'île).
const VILLAGE_SPAWN := Vector3(0.0, 0.2, 9.0)

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
		assert_eq(data.quest_id, fields[2], "%s : quête" % npc_id)
		assert_eq(data.home_zone, fields[3], "%s : zone" % npc_id)
		assert_eq(data.dialogue_path, "res://data/dialogues/%s.json" % npc_id)
		assert_true(FileAccess.file_exists(data.dialogue_path), "%s : dialogue" % npc_id)
	for file_name: String in ResourceLoader.list_directory(NPCS_DIR):
		if file_name.ends_with(".tres"):
			assert_has(NPCS, StringName(file_name.get_basename()), "PNJ attendu : %s" % file_name)
	for old_id: String in ["librarian", "blacksmith", "child"]:
		assert_false(ResourceLoader.exists("%s/%s.tres" % [NPCS_DIR, old_id]), "%s retiré" % old_id)


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
		for anim: String in ["repos", "marche", "course", "attaque", "charge", "degats", "mort"]:
			assert_true(animations.has(anim), "%s : animation %s" % [visual_id, anim])
		assert_eq(SheetLoader.hit_frames(sheet, &"attaque"), [1, 2, 3] as Array[int])
		assert_eq(SheetLoader.wave_frame(sheet, &"charge"), 3)
	assert_eq(SkinRegistry.all().size(), 1, "seule Chtholly reste jouable")


func test_placements_follow_the_story() -> void:
	for zone_id: String in PLACEMENTS:
		var packed := load("res://src/npc/placements/%s.tscn" % zone_id) as PackedScene
		var root := packed.instantiate() as Node3D
		assert_eq(root.name, &"NPCs", "%s : racine NPCs" % zone_id)
		add_child_autofree(root)
		var expected: Array = PLACEMENTS[zone_id]
		var positions: Array[Vector3] = []
		for child: Node in root.get_children():
			if child is QuestTrigger:
				continue
			assert_true(child is Npc, "%s/%s est un Npc" % [zone_id, child.name])
			positions.append((child as Node3D).position)
		assert_eq(positions.size(), expected.size(), "%s : nombre de PNJ" % zone_id)
		for entry: Array in expected:
			var npc := root.get_node_or_null(NodePath(String(entry[0]))) as Npc
			assert_not_null(npc, "%s/%s" % [zone_id, entry[0]])
			if npc == null:
				continue
			assert_eq(npc.data.id, entry[1], "%s : données" % entry[0])
			assert_almost_eq(npc.position, entry[2] as Vector3, Vector3.ONE * 0.001, "position")
		for i: int in positions.size():
			for j: int in range(i + 1, positions.size()):
				assert_gt(positions[i].distance_to(positions[j]), 2.5, "%s : PNJ espacés" % zone_id)
		if zone_id == "village":
			for spot: Vector3 in positions:
				var from_spawn := Vector2(spot.x - VILLAGE_SPAWN.x, spot.z - VILLAGE_SPAWN.z)
				assert_gt(from_spawn.length(), 3.0, "le Spawn reste libre")


func test_triggers_of_the_main_quest() -> void:
	for entry: Array in TRIGGERS:
		var packed := load("res://src/npc/placements/%s.tscn" % entry[0]) as PackedScene
		var root: Node3D = add_child_autofree(packed.instantiate())
		var trigger := root.get_node_or_null(NodePath(String(entry[1]))) as QuestTrigger
		assert_not_null(trigger, "%s/%s" % [entry[0], entry[1]])
		if trigger == null:
			continue
		assert_eq(trigger.id(), entry[1])
		assert_almost_eq(trigger.position, entry[2] as Vector3, Vector3.ONE * 0.001)
		assert_eq(trigger.radius, float(entry[3]), "rayon")
		assert_eq(trigger.height, float(entry[4]), "hauteur")
