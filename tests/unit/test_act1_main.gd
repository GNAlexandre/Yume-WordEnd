extends "res://tests/stubs/q_quest_test.gd"
## Acte 1, quête principale act1_main « Dans la forêt céleste » (HISTOIRE.md 3.1), jouée de bout
## en bout avec le vrai moteur et les vrais dialogues (modèle : test_quest_example.gd). Elle
## démarre seule (auto_start : la base des tests la met de côté, release_auto_start() la rend) ;
## les PNJ donnent leurs aides selon l'étape ; Willem a deux instances de repli (willem_training
## au terrain, willem_stars au sommet) en attendant la présence selon l'histoire (visible_if).

const QUEST := &"act1_main"


func before_each() -> void:
	super()
	release_auto_start()


func _say(npc_id: StringName, answers: Array[int] = [-1]) -> Array[String]:
	return talk(find_npc(npc_id), answers)


func test_main_quest_starts_by_itself() -> void:
	var quest := QuestData.find(QUEST)
	assert_true(quest.main, "quête principale")
	assert_eq(quest.steps.size(), 13, "treize étapes")
	assert_eq(quest.giver_npc, &"nygglatho")
	assert_eq(GameState.quest_state(QUEST), &"active", "auto_start")
	assert_eq(step_of(QUEST), &"morning")
	assert_eq(GameState.tracked_quest, QUEST, "suivie dès le début")
	assert_eq(QuestData.npc_marker(&"nygglatho"), QuestData.MARKER_TURN_IN, "« ? » : Nygglatho")
	assert_eq(quest.current_objective(), "Rejoindre Nygglatho sous le porche")


func test_main_quest_from_the_morning_to_the_promise() -> void:
	# 1. Nygglatho, sous le porche.
	var said := _say(&"nygglatho", [-1, -1, -1, -1, 0, -1])
	assert_string_contains(said[0], "Le vent a hurlé")
	assert_eq(step_of(QUEST), &"new_officer")
	assert_eq(QuestData.npc_marker(&"willem"), QuestData.MARKER_TURN_IN, "« ? » : Willem")
	# 2. Willem et ses conseils : le nouveau responsable est salué.
	said = _say(&"willem", [-1, 0, -1, 0, -1, -1])
	assert_string_contains(said[1], "Market Medley")
	assert_eq(step_of(QUEST), &"to_the_woods")
	assert_true(GameState.has_flag(&"met_willem"), "récompense de l'étape")
	for side: StringName in [&"picture_book", &"special_dessert", &"flying_laundry", &"old_clock"]:
		assert_eq(QuestData.state_of(side), &"available", "%s à prendre" % side)
	# 3. Les bois du marais.
	enter_zone(&"beach")
	assert_eq(step_of(QUEST), &"to_the_woods", "une autre zone ne compte pas")
	enter_zone(&"forest")
	assert_eq(step_of(QUEST), &"rejetons")
	# 4. Quatre rejetons, dans les bois seulement.
	kill(&"timere_small", 3)
	assert_eq(count_of(QUEST), 3)
	enter_zone(&"village")
	kill(&"timere_normal")
	assert_eq(count_of(QUEST), 3, "hors des bois : ne compte pas")
	enter_zone(&"forest")
	kill(&"timere_runner")
	assert_eq(step_of(QUEST), &"pannibal", "quatre rejetons : n'importe lesquels")
	# 5. Pannibal, en embuscade : elle rentre.
	said = _say(&"pannibal", [-1, 1, -1, -1])
	assert_string_contains(said[0], "Embuscade")
	assert_eq(step_of(QUEST), &"report")
	assert_true(GameState.has_flag(&"pannibal_found"))
	# 6. Le rapport à Nygglatho : la veille du soir.
	said = _say(&"nygglatho", [-1, -1, -1, -1, -1])
	assert_eq(said.size(), 5, "aucune scène secondaire en attente : pas de choix")
	assert_string_contains(said[2], "cloche")
	assert_eq(step_of(QUEST), &"first_vigil")
	# 7. La première veille : la 3e vague du Couchant.
	reach_wave(&"dunes", 2)
	assert_eq(step_of(QUEST), &"first_vigil")
	reach_wave(&"dunes", 3)
	assert_eq(step_of(QUEST), &"fever")
	assert_true(GameState.has_flag(&"first_vigil_done"))
	assert_eq(QuestData.state_of(&"vigil_register"), &"available", "le registre de Tiat")
	# 8. La fièvre : Willem soigne, Nephren apporte deux cafés.
	said = _say(&"willem", [-1, 0, -1, -1, -1, -1])
	assert_string_contains(said[2], "Dors.")
	assert_eq(step_of(QUEST), &"training")
	assert_true(GameState.has_flag(&"departure_told"))
	# 9. L'assaut : au terrain d'entraînement (instance de repli), pas à l'entrepôt.
	said = _say(&"willem", [-1, 1, -1])
	assert_string_contains(said[0], "Les petites me fuient", "à l'entrepôt : le dessert d'abord")
	assert_eq(step_of(QUEST), &"training", "le Willem de l'entrepôt ne valide pas l'étape")
	assert_eq(QuestData.npc_marker(&"willem_training"), QuestData.MARKER_TURN_IN)
	said = _say(&"willem_training", [-1, -1, -1, -1, 0, -1])
	assert_string_contains(said[4], "trois jours")
	assert_eq(step_of(QUEST), &"the_edge")
	assert_true(GameState.has_flag(&"duel_lost"))
	# 10. Seule, au bord du Couchant.
	enter_trigger(&"hill_summit")
	assert_eq(step_of(QUEST), &"the_edge", "un autre déclencheur ne compte pas")
	enter_trigger(&"couchant_edge")
	assert_eq(step_of(QUEST), &"barocupot")
	# 11. Le thé du Barocupot.
	said = _say(&"limeskin", [-1, -1, 0, -1, -1])
	assert_string_contains(said[4], "Seniorious")
	assert_eq(step_of(QUEST), &"starry_hill")
	# 12. La colline des étoiles.
	enter_trigger(&"hill_summit")
	assert_eq(step_of(QUEST), &"promise")
	assert_eq(QuestData.npc_marker(&"willem_stars"), QuestData.MARKER_TURN_IN)
	# 13. La promesse.
	assert_eq(GameState.max_hp, GameState.DEFAULT_MAX_HP)
	said = _say(&"willem_stars", [-1, -1, -1, 0, -1, 0])
	assert_string_contains(said[5], "C’est promis.")
	assert_eq(GameState.quest_state(QUEST), &"done", "acte 1 terminé")
	assert_eq(GameState.count(&"butter_cake_promise"), 1, "la promesse du gâteau au beurre")
	assert_eq(GameState.max_hp, 6, "PV max portés à 6")
	assert_true(GameState.has_flag(&"act1_promise"), "récompense de l'étape")
	assert_true(GameState.has_flag(&"act1_done"), "récompense de la quête")
	# Après l'acte : leurs répliques (les quêtes secondaires restent proposées avant).
	assert_string_contains(_say(&"pannibal")[0], "pendant que tu n’es pas là")
	assert_string_contains(_say(&"willem_stars")[0], "étoiles")
	assert_string_contains(_say(&"nygglatho")[0], "draps du toit", "le linge à rapporter")


func test_hints_follow_the_current_step() -> void:
	# Sans quête secondaire à proposer, les aides de la quête principale.
	assert_string_contains(_say(&"willem")[0], "Sous le porche", "Willem renvoie à Nygglatho")
	_say(&"nygglatho", [-1, -1, -1, -1, 1, -1])
	assert_string_contains(_say(&"nygglatho")[0], "porte rivetée", "Nygglatho renvoie à Willem")
	assert_eq(step_of(QUEST), &"new_officer", "une aide ne valide rien")
	assert_string_contains(_say(&"willem_training")[0], "Bonjour", "pas encore présentés")
	assert_string_contains(_say(&"garde_lookout")[0], "Rien à signaler", "le guetteur")
	GameState.set_quest_state(QUEST, &"active")
	GameState.set_quest_step(QUEST, &"training")
	assert_string_contains(_say(&"willem")[0], "terrain d’entraînement", "étape de l'assaut")
	assert_string_contains(_say(&"garde_lookout")[0], "Rien à signaler")
	GameState.set_quest_step(QUEST, &"the_edge")
	assert_string_contains(_say(&"garde_lookout")[0], "Le bord est tout près")


func test_the_morning_is_validated_even_if_cut_short() -> void:
	# Une étape talk se valide à la fin de toute conversation avec le PNJ (docs/QUETES.md).
	_say(&"nygglatho", [])
	assert_eq(step_of(QUEST), &"new_officer")
