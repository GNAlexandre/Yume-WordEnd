extends "res://tests/stubs/m2_game_test.gd"
## Intégration M2, parcours 4 : reprise d'une partie dans le vrai main.tscn. Une partie avance
## (drapeau posé, objet unique ramassé en marchant dessus, 6 PV max, une autre carte), le joueur se
## promène : SaveManager écrit sa position toutes les checkpoint_interval s de jeu s'il a bougé,
## rien s'il reste immobile, et tout de suite quand la fenêtre perd le focus. « Fermeture de
## l'onglet » simulée (partie libérée sans rien écrire de plus, GameState remis à zéro, nouveau
## main.tscn) : « Continuer » restaure carte, position, nom de la carte annoncé, skin, inventaire,
## drapeaux, objets déjà pris et PV max. (F1) Zone, quêtes et record d'arène sont partis avec
## l'ancienne île.
## main.show_menu() ferme aussi proprement le suivi de la partie. Acte 1 : Chtholly est le seul
## skin jouable ; le skin choisi vient d'un dossier de skins de test (Chtholly et une fée faite
## du visuel d'Ithea).

const TEST_SKINS_DIR := "user://test_m2_resume_skins"
const PICKUP_SCENE := preload("res://src/items/pickup.tscn")
## La partie se reprend dans le rez-de-chaussée d'essai (pas sur la carte de départ).
const RDC := &"entrepot_rdc_essai"
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


## La partie a avancé : un drapeau, 6 PV max, le rez-de-chaussée d'essai, et un objet unique
## (essai_bougie_1, posé devant le joueur) ramassé à pied.
func _make_progress() -> void:
	GameState.set_flag(&"met_willem")
	GameState.max_hp = 6
	await WorldManager.go_to(RDC)
	await until(func() -> bool: return not WorldManager.is_transitioning(), 10.0)
	await place_player(Vector3(19.0, 0.0, 19.0), Vector3.FORWARD)
	var pickup := PICKUP_SCENE.instantiate() as Pickup
	pickup.name = "essai_bougie_1"
	pickup.item_id = &"candle"
	current_map().add_child(pickup)
	pickup.global_position = player.global_position + Vector3(0.0, 0.0, -1.5)
	var picked: bool = await walk_keys_until(
		[KEY_W], func() -> bool: return GameState.is_pickup_collected(&"essai_bougie_1"), 3.0
	)
	assert_true(picked, "objet ramassé en marchant dessus")
	var written: bool = await until(
		func() -> bool: return _saved().get("collected_pickups", []).has("essai_bougie_1"), 3.0
	)
	assert_true(written, "auto-sauvegarde après le ramassage")


func test_walking_is_saved_and_continue_restores_everything() -> void:
	SaveManager.checkpoint_interval = 1.0
	assert_true(await new_game_from_menu(&"ithea"), "nouvelle partie")
	await _make_progress()
	# Promenade vers le couloir, au nord, sans aucun signal d'auto-sauvegarde.
	player.set_aim_direction(Vector3.FORWARD, true)
	await hold_aim(1.0)
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
	assert_eq(GameState.count(&"candle"), 0, "GameState vide après la fermeture")
	await open_main()
	await click_center()
	assert_true(menu_button("ContinueButton").visible, "Continuer")
	await click(menu_button("ContinueButton"))
	assert_true(await wait_for_game(), "partie reprise")
	assert_eq(WorldManager.current_map(), RDC, "carte restaurée")
	assert_lt(flat_distance(player.global_position, left_at), 0.3, "position restaurée")
	assert_true(
		await until(func() -> bool: return map_banner() == current_map().display_name, 3.0),
		"nom de la carte à la reprise"
	)
	assert_eq(GameState.skin_id, &"ithea", "skin gardé")
	assert_eq(player.visual.skin.id, &"ithea")
	assert_eq(GameState.count(&"candle"), 1, "inventaire restauré")
	assert_true(GameState.has_flag(&"met_willem"), "drapeau restauré")
	assert_true(GameState.is_pickup_collected(&"essai_bougie_1"), "objet déjà pris retenu")
	assert_eq(GameState.max_hp, 6, "PV max restaurés")
	assert_eq(health.max_hp, 6, "le joueur a 6 PV max")
	assert_eq(hearts_shown(), 6)


func test_show_menu_closes_the_tracked_game() -> void:
	assert_true(await new_game_from_menu(), "nouvelle partie")
	await until(
		func() -> bool: return SaveManager.has_save() and not SaveManager.is_autosave_pending(), 3.0
	)
	await place_player(Vector3(26.0, 0.0, 20.0), Vector3.FORWARD)
	var at := player.global_position
	main.call(&"show_menu")
	assert_false(SaveManager.is_game_loaded(), "plus de partie suivie")
	assert_lt(_saved_position().distance_to(at), 0.1, "la partie quittée est écrite")
	await wait_process_frames(2)
	assert_not_null(menu(), "menu affiché")
	assert_null(main.call(&"game"), "partie libérée")
	var text := _file_text()
	EventBus.item_collected.emit(&"candle", 1)
	EventBus.map_entered.emit(&"essai")
	assert_false(SaveManager.is_autosave_pending(), "rien n'est demandé au menu")
	await wait_seconds(1.0)
	assert_eq(_file_text(), text, "aucune auto-sauvegarde après le retour au menu")
