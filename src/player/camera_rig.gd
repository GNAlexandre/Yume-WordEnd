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
## au nord du joueur et dans le champ, la caméra lève les yeux sans bouger (tangage jusqu'à
## FRAME_MIN_PITCH) et, si cela ne suffit pas, recule (jusqu'à FRAME_MAX_DISTANCE), juste assez
## pour que la façade et le bas du toit tiennent dans le cadre, le joueur restant dans le bas de
## l'écran (FRAME_FEET) ; la demande d'une façade naît et s'éteint en douceur (FRAME_FADE,
## FRAME_SIDE_FADE) : pas de saut quand on s'en approche ou qu'on la longe. En conversation
## (EventBus.dialogue_started → dialogue_ended), le joueur reste au-dessus de la boîte de dialogue
## (FRAME_FEET_TALKING) et la caméra ne recule pas : la façade peut être coupée. Il n'y a pas de
## bâtiment là où l'on se bat : le combat garde le cadrage habituel.
##
## Structure : Camera3D (caméra courante, top_level : elle ne suit pas les rotations du joueur) et
## PostFX (CanvasLayer derrière l'interface : flou de profondeur, lueur, étalonnage chaud,
## src/player/post_fx.gdshader ; la bande nette suit le joueur à l'écran).
## Verrouillage : lock_target est cadrée avec le joueur (le point visé avance vers elle, sans
## rotation). Le joueur (player.gd) pose lock_target et follow_velocity à chaque image physique.

## (H5) Cadrage des bâtiments : portée au nord du joueur (m) et largeur du fondu de la demande
## d'une façade (m, vers le sud et sur les côtés), marge au-dessus du mur (m : le bas du toit),
## place de la façade et des pieds du joueur à l'écran (coordonnées normalisées, 1 en haut, −1 en
## bas ; en conversation, au-dessus de la boîte de dialogue), tangage minimal (degrés), recul
## maximal (m) et lissage (1/s).
const FRAME_REACH := 18.0
const FRAME_FADE := 4.0
const FRAME_SIDE_FADE := 3.0
const FRAME_MARGIN := 0.4
const FRAME_TOP := 0.97
const FRAME_FEET := -0.7
const FRAME_FEET_TALKING := -0.3
const FRAME_MIN_PITCH := 24.0
const FRAME_MAX_DISTANCE := 29.0
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
## Cadrage des bâtiments lissé : tangage (degrés) et recul (m, 0 : aucun).
var _frame_pitch: float = 32.0
var _frame_distance: float = 0.0
## (H5) Conversation en cours (EventBus.dialogue_started → dialogue_ended).
var _talking: bool = false

@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	_target_distance = clampf(distance, min_distance, max_distance)
	_distance = _target_distance
	_frame_pitch = pitch_deg
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_ended.connect(_on_dialogue_ended)
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
	_frame_pitch = lerpf(_frame_pitch, framing.x, frame_weight)
	_frame_distance = lerpf(_frame_distance, framing.y, frame_weight)
	var goal := focus_goal()
	_focus = _focus.lerp(goal, 1.0 - exp(-follow_speed * delta))
	_distance = lerpf(
		_distance, maxf(_target_distance, _frame_distance), 1.0 - exp(-zoom_smoothing * delta)
	)
	_apply()


## Point visé idéal : le joueur (un peu en avant dans le sens de la marche si with_lead, et vers
## la cible verrouillée), borné à limits ; (H5) devant un bâtiment, plus haut et plus au nord, là
## où regarde la caméra qui lève les yeux sans bouger.
func focus_goal(with_lead: bool = true) -> Vector3:
	var reach := maxf(_target_distance, _frame_distance)
	return _player_focus(with_lead) + (_back(pitch_deg) - _back(_frame_pitch)) * reach


## Point visé sans cadrage de bâtiment : le joueur, l'avance, la cible verrouillée, les bornes.
func _player_focus(with_lead: bool) -> Vector3:
	var goal := global_position + Vector3.UP * focus_height
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
	_frame_pitch = framing.x
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


## Tangage (radians, négatif : la caméra regarde vers le bas) ; (H5) pitch_deg, sauf devant un
## bâtiment (cadrage).
func pitch() -> float:
	return -deg_to_rad(_frame_pitch)


## Avant horizontal de la caméra : le nord.
func forward() -> Vector3:
	return Vector3.FORWARD


func _apply() -> void:
	var tilt := deg_to_rad(_frame_pitch)
	camera.global_transform = Transform3D(
		Basis(Vector3.RIGHT, -tilt), _focus + _back(_frame_pitch) * _distance
	)
	_update_focus_band()


## Direction du point visé vers la caméra pour un tangage (degrés).
static func _back(degrees: float) -> Vector3:
	var tilt := deg_to_rad(degrees)
	return Vector3(0.0, sin(tilt), cos(tilt))


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


## (H5) Cadrage des bâtiments voulu : Vector2(tangage en degrés, recul), (pitch_deg, 0) sans
## façade à cadrer. La caméra garde sa place (au recul du zoom du joueur, au tangage pitch_deg) et
## lève les yeux juste assez pour que le haut de chaque façade proche passe sous FRAME_TOP, les
## pieds du joueur restant au-dessus de FRAME_FEET et le tangage au-dessus de FRAME_MIN_PITCH ;
## sinon elle recule du moins possible (recherche par dichotomie : le cadre ne fait que gagner à
## reculer). Au recul maximal, le joueur passe avant la façade. En conversation, ni recul ni
## pieds sous FRAME_FEET_TALKING. Calcul exact (angles), quelques arcs tangentes par image.
func _building_framing() -> Vector2:
	var none := Vector2(pitch_deg, 0.0)
	if not is_inside_tree():
		return none
	var origin := _player_focus(true)
	var walls := _walls_in_front(origin)
	if walls.is_empty():
		return none
	var half_fov := tan(deg_to_rad(camera.fov) / 2.0)
	var top := atan(FRAME_TOP * half_fov)
	var feet_angle := atan((FRAME_FEET_TALKING if _talking else FRAME_FEET) * half_fov)
	var feet := Vector2(origin.z - global_position.z, global_position.y - origin.y)
	# Hauteur demandée de chaque façade : de ce que le cadrage habituel montre déjà à son mur
	# entier, selon le fondu (poids z) ; une façade déjà dans le cadre ne demande rien.
	var demands: Array[Vector2] = []
	for wall: Vector3 in walls:
		var shown := _shown_height(wall.x, _target_distance, top)
		if wall.y > shown:
			demands.append(Vector2(wall.x, lerpf(shown, wall.y, wall.z)))
	if demands.is_empty():
		return none
	var bounds := _tilt_bounds(demands, feet, feet_angle, _target_distance, top)
	if bounds.x >= bounds.y or _talking:
		return Vector2(rad_to_deg(maxf(bounds.x, bounds.y)), 0.0)
	var near := _target_distance
	var far := FRAME_MAX_DISTANCE
	bounds = _tilt_bounds(demands, feet, feet_angle, far, top)
	if bounds.x < bounds.y:
		return Vector2(rad_to_deg(bounds.y), far)
	for _i in 12:
		var middle := (near + far) / 2.0
		var tried := _tilt_bounds(demands, feet, feet_angle, middle, top)
		if tried.x >= tried.y:
			far = middle
		else:
			near = middle
	bounds = _tilt_bounds(demands, feet, feet_angle, far, top)
	return Vector2(rad_to_deg(maxf(bounds.x, bounds.y)), far)


## Tangages permis (radians) avec la caméra à reach m du point visé sans cadrage, au tangage
## pitch_deg : Vector2(le plus fort qui met chaque façade demandée sous l'angle top au-dessus de
## l'axe, borné à pitch_deg ; le plus faible qui garde les pieds au-dessus de feet_angle, borné à
## FRAME_MIN_PITCH). Un point vu à l'élévation φ depuis l'œil paraît à φ + tangage de l'axe.
func _tilt_bounds(
	demands: Array[Vector2], feet: Vector2, feet_angle: float, reach: float, top: float
) -> Vector2:
	var high := deg_to_rad(pitch_deg)
	for wall: Vector2 in demands:
		high = minf(high, top - _elevation(wall, reach))
	var low := maxf(deg_to_rad(FRAME_MIN_PITCH), feet_angle - _elevation(feet, reach))
	return Vector2(high, low)


## Élévation (radians, > 0 au-dessus de l'horizon) d'un point à point.x m au nord du point visé
## sans cadrage et point.y m au-dessus, vu de la caméra placée à reach m de ce point au tangage
## pitch_deg.
func _elevation(point: Vector2, reach: float) -> float:
	var eye := _back(pitch_deg) * reach
	return atan2(point.y - eye.y, point.x + eye.z)


## Hauteur au-dessus du point visé que le cadrage habituel (tangage pitch_deg) montre, sous l'angle
## top au-dessus de l'axe, à north m au nord du point visé.
func _shown_height(north: float, reach: float, top: float) -> float:
	var eye := _back(pitch_deg) * reach
	return eye.y + (north + eye.z) * tan(top - deg_to_rad(pitch_deg))


## Façades sud à cadrer : Vector3(écart au nord du point visé, hauteur à montrer au-dessus de lui,
## poids du fondu 0..1) de chaque Building dont la façade est à moins de FRAME_REACH m au nord du
## joueur et dont la largeur croise le milieu du champ. Le poids naît sur le premier mètre devant
## la façade et s'éteint sur les FRAME_FADE derniers mètres de la portée et les FRAME_SIDE_FADE
## derniers mètres du champ.
func _walls_in_front(origin: Vector3) -> Array[Vector3]:
	var walls: Array[Vector3] = []
	var size := get_viewport().get_visible_rect().size
	var aspect := size.x / size.y if size.y > 0.0 else 16.0 / 9.0
	var half_width := 0.8 * _target_distance * tan(deg_to_rad(camera.fov) / 2.0) * aspect
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
		var aside := maxf(left - global_position.x, global_position.x - right)
		if ahead <= 0.0 or ahead >= FRAME_REACH or aside >= half_width:
			continue
		var weight := (
			smoothstep(0.0, 1.0, ahead)
			* (1.0 - smoothstep(FRAME_REACH - FRAME_FADE, FRAME_REACH, ahead))
			* (1.0 - smoothstep(half_width - FRAME_SIDE_FADE, half_width, aside))
		)
		var tall := building.ridge_height if building.gable_front else building.wall_height
		var top := xform.origin.y + tall * xform.basis.get_scale().y + FRAME_MARGIN
		walls.append(Vector3(origin.z - front, top - origin.y, weight))
	return walls


func _on_dialogue_started(_npc_id: StringName) -> void:
	_talking = true


func _on_dialogue_ended(_npc_id: StringName) -> void:
	_talking = false
