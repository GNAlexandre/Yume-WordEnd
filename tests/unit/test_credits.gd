extends "res://tests/stubs/l10_ui_test.gd"
## Crédits (L10) : texte de la scène (assets/CREDITS.md, assets/characters/CREDITS.md, hommage à
## SukaSuka), licence du moteur, défilement, retour (bouton, Échap, B). (Systèmes et textes)
## Seniorious et Timere (graphies de la traduction), titre de la traduction française de Yume
## Novel, hommage non commercial, fiches de lecture et bible faites à partir de la traduction.

const CREDITS := preload("res://src/ui/credits.tscn")
const CreditsScript := preload("res://src/ui/credits.gd")
const NBSP := " "


func _credits() -> CreditsScript:
	return add_child_autofree(CREDITS.instantiate())


func test_text_has_credits_homage_and_engine_license() -> void:
	var credits := _credits()
	var text := credits.full_text()
	for expected: String in [
		"SukaSuka",
		"Chtholly",
		"Seniorious",
		"Timere",
		"Akira Kareno",
		"Gemini",
		"decouper-planche.py",
		"gen_placeholders.py",
		"gen_item_icons.py",
		"gen_ui_icons.py",
		"Scarborough Fair",
		"Godot Engine",
	]:
		assert_string_contains(text, expected)
	assert_string_contains(text, Engine.get_license_text(), "licence du moteur")


func test_homage_names_the_french_translation() -> void:
	var text := _credits().full_text()
	var title := (
		"Que faites-vous à la fin du monde%s? Êtes-vous occupés%s? Voulez-vous bien nous sauver%s?"
		% [NBSP, NBSP, NBSP]
	)
	assert_string_contains(text, title, "titre de la traduction française")
	for expected: String in [
		"traduction française de Yume Novel",
		"hommage de fans, gratuit et non commercial",
		"fiches de lecture et la bible",
		"à partir de la traduction de Yume Novel",
	]:
		assert_string_contains(text, expected)


func test_sword_and_beast_use_the_translation_spelling() -> void:
	var text := _credits().full_text()
	assert_false(text.contains("Seniolis"), "Seniorious, jamais Seniolis")
	assert_string_contains(text, "son épée Seniorious")
	assert_false(text.contains("les Timeres viennent"), "Timere, la Bête, au singulier")


func test_scrolls_with_arrows() -> void:
	var credits := _credits()
	await wait_process_frames(3)
	var scroll := credits.get_node("%Scroll") as ScrollContainer
	assert_gt(scroll.get_v_scroll_bar().max_value, scroll.size.y, "texte plus long que l'écran")
	push_action(&"ui_down")
	assert_gt(scroll.scroll_vertical, 0, "bas : défile")
	push_action(&"ui_up")
	assert_eq(scroll.scroll_vertical, 0, "haut : remonte")


func test_back_button_escape_and_b_emit_closed() -> void:
	var credits := _credits()
	watch_signals(credits)
	(credits.get_node("%BackButton") as Button).pressed.emit()
	assert_signal_emit_count(credits, "closed", 1, "Retour")
	push_action(&"ui_cancel")
	assert_signal_emit_count(credits, "closed", 2, "Échap")
	tap_joy(JOY_BUTTON_B)
	assert_signal_emit_count(credits, "closed", 3, "B")
