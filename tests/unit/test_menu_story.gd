extends "res://tests/stubs/l10_ui_test.gd"
## (Systèmes et textes) Le menu et l'histoire (MONDE.md, section 1.2) : le joueur incarne la fée
## qui porte Seniorious, Chtholly par défaut ; sous les vignettes des skins, le menu le dit : « Ta
## fée prend la place de Chtholly dans l'histoire. »

const MENU := preload("res://src/ui/main_menu.tscn")
const HINT := "Ta fée prend la place de Chtholly dans l'histoire."


func _menu() -> MenuScript:
	var menu: MenuScript = MENU.instantiate()
	menu.require_gesture = false
	return add_child_autofree(menu)


func test_hint_under_the_skin_cards_says_whose_place_the_fairy_takes() -> void:
	var menu := _menu()
	await wait_process_frames(2)
	var grid := menu.get_node(^"%SkinGrid") as Control
	var hint := menu.get_node(^"%SkinHint") as Label
	assert_eq(hint.text, HINT)
	assert_true(hint.is_visible_in_tree(), "visible avec le menu")
	assert_eq(hint.get_parent(), grid.get_parent(), "dans le panneau des vignettes")
	assert_eq(hint.get_index(), grid.get_index() + 1, "juste sous les vignettes")
	assert_gt(hint.global_position.y, grid.global_position.y + grid.size.y - 1.0, "en dessous")
	var title := grid.get_parent().get_child(0) as Label
	assert_eq(title.text, "Choisis ta fée", "les skins jouables sont des fées")
	assert_ne(hint.autowrap_mode, TextServer.AUTOWRAP_OFF, "la phrase se replie sous les vignettes")
	assert_lt(hint.size.x, grid.size.x + 1.0, "pas plus large que les vignettes")


func test_hint_stays_whatever_skin_is_chosen() -> void:
	var menu := _menu()
	var hint := menu.get_node(^"%SkinHint") as Label
	for skin: SkinData in SkinRegistry.all():
		menu.select_skin(skin.id, true)
		assert_eq(hint.text, HINT, "%s : même phrase" % skin.display_name)
		assert_true(hint.is_visible_in_tree())
