extends "res://tests/stubs/l8_save_test.gd"
## SaveManager, auto-sauvegarde (L8) : déclenchée par arena_finished, item_collected,
## quest_updated, zone_entered et save_requested ; regroupée (au plus une écriture par délai) ;
## minuteur actif en pause ; jamais avant game_loaded ; game_loaded émis par new_game,
## load_game et import_json.

## Délai court pour les tests de déclenchement (le délai réel est testé à part).
const SHORT_DELAY := 0.1

var _write_times: Array[int] = []
var _last_frame_ms: int = 0
var _longest_frame_ms: int = 0


## Un émetteur par signal qui déclenche l'auto-sauvegarde.
func _triggers() -> Dictionary[String, Callable]:
	return {
		"arena_finished": func() -> void: EventBus.arena_finished.emit(&"dunes", 120, true),
		"item_collected": func() -> void: EventBus.item_collected.emit(&"page_fragment", 1),
		"quest_updated": func() -> void: EventBus.quest_updated.emit(&"pages", &"active"),
		"zone_entered": func() -> void: EventBus.zone_entered.emit(&"beach"),
		"save_requested": func() -> void: EventBus.save_requested.emit(),
	}


func _emit_all() -> void:
	for trigger: Callable in _triggers().values():
		trigger.call()


func _record_write(_path: String) -> void:
	_write_times.append(Time.get_ticks_msec())


## Plus longue image : un Timer peut partir jusqu'à une image en avance (delta de l'image où il
## démarre), d'où cette marge dans les mesures d'écart.
func _record_frame() -> void:
	var now := Time.get_ticks_msec()
	if _last_frame_ms > 0:
		_longest_frame_ms = maxi(_longest_frame_ms, now - _last_frame_ms)
	_last_frame_ms = now


func test_default_delay_is_half_a_second() -> void:
	assert_eq(SaveManager.autosave_delay, 0.5)
	assert_eq(SaveManager.DEFAULT_AUTOSAVE_DELAY, 0.5)


func test_each_signal_triggers_an_autosave() -> void:
	SaveManager.autosave_delay = SHORT_DELAY
	start_game()
	var triggers := _triggers()
	for signal_name: String in triggers:
		delete_save_files(SaveManager.save_path)
		triggers[signal_name].call()
		assert_true(SaveManager.is_autosave_pending(), "%s : écriture demandée" % signal_name)
		assert_false(SaveManager.has_save(), "%s : pas d'écriture immédiate" % signal_name)
		var written: bool = await wait_real_until(SaveManager.has_save, 2.0)
		assert_true(written, "%s : sauvegarde écrite après le délai" % signal_name)


func test_burst_of_signals_gives_one_write_with_final_state() -> void:
	SaveManager.autosave_delay = SHORT_DELAY
	start_game()
	watch_signals(SaveManager)
	_emit_all()
	for _i in 10:
		GameState.add_item(&"page_fragment")
		EventBus.item_collected.emit(&"page_fragment", 1)
	# Récompense donnée après quest_updated (QuestTracker) : elle doit être dans le fichier.
	GameState.set_quest_state(&"pages", &"done")
	GameState.add_item(&"bookmark")
	await wait_real(SHORT_DELAY * 4.0)
	assert_signal_emit_count(SaveManager, "saved", 1, "une seule écriture pour la rafale")
	var data := read_save()
	assert_eq(data["inventory"], {"page_fragment": 10.0, "bookmark": 1.0}, "état final écrit")
	assert_eq(data["quests"], {"pages": "done"})
	assert_eq(data["zone"], "beach", "zone mise à jour par WorldManager après le signal")


func test_at_most_one_write_per_delay() -> void:
	SaveManager.autosave_delay = 0.2
	start_game()
	_write_times.clear()
	_last_frame_ms = 0
	_longest_frame_ms = 0
	SaveManager.saved.connect(_record_write)
	get_tree().process_frame.connect(_record_frame)
	var stop_at := Time.get_ticks_msec() + 900
	while Time.get_ticks_msec() < stop_at:
		EventBus.item_collected.emit(&"page_fragment", 1)
		await wait_real(0.03)
	await wait_real(0.3)
	SaveManager.saved.disconnect(_record_write)
	get_tree().process_frame.disconnect(_record_frame)
	assert_between(_write_times.size(), 3, 6, "écritures régulières pendant 0,9 s de signaux")
	var minimum_gap := 200 - _longest_frame_ms - 2
	for i in range(1, _write_times.size()):
		assert_gte(_write_times[i] - _write_times[i - 1], minimum_gap, "écart entre deux écritures")


func test_default_delay_groups_within_half_a_second() -> void:
	start_game()
	delete_save_files(SaveManager.save_path)
	watch_signals(SaveManager)
	var started := Time.get_ticks_msec()
	_emit_all()
	await wait_real(0.25)
	assert_signal_not_emitted(SaveManager, "saved", "rien avant 0,5 s")
	assert_true(SaveManager.is_autosave_pending())
	var written: bool = await wait_real_until(func() -> bool: return SaveManager.has_save(), 2.0)
	assert_true(written)
	assert_signal_emit_count(SaveManager, "saved", 1)
	assert_between(Time.get_ticks_msec() - started, 400, 1500, "écrite vers 0,5 s")


func test_autosave_timer_runs_while_paused() -> void:
	SaveManager.autosave_delay = SHORT_DELAY
	start_game()
	delete_save_files(SaveManager.save_path)
	get_tree().paused = true
	EventBus.item_collected.emit(&"page_fragment", 1)
	var written: bool = await wait_real_until(SaveManager.has_save, 2.0)
	get_tree().paused = false
	assert_true(written, "écrite pendant la pause")


func test_nothing_is_written_before_game_loaded() -> void:
	SaveManager.autosave_delay = SHORT_DELAY
	watch_signals(SaveManager)
	_emit_all()
	assert_false(SaveManager.is_autosave_pending(), "rien n'est demandé au menu")
	await wait_real(SHORT_DELAY * 3.0)
	assert_false(SaveManager.has_save(), "rien n'est écrit au menu")
	assert_signal_not_emitted(SaveManager, "saved")
	EventBus.game_loaded.emit()
	assert_true(SaveManager.is_game_loaded())
	EventBus.item_collected.emit(&"page_fragment", 1)
	assert_true(SaveManager.is_autosave_pending(), "après game_loaded, les signaux comptent")


func test_close_game_writes_pending_then_stops() -> void:
	start_game()
	GameState.add_item(&"page_fragment", 2)
	EventBus.item_collected.emit(&"page_fragment", 2)
	delete_save_files(SaveManager.save_path)
	SaveManager.close_game()
	assert_true(SaveManager.has_save(), "écriture en attente faite tout de suite")
	assert_eq(read_save()["inventory"], {"page_fragment": 2.0})
	assert_false(SaveManager.is_game_loaded())
	_emit_all()
	assert_false(SaveManager.is_autosave_pending(), "plus d'auto-sauvegarde après close_game")


func test_flush_writes_only_when_pending() -> void:
	start_game()
	watch_signals(SaveManager)
	assert_eq(SaveManager.flush(), OK)
	assert_signal_not_emitted(SaveManager, "saved", "rien en attente : rien d'écrit")
	EventBus.save_requested.emit()
	assert_eq(SaveManager.flush(), OK)
	assert_signal_emit_count(SaveManager, "saved", 1)
	assert_false(SaveManager.is_autosave_pending())


func test_losing_focus_or_closing_writes_pending_save() -> void:
	start_game()
	for what: int in SaveManager.FLUSH_NOTIFICATIONS:
		delete_save_files(SaveManager.save_path)
		EventBus.item_collected.emit(&"page_fragment", 1)
		SaveManager.notification(what)
		assert_true(SaveManager.has_save(), "notification %d : écrite sans attendre" % what)
		assert_false(SaveManager.is_autosave_pending())
	delete_save_files(SaveManager.save_path)
	SaveManager.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	assert_false(SaveManager.has_save(), "sans écriture en attente, rien à la fermeture")


func test_new_load_and_import_emit_game_loaded() -> void:
	watch_signals(EventBus)
	SaveManager.new_game(&"enfant")
	assert_signal_emit_count(EventBus, "game_loaded", 1, "new_game")
	assert_eq(GameState.skin_id, &"enfant")
	assert_eq(SaveManager.save(), OK)
	assert_eq(SaveManager.load_game(), OK)
	assert_signal_emit_count(EventBus, "game_loaded", 2, "load_game")
	assert_eq(SaveManager.import_json(SaveManager.export_json()), OK)
	assert_signal_emit_count(EventBus, "game_loaded", 3, "import_json")
	assert_true(SaveManager.is_game_loaded())


func test_loading_drops_the_pending_write_of_the_replaced_game() -> void:
	SaveManager.autosave_delay = SHORT_DELAY
	start_game(&"enfant")
	GameState.add_item(&"page_fragment", 4)
	EventBus.item_collected.emit(&"page_fragment", 4)
	# « Charger » revient au fichier : l'état en mémoire, non écrit, ne doit pas l'écraser.
	assert_eq(SaveManager.load_game(), OK)
	assert_eq(GameState.count(&"page_fragment"), 0)
	await wait_real(SHORT_DELAY * 3.0)
	assert_false(read_save()["inventory"].has("page_fragment"), "fichier jamais écrasé")
