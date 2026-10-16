extends Node
## (X-L5) Démo du choix du mode de jeu dans l'interface. F6 dans l'éditeur, ou capture :
##   L5_VIEW=<vue> tools/screenshot.sh res://tests/integration/demo_xl5.tscn build/l5/<vue>.png 70
## Vues :
##   choix         : « Nouvelle partie » du menu principal demande le mode (libre : le défaut) ;
##   pause         : le menu de pause, le mode sous le jour (mode libre) ;
##   options       : Options de la pause, l'entrée « Mode de jeu » ;
##   confirmation  : la confirmation courte du passage en mode scénarisé ;
##   scenario      : Options de la pause d'une partie scénarisée.

const GAME_SCENE := preload("res://src/game.tscn")
const MAIN_SCENE := preload("res://src/main.tscn")
const MenuScript := preload("res://src/ui/main_menu.gd")
const STAGE_FRAME := 6
## Image où s'ouvrent les écrans qui figent la partie (la caméra a rejoint le joueur).
const LATE_FRAME := 40

var _view := ""
var _state: Dictionary = {}
var _frame := 0
var _game: Node3D
var _previous_mode: StringName


func _ready() -> void:
	_view = OS.get_environment("L5_VIEW")
	if _view.is_empty():
		_view = "choix"
	_state = GameState.to_dict()
	_previous_mode = StoryDirector.default_mode
	GameState.reset()
	if _view == "choix":
		get_tree().root.set_meta(MenuScript.GESTURE_META, true)
		add_child(MAIN_SCENE.instantiate())
		return
	if _view == "scenario":
		StoryDirector.default_mode = StoryPacing.SCENARIO
	_game = GAME_SCENE.instantiate() as Node3D
	add_child(_game)


func _exit_tree() -> void:
	if get_tree().paused:
		get_tree().paused = false
	StoryDirector.default_mode = _previous_mode
	GameState.from_dict.call_deferred(_state)


func _process(_delta: float) -> void:
	_frame += 1
	if _frame == STAGE_FRAME and _view == "choix":
		var menu := (
			(
				find_children("*", "Control", true, false)
				. filter(func(node: Node) -> bool: return node.get_script() == MenuScript)
				. front()
			)
			as Control
		)
		menu.call(&"open_mode_choice")
	elif _frame == LATE_FRAME and _game != null:
		GameState.day = 2
		GameState.slot = &"matin"
		var pause := _game.get_node(^"UI/HUD/PauseMenu")
		pause.call(&"open")
		if _view != "pause":
			pause.call(&"show_options")
		if _view == "confirmation":
			pause.call(&"request_mode_switch")
