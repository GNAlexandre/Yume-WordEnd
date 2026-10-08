extends "res://tests/stubs/l10_ui_test.gd"
## Application de bureau (bureau, docs/bureau.md) : préréglages Windows et Linux à côté du Web
## (resté premier et seul de sa plateforme), version tirée de project.godot, dossier utilisateur
## « WordEnd » hors Web, boutons « Plein écran » et « Quitter » absents du Web (simulé), plein écran
## mémorisé et raccourcis (DesktopApp), taille de départ de la fenêtre, icône .ico, installateur
## NSIS, script de construction, CI et tools/check.sh.

const PRESETS_PATH := "res://export_presets.cfg"
const MENU := preload("res://src/ui/main_menu.tscn")
const PAUSE := preload("res://src/ui/pause_menu.tscn")
const PauseScript := preload("res://src/ui/pause_menu.gd")
const DesktopAppScript := preload("res://src/autoload/desktop_app.gd")
const DesktopCheck := preload("res://src/desktop_check.gd")
const TouchControls := preload("res://src/ui/touch_controls.gd")
const ICON_PNG := "res://assets/ui/icon.png"
const ICON_ICO := "res://tools/installer/wordend.ico"
const WELCOME_BMP := "res://tools/installer/welcome.bmp"
const NSIS_SCRIPT := "res://tools/installer/wordend.nsi"
const BUILD_SCRIPT := "res://tools/build_desktop.sh"
const SETTINGS_TEST_PATH := "user://test_desktop_settings.cfg"
const EXCLUDED: Array[String] = ["addons/gut/*", "tests/*", "tools/*", "docs/*", "build/*", "web/*"]

var _presets: ConfigFile


func before_all() -> void:
	_presets = ConfigFile.new()
	assert_eq(_presets.load(PRESETS_PATH), OK, "export_presets.cfg lisible")


func before_each() -> void:
	super()
	_reset_desktop()


func after_each() -> void:
	_reset_desktop()
	super()


## Fenêtre (réglage écrit dans le fichier de test, puis effacé), vraie plateforme, vrai fichier.
func _reset_desktop() -> void:
	DesktopApp.simulated_web = 0
	DesktopApp.settings_path = SETTINGS_TEST_PATH
	DesktopApp.set_fullscreen(false)
	if FileAccess.file_exists(SETTINGS_TEST_PATH):
		DirAccess.remove_absolute(SETTINGS_TEST_PATH)
	DesktopApp.simulated_web = -1
	DesktopApp.settings_path = DesktopAppScript.SETTINGS_PATH
	DesktopApp.quit_enabled = true


func _text(path: String) -> String:
	return FileAccess.get_file_as_string(path)


## Section du préréglage de ce nom ("" s'il n'existe pas).
func _preset_section(preset_name: String) -> String:
	for section: String in _presets.get_sections():
		if section.ends_with(".options") or not section.begins_with("preset."):
			continue
		if _presets.get_value(section, "name", "") == preset_name:
			return section
	return ""


func _option(preset_name: String, key: String) -> Variant:
	return _presets.get_value(_preset_section(preset_name) + ".options", key, null)


func _project_version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", ""))


func _menu() -> Control:
	var menu: MenuScript = MENU.instantiate()
	menu.require_gesture = false
	return add_child_autofree(menu)


func _pause() -> PauseScript:
	var menu: PauseScript = PAUSE.instantiate()
	menu.reload_on_quit = false
	return add_child_autofree(menu)


func _button(menu: Control, unique_name: String) -> Button:
	return menu.get_node("%" + unique_name) as Button


func _key(keycode: Key, alt: bool = false, pressed: bool = true) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.alt_pressed = alt
	event.pressed = pressed
	return event


# --- Préréglages d'export ---------------------------------------------------------------------


func test_web_stays_first_and_default() -> void:
	assert_eq(_presets.get_value("preset.0", "name", ""), "Web", "le Web reste le préréglage 0")
	assert_eq(_presets.get_value("runnable_presets", "Web", ""), "Web")
	var check := _text("res://tools/check.sh")
	assert_string_contains(check, "--export-release Web build/web/index.html")


func test_windows_preset() -> void:
	var section := _preset_section("Windows Desktop")
	assert_ne(section, "", "préréglage « Windows Desktop »")
	assert_eq(_presets.get_value(section, "platform", ""), "Windows Desktop")
	assert_eq(_presets.get_value(section, "export_path", ""), "build/desktop/windows/WordEnd.exe")
	assert_eq(_presets.get_value(section, "export_filter", ""), "all_resources")
	var excluded: String = _presets.get_value(section, "exclude_filter", "")
	for pattern: String in EXCLUDED:
		assert_true(excluded.contains(pattern), "%s hors du pck" % pattern)
	assert_eq(_option("Windows Desktop", "binary_format/architecture"), "x86_64")
	assert_eq(_option("Windows Desktop", "binary_format/embed_pck"), true, "pck dans l'exe")
	assert_eq(_option("Windows Desktop", "texture_format/s3tc_bptc"), true)
	assert_eq(_option("Windows Desktop", "debug/export_console_wrapper"), 0, "pas de console")
	assert_eq(_option("Windows Desktop", "codesign/enable"), false, "pas de signature")


func test_windows_metadata_and_icon_without_rcedit() -> void:
	# Godot 4.7 écrit lui-même les ressources de l'exe (TemplateModifier) : ni rcedit ni wine.
	assert_eq(_option("Windows Desktop", "application/modify_resources"), true)
	assert_eq(_option("Windows Desktop", "application/product_name"), "WordEnd")
	assert_eq(_option("Windows Desktop", "application/company_name"), "Yume Novel")
	assert_false(str(_option("Windows Desktop", "application/file_description")).is_empty())
	assert_eq(_option("Windows Desktop", "application/icon"), ICON_ICO)
	assert_true(FileAccess.file_exists(ICON_ICO), "icône .ico versionnée")
	for key: String in ["application/file_version", "application/product_version"]:
		assert_eq(_option("Windows Desktop", key), "", "%s vide : version du projet" % key)


func test_linux_preset_for_the_headless_check() -> void:
	var section := _preset_section("Linux")
	assert_ne(section, "", "préréglage « Linux »")
	assert_eq(_presets.get_value(section, "platform", ""), "Linux")
	assert_eq(_presets.get_value(section, "export_path", ""), "build/desktop/linux/WordEnd.x86_64")
	assert_eq(_option("Linux", "binary_format/architecture"), "x86_64")
	assert_eq(_option("Linux", "binary_format/embed_pck"), true)
	assert_eq(
		_presets.get_value(section, "exclude_filter", ""),
		_presets.get_value(_preset_section("Windows Desktop"), "exclude_filter", ""),
		"même pck que Windows"
	)


func test_same_renderer_as_the_web() -> void:
	assert_eq(
		ProjectSettings.get_setting("rendering/renderer/rendering_method"), "gl_compatibility"
	)


# --- Projet : version, dossier utilisateur -----------------------------------------------------


func test_version_comes_from_project_settings() -> void:
	var version := _project_version()
	var semver := RegEx.create_from_string("^\\d+\\.\\d+\\.\\d+$")
	assert_not_null(semver.search(version), "version X.Y.Z : %s" % version)
	assert_string_contains(_text(BUILD_SCRIPT), "config/version")


func test_user_dir_named_after_the_game_but_not_on_the_web() -> void:
	assert_true(ProjectSettings.get_setting("application/config/use_custom_user_dir", false))
	assert_eq(ProjectSettings.get_setting("application/config/custom_user_dir_name"), "WordEnd")
	assert_true(OS.get_user_data_dir().ends_with("/WordEnd"), OS.get_user_data_dir())
	# Web : user:// reste /userfs/godot/app_userdata/WordEnd (les parties d'IndexedDB y sont).
	var project := ConfigFile.new()
	assert_eq(project.load("res://project.godot"), OK)
	assert_eq(project.get_value("application", "config/use_custom_user_dir.web", true), false)


# --- Boutons du menu principal et du menu pause --------------------------------------------------


func test_quit_and_fullscreen_hidden_on_the_web() -> void:
	DesktopApp.simulated_web = 1
	assert_false(DesktopApp.is_desktop())
	var menu := _menu()
	assert_false(_button(menu, "ExitGameButton").visible, "pas de « Quitter » sur le Web")
	assert_false(_button(menu, "FullscreenButton").visible)
	var pause := _pause()
	assert_false(_button(pause, "ExitGameButton").visible)
	assert_false(_button(pause, "FullscreenButton").visible)
	assert_true(_button(pause, "QuitButton").visible, "« Retour au menu » reste")


func test_quit_and_fullscreen_shown_on_the_desktop() -> void:
	DesktopApp.simulated_web = 0
	var menu := _menu()
	var quit := _button(menu, "ExitGameButton")
	assert_true(quit.visible, "« Quitter » au menu principal")
	assert_eq(quit.text, "Quitter")
	var fullscreen := _button(menu, "FullscreenButton")
	assert_true(fullscreen.visible)
	assert_eq(fullscreen.text, DesktopApp.text("fullscreen_off"))
	var pause := _pause()
	assert_true(_button(pause, "ExitGameButton").visible, "« Quitter le jeu » en pause")
	assert_eq(_button(pause, "ExitGameButton").text, "Quitter le jeu")
	assert_true(_button(pause, "FullscreenButton").visible)


func test_desktop_texts_live_in_story_json() -> void:
	for key: String in ["fullscreen_off", "fullscreen_on", "quit", "quit_game"]:
		assert_false(DesktopApp.text(key).is_empty(), "desktop/%s dans story.json" % key)
	assert_ne(DesktopApp.text("fullscreen_off"), DesktopApp.text("fullscreen_on"))


func test_quit_writes_the_game_first() -> void:
	DesktopApp.simulated_web = 0
	DesktopApp.quit_enabled = false
	SaveManager.new_game(&"")
	assert_true(SaveManager.is_game_loaded())
	GameState.add_item(&"flower_blue", 1)
	assert_false(SaveManager.has_save(), "rien d'écrit encore")
	watch_signals(DesktopApp)
	var pause := _pause()
	_button(pause, "ExitGameButton").pressed.emit()
	assert_signal_emitted(DesktopApp, "quit_requested")
	assert_true(SaveManager.has_save(), "partie écrite avant de quitter")
	assert_false(SaveManager.is_game_loaded(), "suivi arrêté")
	assert_string_contains(_text(SaveManager.save_path), "flower_blue")


func test_quit_from_the_main_menu_without_game() -> void:
	DesktopApp.simulated_web = 0
	DesktopApp.quit_enabled = false
	watch_signals(DesktopApp)
	_button(_menu(), "ExitGameButton").pressed.emit()
	assert_signal_emitted(DesktopApp, "quit_requested")
	assert_false(SaveManager.has_save(), "rien à écrire au menu")


# --- Plein écran ---------------------------------------------------------------------------------


func test_fullscreen_is_remembered() -> void:
	DesktopApp.simulated_web = 0
	DesktopApp.settings_path = SETTINGS_TEST_PATH
	var other := ConfigFile.new()
	other.set_value("audio", "volume", 0.5)
	other.save(SETTINGS_TEST_PATH)
	watch_signals(DesktopApp)
	DesktopApp.set_fullscreen(true)
	assert_true(DesktopApp.is_fullscreen())
	assert_signal_emitted_with_parameters(DesktopApp, "fullscreen_changed", [true])
	var config := ConfigFile.new()
	assert_eq(config.load(SETTINGS_TEST_PATH), OK, "réglages écrits")
	assert_eq(config.get_value("display", "fullscreen"), true)
	assert_eq(config.get_value("audio", "volume"), 0.5, "les autres réglages sont gardés")
	# Lancement suivant : une nouvelle instance relit le réglage.
	var next: Node = autofree(DesktopAppScript.new())
	next.set(&"simulated_web", 0)
	next.set(&"settings_path", SETTINGS_TEST_PATH)
	next.call(&"load_settings")
	assert_true(next.call(&"is_fullscreen"), "plein écran rétabli au lancement suivant")
	DesktopApp.toggle_fullscreen()
	next.call(&"load_settings")
	assert_false(next.call(&"is_fullscreen"), "fenêtre mémorisée aussi")


func test_fullscreen_button_follows_the_setting() -> void:
	DesktopApp.simulated_web = 0
	DesktopApp.settings_path = SETTINGS_TEST_PATH
	var menu := _menu()
	var button := _button(menu, "FullscreenButton")
	button.pressed.emit()
	assert_true(DesktopApp.is_fullscreen(), "le bouton passe en plein écran")
	assert_eq(button.text, DesktopApp.text("fullscreen_on"))
	DesktopApp.toggle_fullscreen()
	assert_eq(button.text, DesktopApp.text("fullscreen_off"), "texte rafraîchi (F11)")


func test_fullscreen_has_no_effect_on_the_web() -> void:
	DesktopApp.simulated_web = 1
	DesktopApp.settings_path = SETTINGS_TEST_PATH
	DesktopApp.set_fullscreen(true)
	assert_false(DesktopApp.is_fullscreen())
	assert_false(FileAccess.file_exists(SETTINGS_TEST_PATH), "aucun fichier écrit")
	assert_false(DesktopApp.controls_window())


func test_fullscreen_shortcuts() -> void:
	assert_true(DesktopAppScript.is_fullscreen_shortcut(_key(KEY_F11)), "F11")
	assert_true(DesktopAppScript.is_fullscreen_shortcut(_key(KEY_ENTER, true)), "Alt+Entrée")
	assert_true(DesktopAppScript.is_fullscreen_shortcut(_key(KEY_KP_ENTER, true)))
	assert_false(DesktopAppScript.is_fullscreen_shortcut(_key(KEY_ENTER)), "Entrée seule")
	assert_false(DesktopAppScript.is_fullscreen_shortcut(_key(KEY_F11, false, false)), "relâché")
	var echo := _key(KEY_F11)
	echo.echo = true
	assert_false(DesktopAppScript.is_fullscreen_shortcut(echo), "répétition")
	var action := InputEventAction.new()
	action.action = &"ui_accept"
	action.pressed = true
	assert_false(DesktopAppScript.is_fullscreen_shortcut(action))


## Les événements de Input.parse_input_event sont distribués au début de l'image suivante (pas à
## chaque image physique) : on attend des images de rendu.
func test_shortcuts_toggle_without_pressing_the_focused_button() -> void:
	DesktopApp.simulated_web = 0
	DesktopApp.settings_path = SETTINGS_TEST_PATH
	var button: Button = add_child_autofree(Button.new())
	button.grab_focus()
	watch_signals(button)
	for event: InputEventKey in [_key(KEY_F11), _key(KEY_F11, false, false)]:
		Input.parse_input_event(event)
	await wait_process_frames(3)
	assert_true(DesktopApp.is_fullscreen(), "F11 (événement réel)")
	for event: InputEventKey in [_key(KEY_ENTER, true), _key(KEY_ENTER, true, false)]:
		Input.parse_input_event(event)
	await wait_process_frames(3)
	assert_false(DesktopApp.is_fullscreen(), "Alt+Entrée")
	assert_signal_not_emitted(button, "pressed", "Alt+Entrée ne presse pas le bouton")
	DesktopApp.simulated_web = 1
	for event: InputEventKey in [_key(KEY_F11), _key(KEY_F11, false, false)]:
		Input.parse_input_event(event)
	await wait_process_frames(3)
	assert_false(DesktopApp.is_fullscreen(), "Web : F11 laissé au navigateur")


# --- Fenêtre et vérification du jeu exporté ---------------------------------------------------


func test_start_window_size() -> void:
	assert_eq(DesktopAppScript.fit_window_size(Vector2i(1920, 1040)), Vector2i(1472, 828))
	assert_eq(DesktopAppScript.fit_window_size(Vector2i(1366, 728)), Vector2i(1024, 576))
	assert_eq(DesktopAppScript.fit_window_size(Vector2i(2560, 1400)), Vector2i(1984, 1116))
	var small := DesktopAppScript.fit_window_size(Vector2i(800, 560))
	assert_eq(small, Vector2i(640, 360), "au moins 640 × 360")
	assert_eq(DesktopAppScript.fit_window_size(Vector2i(600, 300)), Vector2i(600, 300))
	assert_false(DesktopApp.controls_window(), "l'éditeur et les tests gardent leur fenêtre")


func test_export_check_only_with_its_argument() -> void:
	assert_eq(DesktopCheck.requested_phase(PackedStringArray()), "")
	assert_eq(DesktopCheck.requested_phase(PackedStringArray(["--zone=dunes"])), "")
	var arguments := PackedStringArray(["--desktop-check=first", "--desktop-shot=/tmp/a.png"])
	assert_eq(DesktopCheck.requested_phase(arguments), "first")
	assert_eq(DesktopCheck.requested_shot(arguments), "/tmp/a.png")
	assert_null(DesktopApp.get_node_or_null(^"DesktopCheck"), "rien dans une partie normale")
	var boot := _text("res://tools/desktop_boot.sh")
	assert_string_contains(boot, "--desktop-check=")


func test_touch_controls_not_shown_at_start_on_the_desktop() -> void:
	assert_false(TouchControls.is_touch_device(), "pas d'écran tactile supposé hors Web")


# --- Icône, installateur, construction, CI -------------------------------------------------------


func test_ico_has_every_size_and_matches_the_game_icon() -> void:
	var data := FileAccess.get_file_as_bytes(ICON_ICO)
	assert_gt(data.size(), 6, "icône lisible")
	assert_eq(data.decode_u16(2), 1, "type ICO")
	var count := data.decode_u16(4)
	var sizes: Array[int] = []
	var largest := PackedByteArray()
	for i in count:
		var entry := 6 + 16 * i
		var width := data[entry]
		sizes.append(256 if width == 0 else width)
		if width == 0:
			var length := data.decode_u32(entry + 8)
			var offset := data.decode_u32(entry + 12)
			largest = data.slice(offset, offset + length)
	sizes.sort()
	assert_eq(sizes, [16, 32, 48, 64, 128, 256] as Array[int], "tailles attendues par Godot")
	var from_ico := Image.new()
	assert_eq(from_ico.load_png_from_buffer(largest), OK, "256 px en PNG")
	var source := Image.new()
	assert_eq(source.load_png_from_buffer(FileAccess.get_file_as_bytes(ICON_PNG)), OK)
	from_ico.convert(Image.FORMAT_RGBA8)
	source.convert(Image.FORMAT_RGBA8)
	assert_eq(
		from_ico.get_data() == source.get_data(),
		true,
		"wordend.ico à jour (python3 tools/installer/make_installer_art.py)"
	)


func test_installer_welcome_bitmap() -> void:
	var data := FileAccess.get_file_as_bytes(WELCOME_BMP)
	assert_gt(data.size(), 54, "tools/installer/welcome.bmp")
	assert_eq(data.slice(0, 2).get_string_from_ascii(), "BM", "BMP")
	assert_eq(data.decode_s32(18), 164, "largeur du bandeau de NSIS (Modern UI)")
	assert_eq(data.decode_s32(22), 314, "hauteur")
	assert_eq(data.decode_u16(28), 24, "24 bits")
	assert_true(FileAccess.file_exists("res://tools/installer/.gdignore"), "Godot ne l'importe pas")


func test_nsis_script_per_user_french_and_versioned() -> void:
	var nsi := _text(NSIS_SCRIPT)
	assert_false(nsi.is_empty(), "tools/installer/wordend.nsi")
	for fragment: String in [
		"RequestExecutionLevel user",
		"$LOCALAPPDATA\\Programs\\WordEnd",
		'!insertmacro MUI_LANGUAGE "French"',
		"!ifndef VERSION",
		"!error",
		"WordEnd-Setup-${VERSION}.exe",
		'"DisplayVersion" "${VERSION}"',
		'"Publisher"',
		"Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\WordEnd",
		"$SMPROGRAMS\\WordEnd.lnk",
		"$DESKTOP\\WordEnd.lnk",
		"wordend.ico",
		"welcome.bmp",
		"Target amd64-unicode",
		"MB_YESNO",
		"/SD IDYES",
	]:
		assert_string_contains(nsi, fragment)
	# Les sauvegardes que le désinstalleur propose de garder sont celles du jeu.
	var user_dir := str(ProjectSettings.get_setting("application/config/custom_user_dir_name"))
	assert_string_contains(nsi, "$APPDATA\\" + user_dir)
	assert_string_contains(
		nsi, str(_option("Windows Desktop", "application/company_name")), "même éditeur"
	)


func test_build_script_chain() -> void:
	var script := _text(BUILD_SCRIPT)
	for fragment: String in [
		'--export-release "Windows Desktop"',
		"makensis",
		"-WX",
		"-DVERSION=",
		"WordEnd-Setup-",
		"build/dist",
		"zip",
		"GITHUB_STEP_SUMMARY",
	]:
		assert_string_contains(script, fragment)


func test_ci_builds_the_installer_and_releases_on_tags() -> void:
	var ci := _text("res://.github/workflows/ci.yml")
	for fragment: String in [
		"bureau:",
		"tools/build_desktop.sh",
		"softprops/action-gh-release",
		"contents: write",
		"'v*'",
		"WordEnd-Setup-",
		"windows-portable.zip",
		"windows_release_x86_64.exe",
		"linux_release.x86_64",
		"tools/build_desktop.sh --linux",
	]:
		assert_string_contains(ci, fragment)
	assert_eq(ci.count("contents: write"), 1, "écriture réservée à la tâche release")
	assert_string_contains(ci, "permissions:\n  contents: read", "lecture seule par défaut")
	assert_string_contains(ci, "github.ref == 'refs/heads/main'", "déploiement Pages inchangé")
	assert_string_contains(ci, "run: tools/check.sh", "vérification inchangée")


func test_check_verifies_the_desktop_presets() -> void:
	var check := _text("res://tools/check.sh")
	assert_string_contains(check, "Windows Desktop")
	assert_false(check.contains("makensis"), "check.sh ne construit pas l'installateur")
