class_name CharacterVisual
extends Node3D
## Visuel d'un personnage, même interface pour sprite et mesh (PLAN.md sections 3 et 5).
## Propriétaire : L3. Instancié sous le nom « Visual » dans player.tscn, enemy.tscn, npc.tscn.
##
## Squelette du Lot 0 : AnimatedSprite3D billboard (enfant « Sprite ») construit depuis la
## planche du skin (SheetLoader), ancres alignées, pieds à l'origine. L3 ajoute la variante
## mesh, l'ombre, les effets. Animations : repos, marche, course, attaque, charge, degats,
## mort (+ fouet, morsure pour les Timeres). La planche est dessinée tournée vers la droite.

## Émis à chaque changement d'image (y compris l'image 0 au lancement d'une animation).
signal frame_changed(anim: StringName, frame: int)
## Émis à la fin d'une animation non bouclée.
signal animation_finished(anim: StringName)

## Skin affiché (peut être fixé dans une scène ; à l'exécution, utiliser set_skin()).
@export var skin: SkinData:
	set(value):
		skin = value
		if is_node_ready():
			_apply_skin()

var _sheet: Dictionary = {}
var _offset: Vector2 = Vector2.ZERO
var _flipped: bool = false

@onready var _sprite: AnimatedSprite3D = $Sprite


func _ready() -> void:
	_sprite.frame_changed.connect(_on_sprite_frame_changed)
	_sprite.animation_finished.connect(_on_sprite_animation_finished)
	_apply_skin()


func set_skin(new_skin: SkinData) -> void:
	skin = new_skin


## Joue anim ; continue si elle est déjà en cours, sauf restart = true. Sans effet si le skin
## n'a pas cette animation.
func play(anim: StringName, restart: bool = false) -> void:
	if not has_animation(anim):
		return
	if not restart and _sprite.animation == anim and _sprite.is_playing():
		return
	_sprite.play(anim)
	if restart:
		_sprite.frame = 0


## Fige l'animation anim sur l'image frame (ex. charge maintenue).
func show_frame(anim: StringName, frame: int) -> void:
	if not has_animation(anim):
		return
	_sprite.animation = anim
	_sprite.pause()
	_sprite.frame = clampi(frame, 0, _sprite.sprite_frames.get_frame_count(anim) - 1)


## Oriente le sprite : retourné quand direction pointe vers la gauche de l'écran.
func set_facing(direction: Vector3) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d() if is_inside_tree() else null
	var side := direction.x
	if camera != null:
		side = direction.dot(camera.global_basis.x)
	if absf(side) < 0.01:
		return
	_flipped = side < 0.0
	_sprite.flip_h = _flipped
	_sprite.offset = Vector2(-_offset.x if _flipped else _offset.x, _offset.y)


## Images « coup » de anim (lues dans le JSON de la planche, qui fait foi).
func hit_frames(anim: StringName) -> Array[int]:
	return SheetLoader.hit_frames(_sheet, anim)


## Image « onde » de anim (charge), -1 si absente.
func wave_frame(anim: StringName) -> int:
	return SheetLoader.wave_frame(_sheet, anim)


func has_animation(anim: StringName) -> bool:
	return _sprite.sprite_frames != null and _sprite.sprite_frames.has_animation(anim)


func current_animation() -> StringName:
	return _sprite.animation


func _apply_skin() -> void:
	_sheet = SheetLoader.read_sheet(skin)
	if skin == null or skin.sprite_sheet == null:
		_sprite.sprite_frames = null
		return
	_sprite.sprite_frames = SheetLoader.build_frames(skin.sprite_sheet, _sheet)
	_sprite.pixel_size = SheetLoader.pixel_size(skin, _sheet)
	_offset = SheetLoader.anchor_offset(_sheet)
	_sprite.offset = Vector2(-_offset.x if _flipped else _offset.x, _offset.y)
	if has_animation(&"repos"):
		_sprite.play(&"repos")


func _on_sprite_frame_changed() -> void:
	frame_changed.emit(_sprite.animation, _sprite.frame)


func _on_sprite_animation_finished() -> void:
	animation_finished.emit(_sprite.animation)
