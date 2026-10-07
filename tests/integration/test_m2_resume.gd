extends "res://tests/stubs/m2_game_test.gd"
## Intégration M2, parcours 4 : reprise d'une partie dans le vrai main.tscn. Une partie avance
## (livre d'images accepté, page ramassée en marchant dessus, record d'arène, 6 PV max), le
## joueur se promène : SaveManager écrit sa position toutes les checkpoint_interval s de jeu s'il
## a bougé, rien s'il reste immobile, et tout de suite quand la fenêtre perd le focus.
## « Fermeture de l'onglet » simulée (partie libérée sans rien écrire de plus, GameState remis à
## zéro, nouveau main.tscn) : « Continuer » restaure position, zone, skin, inventaire, quêtes (et
## la quête principale de l'acte 1), objets déjà pris (absents), PV max et meilleur score.
## main.show_menu() ferme aussi proprement le suivi de la partie. Acte 1 : Chtholly est le seul
## skin jouable ; le skin choisi vient d'un dossier de skins de test (Chtholly et une fée faite
## du visuel d'Ithea).

const TEST_SKINS_DIR := "user://test_m2_resume_skins"
const TEST_SKINS: Array[String] = [
	"res://data/skins/chtholly.tres", "res://data/npcs/visuals/ithea.tres"
]


func before_each() -> void:
	super()
	DirAccess.make_dir_recursive_absolute(TEST_SKINS_DIR)
	for path: String in TEST_SKINS:
		assert_eq(ResourceSaver.save(load(path), TEST_SKINS_DIR.path_join(path.get_file())), OK)
	SkinRegistry.skins_dir = TEST_SKINS_DIR
	SkinRegistry.reload()


func after_each() -> void:
	super()
	SkinRegistry.skins_dir = SkinRegistry.SKINS_DIR
	SkinRegistry.reload()
	for path: String in TEST_SKINS:
		DirAccess.remove_absolute(TEST_SKINS_DIR.path_join(path.get_file()))
	DirAccess.remove_absolute(TEST_SKINS_DIR)


## Contenu de la sauvegarde de test ({} si absente ou illisible).
func _saved() -> Dictionary:
	if not FileAccess.file_exists(SaveManager.save_path):
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SaveManager.save_path))
	return data if data is Dictionary else {}


func _saved_position() -> Vector3:
	var p: Array = _saved().get("position", [0.0, 0.0, 0.0])
	return Vector3(float(p[0]), float(p[1]), float(p[2]))


func _file_text() -> String:
	return FileAccess.get_file_as_string(SaveManager.save_path)


## La partie a avancé : livre d'images accepté, forest_page_1 ramassée à pied, un record aux
## dunes, 6 PV max.
func _make_progress() -> void:
	GameState.set_flag(&"met_willem")
	GameState.set_quest_state(&"picture_book", &"active")
	GameState.record_score(&"dunes", 240, 4)
	GameState.max_hp = 6
	var page := zone(&"forest").get_node(^"Pickups/forest_page_1") as Node3D
	await place_player(&"forest", Vector3(-3.0, 0.0, 4.5), Vector3.FORWARD)
	for timere: Node in zone(&"forest").get_node(^"Enemies").get_children():
		timere.set_physics_process(false)
	var picked: bool = await walk_keys_until(
		[KEY_W], func() -> bool: return GameState.is_pickup_collected(&"forest_page_1"), 3.0
	)
	assert_true(picked, "page ramassée en marchant dessus")
	assert_false(is_instance_valid(page) and not page.is_queued_for_deletion(), "page disparue")
	var written: bool = await until(
		func() -> bool: return _saved().get("collected_pickups", []).has("forest_page_1"), 3.0
	)
	assert_true(written, "auto-sauvegarde après le ramassage")


func test_walking_is_saved_and_continue_restores_everything() -> void:
	SaveManager.checkpoint_interval = 1.0
	assert_true(await new_game_from_menu(&"ithea"), "nouvelle partie")
	await _make_progress()
	# Promenade vers le sud-est de la forêt, sans aucun signal d'auto-sauvegarde.
	player.set_aim_direction(Vector3(1.0, 0.0, 1.0), true)
	await hold_aim(1.2)
	var walked_to := player.global_position
	var checkpointed: bool = await until(
		func() -> bool: return _saved_position().distance_to(walked_to) < 0.2, 2.5
	)
	assert_true(checkpointed, "position écrite pendant la promenade")
	# Immobile : plus rien n'est écrit.
	var text := _file_text()
	await wait_seconds(2.5)
	assert_eq(_file_text(), text, "joueur immobile : aucune écriture")
	# Quelques pas, puis la fenêtre perd le focus (onglet quitté) : écrit tout de suite.
	SaveManager.checkpoint_interval = 60.0
	await hold_aim(0.4)
	var left_at := player.global_position
	assert_gt(_saved_position().distance_to(left_at), 0.5, "pas encore écrit")
	get_tree().root.propagate_notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	assert_lt(_saved_position().distance_to(left_at), 0.1, "écrit à la perte du focus")
	text = _file_text()
	get_tree().root.propagate_notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	assert_eq(_file_text(), text, "focus perdu sans changement : rien de plus")
	# « Fermeture de l'onglet », puis retour : Continuer.
	await close_tab()
	assert_eq(GameState.count(&"page_fragment"), 0, "GameState vide après la fermeture")
	await open_main()
	await click_center()
	assert_true(menu_button("ContinueButton").visible, "Continuer")
	await click(menu_button("ContinueButton"))
	assert_true(await wait_for_game(), "partie reprise")
	assert_lt(flat_distance(player.global_position, left_at), 0.3, "position restaurée")
	assert_eq(WorldManager.current_zone(), &"forest", "zone restaurée")
	assert_eq(
		zone_banner(), WorldManager.zone_display_name(&"forest"), "nom de la zone à la reprise"
	)
	assert_eq(GameState.skin_id, &"ithea", "skin gardé")
	assert_eq(player.visual.skin.id, &"ithea")
	assert_eq(GameState.count(&"page_fragment"), 1, "inventaire restauré")
	assert_eq(GameState.quest_state(&"picture_book"), &"active", "quête restaurée")
	assert_eq(GameState.quest_state(&"act1_main"), &"active", "quête principale restaurée")
	assert_eq(GameState.quest_step(&"act1_main"), &"morning", "à son étape")
	assert_eq(GameState.best_score(&"dunes"), 240, "meilleur score restauré")
	assert_null(
		zone(&"forest").get_node_or_null(^"Pickups/forest_page_1"), "page déjà prise : absente"
	)
	assert_not_null(zone(&"forest").get_node_or_null(^"Pickups/forest_page_2"), "les autres là")
	await wait_process_frames(2)
	assert_eq(
		hud.call(&"quest_objective", &"picture_book"),
		"Rapporter 5 pages du livre d’images à Nephren",
		"objectif de la quête dans le HUD"
	)
	assert_eq(GameState.max_hp, 6, "PV max restaurés")
	assert_eq(health.max_hp, 6, "le joueur a 6 PV max")
	assert_eq(hearts_shown(), 6)


func test_show_menu_closes_the_tracked_game() -> void:
	assert_true(await new_game_from_menu(), "nouvelle partie")
	await until(
		func() -> bool: return SaveManager.has_save() and not SaveManager.is_autosave_pending(), 3.0
	)
	await place_player(&"village", Vector3(6.0, 0.0, 6.0), Vector3.FORWARD)
	var at := player.global_position
	main.call(&"show_menu")
	assert_false(SaveManager.is_game_loaded(), "plus de partie suivie")
	assert_lt(_saved_position().distance_to(at), 0.1, "la partie quittée est écrite")
	await wait_process_frames(2)
	assert_not_null(menu(), "menu affiché")
	assert_null(main.call(&"game"), "partie libérée")
	var text := _file_text()
	EventBus.item_collected.emit(&"page_fragment", 1)
	EventBus.zone_entered.emit(&"beach")
	assert_false(SaveManager.is_autosave_pending(), "rien n'est demandé au menu")
	await wait_seconds(1.0)
	assert_eq(_file_text(), text, "aucune auto-sauvegarde après le retour au menu")
	EventBus.zone_entered.emit(&"village")
