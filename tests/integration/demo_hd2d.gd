extends Node
## Démo du passage au HD-2D : la vraie partie (game.tscn), vue par la caméra fixe du joueur, dans
## chacune des cinq zones, en conversation et pendant une veille ; ou le menu. F6 dans l'éditeur.
##
## Captures : HD2D_VIEW=<vue> tools/screenshot.sh res://tests/integration/demo_hd2d.tscn
## build/shots/hd2d_<vue>.png 60
##   menu        : le menu principal ;
##   village     : l'entrepôt des fées, sa cour, son puits (défaut) ;
##   entrepot    : l'entrepôt entier, de face, zoom au plus loin (planche avant/après) ;
##   forest      : les bois du marais, le terrain d'entraînement et ses rejetons ;
##   dunes       : le bord du Couchant, le cercle de veille et sa cloche ;
##   beach       : la rue du Port, ses façades et le marché ;
##   hill        : la colline des étoiles, son belvédère ;
##   dialogue    : Nygglatho parle, sous le porche ;
##   vigil       : une veille en cours au Couchant (vague 1, deux rejetons) ;
##   (E1, cartes : docs/REFONTE.md, section 7.1)
##   quai        : le bout du quai, devant le panneau de la sortie d'essai (invite « E ») ;
##   fondu       : la même sortie prise (WorldManager.go_to), figée au milieu du fondu au noir ;
##   essai       : la carte d'essai, au Spawn, après son fondu de retour ;
##   retour      : de retour sur le quai par le sentier ouest de la carte d'essai.
## Draw calls et primitives de l'image mesurée sont écrits dans le journal (« HD-2D vue … ») ;
## (E1) les vues de cartes y ajoutent la carte et les mesures de son chargement.

const GAME_SCENE := preload("res://src/game.tscn")
const MAIN_SCENE := preload("res://src/main.tscn")
const MenuScript := preload("res://src/ui/main_menu.gd")
## Où se tient le joueur (zone, position locale, direction regardée) pour chaque vue.
const SPOTS := {
	"village": [&"village", Vector3(-5.0, 0.0, -2.5), Vector3(1.0, 0.0, 0.0)],
	"entrepot": [&"village", Vector3(-10.5, 0.0, -6.5), Vector3(-1.0, 0.0, 0.0)],
	"dialogue": [&"village", Vector3(-7.2, 0.0, -6.2), Vector3(-1.0, 0.0, -1.0)],
	"forest": [&"forest", Vector3(1.0, 0.0, 9.0), Vector3(0.0, 0.0, -1.0)],
	"dunes": [&"dunes", Vector3(10.0, 0.0, 3.0), Vector3(-1.0, 0.0, 0.0)],
	"vigil": [&"dunes", Vector3(2.0, 0.0, 3.0), Vector3(-1.0, 0.0, 0.0)],
	"beach": [&"beach", Vector3(-9.0, 0.0, -3.0), Vector3(1.0, 0.0, 0.0)],
	"hill": [&"hill", Vector3(1.0, 8.0, 3.0), Vector3(1.0, 0.0, -1.0)],
}
const STAGE_FRAME := 6
const DIALOGUE_LINES := 2
const MEASURE_FRAME := 50
## (E1) Vues des cartes, image de leur mesure (le retour recharge l'île : tools/hd2d_shots.sh
## leur laisse MAP_FRAMES images) et opacité où la vue « fondu » se fige.
const MAP_VIEWS: Array[String] = ["quai", "fondu", "essai", "retour"]
const MAP_MEASURE_FRAME := 150
const FADE_HOLD := 0.5

var _view := ""
var _state: Dictionary = {}
var _frame := 0
var _game: Node3D
var _player: Player


func _ready() -> void:
	_view = OS.get_environment("HD2D_VIEW")
	if _view.is_empty():
		_view = "village"
	_state = GameState.to_dict()
	GameState.reset()
	if _view == "menu":
		get_tree().root.set_meta(MenuScript.GESTURE_META, true)
		add_child(MAIN_SCENE.instantiate())
		return
	_game = GAME_SCENE.instantiate() as Node3D
	add_child(_game)
	_player = _game.get_node(^"Player") as Player


func _exit_tree() -> void:
	if get_tree().paused:
		get_tree().paused = false
	WorldManager.fade_time = WorldManager.DEFAULT_FADE_TIME
	GameState.from_dict.call_deferred(_state)


func _process(_delta: float) -> void:
	_frame += 1
	if _frame == STAGE_FRAME and _game != null:
		if _view in MAP_VIEWS:
			_stage_map_view()
		else:
			_stage()
	elif _frame == (MAP_MEASURE_FRAME if _view in MAP_VIEWS else MEASURE_FRAME):
		print(
			(
				"HD-2D vue %s : %d draw calls, %d primitives, %d objets"
				% [
					_view,
					Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
					Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
					Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
				]
			)
		)
		if _view in MAP_VIEWS:
			print(
				(
					"Carte %s, fondu %.2f, joueur %s, caméra %s, dernier changement %s"
					% [
						WorldManager.current_map(),
						WorldManager.fade_alpha(),
						_player.global_position,
						get_viewport().get_camera_3d().global_position,
						WorldManager.last_transition()
					]
				)
			)
	if _view == "fondu" and not get_tree().paused and WorldManager.fade_alpha() >= FADE_HOLD:
		# Au milieu du fondu au noir : tout se fige (le fondu de l'interface reste dessiné).
		get_tree().paused = true


func _stage() -> void:
	var spot: Array = SPOTS.get(_view, SPOTS["village"])
	var zone := _zone(spot[0] as StringName)
	WorldManager.load_zone(spot[0] as StringName)
	_player.global_position = WorldManager.ground_position(
		zone.to_global(spot[1] as Vector3), _player
	)
	_player.velocity = Vector3.ZERO
	_player.set_aim_direction(spot[2] as Vector3, true)
	match _view:
		"entrepot":
			_player.camera_rig.zoom(_player.camera_rig.max_distance)
			_player.camera_rig.snap()
		"dialogue":
			_open_dialogue.call_deferred()
		"forest":
			_freeze_forest()
		"vigil":
			_start_vigil()


## (E1) Vues des cartes : le bout du quai et sa sortie d'essai, le fondu, la carte d'essai, le
## retour par le sentier ouest.
func _stage_map_view() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var island := WorldManager.current_map_node()
	var exit := island.get_node(^"Exits/to_essai") as Node3D
	var front := exit.global_position + Vector3(0.0, -1.5, 1.9)
	_player.global_position = WorldManager.ground_position(front, _player)
	_player.velocity = Vector3.ZERO
	_player.reset_physics_interpolation()
	_player.set_aim_direction(Vector3.FORWARD, true)
	match _view:
		"fondu":
			# La caméra rejoint d'abord le joueur (la place affichée suit la téléportation
			# une image plus tard), puis la sortie est prise, comme avec E.
			for _wait in 20:
				await get_tree().process_frame
			WorldManager.fade_time = 1.2
			(exit as MapExit).use()
		"essai":
			WorldManager.fade_time = 0.0
			WorldManager.go_to(&"essai")
		"retour":
			WorldManager.fade_time = 0.0
			await WorldManager.go_to(&"essai")
			await WorldManager.go_to(WorldManager.LEGACY_MAP, &"from_essai")


func _zone(zone_id: StringName) -> Node3D:
	return _game.get_node(NodePath("World/ile_ancienne/Zones/%s" % zone_id)) as Node3D


## Nygglatho parle (comme E) ; ses premières répliques passent.
func _open_dialogue() -> void:
	var nygglatho := _zone(&"village").get_node(^"NPCs/Nygglatho") as Npc
	nygglatho.interact(_player)
	var box := _game.get_node(^"UI/DialogueBox") as DialogueBox
	for _line in DIALOGUE_LINES:
		box.complete_line()
		if box.is_choosing():
			break
		box.advance()
	box.complete_line()


## Les rejetons des bois, immobiles, chacun dans une pose.
func _freeze_forest() -> void:
	var poses: Array[StringName] = [&"marche", &"repos", &"fouet", &"course"]
	var index := 0
	for child: Node in _zone(&"forest").get_node(^"Enemies").get_children():
		var timere := child as Enemy
		if timere == null:
			continue
		timere.set_physics_process(false)
		timere.visual.set_facing(_player.global_position - timere.global_position)
		timere.visual.play(poses[index % poses.size()])
		index += 1


## La veille commence : la cloche sonne, les rejetons arrivent par les quatre points.
func _start_vigil() -> void:
	var arena := _zone(&"dunes").get_node(^"Arena") as Arena
	arena.director().start()
