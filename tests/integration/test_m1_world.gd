extends GutTest
## Intégration M1, monde : ce que les autres lots posent sur l'île de L2 est praticable.
## Objets (L7), PNJ du village (L6), Timeres de la forêt (L5), panneau et points d'apparition
## de l'arène (L5) : au sol (ni dessous, ni en l'air), hors de tout décor (capsule du joueur),
## sur la terre ferme et reliés au Spawn du village par un chemin à pied (grille de 0,5 m,
## décor de la couche world, sans eau). Clairière de la forêt dégagée sur 6 m pour ses Timeres ;
## arène plate autour du panneau et des points d'apparition ; WorldManager.is_zone_safe().

const ISLAND := preload("res://src/world/island.tscn")
const PLACEMENTS: Array[String] = ["Pickups", "NPCs", "Enemies"]
## Capsule du joueur (player.tscn).
const PLAYER_RADIUS := 0.35
const PLAYER_HEIGHT := 1.5
## Marche franchie par le joueur (dalles du village, plateau du belvédère).
const STEP_UP := 0.2
## Grille du chemin à pied (m) et limite de la terre ferme (niveau de l'eau : −0,6 m).
const GRID_STEP := 0.5
const DRY_LAND := -0.45
## Rayon dégagé de la clairière de la forêt (m, autour du local (0, 0)).
const CLEARING_RADIUS := 6.0

var _island: Node3D
var _space: PhysicsDirectSpaceState3D
var _ground: Node
## Nom → position de départ (avant toute image physique : PNJ et Timeres bougent ensuite).
var _start_positions: Dictionary = {}
var _npc_bodies: Array[RID] = []
var _walkable := PackedByteArray()
var _reached := PackedByteArray()
var _cells := 0


func before_all() -> void:
	_island = ISLAND.instantiate() as Node3D
	add_child(_island)
	for zone: Node in _island.get_node(^"Zones").get_children():
		for placement: String in PLACEMENTS:
			for child: Node in zone.get_node(placement).get_children():
				_start_positions[child] = (child as Node3D).global_position
	await wait_physics_frames(2)
	for npc: Node in get_tree().get_nodes_in_group(&"interactable"):
		if npc is Npc:
			_npc_bodies.append((npc as Npc).get_rid())
	_space = _island.get_world_3d().direct_space_state
	_ground = _island.get_node(^"Ground")
	_build_walk_map()


func after_all() -> void:
	_island.free()


func test_placements_rest_on_dry_ground_clear_of_decor() -> void:
	var problems: Array[String] = []
	for node: Node in _start_positions:
		var at: Vector3 = _start_positions[node]
		var label := "%s/%s" % [node.get_parent().get_parent().name, node.name]
		var floor_y := _floor_height(at)
		if node is Pickup and absf(at.y - floor_y) > 0.1:
			problems.append("%s : posé à y = %.2f, sol à %.2f" % [label, at.y, floor_y])
		elif at.y < floor_y - 0.05:
			problems.append("%s : sous le sol (y = %.2f, sol à %.2f)" % [label, at.y, floor_y])
		if floor_y < DRY_LAND:
			problems.append("%s : dans l'eau (fond à %.2f)" % [label, floor_y])
		var blocking := _decor_at(at, node as CollisionObject3D)
		if not blocking.is_empty():
			problems.append("%s : dans le décor (%s)" % [label, blocking])
	assert_true(
		problems.is_empty(), "objets, PNJ et Timeres praticables : %s" % "; ".join(problems)
	)


func test_placements_are_reachable_on_foot_from_the_village() -> void:
	var unreachable: Array[String] = []
	for node: Node in _start_positions:
		if not _is_reached(_start_positions[node]):
			unreachable.append("%s/%s" % [node.get_parent().get_parent().name, node.name])
	assert_true(unreachable.is_empty(), "inaccessibles à pied : %s" % ", ".join(unreachable))
	assert_gt(_count_reached(), 60000, "le chemin à pied couvre l'île (cases de 0,5 m)")


func test_forest_clearing_is_clear_for_its_timeres() -> void:
	var forest := _island.get_node(^"Zones/forest") as Node3D
	var blocked: Array[String] = []
	var r := -CLEARING_RADIUS
	while r <= CLEARING_RADIUS:
		var c := -CLEARING_RADIUS
		while c <= CLEARING_RADIUS:
			var local := Vector3(r, 0.0, c)
			if local.length() <= CLEARING_RADIUS:
				var at := forest.to_global(local)
				if not _decor_at(at).is_empty() or absf(_floor_height(at)) > 0.05:
					blocked.append(str(local))
			c += GRID_STEP
		r += GRID_STEP
	assert_true(blocked.is_empty(), "clairière plate et dégagée sur 6 m : %s" % ", ".join(blocked))
	var timeres := 0
	for child: Node in forest.get_node(^"Enemies").get_children():
		var local := forest.to_local(_start_positions[child] as Vector3)
		assert_lt(
			Vector2(local.x, local.z).length(), CLEARING_RADIUS, "%s dans la clairière" % child.name
		)
		timeres += 1
	assert_eq(timeres, 4)


func test_arena_panel_and_spawn_points_stand_on_flat_open_sand() -> void:
	var dunes := _island.get_node(^"Zones/dunes") as Node3D
	var arena := dunes.get_node(^"Arena") as Arena
	var panel := arena.get_node(^"Panel") as Node3D
	assert_almost_eq(
		dunes.to_local(panel.global_position), Vector3(9.0, 0.0, -2.0), Vector3.ONE * 0.01
	)
	# Devant le panneau (côté village, à l'est), le joueur se tient et interagit.
	var front := panel.global_position + Vector3(1.4, 0.0, 0.0)
	assert_true(_decor_at(front).is_empty(), "place libre devant le panneau")
	assert_true(_is_reached(front), "panneau atteignable depuis le village")
	assert_true(arena.contains(front), "devant le panneau : dans les bornes de l'arène")
	var points: Array = arena.director().config()["spawn_points"]
	assert_eq(points.size(), 4)
	for marker_name: String in points:
		var marker := arena.spawn_point(StringName(marker_name))
		var flat := true
		for offset: Vector3 in [
			Vector3.ZERO, Vector3(1, 0, 1), Vector3(-1, 0, 1), Vector3(1, 0, -1), Vector3(-1, 0, -1)
		]:
			var at := marker.global_position + offset
			flat = flat and absf(_floor_height(at)) < 0.05 and _decor_at(at).is_empty()
		assert_true(flat, "%s : sable plat et libre à ±1 m (écart des apparitions)" % marker_name)
		assert_true(
			_is_reached(marker.global_position), "%s relié au centre de l'arène" % marker_name
		)
		assert_gt(
			marker.global_position.y,
			_floor_height(marker.global_position),
			"%s au-dessus du sol" % marker_name
		)


func test_world_manager_tells_safe_zones() -> void:
	assert_true(WorldManager.is_zone_safe(&"village"), "village sûr")
	for zone_id: StringName in [&"dunes", &"forest", &"beach", &"hill"]:
		assert_false(WorldManager.is_zone_safe(zone_id), "%s n'est pas sûre" % zone_id)
	assert_false(WorldManager.is_zone_safe(&"nulle_part"), "zone inconnue")
	assert_false(WorldManager.is_zone_safe(&""), "aucune zone")


# --- Outils ------------------------------------------------------------------------------------


## Hauteur du sol (décor statique de la couche world) sous le point.
func _floor_height(at: Vector3) -> float:
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(at.x, 40.0, at.z), Vector3(at.x, -40.0, at.z), 1
	)
	var excluded: Array[RID] = []
	for _attempt in 6:
		query.exclude = excluded
		var hit := _space.intersect_ray(query)
		if hit.is_empty():
			return -INF
		if hit["collider"] == _ground:
			return (hit["position"] as Vector3).y
		excluded.append(hit["rid"] as RID)
	return -INF


## Décor (couche world, hors sol et hors `own`) qui touche une capsule de joueur debout en `at`.
func _decor_at(at: Vector3, own: CollisionObject3D = null) -> String:
	var capsule := CapsuleShape3D.new()
	capsule.radius = PLAYER_RADIUS
	capsule.height = PLAYER_HEIGHT
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = 1
	var excluded := _npc_bodies.duplicate()
	if own != null:
		excluded.append(own.get_rid())
	query.exclude = excluded
	var y := _floor_height(at) + STEP_UP + PLAYER_HEIGHT / 2.0
	query.transform = Transform3D(Basis.IDENTITY, Vector3(at.x, y, at.z))
	var names: Array[String] = []
	for hit: Dictionary in _space.intersect_shape(query, 4):
		if hit["collider"] != _ground:
			var collider := hit["collider"] as Node
			names.append("%s/%s" % [collider.get_parent().name, collider.name])
	return ", ".join(names)


## Grille praticable (terre ferme, sans décor) et cases atteintes depuis le Spawn du village.
func _build_walk_map() -> void:
	_cells = int(IslandTerrain.SIZE / GRID_STEP)
	_walkable.resize(_cells * _cells)
	_reached.resize(_cells * _cells)
	for j in _cells:
		for i in _cells:
			var at := _cell_center(i, j)
			var dry := IslandTerrain.height_at(at.x, at.z) >= DRY_LAND
			_walkable[j * _cells + i] = 1 if dry and _decor_at(at).is_empty() else 0
	var spawn := (_island.get_node(^"Zones/village/Spawn") as Node3D).global_position
	var start := _cell_index(spawn)
	_reached[start] = 1
	var queue: Array[int] = [start]
	var head := 0
	while head < queue.size():
		var cell := queue[head]
		head += 1
		var ci := cell % _cells
		var cj := floori(float(cell) / _cells)
		for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var ni := ci + step.x
			var nj := cj + step.y
			if ni < 0 or nj < 0 or ni >= _cells or nj >= _cells:
				continue
			var next := nj * _cells + ni
			if _reached[next] == 0 and _walkable[next] == 1:
				_reached[next] = 1
				queue.append(next)


func _cell_center(i: int, j: int) -> Vector3:
	var half := IslandTerrain.HALF
	return Vector3(-half + (i + 0.5) * GRID_STEP, 0.0, -half + (j + 0.5) * GRID_STEP)


func _cell_index(at: Vector3) -> int:
	var half := IslandTerrain.HALF
	var i := clampi(floori((at.x + half) / GRID_STEP), 0, _cells - 1)
	var j := clampi(floori((at.z + half) / GRID_STEP), 0, _cells - 1)
	return j * _cells + i


## Vrai si la case du point, ou une case voisine (un objet se ramasse au contact), est atteinte.
func _is_reached(at: Vector3) -> bool:
	for offset: Vector3 in [
		Vector3.ZERO,
		Vector3(0.5, 0, 0),
		Vector3(-0.5, 0, 0),
		Vector3(0, 0, 0.5),
		Vector3(0, 0, -0.5)
	]:
		if _reached[_cell_index(at + offset)] == 1:
			return true
	return false


func _count_reached() -> int:
	var total := 0
	for value: int in _reached:
		total += value
	return total
