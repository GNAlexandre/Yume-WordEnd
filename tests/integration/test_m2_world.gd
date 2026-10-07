extends "res://tests/stubs/m2_game_test.gd"
## Intégration M2, parcours 5 : le monde dans la vraie partie. Les cinq zones affichent leur nom
## dans le HUD (docs/lore/MONDE.md, section 2.1) ; des allers-retours sur une frontière ne le
## répètent pas (ni l'auto-sauvegarde) ; un Timere au pied de la barrière n'entre pas au
## village ; sous l'île, la KillZone ramène au Spawn de la zone ; le joueur qui court dans le vide
## depuis le bord de l'île flottante tombe, sans jamais passer les murs, et revient au Spawn de
## la zone ; pause et reprise (clavier, manette), inventaire ; retour au menu depuis la pause :
## partie écrite, plus suivie, aucune auto-sauvegarde ensuite, menu sans nouvel écran de clic et
## avec Continuer.

const NAMES := {
	&"village": "L'entrepôt des fées",
	&"dunes": "Le bord du Couchant",
	&"forest": "Les bois du marais",
	&"beach": "Le port et le bourg",
	&"hill": "La colline des étoiles",
}
## Face nord de la barrière du village (coordonnées de l'île) ; les Bounds se touchent à z = −22.
const BARRIER_NORTH_FACE := -22.5


func _focus_owner() -> Control:
	return get_viewport().gui_get_focus_owner()


func test_each_zone_shows_its_name_once_even_along_a_border() -> void:
	assert_true(await new_game_from_menu(), "nouvelle partie")
	var entered: Array[StringName] = []
	listen(EventBus.zone_entered, func(zone_id: StringName) -> void: entered.append(zone_id))
	var writes: Array[String] = []
	listen(SaveManager.saved, func(path: String) -> void: writes.append(path))
	# Les cinq zones, par leur Spawn (côté village) : nom de chacune dans le HUD.
	for zone_id: StringName in [&"dunes", &"forest", &"beach", &"hill", &"village"]:
		WorldManager.teleport(zone_id)
		await wait_physics_frames(3)
		assert_eq(WorldManager.current_zone(), zone_id, "%s : zone courante" % zone_id)
		assert_eq(zone_banner(), NAMES[zone_id], "%s : nom affiché" % zone_id)
	assert_eq(entered, [&"dunes", &"forest", &"beach", &"hill", &"village"], "une fois chacune")
	# Le long de la frontière nord du village : on effleure la forêt, on recule, quatre fois.
	await place_player(&"village", Vector3(0.0, 0.0, -20.5), Vector3.FORWARD)
	await wait_seconds(0.6)
	entered.clear()
	writes.clear()
	for _round in 4:
		var touched: bool = await walk_keys_until(
			[KEY_W], func() -> bool: return player.global_position.z < -21.75, 2.0
		)
		assert_true(touched, "la forêt effleurée")
		var back: bool = await walk_keys_until(
			[KEY_S], func() -> bool: return player.global_position.z > -21.3, 2.0
		)
		assert_true(back, "retour au village")
	assert_eq(entered, [&"forest"], "la forêt annoncée une seule fois")
	await wait_seconds(0.8)
	assert_lte(writes.size(), 1, "une seule auto-sauvegarde pour ces allers-retours")
	# Vraie sortie vers la forêt puis retour : chaque changement est annoncé.
	await walk_keys_until([KEY_W], func() -> bool: return player.global_position.z < -24.0, 3.0)
	await walk_keys_until(
		[KEY_S], func() -> bool: return WorldManager.current_zone() == &"village", 3.0
	)
	assert_eq(entered, [&"forest", &"village"], "retour au village annoncé")
	assert_eq(zone_banner(), NAMES[&"village"])


func test_no_timere_enters_the_village() -> void:
	assert_true(await new_game_from_menu(), "nouvelle partie")
	# Le joueur juste derrière la barrière nord, un Grand juste devant, côté forêt.
	await place_player(&"village", Vector3(0.0, 0.0, -19.0), Vector3.FORWARD)
	var big := spawn_enemy(&"timere_big", Vector3(0.0, 0.2, -24.5))
	var small := spawn_enemy(&"timere_small", Vector3(1.5, 0.2, -25.0))
	var deepest: Array[float] = [-INF]
	var watch := func() -> void:
		for timere: Enemy in [big, small]:
			if is_instance_valid(timere):
				deepest[0] = maxf(deepest[0], timere.global_position.z)
	get_tree().physics_frame.connect(watch)
	await wait_seconds(3.0)
	get_tree().physics_frame.disconnect(watch)
	assert_lt(deepest[0], BARRIER_NORTH_FACE, "aucun Timere n'est entré au village")
	assert_false(health.current < health.max_hp, "le joueur au village n'a pas été touché")


func test_a_fall_into_the_void_brings_the_player_back() -> void:
	assert_true(await new_game_from_menu(), "nouvelle partie")
	# Sous l'île (dans la KillZone) : retour au Spawn de la zone courante.
	WorldManager.teleport(&"beach")
	await wait_physics_frames(3)
	player.global_position = Vector3(10.0, -12.0, 60.0)
	var rescued: bool = await until(func() -> bool: return player.global_position.y > -2.0, 2.0)
	assert_true(rescued, "KillZone : rattrapé")
	var spawn := zone(&"beach").get_node(^"Spawn") as Node3D
	assert_lt(distance_to(spawn), 1.0, "au Spawn du port")
	# Au bord nord des bois, le joueur court droit dans le vide : il tombe le long de la falaise,
	# le mur du carré le retient, et il revient au Spawn des bois.
	await place_player(&"forest", Vector3(0.0, 0.0, -20.0), Vector3.FORWARD)
	assert_eq(WorldManager.current_zone(), &"forest")
	var lowest: Array[float] = [INF]
	var farthest: Array[float] = [INF]
	var watch := func() -> void:
		lowest[0] = minf(lowest[0], player.global_position.y)
		farthest[0] = minf(farthest[0], player.global_position.z)
	get_tree().physics_frame.connect(watch)
	var fell: bool = await walk_keys_until(
		[KEY_W, KEY_SHIFT], func() -> bool: return lowest[0] < -5.0, 4.0
	)
	var back: bool = await until(func() -> bool: return player.global_position.y > -2.0, 2.0)
	get_tree().physics_frame.disconnect(watch)
	assert_true(fell, "tombé du bord dans le vide")
	assert_true(back, "rattrapé")
	assert_gt(farthest[0], -80.5, "retenu par le mur du carré")
	assert_lt(farthest[0], IslandTerrain.edge_point(-PI / 2.0).y, "parti au-delà du bord")
	var forest_spawn := zone(&"forest").get_node(^"Spawn") as Node3D
	assert_lt(distance_to(forest_spawn), 1.0, "au Spawn des bois")


func test_pause_and_inventory_with_keyboard_and_gamepad() -> void:
	assert_true(await new_game_from_menu(), "nouvelle partie")
	GameState.add_item(&"shell", 2)
	# Échap : pause ; Échap : reprise.
	await tap_key(KEY_ESCAPE)
	assert_true(pause_menu.call(&"is_open"), "Échap : pause")
	assert_true(get_tree().paused)
	assert_eq(_focus_owner(), pause_menu.get_node("%ResumeButton"), "focus sur Reprendre")
	await tap_key(KEY_ESCAPE)
	assert_false(pause_menu.call(&"is_open"), "Échap : reprise")
	assert_false(get_tree().paused)
	# Start : pause ; Entrée sur Reprendre.
	await tap_joy(JOY_BUTTON_START)
	assert_true(pause_menu.call(&"is_open"), "Start : pause")
	await tap_key(KEY_ENTER)
	assert_false(pause_menu.call(&"is_open"), "Reprendre")
	# Start : pause ; B : reprise, sans lancer de charge.
	await tap_joy(JOY_BUTTON_START)
	await tap_joy(JOY_BUTTON_B)
	assert_false(pause_menu.call(&"is_open"), "B : reprise")
	await wait_physics_frames(3)
	assert_eq(combat.current_state(), &"idle", "B n'a pas lancé de charge")
	# Inventaire : I l'ouvre et le ferme ; Y l'ouvre, B le ferme.
	await tap_key(KEY_I)
	assert_true(inventory.call(&"is_open"), "I : inventaire")
	assert_true(get_tree().paused, "inventaire modal")
	assert_eq(
		inventory.call(&"displayed_stacks"), [{"item_id": &"shell", "quantity": 2}], "contenu"
	)
	await tap_key(KEY_I)
	assert_false(inventory.call(&"is_open"), "I : fermé")
	await tap_joy(JOY_BUTTON_Y)
	assert_true(inventory.call(&"is_open"), "Y : inventaire")
	await tap_joy(JOY_BUTTON_B)
	assert_false(inventory.call(&"is_open"), "B : fermé")
	assert_false(get_tree().paused)
	await wait_physics_frames(3)
	assert_eq(combat.current_state(), &"idle", "B n'a pas lancé de charge")
	# Pendant l'inventaire, Échap ne déclenche pas la pause par-dessus.
	await tap_key(KEY_I)
	await tap_key(KEY_ESCAPE)
	assert_false(inventory.call(&"is_open"), "Échap ferme l'inventaire")
	assert_false(pause_menu.call(&"is_open"), "sans ouvrir la pause")
	assert_false(get_tree().paused)


func test_return_to_menu_from_pause() -> void:
	assert_true(await new_game_from_menu(), "nouvelle partie")
	await until(func() -> bool: return SaveManager.has_save(), 3.0)
	await place_player(&"village", Vector3(5.0, 0.0, 8.0), Vector3.RIGHT)
	var at := player.global_position
	var quitting: Array[bool] = []
	pause_menu.connect(&"quit_to_menu_started", func() -> void: quitting.append(true))
	# Échap, puis flèche bas jusqu'à « Retour au menu », Entrée.
	await tap_key(KEY_ESCAPE)
	for _step in 3:
		await tap_key(KEY_DOWN)
	assert_eq(_focus_owner(), pause_menu.get_node("%QuitButton"), "focus sur Retour au menu")
	await tap_key(KEY_ENTER)
	assert_eq(quitting.size(), 1, "retour au menu demandé")
	assert_false(get_tree().paused, "pause levée")
	assert_false(SaveManager.is_game_loaded(), "partie plus suivie")
	var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(SaveManager.save_path))
	assert_true(saved is Dictionary, "partie écrite")
	if saved is Dictionary:
		var p: Array = (saved as Dictionary)["position"]
		assert_lt(Vector3(p[0], p[1], p[2]).distance_to(at), 0.1, "à la position quittée")
	var text := FileAccess.get_file_as_string(SaveManager.save_path)
	# Ce que reload_current_scene() ferait : nouvelle racine, la partie libérée.
	main.free()
	main = null
	EventBus.item_collected.emit(&"page_fragment", 1)
	EventBus.zone_entered.emit(&"beach")
	assert_false(SaveManager.is_autosave_pending(), "rien n'est demandé après le retour")
	await wait_seconds(1.0)
	assert_eq(FileAccess.get_file_as_string(SaveManager.save_path), text, "aucune auto-sauvegarde")
	EventBus.zone_entered.emit(&"village")
	var title := await open_main()
	assert_false(title.call(&"is_waiting_for_gesture"), "pas de nouvel écran de clic")
	assert_true(menu_button("ContinueButton").visible, "Continuer")
	assert_eq(_focus_owner(), menu_button("ContinueButton"), "focus sur Continuer")
