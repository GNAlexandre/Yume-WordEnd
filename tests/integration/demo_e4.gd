extends Node
## (E4) Démo de la vie : la vraie partie (game.tscn) posée sur une carte d'essai par
## WorldManager.enter_map, au créneau voulu ; LifeDirector y pose les PNJ des emplois du temps
## (data/life/essai/), qui vivent. F6 dans l'éditeur (F6 en jeu : créneau suivant).
##
## Captures : LIFE_VIEW=<vue> tools/screenshot.sh res://tests/integration/demo_e4.tscn
## build/e4/vie_<vue>.png <images>
##   refectoire : le réfectoire au matin (petit-déjeuner, Willem en cuisine, Nygglatho qui sert) ;
##   marche     : le réfectoire au matin, puis l'après-midi (LIFE_SWITCH images plus tard) : on se
##                lève et on part (salle de lecture, salle de jeux, dehors par la porte d'entrée) ;
##   chat       : le chat dans les hautes herbes d'essai_relief, l'après-midi ;
##   pre        : essai_relief l'après-midi, de plus loin (le chat, le belvédère, le pré) ;
##   avalanche  : la nuit, collées à la porte de Nygglatho ; le joueur arrive par le couloir ;
##   tour       : la tour de fées sur Willem, le soir, dans la salle de jeux ;
##   lecture    : la salle de lecture l'après-midi ;
##   nuit       : la nuit, Willem aux archives.
## LIFE_SEQUENCE=<dossier> : en plus, une image toutes les 0,5 s pendant 5 s
## (<dossier>/<vue>_NN.png), à partir de LIFE_SEQUENCE_FROM images (défaut : 60 ; l'avalanche :
## quand le joueur se met en marche).
## Le journal donne les draw calls (« Vie vue … ») et les mesures du directeur.

const GAME_SCENE := preload("res://src/game.tscn")
const RDC := &"entrepot_rdc_essai"
const RELIEF := &"essai_relief"
## Vue → [carte, créneau, joueur (repère de la carte), regard].
const VIEWS := {
	"refectoire": [RDC, &"matin", Vector3(8.6, 0.0, 9.2), Vector3(0.0, 0.0, -1.0)],
	"marche": [RDC, &"matin", Vector3(13.0, 0.0, 11.6), Vector3(0.0, 0.0, -1.0)],
	"chat": [RELIEF, &"apres_midi", Vector3(40.0, 1.5, 27.0), Vector3(0.0, 0.0, -1.0)],
	"pre": [RELIEF, &"apres_midi", Vector3(33.0, 0.0, 33.0), Vector3(0.0, 0.0, -1.0)],
	"avalanche": [RDC, &"nuit", Vector3(29.0, 0.0, 11.9), Vector3(1.0, 0.0, 0.0)],
	"tour": [RDC, &"soir", Vector3(27.0, 0.0, 20.2), Vector3(0.0, 0.0, -1.0)],
	"lecture": [RDC, &"apres_midi", Vector3(24.6, 0.0, 9.0), Vector3(0.0, 0.0, -1.0)],
	"nuit": [RDC, &"nuit", Vector3(30.0, 0.0, 9.4), Vector3(0.0, 0.0, -1.0)],
}
const STAGE_FRAME := 3
const MEASURE_FRAME := 50
const SEQUENCE_COUNT := 10
const SEQUENCE_STEP := 0.5

var _view := ""
var _state: Dictionary = {}
var _frame := 0
var _game: Node3D
var _player: Player
var _switch_frame := -1
var _sequence_dir := ""
var _sequence_from := 60
var _sequence_index := 0
var _sequence_left := 0.0


func _ready() -> void:
	_view = OS.get_environment("LIFE_VIEW")
	if not VIEWS.has(_view):
		_view = "refectoire"
	_sequence_dir = OS.get_environment("LIFE_SEQUENCE")
	if _view == "avalanche":
		_sequence_from = 1000000
	if OS.get_environment("LIFE_SEQUENCE_FROM").is_valid_int():
		_sequence_from = int(OS.get_environment("LIFE_SEQUENCE_FROM"))
	if _view == "marche":
		var switch := OS.get_environment("LIFE_SWITCH")
		_switch_frame = int(switch) if switch.is_valid_int() else 40
	_state = GameState.to_dict()
	GameState.reset()
	LifeData.use_content(&"essai")
	WorldManager.fade_time = 0.0
	_game = GAME_SCENE.instantiate() as Node3D
	add_child(_game)
	_player = _game.get_node(^"Player") as Player


func _exit_tree() -> void:
	LifeData.use_content(&"")
	WorldManager.fade_time = WorldManager.DEFAULT_FADE_TIME
	GameState.from_dict.call_deferred(_state)


func _process(delta: float) -> void:
	_frame += 1
	if _frame == STAGE_FRAME:
		_stage()
	if _frame == _switch_frame:
		LifeDirector.set_slot(&"apres_midi", 1.0)
	if _frame == MEASURE_FRAME:
		print(
			(
				"Vie vue %s : %d draw calls, %d primitives, %d objets ; %s"
				% [
					_view,
					Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
					Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
					Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
					LifeDirector.stats_text(),
				]
			)
		)
	if (
		not _sequence_dir.is_empty()
		and _frame >= _sequence_from
		and _sequence_index < SEQUENCE_COUNT
	):
		_sequence_left -= delta
		if _sequence_left <= 0.0:
			_sequence_left = SEQUENCE_STEP
			_save_frame()


func _save_frame() -> void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(_sequence_dir)
	var path := _sequence_dir.path_join("%s_%02d.png" % [_view, _sequence_index])
	_sequence_index += 1
	get_viewport().get_texture().get_image().save_png(path)


func _stage() -> void:
	var setup: Array = VIEWS[_view]
	LifeDirector.set_slot(setup[1], 0.0)
	WorldManager.enter_map(setup[0])
	LifeDirector.build_nav_now()
	var map := WorldManager.current_map_node()
	_player.global_position = map.to_global(setup[2] as Vector3)
	_player.velocity = Vector3.ZERO
	_player.set_aim_direction(setup[3] as Vector3, true)
	_player.reset_physics_interpolation()
	_player.camera_rig.snap()
	var room := map.get_node_or_null(^"Ground") as InteriorRoom
	if room != null:
		room.snap_cut()
	if _view == "avalanche":
		_walk_out_of_the_room.call_deferred()


## Le joueur arrive par le couloir à la porte où elles épient.
func _walk_out_of_the_room() -> void:
	for _i: int in 120:
		await get_tree().physics_frame
	if not _sequence_dir.is_empty():
		_sequence_from = _frame
	Input.action_press(&"move_right")
	for _i: int in 80:
		await get_tree().physics_frame
	Input.action_release(&"move_right")
