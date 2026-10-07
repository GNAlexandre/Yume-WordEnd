extends "res://tests/stubs/l8_save_test.gd"
## SaveManager (tests repris du Lot 0) : nouvelle partie, aller-retour JSON, erreurs. La base
## (tests/stubs/l8_save_test.gd) utilise un fichier de test (user://test_l8_*.json) pour ne
## jamais écraser user://save_v1.json et rétablit SaveManager après chaque test.


func test_new_game_resets_and_emits_game_loaded() -> void:
	GameState.add_item(&"page_fragment", 2)
	watch_signals(EventBus)
	SaveManager.new_game(&"chtholly")
	assert_eq(GameState.count(&"page_fragment"), 0)
	assert_eq(GameState.skin_id, &"chtholly")
	assert_signal_emitted(EventBus, "game_loaded")


func test_save_then_load_restores_state() -> void:
	assert_false(SaveManager.has_save())
	SaveManager.new_game(&"chtholly")
	GameState.add_item(&"page_fragment", 3)
	GameState.set_quest_state(&"pages", &"active")
	GameState.zone = &"village"
	GameState.position = Vector3(12.0, 1.0, -4.5)
	GameState.record_score(&"dunes", 640, 6)
	var before := GameState.to_dict()
	assert_eq(SaveManager.save(), OK)
	assert_true(SaveManager.has_save())
	GameState.reset()
	watch_signals(EventBus)
	assert_eq(SaveManager.load_game(), OK)
	assert_signal_emitted(EventBus, "game_loaded")
	assert_eq(JSON.stringify(GameState.to_dict(), "", true), JSON.stringify(before, "", true))


func test_export_contains_version_and_date() -> void:
	var data: Dictionary = JSON.parse_string(SaveManager.export_json())
	assert_eq(int(data["version"]), SaveManager.SAVE_VERSION)
	assert_true(str(data["saved_at"]).ends_with("Z"))
	for key: String in GameState.to_dict():
		assert_true(data.has(key), "champ %s exporté" % key)


func test_import_rejects_bad_input_without_touching_state() -> void:
	GameState.add_item(&"page_fragment", 1)
	assert_eq(SaveManager.import_json("pas du json"), ERR_PARSE_ERROR)
	assert_eq(SaveManager.import_json("[1, 2]"), ERR_PARSE_ERROR)
	assert_eq(SaveManager.import_json('{"version": 99}'), ERR_INVALID_DATA)
	assert_eq(GameState.count(&"page_fragment"), 1)


func test_load_without_save() -> void:
	assert_eq(SaveManager.load_game(), ERR_FILE_NOT_FOUND)
