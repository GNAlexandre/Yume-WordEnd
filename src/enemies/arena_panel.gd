extends Node3D
## Panneau « Affronter les Timeres » de arena.tscn (groupe interactable, PLAN.md section 4).
## Propriétaire : L5. interact() lance la série du WaveDirector de l'Arena parente. Inactif
## pendant une série : invite vide, interact() ignoré et zone d'interaction (InteractArea,
## couche 6) désactivée.

const PROMPT := "Affronter les Timeres"

@onready var _area: Area3D = get_node_or_null(^"InteractArea") as Area3D


func _ready() -> void:
	var director := _director()
	if director != null:
		director.running_changed.connect(_on_running_changed)


func get_prompt() -> String:
	var director := _director()
	return PROMPT if director != null and not director.is_running() else ""


func interact(_player: Node3D) -> void:
	var director := _director()
	if director != null and not director.is_running():
		director.start()


func _director() -> WaveDirector:
	var arena := get_parent() as Arena
	return arena.director() if arena != null else null


func _on_running_changed(running: bool) -> void:
	if _area != null:
		_area.set_deferred(&"monitorable", not running)
