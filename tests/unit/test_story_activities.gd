extends GutTest
## (X-L6) Les jeux à la demande du mode libre, sans lancer le jeu : le fichier des activités
## (data/activities/ile_68.json) est valide, chaque activité a son PNJ, sa carte, sa place et ses
## textes ; les règles de disponibilité (carte, place, occupation, conditions) ; les lignes de
## Willem en libre (la clairière, le marais, la cour) ; le ballon n'est jamais proposé quand la vie
## joue déjà (jours 5, 6, 9 à 12) ; les variantes d'options.

const ISLAND := &"ile_68"


func before_each() -> void:
	StoryData.use_root("")
	StoryActivities.clear_cache()
	GameState.reset()
	LifeData.enter_island(ISLAND)


func after_each() -> void:
	StoryData.use_root("")
	StoryActivities.clear_cache()
	GameState.reset()
	LifeData.enter_island(&"")


## Partie libre où les scènes données sont faites.
func _free_game(done: Array[StringName] = []) -> void:
	GameState.reset()
	StoryPacing.store(StoryPacing.FREE)
	for scene_id: StringName in done:
		GameState.mark_scene_done(scene_id)


func _offered(npc_id: StringName, day: int, slot: StringName) -> StringName:
	var line := LifeData.line_for(npc_id, slot, day)
	var all_data := StoryActivities.all(ISLAND)
	var ids: Array = all_data.keys()
	ids.sort()
	for activity_id: Variant in ids:
		var data: Dictionary = all_data[activity_id]
		if str(data["npc"]) == String(npc_id) and StoryActivities.available(data, line, day, slot):
			return StringName(str(activity_id))
	return &""


func test_the_file_is_valid_and_complete() -> void:
	var text := FileAccess.get_file_as_string(StoryActivities.path_of(ISLAND))
	var raw: Variant = JSON.parse_string(text)
	assert_eq(StoryActivities.problems_of(raw), PackedStringArray(), "aucun problème")
	var all_data := StoryActivities.all(ISLAND)
	assert_eq(all_data.size(), 5, "cinq activités")
	for game: String in StoryActivities.GAMES:
		var found := false
		for data: Dictionary in all_data.values():
			found = found or data["game"] == game
		assert_true(found, "une activité pour le jeu %s" % game)
	for activity_id: StringName in all_data:
		var data: Dictionary = all_data[activity_id]
		var npc_id := StringName(str(data["npc"]))
		assert_not_null(LifeData.find_npc(npc_id), "%s : le PNJ %s existe" % [activity_id, npc_id])
		var map_id := StringName(str(data["map"]))
		assert_true(Map.exists(map_id), "%s : %s est une carte" % [activity_id, map_id])
		if data.has("place"):
			assert_true(
				LifeData.map_places(map_id).has(str(data["place"])),
				"%s : %s est une place de %s" % [activity_id, data["place"], map_id]
			)
		for scene_id: String in StoryOffers._names(data.get("after", [])):
			assert_false(StoryData.scene(ISLAND, StringName(scene_id)).is_empty(), scene_id)
		assert_ne(
			StoryData.text(ISLAND, StoryActivities.text_key(activity_id, "offer")),
			"",
			"%s : le texte de la proposition" % activity_id
		)
		assert_ne(
			StoryData.text(ISLAND, StoryActivities.text_key(activity_id, "result_stopped")),
			"",
			"%s : le texte de l'arrêt" % activity_id
		)
		var outcome_texts := 0
		for outcome: String in ["success", "failure", "victory", "defeat", "draw", "done"]:
			var own := StoryActivities.text_key(activity_id, "result_" + outcome)
			if not StoryData.text(ISLAND, own).is_empty():
				outcome_texts += 1
		assert_gt(outcome_texts, 0, "%s : un texte de fin" % activity_id)
	assert_ne(StoryData.text(ISLAND, "ui/activity_stop"), "", "l'invite « Échap : arrêter »")


func test_problems_are_reported() -> void:
	assert_gt(StoryActivities.problems_of(null).size(), 0, "racine")
	assert_gt(StoryActivities.problems_of({"activities": {}}).size(), 0, "aucune activité")
	var bad := {"activities": {"x": {"game": "tennis", "npc": "willem", "map": "entrepot"}}}
	assert_gt(StoryActivities.problems_of(bad).size(), 0, "jeu inconnu")
	var typo := {
		"activities": {"x": {"game": "duel", "npc": "willem", "map": "entrepot", "plac": "a"}}
	}
	assert_gt(StoryActivities.problems_of(typo).size(), 0, "faute de frappe")
	var odd := {
		"activities":
		{"x": {"game": "duel", "npc": "willem", "map": "entrepot", "slot": "minuit", "day": 0}}
	}
	assert_gt(StoryActivities.problems_of(odd).size(), 1, "créneau et jour")
	var iffy := {
		"activities": {"x": {"game": "duel", "npc": "willem", "map": "entrepot", "if": {"nope": 1}}}
	}
	assert_gt(StoryActivities.problems_of(iffy).size(), 0, "condition inconnue")


func test_availability_rules() -> void:
	var data := {
		"game": "duel",
		"npc": "willem",
		"map": "entrepot",
		"place": "cour_willem",
		"slot": "apres_midi",
		"not_activity": ["ballon"],
		"after": "j8_3_duel",
	}
	var line := {"map": &"entrepot", "place": &"cour_willem", "activity": &"attendre"}
	GameState.reset()
	assert_false(StoryActivities.available(data, line, 13, &"apres_midi"), "le duel pas vécu")
	GameState.mark_scene_done(&"j8_3_duel")
	assert_true(StoryActivities.available(data, line, 13, &"apres_midi"), "le duel vécu")
	assert_false(StoryActivities.available(data, line, 13, &"matin"), "pas le matin")
	var elsewhere := line.duplicate()
	elsewhere["map"] = &"entrepot_rdc"
	assert_false(StoryActivities.available(data, elsewhere, 13, &"apres_midi"), "autre carte")
	var other_place := line.duplicate()
	other_place["place"] = &"champ_centre"
	assert_false(StoryActivities.available(data, other_place, 13, &"apres_midi"), "autre place")
	var busy := line.duplicate()
	busy["activity"] = &"ballon"
	assert_false(StoryActivities.available(data, busy, 13, &"apres_midi"), "déjà au ballon")
	assert_false(StoryActivities.available(data, {"away": "village"}, 13, &"apres_midi"), "absent")
	assert_false(StoryActivities.available(data, {}, 13, &"apres_midi"), "nulle part")


func test_option_variants() -> void:
	var data := StoryActivities.all(ISLAND)["seniorious"] as Dictionary
	GameState.reset()
	assert_eq(StoryActivities.options_of(data)["start_stage"], 1, "la respiration")
	GameState.set_flag(&"j9_baton_reussi")
	assert_eq(StoryActivities.options_of(data)["start_stage"], 2, "les mouvements")
	GameState.set_flag(&"j11_grues")
	assert_eq(StoryActivities.options_of(data)["start_stage"], 3, "la Grue")
	assert_true(StoryActivities.options_of(data)["pickup"], "les autres options restent")
	var duel := StoryActivities.all(ISLAND)["duel"] as Dictionary
	assert_true(StoryActivities.options_of(duel)["reprise"], "la revanche")
	# Les options lues ne sont pas altérées par l'appel.
	assert_eq(int((data["options"] as Dictionary)["start_stage"]), 1)


func test_willem_in_free_mode() -> void:
	_free_game()
	assert_eq(_offered(&"willem", 9, &"matin"), &"baton", "jour 9 au matin : le bâton")
	assert_eq(_offered(&"willem", 10, &"matin"), &"baton", "jour 10 au matin")
	assert_eq(_offered(&"willem", 4, &"matin"), &"baton", "jour 4 au matin : la clairière")
	assert_eq(_offered(&"willem", 13, &"matin"), &"baton", "jour 13 au matin")
	assert_eq(_offered(&"willem", 4, &"aube"), &"", "pas à l'aube")
	assert_eq(_offered(&"willem", 8, &"matin"), &"", "le jour 8, il dort au matin")
	assert_eq(_offered(&"willem", 12, &"matin"), &"", "le jour 12, il répare")
	assert_eq(_offered(&"willem", 13, &"apres_midi"), &"", "le duel pas encore vécu")
	assert_eq(_offered(&"willem", 13, &"midi"), &"", "Seniorious pas encore vécu")
	_free_game([&"j8_3_duel"])
	assert_eq(_offered(&"willem", 13, &"apres_midi"), &"duel", "la revanche dans la cour")
	assert_eq(_offered(&"willem", 9, &"apres_midi"), &"", "le jour 9 il est au village")
	assert_eq(_offered(&"willem", 10, &"apres_midi"), &"", "le jour 10 il arbitre le match")
	_free_game([&"j8_3_duel", &"j11_4_seniorious"])
	assert_eq(_offered(&"willem", 13, &"midi"), &"seniorious", "au marais à midi")
	assert_eq(LifeData.line_for(&"willem", &"midi", 13)["place"], &"marais_epee", "l'épée tombée")
	assert_eq(_offered(&"willem", 11, &"midi"), &"", "le jour 11 il est chez les Limashenka")
	# Sous la pluie, il reste à l'abri.
	GameState.set_flag(&"pluie_du_jour")
	for slot: StringName in [&"matin", &"midi", &"apres_midi"]:
		assert_eq(_offered(&"willem", 13, slot), &"", "pluie : rien dehors (%s)" % slot)


func test_willem_is_unchanged_in_scenario_mode() -> void:
	GameState.reset()
	StoryPacing.store(StoryPacing.SCENARIO)
	GameState.mark_scene_done(&"j8_3_duel")
	GameState.mark_scene_done(&"j11_4_seniorious")
	for day: int in [5, 13]:
		assert_eq(LifeData.line_for(&"willem", &"matin", day)["place"], &"archives_bureau")
		assert_eq(LifeData.line_for(&"willem", &"midi", day)["place"], &"refectoire_siege_willem")
	assert_eq(LifeData.line_for(&"willem", &"apres_midi", 13)["place"], &"champ_centre")


## Les créneaux où la ligne de Willem diffère entre le libre et le scénarisé (scènes done faites),
## « jour créneau », sur les jours donnés.
func _changed(days: Array[int], done: Array[StringName]) -> Array[String]:
	var changed: Array[String] = []
	for day: int in days:
		for slot: StringName in GameState.SLOTS:
			_free_game(done)
			var free := LifeData.line_for(&"willem", slot, day)
			GameState.reset()
			StoryPacing.store(StoryPacing.SCENARIO)
			for scene_id: StringName in done:
				GameState.mark_scene_done(scene_id)
			if free != LifeData.line_for(&"willem", slot, day):
				changed.append("%d %s" % [day, slot])
	return changed


func test_the_story_days_keep_their_lines() -> void:
	# Les lignes à jour de Willem passent avant celles du libre : seuls changent les créneaux de
	# la journée de base (le matin à la clairière ; midi et après-midi une fois les scènes faites).
	var none: Array[StringName] = []
	var days: Array[int] = []
	days.assign(range(1, 13))
	assert_eq(
		_changed(days, none),
		["4 matin", "5 matin", "6 matin", "7 matin"] as Array[String],
		"avant le duel : le matin des jours 4 à 7"
	)
	var duel: Array[StringName] = [&"j8_3_duel"]
	var after_duel: Array[int] = [9, 10, 11, 12]
	assert_eq(_changed(after_duel, duel), [] as Array[String], "jours 9 à 12 : leurs lignes")
	var both: Array[StringName] = [&"j8_3_duel", &"j11_4_seniorious"]
	var last: Array[int] = [12]
	assert_eq(_changed(last, both), ["12 midi"] as Array[String], "jour 12 : le marais à midi")


func test_the_ball_is_never_offered_while_life_plays_it() -> void:
	_free_game()
	for day: int in [5, 6, 9, 10, 11, 12]:
		assert_eq(
			_offered(&"tiat", day, &"apres_midi"),
			&"",
			"jour %d : le ballon est déjà joué par la vie" % day
		)
	for day: int in [4, 7, 13]:
		assert_eq(_offered(&"tiat", day, &"apres_midi"), &"ballon", "jour %d : Tiat" % day)
	assert_eq(_offered(&"tiat", 4, &"matin"), &"", "pas le matin")
	GameState.set_flag(&"pluie_du_jour")
	assert_eq(_offered(&"tiat", 4, &"apres_midi"), &"", "sous la pluie, Tiat est à l'abri")


func test_pannibal_offers_the_ambush_outside() -> void:
	_free_game()
	assert_eq(_offered(&"pannibal", 4, &"apres_midi"), &"embuscade", "dans les fourrés")
	assert_eq(_offered(&"pannibal", 4, &"matin"), &"embuscade", "dans l'arbre")
	assert_eq(_offered(&"pannibal", 4, &"midi"), &"", "au réfectoire")
	assert_eq(_offered(&"pannibal", 9, &"apres_midi"), &"", "au ballon")
