extends Control
## Joystick virtuel des contrôles tactiles : la zone (Control) couvre le bas gauche de l'écran ;
## la base apparaît sous le doigt, le bouton le suit. Produit move_left / move_right /
## move_forward / move_back avec une intensité de 0 à 1 par axe, comme un stick de manette lu par
## Input.get_vector (la zone morte de l'input map s'applique ensuite).

const TouchButton := preload("res://src/ui/touch_button.gd")
const ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_forward", &"move_back"]
const RING := Color(0.953, 0.651, 0.784, 0.85)
const BASE := Color(0.106, 0.071, 0.192, 0.45)
const KNOB := Color(1.0, 0.973, 0.984, 0.9)

## Course du bouton (pixels de l'écran logique) : au bord, l'intensité vaut 1.
@export var radius: float = 96.0
## Fraction de la course sans effet (petits tremblements du pouce).
@export var dead_zone: float = 0.08
## Position de repos de la base, depuis le coin bas gauche de la zone.
@export var rest_offset: Vector2 = Vector2(180.0, -180.0)

var _finger: int = -1
var _base: Vector2 = Vector2.ZERO
var _vector: Vector2 = Vector2.ZERO
var _sent: Dictionary[StringName, float] = {}


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


## Point en coordonnées du canevas (celles des événements de _input).
func contains(point: Vector2) -> bool:
	return is_visible_in_tree() and Rect2(Vector2.ZERO, size).has_point(_to_local(point))


func is_active() -> bool:
	return _finger != -1


## Direction courante (x vers la droite, y vers le bas de l'écran = reculer), longueur 0 à 1.
func get_vector() -> Vector2:
	return _vector


func touch_down(index: int, point: Vector2) -> void:
	if _finger != -1:
		return
	_finger = index
	var local := _to_local(point)
	# La base entière reste dans la zone (et à l'écran), même si le doigt touche le bord.
	var margin := minf(radius, minf(size.x, size.y) * 0.5)
	_base = local.clamp(Vector2(margin, margin), (size - Vector2(margin, margin)).max(Vector2.ONE))
	_move_to(local)


func touch_move(index: int, point: Vector2) -> void:
	if index == _finger:
		_move_to(_to_local(point))


func touch_up(index: int) -> void:
	if index == _finger:
		release()


## Recentre le joystick et relâche les quatre actions.
func release() -> void:
	_finger = -1
	_vector = Vector2.ZERO
	_send()
	queue_redraw()


func _move_to(local: Vector2) -> void:
	var offset := (local - _base) / maxf(radius, 1.0)
	_vector = offset.limit_length(1.0) if offset.length() > dead_zone else Vector2.ZERO
	_send()
	queue_redraw()


func _send() -> void:
	var strengths: Array[float] = [
		maxf(-_vector.x, 0.0), maxf(_vector.x, 0.0), maxf(-_vector.y, 0.0), maxf(_vector.y, 0.0)
	]
	TouchButton.send_strengths(ACTIONS, strengths, _sent)


func _to_local(point: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * point


func _draw() -> void:
	var base := _base if is_active() else Vector2(rest_offset.x, size.y + rest_offset.y)
	var knob := base + _vector * radius
	draw_circle(base, radius, BASE)
	draw_arc(base, radius, 0.0, TAU, 64, RING, 3.0, true)
	draw_circle(knob, radius * 0.42, Color(RING, 0.9) if is_active() else KNOB)
	draw_arc(knob, radius * 0.42, 0.0, TAU, 40, Color(BASE, 0.9), 2.0, true)
