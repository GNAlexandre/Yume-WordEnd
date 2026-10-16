extends Node
## (S2) Démo des scènes des jours 5 et 6 : la vraie partie (game.tscn) reprise au réveil du jour,
## menée par un pilote automatique (répliques lues, choix par défaut ou choisis, déclencheurs
## atteints par une pose) ; une image toutes les S2_STEP s (0,5 par défaut) tant qu'une scène
## joue (et quelques secondes après).
##
## Lancement (les PNG sont écrits par la démo, qui quitte d'elle-même) :
##   S2_DAY=5 S2_SHOTS=build/s2/jour5 xvfb-run -a -s "-screen 0 1280x720x24" \
##     tools/godot --rendering-driver opengl3 --resolution 1280x720 \
##     res://tests/integration/demo_s2.tscn
## S2_DAY : 5 ou 6 ; S2_STEP : le pas des images (s). S2_CHOICE=autre prend le second choix de
## chaque dialogue (« Une autre fois. » au jour 5 ; la clé de bras et rester à la porte au jour 6),
## sinon le premier (« J'arrive. » ; « Lâchez-le. » et s'asseoir sur le tapis). Le journal donne les
## draw calls de chaque image.

const GAME_SCENE := preload("res://src/game.tscn")
const SEEN := "user://demo_s2_seen.cfg"
const READ_TIME := 0.8
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
var _read_left := READ_TIME
var _elapsed := 0.0
var _shot_left := 0.0
var _index := 0
var _acting := false
var _done := false
var _tail := 0.0
var _previous_seen := ""
var _stage := 0


func _ready() -> void:
	_day = int(OS.get_environment("S2_DAY")) if OS.get_environment("S2_DAY").is_valid_int() else 5
	_shots = OS.get_environment("S2_SHOTS")
	if _shots.is_empty():
		_shots = "res://build/s2/jour%d" % _day
	if OS.get_environment("S2_STEP").is_valid_float():
		_step = float(OS.get_environment("S2_STEP"))
	_variant = OS.get_environment("S2_CHOICE")
	_previous_seen = StoryDirector.seen_path
	StoryDirector.seen_path = SEEN
	StoryDirector.forget_seen()
	WorldManager.fade_time = 0.2
	_resume()
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
	Input.action_release(&"move_forward")


func _resume() -> void:
	SaveManager.new_game(&"chtholly")
	SaveManager.close_game(false)
	var state := GameState.to_dict()
	state["day"] = _day
	state["slot"] = "aube"
	state["moment"] = "aube"
	state["map"] = "entrepot_etage"
	state["position"] = [6.2, 0.0, 7.4]
	var done: Array[String] = []
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
		_box.choose(_choice_index())
	elif _box.is_waiting():
		_box.advance()


## L'index du choix : le premier par défaut ; S2_CHOICE=autre prend le second.
func _choice_index() -> int:
	return 1 if _variant == "autre" else 0


func _shown_text() -> String:
	var label := _box.get_node_or_null("%Text") as Label
	return label.text if label != null and _box.is_open() else ""


func _finish() -> void:
	_done = true
	await get_tree().create_timer(0.3).timeout
	get_tree().quit()


func _save(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var dir := _shots if _shots.begins_with("/") else ProjectSettings.globalize_path(_shots)
	DirAccess.make_dir_recursive_absolute(dir)
	get_viewport().get_texture().get_image().save_png(dir.path_join(file_name + ".png"))
	print(
		(
			"S2 image %s : %d draw calls ; carte %s, scène %s, jour %d, créneau %s"
			% [
				file_name,
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
				WorldManager.current_map(),
				StoryDirector.current_scene(),
				GameState.day,
				LifeSlots.current(),
			]
		)
	)


# --- Pilote ---------------------------------------------------------------------------------------


func _pilot() -> void:
	if WorldManager.is_transitioning() or _box.is_open() or StoryDirector.is_playing():
		return
	if _player.is_story_held():
		return
	_act(_day_5 if _day == 5 else _day_6)


func _act(action: Callable) -> void:
	_acting = true
	await action.call()
	await get_tree().create_timer(0.5).timeout
	_acting = false


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
