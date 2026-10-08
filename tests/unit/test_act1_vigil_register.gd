extends "res://tests/stubs/q_quest_test.gd"
## Acte 1, quête secondaire vigil_register « Le registre des veilles » (HISTOIRE.md 3.2), jouée
## avec le vrai moteur et les vrais dialogues : après la première veille, Tiat ouvre son
## registre ; atteindre la 4e vague, le lui raconter, faire 1 000 points en une veille, faire
## inscrire le record ; récompenses : le dessin de Tiat, drapeau vigil_record, 7 PV max.

const QUEST := &"vigil_register"
const TIAT := preload("res://data/npcs/tiat.tres")


func test_vigil_register_from_the_first_vigil_to_the_record() -> void:
	assert_eq(QuestData.state_of(QUEST), &"", "pas avant la première veille")
	GameState.set_flag(&"first_vigil_done")
	assert_eq(QuestData.npc_marker(&"tiat"), QuestData.MARKER_AVAILABLE, "« ! »")
	var said := talk(TIAT, [-1, 0, -1])
	assert_string_contains(said[0], "Mademoiselle")
	assert_eq(step_of(QUEST), &"wave4")
	assert_string_contains(talk(TIAT)[0], "La quatrième vague")
	# La 4e vague d'une veille au Couchant.
	reach_wave(&"dunes", 3)
	assert_eq(step_of(QUEST), &"wave4")
	reach_wave(&"dunes", 4)
	assert_eq(step_of(QUEST), &"tell_tiat")
	assert_eq(QuestData.npc_marker(&"tiat"), QuestData.MARKER_TURN_IN)
	said = talk(TIAT, [-1, -1, -1])
	assert_string_contains(said[2], "1 000 points")
	assert_eq(step_of(QUEST), &"score")
	# 1 000 points en une seule veille.
	reach_score(&"dunes", 640)
	GameState.record_score(&"dunes", 640, 4)
	assert_eq(step_of(QUEST), &"score")
	assert_string_contains(talk(TIAT)[0], "Votre meilleure veille : 640 points.")
	reach_score(&"dunes", 1000)
	GameState.record_score(&"dunes", 1000, 6)
	assert_eq(step_of(QUEST), &"record")
	said = talk(TIAT, [-1, -1, -1])
	assert_string_contains(said[0], "Votre record : 1000.")
	assert_string_contains(said[2], "un dessin pour vous")
	assert_eq(GameState.quest_state(QUEST), &"done")
	assert_eq(GameState.count(&"tiat_drawing"), 1, "le dessin de Tiat")
	assert_true(GameState.has_flag(&"vigil_record"))
	assert_eq(GameState.max_hp, 7, "PV max portés à 7")
	assert_string_contains(talk(TIAT)[0], "souligné deux fois")


func test_the_register_can_wait() -> void:
	GameState.set_flag(&"first_vigil_done")
	assert_string_contains(talk(TIAT, [-1, 1, -1])[2], "page blanche")
	assert_eq(GameState.quest_state(QUEST), &"")
	assert_eq(QuestData.state_of(QUEST), &"available")
