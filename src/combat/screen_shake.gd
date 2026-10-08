class_name ScreenShake
extends Node
## Secousse de l'écran réglée pour la caméra fixe HD-2D (lot H7). Créée par PlayerCombat (un
## nœud « ScreenShake » sous Combat) ; les Timeres la trouvent par le groupe GROUP (kick_in()).
##
## La caméra (camera_rig.*, lot H5) n'est pas touchée : la secousse passe par l'API de Camera3D,
## h_offset / v_offset, que CameraRig ne règle pas (il ne pose que global_transform). Le
## décalage est petit (quelques pixels à 21 m), amorti en un quart de seconde, et suit la
## direction du coup vue à l'écran : un coup venu de la gauche pousse l'image vers la droite,
## une morsure venue du nord la fait sauter verticalement (écrasée par l'inclinaison de 32°).
## La caméra ne tourne jamais : le haut de l'écran reste le nord pendant la secousse.

const GROUP := &"screen_shake"

## Oscillations par seconde.
@export var frequency: float = 24.0
## Amortissement (1/s) : 9 → l'amplitude tombe à 10 % en 0,26 s.
@export var decay: float = 9.0
## Amplitude maximale (m), quelles que soient les secousses cumulées.
@export var max_amplitude: float = 0.18
## Part de l'amplitude dans l'axe perpendiculaire au coup (un peu de désordre).
@export var cross_ratio: float = 0.3

var _amplitude: float = 0.0
var _time: float = 0.0
var _direction: Vector2 = Vector2.RIGHT
var _camera: Camera3D
var _applied: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group(GROUP)


func _exit_tree() -> void:
	_release()


## Secousse de strength m dans la direction world_direction (sol, celle du coup) ; sans
## direction, elle part en biais. Une secousse plus forte que celle en cours la remplace.
func kick(strength: float, world_direction: Vector3 = Vector3.ZERO) -> void:
	if strength <= 0.0 or strength < current_amplitude():
		return
	_amplitude = minf(strength, max_amplitude)
	_time = 0.0
	var camera := _current_camera()
	var screen := CombatFx.screen_direction(
		camera, Vector3(world_direction.x, 0.0, world_direction.z)
	)
	_direction = screen if screen != Vector2.ZERO else Vector2(0.8, 0.6)


## Secousse de la partie (premier nœud du groupe GROUP), s'il y en a une.
static func kick_in(
	tree: SceneTree, strength: float, world_direction: Vector3 = Vector3.ZERO
) -> void:
	if tree == null or strength <= 0.0:
		return
	var shake := tree.get_first_node_in_group(GROUP) as ScreenShake
	if shake != null:
		shake.kick(strength, world_direction)


## Amplitude courante (m) ; 0 au repos.
func current_amplitude() -> float:
	return _amplitude


## Décalage appliqué à la caméra à cette image (m, x à droite, y en haut).
func current_offset() -> Vector2:
	return _applied


func _process(delta: float) -> void:
	if _amplitude <= 0.0:
		return
	_time += delta
	_amplitude *= exp(-decay * delta)
	if _amplitude < 0.002:
		_amplitude = 0.0
		_release()
		return
	var phase := TAU * frequency * _time
	var cross := Vector2(-_direction.y, _direction.x)
	var offset := _direction * _amplitude * sin(phase)
	offset += cross * _amplitude * cross_ratio * sin(phase * 1.37 + 1.1)
	_apply(offset)


func _apply(offset: Vector2) -> void:
	var camera := _current_camera()
	if camera != _camera:
		_release()
		_camera = camera
	if _camera == null:
		return
	_camera.h_offset = offset.x
	_camera.v_offset = offset.y
	_applied = offset


## Rend à la caméra un décalage nul (seulement s'il est encore le nôtre).
func _release() -> void:
	if is_instance_valid(_camera):
		if is_equal_approx(_camera.h_offset, _applied.x):
			_camera.h_offset = 0.0
		if is_equal_approx(_camera.v_offset, _applied.y):
			_camera.v_offset = 0.0
	_applied = Vector2.ZERO


func _current_camera() -> Camera3D:
	return get_viewport().get_camera_3d() if is_inside_tree() else null
