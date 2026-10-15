extends "res://tests/stubs/e6_story_test.gd"
## (E6) Sauvegarde et reprise dans la vraie partie : au milieu du jour 1 (entre deux scènes),
## « Continuer » reprend au même jour, au même créneau, avec ses scènes jouées et son indice ;
## une partie fermée au milieu d'une scène la rejoue depuis son début ; une sauvegarde d'avant
## la refonte reprend sur l'ancienne île, avec ses quêtes, sans récit.

const V2_REAL_SAVE := "res://tests/data/saves/save_v2_avant_refonte.json"


func _skip_port() -> void:
	StoryDirector.mark_seen(&"j1_1_port")
	assert_true(
		await until(func() -> bool: return StoryDirector.current_scene() == &"j1_1_port", 5.0)
	)
	await tap_key(KEY_ESCAPE)


func _continue() -> bool:
	await close_tab()
	await open_main()
	await click_center()
	assert_true(menu_button("ContinueButton").visible, "Continuer")
	await click(menu_button("ContinueButton"))
	return await wait_for_game()


func test_resume_in_the_middle_of_day_1() -> void:
	assert_true(await new_game_from_menu())
	await _skip_port()
	assert_true(await play_until_done(&"j1_2_lumiere", 40.0))
	assert_true(await wait_control())
	var hint := StoryDirector.hint()
	assert_false(hint.is_empty())
	await walk_to(player.global_position + Vector3(2, 0, 3), 0.5, 5.0)
	var left_at := player.global_position
	SaveManager.save()
	assert_true(await _continue(), "partie reprise")
	assert_eq(WorldManager.current_map(), &"entrepot")
	assert_lt(flat_distance(player.global_position, left_at), 0.3, "position restaurée")
	assert_eq(GameState.day, 1, "même jour")
	assert_eq(LifeSlots.current(), &"nuit", "même créneau")
	assert_true(GameState.is_scene_done(&"j1_2_lumiere"), "scènes jouées gardées")
	assert_false(GameState.is_scene_done(&"j1_2_embuscade"))
	await frames(10)
	assert_eq(StoryDirector.hint(), hint, "même indice")
	assert_false(StoryDirector.is_playing(), "aucune scène rejouée")
	assert_eq(GameState.quests(), {})
	assert_true(await take_exit(&"sentier", 60.0))
	assert_true(
		await until(func() -> bool: return StoryDirector.current_scene() == &"j1_2_embuscade", 5.0),
		"le récit continue"
	)


func test_closed_during_a_scene_replays_it() -> void:
	assert_true(await new_game_from_menu())
	await _skip_port()
	assert_true(await until(func() -> bool: return dialogue_box.is_open(), 20.0), "le porche")
	assert_eq(GameState.story_scene, &"j1_2_lumiere")
	SaveManager.save()
	assert_true(await _continue(), "partie reprise")
	assert_true(
		await until(func() -> bool: return StoryDirector.current_scene() == &"j1_2_lumiere", 5.0),
		"la scène reprend"
	)
	assert_true(await play_until_done(&"j1_2_lumiere", 40.0))
	assert_eq(GameState.story_scene, &"")


func test_old_save_resumes_on_the_old_island() -> void:
	var file := FileAccess.open(SaveManager.save_path, FileAccess.WRITE)
	file.store_string(FileAccess.get_file_as_string(V2_REAL_SAVE))
	file.close()
	await open_main()
	await click_center()
	await click(menu_button("ContinueButton"))
	assert_true(await wait_for_game(), "partie reprise")
	assert_eq(WorldManager.current_map(), WorldManager.LEGACY_MAP, "l'ancienne île")
	assert_false(GameState.story_running(), "sans récit")
	assert_false(GameState.quests().is_empty(), "ses quêtes")
	assert_true((hud.get_node("%Quests") as Control).visible, "l'encadré de quête reste là-bas")
