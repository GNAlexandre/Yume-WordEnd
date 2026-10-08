extends GutTest
## Objets de l'acte 1 (HISTOIRE.md section 6) : données (data/items), icônes 64 × 64, quête du
## livre d'images (data/quests/picture_book.json) et objets uniques des fichiers d'emplacement
## (src/items/placements/<zone>.tscn, HISTOIRE.md section 3.3). Le coquillage et le marque-page
## sont retirés.

## item_id → [nom affiché, empilable].
const ITEMS := {
	"page_fragment": ["Page du livre d’images", true],
	"flower_blue": ["Myosotis", true],
	"laundry_sheet": ["Drap envolé", true],
	"eggs": ["Œufs frais", true],
	"wild_berries": ["Baies sauvages", true],
	"fresh_cream": ["Crème fraîche", true],
	"clock_gear": ["Engrenage de laiton", true],
	"clock_comb": ["Peigne de carillon", true],
	"picture_book": ["Le livre d’images", false],
	"dessert_cup": ["Dessert spécial", true],
	"cheesecake_slice": ["Part de cheese-cake", true],
	"tiat_drawing": ["Dessin de Tiat", false],
	"rami_card": ["Carte de M. Rami", false],
	"pressed_forget_me_not": ["Myosotis séché", false],
	"butter_cake_promise": ["La promesse du gâteau au beurre", false],
}
## Objets retirés à l'acte 1 (données et icônes).
const REMOVED: Array[String] = ["shell", "bookmark"]
## zone → {objet : nombre de pickups} (HISTOIRE.md section 3.3).
const PLACEMENTS := {
	"village": {"flower_blue": 1},
	"forest":
	{"page_fragment": 5, "wild_berries": 3, "laundry_sheet": 1, "clock_comb": 1, "flower_blue": 1},
	"dunes": {"laundry_sheet": 1, "clock_gear": 2, "flower_blue": 1},
	"beach": {"laundry_sheet": 2, "clock_gear": 1},
	"hill": {"flower_blue": 3, "laundry_sheet": 1},
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
		assert_lte(data.description.length(), 160, "%s : description courte" % item_id)
		assert_not_null(data.icon, "%s : icône" % item_id)
		if data.icon != null:
			assert_eq(data.icon.get_size(), Vector2(64, 64), "%s : icône 64 × 64" % item_id)
			assert_eq(
				data.icon.resource_path, "res://assets/items/%s.png" % item_id, "assets/items"
			)


func test_removed_items_are_gone() -> void:
	for item_id: String in REMOVED:
		assert_null(ItemData.find(StringName(item_id)), "%s retiré" % item_id)
		assert_false(
			ResourceLoader.exists("res://assets/items/%s.png" % item_id), "icône %s" % item_id
		)
		assert_eq(ItemData.display_name_of(StringName(item_id)), item_id, "inconnu : son id")


func test_every_item_file_is_named_after_its_id() -> void:
	var count := 0
	for file: String in DirAccess.get_files_at(ItemData.DATA_DIR):
		if file.ends_with(".tres"):
			count += 1
			var data := load(ItemData.DATA_DIR.path_join(file)) as ItemData
			assert_not_null(data, file)
			if data != null:
				assert_eq(String(data.id), file.get_basename(), file)
				assert_true(ITEMS.has(file.get_basename()), "%s : objet de l'acte 1" % file)
	assert_eq(count, ITEMS.size(), "rien d'autre dans data/items")


func test_find_rejects_unknown_and_invalid_ids() -> void:
	assert_null(ItemData.find(&"mystery_box"))
	assert_null(ItemData.find(&"../quests/picture_book"))
	assert_null(ItemData.find(&""))
	assert_eq(ItemData.display_name_of(&"mystery_box"), "mystery_box")
	assert_eq(ItemData.display_name_of(&"flower_blue"), "Myosotis")


func test_stack_sizes() -> void:
	var data := ItemData.new()
	assert_eq(data.stack_sizes(120), [99, 21] as Array[int])
	assert_eq(data.stack_sizes(0), [] as Array[int])
	data.stackable = false
	assert_eq(data.stack_sizes(3), [1, 1, 1] as Array[int], "non empilable : une case chacun")
	data.stackable = true
	data.max_stack = 0
	assert_eq(data.stack_sizes(2), [1, 1] as Array[int], "max_stack invalide : une case chacun")


func test_picture_book_quest_data() -> void:
	# Le livre d'images remplace la quête des pages : 5 pages à rapporter à Nephren.
	assert_null(QuestData.find(&"pages"), "ancienne quête des pages retirée")
	var quest := QuestData.find(&"picture_book")
	assert_not_null(quest, "data/quests/picture_book.json")
	if quest == null:
		return
	assert_eq(quest.title, "Le livre d’images")
	assert_eq(quest.giver_npc, &"nephren")
	assert_eq(quest.prereq_flags, [&"met_willem"] as Array[StringName], "après Willem")
	assert_eq(QuestTracker.missing_items(quest), {&"page_fragment": 5}, "5 pages requises")
	assert_eq(quest.steps[0].npc, &"nephren", "à rapporter à Nephren")
	assert_true(quest.steps[0].consume, "retirées à la fin")
	assert_eq(quest.steps[1].npc, &"willem", "puis la lecture de Willem")
	assert_eq(quest.reward_items, {&"picture_book": 1})
	assert_eq(quest.reward_max_hp, 0)
	assert_null(QuestData.find(&"unknown_quest"))


func test_collected_items_are_all_placed() -> void:
	# Chaque étape collect d'objets ramassés dans le monde trouve assez de pickups sur l'île.
	var placed := {}
	for zone: String in PLACEMENTS:
		for item_id: String in PLACEMENTS[zone]:
			placed[item_id] = int(placed.get(item_id, 0)) + int(PLACEMENTS[zone][item_id])
	for quest: QuestData in QuestData.all():
		for step: QuestStep in quest.steps:
			if step.type != QuestStep.COLLECT or not placed.has(String(step.item)):
				continue
			assert_gte(placed[String(step.item)], step.count, "%s/%s" % [quest.id, step.id])
	assert_eq(placed["flower_blue"], 6, "6 myosotis : un de plus que le vase")


func test_placements_hold_unique_pickups_on_the_ground() -> void:
	var seen := {}
	for zone: String in PLACEMENTS:
		var expected: Dictionary = PLACEMENTS[zone]
		var path := "res://src/items/placements/%s.tscn" % zone
		var root: Node = autofree((load(path) as PackedScene).instantiate())
		assert_eq(String(root.name), "Pickups", path)
		var counts := {}
		for child: Node in root.get_children():
			var pickup := child as Pickup
			assert_not_null(pickup, "%s : %s est un Pickup" % [path, child.name])
			if pickup == null:
				continue
			var item_id := String(pickup.item_id)
			counts[item_id] = int(counts.get(item_id, 0)) + 1
			assert_true(ITEMS.has(item_id), "%s : objet connu" % child.name)
			assert_true(pickup.persistent, "%s : persistant" % child.name)
			assert_true(String(child.name).begins_with(zone + "_"), "nommé <zone>_<objet>_<n>")
			assert_false(seen.has(child.name), "%s : pickup_id unique sur l'île" % child.name)
			seen[child.name] = true
			# Au sol du relief (test_m1_world vérifie le sol réel) : jamais sous la zone.
			assert_between(pickup.position.y, 0.0, 10.0, "%s : hauteur du sol" % child.name)
		assert_eq(counts, expected, "%s : objets de HISTOIRE.md 3.3" % zone)
	for n in 5:
		assert_true(seen.has(StringName("forest_page_%d" % (n + 1))), "forest_page_%d" % (n + 1))
