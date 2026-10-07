extends "res://tests/stubs/m2_game_test.gd"
## (Systèmes et textes) Les développements du lot dans la vraie partie (src/main.tscn, appuis
## réels) : une chute hors de l'île (KillZone) ramène au Spawn de la zone avec un fondu au blanc
## et « Tes ailes se sont ouvertes : te revoilà au bord. » ; un PNJ du village dont la condition
## de présence devient fausse disparaît (plus d'invite, E ne lance rien, on le traverse), puis
## revient quand elle redevient vraie.

const FALL_MESSAGE := "Tes ailes se sont ouvertes : te revoilà au bord."


## Premier PNJ du village (quel que soit le contenu de l'acte), null s'il n'y en a pas.
func _village_npc() -> Npc:
	for node: Node in zone(&"village").get_node(^"NPCs").get_children():
		if node is Npc and (node as Npc).data != null and (node as Npc).is_present():
			return node as Npc
	return null


## Ce qu'un rayon vertical (couche world) touche d'abord à la place du PNJ, depuis 2 m (sous un
## éventuel auvent, au-dessus de sa capsule de 1,5 m).
func _first_hit_at(npc: Npc) -> Object:
	var space := npc.get_world_3d().direct_space_state
	var top := npc.global_position + Vector3.UP * 2.0
	var query := PhysicsRayQueryParameters3D.create(top, top + Vector3.DOWN * 5.0, 1)
	query.exclude = [player.get_rid()]
	return space.intersect_ray(query).get("collider")


func test_falling_off_the_island_opens_wings_of_light() -> void:
	assert_true(await new_game_from_menu(), "nouvelle partie")
	WorldManager.teleport(&"dunes")
	await wait_physics_frames(3)
	assert_eq(WorldManager.current_zone(), &"dunes")
	assert_eq(hud.call(&"story_message"), "", "rien avant la chute")
	watch_signals(WorldManager)
	# Sous l'île, dans la KillZone : le rattrapage.
	player.global_position = Vector3(-51.0, -12.0, 0.0)
	var rescued: bool = await until(func() -> bool: return player.global_position.y > -2.0, 2.0)
	assert_true(rescued, "rattrapée")
	assert_signal_emitted_with_parameters(WorldManager, "rescued", [&"dunes"])
	var spawn := zone(&"dunes").get_node(^"Spawn") as Node3D
	assert_lt(distance_to(spawn), 1.0, "au Spawn du bord du Couchant")
	assert_gt(hud.call(&"fall_flash_alpha"), 0.0, "fondu au blanc : les ailes de lumière")
	assert_eq(hud.call(&"story_message"), FALL_MESSAGE, "message de la chute")
	assert_eq(health.current, health.max_hp, "aucun PV perdu")
	var faded: bool = await until(func() -> bool: return hud.call(&"story_message") == "", 6.0)
	assert_true(faded, "le message s'efface")


func test_an_npc_whose_condition_turns_false_leaves_the_village() -> void:
	assert_true(await new_game_from_menu(), "nouvelle partie")
	var npc := _village_npc()
	assert_not_null(npc, "un PNJ au village")
	if npc == null:
		return
	# Sa présence dépend maintenant d'un drapeau (copie de ses données, même id, même dialogue).
	var data := npc.data.duplicate() as NpcData
	data.visible_if = {"not_flag": "sys_away"}
	npc.data = data
	var front := zone(&"village").to_local(npc.global_position) + Vector3(0.0, 0.0, 1.4)
	await place_player(&"village", front, Vector3.FORWARD)
	var prompted: bool = await until(
		func() -> bool: return player.current_prompt() == "Parler", 2.0
	)
	assert_true(prompted, "invite « Parler » devant %s" % npc.name)
	assert_eq(_first_hit_at(npc), npc, "son corps arrête un rayon (couche world)")
	GameState.set_flag(&"sys_away")
	await frames(3)
	assert_false(npc.is_present(), "%s est parti" % npc.name)
	assert_false(npc.is_visible_in_tree(), "caché")
	assert_eq(player.current_prompt(), "", "plus d'invite")
	assert_ne(_first_hit_at(npc), npc, "plus de corps : le rayon passe")
	await tap_key(KEY_E)
	await frames(2)
	assert_false(dialogue_box.is_open(), "E ne lance aucun dialogue")
	# Il revient quand la condition redevient vraie.
	GameState.set_flag(&"sys_away", false)
	await frames(3)
	assert_true(npc.is_present(), "%s est revenu" % npc.name)
	assert_eq(_first_hit_at(npc), npc, "son corps est revenu")
	prompted = await until(func() -> bool: return player.current_prompt() == "Parler", 2.0)
	assert_true(prompted, "de nouveau « Parler »")
	await tap_key(KEY_E)
	var talking: bool = await until(func() -> bool: return dialogue_box.is_open(), 2.0)
	assert_true(talking, "E lance son dialogue")
