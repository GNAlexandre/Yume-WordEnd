@tool
class_name NuitBox
extends StyleBox
## (U1) Boîte de l'interface « Nuit douce », dessinée sans image : un fond arrondi translucide
## (prune foncé pour les panneaux, doré pour le halo d'une sélection), une ombre douce, sans
## bordure, et au besoin un filet doré qui s'efface aux deux bouts ou un point doré à gauche.
## Les valeurs vivent dans src/ui/wordend_theme.tres (sous-ressources NuitBox_*) ; le verre dépoli
## (flou de l'arrière-plan) s'ajoute au nœud par UiStyle.frost().

## Segments du filet (son alpha suit 1 − (écart au milieu)²).
const RULE_SEGMENTS := 24

## Fond (alpha 0 : pas de fond).
@export var fill: Color = Color(0.0, 0.0, 0.0, 0.0)
## Rayon des coins (px).
@export var radius: int = 22
@export_group("Ombre")
@export var shadow_color: Color = Color(0.0, 0.0, 0.0, 0.0)
@export var shadow_size: int = 0
@export var shadow_offset: Vector2 = Vector2.ZERO
@export_group("Filet")
## Filet horizontal (alpha 0 : pas de filet), plein au milieu, effacé aux bouts.
@export var rule_color: Color = Color(0.0, 0.0, 0.0, 0.0)
## Distance du filet au haut de la boîte (px) ; négative : depuis le bas.
@export var rule_inset: float = 8.0
## Distance du filet aux bords gauche et droit (px).
@export var rule_margin: float = 26.0
## Épaisseur du filet (px).
@export var rule_width: float = 1.0
@export_group("Point")
## Point à gauche, centré en hauteur (alpha 0 : pas de point).
@export var dot_color: Color = Color(0.0, 0.0, 0.0, 0.0)
@export var dot_radius: float = 5.0
## Abscisse du centre du point depuis le bord gauche (px).
@export var dot_x: float = 18.0

var _flat: StyleBoxFlat


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if fill.a > 0.0 or (shadow_color.a > 0.0 and shadow_size > 0):
		_flat_box().draw(to_canvas_item, rect)
	if rule_color.a > 0.0 and rule_width > 0.0:
		_draw_rule(to_canvas_item, rect)
	if dot_color.a > 0.0 and dot_radius > 0.0:
		var center := Vector2(rect.position.x + dot_x, rect.get_center().y)
		RenderingServer.canvas_item_add_circle(to_canvas_item, center, dot_radius, dot_color, true)


## Fond et ombre : un StyleBoxFlat (coins lissés) tenu à jour.
func _flat_box() -> StyleBoxFlat:
	if _flat == null:
		_flat = StyleBoxFlat.new()
		_flat.anti_aliasing = true
		_flat.corner_detail = 12
	_flat.bg_color = fill
	_flat.draw_center = fill.a > 0.0
	_flat.set_corner_radius_all(radius)
	_flat.shadow_color = shadow_color
	_flat.shadow_size = shadow_size
	_flat.shadow_offset = shadow_offset
	return _flat


func _draw_rule(to_canvas_item: RID, rect: Rect2) -> void:
	var left := rect.position.x + rule_margin
	var right := rect.end.x - rule_margin
	if right <= left:
		return
	var top := rect.position.y + rule_inset if rule_inset >= 0.0 else rect.end.y + rule_inset
	top = roundf(top)
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	for i in RULE_SEGMENTS + 1:
		var t := float(i) / RULE_SEGMENTS
		var x := lerpf(left, right, t)
		var spread := absf(t * 2.0 - 1.0)
		var color := Color(rule_color, rule_color.a * (1.0 - spread * spread))
		points.append_array([Vector2(x, top), Vector2(x, top + rule_width)])
		colors.append_array([color, color])
	var indices := PackedInt32Array()
	for i in RULE_SEGMENTS:
		var a := i * 2
		indices.append_array([a, a + 1, a + 2, a + 1, a + 3, a + 2])
	RenderingServer.canvas_item_add_triangle_array(to_canvas_item, indices, points, colors)
