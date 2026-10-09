extends GutTest
## (E1) Cartes (docs/REFONTE.md, section 7.1 ; src/world/map.gd, src/world/map_exit.gd) :
## chaque carte de src/world/maps/ suit le contrat (racine Map nommée comme sa carte, enfants
## figés, Spawn, sol sur la couche 1, Geometry fondu, sorties dont la carte cible et le marqueur
## d'arrivée `from_<carte>` existent) ; identifiants ; bornes de caméra par défaut ; carte
## héritée centrée sur l'origine, au Spawn du village ; sorties à pied et à invite.

const ESSAI := &"essai"


## Marqueurs de chaque carte (map_id → noms), lus sur des instances hors de l'arbre.
func _all_markers() -> Dictionary:
	var markers := {}
	for map_id: StringName in Map.all_ids():
		var map := (load(Map.scene_path(map_id)) as PackedScene).instantiate() as Map
		markers[map_id] = map.marker_names() if map != null else []
		if map != null:
			map.free()
	return markers


func test_every_map_follows_the_contract() -> void:
	var ids := Map.all_ids()
	assert_true(ids.has(WorldManager.LEGACY_MAP), "carte héritée")
	assert_true(ids.has(ESSAI), "carte d'essai")
	var markers := _all_markers()
	for map_id: StringName in ids:
		var map := (load(Map.scene_path(map_id)) as PackedScene).instantiate()
		# Dans l'arbre : un sol MapGround ou InteriorRoom construit sa collision dans _ready.
		add_child(map)
		await wait_process_frames(1)
		var problems := Map.problems(map)
		if map is Map:
			problems.append_array(Map.exit_problems(map as Map, markers))
		assert_eq(problems.size(), 0, "%s : %s" % [map_id, "; ".join(problems)])
		map.free()


func test_map_ids() -> void:
	for good: StringName in [&"essai", &"entrepot_rdc", &"port2", &"ile_ancienne"]:
		assert_true(Map.is_valid_id(good), String(good))
	for bad: StringName in [&"", &"Essai", &"entrepôt", &"2port", &"sentier-nord", &"a b"]:
		assert_false(Map.is_valid_id(bad), String(bad))
	assert_true(Map.exists(ESSAI))
	assert_false(Map.exists(&"nulle_part"))
	assert_eq(Map.scene_path(ESSAI), "res://src/world/maps/essai/essai.tscn")


func test_camera_bounds_default_to_the_whole_map() -> void:
	var map := Map.new()
	map.size = Vector2(60, 45)
	assert_eq(map.area(), Rect2(0, 0, 60, 45), "coin nord-ouest à l'origine")
	assert_eq(map.bounds(), Rect2(0, 0, 60, 45), "bornes vides : la carte entière")
	map.camera_bounds = Rect2(10, 8, 40, 20)
	assert_eq(map.bounds(), Rect2(10, 8, 40, 20))
	map.free()


func test_problems_name_what_is_missing() -> void:
	var map := Map.new()
	map.name = "Carte"
	var problems := Map.problems(map)
	var text := "; ".join(problems)
	for expected: String in ["snake_case", "Ground", "Geometry", "Markers", "Exits", "Life"]:
		assert_string_contains(text, expected)
	map.free()
	var plain := Node3D.new()
	assert_string_contains(Map.problems(plain)[0], "pas une Map")
	plain.free()


func test_exit_problems_check_target_and_arrival_marker() -> void:
	var map := Map.new()
	map.name = "essai"
	var exits := Node3D.new()
	exits.name = "Exits"
	map.add_child(exits)
	var to_nowhere := MapExit.new()
	to_nowhere.name = "to_nowhere"
	to_nowhere.target_map = &"nulle_part"
	exits.add_child(to_nowhere)
	var wrong_marker := MapExit.new()
	wrong_marker.name = "to_island"
	wrong_marker.target_map = WorldManager.LEGACY_MAP
	wrong_marker.target_marker = &"from_ailleurs"
	exits.add_child(wrong_marker)
	var text := "; ".join(Map.exit_problems(map, {WorldManager.LEGACY_MAP: [&"Spawn"]}))
	assert_string_contains(text, "nulle_part")
	assert_string_contains(text, "from_ailleurs absent")
	assert_string_contains(text, "attendu from_essai")
	map.free()


func test_legacy_map_keeps_the_island_coordinates() -> void:
	var map := (load(Map.scene_path(WorldManager.LEGACY_MAP)) as PackedScene).instantiate() as Map
	add_child_autofree(map)
	assert_eq(map.area(), Rect2(-80, -80, 160, 160), "île centrée sur l'origine")
	assert_eq(map.bounds(), WorldManager.DEFAULT_CAMERA_BOUNDS, "bornes de la caméra de l'île")
	assert_true(map.get_node(^"Ground") is IslandTerrain, "Ground : le sol de l'île")
	var village_spawn := map.get_node(^"Zones/village/Spawn") as Node3D
	assert_almost_eq(
		map.spawn().global_position,
		village_spawn.global_position,
		Vector3.ONE * 0.01,
		"une nouvelle partie commence au même endroit"
	)
	assert_eq(map.display_name, "", "l'ancienne île annonce ses zones, pas son nom")
	assert_eq(get_tree().get_nodes_in_group(&"zones").size(), 5, "les cinq zones restent")


func test_prompt_exit_is_an_interactable() -> void:
	var exit := MapExit.new()
	exit.target_map = ESSAI
	exit.prompt = "Entrer"
	add_child_autofree(exit)
	assert_true(exit.needs_interaction())
	assert_true(exit.is_in_group(&"interactable"), "détectée comme un PNJ ou un objet")
	assert_eq(exit.collision_layer, 32, "couche 6 (interactable)")
	assert_eq(exit.collision_mask, 2, "masque 2 (player)")
	assert_eq(exit.get_prompt(), "Entrer")
	assert_true(Player.resolve_interactable(exit) == exit, "le joueur la résout")


func test_walk_exit_is_a_plain_area() -> void:
	var exit := MapExit.new()
	exit.target_map = ESSAI
	add_child_autofree(exit)
	assert_false(exit.needs_interaction())
	assert_false(exit.is_in_group(&"interactable"), "on passe en marchant")
	assert_eq(exit.collision_layer, 0, "couche 0")
	assert_eq(exit.collision_mask, 2, "masque 2 (player)")


func test_exit_does_nothing_during_a_transition_or_without_target() -> void:
	var exit := MapExit.new()
	add_child_autofree(exit)
	assert_false(exit.use(), "sans carte cible")
	exit.target_map = ESSAI
	# Une arrivée vient d'avoir lieu (enter_map) : sourde quelques images physiques.
	WorldManager._settle_frames = WorldManager.SETTLE_FRAMES
	assert_true(WorldManager.is_transitioning())
	assert_false(exit.use(), "rien ne part pendant un changement de carte")
	await wait_physics_frames(WorldManager.SETTLE_FRAMES + 1)
	assert_false(WorldManager.is_transitioning(), "les sorties se réveillent")


func test_display_name_is_read_without_loading_the_map() -> void:
	assert_eq(WorldManager.map_display_name(ESSAI), "Clairière d'essai")
	assert_eq(WorldManager.map_display_name(WorldManager.LEGACY_MAP), "")
	assert_eq(WorldManager.map_display_name(&"nulle_part"), "")
