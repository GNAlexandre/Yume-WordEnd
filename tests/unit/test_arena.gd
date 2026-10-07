extends GutTest
## Arena (src/enemies/arena.tscn) : panneau « Sonner la cloche de veille » (interactable, couche 6)
## qui lance la série et reste inactif pendant celle-ci, bornes, points d'apparition, zone.

const ARENA_SCENE := preload("res://src/enemies/arena.tscn")
const DUNES_SCENE := preload("res://src/world/zones/dunes/dunes.tscn")
const PLAYER_STUB := preload("res://tests/stubs/player_stub.tscn")
const PROMPT := "Sonner la cloche de veille"


func before_each() -> void:
	GameState.reset()


func after_all() -> void:
	GameState.reset()


func _arena() -> Arena:
	var root: Node3D = add_child_autofree(Node3D.new())
	var arena := ARENA_SCENE.instantiate() as Arena
	arena.arena_id = &"dunes"
	root.add_child(arena)
	return arena


## Premier nœud du groupe interactable en remontant depuis node (règle de détection du joueur).
func _interactable_from(node: Node) -> Node:
	while node != null and not node.is_in_group(&"interactable"):
		node = node.get_parent()
	return node


func test_panel_starts_the_series() -> void:
	var arena := _arena()
	var player := PLAYER_STUB.instantiate() as Node3D
	arena.get_parent().add_child(player)
	var area := arena.get_node(^"Panel/InteractArea") as Area3D
	assert_eq(area.collision_layer, 32, "zone d'interaction sur la couche 6")
	var panel := _interactable_from(area)
	assert_eq(panel, arena.get_node(^"Panel"), "le joueur trouve le panneau depuis sa zone")
	assert_true(panel.has_method(&"get_prompt") and panel.has_method(&"interact"))
	assert_eq(panel.call(&"get_prompt"), PROMPT)
	panel.call(&"interact", player)
	var director := arena.director()
	assert_true(director.is_running(), "interact() → start()")
	assert_eq(panel.call(&"get_prompt"), "", "inactif pendant une série")
	await wait_physics_frames(2)
	assert_false(area.monitorable, "zone d'interaction coupée pendant la série")
	panel.call(&"interact", player)
	assert_eq(director.current_wave(), 0, "pas de relance pendant la série")
	director.stop()
	await wait_physics_frames(2)
	assert_true(area.monitorable)
	assert_eq(panel.call(&"get_prompt"), PROMPT, "de nouveau actif après la série")


func test_bounds_spawn_points_and_zone_in_dunes() -> void:
	var dunes: Node3D = add_child_autofree(DUNES_SCENE.instantiate())
	var arena := dunes.get_node(^"Arena") as Arena
	assert_eq(arena.zone_id(), &"dunes")
	assert_almost_eq(arena.bounds_radius_m, 12.0, 0.001, "bornes de 12 m")
	assert_true(arena.contains(arena.global_position + Vector3(11.0, 3.0, 0.0)))
	assert_false(arena.contains(arena.global_position + Vector3(9.0, 0.0, 9.0)))
	for marker_name: String in arena.director().config()["spawn_points"]:
		var marker := arena.spawn_point(StringName(marker_name))
		assert_not_null(marker, "point d'apparition %s" % marker_name)
		if marker != null:
			assert_false(arena.contains(marker.global_position), "%s hors des bornes" % marker_name)
	var panel := arena.get_node(^"Panel") as Node3D
	assert_true(arena.contains(panel.global_position), "panneau dans les bornes")
	assert_eq(_arena().zone_id(), &"", "hors d'une zone")


func test_real_dunes_series_spawns_on_the_markers() -> void:
	var dunes: Node3D = add_child_autofree(DUNES_SCENE.instantiate())
	var arena := dunes.get_node(^"Arena") as Arena
	var player := PLAYER_STUB.instantiate() as Node3D
	player.position = Vector3(8.0, 0.2, 0.0)
	dunes.add_child(player)
	watch_signals(EventBus)
	var started_at := Time.get_ticks_msec()
	arena.get_node(^"Panel").call(&"interact", player)
	var director := arena.director()
	var spawned: bool = await wait_until(
		func() -> bool: return not director.alive_enemies().is_empty(), 4.0
	)
	assert_true(spawned, "premier Timere de la vague 1")
	assert_gt(Time.get_ticks_msec() - started_at, 1900, "1,2 s de pause puis 0,8 s")
	assert_signal_emitted_with_parameters(EventBus, "wave_started", [&"dunes", 1, 5])
	var enemy := director.alive_enemies()[0]
	var offset := enemy.global_position - arena.global_position
	assert_almost_eq(Vector2(offset.x, offset.z).length(), 13.0, 1.6, "sur un point à 13 m")
	assert_true(director.is_running(), "le joueur est dans sa zone et dans les bornes")


func test_dunes_waves_config_is_complete() -> void:
	var director := _arena().director()
	var config := director.config()
	assert_eq(str(config.get("arena")), "dunes")
	assert_false(config.has("music"), "pas de musique tant qu'il n'y a pas d'audio")
	assert_eq(int(config["heal_every_waves"]), 2)
	assert_eq(int(config["bonus_per_wave"]), 50)
	assert_eq((config["waves"] as Array).size(), 3)
	var generator: Dictionary = config["generator"]
	assert_eq(str(generator["count"]), "3 + 2 * n")
	assert_eq_deep(generator["min_wave"], {"timere_runner": 2.0, "timere_big": 3.0})
	assert_eq_deep(generator["max_simultaneous"], {"timere_big": 1.0})
