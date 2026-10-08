extends "res://tests/stubs/l10_ui_test.gd"
## (Systèmes et textes) Le menu et l'histoire (MONDE.md, section 1.2) : le joueur incarne la fée
## qui porte Seniorious, Chtholly par défaut ; sous les vignettes des skins, le menu le dit : « Ta
## fée prend la place de Chtholly dans l'histoire. » (Acte 1, intégration) Le panneau tient dans
## l'écran quel que soit le nombre de skins : la grille défile (souris, clavier, manette) et montre
## la vignette choisie.

const MENU := preload("res://src/ui/main_menu.tscn")
const HINT := "Ta fée prend la place de Chtholly dans l'histoire."
## (HD-2D) Les skins de la grille pleine : Chtholly et sept fées de test au nom long, depuis que
## les sept modèles 3D de la PR n° 1 sont retirés (le jeu n'a plus assez de skins pour remplir
## deux rangées et demie).
const MANY_SKINS_DIR := "user://menu_story_skins"
const MANY_SKINS := 8


func after_each() -> void:
	super.after_each()
	if SkinRegistry.skins_dir != SkinRegistry.SKINS_DIR:
		SkinRegistry.skins_dir = SkinRegistry.SKINS_DIR
		SkinRegistry.reload()
	for file_name: String in DirAccess.get_files_at(MANY_SKINS_DIR):
		DirAccess.remove_absolute(MANY_SKINS_DIR.path_join(file_name))
	DirAccess.remove_absolute(MANY_SKINS_DIR)


## Remplit le registre de MANY_SKINS skins (Chtholly d'abord, puis des fées au nom long, avec la
## planche de Chtholly), le temps d'un test.
func _fill_registry() -> void:
	DirAccess.make_dir_recursive_absolute(MANY_SKINS_DIR)
	var chtholly := load("res://data/skins/chtholly.tres") as SkinData
	for i in MANY_SKINS:
		var skin := chtholly.duplicate() as SkinData
		if i > 0:
			skin.id = StringName("fairy_test_%d" % i)
			skin.display_name = "Fée de la communauté n° %d Nota Aurea Longissima" % i
		assert_eq(ResourceSaver.save(skin, MANY_SKINS_DIR.path_join("%s.tres" % skin.id)), OK)
	SkinRegistry.skins_dir = MANY_SKINS_DIR
	SkinRegistry.reload()


func _menu() -> MenuScript:
	var menu: MenuScript = MENU.instantiate()
	menu.require_gesture = false
	return add_child_autofree(menu)


func test_hint_under_the_skin_cards_says_whose_place_the_fairy_takes() -> void:
	var menu := _menu()
	await wait_process_frames(2)
	var grid := menu.get_node(^"%SkinGrid") as Control
	# (Acte 1, intégration) Les vignettes défilent dans leur cadre (%SkinScroll).
	var cards := menu.get_node(^"%SkinScroll") as ScrollContainer
	var hint := menu.get_node(^"%SkinHint") as Label
	assert_eq(hint.text, HINT)
	assert_true(hint.is_visible_in_tree(), "visible avec le menu")
	assert_eq(grid.get_parent(), cards, "la grille dans son cadre défilant")
	assert_eq(hint.get_parent(), cards.get_parent(), "dans le panneau des vignettes")
	assert_eq(hint.get_index(), cards.get_index() + 1, "juste sous les vignettes")
	assert_gt(hint.global_position.y, cards.global_position.y + cards.size.y - 1.0, "en dessous")
	var title := cards.get_parent().get_child(0) as Label
	assert_eq(title.text, "Choisis ta fée", "les skins jouables sont des fées")
	assert_ne(hint.autowrap_mode, TextServer.AUTOWRAP_OFF, "la phrase se replie sous les vignettes")
	assert_lt(hint.size.x, cards.size.x + 1.0, "pas plus large que les vignettes")


func test_skin_panel_fits_the_screen_whatever_the_number_of_skins() -> void:
	# (Acte 1, intégration) Avec les sept skins « · 3D » de la PR n° 1 (huit vignettes, quatre
	# rangées), le panneau débordait de l'écran de 1280 × 720 : titre et phrase hors champ, noms
	# plus larges que leur vignette. La grille défile au-delà de deux rangées et demie.
	_fill_registry()
	var menu := _menu()
	await wait_process_frames(3)
	assert_gt(SkinRegistry.all().size(), 4, "plus de vignettes que deux rangées")
	var cards := menu.get_node(^"%SkinScroll") as ScrollContainer
	var panel := cards.get_parent().get_parent() as Control
	var content := menu.get_node(^"%Content") as MarginContainer
	var screen_height := float(ProjectSettings.get_setting("display/window/size/viewport_height"))
	var room := (
		screen_height
		- content.get_theme_constant(&"margin_top")
		- content.get_theme_constant(&"margin_bottom")
	)
	assert_lte(panel.get_combined_minimum_size().y, room, "le panneau tient dans 1280 × 720")
	assert_lte(cards.size.y, MenuScript.MAX_SKIN_GRID_HEIGHT + 0.5, "deux rangées et demie")
	var grid := menu.get_node(^"%SkinGrid") as Control
	assert_gt(grid.size.y, cards.size.y, "le reste en défilant")
	for skin: SkinData in SkinRegistry.all():
		var card := menu.skin_card(skin.id)
		var label := card.get_node(^"Box/Name") as Label
		assert_eq(label.text, skin.display_name, "%s : nom entier (infobulle aussi)" % skin.id)
		assert_eq(card.tooltip_text, skin.display_name)
		assert_true(
			card.get_global_rect().grow(0.5).encloses(label.get_global_rect()),
			"%s : nom dans sa vignette" % skin.id
		)


func test_selected_skin_down_the_grid_is_scrolled_into_view() -> void:
	_fill_registry()
	var last := SkinRegistry.all().back() as SkinData
	write_valid_save(last.id)
	var menu := _menu()
	await wait_process_frames(3)
	assert_eq(menu.selected_skin(), last.id, "skin de la sauvegarde")
	var cards := menu.get_node(^"%SkinScroll") as ScrollContainer
	assert_gt(cards.scroll_vertical, 0, "la grille a défilé")
	assert_true(
		cards.get_global_rect().grow(0.5).encloses(menu.skin_card(last.id).get_global_rect()),
		"la vignette choisie est en vue"
	)


func test_focus_scrolls_the_grid_for_keyboard_and_gamepad() -> void:
	_fill_registry()
	var menu := _menu()
	await wait_process_frames(3)
	var cards := menu.get_node(^"%SkinScroll") as ScrollContainer
	assert_eq(cards.scroll_vertical, 0, "Chtholly, en haut")
	var last := menu.skin_card((SkinRegistry.all().back() as SkinData).id)
	last.grab_focus()
	await wait_process_frames(3)
	assert_true(cards.get_global_rect().grow(0.5).encloses(last.get_global_rect()), "en bas")
	menu.skin_card(&"chtholly").grab_focus()
	await wait_process_frames(3)
	assert_eq(cards.scroll_vertical, 0, "et retour en haut")


func test_hint_stays_whatever_skin_is_chosen() -> void:
	var menu := _menu()
	var hint := menu.get_node(^"%SkinHint") as Label
	for skin: SkinData in SkinRegistry.all():
		menu.select_skin(skin.id, true)
		assert_eq(hint.text, HINT, "%s : même phrase" % skin.display_name)
		assert_true(hint.is_visible_in_tree())
