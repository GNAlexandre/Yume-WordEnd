extends "res://tests/stubs/e6_story_test.gd"
## (S2) Base des tests des jours 7 et 8 de l'acte 1 (tests/integration/test_s2_day7.gd,
## test_s2_day8.gd) dans la vraie partie (main.tscn, vrais appuis) : une partie posée au début
## d'un jour, comme test_e6_days.gd (les scènes des jours d'avant jouées, le calendrier écrit),
## enregistrée puis reprise par « Continuer » ; le duel joué au clavier.

const ISLAND := &"ile_68"
## Touches de l'attaque et de la charge (project.godot : J, K).
const ATTACK_KEY := KEY_J
const CHARGE_KEY := KEY_K


## Écrit une partie au début du jour day (aube) sur map_id, en at, puis la reprend par le menu
## (« Cliquer pour jouer », « Continuer ») ; faux si la partie n'arrive pas.
func continue_at_day(day: int, map_id: StringName, at: Vector3) -> bool:
	SaveManager.new_game(&"chtholly")
	SaveManager.close_game(false)
	var state := GameState.to_dict()
	state["day"] = day
	state["slot"] = "aube"
	state["moment"] = "aube"
	state["weather"] = "clair"
	state["scenes_done"] = scenes_before(day)
	var calendar := {}
	for done_day: int in range(1, day):
		calendar[str(done_day)] = ""
	state["calendar"] = calendar
	state["map"] = String(map_id)
	state["position"] = [at.x, at.y, at.z]
	GameState.from_dict(state)
	SaveManager.save()
	GameState.reset()
	await open_main()
	await click_center()
	if not menu_button("ContinueButton").visible:
		return false
	await click(menu_button("ContinueButton"))
	return await wait_for_game()


## Les scènes des jours d'avant day (jN_… avec N < day), dans l'ordre des ids.
func scenes_before(day: int) -> Array[String]:
	var done: Array[String] = []
	for scene_id: StringName in StoryData.scene_ids(ISLAND):
		var prefix := String(scene_id).get_slice("_", 0)
		if prefix.begins_with("j") and prefix.trim_prefix("j").to_int() < day:
			done.append(String(scene_id))
	return done


## Comme take_exit, par la sortie vers map_id la plus proche du point near de la carte courante
## (la porte d'entrée plutôt que la porte de service) ; faux si elle n'existe pas.
func take_exit_near(map_id: StringName, near: StringName, max_seconds: float = 40.0) -> bool:
	var target := StoryDirector.stage().resolve(near).origin
	var best: MapExit = null
	for candidate: MapExit in WorldManager.current_map_node().exits():
		if candidate.target_map != map_id:
			continue
		if (
			best == null
			or (
				candidate.global_position.distance_to(target)
				< best.global_position.distance_to(target)
			)
		):
			best = candidate
	if best == null:
		return false
	var with_prompt := best.needs_interaction()
	await walk_to(best.global_position, 0.5, max_seconds)
	if with_prompt and WorldManager.current_map() != map_id:
		await tap_key(KEY_E)
	return await until(
		func() -> bool:
			return WorldManager.current_map() == map_id and not WorldManager.is_transitioning(),
		10.0
	)


## Ferme la partie et la reprend par « Continuer » (la sauvegarde écrite d'abord).
func save_and_continue() -> bool:
	SaveManager.save()
	await close_tab()
	await open_main()
	await click_center()
	if not menu_button("ContinueButton").visible:
		return false
	await click(menu_button("ContinueButton"))
	return await wait_for_game()


## Joue le duel en cours au clavier jusqu'à sa fin et renvoie son résultat ({} s'il ne finit pas) :
## deux frappes qu'il esquive, la charge (K) tenue jusqu'à la vision accélérée, une frappe (J) ;
## à la reprise, la charge puis la frappe.
func play_duel(max_seconds: float = 90.0) -> Dictionary:
	if not await until(func() -> bool: return MiniGames.duel() != null, 20.0):
		return {}
	var duel := MiniGames.duel()
	var outcome := {}
	duel.finished.connect(func(found: Dictionary) -> void: outcome["result"] = found)
	var deadline := Time.get_ticks_msec() + int(max_seconds * 1000.0)
	var strikes := 0
	var charging := false
	while not outcome.has("result") and Time.get_ticks_msec() < deadline:
		var phase: StringName = duel.phase if is_instance_valid(duel) else &"ended"
		if phase == &"dodge" and strikes < 2:
			await tap_key(ATTACK_KEY)
			strikes += 1
			await frames(20)
		elif phase in [&"dodge", &"ready"]:
			if not charging:
				key(CHARGE_KEY, true)
				charging = true
			await frames(1)
		elif phase == &"vision":
			if charging:
				key(CHARGE_KEY, false)
				charging = false
				await frames(2)
			await tap_key(ATTACK_KEY)
			await frames(10)
		else:
			await frames(1)
	if charging:
		key(CHARGE_KEY, false)
	await frames(2)
	return outcome.get("result", {})
