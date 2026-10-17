class_name CharacterVisual
extends Node3D
## Visuel d'un personnage en billboard HD-2D (PLAN.md sections 3 et 5). Propriétaire : L3, H6.
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
## (AN) Allure et pas :
## - match_stride (joueur, PNJ) : la cadence de « marche » et de « course » suit la vitesse au sol
##   réelle du nœud (mesurée d'image en image, lissée) : à la vitesse dessinée de la planche
##   (STRIDE_PX : chemin d'un cycle, en pixels de planche, × pixel_size), elle vaut celle du JSON ;
##   deux fois plus vite, deux fois plus de pas. Les pieds ne patinent plus. À l'arrêt, la dernière
##   cadence est gardée (le pas en cours se termine au même rythme) ;
## - avec match_stride, en marche ou en course, un changement de vue (profil, face, dos : l'épée
##   change de côté à l'écran) attend une image de contact (step_frames : début de chaque pas),
##   jamais en plein pas ; un demi-tour de profil se retourne tout de suite ;
## - settle(anim) passe à anim (le repos) à la fin du pas en cours, au lieu de couper la foulée.
## (AN) Le sprite est lu « net mais lissé » (character_sprite.gdshader, comme le décor) : plus de
## scintillement quand la caméra glisse.

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
## (AN) Animations de déplacement et chemin parcouru au sol par un cycle complet (deux pas), en
## pixels de planche : mesuré sur la planche de Chtholly (pas d'environ 42 px ; foulée de course
## d'environ 74 px, envol compris), commun aux planches du même cahier (6 images à 10 i/s, 5 à
## 14 i/s). Chtholly : 0,88 m en 0,6 s (1,46 m/s) et 1,53 m en 0,36 s (4,3 m/s).
const STRIDE_PX: Dictionary[StringName, float] = {&"marche": 84.0, &"course": 147.0}
## (AN) Bornes du rapport de cadence (vitesse réelle / vitesse dessinée).
const MIN_STRIDE_RATE := 0.35
const MAX_STRIDE_RATE := 3.0
## (AN) Sous cette vitesse (m/s), la cadence n'est plus mesurée : la dernière est gardée.
const STRIDE_MIN_SPEED := 0.2
## (AN) Lissage de la vitesse mesurée (s) ; un saut plus rapide que TELEPORT_SPEED m/s
## (téléportation, changement de carte) est ignoré.
const SPEED_SMOOTHING := 0.08
const TELEPORT_SPEED := 30.0
## (AN) Matériau du sprite : planche « nette mais lissée ».
const SPRITE_SHADER := preload("res://src/visuals/character_sprite.gdshader")

## Skin affiché (peut être fixé dans une scène ; à l'exécution, utiliser set_skin()).
@export var skin: SkinData:
	set(value):
		if value == skin and is_node_ready():
			return
		skin = value
		if is_node_ready():
			_apply_skin()
## (AN) La cadence de marche et de course suit la vitesse au sol réelle (joueur, PNJ).
@export var match_stride: bool = false

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
## (R1) Couleur que d'autres donnent au sprite (EnemyData.tint), et la dernière posée avec la
## teinte de la lumière.
var _base_modulate: Color = Color.WHITE
var _lit_modulate: Color = Color.WHITE
## (AN) Rapport de cadence des animations de déplacement, vitesse au sol mesurée (m/s), dernière
## position mesurée, animation qui attend la fin du pas (settle), matériau du sprite et planche
## qu'il lit.
var _stride_rate: float = 1.0
var _ground_speed: float = 0.0
var _last_position: Vector3 = Vector3.INF
var _settle_anim: StringName = &""
var _material: ShaderMaterial
var _material_sheet: Texture2D

@onready var _sprite: AnimatedSprite3D = $Sprite
@onready var _shadow: MeshInstance3D = $Shadow


func _ready() -> void:
	_material = ShaderMaterial.new()
	_material.shader = SPRITE_SHADER
	_sprite.material_override = _material
	_apply_skin()


func _process(delta: float) -> void:
	_measure_speed(delta)
	advance(delta)
	_update_facing()


## (R1) La planche, non éclairée, prend la teinte de la lumière posée par Atmosphere
## (HD2DLighting.active_sprite_tint : la nuit, plus sombre et bleutée ; blanche au couchant),
## par-dessus la couleur que d'autres lui donnent (EnemyData.tint).
func _apply_light_tint() -> void:
	if _sprite == null:
		return
	if _sprite.modulate != _lit_modulate:
		_base_modulate = _sprite.modulate
	var tint := HD2DLighting.active_sprite_tint()
	_lit_modulate = _base_modulate * Color(tint.r, tint.g, tint.b)
	if _sprite.modulate != _lit_modulate:
		_sprite.modulate = _lit_modulate


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
	_settle_anim = &""
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
	_settle_anim = &""
	_generation += 1
	_playing = false
	_finished = false
	_step = index
	_time = index / clip.fps
	_show(anim, index)
	if changed:
		frame_changed.emit(anim, index)


## (AN) Passe à anim (le repos) à la fin du pas en cours : tout de suite si l'animation courante
## n'est pas une marche ou une course qui avance (is_stepping), ou si elle montre déjà une image de
## contact (step_frames) ; sinon à la prochaine. Un play() ou un show_frame() entre-temps l'annule.
func settle(anim: StringName = IDLE) -> void:
	if not has_animation(anim):
		return
	if anim == _anim or not is_stepping() or _frame in step_frames(_anim):
		play(anim)
		return
	_settle_anim = anim


## (AN) Animation qui attend la fin du pas (settle), &"" si aucune.
func settling_to() -> StringName:
	return _settle_anim


## (AN) Vrai pendant une marche ou une course qui avance (STRIDE_PX).
func is_stepping() -> bool:
	return _playing and STRIDE_PX.has(_anim) and _clips.has(_anim)


## (AN) Images de contact d'une animation : le début de chacun de ses deux pas (0 et la moitié du
## cycle arrondie au-dessus : 0 et 3 pour 6 ou 5 images).
func step_frames(anim: StringName) -> Array[int]:
	if not _clips.has(anim):
		return [0]
	var clip: Clip = _clips[anim]
	if clip.count <= 2:
		return [0]
	return [0, ceili(clip.count / 2.0)]


## (AN) Rapport de cadence des animations de déplacement (1 : celle du JSON).
func stride_rate() -> float:
	return _stride_rate


## (AN) Vitesse au sol mesurée (m/s, lissée).
func ground_speed() -> float:
	return _ground_speed


## (AN) Vitesse au sol (m/s) à laquelle anim garde la cadence du JSON (STRIDE_PX × pixel_size ×
## cycles par seconde) ; 0 si anim n'est pas une animation de déplacement de la planche.
func drawn_speed(anim: StringName) -> float:
	if not STRIDE_PX.has(anim) or not _clips.has(anim):
		return 0.0
	var clip: Clip = _clips[anim]
	return STRIDE_PX[anim] * _side_pixel_size() * clip.fps / clip.count


## (AN) Pose la vitesse au sol (m/s) et la cadence qui en découle sans attendre la mesure (tests,
## démonstrations) ; la mesure d'image en image reprend ensuite.
func set_ground_speed(speed: float) -> void:
	_ground_speed = maxf(speed, 0.0)
	_update_stride_rate()


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
## (un tour au plus pour une boucle). (R1) Pose aussi la teinte de la lumière (_apply_light_tint).
func advance(delta: float) -> void:
	_apply_light_tint()
	if not _playing or not _clips.has(_anim):
		return
	var clip: Clip = _clips[_anim]
	_time += delta * (_stride_rate if match_stride and STRIDE_PX.has(_anim) else 1.0)
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
		if _settle_anim != &"" and _frame in step_frames(_anim):
			play(_settle_anim)
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
		_sync_material()


## (AN) Le matériau lit la planche de l'image affichée (une AtlasTexture de la planche principale
## ou de la planche complémentaire ; une image simple se lit telle quelle).
func _sync_material() -> void:
	if _material == null or not _sprite.sprite_frames.has_animation(_anim):
		return
	var image := _sprite.sprite_frames.get_frame_texture(_anim, _frame)
	var atlas := image as AtlasTexture
	var sheet: Texture2D = atlas.atlas if atlas != null else image
	if sheet != _material_sheet:
		_material_sheet = sheet
		_material.set_shader_parameter(&"sheet", sheet)


## (AN) Mesure la vitesse au sol du nœud (déplacement horizontal depuis l'image précédente,
## lissé) et en tire la cadence des animations de déplacement (match_stride).
func _measure_speed(delta: float) -> void:
	if not match_stride or delta <= 0.0 or not is_inside_tree():
		return
	var here := global_position
	if _last_position != Vector3.INF:
		var step := Vector2(here.x - _last_position.x, here.z - _last_position.z).length() / delta
		if step <= TELEPORT_SPEED:
			_ground_speed = lerpf(_ground_speed, step, 1.0 - exp(-delta / SPEED_SMOOTHING))
	_last_position = here
	_update_stride_rate()


## (AN) Rapport de cadence de l'animation de déplacement courante (ou de la marche) pour la
## vitesse au sol ; sous STRIDE_MIN_SPEED, le dernier est gardé (le pas en cours se termine).
func _update_stride_rate() -> void:
	if _ground_speed < STRIDE_MIN_SPEED:
		return
	var drawn := drawn_speed(_anim if STRIDE_PX.has(_anim) else &"marche")
	if drawn > 0.0:
		_stride_rate = clampf(_ground_speed / drawn, MIN_STRIDE_RATE, MAX_STRIDE_RATE)


## (AN) Taille d'un pixel de planche du profil (celle de la planche qui donne STRIDE_PX).
func _side_pixel_size() -> float:
	var entry: Array = _views.get(SheetLoader.SIDE, [])
	return float(entry[1]) if entry.size() > 1 else _sprite.pixel_size


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
	# (AN) En marche ou en course (match_stride), la vue, et le côté de l'épée avec elle, ne change
	# qu'au début d'un pas.
	var mid_step := match_stride and is_stepping() and not (_frame in step_frames(_anim))
	if view != _view and not mid_step:
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
