class_name TravelView
extends CanvasLayer
## Scène de voyage en dirigeable (lot X1) : ce que voit le joueur entre deux îles, pendant que
## WorldManager.travel() charge la carte d'arrivée sous elle. Posée par WorldManager à la racine
## de l'arbre (au-dessus de l'interface et de UI/MapFade), puis libérée.
##
## Tout est fait d'images du jeu, sans texte ni image propres : le ciel du moment de la journée
## (le préréglage de lumière de GameState.moment, son ciel peint), la ligne des îles à l'horizon,
## une île lointaine qui passe, la mer de nuages qui défile, des nuages au premier plan et le
## dirigeable de la ligne (assets/hd2d/props/airship_ferry.png) qui tangue doucement. Le texte
## « En route vers … » vient de data/texts/story.json (travel/caption, {island} : le nom de
## l'île d'arrivée).
##
## begin() lève le noir (fondu de fade_time s) ; close(durée) attend que la vue ait duré au moins
## ce temps, puis redescend au noir : WorldManager pose alors la carte d'arrivée et lève son
## propre fondu. Un seul draw par couche d'image ; la 3D n'est pas dessinée dessous
## (Viewport.disable_3d, WorldManager).

## Le voyage montré est fini (écran de nouveau noir).
signal closed

## Couche du CanvasLayer : au-dessus de l'interface (UI, MapFade).
const LAYER := 90
const SKY_FALLBACK := preload("res://assets/hd2d/sky/sky_day.png")
const HORIZON_IMAGE := preload("res://assets/hd2d/sky/horizon_islands.png")
const CLOUD_SEA_IMAGE := preload("res://assets/hd2d/sky/cloud_sea.png")
const CLOUD_SEA_NIGHT_IMAGE := preload("res://assets/hd2d/sky/cloud_sea_night.png")
const SHIP_IMAGE := preload("res://assets/hd2d/props/airship_ferry.png")
const ISLAND_IMAGES: Array[Texture2D] = [
	preload("res://assets/hd2d/sky/distant_island_a.png"),
	preload("res://assets/hd2d/sky/distant_island_c.png"),
	preload("res://assets/hd2d/sky/distant_island_e.png"),
]
const CLOUD_IMAGES: Array[Texture2D] = [
	preload("res://assets/hd2d/sky/cloud_a.png"),
	preload("res://assets/hd2d/sky/cloud_d.png"),
	preload("res://assets/hd2d/sky/cloud_b.png"),
]
## Vitesse de défilement de la mer de nuages (px/s, à 720 px de haut) ; les autres couches en
## prennent une part (parallaxe).
const SCROLL_SPEED := 140.0
const SKY_PARALLAX := 0.08
const HORIZON_PARALLAX := 0.18
const ISLAND_PARALLAX := 0.32
const CLOUD_PARALLAX := 1.9
## Haut de la mer de nuages (part de la hauteur de l'écran) et taille de sa première bande.
const SEA_TOP := 0.6
const SEA_ZOOM := 0.42
const SEA_FADE := 0.12
## Hauteur de référence de l'écran (project.godot : 1280 × 720).
const REFERENCE_HEIGHT := 720.0
## Clé du texte affiché (data/texts/story.json).
const CAPTION_KEY := "travel/caption"

## Durée de chaque fondu (s).
var fade_time: float = 0.35
## Île d'arrivée (son id) et texte affiché.
var island_id: StringName = &""
var caption: String = ""

var _elapsed: float = 0.0
var _black_alpha: float = 1.0
var _sky: Texture2D = SKY_FALLBACK
var _clouds: Texture2D = CLOUD_SEA_IMAGE
var _cloud_tint: Color = Color.WHITE
var _sky_tint: Color = Color.WHITE

@onready var _view: Control = %View
@onready var _caption: Label = %Caption
@onready var _black: ColorRect = %Black


func _ready() -> void:
	layer = LAYER
	_view.draw.connect(_draw_view)
	_pick_sky()
	_apply_black()


func _process(delta: float) -> void:
	_elapsed += delta
	_view.queue_redraw()


## Ouvre la vue pour un voyage vers island : texte, ciel du moment, fondu qui lève le noir.
func begin(island: StringName, fade: float = 0.35) -> void:
	island_id = island
	fade_time = fade
	var name_text := WorldAtlas.island_name(island)
	caption = DialogueRunner.story_text(CAPTION_KEY, "{island}").replace("{island}", name_text)
	if is_node_ready():
		_caption.text = caption
	await _fade_black(0.0)


## Attend que la vue ait duré au moins min_seconds, puis redescend au noir et émet closed.
func close(min_seconds: float) -> void:
	while _elapsed < min_seconds and is_inside_tree():
		await get_tree().process_frame
	await _fade_black(1.0)
	closed.emit()


## Temps écoulé depuis l'ouverture (s).
func elapsed() -> float:
	return _elapsed


## Opacité du noir par-dessus la vue (0..1).
func black_alpha() -> float:
	return _black_alpha


func _fade_black(target: float) -> void:
	if fade_time <= 0.0 or not is_inside_tree():
		_black_alpha = target
		_apply_black()
		if is_inside_tree():
			await get_tree().process_frame
		return
	var tween := create_tween()
	tween.tween_method(_set_black, _black_alpha, target, fade_time * absf(target - _black_alpha))
	await tween.finished


func _set_black(value: float) -> void:
	_black_alpha = value
	_apply_black()


func _apply_black() -> void:
	if _black != null:
		_black.color.a = clampf(_black_alpha, 0.0, 1.0)
		_black.visible = _black_alpha > 0.0
	if _caption != null and _caption.text != caption:
		_caption.text = caption


## Ciel et mer de nuages du moment de la journée (son préréglage de lumière).
func _pick_sky() -> void:
	var lighting := HD2DLighting.preset(GameState.moment)
	if lighting == null:
		return
	_sky = lighting.sky_image()
	_sky_tint = lighting.sky_tint
	_cloud_tint = lighting.clouds_tint
	if lighting.uses_night_images():
		_clouds = CLOUD_SEA_NIGHT_IMAGE


func _draw_view() -> void:
	var size := _view.size
	var unit := size.y / REFERENCE_HEIGHT
	var travel := _elapsed * SCROLL_SPEED * unit
	# Le ciel peint, de toute la hauteur, qui glisse à peine.
	var sky_scale := size.y / float(_sky.get_height())
	_draw_strip(_sky, 0.0, sky_scale, travel * SKY_PARALLAX, _sky_tint)
	# La ligne des îles à l'horizon, puis une île plus proche qui passe de temps en temps.
	var horizon_scale := 0.55 * unit
	var horizon_y := size.y * 0.47 - HORIZON_IMAGE.get_height() * horizon_scale
	_draw_strip(
		HORIZON_IMAGE,
		horizon_y,
		horizon_scale,
		travel * HORIZON_PARALLAX,
		Color(0.86, 0.9, 1.0, 0.75)
	)
	_draw_passing(
		ISLAND_IMAGES,
		size.y * 0.2,
		0.42 * unit,
		travel * ISLAND_PARALLAX,
		1.6,
		Color(0.9, 0.93, 1.0, 0.9)
	)
	# La mer de nuages au premier plan, qui défile plus vite que tout le reste ; son bord haut se
	# fond dans celle, lointaine, du ciel peint (dégradé d'opacité par sommet).
	_draw_sea(size.y * SEA_TOP, SEA_ZOOM * unit, travel)
	# Le dirigeable, qui tangue.
	var ship_scale := 0.42 * unit
	var ship_size := Vector2(SHIP_IMAGE.get_size()) * ship_scale
	var bob := sin(_elapsed * 1.4) * 7.0 * unit
	var pitch := deg_to_rad(sin(_elapsed * 0.9) * 1.4)
	var center := Vector2(size.x * 0.46, size.y * 0.43 + bob)
	_view.draw_set_transform(center, pitch, Vector2.ONE)
	_view.draw_texture_rect(SHIP_IMAGE, Rect2(-ship_size * 0.5, ship_size), false)
	_view.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Des nuages au premier plan, plus vite que tout.
	_draw_passing(
		CLOUD_IMAGES,
		size.y * 0.66,
		0.9 * unit,
		travel * CLOUD_PARALLAX,
		0.8,
		Color(1, 1, 1, 0.85) * _cloud_tint
	)


## La mer de nuages de top jusqu'en bas de l'écran, carreaux de zoom, décalée de shift px : un
## polygone aux UV répétés (View : texture_repeat), transparent en haut sur SEA_FADE de hauteur.
func _draw_sea(top: float, zoom: float, shift: float) -> void:
	var size := _view.size
	var tile := Vector2(_clouds.get_size()) * zoom
	var fade := size.y * SEA_FADE
	var rows: Array[float] = [top, top + fade, size.y]
	var alphas: Array[float] = [0.0, 1.0, 1.0]
	for band in 2:
		var y0 := rows[band]
		var y1 := rows[band + 1]
		var points := PackedVector2Array(
			[Vector2(0, y0), Vector2(size.x, y0), Vector2(size.x, y1), Vector2(0, y1)]
		)
		var uvs := PackedVector2Array()
		for point: Vector2 in points:
			uvs.append(Vector2((point.x + shift) / tile.x, (point.y - top) / tile.y))
		var top_color := _cloud_tint * Color(1, 1, 1, alphas[band])
		var bottom_color := _cloud_tint * Color(1, 1, 1, alphas[band + 1])
		var colors := PackedColorArray([top_color, top_color, bottom_color, bottom_color])
		_view.draw_polygon(points, colors, uvs, _clouds)


## Une image répétée en bande horizontale à la hauteur y, décalée de shift px vers la gauche.
func _draw_strip(texture: Texture2D, y: float, zoom: float, shift: float, tint: Color) -> void:
	var width := texture.get_width() * zoom
	var height := texture.get_height() * zoom
	if width <= 1.0:
		return
	var x := -fposmod(shift, width)
	while x < _view.size.x:
		_view.draw_texture_rect(texture, Rect2(x, y, width, height), false, tint)
		x += width


## Des images qui passent de droite à gauche l'une après l'autre, espacées de gap écrans.
func _draw_passing(
	images: Array[Texture2D], y: float, zoom: float, shift: float, gap: float, tint: Color
) -> void:
	var lane := _view.size.x * (1.0 + gap)
	var index := floori(shift / lane)
	for i: int in [index, index + 1]:
		var texture := images[posmod(i, images.size())]
		var size := Vector2(texture.get_size()) * zoom
		var x := _view.size.x + i * lane - shift + (posmod(i * 37, 5) * 0.08) * _view.size.x
		var lift := (posmod(i * 53, 3) - 1) * 0.04 * _view.size.y
		if x + size.x > 0.0 and x < _view.size.x:
			_view.draw_texture_rect(texture, Rect2(Vector2(x, y + lift), size), false, tint)
