extends "res://tests/stubs/q_quest_test.gd"
## (Systèmes et textes) Présence des PNJ selon l'histoire (HISTOIRE.md, développement n° 1) :
## NpcData.visible_if, même grammaire et même évaluateur que les « if » de dialogue (drapeaux,
## objets, état et étape de quête, listes d'étapes et négation, meilleur score) ; un PNJ absent est
## caché, retiré de la physique (corps et zone d'interaction), sans invite, sans dialogue, sans
## marqueur ; réévaluation en fin d'image sur les signaux ; un PNJ qui parle ne part qu'à la fin
## de la conversation ; le PNJ au skin du joueur n'est jamais là ; l'exemple de docs/QUETES.md.

const NPC_SCENE := preload("res://src/npc/npc.tscn")
const DIR := "user://test_npc_presence"
const SKINS_DIR := DIR + "/skins"
const NPC_ID := &"sys_guide"

var _world: Node3D
var _started: Array[StringName] = []


func before_each() -> void:
	super()
	DirAccess.make_dir_recursive_absolute(SKINS_DIR)
	_world = add_child_autofree(Node3D.new())
	_started.clear()
	EventBus.dialogue_started.connect(_on_dialogue_started)
	# Une quête disponible donnée par le PNJ : « ! » au-dessus de lui quand il est là.
	write_quest(
		{
			"id": "sys_presence",
			"title": "Présence",
			"giver": String(NPC_ID),
			"steps": [{"id": "a", "type": "flag", "flag": "sys_done", "objective": "Attendre"}],
		}
	)


func after_each() -> void:
	EventBus.dialogue_started.disconnect(_on_dialogue_started)
	if SkinRegistry.skins_dir != SkinRegistry.SKINS_DIR:
		SkinRegistry.skins_dir = SkinRegistry.SKINS_DIR
		SkinRegistry.reload()
	for dir: String in [SKINS_DIR, DIR]:
		for file_name: String in DirAccess.get_files_at(dir):
			DirAccess.remove_absolute(dir.path_join(file_name))
	super()


func _on_dialogue_started(npc_id: StringName) -> void:
	_started.append(npc_id)


func _dialogue_path() -> String:
	var path := DIR.path_join("sys_guide.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	var nodes := {"hello": {"text": "Bonjour.", "next": "bye"}, "bye": {"text": "À plus."}}
	file.store_string(JSON.stringify({"start": "hello", "nodes": nodes}))
	file.close()
	return path


func _data(condition: Dictionary = {}, skin: SkinData = null) -> NpcData:
	var data := NpcData.new()
	data.id = NPC_ID
	data.display_name = "Guide"
	data.dialogue_path = _dialogue_path()
	data.skin = skin
	data.visible_if = condition
	return data


func _npc(data: NpcData) -> Npc:
	var npc := NPC_SCENE.instantiate() as Npc
	npc.data = data
	_world.add_child(npc)
	return npc


## Vrai si le corps du PNJ et sa zone d'interaction sont dans l'espace physique.
func _in_physics(npc: Npc) -> bool:
	var area := npc.get_node(^"InteractArea") as Area3D
	return (
		PhysicsServer3D.body_get_space(npc.get_rid()).is_valid()
		and PhysicsServer3D.area_get_space(area.get_rid()).is_valid()
	)


## Zone de détection comme celle du joueur (masque 6, interactable) autour du PNJ.
func _detector(npc: Npc) -> Area3D:
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 32
	area.monitorable = false
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 3.0
	shape.shape = sphere
	area.add_child(shape)
	_world.add_child(area)
	area.global_position = npc.global_position
	return area


## Skins jouables de test (user://), dont l'un est celui du joueur.
func _test_skins() -> Array[SkinData]:
	var skins: Array[SkinData] = []
	for entry: Array in [[&"sys_lyra", "Lyra"], [&"sys_mira", "Mira"]]:
		var skin := SkinData.new()
		skin.id = entry[0]
		skin.display_name = entry[1]
		assert_eq(ResourceSaver.save(skin, SKINS_DIR.path_join("%s.tres" % entry[0])), OK)
		skins.append(skin)
	SkinRegistry.skins_dir = SKINS_DIR
	SkinRegistry.reload()
	return skins


# --- La condition -----------------------------------------------------------------------------


func test_visible_if_reads_the_dialogue_grammar() -> void:
	assert_true(_data().is_present(), "{} : toujours là")
	var data := _data({"flag": "sys_here"})
	assert_false(data.is_present(), "drapeau absent")
	GameState.set_flag(&"sys_here")
	assert_true(data.is_present(), "drapeau posé")
	data.visible_if = {"not_flag": ["sys_gone"], "count": ["page_fragment", 2]}
	GameState.add_item(&"page_fragment")
	assert_false(data.is_present(), "une page sur deux")
	GameState.add_item(&"page_fragment")
	assert_true(data.is_present(), "deux pages")
	GameState.set_flag(&"sys_gone")
	assert_false(data.is_present(), "not_flag")
	data.visible_if = {"quest": ["sys_presence", "available"]}
	assert_true(data.is_present(), "quête disponible")
	start_quest(&"sys_presence")
	assert_false(data.is_present(), "plus disponible : en cours")
	data.visible_if = {"quest": ["sys_presence", "active"]}
	assert_true(data.is_present())
	data.visible_if = {"best_score": ["dunes", 300]}
	assert_false(data.is_present(), "aucun record")
	GameState.record_score(&"dunes", 320, 4)
	assert_true(data.is_present(), "record de 320")


## Exemple de docs/QUETES.md : Willem au terrain d'entraînement seulement pendant l'étape
## training, et au village sauf pendant training et promise (listes d'étapes, négation).
func test_quest_step_lists_and_negation() -> void:
	var steps: Array = []
	for step_id: String in ["morning", "training", "evening", "promise"]:
		(
			steps
			. append(
				{
					"id": step_id,
					"type": "flag",
					"flag": "sys_%s_done" % step_id,
					"objective": "Étape %s" % step_id,
				}
			)
		)
	write_quest({"id": "sys_story", "title": "Histoire", "main": true, "steps": steps})
	var training := _data({"quest_step": ["sys_story", "training"]})
	var village := _data({"not_quest_step": ["sys_story", ["training", "promise"]]})
	var stars := _data({"quest_step": ["sys_story", ["promise"]]})
	var expected := {
		"": [false, true, false],
		"morning": [false, true, false],
		"training": [true, false, false],
		"evening": [false, true, false],
		"promise": [false, false, true],
		"done": [false, true, false],
	}
	for stage: String in ["", "morning", "training", "evening", "promise", "done"]:
		if stage == "morning":
			start_quest(&"sys_story")
		elif not stage.is_empty():
			GameState.set_flag(StringName("sys_%s_done" % step_of(&"sys_story")))
		var where := "étape %s" % (String(step_of(&"sys_story")) if not stage.is_empty() else "-")
		assert_eq(
			[training.is_present(), village.is_present(), stars.is_present()],
			expected[stage],
			"%s : terrain, village, sommet" % where
		)
	assert_eq(GameState.quest_state(&"sys_story"), &"done")


## La syntaxe .tres de docs/QUETES.md (« La présence des PNJ ») se charge telle quelle.
func test_visible_if_written_in_a_tres_file() -> void:
	var text := (
		"\n"
		. join(
			[
				'[gd_resource type="Resource" script_class="NpcData" format=3]',
				"",
				'[ext_resource type="Script" path="res://src/npc/npc_data.gd" id="1_npc"]',
				"",
				"[resource]",
				'script = ExtResource("1_npc")',
				'id = &"sys_willem_training"',
				'display_name = "Willem"',
				"visible_if = {",
				'"quest_step": ["sys_act", "training"]',
				"}",
				"",
			]
		)
	)
	var path := DIR.path_join("sys_willem_training.tres")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()
	var npc := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as NpcData
	assert_not_null(npc, "NpcData lue")
	if npc == null:
		return
	assert_eq_deep(npc.visible_if, {"quest_step": ["sys_act", "training"]})
	assert_eq(npc.visible_if_problem(), "", "condition valide")
	assert_false(npc.is_present(), "quête pas commencée")
	GameState.set_quest_state(&"sys_act", &"active")
	GameState.set_quest_step(&"sys_act", &"training")
	assert_true(npc.is_present(), "pendant l'étape training")
	GameState.set_quest_step(&"sys_act", &"evening")
	assert_false(npc.is_present(), "après")


func test_visible_if_is_validated_like_a_dialogue_condition() -> void:
	for valid: Dictionary in [
		{},
		{"flag": "a", "not_flag": ["b", "c"]},
		{"count": ["page_fragment", 2], "best_score": ["dunes", 300.0]},
		{"quest": ["act1_main", "done"], "quest_step": ["act1_main", "training"]},
		{"not_quest_step": [&"act1_main", [&"training", "promise"]]},
	]:
		assert_eq(_data(valid).visible_if_problem(), "", "valide : %s" % valid)
	var cases := {
		"condition inconnue « quest_stage »": {"quest_stage": ["q", "a"]},
		"valeur mal formée pour « quest_step »": {"quest_step": ["q", 2]},
		"valeur mal formée pour « not_quest_step »": {"not_quest_step": ["q", []]},
		"valeur mal formée pour « count »": {"count": "page_fragment"},
		"valeur mal formée pour « flag »": {"flag": ""},
	}
	for expected: String in cases:
		assert_string_contains(_data(cases[expected]).visible_if_problem(), expected)


# --- Le PNJ dans la scène ---------------------------------------------------------------------


func test_absent_npc_is_hidden_without_collision_dialogue_or_marker() -> void:
	var npc := _npc(_data({"flag": "sys_here"}))
	var detector := _detector(npc)
	await wait_physics_frames(3)
	assert_false(npc.is_present(), "condition fausse : absent")
	assert_false(npc.visible, "caché")
	assert_false(_in_physics(npc), "ni corps ni zone d'interaction dans la physique")
	assert_false(detector.get_overlapping_areas().has(npc.get_node(^"InteractArea")), "invisible")
	assert_eq(npc.get_prompt(), "", "aucune invite")
	assert_eq(QuestData.npc_marker(NPC_ID), QuestData.MARKER_AVAILABLE, "il a une quête…")
	assert_false(npc.quest_marker.visible, "… mais pas de « ! » quand il n'est pas là")
	npc.interact(null)
	assert_eq(_started, [] as Array[StringName], "pas de dialogue")
	# La condition devient vraie : il revient en fin d'image, tout entier.
	GameState.set_flag(&"sys_here")
	await wait_process_frames(1)
	await wait_physics_frames(3)
	assert_true(npc.is_present(), "présent")
	assert_true(npc.visible)
	assert_true(_in_physics(npc), "dans la physique")
	assert_true(detector.get_overlapping_areas().has(npc.get_node(^"InteractArea")), "détecté")
	assert_eq(npc.get_prompt(), "Parler")
	assert_true(npc.quest_marker.visible, "« ! »")
	npc.interact(null)
	assert_eq(_started, [NPC_ID] as Array[StringName], "le dialogue démarre")
	npc.runner.stop()


func test_presence_follows_the_story_signals() -> void:
	var by_flag := _npc(_data({"flag": "sys_here"}))
	var by_item := _npc(_data({"count": ["page_fragment", 1]}))
	var by_quest := _npc(_data({"quest": ["sys_presence", "active"]}))
	var by_step := _npc(_data({"not_quest_step": ["sys_presence", "a"]}))
	var by_score := _npc(_data({"best_score": ["dunes", 100]}))
	var by_load := _npc(_data({"flag": "sys_loaded"}))
	await wait_process_frames(1)
	var npcs: Array[Npc] = [by_flag, by_item, by_quest, by_step, by_score, by_load]
	assert_eq(
		npcs.map(func(n: Npc) -> bool: return n.is_present()),
		[false, false, false, true, false, false]
	)
	GameState.set_flag(&"sys_here")
	GameState.add_item(&"page_fragment")
	start_quest(&"sys_presence")
	await wait_process_frames(1)
	assert_true(by_flag.is_present(), "flag_changed")
	assert_true(by_item.is_present(), "inventory_changed")
	assert_true(by_quest.is_present(), "quest_updated")
	assert_false(by_step.is_present(), "quest_step_updated : à l'étape a, absent")
	GameState.record_score(&"dunes", 120, 2)
	EventBus.arena_finished.emit(&"dunes", 120, true)
	await wait_process_frames(1)
	assert_true(by_score.is_present(), "arena_finished : meilleur score")
	var saved := GameState.to_dict()
	saved["flags"] = {"sys_loaded": true}
	GameState.from_dict(saved)
	EventBus.game_loaded.emit()
	await wait_process_frames(1)
	assert_true(by_load.is_present(), "game_loaded")
	assert_false(by_flag.is_present(), "partie chargée sans sys_here")


func test_talking_npc_leaves_only_after_the_conversation() -> void:
	var npc := _npc(_data({"not_flag": "sys_gone"}))
	await wait_process_frames(1)
	npc.interact(null)
	assert_true(npc.runner.is_running(), "conversation commencée")
	GameState.set_flag(&"sys_gone")
	await wait_process_frames(2)
	assert_true(npc.is_present(), "il finit sa phrase")
	assert_true(npc.visible)
	EventBus.dialogue_choice_made.emit(-1)
	EventBus.dialogue_choice_made.emit(-1)
	assert_false(npc.runner.is_running(), "conversation finie")
	await wait_process_frames(1)
	assert_false(npc.is_present(), "puis il s'en va")
	assert_false(npc.visible)


func test_npc_with_the_player_skin_is_always_hidden() -> void:
	var skins := _test_skins()
	var lyra := _npc(_data({}, skins[0]))
	var mira := _npc(_data({}, skins[1]))
	var nobody := _npc(_data({}, null))
	GameState.skin_id = &"sys_lyra"
	await wait_process_frames(1)
	assert_true(lyra.data.is_player_skin(), "même skin que le joueur")
	assert_false(lyra.is_present(), "la fée choisie n'est pas aussi un PNJ")
	assert_true(mira.is_present(), "les autres fées restent")
	assert_true(nobody.is_present(), "un PNJ sans skin reste")
	# skin_changed : le joueur change de fée, l'autre disparaît à son tour.
	GameState.skin_id = &"sys_mira"
	await wait_process_frames(1)
	assert_true(lyra.is_present(), "Lyra revient")
	assert_false(mira.is_present(), "Mira est le joueur")
	# Skin vide ou inconnu : celui par défaut (ici le premier, Lyra), comme le joueur.
	GameState.skin_id = &"inconnu"
	await wait_process_frames(1)
	assert_eq(DialogueRunner.player_skin().id, &"sys_lyra")
	assert_false(lyra.is_present())
	# Même une condition vraie ne le fait pas revenir.
	lyra.data.visible_if = {"flag": "sys_here"}
	GameState.set_flag(&"sys_here")
	await wait_process_frames(1)
	assert_false(lyra.is_present(), "jamais présent tant qu'il a le skin du joueur")
