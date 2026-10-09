extends "res://tests/stubs/m1_game_test.gd"
## Intégration M1, raccourcis de test (src/test_shortcuts.gd) : lecture des paramètres de
## l'adresse Web ou de la ligne de commande, aucun effet sans paramètre, placement dans une
## zone et banc de Timeres qui errent sans poursuivre le joueur.

const TestShortcuts := preload("res://src/test_shortcuts.gd")


func test_parameters_come_from_the_query_or_the_command_line() -> void:
	assert_eq_deep(
		TestShortcuts.parse_query("?zone=dunes&timeres=12&autre=1"),
		{"zone": "dunes", "timeres": "12"}
	)
	assert_eq_deep(TestShortcuts.parse_query(""), {})
	assert_eq_deep(TestShortcuts.parse_query("?"), {})
	assert_eq_deep(TestShortcuts.parse_query("?zone=for%C3%AAt"), {"zone": "forêt"})
	assert_eq_deep(
		TestShortcuts.parse_arguments(["res://scene.tscn", "--zone=forest", "--timeres=4", "-x"]),
		{"zone": "forest", "timeres": "4"}
	)
	assert_true(TestShortcuts.read_parameters().is_empty(), "tests sans paramètre")


func test_no_shortcut_without_parameters() -> void:
	await start_game()
	assert_null(game.get_node_or_null(^"TestShortcuts"), "partie normale : aucun raccourci")
	assert_eq(WorldManager.current_zone(), &"village")


func test_zone_and_bench_shortcuts() -> void:
	await start_game()
	var shortcuts := TestShortcuts.new()
	shortcuts.parameters = {"zone": "dunes", "timeres": "8"}
	game.add_child(shortcuts)
	await wait_physics_frames(3)
	assert_eq(WorldManager.current_zone(), &"dunes", "placé à l'entrée des dunes")
	var spawn := dunes.get_node(^"Spawn") as Node3D
	assert_lt(flat_distance(player.global_position, spawn.global_position), 0.5)
	assert_gt(player.aim_direction().dot(Vector3.LEFT), 0.9, "tourné vers l'arène")
	var bench: Array[Enemy] = []
	for child: Node in game.get_children():
		if child is Enemy and child.name.begins_with("bench_"):
			bench.append(child as Enemy)
	assert_eq(bench.size(), 8, "8 Timeres de banc")
	var kinds := {}
	for enemy: Enemy in bench:
		kinds[enemy.enemy_id()] = true
	assert_eq(kinds.size(), 4, "les quatre types")
	await wait_seconds(1.5)
	var ahead_center := player.global_position + player.aim_direction() * TestShortcuts.BENCH_AHEAD
	for enemy: Enemy in bench:
		assert_eq(enemy.state(), &"idle", "%s erre sans poursuivre" % enemy.name)
		assert_lt(flat_distance(enemy.global_position, ahead_center), 10.5, "devant le joueur")
	assert_eq(health.current, 5, "le banc n'attaque pas")


func test_dunes_shortcut_leads_straight_to_the_arena_panel() -> void:
	await start_game()
	var shortcuts := TestShortcuts.new()
	shortcuts.parameters = {"zone": "dunes"}
	game.add_child(shortcuts)
	await wait_physics_frames(3)
	# Le parcours du navigateur (docs/web.md) : tout droit, puis E devant le panneau.
	hold_toward(player.aim_direction())
	var shown: bool = await wait_until(
		func() -> bool: return player.current_prompt() == "Sonner la cloche de veille", 6.0
	)
	release_move()
	assert_true(shown, "tout droit jusqu'au panneau de l'arène")
	await press(&"interact")
	assert_true(director.is_running(), "E lance la série")


func test_unknown_zone_is_ignored() -> void:
	await start_game()
	var shortcuts := TestShortcuts.new()
	shortcuts.parameters = {"zone": "nulle_part"}
	game.add_child(shortcuts)
	await wait_physics_frames(3)
	assert_eq(WorldManager.current_zone(), &"village", "zone inconnue : rien ne bouge")


func test_face_turns_the_player_and_the_camera_toward_a_npc() -> void:
	# (Acte 1) window.wordendFace du script du navigateur : face(id) ou face_point(x, z).
	await start_game()
	var shortcuts := TestShortcuts.new()
	shortcuts.parameters = {"trace": ""}
	game.add_child(shortcuts)
	await wait_physics_frames(2)
	var nygglatho := game.get_node(^"World/ile_ancienne/Zones/village/NPCs/Nygglatho") as Node3D
	assert_true(shortcuts.face(&"nygglatho"), "Nygglatho, sous le porche")
	var toward := nygglatho.global_position - player.global_position
	toward.y = 0.0
	assert_gt(player.aim_direction().dot(toward.normalized()), 0.99, "tourné vers elle")
	assert_true(shortcuts.face_point(0.0, -40.0), "vers les bois")
	var north := Vector3(0.0, 0.0, -40.0) - player.global_position
	north.y = 0.0
	assert_gt(player.aim_direction().dot(north.normalized()), 0.99, "au nord")
	assert_false(shortcuts.face(&"inconnu"), "PNJ inconnu : rien")
	assert_false(shortcuts.face(&"willem_stars"), "PNJ absent (visible_if) : rien")
