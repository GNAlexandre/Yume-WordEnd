extends Control
## (E6) L'indice discret (docs/REFONTE.md, 6.2 ; ACTE1.md, 0.1) : enfant StoryHint du HUD (groupe
## GROUP), une ligne courte en bas de l'écran, sans marqueur sur la carte. Quand le récit attend
## quelque chose (StoryDirector.hint_changed), elle paraît show_time s puis s'efface ; recall() la
## rappelle (fermeture du calendrier). Cachée pendant un dialogue. Propriétaire : E6.

const GROUP := &"story_hint"
## Durée d'affichage (s) et des fondus (s).
@export var show_time: float = 6.0
@export var fade_time: float = 0.4

var _tween: Tween
var _in_dialogue: bool = false

@onready var _label: Label = %HintLabel


func _ready() -> void:
	add_to_group(GROUP)
	hide()
	modulate.a = 0.0
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_ended.connect(_on_dialogue_ended)
	StoryDirector.hint_changed.connect(_on_hint_changed)


## Montre text (vide : cache) show_time s.
func show_text(text: String) -> void:
	_label.text = text
	if _tween != null:
		_tween.kill()
		_tween = null
	if text.is_empty():
		hide()
		return
	show()
	modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(self, ^"modulate:a", 1.0, fade_time)
	_tween.tween_interval(show_time)
	_tween.tween_property(self, ^"modulate:a", 0.0, fade_time)
	_tween.tween_callback(hide)


## Rappelle l'indice courant du récit.
func recall() -> void:
	show_text(StoryDirector.hint())


## Texte affiché ("" si la ligne est cachée).
func shown_text() -> String:
	return _label.text if visible and not _in_dialogue else ""


func _on_hint_changed(text: String) -> void:
	show_text(text)


func _on_dialogue_started(_npc_id: StringName) -> void:
	_in_dialogue = true
	self_modulate.a = 0.0
	_label.visible = false


func _on_dialogue_ended(_npc_id: StringName) -> void:
	_in_dialogue = false
	self_modulate.a = 1.0
	_label.visible = true
