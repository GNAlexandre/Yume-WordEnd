extends Control
## (E1) Fondu des changements de carte : nœud UI/MapFade de game.tscn, au-dessus du reste de
## l'interface. Propriétaire : E1.
##
## - Écran noir (Black) dont l'opacité suit WorldManager.fade_alpha() à chaque image : le
##   fondu au noir, puis le fondu de retour d'un WorldManager.go_to() ; jamais de clic pris (tout
##   est en mouse_filter IGNORE), traité même en pause.
## - Nom de la carte (Map.display_name, WorldManager.map_display_name) annoncé à l'entrée
##   (EventBus.map_entered), une fois l'écran revenu : fondu d'apparition, title_time s, fondu
##   de disparition, dans le style du nom de zone du HUD. Une carte sans nom n'annonce rien
##   (l'ancienne île annonce ses zones par le HUD).

## Durée d'affichage du nom de la carte (s), sans les fondus ; durée de chaque fondu (s).
@export var title_time: float = 2.4
@export var title_fade_time: float = 0.35

var _title_tween: Tween
var _pending_title: String = ""

@onready var _black: ColorRect = %Black
@onready var _title: Control = %Title
@onready var _title_label: Label = %TitleLabel


func _ready() -> void:
	EventBus.map_entered.connect(_on_map_entered)
	_apply(WorldManager.fade_alpha())


func _process(_delta: float) -> void:
	var alpha := WorldManager.fade_alpha()
	_apply(alpha)
	if not _pending_title.is_empty() and alpha <= 0.0:
		_show_title(_pending_title)
		_pending_title = ""


## Opacité du noir affichée (0..1).
func black_alpha() -> float:
	return _black.color.a if _black.visible else 0.0


## Nom de carte affiché ("" : aucun), même pendant son fondu.
func title_text() -> String:
	return _title_label.text if _title.visible else ""


func _apply(alpha: float) -> void:
	_black.color.a = clampf(alpha, 0.0, 1.0)
	_black.visible = alpha > 0.0


func _show_title(text: String) -> void:
	_title_label.text = text
	_title.show()
	_title.modulate.a = 0.0
	if _title_tween != null:
		_title_tween.kill()
	_title_tween = create_tween()
	_title_tween.tween_property(_title, ^"modulate:a", 1.0, title_fade_time)
	_title_tween.tween_interval(title_time)
	_title_tween.tween_property(_title, ^"modulate:a", 0.0, title_fade_time)
	_title_tween.tween_callback(_title.hide)


func _on_map_entered(map_id: StringName) -> void:
	_pending_title = WorldManager.map_display_name(map_id)
