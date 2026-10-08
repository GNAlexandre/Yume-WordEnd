extends Control
## Atelier des planches entières ; aucune animation ou apparence du jeu n'est remplacée.

const CATALOG_PATH := "res://data/visuals2d/generated/catalog.json"
const VISUAL_SCENE := preload("res://src/visuals/character_visual.tscn")

var _entries: Array = []
var _filtered: Array = []
var _category := "all"
var _list: ItemList
var _texture: TextureRect
var _caption: Label
var _status: Label
var _characters: Array = []
var _animation_mode := false
var _animation_controls: HBoxContainer
var _animation_select: OptionButton
var _direction_select: OptionButton
var _viewport_panel: SubViewportContainer
var _visual: CharacterVisual
var _camera: Camera3D


func _ready() -> void:
	_build_interface()
	_load_catalog()
	_filter_entries()
	set_process(false)


func _process(_delta: float) -> void:
	_status.text = (
		"Brouillon animé — %s / %s / image %d — cycles et ancres à vérifier."
		% [_visual.current_animation(), _visual.current_direction(), _visual.current_frame()]
	)


func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = Color("202635")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)
	var title := Label.new()
	title.text = "Atelier 2D — personnages, décors et objets"
	title.add_theme_font_size_override("font_size", 26)
	content.add_child(title)
	var categories := OptionButton.new()
	categories.add_item("Toutes les planches")
	categories.add_item("Personnages")
	categories.add_item("Décors")
	categories.add_item("Objets et assets")
	categories.item_selected.connect(_select_category)
	content.add_child(categories)
	var mode := CheckButton.new()
	mode.text = "Tester les animations directionnelles"
	mode.toggled.connect(_set_animation_mode)
	content.add_child(mode)
	_animation_controls = HBoxContainer.new()
	_animation_controls.hide()
	content.add_child(_animation_controls)
	_animation_select = OptionButton.new()
	_animation_select.item_selected.connect(_select_animation)
	_animation_controls.add_child(_animation_select)
	_direction_select = OptionButton.new()
	for direction: String in ["Face", "Dos", "Côté droit", "Côté gauche"]:
		_direction_select.add_item(direction)
	_direction_select.item_selected.connect(_select_direction)
	_animation_controls.add_child(_direction_select)
	var replay := Button.new()
	replay.text = "Rejouer"
	replay.pressed.connect(func() -> void: _select_animation(_animation_select.selected))
	_animation_controls.add_child(replay)
	var main := HSplitContainer.new()
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(main)
	_list = ItemList.new()
	_list.custom_minimum_size = Vector2(250, 250)
	_list.item_selected.connect(_select_entry)
	main.add_child(_list)
	var preview := VBoxContainer.new()
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.add_child(preview)
	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview.add_child(panel)
	_texture = TextureRect.new()
	_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_texture.custom_minimum_size = Vector2(320, 250)
	panel.add_child(_texture)
	_build_animation_viewport(panel)
	_caption = Label.new()
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview.add_child(_caption)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.text = "Planches de revue : animations, ancres et découpes à valider."
	content.add_child(_status)


func _load_catalog() -> void:
	if not FileAccess.file_exists(CATALOG_PATH):
		_status.text = "Catalogue absent. Exécutez tools/sukasuka2d/make_resources.py."
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	if parsed is Dictionary and parsed.get("entries") is Array:
		_entries = parsed["entries"]
		_characters = parsed.get("characters", [])
	else:
		_status.text = "Le catalogue ne contient pas de liste de planches valide."


func _build_animation_viewport(parent: Node) -> void:
	_viewport_panel = SubViewportContainer.new()
	_viewport_panel.stretch = true
	_viewport_panel.custom_minimum_size = Vector2(320, 250)
	_viewport_panel.hide()
	parent.add_child(_viewport_panel)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(800, 600)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	_viewport_panel.add_child(viewport)
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = 2.5
	viewport.add_child(_camera)
	_camera.position = Vector3(4, 3.8, 6)
	_camera.look_at(Vector3(0, 0.75, 0))
	_visual = VISUAL_SCENE.instantiate() as CharacterVisual
	viewport.add_child(_visual)
	_visual.set_process(false)


func _set_animation_mode(enabled: bool) -> void:
	_animation_mode = enabled
	_animation_controls.visible = enabled
	_viewport_panel.visible = enabled
	_texture.visible = not enabled
	_visual.set_process(enabled)
	set_process(enabled)
	_filter_entries()


func _select_category(index: int) -> void:
	_category = ["all", "characters", "backgrounds", "props"][index]
	_filter_entries()


func _filter_entries() -> void:
	_filtered.clear()
	_list.clear()
	_texture.texture = null
	_caption.text = ""
	_visual.set_skin(null)
	for entry: Variant in _characters if _animation_mode else _entries:
		if not entry is Dictionary:
			continue
		var category := "characters" if _animation_mode else str(entry.get("category", ""))
		if _category != "all" and _category_group(category) != _category:
			continue
		_filtered.append(entry)
		_list.add_item(str(entry.get("name", entry.get("id", "Planche"))))
	if not _filtered.is_empty():
		_list.select(0)
		_select_entry(0)


func _category_group(category: String) -> String:
	if category in ["character", "characters", "npc", "hero", "heroes"]:
		return "characters"
	if (
		category
		in [
			"background",
			"backgrounds",
			"decor",
			"decors",
			"map",
			"maps",
			"environment",
			"environments"
		]
	):
		return "backgrounds"
	return "props"


func _select_entry(index: int) -> void:
	var entry: Dictionary = _filtered[index]
	if _animation_mode:
		_select_character(entry)
		return
	var path := str(entry.get("texture_path", ""))
	var loaded: Resource = load(path) if ResourceLoader.exists(path) else null
	_texture.texture = loaded as Texture2D
	var caption := "%s\n%s" % [entry.get("name", ""), entry.get("description", "")]
	var dimensions: Array = entry.get("dimensions", [])
	if dimensions.size() == 2:
		caption += "\n%d × %d px" % [dimensions[0], dimensions[1]]
	for limitation: Variant in entry.get("limitations", []):
		caption += "\n• " + str(limitation)
	_caption.text = caption
	if _texture.texture == null:
		_status.text = "Texture introuvable ou non importée : " + path
	else:
		_status.text = "Planche entière — les cellules sont des découpes de revue."


func _select_character(entry: Dictionary) -> void:
	var skin := load(str(entry["skin_path"])) as SkinData
	_visual.set_skin(skin)
	_animation_select.clear()
	for animation: String in SheetLoader.animations(SheetLoader.read_sheet(skin)):
		_animation_select.add_item(animation)
	if _animation_select.item_count > 0:
		_select_animation(0)
	_select_direction(_direction_select.selected)
	_caption.text = str(entry.get("name", ""))
	for limitation: Variant in entry.get("limitations", []):
		_caption.text += "\n• " + str(limitation)


func _select_animation(index: int) -> void:
	if index < 0:
		return
	_visual.play(StringName(_animation_select.get_item_text(index)), true)


func _select_direction(index: int) -> void:
	var right := _camera.global_basis.x
	var toward := _camera.global_basis.z
	toward.y = 0.0
	var directions := [toward, -toward, right, -right]
	_visual.set_facing(directions[index])
