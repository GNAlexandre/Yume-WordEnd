extends GutTest
## Lot 6 : boîte de dialogue (src/ui/dialogue_box.tscn) — masquée hors dialogue, nom, portrait,
## texte lettre par lettre, « suite », deux choix au clavier ou à la souris, index émis sur
## EventBus.dialogue_choice_made. Pilotée uniquement par l'EventBus.

const BOX_SCENE := preload("res://src/ui/dialogue_box.tscn")
const LIBRARIAN := preload("res://data/npcs/librarian.tres")

var _box: DialogueBox
var _answers: Array[int] = []


func before_each() -> void:
	_answers.clear()
	EventBus.dialogue_choice_made.connect(_on_choice_made)
	_box = add_child_autofree(BOX_SCENE.instantiate())


func after_each() -> void:
	EventBus.dialogue_choice_made.disconnect(_on_choice_made)


func _on_choice_made(index: int) -> void:
	_answers.append(index)


func _line(text: String, choices: Array[String] = [], speaker: String = "Bibliothécaire") -> void:
	EventBus.dialogue_line.emit(speaker, text, choices)


func _action(action: StringName, pressed: bool = true) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	return event


func _label(unique_name: String) -> Label:
	return _box.get_node("%" + unique_name) as Label


func _button(index: int) -> Button:
	return _box.get_node("%%Choice%d" % index) as Button


func test_hidden_outside_dialogue() -> void:
	assert_false(_box.visible, "masquée au départ")
	assert_false(_box.is_open())
	assert_eq(_box.mouse_filter, Control.MOUSE_FILTER_IGNORE, "ne bloque pas la souris du jeu")
	EventBus.dialogue_started.emit(&"librarian")
	_line("Bonjour.")
	assert_true(_box.visible, "visible pendant le dialogue")
	EventBus.dialogue_ended.emit(&"librarian")
	assert_false(_box.visible, "masquée à la fin")
	assert_false(_box.is_open())


func test_line_shows_name_and_types_letter_by_letter() -> void:
	_box.characters_per_second = 20.0
	_line("Les Timeres ont emporté des pages du dernier tome.")
	assert_eq(_label("NameLabel").text, "Bibliothécaire")
	assert_true(_box.get_node("%NamePlate").visible)
	assert_eq(_label("Text").text, "Les Timeres ont emporté des pages du dernier tome.")
	assert_true(_box.is_typing())
	assert_eq(_label("Text").visible_characters, 0, "rien d'affiché au départ")
	await wait_seconds(0.3)
	var shown := _label("Text").visible_characters
	assert_between(shown, 1, 20, "quelques lettres après 0,3 s")
	assert_true(_box.is_typing())
	assert_false(_box.get_node("%NextHint").visible, "pas d'indicateur pendant la frappe")


func test_line_finishes_typing_by_itself() -> void:
	_box.characters_per_second = 400.0
	_line("Court.")
	await wait_process_frames(3)
	assert_true(_box.is_waiting(), "ligne entière, attend la suite")
	assert_eq(_label("Text").visible_characters, -1)
	assert_true(_box.get_node("%NextHint").visible, "indicateur de suite")


func test_first_press_completes_second_continues() -> void:
	_line("Une réplique assez longue pour être interrompue.")
	_box.advance()
	assert_true(_box.is_waiting(), "le premier appui termine la ligne")
	assert_eq(_label("Text").visible_characters, -1)
	assert_eq(_answers, [] as Array[int], "rien d'émis au premier appui")
	_box.advance()
	assert_eq(_answers, [-1] as Array[int], "le second appui passe à la suite (-1)")
	_box.advance()
	assert_eq(_answers.size(), 1, "un seul envoi en attendant la ligne suivante")


func test_zero_speed_shows_whole_line_at_once() -> void:
	_box.characters_per_second = 0.0
	_line("Tout d'un coup.")
	assert_true(_box.is_waiting())
	assert_eq(_label("Text").visible_characters, -1)


func test_line_without_dialogue_started_has_no_empty_portrait_frame() -> void:
	EventBus.dialogue_started.emit(&"librarian")
	_line("Bonjour.")
	EventBus.dialogue_ended.emit(&"librarian")
	_line("Une voix sans visage…")
	assert_false(_box.get_node("%PortraitFrame").visible)


func test_empty_speaker_hides_name_plate() -> void:
	_line("Une voix…", [], "")
	assert_false(_box.get_node("%NamePlate").visible)


func test_choices_appear_after_typing_and_emit_index() -> void:
	_line("Peux-tu m'en rapporter cinq ?", ["Je m'en occupe.", "Plus tard."])
	assert_false(_box.get_node("%ChoicesRow").visible, "choix cachés pendant la frappe")
	_box.complete_line()
	assert_true(_box.is_choosing())
	assert_true(_box.get_node("%ChoicesRow").visible)
	assert_eq(_button(0).text, "Je m'en occupe.")
	assert_eq(_button(1).text, "Plus tard.")
	assert_true(_button(0).visible and _button(1).visible)
	assert_eq(_box.selected_choice(), 0, "premier choix sélectionné")
	assert_true(_button(0).has_focus(), "sélection visible (focus)")
	_box.select(1)
	assert_true(_button(1).has_focus())
	_box.advance()
	assert_eq(_answers, [1] as Array[int], "valide le choix sélectionné")
	assert_false(_box.get_node("%ChoicesRow").visible, "choix masqués après la réponse")


func test_single_choice_hides_second_button() -> void:
	_line("D'accord ?", ["Oui."])
	_box.complete_line()
	assert_true(_button(0).visible)
	assert_false(_button(1).visible)
	_box.select(1)
	assert_eq(_box.selected_choice(), 0, "choix inexistant ignoré")
	_box.choose(1)
	assert_eq(_answers, [] as Array[int])
	_box.choose(0)
	assert_eq(_answers, [0] as Array[int])


func test_keyboard_navigation_and_accept() -> void:
	_line("Alors ?", ["Oui.", "Non."])
	_box._input(_action(&"interact"))
	assert_true(_box.is_choosing(), "interact termine la ligne")
	_box._input(_action(&"ui_down"))
	assert_eq(_box.selected_choice(), 1, "ui_down")
	_box._input(_action(&"ui_down"))
	assert_eq(_box.selected_choice(), 1, "reste sur le dernier choix")
	_box._input(_action(&"move_forward"))
	assert_eq(_box.selected_choice(), 0, "move_forward (stick, ZQSD) remonte")
	_box._input(_action(&"move_back"))
	_box._input(_action(&"ui_accept"))
	assert_eq(_answers, [1] as Array[int], "ui_accept valide")


func test_released_and_unrelated_inputs_are_ignored() -> void:
	_line("Alors ?", ["Oui.", "Non."])
	_box._input(_action(&"interact", false))
	assert_true(_box.is_typing(), "un relâchement ne compte pas")
	_box._input(_action(&"attack"))
	assert_true(_box.is_typing(), "autre action ignorée")


func test_input_from_viewport_is_consumed_while_open() -> void:
	_line("Bonjour.")
	Input.parse_input_event(_action(&"interact"))
	Input.flush_buffered_events()
	assert_true(_box.is_waiting(), "l'appui réel atteint la boîte")
	Input.parse_input_event(_action(&"interact", false))
	Input.parse_input_event(_action(&"interact"))
	Input.flush_buffered_events()
	assert_eq(_answers, [-1] as Array[int])
	Input.parse_input_event(_action(&"interact", false))
	Input.flush_buffered_events()


func test_mouse_hover_selects_and_click_chooses() -> void:
	_line("Alors ?", ["Oui.", "Non."])
	_box.complete_line()
	_button(1).mouse_entered.emit()
	assert_eq(_box.selected_choice(), 1, "survol = sélection")
	_button(1).pressed.emit()
	assert_eq(_answers, [1] as Array[int], "clic = validation")


func test_click_on_box_advances_line() -> void:
	_line("Bonjour.")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	var panel := _box.get_node("%Panel") as Control
	panel.gui_input.emit(click)
	assert_true(_box.is_waiting(), "clic : termine la ligne")
	panel.gui_input.emit(click)
	assert_eq(_answers, [-1] as Array[int], "clic : suite")


func test_portrait_from_npc_data() -> void:
	EventBus.dialogue_started.emit(&"librarian")
	_line("Bonjour.")
	var portrait := (_box.get_node("%Portrait") as TextureRect).texture
	assert_not_null(portrait, "portrait du PNJ retrouvé par data/npcs/librarian.tres")
	assert_true(_box.get_node("%PortraitFrame").visible)
	assert_true(portrait is AtlasTexture, "sans SkinData.portrait : image de la planche")
	var atlas := portrait as AtlasTexture
	assert_eq(atlas.atlas, LIBRARIAN.skin.sprite_sheet)
	var first: Array = LIBRARIAN.skin.frames_json.data["animations"]["repos"]["images"][0]
	assert_eq(atlas.region, Rect2(first[0], first[1], first[2], first[3]), "1re image de repos")


func test_portrait_prefers_skin_portrait_and_hides_when_unknown() -> void:
	var skin := SkinData.new()
	var picture := PlaceholderTexture2D.new()
	skin.portrait = picture
	assert_eq(DialogueBox.portrait_of(skin), picture, "SkinData.portrait d'abord")
	assert_null(DialogueBox.portrait_of(SkinData.new()), "ni portrait ni planche")
	assert_null(DialogueBox.portrait_for(&"inconnu"))
	assert_null(DialogueBox.portrait_for(&""))
	EventBus.dialogue_started.emit(&"inconnu")
	_line("…")
	assert_false(_box.get_node("%PortraitFrame").visible, "pas de cadre vide")
