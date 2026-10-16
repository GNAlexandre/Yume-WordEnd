extends GutTest
## (HD-2D) Caméra fixe du joueur (camera_rig.tscn) : réglages de la scène (inclinaison, champ
## étroit, regard vers le nord), suivi du joueur avec un léger retard, bornes de l'île, zoom borné
## (molette et stick droit), cadrage de la cible verrouillée sans rotation, post-traitement sous
## l'interface et son shader qui compile ; (RD) flou selon la vraie profondeur, net autour du
## joueur (DepthBlur, DepthFocus),
## bornes qui gardent le joueur près du centre au bord de l'île ; (recette du 8 octobre 2026)
## cadrage constant : ni tangage ni recul qui changent en marchant devant ou le long des
## bâtiments, joueur sous le milieu de l'écran, au-dessus de la boîte de dialogue en
## conversation, avance dans le sens de la marche qui s'installe et s'éteint sans à-coup, caméra
## posée hors du lissage physique. La caméra est pilotée par update_camera() (son _process est
## coupé). (E1) Bornes de la carte courante à chaque map_entered.

const RIG := preload("res://src/player/camera_rig.tscn")
const CameraRigScript := preload("res://src/player/camera_rig.gd")
const POST_SHADER := preload("res://src/player/post_fx.gdshader")
const DEPTH_SHADER := preload("res://src/player/post_fx_depth.gdshader")
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


func test_limits_follow_the_current_map() -> void:
	# (E1) À chaque carte (EventBus.map_entered) : ses bornes (Map.bounds(), la carte entière
	# par défaut), la caméra courante, recalée sur le joueur.
	var rig := _spawn_rig(Vector3(5, 0, 5))
	var map := Map.new()
	map.name = "carte_test"
	map.size = Vector2(30, 20)
	add_child_autofree(map)
	rig.camera.clear_current(false)
	EventBus.map_entered.emit(&"carte_test")
	assert_eq(rig.limits, Rect2(0, 0, 30, 20), "la carte entière")
	assert_true(rig.camera.current, "redevenue la caméra courante")
	(rig.get_parent() as Node3D).position = Vector3(-10, 0, 40)
	_update(rig, 3.0)
	assert_almost_eq(rig.focus().x, 0.0, 0.01, "bornée à l'ouest de la carte")
	assert_almost_eq(rig.focus().z, 20.0, 0.01, "bornée au sud de la carte")
	map.camera_bounds = Rect2(8, 6, 14, 8)
	EventBus.map_entered.emit(&"carte_test")
	assert_eq(rig.limits, Rect2(8, 6, 14, 8), "bornes choisies par la carte")
	assert_almost_eq(rig.focus(), rig.focus_goal(false), Vector3.ONE * 0.01, "recalée aussitôt")


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


func test_first_frame_snaps_on_a_player_moved_after_ready() -> void:
	# Partie chargée : game.gd pose le joueur à la position sauvegardée après le _ready de la
	# caméra (de même la téléportation au Spawn d'une nouvelle partie). La première image cadre
	# cette place-là, sans glisser depuis la place de player.tscn ; le suivi lissé vient après.
	var rig := _spawn_rig()
	var holder := rig.get_parent() as Node3D
	holder.position = Vector3(0, 0, -60)
	rig.update_camera(DT)
	assert_almost_eq(
		rig.focus(),
		Vector3(0, rig.focus_height, -60 - rig.focus_ahead),
		Vector3.ONE * 0.01,
		"première image : cadrée d'emblée sur le joueur déplacé"
	)
	holder.position = Vector3(4, 0, -60)
	rig.update_camera(DT)
	assert_lt(rig.focus().x, 1.0, "ensuite, le léger retard du suivi")


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
	assert_string_contains(code, "top_blur_px", "flous du réglage de lumière, lus par la caméra")
	assert_string_contains(code, "glow_threshold", "lueur")
	# Un shader qui ne compile pas n'a aucun uniforme exposé.
	assert_gt(POST_SHADER.get_shader_uniform_list().size(), 8, "le shader compile")
	# (RD) Le flou suit la vraie profondeur : rectangle plein écran du monde 3D.
	var blur := rig.get_node(^"Camera3D/DepthBlur") as MeshInstance3D
	var depth_material := blur.material_override as ShaderMaterial
	assert_eq(depth_material.shader, DEPTH_SHADER)
	assert_eq(depth_material.render_priority, -128, "premier des objets mélangés")
	assert_string_contains(DEPTH_SHADER.code, "hint_depth_texture", "lit la profondeur")
	assert_gt(DEPTH_SHADER.get_shader_uniform_list().size(), 6, "le shader de profondeur compile")
	assert_eq(blur.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	assert_true(rig.is_depth_blur_enabled())
	rig.set_depth_blur_enabled(false)
	assert_false(blur.visible, "qualité réduite : le flou s'éteint")
	rig.set_depth_blur_enabled(true)
	# Sous une autre caméra (vue d'ensemble), le rectangle ne se montre pas.
	var other := Camera3D.new()
	add_child_autofree(other)
	other.make_current()
	_update(rig, DT)
	assert_false(blur.visible, "pas sous une autre caméra")
	rig.camera.make_current()
	_update(rig, DT)
	assert_true(blur.visible)


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


func test_focus_depth_follows_the_player() -> void:
	# (RD) Le flou de profondeur est net autour du joueur, quelle que soit sa place à l'écran
	# (retard du suivi), flou au premier plan (6 à 8 px) et adouci au loin.
	var rig := _spawn_rig(Vector3(3, 0, -4))
	var holder := rig.get_parent() as Node3D
	_update(rig, 0.5)
	var blur := rig.depth_blur_material()
	var scene_rig := RIG.instantiate()
	var shared := (scene_rig.get_node(^"Camera3D/DepthBlur") as MeshInstance3D).material_override
	assert_ne(blur, shared, "matériau propre à la caméra : la scène n'est pas touchée")
	scene_rig.free()
	var post := (rig.get_node(^"PostFX/Screen") as ColorRect).material as ShaderMaterial
	for offset: Vector3 in [Vector3.ZERO, Vector3(0, 0, -3), Vector3(0, 0, 3)]:
		holder.position = Vector3(3, 0, -4) + offset
		_update(rig, DT)
		var values := {}
		for key: StringName in DepthFocus.PARAMETERS:
			var value: Variant = blur.get_shader_parameter(key)
			if value != null:
				values[key] = value
		var player := holder.global_position + Vector3.UP * rig.focus_height
		assert_almost_eq(
			float(values[&"focus_depth"]), rig.focus_depth_of(player), 0.01, "profondeur du joueur"
		)
		assert_eq(DepthFocus.radius_px(rig.focus_depth_of(player), values), 0.0, "joueur net")
		for around: Vector3 in [Vector3.FORWARD * 3.0, Vector3.BACK * 1.5, Vector3.RIGHT * 6.0]:
			var near := rig.focus_depth_of(player + around)
			assert_lt(DepthFocus.radius_px(near, values), 0.5, "net à %s du joueur" % around)
		var far := rig.focus_depth_of(player + Vector3.FORWARD * 22.0)
		assert_between(DepthFocus.radius_px(far, values), 2.0, 6.0, "le lointain s'adoucit")
		var front := rig.focus_depth_of(player + Vector3.BACK * 6.0 + Vector3.UP * 3.0)
		assert_between(DepthFocus.radius_px(front, values), 6.0, 8.0, "premier plan flou")
	# Les flous du réglage de lumière (sur PostFX) passent au flou de profondeur.
	post.set_shader_parameter(&"top_blur_px", 3.0)
	post.set_shader_parameter(&"bottom_blur_px", 2.0)
	_update(rig, DT)
	assert_almost_eq(float(blur.get_shader_parameter(&"far_blur_px")), 3.0, 0.001)
	assert_almost_eq(
		float(blur.get_shader_parameter(&"near_blur_px")),
		2.0 * CameraRigScript.NEAR_BLUR_PER_BOTTOM_PX,
		0.001
	)
	# Les matériaux qui se floutent eux-mêmes (ombres des décors) reçoivent la mise au point.
	var shadow := DecorPanel.shadow_material()
	assert_true(DepthFocus.is_registered(shadow))
	assert_almost_eq(
		float(shadow.get_shader_parameter(&"focus_depth")),
		float(blur.get_shader_parameter(&"focus_depth")),
		0.01
	)


func test_depth_focus_defaults_match_the_shader() -> void:
	# Le jumeau sur le processeur (DepthFocus.DEFAULTS) a les valeurs des uniformes du shader.
	var code := FileAccess.get_file_as_string("res://src/world/shaders/depth_focus.gdshaderinc")
	var pattern := RegEx.create_from_string("uniform float (\\w+) = ([0-9.]+);")
	var found := {}
	for result in pattern.search_all(code):
		found[StringName(result.get_string(1))] = float(result.get_string(2))
	for key: StringName in DepthFocus.PARAMETERS:
		assert_true(found.has(key), "uniforme %s" % key)
		assert_almost_eq(float(found.get(key, -1.0)), float(DepthFocus.DEFAULTS[key]), 0.001)


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
