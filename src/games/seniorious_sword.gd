class_name SenioriousSword
extends Node3D
## (E8b) Seniorious arrachée par la troisième Grue de Gossamer (docs/lore/ACTE1.md, 3.4 et 11.4) :
## elle tourne en l'air, plonge dans le marais, y luit ; on la ramasse (invite « Ramasser
## Seniorious »). Posée et avancée par SenioriousTraining (advance, au temps de l'exercice).
## Propriétaire : E8.
##
## La lame est une image (src/games/fx/seniorious.png, tools/gen_duel_sheet.py), tournée face à la
## caméra fixe ; un halo bleu clair la suit (Duel.make_glow). L'invite est un Interactable (couche
## 6, groupe « interactable », contrat de PLAN.md section 3).

## L'épée est tombée en at.
signal landed(at: Vector3)
## Chtholly l'a ramassée.
signal picked

## Couche 6 (interactable) et groupe des interactables (PLAN.md, section 3).
const INTERACTABLE_LAYER := 32
const INTERACTABLE_GROUP := &"interactable"
const BLADE_TEXTURE := preload("res://src/games/fx/seniorious.png")
const GLOW_COLOR := Color(0.6, 0.85, 1.0)
const GLOW_SIZE := 1.1
## Tours en l'air avant de plonger pointe en bas.
const SPINS := 3.0

## L'invite (vide : pas d'invite, l'épée tombe et c'est tout).
var prompt: String = ""
## Rayon de l'invite (m).
var reach: float = 1.2

var _from: Vector3 = Vector3.ZERO
var _to: Vector3 = Vector3.ZERO
var _duration: float = 1.0
var _height: float = 3.0
var _time: float = 0.0
var _landed: bool = false
var _picked: bool = false
var _blade: Sprite3D = null
var _glow: MeshInstance3D = null
var _area: SwordPickup = null


## L'invite du marais : « Ramasser Seniorious ».
class SwordPickup:
	extends Area3D

	var sword: SenioriousSword = null

	func get_prompt() -> String:
		return sword.prompt if sword != null and is_instance_valid(sword) else ""

	func interact(_player: Node3D) -> void:
		if sword != null and is_instance_valid(sword):
			sword.pick_up()


func _init() -> void:
	name = "Seniorious"


## Lance l'épée de from (la main de Chtholly) à to (le marais) en duration s, arc de height m.
func launch(from: Vector3, to: Vector3, duration: float, height: float) -> void:
	_from = from
	_to = to
	_duration = maxf(duration, 0.05)
	_height = height
	_time = 0.0
	_blade = Sprite3D.new()
	_blade.name = "Blade"
	_blade.texture = BLADE_TEXTURE
	_blade.pixel_size = 1.0 / 96.0
	_blade.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_blade.shaded = false
	_blade.double_sided = true
	_blade.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	_blade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_blade)
	_glow = Duel.make_glow(GLOW_SIZE, GLOW_COLOR)
	_glow.name = "Glow"
	add_child(_glow)
	_place(0.0)


## Avance le vol de delta s ; posée, elle luit (le halo respire).
func advance(delta: float) -> void:
	if _blade == null:
		return
	_time += delta
	if _landed:
		var breath := 0.5 + 0.5 * sin(_time * 3.0)
		var material := _glow.material_override as StandardMaterial3D
		material.albedo_color.a = 0.35 + 0.35 * breath
		return
	var ratio := clampf(_time / _duration, 0.0, 1.0)
	_place(ratio)
	if ratio >= 1.0:
		_land()


## Vrai une fois tombée.
func is_landed() -> bool:
	return _landed


## Vrai une fois ramassée.
func is_picked() -> bool:
	return _picked


## Où elle est tombée (le marais).
func spot() -> Vector3:
	return _to


## L'invite (null avant qu'elle tombe, ou sans invite).
func pickup_area() -> Area3D:
	return _area


## Chtholly la ramasse (l'invite) : picked, l'invite s'en va.
func pick_up() -> void:
	if not _landed or _picked:
		return
	_picked = true
	if _area != null:
		_area.remove_from_group(INTERACTABLE_GROUP)
	picked.emit()


## Retire l'invite (l'exercice est fini).
func close_pickup() -> void:
	if _area != null and is_instance_valid(_area):
		_area.remove_from_group(INTERACTABLE_GROUP)
		_area.queue_free()
	_area = null


func _place(ratio: float) -> void:
	var at := _from.lerp(_to + Vector3.UP * 0.35, ratio)
	at.y += 4.0 * _height * ratio * (1.0 - ratio)
	_blade.global_position = at
	_glow.global_position = at
	# Elle tourne en l'air, puis plonge pointe en bas.
	var angle := lerpf(0.0, -TAU * SPINS - PI * 0.6, ratio)
	var camera := get_viewport().get_camera_3d() if is_inside_tree() else null
	var facing := camera.global_basis if camera != null else Basis.IDENTITY
	_blade.global_basis = facing * Basis(Vector3.BACK, angle)


func _land() -> void:
	_landed = true
	if is_inside_tree():
		CombatFx.spawn_burst(self, "dust", _to + Vector3.UP * 0.1, Color(0.7, 0.8, 0.85))
		CombatFx.spawn_burst(self, "impact", _to + Vector3.UP * 0.3, CombatFx.COLOR_WAVE)
	if not prompt.is_empty():
		_area = SwordPickup.new()
		_area.name = "Pickup"
		_area.sword = self
		_area.collision_layer = INTERACTABLE_LAYER
		_area.collision_mask = 0
		_area.monitoring = false
		_area.add_to_group(INTERACTABLE_GROUP)
		var shape := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = reach
		shape.shape = sphere
		_area.add_child(shape)
		add_child(_area)
		_area.global_position = _to + Vector3.UP * 0.5
	landed.emit(_to)
