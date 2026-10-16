extends "res://tests/stubs/s2_story_test.gd"
## (X-L5) Le choix du mode de jeu dans l'interface, dans la vraie partie (main.tscn, vrais clics et
## vrais appuis) : « Nouvelle partie » demande le mode (« Mode libre » d'abord et par défaut,
## « Mode scénarisé »), à la souris, au clavier et à la manette ; l'option de la pause (Options)
## montre le mode et le change après une confirmation courte ; le mode survit à « Sauvegarder »
## puis « Continuer ». Les textes viennent de data/texts (ModeText).


## Les deux modes se choisissent explicitement : le défaut du test ne compte pas ici.
func mode_for_test() -> StringName:
	return StoryPacing.SCENARIO


func _open_new_game_choice() -> Control:
	var title := await open_main()
	await click_center()
	await click(menu_button("NewGameButton"))
	return title


## Attend que le panneau soit en place (son apparition en fondu et glissement est finie).
func _settled(panel: Control) -> void:
	await until(func() -> bool: return not panel.has_meta(&"ui_style_appear"), 2.0)


func _pause_button(unique_name: String) -> Button:
	return pause_menu.get_node("%" + unique_name) as Button


## Pause (Échap) puis « Options » à la souris.
func _open_pause_options() -> void:
	await tap_key(KEY_ESCAPE)
	assert_true(pause_menu.call(&"is_open"), "la pause est ouverte")
	await _settled(pause_menu.get_node("%MainPanel") as Control)
	await click(_pause_button("OptionsButton"))
	assert_true(pause_menu.call(&"is_options_shown"), "les options")
	await _settled(pause_menu.get_node("%OptionsPanel") as Control)


# --- Nouvelle partie : le choix --------------------------------------------------------------


func test_new_game_asks_the_mode_with_free_as_the_default() -> void:
	watch_signals(EventBus)
	var title := await _open_new_game_choice()
	assert_true(title.call(&"is_mode_choice_open"), "« Nouvelle partie » demande le mode")
	assert_signal_not_emitted(EventBus, "game_loaded", "la partie n'a pas encore démarré")
	var free := title.call(&"mode_button", StoryPacing.FREE) as Button
	var scenario := title.call(&"mode_button", StoryPacing.SCENARIO) as Button
	assert_true(free.is_visible_in_tree() and scenario.is_visible_in_tree(), "deux choix")
	assert_lt(free.global_position.y, scenario.global_position.y, "le libre d'abord")
	assert_eq(_focus_owner(), free, "le mode libre est le choix par défaut")
	for pair: Array in [[free, StoryPacing.FREE], [scenario, StoryPacing.SCENARIO]]:
		var button := pair[0] as Button
		var mode: StringName = pair[1]
		var name_label := button.get_node(^"Box/Name") as Label
		var blurb := button.get_node(^"Box/Blurb") as Label
		assert_eq(name_label.text, StoryDirector.mode_name(mode), "le nom du mode")
		assert_false(blurb.text.is_empty(), "%s : une phrase d'explication" % mode)
		assert_true(blurb.get_line_count() <= 2, "%s : la phrase tient en deux lignes" % mode)
	assert_ne(
		(free.get_node(^"Box/Blurb") as Label).text,
		(scenario.get_node(^"Box/Blurb") as Label).text,
		"deux phrases différentes"
	)
	assert_false((title.get_node("%ModeHeader") as Label).text.is_empty(), "une question en titre")


func test_clicking_free_mode_starts_a_free_game() -> void:
	assert_true(await new_game_from_menu(&"chtholly", StoryPacing.FREE), "partie lancée")
	assert_eq(StoryDirector.mode(), &"libre", "« Mode libre » donne le mode libre")
	assert_true(StoryDirector.is_free())
	assert_true(GameState.has_flag(StoryPacing.FREE_FLAG), "écrit dans la partie")
	assert_false(GameState.has_flag(StoryPacing.FLAG))
	assert_eq(GameState.day, 1, "l'acte est ouvert")
	assert_eq(StoryDirector.next_game_mode, &"", "le choix est consommé")


func test_clicking_scenario_mode_starts_a_scenario_game() -> void:
	assert_true(await new_game_from_menu(&"chtholly", StoryPacing.SCENARIO), "partie lancée")
	assert_eq(StoryDirector.mode(), &"scenario", "« Mode scénarisé » donne le scénarisé")
	assert_false(StoryDirector.is_free())
	assert_true(GameState.has_flag(StoryPacing.FLAG), "écrit dans la partie")
	assert_false(GameState.has_flag(StoryPacing.FREE_FLAG))
	assert_eq(GameState.day, 1, "l'acte est ouvert")


func test_the_keyboard_picks_the_mode() -> void:
	var title := await open_main()
	await tap_key(KEY_ENTER)
	assert_false(title.call(&"is_waiting_for_gesture"), "une touche ouvre le menu")
	assert_eq(_focus_owner(), menu_button("NewGameButton"), "focus sur Nouvelle partie")
	await tap_key(KEY_ENTER)
	assert_true(title.call(&"is_mode_choice_open"), "Entrée ouvre le choix")
	assert_eq(_focus_owner(), title.call(&"mode_button", StoryPacing.FREE), "libre : le défaut")
	await tap_key(KEY_DOWN)
	assert_eq(_focus_owner(), title.call(&"mode_button", StoryPacing.SCENARIO), "flèche en bas")
	await tap_key(KEY_UP)
	assert_eq(_focus_owner(), title.call(&"mode_button", StoryPacing.FREE), "flèche en haut")
	await tap_key(KEY_DOWN)
	await tap_key(KEY_ENTER)
	assert_true(await wait_for_game(), "Entrée lance la partie")
	assert_eq(StoryDirector.mode(), StoryPacing.SCENARIO, "dans le mode choisi au clavier")


func test_the_gamepad_picks_the_mode() -> void:
	var title := await open_main()
	await tap_joy(JOY_BUTTON_A)
	await tap_joy(JOY_BUTTON_A)
	assert_true(title.call(&"is_mode_choice_open"), "A ouvre le choix")
	assert_eq(_focus_owner(), title.call(&"mode_button", StoryPacing.FREE), "libre : le défaut")
	await tap_joy(JOY_BUTTON_A)
	assert_true(await wait_for_game(), "A sur le défaut lance la partie")
	assert_eq(StoryDirector.mode(), StoryPacing.FREE, "le libre, par défaut, à la manette")


func test_back_returns_to_the_menu_without_starting() -> void:
	watch_signals(EventBus)
	var title := await _open_new_game_choice()
	assert_true(title.call(&"is_mode_choice_open"))
	await tap_key(KEY_ESCAPE)
	assert_false(title.call(&"is_mode_choice_open"), "Échap referme le choix")
	assert_eq(_focus_owner(), menu_button("NewGameButton"), "le focus revient à Nouvelle partie")
	await click(menu_button("NewGameButton"))
	await click(title.get_node("%ModeBack") as Control)
	assert_false(title.call(&"is_mode_choice_open"), "« Retour » referme le choix")
	await tap_key(KEY_ENTER)
	await tap_joy(JOY_BUTTON_B)
	assert_false(title.call(&"is_mode_choice_open"), "B referme le choix")
	assert_signal_not_emitted(EventBus, "game_loaded", "aucune partie lancée")
	assert_false(SaveManager.is_game_loaded())


func test_the_choice_comes_after_the_overwrite_confirmation() -> void:
	assert_true(await new_game_from_menu(&"chtholly", StoryPacing.FREE), "première partie")
	assert_true(
		await until(func() -> bool: return SaveManager.has_save(), 3.0), "la partie est écrite"
	)
	await close_tab()
	var title := await open_main()
	await click_center()
	await click(menu_button("NewGameButton"))
	assert_true(title.call(&"is_confirm_open"), "la sauvegarde est confirmée d'abord")
	assert_false(title.call(&"is_mode_choice_open"))
	await click(title.get_node("%ConfirmOk") as Control)
	assert_true(title.call(&"is_mode_choice_open"), "puis le mode")
	await choose_mode(StoryPacing.SCENARIO)
	assert_true(await wait_for_game(), "la nouvelle partie")
	assert_eq(StoryDirector.mode(), StoryPacing.SCENARIO)


# --- La pause : l'option -----------------------------------------------------------------------


func test_the_pause_shows_the_mode_and_switches_it() -> void:
	assert_true(await new_game_from_menu(&"chtholly", StoryPacing.FREE), "partie lancée")
	assert_true(await wait_control(), "la main au joueur")
	await tap_key(KEY_ESCAPE)
	var tag := pause_menu.get_node("%ModeTag") as Label
	assert_true(tag.is_visible_in_tree(), "le mode, discret, sous le jour")
	assert_eq(tag.text, StoryDirector.mode_name(StoryPacing.FREE))
	await tap_key(KEY_ESCAPE)
	await _open_pause_options()
	var mode_button := _pause_button("ModeButton")
	assert_true(mode_button.is_visible_in_tree(), "l'entrée du mode dans les options")
	assert_string_contains(mode_button.text, "Mode libre", "elle montre le mode")
	assert_false(pause_menu.call(&"is_mode_confirm_open"))
	# Confirmation courte : « Garder » ne change rien.
	await click(mode_button)
	assert_true(pause_menu.call(&"is_mode_confirm_open"), "une confirmation")
	assert_false(mode_button.is_visible_in_tree(), "elle prend la place de l'entrée")
	var title := pause_menu.get_node("%ModeConfirmTitle") as Label
	assert_string_contains(title.text, "scénarisé", "elle dit vers quel mode on passe")
	assert_eq(_focus_owner(), _pause_button("ModeConfirmNo"), "« Garder » a le focus")
	await click(_pause_button("ModeConfirmNo"))
	assert_false(pause_menu.call(&"is_mode_confirm_open"))
	assert_eq(StoryDirector.mode(), StoryPacing.FREE, "« Garder » : le mode ne change pas")
	# Échap referme la confirmation seule, pas les options.
	await click(mode_button)
	await tap_key(KEY_ESCAPE)
	assert_false(pause_menu.call(&"is_mode_confirm_open"), "Échap referme la confirmation")
	assert_true(pause_menu.call(&"is_options_shown"), "les options restent")
	assert_eq(StoryDirector.mode(), StoryPacing.FREE)
	# « Changer » : libre -> scénarisé.
	watch_signals(StoryDirector)
	await click(mode_button)
	await click(_pause_button("ModeConfirmYes"))
	assert_eq(StoryDirector.mode(), StoryPacing.SCENARIO, "l'option bascule en scénarisé")
	assert_signal_emitted(StoryDirector, "mode_changed")
	assert_true(GameState.has_flag(StoryPacing.FLAG), "écrit dans la partie")
	assert_string_contains(mode_button.text, "Mode scénarisé", "l'entrée suit")
	assert_false(pause_menu.call(&"is_mode_confirm_open"))
	# Et retour : scénarisé -> libre.
	await click(mode_button)
	assert_string_contains(title.text, "libre")
	await click(_pause_button("ModeConfirmYes"))
	assert_eq(StoryDirector.mode(), StoryPacing.FREE, "l'option rebascule en libre")
	assert_string_contains(mode_button.text, "Mode libre")


func test_the_pause_option_works_with_the_gamepad() -> void:
	assert_true(await new_game_from_menu(&"chtholly", StoryPacing.FREE), "partie lancée")
	assert_true(await wait_control(), "la main au joueur")
	await tap_joy(JOY_BUTTON_START)
	assert_true(pause_menu.call(&"is_open"), "Start ouvre la pause")
	_pause_button("OptionsButton").grab_focus()
	await tap_joy(JOY_BUTTON_A)
	assert_true(pause_menu.call(&"is_options_shown"))
	_pause_button("ModeButton").grab_focus()
	await tap_joy(JOY_BUTTON_A)
	assert_true(pause_menu.call(&"is_mode_confirm_open"), "A ouvre la confirmation")
	await tap_joy(JOY_BUTTON_B)
	assert_false(pause_menu.call(&"is_mode_confirm_open"), "B la referme")
	assert_true(pause_menu.call(&"is_options_shown"), "sans quitter les options")
	assert_eq(StoryDirector.mode(), StoryPacing.FREE)
	assert_eq(_focus_owner(), _pause_button("ModeButton"), "le focus revient à l'entrée")
	await tap_joy(JOY_BUTTON_A)
	assert_true(pause_menu.call(&"is_mode_confirm_open"), "A rouvre la confirmation")
	assert_eq(_focus_owner(), _pause_button("ModeConfirmNo"), "sur « Garder »")
	await tap_joy(JOY_BUTTON_DPAD_RIGHT)
	assert_eq(_focus_owner(), _pause_button("ModeConfirmYes"), "la croix mène à « Changer »")
	await tap_joy(JOY_BUTTON_A)
	assert_eq(StoryDirector.mode(), StoryPacing.SCENARIO, "A change le mode")


# --- Sauvegarder puis Continuer ----------------------------------------------------------------


func _save_from_the_pause() -> void:
	await click(_pause_button("SaveButton"))
	var saved := await until(
		func() -> bool: return str(pause_menu.call(&"status_text")) == "Partie sauvegardée.", 5.0
	)
	assert_true(saved, "« Sauvegarder » : Partie sauvegardée.")


func test_the_scenario_mode_survives_save_and_continue() -> void:
	assert_true(await new_game_from_menu(&"chtholly", StoryPacing.FREE), "partie lancée")
	assert_true(await wait_control(), "la main au joueur")
	await _open_pause_options()
	await click(_pause_button("ModeButton"))
	await click(_pause_button("ModeConfirmYes"))
	assert_eq(StoryDirector.mode(), StoryPacing.SCENARIO, "passé en scénarisé")
	await tap_key(KEY_ESCAPE)
	assert_false(pause_menu.call(&"is_options_shown"), "retour au panneau principal")
	await _save_from_the_pause()
	assert_true(await continue_game(), "« Continuer »")
	assert_eq(StoryDirector.mode(), StoryPacing.SCENARIO, "scénarisé après « Continuer »")
	assert_true(GameState.has_flag(StoryPacing.FLAG))
	assert_false(GameState.has_flag(StoryPacing.FREE_FLAG))


func test_the_free_mode_survives_save_and_continue() -> void:
	assert_true(await new_game_from_menu(&"chtholly", StoryPacing.FREE), "partie lancée")
	assert_true(await wait_control(), "la main au joueur")
	await tap_key(KEY_ESCAPE)
	await _settled(pause_menu.get_node("%MainPanel") as Control)
	await _save_from_the_pause()
	assert_true(await continue_game(), "« Continuer »")
	assert_eq(StoryDirector.mode(), StoryPacing.FREE, "libre après « Continuer »")
	assert_true(GameState.has_flag(StoryPacing.FREE_FLAG))
	await tap_key(KEY_ESCAPE)
	var tag := pause_menu.get_node("%ModeTag") as Label
	assert_eq(tag.text, StoryDirector.mode_name(StoryPacing.FREE), "la pause montre le mode repris")


func test_a_scenario_game_survives_save_and_continue() -> void:
	assert_true(await new_game_from_menu(&"chtholly", StoryPacing.SCENARIO), "partie lancée")
	assert_eq(StoryDirector.mode(), StoryPacing.SCENARIO)
	assert_true(await save_and_continue(), "« Continuer »")
	assert_eq(StoryDirector.mode(), StoryPacing.SCENARIO, "scénarisé après « Continuer »")


# --- Textes ------------------------------------------------------------------------------------


func test_the_texts_come_from_the_data_files() -> void:
	for text_key: String in [
		"mode_choice_title",
		"mode_libre_blurb",
		"mode_scenario_blurb",
		"mode_choice_hint",
		"mode_choice_back",
		"mode_option",
		"mode_switch_libre",
		"mode_switch_scenario",
		"mode_switch_libre_note",
		"mode_switch_scenario_note",
		"mode_switch_yes",
		"mode_switch_no",
		"mode_switched",
	]:
		assert_false(ModeText.text(text_key).is_empty(), "data/texts : ui/%s" % text_key)
	assert_eq(ModeText.mode_name(StoryPacing.FREE), "Mode libre")
	assert_eq(ModeText.mode_name(StoryPacing.SCENARIO), "Mode scénarisé")
	assert_eq(ModeText.other(StoryPacing.FREE), StoryPacing.SCENARIO)
	assert_eq(ModeText.other(StoryPacing.SCENARIO), StoryPacing.FREE)
	assert_string_contains(ModeText.text("mode_option", {"mode": "X"}), "X")


func _focus_owner() -> Control:
	return get_viewport().gui_get_focus_owner()
