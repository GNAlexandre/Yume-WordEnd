extends Node3D
## Promenade indépendante : les panneaux livrés sont posés à 96 px/m.
## Les scènes de l'histoire et leurs sauvegardes ne sont pas modifiées.

const VISUAL_SCENE: PackedScene = preload("res://src/visuals/character_visual.tscn")
const ZONES: Array[String] = [
	"L'entrepôt des fées",
	"Les bois du marais",
	"Le bord du Couchant",
	"Le port et le bourg",
	"La colline des étoiles",
]
const CENTERS: Array[Vector3] = [
	Vector3.ZERO,
	Vector3(0, 0, -51),
	Vector3(-51, 0, 0),
	Vector3(0, 0, 51),
	Vector3(52, 0, -3),
]

var _zone: Node3D
var _zone_index: int = 0
var _hero: CharacterBody3D
var _visual: CharacterVisual
var _camera: Camera3D
var _heading: Label
var _buttons: Array[Button] = []
var _missing: Dictionary[String, bool] = {}
var _combat_time: float = 0.0
var _npcs: Array[CharacterVisual] = []
var _nearby: CharacterVisual
var _talking: CharacterVisual
var _talk_time: float = 0.0
var _prompt: Label
var _zone_row: HBoxContainer
var _zone_picker: OptionButton
var _controls: Label


func _ready() -> void:
	_make_light()
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = 26.0
	_camera.far = 300.0
	_camera.current = true
	add_child(_camera)
	_make_hero()
	_make_hud()
	select_zone(0)


func _make_light() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("82769c")
	var sky_texture := _texture("sky/sky")
	if sky_texture != null:
		var material := PanoramaSkyMaterial.new()
		material.panorama = sky_texture
		var sky := Sky.new()
		sky.sky_material = material
		environment.sky = sky
		environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("f4dcc6")
	environment.ambient_light_energy = 0.8
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color("ffe6a6")
	sun.light_energy = 0.55
	sun.rotation_degrees = Vector3(-40, -70, 0)
	add_child(sun)


func _make_hero() -> void:
	_hero = CharacterBody3D.new()
	_hero.name = "Chtholly"
	add_child(_hero)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.25
	capsule.height = 1.5
	shape.shape = capsule
	shape.position.y = 0.75
	_hero.add_child(shape)
	_visual = VISUAL_SCENE.instantiate() as CharacterVisual
	_hero.add_child(_visual)
	var skin_path := "res://data/visuals2d/characters/chtholly/chtholly.tres"
	if not ResourceLoader.exists(skin_path):
		skin_path = "res://data/visuals2d/generated/characters/chtholly/chtholly.tres"
	if not ResourceLoader.exists(skin_path):
		skin_path = "res://data/skins/chtholly.tres"
	_visual.set_skin(load(skin_path) as SkinData)
	_visual.set_facing(Vector3(0, 0, 1))


func _make_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 14)
	layer.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)
	_heading = Label.new()
	_heading.add_theme_font_size_override("font_size", 25)
	_heading.add_theme_color_override("font_outline_color", Color("3d324b"))
	_heading.add_theme_constant_override("outline_size", 5)
	column.add_child(_heading)
	_zone_row = HBoxContainer.new()
	_zone_row.add_theme_constant_override("separation", 8)
	column.add_child(_zone_row)
	_zone_picker = OptionButton.new()
	_zone_picker.item_selected.connect(select_zone)
	column.add_child(_zone_picker)
	for index: int in range(ZONES.size()):
		var button := Button.new()
		button.text = "%d · %s" % [index + 1, ZONES[index]]
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(select_zone.bind(index))
		_zone_row.add_child(button)
		_buttons.append(button)
		_zone_picker.add_item(ZONES[index])
	get_viewport().size_changed.connect(_resize_hud)
	_resize_hud()
	_prompt = Label.new()
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_prompt.offset_left = 22
	_prompt.offset_top = -63
	_prompt.add_theme_constant_override("outline_size", 4)
	_prompt.add_theme_color_override("font_outline_color", Color("3d324b"))
	layer.add_child(_prompt)
	var controls := Label.new()
	_controls = controls
	controls.text = (
		"Flèches / ZQSD / WASD : marcher    Maj : courir    "
		+ "X : épée    C : charge    E : parler    Échap : menu"
	)
	controls.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	controls.offset_left = 22
	controls.offset_top = -35
	controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls.add_theme_constant_override("outline_size", 4)
	controls.add_theme_color_override("font_outline_color", Color("3d324b"))
	layer.add_child(controls)
	_resize_hud()


func _resize_hud() -> void:
	var compact := get_viewport().get_visible_rect().size.x < 1000
	_zone_row.visible = not compact
	_zone_picker.visible = compact
	_heading.add_theme_font_size_override("font_size", 20 if compact else 25)
	if _controls != null:
		_controls.offset_top = -64 if compact else -35
		_prompt.offset_top = -92 if compact else -63


func select_zone(index: int) -> void:
	_zone_index = clampi(index, 0, 4)
	_npcs.clear()
	_nearby = null
	_talking = null
	_talk_time = 0.0
	if _zone != null:
		remove_child(_zone)
		_zone.queue_free()
	_zone = Node3D.new()
	_zone.name = "Landscape"
	add_child(_zone)
	_zone.position = CENTERS[_zone_index]
	_heading.text = "Île n° 68 — " + ZONES[_zone_index]
	_zone_picker.select(_zone_index)
	for button_index: int in range(_buttons.size()):
		_buttons[button_index].disabled = button_index == _zone_index
	_clouds()
	match _zone_index:
		0:
			_courtyard()
		1:
			_forest()
		2:
			_sunset()
		3:
			_port()
		4:
			_hill()
	_hero.position = CENTERS[_zone_index] + Vector3(0, 0, 6)
	_camera.position = CENTERS[_zone_index] + Vector3(0, 25, 35)
	_camera.look_at(CENTERS[_zone_index] + Vector3(0, 0, -2))
	_combat_time = 0.0


func _physics_process(delta: float) -> void:
	_combat_time = maxf(0.0, _combat_time - delta)
	_talk_time = maxf(0.0, _talk_time - delta)
	if _talking != null and _talk_time <= 0.0:
		_talking.play(&"repos")
		_talking = null
	var movement := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if Input.is_physical_key_pressed(KEY_Q):
		movement.x = -1
	if Input.is_physical_key_pressed(KEY_Z):
		movement.y = -1
	movement = movement.limit_length()
	var running := Input.is_action_pressed("run")
	var speed := 6.0 if running else 3.4
	_hero.velocity = Vector3(movement.x, 0, movement.y) * speed
	_hero.move_and_slide()
	var center := CENTERS[_zone_index]
	_hero.position.x = clampf(_hero.position.x, center.x - 18, center.x + 18)
	_hero.position.z = clampf(_hero.position.z, center.z - 12, center.z + 13)
	if movement.length_squared() > 0.001:
		_visual.set_facing(_hero.velocity)
	if _combat_time <= 0.0:
		_visual.play(
			(
				&"course"
				if running and movement != Vector2.ZERO
				else (&"marche" if movement != Vector2.ZERO else &"repos")
			)
		)
	_update_nearby()


func _update_nearby() -> void:
	_nearby = null
	var nearest_distance := 2.4
	for npc: CharacterVisual in _npcs:
		var distance := npc.global_position.distance_to(_hero.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			_nearby = npc
	_prompt.text = "E · Parler avec " + str(_nearby.name) if _nearby != null else ""


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	if key.keycode >= KEY_1 and key.keycode <= KEY_5:
		select_zone(key.keycode - KEY_1)
	elif key.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://src/main.tscn")
	elif key.physical_keycode == KEY_X:
		_visual.play(&"attaque", true)
		_combat_time = 0.5
	elif key.physical_keycode == KEY_C:
		_visual.play(&"charge", true)
		_combat_time = 0.5
	elif key.physical_keycode == KEY_E and _nearby != null:
		if _talking != null:
			_talking.play(&"repos")
		_talking = _nearby
		_talking.set_facing(_hero.global_position - _talking.global_position)
		_talking.play(&"parle", true)
		_talk_time = 2.0


func _texture(path: String) -> Texture2D:
	var resource_path := "res://assets/hd2d/" + path + ".png"
	if ResourceLoader.exists(resource_path):
		return load(resource_path) as Texture2D
	if not _missing.has(path):
		_missing[path] = true
		push_warning("Panneau HD-2D absent : " + resource_path)
	return null


func _surface(path: String, size: Vector2, position_3d: Vector3, tile_m: float = 4.0) -> void:
	var texture := _texture(path)
	if texture == null:
		return
	var mesh := PlaneMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.uv1_scale = Vector3(size.x / tile_m, size.y / tile_m, 1)
	material.roughness = 1.0
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position_3d
	_zone.add_child(instance)


func _panel(
	path: String,
	x: float,
	z: float,
	solid_size: Vector2 = Vector2.ZERO,
	density: float = 96.0,
	y: float = 0.0
) -> void:
	var texture := _texture(path)
	if texture == null:
		return
	var sprite := Sprite3D.new()
	sprite.texture = texture
	sprite.pixel_size = 1.0 / density
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold = 0.5
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.offset = Vector2(0, texture.get_height() * 0.5)
	sprite.position = Vector3(x, y, z)
	sprite.shaded = true
	_zone.add_child(sprite)
	if solid_size != Vector2.ZERO:
		_obstacle(Vector3(x, 0, z), solid_size)


func _obstacle(position_3d: Vector3, size: Vector2) -> void:
	var body := StaticBody3D.new()
	body.position = position_3d + Vector3(0, 1, 0)
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, 2, size.y)
	collision.shape = box
	body.add_child(collision)
	_zone.add_child(body)


func _npc(id: String, character_name: String, x: float, z: float) -> void:
	var path := "res://data/visuals2d/characters/%s/%s.tres" % [id, id]
	if not ResourceLoader.exists(path):
		path = "res://data/visuals2d/generated/characters/%s/%s.tres" % [id, id]
	if not ResourceLoader.exists(path):
		return
	var skin := load(path) as SkinData
	if skin == null or skin.sprite_sheet == null:
		return
	var visual := VISUAL_SCENE.instantiate() as CharacterVisual
	visual.name = character_name
	visual.position = Vector3(x, 0, z)
	_zone.add_child(visual)
	visual.set_skin(skin)
	visual.set_facing(Vector3(0, 0, 1))
	visual.play(&"repos")
	_npcs.append(visual)
	_obstacle(Vector3(x, 0, z), Vector2(0.5, 0.5))
	var label := Label3D.new()
	label.text = character_name
	label.font_size = 26
	label.pixel_size = 0.018
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("ffe6a6")
	label.outline_modulate = Color("654d3c")
	label.position.y = skin.height_m + 0.3
	visual.add_child(label)


func _building(
	name_id: String,
	position_3d: Vector3,
	size: Vector3,
	wall: String = "wall_planks",
	roof: String = "roof_slate"
) -> void:
	_panel("buildings/" + name_id, position_3d.x, position_3d.z + size.z * 0.5 + 0.025)
	_obstacle(position_3d, Vector2(size.x, size.z))
	var wall_texture := _texture("buildings/materials/" + wall)
	var roof_texture := _texture("buildings/materials/" + roof)
	if wall_texture == null or roof_texture == null:
		return
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_texture = wall_texture
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.uv1_scale = Vector3(size.x / 2.0, size.y / 2.0, 1)
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position_3d + Vector3(0, size.y * 0.5, 0)
	_zone.add_child(instance)
	var rise := 2.0
	if name_id == "warehouse_main":
		rise = 2.5
	elif name_id == "warehouse_wing":
		rise = 3.0
	elif name_id == "projection_hall":
		rise = 1.5
	_roof(roof_texture, position_3d, size, rise)


func _roof(texture: Texture2D, position_3d: Vector3, size: Vector3, rise: float) -> void:
	var half_depth := (size.z + 0.4) * 0.5
	var length := sqrt(half_depth * half_depth + rise * rise)
	for sign_value: float in [-1.0, 1.0]:
		var mesh := PlaneMesh.new()
		mesh.size = Vector2(size.x + 0.4, length)
		var material := StandardMaterial3D.new()
		material.albedo_texture = texture
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		material.uv1_scale = Vector3(size.x / 2.0, length / 2.0, 1)
		mesh.material = material
		var instance := MeshInstance3D.new()
		instance.mesh = mesh
		instance.rotation.x = atan2(rise, half_depth) * sign_value
		instance.position = (
			position_3d + Vector3(0, size.y + rise * 0.5, half_depth * 0.5 * sign_value)
		)
		_zone.add_child(instance)


func _clouds() -> void:
	_surface("sky/cloud_sea", Vector2(180, 140), Vector3(0, -8, 0), 1024.0 / 48.0)
	_panel("sky/distant_island_a", -38, -44, Vector2.ZERO, 48, -3)
	_panel("sky/distant_island_b", 39, -43, Vector2.ZERO, 48, -5)


func _ground(texture: String = "grass") -> void:
	_surface("ground/" + texture, Vector2(42, 32), Vector3.ZERO)
	_island_edges()
	_surface("ground/path_dirt", Vector2(5, 30), Vector3(0, 0.015, 0))
	_surface("ground/path_dirt", Vector2(40, 3), Vector3(0, 0.017, 4))


func _island_edges() -> void:
	var texture := _texture("cliff/cliff")
	if texture == null:
		return
	for index: int in range(4):
		var width := 42.0 if index < 2 else 32.0
		var mesh := QuadMesh.new()
		mesh.size = Vector2(width, 4)
		var material := StandardMaterial3D.new()
		material.albedo_texture = texture
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.uv1_scale = Vector3(width / 4.0, 1, 1)
		mesh.material = material
		var instance := MeshInstance3D.new()
		instance.mesh = mesh
		if index < 2:
			instance.position = Vector3(0, -2, 16 if index == 0 else -16)
		else:
			instance.position = Vector3(-21 if index == 2 else 21, -2, 0)
			instance.rotation.y = PI * 0.5
		_zone.add_child(instance)


func _tree_line() -> void:
	for index: int in range(9):
		_panel(
			"props/tree_autumn" if index % 2 == 0 else "props/tree_autumn_rust",
			-18.0 + index * 4.5,
			-11.0,
			Vector2(0.7, 0.7)
		)
	for x: float in [-17.0, 17.0]:
		_panel("props/tree_autumn_yellow", x, 9, Vector2(0.7, 0.7))
		_panel("props/bush", x - 2, 11, Vector2(0.8, 0.6))


func _courtyard() -> void:
	_ground()
	_tree_line()
	_building("warehouse_main", Vector3(-6, 0, -7), Vector3(16, 6.5, 6))
	_building("warehouse_wing", Vector3(-11, 0, -2), Vector3(6, 3.5, 5))
	_panel("buildings/warehouse_porch", -6, -3.8, Vector2(5, 1))
	_panel("buildings/armory_door", -11, 2, Vector2(2.2, 1.5))
	_panel("props/well", 0, 0, Vector2(1.3, 1.3))
	_panel("props/climbing_tree", 11, -2, Vector2(1, 1))
	_panel("buildings/tool_shed", 12, 5, Vector2(2.8, 2))
	_panel("props/laundry_line", 7, 9)
	_panel("props/vegetable_patch", 9, 5, Vector2(4.5, 1))
	_panel("props/ball", -5, 7)
	_panel("props/crate", -6, 8, Vector2(0.6, 0.6))
	for x: float in [-19.0, -17.0, -15.0, -13.0, -11.0, -9.0, 9.0, 11.0, 13.0, 15.0, 17.0, 19.0]:
		_panel("props/palisade", x, 12, Vector2(2, 0.35))
	_panel("props/palisade_gate", 0, 12)
	for x: float in [-3.0, 3.0]:
		_panel("props/crystal_lamp", x, 4)
	_npc("nygglatho", "Nygglatho", -6, -1.5)
	_npc("tiat", "Tiat", -4, 6)
	_npc("pannibal", "Pannibal", 9, 1)
	_npc("collon", "Collon", -3, 9)
	_npc("lakhesh", "Lakhesh", 2, 2)
	_npc("ithea", "Ithea", -8, 8)
	_npc("nephren", "Nephren", 9, 8)


func _forest() -> void:
	_ground("forest_floor")
	_surface("ground/water", Vector2(11, 7), Vector3(-9, 0.025, -4))
	_tree_line()
	for index: int in range(6):
		var x := -15.0 if index % 2 == 0 else 14.0
		_panel("props/tree_old_pine", x, -8.0 + index * 3, Vector2(0.8, 0.8))
		_panel("props/mushroom", x + 2, -5.0 + index * 3)
	_panel("props/log_bridge", -8, 0)
	_panel("props/reeds", -6, -2)
	_panel("props/reeds", -11, 0)
	_panel("props/bear_rock", 9, -6, Vector2(4, 2))
	_panel("props/stick_rack", 5, 1, Vector2(1, 0.5))
	_panel("props/play_goal", 7, 7)
	_panel("props/play_goal_red", -7, 7)
	_panel("props/berry_bush", 10, 9, Vector2(1, 0.6))
	_npc("lakhesh", "Lakhesh", 4, 6)


func _sunset() -> void:
	_ground("sand")
	_panel("props/watch_post_ruin", 7, -6, Vector2(5, 2))
	_panel("props/vigil_bell", -4, 2, Vector2(1, 0.8))
	_panel("props/signal_pillar", 10, -4, Vector2(0.6, 0.6))
	_panel("props/garde_pennant", 12, -4)
	_panel("props/wind_rock_a", -9, 5, Vector2(2.5, 1.4))
	_panel("props/wind_rock_b", 9, 7, Vector2(1.5, 1))
	_panel("props/fallen_lantern", 6, -1)
	for index: int in range(8):
		_panel("props/edge_parapet", -19, -10 + index * 3)
		_panel("props/grass_tuft", -12 + index * 3, 9)
	for index: int in range(12):
		var angle := index * TAU / 12
		_panel("props/ring_stone", cos(angle) * 5, sin(angle) * 4)


func _port() -> void:
	_ground("cobble")
	_surface("ground/metal", Vector2(42, 6), Vector3(0, 0.025, 11))
	_building("cafe", Vector3(-13, 0, -6), Vector3(7, 5.5, 5), "wall_plaster", "roof_tiles")
	_building("shop_bakery", Vector3(-6, 0, -6), Vector3(5, 4, 5), "wall_stone", "roof_tiles")
	_building("shop_bookshop", Vector3(0, 0, -6), Vector3(5, 4, 5), "wall_plaster", "roof_tiles")
	_building("projection_hall", Vector3(8, 0, -6), Vector3(7, 6, 5), "wall_stone")
	_panel("props/market_stall", -10, 1, Vector2(2, 1))
	_panel("props/market_stall_veg", -5, 1, Vector2(2, 1))
	_panel("props/snack_stall", 8, 1, Vector2(1.5, 1))
	_panel("props/signpost", 2, 4)
	_panel("props/cargo_crane", -13, 9, Vector2(2, 1.4))
	_panel("props/crates_barrels", -7, 10, Vector2(1.6, 1))
	_panel("props/gangway", 11, 11)
	_panel("props/airship_ferry", 16, 15, Vector2.ZERO, 48, -1)
	_panel("props/airship_barocupot", -17, 17, Vector2.ZERO, 48, -2)
	for index: int in range(10):
		_panel("props/edge_railing", -19 + index * 4, 13)
	_npc("limeskin", "Limeskin", -5, 5)
	_npc("willem", "Willem", -3, 2)
	_npc("cat_waiter", "Le serveur", -10, -1)
	_npc("ferryman", "Le passeur", 9, 7)


func _hill() -> void:
	_ground("grass_dry")
	_panel("props/lookout", 5, -5, Vector2(3, 3))
	_panel("props/lone_tree", -10, -4, Vector2(0.7, 0.7))
	_panel("props/bench", 2, -1, Vector2(1.4, 0.5))
	for index: int in range(26):
		var x := float((index * 7) % 35) - 17
		var z := float((index * 11) % 20) - 9
		if absf(x) > 3:
			_panel("props/myosotis", x, z)
			_panel("props/tall_grass", x + 1, z + 0.5)
	for index: int in range(9):
		_panel("props/edge_parapet", -18 + index * 4.5, -10)
