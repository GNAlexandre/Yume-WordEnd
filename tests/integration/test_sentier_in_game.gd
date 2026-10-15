extends "res://tests/stubs/m2_game_test.gd"
## (C1) Le sentier et le marais dans la vraie partie (main.tscn, appuis réels) : de l'entrepôt au
## sentier par la sortie à pied (on arrive sur from_entrepot), le long de la levée jusqu'au marais
## où l'on descend par la rampe (−0,5 m, eau basse : on y marche) ; la nuit, la lumière des fées du
## joueur est allumée ; au chemin de la ville, la rampe descend et l'écriteau « Plus loin, bientôt »
## s'offre à la lecture ; à l'est, la sortie à pied mène au port d'attente et l'on en revient sur
## from_port ; puis le retour à l'entrepôt, sur from_sentier.

const ENTREPOT := &"entrepot"
const SENTIER := &"sentier"
const PORT := &"port"

var _previous_fade: float


func before_each() -> void:
	super()
	_previous_fade = WorldManager.fade_time
	WorldManager.fade_time = 0.0


func after_each() -> void:
	WorldManager.fade_time = _previous_fade
	Atmosphere.player_light_mode = Atmosphere.LIGHT_AUTO
	GameState.reset()
	super()


func _map() -> Map:
	return WorldManager.current_map_node()


func _ground() -> MapGround:
	return _map().get_node(^"Ground") as MapGround


func wait_transition(max_seconds: float = 10.0) -> bool:
	return await until(func() -> bool: return not WorldManager.is_transitioning(), max_seconds)


## Pose le joueur au sol en (x, z) de la carte, visée aim, et attend qu'il touche le sol.
func put_player(x: float, z: float, aim: Vector3) -> void:
	player.global_position = Vector3(x, _ground().height_at(x, z) + 0.1, z)
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	player.set_aim_direction(aim, true)
	await frames(3)
	await until(func() -> bool: return player.is_on_floor(), 2.0)
	await frames(1)


func _enter_entrepot() -> void:
	assert_true(await new_game_from_menu(), "partie lancée depuis le menu")
	await WorldManager.go_to(ENTREPOT)
	assert_true(await wait_transition(), "arrivée")
	assert_eq(WorldManager.current_map(), ENTREPOT)


## Va d'une carte à une autre en marchant dans la direction de la sortie, depuis le marqueur de
## retour
## de la carte courante (ou une place donnée), et vérifie l'arrivée sur le marqueur de la carte
## cible.
func _walk_out(
	from_marker: StringName, key_code: Key, target: StringName, arrival: StringName
) -> void:
	var marker := _map().marker(from_marker)
	await put_player(marker.global_position.x, marker.global_position.z, -marker.global_basis.z)
	assert_true(
		await walk_keys_until(
			[key_code], func() -> bool: return WorldManager.current_map() == target, 8.0
		),
		"%s → %s" % [from_marker, target]
	)
	release_all_input()
	assert_true(await wait_transition(), "arrivée sur %s" % target)
	assert_lt(distance_to(_map().marker(arrival)), 0.3, "posé sur %s" % arrival)


func test_from_the_warehouse_to_the_path_the_marsh_the_port_and_back() -> void:
	await _enter_entrepot()
	# L'entrepôt, la sortie à pied vers le sentier.
	await _walk_out(&"from_sentier", KEY_D, SENTIER, &"from_entrepot")
	assert_eq(WorldManager.current_map(), SENTIER, "au sentier")
	assert_eq(player.camera_rig.limits, _map().bounds(), "caméra bornée à la carte")
	assert_eq(WorldManager.map_display_name(SENTIER), "Le sentier et le marais")
	# Le long de la levée, vers l'est, jusqu'en face du marais.
	assert_true(
		await walk_keys_until(
			[KEY_D], func() -> bool: return player.global_position.x > 33.0, 14.0
		),
		"le long du sentier, vers l'est"
	)
	release_all_input()
	# Dans le marais : on descend par la rampe de la levée (x 33 → 36, z 18 → 20), l'eau basse se
	# marche.
	await put_player(34.5, 22.5, Vector3.FORWARD)
	assert_true(
		await walk_keys_until([KEY_W], func() -> bool: return player.global_position.z < 16.0, 8.0),
		"descendu dans le marais"
	)
	release_all_input()
	await until(func() -> bool: return player.is_on_floor(), 2.0)
	assert_almost_eq(player.global_position.y, -0.5, 0.08, "le marais est 0,5 m plus bas")
	assert_eq(WorldManager.current_map(), SENTIER, "toujours au sentier")
	# La nuit, la lumière des fées éclaire le joueur : le sentier sans lumière reste lisible.
	Atmosphere.set_moment(&"nuit", 0.0)
	await frames(4)
	assert_true(Atmosphere.is_player_light_on(), "la nuit, la lumière magique du joueur")
	assert_gt(Atmosphere.player_light_amount(), 0.0, "elle éclaire")
	Atmosphere.set_moment(&"couchant", 0.0)
	# De retour sur la levée, le chemin de la ville : la rampe descend, l'écriteau se lit.
	await put_player(66.0, 24.5, Vector3.BACK)
	assert_true(
		await walk_keys_until([KEY_S], func() -> bool: return player.global_position.z > 32.0, 8.0),
		"par la rampe du chemin de la ville"
	)
	release_all_input()
	await until(func() -> bool: return player.is_on_floor(), 2.0)
	assert_almost_eq(player.global_position.y, -0.5, 0.08, "le creux du chemin de la ville")
	if not Map.exists(&"ville_haute"):
		await put_player(66.8, 38.4, Vector3.FORWARD)
		assert_true(
			await until(func() -> bool: return player.current_prompt() != "", 3.0),
			"l'écriteau au bout du chemin de la ville s'offre à la lecture"
		)
	# À l'est : la sortie à pied mène au port d'attente, et l'on en revient sur from_port.
	await put_player(72.0, 21.8, Vector3.RIGHT)
	assert_true(
		await walk_keys_until(
			[KEY_D], func() -> bool: return WorldManager.current_map() == PORT, 8.0
		),
		"vers le port"
	)
	release_all_input()
	assert_true(await wait_transition(), "arrivée au port")
	assert_lt(distance_to(_map().marker(&"from_sentier")), 0.3, "posé sur from_sentier du port")
	assert_eq(WorldManager.map_display_name(PORT), "Le port")
	assert_true(
		await walk_keys_until(
			[KEY_A], func() -> bool: return WorldManager.current_map() == SENTIER, 8.0
		),
		"retour au sentier"
	)
	release_all_input()
	assert_true(await wait_transition(), "retour du port")
	assert_lt(distance_to(_map().marker(&"from_port")), 0.3, "posé sur from_port")
	# Et jusqu'à l'entrepôt, par la sortie ouest, sur from_sentier.
	await _walk_out(&"from_entrepot", KEY_A, ENTREPOT, &"from_sentier")
	assert_eq(WorldManager.current_map(), ENTREPOT, "de retour à l'entrepôt")
