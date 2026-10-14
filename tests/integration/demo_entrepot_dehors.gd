extends Node
## (T1) Démonstration de la carte entrepot (l'entrepôt des fées vu du dehors, docs/lore/CARTE.md,
## section 2) : la vraie partie (game.tscn), posée sur la carte par WorldManager.enter_map, avec
## la lumière d'Atmosphere (E9), le joueur et sa caméra fixe (post-traitement compris).
##
## Captures : ENTREPOT_VIEW=<vue> [ENTREPOT_MOMENT=nuit] tools/screenshot.sh
## res://tests/integration/demo_entrepot_dehors.tscn build/shots/t1_<vue>.png 60
##   facade (défaut), porche, cour, champ, clairiere, marais, bois, arbre, potager, sentier,
##   riviere, lisiere, large (zoom au plus loin).
## Draw calls et primitives sont écrits dans le journal (« T1 vue … »).

const GAME_SCENE := preload("res://src/game.tscn")
const MAP_ID := &"entrepot"
## Où se tient le joueur (position sur la carte, direction regardée, zoom : distance de la caméra,
## 0 : celle par défaut) pour chaque vue.
const SPOTS := {
	"facade": [Vector3(42.0, 0.0, 34.0), Vector3(0.0, 0.0, -1.0), 0.0],
	"porche": [Vector3(43.5, 0.0, 28.6), Vector3(0.0, 0.0, -1.0), 0.0],
	"cour": [Vector3(42.0, 0.0, 41.0), Vector3(0.0, 0.0, -1.0), 0.0],
	"champ": [Vector3(74.0, -0.5, 24.0), Vector3(0.0, 0.0, -1.0), 0.0],
	"clairiere": [Vector3(15.0, 0.5, 19.0), Vector3(0.0, 0.0, -1.0), 0.0],
	"marais": [Vector3(9.0, 0.0, 27.0), Vector3(-1.0, 0.0, -1.0), 0.0],
	"bois": [Vector3(30.0, 0.0, 52.0), Vector3(0.0, 0.0, -1.0), 0.0],
	"arbre": [Vector3(62.5, 0.0, 38.0), Vector3(0.0, 0.0, -1.0), 0.0],
	"potager": [Vector3(22.0, 0.0, 33.0), Vector3(0.0, 0.0, -1.0), 0.0],
	"sentier": [Vector3(78.0, 0.0, 38.0), Vector3(1.0, 0.0, 0.0), 0.0],
	"riviere": [Vector3(12.0, 0.0, 46.0), Vector3(-1.0, 0.0, 0.0), 0.0],
	"lisiere": [Vector3(14.0, 0.5, 10.0), Vector3(0.0, 0.0, -1.0), 0.0],
	"large": [Vector3(44.0, 0.0, 36.0), Vector3(0.0, 0.0, -1.0), 25.0],
}
const STAGE_FRAME := 4
const MEASURE_FRAME := 50

var _view := ""
var _state: Dictionary = {}
var _frame := 0
var _game: Node3D
var _player: Player


func _ready() -> void:
	_view = OS.get_environment("ENTREPOT_VIEW")
	if _view.is_empty() or not SPOTS.has(_view):
		_view = "facade"
	_state = GameState.to_dict()
	GameState.reset()
	var moment := OS.get_environment("ENTREPOT_MOMENT")
	if not moment.is_empty():
		GameState.moment = StringName(moment)
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
		print(
			(
				"T1 vue %s (%s) : %d draw calls, %d primitives, %d objets"
				% [
					_view,
					GameState.moment,
					Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
					Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
					Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
				]
			)
		)


## La carte posée sans fondu, le joueur au sol à sa place, la caméra recalée.
func _stage() -> void:
	var spot: Array = SPOTS[_view]
	var at: Vector3 = spot[0]
	WorldManager.enter_map(MAP_ID, &"Spawn", at)
	Atmosphere.snap()
	var ground := WorldManager.current_map_node().get_node(^"Ground") as MapGround
	_player.global_position = Vector3(at.x, ground.height_at(at.x, at.z) + 0.05, at.z)
	_player.velocity = Vector3.ZERO
	_player.set_aim_direction(spot[1] as Vector3, true)
	if float(spot[2]) > 0.0:
		_player.camera_rig.zoom(float(spot[2]))
	_player.camera_rig.snap()
	_player.reset_physics_interpolation()
