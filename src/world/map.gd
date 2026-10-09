class_name Map
extends Node3D
## Racine d'une carte (docs/REFONTE.md, section 7.1 ; PLAN.md section 3). Propriétaire : E1.
##
## Une carte par lieu, à la manière d'Octopath Traveler : `src/world/maps/<map_id>/<map_id>.tscn`,
## racine `Map` nommée comme son map_id (snake_case sans accent). WorldManager en charge une
## seule à la fois, sous le nœud « World » de game.tscn ; le joueur, la caméra et l'interface
## restent dans game.tscn.
##
## Repères : origine au coin nord-ouest, x vers l'est, z vers le sud, y vers le haut, 1 unité =
## 1 m ; la carte occupe [0, size.x] × [0, size.y] (area()) ; sol courant à y = 0, paliers par
## pas de 0,5 m. Exception : la carte héritée `ile_ancienne` garde les coordonnées de l'île, centrée
## sur l'origine (island.gd redéfinit area()).
##
## Enfants figés (problems() les vérifie, tests/unit/test_maps.gd pour chaque carte) :
## - Ground : le sol et sa collision (couche 1 world) ; MapGround (E2) dehors, InteriorRoom (E3)
##   dedans ; en attendant, un StaticBody3D plat suffit ;
## - Geometry : le décor (scènes de src/world/props/), script PropBatcher ;
## - Markers : des Marker3D nommés, points d'arrivée ; `Spawn` obligatoire, plus un marqueur par
##   sortie qui mène ici, nommé comme la carte d'où l'on vient (`from_sentier`, ou
##   `from_sentier_<suffixe>` si plusieurs sorties de la même carte mènent ici) ; le joueur est
##   posé au sol sous le marqueur et regarde son −Z ;
## - Exits : des MapExit (src/world/map_exit.gd) ;
## - Life : les PNJ, les animaux et les objets (E4, E5).
## D'autres enfants sont permis (lumière, ciel…) : en attendant les préréglages de E9
## (light_preset), une carte porte sa lumière, par exemple une instance de
## src/world/map_light.tscn.

## Dossier des cartes : une carte = <MAPS_DIR>/<map_id>/<map_id>.tscn.
const MAPS_DIR := "res://src/world/maps"
## Groupe de toutes les cartes dans l'arbre.
const GROUP := &"maps"
## Marqueur obligatoire de chaque carte (arrivée par défaut, nouvelle partie).
const SPAWN_MARKER := &"Spawn"
## Préfixe des marqueurs d'arrivée : `from_<carte d'origine>`.
const FROM_PREFIX := "from_"
## Enfants figés et leur rôle (messages de problems()).
const REQUIRED_CHILDREN: Array[StringName] = [&"Ground", &"Geometry", &"Markers", &"Exits", &"Life"]
## Couche « world » (1) : celle du sol.
const WORLD_LAYER := 1

## Nom affiché à l'entrée de la carte (vide : rien d'annoncé).
@export var display_name: String = ""
## Lieu sur la carte de l'île ; plusieurs cartes peuvent partager un lieu (`entrepot` et
## `entrepot_rdc`).
@export var region: StringName = &""
## Carte intérieure (pièces, étages) : son Ground est une InteriorRoom.
@export var interior: bool = false
## Largeur (x) et profondeur (z) de la carte, en m.
@export var size: Vector2 = Vector2(40.0, 30.0)
## Bornes du point visé par la caméra, en x et z ; vide (taille nulle) : la carte entière.
@export var camera_bounds: Rect2 = Rect2()
## Préréglage de lumière (E9) ; vide : celui du moment de la journée.
@export var light_preset: StringName = &""


func _enter_tree() -> void:
	add_to_group(GROUP)


## Identifiant de la carte : le nom de sa racine.
func map_id() -> StringName:
	return StringName(name)


## Rectangle (x, z) qu'occupe la carte : [0, size.x] × [0, size.y].
func area() -> Rect2:
	return Rect2(Vector2.ZERO, size)


## Bornes du point visé par la caméra (camera_bounds, ou la carte entière s'il est vide).
func bounds() -> Rect2:
	return camera_bounds if camera_bounds.has_area() else area()


## Marqueur d'arrivée par son nom (null s'il n'existe pas).
func marker(marker_name: StringName) -> Marker3D:
	if marker_name.is_empty():
		return null
	return get_node_or_null(NodePath("Markers/" + String(marker_name))) as Marker3D


## Le marqueur obligatoire Spawn (null si la carte est incomplète).
func spawn() -> Marker3D:
	return marker(SPAWN_MARKER)


## Noms des marqueurs d'arrivée.
func marker_names() -> Array[StringName]:
	var names: Array[StringName] = []
	var markers := get_node_or_null(^"Markers")
	if markers != null:
		for child: Node in markers.get_children():
			if child is Marker3D:
				names.append(StringName(child.name))
	return names


## Sorties de la carte (enfants MapExit du nœud Exits).
func exits() -> Array[MapExit]:
	var result: Array[MapExit] = []
	var node := get_node_or_null(^"Exits")
	if node != null:
		for child: Node in node.get_children():
			if child is MapExit:
				result.append(child as MapExit)
	return result


## Chemin de la scène d'une carte.
static func scene_path(id: StringName) -> String:
	return "%s/%s/%s.tscn" % [MAPS_DIR, id, id]


## Vrai si la carte id existe (sa scène est dans MAPS_DIR).
static func exists(id: StringName) -> bool:
	return is_valid_id(id) and ResourceLoader.exists(scene_path(id))


## Identifiant permis : snake_case ASCII sans accent, commençant par une lettre.
static func is_valid_id(id: StringName) -> bool:
	var text := String(id)
	if text.is_empty() or not (text[0] >= "a" and text[0] <= "z"):
		return false
	for character: String in text:
		var ok := (
			(character >= "a" and character <= "z")
			or (character >= "0" and character <= "9")
			or character == "_"
		)
		if not ok:
			return false
	return true


## Identifiants de toutes les cartes de MAPS_DIR (un dossier <id> avec <id>.tscn), triés.
static func all_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	var dir := DirAccess.open(MAPS_DIR)
	if dir == null:
		return ids
	for sub: String in dir.get_directories():
		if exists(StringName(sub)):
			ids.append(StringName(sub))
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return ids


## Problèmes de structure d'une carte (vide : elle suit le contrat), en français. À appeler sur
## une carte prête (dans l'arbre : un MapGround ou une InteriorRoom construit sa collision dans
## son _ready). Les cibles des sorties sont vérifiées par exit_problems().
static func problems(node: Node) -> PackedStringArray:
	var found := PackedStringArray()
	if not node is Map:
		found.append("la racine n'est pas une Map (src/world/map.gd)")
		return found
	var map := node as Map
	if not is_valid_id(map.map_id()):
		found.append("nom de racine « %s » : snake_case sans accent attendu" % map.name)
	if not map.scene_file_path.is_empty() and map.scene_file_path != scene_path(map.map_id()):
		found.append(
			(
				"racine « %s » dans %s : attendu %s"
				% [map.name, map.scene_file_path, scene_path(map.map_id())]
			)
		)
	if map.size.x <= 0.0 or map.size.y <= 0.0:
		found.append("size %s : largeur et profondeur positives attendues" % map.size)
	for child: StringName in REQUIRED_CHILDREN:
		var required := map.get_node_or_null(NodePath(String(child)))
		if not required is Node3D:
			found.append("enfant figé %s absent (ou pas un Node3D)" % child)
	var ground := map.get_node_or_null(^"Ground")
	if ground != null and not _has_world_collision(ground):
		found.append("Ground sans collision sur la couche 1 (world)")
	var geometry := map.get_node_or_null(^"Geometry")
	if geometry != null and not geometry is PropBatcher:
		found.append("Geometry sans le script PropBatcher")
	var markers := map.get_node_or_null(^"Markers")
	if markers != null:
		if map.spawn() == null:
			found.append("marqueur Markers/Spawn absent")
		for child: Node in markers.get_children():
			if not child is Marker3D:
				found.append("Markers/%s n'est pas un Marker3D" % child.name)
			elif not map.area().grow(0.01).has_point(_flat(map, child as Node3D)):
				found.append("Markers/%s hors de la carte %s" % [child.name, map.area()])
	var exit_root := map.get_node_or_null(^"Exits")
	if exit_root != null:
		for child: Node in exit_root.get_children():
			if not child is MapExit:
				found.append("Exits/%s n'est pas une MapExit" % child.name)
			elif (child as MapExit).collision_mask != MapExit.PLAYER_MASK:
				found.append("Exits/%s : masque 2 (player) attendu" % child.name)
	return found


## Problèmes des sorties d'une carte : carte cible existante, marqueur cible présent dans la
## carte cible et nommé `from_<cette carte>` (ou Spawn). target_markers : map_id → noms des
## marqueurs de la carte (lus par l'appelant, qui charge les cartes une fois).
static func exit_problems(map: Map, target_markers: Dictionary) -> PackedStringArray:
	var found := PackedStringArray()
	for exit: MapExit in map.exits():
		var label := "Exits/%s" % exit.name
		if not exists(exit.target_map):
			found.append("%s : carte cible « %s » introuvable" % [label, exit.target_map])
			continue
		var names: Array = target_markers.get(exit.target_map, [])
		if not names.has(exit.target_marker):
			found.append(
				"%s : marqueur %s absent de %s" % [label, exit.target_marker, exit.target_map]
			)
		var from := FROM_PREFIX + String(map.map_id())
		var marker_text := String(exit.target_marker)
		if (
			exit.target_marker != SPAWN_MARKER
			and marker_text != from
			and not marker_text.begins_with(from + "_")
		):
			found.append(
				"%s : marqueur cible %s, attendu %s (ou %s_…)" % [label, marker_text, from, from]
			)
	return found


static func _has_world_collision(node: Node) -> bool:
	if node is CollisionObject3D and (node as CollisionObject3D).collision_layer & WORLD_LAYER:
		return true
	for child: Node in node.get_children():
		if _has_world_collision(child):
			return true
	return false


## Position (x, z) d'un nœud dans le repère de la carte (dans l'arbre ou non).
static func _flat(map: Map, node: Node3D) -> Vector2:
	var xform := Transform3D.IDENTITY
	var current: Node = node
	while current != null and current != map:
		if current is Node3D:
			xform = (current as Node3D).transform * xform
		current = current.get_parent()
	return Vector2(xform.origin.x, xform.origin.z)
