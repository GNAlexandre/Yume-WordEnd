extends SceneTree
## Capture les quatre poses d'attaque effectives, dans les trois orientations.
## xvfb-run -a tools/godot --path . --script tools/hd2d_weapon_preview.gd

const FACINGS := {"front": Vector3.BACK, "back": Vector3.FORWARD, "right": Vector3.RIGHT}
const DESTINATION := "res://docs/sprites/previews/"


func _initialize() -> void:
	call_deferred("capture_weapons")


func capture_weapons() -> void:
	root.size = Vector2i(1400, 1100)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DESTINATION))
	var stage := Node3D.new()
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("302b42")
	stage.add_child(environment)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 11.2
	camera.position = Vector3(0, 5.5, 20)
	stage.add_child(camera)
	var layer := CanvasLayer.new()
	stage.add_child(layer)
	var title := Label.new()
	title.position = Vector2(24, 12)
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("ffe6a6"))
	layer.add_child(title)
	var views: Array[CharacterVisual] = []
	var row := 0
	for direction: String in FACINGS:
		for phase: int in range(4):
			var view := (
				load("res://src/visuals/character_visual.tscn").instantiate() as CharacterVisual
			)
			stage.add_child(view)
			view.position = Vector3((phase - 1.5) * 3.3, 8.0 - row * 3.5, 0)
			view.set_facing(FACINGS[direction])
			view.set_process(false)
			views.append(view)
			var label := Label.new()
			var label_direction: String = {"front": "Face", "back": "Dos", "right": "Profil"}[direction]
			label.text = "%s · pose %d" % [label_direction, phase + 1]
			label.position = (
				camera.unproject_position(view.position + Vector3(0, -0.1, 0)) - Vector2(70, 0)
			)
			label.add_theme_font_size_override("font_size", 20)
			layer.add_child(label)
		row += 1
	for identifier: String in ["ithea", "nephren"]:
		var skin := load("res://data/skins/sukasuka_%s.tres" % identifier) as SkinData
		title.text = "%s — attaque · quatre poses / trois vues" % identifier.capitalize()
		for index: int in range(views.size()):
			views[index].set_skin(skin)
			views[index].show_frame(&"attaque", index % 4)
		for frame: int in range(10):
			await process_frame
		await RenderingServer.frame_post_draw
		var filename := DESTINATION + identifier + "-attaque-directions.png"
		var destination := ProjectSettings.globalize_path(filename)
		if root.get_texture().get_image().save_png(destination) != OK:
			push_error("Échec de capture : " + destination)
			quit(1)
			return
	print("HD2D_WEAPON_PREVIEW: 24 poses effectives capturées depuis SkinData")
	quit(0)
