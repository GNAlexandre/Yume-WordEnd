class_name GameScore
extends CanvasLayer
## (E8) Le score d'un jeu, sobre : une ligne de texte en haut de l'écran, sur un petit bandeau
## sombre et transparent (« Blanches 1 – 0 Rouges · 1re mi-temps 2:41 »). Posé par le jeu tant que
## le joueur y est. Sous les menus (couche 2). Propriétaire : E8.
## (QC2) Le bandeau ne couvre jamais le coin haut gauche du HUD (cœurs, jauge de charge :
## HUD.top_left_rect()) : centré s'il y a la place, sinon poussé à droite de ce coin, et replié sur
## plusieurs lignes si la largeur manque encore.

const LAYER_INDEX := 2
const FONT_SIZE := 18
const MARGIN_TOP := 10.0
## Écart (px) entre le bandeau et le coin du HUD, et marge au bord de l'écran.
const GAP := 16.0
const EDGE := 24.0
const HUD_GROUP := &"hud"

var _label: Label
var _panel: PanelContainer
var _pending: String = ""


func _init() -> void:
	name = "GameScore"
	layer = LAYER_INDEX


func _ready() -> void:
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.08, 0.55)
	style.set_corner_radius_all(6)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	_panel.add_theme_stylebox_override(&"panel", style)
	_panel.position.y = MARGIN_TOP
	add_child(_panel)
	_label = Label.new()
	_label.name = "Text"
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override(&"font_size", FONT_SIZE)
	_label.add_theme_color_override(&"font_color", Color(1.0, 0.98, 0.94))
	_label.text = _pending
	_panel.add_child(_label)
	fit()


func _process(_delta: float) -> void:
	fit()


## Change le texte affiché.
func set_text(value: String) -> void:
	if _label != null:
		_label.text = value
		fit()
	_pending = value


## Texte affiché (ou, avant que le nœud soit prêt, celui qu'on lui a donné).
func shown_text() -> String:
	return _label.text if _label != null else _pending


## Le cadre du bandeau à l'écran.
func panel_rect() -> Rect2:
	return Rect2(_panel.position, _panel.size) if _panel != null else Rect2()


## Place le bandeau : centré en haut, à droite du coin du HUD, replié s'il le faut.
func fit() -> void:
	if _panel == null or not is_inside_tree():
		return
	var view := get_viewport().get_visible_rect().size
	var left := EDGE
	var hud := get_tree().get_first_node_in_group(HUD_GROUP)
	if hud != null and hud.has_method(&"top_left_rect"):
		var corner: Rect2 = hud.call(&"top_left_rect")
		if corner.size != Vector2.ZERO and corner.position.y < MARGIN_TOP + 80.0:
			left = maxf(left, corner.end.x + GAP)
	var room := maxf(view.x - EDGE - left, 120.0)
	var style := _panel.get_theme_stylebox(&"panel")
	var margins := style.get_margin(SIDE_LEFT) + style.get_margin(SIDE_RIGHT)
	_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_label.custom_minimum_size = Vector2.ZERO
	var natural := _label.get_minimum_size().x + margins
	if natural > room:
		_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_label.custom_minimum_size.x = room - margins
	_panel.reset_size()
	var width := _panel.get_combined_minimum_size().x
	_panel.size.x = width
	_panel.position = Vector2(
		clampf((view.x - width) * 0.5, left, maxf(view.x - EDGE - width, left)), MARGIN_TOP
	)
