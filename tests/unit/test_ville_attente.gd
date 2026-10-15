extends GutTest
## (CV) Les cartes d'attente de la ville et la ville dans l'île n° 68 :
## - la place du marché (`ville_marche`), construite plus tard : carte d'attente du dehors (32 × 24
##   m, écriteau
##   « Plus loin, bientôt », deux sorties : vers la ville haute et, à l'ouest, vers le port) ;
## - la librairie, le café habituel et la salle de projection : la pièce, la porte, les points du
##   plan, sans meuble
##   (leur lot les meublera), un écriteau à examiner sur le seuil ;
## - les six cartes de la ville sont dans `ile_68.json` (lieu `ville`) ; les portes et les retours
##   se répondent.

const SHOPS := {
	&"ville_cafe": ["Le café habituel", &"from_ville_cafe", &"cafe_comptoir"],
	&"ville_librairie": ["La librairie", &"from_ville_librairie", &"librairie_comptoir"],
	&"ville_projection": ["La salle de projection", &"from_ville_projection", &"projection_allee"],
}
const TOWN_MAPS: Array[StringName] = [
	&"ville_haute",
	&"ville_marche",
	&"ville_snack",
	&"ville_cafe",
	&"ville_librairie",
	&"ville_projection",
]


func after_each() -> void:
	DialogueRunner.clear_story_cache()


func test_the_town_maps_are_in_the_island_and_in_their_place() -> void:
	for map_id: StringName in TOWN_MAPS:
		assert_true(Map.exists(map_id), "%s existe" % map_id)
		assert_true(WorldAtlas.maps_of(&"ile_68").has(map_id), "%s dans l'île n° 68" % map_id)
		assert_eq(WorldAtlas.place_of(map_id), &"ville", "%s : lieu de la ville" % map_id)
		assert_eq(WorldAtlas.island_of(map_id), &"ile_68")
	var place := WorldAtlas.place(&"ile_68", &"ville")
	assert_eq(place["name"], "Le centre-ville")
	assert_eq((place["maps"] as Array).size(), TOWN_MAPS.size(), "les six cartes du lieu")
	assert_eq(WorldAtlas.problems(), PackedStringArray(), "îles et mondes sans problème")


func test_the_waiting_market_leads_back_to_the_upper_town() -> void:
	var map := (load(Map.scene_path(&"ville_marche")) as PackedScene).instantiate() as Map
	add_child(map)
	await wait_physics_frames(1)
	assert_eq(map.display_name, "La place du marché")
	assert_eq(map.region, &"ville")
	assert_eq(map.size, Vector2(32, 24), "carte d'attente de 32 × 24 m")
	assert_eq(Map.problems(map), PackedStringArray(), "contrat des cartes")
	var exit := map.get_node(^"Exits/vers_haute") as MapExit
	assert_eq([exit.target_map, exit.target_marker], [&"ville_haute", &"from_ville_marche"])
	assert_eq(exit.prompt, "", "on passe en marchant")
	assert_eq(
		map.get_node(^"Exits").get_child_count(), 2, "deux sorties : la ville haute et le port"
	)
	assert_not_null(map.marker(&"from_ville_haute"), "marqueur d'arrivée de la ville haute")
	assert_not_null(map.marker(&"from_port"), "marqueur d'arrivée du port (CP)")
	assert_not_null(map.get_node_or_null(^"Geometry/Sign/Reader"), "écriteau")
	var to_port := map.get_node(^"Exits/vers_port") as MapExit
	assert_eq([to_port.target_map, to_port.target_marker], [&"port", &"from_ville_marche"])
	var street := (load(Map.scene_path(&"ville_haute")) as PackedScene).instantiate() as Map
	var port := (load(Map.scene_path(&"port")) as PackedScene).instantiate() as Map
	assert_eq(
		Map.exit_problems(
			map, {&"ville_haute": street.marker_names(), &"port": port.marker_names()}
		),
		PackedStringArray(),
		"sorties vers la ville haute et le port"
	)
	var to_market := street.get_node(^"Exits/vers_marche") as MapExit
	assert_eq(
		[to_market.target_map, to_market.target_marker], [&"ville_marche", &"from_ville_haute"]
	)
	street.free()
	port.free()
	map.free()


func test_the_empty_shops_have_their_room_their_door_and_their_notice() -> void:
	var street := (load(Map.scene_path(&"ville_haute")) as PackedScene).instantiate() as Map
	for map_id: StringName in SHOPS:
		var spec: Array = SHOPS[map_id]
		var map := (load(Map.scene_path(map_id)) as PackedScene).instantiate() as Map
		add_child(map)
		await wait_physics_frames(2)
		assert_eq(Map.problems(map), PackedStringArray(), "%s : contrat des cartes" % map_id)
		assert_eq(map.display_name, spec[0], "%s : nom du plan" % map_id)
		assert_eq(map.region, &"ville")
		assert_true(map.interior, "%s : un intérieur" % map_id)
		var exit := map.get_node(^"Exits/vers_rue") as MapExit
		assert_eq(
			[exit.target_map, exit.target_marker], [&"ville_haute", spec[1]], "%s : retour" % map_id
		)
		assert_false(exit.needs_interaction(), "%s : on sort en marchant" % map_id)
		assert_not_null(street.marker(spec[1] as StringName), "%s : la rue a le marqueur" % map_id)
		assert_not_null(
			map.get_node_or_null(NodePath("Life/Places/" + String(spec[2]))), "point %s" % spec[2]
		)
		var panels := 0
		for node: Node in map.find_children("*", "InteriorPanel", true, false):
			panels += 1
		assert_eq(panels, 0, "%s : pas de meuble, son lot les posera" % map_id)
		var notice := map.get_node(^"Examine/ecriteau") as Examinable
		assert_not_null(notice, "%s : l'écriteau" % map_id)
		if notice != null:
			assert_eq(notice.text_key, "%s/ecriteau" % map_id)
			assert_string_contains(
				notice.text_value(),
				"Revenez bientôt" if map_id != &"ville_projection" else "séance"
			)
		map.free()
	street.free()
