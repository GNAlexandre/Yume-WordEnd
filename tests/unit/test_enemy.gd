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
const BITE := preload("res://data/attacks/bite.tres")
const RUSH := preload("res://data/attacks/rush.tres")
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
	# (H7) Arrêt sur image : le corps attend sword_1.hitstop, puis recule de la même distance.
	assert_almost_eq(timere.hitstop_left(), SWORD.hitstop, 0.001, "arrêt sur image")
	await wait_physics_frames(2)
	assert_almost_eq(timere.global_position.z, 0.0, 0.01, "figé pendant l'arrêt sur image")
	await wait_physics_frames(ceili(SWORD.hitstop * Engine.physics_ticks_per_second) + 8)
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
	# Les corps de Timere ne lâchent rien (data/enemies, V3) : le mécanisme des drops se teste
	# sur une copie de leurs données qui porte une page.
	var carrying := (load("res://data/enemies/timere_small.tres") as EnemyData).duplicate()
	var drops: Dictionary[StringName, float] = {&"page_fragment": 1.0}
	(carrying as EnemyData).drops = drops
	var dropper := _enemy(&"timere_small", Vector3(2.0, 0.0, 0.0))
	var keeper := _enemy(&"timere_small", Vector3(-2.0, 0.0, 0.0))
	dropper.data = carrying as EnemyData
	keeper.data = carrying as EnemyData
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


func test_stops_chasing_while_the_player_talks() -> void:
	# Audit : un Timere qui frappait pendant une conversation tuait le joueur, qui réapparaissait
	# au village figé, la boîte de dialogue encore ouverte.
	var player := _player(Vector3(6.0, 0.0, 0.0))
	var enemy := _enemy(&"timere_normal", Vector3.ZERO)
	var chasing: bool = await wait_until(func() -> bool: return enemy.state() == &"chase", 3.0)
	assert_true(chasing, "poursuite engagée")
	EventBus.dialogue_started.emit(&"pannibal")
	var stopped: bool = await wait_until(func() -> bool: return enemy.state() == &"idle", 2.0)
	assert_true(stopped, "en conversation : plus de poursuite")
	await wait_seconds(0.5)
	assert_gt(_flat_distance(enemy, player), 1.0, "il ne vient pas frapper")
	EventBus.dialogue_ended.emit(&"pannibal")
	var resumed: bool = await wait_until(func() -> bool: return enemy.state() == &"chase", 3.0)
	assert_true(resumed, "la conversation finie, la poursuite reprend")


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


func test_forest_has_four_free_timeres_that_drop_nothing() -> void:
	var placement: Node3D = autofree(FOREST.instantiate())
	var counts := {}
	for child: Node in placement.get_children():
		var enemy := child as Enemy
		assert_not_null(enemy, "%s est un Enemy" % child.name)
		if enemy == null:
			continue
		counts[enemy.enemy_id()] = int(counts.get(enemy.enemy_id(), 0)) + 1
		assert_false(enemy.always_chase, "%s est un ennemi libre" % child.name)
		assert_true(
			enemy.data.drops.is_empty(), "%s ne lâche rien (Timere ignore les objets)" % child.name
		)
		assert_lt(Vector2(enemy.position.x, enemy.position.z).length(), 6.0, "dans la clairière")
	assert_eq_deep(counts, {&"timere_small": 2, &"timere_normal": 1, &"timere_runner": 1})


# --- (H7) Lisibilité en vue fixe ---------------------------------------------------------------


func test_windup_shows_the_exact_strike_zone_then_strikes(
	enemy_id: StringName = use_parameters([&"timere_small", &"timere_normal", &"timere_big"])
) -> void:
	var player := _player()
	var enemy := _enemy(enemy_id, Vector3(3.0, 0.0, 0.0))
	var winding: bool = await wait_until(func() -> bool: return enemy.state() == &"windup", 6.0)
	assert_true(winding, "%s se prépare avant de frapper" % enemy_id)
	if not winding:
		return
	var started := Engine.get_physics_frames()
	var attack := enemy.prepared_attack()
	assert_not_null(attack, "%s : attaque préparée" % enemy_id)
	assert_eq(enemy.telegraph.mode(), &"strike", "%s : zone au sol" % enemy_id)
	var reach := enemy.attack_reach(attack)
	var radius := maxf(reach * 0.5, Enemy.HITBOX_MIN_RADIUS)
	assert_almost_eq(enemy.telegraph.zone_radius(), radius, 0.001, "zone = sphère de la Hitbox")
	var center := enemy.telegraph.zone_center()
	assert_almost_eq(
		center.length(), enemy.engage_distance(attack) - radius, 0.01, "%s : à portée" % enemy_id
	)
	assert_gt(
		center.normalized().dot(_flat_to(enemy, player)),
		0.95,
		"%s : tournée vers le joueur" % enemy_id
	)
	assert_false(enemy.hitbox.is_active(), "%s : rien ne touche pendant la préparation" % enemy_id)
	await wait_physics_frames(roundi(enemy.windup_duration(attack) * 30.0))
	assert_lt(enemy.visual.scale.y, enemy.data.scale, "%s : il se ramasse" % enemy_id)
	var striking: bool = await wait_until(func() -> bool: return enemy.state() == &"attack", 2.0)
	assert_true(striking, "%s : puis le coup part" % enemy_id)
	var frames := Engine.get_physics_frames() - started
	assert_gte(
		frames + 1,
		floori(enemy.windup_duration(attack) * Engine.physics_ticks_per_second),
		"%s : préparation entière (%d images)" % [enemy_id, frames]
	)
	assert_eq(enemy.telegraph.mode(), &"", "%s : signes effacés au coup" % enemy_id)
	assert_almost_eq(enemy.visual.scale.y, enemy.data.scale, 0.001, "posture rendue")


func test_windup_does_not_slow_the_attack_cadence() -> void:
	# Au contact, la préparation se loge dans la recharge : un coup toutes les
	# anim + cooldown × [0,7 ; 1,3] s, comme avant (jeu.js : 1,3 à 2 s).
	var player := _player()
	(player.get_node(^"Health") as Health).max_hp = 99
	var enemy := _enemy(&"timere_small", Vector3(1.0, 0.0, 0.0))
	var starts: Array[int] = []
	var previous: Array[StringName] = [&""]
	var track := func() -> void:
		if enemy.state() == &"attack" and previous[0] != &"attack":
			starts.append(Engine.get_physics_frames())
		previous[0] = enemy.state()
	get_tree().physics_frame.connect(track)
	await wait_until(func() -> bool: return starts.size() >= 4, 8.0)
	get_tree().physics_frame.disconnect(track)
	assert_gte(starts.size(), 4, "quatre morsures")
	var anim := 0.5
	var low := anim + BITE.cooldown * Enemy.COOLDOWN_JITTER.x
	var high := anim + BITE.cooldown * Enemy.COOLDOWN_JITTER.y
	for i in range(1, starts.size()):
		var gap := float(starts[i] - starts[i - 1]) / Engine.physics_ticks_per_second
		assert_between(gap, low - 0.05, high + 0.05, "intervalle %d : %.2f s" % [i, gap])


func test_a_blow_during_the_windup_cancels_the_attack() -> void:
	_player()
	var enemy := _enemy(&"timere_normal", Vector3(2.5, 0.0, 0.0))
	var winding: bool = await wait_until(func() -> bool: return enemy.state() == &"windup", 6.0)
	assert_true(winding)
	var source := Node3D.new()
	_world.add_child(source)
	source.position = Vector3(-1.0, 0.0, 0.0)
	assert_true(enemy.hurtbox.receive_hit(SWORD, source))
	assert_eq(enemy.state(), &"hurt", "interrompu")
	assert_eq(enemy.telegraph.mode(), &"", "signes effacés")
	await wait_seconds(0.5)
	assert_ne(enemy.state(), &"attack", "pas de coup juste après : la recharge court")


func test_runner_shows_its_lane_and_rushes_along_it() -> void:
	var player := _player()
	var runner := _enemy(&"timere_runner", Vector3(6.0, 0.0, 0.0))
	var winding: bool = await wait_until(func() -> bool: return runner.state() == &"windup", 2.0)
	assert_true(winding, "le bondissant se ramasse avant de charger")
	if not winding:
		return
	assert_eq(runner.prepared_attack(), RUSH, "c'est la charge qui se prépare")
	assert_eq(runner.telegraph.mode(), &"rush", "couloir au sol")
	assert_eq(runner.velocity.x, 0.0, "immobile pendant la préparation")
	var lane := _flat_to(runner, player)
	# Le joueur s'écarte : la charge garde le couloir montré.
	player.position = Vector3(0.0, 0.0, 3.0)
	var rushing: bool = await wait_until(func() -> bool: return runner.state() == &"rush", 1.0)
	assert_true(rushing, "puis il charge")
	var heading := Vector3(runner.velocity.x, 0.0, runner.velocity.z).normalized()
	assert_gt(heading.dot(lane), 0.99, "dans le couloir annoncé")


func test_big_prepares_longer_than_a_normal() -> void:
	var big := _enemy(&"timere_big", Vector3(-5.0, 0.0, 0.0))
	var normal := _enemy(&"timere_normal", Vector3(5.0, 0.0, 0.0))
	var whip := load("res://data/attacks/whip.tres") as AttackData
	assert_almost_eq(normal.windup_duration(whip), whip.windup, 0.001)
	assert_almost_eq(big.windup_duration(whip), whip.windup * 1.5, 0.001, "le Grand : × 1,5")


func test_approach_from_the_north_ends_on_a_side_of_the_screen() -> void:
	var player := _player()
	var enemy := _enemy(&"timere_normal", Vector3(0.02, 0.0, -4.5))
	var engaged: bool = await wait_until(
		func() -> bool: return enemy.state() in [&"windup", &"attack"], 6.0
	)
	assert_true(engaged, "le Normal arrive au contact")
	var offset := enemy.global_position - player.global_position
	var angle := rad_to_deg(atan2(absf(offset.x), absf(offset.z)))
	assert_gt(angle, 15.0, "pas pile au nord du joueur, où son sprite le cacherait (%.0f°)" % angle)
	assert_lt(angle, 50.0, "encore dans l'arc de l'épée tournée vers lui (%.0f°)" % angle)


func test_timeres_in_a_column_spread_across_the_screen() -> void:
	_player()
	var front := _enemy(&"timere_small", Vector3(0.0, 0.0, -4.0))
	var back := _enemy(&"timere_small", Vector3(0.0, 0.0, -5.0))
	await wait_seconds(1.6)
	var gap := front.global_position - back.global_position
	assert_gt(absf(gap.x), 0.6, "ils s'écartent de côté (%.2f m), pas en file" % gap.x)


func test_bodies_are_tinted_and_have_a_crisp_shadow() -> void:
	for enemy_id: StringName in TYPES:
		var enemy := _enemy(enemy_id, Vector3(0.0, 0.0, 0.0))
		var sprite := enemy.visual.get_node(^"Sprite") as AnimatedSprite3D
		assert_eq(sprite.modulate, enemy.data.tint, "%s : teinte de ses données" % enemy_id)
		var shadow := enemy.get_node_or_null(^"GroundShadow") as MeshInstance3D
		assert_not_null(shadow, "%s : ombre nette" % enemy_id)
		if shadow != null:
			var size := (shadow.mesh as PlaneMesh).size.x
			assert_almost_eq(
				size,
				2.0 * (0.4 + Enemy.SHADOW_MARGIN) * enemy.data.scale,
				0.01,
				"%s : à la taille de son corps, pas de son dessin" % enemy_id
			)
		enemy.queue_free()


func test_a_blow_flashes_and_freezes_even_the_stoic_big() -> void:
	var big := _enemy(&"timere_big", Vector3.ZERO)
	var source := Node3D.new()
	_world.add_child(source)
	source.position = Vector3(-1.0, 0.0, 0.0)
	await wait_physics_frames(2)
	assert_true(big.hurtbox.receive_hit(SWORD, source))
	assert_true(big.hit_flash.is_flashing() or big.hit_flash.visible, "éclair")
	assert_true(CombatFx.is_frozen(big.visual), "arrêt sur image de la planche")
	assert_almost_eq(big.hitstop_left(), SWORD.hitstop, 0.001)
	assert_eq(big.knockback(), Vector3.ZERO, "mais toujours aucun recul sous l'épée")


func _flat_to(from: Node3D, to: Node3D) -> Vector3:
	var offset := to.global_position - from.global_position
	return Vector3(offset.x, 0.0, offset.z).normalized()
