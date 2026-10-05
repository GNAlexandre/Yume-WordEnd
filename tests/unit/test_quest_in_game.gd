extends GutTest
## Quête des pages dans src/game.tscn : fragments de la forêt, QuestTracker et UI/Inventory du
## jeu, récompense jusqu'au Health du joueur (relais max_hp_changed de PlayerCombat).

const GAME_SCENE := preload("res://src/game.tscn")


func before_each() -> void:
	GameState.reset()
	get_tree().paused = false


func after_each() -> void:
	get_tree().paused = false


func after_all() -> void:
	GameState.reset()


func test_pages_quest_end_to_end() -> void:
	var game: Node3D = add_child_autofree(GAME_SCENE.instantiate())
	await wait_physics_frames(3)
	var player := game.get_node(^"Player") as Node3D
	var forest_pickups := game.get_node(^"Island/Zones/forest/Pickups")
	assert_eq(forest_pickups.get_child_count(), 3, "trois fragments dans la forêt")
	GameState.set_quest_state(&"pages", &"active")
	for pickup: Node in forest_pickups.get_children():
		(pickup as Pickup).interact(player)
	GameState.add_item(&"page_fragment", 2)
	assert_eq(GameState.count(&"page_fragment"), 5, "3 ramassés + 2 lâchés par les Timeres")
	var inventory := game.get_node(^"UI/Inventory") as Control
	assert_eq(inventory.call(&"displayed_stacks"), [{"item_id": &"page_fragment", "quantity": 5}])
	GameState.set_quest_state(&"pages", &"done")
	assert_eq(GameState.items(), {&"bookmark": 1}, "pages rendues, marque-page reçu")
	assert_eq(GameState.max_hp, 6)
	assert_eq((game.get_node(^"Player/Health") as Health).max_hp, 6, "6 PV max pour le joueur")
	assert_eq(inventory.call(&"displayed_stacks"), [{"item_id": &"bookmark", "quantity": 1}])
	for n in 3:
		assert_true(GameState.is_pickup_collected(StringName("forest_page_%d" % (n + 1))))
	inventory.call(&"open")
	assert_true(get_tree().paused, "inventaire du jeu modal")
	inventory.call(&"close")
	assert_false(get_tree().paused)
