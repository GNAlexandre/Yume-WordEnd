extends "res://tests/stubs/m2_game_test.gd"
## (E1) Cartes dans la vraie partie (docs/REFONTE.md, section 7.1) : nouvelle partie dans la
## carte héritée, sortie à invite du bout du quai (E), fondu, carte d'essai (ancienne carte
## libérée, joueur sur son marqueur et tourné comme lui, caméra bornée), sortie à pied du
## sentier ouest, retour sur le quai ; fondu qui cache l'échange ; pas d'aller-retour en
## arrivant sur une sortie ; sauvegarde et reprise dans la carte d'essai ; vraie sauvegarde
## d'avant la refonte reprise à la même place ; réapparition et rattrapage sur une carte sans
## village ; une seule carte en mémoire.

const ESSAI := &"essai"
const LEGACY := &"ile_ancienne"
## Sauvegarde du jeu d'avant la refonte (commit 50ec961), rue du port.
const V2_REAL_SAVE := "res://tests/data/saves/save_v2_avant_refonte.json"

var _previous_fade: float


func before_each() -> void:
	super()
	_previous_fade = WorldManager.fade_time


func after_each() -> void:
	WorldManager.fade_time = _previous_fade
	super()


## Carte courante (Map) de la partie.
func current_map() -> Map:
	return WorldManager.current_map_node()


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


func test_quay_exit_to_essai_and_west_path_back() -> void:
	assert_true(await new_game_from_menu(), "partie lancée depuis le menu")
	assert_eq(WorldManager.current_map(), LEGACY, "nouvelle partie : l'ancienne île")
	var island := current_map()
	var island_ref: WeakRef = weakref(island)
	var exit := island.get_node(^"Exits/to_essai") as MapExit
	# Devant le panneau du bout du quai, tourné vers lui (au nord).
	await put_player(exit.global_position + Vector3(0.0, -1.3, 1.9), Vector3.FORWARD)
	assert_true(
		await until(func() -> bool: return player.current_prompt() == exit.prompt, 3.0),
		"invite « %s » au bout du quai" % exit.prompt
	)
	watch_signals(EventBus)
	await tap_key(KEY_E)
	assert_true(WorldManager.is_transitioning(), "E : le changement commence")
	assert_eq(player.process_mode, Node.PROCESS_MODE_DISABLED, "joueur figé pendant le fondu")
	assert_true(
		await until(func() -> bool: return WorldManager.current_map() == ESSAI, 10.0),
		"carte d'essai posée"
	)
	assert_null(island_ref.get_ref(), "ancienne carte libérée")
	assert_eq(game.get_node(^"World").get_child_count(), 1, "une seule carte")
	var essai := current_map()
	var arrival := essai.marker(&"from_ile_ancienne")
	assert_lt(distance_to(arrival), 0.05, "posé sur from_ile_ancienne")
	assert_almost_eq(player.aim_direction(), Vector3.RIGHT, Vector3.ONE * 0.01, "tourné à l'est")
	assert_signal_emitted_with_parameters(EventBus, "map_entered", [ESSAI])
	assert_eq(GameState.map, ESSAI)
	assert_eq(player.camera_rig.limits, essai.bounds(), "caméra bornée à la carte")
	assert_true(await wait_transition(), "fondu de retour")
	assert_ne(player.process_mode, Node.PROCESS_MODE_DISABLED, "joueur rendu")
	assert_eq(get_viewport().get_camera_3d(), player.camera_rig.camera, "caméra du joueur")
	var fade := game.get_node(^"UI/MapFade")
	assert_eq(fade.call(&"title_text"), "Clairière d'essai", "nom de la carte annoncé")
	assert_eq(fade.call(&"black_alpha"), 0.0, "plus de noir")
	# Le sentier ouest : on passe en marchant.
	assert_true(
		await walk_keys_until(
			[KEY_A], func() -> bool: return WorldManager.current_map() == LEGACY, 8.0
		),
		"sortie à pied vers l'ancienne île"
	)
	assert_true(await wait_transition(), "arrivée")
	var back := current_map()
	assert_lt(distance_to(back.marker(&"from_essai")), 0.05, "sur le quai, à from_essai")
	assert_true(
		await until(func() -> bool: return GameState.zone == &"beach", 3.0),
		"zone du port annoncée de nouveau"
	)
	assert_eq(zone_banner(), "Le port et le bourg")
	assert_eq(player.camera_rig.limits, WorldManager.DEFAULT_CAMERA_BOUNDS, "bornes de l'île")


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
	WorldManager.go_to(ESSAI)
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
	assert_eq(stats["map"], ESSAI)
	assert_gt(stats["load_frames"], 0, "chargement mesuré")
	gut.p("Carte d'essai : %s" % stats)


func test_arriving_on_an_exit_does_not_leave_at_once() -> void:
	await start_game()
	WorldManager.fade_time = 0.0
	await WorldManager.go_to(ESSAI)
	var exit := current_map().get_node(^"Exits/to_ile_ancienne") as MapExit
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
	var left: bool = await until(func() -> bool: return WorldManager.current_map() == LEGACY, 5.0)
	release_move()
	assert_true(left, "y revenir fait partir")
	await wait_transition()


func test_nothing_starts_during_a_transition() -> void:
	await start_game()
	WorldManager.fade_time = 0.2
	var exit := current_map().get_node(^"Exits/to_essai") as MapExit
	WorldManager.go_to(ESSAI)
	assert_false(exit.use(), "une sortie ne part pas pendant le fondu")
	WorldManager.go_to(LEGACY)
	assert_push_warning("en cours")
	assert_true(await wait_transition())
	assert_eq(WorldManager.current_map(), ESSAI, "le second voyage a été ignoré")


func test_save_in_essai_and_resume_there() -> void:
	await start_game()
	WorldManager.fade_time = 0.0
	await WorldManager.go_to(ESSAI)
	await wait_transition()
	await put_player(Vector3(27.0, 0.2, 21.0), Vector3.FORWARD)
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


func test_real_v2_save_resumes_on_the_island() -> void:
	var file := FileAccess.open(SaveManager.save_path, FileAccess.WRITE)
	file.store_string(FileAccess.get_file_as_string(V2_REAL_SAVE))
	file.close()
	assert_eq(SaveManager.load_game(), OK)
	game = GAME_SCENE.instantiate() as Node3D
	add_child(game)
	player = game.get_node(^"Player") as Player
	await frames(5)
	assert_eq(WorldManager.current_map(), LEGACY, "carte héritée")
	assert_lt(flat_distance(player.global_position, Vector3(12.0, 0.0, 57.0)), 0.1, "même place")
	assert_true(await until(func() -> bool: return GameState.zone == &"beach", 3.0), "dans le port")
	assert_eq(GameState.quest_step(&"act1_main"), &"to_the_woods", "quête au même point")
	assert_eq(GameState.count(&"page_fragment"), 2)
	assert_eq(GameState.best_score(&"dunes"), 420)


func test_respawn_and_rescue_on_a_map_without_village() -> void:
	await start_game()
	WorldManager.fade_time = 0.0
	await WorldManager.go_to(ESSAI)
	await wait_transition()
	var arrival := current_map().marker(&"Spawn")
	await put_player(Vector3(30.0, 0.2, 22.0), Vector3.LEFT)
	watch_signals(WorldManager)
	WorldManager.respawn()
	assert_lt(distance_to(arrival), 0.05, "réapparition au marqueur d'arrivée")
	player.global_position = Vector3(20.0, WorldManager.FALL_LIMIT - 5.0, 15.0)
	await frames(3)
	assert_signal_emitted_with_parameters(WorldManager, "rescued", [ESSAI])
	assert_lt(distance_to(arrival), 0.05, "rattrapée au marqueur d'arrivée")


func test_only_one_map_in_memory() -> void:
	await start_game()
	WorldManager.fade_time = 0.0
	var counts: Array[int] = []
	for _round in 2:
		await WorldManager.go_to(ESSAI)
		await wait_transition()
		await frames(3)
		assert_false(ResourceLoader.has_cached(Map.scene_path(LEGACY)), "île libérée")
		counts.append(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		await WorldManager.go_to(LEGACY)
		await wait_transition()
		await frames(3)
		assert_false(ResourceLoader.has_cached(Map.scene_path(ESSAI)), "essai libérée")
		assert_eq(game.get_node(^"World").get_child_count(), 1)
	assert_eq(counts[1], counts[0], "autant de nœuds à chaque visite : rien ne s'accumule")
