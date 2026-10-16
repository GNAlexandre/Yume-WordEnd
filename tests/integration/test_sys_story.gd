extends "res://tests/stubs/m2_game_test.gd"
## (Systèmes et textes) Les développements du lot dans la vraie partie (src/main.tscn, appuis
## réels) : une chute hors de la carte ramène au dernier point sûr avec un fondu au blanc et le
## message de la chute (data/texts/story.json) ; un PNJ dont la condition de présence devient
## fausse disparaît (plus d'invite, E ne lance rien, on le traverse), puis revient quand elle
## redevient vraie. (F1) Sur la carte d'essai : l'ancienne île, sa KillZone et son village sont
## partis.

const FALL_MESSAGE := "Tes ailes se sont ouvertes : te revoilà au bord."

const NPC_SCENE := preload("res://src/npc/npc.tscn")


## Nygglatho posée sur la carte, à 3 m au nord du joueur (sa présence suit ses données).
func _put_npc() -> Npc:
	var npc := NPC_SCENE.instantiate() as Npc
	npc.data = DialogueRunner.find_npc(&"nygglatho")
	current_map().add_child(npc)
	npc.global_position = player.global_position + Vector3(0.0, 0.0, -3.0)
	return npc


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
	await wait_physics_frames(10)
	var stood_at := player.global_position
	assert_eq(hud.call(&"story_message"), "", "rien avant la chute")
	watch_signals(WorldManager)
	# Bien sous la carte : le rattrapage.
	player.global_position = stood_at + Vector3(0.0, WorldManager.FALL_LIMIT - 10.0, 0.0)
	var rescued: bool = await until(func() -> bool: return player.global_position.y > -2.0, 2.0)
	assert_true(rescued, "rattrapée")
	assert_signal_emitted_with_parameters(WorldManager, "rescued", [WorldManager.current_map()])
	assert_lt(flat_distance(player.global_position, stood_at), 1.0, "au dernier point sûr")
	assert_gt(hud.call(&"fall_flash_alpha"), 0.0, "fondu au blanc : les ailes de lumière")
	assert_eq(hud.call(&"story_message"), FALL_MESSAGE, "message de la chute")
	assert_eq(health.current, health.max_hp, "aucun PV perdu")
	var faded: bool = await until(func() -> bool: return hud.call(&"story_message") == "", 6.0)
	assert_true(faded, "le message s'efface")


func test_an_npc_whose_condition_turns_false_leaves() -> void:
	assert_true(await new_game_from_menu(), "nouvelle partie")
	var npc := _put_npc()
	await frames(3)
	# Sa présence dépend maintenant d'un drapeau (copie de ses données, même id, même dialogue).
	var data := npc.data.duplicate() as NpcData
	data.visible_if = {"not_flag": "sys_away"}
	npc.data = data
	var front := current_map().to_local(npc.global_position) + Vector3(0.0, 0.0, 1.4)
	await place_player(front, Vector3.FORWARD)
	var prompted: bool = await until(
		func() -> bool: return player.current_prompt() == "Parler", 2.0
	)
	assert_true(prompted, "invite « Parler » devant %s" % npc.name)
	# (U1) Le HUD montre le signe de la cible au-dessus d'elle (plus de pastille).
	var signs := hud.call(&"interact_signs") as Control
	assert_true(
		await until(func() -> bool: return signs.call(&"full_kind") == InteractSign.TALK, 2.0),
		"signe « parler »"
	)
	assert_eq(signs.call(&"full_target"), player.current_interactable())
	assert_eq(_first_hit_at(npc), npc, "son corps arrête un rayon (couche world)")
	GameState.set_flag(&"sys_away")
	await frames(3)
	assert_false(npc.is_present(), "%s est parti" % npc.name)
	assert_false(npc.is_visible_in_tree(), "caché")
	assert_eq(player.current_prompt(), "", "plus d'invite")
	assert_true(
		await until(func() -> bool: return signs.call(&"full_target") == null, 2.0),
		"plus de signe au-dessus du PNJ parti"
	)
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
