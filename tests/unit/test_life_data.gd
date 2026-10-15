extends GutTest
## (E4) Les données de la vie : format des emplois du temps et des activités (clé inconnue refusée,
## carte, place, activité, tenue absentes signalées), tous les fichiers de data/life/ valides, choix
## de la ligne selon le créneau, le jour et la condition ; créneaux et lumière ; textes de la vie ;
## fées génériques.

const NBSP := "\u00a0"
const NNBSP := "\u202f"


## Les emplois du temps de démonstration des cartes d'essai (data/life/essai/) sont ceux que ce
## fichier éprouve ; ceux de l'île n° 68 (data/life/ile_68/) sont vérifiés par test_life_ile_68.gd,
## et leur validité ici aussi (test_every_life_file_is_valid).
func before_each() -> void:
	GameState.reset()
	LifeData.use_content(&"essai")


func after_each() -> void:
	GameState.reset()
	LifeData.use_content(&"")


func _line(extra: Dictionary) -> Dictionary:
	var line := {
		"slot": "matin",
		"map": "entrepot_rdc_essai",
		"place": "refectoire_table_a",
		"activity": "manger",
	}
	line.merge(extra, true)
	return line


func _problems(lines: Array, npc_id: StringName = &"tiat") -> PackedStringArray:
	return LifeData.schedule_problems(npc_id, {"lines": lines})


func test_every_life_file_is_valid() -> void:
	for content: StringName in [&"essai", &"ile_68"]:
		LifeData.use_content(content)
		var problems := LifeData.all_problems()
		assert_eq(problems, PackedStringArray(), "%s : %s" % [content, "\n".join(problems)])
		assert_gt(LifeData.cast().size(), 10, "%s : des emplois du temps dans data/life/" % content)
		assert_false(LifeData.cast().has(&"activities"), "activities.json n'est pas un PNJ")


func test_content_follows_the_island() -> void:
	# (V1) data/life/<île>/ : l'île n° 68 par défaut, l'île courante de la partie sinon ; une île sans
	# dossier n'a aucun emploi du temps (l'ancienne île, l'île d'essai) ; les activités restent communes.
	LifeData.use_content(&"")
	assert_eq(LifeData.content_island(), &"ile_68", "par défaut")
	assert_has(LifeData.cast(), &"willem")
	assert_eq(LifeData.line_for(&"willem", &"midi", 0)["map"], &"entrepot_rdc", "les vraies cartes")
	GameState.island = &"ile_ancienne"
	assert_eq(LifeData.cast(), [] as Array[StringName], "l'ancienne île n'a pas de vie")
	assert_true(LifeData.has_activity(&"manger"), "activities.json est commun")
	GameState.island = &"ile_68"
	assert_has(LifeData.cast(), &"willem")
	LifeData.use_content(&"essai")
	assert_eq(LifeData.line_for(&"willem", &"midi", 0)["map"], &"entrepot_rdc_essai", "la démonstration")
	assert_eq(LifeData.schedule_path(&"willem"), "res://data/life/essai/willem.json")


func test_a_valid_line_passes() -> void:
	assert_eq(
		_problems([_line({"outfit": "vie", "day": [2, 4], "if": {"flag": "x"}})]),
		PackedStringArray()
	)


func test_unknown_keys_are_refused() -> void:
	assert_eq(_problems([_line({"plce": "x"})]).size(), 1, "faute de frappe dans une ligne")
	var top := LifeData.schedule_problems(&"tiat", {"lines": [_line({})], "gaitt": "course"})
	assert_eq(top.size(), 1, "faute de frappe en tête")
	assert_eq(_problems([_line({"_note": "commentaire"})]), PackedStringArray(), "« _… » permis")


func test_missing_map_place_activity_outfit_are_reported() -> void:
	assert_true(_has(_problems([_line({"map": "carte_inconnue"})]), "carte carte_inconnue absente"))
	assert_true(_has(_problems([_line({"place": "nulle_part"})]), "place nulle_part absente"))
	assert_true(_has(_problems([_line({"activity": "voler"})]), "activité voler inconnue"))
	assert_true(_has(_problems([_line({"outfit": "smoking"})]), "tenue smoking absente"))
	assert_true(_has(_problems([_line({"slot": "goûter"})]), "« slot »"))
	assert_true(_has(_problems([_line({"day": 0})]), "« day »"))
	assert_true(_has(_problems([_line({"away": "etage"})]), "« map » (et « place ») ou « away »"))
	assert_true(_has(_problems([{"slot": "nuit"}]), "« map » (et « place ») ou « away »"))
	assert_true(_has(_problems([_line({"if": {"inconnu": 1}})]), "« if »"))
	assert_true(_has(_problems([_line({})], &"personne"), "PNJ introuvable"))


func test_activities_format() -> void:
	assert_eq(LifeData.activities_problems(), PackedStringArray())
	var data := {
		"speeds": {"marche": 1.3},
		"activities": {"x": {"poses": [{"anim": "voler"}], "pause": 3}},
	}
	var problems := LifeData.activities_problems(data)
	assert_true(_has(problems, "animation voler inconnue"), "\n".join(problems))
	assert_true(_has(problems, "clé inconnue « pause »"), "\n".join(problems))
	var game := {"speeds": {"marche": 1.3}, "activities": {"y": {"game": "cache_cache"}}}
	assert_true(_has(LifeData.activities_problems(game), "jeu cache_cache inconnu"))


func test_line_follows_slot_day_and_condition() -> void:
	assert_eq(LifeData.line_for(&"willem", &"matin", 0)["place"], &"cuisine_table")
	assert_eq(LifeData.line_for(&"willem", &"aube", 0)["place"], &"cuisine_table", "deux créneaux")
	assert_eq(LifeData.line_for(&"willem", &"nuit", 0)["place"], &"archives_bureau")
	assert_eq(LifeData.line_for(&"willem", &"matin", 0)["outfit"], &"cuisine")
	# Lakhesh : sa ligne « day » (boulangerie, jours 3 à 12) l'emporte sur la ligne de base.
	assert_eq(
		LifeData.line_for(&"lakhesh", &"matin", 0)["place"], &"refectoire_table_b", "pas de jour"
	)
	assert_eq(LifeData.line_for(&"lakhesh", &"matin", 2)["map"], &"entrepot_rdc_essai")
	assert_eq(LifeData.line_for(&"lakhesh", &"matin", 3)["away"], &"ville_boulangerie", "jour 3")
	assert_eq(LifeData.line_for(&"lakhesh", &"matin", 12)["away"], &"ville_boulangerie", "jour 12")
	assert_eq(LifeData.line_for(&"lakhesh", &"matin", 13)["map"], &"entrepot_rdc_essai", "jour 13")
	assert_eq(LifeData.line_for(&"ithea", &"nuit", 0)["away"], &"entrepot_etage", "à l'étage")


func test_condition_lines_come_first() -> void:
	var dir := "user://e4_life_test"
	DirAccess.make_dir_recursive_absolute(dir)
	# Le boulanger n'a pas d'emploi du temps : on lui en écrit un, la ligne de base d'abord, puis
	# sa variation (un drapeau) ; la variation l'emporte quand elle est vraie.
	var file := FileAccess.open(dir.path_join("baker.json"), FileAccess.WRITE)
	var base := _line({})
	var flagged := _line({"place": "lecture_table", "if": {"flag": "e4_test"}})
	file.store_string(JSON.stringify({"lines": [base, flagged]}))
	file.close()
	LifeData.add_dir(dir)
	assert_has(LifeData.cast(), &"baker")
	assert_eq(LifeData.schedule_problems(&"baker"), PackedStringArray())
	assert_eq(LifeData.line_for(&"baker", &"matin", 0)["place"], &"refectoire_table_a")
	GameState.set_flag(&"e4_test")
	assert_eq(LifeData.line_for(&"baker", &"matin", 0)["place"], &"lecture_table", "variation")
	assert_eq(LifeData.line_for(&"baker", &"nuit", 0), {}, "nulle part la nuit")
	LifeData.remove_dir(dir)
	DirAccess.remove_absolute(dir.path_join("baker.json"))
	DirAccess.remove_absolute(dir)
	assert_false(LifeData.cast().has(&"baker"))


func test_slots_and_light() -> void:
	assert_eq(LifeSlots.all().size(), 6)
	assert_eq(LifeSlots.moment_of(&"midi"), &"matin", "midi garde la lumière du matin")
	assert_eq(LifeSlots.moment_of(&"soir"), &"couchant")
	assert_eq(LifeSlots.default_for(&"couchant"), &"soir")
	assert_eq(LifeSlots.current(), &"soir", "nouvelle partie : le couchant, donc le soir")
	GameState.moment = &"matin"
	assert_eq(LifeSlots.current(), &"matin")
	GameState.slot = &"midi"
	assert_eq(LifeSlots.current(), &"midi", "midi sous la lumière du matin")
	GameState.moment = &"apres_midi"
	assert_eq(LifeSlots.current(), &"apres_midi", "le moment changé ailleurs emporte le créneau")
	assert_eq(GameState.slot, &"", "créneau qui ne va plus : oublié (LifeDirector)")
	assert_eq(LifeSlots.next(&"nuit"), &"aube")


func test_set_slot_moves_the_light() -> void:
	LifeDirector.set_slot(&"midi", 0.0)
	assert_eq(GameState.moment, &"matin")
	assert_eq(LifeSlots.current(), &"midi")
	LifeDirector.next_slot(0.0)
	assert_eq(LifeSlots.current(), &"apres_midi")
	assert_eq(GameState.moment, &"apres_midi")
	assert_eq(GameState.to_dict()["slot"], "apres_midi", "sauvegardé")


func test_life_texts() -> void:
	assert_eq(LifeTexts.problem(LifeTexts.data()), "")
	assert_false(LifeTexts.data().is_empty(), "data/texts/life.json lu")
	assert_false(LifeTexts.greeting(&"tiat").is_empty())
	assert_false(LifeTexts.greeting(&"fairy_03").is_empty(), "repli : default")
	assert_false(LifeTexts.text("games/chat/player_it").contains("{player}"), "{player} remplacé")
	var problems: Array[String] = []
	_check_texts("life", LifeTexts.data(), problems)
	assert_eq(problems, [] as Array[String], "\n".join(problems))


func test_generic_fairies() -> void:
	var names := LifeTexts.fairy_names()
	assert_gte(names.size(), 6)
	var seen := {}
	for index: int in range(1, 7):
		var npc_id := StringName("fairy_%02d" % index)
		var data := LifeData.find_npc(npc_id)
		assert_not_null(data, "%s : data/npcs/generic" % npc_id)
		if data == null:
			continue
		assert_has(names, data.display_name, "%s : prénom de la liste" % npc_id)
		assert_false(seen.has(data.display_name), "prénoms distincts")
		seen[data.display_name] = true
		assert_eq(data.skin.id, npc_id, "planche %s" % npc_id)
		assert_eq(data.dialogue_path, "", "sans dialogue : une bulle")
	assert_has(names, LifeTexts.fairy_name(&"fairy_99"), "tiré de la liste")


func _has(problems: PackedStringArray, fragment: String) -> bool:
	for problem: String in problems:
		if problem.contains(fragment):
			return true
	gut.p("« %s » absent de : %s" % [fragment, "\n".join(problems)])
	return false


## Typographie (comme les dialogues, test_act1_dialogues.gd) : apostrophe ’, …, espace insécable.
func _check_texts(path: String, value: Variant, problems: Array[String]) -> void:
	if value is Dictionary:
		for key: String in value:
			if not key.begins_with("_"):
				_check_texts(path + "/" + key, value[key], problems)
		return
	if value is Array:
		for entry: Variant in value:
			_check_texts(path, entry, problems)
		return
	var text := str(value)
	if text.contains("'") or text.contains("..."):
		problems.append("%s : %s" % [path, text])
	for i: int in text.length():
		var before := text[i - 1] if i > 0 else ""
		if "!?:;»".contains(text[i]) and not [NBSP, NNBSP, "!", "?"].has(before):
			problems.append("%s : espace insécable avant « %s » : %s" % [path, text[i], text])
