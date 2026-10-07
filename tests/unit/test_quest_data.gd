extends "res://tests/stubs/q_quest_test.gd"
## Lot Q, format des quêtes (QuestData, QuestStep) : lecture du JSON, vérification (chaque erreur
## expliquée), quête du livre d'images, dossiers de recherche, état vu par le joueur,
## prérequis, étape courante, textes de progression, marqueurs des PNJ, ordre des quêtes.


## Quête minimale valide, complétée par extra.
func _quest(steps: Array, extra: Dictionary = {}) -> Dictionary:
	var data := {"id": "q", "title": "Quête", "steps": steps}
	data.merge(extra, true)
	return data


func _talk_step(step_id: String = "a", npc_id: String = "child") -> Dictionary:
	return {"id": step_id, "type": "talk", "npc": npc_id, "objective": "Parler"}


func test_picture_book_quest_is_written_in_json() -> void:
	# Acte 1 : le livre d'images remplace la quête des pages (data/quests/pages.json retirée).
	assert_false(FileAccess.file_exists("res://data/quests/pages.json"), "pages.json retirée")
	var quest := QuestData.find(&"picture_book")
	assert_not_null(quest, "data/quests/picture_book.json")
	if quest == null:
		return
	assert_eq(quest.title, "Le livre d’images")
	assert_eq(quest.giver_npc, &"nephren")
	assert_eq(quest.prereq_flags, [&"met_willem"] as Array[StringName])
	assert_eq(quest.steps.size(), 2, "rapporter les pages, puis la lecture")
	var step := quest.steps[0]
	assert_eq(step.type, QuestStep.COLLECT)
	assert_eq(
		[step.item, step.count, step.npc, step.consume], [&"page_fragment", 5, &"nephren", true]
	)
	assert_eq([quest.steps[1].type, quest.steps[1].npc], [QuestStep.TALK, &"willem"])
	assert_eq(quest.reward_items, {&"picture_book": 1} as Dictionary[StringName, int])
	assert_eq(quest.reward_flags, [&"book_read"] as Array[StringName])
	assert_eq(quest.reward_max_hp, 0)
	assert_false(ResourceLoader.exists("res://data/quests/pages.tres"), "plus de .tres")


func test_find_rejects_unknown_ids_and_paths() -> void:
	for quest_id: StringName in [&"inconnue", &"", &"../pages", &"pages.json", &"é"]:
		assert_null(QuestData.find(quest_id), "find(%s)" % quest_id)


func test_all_lists_valid_quests_sorted_by_id() -> void:
	var ids: Array[String] = []
	for quest: QuestData in QuestData.all():
		ids.append(String(quest.id))
	for expected: String in ["act1_main", "demo_followup", "demo_tour", "picture_book"]:
		assert_has(ids, expected)
	var sorted := ids.duplicate()
	sorted.sort()
	assert_eq(ids, sorted, "triées par id")


func test_search_dirs_can_be_added_and_removed() -> void:
	write_quest(_quest([_talk_step()], {"id": "tmp_quest"}))
	assert_not_null(QuestData.find(&"tmp_quest"))
	QuestData.remove_search_dir(TEMP_DIR)
	assert_null(QuestData.find(&"tmp_quest"), "dossier retiré")
	QuestData.remove_search_dir(QuestData.DATA_DIR)
	assert_not_null(QuestData.find(&"picture_book"), "le dossier du jeu ne se retire pas")
	QuestData.add_search_dir(TEMP_DIR)
	assert_not_null(QuestData.find(&"tmp_quest"))


func test_valid_quest_reads_every_field() -> void:
	var data := _quest(
		[
			_talk_step("talk_child"),
			{"id": "beach", "type": "reach", "zone": "beach", "objective": "Plage", "hint": "Sud"},
			{"id": "rock", "type": "reach", "trigger": "rock", "objective": "Rocher"},
			{"id": "kill", "type": "kill", "enemy": "timere_big", "count": 2.0, "zone": "dunes"},
			{"id": "shells", "type": "collect", "item": "shell", "count": 3, "consume": true},
			{"id": "wave", "type": "arena", "arena": "dunes", "wave": 3},
			{"id": "score", "type": "arena", "arena": "dunes", "score": 300},
			{
				"id": "lit",
				"type": "flag",
				"flag": "lit",
				"objective": "Allumer",
				"rewards": {"items": {"shell": 1}, "flags": ["f"], "max_hp": 7}
			},
		],
		{
			"summary": "Résumé",
			"giver": "child",
			"main": true,
			"auto_start": true,
			"requires": {"quests": ["pages"], "flags": ["a"], "not_flags": ["b"]},
			"rewards": {"items": {"bookmark": 2}, "flags": ["done_q"], "max_hp": 8},
			"_comment": "les clés en _ sont des commentaires",
		}
	)
	data["steps"][3]["objective"] = "Vaincre"
	data["steps"][4]["objective"] = "Ramasser"
	data["steps"][5]["objective"] = "Vague 3"
	data["steps"][6]["objective"] = "300 points"
	assert_eq(QuestData.problem(data, "q"), "", "quête valide")
	var quest := QuestData.from_dict(data)
	assert_eq(
		[quest.id, quest.title, quest.summary, quest.giver_npc], [&"q", "Quête", "Résumé", &"child"]
	)
	assert_true(quest.main and quest.auto_start)
	assert_eq(quest.prereq_quests, [&"pages"] as Array[StringName])
	assert_eq(quest.prereq_flags, [&"a"] as Array[StringName])
	assert_eq(quest.prereq_not_flags, [&"b"] as Array[StringName])
	assert_eq(quest.reward_items, {&"bookmark": 2} as Dictionary[StringName, int])
	assert_eq(quest.reward_flags, [&"done_q"] as Array[StringName])
	assert_eq(quest.reward_max_hp, 8)
	assert_eq(quest.steps.size(), 8)
	assert_eq(quest.steps[1].zone, &"beach")
	assert_eq(quest.steps[1].hint, "Sud")
	assert_eq(quest.steps[2].trigger, &"rock")
	assert_eq([quest.steps[3].enemy, quest.steps[3].count], [&"timere_big", 2])
	assert_eq(quest.steps[3].zone, &"dunes")
	assert_eq(quest.steps[0].enemy, QuestStep.ANY_ENEMY, "enemy par défaut : any")
	assert_eq([quest.steps[4].item, quest.steps[4].count], [&"shell", 3])
	assert_true(quest.steps[4].consume)
	assert_eq([quest.steps[5].wave, quest.steps[5].score], [3, 0])
	assert_eq([quest.steps[6].wave, quest.steps[6].score], [0, 300])
	assert_eq(quest.steps[7].flag, &"lit")
	assert_eq(quest.steps[7].reward_items, {&"shell": 1} as Dictionary[StringName, int])
	assert_eq(quest.steps[7].reward_flags, [&"f"] as Array[StringName])
	assert_eq(quest.steps[7].reward_max_hp, 7)
	assert_eq(quest.objective, "Parler", "objectif général : celui de la 1re étape")


func test_every_problem_is_explained() -> void:
	var talk_step := _talk_step()
	var cases := {
		"la racine doit être un objet": [],
		"clé inconnue « titre »": {"id": "q", "titre": "x", "steps": [talk_step]},
		"« id » doit être un identifiant": _quest([talk_step], {"id": "ma quête"}),
		"doit être le nom du fichier": _quest([talk_step], {"id": "autre"}),
		"« title » est obligatoire": {"id": "q", "steps": [talk_step]},
		"« summary » doit être un texte": _quest([talk_step], {"summary": 3}),
		"« giver » doit être un id de PNJ": _quest([talk_step], {"giver": "La bibliothécaire"}),
		"« main » doit valoir true ou false": _quest([talk_step], {"main": "oui"}),
		"clé inconnue « quest » dans « requires »":
		_quest([talk_step], {"requires": {"quest": ["a"]}}),
		"« requires.flags » doit être une liste": _quest([talk_step], {"requires": {"flags": [1]}}),
		"« steps » doit être une liste d'au moins une étape": _quest([]),
		"une étape doit être un objet": _quest(["parler"]),
		"étape 1 : « id » doit être un identifiant": _quest([{"type": "talk"}]),
		"« type » doit valoir": _quest([{"id": "a", "type": "dance", "objective": "x"}]),
		"clé inconnue « zone » pour une étape talk": _quest([_with(talk_step, {"zone": "beach"})]),
		"« objective » (texte du HUD) est obligatoire": _quest([{"id": "a", "type": "talk"}]),
		"« hint » doit être un texte": _quest([_with(talk_step, {"hint": 2})]),
		"« npc » doit être un identifiant": _quest([{"id": "a", "type": "talk", "objective": "x"}]),
		"« zone » ou « trigger » (un seul)":
		_quest([{"id": "a", "type": "reach", "objective": "x", "zone": "beach", "trigger": "t"}]),
		"« count » doit être un entier au moins égal à 1":
		_quest([{"id": "a", "type": "kill", "objective": "x", "count": 0}]),
		"« enemy » doit être un id d'ennemi":
		_quest([{"id": "a", "type": "kill", "objective": "x", "enemy": 3}]),
		"« item » doit être un identifiant":
		_quest([{"id": "a", "type": "collect", "objective": "x", "count": 2}]),
		"« consume » doit valoir true ou false":
		_quest([{"id": "a", "type": "collect", "objective": "x", "item": "shell", "consume": 1}]),
		"« wave » ou « score » (un seul)":
		_quest([{"id": "a", "type": "arena", "objective": "x", "arena": "dunes"}]),
		"« arena » doit être un identifiant":
		_quest([{"id": "a", "type": "arena", "objective": "x", "wave": 2}]),
		"« flag » doit être un identifiant":
		_quest([{"id": "a", "type": "flag", "objective": "x"}]),
		"l'id « a » est déjà pris": _quest([talk_step, talk_step]),
		"« rewards.items » : identifiants et quantités":
		_quest([talk_step], {"rewards": {"items": {"shell": 0}}}),
		"clé inconnue « hp » dans « rewards »": _quest([talk_step], {"rewards": {"hp": 6}}),
		"« rewards.max_hp » doit être un entier": _quest([talk_step], {"rewards": {"max_hp": 0.5}}),
		"étape 2 « b » : « rewards.flags »":
		_quest([talk_step, _with(_talk_step("b"), {"rewards": {"flags": "a b"}})]),
	}
	for expected: String in cases:
		var problem := QuestData.problem(cases[expected], "q")
		assert_string_contains(problem, expected, false)


func _with(step: Dictionary, extra: Dictionary) -> Dictionary:
	var result := step.duplicate(true)
	result.merge(extra, true)
	return result


func test_invalid_files_warn_and_are_ignored() -> void:
	var file := FileAccess.open(TEMP_DIR.path_join("broken.json"), FileAccess.WRITE)
	file.store_string('{"id": "broken", "title": ')
	file.close()
	write_quest(_quest([{"id": "a", "type": "talk", "objective": "x"}], {"id": "bad"}))
	assert_null(QuestData.find(&"broken"))
	assert_push_warning("JSON invalide")
	assert_null(QuestData.find(&"bad"))
	assert_push_warning("« npc » doit être un identifiant")
	assert_null(QuestData.find(&"bad"), "fichier invalide gardé en mémoire : un seul avertissement")
	var ids: Array[StringName] = []
	for quest: QuestData in QuestData.all():
		ids.append(quest.id)
	assert_false(ids.has(&"bad") or ids.has(&"broken"), "absentes de all()")


func test_status_follows_prerequisites() -> void:
	write_quest(
		_quest(
			[_talk_step()],
			{"requires": {"quests": ["pages"], "flags": ["ok"], "not_flags": ["no"]}}
		)
	)
	var quest := QuestData.find(&"q")
	assert_eq(quest.status(), &"", "verrouillée")
	complete_quest(&"pages")
	assert_eq(quest.status(), &"", "il manque le drapeau")
	GameState.set_flag(&"ok")
	assert_eq(quest.status(), &"available")
	assert_true(quest.is_available())
	GameState.set_flag(&"no")
	assert_eq(quest.status(), &"", "drapeau interdit")
	GameState.set_flag(&"no", false)
	start_quest(&"q")
	assert_eq(QuestData.state_of(&"q"), &"active")
	assert_eq(QuestData.state_of(&"sans_donnees"), &"", "sans données : état brut")
	GameState.set_quest_state(&"sans_donnees", &"active")
	assert_eq(QuestData.state_of(&"sans_donnees"), &"active")


func test_current_step_and_progress_texts() -> void:
	write_quest(
		_quest(
			[
				{
					"id": "pages",
					"type": "collect",
					"item": "page_fragment",
					"count": 3,
					"objective": "P"
				},
				{"id": "kill", "type": "kill", "count": 2, "objective": "K"},
				{"id": "big", "type": "kill", "enemy": "timere_big", "objective": "G"},
				{"id": "wave", "type": "arena", "arena": "dunes", "wave": 4, "objective": "W"},
				{"id": "score", "type": "arena", "arena": "dunes", "score": 300, "objective": "S"},
				_talk_step("end"),
			]
		)
	)
	var quest := QuestData.find(&"q")
	assert_null(quest.current_step(), "pas commencée")
	assert_eq(quest.current_index(), -1)
	start_quest(&"q")
	assert_eq(quest.current_step().id, &"pages")
	assert_eq(quest.current_objective(), "P")
	assert_eq(quest.current_progress(), "Page du livre d’images : 0/3")
	GameState.add_item(&"page_fragment", 2)
	assert_eq(quest.current_progress(), "Page du livre d’images : 2/3")
	var expected := {
		&"kill": "Ennemis vaincus : 1/2",
		&"big": "Grand Timere : 1/1",
		&"wave": "Vague atteinte : 1/4",
		&"score": "Score : 1/300",
		&"end": "",
	}
	for step_id: StringName in expected:
		GameState.set_quest_step(&"q", step_id, 1)
		assert_eq(quest.current_progress(), expected[step_id], "progression de %s" % step_id)
	GameState.set_quest_step(&"q", &"inconnue")
	assert_eq(quest.current_step().id, &"pages", "étape inconnue : la première")
	complete_quest(&"q")
	assert_eq(GameState.quest_state(&"q"), &"done")
	assert_eq(quest.current_index(), quest.steps.size(), "terminée")
	assert_null(quest.current_step())


func test_npc_markers() -> void:
	write_quest(_quest([_talk_step("a", "blacksmith")], {"giver": "child"}))
	write_quest(_quest([_talk_step()], {"id": "auto", "giver": "child", "auto_start": true}))
	write_quest(
		_quest(
			[_talk_step()], {"id": "locked", "giver": "blacksmith", "requires": {"flags": ["x"]}}
		)
	)
	assert_eq(QuestData.npc_marker(&"child"), QuestData.MARKER_AVAILABLE, "« ! » : quête à prendre")
	assert_eq(QuestData.npc_marker(&"blacksmith"), &"", "quête verrouillée : rien")
	assert_eq(QuestData.npc_marker(&"nephren"), &"", "livre d'images : Willem pas salué")
	GameState.set_flag(&"met_willem")
	assert_eq(QuestData.npc_marker(&"nephren"), QuestData.MARKER_AVAILABLE, "livre d'images")
	assert_eq(QuestData.npc_marker(&""), &"")
	start_quest(&"q")
	assert_eq(QuestData.npc_marker(&"blacksmith"), QuestData.MARKER_TURN_IN, "« ? » : à qui parler")
	start_quest(&"picture_book")
	assert_eq(QuestData.npc_marker(&"nephren"), &"", "livre en cours, pas assez de pages")
	GameState.add_item(&"page_fragment", 5)
	assert_eq(QuestData.npc_marker(&"nephren"), QuestData.MARKER_TURN_IN, "« ? » : à rendre")


func test_active_quests_main_first_then_start_order() -> void:
	write_quest(_quest([_talk_step()], {"id": "side_a"}))
	write_quest(_quest([_talk_step()], {"id": "main_b", "main": true}))
	write_quest(_quest([_talk_step()], {"id": "side_c"}))
	assert_eq(QuestData.shown_quest(), &"", "aucune quête active")
	start_quest(&"side_c")
	start_quest(&"side_a")
	start_quest(&"main_b")
	var expected: Array[StringName] = [&"main_b", &"side_c", &"side_a"]
	assert_eq(QuestData.active_ids(), expected)
	assert_eq(QuestData.shown_quest(), &"main_b", "la dernière commencée est suivie")
	GameState.tracked_quest = &"side_a"
	assert_eq(QuestData.shown_quest(), &"side_a")
	GameState.tracked_quest = &"inconnue"
	assert_eq(QuestData.shown_quest(), &"main_b", "quête suivie inactive : la première active")
	complete_quest(&"side_c")
	assert_eq(QuestData.done_ids(), [&"side_c"] as Array[StringName])
