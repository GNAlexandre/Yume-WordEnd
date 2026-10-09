extends Control
## Écran de chargement (src/ui/loading.tscn, Lot 9) : couchant sur les dunes (couleurs du décor de
## l'easter egg), barre de progression et message. main.gd lui confie le chargement de
## src/game.tscn et de la carte où commence la partie (load_scenes, E1).
##
## Export Web mono-thread : sans fil d'exécution, ResourceLoader.load_threaded_request() charge la
## ressource entière dans l'appel lui-même (WorkerThreadPool sans fil : la tâche tourne sur le fil
## appelant) et load_threaded_get_status() répond aussitôt THREAD_LOAD_LOADED : aucune progression
## intermédiaire, l'image reste figée pendant le chargement. load_scene() découpe donc le travail
## en plusieurs images (dépendances d'abord) pour que la barre avance vraiment (docs/web.md).

signal progress_changed(ratio: float)
signal finished

const SKY_HEIGHTS: Array[float] = [0.0, 0.34, 0.52, 0.62, 0.7]
const SKY_COLORS: Array[Color] = [
	Color(0.161, 0.129, 0.31),
	Color(0.431, 0.184, 0.341),
	Color(0.769, 0.278, 0.247),
	Color(0.953, 0.533, 0.235),
	Color(0.996, 0.808, 0.333),
]
const DUNE_BASES: Array[float] = [0.69, 0.79, 0.9]
const DUNE_AMPLITUDES: Array[float] = [0.035, 0.045, 0.04]
const DUNE_WAVES: Array[float] = [1.3, 0.9, 1.6]
const DUNE_COLORS: Array[Color] = [
	Color(0.659, 0.239, 0.169), Color(0.518, 0.122, 0.114), Color(0.29, 0.059, 0.071)
]
const SUN := Color(1.0, 0.875, 0.471)
const PETAL := Color(0.953, 0.651, 0.784, 0.75)
const PETALS := 10

## 0 à 1 ; réglable dans l'inspecteur pour prévisualiser la barre.
@export_range(0.0, 1.0) var progress: float = 0.0:
	set = set_progress
## Texte affiché pendant le chargement (le pourcentage s'y ajoute).
@export var message: String = "Chargement de l'île…"

var _finished: bool = false
var _time: float = 0.0

@onready var _backdrop: Control = $Backdrop
@onready var _bar: ProgressBar = $Bar
@onready var _status: Label = $Status


## Dépendances de `path` en profondeur, les feuilles d'abord, sans doublon (ni `path` lui-même).
static func dependency_order(path: String) -> Array[String]:
	var order: Array[String] = []
	_collect_dependencies(path, order, {path: true})
	return order


static func _collect_dependencies(path: String, order: Array[String], seen: Dictionary) -> void:
	for entry: String in ResourceLoader.get_dependencies(path):
		# Forme « uid://…::type::res://… » quand la scène cite ses dépendances par UID.
		var dependency := entry.get_slice("::", 2) if entry.contains("::") else entry
		if dependency.is_empty():
			dependency = entry.get_slice("::", 0)
		if dependency.is_empty() or seen.has(dependency):
			continue
		seen[dependency] = true
		_collect_dependencies(dependency, order, seen)
		order.append(dependency)


func _ready() -> void:
	_backdrop.draw.connect(_draw_backdrop)
	_backdrop.resized.connect(_backdrop.queue_redraw)
	_show_progress()


func _process(delta: float) -> void:
	_time += delta
	_backdrop.queue_redraw()


## Appelé par main.gd (0 puis 1) ; borné à 0..1. Émet progress_changed, puis finished une fois
## arrivé à 1.
func set_progress(ratio: float) -> void:
	progress = clampf(ratio, 0.0, 1.0)
	if is_node_ready():
		_show_progress()
	progress_changed.emit(progress)
	if progress < 1.0:
		_finished = false
	elif not _finished:
		_finished = true
		finished.emit()


func is_finished() -> bool:
	return _finished


func status_text() -> String:
	return _status.text


## Charge `path` en plusieurs images (dépendances d'abord, au plus `frame_budget_ms` de travail
## par image) en faisant avancer la barre, puis renvoie la scène (null si elle n'existe pas).
## Usage : `var scene: PackedScene = await loading.load_scene("res://src/game.tscn")`.
## Ne pas libérer l'écran pendant l'attente.
func load_scene(path: String, frame_budget_ms: float = 50.0) -> PackedScene:
	var scenes: Array[PackedScene] = await load_scenes([path], frame_budget_ms)
	return scenes[0]


## (E1) Comme load_scene, pour plusieurs scènes d'une même barre (la partie et sa première
## carte) : leurs dépendances, sans doublon, puis chacune ; renvoie les scènes dans l'ordre de
## paths (null pour une scène qui n'existe pas).
func load_scenes(paths: Array[String], frame_budget_ms: float = 50.0) -> Array[PackedScene]:
	var queue: Array[String] = []
	var seen := {}
	for path: String in paths:
		if not ResourceLoader.exists(path):
			push_error("Loading : scène introuvable : %s" % path)
			continue
		for dependency: String in dependency_order(path):
			if not seen.has(dependency):
				seen[dependency] = true
				queue.append(dependency)
	# Les dépendances déjà chargées restent en cache tant qu'on les référence.
	var kept: Array[Resource] = []
	set_progress(0.0)
	var started := Time.get_ticks_msec()
	for i in queue.size():
		var resource := ResourceLoader.load(queue[i])
		if resource != null:
			kept.append(resource)
		if Time.get_ticks_msec() - started >= frame_budget_ms:
			set_progress(float(i + 1) / float(queue.size() + paths.size()))
			await get_tree().process_frame
			started = Time.get_ticks_msec()
	var scenes: Array[PackedScene] = []
	for path: String in paths:
		scenes.append(
			ResourceLoader.load(path) as PackedScene if ResourceLoader.exists(path) else null
		)
	kept.clear()
	set_progress(1.0)
	return scenes


## Typographie française : espace insécable avant « ! » et « % ».
func _show_progress() -> void:
	_bar.value = progress
	if progress >= 1.0:
		_status.text = "Prêt !"
	elif progress > 0.0:
		_status.text = "%s %d %%" % [message, roundi(progress * 100.0)]
	else:
		_status.text = message


func _draw_backdrop() -> void:
	var area := _backdrop.size
	for i in SKY_HEIGHTS.size() - 1:
		var top := SKY_HEIGHTS[i] * area.y
		var bottom := SKY_HEIGHTS[i + 1] * area.y
		_backdrop.draw_polygon(
			PackedVector2Array(
				[Vector2(0, top), Vector2(area.x, top), Vector2(area.x, bottom), Vector2(0, bottom)]
			),
			PackedColorArray([SKY_COLORS[i], SKY_COLORS[i], SKY_COLORS[i + 1], SKY_COLORS[i + 1]])
		)
	_backdrop.draw_rect(
		Rect2(0, SKY_HEIGHTS[-1] * area.y, area.x, area.y), SKY_COLORS[SKY_COLORS.size() - 1]
	)
	var sun_center := Vector2(area.x * 0.5, area.y * 0.66)
	var sun_radius := area.y * 0.1
	var pulse := 1.0 + 0.04 * sin(_time * 1.6)
	for k in 4:
		_backdrop.draw_circle(sun_center, sun_radius * (1.5 + 0.45 * k) * pulse, Color(SUN, 0.09))
	_backdrop.draw_circle(sun_center, sun_radius, SUN)
	for layer in DUNE_BASES.size():
		_draw_dune(area, layer)
	for k in PETALS:
		_draw_petal(area, k)


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
	_backdrop.draw_colored_polygon(points, DUNE_COLORS[layer])


## Pétales de sakura qui dérivent (positions pseudo-aléatoires fixes par pétale).
func _draw_petal(area: Vector2, k: int) -> void:
	var seed_x := fposmod(sin(k * 12.9898) * 43758.547, 1.0)
	var seed_y := fposmod(sin(k * 78.233) * 24634.635, 1.0)
	var speed := 0.025 + 0.02 * seed_y
	var position_px := Vector2(
		fposmod(seed_x + _time * speed, 1.0) * area.x,
		fposmod(seed_y + _time * speed * 0.7, 1.0) * area.y * 0.8
	)
	_backdrop.draw_set_transform(position_px, _time * 0.9 + k, Vector2(1.0, 0.55))
	_backdrop.draw_circle(Vector2.ZERO, 5.0 + 2.0 * seed_x, PETAL)
	_backdrop.draw_set_transform_matrix(Transform2D.IDENTITY)
