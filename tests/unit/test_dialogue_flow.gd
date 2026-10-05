extends GutTest
## Lot 6 : conversation complète dans la démo (bibliothécaire, joueur factice, boîte de
## dialogue), pilotée par de vrais événements d'entrée comme au clavier ou à la manette :
## « dialogue jouable avec le joueur stub » (PLAN.md section 7).

const DEMO := preload("res://tests/integration/demo_l6.tscn")

var _demo: Node3D
var _box: DialogueBox


func before_each() -> void:
	GameState.reset()
	_demo = DEMO.instantiate()
	_demo.set("presentation", false)
	add_child_autofree(_demo)
	_box = _demo.get_node("UI/DialogueBox") as DialogueBox
	await wait_process_frames(2)


func after_all() -> void:
	GameState.reset()


## Appui puis relâchement d'une action, distribués comme par le clavier.
func _press(action: StringName) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()


func _text() -> String:
	return (_box.get_node("%Text") as Label).text


func test_npc_faces_the_player_stub() -> void:
	var npc := _demo.get_node("Librarian") as Npc
	var player := _demo.get_node("Player") as Node3D
	assert_true(player.is_in_group(&"player"))
	assert_true(npc.look_toward(player.global_position), "joueur à moins de 4 m")


func test_whole_conversation_with_keys() -> void:
	assert_true(_box.is_open(), "dialogue lancé automatiquement")
	assert_true(_box.is_typing(), "texte lettre par lettre")
	assert_string_contains(_text(), "Timeres")
	_press(&"interact")
	assert_true(_box.is_waiting(), "1er appui : ligne entière")
	_press(&"interact")
	assert_string_contains(_text(), "rapporter cinq", "2e appui : réplique suivante")
	_press(&"ui_accept")
	assert_true(_box.is_choosing(), "deux choix")
	_press(&"ui_down")
	assert_eq(_box.selected_choice(), 1)
	_press(&"ui_up")
	_press(&"interact")
	assert_eq(GameState.quest_state(&"pages"), &"active", "« Je m’en occupe. » démarre la quête")
	assert_true(GameState.has_flag(&"quest_pages_accepted"))
	_press(&"interact")
	_press(&"interact")
	assert_false(_box.is_open(), "fin : boîte masquée")
	assert_false(_box.visible)
	assert_false(DialogueRunner.is_any_running(), "le joueur peut repartir")
	await wait_seconds(0.4)
	_press(&"interact")
	assert_true(_box.is_open(), "E relance la conversation")
	assert_string_contains(_text(), "encore 5 pages", "réplique de quête en cours")


func test_later_then_mouse_choice() -> void:
	_box.complete_line()
	_box.advance()
	_box.complete_line()
	var later := _box.get_node("%Choice1") as Button
	later.mouse_entered.emit()
	later.pressed.emit()
	assert_eq(GameState.quest_state(&"pages"), &"", "« Plus tard. » ne démarre rien")
	assert_string_contains(_text(), "quand tu voudras")
