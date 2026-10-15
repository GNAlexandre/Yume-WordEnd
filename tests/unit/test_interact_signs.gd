extends "res://tests/stubs/l10_ui_test.gd"
## (U1) Signes d'interaction : genre selon la cible, signe plein et signes pâles, cachés pendant
## un dialogue, en bandeau, par InteractSign.suppress ou set_hidden, aucun signe sans invite
## (règle d'E8), rappel de la touche, rebond, réglage des Options de la pause.

const HUD := preload("res://src/ui/hud.tscn")
const SignPlayer := preload("res://tests/stubs/u1_sign_player.gd")
const Board := preload("res://tests/stubs/l1_interactable_stub.gd")
const SignsScript := preload("res://src/ui/interact_signs.gd")

var _player: SignPlayer


func before_each() -> void:
	super.before_each()
	InteractSign.set_always_show_key(false, false)
	DialogueBox.set_presentation(DialogueBox.PRESENTATION_NUIT)


func after_each() -> void:
	InteractSign.suppress(&"test", false)
	InteractSign.set_always_show_key(false, false)
	DialogueBox.set_presentation(DialogueBox.PRESENTATION_NUIT)
	super.after_each()


func _signs() -> Control:
	var hud := add_child_autofree(HUD.instantiate()) as Control
	_player = add_child_autofree(SignPlayer.new()) as SignPlayer
	return hud.call(&"interact_signs") as Control


func _board(prompt: String = "Examiner") -> Node3D:
	var board := Board.new()
	board.prompt = prompt
	board.add_to_group(&"interactable")
	return add_child_autofree(board) as Node3D


func test_kind_follows_the_target() -> void:
	var npc := autofree(Npc.new()) as Npc
	assert_eq(InteractSign.kind_of(npc), InteractSign.TALK, "PNJ : bulle")
	var pickup := autofree(Pickup.new()) as Pickup
	assert_eq(InteractSign.kind_of(pickup), InteractSign.TAKE, "objet : main")
	var exit := autofree(MapExit.new()) as MapExit
	exit.prompt = "Entrer"
	assert_eq(InteractSign.kind_of(exit), InteractSign.ENTER, "sortie : porte")
	assert_eq(InteractSign.kind_of(_board()), InteractSign.EXAMINE, "le reste : étincelle")
	assert_eq(InteractSign.kind_of(_board("")), &"", "pas d'invite : pas de signe")
	var forced := _board()
	forced.set_meta(InteractSign.META, InteractSign.TALK)
	assert_eq(InteractSign.kind_of(forced), InteractSign.TALK, "genre imposé par la méta")
	InteractSign.set_hidden(forced, true)
	assert_true(InteractSign.is_hidden(forced))
	assert_eq(InteractSign.kind_of(forced), &"", "caché par set_hidden")
	InteractSign.set_hidden(forced, false)
	assert_eq(InteractSign.kind_of(forced), InteractSign.EXAMINE, "rendu : genre de sa classe")


func test_full_sign_on_target_and_pale_signs_in_range() -> void:
	var signs := _signs()
	var near := _board()
	var other := _board("Lire")
	var silent := _board("")
	_player.target = near
	_player.in_range = [near, other, silent]
	await wait_process_frames(2)
	assert_eq(signs.call(&"full_target"), near, "signe plein sur la cible")
	assert_eq(signs.call(&"full_kind"), InteractSign.EXAMINE)
	var pales: Array[Node3D] = []
	pales.assign(signs.call(&"pale_targets"))
	assert_eq(pales, [other] as Array[Node3D], "signe pâle sur l'autre cible, aucun sans invite")
	near.set(&"prompt", "")
	await wait_process_frames(2)
	assert_null(signs.call(&"full_target"), "invite vide (un jeu, E8) : plus de signe")


func test_signs_hidden_in_dialogue_bandeau_and_suppressed() -> void:
	var signs := _signs()
	_player.target = _board()
	await wait_process_frames(2)
	assert_not_null(signs.call(&"full_target"))
	EventBus.dialogue_started.emit(&"librarian")
	await wait_process_frames(2)
	assert_null(signs.call(&"full_target"), "rien pendant un dialogue")
	EventBus.dialogue_ended.emit(&"librarian")
	await wait_process_frames(2)
	assert_not_null(signs.call(&"full_target"), "de retour après le dialogue")
	DialogueBox.set_presentation(DialogueBox.PRESENTATION_BANDEAU)
	await wait_process_frames(2)
	assert_null(signs.call(&"full_target"), "rien en bandeau (scène du récit)")
	DialogueBox.set_presentation(DialogueBox.PRESENTATION_NUIT)
	InteractSign.suppress(&"test", true)
	await wait_process_frames(2)
	assert_null(signs.call(&"full_target"), "rien quand une raison les cache")
	InteractSign.suppress(&"test", false)
	InteractSign.set_hidden(_player.target, true)
	await wait_process_frames(2)
	assert_null(signs.call(&"full_target"), "cible cachée par set_hidden")


func test_key_hint_first_minutes_still_or_always() -> void:
	var signs := _signs()
	_player.target = _board()
	var previous := SignsScript.played_seconds
	SignsScript.played_seconds = 0.0
	await wait_process_frames(2)
	assert_true(signs.call(&"is_key_hint_shown"), "premières minutes de jeu")
	assert_eq(signs.call(&"key_hint_text"), "E", "clavier : E")
	SignsScript.played_seconds = 10000.0
	await wait_process_frames(2)
	assert_false(signs.call(&"is_key_hint_shown"), "ensuite, seulement au besoin")
	InteractSign.set_always_show_key(true, false)
	assert_true(signs.call(&"is_key_hint_shown"), "réglage « toujours »")
	InteractSign.set_always_show_key(false, false)
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_DPAD_UP
	pad.pressed = true
	signs.call(&"_input", pad)
	assert_eq(signs.call(&"key_hint_text"), "A", "manette : A")
	SignsScript.played_seconds = previous


func test_interact_makes_the_sign_bounce() -> void:
	var signs := _signs()
	_player.target = _board()
	await wait_process_frames(2)
	var press := InputEventAction.new()
	press.action = &"interact"
	press.pressed = true
	signs.call(&"_input", press)
	assert_gt(float(signs.get(&"_bounce_left")), 0.0, "rebond à l'appui")
	EventBus.dialogue_started.emit(&"librarian")
	await wait_process_frames(1)
	assert_not_null(
		signs.call(&"full_target"), "le signe finit son rebond même si le dialogue s'ouvre"
	)
	await wait_seconds(0.4)
	assert_null(signs.call(&"full_target"), "puis s'efface pendant le dialogue")
	EventBus.dialogue_ended.emit(&"librarian")


func test_pause_options_toggle_the_key_hint_setting() -> void:
	var hud := add_child_autofree(HUD.instantiate()) as Control
	var menu := hud.get_node(^"%PauseMenu")
	menu.call(&"open")
	menu.call(&"show_options")
	assert_true(menu.call(&"is_options_shown"))
	var toggle := menu.get_node(^"%KeyHintToggle") as Button
	assert_false(toggle.button_pressed)
	var previous := InteractSign.always_show_key()
	toggle.button_pressed = true
	assert_true(InteractSign.always_show_key(), "réglage « toujours »")
	assert_string_contains(toggle.text, "toujours")
	menu.call(&"hide_controls")
	assert_false(menu.call(&"is_options_shown"), "retour au panneau principal")
	InteractSign.set_always_show_key(previous)
	menu.call(&"close")
