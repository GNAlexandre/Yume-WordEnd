extends GutTest
## (X-L4) Les jours libres (StoryResolve, PLAN.md « (X) Exploration libre : le rythme ») : le
## coucher et le temps qui passe sans condition de scènes en libre (inchangés en scénarisé), les
## scènes laissées passer réglées au coucher sans être jouées (étapes d'état seulement, clé
## « skip », jeux perdus, chaînes « after » dans le bon ordre, passee_<id>), la ligne du calendrier
## (le jour vécu ou un texte libre), « À vivre aujourd'hui », pas d'indice impératif en libre.

const ISLAND := &"ile_68"
const CALENDAR := preload("res://src/ui/calendar.tscn")
const SLOTS_BUT_NIGHT: Array[StringName] = [&"aube", &"matin", &"midi", &"apres_midi", &"soir"]

var _resolve: StoryResolve


func before_each() -> void:
	GameState.reset()
	GameState.day = 1
	# L'île du récit (StoryDirector : l'île de la carte de départ, au chargement d'une partie).
	EventBus.game_loaded.emit()
	StoryPacing.store(StoryPacing.FREE)
	_resolve = StoryDirector.resolver()


func after_each() -> void:
	GameState.reset()


## Le jour day au créneau slot, les scènes des jours d'avant faites (jouées).
func _at(day: int, slot: StringName, before_done: bool = true) -> void:
	GameState.day = day
	_slot(slot)
	if not before_done:
		return
	for scene_id: StringName in StoryData.scene_ids(ISLAND):
		if _day_of(scene_id) < day:
			GameState.mark_scene_done(scene_id)


## Le créneau et son moment (LifeSlots.current lit les deux).
func _slot(slot: StringName) -> void:
	GameState.moment = LifeSlots.moment_of(slot)
	GameState.slot = slot


func _day_of(scene_id: StringName) -> int:
	return DialogueRunner.day_range(StoryData.scene(ISLAND, scene_id)["day"]).y


func test_free_rest_and_sleep_need_no_scene() -> void:
	for day: int in [1, 2, 7, 11, 12, 13]:
		_at(day, &"aube", false)
		for slot: StringName in SLOTS_BUT_NIGHT:
			_slot(slot)
			assert_true(StoryDirector.can_rest(), "jour %d, %s : le temps passe" % [day, slot])
			assert_eq(
				StoryDirector.can_sleep(),
				slot == &"soir",
				"jour %d, %s : on se couche le soir ou la nuit" % [day, slot]
			)
		_slot(&"nuit")
		assert_false(StoryDirector.can_rest(), "jour %d : la nuit, il faut dormir" % day)
		assert_true(StoryDirector.can_sleep(), "jour %d : la nuit, on dort" % day)
	assert_eq(GameState.scenes_done(), [] as Array[StringName], "aucune scène jouée")


func test_scenario_rules_are_unchanged() -> void:
	StoryPacing.store(StoryPacing.SCENARIO)
	_at(2, &"soir", false)
	assert_false(StoryDirector.can_sleep(), "scénarisé : les scènes du jour d'abord")
	_at(2, &"aube", false)
	assert_false(StoryDirector.can_rest(), "scénarisé : plafonné par la prochaine scène clé")
	_at(12, &"soir")
	for scene_id: StringName in StoryData.scene_ids(ISLAND):
		GameState.mark_scene_done(scene_id)
	assert_false(StoryDirector.can_sleep(), "scénarisé : on ne dort pas au jour du départ")
	StoryPacing.store(StoryPacing.FREE)
	assert_true(StoryDirector.can_sleep(), "libre : le jour du départ se dort")


func test_a_passed_scene_applies_its_state_only() -> void:
	_at(8, &"matin")
	for scene_id: StringName in [&"j8_1_reveil", &"j8_2_archives"]:
		GameState.mark_scene_done(scene_id)
	assert_true(_resolve.resolve_scene(ISLAND, &"j8_3_duel"), "réglée")
	assert_true(GameState.is_scene_done(&"j8_3_duel"), "faite")
	assert_true(GameState.has_flag(&"passee_j8_3_duel"), "passee_<id>")
	assert_true(StoryResolve.is_passed(&"j8_3_duel"))
	assert_true(GameState.has_flag(&"j8_duel_reprise"), "le choix sauté : la clé « skip »")
	assert_false(GameState.has_flag(&"j8_duel_joue"), "le duel n'a pas été joué")
	assert_eq(GameState.day, 8, "ni jour suivant")
	assert_eq(LifeSlots.current(), &"matin", "ni créneau")
	assert_false(_resolve.resolve_scene(ISLAND, &"j8_3_duel"), "déjà faite")
	assert_false(_resolve.resolve_scene(ISLAND, &"inconnue"), "inconnue")


func test_a_passed_game_is_not_won() -> void:
	_at(11, &"apres_midi")
	GameState.set_flag(&"j11_grues")
	assert_true(_resolve.resolve_scene(ISLAND, &"j11_4_seniorious"))
	assert_false(GameState.has_flag(&"j11_grues"), "l'entraînement pas joué n'est pas réussi")


func test_a_passed_ship_scene_leaves_the_ship_gone() -> void:
	_at(7, &"midi")
	ShipControl.pose(&"transport_garde", &"deploy_gangway")
	assert_true(_resolve.resolve_scene(ISLAND, &"j7_4_port"))
	assert_false(ShipControl.is_docked(&"transport_garde"), "le navire est reparti")
	assert_false(ShipControl.has_flag(&"transport_garde", &"gangway"), "passerelle rentrée")


func test_sleeping_resolves_the_day_in_after_order_and_writes_a_free_line() -> void:
	_at(10, &"nuit")
	_resolve.before_sleep(ISLAND, 10)
	for scene_id: StringName in StoryData.scene_ids(ISLAND):
		if _day_of(scene_id) == 10:
			assert_true(GameState.is_scene_done(scene_id), "%s réglée" % scene_id)
			assert_true(StoryResolve.is_passed(scene_id), "%s passée" % scene_id)
	# j10_4_toit vient après j10_5_tour : réglée quand même, après lui.
	var done := GameState.scenes_done()
	assert_gt(done.find(&"j10_4_toit"), done.find(&"j10_5_tour"), "l'ordre des « after »")
	assert_eq(_resolve.passed_on(ISLAND, 10).size(), 5, "cinq scènes passées au jour 10")
	assert_eq(_resolve.lived_on(ISLAND, 10), [] as Array[StringName])
	assert_eq(GameState.calendar().get(10, &"x"), StoryResolve.FREE_LINE, "ligne libre")
	assert_eq(StoryDirector.calendar_line(10), "Une journée à moi, à marcher sur l'île.")
	assert_eq(_resolve.due(ISLAND, 10), [] as Array[StringName], "plus rien à régler")


func test_a_lived_day_keeps_its_own_line() -> void:
	_at(1, &"soir", false)
	for scene_id: StringName in [&"j1_1_port", &"j1_2_lumiere"]:
		GameState.mark_scene_done(scene_id)
	_resolve.before_sleep(ISLAND, 1)
	assert_true(StoryResolve.is_passed(&"j1_7_chambre"), "le reste du jour 1 passé")
	assert_false(StoryResolve.is_passed(&"j1_1_port"), "le port vécu")
	assert_eq(_resolve.lived_on(ISLAND, 1).size(), 2)
	assert_false(GameState.has_calendar_line(1), "le directeur écrit la ligne du jour")


func test_past_days_are_resolved_too() -> void:
	_at(3, &"soir", false)
	_resolve.before_sleep(ISLAND, 3)
	for scene_id: StringName in StoryData.scene_ids(ISLAND):
		var day := _day_of(scene_id)
		assert_eq(GameState.is_scene_done(scene_id), day <= 3, "%s (jour %d)" % [scene_id, day])


func test_the_departure_day_is_resolved_with_its_epilogue() -> void:
	_at(12, &"nuit")
	_resolve.before_sleep(ISLAND, 12)
	assert_true(GameState.has_flag(&"acte1_fini"), "la fin de l'acte")
	assert_true(GameState.has_flag(&"j12_voir_epilogue"), "la clé « skip » du départ")
	assert_true(StoryResolve.is_passed(&"j12_3_epilogue"), "l'épilogue suit")
	assert_false(GameState.has_flag(&"j12_embuscade_gagnee"), "l'embuscade pas jouée")
	assert_eq(GameState.calendar().get(12, &"x"), &"depart", "la ligne choisie par la scène")
	_at(13, &"nuit", false)
	_resolve.before_sleep(ISLAND, 13)
	assert_eq(GameState.calendar().get(13, &"x"), StoryResolve.FREE_LINE, "jour libre")


## Ce que le calendrier dit d'une scène : le texte de sa proposition (X-L1, clé offer.text), sinon
## son titre.
func _offer_or_title(scene_id: StringName) -> String:
	var data := StoryData.scene(ISLAND, scene_id)
	var title := str(data.get("title", scene_id))
	var offer: Variant = data.get("offer")
	if offer is Dictionary and (offer as Dictionary).has("text"):
		return StoryData.text(ISLAND, str(offer["text"]), scene_id, title)
	return title


func test_today_lists_the_day_scenes_to_live() -> void:
	_at(2, &"aube")
	assert_eq(_resolve.today_scenes(ISLAND), [&"j2_1_matin"] as Array[StringName])
	assert_eq(_resolve.scene_label(ISLAND, &"j2_1_matin"), _offer_or_title(&"j2_1_matin"))
	GameState.mark_scene_done(&"j2_1_matin")
	assert_eq(_resolve.today_scenes(ISLAND), [&"j2_2_fuite"] as Array[StringName])
	assert_eq(
		_resolve.scene_label(ISLAND, &"j2_2_fuite"),
		"%s (le matin)" % _offer_or_title(&"j2_2_fuite"),
		"plus tard"
	)
	_slot(&"soir")
	assert_eq(_resolve.today_scenes(ISLAND), [] as Array[StringName], "son créneau est passé")


func test_no_imperative_hint_in_free_mode() -> void:
	_at(2, &"aube")
	StoryDirector.refresh()
	assert_eq(StoryDirector.hint(), "", "libre : pas d'indice hors scène")
	_at(4, &"soir")
	for scene_id: StringName in [&"j4_1_cuisine", &"j4_2_diner"]:
		GameState.mark_scene_done(scene_id)
	StoryDirector.refresh()
	assert_eq(StoryDirector.hint(), "", "libre : pas de « Ton lit t'attend »")
	# Témoin : le même soir en scénarisé, l'indice du coucher.
	StoryPacing.store(StoryPacing.SCENARIO)
	StoryDirector.refresh()
	assert_eq(StoryDirector.hint(), "La journée est finie. Ton lit t'attend.", "scénarisé")
	StoryPacing.store(StoryPacing.FREE)
	StoryDirector.refresh()
	assert_eq(StoryDirector.hint(), "")


## Le calendrier (src/ui/calendar.tscn) dans un écran de 1280 × 720, ouvert et relu.
func _calendar() -> Control:
	var screen := SubViewport.new()
	screen.size = Vector2i(1280, 720)
	screen.disable_3d = true
	add_child_autofree(screen)
	var frame := Control.new()
	frame.size = Vector2(1280, 720)
	screen.add_child(frame)
	var calendar: Control = CALENDAR.instantiate()
	frame.add_child(calendar)
	return calendar


func _show(calendar: Control) -> void:
	calendar.call(&"refresh")
	calendar.show()
	for _i in 3:
		await get_tree().process_frame


func test_the_free_calendar_lists_today_and_marks_passed_scenes() -> void:
	for day: int in [1, 2]:
		_at(day, &"soir", false)
		_resolve.before_sleep(ISLAND, day)
	_at(3, &"aube", false)
	var calendar := _calendar()
	await _show(calendar)
	var lines: PackedStringArray = calendar.call(&"shown_lines")
	assert_eq(lines.size(), 2, "deux jours écrits")
	assert_eq(lines[0], "Jour 1 — Une journée à moi, à marcher sur l'île.")
	var passed: PackedStringArray = calendar.call(&"passed_lines")
	assert_eq(passed.size(), 2, "les scènes passées des deux jours")
	assert_true(passed[0].begins_with("Laissé passer : L'homme au port, "), passed[0])
	var today: PackedStringArray = calendar.call(&"today_entries")
	var label := _resolve.scene_label(ISLAND, &"j3_1_information")
	assert_eq(today, PackedStringArray([label]), "à vivre : %s" % [today])
	assert_true(str(calendar.call(&"free_today_text")).begins_with("À vivre aujourd'hui\n"))
	var page: Rect2 = calendar.call(&"page_rect")
	assert_lte(page.size.y, 640.5, "la page reste dans l'écran (%s)" % page)
	# Le soir, plus rien à vivre ce jour-là.
	_at(3, &"nuit", false)
	await _show(calendar)
	assert_eq(calendar.call(&"today_entries"), PackedStringArray())
	assert_string_contains(str(calendar.call(&"free_today_text")), "l'île est à toi")


func test_the_scenario_calendar_is_unchanged() -> void:
	_at(3, &"aube", false)
	_resolve.before_sleep(ISLAND, 2)
	StoryPacing.store(StoryPacing.SCENARIO)
	var calendar := _calendar()
	await _show(calendar)
	assert_eq(calendar.call(&"passed_lines"), PackedStringArray(), "pas de scènes passées")
	assert_eq(calendar.call(&"free_today_text"), "", "pas d'« À vivre aujourd'hui »")
	assert_false((calendar.get_node(^"%FreeToday") as Control).visible)


func test_free_days_go_on_after_the_departure() -> void:
	for day: int in range(1, 14):
		_at(day, &"nuit", false)
		_resolve.before_sleep(ISLAND, day)
		if not GameState.has_calendar_line(day):
			GameState.write_calendar(day)
	_at(14, &"aube", false)
	var calendar := _calendar()
	await _show(calendar)
	var cells := calendar.get_node(^"%Days").get_children()
	assert_eq(cells.size(), 12, "douze cases")
	assert_eq(cells[0].get_meta(&"day"), 3, "du jour 3")
	assert_eq(cells[11].get_meta(&"day"), 14, "au jour 14")
	assert_eq((calendar.call(&"shown_lines") as PackedStringArray).size(), 13)
	assert_eq(calendar.call(&"departure_text"), "", "plus de départ à compter")
	var page: Rect2 = calendar.call(&"page_rect")
	assert_lte(page.size.y, 640.5, "la page reste dans l'écran (%s)" % page)
