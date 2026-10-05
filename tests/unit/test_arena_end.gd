extends "res://tests/stubs/l10_ui_test.gd"
## Fin d'arène (L10) : valeurs du panneau (score, vague atteinte, meilleur score, séries), record,
## Continuer ; mort dans l'arène : le panneau attend la réapparition sans figer le jeu avant.
## Le WaveDirector (L5) appelle GameState.record_score avant d'émettre arena_finished : les tests
## font de même.

const ARENA_END := preload("res://src/ui/arena_end.tscn")
const ArenaEndScript := preload("res://src/ui/arena_end.gd")


func _panel() -> ArenaEndScript:
	return add_child_autofree(ARENA_END.instantiate())


func _text(panel: Control, unique_name: String) -> String:
	return (panel.get_node("%" + unique_name) as Label).text


## Fin de série comme le WaveDirector : record_score, puis arena_finished.
func _finish(score: int, wave: int) -> void:
	EventBus.wave_started.emit(&"dunes", wave, 3 + 2 * wave)
	var best := GameState.record_score(&"dunes", score, wave)
	EventBus.arena_finished.emit(&"dunes", score, best)


func test_shows_score_wave_best_and_record() -> void:
	var panel := _panel()
	_finish(450, 4)
	await wait_process_frames(1)
	assert_true(panel.is_open(), "panneau « Fin de la série »")
	assert_true(get_tree().paused, "le jeu attend Continuer")
	assert_eq(_text(panel, "ScoreValue"), "450")
	assert_eq(_text(panel, "WaveValue"), "4", "vague atteinte")
	assert_eq(_text(panel, "BestValue"), "450")
	assert_eq(_text(panel, "GamesValue"), "1")
	assert_eq(_text(panel, "ArenaName"), WorldManager.zone_display_name(&"dunes"))
	assert_true(panel.get_node("%RecordBadge").visible, "« Nouveau record ! »")
	assert_eq(focus_owner(), panel.get_node("%ContinueButton"))


func test_without_record_shows_previous_best() -> void:
	GameState.record_score(&"dunes", 600, 6)
	var panel := _panel()
	_finish(120, 2)
	await wait_process_frames(1)
	assert_false(panel.get_node("%RecordBadge").visible, "pas de record")
	assert_eq(_text(panel, "ScoreValue"), "120")
	assert_eq(_text(panel, "WaveValue"), "2")
	assert_eq(_text(panel, "BestValue"), "600", "GameState.arena_record")
	assert_eq(_text(panel, "GamesValue"), "2")


func test_continue_closes_and_resumes() -> void:
	var panel := _panel()
	_finish(80, 1)
	await wait_process_frames(1)
	(panel.get_node("%ContinueButton") as Button).pressed.emit()
	assert_false(panel.is_open())
	assert_false(get_tree().paused, "le jeu reprend")


func test_series_ended_before_first_wave() -> void:
	var panel := _panel()
	EventBus.arena_finished.emit(&"dunes", 0, GameState.record_score(&"dunes", 0, 0))
	await wait_process_frames(1)
	assert_true(panel.is_open())
	assert_eq(_text(panel, "WaveValue"), "–", "aucune vague commencée")


func test_waits_for_respawn_after_death() -> void:
	var panel := _panel()
	EventBus.player_died.emit()
	_finish(200, 3)
	await wait_process_frames(2)
	assert_false(panel.is_open(), "pas pendant la mort")
	assert_true(panel.is_waiting())
	assert_false(get_tree().paused, "la réapparition de WorldManager n'est pas retardée")
	EventBus.player_respawned.emit()
	await wait_process_frames(1)
	assert_true(panel.is_open(), "affiché au village")
	assert_eq(_text(panel, "WaveValue"), "3")


func test_arena_finished_emitted_inside_player_died() -> void:
	# Le WaveDirector, branché avant l'interface, termine la série pendant player_died : le
	# panneau reçoit arena_finished avant d'apprendre la mort.
	var finish := func() -> void: _finish(90, 2)
	EventBus.player_died.connect(finish)
	var panel := _panel()
	EventBus.player_died.emit()
	EventBus.player_died.disconnect(finish)
	await wait_process_frames(2)
	assert_false(panel.is_open(), "attend la réapparition")
	assert_false(get_tree().paused)
	EventBus.player_respawned.emit()
	await wait_process_frames(1)
	assert_true(panel.is_open())


func test_gamepad_a_continues_on_release() -> void:
	var panel := _panel()
	_finish(30, 1)
	await wait_process_frames(1)
	tap_joy(JOY_BUTTON_A)
	assert_false(panel.is_open())
	assert_false(get_tree().paused)
