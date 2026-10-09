extends Node3D
## Caméra HD-2D du joueur : racine « CameraRig » de camera_rig.tscn, enfant de player.tscn (PLAN.md
## sections 3 et 4). Propriétaire : L1.
##
## Caméra fixe à la manière d'Octopath Traveler : elle regarde toujours le nord (−Z), inclinée de
## pitch_deg vers le bas, avec un champ étroit (fov_deg), à distance du point visé. Elle suit le
## joueur avec un léger retard (follow_speed) et reste dans les bornes de la carte courante
## (limits ; sur l'ancienne île, au bord, on voit la lèvre, la falaise et la mer de nuages, le
## joueur restant près du centre). Pas de
## rotation : le haut de l'écran est le nord, les commandes sont relatives à l'écran (player.gd).
## La molette ou le stick droit (camera_up / camera_down) zooment un peu (entre min_distance et
## max_distance).
##
## Cadrage constant (recette du 8 octobre 2026) : le tangage et la distance ne changent qu'à la
## demande du joueur (zoom). Le point visé est à focus_ahead m au nord du joueur : il se tient
## sous le milieu de l'écran et les façades devant lui tiennent mieux dans le cadre. L'ancien
## cadrage automatique des bâtiments (H5 : la caméra levait les yeux et reculait devant une
## façade) est retiré : en marchant le long des façades, il faisait pomper la vue comme un zoom
## d'avant en arrière. En conversation (EventBus.dialogue_started → dialogue_ended), le point
## visé glisse en douceur vers le joueur (talk_ahead) pour qu'il reste au-dessus de la boîte de
## dialogue. L'avance dans le sens de la marche (lead_time) s'installe et s'éteint en douceur
## (lead_smoothing) : pas d'à-coup au départ ni à l'arrêt.
##
## Lissage physique (project.godot : physics/common/physics_interpolation) : le joueur bouge
## aux images physiques (60 par seconde) ; la caméra suit sa position interpolée entre deux
## images physiques (get_global_transform_interpolated), sinon le joueur tremblerait à l'écran
## dès que l'affichage ne tourne pas à 60 images/s (45, 120, 144…). La Camera3D, posée ici à
## chaque image, n'est pas interpolée elle-même.
##
## Structure : Camera3D (caméra courante, top_level : elle ne suit pas les rotations du joueur) et
## PostFX (CanvasLayer derrière l'interface : flou de profondeur, lueur, étalonnage chaud,
## src/player/post_fx.gdshader ; la bande nette suit le joueur à l'écran).
## Verrouillage : lock_target est cadrée avec le joueur (le point visé avance vers elle, sans
## rotation). Le joueur (player.gd) pose lock_target et follow_velocity à chaque image physique.
## (E1) Cartes : à chaque EventBus.map_entered (et à son _ready s'il y a déjà une carte), limits
## prend les bornes de la carte courante (WorldManager.camera_bounds(), Map.camera_bounds, la
## carte entière par défaut), la caméra redevient la caméra courante (une carte peut en
## apporter une, comme l'OverviewCamera de l'île) et se recale sur le joueur (snap), déjà posé
## sur son marqueur d'arrivée.

## (H5) Profondeur nette du flou de profondeur autour du joueur (m) : derrière lui (vers le
## nord) et devant lui (vers la caméra).
const BAND_AHEAD := 9.0
const BAND_BEHIND := 4.5

## Inclinaison de la caméra vers le bas (degrés) et champ vertical (degrés).
@export_range(20.0, 60.0) var pitch_deg: float = 32.0
@export_range(15.0, 60.0) var fov_deg: float = 30.0
## Hauteur du point visé au-dessus des pieds du joueur (m).
@export var focus_height: float = 0.8
## Écart du point visé au nord du joueur (m) : le joueur se tient sous le milieu de l'écran ;
## en conversation, talk_ahead (au-dessus de la boîte de dialogue). Lissage du passage (1/s).
@export var focus_ahead: float = 2.5
@export var talk_ahead: float = 0.0
@export var ahead_smoothing: float = 2.0

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
## Avance du point visé dans le sens de la marche (s de déplacement), pour voir où l'on va, et
## lissage de cette avance (1/s) : elle s'installe et s'éteint en douceur.
@export var lead_time: float = 0.2
@export var lead_smoothing: float = 2.5
## Bornes du point visé dans le plan du sol (x, z). (H5) Assez larges pour que le joueur reste à
## moins de 6 m du centre au bord de l'île (le bord du Couchant est à x = −77) : on voit alors
## la lèvre, la falaise et la mer de nuages, jamais le joueur au bord de l'écran. (E1) Remplacées
## par les bornes de la carte courante à chaque changement de carte ; valeur de la scène tant
## qu'aucune carte n'est posée.
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
## Avance lissée dans le sens de la marche (m) et écart au nord lissé (m).
var _lead: Vector3 = Vector3.ZERO
var _ahead: float = 2.5
## (H5) Conversation en cours (EventBus.dialogue_started → dialogue_ended).
var _talking: bool = false

@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	_target_distance = clampf(distance, min_distance, max_distance)
	_distance = _target_distance
	_ahead = focus_ahead
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_ended.connect(_on_dialogue_ended)
	EventBus.map_entered.connect(_on_map_entered)
	if WorldManager.current_map_node() != null:
		limits = WorldManager.camera_bounds()
	camera.top_level = true
	# Posée à chaque image (pas aux images physiques) : jamais interpolée.
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	camera.fov = fov_deg
	var screen := get_node_or_null(^"PostFX/Screen") as CanvasItem
	if screen != null and screen.material is ShaderMaterial:
		# Copie propre à cette caméra : la bande nette et les réglages de lumière
		# (HD2DLighting.apply_post) ne touchent pas la ressource de la scène.
		_post = screen.material.duplicate() as ShaderMaterial
		screen.material = _post
	snap()
	# Le joueur peut encore être déplacé avant la première image (game.gd : position de la
	# sauvegarde ou téléportation au Spawn, après ce _ready) : la première update_camera() se
	# recale sur lui au lieu de glisser pendant une seconde depuis la place de player.tscn.
	_started = false


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
	var wanted_lead := Vector3(follow_velocity.x, 0.0, follow_velocity.z) * lead_time
	_lead = _lead.lerp(wanted_lead, 1.0 - exp(-lead_smoothing * delta))
	_ahead = lerpf(
		_ahead, talk_ahead if _talking else focus_ahead, 1.0 - exp(-ahead_smoothing * delta)
	)
	_focus = _focus.lerp(focus_goal(), 1.0 - exp(-follow_speed * delta))
	_distance = lerpf(_distance, _target_distance, 1.0 - exp(-zoom_smoothing * delta))
	_apply()


## Point visé idéal : à _ahead m au nord du joueur (avec l'avance lissée dans le sens de la
## marche si with_lead, et vers la cible verrouillée), borné à limits.
func focus_goal(with_lead: bool = true) -> Vector3:
	return _goal_from(anchor(), with_lead)


## Point visé idéal pour des pieds en feet (voir focus_goal).
func _goal_from(feet: Vector3, with_lead: bool) -> Vector3:
	var goal := feet + Vector3.UP * focus_height + Vector3.FORWARD * _ahead
	if with_lead:
		goal += _lead
	var target := _valid_target()
	if target != null:
		var shown := (
			target.get_global_transform_interpolated().origin
			if target.is_physics_interpolated_and_enabled()
			else target.global_position
		)
		var offset := shown - feet
		offset.y = 0.0
		goal += (offset * lock_focus).limit_length(lock_focus_max)
	goal.x = clampf(goal.x, limits.position.x, limits.end.x)
	goal.z = clampf(goal.z, limits.position.y, limits.end.y)
	return goal


## Position affichée du joueur (pieds) : interpolée entre deux images physiques quand le lissage
## physique est actif, sinon sa position.
func anchor() -> Vector3:
	if is_physics_interpolated_and_enabled():
		return get_global_transform_interpolated().origin
	return global_position


## Replace immédiatement la caméra sur le joueur (apparition, téléportation, réapparition).
func snap() -> void:
	if not is_inside_tree():
		return
	_started = true
	var body := get_parent() as Node3D
	if body != null:
		# Téléportation : le joueur ne glisse pas de l'ancienne place à la nouvelle.
		body.reset_physics_interpolation()
	reset_physics_interpolation()
	_lead = Vector3.ZERO
	_ahead = talk_ahead if _talking else focus_ahead
	# La place affichée n'est recalculée qu'une fois par image : juste après une téléportation,
	# elle donne encore l'ancienne. La caméra se recale sur la vraie position.
	_focus = _goal_from(global_position, false)
	_distance = _target_distance
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


## Tangage (radians, négatif : la caméra regarde vers le bas) : pitch_deg.
func pitch() -> float:
	return -deg_to_rad(pitch_deg)


## Avant horizontal de la caméra : le nord.
func forward() -> Vector3:
	return Vector3.FORWARD


func _apply() -> void:
	var tilt := deg_to_rad(pitch_deg)
	camera.global_transform = Transform3D(
		Basis(Vector3.RIGHT, -tilt), _focus + _back(pitch_deg) * _distance
	)
	_update_focus_band()


## Direction du point visé vers la caméra pour un tangage (degrés).
static func _back(degrees: float) -> Vector3:
	var tilt := deg_to_rad(degrees)
	return Vector3(0.0, sin(tilt), cos(tilt))


## (H5) La bande nette du flou de profondeur (post_fx.gdshader : focus_center, focus_half) suit
## le joueur à l'écran : elle va de BAND_BEHIND m devant lui (vers la caméra) à BAND_AHEAD m
## derrière lui, à mi-hauteur d'un personnage. Le joueur et ceux qui l'entourent ne sont jamais
## flous, même décentrés par le retard du suivi, l'avance, le verrouillage ou les bornes de
## l'île.
func _update_focus_band() -> void:
	if _post == null:
		return
	var height := get_viewport().get_visible_rect().size.y
	var middle := anchor() + Vector3.UP * focus_height
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


func _on_dialogue_started(_npc_id: StringName) -> void:
	_talking = true


func _on_dialogue_ended(_npc_id: StringName) -> void:
	_talking = false


## (E1) Nouvelle carte : ses bornes, la caméra courante, recalée sur le joueur.
func _on_map_entered(_map_id: StringName) -> void:
	limits = WorldManager.camera_bounds()
	if is_inside_tree():
		camera.make_current()
		snap()
