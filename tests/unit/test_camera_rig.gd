extends GutTest
## (HD-2D) Caméra fixe du joueur (camera_rig.tscn) : réglages de la scène (inclinaison, champ
## étroit, regard vers le nord), suivi du joueur avec un léger retard, bornes de l'île, zoom borné
## (molette et stick droit), cadrage de la cible verrouillée sans rotation, post-traitement sous
## l'interface et son shader qui compile ; (H5) bande nette du flou qui suit le joueur à l'écran,
## bornes qui gardent le joueur près du centre au bord de l'île ; (recette du 8 octobre 2026)
## cadrage constant : ni tangage ni recul qui changent en marchant devant ou le long des
## bâtiments, joueur sous le milieu de l'écran, au-dessus de la boîte de dialogue en
## conversation, avance dans le sens de la marche qui s'installe et s'éteint sans à-coup, caméra
## posée hors du lissage physique. La caméra est pilotée par update_camera() (son _process est
## coupé).

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
	var aimed := Vector3(5, rig.focus_height, 8) + Vector3.FORWARD * rig.focus_ahead
	assert_almost_eq(
		(aimed - eye).normalized(),
		-rig.camera.global_basis.z,
		Vector3.ONE * 0.02,
		"vise focus_ahead m au nord du joueur"
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
	assert_almost_eq(
		rig.focus(),
		Vector3(-20, rig.focus_height, 30 - rig.focus_ahead),
		Vector3.ONE * 0.01,
		"au nord du joueur, sans retard"
	)
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


# --- (H5) Bande nette du flou, cadrage des bâtiments -----------------------------------------


func _screen_y(rig: CameraRigScript, point: Vector3) -> float:
	return rig.camera.unproject_position(point).y / rig.get_viewport().get_visible_rect().size.y


func _warehouse(at: Vector3) -> Building:
	var building := Building.new()
	building.footprint = Vector2(16.0, 8.0)
	building.wall_height = 6.5
	building.ridge_height = 9.0
	building.position = at
	add_child_autofree(building)
	return building


func test_focus_band_follows_the_player_on_screen() -> void:
	var rig := _spawn_rig(Vector3(3, 0, -4))
	var holder := rig.get_parent() as Node3D
	_update(rig, 0.5)
	var post := (rig.get_node(^"PostFX/Screen") as ColorRect).material as ShaderMaterial
	var scene_post := RIG.instantiate()
	var shared := (scene_post.get_node(^"PostFX/Screen") as ColorRect).material
	assert_ne(post, shared, "matériau propre à la caméra : la scène n'est pas touchée")
	scene_post.free()
	for offset: Vector3 in [Vector3.ZERO, Vector3(0, 0, -3), Vector3(0, 0, 3)]:
		# Retard du suivi : le joueur se décale à l'écran, la bande le suit dans la même image.
		holder.position = Vector3(3, 0, -4) + offset
		_update(rig, DT)
		var center: float = post.get_shader_parameter(&"focus_center")
		var half: float = post.get_shader_parameter(&"focus_half")
		var player := holder.global_position + Vector3.UP * rig.focus_height
		var y := _screen_y(rig, player)
		assert_between(y, center - half, center + half, "joueur dans la bande nette (%s)" % offset)
		var behind := _screen_y(rig, player + Vector3.FORWARD * 6.0)
		assert_gt(behind, center - half, "6 m derrière le joueur : encore net")
		var far := _screen_y(rig, player + Vector3.FORWARD * 14.0)
		assert_lt(far, center - half, "14 m derrière : dans le flou du lointain")


func test_walking_past_buildings_never_tilts_nor_zooms() -> void:
	# Recette : en marchant vers la façade de l'entrepôt ou le long d'elle, la vue pompait comme
	# un zoom (tangage et recul qui suivaient les bâtiments). Le cadrage reste constant.
	var rig := _spawn_rig(Vector3(0, 0, 26))
	var holder := rig.get_parent() as Node3D
	var building := _warehouse(Vector3(0, 0, 0))
	_update(rig, 1.0)
	var paths: Array[Array] = [
		[Vector3(0, 0, 26), Vector3(0, 0, 5)], [Vector3(-30, 0, 12), Vector3(30, 0, 12)]
	]
	for path: Array in paths:
		var from: Vector3 = path[0]
		var to: Vector3 = path[1]
		var steps := roundi(from.distance_to(to) / 0.066)
		for i in range(1, steps + 1):
			holder.position = from.lerp(to, float(i) / steps)
			rig.follow_velocity = (to - from).normalized() * 4.0
			_update(rig, DT)
			assert_almost_eq(-rig.pitch(), deg_to_rad(rig.pitch_deg), 0.0001, "tangage fixe")
			var reach := rig.camera.global_position.distance_to(rig.focus())
			if not is_equal_approx(reach, rig.distance):
				fail_test("recul de %.2f m en %s" % [reach - rig.distance, holder.position])
				break
	rig.follow_velocity = Vector3.ZERO
	building.free()


func test_player_stands_below_the_middle_of_the_screen() -> void:
	var rig := _spawn_rig(Vector3(4, 0, 6))
	_update(rig, 3.0)
	var feet := _screen_y(rig, rig.global_position)
	assert_between(feet, 0.55, 0.72, "pieds sous le milieu, place pour les façades devant")
	var ahead := _screen_y(rig, rig.global_position + Vector3(0, 6.5, -2.0))
	assert_gt(ahead, 0.0, "un mur de 6,5 m à 2 m au nord du joueur tient dans le cadre")


func test_conversation_keeps_the_player_above_the_dialogue_box() -> void:
	# La boîte de dialogue couvre le bas 30 % de l'écran : en conversation, le point visé glisse
	# vers le joueur, sans recul ni tangage, puis revient.
	var rig := _spawn_rig(Vector3(0, 0, 10))
	_update(rig, 3.0)
	var walking := _screen_y(rig, rig.global_position)
	EventBus.dialogue_started.emit(&"nygglatho")
	_update(rig, DT)
	assert_almost_eq(_screen_y(rig, rig.global_position), walking, 0.01, "pas de saut")
	_update(rig, 3.0)
	assert_lt(_screen_y(rig, rig.global_position), 0.62, "en conversation : au-dessus de la boîte")
	assert_almost_eq(
		rig.camera.global_position.distance_to(rig.focus()), rig.distance, 0.05, "sans recul"
	)
	assert_almost_eq(-rig.pitch(), deg_to_rad(rig.pitch_deg), 0.0001, "sans tangage")
	EventBus.dialogue_ended.emit(&"nygglatho")
	_update(rig, 4.0)
	assert_almost_eq(_screen_y(rig, rig.global_position), walking, 0.01, "puis le cadrage revient")


func test_lead_eases_in_and_out() -> void:
	# Le point visé avance dans le sens de la marche sans à-coup au départ ni à l'arrêt.
	var rig := _spawn_rig()
	_update(rig, 1.0)
	var rest := rig.focus()
	rig.follow_velocity = Vector3(4, 0, 0)
	_update(rig, DT)
	assert_lt(rig.focus().x - rest.x, 0.02, "départ : l'avance ne saute pas")
	_update(rig, 3.0)
	assert_almost_eq(
		rig.focus().x - rest.x, 4.0 * rig.lead_time, 0.05, "en marche : avance de lead_time s"
	)
	var moving := rig.focus().x
	rig.follow_velocity = Vector3.ZERO
	_update(rig, DT)
	assert_gt(rig.focus().x, moving - 0.02, "arrêt : pas de recul brusque")
	_update(rig, 4.0)
	assert_almost_eq(rig.focus().x, rest.x, 0.05, "puis revient sur le joueur")


func test_camera_is_placed_outside_physics_interpolation() -> void:
	var rig := _spawn_rig()
	assert_true(
		ProjectSettings.get_setting("physics/common/physics_interpolation", false),
		"lissage physique : le joueur ne tremble pas hors de 60 images/s"
	)
	assert_eq(
		rig.camera.physics_interpolation_mode,
		Node.PHYSICS_INTERPOLATION_MODE_OFF,
		"la caméra, posée à chaque image, n'est pas interpolée"
	)


func test_wide_limits_keep_the_player_on_screen_at_the_edge() -> void:
	# Au bord du Couchant (x = −76), le point visé reste à moins de 6 m du joueur (l'écran en
	# montre 10 de part et d'autre en 16:9) : on voit le vide à côté, jamais le joueur au bord.
	for spot: Vector3 in [Vector3(-76, 0, 0), Vector3(0, 0, -73), Vector3(0, 0, 70)]:
		var rig := _spawn_rig(spot)
		_update(rig, 3.0)
		var gap := rig.focus() - (spot + Vector3.UP * rig.focus_height)
		assert_lte(Vector2(gap.x, gap.z).length(), 6.0, "point visé près du joueur en %s" % spot)
		(rig.get_parent() as Node3D).free()
