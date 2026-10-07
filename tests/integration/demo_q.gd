extends Node
## Démo du Lot Q (tests/integration/demo_q.tscn, F6 dans l'éditeur) : la vraie partie
## (src/game.tscn) au village, avec les quêtes d'exemple des tests (tests/data/quests) et le guide
## de tests/data/placements/village.tscn. Aucune sauvegarde n'est écrite (pas de game_loaded) ;
## GameState et les dossiers de quêtes sont rétablis quand la démo quitte l'arbre.
##
## Captures : Q_SHOT=<vue> tools/screenshot.sh res://tests/integration/demo_q.tscn <png> 150
##   hud     : le HUD suit « Le tour du village » (rapporter les pages : 2/2) ; « ? » au-dessus du
##             guide (et de Nygglatho, sous le porche : l'acte 1 commence) ;
##   journal : journal ouvert sur « Le tour du village » (trois étapes validées, la courante 1/2),
##             avec le livre d'images de l'acte 1 en cours et une quête terminée.
## La mise en scène compte les images (et non le temps) ; la scène se fige avant la capture.

const GAME_SCENE := preload("res://src/game.tscn")
const VILLAGE_DEMO := preload("res://tests/data/placements/village.tscn")
const FIXTURES_DIR := "res://tests/data/quests"
## Image de la mise en scène, puis image du gel.
const STAGE_FRAME := 8
const FREEZE_FRAME := 70

var _shot := ""
var _state: Dictionary = {}
var _frame := 0
var _game: Node3D
var _player: Player


func _ready() -> void:
	_shot = OS.get_environment("Q_SHOT")
	_state = GameState.to_dict()
	GameState.reset()
	QuestData.add_search_dir(FIXTURES_DIR)
	if _shot == "journal":
		GameState.from_dict(_journal_state())
	_game = GAME_SCENE.instantiate() as Node3D
	add_child(_game)
	_zone(&"village").add_child(VILLAGE_DEMO.instantiate())
	_player = _game.get_node(^"Player") as Player


func _exit_tree() -> void:
	if get_tree().paused:
		get_tree().paused = false
	QuestData.remove_search_dir(FIXTURES_DIR)
	GameState.from_dict.call_deferred(_state)


func _process(_delta: float) -> void:
	_frame += 1
	if _frame == STAGE_FRAME:
		_stage()
	elif _frame == FREEZE_FRAME and _shot == "hud":
		get_tree().paused = true


func _stage() -> void:
	match _shot:
		"journal":
			_place(Vector3(1.0, 0.0, 12.0), Vector3(0.0, 0.0, -1.0))
			var journal := _game.get_node(^"UI/HUD/Journal") as Control
			journal.call(&"open")
			journal.call(&"select", &"demo_tour")
		_:
			GameState.set_quest_state(&"demo_tour", &"active")
			GameState.set_quest_step(&"demo_tour", &"pages")
			GameState.add_item(&"page_fragment", 2)
			_place(Vector3(0.5, 0.0, 12.5), Vector3(0.05, 0.0, -1.0))
			_player.camera_rig.rotate_view(deg_to_rad(4.0), deg_to_rad(4.0))


## La partie de la capture du journal : le tour du village à l'étape des Timeres (1/2), le livre
## d'images en cours (3 pages), la ronde de la forêt terminée.
func _journal_state() -> Dictionary:
	return {
		"inventory": {"page_fragment": 3},
		"quests": {"example_patrol": "done", "picture_book": "active", "demo_tour": "active"},
		"quest_progress":
		{
			"demo_tour": {"step": "timeres", "count": 1},
			"picture_book": {"step": "pages", "count": 0},
		},
		"tracked_quest": "demo_tour",
	}


## Joueur au point local `local_position` du village, visée `aim`, caméra derrière lui.
func _place(local_position: Vector3, aim: Vector3) -> void:
	var zone := _zone(&"village")
	_player.global_position = WorldManager.ground_position(zone.to_global(local_position), _player)
	_player.velocity = Vector3.ZERO
	_player.set_aim_direction(aim, true)


func _zone(zone_id: StringName) -> Node3D:
	return _game.get_node(NodePath("Island/Zones/%s" % zone_id)) as Node3D
