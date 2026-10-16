extends Node
## (S2) Démo des scènes de l'acte 1, jours 5, 6 et 9 à 12 : la vraie partie (game.tscn) reprise au
## réveil du jour, menée par un pilote automatique (répliques lues, choix par défaut ou choisis) ;
## une image toutes les S2_STEP s (0,5 par défaut) tant qu'une scène joue.
## - Jours 5 et 6 : un pilote écrit pas à pas (déclencheurs atteints par une pose), des images
##   pendant les scènes et quelques secondes après.
## - Jours 9 à 12 : un pilote générique (ce qu'attend une scène fait d'un coup ; entre deux scènes,
##   ce qui déclenche la suivante ; les jeux joués par de vraies actions), des images pendant les
##   scènes seulement, réduites de moitié ; la démo s'arrête au jour suivant ou à la fin de l'acte.
##
## Lancement (les PNG sont écrits par la démo, qui quitte d'elle-même) :
##   S2_DAY=5 S2_SHOTS=build/s2/jour5 xvfb-run -a -s "-screen 0 1280x720x24" \
##     tools/godot --rendering-driver opengl3 --resolution 1280x720 \
##     res://tests/integration/demo_s2.tscn
## S2_DAY : 5, 6, 9, 10, 11 ou 12 ; S2_STEP : le pas des images (s). S2_CHOICE=autre prend le
## second choix de chaque dialogue des jours 5 et 6 (« Une autre fois. » au jour 5 ; la clé de
## bras et rester à la porte au jour 6), sinon le premier (« J'arrive. » ; « Lâchez-le. » et
## s'asseoir sur le tapis) ; des jours 9 à 12, toujours le premier. Le journal donne les draw
## calls de chaque image (« S2 image … »).

const GAME_SCENE := preload("res://src/game.tscn")
const SEEN := "user://demo_s2_seen.cfg"
const READ_TIME := 0.8
## Des jours 9 à 12, les répliques restent plus longtemps (une image toutes les 0,5 s les montre).
const LATE_READ_TIME := 1.4
## Le premier jour mené par le pilote générique.
const LATE_DAY := 9
## Où l'on se réveille, des jours 9 à 12 (près du lit de la chambre de la protagoniste).
const BEDROOM := Vector3(6.2, 0.0, 6.4)
## Drapeaux posés au réveil des jours 9 à 12 (la réussite du jour 9 change le jour 11).
const LATE_FLAGS := [&"j9_baton_reussi"]
const DAY_1_TO_4: Array[StringName] = [
	&"j1_1_port",
	&"j1_2_lumiere",
	&"j1_2_embuscade",
	&"j1_3_intrus",
	&"j1_4_chemin",
	&"j1_5_premiers_pas",
	&"j1_6_diner",
	&"j1_7_chambre",
	&"j2_1_matin",
	&"j2_2_fuite",
	&"j2_3_fenetre",
	&"j3_1_information",
	&"j3_2_chemin",
	&"j3_3_snack",
	&"j4_1_cuisine",
	&"j4_2_diner",
]
const DAY_5: Array[StringName] = [&"j5_1_jeu_willem", &"j5_2_fenetre"]

var _day := 5
var _shots := ""
var _step := 0.5
var _variant := ""
var _game: Node3D
var _player: Player
var _box: DialogueBox
var _read_time := READ_TIME
var _read_left := READ_TIME
var _elapsed := 0.0
var _shot_left := 0.0
var _index := 0
var _acting := false
var _done := false
var _tail := 0.0
var _previous_seen := ""
var _stage := 0
var _held: Dictionary = {}
var _plan: Dictionary = {}


func _ready() -> void:
	_day = int(OS.get_environment("S2_DAY")) if OS.get_environment("S2_DAY").is_valid_int() else 5
	_shots = OS.get_environment("S2_SHOTS")
	if _shots.is_empty():
		_shots = "res://build/s2/jour%d" % _day
	if OS.get_environment("S2_STEP").is_valid_float():
		_step = float(OS.get_environment("S2_STEP"))
	_variant = OS.get_environment("S2_CHOICE")
	_read_time = LATE_READ_TIME if _late() else READ_TIME
	_read_left = _read_time
	_previous_seen = StoryDirector.seen_path
	StoryDirector.seen_path = SEEN
	StoryDirector.forget_seen()
	WorldManager.fade_time = 0.3 if _late() else 0.2
	_resume()
	process_mode = Node.PROCESS_MODE_ALWAYS
	_game = GAME_SCENE.instantiate() as Node3D
	_game.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_game)
	_player = _game.get_node(^"Player") as Player
	_box = _game.get_node(^"UI/DialogueBox") as DialogueBox


func _exit_tree() -> void:
	for action: StringName in _held.keys():
		Input.action_release(action)
	_held.clear()
	StoryDirector.forget_seen()
	StoryDirector.seen_path = _previous_seen
	WorldManager.fade_time = WorldManager.DEFAULT_FADE_TIME
	Input.action_release(&"move_forward")


## Les jours 9 à 12 (pilote générique).
func _late() -> bool:
	return _day >= LATE_DAY


func _resume() -> void:
	SaveManager.new_game(&"chtholly")
	SaveManager.close_game(false)
	var state := GameState.to_dict()
	state["day"] = _day
	state["slot"] = "aube"
	state["moment"] = "aube"
	state["map"] = "entrepot_etage"
	var wake := BEDROOM if _late() else Vector3(6.2, 0.0, 7.4)
	state["position"] = [wake.x, wake.y, wake.z]
	var done: Array[String] = []
	if _late():
		# Toutes les scènes des jours d'avant.
		for scene_id: StringName in StoryData.scene_ids(&"ile_68"):
			var head := String(scene_id).get_slice("_", 0).trim_prefix("j")
			if head.is_valid_int() and head.to_int() < _day:
				done.append(String(scene_id))
		var flags: Dictionary = state["flags"]
		for flag: StringName in LATE_FLAGS:
			flags[String(flag)] = true
	else:
		for id: StringName in DAY_1_TO_4:
			done.append(String(id))
		if _day >= 6:
			for id: StringName in DAY_5:
				done.append(String(id))
	state["scenes_done"] = done
	var calendar := {}
	for day: int in range(1, _day):
		calendar[str(day)] = ""
	state["calendar"] = calendar
	GameState.from_dict(state)
	EventBus.game_loaded.emit()


func _physics_process(delta: float) -> void:
	if _done or _player == null:
		return
	if _late():
		_late_process(delta)
		return
	_elapsed += delta
	if get_tree().paused:
		return
	if _elapsed > 1200.0:
		print("S2 : trop long, arrêt (scène %s)" % StoryDirector.current_scene())
		_finish()
		return
	_pilot_dialogue(delta)
	var playing := StoryDirector.is_playing() or _box.is_open()
	if playing:
		_tail = 2.5
	elif _tail > 0.0:
		_tail -= delta
	if playing or _tail > 0.0 or _always_shoot():
		_shot_left -= delta
		if _shot_left <= 0.0:
			_shot_left = _step
			_save("%03d_%s" % [_index, StoryDirector.current_scene()])
			_index += 1
	if not _acting:
		_pilot()


func _always_shoot() -> bool:
	return false


## Lit la réplique : elle s'écrit d'abord un peu (comme pour un joueur qui lit), puis paraît en
## entier ; au bout du temps de lecture, la suivante ou le choix.
func _pilot_dialogue(delta: float) -> void:
	if not _box.is_open():
		_read_left = _read_time
		return
	_read_left -= delta
	if _read_left < _read_time - 0.6:
		_box.complete_line()
	if _read_left > 0.0:
		return
	_read_left = _read_time
	if _box.is_choosing():
		_box.choose(_choice_index())
	elif _box.is_waiting():
		_box.advance()


## L'index du choix : le premier par défaut ; S2_CHOICE=autre prend le second (jours 5 et 6).
func _choice_index() -> int:
	return 1 if _variant == "autre" and not _late() else 0


func _shown_text() -> String:
	var label := _box.get_node_or_null("%Text") as Label
	return label.text if label != null and _box.is_open() else ""


func _finish() -> void:
	_done = true
	await get_tree().create_timer(0.4).timeout
	get_tree().quit()


func _save(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var dir := _shots if _shots.begins_with("/") else ProjectSettings.globalize_path(_shots)
	DirAccess.make_dir_recursive_absolute(dir)
	var image := get_viewport().get_texture().get_image()
	if _late():
		image.resize(image.get_width() >> 1, image.get_height() >> 1, Image.INTERPOLATE_BILINEAR)
	image.save_png(dir.path_join(file_name + ".png"))
	print(
		(
			"S2 image %s : %d draw calls ; carte %s, scène %s (%s), jour %d, créneau %s"
			% [
				file_name,
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
				WorldManager.current_map(),
				StoryDirector.current_scene(),
				StoryDirector.runner().current_step(),
				GameState.day,
				LifeSlots.current(),
			]
		)
	)


func _act(action: Callable) -> void:
	if not action.is_valid():
		return
	_acting = true
	print(
		(
			"S2 pilote : %s %s (carte %s)"
			% [action.get_method(), action.get_bound_arguments(), WorldManager.current_map()]
		)
	)
	await action.call()
	await get_tree().create_timer(0.5).timeout
	_acting = false


## Va sur map_id, arrivé par marker (sinon par « from_<carte d'où l'on vient> »).
func _go(map_id: StringName, marker: StringName = &"") -> void:
	var from := WorldManager.current_map()
	var arrival := marker if not marker.is_empty() else StringName("from_" + String(from))
	await WorldManager.go_to(map_id, arrival)


func _teleport(spec: Variant, back: float = 0.0, side: float = 0.0) -> void:
	var at := StoryDirector.stage().resolve(spec).origin
	StoryDirector.stage().place_player(at + Vector3(side, 0.0, back))
	await get_tree().physics_frame


func _pass_to(slot: StringName) -> void:
	while LifeSlots.current() != slot and StoryDirector.can_rest():
		await StoryDirector.pass_time()


func _sleep() -> void:
	if WorldManager.current_map() != &"entrepot_etage":
		await _go(&"entrepot_etage", &"Spawn")
	if _late():
		while not StoryDirector.can_sleep() and StoryDirector.can_rest():
			await StoryDirector.pass_time()
	else:
		await _pass_to(&"nuit")
	await _teleport(&"chtholly_porte")
	await StoryDirector.sleep()


# --- Pilote des jours 5 et 6 ----------------------------------------------------------------------


func _pilot() -> void:
	if WorldManager.is_transitioning() or _box.is_open() or StoryDirector.is_playing():
		return
	if _player.is_story_held():
		return
	_act(_day_5 if _day == 5 else _day_6)


func _day_5() -> void:
	match _stage:
		0:
			# Jusqu'à midi, puis le champ : 14 m du centre.
			await _pass_to(&"midi")
			await _go(&"entrepot", &"from_entrepot_rdc")
			await _teleport(&"champ_centre", 0.0, -14.0)
			_stage = 1
		1:
			if GameState.is_scene_done(&"j5_1_jeu_willem"):
				# La partie de ballon (vie) commence : quelques images.
				_stage = 2
				await get_tree().create_timer(9.0).timeout
				_save("ballon_%03d" % _index)
				_index += 1
		2:
			# La salle de lecture : la banquette (l'invite est remplacée par un lancement direct).
			await _go(&"entrepot_rdc", &"from_entrepot")
			await _teleport(&"lecture_banquette", 1.0)
			_stage = 3
			StoryDirector.play(&"j5_2_fenetre")
		3:
			if GameState.is_scene_done(&"j5_2_fenetre"):
				_stage = 4
		4:
			# Le champ (le choix « J'arrive. » y a mené ; « Une autre fois. » : on y va).
			if WorldManager.current_map() != &"entrepot":
				await _go(&"entrepot", &"from_entrepot_rdc")
				await _teleport(&"champ_entree")
			_stage = 5
			await get_tree().create_timer(8.0).timeout
		5:
			# Dans le champ : le joueur joue quelques secondes.
			await _teleport(&"champ_centre", 0.0, -5.5)
			_stage = 6
			await get_tree().create_timer(8.0).timeout
		6:
			_save("jeu_%03d" % _index)
			_index += 1
			await _sleep()
			_stage = 7
		_:
			_finish()


func _day_6() -> void:
	match _stage:
		0:
			await _pass_to(&"matin")
			await _go(&"entrepot_rdc", &"from_entrepot_etage")
			await _teleport(&"couloir_centre", 0.0, 4.2)
			_stage = 1
		1:
			if GameState.is_scene_done(&"j6_1_soif_de_sang"):
				_stage = 2
		2:
			await _pass_to(&"apres_midi")
			await _go(&"entrepot_rdc", &"from_entrepot_etage")
			await _teleport(&"jeux_tapis", -3.2)
			_stage = 3
		3:
			if GameState.is_scene_done(&"j6_2_livre_images"):
				_stage = 4
		4:
			await _pass_to(&"soir")
			if WorldManager.current_map() != &"entrepot_rdc":
				await _go(&"entrepot_rdc", &"from_entrepot_etage")
			await _teleport(&"refectoire_allee")
			_stage = 5
		5:
			if GameState.is_scene_done(&"j6_3_ordre_mission"):
				_stage = 6
		6:
			if WorldManager.current_map() != &"entrepot_etage":
				await _go(&"entrepot_etage", &"from_entrepot_rdc")
			await _teleport(&"grande_soeur_bureau", 0.4)
			_stage = 7
			StoryDirector.play(&"j6_4_souvenir")
		7:
			if GameState.is_scene_done(&"j6_4_souvenir"):
				_stage = 8
		8:
			await _sleep()
			_stage = 9
		_:
			_finish()


# --- Pilote générique des jours 9 à 12 ------------------------------------------------------------


func _late_process(delta: float) -> void:
	_elapsed += delta
	if _elapsed > 1500.0:
		print("S2 jour %d : arrêt après 1500 s (scène %s)" % [_day, StoryDirector.current_scene()])
		_finish()
		return
	_pilot_dialogue(delta)
	_pilot_games()
	if StoryDirector.is_playing() and not StoryDirector.current_scene().is_empty():
		_shot_left -= delta
		if _shot_left <= 0.0:
			_shot_left = _step
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


## Les jeux des scènes, joués par de vraies actions.
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


func _satisfy(step: Dictionary) -> Callable:
	if step.has("reach"):
		if step.has("map") and StringName(str(step["map"])) != WorldManager.current_map():
			return _go.bind(StringName(str(step["map"])))
		return _teleport_near.bind(step["reach"], float(step.get("radius", 1.0)))
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
		var marker := StringName(str(trigger.get("marker", "Spawn")))
		await _go(map_id, marker)
		await get_tree().create_timer(0.4).timeout
		if StoryDirector.is_playing():
			return
	match str(trigger.get("on", "")):
		"reach":
			await _teleport_near(trigger["point"], float(trigger.get("radius", 2.5)))
		"prompt":
			StoryDirector.play(scene_id)
		"enter":
			await _go(map_id, StringName(str(trigger.get("marker", "Spawn"))))


## Pose le joueur dans le rayon d'un point (un peu au sud, pour ne pas le cacher).
func _teleport_near(spec: Variant, radius: float = 0.0) -> void:
	await _teleport(spec, clampf(radius - 0.6, 0.0, 0.8))
