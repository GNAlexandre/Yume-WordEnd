extends GutTest
## GameState (L7) : inventaire et piles, drapeaux, pickups, propriétés, signaux, schéma exact de
## to_dict et relecture robuste de from_dict. (F1) Les quêtes, les scores d'arène, la zone et la
## quête suivie sont partis avec l'ancienne île : to_dict ne les écrit plus, from_dict les ignore.
## Les piles lisent les objets de tests/data/items.

const TEST_ITEMS_DIR := "res://tests/data/items"


func before_each() -> void:
	GameState.reset()
	ItemData.add_search_dir(TEST_ITEMS_DIR)


func after_each() -> void:
	ItemData.remove_search_dir(TEST_ITEMS_DIR)


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


func test_invalid_changes_do_nothing() -> void:
	watch_signals(EventBus)
	GameState.add_item(&"shell", 0)
	GameState.add_item(&"shell", -3)
	GameState.add_item(&"", 2)
	assert_false(GameState.remove_item(&"shell", 0))
	assert_false(GameState.remove_item(&"shell"), "retrait impossible : aucun exemplaire")
	assert_eq(GameState.items(), {})
	assert_signal_not_emitted(EventBus, "inventory_changed")


func test_stacks_follow_item_data() -> void:
	GameState.add_item(&"test_page", 120)
	GameState.add_item(&"test_picture", 2)
	GameState.add_item(&"test_flower", 3)
	assert_eq(GameState.count(&"test_page"), 120, "count = total de toutes les piles")
	assert_eq(
		GameState.stacks(),
		[
			{"item_id": &"test_flower", "quantity": 3},
			{"item_id": &"test_page", "quantity": 99},
			{"item_id": &"test_page", "quantity": 21},
			{"item_id": &"test_picture", "quantity": 1},
			{"item_id": &"test_picture", "quantity": 1},
		],
		"non empilable : une case chacun ; max_stack 99 : deux piles"
	)
	assert_true(GameState.remove_item(&"test_page", 100), "retrait sur deux piles")
	assert_false(GameState.remove_item(&"test_picture", 3), "retrait impossible : deux seulement")
	assert_eq(GameState.count(&"test_picture"), 2)
	assert_eq(GameState.stacks()[1], {"item_id": &"test_page", "quantity": 20})


func test_unknown_item_is_accepted() -> void:
	GameState.add_item(&"mystery_box", 2)
	assert_eq(GameState.count(&"mystery_box"), 2)
	assert_eq(GameState.stacks(), [{"item_id": &"mystery_box", "quantity": 2}])


func test_quantity_is_capped() -> void:
	GameState.add_item(&"shell", GameState.MAX_QUANTITY + 50)
	GameState.add_item(&"shell")
	assert_eq(GameState.count(&"shell"), GameState.MAX_QUANTITY)


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
	GameState.set_flag(&"")
	assert_false(GameState.to_dict()["flags"].has(""), "drapeau sans nom ignoré")


func test_pickups() -> void:
	assert_false(GameState.is_pickup_collected(&"forest_page_1"))
	GameState.mark_pickup_collected(&"forest_page_1")
	assert_true(GameState.is_pickup_collected(&"forest_page_1"))


func test_properties_emit_signals() -> void:
	watch_signals(EventBus)
	GameState.skin_id = &"chtholly"
	GameState.max_hp = 6
	assert_signal_emitted_with_parameters(EventBus, "skin_changed", [&"chtholly"])
	assert_signal_emitted_with_parameters(EventBus, "max_hp_changed", [6])
	GameState.max_hp = 6
	assert_signal_emit_count(EventBus, "max_hp_changed", 1)
	GameState.max_hp = 0
	assert_eq(GameState.max_hp, 1, "jamais moins de 1 PV max")
	GameState.max_hp = 1000000
	assert_eq(GameState.max_hp, GameState.MAX_HP_LIMIT, "PV max plafonnés")


func test_to_dict_matches_save_schema() -> void:
	GameState.skin_id = &"chtholly"
	GameState.position = Vector3(12.0, 1.0, -4.5)
	GameState.map = &"essai"
	GameState.add_item(&"page_fragment", 3)
	GameState.set_flag(&"quest_pages_accepted")
	GameState.mark_pickup_collected(&"forest_page_1")
	var data := GameState.to_dict()
	var keys: Array = data.keys()
	keys.sort()
	assert_eq(
		keys,
		[
			"calendar",
			"collected_pickups",
			"day",
			"flags",
			"inventory",
			"island",
			"known_islands",
			"map",
			"max_hp",
			"moment",
			"position",
			"scenes_done",
			"skin",
			"slot",
			"story_scene",
			"weather",
		],
		"(F1) v4 : ni zone, ni quêtes, ni scores"
	)
	assert_eq(data["skin"], "chtholly")
	assert_eq(data["max_hp"], 5)
	assert_eq(data["position"], [12.0, 1.0, -4.5])
	assert_eq(data["map"], "essai", "(E1) carte courante")
	assert_eq(data["inventory"], {"page_fragment": 3})
	assert_eq(data["flags"], {"quest_pages_accepted": true})
	assert_eq(data["collected_pickups"], ["forest_page_1"])


func test_from_dict_reads_json_numbers_and_missing_fields() -> void:
	var text := '{"skin": "chtholly", "max_hp": 6, "position": [1, 2, 3], "zone": "forest",'
	text += ' "inventory": {"page_fragment": 2.0}, "quests": {"pages": "done"}}'
	GameState.from_dict(JSON.parse_string(text))
	assert_eq(GameState.skin_id, &"chtholly")
	assert_eq(GameState.max_hp, 6)
	assert_eq(GameState.position, Vector3(1, 2, 3))
	assert_eq(GameState.count(&"page_fragment"), 2)
	assert_false(GameState.has_flag(&"anything"), "champ absent : valeur par défaut")
	assert_false(GameState.to_dict().has("quests"), "(F1) champs de l'ancienne île ignorés")
	assert_false(GameState.to_dict().has("zone"))
	GameState.from_dict({})
	assert_eq(GameState.max_hp, GameState.DEFAULT_MAX_HP, "dictionnaire vide : nouvelle partie")
	assert_eq(GameState.items(), {})


func test_from_dict_ignores_badly_typed_fields() -> void:
	(
		GameState
		. from_dict(
			{
				"skin": 42,
				"max_hp": "beaucoup",
				"position": [1, "deux", 3],
				"zone": ["forest"],
				"inventory":
				{"page_fragment": "3", "shell": 2.0, "flower_blue": -1, "bookmark": 1.9},
				"flags": {"ok": true, "num": 1, "bad": "true"},
				"collected_pickups": "forest_page_1",
			}
		)
	)
	assert_eq(GameState.skin_id, &"")
	assert_eq(GameState.max_hp, GameState.DEFAULT_MAX_HP)
	assert_eq(GameState.position, Vector3.ZERO)
	assert_eq(GameState.count(&"page_fragment"), 0, "quantité en texte ignorée")
	assert_eq(GameState.count(&"shell"), 2)
	assert_eq(GameState.count(&"flower_blue"), 0, "quantité négative ignorée")
	assert_eq(GameState.count(&"bookmark"), 1)
	assert_true(GameState.has_flag(&"ok") and GameState.has_flag(&"num"))
	assert_false(GameState.has_flag(&"bad"), "drapeau en texte ignoré")
	assert_false(GameState.is_pickup_collected(&"forest_page_1"))


func test_from_dict_without_valid_position_restarts_at_the_spawn() -> void:
	GameState.from_dict({"map": "essai"})
	assert_eq(GameState.map, &"", "position absente : game.gd pose au Spawn de la carte de départ")
	GameState.from_dict({"map": "essai", "position": [5.0, 0.0, 1e9]})
	assert_eq(GameState.map, &"", "position hors de toute carte")
	assert_eq(GameState.position, Vector3.ZERO)
	GameState.from_dict({"map": "essai", "position": [5.0, 0.5, 14.0]})
	assert_eq(GameState.map, &"essai")
	assert_eq(GameState.position, Vector3(5.0, 0.5, 14.0))


func test_from_dict_announces_the_inventory_only() -> void:
	watch_signals(EventBus)
	GameState.from_dict({"flags": {"seen": true}, "inventory": {"bookmark": 1}})
	assert_signal_emitted(EventBus, "inventory_changed")
	assert_signal_not_emitted(EventBus, "flag_changed", "un chargement ne rejoue pas les drapeaux")


func test_round_trip_is_identical() -> void:
	GameState.skin_id = &"ithea"
	GameState.max_hp = 6
	GameState.position = Vector3(-3.25, 0.5, 8.0)
	GameState.map = &"essai"
	GameState.add_item(&"page_fragment", 5)
	GameState.add_item(&"mystery_box")
	GameState.set_flag(&"met_librarian")
	GameState.set_flag(&"gate_open", false)
	GameState.mark_pickup_collected(&"beach_shell_2")
	GameState.mark_pickup_collected(&"forest_page_1")
	GameState.day = 4
	GameState.mark_scene_done(&"j1_1_port")
	var first := GameState.to_dict()
	var text := JSON.stringify(first, "", true)
	GameState.reset()
	GameState.from_dict(JSON.parse_string(text))
	assert_eq(JSON.stringify(GameState.to_dict(), "", true), text)


func test_reset() -> void:
	GameState.add_item(&"page_fragment")
	GameState.map = &"essai"
	GameState.max_hp = 6
	GameState.day = 3
	GameState.reset()
	assert_eq(GameState.count(&"page_fragment"), 0)
	assert_eq(GameState.map, &"")
	assert_eq(GameState.max_hp, GameState.DEFAULT_MAX_HP)
	assert_eq(GameState.skin_id, &"")
	assert_eq(GameState.day, 0)
