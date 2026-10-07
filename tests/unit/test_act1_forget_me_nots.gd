extends "res://tests/stubs/q_quest_test.gd"
## Acte 1, quête secondaire forget_me_nots « Celles dont on se souvient » (HISTOIRE.md 3.2),
## jouée avec le vrai moteur et les vrais dialogues : après le linge, Nygglatho demande cinq
## myosotis pour son vase ; ils sont rapportés (retirés) ; elle dit les noms de celles qui ne
## sont pas revenues ; récompenses : un myosotis séché, drapeau forget_me_nots_given.

const QUEST := &"forget_me_nots"
const NYGGLATHO := preload("res://data/npcs/nygglatho.tres")


func test_forget_me_nots_from_offer_to_the_vase() -> void:
	GameState.set_flag(&"met_willem")
	assert_eq(QuestData.state_of(QUEST), &"", "pas avant le linge")
	complete_quest(&"flying_laundry")
	assert_eq(QuestData.state_of(QUEST), &"available")
	assert_eq(QuestData.npc_marker(&"nygglatho"), QuestData.MARKER_AVAILABLE, "« ! »")
	var said := talk(NYGGLATHO, [-1, 0, -1])
	assert_string_contains(said[0], "le vase")
	assert_eq(step_of(QUEST), &"flowers")
	# Cinq myosotis, rapportés à Nygglatho.
	GameState.add_item(&"flower_blue", 4)
	assert_string_contains(talk(NYGGLATHO)[0], "Encore 1 myosotis")
	assert_eq(step_of(QUEST), &"flowers")
	GameState.add_item(&"flower_blue", 2)
	said = talk(NYGGLATHO, [-1, 0, -1, -1, -1, 0, -1])
	assert_eq(said.size(), 7, "les fleurs, puis le vase dans la même conversation")
	assert_string_contains(said[3], "Tuca")
	assert_string_contains(said[6], "faire sécher")
	assert_eq(GameState.quest_state(QUEST), &"done")
	assert_eq(GameState.count(&"flower_blue"), 1, "cinq myosotis rendus, un gardé")
	assert_eq(GameState.count(&"pressed_forget_me_not"), 1, "un myosotis séché")
	assert_true(GameState.has_flag(&"forget_me_nots_given"))


func test_the_vase_can_wait() -> void:
	GameState.set_flag(&"met_willem")
	complete_quest(&"flying_laundry")
	start_quest(QUEST)
	GameState.add_item(&"flower_blue", 5)
	talk(NYGGLATHO, [-1, 1, -1])
	assert_eq(step_of(QUEST), &"vase", "fleurs rendues, le vase attend")
	var said := talk(NYGGLATHO, [-1, -1, -1, 1, -1])
	assert_string_contains(said[0], "Ce vase")
	assert_eq(GameState.quest_state(QUEST), &"done")
