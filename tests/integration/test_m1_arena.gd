extends "res://tests/stubs/m1_game_test.gd"
## Intégration M1, l'arène des dunes dans le vrai jeu (src/game.tscn) : téléportation, panneau
## « Sonner la cloche de veille » (appui réel sur interact), vague 1 de 5 Timeres sortis des 4
## points, Timeres qui atteignent le joueur (même derrière le poteau du panneau), score à
## l'épée, fin de série en sortant de l'arène entre deux vagues, Grand dès la vague 3 et jamais
## deux à la fois, mort du joueur : arena_finished, record, sauvegarde, réapparition au village.

const PROMPT := "Sonner la cloche de veille"
## Devant le panneau, côté village (local à la zone des dunes) : départ des séries.
const PANEL_FRONT := Vector3(10.6, 0.0, -2.0)
## Rayon (m) autour d'un point d'apparition où sort un Timere (WaveDirector.SPAWN_SPREAD ±1 m).
const SPAWN_TOLERANCE := 1.5


## Joueur devant le panneau, tourné vers lui ; appui réel sur interact.
func _start_series_from_panel() -> void:
	await place_player(&"dunes", PANEL_FRONT, Vector3.LEFT)
	assert_eq(player.current_prompt(), PROMPT, "invite du panneau")
	await press(&"interact")
	assert_true(director.is_running(), "la série a commencé")


## Joueur qui encaisse (99 PV) : pour les tests où il ne doit pas mourir.
func _sturdy_player() -> void:
	health.max_hp = 99
	health.reset()


func _marker_near(at: Vector3) -> StringName:
	for marker_name: String in director.config()["spawn_points"]:
		var marker := arena.spawn_point(StringName(marker_name))
		if flat_distance(marker.global_position, at) <= SPAWN_TOLERANCE:
			return StringName(marker_name)
	return &""


func test_teleport_then_panel_starts_wave_one_from_the_four_points() -> void:
	await start_game()
	watch_signals(EventBus)
	WorldManager.teleport(&"dunes")
	await wait_physics_frames(3)
	assert_eq(WorldManager.current_zone(), &"dunes", "téléporté aux dunes")
	# Du Spawn des dunes au panneau, à pied, jusqu'à son invite.
	var panel := arena.get_node(^"Panel") as Node3D
	player.set_aim_direction(panel.global_position - player.global_position, true)
	hold_toward(player.aim_direction())
	var shown: bool = await wait_until(
		func() -> bool: return player.current_prompt() == PROMPT, 6.0
	)
	release_move()
	assert_true(shown, "invite « %s » en arrivant au panneau" % PROMPT)
	await wait_physics_frames(6)
	var spawned: Array[String] = []
	listen(
		EventBus.enemy_spawned,
		func(enemy: Node3D, enemy_id: StringName) -> void:
			spawned.append("%s@%s" % [enemy_id, _marker_near(enemy.global_position)])
	)
	var pressed_at := Engine.get_physics_frames()
	await press(&"interact")
	assert_true(director.is_running(), "interact → série")
	await wait_physics_frames(2)
	assert_eq(player.current_prompt(), "", "panneau inactif pendant la série")
	var first: bool = await wait_until(func() -> bool: return not spawned.is_empty(), 3.0)
	assert_true(first, "premier Timere")
	var delay := float(Engine.get_physics_frames() - pressed_at) / Engine.physics_ticks_per_second
	assert_almost_eq(delay, 2.0, 0.15, "1,2 s de pause puis 0,8 s (jeu.js)")
	assert_signal_emitted_with_parameters(EventBus, "wave_started", [&"dunes", 1, 5])
	# Cadence réelle vérifiée pour le premier ; la suite de la vague est accélérée.
	director.set_config(fast_waves())
	await wait_until(func() -> bool: return spawned.size() == 5, 4.0)
	assert_eq(spawned.size(), 5, "vague 1 : 5 Timeres (3 + 2 × 1)")
	var counts := {}
	for entry: String in spawned:
		assert_false(entry.ends_with("@"), "%s : sorti d'un des 4 points" % entry)
		var enemy_id := entry.get_slice("@", 0)
		counts[enemy_id] = int(counts.get(enemy_id, 0)) + 1
	assert_eq_deep(counts, {"timere_small": 3, "timere_normal": 2})


func test_wave_timeres_from_each_point_reach_the_player() -> void:
	await start_game()
	await place_player(&"dunes", Vector3.ZERO, Vector3.FORWARD)
	_sturdy_player()
	director.set_config(fast_waves())
	director.random_seed = 3
	director.start()
	await wait_until(func() -> bool: return director.alive_enemies().size() == 5, 3.0)
	var enemies := director.alive_enemies()
	# Un Timere sur chacun des 4 points (le 5e sur le premier), comme à leur sortie.
	var points: Array = director.config()["spawn_points"]
	for i in enemies.size():
		var marker := arena.spawn_point(StringName(points[i % points.size()]))
		enemies[i].global_position = marker.global_position
	var reached := {}
	var watch := func() -> void:
		for enemy: Enemy in enemies:
			if is_instance_valid(enemy) and enemy.state() == &"attack":
				reached[enemy.enemy_id() + str(enemy.get_instance_id())] = true
	get_tree().physics_frame.connect(watch)
	var all_reached: bool = await wait_until(func() -> bool: return reached.size() == 5, 9.0)
	get_tree().physics_frame.disconnect(watch)
	assert_true(
		all_reached, "les 5 Timeres atteignent le joueur et l'attaquent (%d)" % reached.size()
	)
	assert_lt(health.current, health.max_hp, "et le blessent")


func test_timere_goes_around_the_panel_post() -> void:
	await start_game()
	await place_player(&"dunes", PANEL_FRONT, Vector3.LEFT)
	_sturdy_player()
	# Le poteau du panneau (9, −2) est entre le Timere et le joueur.
	var small := spawn_enemy(&"timere_small", dunes.to_global(Vector3(2.0, 0.0, -2.0)))
	small.always_chase = true
	var reached: bool = await wait_until(func() -> bool: return small.state() == &"attack", 6.0)
	assert_true(reached, "le Timere contourne le poteau et mord")


func test_panel_only_starts_a_series_from_inside_the_arena() -> void:
	await start_game()
	await place_player(&"dunes", PANEL_FRONT, Vector3.LEFT)
	var panel := arena.get_node(^"Panel") as Node3D
	var shown := 0
	for distance: float in [0.8, 1.4, 2.0, 2.4, 2.6, 2.9, 3.3]:
		for angle in range(-180, 180, 45):
			var side := Vector3.RIGHT.rotated(Vector3.UP, deg_to_rad(angle))
			player.global_position = WorldManager.ground_position(
				panel.global_position + side * distance, player
			)
			player.set_aim_direction(-side)
			await wait_physics_frames(2)
			if player.current_prompt() == PROMPT:
				shown += 1
				assert_true(
					arena.contains(player.global_position),
					"invite visible hors de l'arène (%.1f m, %d°)" % [distance, angle]
				)
	assert_gt(shown, 12, "le panneau s'active de près, de tous côtés")


func test_sword_kill_in_the_arena_scores() -> void:
	await start_game()
	director.set_config(fast_waves())
	watch_signals(EventBus)
	await _start_series_from_panel()
	await wait_until(func() -> bool: return director.alive_enemies().size() == 5, 3.0)
	var small: Enemy = null
	for enemy: Enemy in director.alive_enemies():
		if enemy.enemy_id() == &"timere_small":
			small = enemy
	assert_not_null(small, "un Petit dans la vague 1")
	if small == null:
		return
	small.set_physics_process(false)
	small.global_position = ahead(1.0)
	var frames: Array[String] = []
	small.health.damaged.connect(
		func(_amount: int, _source: Node3D) -> void:
			frames.append(
				"%s:%d" % [player.visual.current_animation(), player.visual.current_frame()]
			)
	)
	await wait_physics_frames(2)
	await press(&"attack")
	var killed: bool = await wait_until(func() -> bool: return small.is_dead(), 1.0)
	assert_true(killed, "le Petit meurt d'un coup d'épée")
	assert_eq(frames.size(), 1)
	if frames.size() == 1:
		var frame := int(frames[0].get_slice(":", 1))
		assert_true(
			frames[0].begins_with("attaque:") and player.visual.hit_frames(&"attaque").has(frame),
			"touché sur une image « coup » (%s)" % frames[0]
		)
	assert_signal_emitted_with_parameters(EventBus, "enemy_killed", [&"timere_small", 10])
	assert_signal_emitted_with_parameters(EventBus, "arena_score_changed", [&"dunes", 10])
	assert_eq(director.score(), 10)


func test_leaving_the_arena_before_a_wave_ends_the_series() -> void:
	await start_game()
	watch_signals(EventBus)
	await _start_series_from_panel()
	# Pendant la pause d'avant la vague 1, le joueur ressort à l'est en courant.
	player.set_aim_direction(Vector3.RIGHT, true)
	Input.action_press(&"run")
	hold_toward(player.aim_direction())
	var stopped: bool = await wait_until(func() -> bool: return not director.is_running(), 1.2)
	release_move()
	Input.action_release(&"run")
	assert_true(stopped, "sortir de l'arène entre deux vagues termine la série")
	assert_false(arena.contains(player.global_position))
	assert_signal_emitted_with_parameters(EventBus, "arena_finished", [&"dunes", 0, false])
	assert_signal_not_emitted(EventBus, "wave_started", "aucune vague")
	assert_eq(director.alive_enemies().size(), 0)


func test_leaving_during_a_wave_lasts_until_it_is_cleared() -> void:
	await start_game()
	director.set_config(fast_waves())
	watch_signals(EventBus)
	await _start_series_from_panel()
	await wait_until(func() -> bool: return director.alive_enemies().size() == 5, 3.0)
	# Hors du disque de 12 m, toujours dans la zone des dunes : la vague continue.
	player.global_position = dunes.to_global(Vector3(14.0, 0.05, 0.0))
	await wait_seconds(0.3)
	assert_eq(WorldManager.current_zone(), &"dunes")
	assert_true(director.is_running(), "pendant une vague, la série continue")
	var points := 0
	for enemy: Enemy in director.alive_enemies():
		points += enemy.data.points
		enemy.health.take_damage(99, player)
	var stopped: bool = await wait_until(func() -> bool: return not director.is_running(), 1.0)
	assert_true(stopped, "vague nettoyée hors de l'arène : fin de la série")
	assert_signal_emitted_with_parameters(EventBus, "wave_cleared", [&"dunes", 1, 50])
	assert_signal_emitted_with_parameters(EventBus, "arena_finished", [&"dunes", points + 50, true])
	assert_eq(GameState.best_score(&"dunes"), points + 50, "record : points + bonus 50 × 1")


func test_big_from_wave_three_never_two_at_once() -> void:
	await start_game()
	await place_player(&"dunes", Vector3.ZERO, Vector3.FORWARD)
	_sturdy_player()
	director.set_config(fast_waves())
	# Graine dont une vague générée (4 à 7) tire deux Grands : le second doit attendre.
	var chosen := 0
	var double_wave := 0
	for candidate in range(1, 300):
		director.random_seed = candidate
		for wave in range(4, 8):
			if director.compose(wave).count(&"timere_big") >= 2:
				double_wave = wave
				break
		if double_wave != 0:
			chosen = candidate
			break
	assert_ne(chosen, 0, "une graine avec deux Grands dans une vague")
	director.random_seed = chosen
	watch_signals(EventBus)
	var spawns: Array[String] = []
	var most_bigs: Array[int] = [0]
	listen(
		EventBus.enemy_spawned,
		func(enemy: Node3D, enemy_id: StringName) -> void:
			var wave := director.current_wave()
			spawns.append("%d:%s" % [wave, enemy_id])
			var bigs := 0
			for alive: Enemy in director.alive_enemies():
				bigs += 1 if alive.enemy_id() == &"timere_big" else 0
			most_bigs[0] = maxi(most_bigs[0], bigs)
			var data_enemy := enemy as Enemy
			var bonus := minf(0.5, 0.04 * wave)
			assert_almost_eq(
				data_enemy.speed_multiplier, 1.0 + bonus, 0.001, "vitesse vague %d" % wave
			)
			if enemy_id == &"timere_normal":
				assert_eq(
					data_enemy.bonus_hp, 1 if wave >= 6 else 0, "PV du Normal, vague %d" % wave
				)
	)
	# Les Timeres meurent aussitôt sortis ; un Grand vit 0,4 s (le suivant doit l'attendre).
	var born := {}
	var reaper := func() -> void:
		for enemy: Enemy in director.alive_enemies():
			var id := enemy.get_instance_id()
			if not born.has(id):
				born[id] = Engine.get_physics_frames()
			var age := Engine.get_physics_frames() - int(born[id])
			if enemy.enemy_id() != &"timere_big" or age >= 24:
				enemy.health.take_damage(99, player)
	get_tree().physics_frame.connect(reaper)
	director.start()
	var done: bool = await wait_until(
		func() -> bool: return get_signal_emit_count(EventBus, "wave_cleared") >= 7, 15.0
	)
	get_tree().physics_frame.disconnect(reaper)
	director.stop()
	assert_true(done, "7 vagues jouées")
	for wave in range(1, 8):
		assert_signal_emitted_with_parameters(
			EventBus, "wave_started", [&"dunes", wave, 3 + 2 * wave], wave - 1
		)
	var bigs_by_wave := {}
	var first_runner := 99
	for entry: String in spawns:
		var wave := int(entry.get_slice(":", 0))
		if entry.ends_with("timere_big"):
			bigs_by_wave[wave] = int(bigs_by_wave.get(wave, 0)) + 1
		if entry.ends_with("timere_runner"):
			first_runner = mini(first_runner, wave)
	assert_eq(first_runner, 2, "Coureur dès la vague 2")
	assert_false(bigs_by_wave.has(1) or bigs_by_wave.has(2), "pas de Grand avant la vague 3")
	assert_eq(int(bigs_by_wave.get(3, 0)), 1, "un Grand à la vague 3")
	assert_eq(int(bigs_by_wave.get(double_wave, 0)), 2, "deux Grands à la vague %d" % double_wave)
	assert_eq(most_bigs[0], 1, "jamais deux Grands vivants à la fois")
	assert_eq(get_signal_emit_count(EventBus, "player_heal_requested"), 3, "soin vagues 2, 4, 6")


func test_death_in_the_arena_records_the_score_and_respawns_at_the_village() -> void:
	await start_game()
	director.set_config(fast_waves())
	watch_signals(EventBus)
	await _start_series_from_panel()
	await wait_until(func() -> bool: return director.alive_enemies().size() == 5, 3.0)
	# Un Timere tué (des points à enregistrer), les quatre autres autour du joueur.
	var enemies := director.alive_enemies()
	var points := enemies[0].data.points
	enemies[0].health.take_damage(99, player)
	for i in range(1, enemies.size()):
		var angle := TAU * i / 4.0
		enemies[i].global_position = (
			player.global_position + Vector3(cos(angle), 0.0, sin(angle)) * 1.4
		)
	await press(&"lock_target")
	assert_not_null(player.locked_target(), "verrou sur un Timere de l'arène")
	var hits: Array[int] = []
	health.damaged.connect(
		func(_amount: int, _source: Node3D) -> void: hits.append(Engine.get_physics_frames())
	)
	var died: bool = await wait_until(func() -> bool: return health.is_dead(), 12.0)
	var died_ms := Time.get_ticks_msec()
	assert_true(died, "cinq morsures : mort")
	assert_eq(hits.size(), 5, "cinq dégâts d'un PV")
	for k in range(1, hits.size()):
		assert_gte(hits[k] - hits[k - 1], 72, "jamais deux dégâts en moins de 1,2 s")
	assert_false(director.is_running(), "la mort termine la série")
	assert_signal_emitted_with_parameters(EventBus, "arena_finished", [&"dunes", points, true])
	assert_eq(GameState.best_score(&"dunes"), points, "record gardé dans GameState")
	assert_eq(int(GameState.arena_record(&"dunes").get("games", 0)), 1)
	await wait_physics_frames(2)
	assert_null(player.locked_target(), "verrou levé à la mort")
	for enemy: Node in arena.get_node(^"Spawned").get_children():
		assert_true(
			(enemy as Enemy).is_dead() or enemy.is_queued_for_deletion(),
			"Timeres de la série retirés"
		)
	assert_eq(SaveManager.flush(), OK)
	var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(SaveManager.save_path))
	assert_true(saved is Dictionary, "sauvegarde écrite après arena_finished")
	if saved is Dictionary:
		var best: Dictionary = (saved as Dictionary)["best_scores"]["dunes"]
		assert_eq(int(best["score"]), points, "record sauvegardé")
	var respawned: bool = await wait_until(func() -> bool: return not health.is_dead(), 4.0)
	assert_true(respawned, "réapparition")
	assert_gte(Time.get_ticks_msec() - died_ms, 2000, "après respawn_delay (2,2 s)")
	await wait_physics_frames(3)
	var spawn := zone(&"village").get_node(^"Spawn") as Node3D
	assert_lt(flat_distance(player.global_position, spawn.global_position), 0.5, "au village")
	assert_eq(WorldManager.current_zone(), &"village")
	assert_eq(health.current, 5, "PV pleins")
	assert_eq(combat.current_state(), &"idle")
	assert_eq(player.visual.current_animation(), &"repos")
	assert_true(player.visual.visible)
	assert_null(player.camera_rig.lock_target, "caméra sans cible")
	assert_lt(
		flat_distance(
			player.camera_rig.focus(),
			player.global_position + Vector3.FORWARD * player.camera_rig.focus_ahead
		),
		1.5,
		"(HD-2D) caméra fixe recalée sur le joueur (point visé au nord de lui)"
	)
	var facing := -spawn.global_basis.z
	assert_almost_eq(player.aim_direction(), facing, Vector3.ONE * 0.01, "tourné vers la place")
	assert_almost_eq(
		player.camera_rig.forward(), Vector3.FORWARD, Vector3.ONE * 0.01, "caméra fixe : le nord"
	)
	assert_eq(get_signal_emit_count(EventBus, "arena_finished"), 1, "une seule fin de série")
