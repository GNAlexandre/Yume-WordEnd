extends "res://tests/stubs/s2_story_test.gd"
## (X-L1) Les propositions du mode libre dans la vraie partie (main.tscn, vrais appuis) : parler à
## Willem à la clairière le matin du jour 9 dit la proposition des bâtons, avec « Allons-y » et
## « Plus tard » ; « Plus tard » mène à la conversation libre et rien ne part pendant 20 s ;
## « Allons-y » lance j9_2_batons ; le ruban du récit ne paraît qu'à moins de 3,5 m ; le port,
## proposé par Nygglatho, s'enchaîne avec la lumière dans la nuit ; Pannibal propose la dernière
## embuscade (et y mène) ; un lieu propose sa scène par une invite.

const OFFER_GO := "Allons-y"
const OFFER_LATER := "Plus tard"
## Le départ des reprises sur la carte de l'entrepôt : Spawn, devant le porche.
const COURTYARD := Vector3(42.0, 0.2, 33.0)
## Un point du couloir du rez-de-chaussée.
const CORRIDOR := Vector3(17.5, 0.0, 6.8)

## Répliques reçues (dialogue_line) : [orateur, texte, choix].
var _lines: Array[Array] = []
var _dialogues: Array[StringName] = []


## Ces tests jouent le mode libre (la base M1 prend le mode scénarisé).
func mode_for_test() -> StringName:
	return StoryPacing.FREE


func before_each() -> void:
	super()
	_lines.clear()
	_dialogues.clear()
	listen(EventBus.dialogue_line, _on_line)
	listen(EventBus.dialogue_started, _on_dialogue_started)


func _on_line(speaker: String, text: String, choices: Array) -> void:
	_lines.append([speaker, text, choices])


func _on_dialogue_started(dialogue_id: StringName) -> void:
	_dialogues.append(dialogue_id)


func _signs() -> Control:
	return hud.get_node(^"InteractSigns") as Control


func _offer_text(scene_id: StringName) -> String:
	return StoryData.text(STORY_ISLAND, "offer", scene_id)


func _last_line() -> Array:
	return _lines.back() if not _lines.is_empty() else ["", "", []]


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


func _no_scene() -> bool:
	return StoryDirector.current_scene().is_empty() and not StoryDirector.is_playing()


func _willem_morning() -> bool:
	var done: Array[StringName] = [&"j9_1_porte"]
	var flags: Array[StringName] = [StoryPacing.FREE_FLAG]
	if not await begin_day(9, flags, done, &"matin", &"entrepot", COURTYARD):
		return false
	return await until(func() -> bool: return LifeDirector.npc(&"willem") != null, 5.0)


func test_willem_offers_the_sticks_in_the_glade() -> void:
	assert_true(await _willem_morning(), "jour 9 au matin, à l'entrepôt")
	assert_eq(StoryDirector.mode(), StoryPacing.FREE)
	assert_true(StoryDirector.offers().offered_scenes().has(&"j9_2_batons"), "les bâtons proposés")
	var willem := LifeDirector.npc(&"willem")
	assert_true(
		await until(func() -> bool: return InteractSign.is_story(willem), 2.0),
		"Willem porte le ruban du récit"
	)
	# Plus tard : la conversation libre ; rien ne part pendant 20 s, même à la clairière.
	assert_true(await _talk_to(&"willem"), "parler à Willem")
	assert_true(await until(func() -> bool: return dialogue_box.is_choosing(), 5.0), "deux choix")
	var line := _last_line()
	assert_eq(line[0], "Willem", "Willem parle")
	assert_eq(line[1], _offer_text(&"j9_2_batons"), "la proposition des bâtons")
	assert_eq(line[2], [OFFER_GO, OFFER_LATER], "« Allons-y » et « Plus tard »")
	assert_eq(StoryDirector.offers().proposing(), &"j9_2_batons")
	var lines_before := _lines.size()
	var dialogues_before := _dialogues.size()
	assert_true(await _choose(1), "« Plus tard »")
	assert_true(
		await until(func() -> bool: return _dialogues.size() > dialogues_before, 3.0),
		"la conversation libre s'ouvre"
	)
	assert_eq(_dialogues.back(), &"willem", "celle de Willem")
	assert_true(await until(func() -> bool: return _lines.size() > lines_before, 3.0))
	assert_ne(_last_line()[1], _offer_text(&"j9_2_batons"), "pas la proposition")
	assert_true(await wait_control(30.0), "conversation lue")
	assert_true(_no_scene(), "aucune scène")
	var glade := StoryDirector.stage().resolve(&"clairiere_centre").origin
	assert_lt(flat_distance(player.global_position, glade), 6.5, "dans la clairière (le piège)")
	var started := await until(func() -> bool: return not _no_scene(), 20.0)
	assert_false(started, "aucune scène pendant 20 s")
	assert_false(GameState.is_scene_done(&"j9_2_batons"), "toujours proposée")
	# Allons-y : les bâtons.
	assert_true(await _talk_to(&"willem"), "reparler à Willem")
	assert_true(await _choose(0), "« Allons-y »")
	assert_true(
		await until(func() -> bool: return StoryDirector.current_scene() == &"j9_2_batons", 5.0),
		"j9_2_batons démarre"
	)
	assert_false(InteractSign.is_story(willem), "plus de ruban pendant la scène")


func test_the_story_sign_shows_only_within_three_metres_and_a_half() -> void:
	assert_true(await _willem_morning(), "jour 9 au matin, à l'entrepôt")
	var willem := LifeDirector.npc(&"willem")
	assert_true(await until(func() -> bool: return InteractSign.is_story(willem), 2.0))
	assert_eq(InteractSign.kind_of(willem), InteractSign.STORY, "le ruban, pas la bulle")
	var signs := _signs()
	var shows := func() -> bool:
		return (
			signs.call(&"full_target") == willem
			or (signs.call(&"pale_targets") as Array).has(willem)
		)
	for distance: float in [6.0, 4.5]:
		var far := willem.global_position + Vector3(0.0, 0.0, distance)
		await place_player(current_map().to_local(far), Vector3.FORWARD)
		await frames(20)
		assert_gt(flat_distance(player.global_position, willem.global_position), 3.6)
		assert_false(shows.call(), "aucun ruban à %.1f m" % distance)
	var near := willem.global_position + Vector3(0.0, 0.0, 2.6)
	await place_player(current_map().to_local(near), Vector3.FORWARD)
	assert_true(await until(shows, 2.0), "le ruban à 2,6 m")
	for node: Node3D in signs.call(&"pale_targets"):
		assert_lte(
			flat_distance(node.global_position, player.global_position),
			3.5,
			"un signe pâle est à deux pas (%s)" % node.name
		)
	# En scénarisé, ni ruban ni proposition (loin de la clairière : son piège y partirait).
	await place_player(COURTYARD, Vector3.FORWARD)
	StoryDirector.set_mode(StoryPacing.SCENARIO)
	await frames(3)
	assert_false(InteractSign.is_story(willem), "scénarisé : pas de ruban")
	assert_eq(InteractSign.kind_of(willem), InteractSign.TALK, "la bulle d'avant")
	assert_eq(StoryDirector.offers().offered_scenes(), [] as Array[StringName])
	assert_eq(StoryDirector.offers().prompts(), [] as Array[StoryPrompt])
	StoryDirector.set_mode(StoryPacing.FREE)
	assert_true(await until(func() -> bool: return InteractSign.is_story(willem), 2.0), "rendu")


func test_the_port_offered_by_nygglatho_chains_into_the_night_light() -> void:
	assert_true(await new_game_from_menu(), "partie lancée depuis le menu")
	assert_eq(GameState.day, 1)
	assert_true(
		await until(func() -> bool: return LifeDirector.npc(&"nygglatho") != null, 5.0),
		"Nygglatho est là"
	)
	var nygglatho := LifeDirector.npc(&"nygglatho")
	var porch := StoryDirector.stage().resolve(&"porte_seuil").origin
	assert_lt(flat_distance(nygglatho.global_position, porch), 1.5, "sous le porche")
	assert_true(await until(func() -> bool: return InteractSign.is_story(nygglatho), 2.0))
	assert_true(await _talk_to(&"nygglatho"), "parler à Nygglatho")
	assert_true(await until(func() -> bool: return dialogue_box.is_choosing(), 5.0), "deux choix")
	assert_eq(_last_line()[1], _offer_text(&"j1_1_port"), "la proposition du port")
	assert_true(await _choose(0), "« Allons-y »")
	assert_true(
		await until(func() -> bool: return StoryDirector.current_scene() == &"j1_1_port", 5.0),
		"le port démarre"
	)
	assert_true(await play_until_done(&"j1_1_port", 120.0), "le port joué")
	assert_true(
		await until(func() -> bool: return StoryDirector.current_scene() == &"j1_2_lumiere", 5.0),
		"la lumière dans la nuit s'enchaîne"
	)


func test_pannibal_offers_the_last_ambush_and_leads_there() -> void:
	var done: Array[StringName] = [&"j12_1_derniere_journee"]
	var flags: Array[StringName] = [StoryPacing.FREE_FLAG]
	assert_true(
		await begin_day(12, flags, done, &"matin", &"entrepot_rdc", CORRIDOR), "jour 12 au matin"
	)
	assert_true(await until(func() -> bool: return LifeDirector.npc(&"pannibal") != null, 5.0))
	var anchor := StoryDirector.offers().anchor(&"j12_1_embuscade")
	assert_eq(anchor, {"npc": &"pannibal", "map": &"entrepot_rdc"}, "Pannibal la porte")
	var pannibal := LifeDirector.npc(&"pannibal")
	assert_true(await until(func() -> bool: return InteractSign.is_story(pannibal), 2.0))
	assert_true(await _talk_to(&"pannibal"), "parler à Pannibal")
	assert_true(await until(func() -> bool: return dialogue_box.is_choosing(), 5.0), "deux choix")
	assert_eq(_last_line()[0], "Pannibal")
	assert_eq(_last_line()[1], _offer_text(&"j12_1_embuscade"))
	assert_true(await _choose(0), "« Allons-y »")
	assert_true(
		await until(
			func() -> bool: return StoryDirector.current_scene() == &"j12_1_embuscade", 10.0
		),
		"la dernière embuscade démarre"
	)
	assert_eq(WorldManager.current_map(), &"entrepot", "dehors, sur la carte de la scène")


func test_a_place_offers_its_scene_by_a_prompt() -> void:
	var done: Array[StringName] = [&"j9_1_porte", &"j9_2_batons"]
	var flags: Array[StringName] = [StoryPacing.FREE_FLAG]
	assert_true(await begin_day(9, flags, done, &"apres_midi", &"entrepot", COURTYARD))
	var offers := StoryDirector.offers()
	assert_true(
		await until(func() -> bool: return not offers.prompts().is_empty(), 2.0), "une invite"
	)
	var prompt: StoryPrompt = null
	for candidate: StoryPrompt in offers.prompts():
		if candidate.scene_id == &"j9_3_cafe":
			prompt = candidate
	assert_not_null(prompt, "le café proposé sous le porche")
	if prompt == null:
		return
	assert_eq(prompt.point_name, "porte_seuil")
	assert_true(InteractSign.is_story(prompt), "au ruban du récit")
	assert_eq(InteractSign.kind_of(prompt), InteractSign.STORY)
	for choice: int in [1, 0]:
		await walk_to(prompt.global_position + Vector3(0.0, 0.0, 0.9), 0.4)
		player.set_aim_direction(Vector3.FORWARD, true)
		await frames(4)
		assert_eq(player.current_interactable(), prompt, "l'invite devant elle")
		await tap_key(KEY_E)
		assert_true(await until(func() -> bool: return dialogue_box.is_choosing(), 5.0))
		assert_eq(_last_line()[0], "", "un lieu : sans orateur")
		assert_eq(_last_line()[1], _offer_text(&"j9_3_cafe"))
		assert_true(await _choose(choice))
		if choice == 1:
			assert_true(await wait_control(5.0), "« Plus tard » : rien")
			assert_false(await until(func() -> bool: return not _no_scene(), 2.0), "pas de scène")
	assert_true(
		await until(func() -> bool: return StoryDirector.current_scene() == &"j9_3_cafe", 5.0),
		"« Allons-y » : le café"
	)
