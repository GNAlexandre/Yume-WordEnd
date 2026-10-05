extends GutTest
## Village : zone sûre, barrière à ennemis sur la couche 8 qui entoure tout le village (portes
## comprises), infranchissable pour un ennemi (masque 1 + 2 + 8), transparente pour le joueur
## (masque 1 + 3).

const FIXTURE := preload("res://tests/stubs/l2_island_fixture.gd")
const ENEMY_BARRIER_LAYER := 128
## Masques du plan (PLAN.md section 3, couches et masques).
const ENEMY_MASK := 1 + 2 + 128
const PLAYER_MASK := 1 + 4
## Les quatre portes (arches) sont sur les chemins, aux points cardinaux du village.
const GATES: Array[Vector3] = [
	Vector3(0.0, 0.0, -1.0), Vector3(0.0, 0.0, 1.0), Vector3(-1.0, 0.0, 0.0), Vector3(1.0, 0.0, 0.0)
]

var _island: Node3D
var _village: Zone


func before_all() -> void:
	_island = FIXTURE.island()
	add_child(_island)
	_village = _island.get_node(^"Zones/village") as Zone
	await wait_physics_frames(2)


func after_all() -> void:
	_island.free()


func test_village_is_safe_and_barrier_on_layer_8_only() -> void:
	assert_true(_village.safe, "le village est une zone sûre")
	var barrier := _village.get_node(^"EnemyBarrier") as StaticBody3D
	assert_eq(barrier.collision_layer, ENEMY_BARRIER_LAYER, "couche 8 enemy_barrier seule")
	assert_eq(barrier.collision_mask, 0)
	assert_eq(ENEMY_MASK & ENEMY_BARRIER_LAYER, ENEMY_BARRIER_LAYER, "les ennemis la voient")
	assert_eq(PLAYER_MASK & ENEMY_BARRIER_LAYER, 0, "le joueur ne la voit pas")


func test_barrier_surrounds_the_village_in_every_direction() -> void:
	var space := _island.get_world_3d().direct_space_state
	var barrier := _village.get_node(^"EnemyBarrier")
	for height: float in [0.3, 1.5, 4.0]:
		for angle in range(0, 360, 5):
			var direction := Vector3.FORWARD.rotated(Vector3.UP, deg_to_rad(angle))
			var from := Vector3(0.0, height, 0.0)
			var query := PhysicsRayQueryParameters3D.create(
				from, from + direction * 40.0, ENEMY_BARRIER_LAYER
			)
			var hit := space.intersect_ray(query)
			assert_eq(hit.get("collider"), barrier, "barrière à %d° (h = %.1f m)" % [angle, height])
			if not hit.is_empty():
				var distance := (hit["position"] as Vector3).distance_to(from)
				assert_between(distance, 21.0, 33.0, "barrière au bord du village (%d°)" % angle)


func test_gates_stop_enemies_but_let_the_player_through() -> void:
	for gate in GATES:
		var start := gate * 28.0 + Vector3.UP * 0.2
		var motion := -gate * 16.0
		var enemy := _body(4, ENEMY_MASK)
		var player := _body(2, PLAYER_MASK)
		enemy.add_collision_exception_with(player)
		player.add_collision_exception_with(enemy)
		enemy.global_position = start
		player.global_position = start
		await wait_physics_frames(2)
		assert_true(
			enemy.test_move(enemy.global_transform, motion), "porte %s : ennemi bloqué" % gate
		)
		assert_false(
			player.test_move(player.global_transform, motion), "porte %s : joueur passe" % gate
		)
		enemy.free()
		player.free()


func test_bounds_cover_the_barrier() -> void:
	var shape := (_village.get_node(^"Bounds/CollisionShape3D") as CollisionShape3D).shape
	var size := (shape as BoxShape3D).size
	assert_eq(Vector2(size.x, size.z), Vector2(44.0, 44.0), "Bounds ±22 m (repères de l'île)")


## Corps de test : capsule de la taille d'un Timere moyen sur la couche donnée.
func _body(layer: int, mask: int) -> CharacterBody3D:
	var body := CharacterBody3D.new()
	body.collision_layer = layer
	body.collision_mask = mask
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.2
	shape.shape = capsule
	shape.position = Vector3(0.0, 0.6, 0.0)
	body.add_child(shape)
	add_child(body)
	return body
