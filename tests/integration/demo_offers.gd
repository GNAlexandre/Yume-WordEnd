extends Node
## (X-L1) Démo des propositions du mode libre : une nouvelle partie en libre (jour 1, le soir),
## Nygglatho sous le porche porte le ruban du récit ; la joueuse posée à deux pas d'elle (image
## « ruban »), puis lui parle (image « proposition » : « Allons-y » / « Plus tard »).
##
## Lancement (les PNG sont écrits par la démo, qui quitte d'elle-même) :
##   OFFERS_SHOTS=build/x-l1/shots xvfb-run -a -s "-screen 0 1280x720x24" \
##     tools/godot --rendering-driver opengl3 --resolution 1280x720 \
##     res://tests/integration/demo_offers.tscn
## Le journal donne les draw calls de chaque capture (« X-L1 vue … »).

const GAME_SCENE := preload("res://src/game.tscn")
## La joueuse posée à cette distance (m) au sud de Nygglatho, tournée vers elle.
const NEAR := 2.0
## Temps (s) laissé au ruban pour entrer en fondu, à la réplique pour s'écrire.
const SETTLE := 1.6
const LIMIT := 60.0

var _shots := ""
var _game: Node3D
var _player: Player
var _box: DialogueBox
var _previous_mode: StringName = &""
var _elapsed := 0.0
var _phase := 0
var _phase_at := 0.0
var _done := false
## Une capture attend l'image dessinée.
var _saving := false


func _ready() -> void:
	_shots = OS.get_environment("OFFERS_SHOTS")
	if _shots.is_empty():
		_shots = "res://build/x-l1/shots"
	_previous_mode = StoryDirector.default_mode
	StoryDirector.default_mode = StoryPacing.FREE
	WorldManager.fade_time = 0.2
	SaveManager.new_game(&"chtholly")
	SaveManager.close_game(false)
	_game = GAME_SCENE.instantiate() as Node3D
	add_child(_game)
	_player = _game.get_node(^"Player") as Player
	_box = _game.get_node(^"UI/DialogueBox") as DialogueBox


func _exit_tree() -> void:
	if not _previous_mode.is_empty():
		StoryDirector.default_mode = _previous_mode
	WorldManager.fade_time = WorldManager.DEFAULT_FADE_TIME


func _physics_process(delta: float) -> void:
	if _done or _player == null or _saving:
		return
	_elapsed += delta
	if _elapsed > LIMIT:
		print("X-L1 : rien à capturer après %d s (phase %d)" % [LIMIT, _phase])
		_finish()
		return
	var nygglatho := LifeDirector.npc(&"nygglatho")
	match _phase:
		0:
			if nygglatho != null and InteractSign.is_story(nygglatho) and _elapsed > 1.8:
				var at := nygglatho.global_position + Vector3(0.0, 0.0, NEAR)
				_player.global_position = WorldManager.ground_position(at, _player)
				_player.reset_physics_interpolation()
				_player.set_aim_direction(Vector3.FORWARD, true)
				_next_phase()
		1:
			if _elapsed - _phase_at > SETTLE:
				_save("ruban")
				_next_phase()
		2:
			if StoryDirector.offers().talk(&"nygglatho"):
				_next_phase()
		3:
			if _box.is_open() and _box.is_typing():
				_box.complete_line()
			if _box.is_choosing() and _elapsed - _phase_at > SETTLE:
				_save("proposition")
				_finish()


func _next_phase() -> void:
	_phase += 1
	_phase_at = _elapsed


func _finish() -> void:
	_done = true
	await get_tree().create_timer(0.3).timeout
	get_tree().quit()


func _save(file_name: String) -> void:
	_saving = true
	await RenderingServer.frame_post_draw
	_saving = false
	var dir := _shots if _shots.begins_with("/") else ProjectSettings.globalize_path(_shots)
	DirAccess.make_dir_recursive_absolute(dir)
	get_viewport().get_texture().get_image().save_png(dir.path_join(file_name + ".png"))
	print(
		(
			"X-L1 vue %s : %d draw calls, %d primitives ; carte %s, jour %d, créneau %s"
			% [
				file_name,
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
				Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
				WorldManager.current_map(),
				GameState.day,
				LifeSlots.current(),
			]
		)
	)
