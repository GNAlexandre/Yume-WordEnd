extends GutTest
## (X1) Les règles des îles appliquées par les données (data/world/, WorldAtlas.rules_for),
## jamais par un nom de carte : aucun Timere sur l'île n° 68, des Timeres sur la surface ((F1)
## l'ancienne île, ses Timeres libres et son arène sont partis) ; la mer de nuages
## sous le bord ou le sol jusqu'à l'horizon (MapGround) ; le ciel par défaut de l'île
## (Atmosphere) ; l'île courante et les îles connues de GameState, sauvegardées.

const ENEMY_SCENE := preload("res://src/enemies/enemy.tscn")
const AtmosphereScript := preload("res://src/autoload/atmosphere.gd")
const TEMP_DIR := "user://test_island_rules"


func before_each() -> void:
	GameState.reset()
	WorldAtlas.set_data_dirs()


func after_each() -> void:
	Atmosphere.dress(null)
	GameState.reset()
	WorldAtlas.set_data_dirs()
	for kind: String in ["worlds", "islands"]:
		var dir := TEMP_DIR.path_join(kind)
		if DirAccess.dir_exists_absolute(dir):
			for file: String in DirAccess.get_files_at(dir):
				DirAccess.remove_absolute(dir.path_join(file))
			DirAccess.remove_absolute(dir)
	if DirAccess.dir_exists_absolute(TEMP_DIR):
		DirAccess.remove_absolute(TEMP_DIR)


## Une carte vide (une Map nommée map_id, sans rien d'autre) ajoutée au test.
func _map(map_id: StringName) -> Map:
	var map := Map.new()
	map.name = map_id
	add_child_autofree(map)
	return map


func _timere() -> Enemy:
	var enemy := ENEMY_SCENE.instantiate() as Enemy
	enemy.data = load("res://data/enemies/timere_small.tres") as EnemyData
	enemy.drops_enabled = false
	return enemy


# --- Timeres ----------------------------------------------------------------------------------


func test_no_timere_appears_on_island_68() -> void:
	watch_signals(EventBus)
	var map := _map(&"essai")
	var enemy := _timere()
	map.add_child(enemy)
	assert_false(enemy.is_in_group(&"enemies"), "pas parmi les ennemis vivants")
	await wait_process_frames(2)
	assert_false(is_instance_valid(enemy), "retiré aussitôt")
	assert_signal_not_emitted(EventBus, "enemy_spawned", "jamais annoncé")


func test_timeres_appear_on_the_surface() -> void:
	for map_id: StringName in [&"surface_essai"]:
		watch_signals(EventBus)
		var map := _map(map_id)
		var enemy := _timere()
		map.add_child(enemy)
		await wait_process_frames(2)
		assert_true(is_instance_valid(enemy) and enemy.is_inside_tree(), "%s : il reste" % map_id)
		assert_signal_emitted(EventBus, "enemy_spawned", "%s : annoncé" % map_id)
		map.free()


# --- Sol, ciel --------------------------------------------------------------------------------


func test_cloud_sea_on_regule_aire_and_ground_to_the_horizon_on_the_surface() -> void:
	var quay := (load(Map.scene_path(&"quai_essai")) as PackedScene).instantiate() as Map
	add_child_autofree(quay)
	var quay_ground := quay.get_node(^"Ground") as MapGround
	assert_true(quay_ground.data.has_void(), "le quai touche le vide")
	assert_true(_internal(quay_ground, &"CloudSea").visible, "Regule Aire : la mer de nuages")
	assert_false(quay_ground.has_far_ground())
	var surface := (load(Map.scene_path(&"surface_essai")) as PackedScene).instantiate() as Map
	add_child_autofree(surface)
	var surface_ground := surface.get_node(^"Ground") as MapGround
	assert_true(surface_ground.has_far_ground(), "la surface : un sol jusqu'à l'horizon")
	assert_null(_internal(surface_ground, &"CloudSea"), "et pas de mer de nuages")
	var far := _internal(surface_ground, &"FarGround")
	var bounds := far.get_aabb()
	assert_gt(bounds.size.x, 2000.0, "jusqu'à l'horizon")
	assert_almost_eq(bounds.position.y, MapGround.FAR_GROUND_DROP, 0.001, "juste sous le sol")
	assert_eq(surface_ground.stats()["draw_calls"], 3, "sol, faces, horizon")


func test_void_below_is_read_from_the_rules_not_the_map_name() -> void:
	# Le même quai (un bord sur le vide), rangé dans un monde dont les îles ont un sol dessous.
	_write(
		"worlds",
		"monde_essai",
		{"name": "Monde", "islands": ["ile_x"], "rules": {"void_below": "ground"}}
	)
	_write(
		"islands",
		"ile_x",
		{
			"name": "Île X",
			"maps": ["quai_essai"],
			"arrival_map": "quai_essai",
			"places": {},
			"ports": {},
		}
	)
	WorldAtlas.set_data_dirs(TEMP_DIR.path_join("worlds"), TEMP_DIR.path_join("islands"))
	var quay := (load(Map.scene_path(&"quai_essai")) as PackedScene).instantiate() as Map
	add_child_autofree(quay)
	var ground := quay.get_node(^"Ground") as MapGround
	assert_true(ground.data.has_void())
	var clouds := _internal(ground, &"CloudSea")
	assert_true(clouds == null or not clouds.visible, "pas de mer de nuages sous ce bord")
	assert_true(ground.has_far_ground(), "le sol, dessous")


func test_default_sky_of_the_island() -> void:
	var surface := _map(&"surface_essai")
	assert_eq(
		AtmosphereScript.effective_preset_id(surface, &"couchant"), &"apres_midi", "ciel de l'île"
	)
	surface.light_preset = &"nuit"
	assert_eq(
		AtmosphereScript.effective_preset_id(surface, &"couchant"), &"nuit", "la carte d'abord"
	)
	surface.light_preset = &""
	surface.interior = true
	assert_eq(AtmosphereScript.effective_preset_id(surface, &"couchant"), &"interieur", "dedans")
	var essai := _map(&"essai")
	assert_eq(
		AtmosphereScript.effective_preset_id(essai, &"matin"), &"matin", "île n° 68 : le moment"
	)
	var unknown := _map(&"carte_de_test")
	assert_eq(AtmosphereScript.effective_preset_id(unknown, &"nuit"), &"nuit", "hors des îles")


# --- État de la partie ------------------------------------------------------------------------


func test_island_state_round_trip() -> void:
	GameState.position = Vector3(1, 0, 2)
	GameState.map = &"quai_essai"
	GameState.island = &"ile_essai"
	assert_true(GameState.discover_island(&"ile_68"))
	assert_true(GameState.discover_island(&"ile_essai"))
	assert_false(GameState.discover_island(&"ile_68"), "déjà connue")
	assert_false(GameState.discover_island(&""), "sans nom")
	var data := GameState.to_dict()
	assert_eq(data["island"], "ile_essai")
	assert_eq(data["known_islands"], ["ile_68", "ile_essai"], "dans l'ordre de découverte")
	var text := JSON.stringify(data)
	GameState.reset()
	assert_eq(GameState.island, &"")
	assert_eq(GameState.known_islands(), [] as Array[StringName])
	GameState.from_dict(JSON.parse_string(text))
	assert_eq(GameState.island, &"ile_essai")
	assert_eq(GameState.known_islands(), [&"ile_68", &"ile_essai"] as Array[StringName])
	assert_true(GameState.knows_island(&"ile_essai"))


func test_saves_without_islands_still_load() -> void:
	var data := GameState.to_dict()
	data.erase("island")
	data.erase("known_islands")
	data["position"] = [1, 0, 2]
	data["map"] = "essai"
	GameState.from_dict(data)
	assert_eq(GameState.island, &"", "champ facultatif : WorldManager le déduit de la carte")
	assert_eq(GameState.known_islands(), [] as Array[StringName])
	var bad := {"version": SaveManager.SAVE_VERSION, "day": 1, "island": 68}
	assert_eq(SaveManager.import_json(JSON.stringify(bad)), ERR_INVALID_DATA, "île mal typée")
	bad = {"version": SaveManager.SAVE_VERSION, "day": 1, "known_islands": "ile_68"}
	assert_eq(SaveManager.import_json(JSON.stringify(bad)), ERR_INVALID_DATA, "liste attendue")


func _internal(ground: MapGround, child: StringName) -> MeshInstance3D:
	for node: Node in ground.get_children(true):
		if node.name == child:
			return node as MeshInstance3D
	return null


func _write(kind: String, id: String, data: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(TEMP_DIR.path_join(kind))
	var file := FileAccess.open(TEMP_DIR.path_join(kind).path_join(id + ".json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
