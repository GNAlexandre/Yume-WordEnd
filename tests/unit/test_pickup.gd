extends GutTest
## Pickup (L7) : ramassage au contact du joueur ou par interact(), dans l'ordre
## GameState.add_item → mark_pickup_collected → EventBus.item_collected → queue_free ;
## objets persistants déjà pris absents (au _ready et sur game_loaded) ; objets lâchés par un
## ennemi (persistent = false) jamais mémorisés.

const PICKUP := preload("res://src/items/pickup.tscn")
const PLAYER_STUB := preload("res://tests/stubs/player_stub.tscn")
const DUMMY := preload("res://tests/stubs/dummy.tscn")
const FOREST := preload("res://src/items/placements/forest.tscn")

var _events: Array[String] = []


func before_each() -> void:
	GameState.reset()
	_events.clear()


func after_each() -> void:
	if EventBus.inventory_changed.is_connected(_on_inventory_changed):
		EventBus.inventory_changed.disconnect(_on_inventory_changed)
	if EventBus.item_collected.is_connected(_on_item_collected):
		EventBus.item_collected.disconnect(_on_item_collected)


func after_all() -> void:
	GameState.reset()


func _pickup(pickup_name: String, item_id: StringName, persistent: bool = true) -> Pickup:
	var pickup := PICKUP.instantiate() as Pickup
	pickup.name = pickup_name
	pickup.item_id = item_id
	pickup.persistent = persistent
	return add_child_autofree(pickup)


func _on_inventory_changed() -> void:
	_events.append(
		(
			"inventory_changed %d %s"
			% [GameState.count(&"page_fragment"), GameState.is_pickup_collected(&"forest_page_9")]
		)
	)


func _on_item_collected(item_id: StringName, quantity: int) -> void:
	_events.append(
		(
			"item_collected %s %d %s"
			% [item_id, quantity, GameState.is_pickup_collected(&"forest_page_9")]
		)
	)


func test_collect_order() -> void:
	var pickup := _pickup("forest_page_9", &"page_fragment")
	pickup.quantity = 2
	EventBus.inventory_changed.connect(_on_inventory_changed)
	EventBus.item_collected.connect(_on_item_collected)
	pickup.collect()
	assert_eq(
		_events,
		["inventory_changed 2 false", "item_collected page_fragment 2 true"] as Array[String],
		"add_item, puis mark_pickup_collected, puis item_collected"
	)
	assert_true(pickup.is_queued_for_deletion(), "puis queue_free")
	assert_eq(GameState.count(&"page_fragment"), 2)
	assert_true(GameState.is_pickup_collected(&"forest_page_9"))


func test_collect_only_once() -> void:
	var pickup := _pickup("beach_shell_9", &"shell")
	watch_signals(EventBus)
	pickup.collect()
	pickup.collect()
	pickup.interact(null)
	assert_signal_emit_count(EventBus, "item_collected", 1)
	assert_eq(GameState.count(&"shell"), 1)


func test_interact_collects() -> void:
	var player: Node3D = add_child_autofree(PLAYER_STUB.instantiate())
	player.position = Vector3(20, 0, 0)
	var pickup := _pickup("hill_flower_9", &"flower_blue")
	assert_true(pickup.is_in_group(&"interactable"))
	assert_eq(pickup.get_prompt(), "Ramasser")
	watch_signals(EventBus)
	pickup.interact(player)
	assert_signal_emitted_with_parameters(EventBus, "item_collected", [&"flower_blue", 1])
	assert_eq(GameState.count(&"flower_blue"), 1)
	assert_true(pickup.is_queued_for_deletion())


func test_player_contact_collects_and_others_do_not() -> void:
	var pickup := _pickup("hill_flower_9", &"flower_blue")
	var dummy: Node3D = add_child_autofree(DUMMY.instantiate())
	dummy.position = Vector3(0.2, 0, 0)
	await wait_physics_frames(4)
	assert_eq(GameState.count(&"flower_blue"), 0, "un ennemi ne ramasse rien")
	var player := PLAYER_STUB.instantiate() as Node3D
	player.position = Vector3(-0.3, 0, 0)
	add_child_autofree(player)
	await wait_physics_frames(4)
	assert_eq(GameState.count(&"flower_blue"), 1, "ramassé au contact du joueur")
	assert_true(not is_instance_valid(pickup) or pickup.is_queued_for_deletion())


func test_dropped_pickup_is_not_remembered() -> void:
	var pickup := _pickup("Pickup", &"page_fragment", false)
	pickup.collect()
	assert_eq(GameState.count(&"page_fragment"), 1)
	assert_false(GameState.is_pickup_collected(&"Pickup"))
	assert_eq(GameState.to_dict()["collected_pickups"], [], "rien dans la sauvegarde")
	var again := _pickup("Pickup", &"page_fragment", false)
	await wait_process_frames(1)
	assert_false(again.is_queued_for_deletion(), "un objet lâché réapparaît toujours")


func test_collected_persistent_pickup_does_not_come_back() -> void:
	GameState.mark_pickup_collected(&"forest_page_2")
	var forest: Node3D = add_child_autofree(FOREST.instantiate())
	await wait_process_frames(1)
	assert_null(forest.get_node_or_null(^"forest_page_2"), "déjà pris : absent")
	assert_not_null(forest.get_node_or_null(^"forest_page_1"))
	assert_not_null(forest.get_node_or_null(^"forest_page_3"))


func test_game_loaded_removes_collected_pickups() -> void:
	var forest: Node3D = add_child_autofree(FOREST.instantiate())
	await wait_process_frames(1)
	GameState.from_dict({"collected_pickups": ["forest_page_1", "forest_page_3"]})
	EventBus.game_loaded.emit()
	await wait_process_frames(1)
	assert_null(forest.get_node_or_null(^"forest_page_1"))
	assert_not_null(forest.get_node_or_null(^"forest_page_2"))
	assert_null(forest.get_node_or_null(^"forest_page_3"))


func test_visual_uses_item_icon_and_floats() -> void:
	var pickup := _pickup("beach_gear_9", &"clock_gear")
	var icon := pickup.get_node(^"Mesh/Icon") as Sprite3D
	var mesh := pickup.get_node(^"Mesh") as MeshInstance3D
	assert_eq(icon.texture, ItemData.find(&"clock_gear").icon)
	assert_eq(icon.billboard, BaseMaterial3D.BILLBOARD_ENABLED)
	var heights: Array[float] = []
	for i in 4:
		await wait_process_frames(5)
		heights.append(mesh.position.y)
	assert_gt(heights.max() - heights.min(), 0.001, "le halo et l'icône flottent")
	pickup.item_id = &"mystery_box"
	assert_eq(icon.texture, Pickup.UNKNOWN_ICON, "objet inconnu : icône de remplacement")
