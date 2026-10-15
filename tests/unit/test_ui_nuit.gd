extends GutTest
## (U1) Interface « Nuit douce » : un seul thème partout, ses polices (accents, guillemets,
## espaces fines, tirets), aucune couleur en dur dans les scènes d'interface, et les deux
## présentations de la boîte de dialogue (Nuit douce et Bandeau).

const THEME_PATH := "res://src/ui/wordend_theme.tres"
const UI_DIR := "res://src/ui/"
const DIALOGUE_BOX := preload("res://src/ui/dialogue_box.tscn")
## Scènes qui ne sont pas des écrans : la case de l'inventaire prend le thème de l'inventaire.
const NOT_SCREENS: Array[String] = ["inventory_slot.tscn"]
## (E6) Le journal de quêtes est hors du périmètre d'U1 : le lot E6 retire l'ancien encadré.
const NOT_OWNED: Array[String] = ["journal.tscn"]
## Caractères du français que les polices doivent porter.
const FRENCH := "àâäçéèêëîïôöùûüÿœæÀÂÇÉÈÊËÎÏÔÙÛŒÆ«»  –—’…·"

var _box: DialogueBox


func before_each() -> void:
	DialogueBox.set_presentation(DialogueBox.PRESENTATION_NUIT)


func after_each() -> void:
	DialogueBox.set_presentation(DialogueBox.PRESENTATION_NUIT)
	if _box != null and _box.is_open():
		EventBus.dialogue_ended.emit(&"nephren")


func _ui_scenes() -> Array[String]:
	var scenes: Array[String] = []
	for file: String in DirAccess.get_files_at(UI_DIR):
		if file.ends_with(".tscn"):
			scenes.append(file)
	return scenes


func test_every_screen_wears_the_theme() -> void:
	var theme := load(THEME_PATH) as Theme
	for file: String in _ui_scenes():
		if file in NOT_SCREENS:
			continue
		var root := (load(UI_DIR + file) as PackedScene).instantiate()
		var control := root as Control
		assert_not_null(control, "%s : un Control" % file)
		if control != null:
			assert_eq(control.theme, theme, "%s porte wordend_theme.tres" % file)
		root.free()
	assert_eq(UiStyle.THEME, theme, "UiStyle lit le même thème")


func test_no_hard_coded_color_in_ui_scenes() -> void:
	var found: Array[String] = []
	for file: String in _ui_scenes():
		if file in NOT_OWNED:
			continue
		var text := FileAccess.get_file_as_string(UI_DIR + file)
		for line: String in text.split("\n"):
			if line.contains("Color("):
				found.append("%s : %s" % [file, line.strip_edges()])
	assert_eq(found, [] as Array[String], "les couleurs vivent dans le thème")


func test_tokens_and_fonts() -> void:
	for token: StringName in [&"panel", &"gold", &"cream", &"ink", &"muted", &"error", &"black"]:
		assert_true(UiStyle.THEME.has_color(token, UiStyle.TOKENS), "couleur %s" % token)
	for token: StringName in [&"appear_ms", &"slide_px", &"breath_ms", &"heart_px"]:
		assert_gt(UiStyle.constant(token), 0, "constante %s" % token)
	assert_eq(UiStyle.color(&"gold"), Color(0.91, 0.788, 0.541, 1), "or #E8C98A")
	var panel := UiStyle.THEME.get_stylebox(&"panel", &"PanelContainer") as NuitBox
	assert_not_null(panel, "panneau : une NuitBox")
	assert_eq(panel.fill, UiStyle.color(&"panel"), "fond du panneau = jeton panel")
	assert_eq(panel.rule_color.a > 0.0, true, "filet doré en haut")
	for font_owner: Array in [
		[&"font", &"Label"],
		[&"font", &"DialogueName"],
		[&"font", &"DayLabel"],
		[&"font", &"Button"]
	]:
		var font := UiStyle.THEME.get_font(font_owner[0], font_owner[1])
		if font == null:
			font = UiStyle.THEME.default_font
		var missing := ""
		for i in FRENCH.length():
			var code := FRENCH.unicode_at(i)
			if not _has_char(font, code):
				missing += FRENCH[i]
		assert_eq(missing, "", "%s : glyphes du français" % font_owner[1])


func _has_char(font: Font, code: int) -> bool:
	if font.has_char(code):
		return true
	var variation := font as FontVariation
	if variation != null and variation.base_font != null and variation.base_font.has_char(code):
		return true
	for fallback: Font in font.fallbacks:
		if _has_char(fallback, code):
			return true
	return false


func _open_box() -> void:
	_box = add_child_autofree(DIALOGUE_BOX.instantiate()) as DialogueBox
	EventBus.dialogue_started.emit(&"nephren")
	EventBus.dialogue_line.emit("Nephren", "« Tu es là ? » — Oui.", [])
	_box.complete_line()


func test_set_presentation_changes_the_style() -> void:
	_open_box()
	var panel := _box.get_node(^"%Panel") as Control
	var veil := _box.get_node(^"%Veil") as Control
	var name_label := _box.get_node(^"%NameLabel") as Label
	assert_eq(_box.shown_presentation(), DialogueBox.PRESENTATION_NUIT, "Nuit douce par défaut")
	assert_eq(panel.theme_type_variation, &"DialoguePanel")
	assert_true(UiStyle.is_frosted(panel), "verre dépoli")
	assert_false(veil.visible, "pas de dégradé")
	DialogueBox.set_presentation(DialogueBox.PRESENTATION_BANDEAU)
	assert_eq(DialogueBox.presentation(), DialogueBox.PRESENTATION_BANDEAU)
	assert_eq(_box.shown_presentation(), DialogueBox.PRESENTATION_BANDEAU, "boîte ouverte changée")
	assert_eq(panel.theme_type_variation, &"BandeauPanel", "pas de boîte")
	assert_false(UiStyle.is_frosted(panel))
	assert_true(veil.visible, "dégradé du bas de l'écran")
	assert_true(name_label.uppercase, "nom en capitales")
	assert_eq(name_label.theme_type_variation, &"BandeauName")
	DialogueBox.set_presentation(&"inconnue")
	assert_push_warning("présentation inconnue")
	assert_eq(DialogueBox.presentation(), DialogueBox.PRESENTATION_BANDEAU, "valeur refusée")
	DialogueBox.set_presentation(DialogueBox.PRESENTATION_NUIT)
	assert_eq(panel.theme_type_variation, &"DialoguePanel", "retour à Nuit douce")
	assert_false(name_label.uppercase)


func test_both_styles_show_name_text_and_portrait() -> void:
	for presentation: StringName in DialogueBox.PRESENTATIONS:
		DialogueBox.set_presentation(presentation)
		_open_box()
		await wait_process_frames(2)
		var name_label := _box.get_node(^"%NameLabel") as Label
		var text := _box.get_node(^"%Text") as Label
		var portrait := _box.get_node(^"%Portrait") as TextureRect
		assert_true(name_label.is_visible_in_tree(), "%s : nom" % presentation)
		assert_eq(name_label.text, "Nephren")
		assert_true(text.is_visible_in_tree(), "%s : texte" % presentation)
		assert_string_contains(text.text, "Tu es là")
		assert_true(portrait.is_visible_in_tree(), "%s : portrait" % presentation)
		assert_not_null(portrait.texture)
		assert_gt(portrait.size.y, 150.0, "%s : portrait en buste" % presentation)
		EventBus.dialogue_ended.emit(&"nephren")
		_box.queue_free()
		_box = null
		await wait_process_frames(1)
