class_name CharacterVisual
extends Node3D
## Visuel d'un personnage, même interface pour une planche de sprites et un mesh 3D (PLAN.md
## sections 3 et 5). Propriétaire : L3. Point d'entrée unique, instancié sous le nom « Visual »
## dans player.tscn, enemy.tscn, npc.tscn (et le menu).
##
## Planche (SkinData.sprite_sheet + frames_json) : l'enfant « Sprite » (AnimatedSprite3D,
## billboard axe Y, filtrage nearest, alpha scissor) affiche les images de SheetLoader ; l'ancre
## de chaque image est remise à l'origine du nœud à chaque image (pieds au sol, pas de saut,
## retournement compris). Mesh (SkinData.mesh_scene sans planche) : la scène est instanciée
## sous le nom « Mesh », son AnimationPlayer joue des animations nommées comme la planche dont
## les métadonnées « ips », « coup », « onde » remplacent le JSON.
## Horloge commune, celle de jeu.js : image = floor(t × ips), en boucle ou bloquée sur la
## dernière. frame_changed est émis pour chaque image affichée, image 0 comprise (et à chaque
## tour d'une boucle) ; animation_finished une fois quand t ≥ images / ips (sans boucle).
## L'ombre (« Shadow », disque transparent au sol) et le sprite suivent l'échelle du nœud
## (Visual.scale = EnemyData.scale pour les Timeres).

## Émis à chaque image affichée (y compris l'image 0 au lancement d'une animation).
signal frame_changed(anim: StringName, frame: int)
## Émis à la fin d'une animation non bouclée.
signal animation_finished(anim: StringName)

## Animation jouée au départ, et au changement de skin si le nouveau n'a pas l'animation en cours.
const IDLE := &"repos"
## Cadence d'une animation de mesh sans métadonnée « ips ».
const DEFAULT_MESH_FPS := 10.0
## Rayon de l'ombre / demi-largeur du corps au repos (Chtholly : 0,38 m, comme jeu.js).
const SHADOW_RATIO := 0.75
## Rayon de l'ombre / hauteur, pour un mesh.
const MESH_SHADOW_RATIO := 0.25
## En deçà (|cos|), la direction est face ou dos à la caméra : le sprite garde son côté.
const FACING_DEAD_ZONE := 0.1
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
var _mesh: Node3D
var _player: AnimationPlayer

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


## Oriente le personnage vers direction (plan du sol). Sprite : les planches regardent vers la
## droite, il est retourné quand direction pointe vers la gauche de la caméra courante (réévalué
## à chaque image quand la caméra tourne). Mesh : il tourne vers direction (avant = +Z).
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
	_sync_mesh_pose()
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
	_clear_mesh()
	_clips.clear()
	_sheet = {}
	_sprite.sprite_frames = null
	if skin != null and skin.sprite_sheet == null and skin.mesh_scene != null:
		_load_mesh()
	elif skin != null:
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


func _load_mesh() -> void:
	var instance := skin.mesh_scene.instantiate()
	if not instance is Node3D:
		instance.free()
		return
	_mesh = instance
	_mesh.name = "Mesh"
	add_child(_mesh)
	var players := _mesh.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		_player = players[0]
		_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		var anims := {}
		for anim_name: String in _player.get_animation_list():
			if anim_name == "RESET":
				continue
			var animation := _player.get_animation(anim_name)
			var fps := float(animation.get_meta(&"ips", DEFAULT_MESH_FPS))
			var looped := animation.loop_mode != Animation.LOOP_NONE
			_clips[StringName(anim_name)] = Clip.new(fps, roundi(animation.length * fps), looped)
			anims[anim_name] = {
				"coup": animation.get_meta(&"coup", []), "onde": animation.get_meta(&"onde", -1)
			}
		_sheet = {"animations": anims}
	_set_shadow_radius(MESH_SHADOW_RATIO * skin.height_m)


func _clear_mesh() -> void:
	if _mesh != null:
		remove_child(_mesh)
		_mesh.queue_free()
	_mesh = null
	_player = null


## Affiche l'image frame de anim (sans signal) : sprite et ancre, ou pose du mesh.
func _show(anim: StringName, frame: int) -> void:
	_anim = anim
	_frame = frame
	if _player != null:
		_sync_mesh_pose()
	elif _sprite.sprite_frames != null:
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


## Pose du mesh à l'instant de l'horloge (continue, pas image par image).
func _sync_mesh_pose() -> void:
	if _player == null or not _player.has_animation(_anim):
		return
	if _player.assigned_animation != _anim:
		_player.play(_anim)
	var length := _player.get_animation(_anim).length
	var clip: Clip = _clips[_anim]
	_player.seek(fmod(_time, length) if clip.loops and length > 0.0 else minf(_time, length), true)


func _update_facing() -> void:
	if _facing == Vector3.ZERO or not is_node_ready():
		return
	if _mesh != null:
		if _mesh.is_inside_tree():
			_mesh.global_rotation = Vector3(0.0, atan2(_facing.x, _facing.z), 0.0)
		return
	var right := Vector3.RIGHT
	var camera := get_viewport().get_camera_3d() if is_inside_tree() else null
	if camera != null:
		right = camera.global_basis.x
	var side := _facing.dot(right)
	if absf(side) >= FACING_DEAD_ZONE and (side < 0.0) != _sprite.flip_h:
		_sprite.flip_h = side < 0.0
		_sync_offset()


func _set_shadow_radius(radius: float) -> void:
	var diameter := 2.0 * clampf(radius, 0.1, 2.0)
	_shadow.scale = Vector3(diameter, 1.0, diameter)


## Cadence d'une animation (planche ou mesh).
class Clip:
	var fps: float
	var count: int
	var loops: bool

	func _init(clip_fps: float, clip_count: int, clip_loops: bool) -> void:
		fps = maxf(clip_fps, 0.01)
		count = maxi(clip_count, 1)
		loops = clip_loops
