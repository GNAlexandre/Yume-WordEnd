extends GutTest
## Lot 1 — caméra du joueur (camera_rig.tscn) : réglages de la scène, zoom borné (3 à 10 m) à
## la molette, tangage borné, orbite souris et stick, capture du pointeur au clic et libération
## (pause, mise en pause, dialogue, sortie de l'arbre), recentrage doux derrière le joueur qui
## avance, cadrage de la cible verrouillée, collision du bras avec le décor (couche 1 seulement).
## La caméra est pilotée par update_camera() (son _process est coupé).

const RIG := preload("res://src/player/camera_rig.tscn")
const CameraRigScript := preload("res://src/player/camera_rig.gd")
const DT := 1.0 / 60.0

# --- Outils -----------------------------------------------------------------------------------


func _spawn_rig() -> CameraRigScript:
	var rig: CameraRigScript = RIG.instantiate()
	add_child_autofree(rig)
	rig.set_process(false)
	return rig


func _mouse_button(rig: CameraRigScript, index: MouseButton, device: int = 0) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = index
	event.pressed = true
	event.device = device
	rig._unhandled_input(event)


func _update(rig: CameraRigScript, seconds: float, look: Vector2 = Vector2.ZERO) -> void:
	for _i in roundi(seconds / DT):
		rig.update_camera(DT, look)


func _add_wall(at: Vector3, layer: int) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = layer
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(8, 8, 0.3)
	shape.shape = box
	body.add_child(shape)
	body.position = at
	add_child_autofree(body)
	return body


# --- Réglages, zoom, orbite -------------------------------------------------------------------


func test_scene_defaults() -> void:
	var rig := _spawn_rig()
	assert_eq(rig.spring_arm.collision_mask, 1, "le bras ne heurte que le décor")
	assert_true(rig.camera.current, "caméra courante")
	assert_eq(get_viewport().get_camera_3d(), rig.camera)
	assert_almost_eq(rig.pitch(), deg_to_rad(-22.0), 0.01, "caméra au-dessus, 22° vers le bas")
	assert_almost_eq(rig.yaw(), 0.0, 0.001, "derrière le joueur (regarde vers −Z)")
	assert_almost_eq(rig.zoom_distance(), 6.0, 0.001)


func test_wheel_zoom_is_clamped_between_3_and_10_m() -> void:
	var rig := _spawn_rig()
	for _i in 12:
		_mouse_button(rig, MOUSE_BUTTON_WHEEL_UP)
	assert_almost_eq(rig.zoom_distance(), 3.0, 0.001, "zoom avant borné à 3 m")
	for _i in 20:
		_mouse_button(rig, MOUSE_BUTTON_WHEEL_DOWN)
	assert_almost_eq(rig.zoom_distance(), 10.0, 0.001, "zoom arrière borné à 10 m")
	_update(rig, 1.0)
	assert_almost_eq(rig.spring_arm.spring_length, 10.0, 0.01, "le bras rejoint la distance")


func test_pitch_is_clamped() -> void:
	var rig := _spawn_rig()
	rig.rotate_view(0.0, -10.0)
	assert_almost_eq(rig.pitch(), deg_to_rad(rig.min_pitch_deg), 0.001, "pas plus haut")
	rig.rotate_view(0.0, 10.0)
	assert_almost_eq(rig.pitch(), deg_to_rad(rig.max_pitch_deg), 0.001, "pas plus bas")
	_update(rig, 0.5, Vector2(0, -1))
	assert_almost_eq(rig.pitch(), deg_to_rad(rig.max_pitch_deg), 0.001, "stick : même borne")


func test_mouse_and_stick_orbit() -> void:
	var rig := _spawn_rig()
	rig.orbit_mouse(Vector2(100, 0))
	assert_almost_eq(rig.yaw(), -100 * rig.mouse_sensitivity, 0.0001, "souris à droite")
	assert_gt(rig.forward().x, 0.0, "la vue tourne vers la droite")
	var pitch_before := rig.pitch()
	rig.orbit_mouse(Vector2(0, -40))
	assert_almost_eq(rig.pitch(), pitch_before + 40 * rig.mouse_sensitivity, 0.0001, "vers le haut")
	rig.invert_y = true
	rig.orbit_mouse(Vector2(0, -40))
	assert_almost_eq(rig.pitch(), pitch_before, 0.0001, "axe vertical inversé")
	var yaw_before := rig.yaw()
	rig.update_camera(0.5, Vector2(1, 0))
	assert_almost_eq(rig.yaw(), yaw_before - 0.5 * rig.stick_speed.x, 0.0001, "stick à droite")


# --- Pointeur de la souris ----------------------------------------------------------------------


func test_click_captures_pointer_and_pause_releases_it() -> void:
	var rig := _spawn_rig()
	assert_false(rig.is_pointer_captured())
	_mouse_button(rig, MOUSE_BUTTON_LEFT)
	assert_true(rig.is_pointer_captured(), "clic dans le jeu : capture")
	var pause := InputEventAction.new()
	pause.action = &"pause"
	pause.pressed = true
	rig._input(pause)
	assert_false(rig.is_pointer_captured(), "action pause : libéré")
	_mouse_button(rig, MOUSE_BUTTON_LEFT)
	rig.notification(Node.NOTIFICATION_PAUSED)
	assert_false(rig.is_pointer_captured(), "arbre mis en pause (menu, inventaire) : libéré")
	_mouse_button(rig, MOUSE_BUTTON_LEFT, InputEvent.DEVICE_ID_EMULATION)
	assert_false(rig.is_pointer_captured(), "toucher émulé en clic : pas de capture")
	_mouse_button(rig, MOUSE_BUTTON_LEFT)
	remove_child(rig)
	assert_false(rig.is_pointer_captured(), "sortie de l'arbre (retour au menu) : libéré")
	add_child(rig)


func test_dialogue_releases_pointer_and_blocks_capture() -> void:
	var rig := _spawn_rig()
	_mouse_button(rig, MOUSE_BUTTON_LEFT)
	EventBus.dialogue_started.emit(&"l1_test")
	assert_false(rig.is_pointer_captured(), "souris libre pour les choix du dialogue")
	_mouse_button(rig, MOUSE_BUTTON_LEFT)
	assert_false(rig.is_pointer_captured(), "pas de capture pendant le dialogue")
	EventBus.dialogue_ended.emit(&"l1_test")
	_mouse_button(rig, MOUSE_BUTTON_LEFT)
	assert_true(rig.is_pointer_captured(), "capture au clic après le dialogue")


# --- Recentrage -------------------------------------------------------------------------------


func test_recenters_behind_moving_player_after_delay() -> void:
	var rig := _spawn_rig()
	rig.follow_velocity = Vector3(4, 0, -4)
	_update(rig, 0.5)
	assert_almost_eq(rig.yaw(), 0.0, 0.001, "pas avant recenter_delay")
	_update(rig, 4.0)
	assert_almost_eq(rig.yaw(), -PI / 4.0, 0.02, "derrière le joueur qui avance en diagonale")


func test_does_not_spin_toward_a_player_walking_to_the_camera() -> void:
	var rig := _spawn_rig()
	rig.follow_velocity = Vector3(0, 0, 4)
	_update(rig, 3.0)
	assert_almost_eq(rig.yaw(), 0.0, 0.001, "pas de demi-tour de la caméra")
	rig.follow_velocity = Vector3.ZERO
	_update(rig, 3.0)
	assert_almost_eq(rig.yaw(), 0.0, 0.001, "joueur immobile : caméra immobile")


func test_manual_orbit_postpones_recentering() -> void:
	var rig := _spawn_rig()
	rig.follow_velocity = Vector3(4, 0, 0)
	_update(rig, 1.2)
	rig.rotate_view(0.6, 0.0)
	var manual := rig.yaw()
	_update(rig, 0.8)
	assert_almost_eq(rig.yaw(), manual, 0.001, "la caméra touchée n'est pas reprise tout de suite")
	_update(rig, 4.0)
	assert_almost_eq(rig.yaw(), -PI / 2.0, 0.02, "puis elle se replace derrière le joueur")


func test_snap_and_recenter_behind_a_direction() -> void:
	var rig := _spawn_rig()
	rig.rotate_view(1.0, 0.5)
	rig.snap_behind(Vector3(1, 0, 0))
	assert_almost_eq(rig.yaw(), -PI / 2.0, 0.001, "immédiatement derrière")
	assert_almost_eq(rig.pitch(), rig.default_pitch(), 0.001)
	rig.recenter_behind(Vector3(0, 0, 1))
	_update(rig, 1.5)
	assert_almost_eq(absf(angle_difference(rig.yaw(), PI)), 0.0, 0.02, "en douceur")


# --- Verrouillage -------------------------------------------------------------------------------


func test_frames_locked_target_and_ignores_manual_orbit() -> void:
	var rig := _spawn_rig()
	var target: Node3D = add_child_autofree(Node3D.new())
	target.position = Vector3(6, -1.3, 0)
	rig.lock_target = target
	_update(rig, 1.0)
	assert_almost_eq(rig.yaw(), -PI / 2.0, 0.01, "regarde vers la cible")
	assert_almost_eq(rig.pitch(), deg_to_rad(rig.lock_pitch_deg), 0.02, "tangage de cadrage")
	assert_gt(rig.spring_arm.position.x, 1.0, "point visé avancé vers la cible")
	assert_lt(rig.spring_arm.position.x, rig.lock_focus_max + 0.01)
	var locked_yaw := rig.yaw()
	rig.orbit_mouse(Vector2(300, 0))
	rig.update_camera(DT, Vector2(1, 0))
	assert_almost_eq(rig.yaw(), locked_yaw, 0.01, "orbite manuelle ignorée pendant le verrou")
	target.free()
	_update(rig, 1.0)
	assert_almost_eq(
		rig.spring_arm.position.length(), 0.0, 0.01, "cible libérée : retour au joueur"
	)


# --- Collision du bras --------------------------------------------------------------------------


func test_spring_arm_shortens_against_world_only() -> void:
	var rig := _spawn_rig()
	var wall := _add_wall(Vector3(0, 0.8, 2.0), 1)
	await wait_physics_frames(3)
	assert_lt(rig.spring_arm.get_hit_length(), 2.5, "mur du décor derrière : bras raccourci")
	wall.collision_layer = 2
	await wait_physics_frames(3)
	assert_almost_eq(rig.spring_arm.get_hit_length(), 6.0, 0.01, "autre couche : ignorée")
