extends Node
## Démo de l'acte 1 (tests/integration/demo_act1.tscn, F6 dans l'éditeur) : la vraie partie
## (src/game.tscn) avec le contenu de l'acte 1, mise en scène pour les captures. Aucune
## sauvegarde n'est écrite (pas de game_loaded) ; GameState est rétabli quand la démo quitte
## l'arbre.
##
## Captures : ACT1_SHOT=<vue> tools/screenshot.sh res://tests/integration/demo_act1.tscn <png> 150
##   nygglatho : la première scène de act1_main, sous le porche (Nygglatho, le grand vent) ;
##   willem    : Willem et ses conseils (étape new_officer, après « N'y touche pas. ») ;
##   journal   : le journal ouvert sur la quête principale, des quêtes secondaires en cours et
##               une terminée ;
##   village   : (par défaut) l'entrepôt des fées et ses PNJ, vue d'ensemble.
## La mise en scène compte les images (et non le temps) ; la scène se fige avant la capture.

const GAME_SCENE := preload("res://src/game.tscn")
## Image de la mise en scène, puis image du gel.
const STAGE_FRAME := 8
const FREEZE_FRAME := 90
## Willem : réponses jusqu'à ses conseils (-1 : suite), une par image à partir de STAGE_FRAME + 4.
const WILLEM_ANSWERS: Array[int] = [-1, 0, -1, 0]

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
	match _shot:
		"willem":
			GameState.from_dict(_willem_state())
		"journal":
			GameState.from_dict(_journal_state())
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
		"journal":
			_place(Vector3(1.0, 0.0, 12.0), Vector3(0.0, 0.0, -1.0))
			var journal := _game.get_node(^"UI/HUD/Journal") as Control
			journal.call(&"open")
			journal.call(&"select", &"act1_main")
		_:
			_overview()


## Joueur au point local du village, tourné vers le PNJ (caméra derrière lui, décalée de yaw),
## puis la conversation commence.
func _talk_to(node_name: String, local_position: Vector3, yaw: float) -> void:
	var npc := _zone().get_node(NodePath("NPCs/" + node_name)) as Npc
	_place(local_position, npc.global_position - _zone().to_global(local_position))
	_player.camera_rig.rotate_view(yaw, deg_to_rad(4.0))
	npc.interact(_player)


## Vue d'ensemble : caméra au-dessus de l'entrée sud, vers la place, les PNJ en vue.
func _overview() -> void:
	_place(Vector3(0.0, 0.0, 9.0), Vector3(0.0, 0.0, -1.0))
	var camera := Camera3D.new()
	camera.fov = 62.0
	_game.add_child(camera)
	var eye := _zone().to_global(Vector3(0.0, 7.5, 12.5))
	camera.look_at_from_position(eye, _zone().to_global(Vector3(-2.0, 0.5, -3.5)))
	camera.make_current()


## Joueur au point local `local_position` du village, visée `aim`, caméra derrière lui.
func _place(local_position: Vector3, aim: Vector3) -> void:
	_player.global_position = WorldManager.ground_position(
		_zone().to_global(local_position), _player
	)
	_player.velocity = Vector3.ZERO
	_player.set_aim_direction(aim, true)


func _zone() -> Node3D:
	return _game.get_node(^"Island/Zones/village") as Node3D


## La partie de la capture de Willem : act1_main à l'étape du nouveau responsable.
func _willem_state() -> Dictionary:
	return {
		"quests": {"act1_main": "active"},
		"quest_progress": {"act1_main": {"step": "new_officer", "count": 0}},
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
