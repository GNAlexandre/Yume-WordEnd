extends Node
## (V1) Démo de la vie de l'entrepôt sur les vraies cartes (data/life/ile_68/) : la vraie partie
## (game.tscn) posée par WorldManager.enter_map à un créneau, un jour et un temps voulus ;
## LifeDirector
## y pose les PNJ, qui vivent. Les cartes d'essai d'E4 ont leur démonstration (demo_e4.tscn).
##
## Captures : V1_VIEW=<vue> tools/screenshot.sh res://tests/integration/demo_v1.tscn
## build/v1/<vue>.png <images>
## Vues (carte, créneau, jour, temps ; voir VIEWS) : refectoire_matin, refectoire_midi, cour_matin
## (le
## grand arbre, le potager, les corvées), cour_apres_midi (le chat, le banc du porche), herbes_chat,
## couloir_course et tour et bains (soir), lecture (après-midi), veillee et archives et dortoirs
## (nuit),
## avalanche (étage, après-midi), toit_aube (le linge), toit_nuit, jeux_pluie, champ_boue (après
## la pluie),
## cercle (jour 12, au couchant), infirmerie (jour 8), cour_aube, cour_soir, cour_nuit, rdc_aube,
## etage_aube.
## V1_SEQUENCE=<dossier> : en plus, une image toutes les 0,5 s pendant 5 s
## (<dossier>/<vue>_NN.png), à
## partir de V1_SEQUENCE_FROM images (défaut : 90).
## V1_SWITCH=<créneau> : au bout de V1_SWITCH_FRAME images (défaut 40), passe à ce créneau (on
## marche).
## Le journal donne les draw calls (« Vie vue … ») et les mesures du directeur.

const GAME_SCENE := preload("res://src/game.tscn")
const RDC := &"entrepot_rdc"
const ETAGE := &"entrepot_etage"
const TOIT := &"entrepot_toit"
const DEHORS := &"entrepot"
const NORTH := Vector3(0.0, 0.0, -1.0)
## Vue → [carte, créneau, joueur (repère de la carte ; y : au sol), regard, jour, temps].
const VIEWS := {
	"refectoire_matin": [RDC, &"matin", Vector3(11.0, 0.0, 5.6), NORTH, 0, &"clair"],
	"refectoire_midi": [RDC, &"midi", Vector3(11.0, 0.0, 5.6), NORTH, 0, &"clair"],
	"cour_matin": [DEHORS, &"matin", Vector3(58.0, 0.0, 37.0), NORTH, 0, &"clair"],
	"cour_apres_midi": [DEHORS, &"apres_midi", Vector3(42.0, 0.0, 41.0), NORTH, 0, &"clair"],
	"herbes_chat": [DEHORS, &"apres_midi", Vector3(24.0, 0.0, 40.0), NORTH, 0, &"clair"],
	"couloir_course": [RDC, &"soir", Vector3(20.0, 0.0, 9.6), NORTH, 0, &"clair"],
	"tour": [RDC, &"soir", Vector3(22.0, 0.0, 14.0), NORTH, 0, &"clair"],
	"bains": [RDC, &"soir", Vector3(5.0, 0.0, 12.2), NORTH, 0, &"clair"],
	"lecture": [RDC, &"apres_midi", Vector3(28.0, 0.0, 6.6), NORTH, 0, &"clair"],
	"veillee": [RDC, &"nuit", Vector3(11.0, 0.0, 5.6), NORTH, 0, &"clair"],
	"archives": [RDC, &"nuit", Vector3(24.8, 0.0, 6.0), NORTH, 0, &"clair"],
	"dortoirs": [ETAGE, &"nuit", Vector3(12.0, 0.0, 12.0), NORTH, 0, &"clair"],
	"avalanche": [ETAGE, &"apres_midi", Vector3(17.0, 0.0, 9.5), NORTH, 0, &"clair"],
	"toit_aube": [TOIT, &"aube", Vector3(11.0, 0.0, 9.0), NORTH, 0, &"clair"],
	"toit_nuit": [TOIT, &"nuit", Vector3(11.0, 0.0, 9.0), NORTH, 10, &"clair"],
	"jeux_pluie": [RDC, &"apres_midi", Vector3(22.0, 0.0, 14.0), NORTH, 0, &"pluie"],
	"champ_boue": [DEHORS, &"apres_midi", Vector3(75.0, 0.0, 28.0), NORTH, 10, &"boue"],
	"cercle": [DEHORS, &"soir", Vector3(44.0, 0.0, 42.0), NORTH, 12, &"clair"],
	"infirmerie": [RDC, &"apres_midi", Vector3(26.0, 0.0, 9.5), NORTH, 8, &"clair"],
	"cour_aube": [DEHORS, &"aube", Vector3(42.0, 0.0, 41.0), NORTH, 0, &"clair"],
	"cour_soir": [DEHORS, &"soir", Vector3(42.0, 0.0, 41.0), NORTH, 0, &"clair"],
	"cour_nuit": [DEHORS, &"nuit", Vector3(42.0, 0.0, 41.0), NORTH, 0, &"clair"],
	"rdc_aube": [RDC, &"aube", Vector3(24.0, 0.0, 9.5), NORTH, 0, &"clair"],
	"etage_aube": [ETAGE, &"aube", Vector3(12.0, 0.0, 12.0), NORTH, 0, &"clair"],
}
const STAGE_FRAME := 3
const MEASURE_FRAME := 80
const SEQUENCE_COUNT := 10
const SEQUENCE_STEP := 0.5

var _view := ""
var _state: Dictionary = {}
var _frame := 0
var _game: Node3D
var _player: Player
var _switch_frame := -1
var _switch_slot: StringName = &""
var _sequence_dir := ""
var _sequence_from := 90
var _sequence_index := 0
var _sequence_left := 0.0


func _ready() -> void:
	_view = OS.get_environment("V1_VIEW")
	if not VIEWS.has(_view):
		_view = "refectoire_matin"
	_sequence_dir = OS.get_environment("V1_SEQUENCE")
	if OS.get_environment("V1_SEQUENCE_FROM").is_valid_int():
		_sequence_from = int(OS.get_environment("V1_SEQUENCE_FROM"))
	var switch := OS.get_environment("V1_SWITCH")
	if LifeSlots.is_slot(StringName(switch)):
		_switch_slot = StringName(switch)
		var at := OS.get_environment("V1_SWITCH_FRAME")
		_switch_frame = int(at) if at.is_valid_int() else 40
	_state = GameState.to_dict()
	GameState.reset()
	WorldManager.fade_time = 0.0
	_game = GAME_SCENE.instantiate() as Node3D
	add_child(_game)
	_player = _game.get_node(^"Player") as Player


func _exit_tree() -> void:
	WorldManager.fade_time = WorldManager.DEFAULT_FADE_TIME
	GameState.from_dict.call_deferred(_state)


func _process(delta: float) -> void:
	_frame += 1
	if _frame == STAGE_FRAME:
		_stage()
	if _frame == _switch_frame:
		LifeDirector.set_slot(_switch_slot, 1.0)
	if _frame == MEASURE_FRAME:
		print(
			(
				"Vie vue %s : %d draw calls, %d primitives, %d objets ; %d PNJ ; %s"
				% [
					_view,
					Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
					Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
					Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
					LifeDirector.actors().size(),
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
	GameState.day = int(setup[4])
	var weather: StringName = setup[5]
	if weather == &"pluie":
		Atmosphere.set_weather(&"pluie", 0.0)
	elif weather == &"boue":
		# La pluie vient de cesser : le drapeau d'après la pluie, la boue du champ.
		Atmosphere.set_weather(&"pluie", 0.0)
		Atmosphere.set_weather(&"clair", 0.0)
	LifeDirector.set_slot(setup[1], 0.0)
	var entered := WorldManager.enter_map(setup[0])
	print(
		(
			"V1 : carte %s posée : %s, île %s, créneau %s, jour %d"
			% [setup[0], entered, GameState.island, LifeSlots.current(), GameState.day]
		)
	)
	LifeDirector.build_nav_now()
	var map := WorldManager.current_map_node()
	var at: Vector3 = setup[2]
	var nav := LifeDirector.nav()
	if nav != null:
		at.y = nav.height_at(at.x, at.z)
	_player.global_position = map.to_global(at)
	_player.velocity = Vector3.ZERO
	_player.set_aim_direction(setup[3] as Vector3, true)
	_player.reset_physics_interpolation()
	_player.camera_rig.snap()
	var room := map.get_node_or_null(^"Ground") as InteriorRoom
	if room != null:
		room.snap_cut()
