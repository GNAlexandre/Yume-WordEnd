extends "res://tests/stubs/s2_story_test.gd"
## (X-L4) Les jours libres dans la vraie partie (main.tscn, vrais appuis) : une nouvelle partie en
## libre où l'on ne joue rien ; on laisse passer le temps par les invites (à toute heure sauf la
## nuit, quel que soit l'état des scènes) et l'on dort onze fois par l'invite du lit : le jour 12
## arrive sans erreur, les scènes des jours 1 à 11 sont réglées (faites, passee_<id>), le
## calendrier a onze lignes et liste « À vivre aujourd'hui », la vie se repeuple à chaque réveil,
## aucun indice impératif ne paraît ; puis le jour 12 se dort aussi, et le jour 13 commence.

var _hints: Array[String] = []
var _wakes: Array[Vector2i] = []


## Ces tests jouent le mode libre (la base M1 prend le mode scénarisé).
func mode_for_test() -> StringName:
	return StoryPacing.FREE


func _on_hint(text: String) -> void:
	if not text.is_empty():
		_hints.append(text)


func _on_slot(slot: StringName) -> void:
	if slot == &"aube":
		_wakes.append(Vector2i(GameState.day, 0))


func _hint_shown() -> String:
	var node := get_tree().get_first_node_in_group(&"story_hint")
	return str(node.call(&"shown_text")) if node != null else ""


func _calendar() -> Control:
	return get_tree().get_first_node_in_group(&"story_calendar") as Control


## Le temps passe par l'invite du lit jusqu'au soir ; à chaque créneau, can_rest est vrai.
func _rest_to_evening() -> bool:
	for _use in 6:
		assert_true(
			StoryDirector.can_rest(),
			"jour %d, %s : le temps passe" % [GameState.day, LifeSlots.current()]
		)
		if LifeSlots.current() == &"soir":
			return true
		assert_false(StoryDirector.can_sleep(), "pas encore le soir")
		if not await rest_until(LifeSlots.next(LifeSlots.current())):
			return false
	return LifeSlots.current() == &"soir"


## La vie de la chambre au réveil : chaque PNJ dont la ligne de l'aube est ici y est, personne
## n'est retenu par une scène.
func _life_matches_the_dawn() -> bool:
	var map_id := WorldManager.current_map()
	for npc_id: StringName in LifeData.cast():
		var line := LifeData.line_for(npc_id, &"aube", GameState.day)
		if line.get("map", &"") == map_id and LifeDirector.actor(npc_id) == null:
			return false
	return LifeDirector.reserved().is_empty()


func test_eleven_nights_without_playing_lead_to_day_twelve_then_thirteen() -> void:
	StoryDirector.hint_changed.connect(_on_hint)
	LifeDirector.slot_changed.connect(_on_slot)
	assert_true(await new_game_from_menu(), "partie lancée depuis le menu")
	assert_true(await wait_control(), "la main")
	assert_eq(StoryDirector.mode(), StoryPacing.FREE)
	assert_eq(GameState.day, 1)
	assert_eq(LifeSlots.current(), &"soir", "le soir du jour 1")
	# Le soir du jour 1 : le temps passe encore (jusqu'à la nuit), au banc du porche.
	assert_true(StoryDirector.can_rest(), "le soir, le temps passe")
	assert_true(StoryDirector.can_sleep(), "le soir, on peut se coucher")
	assert_true(await rest_here_until(&"nuit"), "la nuit, au banc du porche")
	assert_false(StoryDirector.can_rest(), "la nuit, il faut dormir")
	assert_true(StoryDirector.can_sleep(), "la nuit, on dort")
	assert_true(await go_upstairs(), "à la chambre")
	assert_true(await sleep_by_prompt(), "première nuit")
	# Jours 2 à 11 : du réveil au soir, puis au lit.
	while GameState.day < 12:
		var day := GameState.day
		assert_true(await wait_control(), "jour %d : la main au réveil" % day)
		assert_eq(LifeSlots.current(), &"aube", "jour %d : l'aube" % day)
		assert_true(
			await until(_life_matches_the_dawn, 5.0), "jour %d : la vie de l'aube est là" % day
		)
		assert_true(await _rest_to_evening(), "jour %d : jusqu'au soir" % day)
		assert_eq(_hint_shown(), "", "jour %d : aucun indice à l'écran" % day)
		assert_true(await sleep_by_prompt(), "jour %d : au lit" % day)
		if GameState.day != day + 1:
			break
	assert_eq(GameState.day, 12, "le jour 12, en ne jouant rien")
	assert_true(await wait_control(), "la main au jour 12")
	# Les scènes des jours 1 à 11 réglées sans être jouées ; celles du jour 12 à vivre.
	for scene_id: StringName in StoryData.scene_ids(ISLAND):
		var data := StoryData.scene(ISLAND, scene_id)
		var last := DialogueRunner.day_range(data["day"]).y
		assert_eq(GameState.is_scene_done(scene_id), last <= 11, "%s faite" % scene_id)
		assert_eq(StoryResolve.is_passed(scene_id), last <= 11, "%s passée" % scene_id)
	assert_eq(GameState.calendar().size(), 11, "onze lignes au calendrier")
	assert_eq(GameState.calendar()[3], StoryResolve.FREE_LINE, "une journée libre")
	for day: int in range(2, 13):
		assert_true(_wakes.has(Vector2i(day, 0)), "la vie se repeuple au réveil du jour %d" % day)
	# Le calendrier, ouvert à la touche (Tab).
	await tap_key(KEY_TAB)
	var calendar := _calendar()
	assert_true(await until(func() -> bool: return calendar.call(&"is_open"), 3.0))
	var lines: PackedStringArray = calendar.call(&"shown_lines")
	assert_eq(lines.size(), 11, "onze lignes affichées")
	assert_eq(lines[0], "Jour 1 — Une journée à moi, à marcher sur l'île.")
	assert_eq((calendar.call(&"passed_lines") as PackedStringArray).size(), 11)
	var today: PackedStringArray = calendar.call(&"today_entries")
	var first := StoryDirector.resolver().scene_label(ISLAND, &"j12_1_derniere_journee")
	assert_eq(today, PackedStringArray([first]), "à vivre : %s" % [today])
	await tap_key(KEY_TAB)
	assert_true(await until(func() -> bool: return not calendar.call(&"is_open"), 3.0))
	# Le jour 12 se dort aussi : le jour 13 commence.
	assert_true(await _rest_to_evening(), "jour 12 : jusqu'au soir")
	assert_true(await sleep_by_prompt(), "jour 12 : au lit")
	assert_eq(GameState.day, 13, "le jour 13, un jour libre")
	assert_true(await wait_control(), "la main au jour 13")
	assert_true(GameState.has_flag(&"acte1_fini"), "l'acte réglé")
	assert_eq(GameState.calendar()[12], &"depart", "la ligne du départ")
	assert_true(_wakes.has(Vector2i(13, 0)), "la vie se repeuple au jour 13")
	assert_true(await until(_life_matches_the_dawn, 5.0), "la vie de l'aube au jour 13")
	assert_true(StoryDirector.can_rest(), "le temps passe au jour 13")
	# Aucun indice impératif de toute la partie.
	assert_eq(_hints, [] as Array[String], "aucun indice : %s" % [_hints])
	StoryDirector.hint_changed.disconnect(_on_hint)
	LifeDirector.slot_changed.disconnect(_on_slot)
