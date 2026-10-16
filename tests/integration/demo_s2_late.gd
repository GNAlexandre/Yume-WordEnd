extends Node
## (S2) Démo des jours 9 à 12 de l'acte 1 : la vraie partie (game.tscn) reprise au réveil d'un jour,
## menée par un pilote automatique (répliques lues, premier choix ; ce qu'attend une scène fait d'un
## coup ; entre deux scènes, ce qui déclenche la suivante ; les jeux joués par de vraies actions) ;
## une image toutes les S2_STEP s (0,5 par défaut) pendant les scènes, réduite de moitié.
##
## Lancement (la démo quitte d'elle-même au jour suivant, ou à la fin de l'acte) :
##   S2_DAY=9 S2_SHOTS=build/s2j9/shots/jour9 xvfb-run -a -s "-screen 0 1280x720x24" \
##     tools/godot --rendering-driver opengl3 --resolution 1280x720 \
##     res://tests/integration/demo_s2_late.tscn
## Sans S2_DAY (fumée), la démo ne fait rien. Le journal donne les draw calls de chaque image
## (« S2 image … »). Planches : python3 tools/contact_sheet.py (build/s2j9).

const GAME_SCENE := preload("res://src/game.tscn")
const SEEN := "user://demo_s2_late_seen.cfg"
const READ_TIME := 1.1
const BEDROOM := Vector3(6.2, 0.0, 6.4)
## Drapeaux posés au réveil (la réussite du jour 9 change le jour 11).
const FLAGS := [&"j9_baton_reussi"]

var _day := 0
var _shots := ""
var _game: Node3D
var _player: Player
var _box: DialogueBox
var _state: Dictionary = {}
var _read_left := READ_TIME
var _acting := false
var _done := false
var _step := 0.5
var _step_left := 0.0
var _index := 0
var _elapsed := 0.0
var _previous_seen := ""
var _held: Dictionary = {}
var _plan: Dictionary = {}


func _ready() -> void:
	_day = int(OS.get_environment("S2_DAY")) if OS.get_environment("S2_DAY").is_valid_int() else 0
	if _day < 9:
		return
	_shots = OS.get_environment("S2_SHOTS")
	if _shots.is_empty():
		_shots = "res://build/s2j9/shots/jour%d" % _day
	if OS.get_environment("S2_STEP").is_valid_float():
		_step = float(OS.get_environment("S2_STEP"))
	_state = GameState.to_dict()
	_previous_seen = StoryDirector.seen_path
	StoryDirector.seen_path = SEEN
	StoryDirector.forget_seen()
	WorldManager.fade_time = 0.3
	_resume()
	process_mode = Node.PROCESS_MODE_ALWAYS
	_game = GAME_SCENE.instantiate() as Node3D
	_game.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_game)
	_player = _game.get_node(^"Player") as Player
	_box = _game.get_node(^"UI/DialogueBox") as DialogueBox


func _exit_tree() -> void:
	if _day < 9:
		return
	for action: StringName in _held.keys():
		Input.action_release(action)
	StoryDirector.forget_seen()
	StoryDirector.seen_path = _previous_seen
	WorldManager.fade_time = WorldManager.DEFAULT_FADE_TIME
	GameState.from_dict(_state)


func _resume() -> void:
	SaveManager.new_game(&"chtholly")
	SaveManager.close_game(false)
	var state := GameState.to_dict()
	state["day"] = _day
	state["slot"] = "aube"
	state["moment"] = "aube"
	state["map"] = "entrepot_etage"
	state["position"] = [BEDROOM.x, BEDROOM.y, BEDROOM.z]
	var done: Array[String] = []
	for scene_id: StringName in StoryData.scene_ids(&"ile_68"):
		var head := String(scene_id).get_slice("_", 0).trim_prefix("j")
		if head.is_valid_int() and head.to_int() < _day:
			done.append(String(scene_id))
	state["scenes_done"] = done
	var calendar := {}
	for day: int in range(1, _day):
		calendar[str(day)] = ""
	state["calendar"] = calendar
	var flags := {}
	for flag: StringName in FLAGS:
		flags[String(flag)] = true
	state["flags"] = flags
	GameState.from_dict(state)
	EventBus.game_loaded.emit()


func _physics_process(delta: float) -> void:
	if _done or _player == null:
		return
	_elapsed += delta
	if _elapsed > 1500.0:
		print("S2 jour %d : arrêt après 1500 s (scène %s)" % [_day, StoryDirector.current_scene()])
		_finish()
		return
	_pilot_dialogue(delta)
	_pilot_games()
	if StoryDirector.is_playing() and not StoryDirector.current_scene().is_empty():
		_step_left -= delta
		if _step_left <= 0.0:
			_step_left = _step
			_save("%s_%03d" % [StoryDirector.current_scene(), _index])
			_index += 1
	if _over():
		_save("fin_%03d" % _index)
		_finish()
		return
	if not _acting:
		_pilot_story()


func _over() -> bool:
	if StoryDirector.is_playing() or WorldManager.is_transitioning():
		return false
	if GameState.day > _day:
		return true
	return _day == 12 and GameState.has_flag(&"acte1_fini") and not _player.is_story_held()


# --- Répliques -----------------------------------------------------------------------------------


func _pilot_dialogue(delta: float) -> void:
	if not _box.is_open():
		_read_left = READ_TIME
		return
	_box.complete_line()
	_read_left -= delta
	if _read_left > 0.0:
		return
	_read_left = READ_TIME
	if _box.is_choosing():
		_box.choose(0)
	elif _box.is_waiting():
		_box.advance()


# --- Jeux (vraies actions) -----------------------------------------------------------------------


func _press(action: StringName, pressed: bool) -> void:
	if pressed == _held.has(action):
		return
	if pressed:
		_held[action] = true
		Input.action_press(action)
	else:
		_held.erase(action)
		Input.action_release(action)


func _tap(action: StringName) -> void:
	_press(action, false)
	_press(action, true)
	get_tree().create_timer(0.05, true, true).timeout.connect(_press.bind(action, false))


func _walk(toward: Vector3) -> void:
	var flat := Vector2(toward.x, toward.z)
	var go := flat.length() > 0.2
	_press(&"move_right", go and toward.x > 0.25)
	_press(&"move_left", go and toward.x < -0.25)
	_press(&"move_back", go and toward.z > 0.25)
	_press(&"move_forward", go and toward.z < -0.25)


func _pilot_games() -> void:
	var staff := MiniGames.staff_training()
	if staff != null and staff.is_running():
		_drive_staff(staff)
		return
	var training := MiniGames.seniorious_training()
	if training != null and training.is_running():
		_drive_seniorious(training)
		return
	var ambush := MiniGames.ambush()
	if ambush != null and ambush.is_running():
		_drive_ambush(ambush)
		return
	if not _held.is_empty():
		for action: StringName in _held.keys():
			_press(action, false)
		_plan.clear()


func _drive_staff(staff: StaffTraining) -> void:
	var blow := staff.current_blow()
	var now := staff.game_time()
	var on_me := false
	if not blow.is_empty():
		var target: Vector3 = blow["target"]
		on_me = (
			(
				Vector2(target.x - _player.global_position.x, target.z - _player.global_position.z)
				. length()
			)
			< 0.9
		)
	var guard := (
		on_me and now >= float(blow["impact"]) - 0.42 and now < float(blow["impact"]) - 0.07
	)
	_press(&"charge", guard)
	if staff.phase == &"b" and not guard:
		var willem := LifeDirector.actor(&"willem")
		if willem != null:
			var gap := willem.position() - _player.global_position
			gap.y = 0.0
			_walk(gap if gap.length() > 1.3 else Vector3.ZERO)
			if gap.length() <= 1.4 and staff.open_until > now:
				_tap(&"attack")
	else:
		_walk(Vector3.ZERO)


func _drive_seniorious(training: SenioriousTraining) -> void:
	var now := training.game_time()
	match training.stage:
		&"breath":
			var start := training.breath_end() - 4.0
			_press(&"charge", now >= start and now < training.breath_end() - 0.05)
		&"moves":
			var gesture := training.current_gesture()
			if gesture.is_empty() or now < float(gesture["start"]) + 0.25:
				_press(&"move_back", false)
				return
			var last := float(_plan.get("tap_at", -9.0))
			match gesture["gesture"]:
				&"trois_coups":
					if now - last > 0.25:
						_plan["tap_at"] = now
						_tap(&"attack")
				&"pare":
					if last < float(gesture["start"]):
						_plan["tap_at"] = now
						_tap(&"charge")
				&"cote":
					_press(&"move_back", true)
		&"crane":
			_press(&"move_back", false)
			var fend := training.current_fend()
			if fend.is_empty() or bool(fend["struck"]):
				if not fend.is_empty() and bool(fend["perfect"]):
					if _held.has(&"charge"):
						_press(&"charge", false)
					elif not _plan.get("struck", false):
						_plan["struck"] = true
						_tap(&"attack")
				elif fend.is_empty():
					_plan.erase("struck")
					_press(&"charge", false)
				return
			if now >= float(fend["impact"]) - 0.1:
				_press(&"charge", true)
		&"pickup":
			var spot := training.sword_spot()
			if spot == Vector3.INF:
				return
			var gap := spot - _player.global_position
			gap.y = 0.0
			if gap.length() > 0.8:
				_walk(gap)
			else:
				_walk(Vector3.ZERO)
				if now - float(_plan.get("tap_at", -9.0)) > 0.6:
					_plan["tap_at"] = now
					_tap(&"interact")


func _drive_ambush(ambush: Ambush) -> void:
	var attack := ambush.current_attack()
	var kind: StringName = attack.get("kind", &"")
	_press(&"charge", kind == &"slash")
	if kind == &"leap":
		var target: Vector3 = attack["target"]
		var away := _player.global_position - target
		away.y = 0.0
		_walk(Vector3.FORWARD if away.length() < 1.4 else Vector3.ZERO)
	else:
		_walk(Vector3.ZERO)


# --- Le récit ------------------------------------------------------------------------------------


func _pilot_story() -> void:
	if WorldManager.is_transitioning() or _box.is_open() or _game_running():
		return
	var expected := StoryDirector.expected()
	if not expected.is_empty():
		_act(_satisfy(expected))
		return
	if StoryDirector.is_playing():
		return
	_act(_next_trigger())


func _game_running() -> bool:
	return (
		MiniGames.staff_training() != null
		or MiniGames.seniorious_training() != null
		or MiniGames.ambush() != null
	)


func _act(action: Callable) -> void:
	if not action.is_valid():
		return
	_acting = true
	await action.call()
	await get_tree().create_timer(0.5).timeout
	_acting = false


func _satisfy(step: Dictionary) -> Callable:
	if step.has("reach"):
		if step.has("map") and StringName(str(step["map"])) != WorldManager.current_map():
			return _go.bind(StringName(str(step["map"])))
		return _teleport.bind(step["reach"], float(step.get("radius", 1.0)))
	if step.has("map"):
		return _go.bind(StringName(str(step["map"])))
	return Callable()


## Ce qui déclenche la scène suivante du jour (la première qui n'est pas jouée).
func _next_trigger() -> Callable:
	if GameState.day > _day:
		return Callable()
	for scene_id: StringName in StoryData.scene_ids(&"ile_68"):
		if GameState.is_scene_done(scene_id):
			continue
		var data := StoryData.scene(&"ile_68", scene_id)
		if int(DialogueRunner.day_range(data.get("day", 0)).x) != _day:
			continue
		if not _after_done(data):
			continue
		if data.get("key", true) == false and scene_id != &"j10_3_linge":
			if not scene_id.begins_with("j12_1"):
				continue
		return _trigger.bind(scene_id, data)
	return _sleep


func _after_done(data: Dictionary) -> bool:
	for scene_id: Variant in data.get("after", []):
		if not GameState.is_scene_done(StringName(str(scene_id))):
			return false
	if data.has("if"):
		return DialogueRunner.evaluate(data["if"])
	return true


func _trigger(scene_id: StringName, data: Dictionary) -> void:
	var slots: Array = data.get("slot", []) if data.get("slot") is Array else [data.get("slot", "")]
	while (
		not slots.is_empty()
		and str(slots[0]) != ""
		and not slots.has(String(LifeSlots.current()))
		and StoryDirector.can_rest()
	):
		await StoryDirector.pass_time()
	var map_id := StringName(str(data.get("map", "")))
	var trigger: Dictionary = data.get("trigger", {})
	if WorldManager.current_map() != map_id:
		var marker := StringName(str(trigger.get("marker", "")))
		await _go(map_id, marker)
		await get_tree().create_timer(0.4).timeout
		if StoryDirector.is_playing():
			return
	match str(trigger.get("on", "")):
		"reach":
			await _teleport(trigger["point"], float(trigger.get("radius", 2.5)))
		"prompt":
			StoryDirector.play(scene_id)
		"enter":
			await _go(&"entrepot_rdc" if map_id == &"entrepot" else &"village")
			await _go(map_id, StringName(str(trigger.get("marker", ""))))


func _go(map_id: StringName, marker: StringName = &"") -> void:
	var from := WorldManager.current_map()
	var arrival := marker if not marker.is_empty() else StringName("from_" + String(from))
	if (
		WorldManager.current_map_node() != null
		and WorldManager.current_map_node().marker(arrival) == null
	):
		arrival = &"Spawn"
	await WorldManager.go_to(map_id, arrival)


func _teleport(spec: Variant, radius: float = 0.0) -> void:
	var at := StoryDirector.stage().resolve(spec).origin
	StoryDirector.stage().place_player(at + Vector3(0.0, 0.0, clampf(radius - 0.6, 0.0, 2.0)))
	await get_tree().physics_frame


func _sleep() -> void:
	if WorldManager.current_map() != &"entrepot_etage":
		await WorldManager.go_to(&"entrepot_etage", &"Spawn")
	while not StoryDirector.can_sleep() and StoryDirector.can_rest():
		await StoryDirector.pass_time()
	await _teleport(&"chtholly_porte")
	await StoryDirector.sleep()


func _finish() -> void:
	_done = true
	await get_tree().create_timer(0.4).timeout
	get_tree().quit()


func _save(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var dir := _shots if _shots.begins_with("/") else ProjectSettings.globalize_path(_shots)
	DirAccess.make_dir_recursive_absolute(dir)
	var image := get_viewport().get_texture().get_image()
	image.resize(image.get_width() >> 1, image.get_height() >> 1, Image.INTERPOLATE_BILINEAR)
	image.save_png(dir.path_join(file_name + ".png"))
	print(
		(
			"S2 image %s : %d draw calls ; carte %s, étape %s, jour %d, créneau %s"
			% [
				file_name,
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
				WorldManager.current_map(),
				StoryDirector.runner().current_step(),
				GameState.day,
				LifeSlots.current(),
			]
		)
	)
