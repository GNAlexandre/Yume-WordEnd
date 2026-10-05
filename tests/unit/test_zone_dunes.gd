extends GutTest
## Arène des dunes : l'Arena (arena_id dunes) au centre de la cuvette, les 4 points
## d'apparition frères de l'Arena à ~13 m du centre et posés sur le sol, sol de l'arène plat
## et dégagé sur 12 m de rayon.

const FIXTURE := preload("res://tests/stubs/l2_island_fixture.gd")
const MARKERS: Array[StringName] = [&"SpawnN", &"SpawnS", &"SpawnE", &"SpawnW"]

var _island: Node3D
var _dunes: Zone
var _arena: Arena


func before_all() -> void:
	_island = FIXTURE.island()
	add_child(_island)
	_dunes = _island.get_node(^"Zones/dunes") as Zone
	_arena = _dunes.get_node(^"Arena") as Arena
	await wait_physics_frames(2)


func after_all() -> void:
	_island.free()


func _flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)


## Premier obstacle de la couche world sur le rayon, en ignorant le contenu de arena.tscn (L5 :
## panneau, décor de l'arène) : seul le monde du Lot 2 est vérifié ici.
func _hit(from: Vector3, to: Vector3) -> Dictionary:
	var space := _island.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	var excluded: Array[RID] = []
	for _attempt in 8:
		query.exclude = excluded
		var hit := space.intersect_ray(query)
		if hit.is_empty() or not _arena.is_ancestor_of(hit["collider"] as Node):
			return hit
		excluded.append(hit["rid"] as RID)
	return {}


func test_arena_sits_in_the_middle_of_the_flat_bowl() -> void:
	assert_eq(_arena.arena_id, &"dunes")
	assert_almost_eq(_flat(_arena.global_position), IslandTerrain.ARENA_CENTER, Vector2.ONE * 0.01)
	assert_almost_eq(_arena.global_position.x, -51.0, 0.01, "arène à x = −51 (repères)")


func test_four_spawn_points_at_13_m_on_the_ground() -> void:
	var ground := _island.get_node(^"Ground")
	for marker_name in MARKERS:
		var marker := _dunes.get_node_or_null(NodePath(String(marker_name))) as Marker3D
		assert_not_null(marker, "%s enfant direct de la zone" % marker_name)
		if marker == null:
			continue
		assert_eq(marker.get_parent(), _arena.get_parent(), "%s frère de l'Arena" % marker_name)
		assert_eq(_arena.spawn_point(marker_name), marker, "Arena.spawn_point(%s)" % marker_name)
		var distance := _flat(marker.global_position).distance_to(_flat(_arena.global_position))
		assert_almost_eq(distance, 13.0, 0.5, "%s à ~13 m du centre" % marker_name)
		var from := marker.global_position + Vector3.UP
		var hit := _hit(from, from + Vector3.DOWN * 5.0)
		assert_eq(hit.get("collider"), ground, "%s : sol sous le point" % marker_name)
		if not hit.is_empty():
			var drop := marker.global_position.y - (hit["position"] as Vector3).y
			assert_between(drop, -0.05, 1.0, "%s : juste au-dessus du sol" % marker_name)


func test_arena_floor_is_flat_and_clear() -> void:
	var ground := _island.get_node(^"Ground")
	var center := _arena.global_position
	for radius: float in [0.0, 3.0, 6.0, 9.0, 12.0]:
		for angle in range(0, 360, 20):
			var p := center + Vector3.FORWARD.rotated(Vector3.UP, deg_to_rad(angle)) * radius
			var hit := _hit(p + Vector3.UP * 10.0, p + Vector3.DOWN * 5.0)
			assert_eq(hit.get("collider"), ground, "rien posé sur l'arène en %s" % p)
			if not hit.is_empty():
				assert_almost_eq((hit["position"] as Vector3).y, 0.0, 0.05, "sol plat en %s" % p)
	# Dégagée : un rayon à hauteur de Timere traverse l'arène de part en part.
	for angle in range(0, 180, 15):
		var direction := Vector3.FORWARD.rotated(Vector3.UP, deg_to_rad(angle))
		var from := center + Vector3.UP * 0.8 - direction * 12.0
		assert_true(_hit(from, from + direction * 24.0).is_empty(), "arène dégagée (%d°)" % angle)
