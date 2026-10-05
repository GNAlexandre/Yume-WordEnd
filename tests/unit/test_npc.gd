extends GutTest
## Lot 6 : PNJ (src/npc/npc.tscn), données data/npcs/*.tres et emplacement du village.

const NPC_SCENE := preload("res://src/npc/npc.tscn")
const PLAYER_STUB := preload("res://tests/stubs/player_stub.tscn")
const LIBRARIAN := preload("res://data/npcs/librarian.tres")
const VILLAGE_NPCS := preload("res://src/npc/placements/village.tscn")
const NPC_IDS: Array[StringName] = [&"librarian", &"blacksmith", &"child"]
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


func _npc(data: NpcData = LIBRARIAN) -> Npc:
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
	assert_eq(_started, [&"librarian"] as Array[StringName])
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
	assert_eq(npc.visual.skin, LIBRARIAN.skin, "skin data.skin")
	assert_eq(npc.visual.current_animation(), &"repos")
	await wait_seconds(0.4)
	assert_ne(npc.visual.scale.y, 1.0, "respiration au repos")
	assert_almost_eq(npc.visual.scale.y, 1.0, npc.breath_amount + 0.001)


func test_data_can_be_set_after_ready() -> void:
	var npc := _npc(null)
	npc.data = LIBRARIAN
	assert_eq(npc.visual.skin, LIBRARIAN.skin)
	npc.interact(null)
	assert_eq(_started, [&"librarian"] as Array[StringName])
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
	npc.data = LIBRARIAN
	npc.position = Vector3(0.0, 0.6, 0.0)
	add_child_autofree(npc)
	await wait_physics_frames(40)
	assert_almost_eq(npc.global_position.y, 0.1, 0.05, "posé sur le sol (dessus à y = 0,1)")
	assert_false(npc.is_physics_processing(), "immobile une fois posé")


func test_npc_data_files() -> void:
	var expected := {
		&"librarian": ["Bibliothécaire", &"bibliothecaire", &"pages"],
		&"blacksmith": ["Forgeron", &"forgeron", &""],
		&"child": ["Enfant", &"enfant", &""],
	}
	for npc_id: StringName in NPC_IDS:
		var data := load("res://data/npcs/%s.tres" % npc_id) as NpcData
		assert_not_null(data, "data/npcs/%s.tres" % npc_id)
		if data == null:
			continue
		var fields: Array = expected[npc_id]
		assert_eq(data.id, npc_id, "id = nom du fichier")
		assert_eq(data.display_name, fields[0])
		assert_not_null(data.skin)
		if data.skin != null:
			assert_eq(data.skin.id, fields[1], "%s : skin" % npc_id)
		assert_eq(data.quest_id, fields[2], "%s : quête" % npc_id)
		assert_eq(data.home_zone, &"village")
		assert_eq(data.dialogue_path, "res://data/dialogues/%s.json" % npc_id)


func test_village_placement() -> void:
	var root: Node3D = add_child_autofree(VILLAGE_NPCS.instantiate())
	assert_eq(root.name, &"NPCs")
	var found: Array[String] = []
	var positions: Array[Vector3] = []
	for child: Node in root.get_children():
		var npc := child as Npc
		assert_not_null(npc, "%s est un Npc" % child.name)
		if npc == null or npc.data == null:
			continue
		found.append(String(npc.data.id))
		var spot := npc.position
		positions.append(spot)
		assert_lt(maxf(absf(spot.x), absf(spot.z)), 22.0, "%s dans le village" % npc.name)
		assert_between(spot.y, 0.0, 0.5, "%s au niveau du sol" % npc.name)
		var from_spawn := Vector2(spot.x - VILLAGE_SPAWN.x, spot.z - VILLAGE_SPAWN.z).length()
		assert_between(from_spawn, 3.0, 9.0, "%s à quelques mètres du Spawn" % npc.name)
		assert_gt(Vector2(spot.x, spot.z).length(), 2.5, "%s hors de la fontaine" % npc.name)
		assert_lt(Vector2(spot.x, spot.z).length(), 9.0, "%s autour de la place" % npc.name)
		assert_gt(absf(spot.x), 1.5, "%s laisse libre l'allée nord-sud du Spawn" % npc.name)
	found.sort()
	assert_eq(found, ["blacksmith", "child", "librarian"] as Array[String])
	for i: int in positions.size():
		for j: int in range(i + 1, positions.size()):
			assert_gt(positions[i].distance_to(positions[j]), 2.5, "PNJ espacés")
