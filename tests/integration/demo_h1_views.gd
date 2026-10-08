extends Node
## (H1, H6) Planches livrées dans la vraie partie (game.tscn), vues par la caméra fixe du joueur au
## bord du Couchant : une rangée par personnage, chacun de face, de profil droit, de dos et de
## profil gauche (le miroir du droit). F6 dans l'éditeur.
##
## Captures : H1_VIEW=<vue> tools/screenshot.sh res://tests/integration/demo_h1_views.tscn
## build/shots/h1_<vue>.png 60
##   vues   : Chtholly (repos, puis l'image « coup » de l'attaque) et le Timere (repos), défaut ;
##   pnj    : les PNJ de l'acte 1 et les skins jouables, de face puis de dos (repos) ;
##   parle  : les mêmes PNJ, de face puis de profil, en conversation (parle).

const GAME_SCENE := preload("res://src/game.tscn")
const VISUAL := preload("res://src/visuals/character_visual.tscn")
const CHTHOLLY := preload("res://data/skins/chtholly.tres")
const TIMERE := preload("res://data/enemies/visuals/timere.tres")
const NPC_VISUALS := "res://data/npcs/visuals/%s.tres"
const SKINS := "res://data/skins/%s.tres"
## Où se tient la rangée (zone, position locale du joueur).
const SPOT := [&"dunes", Vector3(6.0, 0.0, 3.0)]
## Directions : face (vers la caméra), profil droit, dos, profil gauche.
const FACINGS: Array[Vector3] = [Vector3.BACK, Vector3.RIGHT, Vector3.FORWARD, Vector3.LEFT]
const NPCS: Array[String] = [
	"nygglatho",
	"willem",
	"ithea",
	"nephren",
	"tiat",
	"pannibal",
	"collon",
	"lakhesh",
	"almita",
	"limeskin",
	"cat_waiter",
	"ramikeldi",
	"snack_vendor",
	"baker",
	"ferryman",
	"egg_vendor",
	"garde_lookout",
]
const STAGE_FRAME := 6

var _view := ""
var _state: Dictionary = {}
var _frame := 0
var _game: Node3D
var _player: Player


func _ready() -> void:
	_view = OS.get_environment("H1_VIEW")
	if _view.is_empty():
		_view = "vues"
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


func _stage() -> void:
	var zone := _game.get_node(NodePath("Island/Zones/%s" % SPOT[0])) as Node3D
	WorldManager.load_zone(SPOT[0] as StringName)
	_player.global_position = WorldManager.ground_position(
		zone.to_global(SPOT[1] as Vector3), _player
	)
	_player.velocity = Vector3.ZERO
	_player.set_physics_process(false)
	_player.visual.visible = false
	(_game.get_node(^"UI") as CanvasLayer).visible = false
	if _view == "vues":
		_player.camera_rig.zoom(-100.0)
	_player.camera_rig.snap()
	var base := _player.global_position
	match _view:
		"pnj":
			_npc_rows(zone, base, [Vector3.BACK, Vector3.FORWARD], &"repos")
		"parle":
			_npc_rows(zone, base, [Vector3.BACK, Vector3.RIGHT], &"parle")
		_:
			_row(zone, base + Vector3(-3.0, 0.0, -2.2), CHTHOLLY, &"repos", 0)
			_row(zone, base + Vector3(-3.0, 0.0, 0.0), CHTHOLLY, &"attaque", 2)
			_row(zone, base + Vector3(-3.0, 0.0, 2.2), TIMERE, &"repos", 0)


## Un personnage par direction de FACINGS, figé sur l'image frame de anim, de gauche à droite.
func _row(zone: Node3D, start: Vector3, skin: SkinData, anim: StringName, frame: int) -> void:
	for i in FACINGS.size():
		_place(zone, start + Vector3(2.0 * i, 0.0, 0.0), skin, FACINGS[i], anim, frame)


## Tous les PNJ (et skins jouables) sur deux rangées par direction.
func _npc_rows(zone: Node3D, base: Vector3, facings: Array[Vector3], anim: StringName) -> void:
	var skins: Array[SkinData] = []
	for npc_id: String in NPCS:
		skins.append(load(NPC_VISUALS % npc_id) as SkinData)
	for skin_id: String in ["nopht", "rhantolk"]:
		skins.append(load(SKINS % skin_id) as SkinData)
	var per_row := 10
	for f in facings.size():
		for i in skins.size():
			var row := f * 2 + floori(float(i) / per_row)
			var spot := base + Vector3(-6.3 + 1.4 * (i % per_row), 0.0, -3.6 + 2.4 * row)
			_place(zone, spot, skins[i], facings[f], anim, 0)


func _place(
	zone: Node3D, spot: Vector3, skin: SkinData, facing: Vector3, anim: StringName, frame: int
) -> void:
	var visual := VISUAL.instantiate() as CharacterVisual
	zone.add_child(visual)
	visual.global_position = spot
	visual.set_skin(skin)
	visual.set_facing(facing)
	visual.show_frame(anim if visual.has_animation(anim) else &"repos", frame)
