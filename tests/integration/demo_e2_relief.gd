extends Node
## (E2) Démonstration du sol en relief : la vraie partie (game.tscn), posée sur la carte
## essai_relief (src/world/maps/essai_relief/) par WorldManager.enter_map, avec sa lumière
## (src/world/map_light.tscn), le joueur et sa caméra fixe (post-traitement compris). F6 dans
## l'éditeur.
##
## Captures : E2_VIEW=<vue> tools/screenshot.sh res://tests/integration/demo_e2_relief.tscn
## build/shots/e2_<vue>.png 60
##   depart     : le départ au sud, le sentier, l'escalier et les terrasses (défaut) ;
##   escalier   : au pied de l'escalier de dalles, la falaise de roche et le muret ;
##   rampe      : sur la terrasse, la rampe et le plateau ;
##   belvedere  : au bord du vide, la mer de nuages au nord ;
##   mare       : la mare du marais, la butte et ses talus ;
##   large      : la carte de haut, zoom au plus loin.
## Draw calls, primitives et mesures du sol sont écrits dans le journal (« E2 vue … »).

const GAME_SCENE := preload("res://src/game.tscn")
const MAP_ID := &"essai_relief"
## Où se tient le joueur (position sur la carte, direction regardée, zoom : distance de la caméra,
## 0 : celle par défaut) pour chaque vue.
const SPOTS := {
	"depart": [Vector3(31.5, 0.0, 41.0), Vector3(0.0, 0.0, -1.0), 0.0],
	"escalier": [Vector3(27.5, 0.0, 33.5), Vector3(-1.0, 0.0, -1.0), 0.0],
	"rampe": [Vector3(44.0, 1.5, 21.0), Vector3(1.0, 0.0, -1.0), 0.0],
	"belvedere": [Vector3(45.0, 3.0, 6.0), Vector3(0.0, 0.0, -1.0), 0.0],
	"mare": [Vector3(17.0, 0.0, 37.5), Vector3(-1.0, 0.0, 0.0), 0.0],
	"large": [Vector3(31.0, 1.5, 24.0), Vector3(0.0, 0.0, -1.0), 25.0],
}
const STAGE_FRAME := 4
const MEASURE_FRAME := 50

var _view := ""
var _state: Dictionary = {}
var _frame := 0
var _game: Node3D
var _player: Player


func _ready() -> void:
	_view = OS.get_environment("E2_VIEW")
	if _view.is_empty() or not SPOTS.has(_view):
		_view = "depart"
	_state = GameState.to_dict()
	GameState.reset()
	_game = GAME_SCENE.instantiate() as Node3D
	add_child(_game)
	_player = _game.get_node(^"Player") as Player


func _exit_tree() -> void:
	GameState.from_dict.call_deferred(_state)


func _process(_delta: float) -> void:
	_frame += 1
	if _frame == STAGE_FRAME:
		_stage()
	elif _frame == MEASURE_FRAME:
		var ground := WorldManager.current_map_node().get_node(^"Ground") as MapGround
		print(
			(
				"E2 vue %s : %d draw calls, %d primitives, %d objets ; sol : %s"
				% [
					_view,
					Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
					Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
					Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
					ground.stats(),
				]
			)
		)


## La carte posée sans fondu, le joueur au sol à sa place, la caméra recalée.
func _stage() -> void:
	var spot: Array = SPOTS[_view]
	var at: Vector3 = spot[0]
	WorldManager.enter_map(MAP_ID, &"Spawn", at)
	var ground := WorldManager.current_map_node().get_node(^"Ground") as MapGround
	_player.global_position = Vector3(at.x, ground.height_at(at.x, at.z) + 0.05, at.z)
	_player.velocity = Vector3.ZERO
	_player.set_aim_direction(spot[1] as Vector3, true)
	if float(spot[2]) > 0.0:
		_player.camera_rig.zoom(float(spot[2]))
	_player.camera_rig.snap()
	_player.reset_physics_interpolation()
