extends Node3D
## Caméra du joueur à la troisième personne : racine « CameraRig » de camera_rig.tscn, enfant
## de player.tscn (PLAN.md sections 3 et 4). Propriétaire : L1.
##
## Structure figée : SpringArm3D (masque 1 : le bras se raccourcit contre le décor) et
## SpringArm3D/Camera3D (caméra courante). Le bras porte l'orbite : rotation.x = tangage
## (négatif : caméra au-dessus du joueur), rotation.y = lacet, spring_length = distance.
## - Souris : pointeur capturé au clic dans le jeu ; l'action pause, la mise en pause de
##   l'arbre, un dialogue ou la sortie de l'arbre le libèrent. Molette : zoom de 3 à 10 m.
## - Stick droit : actions camera_left / camera_right / camera_up / camera_down.
## - Recentrage doux derrière le joueur quand il avance sans que la caméra ait été touchée.
## - Verrouillage : lock_target est cadrée avec le joueur (lacet vers la cible, point visé
##   avancé vers elle) ; l'orbite manuelle est alors ignorée.
## Le joueur (player.gd) pose lock_target et follow_velocity à chaque image physique.

## Vitesse horizontale minimale du joueur pour que la caméra se replace derrière lui (m/s).
const FOLLOW_MIN_SPEED := 0.5
## Le recentrage ne suit pas un joueur qui revient vers la caméra : cosinus minimal entre sa
## direction et l'avant de la caméra.
const FOLLOW_MIN_DOT := -0.2

@export_group("Orbite")
## Sensibilité de la souris (radians par pixel).
@export var mouse_sensitivity: float = 0.0025
## Vitesse d'orbite au stick droit (radians par seconde) : x = lacet, y = tangage.
@export var stick_speed: Vector2 = Vector2(2.6, 1.6)
## Inverse l'axe vertical (souris et stick).
@export var invert_y: bool = false
## Tangage minimal : caméra au-dessus du joueur (degrés).
@export_range(-89.0, 0.0) var min_pitch_deg: float = -70.0
## Tangage maximal : caméra sous la tête du joueur (degrés).
@export_range(-45.0, 45.0) var max_pitch_deg: float = 20.0

@export_group("Zoom")
## Distance minimale de la caméra (m).
@export var min_distance: float = 3.0
## Distance maximale de la caméra (m).
@export var max_distance: float = 10.0
## Distance gagnée ou perdue par cran de molette (m).
@export var zoom_step: float = 0.75
## Lissage du zoom (1/s).
@export var zoom_smoothing: float = 10.0

@export_group("Recentrage")
## Temps sans toucher la caméra avant qu'elle suive le joueur (s).
@export var recenter_delay: float = 1.0
## Vitesse du recentrage pendant le déplacement (1/s).
@export var recenter_speed: float = 2.0
## Vitesse du recentrage demandé (verrouillage sans cible) (1/s).
@export var snap_speed: float = 8.0

@export_group("Verrouillage")
## Tangage visé quand une cible est verrouillée (degrés).
@export var lock_pitch_deg: float = -16.0
## Vitesse à laquelle la caméra se tourne vers la cible (1/s).
@export var lock_turn_speed: float = 8.0
## Part de l'écart joueur → cible dont le point visé avance vers la cible.
@export_range(0.0, 1.0) var lock_focus: float = 0.35
## Avancée maximale du point visé vers la cible (m).
@export var lock_focus_max: float = 4.0

## Cible verrouillée à cadrer avec le joueur (null : aucune). Posée par le joueur.
var lock_target: Node3D
## Vitesse horizontale voulue du joueur, pour le recentrage. Posée par le joueur.
var follow_velocity: Vector3 = Vector3.ZERO

var _yaw: float = 0.0
var _pitch: float = 0.0
var _default_pitch: float = 0.0
var _distance: float = 6.0
var _target_distance: float = 6.0
var _focus: Vector3 = Vector3.ZERO
var _idle_time: float = 0.0
var _recentering: bool = false
var _recenter_yaw: float = 0.0
var _captured: bool = false
var _in_dialogue: bool = false

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D


func _ready() -> void:
	_pitch = clampf(spring_arm.rotation.x, _min_pitch(), _max_pitch())
	_default_pitch = _pitch
	_yaw = spring_arm.rotation.y
	_target_distance = clampf(spring_arm.spring_length, min_distance, max_distance)
	_distance = _target_distance
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_ended.connect(_on_dialogue_ended)
	_apply()


func _process(delta: float) -> void:
	update_camera(
		delta, Input.get_vector(&"camera_left", &"camera_right", &"camera_up", &"camera_down")
	)


func _input(event: InputEvent) -> void:
	# _input voit l'action pause avant l'interface : le pointeur est libéré même si le menu
	# pause consomme ensuite l'événement.
	if event.is_action_pressed(&"pause"):
		set_pointer_captured(false)


func _unhandled_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null:
		if button.pressed:
			_on_mouse_button(button)
		return
	var motion := event as InputEventMouseMotion
	if motion != null and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		orbit_mouse(motion.screen_relative)
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	# Pause (menu, inventaire, fin d'arène) ou retour au menu : la souris redevient libre.
	if what == NOTIFICATION_PAUSED or what == NOTIFICATION_EXIT_TREE:
		set_pointer_captured(false)


## Lacet (radians) qui fait regarder la caméra dans direction (plan du sol).
static func yaw_toward(direction: Vector3) -> float:
	return atan2(-direction.x, -direction.z)


## Une image de caméra. look : stick droit (Input.get_vector : x à droite, y vers le bas).
func update_camera(delta: float, look: Vector2) -> void:
	_idle_time += delta
	var target := _valid_target()
	if look != Vector2.ZERO and target == null:
		rotate_view(-look.x * stick_speed.x * delta, -look.y * stick_speed.y * delta * _y_sign())
	if target != null:
		_frame_target(target, delta)
	else:
		_focus = _focus.lerp(Vector3.ZERO, _blend(lock_turn_speed, delta))
		if _recentering:
			_yaw = lerp_angle(_yaw, _recenter_yaw, _blend(snap_speed, delta))
			_recentering = absf(angle_difference(_yaw, _recenter_yaw)) > 0.01
		elif _idle_time >= recenter_delay:
			_follow(delta)
	_distance = lerpf(_distance, _target_distance, _blend(zoom_smoothing, delta))
	_apply()


## Orbite manuelle (radians) : yaw_delta > 0 tourne la vue vers la gauche, pitch_delta > 0
## lève la vue (la caméra descend). Le tangage reste entre min_pitch_deg et max_pitch_deg.
func rotate_view(yaw_delta: float, pitch_delta: float) -> void:
	_yaw = wrapf(_yaw + yaw_delta, -PI, PI)
	_pitch = clampf(_pitch + pitch_delta, _min_pitch(), _max_pitch())
	_idle_time = 0.0
	_recentering = false
	_apply()


## Orbite à la souris : relative = déplacement du pointeur capturé, en pixels.
func orbit_mouse(relative: Vector2) -> void:
	if _valid_target() != null:
		return
	rotate_view(-relative.x * mouse_sensitivity, -relative.y * mouse_sensitivity * _y_sign())


## Zoom : amount > 0 éloigne la caméra ; distance bornée entre min_distance et max_distance.
func zoom(amount: float) -> void:
	_target_distance = clampf(_target_distance + amount, min_distance, max_distance)


## Replace doucement la caméra derrière un joueur qui regarde dans direction.
func recenter_behind(direction: Vector3) -> void:
	var flat := Vector3(direction.x, 0.0, direction.z)
	if flat.length_squared() < 0.0001:
		return
	_recenter_yaw = yaw_toward(flat)
	_recentering = true


## Place immédiatement la caméra derrière un joueur qui regarde dans direction, au tangage
## par défaut (réapparition, téléportation).
func snap_behind(direction: Vector3) -> void:
	var flat := Vector3(direction.x, 0.0, direction.z)
	if flat.length_squared() > 0.0001:
		_yaw = yaw_toward(flat)
	_pitch = _default_pitch
	_focus = Vector3.ZERO
	_recentering = false
	_idle_time = 0.0
	_apply()


## Capture (true) ou libère (false) le pointeur pour l'orbite à la souris. Ne libère que ce
## que la caméra a capturé.
func set_pointer_captured(captured: bool) -> void:
	if not captured and not _captured:
		return
	_captured = captured
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if captured else Input.MOUSE_MODE_VISIBLE


## true si la caméra a capturé le pointeur (le navigateur peut l'avoir relâché depuis).
func is_pointer_captured() -> bool:
	return _captured


## Lacet courant (radians ; 0 : la caméra regarde vers −Z).
func yaw() -> float:
	return _yaw


## Tangage courant (radians ; négatif : caméra au-dessus du joueur).
func pitch() -> float:
	return _pitch


## Tangage de départ de la scène (radians), rétabli par snap_behind().
func default_pitch() -> float:
	return _default_pitch


## Distance visée par le zoom (m) ; le bras la rejoint en douceur.
func zoom_distance() -> float:
	return _target_distance


## Avant horizontal de la caméra (vecteur unitaire du plan du sol).
func forward() -> Vector3:
	return Vector3(-sin(_yaw), 0.0, -cos(_yaw))


func _on_mouse_button(button: InputEventMouseButton) -> void:
	var factor := clampf(button.factor, 0.1, 3.0) if button.factor > 0.0 else 1.0
	match button.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			zoom(-zoom_step * factor)
			get_viewport().set_input_as_handled()
		MOUSE_BUTTON_WHEEL_DOWN:
			zoom(zoom_step * factor)
			get_viewport().set_input_as_handled()
		MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT:
			# Pas pendant un dialogue (souris libre pour les choix) ni pour un toucher émulé.
			if button.device != InputEvent.DEVICE_ID_EMULATION and not _in_dialogue:
				set_pointer_captured(true)


func _frame_target(target: Node3D, delta: float) -> void:
	var offset := target.global_position - global_position
	offset.y = 0.0
	if offset.length_squared() > 0.04:
		_yaw = lerp_angle(_yaw, yaw_toward(offset), _blend(lock_turn_speed, delta))
	var lock_pitch := clampf(deg_to_rad(lock_pitch_deg), _min_pitch(), _max_pitch())
	_pitch = lerpf(_pitch, lock_pitch, _blend(lock_turn_speed * 0.5, delta))
	var focus := (offset * lock_focus).limit_length(lock_focus_max)
	_focus = _focus.lerp(focus, _blend(lock_turn_speed, delta))
	_recentering = false
	_idle_time = 0.0


func _follow(delta: float) -> void:
	var flat := Vector3(follow_velocity.x, 0.0, follow_velocity.z)
	if flat.length() < FOLLOW_MIN_SPEED:
		return
	var direction := flat.normalized()
	if direction.dot(forward()) < FOLLOW_MIN_DOT:
		return
	_yaw = lerp_angle(_yaw, yaw_toward(direction), _blend(recenter_speed, delta))


func _apply() -> void:
	spring_arm.rotation = Vector3(_pitch, _yaw, 0.0)
	spring_arm.spring_length = _distance
	spring_arm.position = global_basis.inverse() * _focus if is_inside_tree() else _focus


func _valid_target() -> Node3D:
	if is_instance_valid(lock_target) and lock_target.is_inside_tree():
		return lock_target
	return null


func _blend(speed: float, delta: float) -> float:
	return 1.0 - exp(-speed * delta)


func _y_sign() -> float:
	return -1.0 if invert_y else 1.0


func _min_pitch() -> float:
	return deg_to_rad(min_pitch_deg)


func _max_pitch() -> float:
	return deg_to_rad(max_pitch_deg)


func _on_dialogue_started(_npc_id: StringName) -> void:
	_in_dialogue = true
	set_pointer_captured(false)


func _on_dialogue_ended(_npc_id: StringName) -> void:
	_in_dialogue = false
