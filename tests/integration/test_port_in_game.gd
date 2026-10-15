extends "res://tests/stubs/m2_game_test.gd"
## (CP) Le port dans la vraie partie (main.tscn, appuis réels) : du sentier au port par la sortie
## à
## pied (on arrive sur from_sentier, la caméra est bornée à la carte), le long de la rue du port ;
## la
## nuit, la lumière d'Atmosphere éclaire le quai sans lampe de la carte ; le panneau aux flèches
## rouges
## s'examine (texte de data/texts/port.json, sans nom) ; la colline ventée se monte à pied, de
## rampe en
## rampe, jusqu'au sommet (+3 m) ; la route de la ville est fermée d'un écriteau tant que la place
## du
## marché n'existe pas ; enfin le retour au sentier par la sortie ouest, sur from_port.

const SENTIER := &"sentier"
const PORT := &"port"

var _previous_fade: float
var _lines: Array[String] = []


func before_each() -> void:
	super()
	_previous_fade = WorldManager.fade_time
	WorldManager.fade_time = 0.0
	_lines.clear()
	EventBus.dialogue_line.connect(_on_line)


func after_each() -> void:
	EventBus.dialogue_line.disconnect(_on_line)
	WorldManager.fade_time = _previous_fade
	Atmosphere.player_light_mode = Atmosphere.LIGHT_AUTO
	GameState.reset()
	super()


func _on_line(speaker: String, text: String, _choices: Array[String]) -> void:
	_lines.append("%s|%s" % [speaker, text])


func _map() -> Map:
	return WorldManager.current_map_node()


func _ground() -> MapGround:
	return _map().get_node(^"Ground") as MapGround


func wait_transition(max_seconds: float = 10.0) -> bool:
	return await until(func() -> bool: return not WorldManager.is_transitioning(), max_seconds)


## Pose le joueur au sol en (x, z) de la carte, visée aim, et attend qu'il touche le sol.
func put_player(x: float, z: float, aim: Vector3) -> void:
	var height := _ground().height_at(x, z)
	player.global_position = _map().to_global(Vector3(x, height + 0.1, z))
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	player.set_aim_direction(aim, true)
	await frames(3)
	await until(func() -> bool: return player.is_on_floor(), 2.0)
	await frames(1)


func _local_y() -> float:
	return _map().to_local(player.global_position).y


func test_from_the_path_to_the_port_the_sign_the_hill_and_back() -> void:
	assert_true(await new_game_from_menu(), "partie lancée depuis le menu")
	await WorldManager.go_to(SENTIER)
	assert_true(await wait_transition(), "au sentier")
	# Du sentier, la sortie est mène au port : on y arrive sur from_sentier, au bout ouest de la
	# rue.
	await put_player(72.0, 21.8, Vector3.RIGHT)
	assert_true(
		await walk_keys_until(
			[KEY_D], func() -> bool: return WorldManager.current_map() == PORT, 8.0
		),
		"du sentier au port, à pied"
	)
	release_all_input()
	assert_true(await wait_transition(), "arrivée au port")
	assert_eq(WorldManager.map_display_name(PORT), "Le port")
	assert_lt(distance_to(_map().marker(&"from_sentier")), 0.3, "posé sur from_sentier")
	assert_eq(player.camera_rig.limits, _map().bounds(), "caméra bornée au port")
	assert_eq(_map().bounds(), Rect2(10, 6, 50, 24), "les bornes de caméra du plan (CP)")
	# Le long de la rue du port, vers l'est, jusqu'en face du poste d'amarrage.
	assert_true(
		await walk_keys_until(
			[KEY_D], func() -> bool: return player.global_position.x > 26.0, 20.0
		),
		"le long de la rue du port"
	)
	release_all_input()
	# La nuit, la lumière magique du joueur éclaire le quai (aucune lampe n'est dans la carte).
	Atmosphere.set_moment(&"nuit", 0.0)
	await frames(4)
	assert_true(Atmosphere.is_player_light_on(), "la nuit, la lumière magique du joueur")
	assert_null(_map().get_node_or_null(^"Lights"), "aucune lampe dans la carte")
	Atmosphere.set_moment(&"apres_midi", 0.0)
	# Au pied de la passerelle, au poste d'amarrage : le point que la scène du débarquement vise.
	var foot := _map().get_node(^"Life/Places/navire_quai") as Marker3D
	await put_player(foot.global_position.x, foot.global_position.z, Vector3.FORWARD)
	assert_lt(distance_to(foot), 0.5, "au pied de la passerelle")
	# Le panneau aux flèches rouges : on l'examine (« Examiner », touche E).
	await put_player(6.0, 19.8, Vector3.FORWARD)
	assert_true(
		await until(func() -> bool: return player.current_prompt() == "Examiner", 3.0),
		"le panneau s'offre à l'examen"
	)
	await tap_key(KEY_E)
	assert_true(await until(func() -> bool: return not _lines.is_empty(), 3.0), "texte lu")
	assert_true(_lines[0].begins_with("|"), "sans nom de personnage")
	assert_string_contains(_lines[0], "marmer")
	for _page in 4:
		if not DialogueRunner.is_any_running():
			break
		await tap_key(KEY_E)
		await frames(3)
	assert_false(DialogueRunner.is_any_running(), "la lecture est finie")
	# La colline ventée : on la monte à pied, de rampe en rampe, jusqu'au sommet.
	await put_player(61.0, 28.6, Vector3.FORWARD)
	assert_true(
		await walk_keys_until([KEY_W], func() -> bool: return player.global_position.z < 24.2, 8.0),
		"par la première rampe, vers le nord"
	)
	release_all_input()
	await until(func() -> bool: return player.is_on_floor(), 2.0)
	assert_almost_eq(_local_y(), 1.0, 0.15, "première terrasse, +1 m")
	await put_player(66.0, 25.8, Vector3.FORWARD)
	assert_true(
		await walk_keys_until([KEY_W], func() -> bool: return player.global_position.z < 21.5, 8.0),
		"par la deuxième rampe, vers le nord"
	)
	release_all_input()
	await until(func() -> bool: return player.is_on_floor(), 2.0)
	assert_almost_eq(_local_y(), 2.0, 0.15, "deuxième terrasse, +2 m")
	await put_player(67.0, 20.2, Vector3.FORWARD)
	assert_true(
		await walk_keys_until([KEY_W], func() -> bool: return player.global_position.z < 15.5, 8.0),
		"par la troisième rampe, vers le nord"
	)
	release_all_input()
	await until(func() -> bool: return player.is_on_floor(), 2.0)
	assert_almost_eq(_local_y(), 3.0, 0.15, "le sommet, +3 m")
	# La route de la ville : fermée d'un écriteau tant que la place du marché n'existe pas.
	if not Map.exists(&"ville_marche"):
		await put_player(66.4, 33.0, Vector3.BACK)
		assert_true(
			await until(func() -> bool: return player.current_prompt() != "", 3.0),
			"l'écriteau au bout de la route de la ville s'offre à la lecture"
		)
	# Enfin, le retour au sentier par la sortie ouest, sur from_port.
	var back := _map().marker(&"from_sentier")
	await put_player(back.global_position.x, back.global_position.z, -back.global_basis.z)
	assert_true(
		await walk_keys_until(
			[KEY_A], func() -> bool: return WorldManager.current_map() == SENTIER, 8.0
		),
		"du port au sentier, à pied"
	)
	release_all_input()
	assert_true(await wait_transition(), "retour au sentier")
	assert_lt(distance_to(_map().marker(&"from_port")), 0.3, "posé sur from_port")
