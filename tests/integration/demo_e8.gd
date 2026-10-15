extends Node
## (E8) Démo des jeux : la vraie partie (game.tscn) posée sur l'entrepôt par WorldManager.enter_map ;
## le ballon au champ ou l'entraînement au bâton à la clairière (MiniGames, comme `?jeu=`).
## Le jeu est avancé à la main jusqu'à un moment parlant (plus vite que le temps), puis il joue en
## temps réel pendant les captures.
##
## Captures : E8_VIEW=<vue> tools/screenshot.sh res://tests/integration/demo_e8.tscn
## build/e8/<vue>.png <images>
##   ballon       : le match en cours, le joueur dans la partie (le score s'affiche) ;
##   ballon_bord  : le même match vu du bord ouest, le joueur spectateur ;
##   ballon_banc  : un match à quatre par équipe : les remplaçantes sur le banc ;
##   baton_a      : l'entraînement, phase A (Willem annonce un coup, le cercle au sol) ;
##   baton_b      : l'entraînement, phase B (trois contre un).
## E8_SEQUENCE=<dossier> : en plus, une image toutes les 0,5 s pendant 5 s (<dossier>/<vue>_NN.png),
## à partir de E8_SEQUENCE_FROM images (défaut : 20).
## Le journal donne les draw calls (« E8 vue … ») au plus fort du match.

const GAME_SCENE := preload("res://src/game.tscn")
const MAP := &"entrepot"
const DT := 1.0 / 60.0
const VIEWS := {
	"ballon": [&"apres_midi", 45.0],
	"ballon_bord": [&"apres_midi", 45.0],
	"ballon_banc": [&"apres_midi", 40.0],
	"baton_a": [&"matin", 3.0],
	"baton_b": [&"matin", 0.0],
}
const STAGE_FRAME := 3
const MEASURE_FRAME := 40
const SEQUENCE_COUNT := 10
const SEQUENCE_STEP := 0.5

var _view := ""
var _state: Dictionary = {}
var _frame := 0
var _game: Node3D
var _player: Player
var _sequence_dir := ""
var _sequence_from := 20
var _sequence_index := 0
var _sequence_left := 0.0
var _training: StaffTraining
var _bot_plan: StringName = &""
var _bot_blow_at: float = -1.0
var _bot_cycle: int = 0
var _bot_back_at: float = -1.0
var _bot_home := Vector3.ZERO
var _max_draw_calls := 0


func _ready() -> void:
	_view = OS.get_environment("E8_VIEW")
	if not VIEWS.has(_view):
		_view = "ballon"
	_sequence_dir = OS.get_environment("E8_SEQUENCE")
	if OS.get_environment("E8_SEQUENCE_FROM").is_valid_int():
		_sequence_from = int(OS.get_environment("E8_SEQUENCE_FROM"))
	_state = GameState.to_dict()
	GameState.reset()
	WorldManager.fade_time = 0.0
	_game = GAME_SCENE.instantiate() as Node3D
	add_child(_game)
	_player = _game.get_node(^"Player") as Player


func _exit_tree() -> void:
	WorldManager.fade_time = WorldManager.DEFAULT_FADE_TIME
	GameState.from_dict.call_deferred(_state)


func _physics_process(_delta: float) -> void:
	if _training != null and is_instance_valid(_training) and _training.is_running():
		_bot_step()


func _process(delta: float) -> void:
	_frame += 1
	if _frame == STAGE_FRAME:
		_stage()
	if _frame > STAGE_FRAME:
		_max_draw_calls = maxi(
			_max_draw_calls,
			int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		)
	if _frame == MEASURE_FRAME:
		print(
			(
				"E8 vue %s : %d draw calls (max %d), %d primitives, %d objets ; %s"
				% [
					_view,
					Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
					_max_draw_calls,
					Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
					Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
					LifeDirector.stats_text(),
				]
			)
		)
	if (
		not _sequence_dir.is_empty()
		and _frame >= _sequence_from
		and _sequence_index < SEQUENCE_COUNT
	):
		_sequence_left -= delta
		if _sequence_left <= 0.0:
			_sequence_left = SEQUENCE_STEP
			_save_frame()


func _save_frame() -> void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(_sequence_dir)
	var path := _sequence_dir.path_join("%s_%02d.png" % [_view, _sequence_index])
	_sequence_index += 1
	get_viewport().get_texture().get_image().save_png(path)


func _stage() -> void:
	var setup: Array = VIEWS[_view]
	LifeDirector.set_slot(setup[0], 0.0)
	WorldManager.enter_map(MAP)
	LifeDirector.build_nav_now()
	if _view.begins_with("ballon"):
		_stage_ball(float(setup[1]))
	else:
		_stage_training(float(setup[1]))
	_player.velocity = Vector3.ZERO
	_player.reset_physics_interpolation()
	_player.camera_rig.snap()


func _stage_ball(forward: float) -> void:
	var options := {"overrides": {"assemble_wait": 0.2}}
	if _view == "ballon_banc":
		options["overrides"]["team_size"] = 4
	if _view == "ballon":
		options["player_at"] = Vector3(75.0, -0.4, 21.0)
	else:
		options["player_at"] = Vector3(64.6, -0.4, 16.0)
	var game := MiniGames.start_ball_match(options)
	_player.set_aim_direction(Vector3(1.0, 0.0, 0.0), true)
	for _i: int in roundi(forward / DT):
		LifeDirector._physics_process(DT)
	if game != null:
		print("E8 match : %s, score %s, %d membres" % [game.phase, game.score, game.members.size()])
		var ball := game.ball
		print(
			(
				"E8 ballon en %s, visible %s, enfants %s"
				% [ball.global_position, ball.visible, ball.get_children()]
			)
		)
		for child: Node in ball.get_node("Image").get_children():
			print("   ", child.name, " ", child.get("visible"), " ", child.get("mesh"))


func _stage_training(forward: float) -> void:
	_training = MiniGames.start_staff_training({"place_player": true, "with_hud": true})
	if _training == null:
		return
	_bot_home = _player.global_position
	_training.set_physics_process(false)
	if _view == "baton_b":
		# Phase A réussie d'office pour montrer la B.
		var seconds := 0.0
		while _training.phase != &"b" and seconds < 200.0:
			_step_training(DT)
			seconds += DT
			if _training.phase == &"link" and _training.streak < 12:
				break
		print("E8 entraînement : phase %s après %.1f s" % [_training.phase, seconds])
		forward = 4.0
	for _i: int in roundi(forward / DT):
		_step_training(DT)
	_training.set_physics_process(true)
	_player.set_aim_direction(_training_willem_position() - _player.global_position, true)


func _training_willem_position() -> Vector3:
	var willem := LifeDirector.actor(&"willem")
	return willem.position() if willem != null else Vector3.ZERO


func _step_training(delta: float) -> void:
	_bot_step()
	_training.advance(delta)
	LifeDirector._physics_process(delta)


## Un joueur automatique : il bloque, dévie ou esquive selon le coup annoncé.
func _bot_step() -> void:
	if _training == null or not is_instance_valid(_training):
		return
	var blow := _training.current_blow()
	var now := _training.game_time()
	if _bot_back_at > 0.0 and now >= _bot_back_at:
		_bot_back_at = -1.0
		_player.global_position = _bot_home
	if blow.is_empty():
		_bot_plan = &""
		return
	var impact: float = blow["impact"]
	if _bot_plan.is_empty():
		_bot_cycle += 1
		var phase_b: bool = blow["kind"] == &"counter"
		var plans: Array[StringName] = [&"block", &"deflect", &"deflect", &"dodge"]
		if phase_b:
			plans = [&"dodge", &"deflect"]
		_bot_plan = plans[_bot_cycle % plans.size()]
		_bot_blow_at = impact
		match _bot_plan:
			&"block", &"deflect":
				_player.combat.charge_begin()
			&"dodge":
				_player.global_position = _bot_home + Vector3(1.7, 0.0, 0.0)
				_bot_back_at = impact + 0.4
	if _bot_plan == &"deflect" and now >= impact - 0.07:
		_player.combat.charge_release()
	elif _bot_plan == &"block" and now >= impact + 0.05:
		_player.combat.charge_release()
