extends Node3D
## Caméra HD-2D du joueur : racine « CameraRig » de camera_rig.tscn, enfant de player.tscn (PLAN.md
## sections 3 et 4). Propriétaire : L1.
##
## Caméra fixe à la manière d'Octopath Traveler : elle regarde toujours le nord (−Z), inclinée de
## pitch_deg vers le bas, avec un champ étroit (fov_deg), à distance du point visé. Elle suit le
## joueur avec un léger retard (follow_speed) et reste dans les bornes de l'île (limits : au bord,
## on voit la lèvre, la falaise et la mer de nuages, le joueur restant près du centre). Pas de
## rotation : le haut de l'écran est le nord, les commandes sont relatives à l'écran (player.gd).
## La molette ou le stick droit (camera_up / camera_down) zooment un peu (entre min_distance et
## max_distance).
##
## (H5) Cadrage des bâtiments : avec ce tangage et ce champ, le haut de l'écran passe à 6,5 m
## au-dessus du joueur et plus bas derrière lui ; un mur de l'entrepôt au nord du joueur serait
## coupé. Quand la façade sud d'un Building (groupe Building.GROUP) est à moins de FRAME_REACH m
## au nord du joueur et dans le champ, la caméra recule et vise plus au nord juste assez pour que
## la façade et le bas du toit tiennent dans le cadre, le joueur restant dans le bas de l'écran
## (FRAME_FEET) ; elle revient en douceur ailleurs. Il n'y a pas de bâtiment là où l'on se bat.
##
## Structure : Camera3D (caméra courante, top_level : elle ne suit pas les rotations du joueur) et
## PostFX (CanvasLayer derrière l'interface : flou de profondeur, lueur, étalonnage chaud,
## src/player/post_fx.gdshader ; la bande nette suit le joueur à l'écran).
## Verrouillage : lock_target est cadrée avec le joueur (le point visé avance vers elle, sans
## rotation). Le joueur (player.gd) pose lock_target et follow_velocity à chaque image physique.

## (H5) Cadrage des bâtiments : portée au nord du joueur (m), marge au-dessus du mur (m : le bas
## du toit), place de la façade et des pieds du joueur à l'écran (coordonnées normalisées, 1 en
## haut, −1 en bas), recul maximal (m), pas de la recherche (m) et lissage (1/s).
const FRAME_REACH := 14.0
const FRAME_MARGIN := 0.6
const FRAME_TOP := 0.96
const FRAME_FEET := -0.64
const FRAME_MAX_DISTANCE := 30.0
const FRAME_STEP := 0.5
const FRAME_SMOOTHING := 2.5
## (H5) Profondeur nette du flou de profondeur autour du joueur (m) : derrière lui (vers le
## nord) et devant lui (vers la caméra).
const BAND_AHEAD := 9.0
const BAND_BEHIND := 4.5

## Inclinaison de la caméra vers le bas (degrés) et champ vertical (degrés).
@export_range(20.0, 60.0) var pitch_deg: float = 32.0
@export_range(15.0, 60.0) var fov_deg: float = 30.0
## Hauteur du point visé au-dessus des pieds du joueur (m).
@export var focus_height: float = 0.8

@export_group("Zoom")
## Distance de la caméra au point visé (m) : défaut, minimum, maximum.
@export var distance: float = 21.0
@export var min_distance: float = 14.0
@export var max_distance: float = 25.0
## Distance gagnée ou perdue par cran de molette (m) ; vitesse au stick (m/s).
@export var zoom_step: float = 1.5
@export var zoom_stick_speed: float = 8.0
## Lissage du zoom (1/s).
@export var zoom_smoothing: float = 8.0

@export_group("Suivi")
## Vitesse à laquelle le point visé rejoint le joueur (1/s) : le léger retard du suivi.
@export var follow_speed: float = 5.0
## Avance du point visé dans le sens de la marche (s de déplacement), pour voir où l'on va.
@export var lead_time: float = 0.25
## Bornes du point visé dans le plan du sol (x, z). (H5) Assez larges pour que le joueur reste à
## moins de 6 m du centre au bord de l'île (le bord du Couchant est à x = −77) : on voit alors
## la lèvre, la falaise et la mer de nuages, jamais le joueur au bord de l'écran.
@export var limits: Rect2 = Rect2(-71.0, -70.0, 142.0, 136.0)

@export_group("Verrouillage")
## Part de l'écart joueur → cible dont le point visé avance vers elle, et avancée maximale (m).
@export_range(0.0, 1.0) var lock_focus: float = 0.4
@export var lock_focus_max: float = 5.0

## Cible verrouillée à cadrer avec le joueur (null : aucune). Posée par le joueur.
var lock_target: Node3D
## Vitesse horizontale voulue du joueur (avance du point visé). Posée par le joueur.
var follow_velocity: Vector3 = Vector3.ZERO

var _focus: Vector3 = Vector3.ZERO
var _distance: float = 19.0
var _target_distance: float = 19.0
var _started: bool = false
var _post: ShaderMaterial
## Cadrage des bâtiments lissé : avancée du point visé vers le nord (m) et recul (m, 0 : aucun).
var _frame_shift: float = 0.0
var _frame_distance: float = 0.0

@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	_target_distance = clampf(distance, min_distance, max_distance)
	_distance = _target_distance
	camera.top_level = true
	camera.fov = fov_deg
	var screen := get_node_or_null(^"PostFX/Screen") as CanvasItem
	if screen != null and screen.material is ShaderMaterial:
		# Copie propre à cette caméra : la bande nette et les réglages de lumière
		# (HD2DLighting.apply_post) ne touchent pas la ressource de la scène.
		_post = screen.material.duplicate() as ShaderMaterial
		screen.material = _post
	snap()


func _process(delta: float) -> void:
	update_camera(delta, Input.get_axis(&"camera_up", &"camera_down"))


func _unhandled_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button == null or not button.pressed:
		return
	var factor := clampf(button.factor, 0.1, 3.0) if button.factor > 0.0 else 1.0
	match button.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			zoom(-zoom_step * factor)
			get_viewport().set_input_as_handled()
		MOUSE_BUTTON_WHEEL_DOWN:
			zoom(zoom_step * factor)
			get_viewport().set_input_as_handled()


## Une image de caméra. zoom_axis : stick droit vertical (> 0 : s'éloigne).
func update_camera(delta: float, zoom_axis: float = 0.0) -> void:
	if not is_inside_tree():
		return
	if not _started:
		snap()
	if absf(zoom_axis) > 0.2:
		zoom(zoom_axis * zoom_stick_speed * delta)
	var framing := _building_framing()
	var frame_weight := 1.0 - exp(-FRAME_SMOOTHING * delta)
	_frame_shift = lerpf(_frame_shift, framing.x, frame_weight)
	_frame_distance = lerpf(_frame_distance, framing.y, frame_weight)
	var goal := focus_goal()
	_focus = _focus.lerp(goal, 1.0 - exp(-follow_speed * delta))
	_distance = lerpf(
		_distance, maxf(_target_distance, _frame_distance), 1.0 - exp(-zoom_smoothing * delta)
	)
	_apply()


## Point visé idéal : le joueur (un peu en avant dans le sens de la marche si with_lead, et vers
## la cible verrouillée ; (H5) plus au nord devant un bâtiment), borné à limits.
func focus_goal(with_lead: bool = true) -> Vector3:
	var goal := global_position + Vector3.UP * focus_height + Vector3.FORWARD * _frame_shift
	if with_lead:
		goal += Vector3(follow_velocity.x, 0.0, follow_velocity.z) * lead_time
	var target := _valid_target()
	if target != null:
		var offset := target.global_position - global_position
		offset.y = 0.0
		goal += (offset * lock_focus).limit_length(lock_focus_max)
	goal.x = clampf(goal.x, limits.position.x, limits.end.x)
	goal.z = clampf(goal.z, limits.position.y, limits.end.y)
	return goal


## Replace immédiatement la caméra sur le joueur (apparition, téléportation, réapparition).
func snap() -> void:
	if not is_inside_tree():
		return
	_started = true
	var framing := _building_framing()
	_frame_shift = framing.x
	_frame_distance = framing.y
	_focus = focus_goal(false)
	_distance = maxf(_target_distance, _frame_distance)
	_apply()


## Ancien nom (caméra orbitale) : la caméra fixe ne tourne pas, elle se recale sur le joueur.
func snap_behind(_direction: Vector3 = Vector3.ZERO) -> void:
	snap()


## Ancien nom (caméra orbitale) : sans effet, la caméra fixe ne tourne pas.
func recenter_behind(_direction: Vector3) -> void:
	pass


## Zoom : amount > 0 éloigne la caméra ; distance bornée entre min_distance et max_distance.
func zoom(amount: float) -> void:
	_target_distance = clampf(_target_distance + amount, min_distance, max_distance)


## Distance visée par le zoom (m) ; la caméra la rejoint en douceur.
func zoom_distance() -> float:
	return _target_distance


## Point visé courant (après le retard du suivi).
func focus() -> Vector3:
	return _focus


## Lacet (radians) : toujours 0, la caméra regarde le nord (−Z).
func yaw() -> float:
	return 0.0


## Tangage (radians, négatif : la caméra regarde vers le bas).
func pitch() -> float:
	return -deg_to_rad(pitch_deg)


## Avant horizontal de la caméra : le nord.
func forward() -> Vector3:
	return Vector3.FORWARD


func _apply() -> void:
	var tilt := deg_to_rad(pitch_deg)
	var back := Vector3(0.0, sin(tilt), cos(tilt)) * _distance
	camera.global_transform = Transform3D(Basis(Vector3.RIGHT, -tilt), _focus + back)
	_update_focus_band()


## (H5) La bande nette du flou de profondeur (post_fx.gdshader : focus_center, focus_half) suit
## le joueur à l'écran : elle va de BAND_BEHIND m devant lui (vers la caméra) à BAND_AHEAD m
## derrière lui, à mi-hauteur d'un personnage. Le joueur et ceux qui l'entourent ne sont jamais
## flous, même décentrés par le retard du suivi, l'avance, le verrouillage, les bornes de l'île
## ou le cadrage d'un bâtiment.
func _update_focus_band() -> void:
	if _post == null:
		return
	var height := get_viewport().get_visible_rect().size.y
	var middle := global_position + Vector3.UP * focus_height
	var far := middle + Vector3.FORWARD * BAND_AHEAD
	var near := middle + Vector3.BACK * BAND_BEHIND
	if height <= 0.0 or camera.is_position_behind(far) or camera.is_position_behind(near):
		return
	var top := clampf(camera.unproject_position(far).y / height, 0.05, 0.85)
	var bottom := clampf(camera.unproject_position(near).y / height, top + 0.05, 1.0)
	_post.set_shader_parameter(&"focus_center", (top + bottom) / 2.0)
	_post.set_shader_parameter(&"focus_half", (bottom - top) / 2.0)


func _valid_target() -> Node3D:
	if is_instance_valid(lock_target) and lock_target.is_inside_tree():
		return lock_target
	return null


## (H5) Cadrage des bâtiments voulu : Vector2(avancée du point visé vers le nord, recul), (0, 0)
## sans façade à cadrer. Le plus petit recul (à partir du zoom du joueur) pour lequel une avancée
## suffit à mettre le haut de chaque façade proche sous FRAME_TOP sans que les pieds du joueur
## passent sous FRAME_FEET ; au recul maximal, le joueur reste à l'écran avant la façade.
func _building_framing() -> Vector2:
	if not is_inside_tree():
		return Vector2.ZERO
	var walls := _walls_in_front()
	if walls.is_empty():
		return Vector2.ZERO
	var tilt := deg_to_rad(pitch_deg)
	var sp := sin(tilt)
	var cp := cos(tilt)
	var t := tan(deg_to_rad(camera.fov) / 2.0)
	var top_denominator := sp - FRAME_TOP * t * cp
	var feet_denominator := sp - FRAME_FEET * t * cp
	if top_denominator <= 0.0:
		return Vector2.ZERO
	var reach := _target_distance
	var shift := 0.0
	while true:
		# Avancée nécessaire : chaque façade (dz : écart au nord, h : hauteur au-dessus du point
		# visé) au plus a_max en avant du point visé ; avancée permise par les pieds du joueur.
		var need := 0.0
		for wall: Vector2 in walls:
			var ahead := (FRAME_TOP * t * (reach - wall.y * sp) - wall.y * cp) / top_denominator
			need = maxf(need, wall.x - ahead)
		if need <= 0.0:
			return Vector2(0.0, reach) if reach > _target_distance else Vector2.ZERO
		var allowed := (
			(-focus_height * cp - FRAME_FEET * t * (reach + focus_height * sp)) / feet_denominator
		)
		shift = minf(need, maxf(allowed, 0.0))
		if need <= allowed or reach >= FRAME_MAX_DISTANCE:
			break
		reach = minf(reach + FRAME_STEP, FRAME_MAX_DISTANCE)
	return Vector2(shift, reach)


## Façades sud à cadrer : Vector2(écart au nord du joueur, hauteur à montrer au-dessus du point
## visé) de chaque Building dont la façade est à moins de FRAME_REACH m au nord du joueur et dont
## la largeur croise le milieu du champ.
func _walls_in_front() -> Array[Vector2]:
	var walls: Array[Vector2] = []
	var size := get_viewport().get_visible_rect().size
	var aspect := size.x / size.y if size.y > 0.0 else 16.0 / 9.0
	var half_width := 0.8 * _target_distance * tan(deg_to_rad(camera.fov) / 2.0) * aspect
	var eye := global_position + Vector3.UP * focus_height
	for node: Node in get_tree().get_nodes_in_group(Building.GROUP):
		var building := node as Building
		if building == null or not building.is_visible_in_tree():
			continue
		var xform := building.global_transform
		var front := -INF
		var left := INF
		var right := -INF
		var half := building.footprint / 2.0
		for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			var at := xform * Vector3(corner.x * half.x, 0.0, corner.y * half.y)
			front = maxf(front, at.z)
			left = minf(left, at.x)
			right = maxf(right, at.x)
		var ahead := global_position.z - front
		if ahead <= 0.0 or ahead > FRAME_REACH:
			continue
		if right < global_position.x - half_width or left > global_position.x + half_width:
			continue
		var tall := building.ridge_height if building.gable_front else building.wall_height
		var top := xform.origin.y + tall * xform.basis.get_scale().y + FRAME_MARGIN
		walls.append(Vector2(ahead, top - eye.y))
	return walls
