extends "res://tests/stubs/s2_story_test.gd"
## (S2) Le jour 8 de l'acte 1, « Le duel, la fugue et la colline », de bout en bout dans la vraie
## partie, avec de vrais appuis : la partie reprise à l'aube du jour 8 à l'infirmerie (la nuit des
## archives jouée) ; le réveil honteux (8.1, « Dehors ! ») ; les endormis des archives (8.2) ; la
## partie enregistrée et reprise par « Continuer » dans le temps libre du matin ; le duel (8.3 :
## le jeu d'E8b joué au clavier, « Encore une fois ! » et la reprise) ; le cristal (8.4, séquence
## déjà vue : Échap) ; la réunion et l'infirmerie envahie (8.5) ; la fugue (8.6 : la colline,
## l'invite « S'envoler ») ; le Barocupot (8.7 : la salle du conseil, « Remonter sur le pont ») ;
## la colline aux étoiles (8.8 : Ithea au porche, les quarante et un talismans, les quatre qu'on
## frôle, la promesse) ; le réveil à l'aube du jour 9 dans son lit, deux lignes de plus au
## calendrier.


func test_day_8_end_to_end_until_day_9() -> void:
	StoryDirector.mark_seen(&"j8_4_cristal")
	assert_true(await continue_at_day(8, &"entrepot_rdc", Vector3(26.6, 0.0, 12.6)), "partie")
	assert_eq(GameState.day, 8)
	# 8.1 : le réveil honteux.
	trace("1")
	assert_true(await play_until_done(&"j8_1_reveil", 60.0, {"Dehors !": 1}), "le réveil")
	assert_true(await wait_control())
	assert_eq(LifeSlots.current(), &"matin")
	assert_eq(StoryDirector.hint(), "Où Willem a-t-il passé la nuit ?")
	assert_null(LifeDirector.actor(&"chtholly_double"), "la doublure couchée est partie")
	# 8.2 : les endormis des archives (V1 : Willem y dort le matin du jour 8).
	trace("2")
	assert_not_null(LifeDirector.actor(&"willem"), "Willem au rez-de-chaussée")
	assert_true(await walk_to_point(&"archives_canape", 2.2, 30.0), "les archives")
	assert_true(await play_until_done(&"j8_2_archives", 60.0), "les endormis")
	assert_true(await wait_control())
	assert_eq(StoryDirector.hint(), "Willem t'attend dans la cour.")
	assert_false(StoryDirector.can_rest(), "pas au-delà du duel du matin")
	# La partie enregistrée et reprise au milieu du jour 8.
	trace("3")
	assert_true(await save_and_continue(), "partie reprise")
	assert_eq(GameState.day, 8, "même jour")
	assert_eq(LifeSlots.current(), &"matin", "même créneau")
	assert_true(GameState.is_scene_done(&"j8_2_archives"), "scènes jouées gardées")
	assert_false(GameState.is_scene_done(&"j8_3_duel"))
	await frames(10)
	assert_false(StoryDirector.is_playing(), "aucune scène rejouée")
	assert_eq(StoryDirector.hint(), "Willem t'attend dans la cour.", "même indice")
	# 8.3 : le duel dans la cour.
	trace("4")
	assert_true(await take_exit_near(&"entrepot", &"vers_entrepot", 40.0), "la cour")
	assert_true(await walk_to_point(&"cour_willem", 3.5, 30.0))
	assert_true(
		await read_until(func() -> bool: return MiniGames.duel() != null, 40.0), "le duel commence"
	)
	assert_false(player.is_story_held(), "la main pour le duel")
	var first := await play_duel()
	trace("5")
	assert_eq(first.get("ended_by"), &"thrown", "projetée")
	assert_false(first.get("success", true), "ingagnable")
	assert_eq(player.health.current, player.health.max_hp, "aucun point de vie perdu")
	assert_true(
		await read_until(
			func() -> bool: return MiniGames.duel() != null, 30.0, {"Encore une fois !": 0}
		),
		"la reprise"
	)
	var second := await play_duel()
	assert_true(second.get("reprise", false), "« Encore une fois ! »")
	assert_eq(second.get("ended_by"), &"thrown")
	assert_true(GameState.has_flag(&"j8_duel_joue"))
	assert_true(await play_until_done(&"j8_3_duel", 60.0), "Willem s'effondre")
	# 8.4 : le cristal (séquence déjà vue).
	trace("6")
	assert_true(
		await read_until(
			func() -> bool: return StoryDirector.current_scene() == &"j8_4_cristal", 30.0
		)
	)
	assert_true(StoryDirector.is_skippable())
	await frames(5)
	await tap_key(KEY_ESCAPE)
	assert_true(await until(func() -> bool: return GameState.is_scene_done(&"j8_4_cristal"), 10.0))
	# 8.5 : la réunion, l'infirmerie envahie.
	trace("7")
	assert_true(
		await read_until(
			func() -> bool: return StoryDirector.runner().current_step() == "wait_for", 60.0
		),
		"la main dans le couloir"
	)
	assert_eq(StoryDirector.current_scene(), &"j8_5_refectoire")
	assert_eq(StoryDirector.hint(), "Du vacarme à l'infirmerie.")
	assert_true(await walk_to_point(&"epie_infirmerie", 1.2, 30.0))
	assert_true(await play_until_done(&"j8_5_refectoire", 60.0))
	assert_true(await wait_control())
	assert_eq(StoryDirector.hint(), "Le bord de l'île, au-delà de la colline.")
	# 8.6 : la fugue, de la porte au bord de la colline.
	trace("8")
	assert_true(await take_exit_near(&"entrepot", &"vers_entrepot", 40.0))
	assert_true(await take_exit(&"colline", 90.0), "la colline")
	assert_true(await climb_to_summit(), "le sommet")
	assert_true(await walk_to_point(&"vue_nord", 1.2, 40.0), "le bord")
	assert_true(await use_prompt(StoryPrompt.ROLE_SCENE), "« S'envoler »")
	trace("9")
	assert_true(
		await read_until(func() -> bool: return WorldManager.current_map() == &"barocupot", 60.0),
		"le Barocupot"
	)
	# 8.7 : la salle du conseil, le thé, l'échelle.
	assert_true(
		await read_until(
			func() -> bool: return StoryDirector.runner().current_step() == "wait_for", 30.0
		)
	)
	assert_eq(StoryDirector.hint(), "La salle du conseil, au bout de la coursive.")
	assert_true(await walk_to_point(&"conseil_chtholly", 1.0, 30.0))
	assert_true(
		await read_until(
			func() -> bool: return StoryDirector.runner().current_step() == "wait_for",
			60.0,
			{"Merci pour le thé.": 1}
		)
	)
	assert_eq(StoryDirector.hint(), "Remonte sur le pont, par l'échelle.")
	trace("10")
	assert_true(await take_exit(&"entrepot", 30.0), "« Remonter sur le pont »")
	assert_true(await play_until_done(&"j8_7_barocupot", 30.0))
	# 8.8 : Ithea au porche, la colline, les talismans, la promesse.
	trace("11")
	assert_true(
		await read_until(
			func() -> bool: return StoryDirector.runner().current_step() == "wait_for", 40.0
		),
		"Ithea a parlé"
	)
	assert_eq(StoryDirector.current_scene(), &"j8_8_colline")
	assert_eq(LifeSlots.current(), &"nuit", "la nuit claire")
	assert_eq(StoryDirector.hint(), "Willem t'attend sur la colline, avec Seniorious.")
	assert_true(await take_exit(&"colline", 90.0), "la colline, de nuit")
	trace("12")
	assert_true(await climb_to_summit(), "le sommet")
	assert_true(await walk_to_point(&"talismans_centre", 5.5, 40.0), "le cercle")
	assert_true(
		await read_until(
			func() -> bool: return StoryDirector.runner().current_step() == "wait_for",
			40.0,
			{"Toucher les talismans.": 0}
		)
	)
	var talismans := StoryDirector.stage().props(&"talismans")
	assert_not_null(talismans, "les talismans posés par la scène")
	if talismans != null:
		assert_eq(talismans.get_child_count(), 42, "quarante et un talismans et leur lueur")
		assert_not_null(talismans.get_node_or_null(^"Glow") as OmniLight3D, "la lueur du cristal")
	assert_eq(StoryDirector.hint(), "Frôle les talismans, un par un.")
	for spot: StringName in [&"talisman_1", &"talisman_2", &"talisman_3", &"talisman_4"]:
		assert_true(await walk_to_point(spot, 0.7, 15.0), "frôler %s" % spot)
	trace("13")
	assert_true(
		await play_until_done(&"j8_8_colline", 120.0, {"Tu sais faire un gâteau au beurre ?": 1}),
		"la promesse"
	)
	# L'aube du jour 9, dans son lit.
	assert_eq(GameState.day, 9, "le jour 9 (scènes d'un autre lot)")
	assert_eq(LifeSlots.current(), &"aube")
	assert_eq(WorldManager.current_map(), &"entrepot_etage", "réveil dans sa chambre")
	assert_true(GameState.has_calendar_line(8), "la ligne du jour 8")
	assert_string_contains(StoryDirector.calendar_line(8), "gâteau")
	assert_eq(GameState.calendar().size(), 8, "huit lignes au calendrier")
	assert_null(StoryDirector.stage().props(&"talismans"), "les talismans retirés")
	assert_false(StoryDirector.stage().is_player_hidden(), "la protagoniste rendue")


## Monte au sommet de la colline par la dernière rampe (x 14 → 19, z 24 → 19, CARTE.md) : le
## chemin de la navigation coupe par le flanc est, où l'on bute sur la falaise d'un mètre
## (docs/CONTRACT_REQUESTS.md, S2).
func climb_to_summit() -> bool:
	if not await walk_to(Vector3(16.5, 0.0, 25.2), 0.8, 40.0):
		return false
	return await walk_to(Vector3(16.5, 0.0, 18.0), 0.8, 15.0)
