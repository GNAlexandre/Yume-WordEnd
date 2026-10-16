extends Node
## (X-L6) Démo des jeux à la demande du mode libre : le matin du jour 9 (les bâtons déjà faits),
## Willem à la clairière ; la joueuse à deux pas de lui lui parle (image « proposition » :
## « Allons-y » / « Plus tard »), puis « Allons-y » lance l'entraînement au bâton (image « jeu » :
## le texte « Échap : arrêter »).
##
## Lancement (les PNG sont écrits par la démo, qui quitte d'elle-même) :
##   ACTIVITIES_SHOTS=build/x-l6/shots xvfb-run -a -s "-screen 0 1280x720x24" \
##     tools/godot --rendering-driver opengl3 --resolution 1280x720 \
##     res://tests/integration/demo_activities.tscn
## Le journal donne les draw calls de chaque capture (« X-L6 vue … »).

const GAME_SCENE := preload("res://src/game.tscn")
## La joueuse posée à cette distance (m) au sud de Willem, tournée vers lui.
const NEAR := 1.6
## Temps (s) laissé à la réplique pour s'écrire, au jeu pour s'installer.
const SETTLE := 1.6
const PLAY_TIME := 3.0
const LIMIT := 90.0
const DONE_SCENES: Array[StringName] = [&"j9_1_porte", &"j9_2_batons"]

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
	_shots = OS.get_environment("ACTIVITIES_SHOTS")
	if _shots.is_empty():
		_shots = "res://build/x-l6/shots"
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
		print("X-L6 : rien à capturer après %d s (phase %d)" % [LIMIT, _phase])
		_finish()
		return
	var activities := StoryDirector.activities()
	match _phase:
		0:
			if _elapsed > 2.0 and LifeDirector.player_node() != null:
				# Le matin du jour 9, les bâtons faits : l'état de la partie, puis la vie suit.
				GameState.day = 9
				for scene_id: StringName in DONE_SCENES:
					GameState.mark_scene_done(scene_id)
				LifeDirector.set_slot(&"matin", 0.0)
				LifeDirector.refresh(false)
				_next_phase()
		1:
			var willem := LifeDirector.npc(&"willem")
			if willem != null and activities.offered_by(&"willem") == &"baton":
				# Willem à la clairière : on le laisse y arriver.
				var glade := LifeDirector.places().center(&"clairiere_centre")
				var apart := Vector2(
					willem.global_position.x - glade.x, willem.global_position.z - glade.z
				)
				if apart.length() < 1.5:
					var at := willem.global_position + Vector3(0.0, 0.0, NEAR)
					_player.global_position = WorldManager.ground_position(at, _player)
					_player.reset_physics_interpolation()
					_player.set_aim_direction(Vector3.FORWARD, true)
					_next_phase()
		2:
			if _elapsed - _phase_at > 1.0 and activities.talk(&"willem"):
				_next_phase()
		3:
			if _box.is_open() and _box.is_typing():
				_box.complete_line()
			if _box.is_choosing() and _elapsed - _phase_at > SETTLE:
				await _save("proposition")
				_box.choose(0)
				_next_phase()
		4:
			if activities.running() == &"baton" and _elapsed - _phase_at > PLAY_TIME:
				await _save("jeu")
				_finish()


func _next_phase() -> void:
	_phase += 1
	_phase_at = _elapsed


func _finish() -> void:
	_done = true
	MiniGames.stop_all()
	await get_tree().create_timer(0.5).timeout
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
			"X-L6 vue %s : %d draw calls, %d primitives ; carte %s, jour %d, créneau %s"
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
