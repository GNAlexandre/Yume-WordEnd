extends "res://tests/stubs/s2_story_test.gd"
## (X-L6) Les jeux à la demande du mode libre dans la vraie partie (main.tscn, vrais appuis) :
## parler à Willem à la clairière le matin propose l'entraînement au bâton, « Allons-y » le lance ;
## Échap l'arrête et rend la main (sans ouvrir le menu pause) ; aucun drapeau du récit n'est
## changé (GameState comparé avant et après) ; une scène proposée passe d'abord ; en scénarisé,
## rien n'est proposé ; l'embuscade de Pannibal et le ballon de Tiat se lancent et s'arrêtent.

const OFFER_GO := "Allons-y"
const OFFER_LATER := "Plus tard"
## Le départ des reprises sur la carte de l'entrepôt : Spawn, devant le porche.
const COURTYARD := Vector3(42.0, 0.2, 33.0)
## Champs de la partie qu'un jeu à la demande ne doit pas toucher : tout, sauf où se trouve le
## joueur et l'ambiance (carte, position, moment, météo).
const MOVING_KEYS: Array[String] = ["position", "map", "moment", "weather"]

## Répliques reçues (dialogue_line) : [orateur, texte, choix].
var _lines: Array[Array] = []


## Ces tests jouent le mode libre (la base M1 prend le mode scénarisé).
func mode_for_test() -> StringName:
	return StoryPacing.FREE


func before_each() -> void:
	super()
	_lines.clear()
	listen(EventBus.dialogue_line, _on_line)


func after_each() -> void:
	MiniGames.stop_ball_match()
	StoryDirector.activities().seed_value = -1
	super()


func _on_line(speaker: String, text: String, choices: Array) -> void:
	_lines.append([speaker, text, choices])


func _last_line() -> Array:
	return _lines.back() if not _lines.is_empty() else ["", "", []]


func _offer_text(activity_id: StringName) -> String:
	return StoryData.text(
		STORY_ISLAND, StoryActivities.text_key(activity_id, "offer"), &"", "(manque)"
	)


## L'état de la partie qui compte pour le récit : tout GameState, sauf où est le joueur.
func _story_state() -> Dictionary:
	var state := GameState.to_dict()
	for moving: String in MOVING_KEYS:
		state.erase(moving)
	return state


## Un point à 1,2 m du PNJ, du côté le plus loin des autres personnages (une table de jeu…).
func _approach(npc: Npc) -> Vector3:
	var best := npc.global_position
	var best_room := -1.0
	for side: Vector3 in [Vector3.BACK, Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD]:
		var spot := npc.global_position + side * 1.2
		var room := INF
		for actor: LifeActor in LifeDirector.actors():
			if actor.npc != npc:
				room = minf(room, flat_distance(actor.position(), spot))
		if room > best_room:
			best_room = room
			best = spot
	return best


## Marche jusqu'au PNJ, se tourne vers lui et lui parle (E) ; vrai si un dialogue s'ouvre.
func _talk_to(npc_id: StringName) -> bool:
	for _attempt in 5:
		var npc := LifeDirector.npc(npc_id)
		if npc == null:
			await frames(10)
			continue
		var spot := _approach(npc)
		if not await walk_to(spot, 0.3, 12.0):
			# Coincée contre une table ou un personnage : posée à côté de lui.
			await place_player(current_map().to_local(spot), Vector3.FORWARD)
		var toward := npc.global_position - player.global_position
		toward.y = 0.0
		if toward.length() > 0.05:
			player.set_aim_direction(toward.normalized(), true)
		await frames(4)
		if player.current_interactable() == npc:
			await tap_key(KEY_E)
			return await until(func() -> bool: return dialogue_box.is_open(), 3.0)
	return false


## Attend les deux choix de la proposition et prend celui d'index index (flèches, E).
func _choose(index: int) -> bool:
	var shown := await until(
		func() -> bool:
			if dialogue_box.is_typing():
				dialogue_box.complete_line()
			return dialogue_box.is_choosing(),
		5.0
	)
	if not shown:
		return false
	while dialogue_box.selected_choice() < index:
		await tap_key(KEY_DOWN)
	await tap_key(KEY_E)
	return true


## Le matin du jour 9 dehors, les bâtons déjà faits (aucune scène n'est plus proposée à Willem).
func _willem_morning(done_extra: Array[StringName] = []) -> bool:
	var done: Array[StringName] = [&"j9_1_porte", &"j9_2_batons"]
	done.append_array(done_extra)
	var flags: Array[StringName] = [StoryPacing.FREE_FLAG]
	if not await begin_day(9, flags, done, &"matin", &"entrepot", COURTYARD):
		return false
	return await until(func() -> bool: return LifeDirector.npc(&"willem") != null, 5.0)


func _training_running() -> bool:
	var training := MiniGames.staff_training()
	return training != null and training.is_running()


func test_willem_offers_the_staff_training_and_escape_stops_it() -> void:
	assert_true(await _willem_morning(), "jour 9 au matin, à l'entrepôt")
	var activities := StoryDirector.activities()
	var glade := StoryDirector.stage().resolve(&"clairiere_centre").origin
	var willem := LifeDirector.npc(&"willem")
	assert_true(
		await until(
			func() -> bool: return flat_distance(willem.global_position, glade) < 6.0, 20.0
		),
		"Willem est à la clairière"
	)
	assert_eq(StoryDirector.mode(), StoryPacing.FREE)
	assert_eq(activities.offered_by(&"willem"), &"baton", "l'entraînement est proposé")
	assert_eq(StoryDirector.offers().offered_scenes(), [] as Array[StringName], "aucune scène")
	var before := _story_state()
	var outcomes: Array[StringName] = []
	activities.finished.connect(
		func(_id: StringName, outcome: StringName) -> void: outcomes.append(outcome)
	)
	# Parler à Willem : la proposition, puis « Allons-y ».
	assert_true(await _talk_to(&"willem"), "parler à Willem")
	assert_true(await until(func() -> bool: return dialogue_box.is_choosing(), 5.0), "deux choix")
	var line := _last_line()
	assert_eq(line[0], "Willem", "Willem parle")
	assert_eq(line[1], _offer_text(&"baton"), "la proposition de l'entraînement")
	assert_eq(line[2], [OFFER_GO, OFFER_LATER], "« Allons-y » et « Plus tard »")
	assert_true(await _choose(0), "« Allons-y »")
	assert_true(
		await until(func() -> bool: return activities.running() == &"baton", 5.0),
		"l'activité démarre"
	)
	assert_true(await until(_training_running, 5.0), "l'entraînement au bâton court")
	assert_true(activities.busy())
	assert_true(StoryDirector.current_scene().is_empty(), "ce n'est pas une scène")
	await wait_seconds(1.0)
	assert_true(_training_running(), "il court encore")
	# Échap : le jeu s'arrête, la main est rendue, le menu pause ne s'ouvre pas.
	await tap_key(KEY_ESCAPE)
	assert_true(
		await until(func() -> bool: return activities.running().is_empty(), 5.0),
		"l'activité est finie"
	)
	assert_eq(outcomes, [StoryActivities.STOPPED] as Array[StringName], "arrêtée")
	assert_false(activities.busy())
	assert_false(_training_running(), "l'entraînement est arrêté")
	assert_false(get_tree().paused, "pas de menu pause")
	assert_false(player.is_story_held(), "la main est rendue")
	assert_true(hud.story_message().length() > 0, "un message dit la fin")
	assert_eq(
		hud.story_message(),
		StoryData.text(STORY_ISLAND, "activities/baton/result_stopped"),
		"le résultat de l'arrêt"
	)
	# Rendre la main : le joueur marche.
	var start := player.global_position
	await hold_key(KEY_D, 0.6)
	assert_gt(flat_distance(player.global_position, start), 0.5, "le joueur marche")
	# Le récit n'en garde rien.
	assert_eq(_story_state(), before, "aucun drapeau du récit n'a changé")
	assert_true(await wait_control(10.0))
	# Un second Échap ouvre le menu pause comme avant.
	await tap_key(KEY_ESCAPE)
	assert_true(await until(func() -> bool: return get_tree().paused, 3.0), "le menu pause")
	await tap_key(KEY_ESCAPE)
	await until(func() -> bool: return not get_tree().paused, 3.0)


func test_later_leads_to_the_free_conversation() -> void:
	assert_true(await _willem_morning(), "jour 9 au matin, à l'entrepôt")
	var dialogues: Array[StringName] = []
	listen(EventBus.dialogue_started, func(id: StringName) -> void: dialogues.append(id))
	var before := _story_state()
	assert_true(await _talk_to(&"willem"), "parler à Willem")
	assert_eq(_last_line()[1], _offer_text(&"baton"))
	var lines_before := _lines.size()
	assert_true(await _choose(1), "« Plus tard »")
	assert_true(
		await until(func() -> bool: return dialogues.size() > 1, 3.0), "la conversation libre"
	)
	assert_true(await until(func() -> bool: return _lines.size() > lines_before, 3.0))
	assert_ne(_last_line()[1], _offer_text(&"baton"), "pas la proposition")
	assert_true(await wait_control(30.0), "conversation lue")
	assert_false(StoryDirector.activities().busy(), "aucun jeu")
	assert_false(_training_running())
	assert_eq(_story_state(), before, "rien n'a changé")


func test_a_scene_offer_comes_before_the_activity() -> void:
	# Les bâtons du jour 9 pas encore joués : Willem propose la scène, pas l'entraînement.
	var flags: Array[StringName] = [StoryPacing.FREE_FLAG]
	var done: Array[StringName] = [&"j9_1_porte"]
	assert_true(await begin_day(9, flags, done, &"matin", &"entrepot", COURTYARD))
	assert_true(await until(func() -> bool: return LifeDirector.npc(&"willem") != null, 5.0))
	assert_true(StoryDirector.offers().offered_scenes().has(&"j9_2_batons"), "la scène proposée")
	assert_eq(StoryDirector.activities().offered_by(&"willem"), &"baton", "l'activité aussi")
	assert_true(await _talk_to(&"willem"), "parler à Willem")
	assert_true(await until(func() -> bool: return dialogue_box.is_choosing(), 5.0))
	assert_eq(
		_last_line()[1],
		StoryData.text(STORY_ISLAND, "offer", &"j9_2_batons"),
		"la scène passe d'abord"
	)
	assert_ne(_last_line()[1], _offer_text(&"baton"))
	assert_eq(StoryDirector.offers().proposing(), &"j9_2_batons")
	assert_true(await _choose(1), "« Plus tard »")
	assert_true(await wait_control(30.0))
	assert_false(StoryDirector.activities().busy(), "aucun jeu lancé")


func test_nothing_is_offered_in_scenario_mode() -> void:
	assert_true(await _willem_morning(), "jour 9 au matin, à l'entrepôt")
	var activities := StoryDirector.activities()
	assert_eq(activities.offered_by(&"willem"), &"baton")
	StoryDirector.set_mode(StoryPacing.SCENARIO)
	await frames(3)
	assert_eq(StoryDirector.mode(), StoryPacing.SCENARIO)
	assert_eq(activities.offered_by(&"willem"), &"", "scénarisé : rien n'est proposé")
	assert_false(activities.talk(&"willem"), "scénarisé : parler ne propose rien")
	StoryDirector.set_mode(StoryPacing.FREE)
	await frames(3)
	assert_eq(activities.offered_by(&"willem"), &"baton", "rendu en libre")


func test_pannibal_ambush_starts_and_escape_stops_it() -> void:
	var flags: Array[StringName] = [StoryPacing.FREE_FLAG]
	var done: Array[StringName] = []
	assert_true(await begin_day(4, flags, done, &"apres_midi", &"entrepot", COURTYARD))
	assert_true(await until(func() -> bool: return LifeDirector.npc(&"pannibal") != null, 5.0))
	var activities := StoryDirector.activities()
	activities.seed_value = 7
	assert_eq(activities.offered_by(&"pannibal"), &"embuscade", "Pannibal propose l'embuscade")
	var before := _story_state()
	assert_true(activities.start(&"embuscade"), "l'embuscade démarre")
	assert_eq(activities.running(), &"embuscade")
	assert_not_null(MiniGames.ambush(), "le jeu est dans la carte")
	await wait_seconds(0.5)
	await tap_key(KEY_ESCAPE)
	assert_true(await until(func() -> bool: return activities.running().is_empty(), 5.0))
	assert_true(
		await until(func() -> bool: return MiniGames.ambush() == null, 5.0),
		"l'embuscade est arrêtée"
	)
	assert_false(get_tree().paused, "pas de menu pause")
	assert_eq(_story_state(), before, "aucun drapeau du récit n'a changé")


func test_tiat_offers_the_ball_and_escape_stops_the_match() -> void:
	var flags: Array[StringName] = [StoryPacing.FREE_FLAG]
	var done: Array[StringName] = []
	assert_true(await begin_day(4, flags, done, &"apres_midi", &"entrepot", COURTYARD))
	assert_true(await until(func() -> bool: return LifeDirector.npc(&"tiat") != null, 5.0))
	var activities := StoryDirector.activities()
	assert_eq(activities.offered_by(&"tiat"), &"ballon", "Tiat propose le ballon")
	var before := _story_state()
	assert_true(activities.start(&"ballon"), "le match démarre")
	assert_not_null(MiniGames.ball_match(), "le match est au champ")
	await wait_seconds(0.5)
	assert_true(activities.busy(), "l'activité dure")
	await tap_key(KEY_ESCAPE)
	assert_true(await until(func() -> bool: return activities.running().is_empty(), 5.0))
	var match_now := MiniGames.ball_match()
	assert_true(match_now == null or not match_now.running, "le match est dispersé")
	assert_false(get_tree().paused, "pas de menu pause")
	assert_eq(_story_state(), before, "aucun drapeau du récit n'a changé")
