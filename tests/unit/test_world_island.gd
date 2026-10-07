extends GutTest
## L'île flottante complète avec le joueur factice : entrée dans chaque zone, noms affichés
## (docs/lore/MONDE.md, section 2.1), téléportation sur chaque Spawn et sur les 4 points de
## l'arène, KillZone et rattrapage, réapparition au village, sol sans trou sur l'île et vide
## au-delà du bord (au-dessus de la KillZone), murs fermés, barrière à Timeres au bord.

const FIXTURE := preload("res://tests/stubs/l2_island_fixture.gd")
const PLAYER_STUB := preload("res://tests/stubs/player_stub.tscn")
const ZONES: Array[StringName] = [&"village", &"dunes", &"forest", &"beach", &"hill"]
const ARENA_MARKERS: Array[StringName] = [&"SpawnN", &"SpawnS", &"SpawnE", &"SpawnW"]
## Noms affichés des zones (docs/lore/MONDE.md, section 2.1).
const NAMES := {
	&"village": "L'entrepôt des fées",
	&"dunes": "Le bord du Couchant",
	&"forest": "Les bois du marais",
	&"beach": "Le port et le bourg",
	&"hill": "La colline des étoiles",
}
## Couche 8 (enemy_barrier) et masques des Timeres et du joueur (PLAN.md section 3).
const ENEMY_BARRIER_LAYER := 128
const ENEMY_MASK := 1 + 2 + 128
const PLAYER_MASK := 1 + 4

var _island: Node3D
var _player: CharacterBody3D


func before_all() -> void:
	_island = FIXTURE.island()
	add_child(_island)


func after_all() -> void:
	_island.free()


func before_each() -> void:
	_player = add_child_autofree(PLAYER_STUB.instantiate())
	await wait_physics_frames(2)


func _zone(zone_id: StringName) -> Zone:
	return _island.get_node("Zones/%s" % zone_id) as Zone


func _marker(zone_id: StringName, marker: StringName) -> Node3D:
	return _zone(zone_id).get_node(NodePath(String(marker))) as Node3D


func _assert_on_ground_at(target: Node3D, label: String) -> void:
	var flat := Vector2(_player.global_position.x, _player.global_position.z)
	var expected := Vector2(target.global_position.x, target.global_position.z)
	assert_lt(flat.distance_to(expected), 0.05, "%s : au-dessus du marqueur" % label)
	var ground := IslandTerrain.height_at(expected.x, expected.y)
	assert_almost_eq(_player.global_position.y, ground, 0.2, "%s : posé sur le sol" % label)


func test_every_zone_emits_zone_entered() -> void:
	# Hors de toutes les zones (au-dessus de leurs Bounds), puis dans chacune tour à tour.
	_player.global_position = Vector3(0.0, 60.0, 0.0)
	await wait_physics_frames(2)
	# Intégration M2 : une zone n'est pas réannoncée au joueur qui y était déjà (frontières) ;
	# le joueur factice, né au village, oublie la sienne pour que le village compte aussi.
	_player.remove_meta(Zone.LAST_ZONE_META)
	watch_signals(EventBus)
	for zone_id in ZONES:
		WorldManager.teleport(zone_id)
		await wait_physics_frames(3)
		assert_signal_emitted(EventBus, "zone_entered")
		assert_eq(
			get_signal_parameters(EventBus, "zone_entered"),
			[zone_id],
			"%s : zone_entered" % zone_id
		)
		assert_eq(WorldManager.current_zone(), zone_id)
		assert_eq(GameState.zone, zone_id, "%s : GameState.zone tenu à jour" % zone_id)


func test_display_names() -> void:
	for zone_id in ZONES:
		var zone := _zone(zone_id)
		assert_eq(zone.display_name, NAMES[zone_id], "%s : nom affiché" % zone_id)
		assert_eq(WorldManager.zone_display_name(zone_id), zone.display_name)
		assert_eq(zone.zone_id(), zone_id)


func test_teleport_to_every_spawn_lands_on_ground() -> void:
	for zone_id in ZONES:
		WorldManager.teleport(zone_id)
		_assert_on_ground_at(_marker(zone_id, &"Spawn"), "%s/Spawn" % zone_id)
		assert_eq(_player.velocity, Vector3.ZERO, "vitesse annulée")


func test_teleport_to_the_four_arena_points() -> void:
	for marker in ARENA_MARKERS:
		WorldManager.teleport(&"dunes", marker)
		_assert_on_ground_at(_marker(&"dunes", marker), "dunes/%s" % marker)


func test_kill_zone_returns_player_to_current_zone_spawn() -> void:
	WorldManager.teleport(&"hill")
	await wait_physics_frames(3)
	assert_eq(WorldManager.current_zone(), &"hill")
	# Chute hors de l'île : dans le vide, sous le bord, au-delà des murs.
	_player.global_position = Vector3(95.0, -12.0, 0.0)
	await wait_physics_frames(3)
	await wait_process_frames(1)
	_assert_on_ground_at(_marker(&"hill", &"Spawn"), "retour au Spawn de la colline")


func test_fall_below_limit_is_rescued_without_kill_zone() -> void:
	WorldManager.teleport(&"beach")
	await wait_physics_frames(3)
	_player.global_position = Vector3(0.0, WorldManager.FALL_LIMIT - 10.0, 0.0)
	await wait_physics_frames(3)
	_assert_on_ground_at(_marker(&"beach", &"Spawn"), "rattrapé au Spawn de la plage")


func test_respawn_returns_to_village_spawn() -> void:
	WorldManager.teleport(&"forest")
	await wait_physics_frames(2)
	watch_signals(EventBus)
	WorldManager.respawn()
	_assert_on_ground_at(_marker(&"village", &"Spawn"), "réapparu au village")
	assert_signal_emitted(EventBus, "player_respawned")


func test_ground_everywhere_on_the_island_and_the_void_beyond() -> void:
	var space := _island.get_world_3d().direct_space_state
	var ground := _island.get_node(^"Ground")
	var kill_zone := _island.get_node(^"KillZone/CollisionShape3D") as CollisionShape3D
	var kill_box := (kill_zone.shape as BoxShape3D).size
	var holes: Array[Vector2] = []
	var floors: Array[Vector2] = []
	var uncaught: Array[Vector2] = []
	for x in range(-78, 79, 4):
		for z in range(-78, 79, 4):
			var edge := IslandTerrain.edge_distance(x, z)
			if absf(edge) < 0.3:
				continue
			var hit := _ground_hit(space, Vector2(x, z))
			if edge > 0.0 and hit.get("collider") != ground:
				holes.append(Vector2(x, z))
			elif edge < 0.0 and not hit.is_empty():
				floors.append(Vector2(x, z))
			# Dans le vide, un corps qui tombe traverse la KillZone avant y = −30.
			var below := kill_zone.global_transform.affine_inverse() * Vector3(x, -12.0, z)
			if (
				edge < 0.0
				and (absf(below.x) > kill_box.x / 2.0 or absf(below.z) > kill_box.z / 2.0)
			):
				uncaught.append(Vector2(x, z))
	assert_eq(holes, [] as Array[Vector2], "aucun trou dans le sol de l'île")
	assert_eq(floors, [] as Array[Vector2], "rien ne porte au-delà du bord : le vide")
	assert_eq(uncaught, [] as Array[Vector2], "sous le vide, la KillZone")
	assert_lt(kill_zone.global_position.y + kill_box.y / 2.0, -9.9, "KillZone sous y = −10")


func test_edge_barrier_holds_timeres_not_the_player() -> void:
	var barrier := _island.get_node(^"EdgeBarrier") as StaticBody3D
	assert_eq(barrier.collision_layer, ENEMY_BARRIER_LAYER, "couche 8 enemy_barrier seule")
	assert_eq(barrier.collision_mask, 0)
	assert_eq(PLAYER_MASK & ENEMY_BARRIER_LAYER, 0, "le joueur ne la voit pas")
	var space := _island.get_world_3d().direct_space_state
	for angle in range(0, 360, 5):
		var edge := IslandTerrain.edge_point(deg_to_rad(angle))
		var from := Vector3(edge.x, 0.6, edge.y) * Vector3(0.8, 1.0, 0.8)
		var to := Vector3(edge.x, 0.6, edge.y) + Vector3(edge.x, 0.0, edge.y).normalized() * 3.0
		var query := PhysicsRayQueryParameters3D.create(from, to, ENEMY_BARRIER_LAYER)
		query.hit_back_faces = true
		var hit := space.intersect_ray(query)
		assert_eq(hit.get("collider"), barrier, "barrière du bord à %d°" % angle)
		if not hit.is_empty():
			var inside := IslandTerrain.edge_distance(hit["position"].x, hit["position"].z)
			assert_between(inside, 0.4, 1.5, "%d° : juste en deçà du bord" % angle)


func test_walls_close_every_side() -> void:
	var space := _island.get_world_3d().direct_space_state
	var walls := _island.get_node(^"Walls") as StaticBody3D
	# Juste sous le niveau du sol, sous le tablier de la passerelle du port.
	var y := -0.45
	for t in range(-79, 80, 6):
		for ray: Array in [
			[Vector3(78.5, y, t), Vector3(85.0, y, t)],
			[Vector3(-78.5, y, t), Vector3(-85.0, y, t)],
			[Vector3(t, y, 78.5), Vector3(t, y, 85.0)],
			[Vector3(t, y, -78.5), Vector3(t, y, -85.0)],
		]:
			var query := PhysicsRayQueryParameters3D.create(ray[0], ray[1], 1)
			query.hit_back_faces = false
			var hit := space.intersect_ray(query)
			assert_eq(hit.get("collider"), walls, "mur sur le chemin %s → %s" % [ray[0], ray[1]])


## Premier impact sur le sol (couche world) à la verticale de p, en traversant le décor posé
## dessus ; {} si rien ne porte.
func _ground_hit(space: PhysicsDirectSpaceState3D, p: Vector2) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(p.x, 40.0, p.y), Vector3(p.x, -40.0, p.y), 1
	)
	var ground := _island.get_node(^"Ground")
	var excluded: Array[RID] = []
	for _attempt in 6:
		query.exclude = excluded
		var hit := space.intersect_ray(query)
		if hit.is_empty() or hit["collider"] == ground:
			return hit
		excluded.append(hit["rid"] as RID)
	return {}
