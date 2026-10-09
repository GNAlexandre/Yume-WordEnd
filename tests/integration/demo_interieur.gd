extends Node
## (E3) Démo des intérieurs : la vraie partie (game.tscn), posée dans la carte d'essai du
## rez-de-chaussée de l'entrepôt (src/world/maps/entrepot_rdc_essai/) par
## WorldManager.enter_map, sans fondu ; le joueur, sa caméra fixe (bornée à camera_bounds), son
## post-traitement et la lumière de la carte (src/world/interior_light.tscn, préréglage
## « interieur »). F6 dans l'éditeur.
##
## Captures : INTERIOR_VIEW=<vue> tools/screenshot.sh res://tests/integration/demo_interieur.tscn
## build/e3/interieur_<vue>.png 60
##   couloir     : le couloir, ses plannings, ses écriteaux, ses lampes (défaut) ;
##   refectoire  : le réfectoire, sa grande fenêtre, ses tables ;
##   cuisine     : la cuisine et son fourneau de cristal ;
##   lecture     : la salle de lecture et sa fenêtre à banc ;
##   archives    : les archives, l'océan de papiers, le canapé ;
##   infirmerie  : l'infirmerie, ses lits ;
##   jeux        : la salle de jeux, son tapis ;
##   bains       : la salle de bains, sa cuve, son grand miroir ;
##   entree      : l'entrée, ses patères, la double porte ;
##   nygglatho   : la chambre de Nygglatho, sa cheminée, sa table à thé ;
##   derriere    : le joueur au sud du réfectoire, juste derrière le mur du couloir (coupé) ;
##   table       : le joueur derrière la table de la cuisine ;
##   lit         : le joueur derrière un lit de l'infirmerie ;
##   porte       : le joueur dans la porte de la cloison réfectoire-cuisine (colonne de coupe) ;
##   descente    : la descente vers la salle des armes ;
##   plan        : tout l'étage, caméra au plus loin.
## INTERIOR_PHASE=morning|day|evening|night : moment de la journée (InteriorRoom.apply_phase).
## INTERIOR_CUT=0 : sans la coupe (pour comparer : ce qui cacherait le joueur).
## Draw calls et primitives de l'image mesurée sont écrits dans le journal (« Intérieur vue … »).

const GAME_SCENE := preload("res://src/game.tscn")
const MAP_ID := &"entrepot_rdc_essai"
## Où se tient le joueur (repère de la carte) et où il regarde, pour chaque vue.
const SPOTS := {
	"couloir": [Vector3(13.6, 0.0, 11.7), Vector3(1.0, 0.0, 0.0)],
	"refectoire": [Vector3(8.5, 0.0, 6.4), Vector3(0.0, 0.0, -1.0)],
	"cuisine": [Vector3(18.6, 0.0, 4.4), Vector3(-1.0, 0.0, 0.0)],
	"lecture": [Vector3(24.6, 0.0, 4.2), Vector3(0.0, 0.0, -1.0)],
	"archives": [Vector3(31.4, 0.0, 7.4), Vector3(1.0, 0.0, 0.0)],
	"infirmerie": [Vector3(11.9, 0.0, 17.3), Vector3(0.0, 0.0, -1.0)],
	"jeux": [Vector3(27.0, 0.0, 15.4), Vector3(0.0, 0.0, 1.0)],
	"bains": [Vector3(6.3, 0.0, 16.0), Vector3(-1.0, 0.0, 0.0)],
	"entree": [Vector3(19.0, 0.0, 17.5), Vector3(0.0, 0.0, -1.0)],
	"nygglatho": [Vector3(35.6, 0.0, 17.6), Vector3(0.0, 0.0, -1.0)],
	"derriere": [Vector3(6.6, 0.0, 9.4), Vector3(1.0, 0.0, 0.0)],
	"table": [Vector3(18.0, 0.0, 5.15), Vector3(0.0, 0.0, 1.0)],
	"lit": [Vector3(10.0, 0.0, 17.3), Vector3(0.0, 0.0, 1.0)],
	"porte": [Vector3(15.0, 0.0, 4.0), Vector3(1.0, 0.0, 0.0)],
	"descente": [Vector3(36.5, 0.0, 4.6), Vector3(0.0, 0.0, -1.0)],
	"plan": [Vector3(20.0, 0.0, 12.0), Vector3(0.0, 0.0, 1.0)],
}
const STAGE_FRAME := 3
const MEASURE_FRAME := 50

var _view := ""
var _state: Dictionary = {}
var _frame := 0
var _game: Node3D
var _player: Player


func _ready() -> void:
	_view = OS.get_environment("INTERIOR_VIEW")
	if not SPOTS.has(_view):
		_view = "couloir"
	_state = GameState.to_dict()
	GameState.reset()
	WorldManager.fade_time = 0.0
	_game = GAME_SCENE.instantiate() as Node3D
	add_child(_game)
	_player = _game.get_node(^"Player") as Player


func _exit_tree() -> void:
	WorldManager.fade_time = WorldManager.DEFAULT_FADE_TIME
	GameState.from_dict.call_deferred(_state)


func _process(_delta: float) -> void:
	_frame += 1
	if _frame == STAGE_FRAME:
		_stage()
	elif _frame == MEASURE_FRAME:
		print(
			(
				"Intérieur vue %s : %d draw calls, %d primitives, %d objets"
				% [
					_view,
					Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
					Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
					Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
				]
			)
		)


func _stage() -> void:
	WorldManager.enter_map(MAP_ID)
	var map := WorldManager.current_map_node()
	var room := map.get_node(^"Ground") as InteriorRoom
	var phase := StringName(OS.get_environment("INTERIOR_PHASE"))
	if not phase.is_empty():
		room.apply_phase(phase)
	room.cut_enabled = OS.get_environment("INTERIOR_CUT") != "0"
	var spot: Array = SPOTS[_view]
	_player.global_position = map.to_global(spot[0] as Vector3)
	_player.velocity = Vector3.ZERO
	_player.set_aim_direction(spot[1] as Vector3, true)
	_player.reset_physics_interpolation()
	var rig := _player.camera_rig
	if _view == "plan":
		rig.zoom(rig.max_distance)
	rig.snap()
	room.snap_cut()
