extends GutTest
## Base des tests d'intégration M1 (tests/integration/test_m1_*.gd), dont ils héritent par
## chemin (pas de class_name, règle des stubs) : une vraie partie (SaveManager.new_game puis
## src/game.tscn) sur une sauvegarde de test, des appuis réels sur les actions d'entrée et
## une horloge déterministe.
##
## Horloge : en jeu, CharacterVisual avance dans _process (temps réel) et le combat dans
## _physics_process ; sur une machine chargée, les deux temps s'écartent. Ici chaque visuel de
## la partie avance de exactement une image physique par image physique (advance(), API
## publique de L3) : images « coup », fin des animations, états et recharges restent alignés,
## quelle que soit la charge. Le hasard global (IA des Timeres) est semé à chaque test.
##
## Après chaque test : partie libérée, touches relâchées, pause levée, sauvegarde de test
## effacée, chemin de sauvegarde, délai de réapparition, carte de départ et récit rétablis.
## (F1) Une nouvelle partie se pose sur la carte d'essai (start_map_for_test), récit coupé
## (story_for_test) : les tests du récit (tests/stubs/e6_story_test.gd) le rallument. (X-L0) Le
## mode de jeu par défaut (StoryDirector.default_mode) est scénarisé (mode_for_test) :
## les tests écrits avant le mode libre gardent le récit d'E6 et de S2, au bit près.

const GAME_SCENE := preload("res://src/game.tscn")
const ENEMY_SCENE := preload("res://src/enemies/enemy.tscn")
## Actions de jeu relâchées après chaque test.
const ACTIONS: Array[StringName] = [
	&"move_left",
	&"move_right",
	&"move_forward",
	&"move_back",
	&"run",
	&"jump",
	&"attack",
	&"charge",
	&"interact",
	&"lock_target",
]
## Graine du hasard global (IA des Timeres) au début de chaque test.
const RANDOM_SEED := 20261005

var game: Node3D
var player: Player
var combat: PlayerCombat
var health: Health

## Identifiants des CharacterVisual de la partie (instance_from_id : null une fois libérés).
var _visuals: Array[int] = []
## Branchements sur des signaux d'autoload ([signal, callable]), défaits après chaque test.
var _listeners: Array[Array] = []
var _previous_path: String
var _previous_autosave: float
var _previous_respawn: float
var _previous_start: StringName
var _previous_story: bool
var _previous_mode: StringName


func before_each() -> void:
	seed(RANDOM_SEED)
	_previous_path = SaveManager.save_path
	_previous_autosave = SaveManager.autosave_delay
	_previous_respawn = WorldManager.respawn_delay
	# (E6) Une nouvelle partie ouvre l'acte 1 à l'entrepôt ; (F1) ces tests partent de la carte
	# d'essai, sans le récit, sauf ceux qui le demandent.
	_previous_start = WorldManager.start_map
	WorldManager.start_map = start_map_for_test()
	_previous_story = StoryDirector.enabled
	StoryDirector.enabled = story_for_test()
	_previous_mode = StoryDirector.default_mode
	StoryDirector.default_mode = mode_for_test()
	SaveManager.close_game(false)
	SaveManager.save_path = save_file()
	_delete_save_files()
	GameState.reset()
	_visuals.clear()
	get_tree().node_added.connect(_on_node_added)
	get_tree().physics_frame.connect(_on_physics_frame)


func after_each() -> void:
	for listener: Array in _listeners:
		var bus_signal: Signal = listener[0]
		if bus_signal.is_connected(listener[1]):
			bus_signal.disconnect(listener[1])
	_listeners.clear()
	for action: StringName in ACTIONS:
		Input.action_release(action)
	get_tree().node_added.disconnect(_on_node_added)
	get_tree().physics_frame.disconnect(_on_physics_frame)
	get_tree().paused = false
	if is_instance_valid(game):
		game.free()
	game = null
	_visuals.clear()
	SaveManager.close_game(false)
	_delete_save_files()
	SaveManager.save_path = _previous_path
	SaveManager.autosave_delay = _previous_autosave
	WorldManager.respawn_delay = _previous_respawn
	WorldManager.start_map = _previous_start
	StoryDirector.enabled = _previous_story
	StoryDirector.default_mode = _previous_mode
	StoryDirector.next_game_mode = &""
	SaveManager.close_game(false)
	GameState.reset()


## (E6) Carte d'une nouvelle partie pendant le test : (F1) la carte d'essai (une prairie plate
## de l'île n° 68, ses sorties et ses quais) ; les tests de l'acte en jours la redéfinissent
## (WorldManager.START_MAP), ceux des Timeres prennent la surface (surface_essai).
func start_map_for_test() -> StringName:
	return &"essai"


## (F1) Récit (StoryDirector.enabled) pendant le test : coupé, une nouvelle partie n'ouvre pas
## l'acte ; les tests du récit le rallument.
func story_for_test() -> bool:
	return false


## (X-L0) Mode de jeu par défaut pendant le test (StoryDirector.default_mode) : scénarisé ;
## les tests du mode libre (tests/integration/test_free_start.gd) le redéfinissent.
func mode_for_test() -> StringName:
	return StoryPacing.SCENARIO


## Sauvegarde propre au script de test.
func save_file() -> String:
	return "user://test_m1_%s.json" % get_script().resource_path.get_file().get_basename()


## Nouvelle partie avec Chtholly puis src/game.tscn : le joueur est au Spawn de la carte de départ.
func start_game() -> void:
	SaveManager.new_game(&"chtholly")
	game = GAME_SCENE.instantiate() as Node3D
	add_child(game)
	player = game.get_node(^"Player") as Player
	combat = player.combat
	health = player.health
	await wait_physics_frames(3)


## Branche callable sur un signal d'autoload (EventBus…) jusqu'à la fin du test : un
## branchement oublié survivrait au test et à la partie qu'il observe.
func listen(bus_signal: Signal, callable: Callable) -> void:
	bus_signal.connect(callable)
	_listeners.append([bus_signal, callable])


## Carte courante (WorldManager.current_map_node()).
func current_map() -> Map:
	return WorldManager.current_map_node()


## Place le joueur au point `at` de la carte courante (repère de la carte, posé au sol), visée
## `aim`, caméra derrière lui.
func place_player(at: Vector3, aim: Vector3) -> void:
	var target := current_map().to_global(at)
	player.global_position = WorldManager.ground_position(target, player)
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	player.set_aim_direction(aim, true)
	await wait_physics_frames(3)


## Timere libre (sans objet lâché) de type enemy_id au point global `at`, ajouté à la partie ;
## frozen : IA arrêtée (cible immobile, sans attaque). Sur une île qui n'admet pas les Timeres
## (l'île n° 68, la carte d'essai), il se retire aussitôt : les tests de combat partent de la
## surface (start_map_for_test : surface_essai).
func spawn_enemy(enemy_id: StringName, at: Vector3, frozen: bool = false) -> Enemy:
	var enemy := ENEMY_SCENE.instantiate() as Enemy
	enemy.data = load("res://data/enemies/%s.tres" % enemy_id) as EnemyData
	enemy.drops_enabled = false
	enemy.position = game.to_local(at)
	game.add_child(enemy)
	if frozen:
		enemy.set_physics_process(false)
	return enemy


## Point global à `distance` m devant le joueur (dans sa visée), au ras du sol.
func ahead(distance: float, side: float = 0.0) -> Vector3:
	var aim := player.aim_direction()
	var right := aim.cross(Vector3.UP)
	return player.global_position + aim * distance + right * side


## Appui bref sur une action (relâchée frames images plus tard), aligné sur une image physique
## pour que Player.read_commands() le voie comme « just pressed ».
func press(action: StringName, frames: int = 1) -> void:
	await wait_physics_frames(1)
	Input.action_press(action)
	await wait_physics_frames(frames)
	Input.action_release(action)


## Maintient action pendant seconds secondes de temps de jeu, puis la relâche.
func hold(action: StringName, seconds: float) -> void:
	await wait_physics_frames(1)
	Input.action_press(action)
	await wait_seconds(seconds)
	Input.action_release(action)


## (HD-2D) Avance vers direction (plan du sol) : la caméra fixe regarde le nord, les quatre
## actions de déplacement sont donc tenues avec la force qui mène exactement dans cette direction
## (est = move_right, sud = move_back). Les relâcher avec release_move().
func hold_toward(direction: Vector3) -> void:
	var flat := Vector3(direction.x, 0.0, direction.z).normalized()
	_hold_axis(&"move_right", flat.x)
	_hold_axis(&"move_left", -flat.x)
	_hold_axis(&"move_back", flat.z)
	_hold_axis(&"move_forward", -flat.z)


## Relâche les quatre actions de déplacement.
func release_move() -> void:
	for action: StringName in [&"move_left", &"move_right", &"move_forward", &"move_back"]:
		Input.action_release(action)


func _hold_axis(action: StringName, strength: float) -> void:
	if strength > 0.001:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)


## Distance horizontale entre deux points.
func flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _delete_save_files() -> void:
	var path := save_file()
	for file: String in [
		path,
		path + SaveManager.BACKUP_SUFFIX,
		path + SaveManager.TEMP_SUFFIX,
		path + SaveManager.LEGACY_SUFFIX,
	]:
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)


func _on_node_added(node: Node) -> void:
	var visual := node as CharacterVisual
	if visual != null and not _visuals.has(visual.get_instance_id()):
		_visuals.append(visual.get_instance_id())
		# Après son _ready (qui active _process) : plus d'horloge en temps réel.
		visual.ready.connect(visual.set_process.bind(false), CONNECT_ONE_SHOT)


func _on_physics_frame() -> void:
	var step := 1.0 / Engine.physics_ticks_per_second
	for id: int in _visuals.duplicate():
		var visual := instance_from_id(id) as CharacterVisual
		if visual == null:
			_visuals.erase(id)
		elif visual.is_inside_tree() and visual.can_process():
			visual.advance(step)
