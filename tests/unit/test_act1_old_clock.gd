extends "res://tests/stubs/q_quest_test.gd"
## Acte 1, quête secondaire old_clock « L’homme-chat » (HISTOIRE.md 3.2), jouée avec le vrai
## moteur et les vrais dialogues : Ithea a vu Willem avec un homme-chat ; le serveur du café
## renseigne ; M. Rami raconte son horloge ; trois engrenages et un peigne de carillon ; Willem
## répare (les pièces sont prises) ; l'horloge sonne faux ; récompenses : la carte de M. Rami,
## drapeau rami_clock_fixed.

const QUEST := &"old_clock"
const ITHEA := preload("res://data/npcs/ithea.tres")
const CAT_WAITER := preload("res://data/npcs/cat_waiter.tres")
const RAMIKELDI := preload("res://data/npcs/ramikeldi.tres")
const WILLEM := preload("res://data/npcs/willem.tres")


func test_old_clock_from_the_rumour_to_the_chime() -> void:
	assert_eq(QuestData.state_of(QUEST), &"", "pas avant d'avoir salué Willem")
	GameState.set_flag(&"met_willem")
	assert_eq(QuestData.npc_marker(&"ithea"), QuestData.MARKER_AVAILABLE, "« ! »")
	var said := talk(ITHEA, [-1, 0, -1])
	assert_string_contains(said[0], "homme-chat")
	assert_eq(step_of(QUEST), &"cafe")
	assert_string_contains(talk(ITHEA)[0], "Alors, cet homme-chat")
	# Le serveur du café.
	assert_eq(QuestData.npc_marker(&"cat_waiter"), QuestData.MARKER_TURN_IN)
	said = talk(CAT_WAITER, [-1, -1, -1])
	assert_string_contains(said[1], "M. Rami")
	assert_eq(step_of(QUEST), &"rami")
	# M. Rami et son horloge.
	said = talk(RAMIKELDI, [-1, -1, -1, -1, -1])
	assert_eq(said.size(), 5)
	assert_string_contains(said[2], "horloge")
	assert_eq(step_of(QUEST), &"gears")
	assert_string_contains(talk(RAMIKELDI)[0], "Trois engrenages")
	# Les pièces : trois engrenages, un peigne de carillon.
	GameState.add_item(&"clock_gear", 2)
	assert_eq(QuestData.find(QUEST).current_progress(), "Engrenage de laiton : 2/3")
	GameState.add_item(&"clock_gear")
	assert_eq(step_of(QUEST), &"comb")
	assert_string_contains(talk(RAMIKELDI)[0], "peigne de carillon")
	GameState.add_item(&"clock_comb")
	assert_eq(step_of(QUEST), &"repair")
	# Willem répare : les pièces sont prises.
	assert_eq(QuestData.npc_marker(&"willem"), QuestData.MARKER_TURN_IN, "« ? »")
	said = talk(WILLEM, [-1, -1, 0, -1])
	assert_string_contains(said[0], "engrenages de laiton")
	assert_string_contains(said[3], "Partir\u00a0?")
	assert_eq(step_of(QUEST), &"chime")
	assert_eq(GameState.count(&"clock_gear"), 0, "engrenages pris")
	assert_eq(GameState.count(&"clock_comb"), 0, "peigne pris")
	said = talk(RAMIKELDI, [-1, -1, -1])
	assert_string_contains(said[0], "Un déclic")
	assert_string_contains(said[2], "Ma carte")
	assert_eq(GameState.quest_state(QUEST), &"done")
	assert_eq(GameState.count(&"rami_card"), 1, "la carte de M. Rami")
	assert_true(GameState.has_flag(&"rami_clock_fixed"))
	# Ensuite : Ithea en reparle une fois.
	assert_string_contains(talk(ITHEA)[0], "Juste un voisin")
	assert_string_contains(talk(RAMIKELDI)[0], "Les voisins se plaignent")


func test_the_cafe_waiter_also_gives_the_cream() -> void:
	# Deux scènes chez le même PNJ : la question du dessert vient après celle de l'horloge.
	GameState.set_flag(&"met_willem")
	start_quest(QUEST)
	start_quest(&"special_dessert")
	var said := talk(CAT_WAITER, [-1, -1, 0, -1])
	assert_eq(said.size(), 4)
	assert_string_contains(said[3], "De la crème fraîche")
	assert_eq(step_of(QUEST), &"rami")
	assert_eq(GameState.count(&"fresh_cream"), 1)
	assert_true(GameState.has_flag(&"cream_given"))
