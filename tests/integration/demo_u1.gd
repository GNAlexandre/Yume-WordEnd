extends Node
## (U1) Démo de l'interface « Nuit douce » dans la vraie partie (game.tscn, ou main.tscn pour le
## menu). F6 dans l'éditeur, ou capture :
##   U1_VIEW=<vue> tools/screenshot.sh res://tests/integration/demo_u1.tscn build/u1/<vue>.png 70
## Vues :
##   menu         : le menu principal et le choix de la fée ;
##   sauvegarde   : le panneau de sauvegarde du menu ;
##   credits      : les crédits ;
##   pause        : le menu de pause, jour 2 au matin ;
##   dialogue     : Nygglatho parle, sous le porche, en Nuit douce ;
##   nuit         : la même réplique la nuit ;
##   bandeau      : la même réplique en Bandeau (scène du récit) ;
##   choix        : une réplique et ses deux réponses ;
##   choix_bandeau: les mêmes réponses en Bandeau ;
##   inventaire   : le sac ouvert ;
##   invite       : l'invite « E / A : Parler » près de Nygglatho, deux cœurs perdus ;
##   arene        : l'écran de fin de veille ;
##   (signes d'interaction : le joueur devant la cible la plus proche d'un lieu ; images à
##   attendre : 400)
##   cour         : la cour de l'entrepôt, un PNJ (signe plein) et ses voisins (signes pâles) ;
##   refectoire   : le réfectoire de l'entrepôt ;
##   cafe         : le comptoir du café ;
##   objet        : un objet à examiner dans la cuisine, survolé à la souris (liseré, main).
## Draw calls et primitives de l'image mesurée dans le journal (« U1 vue … »).

const GAME_SCENE := preload("res://src/game.tscn")
const MAIN_SCENE := preload("res://src/main.tscn")
const MenuScript := preload("res://src/ui/main_menu.gd")
const STAGE_FRAME := 6
## Image où s'ouvrent les écrans qui figent la partie (la caméra a rejoint le joueur).
const LATE_FRAME := 40
const MEASURE_FRAME := 60
const SPOT := [Vector3(-7.2, 0.0, -6.2), Vector3(-1.0, 0.0, -1.0)]
const PROMPT_SPOT := [Vector3(-5.2, 0.0, -4.6), Vector3(-1.0, 0.0, -1.0)]
const LINE := (
	"Pannibal l'a « accueilli » au marais, d'un coup d'épée de bois. Il a dormi avec de la "
	+ "vase jusqu'aux oreilles."
)
const QUESTION := "Tu viendras goûter le gâteau au beurre, ce soir ? Il sera tiède."
const ANSWERS: Array[String] = [
	"Avec plaisir, j'apporterai la confiture.", "Pas ce soir, la veille m'attend."
]
const MENU_VIEWS: Array[String] = ["menu", "sauvegarde", "credits"]
## Vues des signes : carte, lieu (repère de la carte), genre de la cible cherchée, créneau.
const SIGN_VIEWS := {
	"cour": [&"entrepot", Vector3(42.0, 0.0, 41.0), InteractSign.TALK, &"apres_midi"],
	"refectoire": [&"entrepot_rdc", Vector3(11.0, 0.0, 5.55), InteractSign.TALK, &"soir"],
	"cafe": [&"cafe", Vector3(4.0, 0.0, 4.2), InteractSign.TALK, &"soir"],
	"objet": [&"entrepot_rdc", Vector3(3.3, 0.0, 6.6), InteractSign.EXAMINE, &"apres_midi"],
}
## Distance (m) entre le joueur et la cible, à l'est d'elle (le joueur ne la cache pas).
const SIGN_FRONT := 1.1

var _view := ""
var _state: Dictionary = {}
var _frame := 0
var _game: Node3D
var _player: Player
var _menu: Control


func _ready() -> void:
	_view = OS.get_environment("U1_VIEW")
	if _view.is_empty():
		_view = "dialogue"
	_state = GameState.to_dict()
	GameState.reset()
	if _view in MENU_VIEWS:
		get_tree().root.set_meta(MenuScript.GESTURE_META, true)
		var main := MAIN_SCENE.instantiate()
		add_child(main)
		return
	_game = GAME_SCENE.instantiate() as Node3D
	add_child(_game)
	_player = _game.get_node(^"Player") as Player


func _exit_tree() -> void:
	if get_tree().paused:
		get_tree().paused = false
	DialogueBox.set_presentation(DialogueBox.PRESENTATION_NUIT)
	WorldManager.fade_time = WorldManager.DEFAULT_FADE_TIME
	GameState.from_dict.call_deferred(_state)


func _process(_delta: float) -> void:
	_frame += 1
	if _frame == STAGE_FRAME:
		if _game != null:
			_stage()
		else:
			_stage_menu()
	elif _frame == LATE_FRAME and _game != null:
		_stage_late()
	elif _frame == MEASURE_FRAME:
		print(
			(
				"U1 vue %s : %d draw calls, %d primitives, %d objets"
				% [
					_view,
					Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
					Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
					Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
				]
			)
		)


func _stage_menu() -> void:
	_menu = (
		(
			find_children("*", "Control", true, false)
			. filter(func(node: Node) -> bool: return node.get_script() == MenuScript)
			. front()
		)
		as Control
	)
	match _view:
		"sauvegarde":
			_menu.call(&"open_save_panel")
		"credits":
			_menu.call(&"open_credits")


func _stage() -> void:
	if SIGN_VIEWS.has(_view):
		_stage_sign_view.call_deferred()
		return
	var spot: Array = PROMPT_SPOT if _view == "invite" else SPOT
	var zone := _game.get_node(^"World/ile_ancienne/Zones/village") as Node3D
	WorldManager.load_zone(&"village")
	_player.global_position = WorldManager.ground_position(zone.to_global(spot[0]), _player)
	_player.velocity = Vector3.ZERO
	_player.set_aim_direction(spot[1] as Vector3, true)
	match _view:
		"nuit":
			Atmosphere.set_moment(&"nuit", 0.0)
			_say.call_deferred(LINE, [])
		"bandeau":
			DialogueBox.set_presentation(DialogueBox.PRESENTATION_BANDEAU)
			_say.call_deferred(LINE, [])
		"choix":
			_say.call_deferred(QUESTION, ANSWERS)
		"choix_bandeau":
			DialogueBox.set_presentation(DialogueBox.PRESENTATION_BANDEAU)
			_say.call_deferred(QUESTION, ANSWERS)
		"pause", "inventaire":
			pass
		"invite":
			EventBus.player_health_changed.emit(3, 5)
		"arene":
			EventBus.arena_finished.emit(&"dunes", 1240, true)
		_:
			_say.call_deferred(LINE, [])


## Signes d'interaction : le joueur entre dans la carte, puis se poste devant la cible du genre
## voulu la plus proche du lieu.
func _stage_sign_view() -> void:
	var setup: Array = SIGN_VIEWS[_view]
	GameState.day = 2
	GameState.slot = setup[3] as StringName
	WorldManager.fade_time = 0.0
	WorldManager.enter_map(setup[0] as StringName)
	Atmosphere.set_atmosphere(LifeSlots.moment_of(setup[3] as StringName), &"clair", 0.0)
	await get_tree().create_timer(1.0).timeout
	var map := WorldManager.current_map_node()
	var spot := map.to_global(setup[1] as Vector3)
	_put_player(spot, Vector3.FORWARD)
	await get_tree().create_timer(1.5).timeout
	var candidates := _targets_by_distance(spot, setup[2] as StringName)
	if candidates.is_empty():
		candidates = _targets_by_distance(spot, &"")
	if candidates.is_empty():
		print("U1 vue %s : aucune cible" % _view)
		return
	# Les habitants bougent ou sont attablés (la vie, E4) : le joueur se poste à côté d'une cible
	# (à l'est, à l'ouest, au sud) jusqu'à ce qu'elle soit la sienne.
	var target: Node3D = candidates[0]
	var sides: Array[Vector3] = [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK]
	var found := false
	for candidate: Node3D in candidates.slice(0, 6):
		for side: Vector3 in sides:
			_put_player(candidate.global_position + side * SIGN_FRONT, -side)
			await get_tree().create_timer(0.5).timeout
			if _player.current_interactable() == candidate:
				target = candidate
				found = true
				break
		if found:
			break
	print("U1 vue %s : cible %s (%s)" % [_view, target.name, InteractSign.kind_of(target)])
	if _view == "objet":
		await get_tree().create_timer(0.6).timeout
		var camera := get_viewport().get_camera_3d()
		var point := camera.unproject_position(target.global_position + Vector3.UP * 0.4)
		get_viewport().warp_mouse(point)
		var motion := InputEventMouseMotion.new()
		motion.position = point
		motion.global_position = point
		Input.parse_input_event(motion)


func _put_player(at: Vector3, facing: Vector3) -> void:
	_player.global_position = at + Vector3.UP * 0.05
	_player.velocity = Vector3.ZERO
	_player.set_aim_direction(facing, true)
	_player.reset_physics_interpolation()
	_player.camera_rig.snap()


## Cibles du genre kind (&"" : toutes), de la plus proche d'origin à la plus loin.
func _targets_by_distance(origin: Vector3, kind: StringName) -> Array[Node3D]:
	var result: Array[Node3D] = []
	for node: Node in get_tree().get_nodes_in_group(&"interactable"):
		var target := node as Node3D
		if target == null or not target.is_visible_in_tree():
			continue
		var target_kind := InteractSign.kind_of(target)
		if target_kind.is_empty() or (not kind.is_empty() and target_kind != kind):
			continue
		result.append(target)
	result.sort_custom(
		func(a: Node3D, b: Node3D) -> bool:
			return a.global_position.distance_to(origin) < b.global_position.distance_to(origin)
	)
	return result


## Écrans qui mettent la partie en pause, une fois la caméra posée.
func _stage_late() -> void:
	match _view:
		"pause":
			GameState.day = 2
			GameState.slot = &"matin"
			_hud().get_node(^"%PauseMenu").call(&"open")
		"inventaire":
			for item: StringName in [&"page_fragment", &"eggs", &"flower_blue", &"clock_gear"]:
				GameState.add_item(item, 3 if item == &"page_fragment" else 1)
			_game.get_node(^"UI/Inventory").call(&"open")


## Nygglatho dit text (et propose choices) : la boîte reçoit les signaux du dialogue.
func _say(text: String, choices: Array) -> void:
	EventBus.dialogue_started.emit(&"nygglatho")
	EventBus.dialogue_line.emit("Nygglatho", text, choices)
	var box := _game.get_node(^"UI/DialogueBox") as DialogueBox
	box.complete_line()


func _hud() -> Control:
	return _game.get_node(^"UI/HUD") as Control
