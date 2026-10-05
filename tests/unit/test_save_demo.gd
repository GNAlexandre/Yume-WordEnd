extends "res://tests/stubs/l8_save_test.gd"
## Démo du Lot 8 (tests/integration/demo_l8.tscn) pilotée par ses boutons : chemin de test,
## Nouvelle partie, Sauvegarder, Exporter, Charger, Importer, fichier abîmé, chemin rétabli.

const DEMO := preload("res://tests/integration/demo_l8.tscn")
const DEMO_PATH := "user://test_l8_demo.json"

var _demo: Control


func after_each() -> void:
	# Libérée avant que la base rétablisse save_path : son _exit_tree remet le chemin du test.
	if is_instance_valid(_demo):
		_demo.free()
	delete_save_files(DEMO_PATH)
	super()


func _press(button: String) -> void:
	(_demo.get_node("%" + button) as Button).pressed.emit()


func _text(node: String) -> String:
	var control := _demo.get_node("%" + node)
	return (control as TextEdit).text if control is TextEdit else (control as Label).text


func test_demo_buttons_drive_the_save_manager() -> void:
	delete_save_files(DEMO_PATH)
	var test_path := SaveManager.save_path
	_demo = DEMO.instantiate()
	add_child(_demo)
	assert_eq(SaveManager.save_path, DEMO_PATH, "la démo écrit dans son fichier de test")
	assert_eq(_text("FileView"), "(aucune sauvegarde)")
	_press("NewGameButton")
	assert_true(SaveManager.is_game_loaded())
	_press("PickupButton")
	_press("PickupButton")
	assert_true(SaveManager.is_autosave_pending(), "ramasser déclenche l'auto-sauvegarde")
	_press("SaveButton")
	assert_eq(read_save()["inventory"], {"page_fragment": 2.0})
	assert_string_contains(_text("FileView"), "page_fragment", "fichier affiché")
	_press("ExportButton")
	assert_string_contains(_text("JsonEdit"), '"page_fragment": 2')
	GameState.reset()
	_press("LoadButton")
	assert_eq(GameState.count(&"page_fragment"), 2, "Charger relit le fichier")
	(_demo.get_node("%JsonEdit") as TextEdit).text = '{"version": 1, "skin": "enfant"}'
	_press("ImportButton")
	assert_eq(GameState.skin_id, &"enfant", "Importer lit le texte de gauche")
	assert_eq(GameState.count(&"page_fragment"), 0)
	_press("DamageButton")
	_press("LoadButton")
	assert_push_error("Sauvegarde illisible")
	assert_true(FileAccess.file_exists(DEMO_PATH + ".bak"), "fichier abîmé mis de côté")
	assert_string_contains(_text("Status"), ".bak")
	_demo.free()
	assert_eq(SaveManager.save_path, test_path, "chemin rétabli en quittant la démo")
