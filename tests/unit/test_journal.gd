extends "res://tests/stubs/q_quest_test.gd"
## Lot Q, journal de quêtes (src/ui/journal.tscn, enfant Journal du HUD) : action journal (Tab,
## L, Select) qui l'ouvre et le ferme, pause comme l'inventaire, autres façons de le fermer,
## jamais pendant un dialogue ni par-dessus une pause ; quêtes actives puis terminées, étapes
## validées et courante (progression, aide), récompense ; quête suivie choisie au clavier, à la
## manette ou à la souris ; journal vide.

const JOURNAL := preload("res://src/ui/journal.tscn")

var _journal: Control


func before_each() -> void:
	super()
	get_tree().paused = false
	_journal = add_child_autofree(JOURNAL.instantiate())


func after_each() -> void:
	get_tree().paused = false
	super()


func _push(event: InputEvent) -> void:
	get_viewport().push_input(event)


func _push_action(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	_push(event)


func _push_key(keycode: Key) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = keycode
		event.physical_keycode = keycode
		event.pressed = pressed
		_push(event)


func _push_joy(button: JoyButton) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventJoypadButton.new()
		event.button_index = button
		event.pressed = pressed
		_push(event)


## Trois quêtes : une secondaire en cours (à la 3e étape), une principale en cours, une terminée.
func _three_quests() -> void:
	write_quest(
		{
			"id": "side",
			"title": "Secondaire",
			"summary": "Un résumé.",
			"giver": "child",
			"steps":
			[
				{"id": "a", "type": "talk", "npc": "child", "objective": "Parler à l'enfant"},
				{"id": "b", "type": "reach", "zone": "beach", "objective": "Aller à la plage"},
				{
					"id": "c",
					"type": "kill",
					"count": 3,
					"objective": "Vaincre 3 Timeres",
					"hint": "Dans la forêt."
				},
				{"id": "d", "type": "flag", "flag": "secret", "objective": "Étape cachée"},
			],
			"rewards": {"items": {"flower_blue": 2}, "max_hp": 7},
		}
	)
	write_quest(
		{
			"id": "main_q",
			"title": "Principale",
			"main": true,
			"steps": [{"id": "x", "type": "flag", "flag": "x", "objective": "X"}],
		}
	)
	write_quest(
		{
			"id": "old",
			"title": "Terminée",
			"steps": [{"id": "y", "type": "flag", "flag": "y", "objective": "Y"}],
		}
	)
	start_quest(&"side")
	chat(&"child")
	enter_zone(&"beach")
	kill(&"timere_small")
	start_quest(&"old")
	GameState.set_flag(&"y")
	start_quest(&"main_q")


func test_journal_action_opens_and_closes_with_pause() -> void:
	assert_false(_journal.call(&"is_open"))
	for keycode: Key in [KEY_TAB, KEY_L]:
		_push_key(keycode)
		assert_true(_journal.call(&"is_open"), "ouvert (%s)" % OS.get_keycode_string(keycode))
		assert_true(get_tree().paused, "jeu en pause")
		_push_key(keycode)
		assert_false(_journal.call(&"is_open"), "refermé")
		assert_false(get_tree().paused, "pause levée")
	_push_joy(JOY_BUTTON_BACK)
	assert_true(_journal.call(&"is_open"), "Select / Back")
	_push_joy(JOY_BUTTON_BACK)
	assert_false(_journal.call(&"is_open"))


func test_journal_bindings_are_free() -> void:
	# Tab, L et Select / Back ne servent à aucune autre action du jeu. Les actions ui_* de Godot
	# gardent Tab pour passer d'un bouton à l'autre dans les menus : ouvert, le journal le lit
	# avant elles (_input) ; fermé, rien n'a le focus de l'interface pendant le jeu.
	var events := InputMap.action_get_events(&"journal")
	var bindings := PackedStringArray()
	for event: InputEvent in events:
		var key := event as InputEventKey
		var joy := event as InputEventJoypadButton
		if key != null:
			bindings.append(OS.get_keycode_string(key.physical_keycode))
		elif joy != null:
			bindings.append("bouton %d" % joy.button_index)
	assert_eq(bindings, PackedStringArray(["Tab", "L", "bouton 4"]), "Tab, L, Select / Back")
	for action: StringName in InputMap.get_actions():
		if action == &"journal" or String(action).begins_with("ui_"):
			continue
		for event: InputEvent in events:
			assert_false(
				InputMap.action_has_event(action, event), "%s n'utilise pas %s" % [action, event]
			)


func test_other_ways_to_close() -> void:
	for action: StringName in [&"ui_cancel", &"pause", &"inventory"]:
		_journal.call(&"open")
		_push_action(action)
		assert_false(_journal.call(&"is_open"), "fermé par %s" % action)
		assert_false(get_tree().paused)
	_journal.call(&"open")
	_push_joy(JOY_BUTTON_B)
	assert_false(_journal.call(&"is_open"), "B, au relâchement")
	_journal.call(&"open")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	(_journal.get_node("%Dim") as Control).gui_input.emit(click)
	assert_false(_journal.call(&"is_open"), "clic hors du panneau")


func test_never_opens_during_a_dialogue_or_over_a_pause() -> void:
	EventBus.dialogue_started.emit(&"child")
	_push_action(&"journal")
	assert_false(_journal.call(&"is_open"), "pas pendant un dialogue")
	EventBus.dialogue_ended.emit(&"child")
	get_tree().paused = true
	_journal.call(&"open")
	assert_false(_journal.call(&"is_open"), "pas par-dessus une pause (menu, inventaire)")
	get_tree().paused = false
	_journal.call(&"open")
	EventBus.dialogue_started.emit(&"child")
	assert_false(_journal.call(&"is_open"), "un dialogue le ferme")
	assert_false(get_tree().paused)


func test_lists_active_then_done_quests_with_their_steps() -> void:
	_three_quests()
	_journal.call(&"open")
	var listed: Array[StringName] = _journal.call(&"listed_quests")
	var expected: Array[StringName] = [&"main_q", &"side", &"old"]
	assert_eq(listed, expected, "actives (principale d'abord) puis terminées")
	assert_eq(_journal.call(&"selected_quest"), &"main_q", "la quête suivie est choisie")
	_journal.call(&"select", &"side")
	var steps: Array[Dictionary] = _journal.call(&"shown_steps")
	assert_eq(steps.size(), 3, "étapes validées et courante, pas les suivantes")
	assert_eq(steps[0]["state"], &"done")
	assert_eq(steps[1]["state"], &"done")
	assert_eq(steps[2]["state"], &"current")
	assert_eq(steps[2]["objective"], "Vaincre 3 Timeres")
	assert_eq(steps[2]["progress"], "Ennemis vaincus : 1/3")
	var text := _texts()
	for expected_text: String in [
		"Secondaire", "Un résumé.", "Dans la forêt.", "Myosotis × 2", "7 PV max", "Enfant"
	]:
		assert_string_contains(text, expected_text, false)
	_journal.call(&"select", &"old")
	steps = _journal.call(&"shown_steps")
	assert_eq(steps.size(), 1)
	assert_eq(steps[0]["state"], &"done", "quête terminée : toutes ses étapes validées")
	assert_string_contains(_texts(), "terminée")


func test_choosing_a_quest_makes_it_the_tracked_one() -> void:
	_three_quests()
	assert_eq(GameState.tracked_quest, &"main_q")
	_journal.call(&"open")
	var side := _journal.find_child("Quest_side", true, false) as Button
	var main := _journal.find_child("Quest_main_q", true, false) as Button
	assert_not_null(main.icon, "icône sur la quête suivie")
	assert_null(side.icon)
	side.grab_focus()
	assert_eq(_journal.call(&"selected_quest"), &"side", "le focus montre la quête")
	assert_eq(GameState.tracked_quest, &"main_q", "le focus ne change pas la quête suivie")
	_push_joy(JOY_BUTTON_A)
	assert_eq(GameState.tracked_quest, &"side", "A : suivre cette quête")
	assert_not_null(side.icon)
	assert_null(main.icon)
	assert_string_contains(_texts(), "Quête suivie")
	main.pressed.emit()
	assert_eq(GameState.tracked_quest, &"main_q", "clic ou Entrée")
	var old := _journal.find_child("Quest_old", true, false) as Button
	old.pressed.emit()
	assert_eq(GameState.tracked_quest, &"main_q", "une quête terminée ne se suit pas")


func test_empty_journal() -> void:
	_journal.call(&"open")
	assert_eq(_journal.call(&"listed_quests"), [] as Array[StringName])
	assert_string_contains(_texts(), "Aucune quête")
	assert_string_contains(_texts(), "habitants du village")
	assert_eq(get_viewport().gui_get_focus_owner(), _journal.get_node("%CloseButton"))


## Textes visibles du journal, bout à bout.
func _texts() -> String:
	var parts := PackedStringArray()
	for node: Node in _journal.find_children("*", "Label", true, false):
		var label := node as Label
		if label.is_visible_in_tree() and not label.is_queued_for_deletion():
			parts.append(label.text)
	for node: Node in _journal.find_children("*", "Button", true, false):
		parts.append((node as Button).text)
	return " | ".join(parts)
