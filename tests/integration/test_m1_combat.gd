extends "res://tests/stubs/m1_game_test.gd"
## Intégration M1, combat dans le vrai jeu (src/game.tscn, vrai joueur, vrais Timeres, appuis
## réels sur les actions) : enchaînement de l'épée, portées réelles de l'épée et des attaques
## des Timeres, images « coup », dégâts du joueur (1 PV, invincibilité, recul), Grand stoïque,
## onde qui traverse, verrouillage d'un Timere de l'arène.

## Coin plat et dégagé de l'arène des dunes, loin du panneau (local à la zone).
const DUEL_SPOT := Vector3(-3.0, 0.0, 4.0)

var _hit_frames: Array[String] = []


## Retient l'image du joueur à chaque dégât reçu par enemy (« attaque:2 »).
func _watch_hits(enemy: Enemy) -> void:
	enemy.health.damaged.connect(
		func(_amount: int, _source: Node3D) -> void:
			_hit_frames.append(
				"%s:%d" % [player.visual.current_animation(), player.visual.current_frame()]
			)
	)


## Un coup d'épée complet : appui réel, puis attente du retour au repos (fenêtre
## d'enchaînement écoulée : le coup suivant repart de sword_1).
func _swing() -> void:
	await press(&"attack")
	await wait_until(func() -> bool: return combat.current_state() == &"idle", 1.0)
	await wait_seconds(combat.combo_window + 0.1)


func test_mashing_attack_chains_the_three_swords() -> void:
	await start_game()
	await place_player(&"dunes", DUEL_SPOT, Vector3.FORWARD)
	var started: Array[StringName] = []
	var idle_seen: Array[bool] = [false]
	combat.attack_started.connect(func(data: AttackData) -> void: started.append(data.id))
	var watch_idle := func() -> void:
		if not started.is_empty() and started.size() < 3 and combat.current_state() == &"idle":
			idle_seen[0] = true
	get_tree().physics_frame.connect(watch_idle)
	# Appuis toutes les 9 images (0,15 s) : la plupart tombent pendant un coup (0,29 s).
	for _i in 6:
		await press(&"attack")
		await wait_physics_frames(6)
	get_tree().physics_frame.disconnect(watch_idle)
	assert_eq(started, [&"sword_1", &"sword_2", &"sword_3"] as Array[StringName], "trois coups")
	assert_false(idle_seen[0], "enchaînés sans repasser au repos")
	# Après sword_3 : recharge (sword_3.cooldown), puis un appui repart de sword_1.
	await wait_until(func() -> bool: return combat.current_state() == &"idle", 1.0)
	await wait_seconds(0.4)
	await press(&"attack")
	assert_eq(started[-1], &"sword_1", "nouvel enchaînement")


func test_combo_lands_its_second_blow_on_a_normal() -> void:
	await start_game()
	await place_player(&"dunes", DUEL_SPOT, Vector3.FORWARD)
	health.max_hp = 99
	health.reset()
	# Un Normal (2 PV) vient au contact ; deux coups enchaînés doivent le tuer : le recul du
	# premier (sword_1.knockback) ne doit pas le sortir de la portée du second.
	var normal := spawn_enemy(&"timere_normal", ahead(3.0))
	var close: bool = await wait_until(
		func() -> bool: return flat_distance(normal.global_position, player.global_position) < 1.3,
		3.0
	)
	assert_true(close, "le Normal approche")
	var blows: Array[StringName] = []
	normal.health.damaged.connect(
		func(_amount: int, _source: Node3D) -> void: blows.append(combat.current_attack().id)
	)
	for _i in 3:
		await press(&"attack")
		await wait_physics_frames(6)
	await wait_until(func() -> bool: return combat.current_state() == &"idle", 1.0)
	assert_true(normal.is_dead(), "Normal tué")
	assert_eq(blows, [&"sword_1", &"sword_2"] as Array[StringName], "par les deux premiers coups")


func test_attack_presses_do_nothing_while_hurt_dead_or_talking() -> void:
	await start_game()
	await place_player(&"dunes", DUEL_SPOT, Vector3.FORWARD)
	var started: Array[StringName] = []
	combat.attack_started.connect(func(data: AttackData) -> void: started.append(data.id))
	health.take_damage(1, game)
	assert_eq(combat.current_state(), &"hurt")
	await press(&"attack")
	assert_eq(started.size(), 0, "pas de coup pendant les dégâts")
	await wait_until(func() -> bool: return combat.current_state() == &"idle", 1.0)
	EventBus.dialogue_started.emit(&"m1_test")
	await press(&"attack")
	assert_eq(started.size(), 0, "pas de coup pendant un dialogue")
	EventBus.dialogue_ended.emit(&"m1_test")
	await wait_physics_frames(2)
	await press(&"attack")
	assert_eq(started.size(), 1, "de nouveau libre")
	await wait_until(
		func() -> bool: return combat.current_state() == &"idle" and not health.is_invincible(), 2.0
	)
	WorldManager.respawn_delay = 30.0
	health.take_damage(10, game)
	assert_true(health.is_dead())
	await press(&"attack")
	assert_eq(started.size(), 1, "pas de coup une fois mort")


func test_sword_reaches_a_small_and_a_big_in_front_only() -> void:
	await start_game()
	await place_player(&"dunes", DUEL_SPOT, Vector3.FORWARD)
	watch_signals(EventBus)
	# Petit à 1 m devant : tué d'un coup.
	var small := spawn_enemy(&"timere_small", ahead(1.0), true)
	_watch_hits(small)
	await wait_physics_frames(2)
	await _swing()
	assert_true(small.is_dead(), "Petit à 1 m touché et tué")
	assert_signal_emitted_with_parameters(EventBus, "enemy_killed", [&"timere_small", 10])
	# Grand à 1,5 m (sa distance d'approche) : touché, ni recul ni état hurt.
	var big := spawn_enemy(&"timere_big", ahead(1.5), true)
	_watch_hits(big)
	await wait_physics_frames(2)
	await _swing()
	assert_eq(big.health.current, 4, "Grand à 1,5 m touché (5 → 4 PV)")
	assert_eq(big.knockback(), Vector3.ZERO, "le Grand ne recule pas sous l'épée")
	assert_ne(big.state(), &"hurt", "ni état hurt")
	big.queue_free()
	# Trop loin ou derrière : rien.
	var far_small := spawn_enemy(&"timere_small", ahead(1.8), true)
	var behind := spawn_enemy(&"timere_small", ahead(-1.0), true)
	var aside := spawn_enemy(&"timere_small", ahead(0.3, 1.0), true)
	await wait_physics_frames(2)
	await _swing()
	assert_eq(far_small.health.current, 1, "Petit à 1,8 m : hors de portée")
	assert_eq(behind.health.current, 1, "Petit derrière : hors de l'arc de 90°")
	assert_eq(aside.health.current, 1, "Petit sur le côté : hors de l'arc de 90°")
	var big_far := spawn_enemy(&"timere_big", ahead(1.9), true)
	await wait_physics_frames(2)
	await _swing()
	assert_eq(big_far.health.current, 5, "Grand à 1,9 m : hors de portée")
	assert_eq(_hit_frames.size(), 2, "deux coups portés")
	for hit: String in _hit_frames:
		var frame := int(hit.get_slice(":", 1))
		assert_true(
			hit.begins_with("attaque:") and player.visual.hit_frames(&"attaque").has(frame),
			"dégât sur une image « coup » de l'attaque (%s)" % hit
		)


func test_timere_at_contact_bites_once_with_invincibility_and_knockback() -> void:
	await start_game()
	await place_player(&"dunes", DUEL_SPOT, Vector3.FORWARD)
	var small := spawn_enemy(&"timere_small", ahead(3.0))
	var attacking: bool = await wait_until(func() -> bool: return small.state() == &"attack", 4.0)
	assert_true(attacking, "le Petit vient mordre")
	var reach := flat_distance(small.global_position, player.global_position)
	assert_lt(reach, small.engage_distance(small.current_attack()) + 0.05, "au contact")
	var start := player.global_position
	var bitten: bool = await wait_until(func() -> bool: return health.current == 4, 1.0)
	assert_true(bitten, "morsure : 1 PV")
	assert_almost_eq(health.invincibility_left(), 1.2, 0.05, "1,2 s d'invincibilité")
	assert_eq(combat.current_state(), &"hurt", "état dégâts")
	await wait_physics_frames(10)
	var away := (player.global_position - small.global_position).normalized()
	var pushed := player.global_position - start
	assert_gt(pushed.dot(away), 0.15, "recul en s'éloignant du Timere")
	# Pendant l'invincibilité, aucun autre dégât ; ensuite le Petit peut remordre.
	var hp_during := health.current
	await wait_until(func() -> bool: return not health.is_invincible(), 1.5)
	assert_eq(hp_during, 4)
	assert_eq(health.current, 4, "pas de second dégât pendant 1,2 s")


func test_bite_misses_a_player_out_of_reach() -> void:
	await start_game()
	await place_player(&"dunes", DUEL_SPOT, Vector3.FORWARD)
	var small := spawn_enemy(&"timere_small", ahead(3.0))
	await wait_until(func() -> bool: return small.state() == &"attack", 4.0)
	# Le joueur recule à 1,7 m avant l'image « coup » (0,125 s après le début de la morsure).
	var back := (player.global_position - small.global_position).normalized()
	back.y = 0.0
	player.global_position = small.global_position + back * 1.7
	var active_seen: Array[bool] = [false]
	var watch := func() -> void: active_seen[0] = active_seen[0] or small.hitbox.is_active()
	get_tree().physics_frame.connect(watch)
	await wait_until(func() -> bool: return small.state() != &"attack", 1.0)
	get_tree().physics_frame.disconnect(watch)
	assert_true(active_seen[0], "la morsure a bien eu lieu")
	assert_eq(health.current, 5, "à 1,7 m, la morsure du Petit ne touche pas")


func test_charge_wave_pierces_aligned_timeres() -> void:
	await start_game()
	await place_player(&"dunes", DUEL_SPOT, Vector3.FORWARD)
	var small := spawn_enemy(&"timere_small", ahead(2.0), true)
	var normal := spawn_enemy(&"timere_normal", ahead(3.5), true)
	var big := spawn_enemy(&"timere_big", ahead(5.0), true)
	var big_start := big.global_position
	await wait_physics_frames(2)
	# Relâchée trop tôt (0,3 s < 0,55 s) : pas d'onde.
	var waves: Array[Node3D] = []
	combat.wave_launched.connect(func(wave: Node3D) -> void: waves.append(wave))
	await hold(&"charge", 0.3)
	await wait_physics_frames(2)
	assert_eq(waves.size(), 0, "charge trop courte : rien")
	await hold(&"charge", 0.65)
	var launched: bool = await wait_until(func() -> bool: return waves.size() == 1, 0.5)
	assert_true(launched, "onde lancée")
	await wait_until(func() -> bool: return not is_instance_valid(waves[0]), 1.0)
	assert_true(small.is_dead(), "Petit traversé (3 dégâts)")
	assert_true(normal.is_dead(), "Normal traversé (3 dégâts)")
	assert_eq(big.health.current, 2, "Grand traversé : 5 − 3")
	assert_gt(big.knockback().dot(player.aim_direction()), 1.0, "le Grand recule sous l'onde")
	assert_eq(big.state(), &"hurt")
	assert_almost_eq(combat.wave_cooldown_left(), 1.2 - 0.42, 0.2, "recharge en cours")
	big.set_physics_process(true)
	await wait_physics_frames(15)
	assert_gt(
		(big.global_position - big_start).dot(player.aim_direction()), 0.3, "il s'est éloigné"
	)


func test_lock_on_aims_combat_and_wave_at_an_arena_timere_until_it_dies() -> void:
	await start_game()
	await place_player(&"dunes", Vector3.ZERO, Vector3.FORWARD)
	director.set_config(fast_waves())
	director.random_seed = 7
	director.start()
	await wait_until(func() -> bool: return director.alive_enemies().size() == 5, 3.0)
	var enemies := director.alive_enemies()
	# Un Timere de la vague, à 3 m à l'est (le joueur regarde au nord) ; les autres au loin.
	var target := enemies[0]
	for enemy: Enemy in enemies:
		enemy.set_physics_process(false)
	target.global_position = player.global_position + Vector3(3.0, 0.0, 0.0)
	for i in range(1, enemies.size()):
		enemies[i].global_position = player.global_position + Vector3(-8.0, 0.0, 2.0 * i)
	await wait_physics_frames(2)
	await press(&"lock_target")
	assert_eq(player.locked_target(), target, "verrou sur le Timere le plus proche")
	assert_eq(player.camera_rig.lock_target, target, "la caméra le cadre")
	assert_almost_eq(
		-combat.global_basis.z, Vector3.RIGHT, Vector3.ONE * 0.01, "Combat −Z vers lui"
	)
	var waves: Array[Node3D] = []
	combat.wave_launched.connect(func(wave: Node3D) -> void: waves.append(wave))
	await hold(&"charge", 0.65)
	await wait_until(func() -> bool: return waves.size() == 1, 0.5)
	assert_eq(waves.size(), 1, "onde lancée")
	if waves.is_empty():
		return
	assert_almost_eq(-waves[0].global_basis.z, Vector3.RIGHT, Vector3.ONE * 0.01, "onde vers lui")
	var dead: bool = await wait_until(func() -> bool: return target.is_dead(), 1.0)
	assert_true(dead, "touché par l'onde (3 dégâts)")
	await wait_physics_frames(2)
	assert_null(player.locked_target(), "verrou perdu à sa mort")
	assert_null(player.camera_rig.lock_target)
