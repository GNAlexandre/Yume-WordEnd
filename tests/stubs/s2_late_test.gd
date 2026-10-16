extends "res://tests/stubs/e6_story_test.gd"
## (S2) Base des tests des jours 9 à 12 de l'acte 1 dans la vraie partie (main.tscn, vrais appuis) :
## une sauvegarde prise au réveil d'un jour (begin_day : jour, aube, la chambre de la protagoniste,
## les scènes des jours d'avant jouées, le calendrier rempli) est reprise par « Continuer » ; puis
## le jour se joue au stick et au clavier. Pilotes des jeux par les vraies touches : l'entraînement
## au bâton (parade K, coup J), l'entraînement avec Seniorious (souffle et Grue à la touche K, coups
## J, pas de côté S, « Ramasser Seniorious » E), l'embuscade de Pannibal (pas de côté, parade K).

## Touches des actions (project.godot) : la parade / la charge, le coup, l'interaction.
const GUARD_KEY := KEY_K
const ATTACK_KEY := KEY_J
const INTERACT_KEY := KEY_E
## La chambre de la protagoniste, à l'étage (près de son lit).
const BEDROOM := Vector3(6.2, 0.0, 6.4)

var _held_keys: Dictionary = {}


func after_each() -> void:
	_release_keys()
	MiniGames.stop_staff_training()
	MiniGames.stop_seniorious_training()
	MiniGames.stop_ambush()
	super()


# --- Début d'un jour ------------------------------------------------------------------------------


## Écrit la sauvegarde du réveil du jour day (scènes des jours d'avant jouées, sauf skip ; done en
## plus ; drapeaux flags ; créneau slot ; carte et position), puis la reprend par « Continuer ».
func begin_day(
	day: int,
	flags: Array[StringName] = [],
	done: Array[StringName] = [],
	slot: StringName = &"aube",
	map_id: StringName = &"entrepot_etage",
	at: Vector3 = BEDROOM
) -> bool:
	GameState.reset()
	GameState.skin_id = &"chtholly"
	var state := GameState.to_dict()
	state["day"] = day
	state["slot"] = String(slot)
	state["moment"] = String(LifeSlots.moment_of(slot))
	state["weather"] = "clair"
	state["map"] = String(map_id)
	state["position"] = [at.x, at.y, at.z]
	var scenes: Array[String] = []
	for scene_id: StringName in StoryData.scene_ids(STORY_ISLAND):
		if _scene_day(scene_id) < day or done.has(scene_id):
			scenes.append(String(scene_id))
	state["scenes_done"] = scenes
	var calendar := {}
	for previous: int in range(1, day):
		calendar[str(previous)] = ""
	state["calendar"] = calendar
	var flag_values := {}
	for flag: StringName in flags:
		flag_values[String(flag)] = true
	state["flags"] = flag_values
	GameState.from_dict(state)
	SaveManager.save()
	GameState.reset()
	return await continue_from_menu()


## « Continuer » depuis le menu (main.tscn ouvert au besoin, partie courante fermée).
func continue_from_menu() -> bool:
	if main != null:
		await close_tab()
	await open_main()
	await click_center()
	if not menu_button("ContinueButton").visible:
		return false
	await click(menu_button("ContinueButton"))
	return await wait_for_game()


## Jour d'une scène d'après son id (j9_2_batons → 9).
func _scene_day(scene_id: StringName) -> int:
	var head := String(scene_id).get_slice("_", 0).trim_prefix("j")
	return head.to_int() if head.is_valid_int() else 0


# --- Le temps ------------------------------------------------------------------------------


## Laisse passer le temps (invite d'un repos de la carte courante) jusqu'au créneau slot ; faux si
## c'est impossible.
func rest_until(slot: StringName, max_uses: int = 5) -> bool:
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


## Monte au lit (étage), « Dormir », et attend le jour suivant.
func sleep_in_bed() -> bool:
	if WorldManager.current_map() == &"entrepot":
		await take_exit(&"entrepot_rdc", 60.0)
	if WorldManager.current_map() == &"entrepot_rdc":
		await take_exit(&"entrepot_etage", 60.0)
	if WorldManager.current_map() == &"entrepot_toit":
		await take_exit(&"entrepot_etage", 60.0)
	var day := GameState.day
	if not await use_prompt(StoryPrompt.ROLE_SLEEP):
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
