extends GutTest
## QuestTracker (L7) : une quête aux objets requis n'est terminée que si count >= required ;
## sinon elle revient à active (completion_refused). Acte 1 : le livre d'images (5 pages à
## rapporter à Nephren) ; terminée, pages retirées et livre donné. PV max portés à 7 (donnée de
## vigil_register.json) avec max_hp_changed, jamais baissés.

var _tracker: QuestTracker


func before_each() -> void:
	GameState.reset()
	_tracker = add_child_autofree(QuestTracker.new())


func after_all() -> void:
	GameState.reset()


func test_refuses_completion_without_enough_pages() -> void:
	GameState.set_quest_state(&"picture_book", &"active")
	GameState.add_item(&"page_fragment", 4)
	watch_signals(EventBus)
	watch_signals(_tracker)
	GameState.set_quest_state(&"picture_book", &"done")
	assert_eq(GameState.quest_state(&"picture_book"), &"active", "remise à active")
	assert_eq(GameState.count(&"page_fragment"), 4, "rien n'est retiré")
	assert_eq(GameState.count(&"picture_book"), 0, "pas de récompense")
	assert_eq(GameState.max_hp, GameState.DEFAULT_MAX_HP)
	assert_signal_emitted_with_parameters(
		_tracker, "completion_refused", [&"picture_book", {&"page_fragment": 1}]
	)
	assert_signal_not_emitted(_tracker, "quest_completed")
	assert_signal_not_emitted(EventBus, "max_hp_changed")


func test_completes_with_enough_pages() -> void:
	GameState.set_quest_state(&"picture_book", &"active")
	GameState.add_item(&"page_fragment", 7)
	GameState.add_item(&"flower_blue", 2)
	watch_signals(_tracker)
	GameState.set_quest_state(&"picture_book", &"done")
	assert_eq(GameState.quest_state(&"picture_book"), &"done")
	assert_eq(GameState.count(&"page_fragment"), 2, "5 pages rapportées, 2 gardées")
	assert_eq(GameState.count(&"flower_blue"), 2, "les autres objets ne bougent pas")
	assert_eq(GameState.count(&"picture_book"), 1, "livre d'images reçu")
	assert_true(GameState.has_flag(&"book_read"), "drapeau de la récompense")
	assert_signal_emitted_with_parameters(_tracker, "quest_completed", [&"picture_book"])
	assert_signal_not_emitted(_tracker, "completion_refused")


func test_max_hp_reward_is_data() -> void:
	watch_signals(EventBus)
	GameState.set_quest_state(&"vigil_register", &"done")
	assert_eq(GameState.quest_state(&"vigil_register"), &"done", "rien à rapporter")
	assert_eq(GameState.max_hp, 7, "PV max portés à 7")
	assert_signal_emitted_with_parameters(EventBus, "max_hp_changed", [7])
	assert_eq(GameState.count(&"tiat_drawing"), 1, "dessin de Tiat reçu")


func test_exactly_the_required_count_is_enough() -> void:
	GameState.add_item(&"page_fragment", 5)
	GameState.set_quest_state(&"picture_book", &"done")
	assert_eq(GameState.quest_state(&"picture_book"), &"done")
	assert_eq(GameState.count(&"page_fragment"), 0)
	assert_eq(GameState.items(), {&"picture_book": 1})


func test_completion_after_a_refusal() -> void:
	GameState.add_item(&"page_fragment", 3)
	GameState.set_quest_state(&"picture_book", &"done")
	assert_eq(GameState.quest_state(&"picture_book"), &"active")
	GameState.add_item(&"page_fragment", 2)
	GameState.set_quest_state(&"picture_book", &"done")
	assert_eq(GameState.quest_state(&"picture_book"), &"done")
	assert_eq(GameState.count(&"picture_book"), 1)


func test_max_hp_is_never_lowered() -> void:
	GameState.max_hp = 8
	watch_signals(EventBus)
	GameState.set_quest_state(&"vigil_register", &"done")
	assert_eq(GameState.max_hp, 8)
	assert_signal_not_emitted(EventBus, "max_hp_changed")
	assert_eq(GameState.count(&"tiat_drawing"), 1)


func test_ignores_other_states_and_unknown_quests() -> void:
	GameState.add_item(&"page_fragment", 5)
	GameState.set_quest_state(&"picture_book", &"active")
	GameState.set_quest_state(&"unknown_quest", &"done")
	assert_eq(GameState.count(&"page_fragment"), 5, "active : rien ne bouge")
	assert_eq(
		GameState.quest_state(&"unknown_quest"),
		&"done",
		"quête sans données : laissée telle quelle"
	)


func test_requirements_helpers() -> void:
	var quest := QuestData.new()
	quest.required_items = {&"shell": 2}
	quest.required_flags = [&"met_librarian"]
	assert_eq(QuestTracker.missing_items(quest), {&"shell": 2})
	assert_eq(QuestTracker.missing_flags(quest), [&"met_librarian"] as Array[StringName])
	assert_false(QuestTracker.can_complete(quest))
	GameState.add_item(&"shell", 2)
	GameState.set_flag(&"met_librarian")
	assert_true(QuestTracker.can_complete(quest))


func test_only_one_tracker_rewards() -> void:
	add_child_autofree(QuestTracker.new())
	GameState.add_item(&"page_fragment", 5)
	GameState.set_quest_state(&"picture_book", &"done")
	assert_eq(
		GameState.quest_state(&"picture_book"), &"done", "le second suivi ne remet pas à active"
	)
	assert_eq(GameState.count(&"picture_book"), 1, "une seule récompense")
