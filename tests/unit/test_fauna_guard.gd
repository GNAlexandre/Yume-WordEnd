extends "res://tests/stubs/e5_fauna_test.gd"
## (E5) La garde des Timeres (X1) et celle de la faune : un Timere n'apparaît pas là où les
## règles de l'île n'en veulent pas (l'île n° 68), un animal n'apparaît pas là où la liste fauna
## de l'île ne le permet pas ; les deux se distinguent par les données (AnimalData, espèce,
## règles de l'île), jamais par un nom. Non-régression : les Timeres de l'ancienne île et de la
## surface.

const ENEMY_SCENE := preload("res://src/enemies/enemy.tscn")
const TIMERE_DATA := preload("res://data/enemies/timere_small.tres")


func _map(map_id: StringName) -> Map:
	var map := Map.new()
	map.name = map_id
	world.add_child(map)
	return map


func _timere() -> Enemy:
	var enemy := ENEMY_SCENE.instantiate() as Enemy
	enemy.data = TIMERE_DATA
	enemy.drops_enabled = false
	return enemy


func _deer() -> Animal:
	var animal := ANIMAL_SCENE.instantiate() as Animal
	animal.data = FaunaRules.species(ISLAND, &"deer")
	return animal


func test_island_68_keeps_its_animals_but_not_the_timeres() -> void:
	var map := _map(&"foret_essai")
	var timere := _timere()
	var deer := _deer()
	map.add_child(timere)
	map.add_child(deer)
	await wait_physics_frames(2)
	assert_false(is_around(timere), "aucun Timere sur l'île n° 68")
	assert_true(is_around(deer), "mais les animaux y vivent")
	assert_true(deer.is_in_group(&"fauna"))


func test_the_legacy_island_and_the_surface_keep_their_timeres_and_refuse_animals() -> void:
	for map_id: StringName in [&"ile_ancienne", &"surface_essai"]:
		var map := _map(map_id)
		var timere := _timere()
		var deer := _deer()
		map.add_child(timere)
		map.add_child(deer)
		await wait_physics_frames(2)
		assert_true(is_around(timere), "%s : ses Timeres restent" % map_id)
		assert_false(is_around(deer), "%s : la liste fauna de l'île est vide" % map_id)
		map.free()


func test_a_removed_animal_is_never_announced() -> void:
	watch_signals(EventBus)
	var map := _map(&"surface_essai")
	map.add_child(_deer())
	await wait_physics_frames(2)
	assert_signal_not_emitted(EventBus, "enemy_spawned")
	var allowed := _map(&"foret_essai")
	allowed.add_child(_deer())
	await wait_physics_frames(2)
	assert_signal_emitted(
		EventBus, "enemy_spawned", "un animal admis est annoncé comme un combattant"
	)


func test_a_species_the_island_does_not_list_is_removed() -> void:
	var map := _map(&"foret_essai")
	var stranger := _deer()
	stranger.data = stranger.data.duplicate() as AnimalData
	stranger.data.id = &"unicorn"
	map.add_child(stranger)
	await wait_physics_frames(2)
	assert_false(is_around(stranger), "la licorne n'est pas dans rules.fauna de l'île n° 68")


func test_the_warehouse_and_the_village_refuse_animals() -> void:
	for map_id: StringName in [&"entrepot", &"entrepot_rdc", &"village"]:
		var map := _map(map_id)
		var deer := _deer()
		map.add_child(deer)
		await wait_physics_frames(2)
		assert_false(is_around(deer), "%s : jamais d'animal" % map_id)
		map.free()


func test_the_region_of_the_map_is_enough_to_refuse_animals() -> void:
	var map := _map(&"foret_essai")
	map.region = &"ville"
	var deer := _deer()
	map.add_child(deer)
	await wait_physics_frames(2)
	assert_false(is_around(deer), "une carte de la région « ville » n'a pas d'animaux")


func test_outside_any_map_the_rules_do_not_apply() -> void:
	var deer := _deer()
	world.add_child(deer)
	await wait_physics_frames(2)
	assert_true(is_around(deer), "sans carte (tests, démonstration), rien ne l'interdit")


func test_an_animal_without_species_data_is_refused() -> void:
	var animal := ANIMAL_SCENE.instantiate() as Animal
	animal.data = TIMERE_DATA
	world.add_child(animal)
	await wait_physics_frames(2)
	assert_false(is_around(animal), "un Timere ne devient pas un animal")


func test_both_guards_read_the_rules_of_the_island() -> void:
	var surface := WorldAtlas.rules_for(&"surface_essai")
	assert_true(surface.enemies_allowed, "la surface : des Timeres")
	assert_true(surface.fauna.is_empty(), "et pas de faune")
	var island_68 := WorldAtlas.rules_for(&"foret_essai")
	assert_false(island_68.enemies_allowed, "l'île n° 68 : pas de Timere")
	assert_true(&"wolf" in island_68.fauna, "et de la faune")
