extends "res://tests/stubs/e6_story_test.gd"
## (S2) Base des tests des jours 5 et suivants dans la vraie partie (main.tscn, vrais appuis) :
## reprise au réveil d'un jour (état de début de jour posé comme le fait test_e6_days.gd : jour,
## créneau, scènes faites, drapeaux, carte, position ; puis « Continuer » à la souris), laisser
## passer le temps et se coucher par les invites, marches au stick. Pilotes des jeux par les vraies
## touches (jours 9 à 12) : l'entraînement au bâton (parade K, coup J), l'entraînement avec
## Seniorious (souffle et Grue à la touche K, coups J, pas de côté S, « Ramasser Seniorious » E),
## l'embuscade de Pannibal (pas de côté, parade K).

## Touches des actions (project.godot) : la parade / la charge, le coup, l'interaction.
const GUARD_KEY := KEY_K
const ATTACK_KEY := KEY_J
const INTERACT_KEY := KEY_E
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
## (Jours 9 à 12) Le réveil, près du lit de la protagoniste.
const BEDROOM := Vector3(6.2, 0.0, 6.4)

var _held_keys: Dictionary = {}


func after_each() -> void:
	_release_keys()
	MiniGames.stop_staff_training()
	MiniGames.stop_seniorious_training()
	MiniGames.stop_ambush()
	super()


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


## (Jours 9 à 12) Reprend au réveil du jour day par resume_day : les scènes des jours d'avant
## jouées, plus done ; drapeaux flags ; créneau slot ; carte et position.
func begin_day(
	day: int,
	flags: Array[StringName] = [],
	done: Array[StringName] = [],
	slot: StringName = &"aube",
	map_id: StringName = WAKE_MAP,
	at: Vector3 = BEDROOM
) -> bool:
	var scenes: Array[StringName] = []
	for scene_id: StringName in StoryData.scene_ids(STORY_ISLAND):
		if _scene_day(scene_id) < day or done.has(scene_id):
			scenes.append(scene_id)
	return await resume_day(day, slot, scenes, map_id, at, flags)


## Jour d'une scène d'après son id (j9_2_batons → 9).
func _scene_day(scene_id: StringName) -> int:
	var head := String(scene_id).get_slice("_", 0).trim_prefix("j")
	return head.to_int() if head.is_valid_int() else 0


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


## Laisse passer le temps par l'invite de repos de la carte courante (un banc, la banquette…)
## jusqu'au créneau slot, sans monter à la chambre ; faux si c'est impossible.
func rest_here_until(slot: StringName, max_uses: int = 5) -> bool:
	for _use in max_uses:
		if LifeSlots.current() == slot:
			return true
		if not StoryDirector.can_rest():
			return false
		var before := LifeSlots.current()
		if not await use_prompt(StoryPrompt.ROLE_REST):
			return false
		if not await until(func() -> bool: return LifeSlots.current() != before, 8.0):
			return false
		await wait_control(10.0)
	return LifeSlots.current() == slot


## Prend une sortie en réessayant (à la tombée du jour, les petites montent toutes en même temps et
## bouchent un moment l'escalier et les portes).
func take_exit_again(map_id: StringName, attempts: int = 3, seconds: float = 40.0) -> bool:
	for _attempt in attempts:
		if await take_exit(map_id, seconds):
			return true
		await frames(120)
	return WorldManager.current_map() == map_id


## Monte (de l'entrepôt ou du rez-de-chaussée) ou descend (du toit) à l'étage, à pied.
func go_upstairs() -> bool:
	if WorldManager.current_map() == &"entrepot_toit":
		return await take_exit_again(&"entrepot_etage")
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


## Marche tout droit au stick (sans la navigation) jusqu'à moins de radius m de target.
func walk_straight(target: Vector3, radius: float = 0.4, max_seconds: float = 10.0) -> bool:
	var reached: bool = await walk_stick_until(
		0.0,
		0.0,
		func() -> bool:
			var gap := target - player.global_position
			gap.y = 0.0
			if gap.length() <= radius:
				return true
			var toward := gap.normalized()
			stick(toward.x, toward.z)
			return false,
		max_seconds
	)
	return reached


## Utilise l'invite de scène jusqu'à ce que la scène scene_id commence (sous charge, un appui
## peut tomber avant que la zone de l'invite n'ait vu le joueur) : false après tries essais.
func use_scene_prompt(scene_id: StringName, tries: int = 4) -> bool:
	for _try: int in tries:
		if StoryDirector.current_scene() == scene_id:
			return true
		if not await use_prompt(StoryPrompt.ROLE_SCENE):
			await frames(10)
			continue
		if await until(func() -> bool: return StoryDirector.current_scene() == scene_id, 2.0):
			return true
	return StoryDirector.current_scene() == scene_id


## Marche jusqu'à moins de radius m d'un PNJ de la carte (sa place suivie à chaque pas).
func walk_to_actor(npc_id: StringName, radius: float = 1.2, max_seconds: float = 30.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(max_seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		var actor := LifeDirector.actor(npc_id)
		if actor == null:
			return false
		if flat_distance(player.global_position, actor.position()) <= radius:
			stick(0.0, 0.0)
			return true
		if player.is_story_held():
			stick(0.0, 0.0)
			return true
		await walk_to(actor.position(), radius, 2.0)
	return false


# --- Les touches ---------------------------------------------------------------------------


func _press(keycode: Key, pressed: bool) -> void:
	if pressed == _held_keys.has(keycode):
		return
	if pressed:
		_held_keys[keycode] = true
	else:
		_held_keys.erase(keycode)
	key(keycode, pressed)


func _release_keys() -> void:
	for keycode: Key in _held_keys.keys():
		key(keycode, false)
	_held_keys.clear()
	stick(0.0, 0.0)


## Un appui bref sans attendre (la touche relâchée deux images plus tard).
func _tap_soon(keycode: Key) -> void:
	_press(keycode, false)
	_press(keycode, true)
	get_tree().create_timer(0.05, true, true).timeout.connect(_press.bind(keycode, false))


# --- L'entraînement au bâton (E8, 3.2) ------------------------------------------------------------


## Joue l'entraînement au bâton jusqu'à sa fin et renvoie son résultat : à chaque coup qui vise le
## joueur, la parade (K) levée pendant l'annonce et relâchée juste avant l'impact (la déviation) ;
## en phase B, rapproché de Willem, un coup de bâton (J) dès qu'une déviation le découvre.
func play_staff_training(max_seconds: float = 150.0) -> Dictionary:
	var training := MiniGames.staff_training()
	if training == null:
		return {}
	var outcome := {}
	var opened := {"at": -1.0}
	training.finished.connect(func(found: Dictionary) -> void: outcome["result"] = found)
	training.resolved.connect(
		func(_kind: StringName, result: StringName) -> void:
			if result == &"deflected":
				opened["at"] = training.game_time()
	)
	var deadline := Time.get_ticks_msec() + int(max_seconds * 1000.0)
	while not outcome.has("result") and Time.get_ticks_msec() < deadline:
		if not is_instance_valid(training):
			break
		var blow := training.current_blow()
		var now := training.game_time()
		var on_me := false
		if not blow.is_empty():
			var target: Vector3 = blow["target"]
			on_me = flat_distance(target, player.global_position) < 0.9
		var guard := (
			on_me and now >= float(blow["impact"]) - 0.42 and now < float(blow["impact"]) - 0.07
		)
		_press(GUARD_KEY, guard)
		if training.phase == &"b":
			var willem := LifeDirector.actor(&"willem")
			if willem != null and not guard:
				var gap := willem.position() - player.global_position
				gap.y = 0.0
				if gap.length() > 1.3:
					var toward := gap.normalized()
					stick(toward.x, toward.z)
				else:
					stick(0.0, 0.0)
					if float(opened["at"]) >= 0.0 and now - float(opened["at"]) < 0.3:
						opened["at"] = -1.0
						_tap_soon(ATTACK_KEY)
		else:
			stick(0.0, 0.0)
		await frames(1)
	_release_keys()
	await frames(2)
	return outcome.get("result", {})


# --- L'entraînement avec Seniorious (E8b, 3.4) ----------------------------------------------------


## Joue l'entraînement avec Seniorious jusqu'à sa fin (le souffle, les gestes, les Grues, l'épée
## ramassée dans le marais) et renvoie son résultat ; le pilote de la démonstration d'E8b
## (tests/integration/demo_e8b.gd), aux vraies touches.
func play_seniorious(max_seconds: float = 200.0) -> Dictionary:
	var training := MiniGames.seniorious_training()
	if training == null:
		return {}
	var outcome := {}
	var plan := {}
	training.finished.connect(func(found: Dictionary) -> void: outcome["result"] = found)
	var deadline := Time.get_ticks_msec() + int(max_seconds * 1000.0)
	while not outcome.has("result") and Time.get_ticks_msec() < deadline:
		if not is_instance_valid(training):
			break
		_drive_seniorious(training, plan)
		await frames(1)
	_release_keys()
	await frames(2)
	return outcome.get("result", {})


func _drive_seniorious(training: SenioriousTraining, plan: Dictionary) -> void:
	var now := training.game_time()
	match training.stage:
		&"breath":
			var start := training.breath_end() - 4.0
			_press(GUARD_KEY, now >= start and now < training.breath_end() - 0.05)
		&"moves":
			var gesture := training.current_gesture()
			if gesture.is_empty() or now < float(gesture["start"]) + 0.25:
				_press(KEY_S, false)
				return
			var last := float(plan.get("tap_at", -9.0))
			match gesture["gesture"]:
				&"trois_coups":
					if now - last > 0.25:
						plan["tap_at"] = now
						_tap_soon(ATTACK_KEY)
				&"pare":
					if last < float(gesture["start"]):
						plan["tap_at"] = now
						_tap_soon(GUARD_KEY)
				&"cote":
					_press(KEY_S, true)
		&"crane":
			_press(KEY_S, false)
			var fend := training.current_fend()
			if fend.is_empty() or bool(fend["struck"]):
				if not fend.is_empty() and bool(fend["perfect"]):
					if _held_keys.has(GUARD_KEY):
						_press(GUARD_KEY, false)
					elif not plan.get("struck", false):
						plan["struck"] = true
						_tap_soon(ATTACK_KEY)
				elif fend.is_empty():
					plan.erase("struck")
					_press(GUARD_KEY, false)
				return
			if now >= float(fend["impact"]) - 0.1:
				_press(GUARD_KEY, true)
		&"pickup":
			var spot := training.sword_spot()
			if spot == Vector3.INF:
				return
			var gap := spot - player.global_position
			gap.y = 0.0
			if gap.length() > 0.8:
				var toward := gap.normalized()
				stick(toward.x, toward.z)
			else:
				stick(0.0, 0.0)
				if now - float(plan.get("tap_at", -9.0)) > 0.6:
					plan["tap_at"] = now
					_tap_soon(INTERACT_KEY)


# --- L'embuscade de Pannibal (E8c, 3.1) -----------------------------------------------------------


## Joue l'embuscade jusqu'à sa fin et renvoie son résultat : au bond, un pas de côté au stick hors
## du cercle ; aux taillades, la parade tenue (K).
func play_ambush(ambush: Ambush, max_seconds: float = 60.0) -> Dictionary:
	var outcome := {}
	ambush.finished.connect(func(found: Dictionary) -> void: outcome["result"] = found)
	var deadline := Time.get_ticks_msec() + int(max_seconds * 1000.0)
	var nav := LifeDirector.nav()
	var leap_start := -1.0
	var side := Vector3.FORWARD
	while not outcome.has("result") and Time.get_ticks_msec() < deadline:
		var attack: Dictionary = ambush.current_attack() if is_instance_valid(ambush) else {}
		var kind: StringName = attack.get("kind", &"")
		_press(GUARD_KEY, kind == &"slash")
		if kind == &"leap":
			var target: Vector3 = attack["target"]
			var away := player.global_position - target
			away.y = 0.0
			if not is_equal_approx(float(attack["start"]), leap_start):
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
	_release_keys()
	await frames(2)
	return outcome.get("result", {})
