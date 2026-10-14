extends "res://tests/stubs/m2_game_test.gd"
## (X1) Le voyage entre îles dans la vraie partie (src/main.tscn, appuis réels) : du quai d'essai
## de l'île n° 68 (carte essai), E « Embarquer » ; fondu, vue du ciel qui défile (TravelView), le
## quai de l'île d'essai au marqueur du port ; island_entered, île courante et îles connues ;
## sauvegarde et reprise sur l'île d'essai ; retour par son quai. La surface : sol jusqu'à
## l'horizon, ciel de ses règles, Timeres permis ; de retour sur l'île n° 68, aucun Timere. Une
## chute ramène au dernier point sûr. L'ancienne île garde son arène.

const ESSAI := &"essai"
const QUAY := &"quai_essai"
const SURFACE_MAP := &"surface_essai"
const ILE_68 := &"ile_68"
const ILE_ESSAI := &"ile_essai"
const SURFACE := &"surface_essai"
const LEGACY_ISLAND := &"ile_ancienne"

var _previous_fade: float
var _previous_travel: float
var _islands: Array[StringName] = []


func before_each() -> void:
	super()
	_previous_fade = WorldManager.fade_time
	_previous_travel = WorldManager.travel_time
	_islands.clear()


func after_each() -> void:
	WorldManager.fade_time = _previous_fade
	WorldManager.travel_time = _previous_travel
	super()


func current_map() -> Map:
	return WorldManager.current_map_node()


func wait_transition(max_seconds: float = 15.0) -> bool:
	return await until(func() -> bool: return not WorldManager.is_transitioning(), max_seconds)


## Pose le joueur au sol sur un point global, visée `aim` ; attend qu'il touche le sol.
func put_player(at: Vector3, aim: Vector3) -> void:
	player.global_position = WorldManager.ground_position(at, player)
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	player.set_aim_direction(aim, true)
	await frames(3)
	await until(func() -> bool: return player.is_on_floor(), 2.0)
	await frames(1)


## Le joueur devant un quai (2 m de son côté `side`), tourné vers lui, jusqu'à son invite.
func face_dock(dock: AirshipDock, side: Vector3) -> bool:
	await put_player(dock.global_position + side * 2.0 + Vector3.DOWN * 0.8, -side)
	return await until(func() -> bool: return player.current_prompt() == dock.get_prompt(), 3.0)


func _on_island_entered(island_id: StringName) -> void:
	_islands.append(island_id)


func test_travel_to_the_test_island_and_back() -> void:
	assert_true(await new_game_from_menu(), "partie lancée depuis le menu")
	listen(EventBus.island_entered, _on_island_entered)
	assert_eq(GameState.island, LEGACY_ISLAND, "nouvelle partie : l'ancienne île")
	assert_eq(WorldManager.current_island(), LEGACY_ISLAND)
	WorldManager.fade_time = 0.1
	WorldManager.travel_time = 0.6
	await WorldManager.go_to(ESSAI)
	assert_true(await wait_transition())
	assert_eq(
		_islands, [ILE_68] as Array[StringName], "en passant à la carte d'essai : l'île n° 68"
	)
	assert_eq(GameState.island, ILE_68)
	var dock := current_map().get_node(^"Docks/vers_ile_essai") as AirshipDock
	assert_eq(dock.get_prompt(), "Embarquer pour L'île d'essai", "invite de data/texts/story.json")
	assert_true(await face_dock(dock, Vector3.LEFT), "invite du quai")
	watch_signals(WorldManager)
	await tap_key(KEY_E)
	assert_true(WorldManager.is_traveling(), "E : le voyage commence")
	assert_signal_emitted_with_parameters(WorldManager, "travel_started", [ILE_ESSAI])
	assert_eq(player.process_mode, Node.PROCESS_MODE_DISABLED, "joueur figé")
	# La vue du ciel : posée sous le noir, elle le lève, défile, puis redescend au noir.
	var opened: bool = await until(func() -> bool: return WorldManager.travel_view() != null, 5.0)
	assert_true(opened, "vue du ciel ouverte")
	var view := WorldManager.travel_view()
	assert_eq(view.layer, TravelView.LAYER, "au-dessus de l'interface")
	assert_string_contains(view.caption, "L'île d'essai", "« En route vers L'île d'essai… »")
	var lifted: bool = await until(func() -> bool: return view.black_alpha() < 0.05, 3.0)
	assert_true(lifted, "le ciel se montre")
	assert_true(get_tree().root.disable_3d, "la 3D n'est pas dessinée dessous")
	assert_true(await until(func() -> bool: return WorldManager.travel_view() == null, 10.0))
	assert_true(await wait_transition(), "arrivée")
	assert_signal_emitted_with_parameters(WorldManager, "travel_finished", [ILE_ESSAI])
	assert_gt(WorldManager.last_transition()["total_ms"], 600.0, "la vue a duré travel_time")
	assert_eq(WorldManager.current_map(), QUAY, "le quai de l'île d'essai")
	var arrival := current_map().marker(&"from_dirigeable")
	assert_lt(distance_to(arrival), 0.05, "posé au marqueur du port")
	assert_almost_eq(player.aim_direction(), Vector3.BACK, Vector3.ONE * 0.01, "tourné vers l'île")
	assert_eq(_islands, [ILE_68, ILE_ESSAI] as Array[StringName], "island_entered")
	assert_eq(GameState.island, ILE_ESSAI)
	assert_eq(GameState.map, QUAY)
	assert_true(GameState.knows_island(ILE_68) and GameState.knows_island(ILE_ESSAI))
	assert_false(get_tree().root.disable_3d, "3D de nouveau dessinée")
	assert_ne(player.process_mode, Node.PROCESS_MODE_DISABLED, "joueur rendu")
	assert_eq(WorldManager.last_transition()["island"], ILE_ESSAI, "mesures du voyage")
	# Sauvegarde et reprise sur l'île d'essai.
	await put_player(Vector3(16.0, 0.2, 15.0), Vector3.FORWARD)
	var saved_at := player.global_position
	assert_eq(SaveManager.save(), OK)
	var text := FileAccess.get_file_as_string(SaveManager.save_path)
	var saved: Dictionary = JSON.parse_string(text)
	assert_eq(saved["island"], "ile_essai", "île courante sauvegardée")
	assert_true((saved["known_islands"] as Array).has("ile_essai"), "îles connues sauvegardées")
	await close_tab()
	assert_eq(GameState.island, &"")
	assert_eq(SaveManager.load_game(), OK)
	assert_eq(GameState.island, ILE_ESSAI, "relue")
	game = GAME_SCENE.instantiate() as Node3D
	add_child(game)
	player = game.get_node(^"Player") as Player
	await frames(5)
	assert_eq(WorldManager.current_map(), QUAY, "reprise sur le quai")
	assert_eq(WorldManager.current_island(), ILE_ESSAI, "sur l'île d'essai")
	assert_lt(flat_distance(player.global_position, saved_at), 0.1, "à la même place")
	assert_eq(GameState.known_islands().size(), 3, "îles connues relues")
	# Retour par le quai de l'île d'essai.
	var back := current_map().get_node(^"Docks/vers_ile_68") as AirshipDock
	assert_true(await face_dock(back, Vector3.BACK), "invite du quai de retour")
	await tap_key(KEY_E)
	assert_true(await until(func() -> bool: return WorldManager.current_map() == ESSAI, 15.0))
	assert_true(await wait_transition(), "de retour")
	assert_lt(distance_to(current_map().marker(&"from_dirigeable")), 0.05, "au port d'essai")
	assert_eq(GameState.island, ILE_68, "sur l'île n° 68")


func test_the_surface_follows_its_rules() -> void:
	await start_game()
	WorldManager.fade_time = 0.0
	WorldManager.travel_time = 0.0
	await WorldManager.travel(SURFACE)
	assert_true(await wait_transition())
	assert_eq(WorldManager.current_map(), SURFACE_MAP, "le campement de la surface")
	assert_eq(GameState.island, SURFACE)
	var ground := current_map().get_node(^"Ground") as MapGround
	assert_true(ground.has_far_ground(), "le sol jusqu'à l'horizon")
	assert_eq(Atmosphere.preset_id(), &"apres_midi", "un ciel bleu (règle sky)")
	var timere := spawn_enemy(&"timere_small", ahead(5.0))
	await frames(2)
	assert_true(is_instance_valid(timere) and timere.is_inside_tree(), "un Timere à la surface")
	timere.queue_free()
	await WorldManager.travel(ILE_68)
	assert_true(await wait_transition())
	assert_eq(WorldManager.current_map(), ESSAI, "le port d'essai")
	assert_eq(Atmosphere.preset_id(), GameState.moment, "l'île n° 68 suit le moment")
	var none := spawn_enemy(&"timere_small", ahead(5.0))
	await frames(2)
	assert_false(is_instance_valid(none), "aucun Timere sur l'île n° 68")


func test_a_fall_returns_to_the_last_safe_point() -> void:
	await start_game()
	WorldManager.fade_time = 0.0
	WorldManager.travel_time = 0.0
	await WorldManager.travel(ILE_ESSAI)
	assert_true(await wait_transition())
	await put_player(Vector3(24.0, 0.2, 14.0), Vector3.FORWARD)
	assert_lt(flat_distance(WorldManager.last_safe_point(), player.global_position), 0.2)
	var safe := WorldManager.last_safe_point()
	watch_signals(WorldManager)
	player.global_position = Vector3(16.0, WorldManager.FALL_LIMIT - 5.0, 2.0)
	await frames(3)
	assert_signal_emitted_with_parameters(WorldManager, "rescued", [QUAY])
	assert_lt(flat_distance(player.global_position, safe), 0.2, "au dernier point sûr")


func test_unknown_destinations_and_busy_travel_are_refused() -> void:
	await start_game()
	WorldManager.fade_time = 0.2
	WorldManager.travel_time = 0.0
	await WorldManager.travel(&"nulle_part")
	assert_push_error("voyage impossible")
	assert_eq(WorldManager.current_map(), WorldManager.LEGACY_MAP, "on reste là")
	WorldManager.travel(ILE_ESSAI)
	WorldManager.travel(SURFACE)
	assert_push_warning("en cours")
	assert_true(await wait_transition())
	assert_eq(WorldManager.current_island(), ILE_ESSAI, "le second voyage a été ignoré")


func test_legacy_island_keeps_its_arena() -> void:
	await start_game()
	assert_eq(WorldManager.current_island(), LEGACY_ISLAND)
	assert_true(WorldAtlas.rules_for(WorldManager.current_map()).enemies_allowed, "par les données")
	director.start()
	assert_true(director.is_running(), "la veille du Couchant démarre")
	director.stop()
	var forest_enemies := game.get_node(^"World/ile_ancienne/Zones/forest/Enemies")
	assert_gt(forest_enemies.call(&"alive_count"), 0, "les rejetons des bois sont là")
