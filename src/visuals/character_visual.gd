class_name CharacterVisual
extends Node3D
## Visuel d'un personnage en billboard HD-2D (PLAN.md sections 3 et 5). Propriétaire : L3.
## Point d'entrée unique, instancié sous le nom « Visual » dans player.tscn, enemy.tscn, npc.tscn
## (et le menu).
##
## Planche (SkinData.sprite_sheet + frames_json) : l'enfant « Sprite » (AnimatedSprite3D,
## billboard axe Y : toujours face à la caméra fixe, filtrage nearest, alpha scissor) affiche les
## images de SheetLoader ; l'ancre de chaque image est remise à l'origine du nœud à chaque image
## (pieds au sol, pas de saut, retournement compris). (HD-2D) La variante « mesh » des modèles 3D
## est retirée : un personnage est toujours une planche.
## Horloge commune, celle de jeu.js : image = floor(t × ips), en boucle ou bloquée sur la
## dernière. frame_changed est émis pour chaque image affichée, image 0 comprise (et à chaque
## tour d'une boucle) ; animation_finished une fois quand t ≥ images / ips (sans boucle).
## L'ombre (« Shadow », disque transparent au sol) et le sprite suivent l'échelle du nœud
## (Visual.scale = EnemyData.scale pour les Timeres).
## (H6) Trois vues : selon la direction de set_facing par rapport à la caméra (fixe, vers le
## nord), le sprite montre le dos (le personnage va vers le haut de l'écran), la face (vers le bas)
## ou le profil (sur le côté, retourné vers la gauche), si le skin a ces vues
## (SheetLoader.has_view) ; sinon toujours le profil, comme une planche de l'easter egg. Une zone
## morte de VIEW_DEAD_ZONE_DEG autour des diagonales évite le clignotement. Changer de vue garde
## l'animation, l'image et l'horloge, sans émettre de signal : le combat ne voit rien.

## Émis à chaque image affichée (y compris l'image 0 au lancement d'une animation).
signal frame_changed(anim: StringName, frame: int)
## Émis à la fin d'une animation non bouclée.
signal animation_finished(anim: StringName)

## Animation jouée au départ, et au changement de skin si le nouveau n'a pas l'animation en cours.
const IDLE := &"repos"
## Rayon de l'ombre / demi-largeur du corps au repos (Chtholly : 0,38 m, comme jeu.js).
const SHADOW_RATIO := 0.75
## En deçà (|cos|), la direction est face ou dos à la caméra : le sprite garde son côté.
const FACING_DEAD_ZONE := 0.1
## (H6) Au-delà de cet angle (degrés) entre la direction et l'axe gauche-droite de l'écran, le
## personnage montre sa face ou son dos plutôt que son profil.
const VIEW_ANGLE_DEG := 45.0
## (H6) Demi-largeur (degrés) de la zone morte autour de VIEW_ANGLE_DEG : la vue ne change qu'une
## fois la direction franchement passée de l'autre côté.
const VIEW_DEAD_ZONE_DEG := 10.0
## Tolérance de floor(t × ips) (temps avancé par pas exacts de 1 / ips).
const TIME_EPSILON := 0.0001

## Skin affiché (peut être fixé dans une scène ; à l'exécution, utiliser set_skin()).
@export var skin: SkinData:
	set(value):
		if value == skin and is_node_ready():
			return
		skin = value
		if is_node_ready():
			_apply_skin()

var _sheet: Dictionary = {}
var _clips: Dictionary = {}
var _anim: StringName = &""
var _frame: int = 0
var _time: float = 0.0
var _step: int = 0
var _playing: bool = false
var _finished: bool = false
var _generation: int = 0
var _facing: Vector3 = Vector3.ZERO
## (H6) Vue affichée et vues disponibles : vue → [SpriteFrames, pixel_size].
var _view: StringName = SheetLoader.SIDE
var _views: Dictionary = {}
var _side_flip: bool = false

@onready var _sprite: AnimatedSprite3D = $Sprite
@onready var _shadow: MeshInstance3D = $Shadow


func _ready() -> void:
	_apply_skin()


func _process(delta: float) -> void:
	advance(delta)
	_update_facing()


## Change de skin, à chaud : si le nouveau skin a l'animation en cours, elle continue au même
## instant sans réémettre frame_changed ; sinon « repos » démarre. Même skin : sans effet.
func set_skin(new_skin: SkinData) -> void:
	skin = new_skin


## Joue anim depuis l'image 0. Si anim est déjà en cours, elle continue sans relance (figée par
## show_frame, elle reprend à son image), sauf restart = true ; finie (sans boucle), elle est
## relancée. Sans effet si le skin n'a pas cette animation.
func play(anim: StringName, restart: bool = false) -> void:
	if not has_animation(anim):
		return
	if anim == _anim and not restart and not _finished:
		_playing = true
		return
	_generation += 1
	_time = 0.0
	_step = 0
	_playing = true
	_finished = false
	_show(anim, 0)
	frame_changed.emit(anim, 0)


## Fige l'animation anim sur l'image frame (ex. charge maintenue) ; play(anim) reprend de là.
## frame_changed est émis si l'image affichée change.
func show_frame(anim: StringName, frame: int) -> void:
	if not has_animation(anim):
		return
	var clip: Clip = _clips[anim]
	var index := clampi(frame, 0, clip.count - 1)
	var changed := anim != _anim or index != _frame
	_generation += 1
	_playing = false
	_finished = false
	_step = index
	_time = index / clip.fps
	_show(anim, index)
	if changed:
		frame_changed.emit(anim, index)


## Oriente le personnage vers direction (plan du sol) : les planches regardent vers la droite,
## le sprite est retourné quand direction pointe vers la gauche de la caméra courante ; (H6) vers
## le haut ou le bas de l'écran, il montre son dos ou sa face si le skin a ces vues.
func set_facing(direction: Vector3) -> void:
	var flat := Vector3(direction.x, 0.0, direction.z)
	if flat.length_squared() < 0.0001:
		return
	_facing = flat.normalized()
	_update_facing()


## Images « coup » de anim (lues dans le JSON de la planche, qui fait foi).
func hit_frames(anim: StringName) -> Array[int]:
	return SheetLoader.hit_frames(_sheet, anim)


## Image « onde » de anim (charge), -1 si absente.
func wave_frame(anim: StringName) -> int:
	return SheetLoader.wave_frame(_sheet, anim)


func has_animation(anim: StringName) -> bool:
	return _clips.has(anim)


func current_animation() -> StringName:
	return _anim


## Image affichée de l'animation courante.
func current_frame() -> int:
	return _frame


## (H6) Vue affichée : SheetLoader.SIDE (profil), FRONT (face) ou BACK (dos).
func current_view() -> StringName:
	return _view


## true tant que l'animation courante avance (ni finie, ni figée par show_frame).
func is_playing() -> bool:
	return _playing


## Fait avancer l'horloge des animations de delta secondes : appelé par _process, ou par un test
## pour un temps exact. Les images sautées par un grand delta sont toutes émises, dans l'ordre
## (un tour au plus pour une boucle).
func advance(delta: float) -> void:
	if not _playing or not _clips.has(_anim):
		return
	var clip: Clip = _clips[_anim]
	_time += delta
	var target := floori(_time * clip.fps + TIME_EPSILON)
	var last_step := target if clip.loops else mini(target, clip.count - 1)
	if clip.loops:
		_step = maxi(_step, last_step - clip.count)
	var generation := _generation
	while _step < last_step:
		_step += 1
		_show(_anim, _step % clip.count)
		frame_changed.emit(_anim, _frame)
		if generation != _generation:
			return
	if not clip.loops and target >= clip.count:
		_playing = false
		_finished = true
		animation_finished.emit(_anim)


func _apply_skin() -> void:
	var previous := _anim
	_clips.clear()
	_sheet = {}
	_views.clear()
	_view = SheetLoader.SIDE
	_sprite.sprite_frames = null
	if skin != null:
		_load_sheet()
	_sprite.visible = _sprite.sprite_frames != null
	_shadow.visible = not _clips.is_empty()
	_generation += 1
	if _clips.has(previous):
		var clip: Clip = _clips[previous]
		_step = floori(_time * clip.fps + TIME_EPSILON)
		_show(previous, _step % clip.count if clip.loops else mini(_step, clip.count - 1))
	else:
		_anim = &""
		_playing = false
		_finished = false
		if not _clips.is_empty():
			play(IDLE if _clips.has(IDLE) else StringName(_clips.keys()[0]))
	_update_facing()


func _load_sheet() -> void:
	var frames := SheetLoader.frames_for(skin)
	if frames == null:
		return
	_sheet = SheetLoader.read_sheet(skin)
	_sprite.sprite_frames = frames
	_sprite.pixel_size = SheetLoader.pixel_size(skin, _sheet)
	for anim_name: String in frames.get_animation_names():
		_clips[StringName(anim_name)] = Clip.new(
			frames.get_animation_speed(anim_name),
			frames.get_frame_count(anim_name),
			frames.get_animation_loop(anim_name)
		)
	var half_width := SheetLoader.body_half_width(_sheet) * _sprite.pixel_size
	_set_shadow_radius(SHADOW_RATIO * half_width)
	_views[SheetLoader.SIDE] = [frames, _sprite.pixel_size]
	for view: StringName in [SheetLoader.FRONT, SheetLoader.BACK]:
		if SheetLoader.has_view(skin, view):
			var view_sheet := SheetLoader.read_sheet(skin, view)
			_views[view] = [
				SheetLoader.frames_for(skin, view),
				SheetLoader.pixel_size(skin, _sheet, view_sheet),
			]


## Affiche l'image frame de anim (sans signal) : sprite et ancre.
func _show(anim: StringName, frame: int) -> void:
	_anim = anim
	_frame = frame
	if _sprite.sprite_frames != null:
		if _sprite.animation != anim:
			_sprite.animation = anim
		_sprite.frame = frame
		_sync_offset()


func _sync_offset() -> void:
	if _sprite.sprite_frames == null or not _sprite.sprite_frames.has_animation(_anim):
		return
	var texture := _sprite.sprite_frames.get_frame_texture(_anim, _frame)
	if texture != null:
		_sprite.offset = SheetLoader.frame_offset(texture, _sprite.flip_h)


func _update_facing() -> void:
	if _facing == Vector3.ZERO or not is_node_ready():
		return
	var right := Vector3.RIGHT
	var camera := get_viewport().get_camera_3d() if is_inside_tree() else null
	if camera != null:
		right = camera.global_basis.x
	right = Vector3(right.x, 0.0, right.z)
	right = right.normalized() if right.length_squared() > 0.0001 else Vector3.RIGHT
	var side := _facing.dot(right)
	if absf(side) >= FACING_DEAD_ZONE:
		_side_flip = side < 0.0
	# Vers la caméra (le bas de l'écran) : droite × haut, quelle que soit l'inclinaison.
	var view := _choose_view(_facing.dot(right.cross(Vector3.UP)))
	if view != _view:
		_set_view(view)
	var flip := _side_flip if _view == SheetLoader.SIDE else false
	if flip != _sprite.flip_h:
		_sprite.flip_h = flip
		_sync_offset()


## (H6) Vue voulue pour une direction dont la composante vers la caméra vaut toward (−1 : dos,
## 1 : face), avec la zone morte autour de VIEW_ANGLE_DEG ; le profil si la vue manque.
func _choose_view(toward: float) -> StringName:
	var margin := VIEW_DEAD_ZONE_DEG if _view == SheetLoader.SIDE else -VIEW_DEAD_ZONE_DEG
	if absf(toward) <= sin(deg_to_rad(VIEW_ANGLE_DEG + margin)):
		return SheetLoader.SIDE
	var wanted := SheetLoader.FRONT if toward > 0.0 else SheetLoader.BACK
	return wanted if _views.has(wanted) else SheetLoader.SIDE


## (H6) Affiche la vue view (SpriteFrames et taille de pixel) à l'image courante, sans signal.
func _set_view(view: StringName) -> void:
	var entry: Array = _views.get(view, [])
	if entry.is_empty():
		return
	_view = view
	_sprite.sprite_frames = entry[0]
	_sprite.pixel_size = entry[1]
	if _sprite.sprite_frames.has_animation(_anim):
		_show(_anim, _frame)


func _set_shadow_radius(radius: float) -> void:
	var diameter := 2.0 * clampf(radius, 0.1, 2.0)
	_shadow.scale = Vector3(diameter, 1.0, diameter)


## Cadence d'une animation de la planche.
class Clip:
	var fps: float
	var count: int
	var loops: bool

	func _init(clip_fps: float, clip_count: int, clip_loops: bool) -> void:
		fps = maxf(clip_fps, 0.01)
		count = maxi(clip_count, 1)
		loops = clip_loops
