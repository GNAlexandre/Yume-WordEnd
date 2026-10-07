extends "res://tests/stubs/q_quest_test.gd"
## Acte 1, quête secondaire picture_book « Le livre d’images » (HISTOIRE.md 3.2), jouée avec le
## vrai moteur et les vrais dialogues : Nephren la propose une fois Willem salué ; cinq pages des
## bois rapportées (retirées) ; Willem lit le livre aux petites (scène à plusieurs voix) ;
## récompenses : le livre et le drapeau book_read.

const QUEST := &"picture_book"
const NEPHREN := preload("res://data/npcs/nephren.tres")
const WILLEM := preload("res://data/npcs/willem.tres")


func test_picture_book_from_offer_to_reading() -> void:
	assert_eq(QuestData.state_of(QUEST), &"", "pas avant d'avoir salué Willem")
	assert_eq(QuestData.npc_marker(&"nephren"), &"")
	GameState.set_flag(&"met_willem")
	assert_eq(QuestData.state_of(QUEST), &"available")
	assert_eq(QuestData.npc_marker(&"nephren"), QuestData.MARKER_AVAILABLE, "« ! »")
	var said := talk(NEPHREN, [-1, 0, -1])
	assert_eq(said[0], "Livre. Vent. Pages.")
	assert_eq(GameState.quest_state(QUEST), &"active", "start_quest")
	assert_eq(step_of(QUEST), &"pages")
	assert_eq(GameState.tracked_quest, QUEST, "la quête qui commence est suivie")
	# Étape 1 (collect, à rapporter à Nephren) : cinq pages.
	GameState.add_item(&"page_fragment", 3)
	assert_eq(QuestData.find(QUEST).current_progress(), "Page du livre d’images : 3/5")
	assert_eq(talk(NEPHREN)[0], "Encore 2. Mm.")
	assert_eq(step_of(QUEST), &"pages", "pas assez de pages")
	assert_eq(GameState.count(&"page_fragment"), 3, "rien n'est retiré")
	GameState.add_item(&"page_fragment", 2)
	assert_eq(QuestData.npc_marker(&"nephren"), QuestData.MARKER_TURN_IN, "« ? »")
	said = talk(NEPHREN, [-1, -1, -1])
	assert_eq(said[0], "Cinq. Mm.")
	assert_eq(step_of(QUEST), &"reading")
	assert_eq(GameState.count(&"page_fragment"), 0, "pages rendues")
	assert_eq(talk(NEPHREN)[0], "Willem. Lecture. Les petites attendent.")
	# Étape 2 (talk) : Willem lit, les petites l'interrompent.
	assert_eq(QuestData.npc_marker(&"willem"), QuestData.MARKER_TURN_IN)
	said = talk(WILLEM, [-1, -1, -1, -1, -1, -1])
	assert_eq(said.size(), 6, "la lecture d'abord, avant le dessert à proposer")
	assert_string_contains(said[0], "Le livre d’images, recollé")
	assert_string_contains(said[1], "emnetwiht")
	assert_eq(GameState.quest_state(QUEST), &"done")
	assert_eq(GameState.count(&"picture_book"), 1, "le livre d'images")
	assert_true(GameState.has_flag(&"book_read"))
	# Ensuite, Nephren en reparle une fois.
	assert_string_contains(talk(NEPHREN)[0], "Il a bien lu")
	assert_eq(talk(NEPHREN)[0], "Willem. Il lit lentement. C’est bien.")


func test_the_offer_can_wait() -> void:
	GameState.set_flag(&"met_willem")
	assert_eq(talk(NEPHREN, [-1, 1, -1])[2], "Mm.")
	assert_eq(GameState.quest_state(QUEST), &"", "« Plus tard » : rien ne change")
	assert_eq(QuestData.state_of(QUEST), &"available", "toujours proposée")
	talk(NEPHREN, [-1, 0, -1])
	assert_eq(GameState.quest_state(QUEST), &"active")
