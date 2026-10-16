extends Node
## (L3) Rafale d'une escorte : j3_2_chemin (Ithea et Nephren suivent Chtholly sur le sentier). Le
## joueur reprend la main, court 25 m par le chemin de la navigation (ou marche, L3_RUN=0), puis
## s'arrête ; une image toutes les L3_STEP s (0,1) de l'instant où il part jusqu'à L3_AFTER s
## (3) après son arrêt ; au journal, l'écart des suiveuses toutes les 0,5 s.
##
## Lancement :
##   L3_SHOTS=build/l3/avant xvfb-run -a -s "-screen 0 960x540x24" tools/godot \
##     --rendering-driver opengl3 --resolution 960x540 res://tests/integration/demo_l3_escorte.tscn
## Planche : assembler les images r_*.png en grille (Pillow), 10 par ligne.

const GAME_SCENE := preload("res://src/game.tscn")
const SEEN := "user://demo_l3_seen.cfg"
const DONE := [
	"j1_1_port",
	"j1_2_lumiere",
	"j1_2_embuscade",
	"j1_3_intrus",
	"j1_4_chemin",
	"j1_5_premiers_pas",
	"j1_6_diner",
	"j1_7_chambre",
	"j2_1_matin",
	"j2_2_fuite",
	"j2_3_fenetre",
	"j3_1_information",
]
const METERS := 25.0

var _shots := ""
var _step := 0.1
var _after := 3.0
var _run := true
var _game: Node3D
var _player: Player
var _box: DialogueBox
var _previous_seen := ""
var _read_left := 0.9
var _phase := 0
var _clock := 0.0
var _next_shot := 0.0
var _next_log := 0.0
var _index := 0
var _route := PackedVector3Array()
var _leg := 0
var _walked := 0.0
var _last := Vector3.ZERO
var _stopped_at := 0.0
var _done := false


func _ready() -> void:
	_shots = OS.get_environment("L3_SHOTS")
	if _shots.is_empty():
		_shots = "res://build/l3/shots"
	if OS.get_environment("L3_STEP").is_valid_float():
		_step = float(OS.get_environment("L3_STEP"))
	if OS.get_environment("L3_AFTER").is_valid_float():
		_after = float(OS.get_environment("L3_AFTER"))
	_run = OS.get_environment("L3_RUN") != "0"
	_previous_seen = StoryDirector.seen_path
	StoryDirector.seen_path = SEEN
	StoryDirector.forget_seen()
	WorldManager.fade_time = 0.2
	SaveManager.new_game(&"chtholly")
	SaveManager.close_game(false)
	var state := GameState.to_dict()
	state["day"] = 3
	state["slot"] = "matin"
	state["moment"] = String(LifeSlots.moment_of(&"matin"))
	state["map"] = "sentier"
	state["position"] = [2.5, 0.2, 24.0]
	state["scenes_done"] = DONE
	state["calendar"] = {"1": "", "2": ""}
	GameState.from_dict(state)
	EventBus.game_loaded.emit()
	process_mode = Node.PROCESS_MODE_ALWAYS
	_game = GAME_SCENE.instantiate() as Node3D
	_game.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_game)
	_player = _game.get_node(^"Player") as Player
	_box = _game.get_node(^"UI/DialogueBox") as DialogueBox


func _exit_tree() -> void:
	StoryDirector.forget_seen()
	StoryDirector.seen_path = _previous_seen
	WorldManager.fade_time = WorldManager.DEFAULT_FADE_TIME


func _physics_process(delta: float) -> void:
	if _done or _player == null:
		return
	_clock += delta
	if _clock > 400.0:
		print("L3 : rien après 400 s (scène %s)" % StoryDirector.current_scene())
		_finish()
		return
	if _box.is_open():
		_box.complete_line()
		_read_left -= delta
		if _read_left <= 0.0:
			_read_left = 0.9
			if _box.is_choosing():
				_box.choose(0)
			elif _box.is_waiting():
				_box.advance()
		return
	_read_left = 0.9
	match _phase:
		0:
			# La scène rend la main : les suiveuses sont en route.
			if (
				StoryDirector.current_scene() == &"j3_2_chemin"
				and not _player.is_story_held()
				and not WorldManager.is_transitioning()
				and StoryDirector.stage().followers().size() == 2
			):
				_phase = 1
				_clock = 0.0
		1:
			if _clock > 1.5:
				_start_run()
		2:
			_drive(delta)
		3:
			_log_gaps(delta)
			_shoot(delta)
			if _clock - _stopped_at > _after:
				_finish()


func _start_run() -> void:
	var nav: LifeNav = StoryDirector.stage().ensure_nav()
	var exit_point := Vector3.ZERO
	for candidate: MapExit in WorldManager.current_map_node().exits():
		if candidate.target_map == &"ville_haute":
			exit_point = candidate.global_position
	_route = StoryDirector.stage().route(
		_player.global_position, nav.find_path(_player.global_position, exit_point)
	)
	_route.append(exit_point)
	_last = _player.global_position
	if _run:
		Input.action_press(&"run")
	_phase = 2
	_next_shot = 0.0
	_next_log = 0.0
	print("L3 : départ, %d points" % _route.size())


func _drive(delta: float) -> void:
	_walked += Vector2(_player.global_position.x, _player.global_position.z).distance_to(
		Vector2(_last.x, _last.z)
	)
	_last = _player.global_position
	_log_gaps(delta)
	_shoot(delta)
	if _walked >= METERS or _leg >= _route.size():
		_press_move(Vector3.ZERO)
		Input.action_release(&"run")
		_phase = 3
		_stopped_at = _clock
		print("L3 : arrêt à %.1f m, t = %.1f s" % [_walked, _clock])
		return
	var toward := _route[_leg] - _player.global_position
	toward.y = 0.0
	if toward.length() < 0.7:
		_leg += 1
		return
	_press_move(toward.normalized())


func _log_gaps(delta: float) -> void:
	_next_log -= delta
	if _next_log > 0.0:
		return
	_next_log = 0.5
	var line := "L3 t=%.1f" % _clock
	for npc_id: StringName in StoryDirector.stage().followers():
		var actor := LifeDirector.actor(npc_id)
		if actor != null:
			var flat := actor.position() - _player.global_position
			line += "  %s %.1f m" % [npc_id, Vector2(flat.x, flat.z).length()]
	print(line)


func _shoot(delta: float) -> void:
	_next_shot -= delta
	if _next_shot > 0.0:
		return
	_next_shot = _step
	_save("r_%03d" % _index)
	_index += 1


func _press_move(direction: Vector3) -> void:
	var pairs := {
		&"move_right": direction.x,
		&"move_left": -direction.x,
		&"move_back": direction.z,
		&"move_forward": -direction.z,
	}
	for action: StringName in pairs:
		var strength: float = pairs[action]
		if strength > 0.05:
			Input.action_press(action, strength)
		else:
			Input.action_release(action)


func _finish() -> void:
	_done = true
	await get_tree().create_timer(0.3).timeout
	get_tree().quit()


func _save(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var dir := _shots if _shots.begins_with("/") else ProjectSettings.globalize_path(_shots)
	DirAccess.make_dir_recursive_absolute(dir)
	get_viewport().get_texture().get_image().save_png(dir.path_join(file_name + ".png"))
