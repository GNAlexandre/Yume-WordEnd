extends Node
## Racine du jeu (run/main_scene) : menu principal, puis écran de chargement, puis la partie.
##
## Passe au jeu sur EventBus.game_loaded (émis par SaveManager.new_game, load_game,
## import_json) et seulement sur ce signal. Fichier d'intégration du Lot 0 : les lots ne le
## modifient pas (besoin → docs/CONTRACT_REQUESTS.md).
## loading.tscn : si sa racine a une méthode set_progress(ratio: float), elle est appelée
## (0 puis 1) pendant le chargement de src/game.tscn.

const MENU_SCENE := "res://src/ui/main_menu.tscn"
const LOADING_SCENE := "res://src/ui/loading.tscn"
const GAME_SCENE := "res://src/game.tscn"

var _menu: Node
var _game: Node


func _ready() -> void:
	EventBus.game_loaded.connect(_on_game_loaded)
	show_menu()


## Affiche le menu principal (et libère la partie en cours).
func show_menu() -> void:
	if _game != null:
		_game.queue_free()
		_game = null
	if _menu == null:
		_menu = (load(MENU_SCENE) as PackedScene).instantiate()
		add_child(_menu)


## Libère le menu, affiche l'écran de chargement le temps de charger la partie.
func start_game() -> void:
	if _menu != null:
		_menu.queue_free()
		_menu = null
	if _game != null:
		_game.queue_free()
		_game = null
	var loading := (load(LOADING_SCENE) as PackedScene).instantiate()
	add_child(loading)
	_set_progress(loading, 0.0)
	await get_tree().process_frame
	var game_scene := load(GAME_SCENE) as PackedScene
	_set_progress(loading, 1.0)
	_game = game_scene.instantiate()
	add_child(_game)
	loading.queue_free()


func _set_progress(loading: Node, ratio: float) -> void:
	if loading.has_method(&"set_progress"):
		loading.call(&"set_progress", ratio)


func _on_game_loaded() -> void:
	start_game()
