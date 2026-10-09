extends Node
## DesktopApp (bureau, PR « contrats ») : ce que l'application de bureau (Windows, Linux) a de
## plus que le Web, sans rien changer au Web (docs/bureau.md).
##
## - Fenêtre : dans le jeu exporté (fonctionnalité « template »), au lancement, la fenêtre de
##   1280 × 720 prend 80 % de l'écran utile en 16:9 (fit_window_size), centrée ; elle reste
##   redimensionnable (640 × 360 au moins). L'éditeur, les tests et les captures n'y touchent pas.
## - Plein écran : F11 ou Alt+Entrée partout (menu, chargement, partie, pause) et le bouton
##   « Plein écran » du menu principal et du menu pause. Le choix est écrit dans
##   user://settings.cfg (section display, clé fullscreen ; hors de la sauvegarde de la partie)
##   et rétabli au lancement suivant du jeu exporté (lancé depuis l'éditeur, le bouton suit la
##   fenêtre).
## - « Quitter » (menu principal) et « Quitter le jeu » (menu pause) : la partie suivie est écrite
##   (SaveManager.save()), son suivi s'arrête, puis le jeu se ferme (quit_game). Fermer la
##   fenêtre écrit aussi la partie (SaveManager, NOTIFICATION_WM_CLOSE_REQUEST).
## Sur le Web (OS.has_feature("web")) : boutons cachés, raccourcis ignorés, aucun fichier écrit
## (le navigateur a son propre plein écran ; la page du site, son bouton).
## Textes des boutons : data/texts/story.json, section « desktop » (DialogueRunner.story_text).
## Tests : simulated_web simule le Web ou le bureau ; settings_path et quit_enabled isolent.
## Vérification du jeu exporté (tools/desktop_boot.sh) : avec l'argument utilisateur
## --desktop-check=<phase>, un nœud src/desktop_check.gd joue le menu et une partie, puis quitte.

## Le plein écran a changé (raccourci, bouton, réglages relus).
signal fullscreen_changed(enabled: bool)
## quit_game() a écrit la partie et va fermer le jeu (si quit_enabled).
signal quit_requested

const SETTINGS_PATH := "user://settings.cfg"
const DISPLAY_SECTION := "display"
const FULLSCREEN_KEY := "fullscreen"
## Part de l'écran utile prise par la fenêtre au lancement, en 16:9 (ASPECT).
const SCREEN_SHARE := 0.8
const ASPECT := Vector2i(16, 9)
const MIN_WINDOW_SIZE := Vector2i(640, 360)
## Boutons « Plein écran » des menus (texte rafraîchi à chaque changement).
const FULLSCREEN_BUTTONS := &"desktop_fullscreen_buttons"
const TEXT_SECTION := "desktop/"
const DesktopCheck := preload("res://src/desktop_check.gd")

## Fichier des réglages de l'application (les tests en prennent un autre).
var settings_path: String = SETTINGS_PATH
## -1 : la vraie plateforme ; 0 : bureau simulé ; 1 : Web simulé (tests).
var simulated_web: int = -1
## quit_game() ferme vraiment le jeu ; les tests le coupent (sous GUT, il fermerait GUT).
var quit_enabled: bool = true

var _fullscreen: bool = false
## Mode à retrouver en quittant le plein écran (fenêtre ou fenêtre agrandie).
var _restore_mode: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_WINDOWED


func _ready() -> void:
	# Le raccourci reste actif en pause (menu pause, sac, fin d'arène).
	process_mode = PROCESS_MODE_ALWAYS
	if not is_desktop():
		return
	load_settings()
	if controls_window():
		var mode := DisplayServer.window_get_mode()
		if mode == DisplayServer.WINDOW_MODE_WINDOWED:
			fit_window()
		if _fullscreen:
			_apply_window_mode()
		elif _is_fullscreen_mode(mode):
			# Lancé en plein écran (--fullscreen) : le bouton le dit, sans changer le réglage.
			_fullscreen = true
	elif DisplayServer.get_name() != "headless":
		# Partie lancée depuis l'éditeur, capture : le réglage n'y est pas appliqué, le bouton et
		# F11 suivent donc la fenêtre telle qu'elle est.
		_fullscreen = _is_fullscreen_mode(DisplayServer.window_get_mode())
	# Avant le menu et le jeu, qui ne voient l'événement qu'après (voir _input).
	get_tree().root.window_input.connect(_on_window_input)
	var arguments := OS.get_cmdline_user_args()
	var check_phase := DesktopCheck.requested_phase(arguments)
	if not check_phase.is_empty():
		var check := DesktopCheck.new()
		check.name = "DesktopCheck"
		check.phase = check_phase
		check.shot_path = DesktopCheck.requested_shot(arguments)
		add_child(check)


## Le jeu tourne (ou est simulé) dans un navigateur.
func is_web() -> bool:
	if simulated_web >= 0:
		return simulated_web == 1
	return OS.has_feature("web")


## Application de bureau : boutons « Plein écran » et « Quitter », raccourcis, réglages.
func is_desktop() -> bool:
	return not is_web()


## Le jeu exporté pour le bureau, avec une vraie fenêtre : taille de départ et plein écran
## mémorisé s'y appliquent (jamais dans l'éditeur, les tests ou les captures, qui lancent
## l'éditeur, ni sans écran).
func controls_window() -> bool:
	return is_desktop() and OS.has_feature("template") and DisplayServer.get_name() != "headless"


## Taille de départ de la fenêtre pour un écran utile de usable pixels : SCREEN_SHARE de
## l'écran en 16:9, au moins MIN_WINDOW_SIZE (sauf écran plus petit).
static func fit_window_size(usable: Vector2i) -> Vector2i:
	var unit := floori(minf(usable.x * SCREEN_SHARE / ASPECT.x, usable.y * SCREEN_SHARE / ASPECT.y))
	var wanted := (ASPECT * unit).max(MIN_WINDOW_SIZE)
	return wanted.min(usable)


## Agrandit la fenêtre de départ (1280 × 720) à fit_window_size et la centre sur son écran.
## Une taille déjà choisie (--resolution) est gardée.
func fit_window() -> void:
	var start := Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width", 1280),
		ProjectSettings.get_setting("display/window/size/viewport_height", 720)
	)
	DisplayServer.window_set_min_size(MIN_WINDOW_SIZE)
	if DisplayServer.window_get_size() != start:
		return
	var usable := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	if usable.size.x <= 0 or usable.size.y <= 0:
		return
	var size := fit_window_size(usable.size)
	DisplayServer.window_set_size(size)
	var margin := Vector2i((Vector2(usable.size - size) * 0.5).floor())
	DisplayServer.window_set_position(usable.position + margin)


## Plein écran voulu (réglage), même là où la fenêtre ne peut pas changer (sans écran, tests).
func is_fullscreen() -> bool:
	return _fullscreen


## Passe en plein écran ou en revient, mémorise le choix et rafraîchit les boutons. Sans effet
## sur le Web.
func set_fullscreen(enabled: bool) -> void:
	if not is_desktop():
		return
	_fullscreen = enabled
	_apply_window_mode()
	save_settings()
	_refresh_buttons()
	fullscreen_changed.emit(enabled)


func toggle_fullscreen() -> void:
	set_fullscreen(not _fullscreen)


## F11, ou Alt+Entrée (pavé numérique compris), à l'appui seulement.
static func is_fullscreen_shortcut(event: InputEvent) -> bool:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return false
	if key.keycode == KEY_F11 or key.physical_keycode == KEY_F11:
		return true
	var enter := key.keycode in [KEY_ENTER, KEY_KP_ENTER]
	enter = enter or key.physical_keycode in [KEY_ENTER, KEY_KP_ENTER]
	return enter and key.alt_pressed


## Relit settings_path (absent ou illisible : fenêtre). Ne touche pas à la fenêtre.
func load_settings() -> void:
	var config := ConfigFile.new()
	var enabled := false
	if config.load(settings_path) == OK:
		enabled = config.get_value(DISPLAY_SECTION, FULLSCREEN_KEY, false) == true
	if enabled != _fullscreen:
		_fullscreen = enabled
		_refresh_buttons()
		fullscreen_changed.emit(enabled)


## Écrit les réglages dans settings_path (les autres clés du fichier sont gardées).
func save_settings() -> Error:
	if not is_desktop():
		return ERR_UNAVAILABLE
	var config := ConfigFile.new()
	config.load(settings_path)
	config.set_value(DISPLAY_SECTION, FULLSCREEN_KEY, _fullscreen)
	return config.save(settings_path)


## Montre et branche les boutons « Plein écran » et « Quitter » d'un menu sur le bureau, les
## cache sur le Web. quit_text : clé du texte de quit_button dans la section « desktop » de
## data/texts/story.json (« quit » au menu principal, « quit_game » au menu pause).
func setup_menu_buttons(fullscreen_button: Button, quit_button: Button, quit_text: String) -> void:
	var desktop := is_desktop()
	fullscreen_button.visible = desktop
	quit_button.visible = desktop
	if not desktop:
		return
	quit_button.text = text(quit_text)
	fullscreen_button.add_to_group(FULLSCREEN_BUTTONS)
	fullscreen_button.pressed.connect(toggle_fullscreen)
	quit_button.pressed.connect(quit_game)
	_label_fullscreen_button(fullscreen_button)


## Texte du bouton « Plein écran » selon le réglage.
func fullscreen_text() -> String:
	return text("fullscreen_on" if _fullscreen else "fullscreen_off")


## Texte de la section « desktop » de data/texts/story.json.
func text(key: String) -> String:
	return DialogueRunner.story_text(TEXT_SECTION + key)


## « Quitter » : la partie suivie est écrite et son suivi s'arrête, puis le jeu se ferme.
func quit_game() -> void:
	if SaveManager.is_game_loaded():
		SaveManager.save()
	SaveManager.close_game(false)
	quit_requested.emit()
	if quit_enabled and is_inside_tree():
		get_tree().quit()


## Les raccourcis passent ici avant le menu et le jeu (signal window_input de la fenêtre).
func _on_window_input(event: InputEvent) -> void:
	if is_desktop() and is_fullscreen_shortcut(event):
		toggle_fullscreen()


## Les autoloads reçoivent _input après les scènes : ici, le raccourci est seulement retiré avant
## l'interface (sinon Alt+Entrée presserait le bouton qui a le focus).
func _input(event: InputEvent) -> void:
	if is_desktop() and is_fullscreen_shortcut(event):
		get_viewport().set_input_as_handled()


func _apply_window_mode() -> void:
	if DisplayServer.get_name() == "headless" or not is_desktop():
		return
	var mode := DisplayServer.window_get_mode()
	if _fullscreen:
		if not _is_fullscreen_mode(mode):
			_restore_mode = mode
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif _is_fullscreen_mode(mode):
		var back := _restore_mode
		if back != DisplayServer.WINDOW_MODE_MAXIMIZED:
			back = DisplayServer.WINDOW_MODE_WINDOWED
		DisplayServer.window_set_mode(back)


func _is_fullscreen_mode(mode: DisplayServer.WindowMode) -> bool:
	return (
		mode == DisplayServer.WINDOW_MODE_FULLSCREEN
		or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	)


func _refresh_buttons() -> void:
	if not is_inside_tree():
		return
	for node: Node in get_tree().get_nodes_in_group(FULLSCREEN_BUTTONS):
		if node is Button:
			_label_fullscreen_button(node as Button)


func _label_fullscreen_button(button: Button) -> void:
	button.text = fullscreen_text()
