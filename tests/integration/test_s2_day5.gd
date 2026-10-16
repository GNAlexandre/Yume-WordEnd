extends "res://tests/stubs/s2_story_test.gd"
## (S2) Le jour 5 de l'acte 1 (ACTE1.md 5.1 à 5.3) dans la vraie partie, avec de vrais appuis : on
## se réveille (état de début de jour posé comme test_e6_days.gd, puis « Continuer » à la souris),
## on laisse passer le temps par l'invite du lit, on va au champ (la séquence de Willem, la partie
## de ballon de la vie qui commence), à la banquette de la salle de lecture (la scène, le choix), au
## bord du champ (5.3), dans la partie, puis « Dormir » : le jour 6 commence. Sauvegarde et reprise
## au milieu du jour, séquence déjà vue passée d'une touche, contenu des textes.

const SEQUENCE_SEEN := &"j5_1_jeu_willem"


func after_each() -> void:
	MiniGames.stop_ball_match()
	super()


## L'état au début de la scène 5.2 : l'après-midi du jour 5, devant la porte de la salle de lecture.
func _resume_afternoon(flags: Array[StringName] = []) -> bool:
	var done: Array[StringName] = DAYS_1_TO_4.duplicate()
	done.append(&"j5_1_jeu_willem")
	return await resume_day(5, &"apres_midi", done, &"entrepot_rdc", Vector3(29.5, 0.0, 7.0), flags)


func _ball_running() -> bool:
	var ball_match := MiniGames.ball_match()
	return ball_match != null and ball_match.running


func test_day_5_end_to_end_until_day_6() -> void:
	var seen: Array[StringName] = []
	assert_true(await resume_day(5, &"aube", DAYS_1_TO_4), "partie reprise au réveil du jour 5")
	assert_eq(GameState.day, 5)
	assert_eq(LifeSlots.current(), &"aube")
	assert_eq(WorldManager.current_map(), &"entrepot_etage", "dans sa chambre")
	assert_true(GameState.story_running())
	assert_true(await wait_control())
	# Le matin : rien ne presse (la première scène est à midi) ; le temps passe par l'invite du lit.
	assert_true(StoryDirector.can_rest())
	assert_true(await rest_until(&"midi"), "laisser passer le temps jusqu'à midi")
	assert_false(StoryDirector.can_rest(), "pas au-delà de midi : la scène du champ attend")
	assert_eq(StoryDirector.hint(), "Willem rassemble les petites au champ.")
	assert_false(GameState.is_scene_done(&"j5_1_jeu_willem"))
	# Le champ : la séquence part à 15 m du centre.
	assert_true(await take_exit_again(&"entrepot_rdc"), "au rez-de-chaussée")
	assert_true(await wait_control())
	assert_true(await take_exit_again(&"entrepot"), "dehors")
	assert_true(await wait_control())
	assert_true(await walk_to_point(&"champ_centre", 14.0, 120.0), "vers le champ")
	assert_true(
		await until(
			func() -> bool: return StoryDirector.current_scene() == &"j5_1_jeu_willem", 10.0
		),
		"la séquence de Willem part"
	)
	assert_true(player.is_story_held(), "le joueur est tenu pendant la séquence")
	assert_true(
		await read_until(func() -> bool: return dialogue_box.is_open(), 30.0), "Willem parle"
	)
	assert_eq(dialogue_box.shown_presentation(), &"bandeau", "bandeau : le joueur est tenu")
	assert_true(await play_until_done(&"j5_1_jeu_willem", 90.0))
	assert_eq(LifeSlots.current(), &"apres_midi", "la séquence finit à l'après-midi")
	assert_true(await wait_control())
	assert_eq(StoryDirector.hint(), "La banquette de la salle de lecture est libre.")
	# La partie de ballon de la vie commence (lignes d'emploi du temps des jours 5 et 6).
	assert_true(await until(_ball_running, 60.0), "le match démarre au champ")
	var ball_match := MiniGames.ball_match()
	assert_true(
		await until(
			func() -> bool: return ball_match != null and ball_match.members.size() >= 14, 60.0
		),
		"une quinzaine de joueuses et Willem à l'arbitrage"
	)
	assert_eq(LifeDirector.actor(&"willem").role, &"arbitre")
	# 5.2 : la banquette.
	assert_true(await take_exit_again(&"entrepot_rdc"), "à la salle de lecture")
	assert_true(await wait_control())
	assert_has(scene_prompt_texts(), "S'asseoir à la fenêtre")
	assert_true(await use_prompt(StoryPrompt.ROLE_SCENE), "l'invite de la banquette")
	assert_true(
		await until(func() -> bool: return StoryDirector.current_scene() == &"j5_2_fenetre", 10.0)
	)
	assert_true(
		await play_until_done(&"j5_2_fenetre", 150.0, {"J'arrive.": 0}), "la scène va au bout"
	)
	assert_true(GameState.has_flag(&"j5_arrive"), "« J'arrive. »")
	# Au bord du champ : 5.3 (un mot de Willem), puis la partie.
	assert_eq(WorldManager.current_map(), &"entrepot", "menée au champ")
	assert_true(
		await read_until(
			func() -> bool: return GameState.is_scene_done(&"j5_3_premier_match"), 60.0
		),
		"5.3"
	)
	assert_true(await wait_control())
	assert_lt(
		flat_distance(
			player.global_position, StoryDirector.stage().resolve(&"champ_entree").origin
		),
		4.0
	)
	assert_true(await until(_ball_running, 40.0), "la partie est ouverte")
	ball_match = MiniGames.ball_match()
	assert_true(await walk_to_point(&"champ_centre", 6.0, 60.0), "elle entre dans le champ")
	assert_true(ball_match.player_in, "dans la partie")
	assert_ne(ball_match.player_team, &"")
	await tap_key(KEY_J)
	await frames(10)
	assert_eq(player.health.current, player.health.max_hp, "aucun mal fait ni subi")
	var way_out := StoryDirector.stage().resolve(&"champ_entree").origin + Vector3(-6.0, 0.0, 0.0)
	assert_true(await walk_to(way_out, 1.6, 60.0), "elle sort du champ par le chemin")
	assert_true(
		await until(func() -> bool: return ball_match == null or not ball_match.player_in, 10.0)
	)
	# Le soir : se coucher. Le jour 6 commence ; la ligne du calendrier est celle du jour.
	assert_true(await go_upstairs())
	assert_true(await wait_control())
	assert_true(await rest_until(&"soir"), "le soir")
	assert_eq(StoryDirector.hint(), "La journée est finie. Ton lit t'attend.")
	assert_true(await sleep_by_prompt(), "Dormir")
	assert_eq(GameState.day, 6)
	assert_eq(LifeSlots.current(), &"aube")
	assert_true(GameState.has_calendar_line(5))
	assert_eq(
		StoryDirector.calendar_line(5), "Plus beaucoup de jours. Ithea m'a encore serrée trop fort."
	)
	assert_eq(GameState.quests(), {}, "aucune quête à collecter")
	seen.append(SEQUENCE_SEEN)
	assert_true(
		StoryDirector.has_seen(SEQUENCE_SEEN), "la séquence est vue, elle se passera d'une touche"
	)


func test_another_time_leaves_the_player_at_the_window_and_the_match_stays_open() -> void:
	assert_true(await _resume_afternoon(), "partie reprise l'après-midi du jour 5")
	assert_true(await wait_control())
	assert_true(await walk_to_point(&"lecture_banquette", 1.2, 40.0))
	assert_true(await use_prompt(StoryPrompt.ROLE_SCENE), "l'invite de la banquette")
	assert_true(
		await play_until_done(&"j5_2_fenetre", 150.0, {"Une autre fois.": 1}), "la scène va au bout"
	)
	assert_false(GameState.has_flag(&"j5_arrive"))
	assert_eq(WorldManager.current_map(), &"entrepot_rdc", "elle reste à la fenêtre")
	assert_true(await wait_control())
	assert_false(GameState.is_scene_done(&"j5_3_premier_match"))
	# Plus tard : entrer dans le champ pendant la partie suffit (5.3 puis le match).
	assert_true(await take_exit_again(&"entrepot"))
	assert_true(await wait_control())
	assert_true(await walk_to_point(&"champ_entree", 1.0, 120.0), "au bout du chemin du champ")
	assert_true(
		await read_until(
			func() -> bool: return GameState.is_scene_done(&"j5_3_premier_match"), 60.0
		),
		"5.3 part en entrant dans le champ"
	)
	assert_true(await wait_control())
	assert_true(await until(_ball_running, 60.0))
	assert_true(await walk_to_point(&"champ_centre", 6.0, 60.0))
	assert_true(MiniGames.ball_match().player_in, "elle joue")


func test_the_seen_sequence_is_passed_with_escape_and_keeps_its_effects() -> void:
	StoryDirector.mark_seen(&"j5_1_jeu_willem")
	var done: Array[StringName] = DAYS_1_TO_4.duplicate()
	assert_true(
		await resume_day(5, &"midi", done, &"entrepot", Vector3(61.0, 0.0, 18.0)),
		"partie reprise à midi, devant le champ"
	)
	assert_true(
		await until(
			func() -> bool: return StoryDirector.current_scene() == &"j5_1_jeu_willem", 10.0
		),
		"à moins de 15 m du champ, la séquence part"
	)
	assert_true(StoryDirector.is_skippable(), "séquence déjà vue")
	await tap_key(KEY_ESCAPE)
	assert_false(pause_menu.is_open(), "Échap passe la séquence, sans ouvrir la pause")
	assert_true(
		await until(func() -> bool: return GameState.is_scene_done(&"j5_1_jeu_willem"), 10.0)
	)
	assert_eq(LifeSlots.current(), &"apres_midi", "le créneau passé par la séquence reste")
	assert_true(await wait_control())
	assert_true(await until(_ball_running, 60.0), "la partie commence quand même")


func test_save_and_resume_in_the_middle_of_day_5() -> void:
	assert_true(await _resume_afternoon(), "partie reprise l'après-midi du jour 5")
	assert_true(await wait_control())
	assert_eq(StoryDirector.hint(), "La banquette de la salle de lecture est libre.")
	var left_at := player.global_position
	SaveManager.save()
	assert_true(await continue_game(), "Continuer")
	assert_eq(GameState.day, 5, "même jour")
	assert_eq(LifeSlots.current(), &"apres_midi", "même créneau")
	assert_true(GameState.is_scene_done(&"j5_1_jeu_willem"), "scènes jouées gardées")
	assert_false(GameState.is_scene_done(&"j5_2_fenetre"))
	assert_lt(flat_distance(player.global_position, left_at), 0.5, "position restaurée")
	await frames(10)
	assert_eq(StoryDirector.hint(), "La banquette de la salle de lecture est libre.", "même indice")
	assert_false(StoryDirector.is_playing(), "aucune scène rejouée")
	# Fermée au milieu de la scène de la fenêtre : elle reprend depuis son début.
	assert_true(await walk_to_point(&"lecture_banquette", 1.2, 40.0))
	assert_true(await use_prompt(StoryPrompt.ROLE_SCENE))
	assert_true(await until(func() -> bool: return dialogue_box.is_open(), 20.0), "la fenêtre")
	assert_eq(GameState.story_scene, &"j5_2_fenetre")
	SaveManager.save()
	assert_true(await continue_game(), "partie reprise au milieu de la scène")
	assert_true(
		await until(func() -> bool: return StoryDirector.current_scene() == &"j5_2_fenetre", 10.0),
		"la scène reprend"
	)
	assert_true(await play_until_done(&"j5_2_fenetre", 150.0))
	assert_true(
		await read_until(
			func() -> bool: return GameState.is_scene_done(&"j5_3_premier_match"), 60.0
		)
	)
	assert_true(await wait_control())
	assert_eq(GameState.story_scene, &"")


func test_the_match_forms_by_itself_when_the_afternoon_comes() -> void:
	# Correctif de LifeActor (S2) : toutes les joueuses visent le point unique de champ_centre ; la
	# première l'occupe, les autres arrivent à 1,4 m et le jeu les range (sans cela, elles tournaient
	# autour de lui sans jamais arriver et le match n'avait qu'un membre).
	var done: Array[StringName] = DAYS_1_TO_4.duplicate()
	done.append(&"j5_1_jeu_willem")
	assert_true(
		await resume_day(5, &"midi", done, &"entrepot", Vector3(42.0, 0.0, 33.0)),
		"partie reprise à midi, devant le porche"
	)
	assert_true(await wait_control())
	await StoryDirector.pass_time()
	assert_eq(LifeSlots.current(), &"apres_midi")
	assert_true(await until(_ball_running, 90.0), "le match démarre")
	var ball_match := MiniGames.ball_match()
	assert_true(
		await until(
			func() -> bool:
				return (
					ball_match != null
					and ball_match.members.size() >= 16
					and ball_match.roles.has(&"willem")
				),
			90.0
		),
		"les quinze petites et l'arbitre"
	)
	assert_eq(ball_match.roles.get(&"willem"), &"arbitre")


func test_day_5_content() -> void:
	var problems := StoryData.all_problems(&"ile_68")
	assert_eq(problems, PackedStringArray(), "\n".join(problems))
	var ids := StoryData.scene_ids(&"ile_68")
	for scene_id: StringName in [&"j5_1_jeu_willem", &"j5_2_fenetre", &"j5_3_premier_match"]:
		assert_has(ids, scene_id)
		var data := StoryData.scene(&"ile_68", scene_id)
		assert_false(data.is_empty(), "%s se lit" % scene_id)
		assert_eq(int(data.get("day", 0)), 5)
		var hint := StoryData.text(&"ile_68", str(data["hint"]), scene_id)
		assert_false(hint.is_empty(), "%s a un indice" % scene_id)
		assert_lte(hint.length(), 60, "indice de 60 signes au plus : %s" % hint)
		var raw := FileAccess.get_file_as_string("res://data/dialogues/ile_68/%s.json" % scene_id)
		assert_false(raw.contains("Chtholly"), "jamais Chtholly en dur : %s" % scene_id)
	assert_true(StoryData.scene(&"ile_68", &"j5_1_jeu_willem").get("sequence", false), "séquence")
	assert_eq(StoryData.scene(&"ile_68", &"j5_1_jeu_willem").get("slot"), "midi")
	var act_day := StoryData.day_data(&"ile_68", 5)
	assert_eq(act_day.get("sleep_after"), ["j5_1_jeu_willem", "j5_2_fenetre"])
	assert_false(StoryData.text(&"ile_68", "days/5/calendar").is_empty(), "ligne du calendrier")
	# Les lignes de vie du ballon : Willem arbitre, deux équipes, au moins six joueuses.
	var teams := {&"rouge": 0, &"blanc": 0}
	var referee := &""
	for npc_id: StringName in [
		&"willem",
		&"collon",
		&"pannibal",
		&"tiat",
		&"lakhesh",
		&"almita",
		&"fairy_01",
		&"fairy_02",
		&"fairy_03",
		&"fairy_04",
		&"fairy_05",
		&"fairy_06",
		&"fairy_07",
		&"fairy_08",
		&"fairy_09",
		&"fairy_10",
	]:
		var line := LifeData.line_for(npc_id, &"apres_midi", 5)
		assert_eq(line.get("activity"), &"ballon", "%s joue au ballon le jour 5" % npc_id)
		assert_eq(line.get("place"), &"champ_centre")
		var role := StringName(str(line.get("role", "")))
		if role == &"arbitre":
			referee = npc_id
		elif teams.has(role):
			teams[role] += 1
	assert_eq(referee, &"willem")
	assert_gte(teams[&"rouge"] + teams[&"blanc"], 12)
