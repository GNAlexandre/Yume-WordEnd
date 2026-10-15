extends "res://tests/stubs/e5_fauna_test.gd"
## (E5) Le peuplement : quelles espèces, combien, où, à quel moment (GameState.moment) et par quel
## temps ; la meute ; le renvoi d'un groupe hors de saison et le regarnissage ; les règles de
## l'île (liste fauna) et les régions sans animaux (l'entrepôt, le village : rien, sauf les
## bandes d'ambiance de la carte).

const FOREST := &"foret_essai"
const FAUNA_SCENE := preload("res://src/fauna/fauna.tscn")
## Effectifs attendus de foret_essai par moment (peuplement.json).
const BY_MOMENT := {
	&"aube": {&"deer": 3, &"fox": 1, &"blackbird": 2, &"frog": 0},
	&"matin": {&"boar": 1, &"bear": 1, &"squirrel": 2, &"frog": 3, &"blackbird": 2, &"crow": 2},
	&"apres_midi": {&"bear": 1, &"squirrel": 2, &"frog": 3, &"crow": 2},
	&"couchant": {&"deer": 3, &"wolf": 3, &"boar": 1, &"fox": 1, &"frog": 3},
	&"nuit": {&"wolf": 3, &"owl": 1},
}
const ALL_SPECIES: Array[StringName] = [
	&"bear", &"blackbird", &"boar", &"crow", &"deer", &"fox", &"frog", &"owl", &"squirrel", &"wolf"
]


## foret_essai posée dans le monde au moment et par le temps demandés ; renvoie son peuplement.
func _forest(moment: StringName, weather: StringName = &"clair") -> FaunaPopulator:
	GameState.moment = moment
	GameState.weather = weather
	var map := (load(Map.scene_path(FOREST)) as PackedScene).instantiate() as Map
	world.add_child(map)
	await wait_physics_frames(2)
	return map.get_node(^"Life/Fauna") as FaunaPopulator


func _counts(populator: FaunaPopulator) -> Dictionary:
	var counts := {}
	for animal: Animal in populator.animals():
		var id := animal.species().id
		counts[id] = int(counts.get(id, 0)) + 1
	return counts


## Une carte nue (Map, Life, Places, Fauna) nommée map_id avec les groupes entries dans l'île
## island_id (peuplement injecté) ; renvoie son peuplement.
func _bare_map(map_id: StringName, island_id: StringName, entries: Array) -> FaunaPopulator:
	FaunaRules.set_population(
		island_id,
		{
			"banned_regions": ["entrepot", "village", "ville", "port"],
			"maps": {String(map_id): entries}
		}
	)
	var map := Map.new()
	map.name = map_id
	var life := Node3D.new()
	life.name = "Life"
	map.add_child(life)
	var places := Node3D.new()
	places.name = "Places"
	life.add_child(places)
	var marker := Marker3D.new()
	marker.name = "ici"
	marker.position = Vector3(5.0, 0.0, 5.0)
	places.add_child(marker)
	var populator := FAUNA_SCENE.instantiate() as FaunaPopulator
	life.add_child(populator)
	world.add_child(map)
	await wait_physics_frames(2)
	return populator


func test_the_forest_is_populated_by_moment(
	moment: StringName = use_parameters(BY_MOMENT.keys())
) -> void:
	var populator := await _forest(moment)
	var counts := _counts(populator)
	var expected: Dictionary = BY_MOMENT[moment]
	for id: StringName in ALL_SPECIES:
		assert_eq(
			int(counts.get(id, 0)), int(expected.get(id, 0)), "%s, %s : %s" % [moment, id, counts]
		)


func test_wolves_come_out_at_dusk_and_are_hidden_by_day() -> void:
	for moment: StringName in [&"aube", &"matin", &"apres_midi"]:
		var populator := await _forest(moment)
		assert_eq(int(_counts(populator).get(&"wolf", 0)), 0, "%s : pas de loup" % moment)
		populator.get_parent().get_parent().free()
	var dusk := await _forest(&"couchant")
	var wolves: Array[Animal] = []
	for animal: Animal in dusk.animals(&"loups"):
		wolves.append(animal)
	assert_eq(wolves.size(), 3, "une meute de trois au couchant")
	assert_not_null(wolves[0].pack, "ils forment une meute")
	for wolf: Animal in wolves:
		assert_same(wolf.pack, wolves[0].pack, "la même meute")
	assert_eq(wolves[0].pack.initial_size, 3)


func test_animals_stand_near_their_place_on_walkable_ground() -> void:
	var populator := await _forest(&"couchant")
	var map := populator.get_parent().get_parent() as Map
	var ground := map.get_node(^"Ground") as MapGround
	var places := {&"cerfs": &"cerfs", &"souille": &"sanglier", &"loups": &"loups"}
	for marker_name: StringName in places:
		var marker := map.find_child(String(marker_name), true, false) as Marker3D
		var entry := {}
		for candidate: Dictionary in FaunaRules.entries_for(FOREST):
			if candidate["id"] == String(places[marker_name]):
				entry = candidate
		for animal: Animal in populator.animals(places[marker_name]):
			assert_lte(
				flat_distance(animal, marker),
				float(entry["radius"]) + 0.5,
				"%s : dans le rayon de son marqueur" % animal.name
			)
			assert_true(
				ground.is_walkable(animal.global_position.x, animal.global_position.z),
				"%s : sur le sol praticable" % animal.name
			)


func test_a_group_out_of_season_is_sent_away_and_the_new_one_comes() -> void:
	var populator := await _forest(&"couchant")
	var deer := populator.animals(&"cerfs")
	var wolves := populator.animals(&"loups")
	assert_eq(deer.size(), 3)
	GameState.moment = &"nuit"
	await wait_physics_frames(2)
	for animal: Animal in deer:
		assert_true(animal.is_leaving(), "%s : le jour tombe, il s'en va" % animal.name)
	for animal: Animal in wolves:
		assert_false(animal.is_leaving(), "les loups restent la nuit")
	assert_eq(populator.animals(&"cerfs").size(), 0)
	assert_eq(populator.animals(&"chouette").size(), 1, "la chouette sort la nuit")
	assert_eq(populator.animals(&"loups").size(), 3, "toujours les mêmes loups")
	await wait_physics_frames(300)
	for animal: Animal in deer:
		assert_false(is_around(animal), "et ils disparaissent")


func test_a_missing_animal_is_replaced_out_of_sight() -> void:
	var populator := await _forest(&"couchant")
	var deer := populator.animals(&"cerfs")
	for _i in 2:
		assert_true(strike(deer[0], deer[0].global_position + Vector3.LEFT))
		deer.remove_at(0)
	assert_eq(populator.animals(&"cerfs").size(), 1, "deux cerfs ont fui")
	populator.call("_tick", 1.0)
	assert_eq(populator.animals(&"cerfs").size(), 1, "pas avant respawn_s")
	populator.call("_tick", 100.0)
	assert_eq(populator.animals(&"cerfs").size(), 3, "les deux cerfs manquants reviennent")


func test_a_new_animal_never_appears_next_to_the_player() -> void:
	var populator := await _forest(&"couchant")
	var map := populator.get_parent().get_parent() as Map
	for animal: Animal in populator.animals(&"cerfs"):
		animal.free()
	var marker := map.find_child("cerfs", true, false) as Marker3D
	make_player(marker.global_position, 0.0)
	populator.call("_tick", 100.0)
	assert_eq(
		populator.animals(&"cerfs").size(), 0, "le joueur est dans la clairière : rien n'apparaît"
	)
	player.global_position = Vector3(50.0, 0.0, 35.0)
	populator.call("_tick", 100.0)
	assert_gt(populator.animals(&"cerfs").size(), 0, "il s'éloigne : les cerfs reviennent")


func test_ambient_strips_follow_the_moment_and_the_weather() -> void:
	var populator := await _forest(&"matin", &"clair")
	var butterflies := populator.ambient_of(&"papillons")
	assert_not_null(butterflies, "des papillons par beau temps")
	assert_true(butterflies.visible)
	assert_null(populator.ambient_of(&"libellules"), "les libellules : l'après-midi")
	GameState.weather = &"pluie"
	assert_false(butterflies.visible, "pas sous la pluie")
	GameState.weather = &"clair"
	assert_true(butterflies.visible)
	GameState.moment = &"apres_midi"
	assert_true(butterflies.visible, "les papillons : le matin et l'après-midi")
	assert_not_null(populator.ambient_of(&"libellules"))
	assert_true(populator.ambient_of(&"libellules").visible)
	GameState.moment = &"nuit"
	assert_false(populator.ambient_of(&"libellules").visible)
	assert_false(butterflies.visible, "ni les uns ni les autres la nuit")


func test_the_island_rules_decide_who_may_live_where() -> void:
	var cases := [
		[&"foret_essai", &"deer", true],
		[&"foret_essai", &"wolf", true],
		[&"foret_essai", &"unicorn", false],
		[&"surface_essai", &"deer", false],
		[&"ile_ancienne", &"wolf", false],
		[&"quai_essai", &"fox", false],
	]
	for case: Array in cases:
		assert_eq(
			FaunaRules.island_allows(case[0], case[1]), case[2], "%s sur %s" % [case[1], case[0]]
		)


func test_no_animal_at_the_warehouse_the_village_or_in_town() -> void:
	for map_id: StringName in [
		&"entrepot", &"entrepot_rdc", &"entrepot_etage", &"entrepot_toit", &"village"
	]:
		assert_true(FaunaRules.is_banned(map_id), "%s : région sans animaux" % map_id)
	assert_true(FaunaRules.is_banned(FOREST, &"ville"), "la ville")
	assert_true(FaunaRules.is_banned(FOREST, &"port"), "le port")
	for map_id: StringName in [&"foret_essai", &"foret_profonde", &"sentier", &"colline"]:
		assert_false(FaunaRules.is_banned(map_id), "%s : on y croise des bêtes" % map_id)
	for map_key: String in FaunaRules.population(ISLAND)["maps"]:
		assert_false(
			FaunaRules.is_banned(StringName(map_key)), "%s : peuplée, donc permise" % map_key
		)
	for map_key: String in FaunaRules.population(ISLAND)["planned"]:
		assert_false(
			FaunaRules.is_banned(StringName(map_key)), "%s : prévue, donc permise" % map_key
		)


func test_a_banned_map_stays_empty_even_with_a_group_in_the_data() -> void:
	var group := {"id": "cerfs", "species": "deer", "count": 2.0, "at": "ici", "radius": 2.0}
	var control := await _bare_map(FOREST, ISLAND, [group])
	assert_eq(control.animals().size(), 2, "témoin : sur foret_essai, les deux cerfs sont là")
	control.get_parent().get_parent().free()
	for map_id: StringName in [&"village", &"entrepot"]:
		var populator := await _bare_map(map_id, ISLAND, [group])
		assert_eq(populator.animals().size(), 0, "%s : aucun animal" % map_id)
		populator.get_parent().get_parent().free()


func test_a_map_whose_island_lists_no_fauna_stays_empty() -> void:
	var group := {"id": "cerfs", "species": "deer", "count": 2.0, "at": "ici", "radius": 2.0}
	for map_id: StringName in [&"surface_essai", &"quai_essai"]:
		var island_id := WorldAtlas.island_of(map_id)
		var populator := await _bare_map(map_id, island_id, [group])
		assert_eq(populator.animals().size(), 0, "%s (île %s) : rien" % [map_id, island_id])
		populator.get_parent().get_parent().free()


func test_the_populator_ignores_an_unknown_species() -> void:
	var populator := await _bare_map(
		FOREST,
		ISLAND,
		[
			{"id": "licornes", "species": "unicorn", "count": 1.0, "at": "ici"},
			{"id": "cerfs", "species": "deer", "count": 1.0, "at": "ici"},
		]
	)
	assert_eq(populator.group_ids(), [&"cerfs"] as Array[StringName])
