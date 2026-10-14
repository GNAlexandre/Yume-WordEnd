class_name InteriorLayout
extends RefCounted
## (E3) Agencement d'un étage d'intérieur, lu dans data/maps/<map_id>/interior.json (format :
## PLAN.md, « Intérieurs » ; docs/INTERIEURS.md) et vérifié : pièces en rectangles sur une grille
## d'un mètre (repère de la carte : origine au coin nord-ouest, x vers l'est, z vers le sud),
## matières du sol et des murs par pièce, portes entre pièces ou vers l'extérieur, fenêtres,
## éléments de mur, lampes. Les murs se déduisent des pièces : il y en a un partout où deux cases
## voisines n'appartiennent pas à la même pièce (le vide, hors des pièces, compte comme une pièce).
## Un mur est centré sur la ligne de la grille, épais de wall_thickness. Utilisé par InteriorRoom
## (le nœud Ground des cartes intérieures), qui en tire meshes, collisions et lumière.
##
## Un mur est un ensemble de morceaux (pieces) : murs pleins de 0 à wall_height, troués par les
## portes praticables, et linteaux au-dessus d'elles. Aux angles, le mur nord-sud porte le poteau
## commun ; un mur est-ouest s'arrête contre lui. Les portes et les éléments ne touchent jamais un
## angle (problems le dit). Coupe (InteriorRoom) : cut_line_at() donne la première limite de pièce
## au sud du joueur.

## Axe d'une ligne de mur : est-ouest (z constant, le long de x) ou nord-sud (x constant).
const HORIZONTAL := 0
const VERTICAL := 1
## Pas de coupe (aucune limite au sud).
const NO_CUT := 1000000.0
const IMAGE_DIR := "res://assets/hd2d/interior/"
const PIXELS_PER_METER := 96.0
const DOOR_WIDTH := 1.1
const DOOR_HEIGHT := 2.2
const WINDOW_SILL := 0.9
const LAMP_RADIUS := 3.5
const LAMP_COLOR := "#ffc98a"
## Écart minimal entre une ouverture (ou un élément de mur) et un angle (m, au-delà du demi-mur).
const CORNER_GAP := 0.05
## Clés permises ; une clé inconnue est une faute, sauf « _… » (commentaire).
const TOP_KEYS: Array[String] = [
	"size", "wall_height", "wall_thickness", "rooms", "doors", "windows", "wall_items", "lights"
]
const ROOM_KEYS: Array[String] = ["name", "rects", "floor", "wall", "wallcut"]
const DOOR_KEYS: Array[String] = [
	"between", "room", "side", "x", "z", "width", "height", "image", "passable", "id"
]
const WINDOW_KEYS: Array[String] = ["room", "side", "x", "z", "image", "sill"]
const ITEM_KEYS: Array[String] = ["room", "side", "x", "z", "image", "y"]
const LIGHT_KEYS: Array[String] = ["room", "at", "radius", "color", "energy"]

## Taille de la carte (m, cases) ; hauteur et épaisseur des murs (m).
var map_size: Vector2i = Vector2i.ZERO
var wall_height: float = 3.0
var wall_thickness: float = 0.25
## Pièces : {id, name, rects: Array[Rect2i], floor, wall, wallcut (noms d'images)}.
var rooms: Array[Dictionary] = []
## Ouvertures (portes) : {id, axis, line, a, b, center, width, height, low, high (pièces au nord /
## à l'ouest et au sud / à l'est, -1 : le vide), image, passable}.
var doors: Array[Dictionary] = []
## Fenêtres et éléments de mur : {axis, line, face (+1 : face sud ou est, -1 : nord ou ouest),
## a, b, center, bottom, size (m), image, room}.
var windows: Array[Dictionary] = []
var wall_items: Array[Dictionary] = []
## Lampes : {room, at: Vector2 (x, z), radius, color, energy}.
var lights: Array[Dictionary] = []
## Morceaux de mur : {axis, line, a, b, y0, y1, low, high, free_a, free_b} (free : bout libre, au
## bord d'une porte, qui montre sa tranche).
var pieces: Array[Dictionary] = []
## Fautes trouvées à la lecture (vide : agencement valide).
var problems: Array[String] = []

var _grid: PackedInt32Array = PackedInt32Array()
var _index: Dictionary = {}


## Agencement lu dans les données d'un interior.json (déjà décodé).
static func from_data(data: Variant) -> InteriorLayout:
	var plan := InteriorLayout.new()
	plan._read(data)
	return plan


## Pièce (indice) de la case (x, z), -1 hors des pièces ou de la carte.
func cell(x: int, z: int) -> int:
	if x < 0 or z < 0 or x >= map_size.x or z >= map_size.y:
		return -1
	return _grid[z * map_size.x + x]


## Mur sur la ligne z, entre les cases (x, z - 1) et (x, z).
func h_wall(x: int, z: int) -> bool:
	return cell(x, z - 1) != cell(x, z)


## Mur sur la ligne x, entre les cases (x - 1, z) et (x, z).
func v_wall(x: int, z: int) -> bool:
	return cell(x - 1, z) != cell(x, z)


func room_index(id: StringName) -> int:
	return int(_index.get(String(id), -1))


## Identifiant de la pièce sous un point (repère de la carte), &"" hors des pièces.
func room_at(local: Vector3) -> StringName:
	var index := cell(floori(local.x), floori(local.z))
	return StringName(rooms[index]["id"]) if index >= 0 else &""


## Ligne de coupe (z de la carte) pour un joueur en local : la première limite de pièce au sud de
## sa case, dans sa colonne (porte comprise) ; NO_CUT s'il n'y en a pas.
func cut_line_at(local: Vector3) -> float:
	var x := floori(local.x)
	for line in range(floori(local.z) + 1, map_size.y + 1):
		if h_wall(x, line):
			return float(line)
	return NO_CUT


## Porte d'identifiant id (vide : aucune).
func door(id: StringName) -> Dictionary:
	for opening: Dictionary in doors:
		if StringName(opening["id"]) == id:
			return opening
	return {}


## Centre d'une ouverture au sol, sur la ligne de son mur (repère de la carte).
static func opening_center(opening: Dictionary) -> Vector3:
	if int(opening["axis"]) == HORIZONTAL:
		return Vector3(float(opening["center"]), 0.0, float(opening["line"]))
	return Vector3(float(opening["line"]), 0.0, float(opening["center"]))


# --- Lecture ---------------------------------------------------------------------------------


func _read(data: Variant) -> void:
	if not data is Dictionary:
		problems.append("l'agencement doit être un objet JSON")
		return
	var top := data as Dictionary
	_check_keys(top, TOP_KEYS, "agencement")
	var raw_size: Variant = top.get("size")
	if not _is_pair(raw_size) or float(raw_size[0]) < 1.0 or float(raw_size[1]) < 1.0:
		problems.append("size : [largeur, profondeur] en mètres attendu")
		return
	map_size = Vector2i(int(raw_size[0]), int(raw_size[1]))
	wall_height = float(top.get("wall_height", wall_height))
	wall_thickness = float(top.get("wall_thickness", wall_thickness))
	if wall_height < 2.0 or wall_height > 6.0 or wall_thickness < 0.1 or wall_thickness > 0.6:
		problems.append("wall_height (2 à 6 m) ou wall_thickness (0,1 à 0,6 m) hors limites")
	_grid.resize(map_size.x * map_size.y)
	_grid.fill(-1)
	_read_rooms(top.get("rooms"))
	for entry: Variant in _list(top, "doors"):
		_read_door(entry)
	for entry: Variant in _list(top, "windows"):
		_read_wall_panel(entry, WINDOW_KEYS, "window_", windows)
	for entry: Variant in _list(top, "wall_items"):
		_read_wall_panel(entry, ITEM_KEYS, "wallitem_", wall_items)
	for entry: Variant in _list(top, "lights"):
		_read_light(entry)
	_check_overlaps()
	_build_pieces()


func _list(top: Dictionary, key: String) -> Array:
	var value: Variant = top.get(key, [])
	if not value is Array:
		problems.append("%s : liste attendue" % key)
		return []
	return value


func _check_keys(entry: Dictionary, allowed: Array[String], label: String) -> void:
	for key: Variant in entry:
		if not String(key).begins_with("_") and not String(key) in allowed:
			problems.append("%s : clé inconnue « %s »" % [label, key])


static func _is_pair(value: Variant) -> bool:
	return value is Array and (value as Array).size() == 2


func _image_ok(image: Variant, prefix: String, label: String) -> bool:
	var image_name := String(image) if image is String else ""
	if not image_name.begins_with(prefix):
		problems.append("%s : image %s… attendue (« %s »)" % [label, prefix, image_name])
		return false
	if not ResourceLoader.exists(image_path(image_name)):
		problems.append("%s : image absente %s" % [label, image_path(image_name)])
		return false
	return true


## Chemin d'une image d'intérieur par son nom (« floor_planks_worn »).
static func image_path(image_name: String) -> String:
	return IMAGE_DIR + image_name + ".png"


func _read_rooms(raw: Variant) -> void:
	if not raw is Dictionary or (raw as Dictionary).is_empty():
		problems.append("rooms : au moins une pièce attendue")
		return
	for id: Variant in raw:
		if String(id).begins_with("_"):
			continue
		var entry: Variant = raw[id]
		if not entry is Dictionary:
			problems.append("pièce %s : objet attendu" % id)
			continue
		var room := entry as Dictionary
		var label := "pièce %s" % id
		_check_keys(room, ROOM_KEYS, label)
		var ok := _image_ok(room.get("floor"), "floor_", label + ", sol")
		ok = _image_ok(room.get("wall"), "wall_", label + ", murs") and ok
		var wallcut: Variant = room.get("wallcut", "wallcut_wood")
		ok = _image_ok(wallcut, "wallcut_", label + ", dessus des murs") and ok
		var rects := _read_rects(room.get("rects"), label)
		if rects.is_empty() or not ok:
			continue
		var index := rooms.size()
		_index[String(id)] = index
		(
			rooms
			. append(
				{
					"id": StringName(String(id)),
					"name": String(room.get("name", String(id))),
					"rects": rects,
					"floor": String(room["floor"]),
					"wall": String(room["wall"]),
					"wallcut": String(wallcut),
				}
			)
		)
		for rect: Rect2i in rects:
			_fill(rect, index, label)


func _read_rects(raw: Variant, label: String) -> Array[Rect2i]:
	var rects: Array[Rect2i] = []
	if not raw is Array or (raw as Array).is_empty():
		problems.append("%s : rects [[x, z, largeur, profondeur], …] attendu" % label)
		return rects
	for value: Variant in raw:
		var ok := value is Array and (value as Array).size() == 4
		if ok:
			for number: Variant in value:
				ok = ok and (number is float or number is int) and float(number) == roundf(number)
		if not ok:
			problems.append("%s : rectangle %s (4 entiers attendus)" % [label, value])
			continue
		var rect := Rect2i(int(value[0]), int(value[1]), int(value[2]), int(value[3]))
		if rect.size.x < 1 or rect.size.y < 1 or not Rect2i(Vector2i.ZERO, map_size).encloses(rect):
			problems.append("%s : rectangle %s hors de la carte" % [label, rect])
			continue
		rects.append(rect)
	return rects


func _fill(rect: Rect2i, index: int, label: String) -> void:
	for z in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var at := z * map_size.x + x
			if _grid[at] >= 0 and _grid[at] != index:
				problems.append(
					"%s : case (%d, %d) déjà prise par %s" % [label, x, z, rooms[_grid[at]]["id"]]
				)
				return
			_grid[at] = index


func _read_door(entry: Variant) -> void:
	if not entry is Dictionary:
		problems.append("porte : objet attendu")
		return
	var raw := entry as Dictionary
	var label := "porte %s" % [raw.get("id", raw.get("between", raw.get("room", "?")))]
	_check_keys(raw, DOOR_KEYS, label)
	var width := float(raw.get("width", DOOR_WIDTH))
	var place := _place(raw, width, label)
	if place.is_empty():
		return
	place["id"] = StringName(String(raw.get("id", "")))
	place["width"] = width
	place["height"] = float(raw.get("height", DOOR_HEIGHT))
	place["passable"] = bool(raw.get("passable", true))
	place["image"] = ""
	if raw.has("image") and _image_ok(raw["image"], "door_", label):
		place["image"] = String(raw["image"])
	if float(place["height"]) > wall_height - 0.2 or width < 0.8:
		problems.append("%s : ouverture de 0,8 m de large au moins, sous le haut du mur" % label)
	doors.append(place)


## Fenêtre ou élément de mur : posé sur la face d'un mur, côté de sa pièce, taille de l'image.
func _read_wall_panel(
	entry: Variant, keys: Array[String], prefix: String, out: Array[Dictionary]
) -> void:
	if not entry is Dictionary:
		problems.append("%s : objet attendu" % prefix)
		return
	var raw := entry as Dictionary
	var label := "%s %s" % [raw.get("image", prefix), raw.get("room", "?")]
	_check_keys(raw, keys, label)
	if not _image_ok(raw.get("image"), prefix, label):
		return
	var texture := load(image_path(String(raw["image"]))) as Texture2D
	var size := Vector2(texture.get_size()) / PIXELS_PER_METER
	var place := _place(raw, size.x, label)
	if place.is_empty():
		return
	var default_bottom := WINDOW_SILL if prefix == "window_" else 1.2
	place["bottom"] = float(raw.get("sill", raw.get("y", default_bottom)))
	place["size"] = size
	place["image"] = String(raw["image"])
	if float(place["bottom"]) < 0.0 or float(place["bottom"]) + size.y > wall_height + 0.001:
		problems.append("%s : dépasse du mur (bas à %.2f m)" % [label, place["bottom"]])
	out.append(place)


## Place d'une ouverture ou d'un élément de largeur width sur un mur : ligne, axe, intervalle, face
## (côté de la pièce nommée) ; {} et une faute si le mur n'existe pas ou touche un angle.
func _place(raw: Dictionary, width: float, label: String) -> Dictionary:
	var along_key := "x" if raw.has("x") else "z"
	if not raw.has(along_key) or (raw.has("x") and raw.has("z")):
		problems.append("%s : x (mur est-ouest) ou z (mur nord-sud) attendu" % label)
		return {}
	var axis := HORIZONTAL if along_key == "x" else VERTICAL
	var center := float(raw[along_key])
	var a := center - width / 2.0
	var b := center + width / 2.0
	var lines := _matching_lines(raw, axis, a, b, label)
	if lines.size() != 1:
		if lines.is_empty():
			problems.append("%s : aucun mur à cet endroit" % label)
		else:
			problems.append("%s : plusieurs murs possibles %s" % [label, lines])
		return {}
	var line := lines[0]
	var place := {
		"axis": axis,
		"line": line,
		"a": a,
		"b": b,
		"center": center,
		"face": 1 if String(raw.get("side", "N")) in ["N", "W"] else -1,
		"low": _side_cell(axis, line, center, false),
		"high": _side_cell(axis, line, center, true),
		"room": StringName(String(raw.get("room", ""))),
	}
	if not _on_plain_wall(axis, line, a, b):
		problems.append("%s : trop près d'un angle ou hors du mur" % label)
		return {}
	return place


## Lignes candidates : between = [pièce, pièce], ou room + side (N : la pièce est au sud de la
## ligne, W : à l'est…).
func _matching_lines(raw: Dictionary, axis: int, a: float, b: float, label: String) -> Array[int]:
	var found: Array[int] = []
	var first := floori(a)
	var last := ceili(b) - 1
	var limit := map_size.y if axis == HORIZONTAL else map_size.x
	var pair := []
	var room := -1
	var side := String(raw.get("side", ""))
	if raw.has("between"):
		var between: Variant = raw["between"]
		if not _is_pair(between) or room_index(between[0]) < 0 or room_index(between[1]) < 0:
			problems.append("%s : between = [pièce, pièce] attendu" % label)
			return found
		pair = [room_index(between[0]), room_index(between[1])]
	else:
		room = room_index(String(raw.get("room", "")))
		var sides := ["N", "S"] if axis == HORIZONTAL else ["W", "E"]
		if room < 0 or not side in sides:
			problems.append("%s : room et side (%s) attendus" % [label, "/".join(sides)])
			return found
	for line in range(0, limit + 1):
		var ok := true
		for k in range(first, last + 1):
			var before := _cell_on(axis, line, k, false)
			var after := _cell_on(axis, line, k, true)
			if pair.is_empty():
				var high_side := side in ["N", "W"]
				ok = ok and (after if high_side else before) == room
				ok = ok and (before if high_side else after) != room
			else:
				ok = ok and before != after and before in pair and after in pair
		if ok:
			found.append(line)
	return found


## Case juste avant (nord, ouest) ou après (sud, est) la ligne, à la case k le long d'elle.
func _cell_on(axis: int, line: int, k: int, after: bool) -> int:
	if axis == HORIZONTAL:
		return cell(k, line if after else line - 1)
	return cell(line if after else line - 1, k)


func _side_cell(axis: int, line: int, center: float, after: bool) -> int:
	return _cell_on(axis, line, floori(center), after)


func _is_wall(axis: int, line: int, k: int) -> bool:
	return h_wall(k, line) if axis == HORIZONTAL else v_wall(line, k)


## Un mur perpendiculaire touche-t-il le point de grille p de la ligne ?
func _corner_at(axis: int, line: int, p: int) -> bool:
	if axis == HORIZONTAL:
		return v_wall(p, line - 1) or v_wall(p, line)
	return h_wall(line - 1, p) or h_wall(line, p)


## L'intervalle [a, b], élargi du demi-mur, est sur un mur continu, sans angle.
func _on_plain_wall(axis: int, line: int, a: float, b: float) -> bool:
	var margin := wall_thickness / 2.0 + CORNER_GAP
	for k in range(floori(a - margin), ceili(b + margin)):
		if not _is_wall(axis, line, k):
			return false
	for p in range(ceili(a - margin), floori(b + margin) + 1):
		if _corner_at(axis, line, p):
			return false
	return true


func _read_light(entry: Variant) -> void:
	if not entry is Dictionary:
		problems.append("lampe : objet attendu")
		return
	var raw := entry as Dictionary
	var label := "lampe %s" % raw.get("room", "?")
	_check_keys(raw, LIGHT_KEYS, label)
	var room := room_index(String(raw.get("room", "")))
	var at: Variant = raw.get("at")
	if room < 0 or not _is_pair(at):
		problems.append("%s : room et at [x, z] attendus" % label)
		return
	var point := Vector2(float(at[0]), float(at[1]))
	if cell(floori(point.x), floori(point.y)) != room:
		problems.append("%s : %s hors de sa pièce" % [label, point])
		return
	var color_text := String(raw.get("color", LAMP_COLOR))
	if not Color.html_is_valid(color_text):
		problems.append("%s : couleur %s" % [label, color_text])
		return
	var radius := float(raw.get("radius", LAMP_RADIUS))
	if radius <= 0.5 or radius > 12.0:
		problems.append("%s : rayon de 0,5 à 12 m" % label)
		return
	(
		lights
		. append(
			{
				"room": room,
				"at": point,
				"radius": radius,
				"color": Color.html(color_text),
				"energy": float(raw.get("energy", 1.0)),
			}
		)
	)


## Deux ouvertures ou éléments d'un même mur ne se chevauchent pas (une porte fermée peut porter
## un élément, non : elle porte son image).
func _check_overlaps() -> void:
	var placed: Array[Dictionary] = []
	placed.append_array(doors)
	placed.append_array(windows)
	placed.append_array(wall_items)
	for i in placed.size():
		for j in range(i + 1, placed.size()):
			var p := placed[i]
			var q := placed[j]
			if int(p["axis"]) != int(q["axis"]) or int(p["line"]) != int(q["line"]):
				continue
			var faces_meet: bool = p.has("height") or q.has("height") or p["face"] == q["face"]
			if faces_meet and float(p["a"]) < float(q["b"]) and float(q["a"]) < float(p["b"]):
				if _vertical_overlap(p, q):
					problems.append(
						(
							"%s et %s se chevauchent sur la ligne %d"
							% [_label(p), _label(q), p["line"]]
						)
					)


func _vertical_overlap(p: Dictionary, q: Dictionary) -> bool:
	var p_range := _heights(p)
	var q_range := _heights(q)
	return p_range.x < q_range.y and q_range.x < p_range.y


func _heights(placed: Dictionary) -> Vector2:
	if placed.has("height"):
		return Vector2(0.0, float(placed["height"]))
	var size := placed["size"] as Vector2
	return Vector2(float(placed["bottom"]), float(placed["bottom"]) + size.y)


static func _label(placed: Dictionary) -> String:
	return String(placed.get("image", "porte")) if not placed.has("height") else "porte"


# --- Morceaux de mur -------------------------------------------------------------------------


func _build_pieces() -> void:
	if not problems.is_empty() and rooms.is_empty():
		return
	for line in range(0, map_size.y + 1):
		_runs(HORIZONTAL, line, map_size.x)
	for line in range(0, map_size.x + 1):
		_runs(VERTICAL, line, map_size.y)


## Murs d'une ligne : suites de bords de mur entre les mêmes deux pièces, prolongées ou
## raccourcies aux angles, trouées par les portes praticables.
func _runs(axis: int, line: int, length: int) -> void:
	var k := 0
	while k < length:
		if not _is_wall(axis, line, k):
			k += 1
			continue
		var low := _cell_on(axis, line, k, false)
		var high := _cell_on(axis, line, k, true)
		var start := k
		while (
			k < length
			and _is_wall(axis, line, k)
			and _cell_on(axis, line, k, false) == low
			and _cell_on(axis, line, k, true) == high
		):
			k += 1
		var span := _run_span(axis, line, start, k)
		_cut_openings(axis, line, span, low, high)


## Étendue d'une suite de bords [start, end) : le mur nord-sud porte le poteau des angles.
func _run_span(axis: int, line: int, start: int, end: int) -> Vector2:
	var half := wall_thickness / 2.0
	if axis == HORIZONTAL:
		var a := start + (half if _corner_at(axis, line, start) else 0.0)
		var b := end - (half if _corner_at(axis, line, end) else 0.0)
		return Vector2(a, b)
	var north := float(start)
	if _corner_at(axis, line, start) and not v_wall(line, start - 1):
		north -= half
	var south := float(end) + (half if _corner_at(axis, line, end) else 0.0)
	return Vector2(north, south)


func _cut_openings(axis: int, line: int, span: Vector2, low: int, high: int) -> void:
	var openings: Array[Dictionary] = []
	for opening: Dictionary in doors:
		if (
			bool(opening["passable"])
			and int(opening["axis"]) == axis
			and int(opening["line"]) == line
			and float(opening["a"]) > span.x
			and float(opening["b"]) < span.y
		):
			openings.append(opening)
	openings.sort_custom(func(p: Dictionary, q: Dictionary) -> bool: return p["a"] < q["a"])
	var from := span.x
	var free_from := false
	for opening: Dictionary in openings:
		_add_piece(axis, line, Vector2(from, float(opening["a"])), 0.0, low, high, free_from, true)
		_add_piece(
			axis,
			line,
			Vector2(float(opening["a"]), float(opening["b"])),
			float(opening["height"]),
			low,
			high,
			false,
			false
		)
		from = float(opening["b"])
		free_from = true
	_add_piece(axis, line, Vector2(from, span.y), 0.0, low, high, free_from, false)


func _add_piece(
	axis: int, line: int, span: Vector2, y0: float, low: int, high: int, free_a: bool, free_b: bool
) -> void:
	if span.y - span.x < 0.001 or y0 >= wall_height:
		return
	(
		pieces
		. append(
			{
				"axis": axis,
				"line": line,
				"a": span.x,
				"b": span.y,
				"y0": y0,
				"y1": wall_height,
				"low": low,
				"high": high,
				"free_a": free_a,
				"free_b": free_b,
			}
		)
	)


## Boîte d'un morceau de mur (repère de la carte).
func piece_box(piece: Dictionary) -> AABB:
	var half := wall_thickness / 2.0
	var line := float(piece["line"])
	var a := float(piece["a"])
	var b := float(piece["b"])
	var y0 := float(piece["y0"])
	var y1 := float(piece["y1"])
	if int(piece["axis"]) == HORIZONTAL:
		return AABB(Vector3(a, y0, line - half), Vector3(b - a, y1 - y0, 2.0 * half))
	return AABB(Vector3(line - half, y0, a), Vector3(2.0 * half, y1 - y0, b - a))
