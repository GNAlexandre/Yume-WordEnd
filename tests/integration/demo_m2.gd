extends Node
## Démo de l'intégration M2, avec le contenu de l'acte 1 (tests/integration/demo_m2.tscn, F6 dans
## l'éditeur) : la vraie partie (src/game.tscn), nouvelle partie à l'entrepôt des fées, Chtholly
## devant Nygglatho sous le porche : act1_main est prête à jouer (E pour lui parler, puis Willem,
## les bois au nord par le portail…). Aucune sauvegarde n'est écrite (SaveManager ne suit pas la
## partie : pas de game_loaded) ; GameState est rétabli quand la démo quitte l'arbre.
##
## Captures : M2_SHOT=<vue> tools/screenshot.sh res://tests/integration/demo_m2.tscn <png> 150
##   menu      : le vrai menu de main.tscn, après « Cliquer pour jouer » ;
##   village   : HUD complet à l'entrepôt (cœurs, objectif, nom de zone, invite « Parler ») ;
##   dialogue  : Nygglatho, le matin du grand vent, jusqu'à ses deux choix ;
##   forest    : la clairière des bois, ses rejetons et des pages du livre d'images, l'étape
##               rejetons en cours (2/4) ;
##   reward    : l'acte 1 terminé, six cœurs, inventaire ouvert sur la promesse du gâteau ;
##   arena_end : fin de la veille au Couchant (score, vague atteinte, record).
## La mise en scène compte les images (et non le temps) : même capture quelle que soit la
## vitesse du rendu ; la scène se fige (get_tree().paused) avant la capture.

const GAME_SCENE := preload("res://src/game.tscn")
const MAIN_SCENE := preload("res://src/main.tscn")
const MenuScript := preload("res://src/ui/main_menu.gd")
## Devant Nygglatho, côté place (local à l'entrepôt) ; elle est sous le porche (−9 ; 0,2 ; −8,5).
const NYGGLATHO_FRONT := Vector3(-7.2, 0.0, -6.2)
## Répliques de Nygglatho passées avant ses deux choix (« J'y vais. » / « Le nouveau ? »).
const LINES_BEFORE_CHOICES := 4
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
	elif _frame == BANNER_FRAME and _shot == "reward":
		# Après l'entrée sur la colline (l'inventaire met le jeu en pause).
		(_game.get_node(^"UI/Inventory") as Control).call(&"open")
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
			_place(
				&"village", NYGGLATHO_FRONT, _nygglatho().global_position - _player.global_position
			)
			_face_nygglatho()
			if _shot == "village":
				_player.camera_rig.rotate_view(deg_to_rad(25.0), 0.0)
			elif _shot == "dialogue":
				_player.camera_rig.rotate_view(deg_to_rad(-30.0), 0.0)
				_open_dialogue.call_deferred()


## Joueur au point local `local_position` de la zone, visée `aim`, caméra derrière lui.
func _place(zone_id: StringName, local_position: Vector3, aim: Vector3) -> void:
	var zone := _zone(zone_id)
	_player.global_position = WorldManager.ground_position(zone.to_global(local_position), _player)
	_player.velocity = Vector3.ZERO
	aim.y = 0.0
	_player.set_aim_direction(aim, true)


func _face_nygglatho() -> void:
	var aim := _nygglatho().global_position - _player.global_position
	aim.y = 0.0
	_player.set_aim_direction(aim, true)


func _nygglatho() -> Npc:
	return _zone(&"village").get_node(^"NPCs/Nygglatho") as Npc


func _zone(zone_id: StringName) -> Node3D:
	return _game.get_node(NodePath("Island/Zones/%s" % zone_id)) as Node3D


## Nygglatho parle (comme E) ; ses premières répliques passent jusqu'à ses deux choix.
func _open_dialogue() -> void:
	_nygglatho().interact(_player)
	var box := _game.get_node(^"UI/DialogueBox") as DialogueBox
	for _line in LINES_BEFORE_CHOICES:
		box.complete_line()
		if box.is_choosing():
			break
		box.advance()
	box.complete_line()


## La clairière des bois : ses quatre rejetons (immobiles) et des pages ; deux rejetons déjà
## abattus (étape rejetons d'act1_main, 2/4).
func _stage_forest() -> void:
	GameState.set_flag(&"met_willem")
	GameState.set_quest_step(&"act1_main", &"rejetons", 2)
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


## L'acte 1 terminé (la promesse au sommet) : six cœurs, inventaire ouvert sur la promesse du
## gâteau au beurre, avec le livre d'images et un myosotis.
func _stage_reward() -> void:
	_place(&"hill", Vector3(1.0, 8.0, 2.0), Vector3(1.0, 0.0, -1.0))
	GameState.add_item(&"picture_book", 1)
	GameState.add_item(&"flower_blue", 2)
	GameState.set_quest_state(&"act1_main", &"done")


## Fin de la veille au Couchant, record battu à la vague 5.
func _stage_arena_end() -> void:
	_place(&"dunes", Vector3(4.0, 0.0, 3.0), Vector3.LEFT)
	EventBus.wave_started.emit(&"dunes", 5, 13)
	var best := GameState.record_score(&"dunes", 385, 5)
	EventBus.arena_finished.emit(&"dunes", 385, best)


func _freeze() -> void:
	get_tree().paused = true
