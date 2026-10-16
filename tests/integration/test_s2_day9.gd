extends "res://tests/stubs/s2_late_test.gd"
## (S2) Le jour 9 de l'acte 1 de bout en bout dans la vraie partie, avec de vrais appuis : la
## sauvegarde du réveil reprise par « Continuer » ; on frappe à la porte (9.1) ; les bâtons dans la
## clairière (9.2, l'entraînement d'E8 joué à la parade et au coup) ; le temps passe sur le banc du
## porche ; l'argent de poche, le café du village et la coupe sur la terrasse (9.3) ; le thé à la
## moutarde (9.4, l'invite « S'asseoir ») ; la veillée (9.5) ; « Dormir » ; le jour 10.


func test_day_9_end_to_end_until_day_10() -> void:
	assert_true(await begin_day(9), "partie reprise au réveil du jour 9")
	assert_eq(GameState.day, 9)
	assert_eq(WorldManager.current_map(), &"entrepot_etage")
	# 9.1 : on frappe à la porte (dès le réveil).
	trace("9.1")
	assert_true(
		await until(func() -> bool: return StoryDirector.current_scene() == &"j9_1_porte", 10.0)
	)
	assert_true(
		await play_until_done(&"j9_1_porte", 60.0, {"Tu aurais pu prévenir !": 1}), "9.1 jouée"
	)
	assert_eq(LifeSlots.current(), &"matin", "le matin vient")
	assert_true(await wait_control())
	assert_eq(StoryDirector.hint(), "Willem t'attend dans la clairière.")
	# 9.2 : la clairière.
	trace("9.2")
	assert_true(await take_exit(&"entrepot_rdc", 60.0), "en bas")
	assert_true(await take_exit(&"entrepot", 60.0), "dehors")
	assert_true(await walk_to_point(&"clairiere_centre", 5.5, 60.0), "la clairière")
	assert_true(
		await until(func() -> bool: return StoryDirector.current_scene() == &"j9_2_batons", 5.0)
	)
	assert_true(
		await read_until(func() -> bool: return MiniGames.staff_training() != null, 40.0),
		"l'entraînement au bâton commence"
	)
	assert_false(player.is_story_held(), "le joueur a la main pendant l'exercice")
	assert_eq(player.weapon(), &"baton", "le bâton")
	var hp := player.health.current
	var result := await play_staff_training()
	trace("9.2 fin : %s" % result)
	assert_false(result.is_empty(), "l'exercice finit")
	assert_eq(player.health.current, hp, "aucun vrai dégât")
	assert_true(await play_until_done(&"j9_2_batons", 60.0), "9.2 jouée")
	assert_eq(
		GameState.has_flag(&"j9_baton_reussi"),
		bool(result.get("success", false)),
		"la réussite est retenue (le jour 11 en dépend)"
	)
	assert_true(await wait_control())
	# Le temps passe sur le banc du porche jusqu'à l'après-midi (9.3 est une scène clé).
	trace("repos")
	assert_true(await walk_to_point(&"porche_banc", 1.0, 60.0))
	assert_true(await rest_until(&"apres_midi"), "l'après-midi, sur le banc")
	# 9.3 : l'argent de poche sous le porche, puis le café du village.
	trace("9.3")
	assert_true(
		await read_until(func() -> bool: return StoryDirector.current_scene() == &"j9_3_cafe", 10.0)
	)
	assert_true(await read_until(func() -> bool: return not player.is_story_held(), 40.0))
	assert_eq(StoryDirector.hint(), "Ithea et Nephren vont au café du village.")
	assert_has(StoryDirector.stage().followers(), &"ithea", "Ithea suit")
	assert_true(await take_exit(&"village", 80.0), "le village")
	assert_true(await take_exit(&"cafe", 60.0), "le café")
	assert_true(await play_until_done(&"j9_3_cafe", 90.0, {"Il ne partirait pas.": 1}), "9.3")
	assert_eq(WorldManager.current_map(), &"cafe")
	assert_true(await wait_control())
	# Retour à l'entrepôt ; le soir sur la banquette de lecture ; le goûter.
	trace("9.4")
	assert_true(await take_exit(&"village", 30.0))
	assert_true(await take_exit(&"entrepot", 80.0))
	assert_true(await take_exit(&"entrepot_rdc", 60.0))
	assert_true(await walk_to_point(&"lecture_banquette", 1.0, 60.0))
	assert_true(await rest_until(&"soir"), "le soir")
	assert_eq(StoryDirector.hint(), "Le goûter du soir est servi au réfectoire.")
	# Par la porte est du réfectoire, puis le bout de la table (le chemin de la navigation coupe
	# entre les tables, que le joueur ne traverse pas).
	var door := StoryDirector.stage().resolve(&"refectoire_porte_est").origin
	assert_true(await walk_to(door + Vector3(0.0, 0.0, 1.5), 0.5, 40.0), "devant la porte est")
	assert_true(await walk_straight(door), "la porte est")
	var table_end := StoryDirector.stage().resolve(&"refectoire_bout_est").origin
	assert_true(await walk_straight(table_end + Vector3(0.4, 0.0, 0.0)), "le bout de la table")
	assert_true(await use_prompt(StoryPrompt.ROLE_SCENE), "l'invite « S'asseoir »")
	assert_true(await play_until_done(&"j9_4_moutarde", 60.0), "9.4 jouée")
	assert_eq(LifeSlots.current(), &"nuit", "la nuit tombe")
	assert_true(await wait_control())
	# 9.5 : la veillée.
	trace("9.5")
	assert_eq(StoryDirector.hint(), "Il y a de la lumière au réfectoire.")
	assert_false(StoryDirector.can_sleep(), "pas avant la veillée")
	assert_true(await walk_to_point(&"refectoire_veillee", 2.0, 40.0))
	assert_true(await play_until_done(&"j9_5_veillee", 60.0, {"Sans sucre.": 1}), "9.5 jouée")
	assert_true(await wait_control())
	assert_true(StoryDirector.can_sleep(), "on peut se coucher")
	assert_eq(StoryDirector.hint(), "La veillée est finie. Au lit.")
	trace("dormir")
	assert_true(await sleep_in_bed(), "jour 10")
	assert_eq(LifeSlots.current(), &"aube")
	assert_string_contains(StoryDirector.calendar_line(9), "moutarde")
	assert_eq(GameState.quests(), {}, "aucune quête à collecter")
