extends GutTest
## CharacterVisual (L3), variante mesh : un SkinData sans planche mais avec mesh_scene
## (tests/stubs/l3_mesh_capsule.tscn : capsule + AnimationPlayer aux animations nommées comme
## la planche, métadonnées « ips », « coup », « onde ») passe derrière la même interface.

const VISUAL := preload("res://src/visuals/character_visual.tscn")
const CAPSULE := preload("res://tests/stubs/l3_capsule_skin.tres")
const CHTHOLLY := preload("res://data/skins/chtholly.tres")
const FINISHED := -1

var _events: Array = []


func _visual(skin: SkinData) -> CharacterVisual:
	var visual: CharacterVisual = add_child_autofree(VISUAL.instantiate())
	visual.set_process(false)
	visual.set_skin(skin)
	_events.clear()
	visual.frame_changed.connect(
		func(anim: StringName, frame: int) -> void: _events.append([anim, frame])
	)
	visual.animation_finished.connect(
		func(anim: StringName) -> void: _events.append([anim, FINISHED])
	)
	return visual


func test_mesh_skin_replaces_the_sprite() -> void:
	var visual := _visual(CAPSULE)
	var mesh := visual.get_node_or_null(^"Mesh") as Node3D
	assert_not_null(mesh, "scène du mesh instanciée sous « Mesh »")
	assert_false((visual.get_node(^"Sprite") as Node3D).visible, "sprite caché")
	assert_true((visual.get_node(^"Shadow") as Node3D).visible, "l'ombre reste")
	for anim: StringName in [
		&"repos", &"marche", &"course", &"attaque", &"charge", &"degats", &"mort"
	]:
		assert_true(visual.has_animation(anim), String(anim))
	assert_eq(visual.current_animation(), &"repos")
	assert_eq(visual.hit_frames(&"attaque"), [1, 2, 3] as Array[int], "coup en métadonnée")
	assert_eq(visual.wave_frame(&"charge"), 3, "onde en métadonnée")
	assert_eq(visual.wave_frame(&"attaque"), -1)


func test_mesh_animation_is_paced_like_a_sheet() -> void:
	var visual := _visual(CAPSULE)
	var body := visual.get_node(^"Mesh/Body") as Node3D
	visual.play(&"attaque")
	var frame_time := 1.0 / 14.0
	for i in 4:
		visual.advance(frame_time)
	assert_eq(
		_events,
		[
			[&"attaque", 0],
			[&"attaque", 1],
			[&"attaque", 2],
			[&"attaque", 3],
			[&"attaque", FINISHED]
		],
		"4 images à 14 ips, puis la fin"
	)
	assert_almost_eq(body.rotation.x, 0.6, 0.01, "pose de fin de l'AnimationPlayer")
	_events.clear()
	visual.play(&"marche")
	visual.advance(0.65)
	assert_eq(_events.size(), 7, "boucle de 6 images à 10 ips : 0 1 2 3 4 5 0")
	assert_eq(visual.current_frame(), 0)
	visual.show_frame(&"mort", 0)
	visual.advance(0.5)
	assert_almost_eq(body.rotation.x, 0.0, 0.01, "figée sur l'image 0")
	visual.play(&"mort")
	visual.advance(0.5)
	assert_almost_eq(body.rotation.x, -1.5, 0.01, "la pose suit l'horloge du visuel")


func test_mesh_turns_toward_facing() -> void:
	var visual := _visual(CAPSULE)
	var mesh := visual.get_node(^"Mesh") as Node3D
	visual.set_facing(Vector3.LEFT)
	assert_almost_eq(mesh.global_rotation.y, -PI / 2.0, 0.001, "avant du mesh (+Z) vers -X")
	visual.set_facing(Vector3.BACK)
	assert_almost_eq(mesh.global_rotation.y, 0.0, 0.001)


func test_switching_between_mesh_and_sheet() -> void:
	var visual := _visual(CAPSULE)
	var old_mesh := visual.get_node(^"Mesh")
	visual.play(&"course")
	visual.set_skin(CHTHOLLY)
	assert_null(visual.get_node_or_null(^"Mesh"), "mesh retiré")
	assert_true((visual.get_node(^"Sprite") as Node3D).visible)
	assert_eq(visual.current_animation(), &"course", "l'animation continue sur la planche")
	visual.set_skin(CAPSULE)
	assert_not_null(visual.get_node_or_null(^"Mesh"))
	assert_false((visual.get_node(^"Sprite") as Node3D).visible)
	await wait_process_frames(1)
	assert_false(is_instance_valid(old_mesh), "l'ancien mesh est libéré")
