extends GutTest
## (HD-2D) Caméra fixe du joueur (camera_rig.tscn) : réglages de la scène (inclinaison, champ
## étroit, regard vers le nord), suivi du joueur avec un léger retard, bornes de l'île, zoom borné
## (molette et stick droit), cadrage de la cible verrouillée sans rotation, post-traitement sous
## l'interface et son shader qui compile. La caméra est pilotée par update_camera() (son _process
## est coupé).

const RIG := preload("res://src/player/camera_rig.tscn")
const CameraRigScript := preload("res://src/player/camera_rig.gd")
const POST_SHADER := preload("res://src/player/post_fx.gdshader")
const DT := 1.0 / 60.0

# --- Outils -----------------------------------------------------------------------------------


func _spawn_rig(at: Vector3 = Vector3.ZERO) -> CameraRigScript:
	var holder := Node3D.new()
	holder.position = at
	add_child_autofree(holder)
	var rig: CameraRigScript = RIG.instantiate()
	holder.add_child(rig)
	rig.set_process(false)
	return rig


func _mouse_button(rig: CameraRigScript, index: MouseButton) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = index
	event.pressed = true
	rig._unhandled_input(event)


func _update(rig: CameraRigScript, seconds: float, zoom_axis: float = 0.0) -> void:
	for _i in roundi(seconds / DT):
		rig.update_camera(DT, zoom_axis)


# --- Réglages ---------------------------------------------------------------------------------


func test_scene_defaults_fixed_tilted_narrow() -> void:
	var rig := _spawn_rig()
	assert_true(rig.camera.current, "caméra courante")
	assert_true(rig.camera.top_level, "ne suit pas les rotations du joueur")
	assert_between(rig.pitch_deg, 30.0, 40.0, "inclinée de 30 à 40°")
	assert_lte(rig.camera.fov, 40.0, "champ étroit")
	assert_eq(rig.forward(), Vector3.FORWARD, "regarde le nord")
	assert_eq(rig.yaw(), 0.0)
	var look := -rig.camera.global_basis.z
	assert_almost_eq(rad_to_deg(asin(-look.y)), rig.pitch_deg, 0.1, "inclinaison appliquée")
	assert_almost_eq(look.x, 0.0, 0.001, "pas de lacet")
	assert_lt(look.z, 0.0, "vers le nord")
	var post := rig.get_node(^"PostFX") as CanvasLayer
	assert_lt(post.layer, 1, "post-traitement sous l'interface (UI : couche 1)")


func test_camera_frames_the_player_from_the_south() -> void:
	var rig := _spawn_rig(Vector3(5, 0, 8))
	_update(rig, 0.1)
	var eye := rig.camera.global_position
	assert_gt(eye.z, 8.0, "au sud du joueur")
	assert_gt(eye.y, 5.0, "au-dessus")
	var to_player := (Vector3(5, rig.focus_height, 8) - eye).normalized()
	assert_almost_eq(
		to_player, -rig.camera.global_basis.z, Vector3.ONE * 0.02, "le joueur au centre"
	)
	assert_almost_eq(eye.distance_to(rig.focus()), rig.distance, 0.05, "à sa distance")


func test_follows_the_player_with_a_slight_lag() -> void:
	var rig := _spawn_rig()
	_update(rig, 0.2)
	var holder := rig.get_parent() as Node3D
	holder.position = Vector3(4, 0, 0)
	_update(rig, DT)
	assert_lt(rig.focus().x, 1.0, "léger retard")
	assert_gt(rig.focus().x, 0.0, "mais elle suit")
	_update(rig, 2.0)
	assert_almost_eq(rig.focus().x, 4.0, 0.05, "rejoint le joueur")
	assert_eq(rig.forward(), Vector3.FORWARD, "sans tourner")


func test_stays_within_the_island_limits() -> void:
	var rig := _spawn_rig(Vector3(78, 0, -79))
	_update(rig, 3.0)
	assert_almost_eq(rig.focus().x, rig.limits.end.x, 0.01, "bornée à l'est")
	assert_almost_eq(rig.focus().z, rig.limits.position.y, 0.01, "bornée au nord")


func test_snap_puts_the_camera_on_the_player_at_once() -> void:
	var rig := _spawn_rig()
	_update(rig, 0.2)
	(rig.get_parent() as Node3D).position = Vector3(-20, 0, 30)
	rig.snap_behind(Vector3.RIGHT)
	assert_almost_eq(rig.focus(), Vector3(-20, rig.focus_height, 30), Vector3.ONE * 0.01)
	assert_eq(rig.forward(), Vector3.FORWARD, "toujours le nord")


func test_zoom_wheel_and_stick_are_clamped() -> void:
	var rig := _spawn_rig()
	for _i in 30:
		_mouse_button(rig, MOUSE_BUTTON_WHEEL_DOWN)
	assert_eq(rig.zoom_distance(), rig.max_distance, "molette : au plus max_distance")
	for _i in 30:
		_mouse_button(rig, MOUSE_BUTTON_WHEEL_UP)
	assert_eq(rig.zoom_distance(), rig.min_distance, "au moins min_distance")
	_update(rig, 2.0, 1.0)
	assert_eq(rig.zoom_distance(), rig.max_distance, "stick droit vers le bas : s'éloigne")
	_update(rig, 2.0)
	assert_almost_eq(
		rig.camera.global_position.distance_to(rig.focus()), rig.max_distance, 0.05, "rejointe"
	)


func test_locked_target_is_framed_without_turning() -> void:
	var rig := _spawn_rig()
	var target := Node3D.new()
	target.position = Vector3(6, 0, 0)
	add_child_autofree(target)
	rig.lock_target = target
	_update(rig, 2.0)
	assert_gt(rig.focus().x, 1.0, "le point visé avance vers la cible")
	assert_lte(rig.focus().x, rig.lock_focus_max + 0.01, "mais pas au-delà de lock_focus_max")
	assert_eq(rig.forward(), Vector3.FORWARD, "sans rotation")
	target.free()
	_update(rig, 2.0)
	assert_almost_eq(rig.focus().x, 0.0, 0.05, "cible disparue : retour au joueur")


func test_post_fx_shader_compiles() -> void:
	var rig := _spawn_rig()
	var screen := rig.get_node(^"PostFX/Screen") as ColorRect
	var material := screen.material as ShaderMaterial
	assert_eq(material.shader, POST_SHADER)
	assert_eq(screen.mouse_filter, Control.MOUSE_FILTER_IGNORE, "ne prend pas les clics")
	var code := POST_SHADER.code
	assert_string_contains(code, "hint_screen_texture")
	assert_string_contains(code, "focus_center", "flou de profondeur")
	assert_string_contains(code, "glow_threshold", "lueur")
	# Un shader qui ne compile pas n'a aucun uniforme exposé.
	assert_gt(POST_SHADER.get_shader_uniform_list().size(), 8, "le shader compile")
