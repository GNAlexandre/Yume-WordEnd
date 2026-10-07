extends Control
## Fond du menu principal (L10), en HD-2D : le ciel peint du jeu (assets/hd2d/sky/sky.png, la
## part du couchant), deux îles lointaines qui flottent doucement, le soleil qui pulse, des
## feuilles d'automne qui dérivent et les crêtes sombres du bord du Couchant au premier plan.
## Pixels nets (filtrage au plus proche voisin) ; dessiné à chaque image.

const SKY := preload("res://assets/hd2d/sky/sky.png")
const ISLAND_A := preload("res://assets/hd2d/sky/distant_island_a.png")
const ISLAND_B := preload("res://assets/hd2d/sky/distant_island_b.png")
## Part du panorama montrée (fractions de l'image) : le soleil couchant est en u = 0,25.
const SKY_REGION := Rect2(0.1, 0.16, 0.3, 0.46)
const SUN := Color(1.0, 0.875, 0.471)
## Îles lointaines : centre (fraction de l'écran) et largeur (fraction de la hauteur).
const ISLANDS: Array[Vector3] = [Vector3(0.18, 0.3, 0.36), Vector3(0.84, 0.22, 0.26)]
const DUNE_BASES: Array[float] = [0.74, 0.82, 0.91]
const DUNE_AMPLITUDES: Array[float] = [0.035, 0.045, 0.04]
const DUNE_WAVES: Array[float] = [1.2, 0.8, 1.5]
const DUNE_COLORS: Array[Color] = [
	Color(0.459, 0.239, 0.29), Color(0.318, 0.152, 0.214), Color(0.18, 0.09, 0.15)
]
## Feuilles d'automne (or, rouille, jaune : MONDE.md 5.4).
const LEAF_COLORS: Array[Color] = [
	Color(0.8, 0.58, 0.275), Color(0.663, 0.353, 0.227), Color(0.824, 0.706, 0.361)
]
const LEAVES := 16

var _time: float = 0.0


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	texture_filter = TEXTURE_FILTER_NEAREST
	resized.connect(queue_redraw)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var area := size
	var sky_size := Vector2(SKY.get_size())
	var region := Rect2(SKY_REGION.position * sky_size, SKY_REGION.size * sky_size)
	# Le panorama couvre l'écran en gardant ses proportions (rognée sur les côtés si besoin).
	var scale_factor := maxf(area.x / region.size.x, area.y / region.size.y)
	var shown := area / scale_factor
	region = Rect2(region.get_center() - shown / 2.0, shown)
	draw_texture_rect_region(SKY, Rect2(Vector2.ZERO, area), region)
	var sun_center := (Vector2(0.25, 0.47) * sky_size - region.position) * scale_factor
	var pulse := 1.0 + 0.05 * sin(_time * 1.6)
	for k in 3:
		draw_circle(sun_center, area.y * (0.1 + 0.05 * k) * pulse, Color(SUN, 0.07))
	_draw_island(area, ISLAND_A, ISLANDS[0])
	_draw_island(area, ISLAND_B, ISLANDS[1])
	for layer in DUNE_BASES.size():
		_draw_dune(area, layer)
	for k in LEAVES:
		_draw_leaf(area, k)


## Île lointaine qui flotte doucement.
func _draw_island(area: Vector2, texture: Texture2D, island: Vector3) -> void:
	var width := island.z * area.y
	var height := width * texture.get_height() / float(texture.get_width())
	var center := Vector2(island.x * area.x, island.y * area.y + 4.0 * sin(_time + island.x * 9.0))
	draw_texture_rect(
		texture, Rect2(center - Vector2(width, height) / 2.0, Vector2(width, height)), false
	)


func _draw_dune(area: Vector2, layer: int) -> void:
	var points := PackedVector2Array()
	var steps := 32
	for s in steps + 1:
		var t := float(s) / steps
		var wave := sin(TAU * DUNE_WAVES[layer] * t + layer * 1.7)
		points.append(
			Vector2(area.x * t, area.y * (DUNE_BASES[layer] + DUNE_AMPLITUDES[layer] * wave))
		)
	points.append(Vector2(area.x, area.y))
	points.append(Vector2(0, area.y))
	draw_colored_polygon(points, DUNE_COLORS[layer])


## Feuille d'automne portée par le vent d'ouest (positions pseudo-aléatoires fixes par feuille).
func _draw_leaf(area: Vector2, k: int) -> void:
	var seed_x := fposmod(sin(k * 12.9898) * 43758.547, 1.0)
	var seed_y := fposmod(sin(k * 78.233) * 24634.635, 1.0)
	var speed := 0.025 + 0.02 * seed_y
	var at := Vector2(
		fposmod(seed_x + _time * speed, 1.0) * area.x,
		fposmod(seed_y + _time * speed * 0.5, 1.0) * area.y * 0.85
	)
	var side := 4.0 + 3.0 * seed_x
	draw_set_transform(at.floor(), _time * 1.2 + k, Vector2.ONE)
	draw_rect(Rect2(-side, -side * 0.5, side * 2.0, side), LEAF_COLORS[k % LEAF_COLORS.size()])
	draw_set_transform_matrix(Transform2D.IDENTITY)
