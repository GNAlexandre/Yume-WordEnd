extends "res://tests/stubs/q_quest_test.gd"
## Acte 1, quête secondaire flying_laundry « Le linge envolé » (HISTOIRE.md 3.2), jouée avec le
## vrai moteur et les vrais dialogues : Nygglatho la propose une fois Willem salué ; cinq draps
## rapportés (retirés) ; le thé dans sa chambre, la leçon sur les Timeres et le cheese-cake
## caché ; récompenses : une part de cheese-cake, drapeau laundry_done, et la quête des myosotis.

const QUEST := &"flying_laundry"
const NYGGLATHO := preload("res://data/npcs/nygglatho.tres")


func test_flying_laundry_from_offer_to_tea() -> void:
	assert_eq(QuestData.state_of(QUEST), &"", "pas avant d'avoir salué Willem")
	GameState.set_flag(&"met_willem")
	assert_eq(QuestData.npc_marker(&"nygglatho"), QuestData.MARKER_AVAILABLE, "« ! »")
	var said := talk(NYGGLATHO, [-1, 0, -1])
	assert_string_contains(said[0], "Une catastrophe")
	assert_eq(step_of(QUEST), &"sheets")
	# Cinq draps envolés, rapportés à Nygglatho.
	GameState.add_item(&"laundry_sheet", 4)
	assert_eq(QuestData.find(QUEST).current_progress(), "Drap envolé : 4/5")
	assert_string_contains(talk(NYGGLATHO)[0], "encore 1")
	assert_eq(step_of(QUEST), &"sheets", "il en manque un")
	GameState.add_item(&"laundry_sheet")
	assert_eq(QuestData.npc_marker(&"nygglatho"), QuestData.MARKER_TURN_IN, "« ? »")
	said = talk(NYGGLATHO, [-1, 0, -1, -1, -1, 0, -1])
	assert_eq(said.size(), 7, "les draps, puis le thé dans la même conversation")
	assert_string_contains(said[0], "Les cinq")
	assert_string_contains(said[4], "précognition")
	assert_string_contains(said[6], "Mange")
	assert_eq(GameState.quest_state(QUEST), &"done")
	assert_eq(GameState.count(&"laundry_sheet"), 0, "draps rendus")
	assert_eq(GameState.count(&"cheesecake_slice"), 1, "une part de cheese-cake")
	assert_true(GameState.has_flag(&"laundry_done"))
	assert_eq(QuestData.state_of(&"forget_me_nots"), &"available", "la suite : les myosotis")


func test_the_tea_can_wait() -> void:
	GameState.set_flag(&"met_willem")
	start_quest(QUEST)
	GameState.add_item(&"laundry_sheet", 5)
	var said := talk(NYGGLATHO, [-1, 1, -1])
	assert_string_contains(said[2], "Je garde la théière au chaud")
	assert_eq(step_of(QUEST), &"tea", "draps rendus, le thé attend")
	assert_eq(GameState.count(&"laundry_sheet"), 0)
	said = talk(NYGGLATHO, [-1, -1, -1, 1, -1])
	assert_string_contains(said[0], "Assieds-toi")
	assert_eq(GameState.quest_state(QUEST), &"done")
