extends "res://tests/stubs/m2_game_test.gd"
## Souris dans la vraie partie : clic gauche = coup d'épée vers le pointeur, clic droit maintenu
## = charge magique ; un clic pris par l'interface (bouton du menu pause) ou une souris émulée
## par le tactile ne frappe pas ; un clic droit relâché pendant la pause ne laisse pas la charge
## tenue.


func after_each() -> void:
	for button: MouseButton in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		_mouse(button, false, Vector2.ZERO)
	Input.flush_buffered_events()
	for action: StringName in [&"attack", &"charge"]:
		Input.action_release(action)
	super()


## Bouton de souris appuyé ou relâché au point `at` du canevas (comme click_at).
func _mouse(button: MouseButton, pressed: bool, at: Vector2, device: int = 0) -> void:
	var on_window := get_tree().root.get_final_transform() * at
	var event := InputEventMouseButton.new()
	event.device = device
	event.button_index = button
	event.button_mask = (1 << (button - 1)) if pressed else 0
	event.position = on_window
	event.global_position = on_window
	event.pressed = pressed
	Input.parse_input_event(event)


## Point du canevas où se voit le sol à `offset` du joueur.
func _screen_point(offset: Vector3) -> Vector2:
	var camera := get_viewport().get_camera_3d()
	return camera.unproject_position(player.global_position + offset)


## Le joueur au calme, tourné vers le nord, au Spawn de la cour.
func _start() -> void:
	assert_true(await new_game_from_menu(), "nouvelle partie")
	await place_player(&"village", Vector3(0.0, 0.0, -6.0), Vector3.FORWARD)
	await wait_physics_frames(3)


func test_left_click_swings_the_sword_toward_the_pointer() -> void:
	await _start()
	var east := _screen_point(Vector3(3.0, 0.0, 0.0))
	_mouse(MOUSE_BUTTON_LEFT, true, east)
	await wait_physics_frames(2)
	assert_eq(combat.current_state(), &"attack", "clic gauche : coup d'épée")
	assert_gt(player.aim_direction().x, 0.9, "le coup part vers le pointeur (à l'est)")
	_mouse(MOUSE_BUTTON_LEFT, false, east)
	await wait_physics_frames(2)
	assert_false(Input.is_action_pressed(&"attack"), "action relâchée avec le bouton")


func test_right_click_held_charges_until_released() -> void:
	await _start()
	var west := _screen_point(Vector3(-3.0, 0.0, 0.0))
	_mouse(MOUSE_BUTTON_RIGHT, true, west)
	await wait_seconds(0.4)
	assert_eq(combat.current_state(), &"charge", "clic droit maintenu : charge")
	assert_lt(player.aim_direction().x, -0.9, "la charge vise le pointeur (à l'ouest)")
	_mouse(MOUSE_BUTTON_RIGHT, false, west)
	await wait_physics_frames(3)
	assert_false(Input.is_action_pressed(&"charge"), "charge relâchée avec le bouton")
	assert_ne(combat.current_state(), &"charge", "la charge se termine au relâchement")


func test_clicks_taken_by_the_interface_or_from_touch_do_not_strike() -> void:
	await _start()
	var swings: Array[AttackData] = []
	combat.attack_started.connect(func(data: AttackData) -> void: swings.append(data))
	# Souris émulée par un doigt : les contrôles tactiles ont leurs propres boutons.
	var north := _screen_point(Vector3(0.0, 0.0, -3.0))
	_mouse(MOUSE_BUTTON_LEFT, true, north, InputEvent.DEVICE_ID_EMULATION)
	await wait_physics_frames(2)
	_mouse(MOUSE_BUTTON_LEFT, false, north, InputEvent.DEVICE_ID_EMULATION)
	await wait_physics_frames(2)
	assert_eq(swings.size(), 0, "pas de coup pour un toucher")
	assert_ne(combat.current_state(), &"attack", "toujours au calme")
	# « Reprendre » du menu pause, au clic : l'interface le prend, aucun coup à la reprise.
	await tap_key(KEY_ESCAPE)
	await frames(2)
	assert_true(pause_menu.visible, "pause ouverte")
	await click(pause_menu.get_node("%ResumeButton") as Control)
	await frames(4)
	assert_false(get_tree().paused, "reprise")
	assert_eq(swings.size(), 0, "pas de coup pour un clic sur le menu")
	assert_ne(combat.current_state(), &"charge", "ni de charge")


func test_right_button_released_during_pause_does_not_stick() -> void:
	await _start()
	var west := _screen_point(Vector3(-3.0, 0.0, 0.0))
	_mouse(MOUSE_BUTTON_RIGHT, true, west)
	await wait_physics_frames(3)
	assert_true(Input.is_action_pressed(&"charge"), "charge tenue par le clic droit")
	await tap_key(KEY_ESCAPE)
	assert_true(get_tree().paused, "pause")
	_mouse(MOUSE_BUTTON_RIGHT, false, west)
	await frames(2)
	await tap_key(KEY_ESCAPE)
	await frames(4)
	assert_false(get_tree().paused, "reprise")
	assert_false(Input.is_action_pressed(&"charge"), "charge relâchée après la pause")
	assert_ne(combat.current_state(), &"charge", "plus de charge")
