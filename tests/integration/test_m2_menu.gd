extends "res://tests/stubs/m2_game_test.gd"
## Intégration M2, parcours 1 dans le vrai src/main.tscn : « Cliquer pour jouer » → choix du skin
## → Nouvelle partie → écran de chargement dont la barre avance vraiment (plusieurs images, sans
## fil d'exécution) → joueur au Spawn de la carte de départ, cinq cœurs et le nom de la carte
## annoncé. À la souris, puis à la manette seule (geste, croix, A) ; Continuer n'apparaît qu'avec
## une sauvegarde. (Systèmes et textes) Sous les vignettes, « Ta fée prend la place de Chtholly
## dans l'histoire. » ; le PNJ qui a le skin choisi est absent (la fée choisie est le joueur).
## Noms des cartes et skins lus dans le jeu, pas figés ici. Le choix se fait dans un dossier de
## skins de test (Chtholly et une fée faite du visuel de Nephren). (F1) La carte de départ des
## tests est la carte d'essai : l'ancienne île et son village sont partis.

const TEST_SKINS_DIR := "user://test_m2_menu_skins"
const TEST_SKINS: Array[String] = [
	"res://data/skins/chtholly.tres", "res://data/npcs/visuals/nephren.tres"
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


func _focus_owner() -> Control:
	return get_viewport().gui_get_focus_owner()


## Vignette choisie à la souris : le dernier skin du menu (Chtholly s'il est seul).
func _last_skin() -> StringName:
	var skins := SkinRegistry.all()
	return skins.back().id if not skins.is_empty() else &"chtholly"


func _assert_started_at_the_spawn(skin_id: StringName) -> void:
	assert_null(menu(), "menu libéré")
	assert_null(main.call(&"loading_screen"), "écran de chargement libéré")
	assert_eq(WorldManager.current_map(), start_map_for_test(), "carte de départ")
	assert_lt(distance_to(current_map().spawn()), 1.0, "joueur au Spawn")
	assert_true(
		await until(func() -> bool: return map_banner() == current_map().display_name, 3.0),
		"nom de la carte annoncé"
	)
	assert_eq(hearts_shown(), 5, "cinq cœurs")
	assert_eq(hud.call(&"health"), Vector2i(5, 5), "cœurs pleins")
	assert_eq(GameState.skin_id, skin_id, "skin choisi")
	assert_eq(player.visual.skin.id, skin_id, "le personnage a le skin choisi")
	assert_true(SaveManager.is_game_loaded(), "partie suivie par SaveManager")
	for npc_id: StringName in [&"nephren", &"nygglatho"]:
		var npc := DialogueRunner.find_npc(npc_id)
		var same_skin := npc.skin != null and npc.skin.id == skin_id
		assert_eq(
			npc.is_present(), not same_skin, "%s : présent sauf s'il a le skin choisi" % npc_id
		)


func test_new_game_from_the_menu_with_the_mouse() -> void:
	var title := await open_main()
	assert_true(title.call(&"is_waiting_for_gesture"), "« Cliquer pour jouer » d'abord")
	assert_false(menu_button("NewGameButton").is_visible_in_tree(), "menu caché avant le geste")
	await click_center()
	assert_false(title.call(&"is_waiting_for_gesture"), "le clic ouvre le menu")
	assert_false(menu_button("ContinueButton").visible, "pas de sauvegarde : pas de Continuer")
	assert_true(menu_button("NewGameButton").is_visible_in_tree())
	var hint := title.get_node("%SkinHint") as Label
	assert_true(hint.is_visible_in_tree(), "la phrase sous les vignettes")
	assert_eq(hint.text, "Ta fée prend la place de Chtholly dans l'histoire.")
	var chosen := _last_skin()
	await click(title.call(&"skin_card", chosen) as Control)
	assert_eq(title.call(&"selected_skin"), chosen, "vignette choisie au clic")
	# Barre du chargement : une dépendance par image (tout est déjà en cache sous GUT).
	main.set(&"loading_budget_ms", 0.0)
	var progress: Array[float] = []
	var record := func(ratio: float) -> void: progress.append(ratio)
	listen(
		EventBus.game_loaded,
		func() -> void:
			var screen: Node = main.call(&"loading_screen")
			if screen != null:
				screen.connect(&"progress_changed", record)
	)
	await click(menu_button("NewGameButton"))
	assert_true(await wait_for_game(), "la partie se charge")
	var steps := progress.filter(func(ratio: float) -> bool: return ratio > 0.0 and ratio < 1.0)
	assert_gt(steps.size(), 10, "la barre avance par étapes (%d)" % steps.size())
	assert_eq(progress.back(), 1.0, "puis se remplit")
	var sorted := progress.duplicate()
	sorted.sort()
	assert_eq(progress, sorted, "sans jamais reculer")
	await _assert_started_at_the_spawn(chosen)


func test_new_game_from_the_menu_with_a_gamepad_only() -> void:
	watch_signals(EventBus)
	var title := await open_main()
	await tap_joy(JOY_BUTTON_A)
	assert_false(title.call(&"is_waiting_for_gesture"), "un bouton de manette ouvre le menu")
	assert_signal_not_emitted(EventBus, "game_loaded", "le geste ne lance rien")
	assert_eq(_focus_owner(), menu_button("NewGameButton"), "focus sur Nouvelle partie")
	# Croix à droite : les vignettes ; A choisit celle qui a le focus.
	await tap_joy(JOY_BUTTON_DPAD_RIGHT)
	var card := _focus_owner() as Button
	assert_true(card != null and card.name.begins_with("Skin_"), "focus sur une vignette")
	if card == null:
		return
	var skin_id := StringName(card.name.trim_prefix("Skin_"))
	await tap_joy(JOY_BUTTON_A)
	assert_eq(title.call(&"selected_skin"), skin_id, "A choisit la vignette")
	# Stick à gauche : retour à la colonne des boutons ; croix en haut jusqu'à Nouvelle partie.
	stick(-1.0, 0.0)
	await wait_physics_frames(2)
	stick(0.0, 0.0)
	await wait_physics_frames(2)
	assert_true(
		(
			menu().get_node("%Content").is_ancestor_of(_focus_owner())
			and _focus_owner().get_parent().name == "Buttons"
		),
		"stick : retour aux boutons"
	)
	for _step in 3:
		if _focus_owner() != menu_button("NewGameButton"):
			await tap_joy(JOY_BUTTON_DPAD_UP)
	assert_eq(_focus_owner(), menu_button("NewGameButton"), "croix : Nouvelle partie")
	await tap_joy(JOY_BUTTON_A)
	assert_true(await wait_for_game(), "A lance la partie")
	await _assert_started_at_the_spawn(skin_id)
	assert_false(
		player.is_on_floor() and player.velocity.y > 0.1, "l'appui de A n'a pas fait sauter"
	)


func test_trace_shortcut_only_logs() -> void:
	const TestShortcuts := preload("res://src/test_shortcuts.gd")
	assert_eq_deep(TestShortcuts.parse_query("?trace=1"), {"trace": "1"})
	assert_eq_deep(TestShortcuts.parse_query("?trace"), {"trace": ""})
	assert_true(await new_game_from_menu(), "nouvelle partie")
	var spawn := current_map().spawn()
	var shortcuts := TestShortcuts.new()
	shortcuts.parameters = {"trace": "1"}
	game.add_child(shortcuts)
	await wait_physics_frames(3)
	assert_lt(distance_to(spawn), 1.0, "trace : le joueur reste où la partie l'a mis")
	assert_eq(WorldManager.current_map(), start_map_for_test())
	assert_eq(get_tree().get_nodes_in_group(&"enemies").size(), 0, "pas de banc de Timeres")


func test_continue_appears_once_a_game_is_saved() -> void:
	assert_true(await new_game_from_menu(), "première partie")
	assert_true(
		await wait_until(func() -> bool: return SaveManager.has_save(), 3.0),
		"nouvelle partie écrite (auto-sauvegarde)"
	)
	await close_tab()
	var title := await open_main()
	await click_center()
	assert_true(menu_button("ContinueButton").visible, "sauvegarde : Continuer")
	assert_eq(_focus_owner(), menu_button("ContinueButton"), "focus sur Continuer")
	assert_true(title.is_visible_in_tree())
