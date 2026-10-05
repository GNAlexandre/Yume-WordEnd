extends Control
## Contrôles tactiles (UI/TouchControls de game.tscn, Lot 9) : joystick virtuel à gauche (move_*
## avec intensité), boutons Épée, Charge (maintenue), Saut, Parler, Cible, Sac et Pause à droite ;
## glisser ailleurs sur la moitié droite de l'écran tourne la caméra (camera_*). Plusieurs doigts à
## la fois : chaque doigt appartient au contrôle sur lequel il s'est posé. N'émet que des actions
## de l'input map (InputEventAction) : aucun autre système ne connaît ce nœud.
##
## Affichage (`display`) : AUTO = visible sur écran tactile (DisplayServer.is_touchscreen_available
## ou navigateur Android / iOS) et dès qu'un doigt touche l'écran, masqué dès qu'on joue au clavier,
## à la souris ou à la manette. Masqué, il ne consomme aucun événement : la souris d'un ordinateur
## n'est jamais interceptée.
##
## Ordre de Godot : _input (un doigt qui tombe sur nos contrôles est à nous) → interface (les
## boutons d'un dialogue ou d'un menu passent avant la caméra) → _unhandled_input (doigt posé
## ailleurs sur la moitié droite = caméra ; souris émulée par le tactile consommée, pour que la
## caméra à la souris ne la voie pas en double). Pause : seuls Pause et Sac restent ; dialogue :
## Parler (« Suite ») et Pause.

enum Display { AUTO, ALWAYS, NEVER }

const TouchButton := preload("res://src/ui/touch_button.gd")
const TouchJoystick := preload("res://src/ui/touch_joystick.gd")
const CAMERA_ACTIONS: Array[StringName] = [
	&"camera_left", &"camera_right", &"camera_up", &"camera_down"
]
const TALK_LABEL_IN_DIALOGUE := "Suite"

@export var display: Display = Display.AUTO:
	set = set_display
## Vitesse du doigt (pixels logiques par seconde) qui donne une action caméra à pleine intensité :
## la caméra tourne d'un angle proportionnel au glisser, quelle que soit la cadence d'images.
@export var camera_full_speed: float = 1000.0

var _buttons: Array[TouchButton] = []
var _shown: bool = false
var _paused: bool = false
var _in_dialogue: bool = false
var _prompt: String = ""
var _touches: Dictionary[int, bool] = {}
var _owners: Dictionary[int, Node] = {}
var _camera_finger: int = -1
var _camera_motion: Vector2 = Vector2.ZERO
var _camera_sent: Dictionary[StringName, float] = {}
var _eating_mouse: bool = false

@onready var _joystick: TouchJoystick = $Joystick


## Écran tactile probable : API du navigateur ('ontouchstart') ou du système, Android / iOS.
static func is_touch_device() -> bool:
	return (
		DisplayServer.is_touchscreen_available()
		or OS.has_feature("web_android")
		or OS.has_feature("web_ios")
	)


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	for child: Node in get_children():
		if child is TouchButton:
			_buttons.append(child)
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_ended.connect(_on_dialogue_ended)
	EventBus.interaction_available.connect(_on_interaction_available)
	_paused = get_tree().paused
	_set_shown(_initial_shown())


func set_display(value: Display) -> void:
	display = value
	if is_node_ready():
		_set_shown(_initial_shown())


func is_shown() -> bool:
	return _shown


## Le bouton qui émet `action` (null s'il n'existe pas).
func button_for(action: StringName) -> TouchButton:
	for button in _buttons:
		if button.action == action:
			return button
	return null


## Relâche toutes les actions tenues par les contrôles et oublie les doigts suivis.
func release_all() -> void:
	if not is_node_ready():
		return
	for button in _buttons:
		button.release()
	_joystick.release()
	_stop_camera()
	_owners.clear()
	_eating_mouse = false


func _input(event: InputEvent) -> void:
	if handle_input(event):
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if handle_unhandled_input(event):
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	var paused := get_tree().paused
	if paused != _paused:
		_paused = paused
		_refresh()
	update_camera(delta)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			# Les fins de toucher peuvent ne jamais arriver : rien ne doit rester enfoncé.
			release_all()
			_touches.clear()
		NOTIFICATION_EXIT_TREE:
			release_all()


## Avant l'interface : doigts posés sur nos contrôles, glissers et relâchements des doigts suivis.
## Renvoie true si l'événement est consommé (public pour les tests).
func handle_input(event: InputEvent) -> bool:
	_follow_device(event)
	var touch := event as InputEventScreenTouch
	if touch != null:
		if touch.pressed:
			_touches[touch.index] = true
		else:
			_touches.erase(touch.index)
	if not _shown:
		return false
	if touch != null:
		return _on_touch(touch)
	var drag := event as InputEventScreenDrag
	if drag != null:
		return _on_drag(drag)
	var mouse := event as InputEventMouse
	if mouse != null and mouse.device == InputEvent.DEVICE_ID_EMULATION:
		return _on_emulated_mouse(mouse)
	return false


## Après l'interface : un doigt que rien n'a pris sur la moitié droite devient la caméra ; la
## souris émulée par le tactile (et le pointeur qui bouge sous un doigt) est consommée.
func handle_unhandled_input(event: InputEvent) -> bool:
	if not _shown:
		return false
	var touch := event as InputEventScreenTouch
	if touch != null:
		if (
			touch.pressed
			and _camera_finger == -1
			and _gameplay()
			and _in_camera_zone(touch.position)
		):
			_camera_finger = touch.index
			_owners[touch.index] = self
			return true
		return false
	var mouse := event as InputEventMouse
	if mouse == null:
		return false
	return (
		mouse.device == InputEvent.DEVICE_ID_EMULATION
		or (mouse is InputEventMouseMotion and not _touches.is_empty())
	)


## Convertit le glisser de la caméra accumulé depuis la dernière image en intensités camera_*.
func update_camera(delta: float) -> void:
	var axis := _camera_motion / maxf(delta, 0.0001) / maxf(camera_full_speed, 1.0)
	_camera_motion = Vector2.ZERO
	_send_camera(axis)


func _on_touch(touch: InputEventScreenTouch) -> bool:
	if touch.pressed:
		var target := _widget_at(touch.position)
		if target == null:
			return false
		_owners[touch.index] = target
		if target == _joystick:
			_joystick.touch_down(touch.index, touch.position)
		else:
			(target as TouchButton).touch_down(touch.index)
		return true
	var holder: Node = _owners.get(touch.index)
	if holder == null:
		return false
	_owners.erase(touch.index)
	if holder == self:
		_stop_camera()
	elif holder == _joystick:
		_joystick.touch_up(touch.index)
	else:
		(holder as TouchButton).touch_up(touch.index)
	return true


func _on_drag(drag: InputEventScreenDrag) -> bool:
	var holder: Node = _owners.get(drag.index)
	if holder == null:
		return false
	if holder == self:
		_camera_motion += drag.relative
	elif holder == _joystick:
		_joystick.touch_move(drag.index, drag.position)
	return true


## Souris émulée par le premier doigt (Input.emulate_mouse_from_touch) : elle arrive juste AVANT
## le toucher. Si le doigt tombe sur un de nos contrôles, elle est à nous jusqu'au relâchement
## (sinon un bouton de l'interface en dessous recevrait un clic).
func _on_emulated_mouse(mouse: InputEventMouse) -> bool:
	var click := mouse as InputEventMouseButton
	if click != null and click.pressed:
		_eating_mouse = _widget_at(click.position) != null
		return _eating_mouse
	var eaten := _eating_mouse
	if click != null:
		_eating_mouse = false
	return eaten


func _widget_at(point: Vector2) -> Control:
	for button in _buttons:
		if button.contains(point):
			return button
	if _joystick.contains(point):
		return _joystick
	return null


func _in_camera_zone(point: Vector2) -> bool:
	var local := get_global_transform_with_canvas().affine_inverse() * point
	return Rect2(Vector2.ZERO, size).has_point(local) and local.x >= size.x * 0.5


func _stop_camera() -> void:
	if _camera_finger != -1:
		_owners.erase(_camera_finger)
	_camera_finger = -1
	_camera_motion = Vector2.ZERO
	_send_camera(Vector2.ZERO)


func _send_camera(axis: Vector2) -> void:
	var strengths: Array[float] = [
		clampf(-axis.x, 0.0, 1.0),
		clampf(axis.x, 0.0, 1.0),
		clampf(-axis.y, 0.0, 1.0),
		clampf(axis.y, 0.0, 1.0),
	]
	TouchButton.send_strengths(CAMERA_ACTIONS, strengths, _camera_sent)


func _initial_shown() -> bool:
	match display:
		Display.ALWAYS:
			return true
		Display.NEVER:
			return false
	return is_touch_device()


func _set_shown(value: bool) -> void:
	_shown = value
	visible = value
	_refresh()


func _gameplay() -> bool:
	return _shown and not _paused and not _in_dialogue


func _allowed(context: TouchButton.Context) -> bool:
	match context:
		TouchButton.Context.GAMEPLAY:
			return not _paused and not _in_dialogue
		TouchButton.Context.TALK:
			return not _paused
		TouchButton.Context.MENU:
			return not _in_dialogue
	return true


## Montre ce que le contexte permet (pause, dialogue) et relâche ce qui disparaît.
func _refresh() -> void:
	var gameplay := _gameplay()
	_joystick.visible = gameplay
	if not gameplay:
		_joystick.release()
		_stop_camera()
	for button in _buttons:
		var keep := _shown and _allowed(button.context)
		button.visible = keep
		if not keep:
			button.release()
	for index: int in _owners.keys():
		var holder := _owners[index]
		if holder != self and not (holder as CanvasItem).is_visible_in_tree():
			_owners.erase(index)
	var talk := button_for(&"interact")
	if talk != null:
		talk.show_prompt(TALK_LABEL_IN_DIALOGUE if _in_dialogue else _prompt)


## Mode AUTO : un toucher affiche les contrôles ; une touche ou un bouton de manette liés à une
## action du jeu, ou un clic de vraie souris, les masquent (ordinateur tactile joué au clavier).
func _follow_device(event: InputEvent) -> void:
	if display != Display.AUTO:
		return
	if event is InputEventScreenTouch and event.is_pressed():
		if not _shown:
			_set_shown(true)
	elif _shown and _is_desk_input(event):
		release_all()
		_set_shown(false)


func _is_desk_input(event: InputEvent) -> bool:
	if not event.is_pressed() or event.is_echo():
		return false
	if event is InputEventMouseButton:
		return event.device != InputEvent.DEVICE_ID_EMULATION
	if event is InputEventKey or event is InputEventJoypadButton:
		for action: StringName in InputMap.get_actions():
			if not String(action).begins_with("ui_") and event.is_action(action):
				return true
	return false


func _on_dialogue_started(_npc_id: StringName) -> void:
	_in_dialogue = true
	_refresh()


func _on_dialogue_ended(_npc_id: StringName) -> void:
	_in_dialogue = false
	_refresh()


func _on_interaction_available(prompt: String) -> void:
	_prompt = prompt
	_refresh()
