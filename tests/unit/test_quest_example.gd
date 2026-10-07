extends "res://tests/stubs/q_quest_test.gd"
## Modèle de test d'une quête écrite en données (docs/QUETES.md, « Tester une quête ») : la quête
## d'exemple example_patrol (tests/data/quests) et le dialogue du forgeron qui va avec
## (tests/data/dialogues/example_blacksmith.json), joués de bout en bout avec le vrai moteur.
## Pour une nouvelle quête : copier ce fichier en tests/unit/test_quest_<id>.gd, remplacer les
## identifiants, jouer chaque étape et vérifier l'étape courante après chacune.

const BLACKSMITH := preload("res://tests/data/npcs/example_blacksmith.tres")
const QUEST := &"example_patrol"


func test_patrol_from_offer_to_reward() -> void:
	# Verrouillée tant que la quête des pages n'est pas terminée (requires.quests).
	assert_eq(QuestData.state_of(QUEST), &"", "verrouillée")
	assert_eq(QuestData.npc_marker(&"blacksmith"), &"", "pas de « ! » au-dessus du forgeron")
	complete_quest(&"pages")
	assert_eq(QuestData.state_of(QUEST), &"available", "disponible après les pages")
	assert_eq(QuestData.npc_marker(&"blacksmith"), QuestData.MARKER_AVAILABLE, "« ! »")

	# Le forgeron la propose (nœud « offer ») ; on accepte (choix 0), puis « go ».
	var said := talk(BLACKSMITH, [0, -1])
	assert_string_contains(said[0], "clairière")
	assert_eq(GameState.quest_state(QUEST), &"active", "start_quest")
	assert_eq(step_of(QUEST), &"clearing", "première étape")
	assert_eq(GameState.tracked_quest, QUEST, "la quête qui commence est suivie")

	# Étape 1 (reach trigger) : le déclencheur de la clairière.
	enter_trigger(&"elsewhere")
	assert_eq(step_of(QUEST), &"clearing", "un autre déclencheur ne compte pas")
	enter_trigger(&"forest_clearing")
	assert_eq(step_of(QUEST), &"timeres")

	# Étape 2 (kill) : deux petits Timeres, dans la forêt.
	kill(&"timere_small")
	assert_eq(count_of(QUEST), 0, "hors de la forêt : ne compte pas")
	enter_zone(&"forest")
	kill(&"timere_normal")
	assert_eq(count_of(QUEST), 0, "un Timere normal ne compte pas")
	kill(&"timere_small")
	assert_eq(count_of(QUEST), 1)
	assert_eq(QuestData.find(QUEST).current_progress(), "Rejeton de Timere : 1/2")
	kill(&"timere_small")
	assert_eq(step_of(QUEST), &"report", "deux petits Timeres : étape suivante")
	assert_eq(QuestData.npc_marker(&"blacksmith"), QuestData.MARKER_TURN_IN, "« ? »")

	# Étape 3 (talk) : le rapport au forgeron (advance_quest dans le nœud « report »).
	said = talk(BLACKSMITH, [-1, -1])
	assert_string_contains(said[0], "Deux de moins")
	assert_eq(GameState.quest_state(QUEST), &"done", "quête terminée")
	assert_eq(GameState.count(&"shell"), 2, "récompense : deux coquillages")
	assert_true(GameState.has_flag(&"forest_patrol_done"), "récompense : drapeau")
	assert_eq(QuestData.npc_marker(&"blacksmith"), &"")

	# Ensuite, le forgeron n'en parle plus que comme d'un souvenir.
	said = talk(BLACKSMITH, [-1])
	assert_string_contains(said[0], "calme depuis ta ronde")


func test_patrol_can_be_refused_then_accepted() -> void:
	complete_quest(&"pages")
	talk(BLACKSMITH, [1])
	assert_eq(GameState.quest_state(QUEST), &"", "« Pas maintenant » : rien ne change")
	assert_eq(QuestData.state_of(QUEST), &"available", "toujours proposée")
	talk(BLACKSMITH, [0, -1])
	assert_eq(GameState.quest_state(QUEST), &"active")


func test_report_at_the_end_of_any_conversation() -> void:
	# Une étape talk se valide aussi à la fin d'un dialogue sans advance_quest.
	complete_quest(&"pages")
	start_quest(QUEST)
	enter_trigger(&"forest_clearing")
	enter_zone(&"forest")
	kill(&"timere_small", 2)
	chat(&"blacksmith")
	assert_eq(GameState.quest_state(QUEST), &"done")
