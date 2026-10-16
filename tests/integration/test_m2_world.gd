extends "res://tests/stubs/m2_game_test.gd"
## Intégration M2, parcours 5 : le monde dans la vraie partie. Pause et reprise (clavier,
## manette), inventaire ; retour au menu depuis la pause : partie écrite, plus suivie, aucune
## auto-sauvegarde ensuite, menu sans nouvel écran de clic et avec Continuer. (F1) Les noms des
## cinq zones, la barrière du village et la chute sous l'île sont partis avec l'ancienne île ; la
## chute et le rattrapage sur une carte : test_m2_maps.gd et test_x1_travel.gd.


func _focus_owner() -> Control:
	return get_viewport().gui_get_focus_owner()


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
	await place_player(Vector3(25.0, 0.0, 18.0), Vector3.RIGHT)
	var at := player.global_position
	var quitting: Array[bool] = []
	pause_menu.connect(&"quit_to_menu_started", func() -> void: quitting.append(true))
	# Échap, puis flèche bas jusqu'à « Retour au menu », Entrée ; (bureau) hors Web, « Plein écran »
	# le précède (Reprendre, Sauvegarder, (U1) Options, Commandes, Plein écran).
	await tap_key(KEY_ESCAPE)
	for _step in 5:
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
	EventBus.item_collected.emit(&"candle", 1)
	EventBus.map_entered.emit(&"essai")
	assert_false(SaveManager.is_autosave_pending(), "rien n'est demandé après le retour")
	await wait_seconds(1.0)
	assert_eq(FileAccess.get_file_as_string(SaveManager.save_path), text, "aucune auto-sauvegarde")
	var title := await open_main()
	assert_false(title.call(&"is_waiting_for_gesture"), "pas de nouvel écran de clic")
	assert_true(menu_button("ContinueButton").visible, "Continuer")
	assert_eq(_focus_owner(), menu_button("ContinueButton"), "focus sur Continuer")
