extends "res://tests/stubs/e6_story_test.gd"
## (S1b) Les scènes réécrites sur les vraies cartes, de bout en bout dans la vraie partie
## (main.tscn, vrais appuis) : chacune joue, ses présents sont à leur place, aucun carton (sauf
## celui du titre, au jour 1).
## - j1_1_port : la séquence du port (Willem descend de la passerelle, le passeur, le panneau aux
##   flèches rouges), vue sans la passer, puis la coupe sur le porche de l'entrepôt.
## - j3_2_chemin : du sentier à la ville haute par la vraie sortie, le passant qui change de
##   trottoir, jusqu'à la porte du snack-bar.
## - j3_3_snack : le snack-bar (Willem au comptoir, le cuistot à sa poêle, les aînées à la table),
##   puis le retour à pied, de la ville à l'entrepôt, et le coucher du jour 3.

const DAYS_1_2 := [
	"j1_1_port",
	"j1_2_lumiere",
	"j1_2_embuscade",
	"j1_3_intrus",
	"j1_4_chemin",
	"j1_5_premiers_pas",
	"j1_6_diner",
	"j1_7_chambre",
	"j2_1_matin",
	"j2_2_fuite",
	"j2_3_fenetre",
]

var _cards: Array[String] = []


func before_each() -> void:
	super()
	_cards.clear()
	if not StoryDirector.runner().step_started.is_connected(_on_step):
		StoryDirector.runner().step_started.connect(_on_step)


func after_each() -> void:
	if StoryDirector.runner().step_started.is_connected(_on_step):
		StoryDirector.runner().step_started.disconnect(_on_step)
	super()


func _on_step(_index: int, kind: String) -> void:
	if kind == "card":
		var overlay := StoryDirector.stage().overlay()
		await get_tree().process_frame
		_cards.append(str(overlay.call(&"card_text")) if is_instance_valid(overlay) else "?")


## Une partie reprise (« Continuer ») au jour day, au créneau slot, sur map en at, les scènes
## done jouées.
func _resume(day: int, slot: StringName, map_id: StringName, at: Vector3, done: Array) -> bool:
	GameState.reset()
	var state := GameState.to_dict()
	state["skin"] = "chtholly"
	state["day"] = day
	state["slot"] = String(slot)
	state["moment"] = String(LifeSlots.moment_of(slot))
	state["map"] = String(map_id)
	state["island"] = "ile_68"
	state["position"] = [at.x, at.y, at.z]
	state["scenes_done"] = done
	var calendar := {}
	for past: int in range(1, day):
		calendar[str(past)] = ""
	state["calendar"] = calendar
	GameState.from_dict(state)
	SaveManager.save()
	await open_main()
	await click_center()
	await click(menu_button("ContinueButton"))
	return await wait_for_game()


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


## Distance au sol entre deux PNJ (ou un PNJ et le joueur : &"player").
func _apart(a: StringName, b: StringName) -> float:
	var at_a := player.global_position if a == &"player" else LifeDirector.actor(a).position()
	var at_b := player.global_position if b == &"player" else LifeDirector.actor(b).position()
	return _flat(at_a, at_b)


func test_j1_1_port_on_the_port_map() -> void:
	assert_true(await new_game_from_menu(), "nouvelle partie")
	assert_true(
		await until(func() -> bool: return WorldManager.current_map() == &"port", 15.0),
		"la séquence se joue au port"
	)
	assert_eq(StoryDirector.current_scene(), &"j1_1_port")
	assert_true(await until(func() -> bool: return LifeDirector.actor(&"willem") != null, 5.0))
	var willem := LifeDirector.actor(&"willem")
	var ship_foot := StoryDirector.stage().resolve(&"navire_quai").origin
	assert_lt(_flat(willem.position(), ship_foot), 2.5, "Willem paraît sur la passerelle")
	assert_not_null(LifeDirector.actor(&"ferryman"), "le passeur à côté de lui")
	var at_sign := StoryDirector.stage().resolve(&"panneau_sud").origin
	var saw_sign := [false]
	var watch := func() -> bool:
		var actor := LifeDirector.actor(&"willem")
		if actor != null and WorldManager.current_map() == &"port":
			if _flat(actor.position(), at_sign) < 0.8:
				saw_sign[0] = true
		return GameState.is_scene_done(&"j1_1_port")
	assert_true(await read_until(watch, 90.0), "la séquence va au bout")
	assert_true(saw_sign[0], "Willem s'arrête devant le panneau aux flèches rouges")
	assert_eq(_cards.size(), 1, "un seul carton : %s" % [_cards])
	assert_string_contains(_cards[0], "volume 1")
	assert_true(
		await until(func() -> bool: return StoryDirector.current_scene() == &"j1_2_lumiere", 10.0)
	)
	assert_eq(WorldManager.current_map(), &"entrepot", "coupe sur le porche de l'entrepôt")


func test_j3_2_chemin_from_the_path_to_town() -> void:
	var done := DAYS_1_2.duplicate()
	done.append("j3_1_information")
	assert_true(await _resume(3, &"matin", &"sentier", Vector3(2.5, 0.2, 24.0), done))
	assert_true(
		await until(func() -> bool: return StoryDirector.current_scene() == &"j3_2_chemin", 10.0)
	)
	# Sur le sentier : elles rattrapent {player} et bavardent, à 1 m au moins l'une de l'autre.
	assert_true(await until(func() -> bool: return dialogue_box.is_open(), 20.0), "le bavardage")
	assert_gt(_apart(&"ithea", &"player"), 1.0)
	assert_gt(_apart(&"nephren", &"player"), 1.0)
	assert_gt(_apart(&"ithea", &"nephren"), 1.0)
	assert_eq(DialogueBox.presentation(), DialogueBox.PRESENTATION_BANDEAU, "le joueur est tenu")
	assert_true(await wait_control())
	assert_eq(StoryDirector.hint(), "Le snack-bar est sur la rue du café, en ville.")
	assert_has(StoryDirector.stage().followers(), &"ithea")
	# La vraie sortie du sentier vers la ville haute, à pied.
	assert_true(await take_exit(&"ville_haute", 90.0), "la ville haute")
	assert_true(
		await until(func() -> bool: return LifeSlots.current() == &"midi", 5.0), "midi en ville"
	)
	# Le passant change de trottoir.
	var crossed := [false]
	var passant_seen := func() -> bool:
		var cat := LifeDirector.actor(&"villager_cat_m")
		if cat != null and cat.position().z > 14.5:
			crossed[0] = true
		return dialogue_box.is_open() and StoryDirector.runner().current_step() == "dialogue"
	assert_true(await until(passant_seen, 40.0), "le passant, puis la réplique d'Ithea")
	assert_true(crossed[0], "il passe sur le trottoir sud")
	assert_null(LifeDirector.actor(&"villager_cat_m"), "parti vers le sentier")
	assert_gt(_apart(&"ithea", &"player"), 1.0)
	assert_gt(_apart(&"nephren", &"player"), 1.0)
	assert_true(await wait_control(40.0))
	# Jusqu'à la porte du snack-bar : la scène suivante prend la suite.
	assert_true(await walk_to_point(&"porte_snack", 1.2, 60.0))
	assert_true(await until(func() -> bool: return GameState.is_scene_done(&"j3_2_chemin"), 10.0))
	assert_eq(StoryDirector.current_scene(), &"j3_3_snack")
	assert_eq(_cards, [] as Array[String], "aucun carton")


func test_j3_3_snack_and_back_home() -> void:
	var done := DAYS_1_2.duplicate()
	done.append_array(["j3_1_information", "j3_2_chemin"])
	assert_true(await _resume(3, &"midi", &"ville_haute", Vector3(30.0, 1.2, 32.0), done))
	assert_false(StoryDirector.is_playing())
	assert_true(await walk_to_point(&"porte_snack", 1.2, 40.0))
	assert_true(
		await until(func() -> bool: return WorldManager.current_map() == &"ville_snack", 20.0),
		"elles entrent au snack-bar"
	)
	assert_true(await until(func() -> bool: return dialogue_box.is_open(), 15.0))
	var places := StoryDirector.stage().places
	var vendor := LifeDirector.actor(&"snack_vendor")
	assert_not_null(vendor, "le cuistot")
	assert_lt(_flat(vendor.position(), places.point(&"snack_vendor", 0).origin), 0.3)
	assert_eq(vendor.outfit, &"travail", "à sa poêle")
	var willem := LifeDirector.actor(&"willem")
	assert_lt(_flat(willem.position(), places.point(&"snack_tabouret", 0).origin), 0.3)
	# La table : les aînées à leurs places, {player} au bout ; la question d'Ithea.
	assert_true(
		await read_until(
			func() -> bool: return dialogue_box.is_open() and dialogue_box.is_choosing(), 40.0
		)
	)
	var ithea := LifeDirector.actor(&"ithea")
	var nephren := LifeDirector.actor(&"nephren")
	assert_lt(_flat(ithea.position(), places.point(&"snack_table_nord", 0).origin), 0.5)
	assert_lt(_flat(nephren.position(), places.point(&"snack_table_nord_est", 0).origin), 0.5)
	for pair: Array in [[&"ithea", &"nephren"], [&"nephren", &"player"], [&"willem", &"player"]]:
		assert_gt(_apart(pair[0], pair[1]), 0.95, "%s et %s à 1 m" % pair)
	assert_true(
		await play_until_done(&"j3_3_snack", 60.0, {"Une fois, sur l'île n° 28.": 1}),
		"la scène va au bout"
	)
	assert_eq(LifeSlots.current(), &"apres_midi", "l'après-midi libre")
	assert_eq(_cards, [] as Array[String], "aucun carton")
	assert_null(LifeDirector.actor(&"willem"), "Willem est rentré")
	assert_not_null(LifeDirector.actor(&"snack_vendor"), "le cuistot reste à sa poêle")
	# Le retour, à pied : la porte, la ville, le sentier, l'entrepôt ; le soir, le lit.
	assert_true(await wait_control())
	assert_true(await take_exit(&"ville_haute", 30.0), "dehors")
	assert_true(await take_exit(&"sentier", 120.0), "le sentier")
	assert_true(await take_exit(&"entrepot", 120.0), "l'entrepôt")
	assert_true(StoryDirector.can_rest())
	await StoryDirector.pass_time()
	assert_eq(LifeSlots.current(), &"soir")
	assert_eq(StoryDirector.hint(), "La journée est finie. Ton lit t'attend.")
	assert_true(await take_exit(&"entrepot_rdc", 60.0))
	assert_true(await take_exit(&"entrepot_etage", 60.0))
	assert_true(await use_prompt(StoryPrompt.ROLE_SLEEP), "« Dormir »")
	assert_true(await until(func() -> bool: return GameState.day == 4, 15.0), "le jour 4")
