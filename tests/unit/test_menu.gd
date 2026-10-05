extends "res://tests/stubs/l10_ui_test.gd"
## Menu principal (L10) : « Cliquer pour jouer » (rien avant le geste, son muet), Continuer selon
## la sauvegarde et chaque code de load_game, nouvelle partie avec le skin choisi, présélection
## depuis la sauvegarde, confirmation d'écrasement, vignettes, manette et crédits.

const MENU := preload("res://src/ui/main_menu.tscn")


func _menu(require_gesture: bool = false) -> MenuScript:
	var menu: MenuScript = MENU.instantiate()
	menu.require_gesture = require_gesture
	return add_child_autofree(menu)


func _button(menu: Control, unique_name: String) -> Button:
	return menu.get_node("%" + unique_name) as Button


# --- « Cliquer pour jouer » ------------------------------------------------------------------


func test_click_screen_blocks_until_gesture() -> void:
	watch_signals(EventBus)
	var menu := _menu(true)
	assert_true(menu.is_waiting_for_gesture(), "écran « Cliquer pour jouer » d'abord")
	assert_false(_button(menu, "NewGameButton").is_visible_in_tree(), "menu caché")
	assert_true(AudioServer.is_bus_mute(MenuScript.MASTER_BUS), "aucun son avant le geste")
	var motion := InputEventJoypadMotion.new()
	motion.axis = JOY_AXIS_LEFT_X
	motion.axis_value = 1.0
	get_viewport().push_input(motion)
	assert_true(menu.is_waiting_for_gesture(), "un stick n'est pas un geste")
	push_key(KEY_ENTER)
	assert_false(menu.is_waiting_for_gesture(), "une touche ouvre le menu")
	assert_true(_button(menu, "NewGameButton").is_visible_in_tree())
	assert_false(AudioServer.is_bus_mute(MenuScript.MASTER_BUS), "son débloqué")
	assert_eq(focus_owner(), _button(menu, "NewGameButton"), "focus sur Nouvelle partie")
	assert_signal_not_emitted(EventBus, "game_loaded", "la touche ne lance pas la partie")


func test_click_and_touch_are_gestures_that_press_nothing() -> void:
	var shown := _menu()
	await wait_process_frames(1)
	var center := _button(shown, "NewGameButton").get_global_rect().get_center()
	shown.free()
	watch_signals(EventBus)
	for kind: String in ["mouse", "touch"]:
		get_tree().root.remove_meta(MenuScript.GESTURE_META)
		var menu := _menu(true)
		for pressed: bool in [true, false]:
			var event: InputEvent
			if kind == "mouse":
				var click := InputEventMouseButton.new()
				click.button_index = MOUSE_BUTTON_LEFT
				click.position = center
				click.pressed = pressed
				event = click
			else:
				var touch := InputEventScreenTouch.new()
				touch.position = center
				touch.pressed = pressed
				event = touch
			get_viewport().push_input(event)
		assert_false(menu.is_waiting_for_gesture(), "%s : menu ouvert" % kind)
		menu.free()
	assert_signal_not_emitted(EventBus, "game_loaded", "le geste ne presse pas le bouton dessous")


func test_gesture_is_remembered_after_return_to_menu() -> void:
	var first := _menu(true)
	first.accept_gesture()
	first.free()
	var again := _menu(true)
	assert_false(again.is_waiting_for_gesture(), "pas de nouvel écran après reload_current_scene")
	assert_false(AudioServer.is_bus_mute(MenuScript.MASTER_BUS))


func test_mute_released_when_menu_leaves_before_gesture() -> void:
	var menu := _menu(true)
	assert_true(AudioServer.is_bus_mute(MenuScript.MASTER_BUS))
	menu.free()
	assert_false(AudioServer.is_bus_mute(MenuScript.MASTER_BUS))


# --- Continuer ---------------------------------------------------------------------------------


func test_continue_hidden_without_save_and_shown_with_one() -> void:
	var menu := _menu()
	assert_false(_button(menu, "ContinueButton").visible, "pas de sauvegarde : pas de Continuer")
	menu.free()
	write_valid_save(&"chtholly")
	menu = _menu()
	assert_true(_button(menu, "ContinueButton").visible, "sauvegarde : Continuer")
	assert_eq(focus_owner(), _button(menu, "ContinueButton"), "focus sur Continuer")


func test_continue_ok_loads_saved_game() -> void:
	write_valid_save(&"forgeron")
	var menu := _menu()
	watch_signals(EventBus)
	_button(menu, "ContinueButton").pressed.emit()
	assert_signal_emitted(EventBus, "game_loaded", "OK : le jeu démarre")
	assert_eq(GameState.count(&"shell"), 2, "partie rechargée")
	assert_eq(GameState.skin_id, &"forgeron", "skin de la sauvegarde")
	assert_eq(menu.message(), "")


func test_continue_applies_a_skin_chosen_in_the_menu() -> void:
	write_valid_save(&"forgeron")
	var menu := _menu()
	menu.skin_card(&"enfant").pressed.emit()
	assert_eq(menu.continue_game(), OK)
	assert_eq(GameState.skin_id, &"enfant", "le joueur a choisi un autre skin avant Continuer")
	assert_eq(GameState.count(&"shell"), 2)


func test_continue_corrupt_save_starts_new_game_and_shows_error() -> void:
	write_save_text('{"version": 1, "inventory": {"shell"')
	var menu := _menu()
	menu.skin_card(&"enfant").pressed.emit()
	watch_signals(EventBus)
	assert_eq(menu.continue_game(), ERR_FILE_CORRUPT)
	assert_push_error("Sauvegarde illisible")
	assert_signal_emitted(EventBus, "game_loaded", "la partie démarre quand même")
	assert_eq(GameState.count(&"shell"), 0, "nouvelle partie")
	assert_eq(GameState.skin_id, &"enfant", "avec le skin choisi")
	assert_false(SaveManager.last_error.is_empty())
	assert_eq(menu.message(), SaveManager.last_error, "erreur affichée au menu")
	await wait_process_frames(1)
	assert_eq(MenuNotice.current_text(get_tree()), SaveManager.last_error, "avis gardé dans le jeu")


func test_continue_newer_version_stays_in_menu() -> void:
	write_save_text('{"version": 99, "skin": "chtholly"}')
	var menu := _menu()
	watch_signals(EventBus)
	assert_eq(menu.continue_game(), ERR_INVALID_DATA)
	assert_signal_not_emitted(EventBus, "game_loaded", "on reste au menu")
	assert_false(SaveManager.last_error.is_empty())
	assert_eq(menu.message(), SaveManager.last_error, "last_error affiché")
	assert_true(_button(menu, "ContinueButton").visible, "la sauvegarde est gardée")


func test_continue_missing_file_hides_continue() -> void:
	write_valid_save(&"chtholly")
	var menu := _menu()
	delete_save_files()
	assert_eq(menu.continue_game(), ERR_FILE_NOT_FOUND)
	assert_false(_button(menu, "ContinueButton").visible)
	assert_eq(menu.message(), SaveManager.last_error)


# --- Nouvelle partie et skins ---------------------------------------------------------------


func test_skin_cards_come_from_registry() -> void:
	var menu := _menu()
	var skins := SkinRegistry.all()
	var grid := menu.get_node("%SkinGrid")
	assert_eq(grid.get_child_count(), skins.size(), "une vignette par skin")
	assert_eq(grid.get_child(0), menu.skin_card(&"chtholly"), "Chtholly d'abord")
	for skin: SkinData in skins:
		var card := menu.skin_card(skin.id)
		assert_not_null(skin.portrait, "%s a un portrait" % skin.id)
		assert_eq((card.get_node(^"Box/Portrait") as TextureRect).texture, skin.portrait)
		assert_eq((card.get_node(^"Box/Name") as Label).text, skin.display_name)


func test_new_game_uses_selected_skin() -> void:
	var menu := _menu()
	assert_eq(menu.selected_skin(), &"chtholly", "sans sauvegarde : Chtholly")
	menu.skin_card(&"forgeron").pressed.emit()
	assert_eq(menu.skin_card(&"forgeron").theme_type_variation, &"SkinCardSelected")
	assert_eq(menu.skin_card(&"chtholly").theme_type_variation, &"SkinCard")
	watch_signals(EventBus)
	_button(menu, "NewGameButton").pressed.emit()
	assert_signal_emitted(EventBus, "game_loaded")
	assert_eq(GameState.skin_id, &"forgeron", "skin de la nouvelle partie")


func test_preselects_skin_of_existing_save() -> void:
	write_valid_save(&"bibliothecaire")
	var menu := _menu()
	assert_eq(menu.selected_skin(), &"bibliothecaire", "skin lu dans la sauvegarde")
	assert_eq(GameState.count(&"shell"), 0, "la partie n'est pas chargée")
	menu.free()
	write_save_text('{"version": 1, "skin": "inconnu"}')
	assert_eq(_menu().selected_skin(), &"chtholly", "skin inconnu : Chtholly")


func test_new_game_confirms_before_overwriting_save() -> void:
	write_valid_save(&"chtholly")
	var menu := _menu()
	menu.skin_card(&"enfant").pressed.emit()
	watch_signals(EventBus)
	_button(menu, "NewGameButton").pressed.emit()
	assert_true(menu.is_confirm_open(), "confirmation demandée")
	assert_signal_not_emitted(EventBus, "game_loaded")
	assert_eq(focus_owner(), _button(menu, "ConfirmCancel"), "Annuler a le focus")
	_button(menu, "ConfirmCancel").pressed.emit()
	assert_false(menu.is_confirm_open())
	assert_signal_not_emitted(EventBus, "game_loaded", "annulé : rien n'est écrasé")
	assert_eq(focus_owner(), _button(menu, "NewGameButton"))
	_button(menu, "NewGameButton").pressed.emit()
	_button(menu, "ConfirmOk").pressed.emit()
	assert_signal_emitted(EventBus, "game_loaded", "confirmé : nouvelle partie")
	assert_eq(GameState.skin_id, &"enfant")
	assert_eq(GameState.count(&"shell"), 0)


func test_escape_cancels_confirmation() -> void:
	write_valid_save(&"chtholly")
	var menu := _menu()
	menu.request_new_game()
	push_action(&"ui_cancel")
	assert_false(menu.is_confirm_open())


# --- Sauvegarde : export et import --------------------------------------------------------------


func test_export_shows_saved_file_and_copies_it() -> void:
	write_valid_save(&"enfant")
	var menu := _menu()
	_button(menu, "SaveButton").pressed.emit()
	assert_true(menu.is_save_panel_open())
	var export := menu.get_node("%ExportText") as TextEdit
	assert_eq(export.text, FileAccess.get_file_as_string(SaveManager.save_path), "le fichier")
	assert_false(export.editable, "texte sélectionnable, non modifiable")
	_button(menu, "CopyButton").pressed.emit()
	assert_true(export.has_selection(), "texte sélectionné")
	assert_false(menu.save_status().is_empty())
	if DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD):
		assert_eq(DisplayServer.clipboard_get(), export.text, "copié")
	_button(menu, "SaveBackButton").pressed.emit()
	assert_false(menu.is_save_panel_open())
	assert_eq(focus_owner(), _button(menu, "SaveButton"))


func test_export_follows_game_in_progress() -> void:
	SaveManager.new_game(&"forgeron")
	GameState.add_item(&"flower_blue", 3)
	var menu := _menu()
	var data: Dictionary = JSON.parse_string(menu.export_text())
	assert_eq(data["skin"], "forgeron")
	assert_eq(data["inventory"], {"flower_blue": 3.0}, "SaveManager.export_json() de la partie")


func test_import_reports_errors_then_loads_valid_save() -> void:
	var menu := _menu()
	menu.open_save_panel()
	watch_signals(EventBus)
	assert_eq(menu.import_save("pas une sauvegarde"), ERR_PARSE_ERROR)
	assert_string_contains(menu.save_status(), SaveManager.last_error)
	assert_eq(menu.import_save('{"version": 42}'), ERR_INVALID_DATA)
	assert_string_contains(menu.save_status(), SaveManager.last_error)
	assert_signal_not_emitted(EventBus, "game_loaded")
	GameState.skin_id = &"forgeron"
	GameState.add_item(&"shell", 4)
	var text := SaveManager.export_json()
	GameState.reset()
	(menu.get_node("%ImportText") as TextEdit).text = text
	_button(menu, "ImportButton").pressed.emit()
	assert_signal_emitted(EventBus, "game_loaded", "import réussi : le jeu démarre")
	assert_eq(GameState.count(&"shell"), 4)
	assert_eq(GameState.skin_id, &"forgeron")


func test_private_browsing_warns_and_puts_export_forward() -> void:
	var menu := _menu()
	var save_button := _button(menu, "SaveButton")
	assert_false(menu.get_node("%StorageWarning").visible, "stockage conservé : rien à dire")
	menu.show_storage_warning(false)
	assert_true(menu.get_node("%StorageWarning").visible, "avertissement dans le panneau")
	assert_eq(menu.message(), MenuScript.PRIVATE_NOTICE, "et sous les boutons")
	assert_eq(save_button.theme_type_variation, &"PrimaryButton", "export mis en avant")
	assert_eq(save_button.text, "Exporter ma sauvegarde")
	menu.show_storage_warning(true)
	assert_eq(menu.message(), "")
	assert_eq(save_button.text, "Sauvegarde")


# --- Manette et crédits ------------------------------------------------------------------------


func test_gamepad_a_presses_focused_button_and_b_goes_back() -> void:
	var menu := _menu()
	_button(menu, "CreditsButton").grab_focus()
	tap_joy(JOY_BUTTON_A)
	assert_true(menu.is_credits_open(), "A (relâché) presse Crédits")
	await wait_process_frames(1)
	tap_joy(JOY_BUTTON_B)
	assert_false(menu.is_credits_open(), "B revient au menu")
	assert_eq(focus_owner(), _button(menu, "CreditsButton"))
	_button(menu, "SaveButton").grab_focus()
	tap_joy(JOY_BUTTON_A)
	assert_true(menu.is_save_panel_open())
	tap_joy(JOY_BUTTON_B)
	assert_false(menu.is_save_panel_open())


func test_credits_open_from_menu_and_come_back() -> void:
	var menu := _menu()
	_button(menu, "CreditsButton").pressed.emit()
	assert_true(menu.is_credits_open())
	var credits := menu.find_child("Credits", false, false)
	assert_not_null(credits, "credits.tscn affiché par-dessus le menu")
	(credits.get_node("%BackButton") as Button).pressed.emit()
	assert_false(menu.is_credits_open(), "retour au menu")
