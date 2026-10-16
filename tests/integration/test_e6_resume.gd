extends "res://tests/stubs/e6_story_test.gd"
## (E6) Sauvegarde et reprise dans la vraie partie : au milieu du jour 1 (entre deux scènes),
## « Continuer » reprend au même jour, au même créneau, avec ses scènes jouées et son indice ;
## une partie fermée au milieu d'une scène la rejoue depuis son début ; (F1) une sauvegarde d'avant
## la refonte (l'ancienne île, retirée) reprend à l'acte 1, à l'entrepôt, et le menu le dit d'une
## ligne (data/texts/story.json, save/migrated) qui reste lisible pendant le chargement.

const V2_REAL_SAVE := "res://tests/data/saves/save_v2_avant_refonte.json"
const MenuNotice := preload("res://src/ui/main_menu_notice.gd")


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
	assert_false(GameState.to_dict().has("quests"), "(F1) plus de quêtes")
	assert_true(await take_exit(&"sentier", 60.0))
	assert_true(await walk_to_point(&"premiere_embuscade", 1.0, 40.0))
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


func test_old_save_restarts_the_first_act() -> void:
	var file := FileAccess.open(SaveManager.save_path, FileAccess.WRITE)
	file.store_string(FileAccess.get_file_as_string(V2_REAL_SAVE))
	file.close()
	StoryDirector.mark_seen(&"j1_1_port")
	await open_main()
	await click_center()
	assert_true(menu_button("ContinueButton").visible, "Continuer")
	await click(menu_button("ContinueButton"))
	var notice := DialogueRunner.story_text("save/migrated")
	assert_false(notice.is_empty(), "le texte de l'avis existe")
	assert_eq(SaveManager.notice, notice, "SaveManager dit pourquoi")
	assert_true(await wait_for_game(), "partie lancée")
	assert_eq(MenuNotice.current_text(get_tree()), notice, "l'avis reste lisible dans le jeu")
	assert_eq(WorldManager.current_map(), &"entrepot", "l'acte 1 commence à l'entrepôt")
	assert_true(GameState.story_running(), "avec le récit")
	assert_eq(GameState.day, 1, "jour 1")
	assert_eq(GameState.skin_id, &"chtholly", "le skin de la partie")
	assert_eq(GameState.count(&"page_fragment"), 0, "rien de l'ancienne île")
	assert_false(GameState.has_flag(&"met_willem"))
	assert_true(FileAccess.file_exists(SaveManager.legacy_backup_path()), "l'ancienne gardée")
	assert_true(
		await until(func() -> bool: return StoryDirector.current_scene() == &"j1_1_port", 5.0),
		"le début de l'acte"
	)
	await tap_key(KEY_ESCAPE)
	var root_notice := get_tree().root.get_node_or_null(NodePath(String(MenuNotice.NODE_NAME)))
	if root_notice != null:
		root_notice.free()
