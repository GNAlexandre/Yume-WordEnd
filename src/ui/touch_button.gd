extends Control
## Bouton rond des contrôles tactiles (src/ui/touch_controls.tscn) : presse son action tant qu'un
## doigt est posé dessus (« Charge » maintenue comme les autres). Ne lit aucun événement lui-même :
## TouchControls lui confie les doigts (touch_down / touch_up).

## Quand le bouton reste affiché : GAMEPLAY (ni en pause ni en dialogue), TALK (pas en pause),
## MENU (pas en dialogue), ALWAYS.
enum Context { GAMEPLAY, TALK, MENU, ALWAYS }

## Zone de toucher un peu plus grande que le disque dessiné (fraction du rayon).
const TOUCH_SLOP := 1.2
const FILL := Color(0.106, 0.071, 0.192, 0.5)
const TEXT := Color(1.0, 0.973, 0.984)
const TEXT_PRESSED := Color(0.165, 0.071, 0.251)

@export var action: StringName = &"attack"
@export var label: String = "Épée"
@export var context: Context = Context.GAMEPLAY
@export var tint: Color = Color(0.953, 0.651, 0.784)

var _finger: int = -1
var _caption: String = ""
var _dimmed: bool = false


## Émet une action de l'input map comme le ferait une touche : InputEventAction passé à
## Input.parse_input_event (met à jour Input.is_action_pressed / get_action_strength et arrive
## dans _input / _unhandled_input des nœuds).
static func send_action(action_name: StringName, pressed: bool, strength: float = 1.0) -> void:
	var event := InputEventAction.new()
	event.action = action_name
	event.pressed = pressed
	event.strength = clampf(strength, 0.0, 1.0) if pressed else 0.0
	Input.parse_input_event(event)


## Envoie l'intensité de chaque action si elle a changé depuis le dernier envoi (`sent` garde cet
## état) : pas d'événement pour un écart infime, toujours un au passage par zéro.
static func send_strengths(
	actions: Array[StringName], strengths: Array[float], sent: Dictionary[StringName, float]
) -> void:
	for i in actions.size():
		var previous: float = sent.get(actions[i], 0.0)
		var strength := strengths[i]
		if absf(strength - previous) < 0.005 and (strength > 0.0) == (previous > 0.0):
			continue
		sent[actions[i]] = strength
		send_action(actions[i], strength > 0.0, strength)


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	if _caption.is_empty():
		_caption = label


func radius() -> float:
	return minf(size.x, size.y) * 0.5


## Point en coordonnées du canevas (celles des événements de _input).
func contains(point: Vector2) -> bool:
	if not is_visible_in_tree():
		return false
	var local := get_global_transform_with_canvas().affine_inverse() * point
	return local.distance_to(size * 0.5) <= radius() * TOUCH_SLOP


func is_pressed() -> bool:
	return _finger != -1


func touch_down(index: int) -> void:
	if _finger != -1:
		return
	_finger = index
	send_action(action, true)
	queue_redraw()


func touch_up(index: int) -> void:
	if index != _finger:
		return
	_finger = -1
	send_action(action, false)
	queue_redraw()


## Relâche l'action si un doigt la tenait (bouton masqué, fenêtre qui perd le focus…).
func release() -> void:
	if _finger != -1:
		touch_up(_finger)


## Texte du bouton : l'invite d'interaction (« Ramasser ») ou le libellé, estompé sans invite.
func show_prompt(prompt: String) -> void:
	_caption = prompt if not prompt.is_empty() else label
	_dimmed = prompt.is_empty()
	queue_redraw()


func caption() -> String:
	return _caption


func _draw() -> void:
	var center := size * 0.5
	var r := radius() - 2.0
	var alpha := 0.55 if _dimmed and not is_pressed() else 1.0
	var ring := Color(tint, 0.9 * alpha)
	draw_circle(center, r, Color(tint, 0.85) if is_pressed() else Color(FILL, FILL.a * alpha))
	draw_arc(center, r, 0.0, TAU, 48, ring, 3.0, true)
	var font := get_theme_default_font()
	var font_size := int(clampf(r * 0.36, 14.0, 26.0))
	var text_size := font.get_string_size(_caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := center.y + (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	var color := TEXT_PRESSED if is_pressed() else Color(TEXT, alpha)
	draw_string(
		font,
		Vector2(center.x - text_size.x * 0.5, baseline),
		_caption,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		color
	)
