extends GutTest
## Démo du Lot 7 (tests/integration/demo_l7.tscn) : inventaire ouvert au lancement avec des
## objets et jeu en pause ; une fois l'inventaire fermé, le joueur factice ramasse un objet au
## contact et l'inventaire l'affiche (EventBus.inventory_changed).

const DEMO := preload("res://tests/integration/demo_l7.tscn")


func before_each() -> void:
	GameState.reset()
	get_tree().paused = false


func after_each() -> void:
	get_tree().paused = false


func after_all() -> void:
	GameState.reset()


func test_demo_opens_the_inventory_with_items() -> void:
	var demo: Node3D = add_child_autofree(DEMO.instantiate())
	await wait_process_frames(2)
	var inventory := demo.get_node(^"UI/Inventory") as Control
	assert_true(inventory.visible, "inventaire ouvert")
	assert_true(get_tree().paused, "jeu en pause")
	assert_eq(inventory.call(&"displayed_stacks").size(), 4, "quatre objets différents")
	assert_eq(demo.get_node(^"Pickups").get_child_count(), 5, "cinq objets autour du joueur")


func test_walking_onto_a_pickup_fills_the_inventory() -> void:
	var demo: Node3D = add_child_autofree(DEMO.instantiate())
	var inventory := demo.get_node(^"UI/Inventory") as Control
	inventory.call(&"close")
	var flower := demo.get_node(^"Pickups/demo_flower_1") as Node3D
	(demo.get_node(^"Player") as Node3D).global_position = flower.global_position
	await wait_physics_frames(4)
	assert_eq(GameState.count(&"flower_blue"), 4, "3 au départ, 1 ramassée")
	assert_true(not is_instance_valid(flower) or flower.is_queued_for_deletion())
	var stacks: Array = inventory.call(&"displayed_stacks")
	assert_has(stacks, {"item_id": &"flower_blue", "quantity": 4})


func test_freeing_the_demo_resumes_the_game() -> void:
	var demo := DEMO.instantiate()
	add_child(demo)
	await wait_process_frames(1)
	assert_true(get_tree().paused)
	demo.free()
	assert_false(get_tree().paused)
