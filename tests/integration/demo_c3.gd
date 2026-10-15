extends Node
## (C3) Démonstration de la colline des étoiles : la vraie partie (game.tscn), posée sur la carte
## par WorldManager.enter_map, avec la lumière d'Atmosphere (E9), le joueur et sa caméra fixe
## (post-traitement compris).
##
## Captures : C3_VIEW=<vue> [C3_MOMENT=couchant] [C3_FREE=1] [C3_LIGHT=off]
## tools/screenshot.sh res://tests/integration/demo_c3.tscn build/shots/c3_<vue>.png 60
##   vues : entree (défaut), pied, rampe1, terrasse_basse, rampe2, terrasse_haute, rampe3, sommet,
##   cercle, bord, arbre, rocher, ouest, est, large.
## C3_FREE=1 laisse le moment de la journée décider de la lumière (la carte est de nuit par son
## `light_preset` : sans cela, C3_MOMENT n'y change rien) ; C3_LIGHT=off éteint la lumière
## magique du joueur ; C3_WEATHER=pluie. Draw calls et primitives sont écrits dans le journal
## (« C3 vue … »).

const GAME_SCENE := preload("res://src/game.tscn")
const MAP_ID := &"colline"
## Où se tient le joueur (position sur la carte, direction regardée, zoom : distance de la caméra,
## 0 : celle par défaut), par vue.
const SPOTS := {
	"entree": [Vector3(20.0, 0.0, 36.5), Vector3(0.0, 0.0, -1.0), 0.0],
	"pied": [Vector3(14.0, 0.0, 33.5), Vector3(0.0, 0.0, -1.0), 0.0],
	"rampe1": [Vector3(14.0, 0.0, 31.0), Vector3(0.0, 0.0, -1.0), 0.0],
	"terrasse_basse": [Vector3(30.0, 0.0, 29.5), Vector3(-1.0, 0.0, 0.0), 0.0],
	"rampe2": [Vector3(26.0, 0.0, 27.5), Vector3(0.0, 0.0, -1.0), 0.0],
	"terrasse_haute": [Vector3(20.0, 0.0, 24.0), Vector3(-1.0, 0.0, 0.0), 0.0],
	"rampe3": [Vector3(16.0, 0.0, 21.5), Vector3(0.0, 0.0, -1.0), 0.0],
	"sommet": [Vector3(20.0, 0.0, 15.0), Vector3(0.0, 0.0, -1.0), 0.0],
	"cercle": [Vector3(20.0, 0.0, 12.0), Vector3(0.0, 0.0, -1.0), 0.0],
	"bord": [Vector3(20.0, 0.0, 5.2), Vector3(0.0, 0.0, -1.0), 0.0],
	"arbre": [Vector3(28.4, 0.0, 10.8), Vector3(1.0, 0.0, 0.0), 0.0],
	"rocher": [Vector3(10.4, 0.0, 16.2), Vector3(-1.0, 0.0, 0.0), 0.0],
	"ouest": [Vector3(6.0, 0.0, 20.0), Vector3(0.0, 0.0, -1.0), 0.0],
	"est": [Vector3(33.0, 0.0, 14.0), Vector3(0.0, 0.0, -1.0), 0.0],
	"large": [Vector3(20.0, 0.0, 14.0), Vector3(0.0, 0.0, -1.0), 26.0],
}
const STAGE_FRAME := 4
const MEASURE_FRAME := 50

var _view := ""
var _state: Dictionary = {}
var _frame := 0
var _game: Node3D
var _player: Player


func _ready() -> void:
	_view = OS.get_environment("C3_VIEW")
	if _view.is_empty() or not SPOTS.has(_view):
		_view = "entree"
	_state = GameState.to_dict()
	GameState.reset()
	var moment := OS.get_environment("C3_MOMENT")
	if not moment.is_empty():
		GameState.moment = StringName(moment)
	var weather := OS.get_environment("C3_WEATHER")
	if not weather.is_empty():
		GameState.weather = StringName(weather)
	if OS.get_environment("C3_LIGHT") == "off":
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
				"C3 vue %s (%s) : %d draw calls, %d primitives, %d objets"
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
	if OS.get_environment("C3_FREE") == "1":
		WorldManager.current_map_node().light_preset = &""
	Atmosphere.snap()
	var ground := WorldManager.current_map_node().get_node(^"Ground") as MapGround
	_player.global_position = Vector3(at.x, ground.height_at(at.x, at.z) + 0.05, at.z)
	_player.velocity = Vector3.ZERO
	_player.set_aim_direction(spot[1] as Vector3, true)
	if float(spot[2]) > 0.0:
		_player.camera_rig.zoom(float(spot[2]))
	_player.camera_rig.snap()
	_player.reset_physics_interpolation()
