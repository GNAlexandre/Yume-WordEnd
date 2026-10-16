extends Node3D
## Démo du Lot 10 (tests/integration/demo_l10.tscn, F6 dans l'éditeur) : le HUD au-dessus d'une
## petite scène au couchant, alimenté par ce script qui émet en boucle les signaux de l'EventBus
## (cœurs, invite, objets, charge, cible verrouillée, sauvegarde, mort). Échap ouvre le menu
## pause, F3 la surcouche de performance. `preview` fige un état complet pour les captures
## (tests/stubs/l10_*_preview.tscn). GameState est rétabli quand la démo quitte l'arbre. (F1) Les
## zones, l'objectif de quête, les vagues, le score et la fin de série sont partis avec
## l'ancienne île.

enum Preview { NONE, HUD, PAUSE }

## Durée d'un pas de la démo (s).
const STEP_TIME := 1.8

@export var preview: Preview = Preview.NONE

var _state: Dictionary = {}
var _steps: Array[Callable] = []
var _step: int = 0
var _left: float = 1.0
var _finale_left: float = -INF

@onready var _hud: Control = $UI/HUD
@onready var _hero: Node3D = $Hero
@onready var _timere: Node3D = $Timere


func _ready() -> void:
	_state = GameState.to_dict()
	($Camera3D as Camera3D).look_at_from_position(Vector3(0.0, 3.25, 5.56), Vector3(0.0, 1.0, 0.0))
	_hud.set(&"lock_marker_height", 1.35)
	_steps = [
		func() -> void: EventBus.player_health_changed.emit(5, 5),
		func() -> void: EventBus.interaction_available.emit("Parler"),
		func() -> void: _items_and_prompt(1, ""),
		func() -> void: EventBus.charge_progress.emit(0.5),
		func() -> void: EventBus.charge_progress.emit(1.0),
		func() -> void: _damage(),
		func() -> void: _hero.set(&"target", _timere),
		func() -> void: _release_target(),
		func() -> void: SaveManager.saved.emit(SaveManager.save_path),
		func() -> void: EventBus.player_died.emit(),
		func() -> void: _items_and_prompt(4, ""),
		func() -> void: _reset_items(),
	]
	if preview != Preview.NONE:
		$UI/Help.hide()
		_show_everything.call_deferred()


func _exit_tree() -> void:
	GameState.from_dict(_state)


func _process(delta: float) -> void:
	if preview != Preview.NONE:
		# Pause une fois les fondus d'apparition du HUD finis (la pause les figerait).
		_finale_left -= delta
		if _finale_left <= 0.0 and _finale_left > -INF:
			_finale_left = -INF
			_finale()
		return
	_left -= delta
	if _left <= 0.0:
		_left = STEP_TIME
		_steps[_step].call()
		_step = (_step + 1) % _steps.size()


## État complet du HUD, figé pour une capture.
func _show_everything() -> void:
	_hud.set(&"saved_time", 1000.0)
	_hud.set(&"fade_time", 0.01)
	GameState.add_item(&"test_page", 3)
	EventBus.player_health_changed.emit(4, 6)
	EventBus.charge_progress.emit(1.0)
	EventBus.interaction_available.emit("Parler")
	SaveManager.saved.emit(SaveManager.save_path)
	_hero.set(&"target", _timere)
	if preview == Preview.HUD:
		_hud.call(&"toggle_perf_overlay")
	else:
		_finale_left = 0.3


func _finale() -> void:
	if preview == Preview.PAUSE:
		_hud.get_node(^"%PauseMenu").call(&"open")


func _items_and_prompt(fragments: int, prompt: String) -> void:
	GameState.add_item(&"test_page", fragments)
	EventBus.interaction_available.emit(prompt)


func _damage() -> void:
	EventBus.charge_progress.emit(0.0)
	EventBus.player_damaged.emit(1, _timere)
	EventBus.player_health_changed.emit(4, 5)


func _release_target() -> void:
	EventBus.player_health_changed.emit(5, 5)
	_hero.set(&"target", null)


func _reset_items() -> void:
	GameState.remove_item(&"test_page", GameState.count(&"test_page"))
