extends GutTest
## Acte 1, intégration : aucune étape « réunir » n'est impossible faute d'objets. Pour chaque
## quête du jeu (data/quests), chaque étape collect trouve assez d'exemplaires de son objet dans
## l'île (objets uniques des fichiers d'emplacement src/items/placements/<zone>.tscn,
## Pickup.quantity) ou chez un PNJ (effet give_item d'un dialogue de data/dialogues) ; et, toutes
## quêtes confondues, ce que les étapes consomment (consume) et ce que les dialogues reprennent
## (take_item) ne dépasse pas ce qu'offre l'île. Sinon, le joueur resterait bloqué à l'étape.

const ZONES: Array[String] = ["village", "forest", "dunes", "beach", "hill"]
const QUESTS_DIR := "res://data/quests"
const DIALOGUES_DIR := "res://data/dialogues"

## Objet → exemplaires posés dans l'île, puis donnés par les PNJ.
var _placed: Dictionary[StringName, int] = {}
var _given: Dictionary[StringName, int] = {}
var _taken: Dictionary[StringName, int] = {}


func before_all() -> void:
	for zone_id: String in ZONES:
		var packed := load("res://src/items/placements/%s.tscn" % zone_id) as PackedScene
		var root := packed.instantiate()
		for child: Node in root.get_children():
			var pickup := child as Pickup
			if pickup != null:
				_placed[pickup.item_id] = _placed.get(pickup.item_id, 0) + pickup.quantity
		root.free()
	for file_name: String in DirAccess.get_files_at(DIALOGUES_DIR):
		if not file_name.ends_with(".json"):
			continue
		var dialogue: Variant = JSON.parse_string(
			FileAccess.get_file_as_string(DIALOGUES_DIR.path_join(file_name))
		)
		if dialogue is Dictionary:
			for node: Variant in (dialogue as Dictionary).get("nodes", {}).values():
				_read_effects(node)
				for choice: Variant in (node as Dictionary).get("choices", []):
					_read_effects(choice)


## Quêtes du jeu (data/quests/*.json), lues telles quelles.
func _quests() -> Array[Dictionary]:
	var quests: Array[Dictionary] = []
	for file_name: String in DirAccess.get_files_at(QUESTS_DIR):
		if file_name.ends_with(".json"):
			var quest: Variant = JSON.parse_string(
				FileAccess.get_file_as_string(QUESTS_DIR.path_join(file_name))
			)
			if quest is Dictionary:
				quests.append(quest)
	return quests


func _read_effects(step: Variant) -> void:
	if not step is Dictionary:
		return
	for key: String in ["give_item", "take_item"]:
		if not (step as Dictionary).has(key):
			continue
		var amounts := _amounts((step as Dictionary)[key])
		var into: Dictionary[StringName, int] = _given if key == "give_item" else _taken
		for item_id: StringName in amounts:
			into[item_id] = into.get(item_id, 0) + amounts[item_id]


## "objet", ["objet", n] ou {"objet": n} → {objet: n} (formes des dialogues, docs/QUETES.md).
func _amounts(value: Variant) -> Dictionary[StringName, int]:
	var result: Dictionary[StringName, int] = {}
	if value is String:
		result[StringName(value)] = 1
	elif value is Array and (value as Array).size() == 2:
		result[StringName(str(value[0]))] = int(value[1])
	elif value is Dictionary:
		for item_id: Variant in value:
			result[StringName(str(item_id))] = int((value as Dictionary)[item_id])
	return result


func _supply(item_id: StringName) -> int:
	return _placed.get(item_id, 0) + _given.get(item_id, 0)


func test_the_island_holds_the_act1_items() -> void:
	assert_eq(_placed.get(&"page_fragment", 0), 5, "cinq pages du livre d'images")
	assert_eq(_placed.get(&"laundry_sheet", 0), 5, "cinq draps envolés")
	assert_eq(_placed.get(&"flower_blue", 0), 6, "six myosotis")
	assert_eq(_placed.get(&"clock_gear", 0), 3, "trois engrenages")
	assert_eq(_placed.get(&"clock_comb", 0), 1, "un peigne de carillon")
	assert_eq(_placed.get(&"wild_berries", 0), 3, "trois grappes de baies")
	assert_eq(_given.get(&"eggs", 0), 1, "les œufs de la marchande")
	assert_eq(_given.get(&"fresh_cream", 0), 1, "la crème du café")


func test_every_collect_step_can_be_completed() -> void:
	var problems: Array[String] = []
	var steps := 0
	for quest: Dictionary in _quests():
		for step: Variant in quest.get("steps", []):
			if not step is Dictionary or (step as Dictionary).get("type") != "collect":
				continue
			steps += 1
			var item_id := StringName(str(step["item"]))
			var count := int((step as Dictionary).get("count", 1))
			if _supply(item_id) < count:
				problems.append(
					(
						"%s/%s : %d %s demandés, %d dans l'île"
						% [quest["id"], step["id"], count, item_id, _supply(item_id)]
					)
				)
	assert_gt(steps, 0, "des étapes collect dans les quêtes du jeu")
	assert_eq(problems, [] as Array[String], "\n".join(problems))


func test_what_the_quests_take_never_exceeds_what_the_island_offers() -> void:
	var used: Dictionary[StringName, int] = {}
	for quest: Dictionary in _quests():
		for step: Variant in quest.get("steps", []):
			if step is Dictionary and (step as Dictionary).get("consume", false):
				var item_id := StringName(str(step["item"]))
				used[item_id] = used.get(item_id, 0) + int((step as Dictionary).get("count", 1))
	for item_id: StringName in _taken:
		used[item_id] = used.get(item_id, 0) + _taken[item_id]
	var problems: Array[String] = []
	for item_id: StringName in used:
		if used[item_id] > _supply(item_id):
			problems.append(
				"%s : %d pris, %d dans l'île" % [item_id, used[item_id], _supply(item_id)]
			)
	assert_gt(used.size(), 0, "des objets rendus ou repris")
	assert_eq(problems, [] as Array[String], "\n".join(problems))
