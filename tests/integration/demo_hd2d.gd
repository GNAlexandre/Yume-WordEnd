extends Node
## Démo du passage au HD-2D : la vraie partie (game.tscn), vue par la caméra fixe du joueur, sur
## les cartes de l'île n° 68, en conversation et pendant un combat à la surface ; ou le menu. F6
## dans l'éditeur. (F1) L'ancienne île, ses cinq zones et sa veille sont parties : les vues se
## posent sur les cartes (WorldManager.go_to), le récit coupé (StoryDirector.enabled).
##
## Captures : HD2D_VIEW=<vue> tools/screenshot.sh res://tests/integration/demo_hd2d.tscn
## build/shots/hd2d_<vue>.png 160
##   menu        : le menu principal ;
##   entrepot    : l'entrepôt des fées, au Spawn (défaut) ;
##   port        : le port de l'île n° 68 ;
##   village     : le village ;
##   colline     : la colline ;
##   dialogue    : Nygglatho parle, devant l'entrepôt ;
##   combat      : deux rejetons de Timere à la surface (seule terre où ils viennent) ;
##   (E1, cartes : docs/REFONTE.md, section 7.1)
##   quai        : le rez-de-chaussée d'essai, devant la sortie vers le relief (invite « E ») ;
##   fondu       : la même sortie prise (MapExit.use), figée au milieu du fondu au noir ;
##   arrivee     : la carte d'essai en relief, au marqueur d'arrivée, après son fondu de retour ;
##   retour      : de retour au rez-de-chaussée d'essai par la même sortie.
## Draw calls et primitives de l'image mesurée sont écrits dans le journal (« HD-2D vue … ») ;
## les vues y ajoutent la carte et les mesures de son chargement.

const GAME_SCENE := preload("res://src/game.tscn")
const MAIN_SCENE := preload("res://src/main.tscn")
const MenuScript := preload("res://src/ui/main_menu.gd")
const NPC_SCENE := preload("res://src/npc/npc.tscn")
const ENEMY_SCENE := preload("res://src/enemies/enemy.tscn")
## Carte de chaque vue posée au Spawn.
const MAP_OF_VIEW := {
	"entrepot": &"entrepot",
	"port": &"port",
	"village": &"village",
	"colline": &"colline",
	"dialogue": &"entrepot",
	"combat": &"surface_essai",
}
const DIALOGUE_LINES := 2
const MEASURE_FRAME := 150
const STAGE_FRAME := 6
## Vues de la sortie d'essai et opacité où la vue « fondu » se fige.
const EXIT_VIEWS: Array[String] = ["quai", "fondu", "arrivee", "retour"]
const EXIT_MAP := &"entrepot_rdc_essai"
const EXIT_NAME := ^"Exits/vers_essai_relief"
const FADE_HOLD := 0.5

var _view := ""
var _state: Dictionary = {}
var _story_enabled := true
var _frame := 0
var _game: Node3D
var _player: Player


func _ready() -> void:
	_view = OS.get_environment("HD2D_VIEW")
	if _view.is_empty():
		_view = "entrepot"
	_state = GameState.to_dict()
	GameState.reset()
	if _view == "menu":
		get_tree().root.set_meta(MenuScript.GESTURE_META, true)
		add_child(MAIN_SCENE.instantiate())
		return
	_story_enabled = StoryDirector.enabled
	StoryDirector.enabled = false
	_game = GAME_SCENE.instantiate() as Node3D
	add_child(_game)
	_player = _game.get_node(^"Player") as Player


func _exit_tree() -> void:
	if get_tree().paused:
		get_tree().paused = false
	WorldManager.fade_time = WorldManager.DEFAULT_FADE_TIME
	StoryDirector.enabled = _story_enabled
	GameState.from_dict.call_deferred(_state)


func _process(_delta: float) -> void:
	_frame += 1
	if _frame == STAGE_FRAME and _game != null:
		if _view in EXIT_VIEWS:
			_stage_exit_view()
		else:
			_stage()
	elif _frame == MEASURE_FRAME:
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
		if _game != null:
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


## Vues posées au Spawn d'une carte (sans fondu).
func _stage() -> void:
	var map_id: StringName = MAP_OF_VIEW.get(_view, &"entrepot")
	WorldManager.fade_time = 0.0
	if WorldManager.current_map() != map_id:
		await WorldManager.go_to(map_id)
	match _view:
		"dialogue":
			_open_dialogue()
		"combat":
			_spawn_timeres()


## Nygglatho, posée devant le joueur, parle (comme E) ; ses premières répliques passent.
func _open_dialogue() -> void:
	var nygglatho := NPC_SCENE.instantiate() as Npc
	nygglatho.data = DialogueRunner.find_npc(&"nygglatho")
	WorldManager.current_map_node().add_child(nygglatho)
	nygglatho.global_position = _player.global_position + Vector3(0.0, 0.0, -2.0)
	await get_tree().process_frame
	nygglatho.interact(_player)
	var box := _game.get_node(^"UI/DialogueBox") as DialogueBox
	for _line in DIALOGUE_LINES:
		box.complete_line()
		if box.is_choosing():
			break
		box.advance()
	box.complete_line()


## Deux rejetons de Timere à quelques mètres, immobiles dans une pose.
func _spawn_timeres() -> void:
	var poses: Array[StringName] = [&"marche", &"repos"]
	for index: int in poses.size():
		var timere := ENEMY_SCENE.instantiate() as Enemy
		timere.data = load("res://data/enemies/timere_small.tres") as EnemyData
		timere.drops_enabled = false
		WorldManager.current_map_node().add_child(timere)
		timere.global_position = _player.global_position + Vector3(-1.5 + 3.0 * index, 0.0, -4.0)
		await get_tree().process_frame
		if not is_instance_valid(timere):
			continue
		timere.set_physics_process(false)
		timere.visual.set_facing(_player.global_position - timere.global_position)
		timere.visual.play(poses[index])


## Vues de la sortie d'essai : devant elle, le fondu, l'arrivée, le retour.
func _stage_exit_view() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	WorldManager.fade_time = 0.0
	await WorldManager.go_to(EXIT_MAP)
	var exit := WorldManager.current_map_node().get_node(EXIT_NAME) as MapExit
	var front := exit.global_position + Vector3(0.0, 0.0, 1.9)
	_player.global_position = WorldManager.ground_position(front, _player)
	_player.velocity = Vector3.ZERO
	_player.reset_physics_interpolation()
	_player.set_aim_direction(Vector3.FORWARD, true)
	match _view:
		"fondu":
			# La caméra rejoint d'abord le joueur, puis la sortie est prise, comme avec E.
			for _wait in 20:
				await get_tree().process_frame
			WorldManager.fade_time = 1.2
			exit.use()
		"arrivee":
			await WorldManager.go_to(exit.target_map, exit.target_marker)
		"retour":
			await WorldManager.go_to(exit.target_map, exit.target_marker)
			await WorldManager.go_to(EXIT_MAP, &"from_%s" % exit.target_map)
