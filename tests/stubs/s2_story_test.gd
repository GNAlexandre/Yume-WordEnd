extends "res://tests/stubs/e6_story_test.gd"
## (S2) Base des tests des jours 5 et suivants dans la vraie partie (main.tscn, vrais appuis) :
## reprise au réveil d'un jour (état de début de jour posé comme le fait test_e6_days.gd : jour,
## créneau, scènes faites, drapeaux, carte, position ; puis « Continuer » à la souris), laisser
## passer le temps et se coucher par les invites, marches au stick. (S2, jours 7 et 8) une partie
## posée au début d'un jour (continue_at_day : les scènes des jours d'avant jouées), la sortie la
## plus proche d'un point, la reprise au milieu d'un jour, le duel joué au clavier.

const ISLAND := &"ile_68"
## Touches de l'attaque et de la charge (project.godot : J, K).
const ATTACK_KEY := KEY_J
const CHARGE_KEY := KEY_K

## Les scènes des jours 1 à 4, faites au réveil du jour 5.
const DAYS_1_TO_4: Array[StringName] = [
	&"j1_1_port",
	&"j1_2_lumiere",
	&"j1_2_embuscade",
	&"j1_3_intrus",
	&"j1_4_chemin",
	&"j1_5_premiers_pas",
	&"j1_6_diner",
	&"j1_7_chambre",
	&"j2_1_matin",
	&"j2_2_fuite",
	&"j2_3_fenetre",
	&"j3_1_information",
	&"j3_2_chemin",
	&"j3_3_snack",
	&"j4_1_cuisine",
	&"j4_2_diner",
]
## Le jour 5 fait (pour reprendre au jour 6).
const DAY_5_DONE: Array[StringName] = [&"j5_1_jeu_willem", &"j5_2_fenetre"]
## Où l'on se réveille : la chambre de la protagoniste.
const WAKE_MAP := &"entrepot_etage"
const WAKE_AT := Vector3(6.2, 0.0, 7.4)


## Écrit une sauvegarde à l'état donné (jour, créneau, scènes faites, drapeaux, carte, position),
## ouvre le jeu, « Continuer » à la souris ; attend la partie.
func resume_day(
	day: int,
	slot: StringName,
	scenes: Array[StringName],
	map: StringName = WAKE_MAP,
	at: Vector3 = WAKE_AT,
	flags: Array[StringName] = []
) -> bool:
	SaveManager.new_game(&"chtholly")
	var state := GameState.to_dict()
	state["day"] = day
	state["slot"] = String(slot)
	state["moment"] = String(LifeSlots.moment_of(slot))
	var done: Array[String] = []
	for scene_id: StringName in scenes:
		done.append(String(scene_id))
	state["scenes_done"] = done
	var calendar := {}
	for before: int in range(1, day):
		calendar[str(before)] = ""
	state["calendar"] = calendar
	var flag_values: Dictionary = state["flags"]
	for flag: StringName in flags:
		flag_values[String(flag)] = true
	state["map"] = String(map)
	state["position"] = [at.x, at.y, at.z]
	GameState.from_dict(state)
	SaveManager.save()
	await continue_game()
	return GameState.day == day and WorldManager.current_map() == map


## Ferme l'onglet et rouvre le jeu : « Continuer » à la souris ; attend la partie.
func continue_game() -> bool:
	if main != null:
		await close_tab()
	else:
		SaveManager.close_game(false)
	await open_main()
	await click_center()
	assert_true(menu_button("ContinueButton").visible, "Continuer")
	await click(menu_button("ContinueButton"))
	return await wait_for_game()


## Laisse passer le temps par l'invite de la chambre jusqu'au créneau (vrais appuis).
func rest_until(slot: StringName) -> bool:
	var guard := 0
	while LifeSlots.current() != slot and guard < 8:
		guard += 1
		if not StoryDirector.can_rest():
			return false
		if WorldManager.current_map() != WAKE_MAP:
			await go_upstairs()
		var before := LifeSlots.current()
		if not await use_prompt(StoryPrompt.ROLE_REST):
			return false
		if not await until(func() -> bool: return LifeSlots.current() != before, 10.0):
			return false
		await wait_control()
	return LifeSlots.current() == slot


## Prend une sortie en réessayant (à la tombée du jour, les petites montent toutes en même temps et
## bouchent un moment l'escalier et les portes).
func take_exit_again(map_id: StringName, attempts: int = 3, seconds: float = 40.0) -> bool:
	for _attempt in attempts:
		if await take_exit(map_id, seconds):
			return true
		await frames(120)
	return WorldManager.current_map() == map_id


## Monte à l'étage (de l'entrepôt ou du rez-de-chaussée) à pied.
func go_upstairs() -> bool:
	if WorldManager.current_map() == &"entrepot":
		if not await take_exit_again(&"entrepot_rdc"):
			return false
		await wait_control()
	if WorldManager.current_map() == &"entrepot_rdc":
		return await take_exit_again(&"entrepot_etage")
	return WorldManager.current_map() == &"entrepot_etage"


## Marche jusqu'à un point en réessayant (les petites qui regagnent leur place à la tombée du jour
## bouchent un moment les portes) ; vrai quand le joueur y est ou quand une scène l'a pris.
func walk_to_point_again(
	spec: Variant, radius: float = 0.8, attempts: int = 4, seconds: float = 30.0
) -> bool:
	for _attempt in attempts:
		if await walk_to_point(spec, radius, seconds):
			return true
		await frames(120)
	return false


## Le nom des invites de scène de la carte courante (texte affiché), pour les tests.
func scene_prompt_texts() -> PackedStringArray:
	var found := PackedStringArray()
	for prompt: StoryPrompt in StoryDirector.prompts():
		if prompt.roles.has(StoryPrompt.ROLE_SCENE) and prompt.is_available():
			found.append(prompt.get_prompt())
	return found


## Se couche par l'invite du lit (vrais appuis) ; vrai quand le jour suivant a commencé.
func sleep_by_prompt() -> bool:
	if WorldManager.current_map() != WAKE_MAP:
		await go_upstairs()
	var day := GameState.day
	if not StoryDirector.can_sleep() or not await use_prompt(StoryPrompt.ROLE_SLEEP):
		return false
	return await until(func() -> bool: return GameState.day == day + 1, 15.0)


## Une partie au début du jour day (aube) sur map_id, en at, les scènes des jours d'avant
## jouées (resume_day) ; faux si la partie n'arrive pas.
func continue_at_day(day: int, map_id: StringName, at: Vector3) -> bool:
	return await resume_day(day, &"aube", scenes_before(day), map_id, at)


## Les scènes des jours d'avant day (jN_… avec N < day), dans l'ordre des ids.
func scenes_before(day: int) -> Array[StringName]:
	var done: Array[StringName] = []
	for scene_id: StringName in StoryData.scene_ids(ISLAND):
		var prefix := String(scene_id).get_slice("_", 0)
		if prefix.begins_with("j") and prefix.trim_prefix("j").to_int() < day:
			done.append(scene_id)
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
	return await continue_game()


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
