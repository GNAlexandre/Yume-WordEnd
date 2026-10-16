extends Node
## (X-L2) Démo « passer une scène » : la vraie partie (game.tscn) en mode libre ; la scène du porche
## (j1_2_lumiere) jouée, l'invite « Échap : passer » à l'écran pendant sa réplique (vue
## « invite »), puis un appui sur Échap : la scène finie, la main au joueur (vue « passee ») ; enfin
## en mode scénarisé, la même scène accélérée par l'interaction tenue (vue « acceleree »).
##
## Lancement (les PNG sont écrits par la démo, qui quitte d'elle-même) :
##   X2_SHOTS=build/x-l2/shots xvfb-run -a -s "-screen 0 1280x720x24" \
##     tools/godot --rendering-driver opengl3 --resolution 1280x720 \
##     res://tests/integration/demo_x_l2.tscn
## Le journal donne les draw calls de chaque capture (« X-L2 vue … »).

const GAME_SCENE := preload("res://src/game.tscn")
const SCENE := &"j1_2_lumiere"
const ISLAND := &"ile_68"

var _shots := ""
var _game: Node3D
var _player: Player
var _box: DialogueBox
var _previous_mode: StringName = &""
var _started := false


func _ready() -> void:
	# Seulement lancée comme scène principale (pas instanciée par la fumée, qui la libère aussitôt).
	if get_tree().current_scene != self:
		return
	_started = true
	_shots = OS.get_environment("X2_SHOTS")
	if _shots.is_empty():
		_shots = "res://build/x-l2/shots"
	_previous_mode = StoryDirector.default_mode
	StoryDirector.default_mode = StoryPacing.FREE
	WorldManager.fade_time = 0.2
	SaveManager.new_game(&"chtholly")
	SaveManager.close_game(false)
	_game = GAME_SCENE.instantiate() as Node3D
	add_child(_game)
	_player = _game.get_node(^"Player") as Player
	_box = _game.get_node(^"UI/DialogueBox") as DialogueBox
	_run.call_deferred()


func _exit_tree() -> void:
	if not _started:
		return
	StoryDirector.default_mode = _previous_mode
	WorldManager.fade_time = WorldManager.DEFAULT_FADE_TIME
	Engine.time_scale = 1.0


func _run() -> void:
	await _until(func() -> bool: return _ready_to_play(), 20.0)
	for scene_id: StringName in StoryData.scene_ids(ISLAND):
		if scene_id != SCENE:
			GameState.mark_scene_done(scene_id)
	await _seconds(2.0)
	StoryDirector.play(SCENE)
	await _until(func() -> bool: return _box.is_open() and not _box.is_typing(), 20.0)
	await _seconds(0.3)
	await _save("invite")
	_action(&"pause", true)
	await _seconds(0.1)
	_action(&"pause", false)
	await _until(func() -> bool: return not StoryDirector.is_playing(), 5.0)
	await _seconds(1.5)
	await _save("passee")
	# Le mode scénarisé : la même scène, l'interaction tenue.
	StoryDirector.set_mode(StoryPacing.SCENARIO)
	GameState.forget_scene(SCENE)
	StoryDirector.play(SCENE)
	_action(&"interact", true)
	await _until(func() -> bool: return StoryDirector.runner().is_forwarding(), 5.0)
	await _until(func() -> bool: return _box.is_open(), 10.0)
	await _seconds(0.2)
	await _save("acceleree")
	await _until(func() -> bool: return not StoryDirector.is_playing(), 30.0)
	_action(&"interact", false)
	await _seconds(0.5)
	print("X-L2 : fin (temps %.1f)" % Engine.time_scale)
	get_tree().quit()


func _ready_to_play() -> bool:
	return (
		WorldManager.current_map() == &"entrepot"
		and not WorldManager.is_transitioning()
		and not _player.is_story_held()
	)


func _action(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func _seconds(seconds: float) -> void:
	await _until(func() -> bool: return false, seconds)


func _until(predicate: Callable, seconds: float) -> void:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while not predicate.call() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame


func _save(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var dir := _shots if _shots.begins_with("/") else ProjectSettings.globalize_path(_shots)
	DirAccess.make_dir_recursive_absolute(dir)
	get_viewport().get_texture().get_image().save_png(dir.path_join(file_name + ".png"))
	print(
		(
			"X-L2 vue %s : %d draw calls ; scène %s, invite « %s », accélérée %s, temps %.1f"
			% [
				file_name,
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
				StoryDirector.current_scene(),
				str(StoryDirector.stage().overlay().call(&"skip_text")),
				StoryDirector.runner().is_forwarding(),
				Engine.time_scale,
			]
		)
	)
