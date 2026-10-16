extends GutTest
## Câblage du Lot 0 : menu → nouvelle partie → game.tscn ; joueur au Spawn de la carte de départ,
## map_entered, PV initiaux, réapparition. (F1) La carte de départ du test est la carte d'essai,
## récit coupé (l'ancienne île et son village sont partis).

const MAIN_SCENE := preload("res://src/main.tscn")
const GAME_SCENE := preload("res://src/game.tscn")
const PLAYER_STUB := preload("res://tests/stubs/player_stub.tscn")
const START := &"essai"

var _respawn_delay: float
var _previous_story: bool


func before_each() -> void:
	# (E6) Une nouvelle partie ouvre l'acte 1 à l'entrepôt : ce test joue la carte d'essai.
	WorldManager.start_map = START
	_previous_story = StoryDirector.enabled
	StoryDirector.enabled = false
	GameState.reset()
	_respawn_delay = WorldManager.respawn_delay


func after_each() -> void:
	WorldManager.start_map = WorldManager.START_MAP
	StoryDirector.enabled = _previous_story
	WorldManager.respawn_delay = _respawn_delay


func after_all() -> void:
	GameState.reset()


func _spawn(game: Node3D) -> Node3D:
	return game.get_node(NodePath("World/%s/Markers/Spawn" % START)) as Node3D


func test_new_game_from_menu_loads_game() -> void:
	var main: Node = add_child_autofree(MAIN_SCENE.instantiate())
	await wait_process_frames(2)
	assert_not_null(main.find_child("MainMenu", true, false), "menu affiché")
	var skin := SkinRegistry.default_skin()
	SaveManager.new_game(skin.id)
	await wait_until(func() -> bool: return main.find_child("Game", true, false) != null, 5.0)
	await wait_process_frames(2)
	assert_not_null(main.find_child("Game", true, false), "partie chargée")
	assert_null(main.find_child("MainMenu", true, false), "menu libéré")


func test_game_places_player_and_emits_initial_state() -> void:
	watch_signals(EventBus)
	var game: Node3D = add_child_autofree(GAME_SCENE.instantiate())
	await wait_physics_frames(10)
	var player := game.get_node(^"Player") as Node3D
	assert_lt(player.global_position.distance_to(_spawn(game).global_position), 1.0, "au Spawn")
	assert_signal_emitted_with_parameters(EventBus, "player_health_changed", [5, 5])
	assert_signal_emitted_with_parameters(EventBus, "map_entered", [START])
	assert_eq(WorldManager.current_map(), START)
	assert_eq(GameState.map, START)
	assert_eq(get_viewport().get_camera_3d(), game.get_node(^"Player/CameraRig/Camera3D"))


func test_respawn_brings_player_back_to_the_arrival_marker() -> void:
	var game: Node3D = add_child_autofree(GAME_SCENE.instantiate())
	await wait_physics_frames(3)
	var player := game.get_node(^"Player") as Node3D
	player.global_position = _spawn(game).global_position + Vector3(8.0, 0.0, -6.0)
	await wait_physics_frames(3)
	assert_gt(player.global_position.distance_to(_spawn(game).global_position), 5.0, "loin")
	watch_signals(EventBus)
	WorldManager.respawn()
	assert_lt(
		player.global_position.distance_to(_spawn(game).global_position), 1.0, "réapparu au Spawn"
	)
	assert_signal_emitted(EventBus, "player_respawned")


func test_player_died_triggers_respawn_after_delay() -> void:
	WorldManager.respawn_delay = 0.1
	var game: Node3D = add_child_autofree(GAME_SCENE.instantiate())
	await wait_physics_frames(3)
	var player := game.get_node(^"Player") as Node3D
	player.global_position = _spawn(game).global_position + Vector3(8.0, 0.0, -6.0)
	watch_signals(EventBus)
	EventBus.player_died.emit()
	await wait_seconds(0.3)
	assert_signal_emitted(EventBus, "player_respawned")
	assert_lt(player.global_position.distance_to(_spawn(game).global_position), 1.0)


func test_no_respawn_when_dead_player_is_gone() -> void:
	WorldManager.respawn_delay = 0.1
	var player := PLAYER_STUB.instantiate()
	add_child(player)
	watch_signals(EventBus)
	EventBus.player_died.emit()
	player.free()
	await wait_seconds(0.3)
	assert_signal_not_emitted(
		EventBus, "player_respawned", "pas de réapparition d'un joueur disparu"
	)
