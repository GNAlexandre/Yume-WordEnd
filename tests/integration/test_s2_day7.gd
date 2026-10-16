extends "res://tests/stubs/s2_story_test.gd"
## (S2) Le jour 7 de l'acte 1, « Le jour de pluie », de bout en bout dans la vraie partie, avec de
## vrais appuis : la partie reprise à l'aube du jour 7 (« Continuer ») ; les aînées absentes (V1) ;
## l'étage, l'escalier, la porte ; le départ sous le porche (7.1, choix au clavier), la marche
## jusqu'au chemin de l'est avec Ithea et Nephren qui suivent ; le match et la salle des armes,
## séquences déjà vues, passées d'Échap ; le port sous la pluie (7.4 : le transport de la Garde
## descend, s'amarre, pose sa passerelle, jamais d'embarquement ; on la descend au stick) ; la nuit
## de fièvre (7.5) ; la nuit blanche aux archives (7.6, jouée en entier), qui écrit la ligne du
## calendrier et ouvre le jour 8 (sans « Dormir »).


func test_day_7_end_to_end_until_day_8() -> void:
	StoryDirector.mark_seen(&"j7_2_match")
	StoryDirector.mark_seen(&"j7_3_armes")
	assert_true(await continue_at_day(7, &"entrepot_etage", Vector3(6.2, 0.0, 7.4)), "partie")
	assert_eq(GameState.day, 7)
	assert_eq(LifeSlots.current(), &"aube")
	await frames(10)
	trace("1")
	assert_eq(StoryDirector.hint(), "Nygglatho t'attend sous le porche, avec les épées.")
	assert_false(StoryDirector.can_sleep(), "le jour 7 ne finit pas au lit")
	assert_false(StoryDirector.can_rest(), "rien ne passe avant le départ")
	assert_null(LifeDirector.actor(&"ithea"), "V1 : les aînées sont absentes (au port)")
	# 7.1 : l'escalier, la porte, le porche.
	assert_true(await take_exit(&"entrepot_rdc", 40.0), "le rez-de-chaussée")
	assert_true(
		await take_exit_near(&"entrepot", &"vers_entrepot", 40.0), "dehors, par la porte d'entrée"
	)
	trace("2")
	assert_true(
		await until(func() -> bool: return StoryDirector.current_scene() == &"j7_1_depart", 5.0),
		"le départ commence sous le porche"
	)
	assert_true(
		await read_until(
			func() -> bool: return StoryDirector.runner().current_step() == "wait_for",
			40.0,
			{"Garde-les bien.": 1}
		)
	)
	trace("3")
	assert_false(player.is_story_held(), "la main pour la marche")
	assert_eq(StoryDirector.hint(), "Pars avec Ithea et Nephren par le chemin de l'est.")
	assert_has(StoryDirector.stage().followers(), &"ithea", "Ithea suit")
	assert_has(StoryDirector.stage().followers(), &"nephren", "Nephren suit")
	assert_true(await walk_to_point(&"vers_sentier", 2.5, 40.0), "le chemin de l'est")
	# 7.1 (fin) : la fenêtre de Willem, puis 7.2 et 7.3, déjà vues : Échap.
	for sequence: StringName in [&"j7_2_match", &"j7_3_armes"]:
		trace("séquence %s" % sequence)
		assert_true(
			await read_until(
				func() -> bool: return StoryDirector.current_scene() == sequence, 60.0
			),
			"%s commence" % sequence
		)
		assert_true(StoryDirector.is_skippable(), "%s déjà vue" % sequence)
		await frames(5)
		await tap_key(KEY_ESCAPE)
		assert_false(pause_menu.is_open(), "Échap passe la séquence")
		assert_true(await until(func() -> bool: return GameState.is_scene_done(sequence), 10.0))
	assert_true(GameState.is_scene_done(&"j7_1_depart"))
	# 7.4 : le port sous la pluie.
	trace("4")
	assert_true(
		await read_until(
			func() -> bool: return StoryDirector.runner().current_step() == "wait_for", 120.0
		),
		"le transport s'est posé, la main pour descendre"
	)
	trace("5")
	assert_eq(WorldManager.current_map(), &"port")
	assert_eq(LifeSlots.current(), &"soir", "le crépuscule")
	assert_eq(GameState.weather, &"pluie", "pluie fine au port")
	assert_true(ShipControl.is_docked(&"transport_garde"), "à quai")
	assert_true(ShipControl.has_flag(&"transport_garde", &"gangway"), "passerelle posée")
	assert_false(
		ShipControl.has_flag(&"transport_garde", &"boarding"), "jamais d'embarquement à l'acte 1"
	)
	assert_eq(StoryDirector.hint(), "Descends la passerelle.")
	assert_true(await walk_to_point(&"from_transport_garde", 1.0, 15.0), "la passerelle descendue")
	assert_true(
		await play_until_done(&"j7_4_port", 90.0, {"(Se taire, poser la tête.)": 1}), "le retour"
	)
	trace("6")
	# 7.5 : la nuit de fièvre (premier choix : « Dans cinq jours… »).
	assert_true(await play_until_done(&"j7_5_fievre", 90.0), "la nuit de fièvre")
	assert_eq(LifeSlots.current(), &"nuit")
	assert_null(LifeDirector.actor(&"chtholly_double"), "la doublure couchée est partie")
	# 7.6 : la nuit blanche aux archives, jouée en entier ; le jour 8 commence.
	trace("7")
	assert_true(await play_until_done(&"j7_6_archives", 90.0), "les archives")
	assert_eq(GameState.day, 8, "le jour 8, sans passer par le lit")
	assert_true(GameState.has_calendar_line(7), "la ligne du jour 7")
	assert_string_contains(StoryDirector.calendar_line(7), "trop parlé")
	assert_false(
		ShipControl.has_flag(&"transport_garde", &"boarding"), "toujours pas d'embarquement"
	)
	assert_true(
		await until(func() -> bool: return StoryDirector.current_scene() == &"j8_1_reveil", 10.0),
		"le réveil du jour 8 à l'infirmerie"
	)
