extends GutTest
## QuestTracker (L7) : la quête des pages n'est terminée que si count >= required ; sinon elle
## revient à active (completion_refused). Terminée : fragments retirés, marque-page donné, PV max
## portés à 6 (donnée de pages.tres) avec max_hp_changed.

var _tracker: QuestTracker


func before_each() -> void:
	GameState.reset()
	_tracker = add_child_autofree(QuestTracker.new())


func after_all() -> void:
	GameState.reset()


func test_refuses_completion_without_enough_pages() -> void:
	GameState.set_quest_state(&"pages", &"active")
	GameState.add_item(&"page_fragment", 4)
	watch_signals(EventBus)
	watch_signals(_tracker)
	GameState.set_quest_state(&"pages", &"done")
	assert_eq(GameState.quest_state(&"pages"), &"active", "remise à active")
	assert_eq(GameState.count(&"page_fragment"), 4, "rien n'est retiré")
	assert_eq(GameState.count(&"bookmark"), 0, "pas de récompense")
	assert_eq(GameState.max_hp, GameState.DEFAULT_MAX_HP)
	assert_signal_emitted_with_parameters(
		_tracker, "completion_refused", [&"pages", {&"page_fragment": 1}]
	)
	assert_signal_not_emitted(_tracker, "quest_completed")
	assert_signal_not_emitted(EventBus, "max_hp_changed")


func test_completes_with_enough_pages() -> void:
	GameState.set_quest_state(&"pages", &"active")
	GameState.add_item(&"page_fragment", 7)
	GameState.add_item(&"shell", 2)
	watch_signals(EventBus)
	watch_signals(_tracker)
	GameState.set_quest_state(&"pages", &"done")
	assert_eq(GameState.quest_state(&"pages"), &"done")
	assert_eq(GameState.count(&"page_fragment"), 2, "5 fragments rapportés, 2 gardés")
	assert_eq(GameState.count(&"shell"), 2, "les autres objets ne bougent pas")
	assert_eq(GameState.count(&"bookmark"), 1, "marque-page reçu")
	assert_eq(GameState.max_hp, 6, "PV max portés à 6")
	assert_signal_emitted_with_parameters(EventBus, "max_hp_changed", [6])
	assert_signal_emitted_with_parameters(_tracker, "quest_completed", [&"pages"])
	assert_signal_not_emitted(_tracker, "completion_refused")


func test_exactly_the_required_count_is_enough() -> void:
	GameState.add_item(&"page_fragment", 5)
	GameState.set_quest_state(&"pages", &"done")
	assert_eq(GameState.quest_state(&"pages"), &"done")
	assert_eq(GameState.count(&"page_fragment"), 0)
	assert_eq(GameState.items(), {&"bookmark": 1})


func test_completion_after_a_refusal() -> void:
	GameState.add_item(&"page_fragment", 3)
	GameState.set_quest_state(&"pages", &"done")
	assert_eq(GameState.quest_state(&"pages"), &"active")
	GameState.add_item(&"page_fragment", 2)
	GameState.set_quest_state(&"pages", &"done")
	assert_eq(GameState.quest_state(&"pages"), &"done")
	assert_eq(GameState.max_hp, 6)


func test_max_hp_is_never_lowered() -> void:
	GameState.max_hp = 8
	GameState.add_item(&"page_fragment", 5)
	watch_signals(EventBus)
	GameState.set_quest_state(&"pages", &"done")
	assert_eq(GameState.max_hp, 8)
	assert_signal_not_emitted(EventBus, "max_hp_changed")
	assert_eq(GameState.count(&"bookmark"), 1)


func test_ignores_other_states_and_unknown_quests() -> void:
	GameState.add_item(&"page_fragment", 5)
	GameState.set_quest_state(&"pages", &"active")
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
	GameState.set_quest_state(&"pages", &"done")
	assert_eq(GameState.quest_state(&"pages"), &"done", "le second suivi ne remet pas à active")
	assert_eq(GameState.count(&"bookmark"), 1, "une seule récompense")
