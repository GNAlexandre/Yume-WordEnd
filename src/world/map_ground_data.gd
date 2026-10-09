@tool
class_name MapGroundData
extends RefCounted
## Données du sol en relief d'une carte extérieure (lot E2 de la refonte : docs/REFONTE.md 7.1 ;
## format et mode d'emploi : PLAN.md, « Format du sol des cartes extérieures »).
##
## data/maps/<map_id>/map.json et ses images, lues, vérifiées et mises en grilles :
## - heights.png : un pixel par case ; transparent = le vide ; gris R = palier
##   (R − height_zero_value) / height_step_value, de LEVEL_HEIGHT m chacun ;
## - materials.png : materials_scale pixels par mètre ; couleur = matière (palette de map.json,
##   matières de data/maps/ground_materials.json ou de map.json) ;
## - structures.png (facultative) : escaliers, rampes, style des faces (couleurs de la
##   bibliothèque) ; transparent ou noir = rien.
## MapGround (src/world/map_ground.gd) en construit le sol (MapGroundBuilder) ;
## tools/map_build.py les vérifie aussi, les génère d'un plan et en tire une vue de dessus.
##
## Repères (contrat des cartes) : origine au coin nord-ouest, x vers l'est, z vers le sud, une case
## par mètre ; la case (i, j) couvre [i, i + 1] × [j, j + 1]. Au-delà d'un bord « land » de la
## carte, le sol se prolonge de `skirt` m (les cases du bord, recopiées) ; au-delà d'un bord
## « void », le vide.
##
## La côte (bord du vide) n'est pas en escalier : c'est la ligne coast_value() = 0, tirée d'un champ
## lisse (part de terre dans les 4 × 4 cases autour de chaque coin) et d'un bruit, échantillonnée
## tous les 1 / COAST_SUBDIV m comme le mesh. Elle mord sur les cases de terre et déborde sur les
## cases vides voisines (fill_level_at : le palier commun de la terre autour).

enum Kind { FLAT, STAIRS, RAMP }
enum Face { EARTH, ROCK, WALL, ATLAS }

const FORMAT := "map_ground"
const VERSION := 1
const DATA_ROOT := "res://data/maps"
const LIBRARY_PATH := "res://data/maps/ground_materials.json"
## Hauteur d'un palier (m), d'une contremarche d'escalier (m : sous 0,1025 m, la capsule du joueur,
## rayon 0,35 m, pente du sol 45° au plus, monte la marche sans sauter) et pente maximale (°).
const LEVEL_HEIGHT := 0.5
const STAIR_RISER := 0.1
const MAX_SLOPE_DEG := 40.0
## Hauteur rendue dans le vide (sous la mer de nuages) et palier d'une case vide.
const VOID_HEIGHT := -100.0
const VOID_LEVEL := -1000
const NO_FACE := 255
const NO_MATERIAL := 255
const DEFAULT_STEP_VALUE := 16
const DEFAULT_SKIRT := 16.0
## Liseré de la côte : cases (distance de Tchebychev) d'une case de terre au vide où la côte peut
## passer ; découpage de ces cases (pas de 1 / COAST_SUBDIV m) ; écart de la côte au tracé peint.
const RIM_ZONE := 2
const COAST_SUBDIV := 3
const COAST_WOBBLE := 0.11
const COAST_NOISE_CELL := 2.3
## Pente du champ lisse de la côte (par m) : coast_value() / COAST_GRADIENT ≈ distance au vide (m).
const COAST_GRADIENT := 0.25

const SIDES: Array[String] = ["north", "east", "south", "west"]
const DIRECTIONS: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)
]
const MAP_KEYS: Array[String] = [
	"format",
	"version",
	"size",
	"heights_image",
	"height_step_value",
	"height_zero_value",
	"materials_image",
	"materials_scale",
	"structures_image",
	"palette",
	"materials",
	"edges",
	"skirt",
	"barrier",
	"spawn",
]
const MATERIAL_KEYS: Array[String] = [
	"label", "layer", "color", "tint", "variant", "edge", "path", "walkable", "ripple", "border"
]
const BORDER_KEYS: Array[String] = ["layer", "width", "tint"]
const FACE_NAMES := {"earth": Face.EARTH, "rock": Face.ROCK, "wall": Face.WALL}

static var _library: Dictionary = {}

var map_id: StringName = &""
var width: int = 0
var depth: int = 0
var materials_scale: int = 1
var skirt: float = DEFAULT_SKIRT
var barrier: bool = true
## Bord de la carte (« north », « east », « south », « west ») → « void » ou « land ».
var edges: Dictionary = {"north": "land", "east": "land", "south": "land", "west": "land"}
## Case de départ des vérifications d'accès ((-1, -1) : aucune).
var spawn: Vector2i = Vector2i(-1, -1)
## Problèmes relevés à la lecture (vide : carte valide).
var problems: PackedStringArray = PackedStringArray()
## Par case (j × width + i) : palier (VOID_LEVEL : le vide), Kind, direction de montée (indice de
## DIRECTIONS), style imposé des faces qui en descendent (Face ou NO_FACE).
var levels: PackedInt32Array = PackedInt32Array()
var kinds: PackedByteArray = PackedByteArray()
var directions: PackedByteArray = PackedByteArray()
var faces: PackedByteArray = PackedByteArray()
## Volées (escaliers, rampes), par case : rang depuis le bas (-1 hors volée), longueur (cases),
## hauteurs du bas et du haut (m).
var run_index: PackedInt32Array = PackedInt32Array()
var run_length: PackedInt32Array = PackedInt32Array()
var run_low: PackedFloat32Array = PackedFloat32Array()
var run_high: PackedFloat32Array = PackedFloat32Array()
## Matière de chaque pixel de materials.png (materials_scale par m) : indice dans material_names ;
## les pixels du vide prennent la matière de terre la plus proche.
var pixel_materials: PackedByteArray = PackedByteArray()
var material_names: Array[StringName] = []
## Matières résolues (bibliothèque, puis map.json) : layer (indice de GROUND_LAYERS), tint (Color),
## variant, sharp, path, walkable, ripple (bool), border_layer (-1 : aucune), border_width (m),
## border_tint (Color), color (Color de peinture).
var material_specs: Array[Dictionary] = []

## Cases de prolongement à l'ouest, à l'est, au nord et au sud (0 du côté du vide).
var ext_left: int = 0
var ext_right: int = 0
var ext_top: int = 0
var ext_bottom: int = 0


## Bibliothèque des matières et des structures (data/maps/ground_materials.json), lue une fois.
static func library() -> Dictionary:
	if _library.is_empty():
		_library = _read_json(LIBRARY_PATH)
	return _library


## Données de data/maps/<id>/ (ou de root/<id>/) ; problems dit ce qui ne va pas.
static func load_map(id: StringName, root: String = DATA_ROOT) -> MapGroundData:
	var data := MapGroundData.new()
	data.map_id = id
	var folder := root.path_join(String(id))
	var path := folder.path_join("map.json")
	if not FileAccess.file_exists(path):
		data.problems.append("%s absent" % path)
		return data
	var spec := _read_json(path)
	if spec.is_empty():
		data.problems.append("%s illisible" % path)
		return data
	var heights := _image(folder, spec.get("heights_image", "heights.png"), data.problems)
	var materials := _image(folder, spec.get("materials_image", "materials.png"), data.problems)
	var structures: Image = null
	if spec.has("structures_image"):
		structures = _image(folder, spec["structures_image"], data.problems)
	if heights == null or materials == null or not data.problems.is_empty():
		return data
	data.parse(spec, heights, materials, structures)
	return data


## Données faites d'une description (le contenu de map.json) et d'images en mémoire (tests).
static func from_images(
	spec: Dictionary,
	heights: Image,
	materials: Image,
	structures: Image = null,
	id: StringName = &""
) -> MapGroundData:
	var data := MapGroundData.new()
	data.map_id = id
	data.parse(spec, heights, materials, structures)
	return data


static func _read_json(path: String) -> Dictionary:
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		return {}
	return json.data


static func _image(folder: String, file: Variant, out: PackedStringArray) -> Image:
	var path := folder.path_join(str(file))
	if not ResourceLoader.exists(path):
		out.append("%s absente" % path)
		return null
	var texture := load(path) as Texture2D
	var image := texture.get_image() if texture != null else null
	if image == null or image.is_empty():
		out.append("%s illisible" % path)
		return null
	return image


# --- Lecture ------------------------------------------------------------------------------------


## Lit la description et les images ; les problèmes vont dans problems.
func parse(spec: Dictionary, heights: Image, materials: Image, structures: Image) -> void:
	_parse_spec(spec)
	_parse_materials(spec)
	if width <= 0 or depth <= 0:
		return
	_alloc()
	_read_heights(heights, int(spec.get("height_step_value", DEFAULT_STEP_VALUE)), spec)
	_read_materials(materials)
	_read_structures(structures)
	_compute_runs()
	_validate()
	_fill_void_materials()
	var cells := ceili(skirt)
	ext_left = cells if edges["west"] == "land" else 0
	ext_right = cells if edges["east"] == "land" else 0
	ext_top = cells if edges["north"] == "land" else 0
	ext_bottom = cells if edges["south"] == "land" else 0


func _parse_spec(spec: Dictionary) -> void:
	for key: String in spec.keys():
		if not key.begins_with("_") and not key in MAP_KEYS:
			problems.append("map.json : clé inconnue « %s »" % key)
	if String(spec.get("format", "")) != FORMAT:
		problems.append("map.json : format « %s » attendu" % FORMAT)
	if int(spec.get("version", 0)) != VERSION:
		problems.append("map.json : version %d attendue" % VERSION)
	var size: Variant = spec.get("size", [])
	if size is Array and (size as Array).size() == 2:
		width = int(size[0])
		depth = int(size[1])
	if width < 4 or depth < 4:
		problems.append("map.json : size [largeur, profondeur] de 4 m au moins")
		width = 0
		depth = 0
	materials_scale = int(spec.get("materials_scale", 1))
	if not materials_scale in [1, 2, 4]:
		problems.append("map.json : materials_scale vaut 1, 2 ou 4")
		materials_scale = 1
	if int(spec.get("height_step_value", DEFAULT_STEP_VALUE)) < 1:
		problems.append("map.json : height_step_value ≥ 1")
	skirt = maxf(0.0, float(spec.get("skirt", DEFAULT_SKIRT)))
	barrier = bool(spec.get("barrier", true))
	var sides: Variant = spec.get("edges", {})
	if sides is Dictionary:
		for side: String in (sides as Dictionary).keys():
			var kind := String(sides[side])
			if not side in SIDES or not kind in ["void", "land"]:
				problems.append(
					"map.json : edges %s = %s (north|east|south|west : void|land)" % [side, kind]
				)
			else:
				edges[side] = kind
	var at: Variant = spec.get("spawn", [])
	if at is Array and (at as Array).size() == 2:
		spawn = Vector2i(int(at[0]), int(at[1]))


## Palette de map.json → matières (bibliothèque, surchargée par les « materials » de map.json).
func _parse_materials(spec: Dictionary) -> void:
	var known: Dictionary = (library().get("materials", {}) as Dictionary).duplicate()
	var own: Variant = spec.get("materials", {})
	if own is Dictionary:
		for name: String in (own as Dictionary).keys():
			if name.begins_with("_"):
				continue
			var merged: Dictionary = (known.get(name, {}) as Dictionary).duplicate()
			merged.merge(own[name] as Dictionary, true)
			known[name] = merged
	var palette: Variant = spec.get("palette", {})
	if not palette is Dictionary or (palette as Dictionary).is_empty():
		problems.append("map.json : palette vide")
		return
	for color: String in (palette as Dictionary).keys():
		if color.begins_with("_"):
			continue
		var name := StringName(String(palette[color]))
		if not Color.html_is_valid(color) or not color.begins_with("#") or color.length() != 7:
			problems.append("palette : couleur « %s » (#rrggbb)" % color)
			continue
		if not known.has(String(name)):
			problems.append("palette : matière inconnue « %s »" % name)
			continue
		if not material_names.has(name):
			material_names.append(name)
			material_specs.append(_resolve(String(name), known[String(name)] as Dictionary))
		material_specs[material_names.find(name)]["colors"].append(Color.html(color))
	if material_names.size() >= NO_MATERIAL:
		problems.append("palette : %d matières au plus" % (NO_MATERIAL - 1))


## Matière résolue (valeurs par défaut comprises) ; une clé ou une tuile inconnue est un problème.
func _resolve(name: String, raw: Dictionary) -> Dictionary:
	for key: String in raw.keys():
		if not key.begins_with("_") and not key in MATERIAL_KEYS:
			problems.append("matière %s : clé inconnue « %s »" % [name, key])
	var layer := IslandTerrain.GROUND_LAYERS.find(StringName(String(raw.get("layer", ""))))
	if layer < 0:
		problems.append(
			"matière %s : tuile « %s » absente de l'atlas" % [name, raw.get("layer", "")]
		)
		layer = 0
	var spec := {
		"layer": layer,
		"tint": _color(raw.get("tint", [1.0, 1.0, 1.0])),
		"variant": bool(raw.get("variant", true)),
		"sharp": String(raw.get("edge", "soft")) == "sharp",
		"path": bool(raw.get("path", false)),
		"walkable": bool(raw.get("walkable", true)),
		"ripple": bool(raw.get("ripple", false)),
		"border_layer": -1,
		"border_width": 0.0,
		"border_tint": Color.WHITE,
		"colors": [],
	}
	if not String(raw.get("edge", "soft")) in ["soft", "sharp"]:
		problems.append("matière %s : edge soft ou sharp" % name)
	var border: Variant = raw.get("border", null)
	if border is Dictionary:
		for key: String in (border as Dictionary).keys():
			if not key in BORDER_KEYS:
				problems.append("matière %s : bordure, clé inconnue « %s »" % [name, key])
		var border_layer := IslandTerrain.GROUND_LAYERS.find(
			StringName(str(border.get("layer", "")))
		)
		if border_layer < 0:
			problems.append("matière %s : tuile de bordure inconnue" % name)
		spec["border_layer"] = border_layer
		spec["border_width"] = clampf(float(border.get("width", 0.3)), 0.05, 2.0)
		spec["border_tint"] = _color(border.get("tint", [1.0, 1.0, 1.0]))
	return spec


static func _color(value: Variant) -> Color:
	if value is Array and (value as Array).size() >= 3:
		return Color(float(value[0]), float(value[1]), float(value[2]))
	return Color.WHITE


func _alloc() -> void:
	var count := width * depth
	levels.resize(count)
	kinds.resize(count)
	directions.resize(count)
	faces.resize(count)
	faces.fill(NO_FACE)
	run_index.resize(count)
	run_index.fill(-1)
	run_length.resize(count)
	run_low.resize(count)
	run_high.resize(count)
	pixel_materials.resize(count * materials_scale * materials_scale)
	pixel_materials.fill(NO_MATERIAL)


## Octets RGBA8 d'une image de la taille attendue (vide et un problème sinon).
func _rgba(image: Image, want: Vector2i, label: String) -> PackedByteArray:
	if image == null:
		return PackedByteArray()
	if image.get_size() != want:
		problems.append(
			(
				"%s : %d × %d px au lieu de %d × %d"
				% [label, image.get_width(), image.get_height(), want.x, want.y]
			)
		)
		return PackedByteArray()
	var copy := image.duplicate() as Image
	if copy.is_compressed():
		copy.decompress()
	copy.convert(Image.FORMAT_RGBA8)
	return copy.get_data()


func _read_heights(image: Image, step: int, spec: Dictionary) -> void:
	var bytes := _rgba(image, Vector2i(width, depth), "heights.png")
	levels.fill(VOID_LEVEL)
	if bytes.is_empty():
		return
	var zero := int(spec.get("height_zero_value", 0))
	step = maxi(step, 1)
	var bad := 0
	var first := Vector2i(-1, -1)
	for c in width * depth:
		if bytes[c * 4 + 3] < 128:
			continue
		var value := int(bytes[c * 4]) - zero
		if posmod(value, step) != 0:
			bad += 1
			if bad == 1:
				first = Vector2i(c % width, floori(float(c) / width))
		levels[c] = roundi(float(value) / step)
	if bad > 0:
		problems.append(
			(
				"heights.png : %d case(s) hors palier (gris multiple de %d), dont (%d, %d)"
				% [bad, step, first.x, first.y]
			)
		)


func _read_materials(image: Image) -> void:
	var w := width * materials_scale
	var bytes := _rgba(image, Vector2i(w, depth * materials_scale), "materials.png")
	if bytes.is_empty():
		return
	var by_color := {}
	for index in material_specs.size():
		for color: Color in material_specs[index]["colors"]:
			by_color[color.to_rgba32() >> 8] = index
	var unknown := {}
	var last_key := -1
	var last_index := NO_MATERIAL
	for p in pixel_materials.size():
		var at := p * 4
		if bytes[at + 3] >= 128:
			var key := (bytes[at] << 16) | (bytes[at + 1] << 8) | bytes[at + 2]
			if key != last_key:
				last_key = key
				last_index = by_color.get(key, NO_MATERIAL)
			if last_index != NO_MATERIAL:
				pixel_materials[p] = last_index
				continue
		# Pixel transparent ou de couleur inconnue : un problème s'il est sur la terre.
		var x := p % w
		var y := floori(float(p) / w)
		var cell := floori(float(y) / materials_scale) * width + floori(float(x) / materials_scale)
		if levels[cell] != VOID_LEVEL:
			var rgb := (bytes[at] << 16) | (bytes[at + 1] << 8) | bytes[at + 2]
			unknown["transparent" if bytes[at + 3] < 128 else "#%06x" % rgb] = Vector2i(x, y)
	for color: String in unknown.keys():
		var at: Vector2i = unknown[color]
		problems.append(
			"materials.png : couleur %s hors palette, en (%d, %d)" % [color, at.x, at.y]
		)


func _read_structures(image: Image) -> void:
	kinds.fill(Kind.FLAT)
	if image == null:
		return
	var bytes := _rgba(image, Vector2i(width, depth), "structures.png")
	if bytes.is_empty():
		return
	var table: Dictionary = library().get("structures", {})
	var by_color := {}
	for color: String in table.keys():
		if Color.html_is_valid(color):
			by_color[Color.html(color).to_rgba32() >> 8] = table[color]
	for c in width * depth:
		var key := (bytes[c * 4] << 16) | (bytes[c * 4 + 1] << 8) | bytes[c * 4 + 2]
		if bytes[c * 4 + 3] < 128 or key == 0:
			continue
		if not by_color.has(key):
			problems.append(
				(
					"structures.png : couleur #%06x inconnue en (%d, %d)"
					% [key, c % width, floori(float(c) / width)]
				)
			)
			continue
		var entry: Dictionary = by_color[key]
		if entry.has("face"):
			faces[c] = int(FACE_NAMES.get(String(entry["face"]), Face.ROCK))
		else:
			kinds[c] = Kind.STAIRS if String(entry.get("kind", "")) == "stairs" else Kind.RAMP
			directions[c] = maxi(SIDES.find(String(entry.get("dir", "north"))), 0)


# --- Volées ---------------------------------------------------------------------------------------


func _same_run(cell: Vector2i, kind: int, direction: int) -> bool:
	if not in_map(cell.x, cell.y):
		return false
	var c := cell.y * width + cell.x
	return kinds[c] == kind and directions[c] == direction and levels[c] != VOID_LEVEL


## Chaque volée (cases d'escalier ou de rampe à la suite dans leur sens de montée) : rang, longueur,
## hauteurs du bas (case d'avant) et du haut (case d'après), pente.
func _compute_runs() -> void:
	for c in width * depth:
		if kinds[c] == Kind.FLAT or run_index[c] >= 0 or levels[c] == VOID_LEVEL:
			continue
		var kind := kinds[c]
		var dir := DIRECTIONS[directions[c]]
		var start := Vector2i(c % width, floori(float(c) / width))
		while _same_run(start - dir, kind, directions[c]):
			start -= dir
		var count := 0
		var after := start
		while _same_run(after, kind, directions[c]):
			count += 1
			after += dir
		var low := _run_end(start - dir, start)
		var high := _run_end(after, start)
		var label := "escalier" if kind == Kind.STAIRS else "rampe"
		var rise := high - low
		if low == VOID_HEIGHT or high == VOID_HEIGHT or rise <= 0.0:
			(
				problems
				. append(
					(
						"%s en (%d, %d) : il relie une case plate au bas et une case plate plus haute au bout"
						% [label, start.x, start.y]
					)
				)
			)
		elif rad_to_deg(atan(rise / count)) > MAX_SLOPE_DEG + 0.001:
			problems.append(
				(
					"%s en (%d, %d) : pente de %.0f° (%.1f m sur %d m ; %.0f° au plus)"
					% [
						label,
						start.x,
						start.y,
						rad_to_deg(atan(rise / count)),
						rise,
						count,
						MAX_SLOPE_DEG
					]
				)
			)
		for k in count:
			var at := start + dir * k
			var index := at.y * width + at.x
			run_index[index] = k
			run_length[index] = count
			run_low[index] = low
			run_high[index] = high


## Hauteur de la case plate qui borde une volée (VOID_HEIGHT : hors carte, vide ou pas plate).
func _run_end(cell: Vector2i, _start: Vector2i) -> float:
	if not in_map(cell.x, cell.y):
		return VOID_HEIGHT
	var c := cell.y * width + cell.x
	if levels[c] == VOID_LEVEL or kinds[c] != Kind.FLAT:
		return VOID_HEIGHT
	return levels[c] * LEVEL_HEIGHT


# --- Vérifications --------------------------------------------------------------------------------


func _validate() -> void:
	var near_void := 0
	var on_border := 0
	var twisted := 0
	var steps := 0
	var step_at := Vector2i.ZERO
	for j in depth:
		for i in width:
			var c := j * width + i
			if levels[c] == VOID_LEVEL:
				continue
			if kinds[c] != Kind.FLAT:
				if i == 0 or j == 0 or i == width - 1 or j == depth - 1:
					on_border += 1
				if _void_within(i, j, RIM_ZONE):
					near_void += 1
				if not _parallel_neighbors_match(i, j):
					twisted += 1
				continue
			var level := levels[c]
			var east_cliff := i + 1 < width and absi(levels[c + 1] - level) > 1
			var south_cliff := j + 1 < depth and absi(levels[c + width] - level) > 1
			if (
				(east_cliff and _path_cliff(c, Vector2i(i + 1, j)))
				or (south_cliff and _path_cliff(c, Vector2i(i, j + 1)))
			):
				steps += 1
				step_at = Vector2i(i, j)
	if on_border > 0:
		problems.append("%d case(s) d'escalier ou de rampe au bord de la carte" % on_border)
	if near_void > 0:
		problems.append(
			"%d case(s) d'escalier ou de rampe à moins de %d m du vide" % [near_void, RIM_ZONE]
		)
	if twisted > 0:
		problems.append(
			"%d case(s) d'escalier ou de rampe collées à une volée d'un autre profil" % twisted
		)
	if steps > 0:
		problems.append(
			(
				"%d marche(s) de plus de %.1f m sans escalier sur un chemin, dont en (%d, %d)"
				% [steps, LEVEL_HEIGHT, step_at.x, step_at.y]
			)
		)
	if (
		spawn != Vector2i(-1, -1)
		and not (in_map(spawn.x, spawn.y) and is_walkable(spawn.x + 0.5, spawn.y + 0.5))
	):
		problems.append("spawn (%d, %d) : hors de la carte ou pas praticable" % [spawn.x, spawn.y])


## Vrai si une case vide (ou le vide au-delà d'un bord « void ») est à moins de reach cases.
func _void_within(i: int, j: int, reach: int) -> bool:
	for dj in range(-reach, reach + 1):
		for di in range(-reach, reach + 1):
			if is_void_at(i + di, j + dj):
				return true
	return false


## Les voisines de côté d'une case de volée sont plates ou de la même volée large (même profil).
func _parallel_neighbors_match(i: int, j: int) -> bool:
	var c := j * width + i
	var dir := DIRECTIONS[directions[c]]
	for side: Vector2i in [Vector2i(dir.y, dir.x), Vector2i(-dir.y, -dir.x)]:
		var n := Vector2i(i, j) + side
		if not in_map(n.x, n.y):
			continue
		var k := n.y * width + n.x
		if kinds[k] == Kind.FLAT or levels[k] == VOID_LEVEL:
			continue
		if (
			kinds[k] != kinds[c]
			or directions[k] != directions[c]
			or run_index[k] != run_index[c]
			or run_length[k] != run_length[c]
			or run_low[k] != run_low[c]
			or run_high[k] != run_high[c]
		):
			return false
	return true


## Vrai si deux cases de chemin voisines, plates et praticables, ont plus d'un palier d'écart.
func _path_cliff(c: int, n: Vector2i) -> bool:
	if not in_map(n.x, n.y):
		return false
	var k := n.y * width + n.x
	if levels[k] == VOID_LEVEL or kinds[k] != Kind.FLAT or absi(levels[k] - levels[c]) <= 1:
		return false
	var a := cell_material(c % width, floori(float(c) / width))
	var b := cell_material(n.x, n.y)
	if a == NO_MATERIAL or b == NO_MATERIAL:
		return false
	return (
		material_specs[a]["path"]
		and material_specs[b]["path"]
		and material_specs[a]["walkable"]
		and material_specs[b]["walkable"]
	)


## Les pixels du vide prennent la matière de terre voisine (le shader lit la matière sous la côte,
## qui déborde sur le vide, et autour des points du sol).
func _fill_void_materials() -> void:
	var w := width * materials_scale
	var h := depth * materials_scale
	# Parcours en largeur depuis les pixels peints qui touchent un pixel sans matière.
	var empty := pixel_materials.find(NO_MATERIAL)
	if empty < 0:
		return
	var queue := PackedInt32Array()
	for p in range(empty, pixel_materials.size()):
		if pixel_materials[p] == NO_MATERIAL:
			queue.append(p)
	# Couches successives : chaque pixel vide prend la matière d'un voisin déjà peint.
	var total := w * h
	while not queue.is_empty():
		var next := PackedInt32Array()
		var source := pixel_materials.duplicate()
		for p in queue:
			var x := p % w
			var found := NO_MATERIAL
			if x > 0 and source[p - 1] != NO_MATERIAL:
				found = source[p - 1]
			elif x + 1 < w and source[p + 1] != NO_MATERIAL:
				found = source[p + 1]
			elif p >= w and source[p - w] != NO_MATERIAL:
				found = source[p - w]
			elif p + w < total and source[p + w] != NO_MATERIAL:
				found = source[p + w]
			if found == NO_MATERIAL:
				next.append(p)
			else:
				pixel_materials[p] = found
		if next.size() == queue.size():
			break
		queue = next
	for p in queue:
		pixel_materials[p] = 0


# --- Cases, prolongement, vide --------------------------------------------------------------------


func in_map(i: int, j: int) -> bool:
	return i >= 0 and j >= 0 and i < width and j < depth


## Case de la carte qui vaut pour (i, j) : elle-même dans la carte ; au-delà d'un bord « land », la
## case du bord la plus proche (prolongement, jusqu'à skirt m si limited) ; -1 dans le vide d'un
## bord « void » (ou au-delà du prolongement si limited).
func lookup(i: int, j: int, limited: bool = false) -> int:
	if i < 0:
		if edges["west"] == "void" or (limited and i < -ext_left):
			return -1
		i = 0
	elif i >= width:
		if edges["east"] == "void" or (limited and i >= width + ext_right):
			return -1
		i = width - 1
	if j < 0:
		if edges["north"] == "void" or (limited and j < -ext_top):
			return -1
		j = 0
	elif j >= depth:
		if edges["south"] == "void" or (limited and j >= depth + ext_bottom):
			return -1
		j = depth - 1
	return j * width + i


## Vrai si (i, j) est le vide (case vide, ou au-delà d'un bord « void »).
func is_void_at(i: int, j: int) -> bool:
	var c := lookup(i, j)
	return c < 0 or levels[c] == VOID_LEVEL


## Palier commun de la terre (plate) dans les 5 × 5 cases autour d'une case vide, sur lequel la côte
## peut déborder ; VOID_LEVEL si la terre autour n'est pas d'un seul palier, ou s'il n'y en a pas.
func fill_level_at(i: int, j: int) -> int:
	var found := VOID_LEVEL
	for dj in range(-RIM_ZONE, RIM_ZONE + 1):
		for di in range(-RIM_ZONE, RIM_ZONE + 1):
			var c := lookup(i + di, j + dj)
			if c < 0 or levels[c] == VOID_LEVEL:
				continue
			if kinds[c] != Kind.FLAT or (found != VOID_LEVEL and levels[c] != found):
				return VOID_LEVEL
			found = levels[c]
	return found


## Valeur du champ lisse de la côte au coin (ci, cj) : part de terre des 4 × 4 cases autour − 0,5.
func coast_base(ci: int, cj: int) -> float:
	var land := 0
	for dj in range(-2, 2):
		for di in range(-2, 2):
			if not is_void_at(ci + di, cj + dj):
				land += 1
	return land / 16.0 - 0.5


## Champ de la côte à un sommet du découpage (> 0 : terre) : champ lisse interpolé entre les coins,
## plus un bruit d'amplitude COAST_WOBBLE.
func coast_vertex(x: float, z: float) -> float:
	var i := floori(x)
	var j := floori(z)
	var fx := x - i
	var fz := z - j
	var top := lerpf(coast_base(i, j), coast_base(i + 1, j), fx)
	var bottom := lerpf(coast_base(i, j + 1), coast_base(i + 1, j + 1), fx)
	return lerpf(top, bottom, fz) + COAST_WOBBLE * coast_noise(x, z)


## Champ de la côte en (x, z), interpolé sur les triangles du découpage comme le mesh.
func coast_value(x: float, z: float) -> float:
	var gx := x * COAST_SUBDIV
	var gz := z * COAST_SUBDIV
	var a := floori(gx)
	var b := floori(gz)
	var fx := gx - a
	var fz := gz - b
	var step := 1.0 / COAST_SUBDIV
	var x0 := a * step
	var z0 := b * step
	var v01 := coast_vertex(x0, z0 + step)
	var v10 := coast_vertex(x0 + step, z0)
	if fx + fz <= 1.0:
		var v00 := coast_vertex(x0, z0)
		return v00 + fx * (v10 - v00) + fz * (v01 - v00)
	var v11 := coast_vertex(x0 + step, z0 + step)
	return v11 + (1.0 - fx) * (v01 - v11) + (1.0 - fz) * (v10 - v11)


## Bruit de valeurs lisse (−1 à 1) de la côte, sur une grille de COAST_NOISE_CELL m.
static func coast_noise(x: float, z: float) -> float:
	var gx := x / COAST_NOISE_CELL
	var gz := z / COAST_NOISE_CELL
	var i := floori(gx)
	var j := floori(gz)
	var fx := gx - i
	var fz := gz - j
	fx = fx * fx * (3.0 - 2.0 * fx)
	fz = fz * fz * (3.0 - 2.0 * fz)
	# Valeurs pseudo-aléatoires (0 à 1) des quatre coins de la grille, sans appel de fonction.
	var a := (i * 374761393 + j * 668265263) & 0x7fffffff
	var b := ((i + 1) * 374761393 + j * 668265263) & 0x7fffffff
	var c := (i * 374761393 + (j + 1) * 668265263) & 0x7fffffff
	var d := ((i + 1) * 374761393 + (j + 1) * 668265263) & 0x7fffffff
	a = (((a ^ (a >> 13)) * 1274126177) >> 8) & 0xffff
	b = (((b ^ (b >> 13)) * 1274126177) >> 8) & 0xffff
	c = (((c ^ (c >> 13)) * 1274126177) >> 8) & 0xffff
	d = (((d ^ (d >> 13)) * 1274126177) >> 8) & 0xffff
	var top := lerpf(a, b, fx)
	var bottom := lerpf(c, d, fx)
	return lerpf(top, bottom, fz) / 32767.5 - 1.0


# --- Requêtes -----------------------------------------------------------------------------------


## Indice de matière de la case (i, j) (son pixel du centre), ou NO_MATERIAL hors carte.
func cell_material(i: int, j: int) -> int:
	var c := lookup(i, j)
	if c < 0:
		return NO_MATERIAL
	var ci := c % width
	var cj := floori(float(c) / width)
	var half := floori(materials_scale / 2.0)
	var w := width * materials_scale
	return pixel_materials[(cj * materials_scale + half) * w + ci * materials_scale + half]


## Indice de matière au point (x, z) (pixel de materials.png ; prolongement : le bord), ou
## NO_MATERIAL dans le vide d'un bord « void ».
func material_index_at(x: float, z: float) -> int:
	if lookup(floori(x), floori(z)) < 0:
		return NO_MATERIAL
	var w := width * materials_scale
	var px := clampi(floori(x * materials_scale), 0, w - 1)
	var pz := clampi(floori(z * materials_scale), 0, depth * materials_scale - 1)
	return pixel_materials[pz * w + px]


## Hauteur exacte du sol en (x, z), telle que le mesh la dessine (marches, rampes, côte comprises) ;
## VOID_HEIGHT dans le vide.
func surface_height(x: float, z: float) -> float:
	var i := floori(x)
	var j := floori(z)
	var c := lookup(i, j, true)
	if c < 0:
		return VOID_HEIGHT
	var level := levels[c]
	if level == VOID_LEVEL:
		level = fill_level_at(i, j)
		if level == VOID_LEVEL or coast_value(x, z) < 0.0:
			return VOID_HEIGHT
		return level * LEVEL_HEIGHT
	if kinds[c] == Kind.FLAT:
		if _void_within(i, j, RIM_ZONE) and coast_value(x, z) < 0.0:
			return VOID_HEIGHT
		return level * LEVEL_HEIGHT
	return run_height(c, run_position(c, x, z))


## Abscisse (cases, 0 au bas de la volée) du point (x, z) dans la volée de la case c.
func run_position(c: int, x: float, z: float) -> float:
	var i := c % width
	var j := floori(float(c) / width)
	var t := 0.0
	match directions[c]:
		0:
			t = (j + 1) - z
		1:
			t = x - i
		2:
			t = z - j
		_:
			t = (i + 1) - x
	return run_index[c] + clampf(t, 0.0, 1.0)


## Hauteur du sol à l'abscisse s d'une volée : marches de STAIR_RISER m (la première contremarche
## au bas de la volée), ou pente droite d'une rampe.
func run_height(c: int, s: float) -> float:
	var low := run_low[c]
	var high := run_high[c]
	var count := run_length[c]
	if kinds[c] == Kind.RAMP:
		return low + (high - low) * clampf(s / count, 0.0, 1.0)
	var steps := stair_steps(c)
	var tread := float(count) / steps
	return minf(low + STAIR_RISER * (floori(s / tread + 0.000001) + 1), high)


## Nombre de marches de la volée d'escalier de la case c.
func stair_steps(c: int) -> int:
	return maxi(roundi((run_high[c] - run_low[c]) / STAIR_RISER), 1)


## Palier de la case sous (x, z) (prolongement compris) ; VOID_LEVEL dans le vide.
func level_at(x: float, z: float) -> int:
	var c := lookup(floori(x), floori(z), true)
	return VOID_LEVEL if c < 0 else levels[c]


## Vrai si l'on peut se tenir en (x, z) : dans la carte, sur la terre (côte comprise) et sur une
## matière praticable.
func is_walkable(x: float, z: float) -> bool:
	if not in_map(floori(x), floori(z)) or surface_height(x, z) == VOID_HEIGHT:
		return false
	var index := material_index_at(x, z)
	return index != NO_MATERIAL and bool(material_specs[index]["walkable"])


## Nom de la matière d'indice index (&"" : aucune).
func material_name(index: int) -> StringName:
	return material_names[index] if index >= 0 and index < material_names.size() else &""


## Style de la face qui descend de la case c (la plus haute) de height m : imposé par
## structures.png, sinon talus de terre jusqu'à un palier, roche au-delà.
func face_style(c: int, height: float) -> int:
	if c >= 0 and faces[c] != NO_FACE:
		return faces[c]
	return Face.EARTH if height <= LEVEL_HEIGHT + 0.001 else Face.ROCK


## Vrai si la carte touche le vide quelque part (bord « void » ou case vide).
func has_void() -> bool:
	for side: String in SIDES:
		if edges[side] == "void":
			return true
	return levels.find(VOID_LEVEL) >= 0
