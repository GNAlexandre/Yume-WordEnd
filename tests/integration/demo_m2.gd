extends Node
## Démo de l'intégration M2 (tests/integration/demo_m2.tscn, F6 dans l'éditeur) : la vraie partie
## (src/game.tscn), nouvelle partie au village, Chtholly devant la bibliothécaire : la quête des
## pages est prête à jouer (E pour lui parler, la forêt au nord par la porte, cinq pages, retour).
## Aucune sauvegarde n'est écrite (SaveManager ne suit pas la partie : pas de game_loaded) ;
## GameState est rétabli quand la démo quitte l'arbre.
##
## Captures : M2_SHOT=<vue> tools/screenshot.sh res://tests/integration/demo_m2.tscn <png> 150
##   menu      : le vrai menu de main.tscn, après « Cliquer pour jouer » ;
##   village   : HUD complet au village (cœurs, objectif, nom de zone, invite « Parler ») ;
##   dialogue  : la bibliothécaire propose la quête (ses deux choix) ;
##   forest    : la clairière, ses Timeres et ses pages, la quête en cours ;
##   reward    : quête terminée, six cœurs, inventaire ouvert sur le marque-page ;
##   arena_end : fin de série aux dunes (score, vague atteinte, record).
## La mise en scène compte les images (et non le temps) : même capture quelle que soit la
## vitesse du rendu ; la scène se fige (get_tree().paused) avant la capture.

const GAME_SCENE := preload("res://src/game.tscn")
const MAIN_SCENE := preload("res://src/main.tscn")
const MenuScript := preload("res://src/ui/main_menu.gd")
## Devant la bibliothécaire, côté place (local au village) ; elle est à (−3,5 ; 0,2 ; 4).
const LIBRARIAN_FRONT := Vector3(-1.7, 0.0, 5.0)
## Image de la mise en scène, image où le nom de la zone est réaffiché (sa bannière s'efface
## après 3 s), puis image du gel.
const STAGE_FRAME := 8
const BANNER_FRAME := 62
const FREEZE_FRAME := 70

var _shot := ""
var _state: Dictionary = {}
var _frame := 0
var _game: Node3D
var _player: Player


func _ready() -> void:
	_shot = OS.get_environment("M2_SHOT")
	_state = GameState.to_dict()
	GameState.reset()
	if _shot == "menu":
		get_tree().root.set_meta(MenuScript.GESTURE_META, true)
		add_child(MAIN_SCENE.instantiate())
		return
	_game = GAME_SCENE.instantiate() as Node3D
	add_child(_game)
	_player = _game.get_node(^"Player") as Player


func _exit_tree() -> void:
	if get_tree().paused:
		get_tree().paused = false
	# Après la libération de la partie : son inventaire, encore ouvert, ne se rafraîchit plus.
	GameState.from_dict.call_deferred(_state)


func _process(_delta: float) -> void:
	_frame += 1
	if _frame == STAGE_FRAME and _game != null:
		_stage()
	elif _frame == BANNER_FRAME and _shot in ["village", "forest"]:
		EventBus.zone_entered.emit(WorldManager.current_zone())
	elif _frame == FREEZE_FRAME and not _shot.is_empty():
		_freeze()


func _stage() -> void:
	match _shot:
		"forest":
			_stage_forest()
		"reward":
			_stage_reward()
		"arena_end":
			_stage_arena_end()
		_:
			_place(&"village", LIBRARIAN_FRONT, Vector3(-0.9, 0.0, -0.45))
			if _shot == "village":
				GameState.set_quest_state(&"pages", &"active")
				GameState.add_item(&"page_fragment", 2)
				_player.camera_rig.rotate_view(deg_to_rad(25.0), 0.0)
			elif _shot == "dialogue":
				_player.camera_rig.rotate_view(deg_to_rad(-30.0), 0.0)
				_open_dialogue.call_deferred()


## Joueur au point local `local_position` de la zone, visée `aim`, caméra derrière lui.
func _place(zone_id: StringName, local_position: Vector3, aim: Vector3) -> void:
	var zone := _zone(zone_id)
	_player.global_position = WorldManager.ground_position(zone.to_global(local_position), _player)
	_player.velocity = Vector3.ZERO
	_player.set_aim_direction(aim, true)


func _zone(zone_id: StringName) -> Node3D:
	return _game.get_node(NodePath("Island/Zones/%s" % zone_id)) as Node3D


## La bibliothécaire parle (comme E), ses deux premières répliques affichées : la question et
## ses deux choix.
func _open_dialogue() -> void:
	var librarian := _zone(&"village").get_node(^"NPCs/Librarian") as Npc
	librarian.interact(_player)
	var box := _game.get_node(^"UI/DialogueBox") as DialogueBox
	box.complete_line()
	box.advance()
	box.complete_line()


## La clairière de la forêt : ses quatre Timeres (immobiles) et ses pages ; deux pages déjà
## trouvées.
func _stage_forest() -> void:
	GameState.set_quest_state(&"pages", &"active")
	GameState.add_item(&"page_fragment", 2)
	_place(&"forest", Vector3(1.0, 0.0, 8.0), Vector3(-0.05, 0.0, -1.0))
	_player.camera_rig.rotate_view(0.0, deg_to_rad(-6.0))
	_player.camera_rig.zoom(-1.0)
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


## Quête terminée (cinq pages remises) : six cœurs, inventaire ouvert sur le marque-page.
func _stage_reward() -> void:
	_place(&"village", LIBRARIAN_FRONT, Vector3(-0.9, 0.0, -0.45))
	GameState.set_quest_state(&"pages", &"active")
	GameState.add_item(&"page_fragment", 5)
	GameState.add_item(&"shell", 2)
	GameState.add_item(&"flower_blue", 1)
	GameState.set_quest_state(&"pages", &"done")
	(_game.get_node(^"UI/Inventory") as Control).call_deferred(&"open")


## Fin de série aux dunes, record battu à la vague 5.
func _stage_arena_end() -> void:
	_place(&"dunes", Vector3(4.0, 0.0, 3.0), Vector3.LEFT)
	EventBus.wave_started.emit(&"dunes", 5, 13)
	var best := GameState.record_score(&"dunes", 385, 5)
	EventBus.arena_finished.emit(&"dunes", 385, best)


func _freeze() -> void:
	get_tree().paused = true
