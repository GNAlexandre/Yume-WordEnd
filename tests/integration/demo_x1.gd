extends Node
## (X1) Démonstration des îles et de la surface : la vraie partie (game.tscn), posée par
## WorldManager.enter_map, avec la lumière d'Atmosphere, le joueur et sa caméra fixe.
##
## Captures : X1_VIEW=<vue> tools/screenshot.sh res://tests/integration/demo_x1.tscn
## build/shots/x1_<vue>.png 90
##   quai      : le quai de l'île d'essai, le dirigeable au nord, la mer de nuages (défaut) ;
##   surface   : les terres grises, le camp, les ruines, le dirigeable posé ;
##   horizon   : la surface de haut, le sol jusqu'à l'horizon ;
##   port      : le port provisoire de l'île n° 68 (carte essai), ses deux quais ;
##   voyage    : la vue du ciel d'un voyage (WorldManager.travel vers l'île d'essai), en cours.
## Draw calls et primitives sont écrits dans le journal (« X1 vue … »).

const GAME_SCENE := preload("res://src/game.tscn")
## Carte, position, direction regardée, zoom (distance de la caméra, 0 : par défaut).
const SPOTS := {
	"quai": [&"quai_essai", Vector3(16.0, 0.0, 12.5), Vector3(0.0, 0.0, -1.0), 0.0],
	"surface": [&"surface_essai", Vector3(20.0, 0.0, 16.0), Vector3(0.0, 0.0, -1.0), 0.0],
	"horizon": [&"surface_essai", Vector3(20.0, 0.0, 18.0), Vector3(0.0, 0.0, -1.0), 30.0],
	"port": [&"essai", Vector3(29.5, 0.0, 16.2), Vector3(1.0, 0.0, 0.0), 0.0],
	"voyage": [&"essai", Vector3(29.5, 0.0, 16.2), Vector3(1.0, 0.0, 0.0), 0.0],
}
const STAGE_FRAME := 4
const MEASURE_FRAME := 70

var _view := ""
var _state: Dictionary = {}
var _frame := 0
var _game: Node3D
var _player: Player
var _travel_time := 0.0


func _ready() -> void:
	_view = OS.get_environment("X1_VIEW")
	if _view.is_empty() or not SPOTS.has(_view):
		_view = "quai"
	_state = GameState.to_dict()
	_travel_time = WorldManager.travel_time
	GameState.reset()
	_game = GAME_SCENE.instantiate() as Node3D
	add_child(_game)
	_player = _game.get_node(^"Player") as Player


func _exit_tree() -> void:
	WorldManager.travel_time = _travel_time
	GameState.from_dict.call_deferred(_state)


func _process(_delta: float) -> void:
	_frame += 1
	if _frame == STAGE_FRAME:
		_stage()
	elif _frame == STAGE_FRAME + 6 and _view == "voyage":
		WorldManager.travel_time = 60.0
		WorldManager.travel(&"ile_essai")
	elif _frame == MEASURE_FRAME:
		print(
			(
				"X1 vue %s : %d draw calls, %d primitives, %d objets ; carte %s, île %s"
				% [
					_view,
					Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
					Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
					Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
					WorldManager.current_map(),
					WorldManager.current_island(),
				]
			)
		)


## La carte posée sans fondu, le joueur au sol à sa place, la caméra recalée.
func _stage() -> void:
	var spot: Array = SPOTS[_view]
	var at: Vector3 = spot[1]
	WorldManager.enter_map(spot[0], &"Spawn", at)
	_player.global_position = WorldManager.ground_position(at + Vector3.UP * 0.2, _player)
	_player.velocity = Vector3.ZERO
	_player.set_aim_direction(spot[2] as Vector3, true)
	if float(spot[3]) > 0.0:
		_player.camera_rig.zoom(float(spot[3]))
	_player.camera_rig.snap()
	_player.reset_physics_interpolation()
