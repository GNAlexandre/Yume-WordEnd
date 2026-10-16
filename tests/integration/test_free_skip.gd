extends "res://tests/stubs/s2_story_test.gd"
## (X-L2) Passer une scène dans la vraie partie (main.tscn, vrais appuis) : en mode libre, un seul
## appui sur Échap passe chacune des 55 scènes de l'île n° 68 à n'importe quelle étape (invite
## « Échap : passer » dès le début, appui pris avant le menu pause, jeux arrêtés, scène faite,
## voile levé, caméra et main rendues) ; la clé « skip » d'une scène tient lieu de choix sauté
## (l'épilogue vient après le départ passé, la reprise du duel) ; en mode scénarisé, rien ne change
## (seules les séquences déjà vues se passent) et la touche d'interaction tenue accélère la scène
## sans la passer.

## Temps réel (s) avant l'appui, et au plus pour que la scène finisse ensuite.
const PRESS_AFTER := 1.0
const SKIP_WITHIN := 3.0
## Nombre de scènes de l'île n° 68.
const SCENE_COUNT := 55


## Le mode libre (la base M1 prend le mode scénarisé).
func mode_for_test() -> StringName:
	return StoryPacing.FREE


func after_each() -> void:
	key(KEY_E, false)
	key(KEY_ESCAPE, false)
	super()
	assert_eq(Engine.time_scale, 1.0, "le temps rendu après le test")


func _overlay() -> Node:
	return StoryDirector.stage().overlay()


func _fade() -> float:
	var overlay := _overlay()
	return float(overlay.call(&"fade_alpha")) if overlay != null else 0.0


## Attente en temps réel (même pendant une pause de l'arbre).
func _real_wait(seconds: float) -> void:
	await until(func() -> bool: return false, seconds)


## Les jeux du récit restés sous Life (le duel, l'embuscade, les deux entraînements).
func _games_left() -> PackedStringArray:
	var found := PackedStringArray()
	var map := WorldManager.current_map_node()
	var life := map.get_node_or_null(^"Life") if map != null else null
	if life == null:
		return found
	for child: Node in life.get_children():
		var is_game := (
			child is Duel
			or child is Ambush
			or child is StaffTraining
			or child is SenioriousTraining
		)
		if is_game and not child.is_queued_for_deletion():
			found.append(String(child.name))
	return found


func _go(map_id: StringName) -> bool:
	if WorldManager.current_map() == map_id and not WorldManager.is_transitioning():
		return true
	await until(func() -> bool: return not WorldManager.is_transitioning(), 10.0)
	await WorldManager.go_to(map_id)
	return await until(
		func() -> bool:
			return WorldManager.current_map() == map_id and not WorldManager.is_transitioning(),
		15.0
	)


## Toutes les scènes faites (aucune ne part ensuite d'elle-même), sauf keep.
func _all_done_but(keep: Array[StringName]) -> void:
	for scene_id: StringName in StoryData.scene_ids(ISLAND):
		if keep.has(scene_id):
			GameState.forget_scene(scene_id)
		else:
			GameState.mark_scene_done(scene_id)


## Joue la scène sur sa carte à son jour, appuie sur Échap après PRESS_AFTER s ; vrai si elle a
## fini dans les SKIP_WITHIN s qui suivent (et ce qu'il faut après un passage ; followed : une
## suite part juste après, seule la scène faite compte).
func _play_and_skip(scene_id: StringName, followed: bool = false) -> bool:
	var data := StoryData.scene(ISLAND, scene_id)
	assert_true(await _go(StringName(str(data["map"]))), "%s : sa carte" % scene_id)
	if data.has("day"):
		GameState.day = DialogueRunner.day_range(data["day"]).x
	GameState.forget_scene(scene_id)
	assert_true(StoryDirector.play(scene_id), "%s se joue" % scene_id)
	assert_eq(str(_overlay().call(&"skip_text")), "Échap : passer", "%s : l'invite" % scene_id)
	await _real_wait(PRESS_AFTER)
	assert_eq(StoryDirector.current_scene(), scene_id, "%s : toujours en cours" % scene_id)
	assert_true(StoryDirector.is_skippable(), "%s se passe" % scene_id)
	var step := StoryDirector.runner().current_step()
	var since := Time.get_ticks_msec()
	key(KEY_ESCAPE, true)
	var ended := await until(
		func() -> bool:
			return (
				GameState.is_scene_done(scene_id) and (followed or not StoryDirector.is_playing())
			),
		SKIP_WITHIN
	)
	var took := Time.get_ticks_msec() - since
	key(KEY_ESCAPE, false)
	assert_true(ended, "%s passée (étape %s) en %d ms" % [scene_id, step, took])
	gut.p("[x-l2] %s passée à l'étape %s en %d ms" % [scene_id, step, took])
	if not ended or followed:
		return ended
	await frames(2)
	assert_true(GameState.is_scene_done(scene_id), "%s faite" % scene_id)
	assert_false(player.is_story_held(), "%s : la main rendue" % scene_id)
	assert_eq(_games_left(), PackedStringArray(), "%s : aucun jeu restant" % scene_id)
	assert_false(pause_menu.call(&"is_open"), "%s : le menu pause fermé" % scene_id)
	assert_false(get_tree().paused, "%s : pas de pause" % scene_id)
	assert_true(
		await until(func() -> bool: return _fade() == 0.0, 2.0), "%s : voile levé" % scene_id
	)
	assert_true(
		await until(func() -> bool: return not player.camera_rig.is_story_framed(), 2.0),
		"%s : caméra rendue" % scene_id
	)
	assert_eq(StoryDirector.stage().followers(), [] as Array[StringName], "%s : seule" % scene_id)
	var visual := player.get_node(^"Visual") as Node3D
	assert_true(player.visible and visual.visible, "%s : visible" % scene_id)
	return true


func test_every_scene_passes_with_one_press_in_free_mode() -> void:
	assert_true(await new_game_from_menu(), "partie libre lancée depuis le menu")
	assert_eq(StoryDirector.mode(), StoryPacing.FREE)
	var ids := StoryData.scene_ids(ISLAND)
	assert_eq(ids.size(), SCENE_COUNT, "les scènes de l'île n° 68")
	_all_done_but([])
	# Par carte de départ : moins de chargements.
	var by_map := ids.duplicate()
	by_map.sort_custom(
		func(a: StringName, b: StringName) -> bool:
			var map_a := str(StoryData.scene(ISLAND, a)["map"])
			var map_b := str(StoryData.scene(ISLAND, b)["map"])
			return map_a < map_b if map_a != map_b else String(a) < String(b)
	)
	var passed := 0
	for scene_id: StringName in by_map:
		if await _play_and_skip(scene_id):
			passed += 1
		else:
			trace("%s non passée" % scene_id)
			await until(func() -> bool: return not StoryDirector.is_playing(), 30.0)
	assert_eq(passed, SCENE_COUNT, "toutes passées d'un appui")


func test_the_epilogue_follows_a_skipped_departure() -> void:
	assert_true(await new_game_from_menu(), "partie libre lancée depuis le menu")
	var keep: Array[StringName] = [&"j12_2_depart", &"j12_3_epilogue"]
	_all_done_but(keep)
	LifeDirector.set_slot(&"soir", 0.0)
	assert_true(await _play_and_skip(&"j12_2_depart", true), "le départ passé")
	assert_true(GameState.has_flag(&"j12_voir_epilogue"), "la clé « skip » : voir l'épilogue")
	assert_true(GameState.has_flag(&"acte1_fini"), "la fin de l'acte, posée en passant")
	assert_true(
		await until(func() -> bool: return StoryDirector.current_scene() == &"j12_3_epilogue", 3.0),
		"l'épilogue suit"
	)
	key(KEY_ESCAPE, true)
	assert_true(await until(func() -> bool: return not StoryDirector.is_playing(), 5.0))
	key(KEY_ESCAPE, false)
	assert_true(GameState.is_scene_done(&"j12_3_epilogue"), "l'épilogue passé à son tour")


func test_a_running_game_stops_and_its_choice_takes_the_skip_key() -> void:
	assert_true(await new_game_from_menu(), "partie libre lancée depuis le menu")
	_all_done_but([&"j8_3_duel"])
	assert_true(await _go(&"entrepot"))
	GameState.day = 8
	LifeDirector.set_slot(&"matin", 0.0)
	assert_true(StoryDirector.play(&"j8_3_duel"))
	# Le dialogue d'avant le duel lu à la touche, jusqu'au duel.
	assert_true(
		await read_until(func() -> bool: return MiniGames.duel() != null, 40.0), "le duel commence"
	)
	assert_false(GameState.has_flag(&"j8_duel_reprise"))
	await tap_key(KEY_ESCAPE)
	assert_true(await until(func() -> bool: return not StoryDirector.is_playing(), 5.0), "passée")
	await frames(2)
	assert_null(MiniGames.duel(), "le duel arrêté")
	assert_eq(_games_left(), PackedStringArray(), "et retiré")
	assert_true(GameState.has_flag(&"j8_duel_reprise"), "« Encore une fois ! » : la clé « skip »")
	assert_true(GameState.is_scene_done(&"j8_3_duel"))
	assert_eq(WorldManager.current_map(), &"entrepot_etage", "la fin de la scène jouée (go_to)")
	assert_false(player.is_story_held(), "la main")
	assert_false(pause_menu.call(&"is_open"), "pas de menu pause")
	# L'entraînement au bâton : arrêté et retiré tout de suite (sans sa pose de fin).
	_all_done_but([&"j9_2_batons"])
	assert_true(await _go(&"entrepot"))
	GameState.day = 9
	assert_true(StoryDirector.play(&"j9_2_batons"))
	assert_true(
		await read_until(func() -> bool: return MiniGames.staff_training() != null, 40.0),
		"l'entraînement commence"
	)
	await tap_key(KEY_ESCAPE)
	assert_true(await until(func() -> bool: return not StoryDirector.is_playing(), 5.0), "passée")
	await frames(2)
	assert_eq(_games_left(), PackedStringArray(), "l'entraînement retiré")
	assert_true(GameState.is_scene_done(&"j9_2_batons"))


func test_scenario_mode_is_unchanged_and_a_held_key_speeds_a_scene_up() -> void:
	assert_true(await new_game_from_menu(), "partie lancée depuis le menu")
	StoryDirector.set_mode(StoryPacing.SCENARIO)
	_all_done_but([&"j8_2_archives"])
	assert_true(await _go(&"entrepot_rdc"))
	GameState.day = 8
	# Une scène jamais vue ne se passe pas en scénarisé : pas d'invite, Échap n'y fait rien.
	assert_true(StoryDirector.play(&"j8_2_archives"))
	await frames(5)
	assert_false(StoryDirector.is_skippable(), "scénarisé : pas une séquence vue")
	assert_eq(str(_overlay().call(&"skip_text")), "", "pas d'invite")
	assert_true(await play_until_done(&"j8_2_archives", 60.0), "jouée jusqu'au bout")
	# La touche d'interaction tenue accélère l'épilogue (une séquence), sans le passer.
	var epilogue := &"j12_3_epilogue"
	_all_done_but([epilogue])
	assert_true(await _go(&"entrepot"))
	GameState.day = 12
	var since := Time.get_ticks_msec()
	assert_true(StoryDirector.play(epilogue))
	assert_true(await play_until_done(epilogue, 90.0), "l'épilogue au pas")
	var normal := Time.get_ticks_msec() - since
	GameState.forget_scene(epilogue)
	assert_true(await _go(&"entrepot"))
	await wait_control()
	since = Time.get_ticks_msec()
	assert_true(StoryDirector.play(epilogue))
	key(KEY_E, true)
	var forwarded := {"seen": false, "scale": 1.0}
	var done := await until(
		func() -> bool:
			if StoryDirector.runner().is_forwarding():
				forwarded["seen"] = true
				forwarded["scale"] = Engine.time_scale
			return GameState.is_scene_done(epilogue),
		60.0
	)
	key(KEY_E, false)
	var held := Time.get_ticks_msec() - since
	assert_true(done, "l'épilogue accéléré va au bout (sans être passé)")
	assert_true(forwarded["seen"], "accéléré pendant la scène")
	assert_almost_eq(float(forwarded["scale"]), StoryRunner.FAST_FORWARD, 0.001, "temps accéléré")
	assert_eq(Engine.time_scale, 1.0, "le temps rendu à la fin")
	gut.p("épilogue : %d ms au pas, %d ms touche tenue" % [normal, held])
	assert_lt(held, normal * 0.5, "au moins deux fois plus court (%d ms / %d ms)" % [held, normal])
