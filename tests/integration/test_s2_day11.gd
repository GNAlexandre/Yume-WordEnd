extends "res://tests/stubs/s2_late_test.gd"
## (S2) Le jour 11 de l'acte 1 de bout en bout dans la vraie partie, avec de vrais appuis : la
## toilette à l'eau glacée et Collon rattrapée (11.1) ; « Ne pars pas ! » dans le couloir (11.2) ;
## la porte de la maison Limashenka, ouverte ce jour-là, et l'horloge (11.3) ; l'entraînement avec
## Seniorious à la clairière, commencé à l'étape 2 après la réussite du jour 9, l'épée ramassée
## dans le marais, la question contre l'arbre (11.4) ; « Dormir » ; le jour 12.


func test_day_11_end_to_end_until_day_12() -> void:
	assert_true(await begin_day(11, [&"j9_baton_reussi"]), "partie reprise au réveil du jour 11")
	# 11.1 : la toilette.
	trace("11.1")
	assert_true(
		await until(func() -> bool: return StoryDirector.current_scene() == &"j11_1_toilette", 10.0)
	)
	assert_true(await wait_control())
	assert_eq(StoryDirector.hint(), "Les petites se lavent au point d'eau, en bas.")
	assert_true(await take_exit(&"entrepot_rdc", 60.0))
	assert_true(await walk_to_point(&"point_eau", 3.0, 40.0), "le point d'eau")
	assert_true(
		await read_until(
			func() -> bool:
				return not player.is_story_held() and StoryDirector.hint().begins_with("Collon"),
			40.0
		)
	)
	assert_true(await walk_to_actor(&"collon", 1.2, 25.0), "Collon rattrapée")
	assert_true(await play_until_done(&"j11_1_toilette", 60.0), "11.1 jouée")
	assert_false(GameState.has_flag(&"j11_collon_revenue"), "rattrapée avant les 30 s")
	# 11.2 : « Ne pars pas ! » (enchaîné).
	trace("11.2")
	assert_true(
		await play_until_done(&"j11_2_ne_pars_pas", 90.0, {"… Va réparer ton horloge.": 1}),
		"11.2 jouée"
	)
	assert_true(await wait_control())
	assert_eq(StoryDirector.hint(), "Willem répare une horloge au village.")
	# 11.3 : la maison Limashenka (porte ouverte le jour 11).
	trace("11.3")
	assert_true(await take_exit(&"entrepot", 60.0))
	assert_true(await take_exit(&"village", 80.0))
	assert_true(await take_exit(&"maison_limashenka", 60.0), "la porte s'ouvre le jour 11")
	assert_true(await play_until_done(&"j11_3_horloge", 120.0, {"Il est beau.": 1}), "11.3")
	assert_eq(LifeSlots.current(), &"apres_midi", "la sixième cloche")
	assert_true(await wait_control())
	assert_eq(StoryDirector.hint(), "Willem t'attend dans la clairière, avec Seniorious.")
	# 11.4 : l'entraînement avec Seniorious.
	trace("11.4")
	assert_true(await take_exit(&"village", 30.0))
	assert_true(await take_exit(&"entrepot", 80.0))
	var weapon_before := player.weapon()
	assert_true(await walk_to_point(&"clairiere_centre", 5.5, 80.0), "la clairière")
	assert_true(
		await read_until(func() -> bool: return MiniGames.seniorious_training() != null, 40.0),
		"l'entraînement avec Seniorious"
	)
	var training := MiniGames.seniorious_training()
	assert_eq(training.start_stage, 2, "réussite du jour 9 : l'étape 2 d'emblée")
	assert_eq(player.weapon(), &"seniorious")
	var result := await play_seniorious()
	trace("11.4 fin : %s" % result)
	assert_false(result.is_empty(), "l'exercice finit")
	assert_true(await play_until_done(&"j11_4_seniorious", 90.0, {"Tu seras encore là ?": 1}))
	assert_eq(
		GameState.has_flag(&"j11_grues"), bool(result.get("success", false)), "les trois Grues"
	)
	if result.get("success", false):
		assert_true(result.get("picked_up", false), "Seniorious ramassée dans le marais")
	assert_eq(LifeSlots.current(), &"soir")
	assert_true(await wait_control())
	assert_eq(player.weapon(), weapon_before, "l'arme d'avant revient hors de la scène")
	assert_true(StoryDirector.can_sleep())
	trace("dormir")
	assert_true(await sleep_in_bed(), "jour 12")
	assert_string_contains(StoryDirector.calendar_line(11), "Une horloge.")
