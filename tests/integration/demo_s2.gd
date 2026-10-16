extends Node
## (S2) Démo des jours 5 à 8 de l'acte 1 (lots S2a et S2b) : la vraie partie (game.tscn) reprise au
## début du jour, menée par un pilote (répliques lues, choix S2_CHOICE ; jours 5 et 6 : les
## déclencheurs atteints par une pose, le temps passé, le coucher ; jours 7 et 8 : ce qu'attend une
## scène fait à pied par les actions de déplacement, ce qui déclenche la scène suivante) ; une image
## toutes les S2_STEP s (0,5 par défaut) tant qu'une scène joue (et 2,5 s après), jusqu'au jour
## suivant.
##
## Lancement (sous Xvfb ; la démo quitte d'elle-même) :
##   S2_DAY=7 S2_SHOTS=build/s2/shots/j7 xvfb-run -a -s "-screen 0 1280x720x24" \
##     tools/godot --rendering-driver opengl3 --resolution 1280x720 \
##     res://tests/integration/demo_s2.tscn
## S2_CHOICE=1 (ou « autre ») : le second choix partout (jour 5 : « Une autre fois. » ; jour 6 : la
## clé de bras et rester à la porte) ; S2_ONLY=<scène> : n'enregistre que cette scène ;
## S2_START=<scène> : reprise juste avant elle ; S2_UNTIL=<scène> : fin quand elle est jouée.
## Index des images : <dossier>/index.tsv (fichier, scène, étape, draw calls). Le journal donne
## « S2 … » à chaque scène et à la fin.

const GAME_SCENE := preload("res://src/game.tscn")
const SEEN := "user://demo_s2_seen.cfg"
const READ_TIME := 1.1
## Temps donné à pied pour atteindre ce qu'attend une scène, avant de poser le joueur (s).
const WALK_GIVE_UP := 9.0
## Images avant de lancer la partie.
const BOOT_FRAMES := 6
## Où reprendre sur la carte d'une scène (S2_START) : son arrivée.
const START_POINTS := {
	"entrepot": Vector3(42.0, 0.0, 33.0),
	"entrepot_rdc": Vector3(13.0, 0.0, 12.8),
	"entrepot_etage": Vector3(19.4, 0.0, 9.5),
	"port": Vector3(4.0, 0.0, 17.0),
	"colline": Vector3(20.0, 0.0, 36.5),
	"barocupot": Vector3(4.5, 0.0, 6.0),
}

var _day := 7
var _shots := ""
var _step := 0.5
var _choice := 0
var _only := ""
var _start := ""
var _until := ""
var _game: Node3D
var _player: Player
var _box: DialogueBox
var _read_left := READ_TIME
var _acting := false
var _done := false
var _step_left := 0.0
var _index := 0
var _elapsed := 0.0
var _walk_time := 0.0
var _last_scene := &""
var _previous_seen := ""
## (X-L0) Mode de jeu par défaut avant la démo (elle joue le mode scénarisé).
var _previous_mode: StringName = &""
var _index_lines: PackedStringArray = []
var _duel_phase := &""
var _duel_since := 0.0
var _boot_frames := 0
## Jours 5 et 6 : l'étape du pilote ; images après la fin d'une scène (s).
var _stage := 0
var _tail := 0.0


func _ready() -> void:
	_day = int(OS.get_environment("S2_DAY")) if OS.get_environment("S2_DAY").is_valid_int() else 7
	_shots = OS.get_environment("S2_SHOTS")
	if _shots.is_empty():
		_shots = "res://build/s2/shots/j%d" % _day
	if OS.get_environment("S2_STEP").is_valid_float():
		_step = float(OS.get_environment("S2_STEP"))
	if OS.get_environment("S2_CHOICE").is_valid_int():
		_choice = int(OS.get_environment("S2_CHOICE"))
	elif OS.get_environment("S2_CHOICE") == "autre":
		_choice = 1
	_only = OS.get_environment("S2_ONLY")
	_start = OS.get_environment("S2_START")
	_until = OS.get_environment("S2_UNTIL")
	if not _start.is_empty():
		_day = _start.get_slice("_", 0).trim_prefix("j").to_int()
	# (X-L0) Le mode scénarisé d'E6 et de S2 (le jeu part en libre).
	_previous_mode = StoryDirector.default_mode
	StoryDirector.default_mode = StoryPacing.SCENARIO
	_previous_seen = StoryDirector.seen_path
	StoryDirector.seen_path = SEEN
	StoryDirector.forget_seen()
	WorldManager.fade_time = 0.2
	process_mode = Node.PROCESS_MODE_ALWAYS


## La partie démarre quelques images après l'arrivée de la démo : la fumée (tools/smoke.gd), qui
## libère chaque scène au bout de deux images, ne la lance jamais (un changement de carte en
## cours, libéré avec elle, laissait une erreur de WorldManager).
func _start_game() -> void:
	_resume()
	_game = GAME_SCENE.instantiate() as Node3D
	_game.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_game)
	_player = _game.get_node(^"Player") as Player
	_box = _game.get_node(^"UI/DialogueBox") as DialogueBox


func _exit_tree() -> void:
	_release_moves()
	StoryDirector.forget_seen()
	StoryDirector.seen_path = _previous_seen
	if not _previous_mode.is_empty():
		StoryDirector.default_mode = _previous_mode
	WorldManager.fade_time = WorldManager.DEFAULT_FADE_TIME


## Partie reprise au début du jour : les scènes des jours d'avant jouées, le calendrier écrit.
func _resume() -> void:
	SaveManager.new_game(&"chtholly")
	SaveManager.close_game(false)
	var state := GameState.to_dict()
	state["day"] = _day
	state["slot"] = "aube"
	state["moment"] = "aube"
	var done: Array[String] = []
	for scene_id: StringName in StoryData.scene_ids(&"ile_68"):
		var prefix := String(scene_id).get_slice("_", 0)
		if prefix.begins_with("j") and prefix.trim_prefix("j").to_int() < _day:
			done.append(String(scene_id))
	state["scenes_done"] = done
	var calendar := {}
	for day: int in range(1, _day):
		calendar[str(day)] = ""
	state["calendar"] = calendar
	if _day == 8:
		state["map"] = "entrepot_rdc"
		state["position"] = [26.6, 0.0, 12.6]
	else:
		state["map"] = "entrepot_etage"
		state["position"] = [6.2, 0.0, 7.4]
	if not _start.is_empty():
		_start_at(state)
	GameState.from_dict(state)
	EventBus.game_loaded.emit()


## S2_START=<scène> : la partie reprise juste avant cette scène (les scènes d'avant jouées), sur
## sa carte, au créneau qu'elle demande.
func _start_at(state: Dictionary) -> void:
	var done: Array[String] = []
	for scene_id: StringName in StoryData.scene_ids(&"ile_68"):
		if String(scene_id) < _start:
			done.append(String(scene_id))
	state["scenes_done"] = done
	var data := StoryData.scene(&"ile_68", StringName(_start))
	var map_id := str(data.get("map", "entrepot"))
	state["map"] = map_id
	var at: Vector3 = START_POINTS.get(map_id, Vector3.ZERO)
	state["position"] = [at.x, at.y, at.z]
	var slots: Variant = data.get("slot", "aube")
	var wanted := str(slots[0] if slots is Array else slots)
	state["slot"] = wanted
	state["moment"] = String(LifeSlots.moment_of(StringName(wanted)))


func _physics_process(delta: float) -> void:
	if _game == null:
		_boot_frames += 1
		if _boot_frames == BOOT_FRAMES:
			_start_game()
		return
	if _done or _player == null:
		return
	_elapsed += delta
	var scene := StoryDirector.current_scene()
	if scene != _last_scene and not scene.is_empty():
		_last_scene = scene
		print("S2 scène %s (%.1f s)" % [scene, _elapsed])
	if _elapsed > 1500.0:
		print("S2 fin : temps écoulé (scène %s)" % scene)
		_finish()
		return
	if StoryDirector.is_playing() or _box.is_open():
		_tail = 2.5
	elif _tail > 0.0:
		_tail -= delta
	_step_left -= delta
	if _step_left <= 0.0:
		_step_left = _step
		if _recording():
			_save()
	if _ended():
		_finish()
		return
	if get_tree().paused:
		return
	_pilot_dialogue(delta)
	_pilot_duel()
	if _acting:
		return
	if _day <= 6:
		_pilot_days_5_6()
	else:
		_pilot_story(delta)


## Vrai quand la démo a fini : S2_UNTIL jouée, ou le jour suivant commencé.
func _ended() -> bool:
	if not _until.is_empty() and GameState.is_scene_done(StringName(_until)):
		print("S2 fin : %s jouée, %d images" % [_until, _index])
		return true
	if GameState.day > _day and not StoryDirector.is_playing():
		print("S2 fin : jour %d, %d images" % [GameState.day, _index])
		return true
	return false


func _recording() -> bool:
	if not StoryDirector.is_playing() and not _player.is_story_held() and _tail <= 0.0:
		return false
	return _only.is_empty() or String(StoryDirector.current_scene()) == _only


## Les répliques : lues READ_TIME s, puis la suite ou le choix S2_CHOICE.
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
		_box.choose(_choice)
	elif _box.is_waiting():
		_box.advance()


## Le duel : une frappe par seconde (il esquive), la charge tenue 2,2 s, puis une frappe.
func _pilot_duel() -> void:
	var duel := MiniGames.duel()
	if duel == null or not duel.is_running():
		Input.action_release(&"charge")
		return
	var phase := duel.phase
	if phase != _duel_phase:
		_duel_phase = phase
		_duel_since = _elapsed
	var in_phase := _elapsed - _duel_since
	if phase == &"dodge" and int(_elapsed * 2.0) % 2 == 0 and in_phase < 6.0:
		Input.action_press(&"attack")
	elif phase in [&"dodge", &"ready"] and in_phase >= 6.0:
		Input.action_press(&"charge")
	elif phase == &"vision":
		Input.action_release(&"charge")
		Input.action_press(&"attack")
	else:
		Input.action_release(&"attack")
	if Input.is_action_pressed(&"attack") and Engine.get_physics_frames() % 6 == 0:
		Input.action_release(&"attack")


func _pilot_story(delta: float) -> void:
	if WorldManager.is_transitioning() or _box.is_open():
		_release_moves()
		return
	var expected := StoryDirector.expected()
	if not expected.is_empty():
		_satisfy(expected, delta)
		return
	_walk_time = 0.0
	_release_moves()
	if StoryDirector.is_playing():
		return
	_act(_next_trigger())


func _act(action: Callable) -> void:
	if not action.is_valid():
		return
	_acting = true
	await action.call()
	await get_tree().create_timer(0.6).timeout
	_acting = false


## Ce qu'attend la scène : une carte (le changement par sa sortie), un point (à pied par les
## actions de déplacement, posé au bout de WALK_GIVE_UP s).
func _satisfy(step: Dictionary, delta: float) -> void:
	if step.has("map") and StringName(str(step["map"])) != WorldManager.current_map():
		_release_moves()
		_act(_go.bind(StringName(str(step["map"]))))
		return
	if not step.has("reach"):
		return
	var target := StoryDirector.stage().resolve(step["reach"]).origin
	_walk_time += delta
	if _walk_time > WALK_GIVE_UP:
		_walk_time = 0.0
		_release_moves()
		StoryDirector.stage().place_player(target)
		return
	var toward := target - _player.global_position
	toward.y = 0.0
	_drive(toward.normalized() if toward.length() > 0.2 else Vector3.ZERO)


func _drive(direction: Vector3) -> void:
	var axes := {
		&"move_right": maxf(direction.x, 0.0),
		&"move_left": maxf(-direction.x, 0.0),
		&"move_back": maxf(direction.z, 0.0),
		&"move_forward": maxf(-direction.z, 0.0),
	}
	for action: StringName in axes:
		var strength: float = axes[action]
		if strength > 0.05:
			Input.action_press(action, strength)
		else:
			Input.action_release(action)


func _release_moves() -> void:
	for action: StringName in [&"move_right", &"move_left", &"move_back", &"move_forward"]:
		Input.action_release(action)
	Input.action_release(&"attack")


## Après une scène : ce qui déclenche la suivante.
func _next_trigger() -> Callable:
	var last := &""
	for scene_id: StringName in StoryData.scene_ids(&"ile_68"):
		if GameState.is_scene_done(scene_id):
			last = scene_id
	if GameState.day == 7 and not GameState.is_scene_done(&"j7_1_depart"):
		return _to.bind(&"entrepot", &"porte_seuil")
	var next := {
		&"j8_1_reveil": _to.bind(&"entrepot_rdc", &"archives_canape"),
		&"j8_2_archives": _to.bind(&"entrepot", &"cour_willem"),
		&"j8_5_refectoire": _fly,
	}
	return next.get(last, Callable())


func _go(map_id: StringName, marker: StringName = &"") -> void:
	var from := WorldManager.current_map()
	var arrival := marker if not marker.is_empty() else StringName("from_" + String(from))
	await WorldManager.go_to(map_id, arrival)


func _to(map_id: StringName, point: StringName) -> void:
	if WorldManager.current_map() != map_id:
		await _go(map_id)
	await get_tree().create_timer(0.4).timeout
	var at := StoryDirector.stage().resolve(point).origin
	StoryDirector.stage().place_player(at + Vector3(0.0, 0.0, 1.0))
	await get_tree().physics_frame


## La fugue : la colline, le bord, l'invite « S'envoler ».
func _fly() -> void:
	await _to(&"colline", &"vue_nord")
	await get_tree().create_timer(0.6).timeout
	for prompt: StoryPrompt in StoryDirector.prompts():
		if prompt.roles.has(StoryPrompt.ROLE_SCENE) and prompt.is_available():
			prompt.interact(_player)


func _finish() -> void:
	_done = true
	_release_moves()
	var dir := _shots if _shots.begins_with("/") else ProjectSettings.globalize_path(_shots)
	DirAccess.make_dir_recursive_absolute(dir)
	var file := FileAccess.open(dir.path_join("index.tsv"), FileAccess.WRITE)
	if file != null:
		file.store_string("\n".join(_index_lines) + "\n")
		file.close()
	await get_tree().create_timer(0.3).timeout
	get_tree().quit()


func _save() -> void:
	var file_name := "s2_%04d" % _index
	_index += 1
	var scene := StoryDirector.current_scene()
	var step := StoryDirector.runner().current_step()
	await RenderingServer.frame_post_draw
	var dir := _shots if _shots.begins_with("/") else ProjectSettings.globalize_path(_shots)
	DirAccess.make_dir_recursive_absolute(dir)
	get_viewport().get_texture().get_image().save_png(dir.path_join(file_name + ".png"))
	var calls := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	_index_lines.append("%s\t%s\t%s\t%d\t%.1f" % [file_name, scene, step, calls, _elapsed])


# --- Jours 5 et 6 (S2a) ---------------------------------------------------------------------------


func _pilot_days_5_6() -> void:
	if WorldManager.is_transitioning() or _box.is_open() or StoryDirector.is_playing():
		return
	if _player.is_story_held():
		return
	_act(_day_5 if _day == 5 else _day_6)


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
	await _pass_to(&"nuit")
	await _teleport(&"chtholly_porte")
	await StoryDirector.sleep()


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
				_save()
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
			_save()
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
