extends GutTest
## Quêtes de l'acte 1 dans src/game.tscn : les cinq pages du livre d'images dans les bois,
## QuestTracker et UI/Inventory du jeu, récompense ; PV max d'une récompense (registre des
## veilles) jusqu'au Health du joueur (relais max_hp_changed de PlayerCombat).

const GAME_SCENE := preload("res://src/game.tscn")


func before_each() -> void:
	GameState.reset()
	get_tree().paused = false


func after_each() -> void:
	get_tree().paused = false


func after_all() -> void:
	GameState.reset()


func test_picture_book_quest_end_to_end() -> void:
	var game: Node3D = add_child_autofree(GAME_SCENE.instantiate())
	await wait_physics_frames(3)
	var player := game.get_node(^"Player") as Node3D
	var pages: Array[Pickup] = []
	for child: Node in game.get_node(^"World/ile_ancienne/Zones/forest/Pickups").get_children():
		if child is Pickup and (child as Pickup).item_id == &"page_fragment":
			pages.append(child as Pickup)
	assert_eq(pages.size(), 5, "cinq pages dans les bois")
	GameState.set_quest_state(&"picture_book", &"active")
	for pickup: Pickup in pages:
		pickup.interact(player)
	assert_eq(GameState.count(&"page_fragment"), 5, "cinq pages ramassées")
	var inventory := game.get_node(^"UI/Inventory") as Control
	assert_eq(inventory.call(&"displayed_stacks"), [{"item_id": &"page_fragment", "quantity": 5}])
	GameState.set_quest_state(&"picture_book", &"done")
	assert_eq(GameState.items(), {&"picture_book": 1}, "pages rendues, livre d'images reçu")
	assert_eq(inventory.call(&"displayed_stacks"), [{"item_id": &"picture_book", "quantity": 1}])
	for n in 5:
		assert_true(GameState.is_pickup_collected(StringName("forest_page_%d" % (n + 1))))
	GameState.set_quest_state(&"vigil_register", &"done")
	assert_eq(GameState.max_hp, 7)
	assert_eq((game.get_node(^"Player/Health") as Health).max_hp, 7, "7 PV max pour le joueur")
	inventory.call(&"open")
	assert_true(get_tree().paused, "inventaire du jeu modal")
	inventory.call(&"close")
	assert_false(get_tree().paused)
