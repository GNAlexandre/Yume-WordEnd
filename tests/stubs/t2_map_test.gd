extends GutTest
## (T2) Base des tests des cartes de l'entrepôt (tests/unit/test_entrepot_rdc.gd,
## test_entrepot_etage.gd, test_entrepot_toit.gd, test_salle_des_armes.gd), dont ils héritent par
## chemin (stub sans class_name). Chaque carte suit son plan de docs/lore/CARTE.md (section 3, bloc
## ```plan, relu ici par read_plan) et les règles du rendu des intérieurs (docs/INTERIEURS.md) :
## - contrat des cartes (Map.problems), exports du plan, aucune lumière portée (Atmosphere, E9) ;
## - tout le plan est là : pièces, portes, fenêtres, éléments de mur, meubles et objets par leur
##   nom d'image, à leur place ; marqueurs, sorties, points nommés (Life/Places) ;
## - circulation : depuis Spawn, à la taille du joueur (grille de 0,25 m), chaque pièce, sortie,
##   marqueur et point est atteint, on ne quitte la carte que par une sortie ; on passe chaque
##   porte, on ne traverse pas les murs ;
## - rien ne cache le joueur, de toute case praticable (caméra du jeu bornée à camera_bounds, coupe
##   d'InteriorRoom) : ni mur ni meuble haut (image de plus de LOW_FURNITURE m) devant ses pieds,
##   sa taille ou sa tête ; un meuble bas (chaise, table, lit : la règle de caméra de CARTE.md 0.3)
##   peut cacher ses pieds, jamais sa taille ni sa tête ; un panneau de premier plan s'efface
##   devant lui (DecorPanel.foreground) ;
## - au plus DRAW_CALL_BUDGET draw calls par vue (un par image et par matière) ;
## - les objets à examiner ont leur texte (data/texts/entrepot.json) et sont à portée d'une case
##   praticable.

const CARTE := "res://docs/lore/CARTE.md"
const TEXTS := "res://data/texts/entrepot.json"
const CAMERA_RIG := preload("res://src/player/camera_rig.tscn")
const NO_CUT := InteriorLayout.NO_CUT
const ASPECT := 16.0 / 9.0
const PLAYER_RADIUS := 0.35
const PLAYER_HEIGHT := 1.5
const GRID := 0.25
## Points du corps du joueur (m au-dessus des pieds) : pieds, taille, tête.
const BODY: Array[float] = [0.25, 0.8, 1.4]
const FEET := 0.25
## Au-delà, un meuble est « haut » : il ne doit rien cacher du joueur (CARTE.md 0.3 : 1,2 m).
const LOW_FURNITURE := 1.21
const OCCLUDER_TOP := 4.9
const OTHER_DRAW_CALLS := 30
const DRAW_CALL_BUDGET := 200
## Portée d'interaction : sphère de 1 m à 0,6 m devant le joueur (src/player/player.tscn).
const REACH := 1.5
## Image des portes qu'on franchit (chambranle à ouverture transparente, docs/INTERIEURS.md).
const PASSABLE_DOOR := "door_frame_wood"
## (C2) Portes qu'on franchit et qui gardent leur image (le rideau de l'arrière-boutique du café, sur une
## cloison nord-sud : vu de chant, il ne cache pas le joueur).
const OWN_IMAGE_DOORS: Array[String] = ["door_backroom"]

## Carte testée (à définir par le test de chaque carte).
var map_id := ""
## Préréglage de lumière attendu (vide : celui du moment ou « interieur » pour un intérieur).
var expected_light_preset := ""
## (C2) Lieu de la carte sur la carte de l'île (`entrepot` par défaut ; `village` pour le café et la maison
## Limashenka) et fichier de ses textes à examiner.
var expected_region := "entrepot"
var texts_path := TEXTS

var _map: Map
var _room: InteriorRoom
var _space: PhysicsDirectSpaceState3D
var _pitch := 32.0
var _fov := 30.0
var _distance := 21.0
var _focus_height := 0.8
var _focus_ahead := 2.5
var _bounds := Rect2()
var _plan: Dictionary = {}
var _reached: Dictionary = {}
var _occluders: Dictionary = {}


func before_all() -> void:
	_plan = read_plan(map_id)
	_map = (load(Map.scene_path(StringName(map_id))) as PackedScene).instantiate() as Map
	add_child(_map)
	await wait_physics_frames(3)
	_room = _map.get_node_or_null(^"Ground") as InteriorRoom
	_space = _map.get_world_3d().direct_space_state
	var rig := CAMERA_RIG.instantiate()
	_pitch = rig.get(&"pitch_deg")
	_fov = rig.get(&"fov_deg")
	_distance = rig.get(&"distance")
	_focus_height = rig.get(&"focus_height")
	_focus_ahead = rig.get(&"focus_ahead")
	rig.free()
	_bounds = _map.bounds()
	_walk()


func after_all() -> void:
	_map.free()


# --- Le plan (CARTE.md) ---------------------------------------------------------------------------


## Bloc ```plan de la carte map_id dans CARTE.md : {size, meta, rooms {id: [Rect2, sol, mur]},
## doors, windows, furniture, walls, objects, exits, markers, points, decors, grounds}.
static func read_plan(id: String) -> Dictionary:
	var plan := {
		"size": Vector2.ZERO,
		"meta": {},
		"rooms": {},
		"doors": [],
		"windows": [],
		"furniture": [],
		"walls": [],
		"objects": [],
		"exits": [],
		"markers": {},
		"points": {},
		"decors": [],
		"grounds": [],
	}
	var inside := false
	var current := ""
	for raw: String in FileAccess.get_file_as_string(CARTE).split("\n"):
		var line := raw.strip_edges()
		if line.begins_with("```"):
			inside = line == "```plan" and not inside
			continue
		if not inside or line.is_empty() or line.begins_with("#"):
			continue
		var t := tokens(line.split("#")[0].strip_edges() if not line.contains('"') else line)
		if t[0] == "carte":
			current = t[1]
			if current == id:
				plan["size"] = Vector2(float(t[2]), float(t[3]))
			continue
		if current != id:
			continue
		_read_instruction(plan, t)
	return plan


static func _read_instruction(plan: Dictionary, t: PackedStringArray) -> void:
	match t[0]:
		"nom", "region":
			plan["meta"][t[0]] = t[1]
		"piece":
			var r := Rect2(
				float(t[2]), float(t[3]), float(t[4]) - float(t[2]), float(t[5]) - float(t[3])
			)
			plan["rooms"][t[1]] = [r, t[6], t[7]]
		"porte", "ouverture":
			var door := {
				"kind": t[0], "a": t[1], "b": t[2], "at": Vector2(float(t[3]), float(t[4]))
			}
			door["l"] = float(t[5])
			door["image"] = t[6] if t.size() > 6 else ""
			plan["doors"].append(door)
		"fenetre":
			plan["windows"].append(
				{"room": t[1], "side": t[2], "pos": float(t[3]), "image": t[4], "l": float(t[5])}
			)
		"meuble":
			var count := 1
			var free := false
			var regard := ""
			for flag: String in t.slice(7):
				free = free or flag == "libre"
				if flag.begins_with("x") and flag.substr(1).is_valid_int():
					count = int(flag.substr(1))
				if flag.begins_with("regard="):
					regard = flag.substr("regard=".length())
			var x := float(t[2])
			var l := float(t[4])
			for k in count:
				(
					plan["furniture"]
					. append(
						{
							"image": t[1],
							"x": x - l / 2.0 + l / count * (k + 0.5),
							"z": float(t[3]),
							"l": l / count,
							"p": float(t[5]),
							"h": float(t[6]),
							"free": free,
							"regard": regard,
						}
					)
				)
		"mural":
			plan["walls"].append(
				{
					"image": t[1],
					"room": t[2],
					"side": t[3],
					"pos": float(t[4]),
					"bottom": float(t[5])
				}
			)
		"objet":
			plan["objects"].append({"image": t[1], "at": Vector2(float(t[2]), float(t[3]))})
		"sortie":
			var r := Rect2(
				float(t[2]), float(t[3]), float(t[4]) - float(t[2]), float(t[5]) - float(t[3])
			)
			(
				plan["exits"]
				. append(
					{
						"name": t[1],
						"rect": r,
						"target": t[6],
						"marker": t[7],
						"prompt": t[8] if t.size() > 8 else "",
					}
				)
			)
		"marqueur":
			plan["markers"][t[1]] = [Vector2(float(t[2]), float(t[3])), t[4]]
		"point":
			plan["points"][t[1]] = Vector2(float(t[2]), float(t[3]))
		"decor":
			plan["decors"].append({"image": t[1], "at": Vector2(float(t[2]), float(t[3]))})
		"sol":
			plan["grounds"].append(
				{
					"image": t[1],
					"rect":
					Rect2(
						float(t[2]),
						float(t[3]),
						float(t[4]) - float(t[2]),
						float(t[5]) - float(t[3])
					)
				}
			)


## Mots d'une ligne de plan ; « "…" » forme un seul mot (sans les guillemets).
static func tokens(line: String) -> PackedStringArray:
	var out := PackedStringArray()
	var word := ""
	var quoted := false
	var started := false
	for character: String in line:
		if character == '"':
			quoted = not quoted
			started = true
		elif character == " " and not quoted:
			if started:
				out.append(word)
			word = ""
			started = false
		else:
			word += character
			started = true
	if started:
		out.append(word)
	return out


# --- Outils --------------------------------------------------------------------------------------


static func flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)


func cell_of(at: Vector3) -> Vector2i:
	return Vector2i(floori(at.x / GRID), floori(at.z / GRID))


func center(cell: Vector2i) -> Vector3:
	return Vector3((cell.x + 0.5) * GRID, 0.0, (cell.y + 0.5) * GRID)


## Image (nom de fichier sans extension) d'un décor posé dans la carte.
static func image_of(node: Node) -> String:
	var texture: Texture2D = null
	if node is DecorPanel:
		texture = (node as DecorPanel).texture
	elif node is GroundDecal:
		texture = (node as GroundDecal).texture
	return texture.resource_path.get_file().get_basename() if texture != null else ""


## Décors posés (panneaux et décalques) : [nœud, image].
func decors() -> Array:
	var out := []
	var geometry := _map.get_node(^"Geometry")
	for node: Node in geometry.find_children("*", "Node3D", true, false):
		if node is DecorPanel or node is GroundDecal:
			out.append([node, image_of(node)])
	return out


## Vrai si le joueur (sa capsule) ne tient pas en at : un mur, un meuble, une rambarde.
func blocked(at: Vector3) -> bool:
	var capsule := CapsuleShape3D.new()
	capsule.radius = PLAYER_RADIUS
	capsule.height = PLAYER_HEIGHT
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = 1
	query.transform = Transform3D(Basis.IDENTITY, at + Vector3.UP * (PLAYER_HEIGHT / 2.0 + 0.05))
	return not _space.intersect_shape(query, 1).is_empty()


## Vrai si at est dans une sortie qu'on franchit en marchant (prompt vide).
func leaves(at: Vector3) -> bool:
	for exit: MapExit in _map.exits():
		if not exit.needs_interaction() and in_exit(exit, at):
			return true
	return false


func in_exit(exit: MapExit, at: Vector3, margin: float = 0.0) -> bool:
	var shape := exit.get_child(0) as CollisionShape3D
	var box := (shape.shape as BoxShape3D).size + Vector3(margin, 0.0, margin) * 2.0
	var local := shape.global_transform.affine_inverse() * (at + Vector3.UP)
	return AABB(-box / 2.0, box).has_point(local)


## Cases atteintes à pied depuis Spawn (on s'arrête dans une sortie à pied).
func _walk() -> void:
	var start := cell_of(_map.spawn().global_position)
	var limit := Vector2i((_map.size / GRID).ceil())
	var queue: Array[Vector2i] = [start]
	_reached[start] = true
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_back()
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := cell + step
			if next.x < -4 or next.y < -4 or next.x >= limit.x + 4 or next.y >= limit.y + 4:
				continue
			if _reached.has(next) or blocked(center(next)):
				continue
			_reached[next] = true
			if not leaves(center(next)):
				queue.append(next)


## Une case atteinte à moins de distance m de at ?
func reached_near(at: Vector2, distance: float) -> bool:
	for cell: Vector2i in _reached:
		if flat(center(cell)).distance_to(at) <= distance:
			return true
	return false


# --- Structure et plan ---------------------------------------------------------------------------


func check_contract() -> void:
	assert_not_null(_map, "racine Map")
	assert_eq(_map.map_id(), StringName(map_id), "racine nommée comme son map_id")
	assert_eq(Map.problems(_map), PackedStringArray(), "contrat des cartes")
	assert_eq(_map.display_name, String(_plan["meta"].get("nom", "")), "nom du plan")
	assert_eq(_map.region, StringName(expected_region), "lieu de la carte")
	assert_eq(_map.size, _plan["size"] as Vector2, "taille du plan")
	assert_true(_map.area().encloses(_map.bounds()), "bornes de la caméra dans la carte")
	assert_eq(_map.light_preset, StringName(expected_light_preset), "préréglage de lumière")
	assert_null(_map.get_node_or_null(^"Light"), "aucune lumière portée : Atmosphere (E9)")
	# Aucune lumière du moteur posée par la carte (celles d'Atmosphere, AtmosphereRig, à part).
	var lights: Array[String] = []
	for light: Node in _map.find_children("*", "Light3D", true, false):
		if not _map.get_path_to(light).get_concatenated_names().begins_with(
			String(AtmosphereRig.NODE_NAME)
		):
			lights.append(String(_map.get_path_to(light)))
	assert_eq(lights, [] as Array[String], "pas de lumière du moteur")
	var places := _map.get_node_or_null(^"Life/Places")
	assert_not_null(places, "Life/Places")


func check_rooms_and_openings() -> void:
	var plan := _room.plan
	assert_eq(plan.problems, [] as Array[String], "agencement sans faute")
	assert_eq(Vector2(plan.map_size), _plan["size"] as Vector2, "taille de interior.json")
	var rooms: Dictionary = _plan["rooms"]
	assert_eq(plan.rooms.size(), rooms.size(), "toutes les pièces du plan")
	for item: Dictionary in plan.rooms:
		var spec: Array = rooms.get(String(item["id"]), [])
		assert_false(spec.is_empty(), "%s : pièce du plan" % item["id"])
		if spec.is_empty():
			continue
		assert_eq((item["rects"] as Array)[0], spec[0] as Rect2, "%s : cotes du plan" % item["id"])
		assert_eq(item["floor"], spec[1], "%s : sol" % item["id"])
		assert_eq(item["wall"], spec[2], "%s : murs" % item["id"])
	# Une ouverture par porte du plan, sur sa ligne, centrée à 5 cm près, au moins aussi large que
	# le chambranle (ouvertures de toute une largeur : montants de 0,2 m aux angles).
	assert_eq(plan.doors.size(), (_plan["doors"] as Array).size(), "toutes les portes du plan")
	for door: Dictionary in _plan["doors"]:
		var found := _opening_at(door["at"] as Vector2)
		assert_false(found.is_empty(), "porte %s|%s en %s" % [door["a"], door["b"], door["at"]])
		if found.is_empty():
			continue
		assert_gte(
			float(found["width"]),
			minf(float(door["l"]), 1.1),
			"%s|%s : largeur" % [door["a"], door["b"]]
		)
		assert_true(float(found["width"]) >= float(door["l"]) - 0.41, "au plus 0,4 m de montants")
		var outside := String(door["a"]) == "dehors" or String(door["b"]) == "dehors"
		if outside:
			assert_eq(found["image"], door["image"], "porte du dehors : image du plan")
		elif String(door["kind"]) == "porte":
			var wanted: String = (
				String(door["image"])
				if OWN_IMAGE_DOORS.has(String(door["image"]))
				else PASSABLE_DOOR
			)
			assert_eq(found["image"], wanted, "porte qu'on franchit : chambranle ou image propre")
	for window: Dictionary in _plan["windows"]:
		assert_true(_panel_on_wall(plan.windows, window), "fenêtre %s" % window["image"])
	for wall: Dictionary in _plan["walls"]:
		if String(wall["image"]).begins_with("wallitem_"):
			assert_true(_panel_on_wall(plan.wall_items, wall, 0.06), "élément %s" % wall["image"])


func _opening_at(at: Vector2) -> Dictionary:
	for opening: Dictionary in _room.plan.doors:
		var c := InteriorLayout.opening_center(opening)
		if Vector2(c.x, c.z).distance_to(at) < 0.06:
			return opening
	return {}


func _panel_on_wall(placed: Array[Dictionary], spec: Dictionary, tolerance: float = 0.001) -> bool:
	for item: Dictionary in placed:
		if item["image"] != spec["image"] or String(item["room"]) != String(spec["room"]):
			continue
		if absf(float(item["center"]) - float(spec["pos"])) <= tolerance:
			if spec.has("bottom") and absf(float(item["bottom"]) - float(spec["bottom"])) > 0.001:
				continue
			return true
	return false


## (I1) Image de la vue <image>_<vue> d'un meuble : son chemin si elle existe (importée), sinon "".
static func view_path(image: String, view: String) -> String:
	for folder: String in ["res://assets/hd2d/interior/props/", "res://assets/hd2d/interior/"]:
		var path := "%s%s_%s.png" % [folder, image, view]
		if ResourceLoader.exists(path):
			return path
	return ""


## (I1) Un meuble de regard E ou O (ou N : un lit vu par le pied) est tourné d'un quart de tour
## autour du milieu de son bord arrière (le mur) quand l'image de sa vue de flanc (ou de pied)
## existe, et garde sa face et son emprise de face sans elle. Vrai si celle de ce meuble existe.
static func is_turned(item: Dictionary) -> bool:
	var regard := String(item.get("regard", ""))
	var image := String(item["image"])
	if regard in ["E", "O"]:
		return not view_path(image, "side").is_empty()
	return (
		regard == "N"
		and view_path(image, "back").is_empty()
		and not view_path(image, "foot").is_empty()
	)


## Chaque meuble du plan (rangées dépliées) est posé à sa place, par son image, à 1 cm près : un
## meuble (InteriorPanel) a son image au bord sud de l'emprise du plan, en son milieu ; un
## décalque ou un panneau suspendu, au centre de l'emprise ; un tapis de couloir, bout à bout sur
## sa longueur ; chaque objet posé, au-dessus de sa place. (I1) Un meuble tourné vers sa vue : son
## nœud au milieu de l'emprise tournée, collée au mur, l'image au bord sud de sa largeur de face ;
## un meuble de regard marqué porte son orientation (facing) et montre la vue qui existe.
func check_furniture(skip: Array[String] = []) -> void:
	var placed := decors()
	var unused := placed.duplicate()
	var missing: Array[String] = []
	for item: Dictionary in _plan["furniture"]:
		var image := String(item["image"])
		if image in skip:
			continue
		var at := Vector2(float(item["x"]), float(item["z"]))
		var found := false
		for entry: Array in unused:
			if entry[1] != image:
				continue
			var node := entry[0] as Node3D
			var where := _map.to_local(node.global_position)
			var close := Vector2(where.x, where.z).distance_to(at) < 0.011
			if node is InteriorPanel:
				# Un meuble : son image au bord sud de l'emprise du plan.
				var front := where.z + (node as InteriorPanel).image_offset.z
				var plan_front := at.y + float(item["p"]) / 2.0
				close = absf(where.x - at.x) < 0.011 and absf(front - plan_front) < 0.011
				if is_turned(item):
					close = _turned_in_place(node as InteriorPanel, item, where)
			if image == "runner_rug":
				close = (
					absf(where.z - at.y) < 0.011 and absf(where.x - at.x) <= float(item["l"]) / 2.0
				)
			if close:
				found = true
				unused.erase(entry)
				break
		if not found:
			missing.append("%s %s" % [image, at])
	assert_eq(missing, [] as Array[String], "meubles du plan absents ou déplacés")
	for obj: Dictionary in _plan["objects"]:
		var at: Vector2 = obj["at"]
		var found := false
		for entry: Array in placed:
			var where := _map.to_local((entry[0] as Node3D).global_position)
			if entry[1] == obj["image"] and absf(where.x - at.x) < 0.011 and where.z >= at.y - 0.01:
				found = found or where.z - at.y < 1.2
		assert_true(found, "objet %s posé en %s" % [obj["image"], at])


## (I1) Meuble tourné : emprise tournée collée au mur (bord arrière du plan), centrée sur le plan en
## z, image au bord sud de sa largeur de face ; orientation et vue conformes à son regard.
func _turned_in_place(panel: InteriorPanel, item: Dictionary, where: Vector3) -> bool:
	var regard := String(item["regard"])
	var shape := panel.get_node(^"Collision").get_child(0) as CollisionShape3D
	var depth := (shape.shape as BoxShape3D).size.z
	var width := float(item["l"])
	var back_x := float(item["x"]) - width / 2.0
	var expected_x := back_x + depth / 2.0
	var expected_z := float(item["z"])
	if regard == "O":
		expected_x = float(item["x"]) + width / 2.0 - depth / 2.0
	if regard == "N":
		expected_x = float(item["x"])
		expected_z = float(item["z"]) - float(item["p"]) / 2.0 + width / 2.0
	var front := where.z + panel.image_offset.z
	var wanted_facing: StringName = {"E": &"east", "O": &"west", "N": &"north"}[regard]
	var facing_ok := panel.facing == wanted_facing
	var view_ok := panel.view_name() == (&"foot" if regard == "N" else &"side")
	var flip_ok := panel.view_flipped() == (regard == "O")
	return (
		absf(where.x - expected_x) < 0.011
		and absf(where.z - expected_z) < 0.011
		and absf(front - (expected_z + width / 2.0)) < 0.011
		and facing_ok
		and view_ok
		and (flip_ok or regard == "N")
	)


func check_markers_exits_points() -> void:
	for marker_name: String in _plan["markers"]:
		var spec: Array = _plan["markers"][marker_name]
		var marker := _map.marker(StringName(marker_name))
		assert_not_null(marker, "marqueur %s" % marker_name)
		if marker == null:
			continue
		assert_almost_eq(flat(marker.position), spec[0] as Vector2, Vector2.ONE * 0.01, marker_name)
		var facing := -marker.global_basis.z
		var expected := (
			{"N": Vector3.FORWARD, "S": Vector3.BACK, "E": Vector3.RIGHT, "O": Vector3.LEFT}[spec[1]]
			as Vector3
		)
		assert_almost_eq(
			facing, expected, Vector3.ONE * 0.01, "%s regarde %s" % [marker_name, spec[1]]
		)
	assert_eq(_map.exits().size(), (_plan["exits"] as Array).size(), "toutes les sorties du plan")
	for spec: Dictionary in _plan["exits"]:
		var exit := _map.get_node_or_null(NodePath("Exits/" + String(spec["name"]))) as MapExit
		assert_not_null(exit, "sortie %s" % spec["name"])
		if exit == null:
			continue
		var rect: Rect2 = spec["rect"]
		var middle := Vector3(rect.get_center().x, 0.0, rect.get_center().y)
		assert_true(in_exit(exit, middle), "%s couvre sa zone du plan" % spec["name"])
		assert_eq(exit.prompt, String(spec["prompt"]), "%s : invite" % spec["name"])
		var target := String(spec["target"])
		if Map.exists(StringName(target)):
			assert_eq(exit.target_map, StringName(target), "%s : cible du plan" % spec["name"])
			assert_eq(
				exit.target_marker, StringName(spec["marker"]), "%s : marqueur" % spec["name"]
			)
		else:
			assert_true(
				Map.exists(exit.target_map), "%s : cible provisoire qui existe" % spec["name"]
			)
	var places := _map.get_node(^"Life/Places")
	for point_name: String in _plan["points"]:
		var place := places.get_node_or_null(NodePath(point_name)) as Marker3D
		assert_not_null(place, "place %s" % point_name)
		if place != null:
			assert_almost_eq(
				flat(place.position), _plan["points"][point_name] as Vector2, Vector2.ONE * 0.01
			)


# --- Circulation ---------------------------------------------------------------------------------


func check_reach() -> void:
	gut.p("%s : %d cases praticables" % [map_id, _reached.size()])
	if _room != null:
		var rooms := {}
		for cell: Vector2i in _reached:
			var room := _room.plan.room_at(center(cell))
			if not room.is_empty():
				rooms[room] = true
		for item: Dictionary in _room.plan.rooms:
			assert_true(rooms.has(item["id"]), "%s atteinte à pied" % item["id"])
	for marker_name: String in _plan["markers"]:
		var at: Vector2 = (_plan["markers"][marker_name] as Array)[0]
		assert_true(reached_near(at, 0.3), "marqueur %s atteint" % marker_name)
	for point_name: String in _plan["points"]:
		assert_true(
			reached_near(_plan["points"][point_name] as Vector2, 0.6), "point %s" % point_name
		)
	for exit: MapExit in _map.exits():
		var found := false
		for cell: Vector2i in _reached:
			if in_exit(exit, center(cell), 0.0 if not exit.needs_interaction() else 0.9):
				found = true
				break
		assert_true(found, "sortie %s à portée" % exit.name)
	var outside: Array[String] = []
	for cell: Vector2i in _reached:
		var at := center(cell)
		if leaves(at) or not off_limits(at):
			continue
		if outside.size() < 5:
			outside.append(str(flat(at)))
	assert_eq(outside, [] as Array[String], "hors de la carte seulement par une sortie")


## Vrai si at n'est pas un endroit où l'on doit pouvoir se tenir : hors de la carte, hors des
## pièces (dedans), hors de la terrasse (sol plus bas, dehors).
func off_limits(at: Vector3) -> bool:
	if not _map.area().has_point(flat(at)):
		return true
	if _room != null:
		return _room.plan.room_at(at).is_empty()
	var ground := _map.get_node(^"Ground") as MapGround
	return ground != null and absf(ground.height_at(at.x, at.z)) > 0.3


## Un corps qui marche passe chaque porte praticable et bute de part et d'autre (le mur).
func check_doors_pass() -> void:
	var body := CharacterBody3D.new()
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = PLAYER_RADIUS
	capsule.height = PLAYER_HEIGHT
	shape.shape = capsule
	shape.position.y = PLAYER_HEIGHT / 2.0 + 0.05
	body.add_child(shape)
	body.collision_layer = 2
	body.collision_mask = 1
	_map.add_child(body)
	for opening: Dictionary in _room.plan.doors:
		var c := InteriorLayout.opening_center(opening)
		var horizontal := int(opening["axis"]) == InteriorLayout.HORIZONTAL
		var across := Vector3(0, 0, 1) if horizontal else Vector3(1, 0, 0)
		var along := Vector3(1, 0, 0) if horizontal else Vector3(0, 0, 1)
		var label := (
			"porte %s" % [opening.get("id", "")] if opening["id"] != &"" else "porte en %s" % c
		)
		var start := c - across * 0.6
		body.global_position = _map.to_global(start)
		var through := body.test_move(body.global_transform, across * 1.2)
		var wall := blocked(c + along * (float(opening["width"]) / 2.0 + 0.4))
		wall = wall and blocked(c - along * (float(opening["width"]) / 2.0 + 0.4))
		if bool(opening["passable"]):
			assert_false(through, "%s : on la franchit" % label)
			assert_true(wall, "%s : le mur de part et d'autre" % label)
		else:
			assert_true(through, "%s : fermée" % label)
	body.free()


# --- Rien ne cache le joueur ---------------------------------------------------------------------


## Caméra du jeu quand le joueur se tient en feet (repère de la carte) : point visé borné.
func camera(feet: Vector3) -> Transform3D:
	var tilt := Basis(Vector3.RIGHT, deg_to_rad(-_pitch))
	var focus := feet + Vector3(0.0, _focus_height, -_focus_ahead)
	focus.x = clampf(focus.x, _bounds.position.x, _bounds.end.x)
	focus.z = clampf(focus.z, _bounds.position.y, _bounds.end.y)
	return Transform3D(tilt, focus + tilt.z * _distance)


func check_nothing_hides_the_player() -> void:
	var hidden: Array[String] = []
	var checked := 0
	for cell: Vector2i in _reached:
		var feet := center(cell)
		if leaves(feet):
			continue
		var cut := _room.plan.cut_line_at(feet) if _room != null else NO_CUT
		var eye := _map.to_global(camera(feet).origin)
		var buckets := _buckets_for(feet, cut)
		for height: float in BODY:
			checked += 1
			var target := _map.to_global(feet + Vector3.UP * height)
			var hit := first_hit(eye, target, buckets, height <= FEET)
			# Des pieds déjà derrière un meuble bas ne sont pas cachés par ce qui est plus loin.
			if (
				height <= FEET
				and not hit.is_empty()
				and not first_low_hit(eye, target, buckets).is_empty()
			):
				hit = ""
			if not hit.is_empty():
				if hidden.size() < 4000:
					hidden.append("%s à %.2f m : %s" % [flat(feet), height, hit])
				break
	gut.p("%s : %d rayons" % [map_id, checked])
	for line: String in hidden:
		gut.p("  caché : %s" % line)
	assert_gt(checked, 300, "toutes les cases praticables")
	assert_eq(hidden, [] as Array[String], "joueur caché")


## Premier obstacle entre eye et target : « mur », « meuble <nom> » ; un meuble bas ne compte
## pas pour les pieds (feet vrai).
func first_hit(eye: Vector3, target: Vector3, buckets: Dictionary, feet: bool) -> String:
	var t0 := clampf((eye.y - OCCLUDER_TOP) / maxf(eye.y - target.y, 0.001), 0.0, 1.0)
	var from := eye.lerp(target, t0)
	var lo := Vector2i(floori(minf(from.x, target.x)), floori(minf(from.z, target.z)))
	var hi := Vector2i(floori(maxf(from.x, target.x)), floori(maxf(from.z, target.z)))
	for x in range(lo.x, hi.x + 1):
		for z in range(lo.y, hi.y + 1):
			for entry: Array in buckets.get(Vector2i(x, z), []):
				if feet and bool(entry[2]):
					continue
				var tri: PackedVector3Array = entry[1]
				for i in range(0, tri.size(), 3):
					if Geometry3D.segment_intersects_triangle(
						from, target, tri[i], tri[i + 1], tri[i + 2]
					):
						return String(entry[0])
	return ""


## Premier meuble bas (image, ou ce qu'en garde la coupe, sous LOW_FURNITURE) entre eye et target.
func first_low_hit(eye: Vector3, target: Vector3, buckets: Dictionary) -> String:
	var low := {}
	for key: Vector2i in buckets:
		for entry: Array in buckets[key]:
			if bool(entry[2]):
				if not low.has(key):
					low[key] = []
				(low[key] as Array).append([entry[0], entry[1], false])
	return first_hit(eye, target, low, false)


func _buckets_for(feet: Vector3, cut: float) -> Dictionary:
	if _room == null:
		return _buckets(cut)
	var furniture_z := _map.to_global(feet).z
	var line := roundf(feet.x / InteriorLayout.GRID) * InteriorLayout.GRID
	if absf(feet.x - line) >= InteriorRoom.COLUMN_HALF:
		return _buckets(cut, Vector3.INF, furniture_z)
	for piece: Dictionary in _room.plan.pieces:
		if (
			int(piece["axis"]) == InteriorLayout.VERTICAL
			and is_equal_approx(float(piece["line"]), line)
		):
			return _buckets(cut, feet, furniture_z)
	return _buckets(cut, Vector3.INF, furniture_z)


## Triangles qui peuvent cacher le joueur pour une coupe (murs, meubles, panneaux du dehors qui ne
## s'effacent pas), rangés par case d'un mètre ; [nom, triangles, bas].
func _buckets(cut: float, player: Vector3 = Vector3.INF, furniture_z: float = NO_CUT) -> Dictionary:
	# La coupe des meubles suit le z du joueur, même loin d'une cloison.
	InteriorRoom.share_uniform(&"furniture_cut_line", furniture_z)
	var key := Vector2(cut, furniture_z)
	if not player.is_finite() and _occluders.has(key):
		return _occluders[key]
	var buckets := {}
	var cut_world := NO_CUT if cut >= NO_CUT else _map.to_global(Vector3(0.0, 0.0, cut)).z
	if _room != null:
		var at := _map.to_global(player) if player.is_finite() else Vector3.INF
		var walls := _room.occluder_triangles(cut_world, at)
		for i in range(0, walls.size(), 3):
			_bucket(buckets, "mur", walls.slice(i, i + 3), false)
	for entry: Array in decors():
		var node: Node = entry[0]
		if node is InteriorPanel:
			var panel := node as InteriorPanel
			var quad := panel.occluder_triangles(cut_world)
			_bucket(buckets, "meuble %s" % panel.name, quad, _height(quad) <= LOW_FURNITURE)
		elif node is DecorPanel:
			var decor := node as DecorPanel
			if decor.foreground or decor.soft_alpha:
				continue
			_bucket(
				buckets,
				"décor %s" % decor.name,
				_decor_triangles(decor),
				decor.size_m().y <= LOW_FURNITURE
			)
	if not player.is_finite():
		_occluders[key] = buckets
	return buckets


## Hauteur dessinée d'un rectangle (triangles) : ce que la coupe en garde.
static func _height(tri: PackedVector3Array) -> float:
	var lo := INF
	var hi := -INF
	for point in tri:
		lo = minf(lo, point.y)
		hi = maxf(hi, point.y)
	return hi - lo


## Rectangle de l'image d'un panneau du dehors (tourné vers le sud, ou selon son nœud).
static func _decor_triangles(decor: DecorPanel) -> PackedVector3Array:
	var size := decor.size_m()
	var base := decor.global_position + decor.image_offset
	var right := decor.global_basis.x.normalized() if decor.keep_orientation else Vector3.RIGHT
	var left := base - right * size.x / 2.0
	var right_end := base + right * size.x / 2.0
	var up := Vector3.UP * size.y
	return PackedVector3Array([left, right_end, right_end + up, left, right_end + up, left + up])


func _bucket(buckets: Dictionary, label: String, tri: PackedVector3Array, low: bool) -> void:
	if tri.is_empty():
		return
	var box := AABB(tri[0], Vector3.ZERO)
	for point in tri:
		box = box.expand(point)
	for x in range(floori(box.position.x), floori(box.end.x) + 1):
		for z in range(floori(box.position.z), floori(box.end.z) + 1):
			var key := Vector2i(x, z)
			if not buckets.has(key):
				buckets[key] = []
			(buckets[key] as Array).append([label, tri, low])


# --- Draw calls ----------------------------------------------------------------------------------


func _project(cam: Transform3D, point: Vector3) -> Vector3:
	var local := cam.affine_inverse() * point
	var depth := -local.z
	if depth <= 0.05:
		return Vector3(INF, INF, depth)
	var half := tan(deg_to_rad(_fov) / 2.0)
	return Vector3(local.x / (depth * half * ASPECT), local.y / (depth * half), depth)


func _box_on_screen(cam: Transform3D, box: AABB) -> bool:
	var outside := [0, 0, 0, 0]
	for i in 8:
		var p := _project(cam, box.get_endpoint(i))
		if p.z <= 0.05:
			return true
		outside[0] += 1 if p.x < -1.0 else 0
		outside[1] += 1 if p.x > 1.0 else 0
		outside[2] += 1 if p.y < -1.0 else 0
		outside[3] += 1 if p.y > 1.0 else 0
	return not outside.has(8)


## Draw calls de la carte vus de chaque case (un sur quatre) : meshes visibles dans le champ, plus
## OTHER_DRAW_CALLS (personnages, interface, post-traitement). Renvoie le pire.
func check_draw_calls() -> int:
	var meshes: Array[MeshInstance3D] = []
	_all_meshes(_map, meshes)
	var worst := 0
	var worst_at := Vector2.ZERO
	var count := 0
	for cell: Vector2i in _reached:
		count += 1
		if count % 4 != 0:
			continue
		var cam := (
			Transform3D(_map.global_transform.basis, _map.global_position) * camera(center(cell))
		)
		var drawn := 0
		for mesh in meshes:
			if _box_on_screen(cam, mesh.global_transform * mesh.get_aabb()):
				drawn += 1
		if drawn > worst:
			worst = drawn
			worst_at = flat(center(cell))
	gut.p(
		(
			"%s : %d meshes, au pire %d dans le champ (en %s)"
			% [map_id, meshes.size(), worst, worst_at]
		)
	)
	assert_lte(worst + OTHER_DRAW_CALLS, DRAW_CALL_BUDGET, "draw calls par vue")
	return worst


## Meshes dessinés de la carte (enfants internes compris : sol, murs, bâtiments, lots fondus).
static func _all_meshes(node: Node, out: Array[MeshInstance3D]) -> void:
	for child: Node in node.get_children(true):
		var mesh := child as MeshInstance3D
		if mesh != null and mesh.mesh != null and mesh.is_visible_in_tree():
			out.append(mesh)
		_all_meshes(child, out)


# --- Objets à examiner ---------------------------------------------------------------------------


func check_examinables(expected: int) -> void:
	var root := _map.get_node_or_null(^"Examine")
	var found := root.get_children() if root != null else []
	assert_eq(found.size(), expected, "objets à examiner")
	var json := JSON.new()
	assert_eq(json.parse(FileAccess.get_file_as_string(texts_path)), OK, "%s lisible" % texts_path)
	assert_eq(DialogueRunner.story_problem(json.data), "", "format des textes de l'histoire")
	for node: Node in found:
		var item := node as Examinable
		assert_not_null(item, "%s : Examinable" % node.name)
		if item == null:
			continue
		assert_true(item.text_key.begins_with(map_id + "/"), "%s : texte de la carte" % node.name)
		assert_false(item.text_value().is_empty(), "%s : texte %s" % [node.name, item.text_key])
		assert_eq(item.get_prompt(), "Examiner")
		assert_true(item.is_in_group(&"interactable"), "%s : interactable" % node.name)
		assert_true(
			reached_near(flat(item.global_position), REACH + maxf(item.size.x, item.size.z) / 2.0),
			"%s : à portée d'une case praticable" % node.name
		)
