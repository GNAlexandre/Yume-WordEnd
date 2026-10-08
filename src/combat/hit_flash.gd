class_name HitFlash
extends AnimatedSprite3D
## Éclair d'un combattant touché (lot H7) : pendant flash(), ce sprite recopie à chaque image ce
## qu'affiche le sprite source (le « Sprite » d'un CharacterVisual : animation, image, ancre,
## retournement, taille de pixel) et le peint d'une couleur claire (hit_flash.gdshader), un peu
## devant lui. Le modulate d'un sprite ne peut que foncer une image : d'où cette silhouette.
## Ne dépend que du contrat de CharacterVisual (nœud « Sprite », AnimatedSprite3D) : quel que
## soit le dessin ou la vue de la planche, l'éclair en prend la forme. Il se place lui-même sur
## le sprite (position et échelle globales) : son parent importe peu.

const FLASH_SHADER := preload("res://src/combat/hit_flash.gdshader")

## Couleur de l'éclair.
@export var flash_color: Color = Color(1.0, 0.96, 0.88)
## Part de la couleur au début de l'éclair (1 : silhouette pleine) ; elle décroît ensuite.
@export_range(0.0, 1.0) var max_strength: float = 0.85

var _source: AnimatedSprite3D
var _left: float = 0.0
var _duration: float = 0.0
var _sheet: Texture2D
var _material: ShaderMaterial


func _ready() -> void:
	visible = false
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_material = ShaderMaterial.new()
	_material.shader = FLASH_SHADER
	_material.set_shader_parameter(&"flash_color", flash_color)
	material_override = _material


## Sprite dont l'éclair prend la forme. L'éclair suit chaque changement d'image ou d'animation
## de la source dès qu'il a lieu (un Timere touché passe à « degats » juste après l'éclair).
func bind(source: AnimatedSprite3D) -> void:
	if is_instance_valid(_source):
		for source_signal: Signal in [_source.frame_changed, _source.animation_changed]:
			if source_signal.is_connected(_on_source_changed):
				source_signal.disconnect(_on_source_changed)
	_source = source
	if is_instance_valid(_source):
		_source.frame_changed.connect(_on_source_changed)
		_source.animation_changed.connect(_on_source_changed)


## Éclair pendant duration s (le plus long l'emporte s'il y en a déjà un).
func flash(duration: float) -> void:
	if duration <= 0.0 or not is_instance_valid(_source):
		return
	_left = maxf(_left, duration)
	_duration = maxf(_duration, duration) if visible else duration
	if _sync():
		_material.set_shader_parameter(&"flash_color", flash_color)
		_material.set_shader_parameter(&"strength", max_strength)
		visible = true


## true pendant un éclair.
func is_flashing() -> bool:
	return visible and _left > 0.0


func _process(delta: float) -> void:
	if not visible:
		return
	_left -= delta
	if _left <= 0.0 or not _sync():
		_left = 0.0
		visible = false
		return
	# Plein au début, puis il rend un peu l'image d'origine (pas de clignotement dur).
	var ratio := clampf(_left / maxf(_duration, 0.001), 0.0, 1.0)
	_material.set_shader_parameter(&"strength", max_strength * (0.6 + 0.4 * ratio))


func _on_source_changed() -> void:
	if visible and not _sync():
		visible = false


## Recopie l'image du sprite source ; false s'il n'affiche rien. Une image de planche est une
## AtlasTexture (SheetLoader) : l'éclair lit la planche entière aux UV de la région ; une image
## simple se lit telle quelle.
func _sync() -> bool:
	if not is_instance_valid(_source) or _source.sprite_frames == null:
		return false
	var anim := _source.animation
	if not _source.sprite_frames.has_animation(anim):
		return false
	var image := _source.sprite_frames.get_frame_texture(anim, _source.frame)
	var atlas := image as AtlasTexture
	var sheet: Texture2D = atlas.atlas if atlas != null else image
	if sheet == null:
		return false
	if sheet != _sheet:
		_sheet = sheet
		_material.set_shader_parameter(&"sheet", sheet)
	if sprite_frames != _source.sprite_frames:
		sprite_frames = _source.sprite_frames
	if animation != anim:
		animation = anim
	frame = _source.frame
	offset = _source.offset
	flip_h = _source.flip_h
	pixel_size = _source.pixel_size
	centered = _source.centered
	global_transform = Transform3D(
		Basis.from_scale(_source.global_basis.get_scale()), _source.global_position
	)
	return true
