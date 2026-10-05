extends GutTest
## Lot 1 — interaction : l'interactable est le premier ancêtre du groupe "interactable" du nœud
## détecté, le plus proche dans le cône frontal (jamais derrière) ; invite émise dans
## EventBus.interaction_available quand elle change ("" quand plus rien) ; interact passe avant
## jump quand une invite est affichée ; pendant un dialogue, interact est ignoré, et après, la
## touche qui l'a fermé ne relance rien tant qu'elle n'est pas relâchée.

const PLAYER := preload("res://src/player/player.tscn")
const CombatStub := preload("res://tests/stubs/l1_combat_stub.gd")
const BOARD := preload("res://tests/stubs/l1_interactable_stub.tscn")
const BoardStub := preload("res://tests/stubs/l1_interactable_stub.gd")
const DT := 1.0 / 60.0


func before_each() -> void:
	GameState.reset()


func after_each() -> void:
	for action: StringName in [&"jump", &"interact"]:
		Input.action_release(action)


# --- Outils -----------------------------------------------------------------------------------


func _spawn_player() -> Player:
	var player: Player = PLAYER.instantiate()
	player.get_node(^"Combat").set_script(CombatStub)
	add_child_autofree(player)
	return player


func _add_floor() -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 1, 40)
	shape.shape = box
	shape.position = Vector3(0, -0.5, 0)
	body.add_child(shape)
	add_child_autofree(body)


func _add_board(at: Vector3, prompt: String = "Examiner") -> BoardStub:
	var board: BoardStub = BOARD.instantiate()
	board.prompt = prompt
	board.position = at
	add_child_autofree(board)
	return board


func _press_interact(with_jump: bool = false) -> Player.Commands:
	var commands := Player.Commands.new()
	commands.interact = true
	commands.interact_held = true
	commands.jump = with_jump
	commands.jump_held = with_jump
	return commands


# --- Fonctions pures --------------------------------------------------------------------------


func test_resolve_press_gives_interact_priority_when_prompt_shown() -> void:
	assert_eq(Player.resolve_press(true, true, true), &"interact", "A devant une invite")
	assert_eq(Player.resolve_press(true, true, false), &"jump", "A sans invite : saut")
	assert_eq(Player.resolve_press(false, true, true), &"jump", "Espace devant une invite")
	assert_eq(Player.resolve_press(true, false, true), &"interact", "E devant une invite")
	assert_eq(Player.resolve_press(true, false, false), &"", "E sans invite : rien")
	assert_eq(Player.resolve_press(false, false, true), &"")


func test_resolve_interactable_takes_first_ancestor_in_group() -> void:
	var board := _add_board(Vector3.ZERO)
	var zone := board.get_node(^"Zone")
	assert_eq(Player.resolve_interactable(zone.get_node(^"CollisionShape3D")), board)
	assert_eq(Player.resolve_interactable(zone), board, "depuis l'Area3D détectée")
	assert_eq(Player.resolve_interactable(board), board, "le nœud détecté lui-même")
	var lonely: Node3D = add_child_autofree(Node3D.new())
	assert_null(Player.resolve_interactable(lonely), "aucun ancêtre du groupe")
	var mute: Node3D = add_child_autofree(Node3D.new())
	mute.add_to_group(&"interactable")
	assert_null(Player.resolve_interactable(mute), "du groupe mais sans get_prompt / interact")
	var inner: Node3D = Node3D.new()
	mute.add_child(inner)
	assert_null(Player.resolve_interactable(inner), "seul le premier ancêtre du groupe compte")


func test_pick_interactable_prefers_nearest_in_front_never_behind() -> void:
	var far := _add_board(Vector3(0, 0, -2.0))
	var near := _add_board(Vector3(0.3, 0, -1.2))
	var behind := _add_board(Vector3(0, 0, 1.0))
	var side := _add_board(Vector3(1.0, 0, 0))
	var all: Array[Node3D] = [far, behind, near, side]
	assert_eq(Player.pick_interactable(Vector3.ZERO, Vector3.FORWARD, all, 120.0), near)
	var not_in_front: Array[Node3D] = [behind, side]
	assert_null(
		Player.pick_interactable(Vector3.ZERO, Vector3.FORWARD, not_in_front, 120.0),
		"derrière ou sur le côté : rien"
	)
	assert_eq(Player.pick_interactable(Vector3.ZERO, Vector3.BACK, all, 120.0), behind, "demi-tour")
	var touching := _add_board(Vector3(0, 0, 0.4))
	var close: Array[Node3D] = [far, touching]
	assert_eq(
		Player.pick_interactable(Vector3.ZERO, Vector3.FORWARD, close, 120.0),
		touching,
		"au contact, même un peu derrière"
	)
	var none: Array[Node3D] = []
	assert_null(Player.pick_interactable(Vector3.ZERO, Vector3.FORWARD, none, 120.0))


# --- Détection dans le monde (Area3D, images physiques) -----------------------------------------


func test_prompt_follows_interactable_in_front_then_clears() -> void:
	_add_floor()
	var player := _spawn_player()
	watch_signals(EventBus)
	await wait_physics_frames(3)
	assert_signal_not_emitted(EventBus, "interaction_available", "rien autour : pas d'invite")
	assert_eq(player.current_prompt(), "")
	var board := _add_board(Vector3(0, 0, -1.3))
	await wait_physics_frames(4)
	assert_signal_emitted_with_parameters(EventBus, "interaction_available", ["Examiner"])
	assert_eq(player.current_interactable(), board)
	board.free()
	await wait_physics_frames(3)
	assert_signal_emitted_with_parameters(EventBus, "interaction_available", [""])
	assert_signal_emit_count(EventBus, "interaction_available", 2, "une émission par changement")
	assert_null(player.current_interactable())


func test_interactable_behind_is_not_offered() -> void:
	_add_floor()
	var player := _spawn_player()
	var board := _add_board(Vector3(0, 0, 1.0))
	watch_signals(EventBus)
	await wait_physics_frames(5)
	assert_true(
		player.interaction_area.get_overlapping_areas().has(board.get_node(^"Zone")),
		"la zone est bien détectée…"
	)
	assert_signal_not_emitted(EventBus, "interaction_available", "…mais elle est derrière")
	assert_null(player.current_interactable())
	player.set_aim_direction(Vector3.BACK)
	await wait_physics_frames(4)
	assert_eq(player.current_prompt(), "Examiner", "le joueur se retourne : invite")


func test_nearest_of_two_interactables_wins() -> void:
	_add_floor()
	var player := _spawn_player()
	_add_board(Vector3(0.4, 0, -1.9), "Lire")
	var near := _add_board(Vector3(-0.3, 0, -1.0), "Parler")
	await wait_physics_frames(5)
	assert_eq(player.current_prompt(), "Parler")
	assert_eq(player.current_interactable(), near)


func test_interact_passes_before_jump_when_prompt_shown() -> void:
	_add_floor()
	var player := _spawn_player()
	var board := _add_board(Vector3(0, 0, -1.2))
	await wait_physics_frames(5)
	assert_eq(player.current_prompt(), "Examiner")
	player.tick(DT, _press_interact(true))
	assert_eq(board.interactions, [player] as Array[Node3D], "bouton A : interaction")
	assert_almost_eq(player.velocity.y, 0.0, 0.01, "…et pas de saut")
	var space := Player.Commands.new()
	space.jump = true
	space.jump_held = true
	player.tick(DT, space)
	assert_gt(player.velocity.y, 1.0, "Espace seul : saut, même devant une invite")
	assert_eq(board.interactions.size(), 1)


func test_dialogue_ignores_interact_until_key_released() -> void:
	_add_floor()
	var player := _spawn_player()
	var board := _add_board(Vector3(0, 0, -1.2))
	await wait_physics_frames(5)
	watch_signals(EventBus)
	EventBus.dialogue_started.emit(&"l1_test")
	assert_signal_emitted_with_parameters(EventBus, "interaction_available", [""])
	assert_eq(player.current_prompt(), "", "invite masquée pendant le dialogue")
	player.tick(DT, _press_interact())
	assert_eq(board.interactions.size(), 0, "interact ignoré pendant le dialogue")
	EventBus.dialogue_ended.emit(&"l1_test")
	player.tick(DT, _press_interact(true))
	assert_eq(board.interactions.size(), 0, "la touche qui a fermé le dialogue ne le relance pas")
	assert_almost_eq(player.velocity.y, 0.0, 0.01, "ni ne fait sauter (A à la manette)")
	player.tick(DT, Player.Commands.new())
	assert_eq(player.current_prompt(), "Examiner", "invite de retour")
	player.tick(DT, _press_interact())
	assert_eq(board.interactions.size(), 1, "nouvel appui : interaction")


func test_gamepad_a_button_reads_as_jump_and_interact() -> void:
	var press := InputEventJoypadButton.new()
	press.button_index = JOY_BUTTON_A
	press.pressed = true
	assert_true(InputMap.event_is_action(press, &"jump"), "A = jump")
	assert_true(InputMap.event_is_action(press, &"interact"), "A = interact")
	Input.parse_input_event(press)
	Input.flush_buffered_events()
	var commands := Player.read_commands()
	assert_true(commands.jump_held and commands.interact_held, "read_commands lit les deux")
	var release := InputEventJoypadButton.new()
	release.button_index = JOY_BUTTON_A
	release.pressed = false
	Input.parse_input_event(release)
	Input.flush_buffered_events()
	assert_false(Player.read_commands().interact_held, "relâché")
