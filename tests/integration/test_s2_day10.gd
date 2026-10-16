extends "res://tests/stubs/s2_story_test.gd"
## (S2) Le jour 10 de l'acte 1 de bout en bout dans la vraie partie, avec de vrais appuis : tout
## rater à la clairière (10.1, la variante du jour 10 de l'entraînement au bâton), la course
## jusqu'au refuge de la forêt profonde et Ithea (10.2), le linge sur le toit avant l'averse (10.3),
## la tour de fées (10.5), la séquence du toit la nuit (10.4), « Dormir », le jour 11. Et la
## sauvegarde reprise au milieu du jour (l'après-midi, entre deux scènes).


func test_day_10_end_to_end_until_day_11() -> void:
	assert_true(await begin_day(10, [&"j9_baton_reussi"]), "partie reprise au réveil du jour 10")
	assert_eq(StoryDirector.hint(), "Willem t'attend dans la clairière.")
	# 10.1 : tout rater (le matin vient avec la scène).
	trace("10.1")
	assert_true(await take_exit(&"entrepot_rdc", 60.0))
	assert_true(await take_exit(&"entrepot", 60.0))
	assert_true(await walk_to_point(&"clairiere_centre", 5.5, 60.0), "la clairière")
	assert_true(
		await read_until(func() -> bool: return MiniGames.staff_training() != null, 40.0),
		"l'entraînement du jour 10"
	)
	assert_eq(LifeSlots.current(), &"matin")
	assert_eq(MiniGames.staff_training().variant, &"jour10")
	var result := await play_staff_training()
	trace("10.1 fin : %s" % result)
	assert_eq(result.get("ended_by"), &"misses", "au troisième raté, la scène continue")
	assert_false(result.get("success", true))
	# Le cri, puis la course vers le sud.
	assert_true(
		await read_until(
			func() -> bool:
				return (
					not player.is_story_held()
					and StoryDirector.runner().current_step() == "wait_for"
				),
			40.0
		)
	)
	assert_eq(StoryDirector.hint(), "Cours. N'importe où. Vers le sud, vers le bois.")
	trace("10.2")
	assert_true(await take_exit(&"foret_profonde", 90.0), "la forêt profonde")
	assert_true(await play_until_done(&"j10_1_rater", 10.0))
	assert_true(
		await until(func() -> bool: return StoryDirector.current_scene() == &"j10_2_foret", 5.0)
	)
	assert_eq(StoryDirector.hint(), "Plus loin. Le grand chêne, au fond du bois.")
	# Le sentier de la montagne, la fourche du refuge, puis à l'ouest jusqu'au grand chêne.
	for point: StringName in [&"course_entree", &"fourche_refuge", &"refuge_retour"]:
		assert_true(await walk_to_point(point, 1.5, 60.0), "par %s" % point)
	assert_true(await walk_to_point(&"refuge_creux", 2.0, 30.0), "le refuge")
	assert_true(await play_until_done(&"j10_2_foret", 90.0), "10.2 jouée")
	assert_eq(WorldManager.current_map(), &"entrepot", "Ithea l'a ramenée")
	assert_eq(LifeSlots.current(), &"midi")
	assert_true(await wait_control())
	# L'après-midi : le linge sur le toit (10.3, facultatif).
	trace("10.3")
	assert_true(await walk_to_point(&"porche_banc", 1.0, 80.0))
	assert_true(await rest_here_until(&"apres_midi"))
	assert_eq(StoryDirector.hint(), "Le vent sent la pluie. Le linge est sur le toit.")
	assert_true(await take_exit(&"entrepot_rdc", 30.0))
	assert_true(await take_exit(&"entrepot_etage", 60.0))
	assert_true(await take_exit(&"entrepot_toit", 60.0), "le toit")
	assert_true(await walk_to_point(&"toit_sechoir", 3.5, 30.0))
	assert_true(await read_until(func() -> bool: return not player.is_story_held(), 30.0))
	assert_eq(StoryDirector.current_scene(), &"j10_3_linge")
	for npc_id: StringName in [&"fairy_04", &"fairy_05", &"nygglatho"]:
		assert_true(await walk_to_actor(npc_id, 1.3), "un drap de plus (%s)" % npc_id)
		await frames(10)
	assert_true(
		await read_until(
			func() -> bool:
				return (
					not player.is_story_held()
					and StoryDirector.runner().current_step() == "wait_for"
				),
			30.0
		)
	)
	assert_eq(GameState.weather, &"averse", "l'averse")
	assert_true(await take_exit(&"entrepot_etage", 40.0), "par la trappe")
	assert_true(await play_until_done(&"j10_3_linge", 10.0))
	assert_true(GameState.has_flag(&"j10_linge_rentre"))
	# Le soir : la tour de fées, puis la séquence du toit.
	trace("10.5")
	# Le temps passe au lit (« Laisser passer le temps » dans la chambre), puis en bas.
	assert_true(await rest_here_until(&"soir"), "le soir")
	assert_eq(StoryDirector.hint(), "On joue à la salle de jeux.")
	assert_true(await take_exit(&"entrepot_rdc", 60.0))
	await walk_to_point(&"jeux_tapis", 2.0, 60.0)
	assert_true(
		await until(func() -> bool: return StoryDirector.current_scene() == &"j10_5_tour", 5.0),
		"la salle de jeux"
	)
	assert_true(await read_until(_pile_is_up, 60.0), "la pile : Giniette tout en haut")
	assert_true(await play_until_done(&"j10_5_tour", 90.0), "10.5 jouée")
	assert_eq(GameState.weather, &"clair", "la nuit se dégage")
	trace("10.4")
	assert_true(
		await until(func() -> bool: return StoryDirector.current_scene() == &"j10_4_toit", 10.0)
	)
	assert_false(StoryDirector.is_skippable(), "pas vue : elle ne se passe pas")
	assert_true(await play_until_done(&"j10_4_toit", 90.0), "10.4 jouée")
	assert_eq(WorldManager.current_map(), &"entrepot_etage")
	assert_true(await wait_control())
	assert_true(StoryDirector.can_sleep())
	trace("dormir")
	assert_true(await sleep_by_prompt(), "jour 11")
	assert_string_contains(StoryDirector.calendar_line(10), "Je ne l'écrirai pas")


func test_day_10_resumes_in_the_afternoon() -> void:
	var done: Array[StringName] = [&"j10_1_rater", &"j10_2_foret"]
	assert_true(await begin_day(10, [], done, &"midi", &"entrepot", Vector3(44.2, 0.0, 30.0)))
	assert_true(await wait_control())
	assert_true(await rest_here_until(&"apres_midi"), "le temps passe sur le banc")
	var hint := StoryDirector.hint()
	assert_eq(hint, "Le vent sent la pluie. Le linge est sur le toit.")
	await walk_to(player.global_position + Vector3(1.5, 0.0, 2.0), 0.5, 5.0)
	var left_at := player.global_position
	SaveManager.save()
	assert_true(await continue_game(), "partie reprise")
	assert_eq(WorldManager.current_map(), &"entrepot")
	assert_lt(flat_distance(player.global_position, left_at), 0.3, "position restaurée")
	assert_eq(GameState.day, 10)
	assert_eq(LifeSlots.current(), &"apres_midi", "même créneau")
	assert_true(GameState.is_scene_done(&"j10_2_foret"))
	await frames(10)
	assert_eq(StoryDirector.hint(), hint, "même indice")
	assert_false(StoryDirector.is_playing(), "aucune scène rejouée")
	assert_true(await take_exit(&"entrepot_rdc", 30.0))
	assert_true(await take_exit(&"entrepot_etage", 60.0))
	assert_true(await take_exit(&"entrepot_toit", 60.0))
	assert_true(await walk_to_point(&"toit_sechoir", 3.5, 30.0))
	assert_true(
		await until(func() -> bool: return StoryDirector.current_scene() == &"j10_3_linge", 5.0),
		"le récit continue"
	)


## La pile de la tour de fées (« lift ») : Giniette, la dernière, 2 m au moins au-dessus de Willem.
func _pile_is_up() -> bool:
	var top := LifeDirector.actor(&"giniette")
	var base := LifeDirector.actor(&"willem")
	return top != null and base != null and top.position().y - base.position().y > 2.0
