extends Node3D
## Démo du Lot 9 : les contrôles tactiles forcés visibles au-dessus d'une petite scène au couchant.
## Le personnage avance selon move_* (intensité du joystick), la caméra tourne avec camera_*, Saut
## le fait sauter ; le panneau en haut à gauche liste les actions reçues et leur intensité.
## Dans l'éditeur (F6) : le tactile est émulé à la souris pendant la démo ; clavier et manette
## marchent aussi. `preview` pose deux doigts au démarrage (capture build/shots/l9.png).

const TouchControls := preload("res://src/ui/touch_controls.gd")
const SPEED := 4.0
const TURN_SPEED := 2.5
const GRAVITY := 14.0
const JUMP_SPEED := 5.5
const FEET := 0.75

@export var preview: bool = false

var _vertical_speed: float = 0.0
var _emulation_before: bool = false

@onready var _hero: Node3D = $Hero
@onready var _pivot: Node3D = $Pivot
@onready var _readout: Label = $UI/Readout
@onready var _controls: TouchControls = $UI/TouchControls


func _ready() -> void:
	_emulation_before = Input.emulate_touch_from_mouse
	Input.emulate_touch_from_mouse = true
	if preview:
		_place_preview_fingers.call_deferred()


func _exit_tree() -> void:
	Input.emulate_touch_from_mouse = _emulation_before


func _process(delta: float) -> void:
	var move := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	_pivot.rotation.y -= Input.get_axis(&"camera_left", &"camera_right") * TURN_SPEED * delta
	var pitch := Input.get_axis(&"camera_down", &"camera_up") * TURN_SPEED * 0.5 * delta
	_pivot.rotation.x = clampf(_pivot.rotation.x + pitch, -1.1, -0.1)
	var right := _pivot.global_basis.x
	var forward := Vector3(-_pivot.global_basis.z.x, 0.0, -_pivot.global_basis.z.z).normalized()
	_hero.position += (right * move.x - forward * move.y) * SPEED * delta
	if Input.is_action_just_pressed(&"jump") and _hero.position.y <= FEET:
		_vertical_speed = JUMP_SPEED
	_vertical_speed -= GRAVITY * delta
	_hero.position.y = maxf(FEET, _hero.position.y + _vertical_speed * delta)
	_pivot.position = _hero.position
	_readout.text = _describe()


func _describe() -> String:
	var lines := PackedStringArray(["Actions reçues :"])
	for action: StringName in InputMap.get_actions():
		var strength := (
			0.0 if String(action).begins_with("ui_") else Input.get_action_strength(action)
		)
		if strength > 0.0:
			lines.append("%s  %.2f" % [action, strength])
	if lines.size() == 1:
		lines.append("(touche l'écran)")
	return "\n".join(lines)


## Aperçu figé pour la capture : un pouce sur le joystick (avant-droite), un doigt sur l'épée.
func _place_preview_fingers() -> void:
	var stick := (_controls.get_node(^"Joystick") as Control).get_global_rect().get_center()
	_finger(0, stick, true)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = stick + Vector2(62, -50)
	_controls.handle_input(drag)
	_finger(1, (_controls.get_node(^"Attack") as Control).get_global_rect().get_center(), true)


func _finger(index: int, point: Vector2, pressed: bool) -> void:
	var touch := InputEventScreenTouch.new()
	touch.index = index
	touch.position = point
	touch.pressed = pressed
	_controls.handle_input(touch)
