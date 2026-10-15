extends Node
## (E8b) Démo du duel ingagnable et de l'entraînement avec Seniorious : la vraie partie (game.tscn)
## posée sur l'entrepôt (WorldManager.enter_map), le jeu lancé par MiniGames (comme `?jeu=duel` /
## `?jeu=seniorious`) et joué en temps réel par un joueur automatique qui passe par les vraies
## actions (Input.action_press : move_forward, attack, charge, interact).
##
## Captures : E8B_VIEW=<vue> tools/screenshot.sh res://tests/integration/demo_e8b.tscn
## build/e8b/<vue>.png <images>
##   duel           : le duel entier (Willem esquive, la vision accélérée, l'élan, le blanc, la
##                    projection) ;
##   duel_reprise   : « Encore une fois ! » (Willem en garde, phases 2 et 3, plus vite) ;
##   seniorious     : l'entraînement à l'étape 1 (le souffle) puis 2 (les annonces) ;
##   seniorious_grue: l'étape 3 (trois Grues, l'épée qui plonge dans le marais, l'invite).
## E8B_SEQUENCE=<dossier> : une image toutes les 0,5 s de jeu (E8B_STEP ; <dossier>/<vue>_NN.png),
## E8B_COUNT images (défaut : 28), à partir de E8B_SEQUENCE_FROM images (défaut : 6).
## Le journal donne les draw calls (« E8b vue … ») : au plus fort, et le maximum de la séquence.

const GAME_SCENE := preload("res://src/game.tscn")
const MAP := &"entrepot"
const VIEWS := {
	"duel": &"matin",
	"duel_reprise": &"matin",
	"seniorious": &"apres_midi",
	"seniorious_grue": &"apres_midi",
}
const STAGE_FRAME := 3

var _view := ""
var _state: Dictionary = {}
var _frame := 0
var _game: Node3D
var _player: Player
var _sequence_dir := ""
var _sequence_from := 6
var _sequence_count := 28
var _sequence_index := 0
var _sequence_left := 0.0
var _sequence_step := 0.5
var _duel: Duel
var _training: SenioriousTraining
var _max_draw_calls := 0
var _held: Dictionary = {}
var _strikes := 0
var _crane_plan: Dictionary = {}


func _ready() -> void:
	_view = OS.get_environment("E8B_VIEW")
	if not VIEWS.has(_view):
		_view = "duel"
	_sequence_dir = OS.get_environment("E8B_SEQUENCE")
	if OS.get_environment("E8B_SEQUENCE_FROM").is_valid_int():
		_sequence_from = int(OS.get_environment("E8B_SEQUENCE_FROM"))
	if OS.get_environment("E8B_STEP").is_valid_float():
		_sequence_step = float(OS.get_environment("E8B_STEP"))
	if OS.get_environment("E8B_COUNT").is_valid_int():
		_sequence_count = int(OS.get_environment("E8B_COUNT"))
	_state = GameState.to_dict()
	GameState.reset()
	WorldManager.fade_time = 0.0
	_game = GAME_SCENE.instantiate() as Node3D
	add_child(_game)
	_player = _game.get_node(^"Player") as Player


func _exit_tree() -> void:
	for action: StringName in _held:
		Input.action_release(action)
	WorldManager.fade_time = WorldManager.DEFAULT_FADE_TIME
	GameState.from_dict.call_deferred(_state)


func _physics_process(_delta: float) -> void:
	if is_instance_valid(_duel) and _duel.is_running():
		_duel_bot()
	elif is_instance_valid(_training) and _training.is_running():
		_training_bot()
	else:
		_stop_walking()
		_release(&"charge")


func _process(delta: float) -> void:
	_frame += 1
	if _frame == STAGE_FRAME:
		_stage()
	if _frame <= STAGE_FRAME:
		return
	var calls := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	_max_draw_calls = maxi(_max_draw_calls, calls)
	if not _sequence_dir.is_empty() and _frame >= _sequence_from:
		_sequence_left -= delta
		if _sequence_left <= 0.0 and _sequence_index < _sequence_count:
			_sequence_left = _sequence_step
			_save_frame(calls)


func _save_frame(calls: int) -> void:
	var index := _sequence_index
	_sequence_index += 1
	var label := _describe()
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(_sequence_dir)
	var path := _sequence_dir.path_join("%s_%02d.png" % [_view, index])
	get_viewport().get_texture().get_image().save_png(path)
	print(
		(
			"E8b vue %s image %02d : %s ; %d draw calls (max %d), %d objets"
			% [
				_view,
				index,
				label,
				calls,
				_max_draw_calls,
				Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
			]
		)
	)


func _describe() -> String:
	if is_instance_valid(_duel):
		return (
			"duel %s t=%.1f pâleur %.2f blanc %.2f ralenti %.2f Percival %s"
			% [
				_duel.phase,
				_duel.game_time(),
				_duel.vision.pale(),
				_duel.vision.flash(),
				_duel.vision.time_scale,
				_duel.get_node_or_null(^"PercivalGlow") != null,
			]
		)
	if is_instance_valid(_training):
		return (
			"Seniorious %s t=%.1f « %s »"
			% [_training.stage, _training.game_time(), _training.hud_text()]
		)
	return "fin"


func _stage() -> void:
	LifeDirector.set_slot(VIEWS[_view], 0.0)
	WorldManager.enter_map(MAP)
	LifeDirector.refresh(false)
	LifeDirector.build_nav_now()
	match _view:
		"duel":
			_duel = MiniGames.start_duel({"place": true, "seed": 8})
		"duel_reprise":
			_duel = MiniGames.start_duel({"place": true, "seed": 8, "reprise": true})
		"seniorious":
			_training = MiniGames.start_seniorious_training({"place_player": true, "seed": 11})
		"seniorious_grue":
			_training = MiniGames.start_seniorious_training(
				{"place_player": true, "seed": 11, "start_stage": 3}
			)
	if _duel != null:
		_duel.finished.connect(_on_finished)
	if _training != null:
		_training.finished.connect(_on_finished)
	_player.reset_physics_interpolation()
	_player.camera_rig.snap()
	print("E8b vue %s : jeu lancé" % _view)


func _on_finished(result: Dictionary) -> void:
	print("E8b vue %s : fini %s ; draw calls max %d" % [_view, result, _max_draw_calls])


# --- Le joueur automatique (vraies actions) ------------------------------------------------------


func _press(action: StringName) -> void:
	if not _held.has(action):
		_held[action] = true
		Input.action_press(action)


func _release(action: StringName) -> void:
	if _held.has(action):
		_held.erase(action)
		Input.action_release(action)


func _tap(action: StringName) -> void:
	_release(action)
	_press(action)
	get_tree().create_timer(0.05, true, true).timeout.connect(_release.bind(action))


## Marche vers target (les quatre directions, en diagonale si besoin) ; vrai une fois à stop m.
func _walk_toward(target: Vector3, stop: float) -> bool:
	var offset := target - _player.global_position
	var flat := Vector2(offset.x, offset.z)
	var arrived := flat.length() <= stop
	var wanted := {
		&"move_right": not arrived and offset.x > 0.25,
		&"move_left": not arrived and offset.x < -0.25,
		&"move_back": not arrived and offset.z > 0.25,
		&"move_forward": not arrived and offset.z < -0.25,
	}
	for action: StringName in wanted:
		if wanted[action]:
			_press(action)
		else:
			_release(action)
	return arrived


func _stop_walking() -> void:
	for action: StringName in [&"move_right", &"move_left", &"move_back", &"move_forward"]:
		_release(action)


func _willem_distance() -> float:
	var willem := LifeDirector.actor(&"willem")
	var offset := willem.position() - _player.global_position
	return Vector2(offset.x, offset.z).length()


## Le duel : il s'approche, frappe deux fois (Willem esquive), tient la charge jusqu'à la vision,
## la garde une seconde et demie, puis la relâche (l'onde, l'élan).
func _duel_bot() -> void:
	var now := _duel.game_time()
	match _duel.phase:
		&"dodge", &"ready":
			var near := _willem_distance() < 1.7
			if _held.has(&"charge"):
				_stop_walking()
			else:
				near = _walk_toward(LifeDirector.actor(&"willem").position(), 1.6)
			if near and _strikes < 2 and _duel.phase == &"dodge" and now >= 2.4 + _strikes * 1.4:
				_strikes += 1
				_tap(&"attack")
			if (_strikes >= 2 and now >= 5.6) or _duel.phase == &"ready":
				_stop_walking()
				_player.set_aim_direction(
					LifeDirector.actor(&"willem").position() - _player.global_position
				)
				_press(&"charge")
		&"vision":
			_stop_walking()
			if now - _vision_start() >= 1.5:
				_release(&"charge")


func _vision_start() -> float:
	if not _crane_plan.has("vision"):
		_crane_plan["vision"] = _duel.game_time()
	return float(_crane_plan["vision"])


## L'entraînement : le souffle en rythme, les gestes annoncés, les Grues (parade parfaite puis
## attaque), puis la marche vers l'épée et l'invite.
func _training_bot() -> void:
	var now := _training.game_time()
	match _training.stage:
		&"breath":
			var start := _training.breath_end() - 4.0
			if now >= start and now < _training.breath_end() - 0.05:
				_press(&"charge")
			else:
				_release(&"charge")
		&"moves":
			var gesture := _training.current_gesture()
			if gesture.is_empty() or now < float(gesture["start"]) + 0.25:
				_stop_walking()
				return
			match gesture["gesture"]:
				&"trois_coups":
					if int(now * 10.0) % 3 == 0:
						_tap(&"attack")
				&"pare":
					_tap(&"charge")
				&"cote":
					_press(&"move_back")
		&"crane":
			var fend := _training.current_fend()
			if fend.is_empty() or bool(fend["struck"]):
				if not fend.is_empty() and bool(fend["perfect"]):
					# Relâcher la charge, puis frapper à l'image suivante (pendant la charge, le
					# joueur est occupé : un appui d'attaque y serait perdu).
					if _held.has(&"charge"):
						_release(&"charge")
					elif not _crane_plan.get("struck", false):
						_crane_plan["struck"] = true
						_tap(&"attack")
				elif fend.is_empty():
					_crane_plan.erase("struck")
					_release(&"charge")
				return
			var impact := float(fend["impact"])
			if now >= impact - 0.1:
				_press(&"charge")
		&"pickup":
			var spot := _training.sword_spot()
			if spot == Vector3.INF:
				return
			if _walk_toward(spot, 0.8):
				_tap(&"interact")
