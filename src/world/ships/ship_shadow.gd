class_name ShipShadow
extends Node3D
## (E7) L'ombre d'un navire qui passe dans les nuages, devant la caméra (scène 8.6 : Chtholly
## tombe dans la mer de nuages, une ombre passe, elle reconnaît le Barocupot). Faite par
## ShipControl.pass_shadow, qui la pose dans la carte chargée ; elle traverse la vue d'ouest en
## est, apparaît et s'efface en fondu, puis se libère. Une silhouette sombre à alpha doux (la
## silhouette livrée du navire, teintée), jamais un maillage. Propriétaire : E7.
##
## Réglages (data/ships/<id>.json, « shadow ») : image, ppm (densité : plus grand, plus loin),
## time (s), distance (m devant la caméra), drop (m sous l'axe de la caméra), span (m parcourus),
## tint ([r, g, b]), opacity, fade (part du trajet en fondu à chaque bout).

## L'ombre est passée.
signal passed

const GROUP := &"ship_shadows"
const DEFAULT_IMAGE := "res://assets/hd2d/props/airship_barocupot.png"

## Navire dont c'est l'ombre (data/ships/<ship_id>.json).
var ship_id: StringName = &""

var _settings: Dictionary = {}
var _time: float = 0.0
var _duration: float = 7.0
var _done: bool = false
var _start := Vector3.ZERO
var _end := Vector3.ZERO
var _panel: ShipStrip


## Réglages (avant d'entrer dans l'arbre).
func setup(settings: Dictionary) -> void:
	_settings = settings
	_duration = maxf(float(settings.get("time", 7.0)), 0.1)


func _ready() -> void:
	add_to_group(GROUP)
	_panel = ShipStrip.new()
	_panel.name = "Silhouette"
	_panel.texture = load(str(_settings.get("image", DEFAULT_IMAGE))) as Texture2D
	_panel.pixels_per_meter = float(_settings.get("ppm", 48.0))
	_panel.shadow_width = 0.0
	_panel.soft_alpha = true
	var tint: Array = _settings.get("tint", [0.16, 0.18, 0.24])
	_panel.tint = Color(float(tint[0]), float(tint[1]), float(tint[2]), 1.0)
	add_child(_panel)
	_place()
	advance(0.0)


func _physics_process(delta: float) -> void:
	advance(delta)


## Avance le passage de delta s (les tests avancent d'un coup).
func advance(delta: float) -> void:
	if _done:
		return
	_time = minf(_time + delta, _duration)
	var u := _time / _duration
	global_position = _start.lerp(_end, u)
	var fade := clampf(float(_settings.get("fade", 0.25)), 0.01, 0.5)
	var shown := minf(smoothstep(0.0, fade, u), 1.0 - smoothstep(1.0 - fade, 1.0, u))
	_panel.opacity = float(_settings.get("opacity", 0.55)) * shown
	if _time >= _duration:
		_done = true
		passed.emit()
		queue_free()


func is_done() -> bool:
	return _done


## Part du trajet faite (0..1).
func progress() -> float:
	return _time / _duration


## Opacité affichée.
func shown_opacity() -> float:
	return _panel.opacity if _panel != null else 0.0


## Le trajet : à distance m devant la caméra, drop m sous son axe, de span / 2 à l'ouest à span / 2
## à l'est (la caméra regarde le nord).
func _place() -> void:
	var camera := get_viewport().get_camera_3d() if get_viewport() != null else null
	var eye := camera.global_position if camera != null else Vector3(0.0, 10.0, 20.0)
	var ahead := -camera.global_basis.z if camera != null else Vector3.FORWARD
	var center := eye + ahead * float(_settings.get("distance", 40.0))
	center.y -= float(_settings.get("drop", 6.0))
	var half := float(_settings.get("span", 70.0)) / 2.0
	_start = center + Vector3.LEFT * half
	_end = center + Vector3.RIGHT * half
	global_position = _start
