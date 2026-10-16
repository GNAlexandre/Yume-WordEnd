extends "res://tests/stubs/m1_game_test.gd"
## Intégration M1, raccourcis de test (src/test_shortcuts.gd) : lecture des paramètres de
## l'adresse Web ou de la ligne de commande, aucun effet sans paramètre, carte de départ et banc
## de Timeres qui errent sans poursuivre le joueur (seulement là où les règles de l'île les
## admettent : la surface). (F1) Le raccourci zone (et l'arène des dunes) est parti avec
## l'ancienne île : il est ignoré.

const TestShortcuts := preload("res://src/test_shortcuts.gd")
const NPC_SCENE := preload("res://src/npc/npc.tscn")
const SURFACE := &"surface_essai"


func test_parameters_come_from_the_query_or_the_command_line() -> void:
	assert_eq_deep(
		TestShortcuts.parse_query("?map=surface_essai&timeres=12&autre=1"),
		{"map": "surface_essai", "timeres": "12"}
	)
	assert_eq_deep(TestShortcuts.parse_query(""), {})
	assert_eq_deep(TestShortcuts.parse_query("?"), {})
	assert_eq(TestShortcuts.parse_query("?zone=dunes"), {}, "(F1) plus de raccourci zone")
	assert_eq_deep(TestShortcuts.parse_query("?marker=for%C3%AAt"), {"marker": "forêt"})
	assert_eq_deep(
		TestShortcuts.parse_arguments(
			["res://scene.tscn", "--map=essai", "--timeres=4", "--zone=forest", "-x"]
		),
		{"map": "essai", "timeres": "4"}
	)
	assert_true(TestShortcuts.read_parameters().is_empty(), "tests sans paramètre")


func test_no_shortcut_without_parameters() -> void:
	await start_game()
	assert_null(game.get_node_or_null(^"TestShortcuts"), "partie normale : aucun raccourci")
	assert_eq(WorldManager.current_map(), start_map_for_test())


func test_map_and_bench_shortcuts_on_the_surface() -> void:
	await start_game()
	var shortcuts := TestShortcuts.new()
	shortcuts.parameters = {"map": String(SURFACE), "timeres": "8"}
	game.add_child(shortcuts)
	await wait_physics_frames(3)
	assert_eq(WorldManager.current_map(), SURFACE, "posé sur la surface")
	var spawn := current_map().spawn()
	assert_lt(flat_distance(player.global_position, spawn.global_position), 0.5, "à son Spawn")
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
		if not is_instance_valid(enemy):
			continue
		assert_eq(enemy.state(), &"idle", "%s erre sans poursuivre" % enemy.name)
		assert_lt(flat_distance(enemy.global_position, ahead_center), 10.5, "devant le joueur")
	assert_eq(health.current, 5, "le banc n'attaque pas")


func test_no_bench_where_the_island_refuses_timeres() -> void:
	await start_game()
	var shortcuts := TestShortcuts.new()
	shortcuts.parameters = {"timeres": "4"}
	game.add_child(shortcuts)
	await wait_physics_frames(3)
	assert_eq(get_tree().get_nodes_in_group(&"enemies").size(), 0, "l'île n° 68 : aucun Timere")


func test_unknown_map_is_ignored() -> void:
	await start_game()
	var shortcuts := TestShortcuts.new()
	shortcuts.parameters = {"map": "nulle_part", "zone": "dunes"}
	game.add_child(shortcuts)
	await wait_physics_frames(3)
	assert_eq(WorldManager.current_map(), start_map_for_test(), "carte inconnue : rien ne bouge")


func test_face_turns_the_player_and_the_camera_toward_a_npc() -> void:
	# (Acte 1) window.wordendFace du script du navigateur : face(id) ou face_point(x, z).
	await start_game()
	var shortcuts := TestShortcuts.new()
	shortcuts.parameters = {"trace": ""}
	game.add_child(shortcuts)
	await wait_physics_frames(2)
	var nygglatho := NPC_SCENE.instantiate() as Npc
	nygglatho.data = DialogueRunner.find_npc(&"nygglatho")
	current_map().add_child(nygglatho)
	nygglatho.global_position = player.global_position + Vector3(4.0, 0.0, -3.0)
	var absent := NPC_SCENE.instantiate() as Npc
	absent.data = NpcData.new()
	absent.data.id = &"absent_test"
	absent.data.visible_if = {"flag": "jamais_pose"}
	current_map().add_child(absent)
	absent.global_position = player.global_position + Vector3(-4.0, 0.0, -3.0)
	await wait_physics_frames(2)
	assert_true(shortcuts.face(&"nygglatho"), "Nygglatho")
	var toward := nygglatho.global_position - player.global_position
	toward.y = 0.0
	assert_gt(player.aim_direction().dot(toward.normalized()), 0.99, "tourné vers elle")
	var target := player.global_position + Vector3(0.0, 0.0, -10.0)
	assert_true(shortcuts.face_point(target.x, target.z), "un point au nord")
	var north := target - player.global_position
	north.y = 0.0
	assert_gt(player.aim_direction().dot(north.normalized()), 0.99, "au nord")
	assert_false(shortcuts.face(&"inconnu"), "PNJ inconnu : rien")
	assert_false(shortcuts.face(&"absent_test"), "PNJ absent (visible_if) : rien")
