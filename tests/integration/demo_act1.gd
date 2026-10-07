extends Node
## Démo de l'acte 1 (tests/integration/demo_act1.tscn, F6 dans l'éditeur) : la vraie partie
## (src/game.tscn) avec le contenu de l'acte 1, mise en scène pour les captures. Aucune
## sauvegarde n'est écrite (pas de game_loaded) ; GameState est rétabli quand la démo quitte
## l'arbre.
##
## Captures : ACT1_SHOT=<vue> tools/screenshot.sh res://tests/integration/demo_act1.tscn <png> 150
##   nygglatho : la première scène de act1_main, sous le porche (Nygglatho, le grand vent) ;
##   willem    : Willem et ses conseils (étape new_officer, après « N'y touche pas. ») ;
##   deux_voix : une scène à deux voix, la fièvre (étape fever) : Nephren parle dans le
##               dialogue de Willem, avec son portrait ;
##   journal   : le journal ouvert sur la quête principale, des quêtes secondaires en cours et
##               une terminée ;
##   village   : (par défaut) l'entrepôt des fées et ses PNJ, vue d'ensemble ;
##   bois      : les bois du marais pendant l'assaut (étape training) : Willem au banc du
##               terrain d'entraînement, les rejetons, Pannibal au bord du marais ;
##   couchant  : le bord du Couchant à l'heure de la première veille : le cercle, la cloche, le
##               guetteur près du vieux poste de guet ;
##   port      : le port et le bourg quand le Barocupot est là (étape barocupot) : Limeskin au
##               bras d'ancrage, la marchande d'œufs, le serveur du café, le snack ;
##   colline   : la colline des étoiles à l'étape promise : Willem à côté du belvédère ;
##   fin_veille : l'écran de fin de la veille (« Fin de la veille », le bord du Couchant).
## La mise en scène compte les images (et non le temps) ; la scène se fige avant la capture.

const GAME_SCENE := preload("res://src/game.tscn")
## Image de la mise en scène, puis image du gel.
const STAGE_FRAME := 8
const FREEZE_FRAME := 90
## Image de l'écran de fin de veille (après l'entrée au Couchant : il met le jeu en pause).
const RESULT_FRAME := 60
## Willem : réponses jusqu'à ses conseils (-1 : suite), une par image à partir de STAGE_FRAME + 4.
const WILLEM_ANSWERS: Array[int] = [-1, 0, -1, 0]
## La fièvre : jusqu'à la première réplique de Nephren (« Deux cafés. Très sucrés. »).
const FEVER_ANSWERS: Array[int] = [-1, 0, -1]
## Étape d'act1_main de chaque vue (la présence des PNJ en dépend : visible_if).
const SHOT_STEPS := {
	"willem": &"new_officer",
	"deux_voix": &"fever",
	"bois": &"training",
	"couchant": &"first_vigil",
	"port": &"barocupot",
	"colline": &"promise",
	"fin_veille": &"fever",
}
## Drapeaux que posent les dialogues des étapes d'act1_main (en plus des récompenses d'étape).
const DIALOGUE_FLAGS := {&"pannibal": [&"pannibal_found"], &"barocupot": [&"limeskin_tea"]}
## Vues d'ensemble : zone, œil et point visé (locaux à la zone), champ (degrés), place du joueur.
const VIEWS := {
	"bois":
	[&"forest", Vector3(6.0, 5.5, 22.0), Vector3(-9.0, 0.8, 4.0), 60.0, Vector3(-2.0, 0.0, 16.0)],
	"couchant":
	[&"dunes", Vector3(17.0, 4.5, 7.0), Vector3(-6.0, 0.5, -6.0), 62.0, Vector3(12.0, 0.0, 1.0)],
	"port":
	[&"beach", Vector3(9.0, 9.0, 20.0), Vector3(-17.0, 0.5, 6.0), 62.0, Vector3(-15.0, 0.0, 9.5)],
	"colline":
	[&"hill", Vector3(-5.0, 10.5, 7.0), Vector3(2.0, 8.6, -1.5), 60.0, Vector3(-1.0, 8.0, 3.0)],
}

var _shot := ""
var _state: Dictionary = {}
var _frame := 0
var _game: Node3D
var _player: Player
var _box: DialogueBox
var _answers: Array[int] = []


func _ready() -> void:
	_shot = OS.get_environment("ACT1_SHOT")
	_state = GameState.to_dict()
	GameState.reset()
	if _shot == "journal":
		GameState.from_dict(_journal_state())
	elif SHOT_STEPS.has(_shot):
		GameState.from_dict(_step_state(SHOT_STEPS[_shot]))
	if _shot == "fin_veille":
		GameState.record_score(&"dunes", 465, 4)
	_game = GAME_SCENE.instantiate() as Node3D
	add_child(_game)
	_player = _game.get_node(^"Player") as Player
	_box = _game.get_node(^"UI/DialogueBox") as DialogueBox


func _exit_tree() -> void:
	if get_tree().paused:
		get_tree().paused = false
	GameState.from_dict.call_deferred(_state)


func _process(_delta: float) -> void:
	_frame += 1
	if _frame == STAGE_FRAME:
		_stage()
	elif _frame > STAGE_FRAME and not _answers.is_empty() and _frame % 4 == 0:
		_box.complete_line()
		EventBus.dialogue_choice_made.emit(_answers.pop_front())
	elif _frame == RESULT_FRAME and _shot == "fin_veille":
		_game.get_node(^"UI/ArenaEnd").call(&"show_result", &"dunes", 465, true, 4)
	elif _frame == FREEZE_FRAME - 10 and _box.is_open():
		_box.complete_line()
	elif _frame == FREEZE_FRAME:
		get_tree().paused = true


func _stage() -> void:
	match _shot:
		"nygglatho":
			_talk_to("Nygglatho", Vector3(-10.6, 0.0, -6.4), deg_to_rad(18.0))
		"willem":
			_talk_to("Willem", Vector3(-11.2, 0.0, 0.9), deg_to_rad(10.0))
			_answers = WILLEM_ANSWERS.duplicate()
		"deux_voix":
			_talk_to("Willem", Vector3(-11.2, 0.0, 0.9), deg_to_rad(10.0))
			_answers = FEVER_ANSWERS.duplicate()
		"journal":
			_place(&"village", Vector3(1.0, 0.0, 12.0), Vector3(0.0, 0.0, -1.0))
			var journal := _game.get_node(^"UI/HUD/Journal") as Control
			journal.call(&"open")
			journal.call(&"select", &"act1_main")
		"bois", "couchant", "port", "colline":
			_view(VIEWS[_shot])
		"fin_veille":
			_place(&"dunes", Vector3(14.0, 0.0, -2.0), Vector3(-1.0, 0.0, 0.0))
		_:
			_overview()


## Joueur au point local du village, tourné vers le PNJ (caméra derrière lui, décalée de yaw),
## puis la conversation commence.
func _talk_to(node_name: String, local_position: Vector3, yaw: float) -> void:
	var npc := _zone(&"village").get_node(NodePath("NPCs/" + node_name)) as Npc
	var aim := npc.global_position - _zone(&"village").to_global(local_position)
	_place(&"village", local_position, aim)
	_player.camera_rig.rotate_view(yaw, deg_to_rad(4.0))
	npc.interact(_player)


## Vue d'ensemble de l'entrepôt : caméra au-dessus de l'entrée sud, vers la place, les PNJ en vue.
func _overview() -> void:
	_view([&"village", Vector3(0.0, 7.5, 12.5), Vector3(-2.0, 0.5, -3.5), 62.0, Vector3(0, 0, 9)])


## Vue fixe [zone, œil, point visé, champ, place du joueur] (points locaux à la zone).
func _view(view: Array) -> void:
	var zone_id: StringName = view[0]
	_place(zone_id, view[4], (view[2] as Vector3) - (view[4] as Vector3))
	var camera := Camera3D.new()
	camera.fov = view[3]
	_game.add_child(camera)
	var zone := _zone(zone_id)
	camera.look_at_from_position(zone.to_global(view[1]), zone.to_global(view[2]))
	camera.make_current()


## Joueur au point local `local_position` de la zone, visée `aim`, caméra derrière lui.
func _place(zone_id: StringName, local_position: Vector3, aim: Vector3) -> void:
	_player.global_position = WorldManager.ground_position(
		_zone(zone_id).to_global(local_position), _player
	)
	_player.velocity = Vector3.ZERO
	aim.y = 0.0
	_player.set_aim_direction(aim, true)


func _zone(zone_id: StringName) -> Node3D:
	return _game.get_node(NodePath("Island/Zones/" + String(zone_id))) as Node3D


## La partie à l'étape step_id d'act1_main : drapeaux des étapes précédentes, quêtes secondaires
## pas encore commencées.
func _step_state(step_id: StringName) -> Dictionary:
	var flags := {}
	var quest := QuestData.find(&"act1_main")
	for step: QuestStep in quest.steps:
		if step.id == step_id:
			break
		for flag: StringName in DIALOGUE_FLAGS.get(step.id, []):
			flags[String(flag)] = true
		for flag: StringName in step.reward_flags:
			flags[String(flag)] = true
	return {
		"flags": flags,
		"quests": {"act1_main": "active"},
		"quest_progress": {"act1_main": {"step": String(step_id), "count": 0}},
		"tracked_quest": "act1_main",
	}


## La partie de la capture du journal : act1_main aux rejetons des bois (2/4), le livre d'images
## (3 pages) et le linge en cours, l'homme-chat terminé.
func _journal_state() -> Dictionary:
	return {
		"inventory": {"page_fragment": 3, "laundry_sheet": 2, "rami_card": 1},
		"flags": {"met_willem": true, "rami_clock_fixed": true},
		"quests":
		{
			"act1_main": "active",
			"picture_book": "active",
			"flying_laundry": "active",
			"old_clock": "done",
		},
		"quest_progress":
		{
			"act1_main": {"step": "rejetons", "count": 2},
			"picture_book": {"step": "pages", "count": 0},
			"flying_laundry": {"step": "sheets", "count": 0},
		},
		"tracked_quest": "act1_main",
	}
