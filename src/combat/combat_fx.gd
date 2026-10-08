class_name CombatFx
extends RefCounted
## Effets de combat en HD-2D (lot H7) : sprites en pixel art à 96 px/m (src/combat/fx/, images de
## remplacement de make_fx.py), décalcomanies posées au sol, éclats d'impact, poussière, images
## rémanentes, ombre nette des combattants et arrêt sur image. Rien ne dépend du dessin des
## planches, seulement de leurs animations, images « coup » et hauteur. Aucun chiffre de combat
## ici : durée de la préparation, de l'arrêt sur image et force de la secousse viennent de
## data/attacks (AttackData.windup, hitstop, shake) et data/enemies (EnemyData.windup_scale,
## strike_shake).
##
## La caméra est fixe (elle regarde le nord) : un sprite debout se tourne vers elle (billboard),
## une décalcomanie se lit au sol à la place exacte de ce qu'elle montre (portée d'un coup, zone
## d'une morsure, couloir d'une charge). Les éclats passent devant leur cible (sans test de
## profondeur), tout le reste garde la profondeur du monde.

const FX_DIR := "res://src/combat/fx/"
## Mètres par pixel d'image (96 px/m, comme tout le monde HD-2D).
const PIXEL_SIZE := 1.0 / 96.0
## Bandes d'images : nom → [largeur d'une image (px), cadence (ips), boucle].
const STRIPS := {
	"glint": [32, 18.0, false],
	"impact": [48, 30.0, false],
	"bite": [48, 24.0, false],
	"whip": [64, 24.0, false],
	"dust": [32, 16.0, false],
	"slash": [240, 0.0, false],
	"wave": [192, 12.0, true],
}
## Teintes des éclats (les images d'impact, de crocs et de poussière sont blanches ou grises).
const COLOR_SWORD := Color(1.0, 0.93, 0.72)
const COLOR_SWORD_FINAL := Color(1.0, 0.82, 0.48)
const COLOR_WAVE := Color(0.72, 0.9, 1.0)
const COLOR_BITE := Color(1.0, 0.62, 0.48)
const COLOR_DUST := Color(0.92, 0.84, 0.7)
## Hauteur des décalcomanies au-dessus des pieds (m) : au-dessus de l'ombre du Visual (0,02 m).
const GROUND_LIFT := 0.035
## Métadonnée d'un nœud figé par freeze() : [process_mode d'origine, gels en cours].
const FREEZE_META := &"combat_fx_freeze"
## Image de l'ombre nette des combattants, et sa hauteur (m) : entre l'ombre douce du Visual
## (0,02 m) et les décalcomanies des coups.
const SHADOW_FX := "shadow"
const SHADOW_LIFT := 0.028

static var _textures: Dictionary = {}
static var _frames: Dictionary = {}
static var _materials: Dictionary = {}
static var _planes: Dictionary = {}


## Image src/combat/fx/<fx_name>.png (null si absente).
static func texture(fx_name: String) -> Texture2D:
	if not _textures.has(fx_name):
		var path := FX_DIR + fx_name + ".png"
		_textures[fx_name] = load(path) as Texture2D if ResourceLoader.exists(path) else null
	return _textures[fx_name]


## Nombre d'images de la bande fx_name (1 pour une image simple).
static func frame_count(fx_name: String) -> int:
	var image := texture(fx_name)
	if image == null or not STRIPS.has(fx_name):
		return 1
	return maxi(1, floori(float(image.get_width()) / float(STRIPS[fx_name][0])))


## SpriteFrames de la bande fx_name (animation « default »), partagé par tous les effets.
static func sprite_frames(fx_name: String) -> SpriteFrames:
	if _frames.has(fx_name):
		return _frames[fx_name]
	var frames := SpriteFrames.new()
	var image := texture(fx_name)
	var info: Array = STRIPS.get(fx_name, [0, 12.0, false])
	frames.set_animation_speed(&"default", float(info[1]) if float(info[1]) > 0.0 else 12.0)
	frames.set_animation_loop(&"default", bool(info[2]))
	if image != null:
		var count := frame_count(fx_name)
		var width := floori(float(image.get_width()) / count)
		for i in count:
			var atlas := AtlasTexture.new()
			atlas.atlas = image
			atlas.region = Rect2(i * width, 0, width, image.get_height())
			frames.add_frame(&"default", atlas)
	_frames[fx_name] = frames
	return frames


## Plan horizontal de size m (x, z), le haut de l'image vers −Z (devant).
static func ground_plane(size: Vector2) -> PlaneMesh:
	var key := "%.3f|%.3f" % [size.x, size.y]
	if not _planes.has(key):
		var plane := PlaneMesh.new()
		plane.size = size
		_planes[key] = plane
	return _planes[key]


## Matériau d'une décalcomanie (non éclairée, mélangée, pixels nets, deux faces) ; frame choisit
## une image d'une bande (-1 : l'image entière) ; on_top la dessine par-dessus les sprites (sans
## test de profondeur : un trait que le corps qui s'y tient ne doit pas cacher). Partagé : pour
## faire varier l'opacité d'une seule décalcomanie, utiliser ground_material_unique().
static func ground_material(
	fx_name: String, color: Color = Color.WHITE, frame: int = -1, on_top: bool = false
) -> StandardMaterial3D:
	var key := "%s|%s|%d|%s" % [fx_name, color.to_html(), frame, on_top]
	if not _materials.has(key):
		_materials[key] = ground_material_unique(fx_name, color, frame, on_top)
	return _materials[key]


## Comme ground_material(), mais neuf (albedo_color propre à une décalcomanie qui s'estompe).
static func ground_material_unique(
	fx_name: String, color: Color = Color.WHITE, frame: int = -1, on_top: bool = false
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	if on_top:
		material.no_depth_test = true
		material.render_priority = 2
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_texture = texture(fx_name)
	material.albedo_color = color
	var count := frame_count(fx_name)
	if frame >= 0 and count > 1:
		material.uv1_scale = Vector3(1.0 / count, 1.0, 1.0)
		material.uv1_offset = Vector3(float(clampi(frame, 0, count - 1)) / count, 0.0, 0.0)
	return material


## Décalcomanie au sol : MeshInstance3D plat de size m, sans ombre portée, à GROUND_LIFT.
static func make_decal(
	fx_name: String, size: Vector2, color: Color = Color.WHITE, node_name: String = ""
) -> MeshInstance3D:
	var decal := MeshInstance3D.new()
	if not node_name.is_empty():
		decal.name = node_name
	decal.mesh = ground_plane(size)
	decal.material_override = ground_material(fx_name, color)
	decal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	decal.position = Vector3.UP * GROUND_LIFT
	return decal


## Sprite debout d'une bande d'effets, tourné vers la caméra, à 96 px/m × size.
static func make_sprite(fx_name: String, size: float = 1.0) -> AnimatedSprite3D:
	var sprite := AnimatedSprite3D.new()
	sprite.sprite_frames = sprite_frames(fx_name)
	sprite.pixel_size = PIXEL_SIZE * size
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.shaded = false
	sprite.double_sided = true
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return sprite


## Éclat joué une fois au point global at, puis libéré : fx_name ∈ impact, bite, whip, dust, glint.
## Ajouté au parent de near (il reste sur place si near bouge) ; devant tout (sans test de
## profondeur) sauf la poussière, posée au sol.
static func spawn_burst(
	near: Node,
	fx_name: String,
	at: Vector3,
	color: Color = Color.WHITE,
	size: float = 1.0,
	flip: bool = false
) -> AnimatedSprite3D:
	var host := host_for(near)
	if host == null:
		return null
	var sprite := make_sprite(fx_name, size)
	sprite.name = "Fx_%s" % fx_name
	sprite.modulate = color
	sprite.flip_h = flip
	if fx_name != "dust":
		sprite.no_depth_test = true
		sprite.render_priority = 2
	host.add_child(sprite)
	sprite.global_position = at
	sprite.animation_finished.connect(sprite.queue_free)
	sprite.play(&"default")
	return sprite


## Image rémanente de source (le sprite d'un CharacterVisual) : copie translucide de l'image
## affichée, qui s'estompe en fade s (élan du Timere bondissant).
static func spawn_ghost(source: AnimatedSprite3D, color: Color, fade: float = 0.18) -> Sprite3D:
	if source == null or source.sprite_frames == null or not source.is_inside_tree():
		return null
	var host := host_for(source.get_parent().get_parent() if source.get_parent() else source)
	var image := source.sprite_frames.get_frame_texture(source.animation, source.frame)
	if host == null or image == null:
		return null
	var ghost := Sprite3D.new()
	ghost.name = "Fx_ghost"
	ghost.texture = image
	ghost.centered = source.centered
	ghost.offset = source.offset
	ghost.flip_h = source.flip_h
	ghost.pixel_size = source.pixel_size
	ghost.billboard = source.billboard
	ghost.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	ghost.shaded = false
	ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ghost.modulate = color
	host.add_child(ghost)
	ghost.global_transform = Transform3D(
		Basis.from_scale(source.global_basis.get_scale()), source.global_position
	)
	var tween := ghost.create_tween()
	tween.tween_property(ghost, ^"modulate:a", 0.0, fade)
	tween.tween_callback(ghost.queue_free)
	return ghost


## Parent où poser un effet qui ne suit pas near : la zone (Zone) qui contient near, sinon le
## parent de near. Jamais le conteneur des ennemis (Enemies, Spawned) : d'autres systèmes et les
## tests en parcourent les enfants.
static func host_for(near: Node) -> Node:
	if near == null or not near.is_inside_tree():
		return null
	var node := near.get_parent()
	while node != null:
		if node is Zone:
			return node
		node = node.get_parent()
	return near.get_parent()


## Arrêt sur image : node (et ses enfants) ne sont plus traités pendant seconds s de jeu
## (temps physique, suspendu par la pause), puis reprennent où ils en étaient. Pour un
## CharacterVisual : l'animation se fige (les images « coup » suivantes arrivent d'autant plus
## tard). Les gels qui se chevauchent se cumulent ; le mode d'origine est rétabli au dernier.
static func freeze(node: Node, seconds: float) -> void:
	if node == null or seconds <= 0.0 or not node.is_inside_tree():
		return
	if not node.has_meta(FREEZE_META):
		node.set_meta(FREEZE_META, [node.process_mode, 0])
	var state: Array = node.get_meta(FREEZE_META)
	state[1] = int(state[1]) + 1
	node.process_mode = Node.PROCESS_MODE_DISABLED
	var ref: WeakRef = weakref(node)
	var timer := node.get_tree().create_timer(seconds, false, true)
	timer.timeout.connect(func() -> void: thaw(ref.get_ref() as Node))


## Fin d'un gel de freeze() (appelé par son minuteur).
static func thaw(node: Node) -> void:
	if node == null or not node.has_meta(FREEZE_META):
		return
	var state: Array = node.get_meta(FREEZE_META)
	state[1] = int(state[1]) - 1
	if int(state[1]) <= 0:
		node.process_mode = state[0]
		node.remove_meta(FREEZE_META)


## true si node est figé par freeze().
static func is_frozen(node: Node) -> bool:
	return node != null and node.has_meta(FREEZE_META)


## Ombre nette au sol d'un combattant (« GroundShadow ») : disque de rayon radius m (cœur sombre,
## bord net), indépendant de la planche : sa taille vient du corps (capsule, EnemyData.scale),
## pas du dessin. Elle se pose un peu au-dessus de l'ombre douce du Visual.
static func make_shadow(radius: float) -> MeshInstance3D:
	var diameter := 2.0 * maxf(radius, 0.05)
	var shadow := make_decal(SHADOW_FX, Vector2(diameter, diameter), Color.WHITE, "GroundShadow")
	shadow.position = Vector3.UP * SHADOW_LIFT
	return shadow


## Direction à l'écran (x vers la droite, y vers le haut, unitaire) d'une direction du monde
## vue par camera ; Vector2.ZERO si elle est dans l'axe de la caméra.
static func screen_direction(camera: Camera3D, world: Vector3) -> Vector2:
	if camera == null:
		return Vector2(world.x, -world.z).normalized()
	var basis := camera.global_basis
	var screen := Vector2(world.dot(basis.x), world.dot(basis.y))
	return screen.normalized() if screen.length_squared() > 0.000001 else Vector2.ZERO


## Base d'un sprite debout face à camera, dont le haut de l'image pointe à l'écran vers
## world_direction (une direction du sol) : x le long de l'image, y vers où elle file.
static func facing_basis(camera: Camera3D, world_direction: Vector3) -> Basis:
	if camera == null:
		return Basis.IDENTITY
	var basis := camera.global_basis
	var screen := screen_direction(camera, world_direction)
	if screen == Vector2.ZERO:
		screen = Vector2.UP
	var y_axis := (basis.x * screen.x + basis.y * screen.y).normalized()
	var z_axis := basis.z.normalized()
	return Basis(y_axis.cross(z_axis).normalized(), y_axis, z_axis)


## Longueur à l'écran (m, à la profondeur de l'objet) d'un segment du sol world_segment.
static func screen_length(camera: Camera3D, world_segment: Vector3) -> float:
	if camera == null:
		return world_segment.length()
	var basis := camera.global_basis
	return Vector2(world_segment.dot(basis.x), world_segment.dot(basis.y)).length()
