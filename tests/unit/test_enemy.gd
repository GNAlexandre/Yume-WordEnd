extends GutTest
## Enemy (src/enemies/enemy.gd) : les 4 Timeres poursuivent et attaquent un mannequin (dégâts
## seulement sur les images « coup »), recul (le Grand ne recule que sous l'onde), mort, drops,
## abandon de la poursuite (zone sûre, laisse, frontière réelle du village), données et Timeres
## libres de la forêt.

const ENEMY_SCENE := preload("res://src/enemies/enemy.tscn")
const PLAYER_STUB := preload("res://tests/stubs/player_stub.tscn")
const VISUAL_STUB_SCRIPT := preload("res://tests/stubs/visual_stub.gd")
const FOREST := preload("res://src/enemies/placements/forest.tscn")
const ISLAND := preload("res://src/world/island.tscn")
const SWORD := preload("res://data/attacks/sword_1.tres")
const WAVE := preload("res://data/attacks/charge_wave.tres")
const TYPES: Array[StringName] = [
	&"timere_small", &"timere_normal", &"timere_runner", &"timere_big"
]
## Tableau de PLAN.md section 4 : échelle, PV, vitesse (m/s), points, rush, stoic.
const PLAN_TABLE := {
	&"timere_small": [0.8, 1, 3.0, 10, false, false],
	&"timere_normal": [1.0, 2, 2.1, 15, false, false],
	&"timere_runner": [0.9, 1, 6.2, 20, true, false],
	&"timere_big": [1.3, 5, 1.6, 40, false, true],
}

var _world: Node3D
var _zone_before: StringName


func before_each() -> void:
	GameState.reset()
	_zone_before = WorldManager.current_zone()
	_world = add_child_autofree(Node3D.new())
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(80.0, 1.0, 80.0)
	shape.shape = box
	ground.add_child(shape)
	ground.position = Vector3(0.0, -0.5, 0.0)
	_world.add_child(ground)


func after_each() -> void:
	if WorldManager.current_zone() != _zone_before:
		EventBus.zone_entered.emit(_zone_before)
	GameState.reset()


func _enemy(enemy_id: StringName, at: Vector3, stub_visual: bool = false) -> Enemy:
	var enemy := ENEMY_SCENE.instantiate() as Enemy
	enemy.data = load("res://data/enemies/%s.tres" % enemy_id) as EnemyData
	if stub_visual:
		enemy.get_node(^"Visual").set_script(VISUAL_STUB_SCRIPT)
	enemy.position = at
	_world.add_child(enemy)
	return enemy


func _player(at: Vector3 = Vector3.ZERO) -> CharacterBody3D:
	var player := PLAYER_STUB.instantiate() as CharacterBody3D
	player.position = at
	_world.add_child(player)
	return player


func _flat_distance(a: Node3D, b: Node3D) -> float:
	var offset := a.global_position - b.global_position
	return Vector2(offset.x, offset.z).length()


func test_data_matches_the_plan_table() -> void:
	for enemy_id: StringName in TYPES:
		var data := load("res://data/enemies/%s.tres" % enemy_id) as EnemyData
		var row: Array = PLAN_TABLE[enemy_id]
		assert_almost_eq(data.scale, float(row[0]), 0.001, "%s : échelle" % enemy_id)
		assert_eq(data.max_hp, int(row[1]), "%s : PV" % enemy_id)
		assert_almost_eq(data.speed, float(row[2]), 0.001, "%s : vitesse" % enemy_id)
		assert_eq(data.points, int(row[3]), "%s : points" % enemy_id)
		assert_eq(data.rush, bool(row[4]), "%s : rush" % enemy_id)
		assert_eq(data.stoic, bool(row[5]), "%s : stoic" % enemy_id)
		assert_eq(data.visual.id, &"timere", "%s : planche du Timere" % enemy_id)
	var big := load("res://data/enemies/timere_big.tres") as EnemyData
	assert_almost_eq(big.cooldown_scale, 1.4, 0.001, "recharge du Grand × 1,4")


func test_four_sizes_share_the_directional_timere_and_attack_windows() -> void:
	var skin := load("res://data/enemies/visuals/timere.tres") as SkinData
	assert_null(skin.mesh_scene)
	assert_null(SkinRegistry.get_skin(&"timere"), "le Timere reste un ennemi")
	for enemy_id: StringName in TYPES:
		var data := load("res://data/enemies/%s.tres" % enemy_id) as EnemyData
		assert_same(data.visual, skin, "les tailles utilisent le même visuel directionnel")
	var expected := {
		"repos": [5, 6],
		"marche": [4, 7],
		"course": [6, 12],
		"fouet": [4, 8],
		"morsure": [4, 8],
		"degats": [5, 12],
		"mort": [6, 8],
	}
	for direction: String in ["front", "back", "right"]:
		assert_true(skin.directional_sheets.has(direction))
		assert_true(skin.directional_frames_json.has(direction))
		var frames := SheetLoader.frames_for(skin, direction)
		var sheet := SheetLoader.read_sheet(skin, direction)
		for animation: String in expected:
			assert_eq(frames.get_frame_count(animation), expected[animation][0])
			assert_eq(frames.get_animation_speed(animation), float(expected[animation][1]))
		for attack: StringName in [&"fouet", &"morsure"]:
			assert_eq(SheetLoader.hit_frames(sheet, attack), [1, 2] as Array[int])


func test_chases_and_hits_only_on_hit_frames(enemy_id: StringName = use_parameters(TYPES)) -> void:
	var player := _player()
	var player_health := player.get_node(^"Health") as Health
	var enemy := _enemy(enemy_id, Vector3(3.5, 0.0, 0.0), true)
	var visual: Node = enemy.visual
	# Plus d'animation réelle : les images « coup » viennent du test.
	enemy.visual.set_skin(null)
	visual.set(&"forced_hit_frames", {&"morsure": [1, 2], &"fouet": [1, 2]})
	var attacking: bool = await wait_until(func() -> bool: return enemy.state() == &"attack", 5.0)
	assert_true(attacking, "%s attaque le mannequin" % enemy_id)
	if not attacking:
		return
	assert_lt(_flat_distance(enemy, player), 3.0, "%s s'est approché" % enemy_id)
	var attack := enemy.current_attack()
	assert_true(attack.damage > 0, "%s : attaque au contact (%s)" % [enemy_id, attack.id])
	assert_lt(
		_flat_distance(enemy.hitbox, player),
		_flat_distance(enemy, player),
		"%s : Hitbox tournée vers la cible" % enemy_id
	)
	visual.call(&"emit_frame", attack.animation, 0)
	await wait_physics_frames(3)
	assert_false(enemy.hitbox.is_active(), "%s : Hitbox éteinte hors des images coup" % enemy_id)
	assert_eq(player_health.current, 5, "%s : aucun dégât hors des images coup" % enemy_id)
	visual.call(&"emit_frame", attack.animation, 1)
	assert_true(enemy.hitbox.is_active(), "%s : Hitbox active sur l'image coup" % enemy_id)
	await wait_physics_frames(3)
	assert_eq(player_health.current, 4, "%s : un dégât sur l'image coup" % enemy_id)
	var hits: Array = player.get(&"hits")
	assert_eq(hits.size(), 1, "%s : un seul coup" % enemy_id)
	if hits.size() == 1:
		assert_eq(hits[0], attack, "%s : coup porté avec l'AttackData de l'attaque" % enemy_id)
	visual.call(&"emit_frame", attack.animation, 3)
	assert_false(enemy.hitbox.is_active(), "%s : Hitbox éteinte après les images coup" % enemy_id)


func test_runner_rushes_in_a_straight_line() -> void:
	_player()
	var runner := _enemy(&"timere_runner", Vector3(6.0, 0.0, 0.0))
	var rushing: bool = await wait_until(func() -> bool: return runner.state() == &"rush", 2.0)
	assert_true(rushing, "le coureur charge dès 8 m")
	assert_eq(runner.visual.current_animation(), &"course")
	var ground_speed := Vector2(runner.velocity.x, runner.velocity.z).length()
	assert_almost_eq(ground_speed, runner.data.speed, 0.3, "à pleine vitesse")


func test_big_recoils_only_under_the_wave() -> void:
	var big := _enemy(&"timere_big", Vector3.ZERO)
	var source := Node3D.new()
	_world.add_child(source)
	source.position = Vector3(-1.0, 0.0, 0.0)
	assert_true(big.hurtbox.receive_hit(SWORD, source))
	assert_eq(big.knockback(), Vector3.ZERO, "pas de recul sous l'épée")
	assert_ne(big.state(), &"hurt", "pas d'état hurt sous l'épée")
	assert_true(big.hurtbox.receive_hit(WAVE, source))
	assert_almost_eq(big.knockback().x, WAVE.knockback, 0.01, "l'onde le repousse")
	assert_eq(big.state(), &"hurt")
	assert_eq(big.health.current, 1, "5 PV − 1 (épée) − 3 (onde)")


func test_normal_recoils_away_from_the_sword() -> void:
	var timere := _enemy(&"timere_normal", Vector3.ZERO)
	var source := Node3D.new()
	_world.add_child(source)
	source.position = Vector3(0.0, 0.0, 1.0)
	assert_true(timere.hurtbox.receive_hit(SWORD, source))
	assert_almost_eq(timere.knockback().z, -SWORD.knockback, 0.01, "recul source → corps")
	assert_eq(timere.state(), &"hurt")
	await wait_physics_frames(10)
	assert_lt(timere.global_position.z, -0.2, "il a reculé")
	await wait_seconds(0.5)
	assert_ne(timere.state(), &"hurt", "hurt dure moins de 0,45 s")


func test_death_gives_points_and_leaves_group(enemy_id: StringName = use_parameters(TYPES)) -> void:
	var enemy := _enemy(enemy_id, Vector3.ZERO)
	enemy.corpse_time = 0.3
	enemy.drops_enabled = false
	var points: int = PLAN_TABLE[enemy_id][3]
	watch_signals(EventBus)
	watch_signals(enemy)
	assert_true(enemy.is_in_group(&"enemies"))
	enemy.health.take_damage(99, null)
	assert_true(enemy.is_dead())
	assert_eq(enemy.state(), &"dead")
	assert_false(enemy.is_in_group(&"enemies"), "%s : sorti du groupe enemies" % enemy_id)
	assert_signal_emitted_with_parameters(EventBus, "enemy_killed", [enemy_id, points])
	assert_signal_emitted_with_parameters(enemy, "defeated", [enemy, points])
	assert_eq(enemy.visual.current_animation(), &"mort")
	await wait_seconds(0.6)
	assert_freed(enemy, "%s disparu après corpse_time" % enemy_id)


func test_drops_only_when_enabled() -> void:
	var dropper := _enemy(&"timere_small", Vector3(2.0, 0.0, 0.0))
	var keeper := _enemy(&"timere_small", Vector3(-2.0, 0.0, 0.0))
	keeper.drops_enabled = false
	dropper.health.take_damage(99, null)
	keeper.health.take_damage(99, null)
	await wait_process_frames(2)
	var pickups: Array[Pickup] = []
	for child: Node in _world.get_children():
		if child is Pickup:
			pickups.append(child as Pickup)
	assert_eq(pickups.size(), 1, "seul l'ennemi drops_enabled lâche un objet")
	if pickups.size() != 1:
		return
	assert_eq(pickups[0].item_id, &"page_fragment")
	assert_eq(pickups[0].quantity, 1)
	assert_false(pickups[0].persistent, "objet lâché : non persistant")
	assert_almost_eq(pickups[0].global_position.x, 2.0, 0.3, "à la position de l'ennemi")


func test_stops_chasing_when_player_is_in_a_safe_zone() -> void:
	var zone := Zone.new()
	zone.name = "l5_safe_zone"
	zone.safe = true
	zone.add_to_group(&"zones")
	_world.add_child(zone)
	var player := _player(Vector3(6.0, 0.0, 0.0))
	var enemy := _enemy(&"timere_normal", Vector3.ZERO)
	var approached: bool = await wait_until(func() -> bool: return enemy.position.x > 1.0, 3.0)
	assert_true(approached, "poursuite engagée")
	assert_eq(enemy.state(), &"chase")
	EventBus.zone_entered.emit(&"l5_safe_zone")
	await wait_physics_frames(2)
	assert_eq(enemy.state(), &"idle", "plus de poursuite : le joueur est en zone sûre")
	var given_up_at := enemy.position.x
	await wait_seconds(0.5)
	assert_lt(enemy.position.x, given_up_at, "il rentre chez lui")
	assert_lt(_flat_distance(enemy, player), 10.0)


func test_gives_up_at_the_real_village_border() -> void:
	var island: Node3D = add_child_autofree(ISLAND.instantiate())
	var player := PLAYER_STUB.instantiate() as CharacterBody3D
	player.position = Vector3(0.0, 0.2, -25.0)
	island.add_child(player)
	var enemy := ENEMY_SCENE.instantiate() as Enemy
	enemy.data = load("res://data/enemies/timere_normal.tres") as EnemyData
	enemy.position = Vector3(0.0, 0.2, -31.0)
	island.add_child(enemy)
	var chasing: bool = await wait_until(func() -> bool: return enemy.state() == &"chase", 2.0)
	assert_true(chasing, "poursuite dans la forêt, près de la barrière (z = -22)")
	player.position = Vector3(0.0, 0.2, -17.0)
	var gave_up: bool = await wait_until(func() -> bool: return enemy.state() == &"idle", 2.0)
	assert_true(gave_up, "le joueur entre au village : fin de la poursuite")
	assert_eq(WorldManager.current_zone(), &"village")
	await wait_seconds(0.5)
	assert_lt(enemy.global_position.z, -22.0, "le Timere reste côté forêt")


func test_leash_limits_the_chase() -> void:
	var player := _player(Vector3(6.0, 0.0, 0.0))
	var enemy := _enemy(&"timere_normal", Vector3.ZERO)
	enemy.leash_m = 4.0
	await wait_physics_frames(10)
	assert_eq(enemy.state(), &"idle", "joueur au-delà de la laisse : pas de poursuite")
	player.position = Vector3(3.0, 0.0, 0.0)
	await wait_physics_frames(3)
	assert_ne(enemy.state(), &"idle", "joueur dans la laisse : poursuite")


func test_forest_has_four_free_timeres_carrying_pages() -> void:
	var placement: Node3D = autofree(FOREST.instantiate())
	var counts := {}
	for child: Node in placement.get_children():
		var enemy := child as Enemy
		assert_not_null(enemy, "%s est un Enemy" % child.name)
		if enemy == null:
			continue
		counts[enemy.enemy_id()] = int(counts.get(enemy.enemy_id(), 0)) + 1
		assert_true(enemy.drops_enabled, "%s lâche ses objets" % child.name)
		assert_false(enemy.always_chase, "%s est un ennemi libre" % child.name)
		assert_almost_eq(float(enemy.data.drops.get(&"page_fragment", 0.0)), 1.0, 0.001)
		assert_lt(Vector2(enemy.position.x, enemy.position.z).length(), 6.0, "dans la clairière")
	assert_eq_deep(counts, {&"timere_small": 2, &"timere_normal": 1, &"timere_runner": 1})
