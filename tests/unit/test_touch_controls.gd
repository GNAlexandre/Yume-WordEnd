extends GutTest
## Contrôles tactiles (Lot 9) : chaque bouton presse / relâche son action, le joystick donne
## l'intensité attendue, plusieurs doigts à la fois, caméra sur la moitié droite, souris jamais
## interceptée sur ordinateur, contextes pause et dialogue.

const TouchControls := preload("res://src/ui/touch_controls.gd")
const TouchButton := preload("res://src/ui/touch_button.gd")
const TouchJoystick := preload("res://src/ui/touch_joystick.gd")
const SCENE := preload("res://src/ui/touch_controls.tscn")
const MOVES: Array[StringName] = [&"move_left", &"move_right", &"move_forward", &"move_back"]
const BUTTONS := {
	"Attack": &"attack",
	"Charge": &"charge",
	"Jump": &"jump",
	"Interact": &"interact",
	"LockTarget": &"lock_target",
	"Inventory": &"inventory",
	"Pause": &"pause",
}

var _controls: TouchControls


func before_each() -> void:
	_reset_actions()
	_controls = SCENE.instantiate() as TouchControls
	_controls.display = TouchControls.Display.ALWAYS
	add_child_autofree(_controls)


func after_each() -> void:
	get_tree().paused = false
	_reset_actions()


func _reset_actions() -> void:
	for action: StringName in InputMap.get_actions():
		if not String(action).begins_with("ui_"):
			var event := InputEventAction.new()
			event.action = action
			Input.parse_input_event(event)
	Input.flush_buffered_events()


## Un doigt comme Godot le livre : _input d'abord, puis _unhandled_input si rien ne l'a pris.
func _touch(index: int, point: Vector2, pressed: bool = true) -> bool:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = point
	event.pressed = pressed
	var used := _controls.handle_input(event) or _controls.handle_unhandled_input(event)
	Input.flush_buffered_events()
	return used


func _drag(index: int, point: Vector2, relative: Vector2 = Vector2.ZERO) -> bool:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = point
	event.relative = relative
	var used := _controls.handle_input(event)
	Input.flush_buffered_events()
	return used


func _center(node_name: String) -> Vector2:
	var control := _controls.get_node(node_name) as Control
	return control.get_global_transform_with_canvas() * (control.size * 0.5)


func _mouse(device: int, point: Vector2, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.device = device
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = point
	event.pressed = pressed
	return event


func test_hidden_without_touchscreen_and_mouse_passes() -> void:
	var auto := SCENE.instantiate() as TouchControls
	add_child_autofree(auto)
	assert_false(TouchControls.is_touch_device(), "pas d'écran tactile en headless")
	assert_false(auto.visible, "masqué sans écran tactile")
	var click := _mouse(0, _center("Attack"), true)
	assert_false(auto.handle_input(click), "un clic sur un bouton masqué passe")
	assert_false(auto.handle_unhandled_input(click), "et n'est pas consommé ensuite")
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(900, 300)
	motion.relative = Vector2(12, 4)
	assert_false(auto.handle_input(motion) or auto.handle_unhandled_input(motion), "souris libre")
	auto.display = TouchControls.Display.NEVER
	assert_false(auto.visible)
	auto.display = TouchControls.Display.ALWAYS
	assert_true(auto.visible, "forcé visible (démo)")


func test_auto_mode_follows_the_device() -> void:
	var auto := SCENE.instantiate() as TouchControls
	add_child_autofree(auto)
	var touch := InputEventScreenTouch.new()
	touch.position = _center("Attack")
	touch.pressed = true
	assert_true(auto.handle_input(touch), "le premier toucher affiche les contrôles et sert")
	assert_true(auto.visible)
	touch.pressed = false
	auto.handle_input(touch)
	var volume := InputEventKey.new()
	volume.keycode = KEY_VOLUMEUP
	volume.pressed = true
	auto.handle_input(volume)
	assert_true(auto.visible, "une touche hors du jeu (volume) ne masque rien")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_J
	key.pressed = true
	auto.handle_input(key)
	assert_false(auto.visible, "jouer au clavier masque les contrôles")


func test_each_button_presses_and_releases_its_action() -> void:
	for node_name: String in BUTTONS:
		var action: StringName = BUTTONS[node_name]
		assert_true(_touch(0, _center(node_name)), "%s : toucher consommé" % node_name)
		assert_true(Input.is_action_pressed(action), "%s presse %s" % [node_name, action])
		assert_true(_touch(0, _center(node_name), false), "%s : relâché" % node_name)
		assert_false(Input.is_action_pressed(action), "%s relâche %s" % [node_name, action])


func test_charge_stays_pressed_while_held() -> void:
	var point := _center("Charge")
	_touch(3, point)
	assert_true(Input.is_action_just_pressed(&"charge"), "appui transmis")
	for i in 4:
		assert_true(_drag(3, point + Vector2(i * 6, 0), Vector2(6, 0)), "le doigt reste au bouton")
	await wait_process_frames(3)
	assert_true(Input.is_action_pressed(&"charge"), "charge maintenue tant que le doigt reste")
	_touch(3, point, false)
	assert_false(Input.is_action_pressed(&"charge"), "relâcher lance l'onde")


func test_joystick_gives_expected_strength() -> void:
	var start := _center("Joystick")
	var reach: float = (_controls.get_node("Joystick") as TouchJoystick).radius
	assert_true(_touch(1, start), "le joystick prend le doigt")
	_drag(1, start + Vector2(reach * 0.5, 0))
	assert_almost_eq(Input.get_action_strength(&"move_right"), 0.5, 0.01, "mi-course à droite")
	assert_eq(Input.get_action_strength(&"move_left"), 0.0)
	_drag(1, start + Vector2(0, -reach * 2.0))
	assert_almost_eq(Input.get_action_strength(&"move_forward"), 1.0, 0.01, "plafonné au bord")
	assert_false(Input.is_action_pressed(&"move_right"), "plus de composante à droite")
	_drag(1, start + Vector2(reach * 0.6, reach * 0.6))
	assert_almost_eq(Input.get_action_strength(&"move_right"), 0.6, 0.01)
	assert_almost_eq(Input.get_action_strength(&"move_back"), 0.6, 0.01)
	var vector := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	assert_almost_eq(vector.angle(), PI / 4.0, 0.01, "direction conservée par get_vector")
	_drag(1, start + Vector2(reach * 0.03, 0))
	assert_false(Input.is_action_pressed(&"move_right"), "zone morte au centre")
	_drag(1, start + Vector2(-reach, 0))
	_touch(1, start, false)
	for action in MOVES:
		assert_false(Input.is_action_pressed(action), "%s relâché avec le doigt" % action)


func test_multitouch_keeps_each_finger_on_its_control() -> void:
	var start := _center("Joystick")
	var reach: float = (_controls.get_node("Joystick") as TouchJoystick).radius
	_touch(0, start)
	_drag(0, start + Vector2(reach, 0))
	_touch(1, _center("Attack"))
	_touch(2, _center("Jump"))
	assert_true(Input.is_action_pressed(&"move_right"), "doigt 0 : joystick")
	assert_true(Input.is_action_pressed(&"attack"), "doigt 1 : épée")
	assert_true(Input.is_action_pressed(&"jump"), "doigt 2 : saut")
	_touch(1, _center("Attack"), false)
	assert_false(Input.is_action_pressed(&"attack"), "lever le doigt 1 relâche l'épée")
	assert_true(Input.is_action_pressed(&"move_right"), "sans toucher au joystick")
	assert_true(Input.is_action_pressed(&"jump"), "ni au saut")
	_drag(0, start + Vector2(-reach, 0))
	assert_true(Input.is_action_pressed(&"move_left"), "le joystick suit toujours le doigt 0")
	_touch(2, _center("Jump"), false)
	_touch(0, start, false)
	assert_false(Input.is_action_pressed(&"jump") or Input.is_action_pressed(&"move_left"))


func test_drag_on_right_half_turns_the_camera() -> void:
	var point := Vector2(_controls.size.x * 0.7, _controls.size.y * 0.35)
	var touch := InputEventScreenTouch.new()
	touch.index = 4
	touch.position = point
	touch.pressed = true
	assert_false(_controls.handle_input(touch), "hors de nos contrôles : l'interface passe avant")
	assert_true(_controls.handle_unhandled_input(touch), "puis la caméra prend le doigt")
	assert_true(_drag(4, point + Vector2(30, 0), Vector2(30, 0)))
	_controls.update_camera(0.1)
	Input.flush_buffered_events()
	var expected := 30.0 / 0.1 / _controls.camera_full_speed
	assert_almost_eq(Input.get_action_strength(&"camera_right"), expected, 0.01, "vers la droite")
	assert_eq(Input.get_action_strength(&"camera_left"), 0.0)
	_drag(4, point + Vector2(30, -50), Vector2(0, -50))
	_controls.update_camera(0.1)
	Input.flush_buffered_events()
	assert_almost_eq(Input.get_action_strength(&"camera_up"), 0.5, 0.01, "vers le haut")
	assert_false(Input.is_action_pressed(&"camera_right"), "le doigt ne va plus à droite")
	_controls.update_camera(0.1)
	Input.flush_buffered_events()
	assert_false(Input.is_action_pressed(&"camera_up"), "doigt immobile : la caméra s'arrête")
	assert_true(_touch(4, point, false), "le relâchement est à nous")


func test_left_half_and_buttons_never_start_the_camera() -> void:
	assert_false(_touch(5, Vector2(30, 30)), "coin haut gauche : ni joystick ni caméra")
	_touch(5, Vector2(30, 30), false)
	_touch(6, _center("Attack"))
	_drag(6, _center("Attack") + Vector2(40, 0), Vector2(40, 0))
	_controls.update_camera(0.1)
	Input.flush_buffered_events()
	assert_false(
		Input.is_action_pressed(&"camera_right"), "glisser depuis un bouton : pas de caméra"
	)


func test_emulated_mouse_stays_with_the_touch_controls() -> void:
	var emulation := InputEvent.DEVICE_ID_EMULATION
	assert_true(_controls.handle_input(_mouse(emulation, _center("Attack"), true)), "sur un bouton")
	var motion := InputEventMouseMotion.new()
	motion.device = emulation
	motion.position = _center("Attack") + Vector2(5, 0)
	assert_true(_controls.handle_input(motion), "ses mouvements aussi")
	assert_true(_controls.handle_input(_mouse(emulation, _center("Attack"), false)))
	var elsewhere := _mouse(emulation, Vector2(_controls.size.x * 0.7, 300), true)
	assert_false(_controls.handle_input(elsewhere), "ailleurs, l'interface la reçoit d'abord")
	assert_true(_controls.handle_unhandled_input(elsewhere), "puis la caméra souris ne la voit pas")
	var real := _mouse(0, Vector2(_controls.size.x * 0.7, 300), true)
	assert_false(_controls.handle_input(real) or _controls.handle_unhandled_input(real))


func test_pause_keeps_only_pause_and_bag() -> void:
	_touch(0, _center("Attack"))
	get_tree().paused = true
	_controls._process(0.0)
	Input.flush_buffered_events()
	assert_false(Input.is_action_pressed(&"attack"), "l'action tenue est relâchée")
	assert_false(_controls.get_node("Attack").visible)
	assert_false(_controls.get_node("Joystick").visible)
	assert_false(_controls.get_node("Interact").visible)
	assert_true(_controls.get_node("Pause").visible, "Pause reste pour reprendre")
	assert_true(_controls.get_node("Inventory").visible, "Sac reste pour fermer l'inventaire")
	get_tree().paused = false
	_controls._process(0.0)
	assert_true(_controls.get_node("Attack").visible)


func test_dialogue_keeps_talk_and_pause() -> void:
	var talk := _controls.button_for(&"interact")
	EventBus.interaction_available.emit("Ramasser")
	assert_eq(talk.caption(), "Ramasser", "le bouton Parler montre l'invite")
	EventBus.dialogue_started.emit(&"bibliothecaire")
	assert_false(_controls.get_node("Attack").visible)
	assert_false(_controls.get_node("Joystick").visible)
	assert_false(_controls.get_node("Inventory").visible)
	assert_true(talk.visible, "Parler fait avancer le dialogue")
	assert_eq(talk.caption(), "Suite")
	assert_true(_controls.get_node("Pause").visible)
	EventBus.dialogue_ended.emit(&"bibliothecaire")
	EventBus.interaction_available.emit("")
	assert_true(_controls.get_node("Attack").visible)
	assert_eq(talk.caption(), "Parler")


func test_leaving_the_tree_releases_everything() -> void:
	_touch(0, _center("Attack"))
	_touch(1, _center("Joystick"))
	_drag(1, _center("Joystick") + Vector2(80, 0))
	remove_child(_controls)
	Input.flush_buffered_events()
	assert_false(Input.is_action_pressed(&"attack"))
	assert_false(Input.is_action_pressed(&"move_right"))


func test_touch_targets_are_large() -> void:
	for node_name: String in BUTTONS:
		var button := _controls.get_node(node_name) as TouchButton
		assert_gte(button.radius(), 36.0, "%s : au moins 72 px de diamètre" % node_name)
	assert_gte((_controls.get_node("Attack") as TouchButton).radius(), 60.0)
	var stick := _controls.get_node("Joystick") as Control
	assert_gte(stick.size.x, _controls.size.x * 0.4, "zone du joystick : 40 % de la largeur")
