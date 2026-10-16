extends "res://tests/stubs/m2_game_test.gd"
## (E7) Les navires dans la vraie partie (main.tscn, appuis réels) : au port, le poste est vide et
## le bord du vide fermé ; le transport de la Garde à quai, passerelle posée, on monte la passerelle
## à pied jusqu'au seuil de la trappe (le pont, 1 m plus haut ; le bastingage arrête), puis on en
## redescend ; sans la permission du récit, pas de « Monter à bord » ; avec elle, on monte à bord
## (carte transport_garde, sur from_port), on traverse le pont, et « Descendre à quai » ramène au
## pied de la passerelle (from_transport_garde).

const SHIP := &"transport_garde"
const PORT := &"port"

var _previous_fade: float


func before_each() -> void:
	super()
	_previous_fade = WorldManager.fade_time
	WorldManager.fade_time = 0.0


func after_each() -> void:
	WorldManager.fade_time = _previous_fade
	GameState.reset()
	super()


func _map() -> Map:
	return WorldManager.current_map_node()


func wait_transition(max_seconds: float = 10.0) -> bool:
	return await until(func() -> bool: return not WorldManager.is_transitioning(), max_seconds)


## Pose le joueur au sol en (x, z) de la carte, visée aim, et attend qu'il touche le sol.
func put_player(x: float, z: float, aim: Vector3) -> void:
	var ground := _map().get_node(^"Ground") as MapGround
	player.global_position = _map().to_global(Vector3(x, ground.height_at(x, z) + 0.1, z))
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	player.set_aim_direction(aim, true)
	await frames(3)
	await until(func() -> bool: return player.is_on_floor(), 2.0)
	await frames(1)


func _local() -> Vector3:
	return _map().to_local(player.global_position)


func test_the_empty_berth_keeps_the_void_closed() -> void:
	assert_true(await new_game_from_menu(), "partie lancée depuis le menu")
	await WorldManager.go_to(PORT, &"from_transport_garde")
	assert_true(await wait_transition(), "au port")
	var berth := _map().get_node(^"Berth") as ShipBerth
	assert_false(berth.ship().visible, "le poste est vide")
	await put_player(32.5, 8.0, Vector3.FORWARD)
	assert_eq(player.current_prompt(), "", "pas de « Monter à bord »")
	await walk_keys_until([KEY_W], func() -> bool: return _local().z < 4.0, 2.5)
	release_all_input()
	assert_gt(_local().z, 5.0, "le bord du vide arrête le joueur")
	assert_almost_eq(_local().y, 0.0, 0.1, "sur le quai")


func test_up_the_gangway_aboard_across_the_deck_and_back() -> void:
	assert_true(await new_game_from_menu(), "partie lancée depuis le menu")
	ShipControl.pose(SHIP, &"deploy_gangway")
	await WorldManager.go_to(PORT, &"from_transport_garde")
	assert_true(await wait_transition(), "au port")
	var berth := _map().get_node(^"Berth") as ShipBerth
	assert_true(berth.ship().visible, "le transport de la Garde est à quai")
	assert_true(berth.gate_open(), "passerelle posée")
	# On monte la passerelle à pied jusqu'au seuil de la trappe.
	await put_player(32.5, 8.2, Vector3.FORWARD)
	assert_true(
		await walk_keys_until([KEY_W], func() -> bool: return _local().y > 0.85, 6.0),
		"en haut de la passerelle"
	)
	await hold_key(KEY_W, 1.0)
	release_all_input()
	await frames(4)
	assert_almost_eq(_local().y, 1.0, 0.15, "le pont, 1 m au-dessus du quai")
	assert_gt(_local().z, 3.0, "le bastingage arrête (on n'entre pas dans la coque)")
	assert_eq(player.current_prompt(), "", "à l'acte 1, on ne monte pas à bord")
	# Puis on redescend sur le quai.
	assert_true(
		await walk_keys_until([KEY_S], func() -> bool: return _local().z > 7.4, 6.0), "redescendu"
	)
	release_all_input()
	await frames(4)
	assert_almost_eq(_local().y, 0.0, 0.1, "sur le quai")
	# Le récit permet d'embarquer : « Monter à bord », au pied de la passerelle.
	ShipControl.allow_boarding(SHIP)
	await put_player(32.5, 7.9, Vector3.FORWARD)
	assert_true(
		await until(func() -> bool: return player.current_prompt() == "Monter à bord", 3.0),
		"« Monter à bord » au pied de la passerelle"
	)
	await tap_key(KEY_E)
	assert_true(
		await until(func() -> bool: return WorldManager.current_map() == SHIP, 5.0), "à bord"
	)
	assert_true(await wait_transition(), "arrivée sur le pont")
	assert_lt(distance_to(_map().marker(&"from_port")), 0.3, "posé sur from_port")
	# Le pont se traverse, vers la proue.
	assert_true(
		await walk_keys_until([KEY_D], func() -> bool: return _local().x > 15.0, 6.0),
		"vers la proue"
	)
	release_all_input()
	# « Descendre à quai », en haut de la passerelle du pont.
	await put_player(10.0, 4.6, Vector3.BACK)
	assert_true(
		await walk_keys_until(
			[KEY_S], func() -> bool: return player.current_prompt() == "Descendre à quai", 4.0
		),
		"« Descendre à quai »"
	)
	release_all_input()
	await tap_key(KEY_E)
	assert_true(
		await until(func() -> bool: return WorldManager.current_map() == PORT, 5.0), "au port"
	)
	assert_true(await wait_transition(), "retour au port")
	assert_lt(distance_to(_map().marker(&"from_transport_garde")), 0.3, "au pied de la passerelle")
	assert_true((_map().get_node(^"Berth") as ShipBerth).ship().visible, "toujours à quai")
