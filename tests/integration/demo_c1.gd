extends Node
## (C1) Démonstration des cartes du dehors de la phase 3 (le sentier et le marais, le port
## d'attente) : la vraie partie (game.tscn), posée sur la carte par WorldManager.enter_map, avec la
## lumière d'Atmosphere (E9), le joueur et sa caméra fixe (post-traitement compris).
##
## Captures : C1_MAP=<carte> C1_VIEW=<vue> [C1_MOMENT=nuit] [C1_LIGHT=off] tools/screenshot.sh
## res://tests/integration/demo_c1.tscn build/shots/c1_<carte>_<vue>.png 60
##   sentier : entree (défaut), ouest, milieu, marais, embuscade, berge, est, fourche, ville,
##   large ; port : entree.
## C1_LIGHT=off éteint la lumière magique du joueur (le sentier de nuit sans lumière) ;
## C1_WEATHER=pluie. Draw calls et primitives sont écrits dans le journal (« C1 vue … »).

const GAME_SCENE := preload("res://src/game.tscn")
## Où se tient le joueur (position sur la carte, direction regardée, zoom : distance de la caméra,
## 0 : celle par défaut), par carte et par vue.
const SPOTS := {
	"sentier":
	{
		"entree": [Vector3(6.0, 0.0, 24.0), Vector3(1.0, 0.0, 0.0), 0.0],
		"ouest": [Vector3(14.0, 0.0, 24.0), Vector3(1.0, 0.0, 0.0), 0.0],
		"milieu": [Vector3(40.0, 0.0, 23.0), Vector3(1.0, 0.0, 0.0), 0.0],
		"marais": [Vector3(36.0, -0.5, 12.0), Vector3(0.0, 0.0, -1.0), 0.0],
		"embuscade": [Vector3(34.0, 0.0, 21.0), Vector3(0.0, 0.0, -1.0), 0.0],
		"berge": [Vector3(22.0, 0.0, 20.5), Vector3(0.0, 0.0, -1.0), 0.0],
		"est": [Vector3(70.0, 0.0, 22.0), Vector3(1.0, 0.0, 0.0), 0.0],
		"fourche": [Vector3(60.0, 0.0, 24.5), Vector3(1.0, 0.0, 0.0), 0.0],
		"ville": [Vector3(67.0, -0.5, 34.0), Vector3(0.0, 0.0, 1.0), 0.0],
		"large": [Vector3(40.0, 0.0, 23.0), Vector3(1.0, 0.0, 0.0), 25.0],
	},
	"port": {"entree": [Vector3(5.0, 0.0, 12.0), Vector3(1.0, 0.0, 0.0), 0.0]},
}
const STAGE_FRAME := 4
const MEASURE_FRAME := 50

var _map_id: StringName = &"sentier"
var _view := ""
var _state: Dictionary = {}
var _frame := 0
var _game: Node3D
var _player: Player


func _ready() -> void:
	var map_name := OS.get_environment("C1_MAP")
	if not map_name.is_empty() and SPOTS.has(map_name):
		_map_id = StringName(map_name)
	_view = OS.get_environment("C1_VIEW")
	if _view.is_empty() or not (SPOTS[String(_map_id)] as Dictionary).has(_view):
		_view = "entree"
	_state = GameState.to_dict()
	GameState.reset()
	var moment := OS.get_environment("C1_MOMENT")
	if not moment.is_empty():
		GameState.moment = StringName(moment)
	var weather := OS.get_environment("C1_WEATHER")
	if not weather.is_empty():
		GameState.weather = StringName(weather)
	if OS.get_environment("C1_LIGHT") == "off":
		Atmosphere.player_light_mode = Atmosphere.LIGHT_OFF
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
				"C1 vue %s/%s (%s) : %d draw calls, %d primitives, %d objets"
				% [
					_map_id,
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
	var spot: Array = (SPOTS[String(_map_id)] as Dictionary)[_view]
	var at: Vector3 = spot[0]
	WorldManager.enter_map(_map_id, &"Spawn", at)
	Atmosphere.snap()
	var ground := WorldManager.current_map_node().get_node(^"Ground") as MapGround
	_player.global_position = Vector3(at.x, ground.height_at(at.x, at.z) + 0.05, at.z)
	_player.velocity = Vector3.ZERO
	_player.set_aim_direction(spot[1] as Vector3, true)
	if float(spot[2]) > 0.0:
		_player.camera_rig.zoom(float(spot[2]))
	_player.camera_rig.snap()
	_player.reset_physics_interpolation()
