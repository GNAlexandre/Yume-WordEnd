extends Node3D
## Panneau de arena.tscn qui lance la série (groupe interactable, PLAN.md section 4).
## Propriétaire : L5. interact() lance la série du WaveDirector de l'Arena parente. Inactif
## pendant une série : invite vide, interact() ignoré et zone d'interaction (InteractArea,
## couche 6) désactivée.
## (Systèmes et textes) Invite et texte du panneau (Label3D « Label ») lus dans les textes de
## l'histoire, data/texts/story.json : arenas/<arena_id>/prompt et sign (DialogueRunner.arena_text,
## sinon arenas/default) ; aux dunes, « Sonner la cloche de veille ».

## Invite de secours si data/texts/story.json n'en donne aucune.
const FALLBACK_PROMPT := "Affronter les Timeres"

@onready var _area: Area3D = get_node_or_null(^"InteractArea") as Area3D


func _ready() -> void:
	var director := _director()
	if director != null:
		director.running_changed.connect(_on_running_changed)
	var label := get_node_or_null(^"Label") as Label3D
	var sign_text := DialogueRunner.arena_text(_arena_id(), "sign")
	if label != null and not sign_text.is_empty():
		label.text = sign_text


func get_prompt() -> String:
	var director := _director()
	return prompt() if director != null and not director.is_running() else ""


## Invite du panneau hors série : le texte « prompt » de son arène.
func prompt() -> String:
	return DialogueRunner.arena_text(_arena_id(), "prompt", FALLBACK_PROMPT)


func interact(_player: Node3D) -> void:
	var director := _director()
	if director != null and not director.is_running():
		director.start()


func _director() -> WaveDirector:
	var arena := get_parent() as Arena
	return arena.director() if arena != null else null


func _arena_id() -> StringName:
	var arena := get_parent() as Arena
	return arena.arena_id if arena != null else &""


func _on_running_changed(running: bool) -> void:
	if _area != null:
		_area.set_deferred(&"monitorable", not running)
