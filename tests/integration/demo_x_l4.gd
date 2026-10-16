extends Node
## (X-L4) Démo « les jours libres » : la vraie partie (game.tscn) en mode libre ; on dort deux
## nuits sans rien jouer (StoryDirector.sleep : les scènes des jours 1 et 2 réglées au coucher),
## puis le calendrier au réveil du jour 3 (vue « calendrier » : les lignes écrites, les scènes
## laissées passer, « À vivre aujourd'hui ») ; enfin les jours jusqu'au 13 réglés d'un coup, le
## calendrier après le départ (vue « apres_depart » : la grille qui glisse, jours libres).
##
## Lancement (les PNG sont écrits par la démo, qui quitte d'elle-même) :
##   X4_SHOTS=build/x-l4/shots xvfb-run -a -s "-screen 0 1280x720x24" \
##     tools/godot --rendering-driver opengl3 --resolution 1280x720 \
##     res://tests/integration/demo_x_l4.tscn
## Le journal donne les draw calls de chaque capture (« X-L4 vue … »).

const GAME_SCENE := preload("res://src/game.tscn")
const ISLAND := &"ile_68"

var _shots := ""
var _game: Node3D
var _player: Player
var _calendar: Control
var _previous_mode: StringName = &""
var _started := false


func _ready() -> void:
	# Seulement lancée comme scène principale (pas instanciée par la fumée, qui la libère aussitôt).
	if get_tree().current_scene != self:
		return
	_started = true
	_shots = OS.get_environment("X4_SHOTS")
	if _shots.is_empty():
		_shots = "res://build/x-l4/shots"
	_previous_mode = StoryDirector.default_mode
	StoryDirector.default_mode = StoryPacing.FREE
	WorldManager.fade_time = 0.2
	SaveManager.new_game(&"chtholly")
	SaveManager.close_game(false)
	_game = GAME_SCENE.instantiate() as Node3D
	add_child(_game)
	_player = _game.get_node(^"Player") as Player
	_calendar = _game.get_node(^"UI/HUD/Calendar") as Control
	_run.call_deferred()


func _exit_tree() -> void:
	if not _started:
		return
	StoryDirector.default_mode = _previous_mode
	WorldManager.fade_time = WorldManager.DEFAULT_FADE_TIME


func _run() -> void:
	await _until(func() -> bool: return _ready_to_play(), 20.0)
	await _seconds(2.0)
	# Deux nuits sans rien jouer : le soir du jour 1, puis le soir du jour 2.
	await StoryDirector.sleep()
	LifeDirector.set_slot(&"soir", 0.0)
	await _seconds(0.5)
	await StoryDirector.sleep()
	await _seconds(1.5)
	await _save("monde")
	_calendar.call(&"open")
	await _seconds(0.8)
	await _save("calendrier")
	await _save_scenario("calendrier_scenario")
	_calendar.call(&"close")
	# Les jours 3 à 12 réglés d'un coup, comme au coucher : le jour 13 commence.
	while GameState.day < 13:
		StoryDirector.resolver().before_sleep(ISLAND, GameState.day)
		if not GameState.has_calendar_line(GameState.day):
			GameState.write_calendar(GameState.day)
		StoryDirector.advance_day()
	await _seconds(1.5)
	_calendar.call(&"open")
	await _seconds(0.8)
	await _save("apres_depart")
	await _save_scenario("apres_depart_scenario")
	_calendar.call(&"close")
	await _seconds(0.3)
	print("X-L4 : fin (jour %d)" % GameState.day)
	get_tree().quit()


## La même page en scénarisé (la page d'avant X-L4, pour comparer les draw calls), puis le libre.
func _save_scenario(file_name: String) -> void:
	StoryDirector.set_mode(StoryPacing.SCENARIO)
	_calendar.call(&"refresh")
	await _seconds(0.5)
	await _save(file_name)
	StoryDirector.set_mode(StoryPacing.FREE)
	_calendar.call(&"refresh")


func _ready_to_play() -> bool:
	return (
		WorldManager.current_map() == &"entrepot"
		and not WorldManager.is_transitioning()
		and not _player.is_story_held()
	)


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
			"X-L4 vue %s : %d draw calls ; jour %d, %s ; à vivre %s ; passées %s"
			% [
				file_name,
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
				GameState.day,
				LifeSlots.current(),
				_calendar.call(&"today_entries"),
				_calendar.call(&"passed_lines"),
			]
		)
	)
