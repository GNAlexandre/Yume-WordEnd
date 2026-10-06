extends GutTest
## Base des tests du Lot 10 (tests/unit/test_menu*, test_hud*, test_pause*, test_arena_end*,
## test_credits*), dont ils héritent par chemin (pas de class_name, règle des stubs) : sauvegarde
## propre au script (user://test_l10_<script>.json) ; SaveManager, GameState, zone de
## WorldManager, pause, geste « Cliquer pour jouer », bus Master et avis du menu rétablis après
## chaque test.

const MenuScript := preload("res://src/ui/main_menu.gd")
const MenuNotice := preload("res://src/ui/main_menu_notice.gd")

var _previous_path: String
var _previous_mute: bool
var _previous_zone: StringName


func before_each() -> void:
	_previous_path = SaveManager.save_path
	_previous_mute = AudioServer.is_bus_mute(MenuScript.MASTER_BUS)
	_previous_zone = WorldManager.current_zone()
	SaveManager.close_game(false)
	SaveManager.save_path = save_file()
	delete_save_files()
	GameState.reset()
	get_tree().root.remove_meta(MenuScript.GESTURE_META)
	get_tree().paused = false


func after_each() -> void:
	get_tree().paused = false
	if WorldManager.current_zone() != _previous_zone:
		EventBus.zone_entered.emit(_previous_zone)
	SaveManager.close_game(false)
	delete_save_files()
	SaveManager.save_path = _previous_path
	SaveManager.last_error = ""
	GameState.reset()
	get_tree().root.remove_meta(MenuScript.GESTURE_META)
	AudioServer.set_bus_mute(MenuScript.MASTER_BUS, _previous_mute)
	for node: Node in get_tree().root.get_children():
		if node.get_script() == MenuNotice:
			node.free()


## Fichier de sauvegarde propre à ce script de test.
func save_file() -> String:
	return "user://test_l10_%s.json" % get_script().resource_path.get_file().get_basename()


## Supprime la sauvegarde de test, sa copie .bak et son fichier temporaire.
func delete_save_files() -> void:
	var path := save_file()
	for file: String in [path, path + SaveManager.BACKUP_SUFFIX, path + SaveManager.TEMP_SUFFIX]:
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)


## Écrit un texte brut à la place de la sauvegarde (fichier abîmé, version future…).
func write_save_text(text: String) -> void:
	var file := FileAccess.open(SaveManager.save_path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


## Sauvegarde valide écrite par SaveManager (skin, deux coquillages) ; GameState remis à zéro.
func write_valid_save(skin_id: StringName) -> void:
	GameState.skin_id = skin_id
	GameState.add_item(&"shell", 2)
	assert_eq(SaveManager.save(), OK, "sauvegarde de test écrite")
	GameState.reset()


func push_action(action: StringName, pressed: bool = true) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	get_viewport().push_input(event)


func push_key(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	get_viewport().push_input(event)


## Appui puis relâchement d'un bouton de manette (A valide, B revient, au relâchement).
func tap_joy(button: JoyButton) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventJoypadButton.new()
		event.button_index = button
		event.pressed = pressed
		get_viewport().push_input(event)


func focus_owner() -> Control:
	return get_viewport().gui_get_focus_owner()
