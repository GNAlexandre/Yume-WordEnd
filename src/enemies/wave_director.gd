class_name WaveDirector
extends Node
## Vagues d'une arène, lues dans data/waves/<arena_id>.json (PLAN.md section 4).
## Propriétaire : L5. Un par arène : enfant « WaveDirector » de arena.tscn.
##
## Squelette du Lot 0 : lecture du JSON et compose() pour les vagues listées. L5 ajoute le
## generator (3 + 2n, poids, Grand un à la fois, bonus de vitesse et de PV), l'apparition
## aux points SpawnN/S/E/W, le score (enemy_killed, bonus 50 × n), le soin toutes les deux
## vagues (EventBus.player_heal_requested), record_score et arena_finished.

const WAVES_DIR := "res://data/waves"

## Arène ; vide = celui de l'Arena parente.
@export var arena_id: StringName = &""

var _config: Dictionary = {}
var _wave: int = 0
var _running: bool = false


func _ready() -> void:
	if arena_id.is_empty() and get_parent() is Arena:
		arena_id = (get_parent() as Arena).arena_id
	if not arena_id.is_empty():
		load_config("%s/%s.json" % [WAVES_DIR, arena_id])


## Charge un fichier de vagues (format de PLAN.md section 4).
func load_config(path: String) -> Error:
	if not ResourceLoader.exists(path):
		return ERR_FILE_NOT_FOUND
	var json := load(path) as JSON
	if json == null or not json.data is Dictionary:
		return ERR_PARSE_ERROR
	_config = json.data
	return OK


## Configuration lue (copie).
func config() -> Dictionary:
	return _config.duplicate(true)


func start() -> void:
	_running = true
	_wave = 0


func stop() -> void:
	_running = false


func is_running() -> bool:
	return _running


## Numéro de la vague en cours (0 avant la première).
func current_wave() -> int:
	return _wave


## Identifiants des ennemis de la vague (1 = première) : liste explicite de "waves",
## puis "generator" au-delà (L5).
func compose(wave: int) -> Array[StringName]:
	var result: Array[StringName] = []
	var waves: Array = _config.get("waves", [])
	if wave < 1 or wave > waves.size():
		return result
	var enemies: Dictionary = (waves[wave - 1] as Dictionary).get("enemies", {})
	for enemy_id: String in enemies:
		for _i in int(enemies[enemy_id]):
			result.append(StringName(enemy_id))
	return result
