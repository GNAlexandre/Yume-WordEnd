extends Node
## (E6) Démo du récit : la vraie partie (game.tscn) et l'acte 1, mené par un pilote automatique
## (répliques lues, choix par défaut, ce qu'attend une scène fait d'un coup : poses, changements de
## carte, conversations ; entre deux scènes, ce qui déclenche la suivante ; le soir, « Dormir »).
##
## Lancement (le PNG est écrit par la démo, qui quitte d'elle-même) :
##   E6_VIEW=<vue> E6_SHOTS=build/e6/shots xvfb-run -a -s "-screen 0 1280x720x24" \
##     tools/godot --rendering-driver opengl3 --resolution 1280x720 res://tests/integration/demo_e6.tscn
## Vues (capture quand la réplique ou l'état est à l'écran) : carton (1.1), porche (1.2),
## indice (après 1.2), gros_plan (1.3), miroir (1.5), avalanche (1.5), chambre (1.7), sommeil (la
## ligne du calendrier), calendrier (jour 2), fuite (2.2), cuisine (4.1), diner (4.2) ; jour1 :
## une image toutes les E6_STEP s (3 par défaut) du début de la partie à l'aube du jour 2.
## Le journal donne les draw calls de chaque capture (« E6 vue … »).

const GAME_SCENE := preload("res://src/game.tscn")
const SEEN := "user://demo_e6_seen.cfg"
## Vue → réplique (morceau) qui déclenche la capture.
const LINES := {
	"porche": "Ramène-la-moi",
	"gros_plan": "L'accueil est toujours",
	"miroir": "Pas de cornes",
	"avalanche": "Au lit, toutes",
	"chambre": "Au lit. Tout de suite",
	"fuite": "Je sens encore le marais",
	"cuisine": "Tu goûtes le caramel",
	"diner": "Tu en referas demain",
}
## Vues qui partent d'une partie reprise (jour, créneau, carte, position, scènes jouées).
const RESUMES := {
	"calendrier": [2, &"aube", &"entrepot_etage", Vector3(6.2, 0.0, 7.4), 8],
	"fuite": [2, &"aube", &"entrepot_etage", Vector3(6.2, 0.0, 7.4), 8],
	"cuisine": [4, &"aube", &"entrepot_etage", Vector3(6.2, 0.0, 7.4), 14],
	"diner": [4, &"aube", &"entrepot_etage", Vector3(6.2, 0.0, 7.4), 14],
}
const ORDER: Array[StringName] = [
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
## Lecture d'une réplique (s) avant de passer.
const READ_TIME := 0.9

var _view := ""
var _shots := ""
var _game: Node3D
var _player: Player
var _box: DialogueBox
var _state: Dictionary = {}
var _read_left := READ_TIME
var _acting := false
var _done := false
var _step := 3.0
var _step_left := 1.0
var _index := 0
var _previous_seen := ""
var _hint_seen_at := -1.0
var _elapsed := 0.0


func _ready() -> void:
	_view = OS.get_environment("E6_VIEW")
	_shots = OS.get_environment("E6_SHOTS")
	if _shots.is_empty():
		_shots = "res://build/e6/shots"
	if OS.get_environment("E6_STEP").is_valid_float():
		_step = float(OS.get_environment("E6_STEP"))
	_state = GameState.to_dict()
	_previous_seen = StoryDirector.seen_path
	StoryDirector.seen_path = SEEN
	StoryDirector.forget_seen()
	WorldManager.fade_time = 0.2
	if RESUMES.has(_view):
		_resume(RESUMES[_view])
	else:
		SaveManager.new_game(&"chtholly")
		SaveManager.close_game(false)
	_game = GAME_SCENE.instantiate() as Node3D
	add_child(_game)
	_player = _game.get_node(^"Player") as Player
	_box = _game.get_node(^"UI/DialogueBox") as DialogueBox


func _exit_tree() -> void:
	StoryDirector.forget_seen()
	StoryDirector.seen_path = _previous_seen
	WorldManager.fade_time = WorldManager.DEFAULT_FADE_TIME


func _resume(setup: Array) -> void:
	SaveManager.new_game(&"chtholly")
	SaveManager.close_game(false)
	var state := GameState.to_dict()
	state["day"] = setup[0]
	state["slot"] = String(setup[1])
	state["moment"] = String(LifeSlots.moment_of(setup[1]))
	state["map"] = String(setup[2])
	var at: Vector3 = setup[3]
	state["position"] = [at.x, at.y, at.z]
	var done: Array[String] = []
	for index: int in int(setup[4]):
		done.append(String(ORDER[index]))
	state["scenes_done"] = done
	var calendar := {}
	for day: int in range(1, int(setup[0])):
		calendar[str(day)] = ""
	state["calendar"] = calendar
	GameState.from_dict(state)
	EventBus.game_loaded.emit()


func _physics_process(delta: float) -> void:
	if _done or _player == null:
		return
	_elapsed += delta
	if _elapsed > 900.0:
		print(
			(
				"E6 vue %s : rien à capturer après 900 s (scène %s)"
				% [_view, StoryDirector.current_scene()]
			)
		)
		_finish()
		return
	_pilot_dialogue(delta)
	if _view == "jour1":
		_step_left -= delta
		if _step_left <= 0.0:
			_step_left = _step
			_save("jour1_%03d" % _index)
			_index += 1
		if GameState.day >= 2 and not StoryDirector.is_playing() and not _player.is_story_held():
			_save("jour1_%03d" % _index)
			_finish()
			return
	if _check_capture():
		return
	if not _acting:
		_pilot_story()


## Les répliques : lues READ_TIME s, puis la suite ou le premier choix (sauf la réplique visée).
func _pilot_dialogue(delta: float) -> void:
	if not _box.is_open():
		_read_left = READ_TIME
		return
	_box.complete_line()
	_read_left -= delta
	if _read_left > 0.0 or LINES.get(_view, "~~~") in _shown_text():
		return
	_read_left = READ_TIME
	if _box.is_choosing():
		_box.choose(0)
	elif _box.is_waiting():
		_box.advance()


func _shown_text() -> String:
	var label := _box.get_node_or_null("%Text") as Label
	return label.text if label != null and _box.is_open() else ""


## Vrai si la capture de la vue est faite (la démo quitte).
func _check_capture() -> bool:
	var captured := false
	match _view:
		"carton":
			var overlay := StoryDirector.stage().overlay()
			captured = (
				overlay != null and str(overlay.call(&"card_text")).begins_with("Sur le panneau")
			)
		"indice":
			if GameState.is_scene_done(&"j1_2_lumiere") and not StoryDirector.is_playing():
				if _hint_seen_at < 0.0:
					_hint_seen_at = _elapsed
				captured = _elapsed - _hint_seen_at > 1.2
		"sommeil":
			var overlay := StoryDirector.stage().overlay()
			captured = overlay != null and str(overlay.call(&"card_text")).begins_with("Jour 1")
		"calendrier":
			if (
				GameState.is_scene_done(&"j2_1_matin")
				or StoryDirector.runner().current_step() == "wait_for"
			):
				var calendar := _game.get_node(^"UI/HUD/Calendar")
				if not calendar.call(&"is_open"):
					calendar.call(&"open")
					_hint_seen_at = _elapsed
				captured = _elapsed - _hint_seen_at > 0.5
		_:
			var wanted: String = LINES.get(_view, "")
			captured = not wanted.is_empty() and wanted in _shown_text() and _box.is_waiting()
	if not captured:
		return false
	_save(_view)
	_finish()
	return true


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
			"E6 vue %s : %d draw calls, %d primitives ; carte %s, scène %s, jour %d, créneau %s"
			% [
				file_name,
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
				Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
				WorldManager.current_map(),
				StoryDirector.current_scene(),
				GameState.day,
				LifeSlots.current(),
			]
		)
	)


## Ce qu'attend une scène (wait_for), ou ce qui déclenche la suivante.
func _pilot_story() -> void:
	if WorldManager.is_transitioning() or _box.is_open():
		return
	var expected := StoryDirector.expected()
	if not expected.is_empty():
		_act(_satisfy(expected))
		return
	if StoryDirector.is_playing():
		return
	_act(_next_trigger())


func _act(action: Callable) -> void:
	if not action.is_valid():
		return
	_acting = true
	await action.call()
	await get_tree().create_timer(0.4).timeout
	_acting = false


func _satisfy(step: Dictionary) -> Callable:
	if step.has("reach"):
		if step.has("map") and StringName(str(step["map"])) != WorldManager.current_map():
			return _go.bind(StringName(str(step["map"])))
		return _teleport.bind(step["reach"])
	if step.has("map"):
		return _go.bind(StringName(str(step["map"])))
	if step.has("talk"):
		return _talk.bind(StringName(str(step["talk"])))
	return Callable()


## Après la dernière scène jouée : ce qui déclenche la suivante (jours 1 à 4).
func _next_trigger() -> Callable:
	var last := &""
	for scene_id: StringName in ORDER:
		if GameState.is_scene_done(scene_id):
			last = scene_id
	match last:
		&"j1_2_lumiere":
			return _go.bind(&"sentier")
		&"j1_2_embuscade":
			return _teleport.bind([22, 12])
		&"j1_5_premiers_pas":
			return _teleport.bind(&"dortoir_b")
		&"j1_7_chambre", &"j2_3_fenetre", &"j3_3_snack", &"j4_2_diner":
			return _sleep
		&"j2_2_fuite":
			return _afternoon_window
		&"j2_1_matin":
			return _teleport.bind(&"refectoire_allee")
		&"j3_2_chemin":
			return Callable()
		&"j4_1_cuisine":
			return _dinner
	if GameState.day == 3 and not GameState.is_scene_done(&"j3_1_information"):
		return _go.bind(&"entrepot", &"from_entrepot_rdc")
	if GameState.day == 4 and not GameState.is_scene_done(&"j4_1_cuisine"):
		return _kitchen
	return Callable()


func _go(map_id: StringName, marker: StringName = &"") -> void:
	var from := WorldManager.current_map()
	var arrival := marker if not marker.is_empty() else StringName("from_" + String(from))
	await WorldManager.go_to(map_id, arrival)


func _teleport(spec: Variant) -> void:
	StoryDirector.stage().place_player(StoryDirector.stage().resolve(spec).origin)
	await get_tree().physics_frame


func _talk(npc_id: StringName) -> void:
	var actor := LifeDirector.actor(npc_id)
	if actor != null:
		actor.on_interact()
	await get_tree().physics_frame


func _sleep() -> void:
	if WorldManager.current_map() != &"entrepot_etage":
		await WorldManager.go_to(&"entrepot_etage", &"Spawn")
	while not StoryDirector.can_sleep() and StoryDirector.can_rest():
		await StoryDirector.pass_time()
	await _teleport(&"chtholly_porte")
	await StoryDirector.sleep()


func _afternoon_window() -> void:
	while LifeSlots.current() != &"apres_midi" and StoryDirector.can_rest():
		await StoryDirector.pass_time()
	await WorldManager.go_to(&"entrepot_etage", &"from_entrepot_rdc")
	await _teleport(&"willem_porte")


func _kitchen() -> void:
	while LifeSlots.current() != &"apres_midi" and StoryDirector.can_rest():
		await StoryDirector.pass_time()
	if WorldManager.current_map() != &"entrepot_rdc":
		await WorldManager.go_to(&"entrepot_rdc", &"from_entrepot_etage")
	await _teleport(&"refectoire_porte_cuisine")


func _dinner() -> void:
	while LifeSlots.current() != &"soir" and StoryDirector.can_rest():
		await StoryDirector.pass_time()
	await _teleport(&"refectoire_allee")
