extends "res://tests/stubs/s2_story_test.gd"
## (S2) Le jour 6 de l'acte 1 (ACTE1.md 6.1 à 6.4) dans la vraie partie, avec de vrais appuis : on
## se réveille (état de début de jour posé comme test_e6_days.gd, puis « Continuer » à la souris),
## on laisse passer le temps par l'invite du lit puis de la banquette, le couloir (« Soif de sang !
## », le choix de la clé de bras), la salle de jeux (le livre d'images, le carton du souvenir), le
## dîner (l'ordre de mission, Nygglatho au cristal, la nuit qui tombe), la chambre de la grande sœur
## (le souvenir) puis « Dormir » : le jour 7 commence. Les autres choix, la sauvegarde et la
## reprise, les textes.

const DAY_6_BEFORE_DINNER: Array[StringName] = [
	&"j6_1_soif_de_sang",
	&"j6_2_livre_images",
]


func _done_before_day_6() -> Array[StringName]:
	var done: Array[StringName] = DAYS_1_TO_4.duplicate()
	done.append_array(DAY_5_DONE)
	return done


func _card_text() -> String:
	var overlay := StoryDirector.stage().overlay()
	return str(overlay.call(&"card_text")) if overlay != null else ""


func test_day_6_end_to_end_until_day_7() -> void:
	assert_true(
		await resume_day(6, &"aube", _done_before_day_6()), "partie reprise au réveil du jour 6"
	)
	assert_eq(GameState.day, 6)
	assert_true(await wait_control())
	# Le matin : le couloir, sans indice dans l'œuvre : une ligne (original) dit où.
	assert_true(await rest_until(&"matin"), "laisser passer le temps jusqu'au matin")
	assert_eq(StoryDirector.hint(), "Il y a du remue-ménage dans le couloir, en bas.")
	assert_false(StoryDirector.can_rest(), "pas au-delà du matin : la scène du couloir attend")
	assert_true(await take_exit_again(&"entrepot_rdc"), "au rez-de-chaussée")
	assert_true(await wait_control())
	assert_true(await walk_to_point(&"couloir_centre", 4.2, 60.0), "vers le couloir")
	assert_true(
		await until(
			func() -> bool: return StoryDirector.current_scene() == &"j6_1_soif_de_sang", 10.0
		),
		"6.1 part en entrant dans le couloir"
	)
	assert_true(player.is_story_held(), "le joueur est tenu : bandeau")
	assert_true(
		await play_until_done(
			&"j6_1_soif_de_sang", 150.0, {"Montre-moi cette clé de bras, Pannibal.": 1}
		)
	)
	assert_true(GameState.has_flag(&"j6_cle"), "le choix de la clé de bras")
	assert_true(await wait_control())
	# L'après-midi : le livre d'images, à la salle de jeux.
	assert_true(await rest_until(&"apres_midi"), "laisser passer le temps jusqu'à l'après-midi")
	assert_eq(StoryDirector.hint(), "Les petites ont un livre à faire lire.")
	assert_true(await take_exit_again(&"entrepot_rdc"), "en bas")
	assert_true(await wait_control())
	assert_true(await walk_to_point(&"jeux_tapis", 3.5, 60.0), "vers la salle de jeux")
	assert_true(
		await until(
			func() -> bool: return StoryDirector.current_scene() == &"j6_2_livre_images", 10.0
		)
	)
	var card := {"seen": ""}
	assert_true(
		await read_until(
			func() -> bool:
				var shown := _card_text()
				if not shown.is_empty():
					card["seen"] = shown
				return GameState.is_scene_done(&"j6_2_livre_images"),
			200.0,
			{"S'asseoir sur le tapis.": 0}
		),
		"6.2 va au bout"
	)
	assert_string_contains(str(card["seen"]), "Pas un visage", "le carton du souvenir (3 s)")
	assert_true(GameState.has_flag(&"j6_tapis"))
	assert_true(await wait_control())
	# Le soir : l'ordre de mission au dîner (le cristal, puis le réfectoire), la nuit tombe.
	assert_true(await rest_until(&"soir"), "laisser passer le temps jusqu'au soir")
	assert_eq(StoryDirector.hint(), "Le dîner est servi.")
	assert_true(await take_exit_again(&"entrepot_rdc"), "en bas")
	assert_true(await wait_control())
	assert_true(await walk_to_point_again(&"refectoire_allee", 1.8), "au réfectoire")
	assert_true(await play_until_done(&"j6_3_ordre_mission", 250.0), "6.3 va au bout")
	assert_true(await wait_control())
	assert_eq(LifeSlots.current(), &"nuit", "la nuit est tombée")
	assert_false(StoryDirector.can_sleep(), "pas avant le souvenir")
	assert_eq(StoryDirector.hint(), "Tu n'arrives pas à dormir.")
	# La nuit : le bureau de la grande sœur.
	assert_true(await go_upstairs(), "à l'étage")
	assert_true(await wait_control())
	assert_true(await walk_to_point(&"grande_soeur_bureau", 1.6, 60.0), "dans la chambre voisine")
	assert_has(scene_prompt_texts(), "Examiner le bureau")
	assert_true(await use_prompt(StoryPrompt.ROLE_SCENE), "l'invite du bureau")
	assert_true(await play_until_done(&"j6_4_souvenir", 150.0), "6.4 va au bout")
	assert_true(await wait_control())
	assert_eq(StoryDirector.hint(), "Demain, on part à l'aube. Ton lit t'attend.")
	assert_true(await sleep_by_prompt(), "Dormir")
	assert_eq(GameState.day, 7, "le jour 7 commence")
	assert_eq(LifeSlots.current(), &"aube")
	assert_true(GameState.has_calendar_line(6))
	assert_eq(
		StoryDirector.calendar_line(6),
		"Demain, mission. Il a lu aux petites un livre où les méchants lui ressemblent."
	)


func test_the_other_choices_lead_to_the_same_day() -> void:
	assert_true(
		await resume_day(
			6, &"matin", _done_before_day_6(), &"entrepot_rdc", Vector3(17.5, 0.0, 6.8)
		),
		"partie reprise le matin du jour 6"
	)
	assert_true(await wait_control())
	assert_true(await walk_to_point(&"couloir_centre", 4.2, 60.0))
	assert_true(
		await play_until_done(&"j6_1_soif_de_sang", 150.0, {"Lâchez-le.": 0}), "« Lâchez-le. »"
	)
	assert_false(GameState.has_flag(&"j6_cle"))
	assert_true(await wait_control())
	assert_true(await rest_until(&"apres_midi"))
	assert_true(await take_exit_again(&"entrepot_rdc"))
	assert_true(await wait_control())
	assert_true(await walk_to_point(&"jeux_tapis", 3.5, 60.0))
	assert_true(
		await play_until_done(&"j6_2_livre_images", 200.0, {"Rester à la porte.": 1}),
		"rester à la porte"
	)
	assert_false(GameState.has_flag(&"j6_tapis"))
	assert_true(await wait_control())
	assert_true(await rest_until(&"soir"))
	assert_eq(StoryDirector.hint(), "Le dîner est servi.", "même suite")


func test_save_and_resume_in_the_middle_of_day_6() -> void:
	var done := _done_before_day_6()
	done.append_array(DAY_6_BEFORE_DINNER)
	assert_true(
		await resume_day(6, &"soir", done, &"entrepot_rdc", Vector3(15.0, 0.0, 8.0)),
		"partie reprise le soir du jour 6"
	)
	assert_true(await wait_control())
	assert_eq(StoryDirector.hint(), "Le dîner est servi.")
	var left_at := player.global_position
	SaveManager.save()
	assert_true(await continue_game(), "Continuer")
	assert_eq(GameState.day, 6)
	assert_eq(LifeSlots.current(), &"soir")
	assert_true(GameState.is_scene_done(&"j6_2_livre_images"), "scènes jouées gardées")
	assert_false(GameState.is_scene_done(&"j6_3_ordre_mission"))
	assert_lt(flat_distance(player.global_position, left_at), 0.5, "position restaurée")
	await frames(10)
	assert_eq(StoryDirector.hint(), "Le dîner est servi.", "même indice")
	assert_false(StoryDirector.is_playing(), "aucune scène rejouée")
	# Fermée au milieu du dîner : la scène reprend depuis son début (le cristal d'abord).
	assert_true(await walk_to_point_again(&"refectoire_allee", 1.8))
	assert_true(await until(func() -> bool: return dialogue_box.is_open(), 40.0), "le cristal")
	assert_eq(GameState.story_scene, &"j6_3_ordre_mission")
	SaveManager.save()
	assert_true(await continue_game(), "partie reprise au milieu de la scène")
	assert_true(
		await until(
			func() -> bool: return StoryDirector.current_scene() == &"j6_3_ordre_mission", 10.0
		),
		"la scène reprend"
	)
	assert_true(await play_until_done(&"j6_3_ordre_mission", 250.0))
	assert_eq(GameState.story_scene, &"")
	assert_eq(LifeSlots.current(), &"nuit")


func test_day_6_content() -> void:
	var problems := StoryData.all_problems(&"ile_68")
	assert_eq(problems, PackedStringArray(), "\n".join(problems))
	var ids := StoryData.scene_ids(&"ile_68")
	for scene_id: StringName in [
		&"j6_1_soif_de_sang", &"j6_2_livre_images", &"j6_3_ordre_mission", &"j6_4_souvenir"
	]:
		assert_has(ids, scene_id)
		var data := StoryData.scene(&"ile_68", scene_id)
		assert_false(data.is_empty(), "%s se lit" % scene_id)
		assert_eq(int(data.get("day", 0)), 6)
		var hint := StoryData.text(&"ile_68", str(data["hint"]), scene_id)
		assert_false(hint.is_empty(), "%s a un indice" % scene_id)
		assert_lte(hint.length(), 60, "indice de 60 signes au plus : %s" % hint)
		var raw := FileAccess.get_file_as_string("res://data/dialogues/ile_68/%s.json" % scene_id)
		assert_false(raw.contains("Chtholly"), "jamais Chtholly en dur : %s" % scene_id)
	assert_eq(StoryData.scene(&"ile_68", &"j6_1_soif_de_sang").get("slot"), "matin")
	assert_eq(StoryData.scene(&"ile_68", &"j6_2_livre_images").get("slot"), "apres_midi")
	assert_eq(StoryData.scene(&"ile_68", &"j6_3_ordre_mission").get("slot"), "soir")
	var act_day := StoryData.day_data(&"ile_68", 6)
	assert_eq(
		act_day.get("sleep_after"),
		["j6_1_soif_de_sang", "j6_2_livre_images", "j6_3_ordre_mission", "j6_4_souvenir"]
	)
	assert_false(StoryData.text(&"ile_68", "days/6/calendar").is_empty(), "ligne du calendrier")
	# Aucun indice de l'acte ne dépasse 60 signes.
	for scene_id: StringName in ids:
		var data := StoryData.scene(&"ile_68", scene_id)
		if data.has("hint"):
			var hint := StoryData.text(&"ile_68", str(data["hint"]), scene_id)
			assert_lte(hint.length(), 60, "%s : %s" % [scene_id, hint])
