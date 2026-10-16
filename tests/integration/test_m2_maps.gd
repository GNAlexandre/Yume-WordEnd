extends "res://tests/stubs/m2_game_test.gd"
## (E1) Cartes dans la vraie partie (docs/REFONTE.md, section 7.1) : nouvelle partie sur la carte
## d'essai, sortie à pied du sentier ouest vers le rez-de-chaussée d'essai (fondu, ancienne carte
## libérée, joueur sur son marqueur et tourné comme lui, caméra bornée, nom annoncé), retour par la
## porte d'entrée ; sortie à invite (E) vers le pré ; fondu qui cache l'échange ; pas
## d'aller-retour en arrivant sur une sortie ; sauvegarde et reprise ; (F1) vraie sauvegarde
## d'avant la refonte reprise à l'acte 1 (l'ancienne île est partie) ; réapparition et rattrapage ;
## une seule carte en mémoire.

const ESSAI := &"essai"
const RDC := &"entrepot_rdc_essai"
const RELIEF := &"essai_relief"
## Sauvegarde du jeu d'avant la refonte (commit 50ec961), rue du port de l'ancienne île.
const V2_REAL_SAVE := "res://tests/data/saves/save_v2_avant_refonte.json"

var _previous_fade: float


func before_each() -> void:
	super()
	_previous_fade = WorldManager.fade_time


func after_each() -> void:
	WorldManager.fade_time = _previous_fade
	super()


## Attend la fin du changement de carte en cours (fondus et images d'arrivée compris).
func wait_transition(max_seconds: float = 10.0) -> bool:
	return await until(func() -> bool: return not WorldManager.is_transitioning(), max_seconds)


## Pose le joueur au sol sur un point global, visée `aim`, caméra recalée ; attend qu'il
## touche le sol (GameState.position n'est tenue qu'au sol).
func put_player(at: Vector3, aim: Vector3) -> void:
	player.global_position = WorldManager.ground_position(at, player)
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	player.set_aim_direction(aim, true)
	await frames(3)
	await until(func() -> bool: return player.is_on_floor(), 2.0)
	await frames(1)


func test_west_path_to_the_interior_and_front_door_back() -> void:
	assert_true(await new_game_from_menu(), "partie lancée depuis le menu")
	assert_eq(WorldManager.current_map(), ESSAI, "nouvelle partie : la carte d'essai")
	var essai_ref: WeakRef = weakref(current_map())
	watch_signals(EventBus)
	# Le sentier ouest : on passe en marchant.
	assert_true(
		await walk_keys_until([KEY_A], func() -> bool: return WorldManager.is_transitioning(), 8.0),
		"sortie à pied vers le rez-de-chaussée"
	)
	assert_eq(player.process_mode, Node.PROCESS_MODE_DISABLED, "joueur figé pendant le fondu")
	assert_true(
		await until(func() -> bool: return WorldManager.current_map() == RDC, 10.0),
		"rez-de-chaussée d'essai posé"
	)
	release_all_input()
	assert_null(essai_ref.get_ref(), "ancienne carte libérée")
	assert_eq(game.get_node(^"World").get_child_count(), 1, "une seule carte")
	var rdc := current_map()
	assert_lt(distance_to(rdc.marker(&"from_essai")), 0.05, "posé sur from_essai")
	assert_almost_eq(player.aim_direction(), Vector3.FORWARD, Vector3.ONE * 0.01, "tourné au nord")
	assert_signal_emitted_with_parameters(EventBus, "map_entered", [RDC])
	assert_eq(GameState.map, RDC)
	assert_eq(player.camera_rig.limits, rdc.bounds(), "caméra bornée à la carte")
	assert_true(await wait_transition(), "fondu de retour")
	assert_ne(player.process_mode, Node.PROCESS_MODE_DISABLED, "joueur rendu")
	assert_eq(get_viewport().get_camera_3d(), player.camera_rig.camera, "caméra du joueur")
	var fade := game.get_node(^"UI/MapFade")
	assert_eq(map_banner(), rdc.display_name, "nom de la carte annoncé")
	assert_eq(fade.call(&"black_alpha"), 0.0, "plus de noir")
	# La porte d'entrée, au sud : retour sur la carte d'essai.
	assert_true(
		await walk_keys_until(
			[KEY_S], func() -> bool: return WorldManager.current_map() == ESSAI, 8.0
		),
		"sortie à pied par la porte d'entrée"
	)
	release_all_input()
	assert_true(await wait_transition(), "arrivée")
	var back := current_map()
	assert_lt(distance_to(back.marker(&"from_entrepot_rdc_essai")), 0.05, "sur le sentier ouest")
	assert_almost_eq(player.aim_direction(), Vector3.RIGHT, Vector3.ONE * 0.01, "tourné à l'est")
	assert_eq(map_banner(), "Clairière d'essai", "nom de la carte annoncé de nouveau")
	assert_eq(player.camera_rig.limits, back.bounds(), "bornes de la carte d'essai")


func test_prompt_exit_with_the_interact_key() -> void:
	await start_game()
	WorldManager.fade_time = 0.0
	await WorldManager.go_to(RDC)
	await wait_transition()
	var exit := current_map().get_node(^"Exits/vers_essai_relief") as MapExit
	# Devant la porte du pré, tournée vers elle (au nord).
	await put_player(exit.global_position + Vector3(0.0, 0.0, 1.2), Vector3.FORWARD)
	assert_true(
		await until(func() -> bool: return player.current_prompt() == exit.prompt, 3.0),
		"invite « %s »" % exit.prompt
	)
	await tap_key(KEY_E)
	assert_true(
		await until(func() -> bool: return WorldManager.current_map() == RELIEF, 10.0), "E : le pré"
	)
	assert_true(await wait_transition())
	assert_lt(distance_to(current_map().marker(&"from_entrepot_rdc_essai")), 0.05)


func test_fade_hides_the_swap() -> void:
	await start_game()
	WorldManager.fade_time = 0.25
	var at_swap: Array[float] = []
	var hidden_at_swap: Array[bool] = []
	listen(
		EventBus.map_entered,
		func(_map_id: StringName) -> void:
			at_swap.append(WorldManager.fade_alpha())
			hidden_at_swap.append(get_tree().root.disable_3d)
	)
	var seen: Array[float] = []
	var fade := game.get_node(^"UI/MapFade")
	WorldManager.go_to(RDC)
	while WorldManager.is_transitioning():
		await get_tree().process_frame
		seen.append(fade.call(&"black_alpha"))
	assert_eq(at_swap, [1.0] as Array[float], "carte changée sous le noir complet")
	assert_eq(hidden_at_swap, [true] as Array[bool], "monde 3D non dessiné sous le noir")
	assert_false(get_tree().root.disable_3d, "monde 3D de nouveau dessiné")
	assert_true(seen.any(func(a: float) -> bool: return a > 0.05 and a < 0.95), "fondu progressif")
	assert_eq(seen.max(), 1.0, "noir complet")
	assert_eq(fade.call(&"black_alpha"), 0.0, "écran rendu")
	var stats := WorldManager.last_transition()
	assert_eq(stats["map"], RDC)
	assert_gt(stats["load_frames"], 0, "chargement mesuré")
	gut.p("Rez-de-chaussée d'essai : %s" % stats)


func test_arriving_on_an_exit_does_not_leave_at_once() -> void:
	await start_game()
	WorldManager.fade_time = 0.0
	var exit := current_map().get_node(^"Exits/vers_entrepot_rdc_essai") as MapExit
	# Posé dans la sortie du sentier, comme une arrivée qui tomberait dessus.
	WorldManager.enter_map(ESSAI, &"Spawn", exit.global_position + Vector3.DOWN * 1.4)
	await frames(30)
	assert_eq(WorldManager.current_map(), ESSAI, "pas d'aller-retour immédiat")
	assert_false(WorldManager.is_transitioning())
	hold_toward(Vector3.RIGHT)
	await wait_seconds(0.8)
	release_move()
	await frames(3)
	assert_eq(WorldManager.current_map(), ESSAI, "sorti de la sortie, toujours là")
	hold_toward(Vector3.LEFT)
	var left: bool = await until(func() -> bool: return WorldManager.current_map() == RDC, 5.0)
	release_move()
	assert_true(left, "y revenir fait partir")
	await wait_transition()


func test_nothing_starts_during_a_transition() -> void:
	await start_game()
	WorldManager.fade_time = 0.2
	var exit := current_map().get_node(^"Exits/vers_entrepot_rdc_essai") as MapExit
	WorldManager.go_to(RDC)
	assert_false(exit.use(), "une sortie ne part pas pendant le fondu")
	WorldManager.go_to(ESSAI)
	assert_push_warning("en cours")
	assert_true(await wait_transition())
	assert_eq(WorldManager.current_map(), RDC, "le second voyage a été ignoré")


func test_save_and_resume_on_the_map() -> void:
	await start_game()
	WorldManager.fade_time = 0.0
	await put_player(current_map().to_global(Vector3(27.0, 0.2, 21.0)), Vector3.FORWARD)
	var saved_at := player.global_position
	assert_eq(SaveManager.save(), OK)
	SaveManager.close_game(false)
	game.free()
	GameState.reset()
	assert_eq(SaveManager.load_game(), OK)
	assert_eq(GameState.map, ESSAI)
	game = GAME_SCENE.instantiate() as Node3D
	add_child(game)
	player = game.get_node(^"Player") as Player
	await frames(5)
	assert_eq(WorldManager.current_map(), ESSAI, "reprise dans la carte d'essai")
	assert_lt(flat_distance(player.global_position, saved_at), 0.1, "à la même place")
	assert_eq(player.camera_rig.limits, current_map().bounds(), "caméra bornée")


func test_real_v2_save_restarts_the_first_act() -> void:
	var file := FileAccess.open(SaveManager.save_path, FileAccess.WRITE)
	file.store_string(FileAccess.get_file_as_string(V2_REAL_SAVE))
	file.close()
	assert_eq(SaveManager.load_game(), OK, "(F1) une partie de l'ancienne île se charge")
	assert_true(SaveManager.started_new, "nouvelle partie")
	assert_false(SaveManager.notice.is_empty(), "le joueur est prévenu")
	assert_true(FileAccess.file_exists(SaveManager.legacy_backup_path()), "l'ancienne gardée")
	assert_eq(GameState.map, &"", "plus de carte héritée")
	assert_eq(GameState.count(&"page_fragment"), 0, "rien de l'ancienne île")
	game = GAME_SCENE.instantiate() as Node3D
	add_child(game)
	player = game.get_node(^"Player") as Player
	await frames(5)
	assert_eq(WorldManager.current_map(), start_map_for_test(), "carte de départ")
	assert_lt(distance_to(current_map().spawn()), 0.1, "à son Spawn")


func test_respawn_and_rescue_on_a_map() -> void:
	await start_game()
	WorldManager.fade_time = 0.0
	var arrival := current_map().marker(&"Spawn")
	await put_player(current_map().to_global(Vector3(30.0, 0.2, 22.0)), Vector3.LEFT)
	var stood_at := player.global_position
	watch_signals(WorldManager)
	WorldManager.respawn()
	assert_lt(distance_to(arrival), 0.05, "réapparition au marqueur d'arrivée")
	player.global_position = Vector3(20.0, WorldManager.FALL_LIMIT - 5.0, 15.0)
	await frames(3)
	assert_signal_emitted_with_parameters(WorldManager, "rescued", [ESSAI])
	# (X1) Règle void_fall de l'île n° 68 (data/world/worlds/regule_aire.json) : le dernier point
	# sûr, là où le joueur se tenait avant la réapparition (aucune image entre les deux).
	assert_lt(
		flat_distance(player.global_position, stood_at), 0.2, "rattrapée au dernier point sûr"
	)


func test_only_one_map_in_memory() -> void:
	await start_game()
	WorldManager.fade_time = 0.0
	var counts: Array[int] = []
	# (F1) Aller-retour entre deux cartes du dehors (avant : l'ancienne île et la carte d'essai).
	for _round in 2:
		await WorldManager.go_to(RELIEF)
		await wait_transition()
		await frames(3)
		assert_false(ResourceLoader.has_cached(Map.scene_path(ESSAI)), "essai libérée")
		counts.append(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		await WorldManager.go_to(ESSAI)
		await wait_transition()
		await frames(3)
		assert_false(ResourceLoader.has_cached(Map.scene_path(RELIEF)), "relief libéré")
		assert_eq(game.get_node(^"World").get_child_count(), 1)
	assert_eq(counts[1], counts[0], "autant de nœuds à chaque visite : rien ne s'accumule")
