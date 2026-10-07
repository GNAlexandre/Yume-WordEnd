extends GutTest
## Données du Lot 7 : objets (data/items, icônes), quête des pages (data/quests/pages.tres) et
## objets uniques des fichiers d'emplacement (src/items/placements/<zone>.tscn).

## item_id → [nom affiché, empilable].
const ITEMS := {
	"page_fragment": ["Fragment de page", true],
	"bookmark": ["Marque-page porte-bonheur", false],
	"shell": ["Coquillage", true],
	"flower_blue": ["Fleur bleue", true],
}
## zone → [objet attendu, nombre minimal, nombre maximal].
const PLACEMENTS := {
	"village": ["flower_blue", 1, 2],
	"dunes": ["", 0, 0],
	"forest": ["page_fragment", 3, 3],
	"beach": ["shell", 2, 2],
	"hill": ["flower_blue", 1, 2],
}


func test_items_have_data_and_icons() -> void:
	for item_id: String in ITEMS:
		var data := ItemData.find(StringName(item_id))
		assert_not_null(data, "data/items/%s.tres" % item_id)
		if data == null:
			continue
		assert_eq(data.id, StringName(item_id), "id = nom du fichier")
		assert_eq(data.display_name, ITEMS[item_id][0])
		assert_eq(data.stackable, ITEMS[item_id][1], "%s : empilable" % item_id)
		assert_false(data.description.is_empty(), "%s : description" % item_id)
		assert_not_null(data.icon, "%s : icône" % item_id)
		if data.icon != null:
			assert_eq(data.icon.get_size(), Vector2(64, 64), "%s : icône 64 × 64" % item_id)


func test_every_item_file_is_named_after_its_id() -> void:
	for file: String in DirAccess.get_files_at(ItemData.DATA_DIR):
		if file.ends_with(".tres"):
			var data := load(ItemData.DATA_DIR.path_join(file)) as ItemData
			assert_not_null(data, file)
			if data != null:
				assert_eq(String(data.id), file.get_basename(), file)


func test_find_rejects_unknown_and_invalid_ids() -> void:
	assert_null(ItemData.find(&"mystery_box"))
	assert_null(ItemData.find(&"../quests/pages"))
	assert_null(ItemData.find(&""))
	assert_eq(ItemData.display_name_of(&"mystery_box"), "mystery_box")
	assert_eq(ItemData.display_name_of(&"shell"), "Coquillage")


func test_stack_sizes() -> void:
	var data := ItemData.new()
	assert_eq(data.stack_sizes(120), [99, 21] as Array[int])
	assert_eq(data.stack_sizes(0), [] as Array[int])
	data.stackable = false
	assert_eq(data.stack_sizes(3), [1, 1, 1] as Array[int], "non empilable : une case chacun")
	data.stackable = true
	data.max_stack = 0
	assert_eq(data.stack_sizes(2), [1, 1] as Array[int], "max_stack invalide : une case chacun")


func test_pages_quest_data() -> void:
	# Lot Q : pages.json, les 5 fragments à rapporter sont son étape collect « rapporter à ».
	var quest := QuestData.find(&"pages")
	assert_not_null(quest, "data/quests/pages.json")
	if quest == null:
		return
	assert_eq(quest.id, &"pages")
	assert_eq(quest.title, "Les pages envolées")
	assert_eq(quest.objective, "Rapporter 5 fragments de page à la bibliothécaire")
	assert_eq(quest.giver_npc, &"librarian")
	assert_eq(QuestTracker.missing_items(quest), {&"page_fragment": 5}, "5 fragments requis")
	assert_eq(quest.steps[0].npc, &"librarian", "à rapporter à la bibliothécaire")
	assert_true(quest.steps[0].consume, "retirés à la fin")
	assert_eq(quest.required_flags, [] as Array[StringName])
	assert_eq(quest.reward_items, {&"bookmark": 1})
	assert_eq(quest.reward_max_hp, 6, "PV max de la récompense : une donnée")
	assert_null(QuestData.find(&"unknown_quest"))


func test_placements_hold_unique_pickups_on_the_ground() -> void:
	var seen := {}
	for zone: String in PLACEMENTS:
		var expected: Array = PLACEMENTS[zone]
		var path := "res://src/items/placements/%s.tscn" % zone
		var root: Node = autofree((load(path) as PackedScene).instantiate())
		assert_eq(String(root.name), "Pickups", path)
		var count := 0
		for child: Node in root.get_children():
			var pickup := child as Pickup
			assert_not_null(pickup, "%s : %s est un Pickup" % [path, child.name])
			if pickup == null:
				continue
			count += 1
			assert_eq(pickup.item_id, StringName(expected[0]), "%s : objet" % child.name)
			assert_true(pickup.persistent, "%s : persistant" % child.name)
			assert_true(String(child.name).begins_with(zone + "_"), "nommé <zone>_<objet>_<n>")
			assert_false(seen.has(child.name), "%s : pickup_id unique sur l'île" % child.name)
			seen[child.name] = true
			assert_almost_eq(pickup.position.y, 0.0, 0.01, "%s : posé au sol" % child.name)
		assert_between(count, int(expected[1]), int(expected[2]), "%s : nombre d'objets" % zone)
	for n in 3:
		assert_true(seen.has(StringName("forest_page_%d" % (n + 1))), "forest_page_%d" % (n + 1))
