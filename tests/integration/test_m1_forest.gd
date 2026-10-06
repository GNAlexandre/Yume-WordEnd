extends "res://tests/stubs/m1_game_test.gd"
## Intégration M1, la forêt dans le vrai jeu (src/game.tscn) : ses 4 Timeres poursuivent le
## joueur qui approche de la clairière, abandonnent quand il fuit au village (laisse, zone sûre)
## sans jamais y entrer ; la barrière du village arrête un Timere repoussé vers elle ; un Timere
## tué lâche une page que le joueur ramasse ; la mort dans la forêt ramène au village sans
## fin de série d'arène.

## Bord nord du village : la barrière (couche 8) va de z = −22,5 à −21,5 (coordonnées de l'île).
const BARRIER_NORTH_FACE := -22.5


func _forest_timeres() -> Array[Enemy]:
	var result: Array[Enemy] = []
	for child: Node in zone(&"forest").get_node(^"Enemies").get_children():
		if child is Enemy:
			result.append(child as Enemy)
	return result


func _hunting(timeres: Array[Enemy]) -> int:
	var count := 0
	for timere: Enemy in timeres:
		if is_instance_valid(timere) and timere.state() in [&"chase", &"rush", &"attack"]:
			count += 1
	return count


func test_forest_timeres_chase_then_give_up_before_the_village() -> void:
	await start_game()
	health.max_hp = 99
	health.reset()
	var timeres := _forest_timeres()
	assert_eq(timeres.size(), 4, "4 Timeres dans la forêt")
	await place_player(&"forest", Vector3(0.0, 0.0, 8.0), Vector3.FORWARD)
	var chased: bool = await wait_until(func() -> bool: return _hunting(timeres) >= 2, 3.0)
	assert_true(chased, "les Timeres de la clairière poursuivent le joueur")
	var deepest: Array[float] = [-INF]
	var watch := func() -> void:
		for timere: Enemy in timeres:
			if is_instance_valid(timere):
				deepest[0] = maxf(deepest[0], timere.global_position.z)
	get_tree().physics_frame.connect(watch)
	# Fuite vers le village (au sud), en courant.
	player.set_aim_direction(Vector3.BACK, true)
	Input.action_press(&"run")
	Input.action_press(&"move_forward")
	var home: bool = await wait_until(
		func() -> bool: return WorldManager.current_zone() == &"village", 8.0
	)
	Input.action_release(&"move_forward")
	Input.action_release(&"run")
	assert_true(home, "le joueur rentre au village")
	await wait_seconds(1.5)
	get_tree().physics_frame.disconnect(watch)
	assert_eq(_hunting(timeres), 0, "plus aucune poursuite")
	assert_lt(deepest[0], BARRIER_NORTH_FACE, "aucun Timere n'est entré au village")


func test_village_barrier_stops_a_timere_pushed_toward_it() -> void:
	await start_game()
	health.max_hp = 99
	health.reset()
	# Côté forêt, au pied de la barrière : un Grand entre le joueur et le village.
	player.global_position = WorldManager.ground_position(Vector3(0.0, 0.0, -26.0), player)
	player.set_aim_direction(Vector3.BACK, true)
	var big := spawn_enemy(&"timere_big", Vector3(0.0, 0.05, -23.3), true)
	await wait_physics_frames(3)
	assert_eq(WorldManager.current_zone(), &"forest")
	var waves: Array[Node3D] = []
	combat.wave_launched.connect(func(wave: Node3D) -> void: waves.append(wave))
	await hold(&"charge", 0.65)
	var pushed: bool = await wait_until(func() -> bool: return big.knockback().z > 1.0, 1.0)
	assert_true(pushed, "l'onde repousse le Grand vers le village")
	big.set_physics_process(true)
	var deepest: Array[float] = [-INF]
	var watch := func() -> void: deepest[0] = maxf(deepest[0], big.global_position.z)
	get_tree().physics_frame.connect(watch)
	await wait_seconds(0.6)
	get_tree().physics_frame.disconnect(watch)
	var radius := 0.4 * big.data.scale
	assert_lt(deepest[0], BARRIER_NORTH_FACE - radius + 0.05, "arrêté par la barrière")
	assert_gt(deepest[0], -23.3 + 0.1, "il a bien été poussé contre elle")


func test_forest_timere_drops_a_page_that_the_player_picks_up() -> void:
	await start_game()
	watch_signals(EventBus)
	# À l'écart des pages posées (forest_page_1 est en (−3, 0, 2)).
	await place_player(&"forest", Vector3(-6.0, 0.0, 5.0), Vector3.FORWARD)
	var small: Enemy = null
	for timere: Enemy in _forest_timeres():
		if timere.enemy_id() == &"timere_small":
			small = timere
	small.set_physics_process(false)
	small.global_position = ahead(1.0)
	await wait_physics_frames(2)
	await press(&"attack")
	var killed: bool = await wait_until(func() -> bool: return small.is_dead(), 1.0)
	assert_true(killed, "Petit de la forêt tué à l'épée")
	var drops: Array[Pickup] = []
	var dropped: bool = await wait_until(
		func() -> bool:
			for child: Node in zone(&"forest").get_node(^"Enemies").get_children():
				if child is Pickup and not drops.has(child):
					drops.append(child as Pickup)
			return not drops.is_empty(),
		1.0
	)
	assert_true(dropped, "une page lâchée")
	if not dropped:
		return
	var page := drops[0]
	assert_eq(page.item_id, &"page_fragment")
	assert_false(page.persistent, "objet lâché : pas retenu par la sauvegarde")
	assert_lt(flat_distance(page.global_position, small.global_position), 0.3, "à sa place")
	await hold(&"move_forward", 0.5)
	var collected: bool = await wait_until(
		func() -> bool: return GameState.count(&"page_fragment") == 1, 1.0
	)
	assert_true(collected, "le joueur ramasse la page en passant dessus")
	assert_signal_emitted_with_parameters(EventBus, "item_collected", [&"page_fragment", 1])


func test_death_in_the_forest_respawns_at_the_village_without_arena() -> void:
	await start_game()
	watch_signals(EventBus)
	var timeres := _forest_timeres()
	await place_player(&"forest", Vector3(0.0, 0.0, 8.0), Vector3.FORWARD)
	health.take_damage(4, game)
	var died: bool = await wait_until(func() -> bool: return health.is_dead(), 10.0)
	assert_true(died, "mordu à mort par les Timeres de la forêt")
	await wait_seconds(1.0)
	assert_eq(_hunting(timeres), 0, "plus de poursuite d'un joueur mort")
	var respawned: bool = await wait_until(func() -> bool: return not health.is_dead(), 4.0)
	assert_true(respawned, "réapparition")
	await wait_physics_frames(3)
	var spawn := zone(&"village").get_node(^"Spawn") as Node3D
	assert_lt(flat_distance(player.global_position, spawn.global_position), 0.5, "au village")
	assert_eq(health.current, 5, "PV pleins")
	assert_signal_not_emitted(EventBus, "arena_finished", "pas d'arène dans la forêt")
	await wait_seconds(1.0)
	assert_eq(_hunting(timeres), 0, "les Timeres ne le suivent pas au village")
	for timere: Enemy in timeres:
		if is_instance_valid(timere):
			assert_lt(
				timere.global_position.z, BARRIER_NORTH_FACE, "%s reste en forêt" % timere.name
			)
