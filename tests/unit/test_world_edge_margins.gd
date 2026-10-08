extends GutTest
## (B1) Rien ne tombe dans le vide : tout ce que les zones et les fichiers d'emplacement posent sur
## l'île (island.tscn complète) reste en deçà du bord (docs/lore/MONDE.md, section 2.8), à la
## distance exacte du tracé du bord (IslandTerrain.distance_to_edge) :
##
## - décor (scène de src/world/props/) : son ancre à 1 m au moins du vide ; s'il bloque (collision
##   de la couche world), toute sa collision à 3 m au moins ;
## - PNJ, objets, Timeres libres, points d'apparition des zones (Spawn, SpawnN…) : 3 m au moins ;
## - déclencheurs de quête : centre à 3 m au moins, disque entier à 1 m au moins.
##
## Le mobilier du bord (EDGE_PROPS : lèvre, parapets, garde-corps, bittes et bras d'amarrage,
## passerelle, navires, rochers flottants) est fait pour être au bord ou au-delà : il est exempté.
## Les lots de pose s'en servent pour vérifier leurs zones après la fusion ; un message liste
## chaque écart (chemin, distance, angle du bord le plus proche).

const ISLAND := preload("res://src/world/island.tscn")
const PLACEMENTS: Array[NodePath] = [^"NPCs", ^"Enemies", ^"Pickups"]
## Préfixes des décors faits pour le bord (nom du fichier de src/world/props/).
const EDGE_PROPS: Array[String] = [
	"edge_",
	"airship_",
	"gangway",
	"mooring_",
	"bollard",
	"floating_rock",
	"distant_island",
]
## Marges (m) : ancre d'un décor, ce qui bloque, déclencheur (disque).
const DECOR_MARGIN := 1.0
const BLOCKING_MARGIN := 3.0
const TRIGGER_DISC_MARGIN := 1.0
const WORLD_LAYER := 1

var _island: Node3D


func before_all() -> void:
	_island = ISLAND.instantiate() as Node3D
	add_child(_island)
	await wait_physics_frames(2)


func after_all() -> void:
	_island.free()


func test_decor_stays_clear_of_the_void() -> void:
	var problems: Array[String] = []
	var count := 0
	for zone: Node in _island.get_node(^"Zones").get_children():
		for prop: Node3D in _props(zone.get_node(^"Geometry")):
			var id := prop.scene_file_path.get_file().get_basename()
			if _is_edge_prop(id):
				continue
			count += 1
			var label := "%s %s (%s)" % [zone.name, zone.get_path_to(prop), id]
			var at := prop.global_position
			_check(problems, label + " : ancre", Vector2(at.x, at.z), DECOR_MARGIN)
			for corner: Vector2 in _collision_corners(prop):
				if _check(problems, label + " : collision", corner, BLOCKING_MARGIN):
					break
	assert_gt(count, 100, "décors de l'île parcourus")
	assert_true(problems.is_empty(), "décors trop près du vide :\n%s" % "\n".join(problems))


func test_npcs_pickups_enemies_and_spawns_stay_clear_of_the_void() -> void:
	var problems: Array[String] = []
	var count := 0
	for zone: Node in _island.get_node(^"Zones").get_children():
		for path in PLACEMENTS:
			for child: Node in zone.get_node(path).get_children():
				if child is QuestTrigger:
					continue
				count += 1
				var at := (child as Node3D).global_position
				var label := "%s/%s/%s" % [zone.name, path, child.name]
				_check(problems, label, Vector2(at.x, at.z), BLOCKING_MARGIN)
		for marker: Node in zone.find_children("*", "Marker3D", true, false):
			count += 1
			var spot := (marker as Node3D).global_position
			var where := "%s/%s" % [zone.name, zone.get_path_to(marker)]
			_check(problems, where, Vector2(spot.x, spot.z), BLOCKING_MARGIN)
	assert_gt(count, 20, "PNJ, objets, Timeres et points d'apparition parcourus")
	assert_true(problems.is_empty(), "trop près du vide :\n%s" % "\n".join(problems))


func test_quest_triggers_stay_clear_of_the_void() -> void:
	var problems: Array[String] = []
	var count := 0
	for trigger: Node in _island.find_children("*", "QuestTrigger", true, false):
		count += 1
		var quest_trigger := trigger as QuestTrigger
		var at := quest_trigger.global_position
		var center := Vector2(at.x, at.z)
		var label := String(quest_trigger.trigger_id)
		_check(problems, label + " : centre", center, BLOCKING_MARGIN)
		for k in 16:
			var rim := center + Vector2.from_angle(TAU * k / 16.0) * quest_trigger.radius
			if _check(problems, label + " : disque", rim, TRIGGER_DISC_MARGIN):
				break
	assert_gt(count, 0, "déclencheurs parcourus")
	assert_true(problems.is_empty(), "déclencheurs trop près du vide :\n%s" % "\n".join(problems))


# --- Outils ------------------------------------------------------------------------------------


## Ajoute un problème si le point est à moins de margin m du vide ; vrai si c'est le cas.
func _check(problems: Array[String], label: String, point: Vector2, margin: float) -> bool:
	var gap := IslandTerrain.distance_to_edge(point.x, point.y)
	if gap >= margin:
		return false
	problems.append(
		(
			"%s à %.2f m du vide (%.1f m demandés) en (%.1f, %.1f), bord à %.0f°"
			% [label, gap, margin, point.x, point.y, rad_to_deg(atan2(point.y, point.x))]
		)
	)
	return true


## Racines des décors (scènes de src/world/props/) sous node, exemplaires de PropScatter compris
## (enfants internes) ; on ne descend pas dans un décor.
func _props(node: Node) -> Array[Node3D]:
	var found: Array[Node3D] = []
	for child: Node in node.get_children(true):
		if child.scene_file_path.begins_with("res://src/world/props/") and child is Node3D:
			found.append(child as Node3D)
		else:
			found.append_array(_props(child))
	return found


func _is_edge_prop(id: String) -> bool:
	for prefix: String in EDGE_PROPS:
		if id.begins_with(prefix):
			return true
	return false


## Coins (x, z) des boîtes des formes de collision de la couche world d'un décor.
func _collision_corners(prop: Node) -> Array[Vector2]:
	var corners: Array[Vector2] = []
	for body: Node in prop.find_children("*", "StaticBody3D", true, false):
		if ((body as StaticBody3D).collision_layer & WORLD_LAYER) == 0:
			continue
		for node: Node in body.find_children("*", "CollisionShape3D", true, false):
			var shape := node as CollisionShape3D
			if shape.shape == null or shape.disabled:
				continue
			var box := shape.shape.get_debug_mesh().get_aabb()
			for k in 8:
				var corner := shape.global_transform * box.get_endpoint(k)
				corners.append(Vector2(corner.x, corner.z))
	return corners
