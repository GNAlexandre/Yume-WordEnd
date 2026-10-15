extends "res://tests/stubs/m2_game_test.gd"
## (CV) La ville haute et le snack-bar dans la vraie partie (main.tscn, appuis réels) : du sentier à
## la ville haute
## par le chemin de la ville (sortie à pied, arrivée sur from_sentier, caméra bornée à la carte), la
## rue haute, la
## grand-rue et ses volées d'escalier qu'on descend à pied, la porte du snack-bar (« Entrer »,
## touche E), le snack,
## que l'on quitte à pied par sa porte (retour sur from_ville_snack) ; la porte de la salle de
## projection, close
## avant le jour 5 (le texte « Pas sans un adulte. »), ouverte au jour 5 ; la place du marché
## d'attente, d'où l'on
## revient ; enfin le retour au sentier par la sortie ouest.

const SENTIER := &"sentier"
const VILLE := &"ville_haute"
const SNACK := &"ville_snack"
const MARCHE := &"ville_marche"
const PROJECTION := &"ville_projection"

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


func _read_all() -> void:
	for _page in 4:
		if DialogueRunner.is_any_running():
			await tap_key(KEY_E)
			await frames(3)


func test_from_the_path_to_the_upper_town_the_snack_and_back() -> void:
	assert_true(await new_game_from_menu(), "partie lancée depuis le menu")
	GameState.day = 1
	await WorldManager.go_to(SENTIER)
	assert_true(await wait_transition(), "au sentier")
	# Le chemin de la ville descend au sud-est : on y marche jusqu'au bout, sans écriteau.
	assert_not_null(
		_map().get_node_or_null(^"Exits/vers_ville"), "la sortie vers la ville est écrite"
	)
	assert_null(
		_map().get_node_or_null(^"Geometry/Fork/SignVille"),
		"plus d'écriteau « Plus loin, bientôt »"
	)
	await put_player(69.0, 34.0, Vector3.BACK)
	assert_true(await _walk_out(KEY_S, VILLE, &"from_sentier"), "du sentier à la ville haute")
	assert_eq(WorldManager.map_display_name(VILLE), "Le centre-ville")
	assert_eq(player.camera_rig.limits, _map().bounds(), "caméra bornée à la ville")
	assert_false(_map().interior)
	# La rue haute, vers l'est puis le haut de la grand-rue ; la lumière de la nuit est celle
	# d'Atmosphere.
	await put_player(10.0, 13.0, Vector3.RIGHT)
	assert_true(
		await walk_keys_until(
			[KEY_D], func() -> bool: return player.global_position.x > 28.0, 12.0
		),
		"le long de la rue haute jusqu'à la grand-rue"
	)
	release_all_input()
	Atmosphere.set_moment(&"nuit", 0.0)
	await frames(4)
	assert_true(Atmosphere.is_player_light_on(), "la nuit, la lumière magique du joueur")
	assert_null(_map().get_node_or_null(^"Lights"), "aucune lampe dans la carte")
	Atmosphere.set_moment(&"apres_midi", 0.0)
	# La grand-rue descend par deux volées d'escalier : on les descend à pied (de +2 m à +1 m, puis
	# à 0).
	await put_player(30.0, 14.0, Vector3.BACK)
	assert_true(
		await walk_keys_until(
			[KEY_S], func() -> bool: return player.global_position.z > 28.0, 10.0
		),
		"la volée du haut descendue à pied"
	)
	release_all_input()
	await until(func() -> bool: return player.is_on_floor(), 2.0)
	assert_almost_eq(player.global_position.y, 1.0, 0.1, "la rue du café, +1 m")
	# La porte du snack : invite « Entrer », puis E.
	await put_player(37.5, 32.6, Vector3.FORWARD)
	assert_true(await _take_exit([KEY_W], "porte_snack", SNACK), "dans le snack-bar")
	assert_true(_map().interior, "le snack est un intérieur")
	assert_eq(WorldManager.map_display_name(SNACK), "Le snack-bar")
	assert_eq(player.camera_rig.limits, _map().bounds(), "caméra bornée au snack")
	assert_lt(distance_to(_map().marker(&"from_ville_haute")), 0.3, "posé sur from_ville_haute")
	# Au comptoir : on examine la plaque et la poêle (texte de data/texts/ville.json, sans nom).
	await put_player(4.5, 4.4, Vector3.FORWARD)
	assert_true(
		await until(func() -> bool: return player.current_prompt() == "Examiner", 3.0),
		"le comptoir s'offre à l'examen"
	)
	_lines.clear()
	await tap_key(KEY_E)
	assert_true(await until(func() -> bool: return not _lines.is_empty(), 3.0), "texte lu")
	assert_true(_lines[0].begins_with("|"), "sans nom de personnage")
	assert_string_contains(_lines[0], "poêle")
	await _read_all()
	assert_false(DialogueRunner.is_any_running(), "la lecture est finie")
	# La sortie à pied, par la porte du mur sud : on revient dans la rue, sur from_ville_snack.
	await put_player(6.0, 5.2, Vector3.BACK)
	assert_true(await _walk_out(KEY_S, VILLE, &"from_ville_snack"), "du snack à la rue")


## La salle de projection : « Pas sans un adulte. » avant le jour 5, la porte s'ouvre ensuite.
func test_the_projection_door_stays_shut_before_day_five() -> void:
	assert_true(await new_game_from_menu(), "partie lancée depuis le menu")
	GameState.day = 4
	await WorldManager.go_to(VILLE, &"from_sentier")
	assert_true(await wait_transition(), "dans la ville haute")
	var closed := _map().get_node_or_null(^"Exits/porte_projection/ClosedDoor")
	assert_not_null(closed, "la porte de la salle de projection est close avant le jour 5")
	await put_player(19.5, 54.0, Vector3.FORWARD)
	assert_true(
		await walk_keys_until(
			[KEY_W], func() -> bool: return player.current_interactable() == closed, 6.0
		),
		"invite de la porte close"
	)
	release_all_input()
	_lines.clear()
	await tap_key(KEY_E)
	assert_true(await until(func() -> bool: return not _lines.is_empty(), 3.0), "texte lu")
	assert_string_contains(_lines[0], "Pas sans un adulte.")
	await _read_all()
	assert_eq(WorldManager.current_map(), VILLE, "la porte ne mène nulle part")
	# Au jour 5, la porte s'ouvre : invite « Entrer », la salle, et le retour à pied.
	GameState.day = 5
	await WorldManager.go_to(VILLE, &"from_sentier")
	assert_true(await wait_transition(), "de retour dans la ville haute")
	assert_null(
		_map().get_node_or_null(^"Exits/porte_projection/ClosedDoor"),
		"la porte est ouverte au jour 5"
	)
	await put_player(19.5, 54.0, Vector3.FORWARD)
	assert_true(
		await _take_exit([KEY_W], "porte_projection", PROJECTION), "dans la salle de projection"
	)
	await put_player(6.0, 8.2, Vector3.BACK)
	assert_true(await _walk_out(KEY_S, VILLE, &"from_ville_projection"), "de la salle à la rue")


## Au bas de la grand-rue, la place du marché d'attente, d'où l'on revient ; puis le sentier par la
## sortie ouest.
func test_the_market_waits_below_and_the_path_is_behind() -> void:
	assert_true(await new_game_from_menu(), "partie lancée depuis le menu")
	await WorldManager.go_to(VILLE, &"from_sentier")
	assert_true(await wait_transition(), "dans la ville haute")
	await put_player(30.0, 54.0, Vector3.BACK)
	assert_true(
		await _walk_out(KEY_S, MARCHE, &"from_ville_haute"),
		"de la ville haute à la place du marché"
	)
	assert_eq(WorldManager.map_display_name(MARCHE), "La place du marché")
	# Le retour : la sortie de la place, au nord, ramène sur from_ville_marche.
	var from_town := _map().marker(&"from_ville_haute")
	var at := _map().to_local(from_town.global_position)
	await put_player(at.x, at.z + 1.0, Vector3.FORWARD)
	assert_true(await _walk_out(KEY_W, VILLE, &"from_ville_marche"), "de la place à la ville haute")
	# Le sentier, à l'ouest de la rue haute.
	await put_player(6.0, 13.0, Vector3.LEFT)
	assert_true(
		await _walk_out(KEY_A, SENTIER, &"from_ville_haute"), "de la ville haute au sentier"
	)
