extends GutTest
## Objets (ItemData, L7) : chaque fichier de data/items et des dossiers d'add_search_dir porte
## l'id de son nom, une icône 64 × 64 et une description courte ; find() refuse les ids inconnus
## ou invalides ; piles. (F1) Les objets de l'ancienne île (pages, myosotis, draps, engrenages…)
## sont partis avec elle ; les tests utilisent les objets de tests/data/items.

const TEST_DIR := "res://tests/data/items"
## item_id → [nom affiché, empilable] (tests/data/items).
const TEST_ITEMS := {
	"test_page": ["Page d’essai", true],
	"test_picture": ["Image d’essai", false],
}
## Objets de l'ancienne île : plus de données ni d'icônes.
const REMOVED: Array[String] = [
	"page_fragment",
	"flower_blue",
	"laundry_sheet",
	"eggs",
	"wild_berries",
	"fresh_cream",
	"clock_gear",
	"clock_comb",
	"picture_book",
	"dessert_cup",
	"cheesecake_slice",
	"tiat_drawing",
	"rami_card",
	"pressed_forget_me_not",
	"butter_cake_promise",
	"shell",
	"bookmark",
]


func before_each() -> void:
	ItemData.add_search_dir(TEST_DIR)


func after_each() -> void:
	ItemData.remove_search_dir(TEST_DIR)


func test_test_items_are_found_through_the_search_dir() -> void:
	for item_id: String in TEST_ITEMS:
		var data := ItemData.find(StringName(item_id))
		assert_not_null(data, "tests/data/items/%s.tres" % item_id)
		if data == null:
			continue
		assert_eq(data.display_name, TEST_ITEMS[item_id][0])
		assert_eq(data.stackable, TEST_ITEMS[item_id][1], "%s : empilable" % item_id)
	ItemData.remove_search_dir(TEST_DIR)
	assert_null(ItemData.find(&"test_page"), "hors des tests : inconnu")
	ItemData.add_search_dir(TEST_DIR)
	ItemData.add_search_dir(TEST_DIR)
	ItemData.remove_search_dir(TEST_DIR)
	assert_null(ItemData.find(&"test_page"), "ajouté deux fois, retiré une fois : sans doublon")
	ItemData.add_search_dir(TEST_DIR)
	assert_not_null(ItemData.find(&"test_page"), "de nouveau trouvé")


func test_every_item_file_is_named_after_its_id_with_an_icon() -> void:
	for dir: String in [ItemData.DATA_DIR, TEST_DIR]:
		if not DirAccess.dir_exists_absolute(dir):
			continue
		for file: String in DirAccess.get_files_at(dir):
			if not file.ends_with(".tres"):
				continue
			var data := load(dir.path_join(file)) as ItemData
			assert_not_null(data, file)
			if data == null:
				continue
			assert_eq(String(data.id), file.get_basename(), "%s : id = nom du fichier" % file)
			assert_false(data.description.is_empty(), "%s : description" % file)
			assert_lte(data.description.length(), 160, "%s : description courte" % file)
			assert_not_null(data.icon, "%s : icône" % file)
			if data.icon != null:
				assert_eq(data.icon.get_size(), Vector2(64, 64), "%s : icône 64 × 64" % file)


func test_old_island_items_are_gone() -> void:
	for item_id: String in REMOVED:
		assert_null(ItemData.find(StringName(item_id)), "%s retiré" % item_id)
		assert_false(
			ResourceLoader.exists("res://assets/items/%s.png" % item_id), "icône %s" % item_id
		)
		assert_eq(ItemData.display_name_of(StringName(item_id)), item_id, "inconnu : son id")


func test_find_rejects_unknown_and_invalid_ids() -> void:
	assert_null(ItemData.find(&"mystery_box"))
	assert_null(ItemData.find(&"../quests/picture_book"))
	assert_null(ItemData.find(&""))
	assert_eq(ItemData.display_name_of(&"mystery_box"), "mystery_box")
	assert_eq(ItemData.display_name_of(&"test_page"), "Page d’essai")


func test_stack_sizes() -> void:
	var data := ItemData.new()
	assert_eq(data.stack_sizes(120), [99, 21] as Array[int])
	assert_eq(data.stack_sizes(0), [] as Array[int])
	data.stackable = false
	assert_eq(data.stack_sizes(3), [1, 1, 1] as Array[int], "non empilable : une case chacun")
	data.stackable = true
	data.max_stack = 0
	assert_eq(data.stack_sizes(2), [1, 1] as Array[int], "max_stack invalide : une case chacun")
