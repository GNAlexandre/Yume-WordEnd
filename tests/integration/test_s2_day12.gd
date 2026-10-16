extends "res://tests/stubs/s2_story_test.gd"
## (S2) Le jour 12, la fin de l'acte 1, dans la vraie partie, avec de vrais appuis : la ligne
## « Départ au couchant. » au calendrier (12.1) ; la dernière embuscade de Pannibal à la sortie du
## porche ; un adieu (Willem, le matin) ; le temps passe jusqu'au couchant ; le départ (12.2) ;
## « Voir l'épilogue » (12.3) ; puis l'état « acte 1 fini » : rien ne plante, pas de lendemain, la
## vie libre continue, et la partie reprise par « Continuer » ne rejoue rien. Et « Passer ».


func test_day_12_until_the_end_of_act_1() -> void:
	assert_true(await begin_day(12, [&"j9_baton_reussi", &"j11_grues"]), "le réveil du jour 12")
	# 12.1 : le calendrier.
	trace("12.1")
	assert_true(await play_until_done(&"j12_1_derniere_journee", 30.0), "la ligne du calendrier")
	assert_eq(StoryDirector.calendar_line(12), "Départ au couchant.")
	assert_true(await wait_control())
	assert_false(StoryDirector.can_sleep(), "le dernier jour : pas de lendemain")
	# La dernière embuscade, dès la sortie.
	trace("embuscade")
	assert_true(await take_exit(&"entrepot_rdc", 60.0))
	assert_true(await take_exit(&"entrepot", 60.0))
	assert_true(await until(func() -> bool: return MiniGames.ambush() != null, 15.0), "elle bondit")
	var ambush := MiniGames.ambush()
	if ambush == null:
		return
	assert_eq(ambush.day, 12, "le jour 12 : les feintes")
	var result := await play_ambush(ambush)
	trace("embuscade fin : %s" % result)
	assert_false(result.is_empty())
	assert_true(await play_until_done(&"j12_1_embuscade", 30.0))
	assert_eq(GameState.has_flag(&"j12_embuscade_gagnee"), bool(result.get("success", false)))
	assert_true(await wait_control())
	# Le matin, un adieu : Willem répare le plafond qui fuit, à l'étage.
	trace("adieux")
	assert_true(await walk_to_point(&"porche_banc", 1.0, 60.0))
	assert_true(await rest_here_until(&"matin"), "le matin")
	assert_true(await take_exit(&"entrepot_rdc", 60.0))
	assert_true(await take_exit(&"entrepot_etage", 60.0))
	assert_true(await walk_to_actor(&"willem", 1.6, 40.0), "Willem")
	await tap_key(INTERACT_KEY)
	assert_true(await until(func() -> bool: return dialogue_box.is_open(), 5.0), "il parle")
	await frames(30)
	var said := (dialogue_box.get_node("%Text") as Label).text
	assert_string_contains(said, "plafond tiendra")
	assert_true(await read_until(func() -> bool: return not dialogue_box.is_open(), 20.0))
	# Le temps passe jusqu'au couchant (la banquette de lecture).
	trace("repos")
	assert_true(await take_exit(&"entrepot_rdc", 60.0))
	assert_true(await walk_to_point(&"lecture_banquette", 1.0, 60.0))
	assert_true(await rest_here_until(&"soir"), "le couchant")
	assert_false(StoryDirector.can_rest(), "pas au-delà du départ")
	assert_eq(StoryDirector.hint(), "La huitième cloche approche. Tous sont dans la cour.")
	# 12.2 : le départ.
	trace("12.2")
	assert_true(await take_exit(&"entrepot", 60.0))
	assert_true(await walk_to_point(&"cour_centre", 4.0, 60.0), "la cour")
	assert_true(
		await play_until_done(&"j12_2_depart", 150.0, {"Fais-le aux noix, le gâteau.": 0}),
		"12.2 jouée"
	)
	assert_true(GameState.has_flag(&"j12_voir_epilogue"), "« Voir l'épilogue »")
	trace("12.3")
	assert_true(await play_until_done(&"j12_3_epilogue", 150.0), "l'épilogue")
	await _assert_act_over()
	# Reprise de la partie finie : rien ne se rejoue.
	SaveManager.save()
	assert_true(await continue_game(), "partie reprise")
	await frames(30)
	await _assert_act_over()
	assert_true(await walk_to(player.global_position + Vector3(2.0, 0.0, 0.0), 0.5, 5.0))


func test_day_12_skip_the_epilogue() -> void:
	var done: Array[StringName] = [&"j12_1_derniere_journee", &"j12_1_embuscade"]
	var at := Vector3(44.0, 0.0, 41.0)
	assert_true(await begin_day(12, [], done, &"soir", &"entrepot", at), "le couchant")
	assert_true(await walk_to_point(&"cour_centre", 4.0, 30.0), "la cour")
	assert_true(await play_until_done(&"j12_2_depart", 150.0, {"Passer": 1}), "12.2 jouée")
	assert_false(GameState.has_flag(&"j12_voir_epilogue"))
	await frames(20)
	assert_false(GameState.is_scene_done(&"j12_3_epilogue"), "pas d'épilogue")
	await _assert_act_over()


## L'acte 1 est fini : drapeau, nuit du jour 12, aucune scène ni indice, pas de lendemain, le
## joueur a la main dans la cour.
func _assert_act_over() -> void:
	assert_true(await wait_control(20.0), "la main revient")
	assert_true(GameState.has_flag(&"acte1_fini"), "acte 1 fini")
	assert_eq(GameState.day, 12)
	assert_eq(LifeSlots.current(), &"nuit")
	assert_eq(WorldManager.current_map(), &"entrepot")
	assert_false(StoryDirector.is_playing())
	assert_eq(StoryDirector.hint(), "", "plus rien n'attend")
	assert_false(StoryDirector.can_sleep(), "pas de jour 13")
	assert_false(StoryDirector.can_rest())
	assert_eq(GameState.story_scene, &"")
