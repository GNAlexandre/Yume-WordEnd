extends "res://tests/stubs/e6_story_test.gd"
## (E6) Le jour 1 de bout en bout dans la vraie partie, avec de vrais appuis : « Nouvelle partie »
## (menu, souris), l'acte 1 à l'entrepôt de l'île n° 68, sans quête ni HUD de quête ; la séquence
## du port passée d'une touche (déjà vue), le porche, le sentier, (E8c) l'embuscade de Pannibal
## jouée au clavier et à la manette (pas de côté au stick, parade à la touche K), l'intrus, le
## retour par la levée, l'entrepôt, le dîner, la chambre nue ; « Dormir » ; le calendrier ; le
## jour 2 commence à l'aube.

## Touche de la parade (action « charge », bâton en main).
const GUARD_KEY := KEY_K


func test_day_1_end_to_end_until_day_2() -> void:
	# La séquence du port a déjà été vue (une autre partie) : elle se passe d'Échap.
	StoryDirector.mark_seen(&"j1_1_port")
	trace("1")
	assert_true(await new_game_from_menu(), "partie lancée depuis le menu")
	assert_eq(WorldManager.current_map(), &"entrepot", "l'acte 1 commence à l'entrepôt")
	assert_eq(GameState.day, 1, "jour 1")
	assert_eq(LifeSlots.current(), &"nuit", "la nuit du grand vent")
	assert_true(GameState.story_running())
	assert_eq(GameState.quest_state(&"act1_main"), &"", "plus de quête principale à collecter")
	assert_false((hud.get_node("%Quests") as Control).visible, "pas d'encadré de quête")
	# 1.1 : séquence déjà vue, passée par Échap.
	trace("2")
	assert_true(
		await until(func() -> bool: return StoryDirector.current_scene() == &"j1_1_port", 5.0)
	)
	assert_true(StoryDirector.is_skippable(), "séquence déjà vue")
	await tap_key(KEY_ESCAPE)
	assert_false(pause_menu.is_open(), "Échap passe la séquence, sans ouvrir la pause")
	# 1.2 : le porche.
	trace("3")
	assert_true(await play_until_done(&"j1_2_lumiere", 40.0, {"Encore elle ?": 1}))
	assert_true(GameState.is_scene_done(&"j1_1_port"))
	trace("4")
	assert_true(await wait_control())
	assert_eq(StoryDirector.hint(), "Pannibal est sortie. Cherche-la sur le sentier.")
	# Le sentier : l'embuscade (le jeu d'E8, joué au clavier et au stick) puis l'intrus.
	trace("5")
	assert_true(await take_exit(&"sentier", 60.0), "le sentier")
	trace("6")
	assert_eq(player.weapon(), &"seniorious", "l'arme par défaut avant l'embuscade")
	assert_true(await walk_to_point(&"premiere_embuscade", 1.0, 40.0))
	assert_true(await until(func() -> bool: return MiniGames.ambush() != null, 15.0), "elle bondit")
	var ambush := MiniGames.ambush()
	var pannibal := LifeDirector.actor(&"pannibal")
	assert_false(player.is_story_held(), "le joueur a la main le temps du combat")
	assert_eq(player.weapon(), &"baton", "le bâton")
	assert_eq(pannibal.npc.get_prompt(), "", "pas d'invite « Parler » sur Pannibal")
	assert_eq(InteractSign.kind_of(pannibal.npc), &"", "ni de signe")
	assert_true(ambush.help, "les lignes d'aide du jour 1")
	# (S1b) L'indice « Cherche-la sur le sentier » se tait pendant le jeu.
	assert_eq(StoryDirector.hint(), "", "pas d'indice pendant l'embuscade")
	assert_eq(hud.get_node("StoryHint").call(&"shown_text"), "", "l'indice n'est pas affiché")
	var outcome := await _play_ambush(ambush)
	assert_true(outcome.get("success", false), "cinq réponses de suite : Pannibal tombe")
	assert_eq(outcome.get("ended_by"), &"streak")
	assert_eq(player.health.current, player.health.max_hp, "aucun vrai dégât")
	assert_true(GameState.has_flag(&"j1_embuscade_gagnee"), "la réplique de plus")
	assert_eq(player.weapon(), &"seniorious", "l'arme d'avant revient")
	assert_true(await play_until_done(&"j1_2_embuscade", 30.0))
	trace("7")
	assert_true(await wait_control())
	trace("8")
	assert_true(await walk_to_point(&"chtholly_arrivee", 1.0, 40.0))
	trace("9")
	assert_true(await read_until(func() -> bool: return not player.is_story_held(), 40.0))
	var willem := LifeDirector.actor(&"willem")
	assert_not_null(willem, "Willem au marais")
	trace("10")
	await walk_to(willem.position(), 2.5)
	trace("11")
	assert_true(
		await play_until_done(&"j1_3_intrus", 30.0, {"Pannibal, descends. Tout de suite.": 1})
	)
	# 1.4 : l'escorte jusqu'à la porte.
	trace("12")
	assert_true(
		await until(func() -> bool: return StoryDirector.current_scene() == &"j1_4_chemin", 5.0)
	)
	trace("13")
	assert_true(await wait_control())
	assert_has(StoryDirector.stage().followers(), &"willem", "Willem suit la lumière")
	trace("14")
	# Remonter du marais vers l'ouest par la levée (plus de marche à l'ouest de marais_chute).
	assert_true(await take_exit(&"entrepot", 60.0), "retour à l'entrepôt")
	trace("15")
	assert_true(await read_until(func() -> bool: return not player.is_story_held(), 20.0))
	assert_not_null(LifeDirector.actor(&"willem"), "Willem a suivi d'une carte à l'autre")
	trace("16")
	await walk_to_point(&"porte_seuil", 1.5, 60.0)
	trace("17")
	assert_true(await play_until_done(&"j1_4_chemin", 20.0))
	# 1.5 : le porche, la salle de bains, le couloir, l'étage, l'avalanche n° 1.
	trace("18")
	assert_true(
		await read_until(
			func() -> bool:
				return WorldManager.current_map() == &"entrepot_rdc" and not player.is_story_held(),
			60.0
		)
	)
	trace("19")
	await walk_to_point(&"couloir_centre", 2.0)
	trace("20")
	assert_true(
		await read_until(
			func() -> bool:
				return not player.is_story_held() and LifeDirector.actor(&"tiat") == null,
			20.0
		)
	)
	trace("21")
	assert_true(await take_exit(&"entrepot_etage", 40.0), "à l'étage")
	trace("22")
	await walk_to_point(&"nygglatho_tapis", 1.5)
	trace("23")
	assert_true(await play_until_done(&"j1_5_premiers_pas", 60.0, {"Ouvrir.": 1}))
	assert_true(
		await until(
			func() -> bool: return StoryDirector.hint() == "Couche Pannibal, au dortoir.", 2.0
		),
		"indice : %s" % StoryDirector.hint()
	)
	assert_ne(StoryDirector.current_scene(), &"j1_6_diner", "le dîner attend le dortoir")
	# 1.6 (séquence) puis 1.7.
	trace("24")
	await walk_to_point(&"dortoir_b", 0.9)
	trace("25")
	assert_true(await play_until_done(&"j1_6_diner", 60.0))
	trace("26")
	assert_true(
		await read_until(
			func() -> bool:
				return (
					not player.is_story_held() and StoryDirector.current_scene() == &"j1_7_chambre"
				),
			40.0
		)
	)
	trace("27")
	await walk_to_point(&"willem_porte", 2.0)
	trace("28")
	assert_true(await play_until_done(&"j1_7_chambre", 60.0))
	trace("29")
	assert_true(await wait_control())
	# Dormir : la ligne du calendrier, puis l'aube du jour 2.
	assert_eq(StoryDirector.hint(), "Il est tard. Au lit.")
	assert_true(StoryDirector.can_sleep())
	trace("30")
	assert_true(await use_prompt(StoryPrompt.ROLE_SLEEP), "l'invite « Dormir »")
	trace("31")
	assert_true(await until(func() -> bool: return GameState.day == 2, 15.0), "jour 2")
	assert_eq(LifeSlots.current(), &"aube")
	assert_true(GameState.has_calendar_line(1), "ligne du jour 1 au calendrier")
	trace("32")
	assert_true(await wait_control())
	# Le calendrier (Tab) : les douze jours, le jour 1 écrit.
	await tap_key(KEY_TAB)
	var calendar := hud.get_node("%Calendar")
	assert_true(calendar.call(&"is_open"), "Tab ouvre le calendrier")
	assert_false((hud.get_node("%Journal") as Control).visible, "pas le journal de quêtes")
	var lines: PackedStringArray = calendar.call(&"shown_lines")
	assert_eq(lines.size(), 1)
	assert_string_contains(lines[0], "Tombé dans le marais")
	await tap_key(KEY_TAB)
	assert_false(calendar.call(&"is_open"))
	assert_eq(GameState.quests(), {}, "aucune quête n'a démarré de toute la journée")


## Joue l'embuscade avec de vrais appuis jusqu'à sa fin et renvoie son résultat : au bond annoncé,
## un pas de côté au stick hors du cercle (vers le nord, le sud s'il est barré) ; aux
## taillades, la parade tenue (touche K) ; entre deux, rien.
func _play_ambush(ambush: Ambush) -> Dictionary:
	var outcome := {}
	ambush.finished.connect(func(found: Dictionary) -> void: outcome["result"] = found)
	var deadline := Time.get_ticks_msec() + 60000
	var guarding := false
	var nav := LifeDirector.nav()
	var leap_start := -1.0
	var side := Vector3.FORWARD
	while not outcome.has("result") and Time.get_ticks_msec() < deadline:
		var attack: Dictionary = ambush.current_attack() if is_instance_valid(ambush) else {}
		var kind: StringName = attack.get("kind", &"")
		var want_guard := kind == &"slash"
		if want_guard != guarding:
			key(GUARD_KEY, want_guard)
			guarding = want_guard
		if kind == &"leap":
			var target: Vector3 = attack["target"]
			var away := player.global_position - target
			away.y = 0.0
			if not is_equal_approx(float(attack["start"]), leap_start):
				# Une fois par bond : vers le nord (le marais), vers le sud s'il est barré.
				leap_start = float(attack["start"])
				side = Vector3.FORWARD
				if nav != null and not nav.line_clear(target, target + side * 1.6):
					side = -side
			if away.length() < 1.4:
				stick(side.x, side.z)
			else:
				stick(0.0, 0.0)
		else:
			stick(0.0, 0.0)
		await frames(1)
	stick(0.0, 0.0)
	if guarding:
		key(GUARD_KEY, false)
	await frames(2)
	return outcome.get("result", {})
