extends "res://tests/stubs/l10_ui_test.gd"
## Menu pause (L10) : action pause dans _unhandled_input, jamais pendant un dialogue ni par-dessus
## l'inventaire (L7) ou un autre écran en pause ; boutons ; retour au menu. Pendant une pause,
## n'attendre que des images (le temps de GUT est gelé).

const PAUSE := preload("res://src/ui/pause_menu.tscn")
const PauseScript := preload("res://src/ui/pause_menu.gd")
const INVENTORY := preload("res://src/ui/inventory.tscn")
const HUD := preload("res://src/ui/hud.tscn")


func _pause() -> PauseScript:
	var menu: PauseScript = PAUSE.instantiate()
	menu.reload_on_quit = false
	return add_child_autofree(menu)


func _button(menu: Control, unique_name: String) -> Button:
	return menu.get_node("%" + unique_name) as Button


func test_hud_contains_the_pause_menu() -> void:
	var hud: Control = add_child_autofree(HUD.instantiate())
	var menu := hud.get_node_or_null("%PauseMenu") as PauseScript
	assert_not_null(menu, "pause_menu.tscn instancié dans hud.tscn")
	assert_eq(menu.process_mode, Node.PROCESS_MODE_ALWAYS)
	assert_false(menu.visible)


func test_pause_action_opens_and_closes() -> void:
	var menu := _pause()
	push_action(&"pause")
	assert_true(menu.is_open(), "pause ouvre")
	assert_true(get_tree().paused, "le jeu est figé")
	assert_eq(focus_owner(), _button(menu, "ResumeButton"), "focus sur Reprendre")
	push_action(&"pause")
	assert_false(menu.is_open(), "pause referme")
	assert_false(get_tree().paused)
	menu.open()
	push_action(&"ui_cancel")
	assert_false(menu.is_open(), "Échap (ui_cancel) referme")


func test_not_during_dialogue() -> void:
	var menu := _pause()
	EventBus.dialogue_started.emit(&"librarian")
	push_action(&"pause")
	assert_false(menu.is_open(), "pas pendant un dialogue")
	assert_false(get_tree().paused)
	EventBus.dialogue_ended.emit(&"librarian")
	push_action(&"pause")
	assert_true(menu.is_open(), "après le dialogue")


func test_not_over_inventory_or_another_paused_screen() -> void:
	var menu := _pause()
	var inventory: Control = add_child_autofree(INVENTORY.instantiate())
	inventory.call(&"open")
	assert_true(get_tree().paused, "inventaire ouvert")
	push_action(&"pause")
	assert_false(menu.is_open(), "l'inventaire consomme pause")
	assert_false(inventory.visible, "et se ferme")
	assert_false(get_tree().paused)
	get_tree().paused = true
	push_action(&"pause")
	assert_false(menu.is_open(), "pas par-dessus un autre écran en pause (fin d'arène)")


func test_buttons_resume_save_and_controls() -> void:
	var menu := _pause()
	menu.open()
	_button(menu, "SaveButton").pressed.emit()
	assert_string_contains(menu.status_text(), "Aucune partie", "rien à sauvegarder hors partie")
	SaveManager.new_game(&"chtholly")
	watch_signals(EventBus)
	_button(menu, "SaveButton").pressed.emit()
	assert_signal_emitted(EventBus, "save_requested", "Sauvegarder → EventBus.save_requested")
	SaveManager.saved.emit(SaveManager.save_path)
	assert_eq(menu.status_text(), "Partie sauvegardée.")
	_button(menu, "ControlsButton").pressed.emit()
	assert_true(menu.is_controls_shown(), "rappel des commandes")
	var grid := menu.get_node("%ControlsGrid") as GridContainer
	assert_eq(grid.get_child_count(), PauseScript.CONTROLS.size() * 3, "action, clavier, manette")
	push_action(&"ui_cancel")
	assert_false(menu.is_controls_shown(), "Échap revient au menu pause")
	assert_true(menu.is_open())
	_button(menu, "ResumeButton").pressed.emit()
	assert_false(menu.is_open(), "Reprendre")
	assert_false(get_tree().paused)


func test_gamepad_b_resumes_on_release() -> void:
	var menu := _pause()
	menu.open()
	tap_joy(JOY_BUTTON_B)
	assert_false(menu.is_open())
	assert_false(get_tree().paused)


func test_quit_to_menu_saves_closes_game_and_unpauses() -> void:
	SaveManager.new_game(&"forgeron")
	GameState.add_item(&"shell", 1)
	var menu := _pause()
	menu.open()
	watch_signals(menu)
	_button(menu, "QuitButton").pressed.emit()
	assert_signal_emitted(menu, "quit_to_menu_started")
	assert_false(get_tree().paused, "pause levée avant de recharger main.tscn")
	assert_false(menu.is_open())
	assert_false(SaveManager.is_game_loaded(), "close_game : plus d'auto-sauvegarde")
	assert_false(SaveManager.is_autosave_pending())
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveManager.save_path))
	assert_eq(saved["skin"], "forgeron", "partie écrite avant de partir")
	assert_eq(saved["inventory"], {"shell": 1.0})


func test_freed_while_open_releases_pause() -> void:
	var menu := _pause()
	menu.open()
	menu.free()
	assert_false(get_tree().paused)
