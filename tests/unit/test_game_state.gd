extends GutTest
## GameState (implémentation minimale du Lot 0) : inventaire, drapeaux, quêtes, pickups,
## scores, propriétés, signaux et sérialisation.


func before_each() -> void:
	GameState.reset()


func after_all() -> void:
	GameState.reset()


func test_inventory() -> void:
	watch_signals(EventBus)
	GameState.add_item(&"page_fragment", 3)
	assert_eq(GameState.count(&"page_fragment"), 3)
	assert_signal_emit_count(EventBus, "inventory_changed", 1)
	assert_false(GameState.remove_item(&"page_fragment", 4), "pas assez")
	assert_eq(GameState.count(&"page_fragment"), 3)
	assert_true(GameState.remove_item(&"page_fragment", 3))
	assert_eq(GameState.count(&"page_fragment"), 0)
	assert_false(GameState.items().has(&"page_fragment"), "quantité nulle retirée")
	assert_signal_emit_count(EventBus, "inventory_changed", 2)


func test_items_returns_a_copy() -> void:
	GameState.add_item(&"flower_blue")
	var items := GameState.items()
	items[&"flower_blue"] = 99
	assert_eq(GameState.count(&"flower_blue"), 1)


func test_flags() -> void:
	assert_false(GameState.has_flag(&"quest_pages_accepted"))
	GameState.set_flag(&"quest_pages_accepted")
	assert_true(GameState.has_flag(&"quest_pages_accepted"))
	GameState.set_flag(&"quest_pages_accepted", false)
	assert_false(GameState.has_flag(&"quest_pages_accepted"))


func test_quests_emit_quest_updated() -> void:
	watch_signals(EventBus)
	assert_eq(GameState.quest_state(&"pages"), &"")
	GameState.set_quest_state(&"pages", &"active")
	assert_eq(GameState.quest_state(&"pages"), &"active")
	assert_signal_emitted_with_parameters(EventBus, "quest_updated", [&"pages", &"active"])
	GameState.set_quest_state(&"pages", &"active")
	assert_signal_emit_count(EventBus, "quest_updated", 1, "pas de signal si l'état ne change pas")


func test_pickups() -> void:
	assert_false(GameState.is_pickup_collected(&"forest_page_1"))
	GameState.mark_pickup_collected(&"forest_page_1")
	assert_true(GameState.is_pickup_collected(&"forest_page_1"))


func test_record_score() -> void:
	assert_eq(GameState.best_score(&"dunes"), 0)
	assert_true(GameState.record_score(&"dunes", 640, 6), "premier score > 0 : record")
	assert_false(GameState.record_score(&"dunes", 300, 4))
	assert_false(GameState.record_score(&"dunes", 640, 7), "égalité : pas un record (comme jeu.js)")
	assert_eq(GameState.best_score(&"dunes"), 640)
	var scores: Dictionary = GameState.to_dict()["best_scores"]
	assert_eq(scores["dunes"], {"score": 640, "wave": 6, "games": 3})


func test_properties_emit_signals() -> void:
	watch_signals(EventBus)
	GameState.skin_id = &"chtholly"
	GameState.max_hp = 6
	assert_signal_emitted_with_parameters(EventBus, "skin_changed", [&"chtholly"])
	assert_signal_emitted_with_parameters(EventBus, "max_hp_changed", [6])
	GameState.max_hp = 6
	assert_signal_emit_count(EventBus, "max_hp_changed", 1)


func test_to_dict_matches_save_schema() -> void:
	GameState.skin_id = &"chtholly"
	GameState.position = Vector3(12.0, 1.0, -4.5)
	GameState.zone = &"village"
	GameState.add_item(&"page_fragment", 3)
	GameState.set_flag(&"quest_pages_accepted")
	GameState.set_quest_state(&"pages", &"active")
	GameState.mark_pickup_collected(&"forest_page_1")
	GameState.record_score(&"dunes", 640, 6)
	var data := GameState.to_dict()
	var keys: Array = data.keys()
	keys.sort()
	assert_eq(
		keys,
		[
			"best_scores",
			"collected_pickups",
			"flags",
			"inventory",
			"max_hp",
			"position",
			"quests",
			"skin",
			"zone",
		]
	)
	assert_eq(data["skin"], "chtholly")
	assert_eq(data["max_hp"], 5)
	assert_eq(data["position"], [12.0, 1.0, -4.5])
	assert_eq(data["zone"], "village")
	assert_eq(data["inventory"], {"page_fragment": 3})
	assert_eq(data["flags"], {"quest_pages_accepted": true})
	assert_eq(data["quests"], {"pages": "active"})
	assert_eq(data["collected_pickups"], ["forest_page_1"])


func test_from_dict_reads_json_numbers_and_missing_fields() -> void:
	var text := '{"skin": "chtholly", "max_hp": 6, "position": [1, 2, 3], "zone": "forest",'
	text += ' "inventory": {"page_fragment": 2.0}, "quests": {"pages": "done"}}'
	GameState.from_dict(JSON.parse_string(text))
	assert_eq(GameState.skin_id, &"chtholly")
	assert_eq(GameState.max_hp, 6)
	assert_eq(GameState.position, Vector3(1, 2, 3))
	assert_eq(GameState.zone, &"forest")
	assert_eq(GameState.count(&"page_fragment"), 2)
	assert_eq(GameState.quest_state(&"pages"), &"done")
	assert_false(GameState.has_flag(&"anything"), "champ absent : valeur par défaut")
	assert_eq(GameState.best_score(&"dunes"), 0)


func test_round_trip_is_identical() -> void:
	GameState.skin_id = &"forgeron"
	GameState.max_hp = 6
	GameState.position = Vector3(-3.25, 0.5, 8.0)
	GameState.zone = &"beach"
	GameState.add_item(&"page_fragment", 5)
	GameState.set_flag(&"met_librarian")
	GameState.set_quest_state(&"pages", &"done")
	GameState.mark_pickup_collected(&"beach_shell_2")
	GameState.record_score(&"dunes", 120, 2)
	var first := GameState.to_dict()
	var text := JSON.stringify(first, "", true)
	GameState.reset()
	GameState.from_dict(JSON.parse_string(text))
	assert_eq(JSON.stringify(GameState.to_dict(), "", true), text)


func test_reset() -> void:
	GameState.add_item(&"page_fragment")
	GameState.zone = &"forest"
	GameState.max_hp = 6
	GameState.reset()
	assert_eq(GameState.count(&"page_fragment"), 0)
	assert_eq(GameState.zone, &"")
	assert_eq(GameState.max_hp, GameState.DEFAULT_MAX_HP)
	assert_eq(GameState.skin_id, &"")
