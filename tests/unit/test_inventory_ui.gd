extends GutTest
## Inventaire (L7) : contenu relu dans GameState seulement sur EventBus.inventory_changed,
## cases et piles, détail de l'objet choisi, navigation, écran modal (pause) et fermeture.
## Pendant une pause, n'attendre que des images (wait_process_frames), jamais des secondes.

const INVENTORY := preload("res://src/ui/inventory.tscn")
const InventoryScript := preload("res://src/ui/inventory.gd")


func before_each() -> void:
	GameState.reset()
	get_tree().paused = false


func after_each() -> void:
	get_tree().paused = false


func after_all() -> void:
	GameState.reset()


func _make() -> Control:
	return add_child_autofree(INVENTORY.instantiate())


func _press(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	get_viewport().push_input(event)


func _label(inventory: Control, unique_name: String) -> Label:
	return inventory.get_node("%" + unique_name) as Label


func test_starts_closed_with_game_state_content() -> void:
	GameState.add_item(&"page_fragment", 3)
	var inventory := _make()
	assert_false(inventory.visible, "fermé au départ")
	assert_eq(inventory.process_mode, Node.PROCESS_MODE_ALWAYS)
	assert_eq(inventory.call(&"displayed_stacks"), [{"item_id": &"page_fragment", "quantity": 3}])


func test_updates_only_on_inventory_changed() -> void:
	var inventory := _make()
	EventBus.set_block_signals(true)
	GameState.add_item(&"shell", 2)
	EventBus.set_block_signals(false)
	assert_eq(
		inventory.call(&"displayed_stacks"), [], "GameState changé sans signal : rien ne bouge"
	)
	EventBus.inventory_changed.emit()
	assert_eq(inventory.call(&"displayed_stacks"), [{"item_id": &"shell", "quantity": 2}])
	GameState.add_item(&"bookmark", 2)
	assert_eq(inventory.call(&"displayed_stacks").size(), 3, "deux marque-pages : deux cases")


func test_grid_shows_icons_counts_and_empty_slots() -> void:
	GameState.add_item(&"page_fragment", 3)
	GameState.add_item(&"bookmark")
	var inventory := _make()
	var grid := inventory.get_node(^"%Grid") as GridContainer
	assert_eq(grid.get_child_count(), InventoryScript.MIN_SLOTS, "cases vides comprises")
	var first := grid.get_child(0) as Button
	assert_eq((first.get_node(^"Icon") as TextureRect).texture, ItemData.find(&"bookmark").icon)
	assert_eq((first.get_node(^"Count") as Label).text, "", "un seul : pas de chiffre")
	assert_eq((grid.get_child(1).get_node(^"Count") as Label).text, "3")
	assert_true((grid.get_child(2) as Button).disabled, "case vide")
	GameState.add_item(&"page_fragment", 400)
	assert_eq(grid.get_child_count(), 8, "403 fragments : 5 piles + 1 marque-page = 6 cases")
	GameState.add_item(&"shell", 300)
	assert_eq(grid.get_child_count(), 12, "la grille s'allonge d'une rangée")


func test_open_pauses_and_close_resumes() -> void:
	var inventory := _make()
	watch_signals(inventory)
	inventory.call(&"open")
	assert_true(inventory.visible)
	assert_true(get_tree().paused, "jeu en pause pendant l'inventaire")
	await wait_process_frames(2)
	assert_true(inventory.can_process(), "l'inventaire réagit pendant la pause")
	inventory.call(&"close")
	assert_false(inventory.visible)
	assert_false(get_tree().paused, "le jeu repart à la fermeture")
	assert_signal_emitted(inventory, "opened")
	assert_signal_emitted(inventory, "closed")


func test_actions_open_and_close() -> void:
	var inventory := _make()
	_press(&"inventory")
	assert_true(inventory.visible, "I / Y ouvre")
	assert_true(get_tree().paused)
	_press(&"inventory")
	assert_false(inventory.visible, "I / Y ferme")
	_press(&"inventory")
	_press(&"ui_cancel")
	assert_false(inventory.visible, "Échap / B ferme")
	_press(&"inventory")
	_press(&"pause")
	assert_false(inventory.visible, "Start ferme aussi")
	assert_false(get_tree().paused)


func test_does_not_open_over_a_pause_or_during_a_dialogue() -> void:
	var inventory := _make()
	get_tree().paused = true
	inventory.call(&"open")
	assert_false(inventory.visible, "déjà en pause (menu, fin d'arène) : reste fermé")
	assert_true(get_tree().paused, "la pause d'un autre écran est laissée telle quelle")
	get_tree().paused = false
	EventBus.dialogue_started.emit(&"librarian")
	inventory.call(&"open")
	assert_false(inventory.visible, "pas pendant un dialogue")
	EventBus.dialogue_ended.emit(&"librarian")
	inventory.call(&"open")
	assert_true(inventory.visible)


func test_freeing_an_open_inventory_resumes_the_game() -> void:
	var inventory := INVENTORY.instantiate() as Control
	add_child(inventory)
	inventory.call(&"open")
	assert_true(get_tree().paused)
	inventory.free()
	assert_false(get_tree().paused)


func test_selection_details_and_navigation() -> void:
	GameState.add_item(&"flower_blue", 2)
	GameState.add_item(&"shell")
	var inventory := _make()
	inventory.call(&"open")
	await wait_process_frames(2)
	assert_eq(inventory.call(&"selected_item"), &"flower_blue", "première case à l'ouverture")
	assert_eq(_label(inventory, "DetailName").text, "Fleur bleue")
	assert_eq(_label(inventory, "DetailQuantity").text, "Quantité : 2")
	assert_eq(
		_label(inventory, "DetailDescription").text, ItemData.find(&"flower_blue").description
	)
	_press(&"ui_right")
	await wait_process_frames(1)
	assert_eq(inventory.call(&"selected_item"), &"shell", "flèche droite : case suivante")
	assert_eq(_label(inventory, "DetailName").text, "Coquillage")
	var grid := inventory.get_node(^"%Grid") as GridContainer
	(grid.get_child(0) as Button).mouse_entered.emit()
	assert_eq(inventory.call(&"selected_item"), &"flower_blue", "survol de la souris")
	(grid.get_child(5) as Button).mouse_entered.emit()
	assert_eq(inventory.call(&"selected_item"), &"flower_blue", "une case vide ne se choisit pas")


func test_empty_inventory_and_mouse_closing() -> void:
	var inventory := _make()
	inventory.call(&"open")
	assert_eq(_label(inventory, "DetailName").text, "Sac vide")
	var close_button := inventory.get_node(^"%CloseButton") as Button
	assert_true(close_button.has_focus(), "sac vide : le bouton Fermer a le focus")
	close_button.pressed.emit()
	assert_false(inventory.visible, "bouton Fermer")
	inventory.call(&"open")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	(inventory.get_node(^"%Dim") as Control).gui_input.emit(click)
	assert_false(inventory.visible, "clic hors du panneau")
	assert_false(get_tree().paused)
