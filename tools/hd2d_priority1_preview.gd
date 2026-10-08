extends SceneTree
## Fumée du rendu livré en priorité 1, et captures réelles sous Xvfb.
## tools/godot --headless --script tools/hd2d_priority1_preview.gd
## Sous Xvfb, ajouter -- --capture-dir=build/shots/priority1 pour les PNG.

const PREVIEW_PATH := "res://scenes/hd2d/island68.tscn"
const COUNTS: Dictionary[String, int] = {
	"repos": 2,
	"marche": 6,
	"course": 5,
	"attaque": 4,
	"charge": 4,
	"degats": 1,
	"mort": 1,
}
const FACINGS: Dictionary[String, Vector3] = {
	"front": Vector3.BACK,
	"back": Vector3.FORWARD,
	"right": Vector3.RIGHT,
}

var _failures: Array[String] = []
var _checks: int = 0
var _output: String = ""


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			_output = argument.trim_prefix("--capture-dir=")
	if not _output.is_empty():
		DirAccess.make_dir_recursive_absolute(_output)
	var packed := load(PREVIEW_PATH) as PackedScene
	if not _require(packed != null, "La promenade se charge"):
		_finish()
		return
	var scene := packed.instantiate() as Node3D
	root.add_child(scene)
	await process_frame
	var visual := scene.get("_visual") as CharacterVisual
	_require(visual.skin.mesh_scene == null, "Chtholly utilise une planche 2D")
	_require(visual.skin.directional_sheets.size() == 3, "Les trois directions sont présentes")
	var camera := scene.get("_camera") as Camera3D
	_require(camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "Caméra orthographique")
	for zone_index: int in [0, 4]:
		scene.call("select_zone", zone_index)
		await process_frame
		_require(scene.get("_zone_index") == zone_index, "Sélection du lieu %d" % zone_index)
		await _capture("cour.png" if zone_index == 0 else "colline.png")
	scene.set_physics_process(false)
	visual.set_process(false)
	for direction: String in FACINGS:
		var frames := SheetLoader.frames_for(visual.skin, direction)
		if not _require(frames != null, "Atlas chargé : " + direction):
			continue
		visual.set_facing(FACINGS[direction])
		_require(visual.current_direction() == direction, "Direction affichée : " + direction)
		var sheet := SheetLoader.read_sheet(visual.skin, direction)
		_require(SheetLoader.hit_frames(sheet, &"attaque") == [1, 2, 3], "Fenêtres de coup")
		_require(SheetLoader.wave_frame(sheet, &"charge") == 3, "Départ de l'onde")
		_require(
			is_equal_approx(SheetLoader.pixel_size(visual.skin, sheet), 1.0 / 96.0),
			"Densité du personnage : " + direction
		)
		for clip_name: String in COUNTS:
			_require(
				frames.get_frame_count(clip_name) == COUNTS[clip_name],
				"Nombre d'images : " + direction + "/" + clip_name
			)
			visual.play(StringName(clip_name), true)
			_require(visual.current_animation() == StringName(clip_name), "Clip affiché")
			if COUNTS[clip_name] > 1:
				visual.advance(1.0 / frames.get_animation_speed(clip_name) + 0.0001)
				_require(visual.current_frame() == 1, "La vraie horloge avance : " + clip_name)
	visual.set_facing(Vector3.LEFT)
	_require(visual.current_direction() == "right", "La gauche partage le profil")
	var sprite := visual.get_node("Sprite") as AnimatedSprite3D
	_require(sprite.flip_h, "Le profil gauche est retourné")
	if not _output.is_empty():
		await _capture_directions(scene, visual.skin)
	var missing := scene.get("_missing") as Dictionary
	for missing_path: String in missing:
		print("HD2D_PREVIEW_MISSING: ", missing_path)
	scene.queue_free()
	await process_frame
	_finish()


func _capture_directions(scene: Node3D, skin: SkinData) -> void:
	(scene.get("_zone") as Node3D).hide()
	(scene.get("_hero") as Node3D).hide()
	for child: Node in scene.get_children():
		if child is CanvasLayer:
			for control: Node in child.get_children():
				if control is CanvasItem:
					(control as CanvasItem).hide()
		elif child is WorldEnvironment:
			var world := child as WorldEnvironment
			world.environment.background_mode = Environment.BG_COLOR
			world.environment.background_color = Color("3d324b")
	var camera := scene.get("_camera") as Camera3D
	camera.size = 5.2
	camera.position = Vector3(0, 4, 10)
	camera.look_at(Vector3(0, 0.8, 0))
	var stage := Node3D.new()
	root.add_child(stage)
	var layer := CanvasLayer.new()
	stage.add_child(layer)
	var caption := Label.new()
	caption.position = Vector2(24, 24)
	caption.add_theme_font_size_override("font_size", 28)
	caption.add_theme_color_override("font_color", Color("ffe6a6"))
	layer.add_child(caption)
	var views: Array[CharacterVisual] = []
	var index := 0
	for direction: String in FACINGS:
		var view := load("res://src/visuals/character_visual.tscn").instantiate() as CharacterVisual
		stage.add_child(view)
		view.set_skin(skin)
		view.position.x = (index - 1) * 2.4
		view.set_facing(FACINGS[direction])
		view.set_process(false)
		views.append(view)
		var label := Label.new()
		label.text = {"front": "Face", "back": "Dos", "right": "Profil"}[direction]
		label.position = camera.unproject_position(Vector3(view.position.x, 2.1, 0))
		label.position.x -= 32
		label.add_theme_font_size_override("font_size", 22)
		layer.add_child(label)
		index += 1
	for clip_name: String in ["repos", "marche", "course", "attaque", "charge"]:
		caption.text = "Chtholly — " + clip_name.capitalize()
		for view: CharacterVisual in views:
			view.play(StringName(clip_name), true)
		await _capture("chtholly_%s_0.png" % clip_name)
		for view: CharacterVisual in views:
			var frames := SheetLoader.frames_for(skin, view.current_direction())
			view.advance(1.0 / frames.get_animation_speed(clip_name) + 0.0001)
		await _capture("chtholly_%s_1.png" % clip_name)
	stage.queue_free()


func _capture(filename: String) -> void:
	if _output.is_empty():
		return
	for frame_index: int in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(_output.path_join(filename))
	_require(error == OK, "Capture : " + filename)


func _require(condition: bool, description: String) -> bool:
	_checks += 1
	if not condition:
		_failures.append(description)
	return condition


func _finish() -> void:
	for failure: String in _failures:
		printerr("HD2D_PREVIEW_FAILURE: ", failure)
	print("HD2D_PRIORITY1_PREVIEW: %d contrôles, %d échec(s)" % [_checks, _failures.size()])
	quit(0 if _failures.is_empty() else 1)
