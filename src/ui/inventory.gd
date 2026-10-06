extends Control
## Inventaire (PLAN.md section 4) : grille d'icônes, nom, quantité et description de l'objet
## choisi. Propriétaire : L7. Instancié dans src/game.tscn sous UI/Inventory.
##
## Écran modal : open() met le jeu en pause (get_tree().paused = true), close() la lève ; la
## racine est en PROCESS_MODE_ALWAYS. L'action « inventory » (I / bouton Y) ouvre et ferme ;
## ouvert, « ui_cancel » (Échap), « pause » ou un clic hors du panneau le ferment aussi
## (événement consommé). Navigation : ui_* (flèches, croix, stick), survol de la souris, toucher.
## Manette (intégration M2, comme les écrans du L10 : src/ui/main_menu_input.gd) : Godot 4.7
## n'associe aucun bouton à ui_accept ni à ui_cancel ; B ferme et A presse le bouton qui a le
## focus, au relâchement d'un appui reçu ici (B est aussi la charge du joueur).
## Ne s'ouvre ni pendant un dialogue (dialogue_started → dialogue_ended) ni si le jeu est déjà
## en pause (menu pause, fin d'arène).
## Contenu mis à jour uniquement sur EventBus.inventory_changed, en relisant GameState
## (items() pour les quantités, stacks() pour les cases).

## L'inventaire vient de s'ouvrir / de se fermer.
signal opened
signal closed

const SLOT_SCENE := preload("res://src/ui/inventory_slot.tscn")
const UNKNOWN_ICON := preload("res://assets/items/unknown.png")
const MenuInput := preload("res://src/ui/main_menu_input.gd")
## Nombre minimal de cases affichées (cases vides comprises).
const MIN_SLOTS := 8

var _stacks: Array[Dictionary] = []
var _totals: Dictionary = {}
var _selected: int = -1
var _paused_by_me: bool = false
var _dialogue_running: bool = false
var _pad := MenuInput.new()

@onready var _dim: ColorRect = %Dim
@onready var _grid: GridContainer = %Grid
@onready var _close_button: Button = %CloseButton
@onready var _detail_icon: TextureRect = %DetailIcon
@onready var _detail_name: Label = %DetailName
@onready var _detail_quantity: Label = %DetailQuantity
@onready var _detail_description: Label = %DetailDescription


func _ready() -> void:
	EventBus.inventory_changed.connect(_refresh)
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_ended.connect(_on_dialogue_ended)
	_close_button.pressed.connect(close)
	_dim.gui_input.connect(_on_dim_gui_input)
	_refresh()


func _exit_tree() -> void:
	if _paused_by_me:
		get_tree().paused = false
		_paused_by_me = false


func is_open() -> bool:
	return visible


## Ouvre l'inventaire et met le jeu en pause (sans effet pendant un dialogue ou une pause).
func open() -> void:
	if visible or _dialogue_running or not is_inside_tree() or get_tree().paused:
		return
	visible = true
	get_tree().paused = true
	_paused_by_me = true
	_pad.reset()
	_focus_selection()
	opened.emit()


## Ferme l'inventaire et relance le jeu (s'il l'avait mis en pause).
func close() -> void:
	if not visible:
		return
	visible = false
	_pad.reset()
	if _paused_by_me:
		get_tree().paused = false
		_paused_by_me = false
	closed.emit()


func toggle() -> void:
	if visible:
		close()
	else:
		open()


## Cases affichées : [{"item_id": StringName, "quantity": int}, …] (copie).
func displayed_stacks() -> Array[Dictionary]:
	return _stacks.duplicate(true)


## Objet de la case choisie, &"" si aucune.
func selected_item() -> StringName:
	return _stacks[_selected]["item_id"] if _selected >= 0 and _selected < _stacks.size() else &""


func _input(event: InputEvent) -> void:
	if not visible:
		return
	for action: StringName in [&"inventory", &"ui_cancel", &"pause"]:
		if event.is_action_pressed(action):
			close()
			get_viewport().set_input_as_handled()
			return
	var command := _pad.read(event)
	match command:
		MenuInput.Command.ACCEPT:
			MenuInput.press_focused(self)
		MenuInput.Command.BACK:
			close()
	if command != MenuInput.Command.NONE:
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not visible and event.is_action_pressed(&"inventory"):
		open()
		if visible:
			get_viewport().set_input_as_handled()


func _refresh() -> void:
	var previous := selected_item()
	_totals = GameState.items()
	_stacks = GameState.stacks()
	var columns := _grid.columns
	var cell_count := maxi(MIN_SLOTS, ceili(float(_stacks.size()) / columns) * columns)
	while _grid.get_child_count() < cell_count:
		var slot := SLOT_SCENE.instantiate() as Button
		var index := _grid.get_child_count()
		slot.focus_entered.connect(_select.bind(index))
		slot.pressed.connect(_select.bind(index))
		slot.mouse_entered.connect(_on_slot_hovered.bind(index))
		_grid.add_child(slot)
	while _grid.get_child_count() > cell_count:
		var extra := _grid.get_child(_grid.get_child_count() - 1)
		_grid.remove_child(extra)
		extra.queue_free()
	for i in cell_count:
		_fill_slot(_grid.get_child(i) as Button, i)
	_selected = mini(_selected, _stacks.size() - 1)
	for i in _stacks.size():
		if _stacks[i]["item_id"] == previous:
			_selected = i
			break
	_show_details()
	if visible:
		_focus_selection()


func _fill_slot(slot: Button, index: int) -> void:
	var filled := index < _stacks.size()
	slot.disabled = not filled
	slot.focus_mode = Control.FOCUS_ALL if filled else Control.FOCUS_NONE
	var icon := slot.get_node(^"Icon") as TextureRect
	var count_label := slot.get_node(^"Count") as Label
	icon.texture = _icon_of(_stacks[index]["item_id"]) if filled else null
	var quantity: int = _stacks[index]["quantity"] if filled else 0
	count_label.text = str(quantity) if quantity > 1 else ""


func _select(index: int) -> void:
	if index < _stacks.size():
		_selected = index
		_show_details()


func _show_details() -> void:
	if _selected < 0:
		_detail_icon.texture = null
		_detail_name.text = "Sac vide" if _stacks.is_empty() else ""
		_detail_quantity.text = ""
		_detail_description.text = (
			"Les objets se ramassent en marchant dessus, ou avec E / A."
			if _stacks.is_empty()
			else ""
		)
		return
	var item_id: StringName = _stacks[_selected]["item_id"]
	var data := ItemData.find(item_id)
	_detail_icon.texture = _icon_of(item_id)
	_detail_name.text = ItemData.display_name_of(item_id)
	_detail_quantity.text = "Quantité : %d" % int(_totals.get(item_id, 0))
	_detail_description.text = data.description if data != null else ""


func _focus_selection() -> void:
	if _selected < 0 and not _stacks.is_empty():
		_selected = 0
	if _selected >= 0:
		(_grid.get_child(_selected) as Control).grab_focus()
	else:
		_close_button.grab_focus()
	_show_details()


func _icon_of(item_id: StringName) -> Texture2D:
	var data := ItemData.find(item_id)
	return data.icon if data != null and data.icon != null else UNKNOWN_ICON


func _on_slot_hovered(index: int) -> void:
	var slot := _grid.get_child(index) as Control
	if slot.focus_mode != Control.FOCUS_NONE:
		slot.grab_focus()


func _on_dim_gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		close()


func _on_dialogue_started(_npc_id: StringName) -> void:
	_dialogue_running = true
	close()


func _on_dialogue_ended(_npc_id: StringName) -> void:
	_dialogue_running = false
