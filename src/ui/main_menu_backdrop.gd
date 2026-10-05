extends Control
## Fond du menu principal (L10) : couchant sur les dunes aux couleurs de l'écran de chargement
## (L9) et du décor de l'easter egg, îles flottantes au loin, soleil qui pulse, pétales qui
## dérivent. Dessiné à chaque image, sans texture.

const SKY_HEIGHTS: Array[float] = [0.0, 0.32, 0.5, 0.62, 0.72]
const SKY_COLORS: Array[Color] = [
	Color(0.161, 0.129, 0.31),
	Color(0.431, 0.184, 0.341),
	Color(0.769, 0.278, 0.247),
	Color(0.953, 0.533, 0.235),
	Color(0.996, 0.808, 0.333),
]
const SUN := Color(1.0, 0.875, 0.471)
const ISLAND := Color(0.29, 0.13, 0.27, 0.55)
## Îles flottantes : centre (fraction de l'écran) et demi-largeur (fraction de la hauteur).
const ISLANDS: Array[Vector3] = [Vector3(0.2, 0.3, 0.09), Vector3(0.83, 0.22, 0.06)]
const DUNE_BASES: Array[float] = [0.7, 0.8, 0.9]
const DUNE_AMPLITUDES: Array[float] = [0.035, 0.045, 0.04]
const DUNE_WAVES: Array[float] = [1.2, 0.8, 1.5]
const DUNE_COLORS: Array[Color] = [
	Color(0.659, 0.239, 0.169), Color(0.518, 0.122, 0.114), Color(0.29, 0.059, 0.071)
]
const PETAL := Color(0.953, 0.651, 0.784, 0.8)
const PETALS := 14

var _time: float = 0.0


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var area := size
	for i in SKY_HEIGHTS.size() - 1:
		var top := SKY_HEIGHTS[i] * area.y
		var bottom := SKY_HEIGHTS[i + 1] * area.y
		draw_polygon(
			PackedVector2Array(
				[Vector2(0, top), Vector2(area.x, top), Vector2(area.x, bottom), Vector2(0, bottom)]
			),
			PackedColorArray([SKY_COLORS[i], SKY_COLORS[i], SKY_COLORS[i + 1], SKY_COLORS[i + 1]])
		)
	draw_rect(Rect2(0, SKY_HEIGHTS[-1] * area.y, area.x, area.y), SKY_COLORS[-1])
	var sun_center := Vector2(area.x * 0.5, area.y * 0.68)
	var sun_radius := area.y * 0.12
	var pulse := 1.0 + 0.04 * sin(_time * 1.6)
	for k in 4:
		draw_circle(sun_center, sun_radius * (1.5 + 0.45 * k) * pulse, Color(SUN, 0.08))
	draw_circle(sun_center, sun_radius, SUN)
	for island: Vector3 in ISLANDS:
		_draw_island(area, island)
	for layer in DUNE_BASES.size():
		_draw_dune(area, layer)
	for k in PETALS:
		_draw_petal(area, k)


## Île flottante (clin d'œil aux îles de SukaSuka) : roche irrégulière sous un plateau herbeux,
## deux arbres ronds et une maison ; elle flotte doucement.
func _draw_island(area: Vector2, island: Vector3) -> void:
	var half := island.z * area.y
	var center := Vector2(island.x * area.x, island.y * area.y + 4.0 * sin(_time + island.x * 9.0))
	var rock := PackedVector2Array()
	for p: Vector2 in [
		Vector2(-1.0, 0.0),
		Vector2(1.0, 0.0),
		Vector2(0.86, 0.3),
		Vector2(0.62, 0.38),
		Vector2(0.48, 0.72),
		Vector2(0.22, 0.8),
		Vector2(0.08, 1.25),
		Vector2(-0.14, 0.86),
		Vector2(-0.42, 0.74),
		Vector2(-0.6, 0.42),
		Vector2(-0.88, 0.3)
	]:
		rock.append(center + p * half)
	draw_colored_polygon(rock, ISLAND)
	draw_set_transform(center, 0.0, Vector2(1.0, 0.22))
	draw_circle(Vector2.ZERO, half * 1.04, ISLAND)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	for tree: Vector3 in [Vector3(-0.62, 0.3, 0.24), Vector3(-0.3, 0.42, 0.3)]:
		var foot := center + Vector2(tree.x, -0.08) * half
		draw_line(foot, foot - Vector2(0, tree.y * half), ISLAND, maxf(half * 0.07, 1.0))
		draw_circle(foot - Vector2(0, tree.y * half), tree.z * half, ISLAND)
	var house := center + Vector2(0.25, -0.34) * half
	draw_rect(Rect2(house, Vector2(0.4, 0.3) * half), ISLAND)
	draw_colored_polygon(
		PackedVector2Array(
			[
				house + Vector2(-0.06, 0) * half,
				house + Vector2(0.46, 0) * half,
				house + Vector2(0.2, -0.24) * half
			]
		),
		ISLAND
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


## Pétales de sakura (positions pseudo-aléatoires fixes par pétale).
func _draw_petal(area: Vector2, k: int) -> void:
	var seed_x := fposmod(sin(k * 12.9898) * 43758.547, 1.0)
	var seed_y := fposmod(sin(k * 78.233) * 24634.635, 1.0)
	var speed := 0.02 + 0.02 * seed_y
	var at := Vector2(
		fposmod(seed_x + _time * speed, 1.0) * area.x,
		fposmod(seed_y + _time * speed * 0.7, 1.0) * area.y * 0.85
	)
	draw_set_transform(at, _time * 0.9 + k, Vector2(1.0, 0.55))
	draw_circle(Vector2.ZERO, 5.0 + 3.0 * seed_x, PETAL)
	draw_set_transform_matrix(Transform2D.IDENTITY)
