extends Node
## Racine du jeu (run/main_scene) : menu principal, puis écran de chargement, puis la partie.
##
## Passe au jeu sur EventBus.game_loaded (émis par SaveManager.new_game, load_game,
## import_json) et seulement sur ce signal. Fichier d'intégration (Lot 0, intégration M2) : les
## lots ne le modifient pas (besoin → docs/CONTRACT_REQUESTS.md).
## Chargement : si la racine de loading.tscn a load_scene(path) (L9), elle charge src/game.tscn
## en plusieurs images (dépendances d'abord) et sa barre avance vraiment, sans fil d'exécution
## (export Web mono-thread, docs/web.md) ; sinon set_progress(0) puis set_progress(1) autour d'un
## load() d'un bloc, si elle a set_progress(ratio: float).
## Retour au menu : le menu pause (L10) écrit la partie, appelle SaveManager.close_game(false)
## puis recharge main.tscn (reload_current_scene) ; show_menu() fait de même pour un appel direct.

const MENU_SCENE := "res://src/ui/main_menu.tscn"
const LOADING_SCENE := "res://src/ui/loading.tscn"
const GAME_SCENE := "res://src/game.tscn"

## Travail de chargement par image (ms) confié à Loading.load_scene() ; 0 : une dépendance par
## image (les tests voient ainsi la barre avancer même quand tout est déjà en cache).
@export var loading_budget_ms: float = 50.0

var _menu: Node
var _game: Node
var _loading: Node
## Change à chaque passage au menu : un chargement dépassé n'ajoute pas sa partie.
var _generation: int = 0


func _ready() -> void:
	EventBus.game_loaded.connect(_on_game_loaded)
	show_menu()


## Affiche le menu principal. La partie en cours est écrite si elle a changé, SaveManager cesse
## de la suivre (aucune auto-sauvegarde au menu), puis elle est libérée.
func show_menu() -> void:
	_generation += 1
	if _game != null:
		if SaveManager.is_game_loaded():
			SaveManager.save_on_leave()
		SaveManager.close_game(false)
		_game.queue_free()
		_game = null
	if _menu == null:
		_menu = (load(MENU_SCENE) as PackedScene).instantiate()
		add_child(_menu)


## Libère le menu (et une partie en cours), affiche l'écran de chargement le temps de charger
## la partie, puis l'ajoute. Une demande pendant un chargement est servie par lui : la partie
## lit GameState à son _ready, après le chargement.
func start_game() -> void:
	if _menu != null:
		_menu.queue_free()
		_menu = null
	if _game != null:
		_game.queue_free()
		_game = null
	if _loading != null:
		return
	var generation := _generation
	var loading := (load(LOADING_SCENE) as PackedScene).instantiate()
	_loading = loading
	add_child(loading)
	_set_progress(loading, 0.0)
	await get_tree().process_frame
	var game_scene: PackedScene
	if loading.has_method(&"load_scene"):
		var loaded: Variant = await loading.call(&"load_scene", GAME_SCENE, loading_budget_ms)
		game_scene = loaded as PackedScene
	else:
		game_scene = load(GAME_SCENE) as PackedScene
		_set_progress(loading, 1.0)
	_loading = null
	loading.queue_free()
	if generation != _generation or game_scene == null:
		return
	_game = game_scene.instantiate()
	add_child(_game)


## Écran de chargement affiché (null hors chargement).
func loading_screen() -> Node:
	return _loading


## Partie en cours (null au menu et pendant le chargement).
func game() -> Node:
	return _game


func _set_progress(loading: Node, ratio: float) -> void:
	if loading.has_method(&"set_progress"):
		loading.call(&"set_progress", ratio)


func _on_game_loaded() -> void:
	start_game()
