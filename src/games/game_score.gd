class_name GameScore
extends CanvasLayer
## (E8) Le score d'un jeu, sobre : une ligne de texte en haut de l'écran, sur un petit bandeau
## sombre et transparent (« Blanches 1 – 0 Rouges · 1re mi-temps 2:41 »). Posé par le jeu tant que
## le joueur y est. Sous les menus (couche 2). Propriétaire : E8.

const LAYER_INDEX := 2
const FONT_SIZE := 18
const MARGIN_TOP := 10.0

var _label: Label
var _pending: String = ""


func _init() -> void:
	name = "GameScore"
	layer = LAYER_INDEX


func _ready() -> void:
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.08, 0.55)
	style.set_corner_radius_all(6)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	panel.add_theme_stylebox_override(&"panel", style)
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.position.y = MARGIN_TOP
	add_child(panel)
	_label = Label.new()
	_label.name = "Text"
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override(&"font_size", FONT_SIZE)
	_label.add_theme_color_override(&"font_color", Color(1.0, 0.98, 0.94))
	_label.text = _pending
	panel.add_child(_label)


## Change le texte affiché.
func set_text(value: String) -> void:
	if _label != null:
		_label.text = value
	_pending = value


## Texte affiché (ou, avant que le nœud soit prêt, celui qu'on lui a donné).
func shown_text() -> String:
	return _label.text if _label != null else _pending
