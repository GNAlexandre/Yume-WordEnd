extends "res://tests/stubs/l8_save_test.gd"
## SaveManager, fichier (L8) : aller-retour identique champ à champ, schéma v1, fichier absent,
## fichier corrompu → nouvelle partie + .bak, écriture sûre, export / import JSON.

const ISO_UTC := "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$"


## Partie bien remplie : chaque champ du schéma a une valeur différente du défaut.
func _fill_state() -> void:
	GameState.skin_id = &"forgeron"
	GameState.max_hp = 6
	GameState.position = Vector3(12.25, 1.5, -4.75)
	GameState.zone = &"forest"
	GameState.add_item(&"page_fragment", 3)
	GameState.add_item(&"flower_blue")
	GameState.set_flag(&"quest_pages_accepted")
	GameState.set_flag(&"met_smith", false)
	GameState.set_quest_state(&"pages", &"active")
	GameState.set_quest_state(&"flowers", &"done")
	GameState.mark_pickup_collected(&"forest_page_1")
	GameState.mark_pickup_collected(&"beach_shell_2")
	GameState.record_score(&"dunes", 640, 6)
	GameState.record_score(&"dunes", 300, 4)
	GameState.record_score(&"dunes", 120, 2)
	GameState.record_score(&"dunes", 90, 1)


func test_no_file_means_no_save() -> void:
	assert_false(SaveManager.has_save())
	GameState.add_item(&"page_fragment")
	watch_signals(EventBus)
	assert_eq(SaveManager.load_game(), ERR_FILE_NOT_FOUND)
	assert_eq(GameState.count(&"page_fragment"), 1, "GameState inchangé")
	assert_signal_not_emitted(EventBus, "game_loaded")
	assert_false(SaveManager.has_save(), "rien n'est créé")


func test_round_trip_is_identical_field_by_field() -> void:
	_fill_state()
	var before := GameState.to_dict()
	watch_signals(SaveManager)
	assert_eq(SaveManager.save(), OK)
	assert_signal_emitted_with_parameters(SaveManager, "saved", [SaveManager.save_path])
	assert_true(SaveManager.has_save())
	GameState.reset()
	assert_eq(SaveManager.load_game(), OK)
	var after := GameState.to_dict()
	assert_eq(after.keys(), before.keys(), "mêmes champs")
	for key: String in before:
		assert_eq(after[key], before[key], "champ %s" % key)
	assert_eq(GameState.position, Vector3(12.25, 1.5, -4.75))
	assert_eq(after["collected_pickups"], ["beach_shell_2", "forest_page_1"])
	assert_eq(after["best_scores"], {"dunes": {"score": 640, "wave": 6, "games": 4}})
	assert_eq(GameState.best_score(&"dunes"), 640)
	assert_true(GameState.is_pickup_collected(&"forest_page_1"))
	assert_eq(GameState.skin_id, &"forgeron")
	assert_eq(GameState.max_hp, 6)


func test_file_follows_schema_v1() -> void:
	_fill_state()
	assert_eq(SaveManager.save(), OK)
	var data := read_save()
	var keys: Array = data.keys()
	assert_eq(keys.slice(0, 2), ["version", "saved_at"], "version et saved_at d'abord")
	assert_eq(keys.slice(2), GameState.to_dict().keys(), "puis les champs de to_dict()")
	assert_eq(data["version"], 1.0)
	var saved_at := str(data["saved_at"])
	assert_not_null(
		RegEx.create_from_string(ISO_UTC).search(saved_at), "ISO 8601 UTC : " + saved_at
	)
	var age := Time.get_unix_time_from_system()
	age -= Time.get_unix_time_from_datetime_string(saved_at.trim_suffix("Z"))
	assert_between(age, -2.0, 60.0, "saved_at est l'heure UTC de l'écriture")
	assert_eq(data["position"], [12.25, 1.5, -4.75])
	assert_eq(data["inventory"], {"page_fragment": 3.0, "flower_blue": 1.0})
	assert_eq(data["best_scores"], {"dunes": {"score": 640.0, "wave": 6.0, "games": 4.0}})


func test_save_replaces_through_a_temporary_file() -> void:
	write_save_text('{"version": 1, "skin": "enfant"}')
	GameState.skin_id = &"bibliothecaire"
	assert_eq(SaveManager.save(), OK)
	assert_eq(read_save()["skin"], "bibliothecaire", "ancienne sauvegarde remplacée")
	assert_false(
		FileAccess.file_exists(SaveManager.save_path + ".tmp"), "pas de fichier temporaire"
	)


func test_failed_write_keeps_previous_save() -> void:
	GameState.skin_id = &"enfant"
	assert_eq(SaveManager.save(), OK)
	var previous := FileAccess.get_file_as_string(SaveManager.save_path)
	GameState.skin_id = &"forgeron"
	# Le fichier temporaire ne peut pas être créé : un dossier occupe son nom.
	DirAccess.make_dir_absolute(SaveManager.save_path + ".tmp")
	watch_signals(SaveManager)
	assert_ne(SaveManager.save(), OK)
	assert_push_error("Sauvegarde impossible")
	assert_signal_not_emitted(SaveManager, "saved")
	assert_eq(FileAccess.get_file_as_string(SaveManager.save_path), previous, "ancienne intacte")
	assert_string_contains(SaveManager.last_error, SaveManager.save_path)


func test_corrupted_file_starts_new_game_and_keeps_backup() -> void:
	_fill_state()
	var full := SaveManager.export_json()
	var corrupted := full.left(full.length() >> 1)
	write_save_text(corrupted)
	GameState.skin_id = &"enfant"
	watch_signals(EventBus)
	assert_eq(SaveManager.load_game(), ERR_FILE_CORRUPT)
	assert_push_error("Sauvegarde illisible")
	assert_signal_emitted(EventBus, "game_loaded", "nouvelle partie lancée")
	assert_eq(GameState.count(&"page_fragment"), 0, "partie remise à zéro")
	assert_eq(GameState.best_score(&"dunes"), 0)
	assert_eq(GameState.skin_id, &"enfant", "skin courant gardé")
	var backup := SaveManager.backup_path()
	assert_eq(backup, SaveManager.save_path + ".bak")
	assert_eq(FileAccess.get_file_as_string(backup), corrupted, "fichier gardé tel quel à côté")
	assert_string_contains(SaveManager.last_error, backup)
	assert_true(SaveManager.is_autosave_pending(), "la nouvelle partie va être écrite")
	assert_eq(SaveManager.flush(), OK)
	assert_eq(read_save()["version"], 1.0, "nouvelle sauvegarde valide")


func test_every_kind_of_damage_is_recovered() -> void:
	var damaged: Array[String] = [
		"",
		"\u0001 pas du json",
		"[1, 2]",
		'{"version": "1"}',
		'{"version": -1}',
		'{"version": 1, "inventory": [1]}',
		'{"version": 1, "max_hp": 0}',
		'{"version": 1, "position": [1, 2]}',
		'{"version": 1, "flags": {"a": "oui"}}',
		'{"version": 1, "best_scores": {"dunes": {"score": "beaucoup"}}}',
		'{"version": 1, "skin": null}',
	]
	for text: String in damaged:
		write_save_text(text)
		assert_eq(SaveManager.load_game(), ERR_FILE_CORRUPT, "illisible : %s" % text)
		assert_push_error("Sauvegarde illisible")
		assert_false(SaveManager.has_save(), "mis de côté : %s" % text)
		assert_eq(FileAccess.get_file_as_string(SaveManager.backup_path()), text)


func test_export_then_import_restores_state() -> void:
	_fill_state()
	var before := GameState.to_dict()
	var text := SaveManager.export_json()
	GameState.reset()
	watch_signals(EventBus)
	assert_eq(SaveManager.import_json(text), OK)
	assert_signal_emitted(EventBus, "game_loaded")
	assert_eq(JSON.stringify(GameState.to_dict()), JSON.stringify(before))
	assert_false(SaveManager.has_save(), "rien n'est écrit tout de suite")
	assert_true(SaveManager.is_autosave_pending(), "la partie importée va remplacer la sauvegarde")
	assert_eq(SaveManager.flush(), OK)
	assert_eq(read_save()["inventory"], {"page_fragment": 3.0, "flower_blue": 1.0})


func test_invalid_import_is_refused_without_touching_state() -> void:
	_fill_state()
	var before := JSON.stringify(GameState.to_dict())
	var refused := {
		"": ERR_PARSE_ERROR,
		"pas du json": ERR_PARSE_ERROR,
		"[1, 2]": ERR_PARSE_ERROR,
		'"texte"': ERR_PARSE_ERROR,
		'{"version": 99}': ERR_INVALID_DATA,
		'{"version": 1.5}': ERR_INVALID_DATA,
		'{"version": 1, "max_hp": "beaucoup"}': ERR_INVALID_DATA,
		'{"version": 1, "inventory": {"page_fragment": -2}}': ERR_INVALID_DATA,
		'{"version": 1, "collected_pickups": "forest_page_1"}': ERR_INVALID_DATA,
		'{"version": 1, "quests": {"pages": true}}': ERR_INVALID_DATA,
	}
	watch_signals(EventBus)
	for text: String in refused:
		SaveManager.last_error = ""
		assert_eq(SaveManager.import_json(text), refused[text], "refusé : %s" % text)
		assert_ne(SaveManager.last_error, "", "erreur expliquée : %s" % text)
	assert_eq(JSON.stringify(GameState.to_dict()), before, "GameState inchangé")
	assert_signal_not_emitted(EventBus, "game_loaded")
	assert_false(SaveManager.is_game_loaded())
	assert_false(SaveManager.has_save())
