extends "res://tests/stubs/m2_game_test.gd"
## (C2) Le village dans la vraie partie (main.tscn, appuis réels) : de l'entrepôt au village par la
## sortie
## à pied (on arrive sur from_entrepot, la caméra est bornée à la carte), le long de la rue jusqu'à
## la
## porte du café (« Entrer », touche E), dans le café, que l'on quitte à pied par sa porte (on
## revient
## sur from_cafe) ; la porte de la maison Limashenka (« Entrer »), la maison, d'où l'on sort à pied
## sur
## from_maison_limashenka ; la nuit, la lumière d'Atmosphere éclaire la rue sans lampe de la carte ;
## enfin
## le retour à l'entrepôt par la sortie est, sur from_village.

const ENTREPOT := &"entrepot"
const VILLAGE := &"village"
const CAFE := &"cafe"
const MAISON := &"maison_limashenka"

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
	return _map().get_node_or_null(^"Ground") as MapGround


func wait_transition(max_seconds: float = 10.0) -> bool:
	return await until(func() -> bool: return not WorldManager.is_transitioning(), max_seconds)


func _arrived(map_id: StringName) -> bool:
	return WorldManager.current_map() == map_id and not WorldManager.is_transitioning()


## Pose le joueur au sol en (x, z) de la carte, visée aim, et attend qu'il touche le sol.
func put_player(x: float, z: float, aim: Vector3) -> void:
	var ground := _ground()
	var height := ground.height_at(x, z) if ground != null else 0.0
	player.global_position = _map().to_global(Vector3(x, height + 0.1, z))
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	player.set_aim_direction(aim, true)
	await frames(3)
	await until(func() -> bool: return player.is_on_floor(), 2.0)
	await frames(1)


## Marche (touches tenues) jusqu'à l'invite de la sortie exit_name, puis appuie sur E et attend
## l'arrivée
## dans target.
func _take_exit(keys: Array[Key], exit_name: String, target: StringName) -> bool:
	var exit := _map().get_node(NodePath("Exits/" + exit_name)) as MapExit
	var shown := await walk_keys_until(
		keys, func() -> bool: return player.current_interactable() == exit, 6.0
	)
	assert_true(shown, "invite de %s" % exit_name)
	if not shown:
		return false
	assert_eq(player.current_prompt(), exit.prompt, "%s : invite « %s »" % [exit_name, exit.prompt])
	release_all_input()
	await tap_key(KEY_E)
	var arrived: bool = await until(_arrived.bind(target), 10.0)
	assert_true(arrived, "%s : arrivée dans %s" % [exit_name, target])
	await frames(2)
	return arrived


## Sort à pied : marche dans la direction de la sortie jusqu'à la carte cible, arrive sur le
## marqueur.
func _walk_out(key_code: Key, target: StringName, arrival: StringName) -> bool:
	var left := await walk_keys_until(
		[key_code], func() -> bool: return WorldManager.current_map() == target, 8.0
	)
	release_all_input()
	assert_true(
		left,
		(
			"sortie à pied vers %s (le joueur est en %s sur %s)"
			% [target, player.global_position, WorldManager.current_map()]
		)
	)
	if not left:
		return false
	assert_true(await wait_transition(), "arrivée sur %s" % target)
	assert_lt(distance_to(_map().marker(arrival)), 0.3, "posé sur %s" % arrival)
	return true


func test_from_the_warehouse_to_the_cafe_the_house_and_back() -> void:
	assert_true(await new_game_from_menu(), "partie lancée depuis le menu")
	await WorldManager.go_to(ENTREPOT)
	assert_true(await wait_transition(), "à l'entrepôt")
	# L'entrepôt : la sortie ouest mène au village, qu'on aborde par l'est.
	var marker := _map().marker(&"from_village")
	var back := _map().to_local(marker.global_position)
	await put_player(back.x, back.z, -marker.global_basis.z)
	assert_true(await _walk_out(KEY_A, VILLAGE, &"from_entrepot"), "de l'entrepôt au village")
	assert_eq(WorldManager.map_display_name(VILLAGE), "Le village")
	assert_eq(player.camera_rig.limits, _map().bounds(), "caméra bornée au village")
	# Le long de la rue, vers l'ouest, jusqu'en face du café.
	assert_true(
		await walk_keys_until(
			[KEY_A], func() -> bool: return player.global_position.x < 22.0, 14.0
		),
		"le long de la rue jusqu'au café"
	)
	release_all_input()
	# La nuit, la lumière magique du joueur éclaire la rue (aucune lampe n'est dans la carte).
	Atmosphere.set_moment(&"nuit", 0.0)
	await frames(4)
	assert_true(Atmosphere.is_player_light_on(), "la nuit, la lumière magique du joueur")
	assert_null(_map().get_node_or_null(^"Lights"), "aucune lampe dans la carte")
	Atmosphere.set_moment(&"apres_midi", 0.0)
	# La porte du café : invite « Entrer », puis E.
	await put_player(19.8, 12.0, Vector3.FORWARD)
	assert_true(await _take_exit([KEY_W], "porte_cafe", CAFE), "dans le café")
	assert_true(_map().interior, "le café est un intérieur")
	assert_eq(WorldManager.map_display_name(CAFE), "Le café du village")
	assert_eq(player.camera_rig.limits, _map().bounds(), "caméra bornée au café")
	assert_lt(distance_to(_map().marker(&"from_village")), 0.3, "posé sur from_village")
	# Au café : l'ardoise du menu s'examine (texte de data/texts/village.json, sans nom).
	await put_player(6.8, 2.6, Vector3.FORWARD)
	assert_true(
		await until(func() -> bool: return player.current_prompt() == "Examiner", 3.0),
		"l'ardoise du menu s'offre à l'examen"
	)
	await tap_key(KEY_E)
	assert_true(await until(func() -> bool: return not _lines.is_empty(), 3.0), "texte lu")
	assert_true(_lines[0].begins_with("|"), "sans nom de personnage")
	assert_string_contains(_lines[0], "ardoise")
	for _page in 4:
		if not DialogueRunner.is_any_running():
			break
		await tap_key(KEY_E)
		await frames(3)
	assert_false(DialogueRunner.is_any_running(), "la lecture est finie")
	# La sortie à pied, par la porte du mur sud : on revient dans la rue, sur from_cafe.
	await put_player(4.75, 8.2, Vector3.BACK)
	assert_true(await _walk_out(KEY_S, VILLAGE, &"from_cafe"), "du café à la rue")
	# La maison Limashenka : porte à invite, vestibule, sortie à pied.
	await put_player(44.0, 11.4, Vector3.FORWARD)
	assert_true(await _take_exit([KEY_W], "porte_limashenka", MAISON), "dans la maison")
	assert_eq(WorldManager.map_display_name(MAISON), "La maison Limashenka")
	assert_lt(distance_to(_map().marker(&"from_village")), 0.3, "posé sur from_village")
	await put_player(2.25, 6.0, Vector3.BACK)
	assert_true(await _walk_out(KEY_S, VILLAGE, &"from_maison_limashenka"), "de la maison à la rue")
	# Enfin, le retour à l'entrepôt par la sortie est.
	var from_warehouse := _map().marker(&"from_entrepot")
	var at := _map().to_local(from_warehouse.global_position)
	await put_player(at.x, at.z, -from_warehouse.global_basis.z)
	assert_true(await _walk_out(KEY_D, ENTREPOT, &"from_village"), "du village à l'entrepôt")
