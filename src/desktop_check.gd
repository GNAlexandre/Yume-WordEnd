extends Node
## Vérification de démarrage de l'application de bureau exportée (bureau, docs/bureau.md), sans
## effet dans une partie normale : DesktopApp ne crée ce nœud que si le jeu est lancé sur le
## bureau avec l'argument utilisateur --desktop-check=<phase> (un jeu exporté ignore --script : la
## vérification voyage donc dans le pck). tools/desktop_boot.sh s'en sert :
##   WordEnd.x86_64 --headless -- --desktop-check=first [--desktop-shot=<capture du menu.png>]
## Phase « first » (profil neuf) : « Cliquer pour jouer », menu avec « Plein écran » et
## « Quitter », F11 et Alt+Entrée (plein écran mémorisé, laissé actif), nouvelle partie jusqu'au
## joueur, quelques pas, ni raccourcis de test ni contrôles tactiles, puis menu pause →
## « Quitter le jeu » (partie écrite, jeu fermé). Phase « resume » (même profil) : plein écran
## rétabli au lancement, « Continuer », F11 rend la fenêtre, « Quitter le jeu ».
## Chaque contrôle écrit « [bureau] ok : … » ; un échec écrit « DESKTOP BOOT ÉCHEC : … » et quitte
## avec le code 1 ; la réussite, « DESKTOP BOOT OK », puis le bouton ferme le jeu (code 0).

const ARGUMENT := "--desktop-check="
const SHOT_ARGUMENT := "--desktop-shot="
const NO_WM_ARGUMENT := "--desktop-no-wm"
const TIMEOUT_S := 240.0
const PAUSE_PATH := ^"UI/HUD/PauseMenu"

## « first » ou « resume ».
var phase: String = "first"
## Capture du menu (PNG, chemin absolu) ; "" : aucune (et jamais sans écran).
var shot_path: String = ""

var _desktop: Node
var _failed: bool = false


## Phase demandée par les arguments utilisateur ("" : aucune vérification).
static func requested_phase(arguments: PackedStringArray) -> String:
	for argument: String in arguments:
		if argument.begins_with(ARGUMENT):
			return argument.trim_prefix(ARGUMENT)
	return ""


## Capture demandée par les arguments utilisateur ("" : aucune).
static func requested_shot(arguments: PackedStringArray) -> String:
	for argument: String in arguments:
		if argument.begins_with(SHOT_ARGUMENT):
			return argument.trim_prefix(SHOT_ARGUMENT)
	return ""


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_desktop = get_parent()
	get_tree().create_timer(TIMEOUT_S, true, false, true).timeout.connect(
		_fail.bind("délai dépassé")
	)
	_run.call_deferred()


func _run() -> void:
	await get_tree().process_frame
	if not _environment_ok():
		return
	var menu := await _wait_node("MainMenu", 30.0)
	if not _check(menu != null, "menu principal affiché"):
		return
	await _menu_phase(menu)
	if _failed:
		return
	var main := get_tree().current_scene
	await _press_key(KEY_ENTER)
	var player := await _wait_player(main, 120.0)
	if not _check(player != null, "partie chargée, joueur présent"):
		return
	await _game_phase(main, player)


func _environment_ok() -> bool:
	var user_dir := OS.get_user_data_dir()
	_log(
		(
			"WordEnd %s (%s), phase %s, affichage %s, user:// = %s"
			% [
				ProjectSettings.get_setting("application/config/version", "?"),
				"jeu exporté" if OS.has_feature("template") else "éditeur",
				phase,
				DisplayServer.get_name(),
				user_dir,
			]
		)
	)
	if DisplayServer.get_name() != "headless":
		_log("fenêtre : %s, écran utile : %s" % [DisplayServer.window_get_size(), _usable()])
	return (
		_check(bool(_desktop.call(&"is_desktop")), "application de bureau (pas le Web)")
		and _check(user_dir.ends_with("/WordEnd"), "dossier utilisateur à son nom (WordEnd)")
		and _check(not user_dir.contains("app_userdata"), "pas sous godot/app_userdata")
	)


func _menu_phase(menu: Node) -> void:
	if bool(menu.call(&"is_waiting_for_gesture")):
		await _press_key(KEY_SPACE)
	_check(not bool(menu.call(&"is_waiting_for_gesture")), "« Cliquer pour jouer » passé")
	var fullscreen_button := menu.get_node(^"%FullscreenButton") as Button
	var quit_button := menu.get_node(^"%ExitGameButton") as Button
	var continue_button := menu.get_node(^"%ContinueButton") as Button
	_check(fullscreen_button.visible, "bouton « %s » visible" % fullscreen_button.text)
	_check(quit_button.visible and quit_button.text == "Quitter", "bouton « Quitter » visible")
	var has_save := bool(_save_manager().call(&"has_save"))
	if phase == "resume":
		_check(has_save and continue_button.visible, "« Continuer » : la partie a été écrite")
		_check(_fullscreen_wanted(), "plein écran rétabli depuis user://settings.cfg")
		_check(_fullscreen_shown(), "fenêtre en plein écran dès le lancement")
		await _capture()
		await _press_key(KEY_F11)
		_check(not _fullscreen_wanted() and not _fullscreen_shown(), "F11 : retour en fenêtre")
		_check(_settings_fullscreen() == false, "fenêtre mémorisée")
		return
	_check(not has_save and not continue_button.visible, "profil neuf : pas de « Continuer »")
	await _capture()
	await _press_key(KEY_F11)
	_check(_fullscreen_wanted() and _fullscreen_shown(), "F11 : plein écran")
	_check(_settings_fullscreen() == true, "plein écran mémorisé dans user://settings.cfg")
	_check(fullscreen_button.text == str(_desktop.call(&"fullscreen_text")), "bouton à jour")
	await _press_key(KEY_ENTER, true)
	_check(not _fullscreen_wanted() and not _fullscreen_shown(), "Alt+Entrée : retour en fenêtre")
	_check(not bool(_save_manager().call(&"is_game_loaded")), "Alt+Entrée ne presse aucun bouton")
	await _press_key(KEY_F11)
	_check(_fullscreen_wanted(), "F11 : plein écran de nouveau (gardé pour la phase resume)")


func _game_phase(main: Node, player: Node3D) -> void:
	var game := main.call(&"game") as Node
	_check(game.get_node_or_null(^"TestShortcuts") == null, "aucun raccourci de test")
	var touch := game.get_node_or_null(^"UI/TouchControls") as CanvasItem
	_check(touch != null and not touch.visible, "contrôles tactiles masqués")
	_check(bool(_save_manager().call(&"is_game_loaded")), "partie suivie par SaveManager")
	var start := player.global_position
	Input.action_press(&"move_back")
	for i in 40:
		await get_tree().physics_frame
	Input.action_release(&"move_back")
	_log("joueur : %.2f m parcourus" % start.distance_to(player.global_position))
	await _press_key(KEY_ESCAPE)
	var pause := game.get_node_or_null(PAUSE_PATH) as Control
	if not _check(pause != null and pause.visible, "menu pause ouvert"):
		return
	var quit := pause.get_node(^"%ExitGameButton") as Button
	_check(quit.visible and quit.text == "Quitter le jeu", "bouton « Quitter le jeu » visible")
	_check((pause.get_node(^"%FullscreenButton") as Button).visible, "« Plein écran » en pause")
	await _capture("_pause")
	if _failed:
		return
	_desktop.connect(&"quit_requested", _on_quit_requested)
	quit.pressed.emit()


func _on_quit_requested() -> void:
	var path := str(_save_manager().get(&"save_path"))
	_check(FileAccess.file_exists(path), "partie écrite avant de quitter (%s)" % path)
	_check(not bool(_save_manager().call(&"is_game_loaded")), "suivi de la partie arrêté")
	if not _failed:
		print("DESKTOP BOOT OK (phase %s)" % phase)


func _save_manager() -> Node:
	return get_tree().root.get_node(^"SaveManager")


func _wait_node(node_name: String, seconds: float) -> Node:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		var scene := get_tree().current_scene
		if scene != null:
			var found := scene.find_child(node_name, true, false)
			if found != null and found.is_node_ready():
				return found
		await get_tree().process_frame
	return null


func _wait_player(main: Node, seconds: float) -> Node3D:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if main.call(&"game") != null:
			var players := get_tree().get_nodes_in_group(&"player")
			if players.size() == 1 and players[0].is_inside_tree():
				for i in 10:
					await get_tree().process_frame
				return players[0] as Node3D
		await get_tree().process_frame
	return null


func _press_key(keycode: Key, alt: bool = false) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = keycode
		event.physical_keycode = keycode
		event.alt_pressed = alt
		event.pressed = pressed
		Input.parse_input_event(event)
		await get_tree().physics_frame
		await get_tree().process_frame
	await get_tree().process_frame


## Capture de l'écran dans shot_path (suffix avant « .png » : une autre vue).
func _capture(suffix: String = "") -> void:
	if shot_path.is_empty() or DisplayServer.get_name() == "headless":
		return
	for i in 45:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var path := shot_path.get_basename() + suffix + ".png"
	var image := get_tree().root.get_texture().get_image()
	var err := image.save_png(path)
	_check(err == OK, "capture : %s (%d × %d)" % [path, image.get_width(), image.get_height()])


func _usable() -> Vector2i:
	return DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen()).size


func _fullscreen_wanted() -> bool:
	return bool(_desktop.call(&"is_fullscreen"))


## La fenêtre elle-même. Sans écran, le mode ne change pas ; sous X11 sans gestionnaire de
## fenêtres (Xvfb nu, --desktop-no-wm), le plein écran ne tient pas : on suit le réglage.
func _fullscreen_shown() -> bool:
	if DisplayServer.get_name() == "headless" or NO_WM_ARGUMENT in OS.get_cmdline_user_args():
		return _fullscreen_wanted()
	var mode := DisplayServer.window_get_mode()
	return (
		mode == DisplayServer.WINDOW_MODE_FULLSCREEN
		or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	)


func _settings_fullscreen() -> Variant:
	var config := ConfigFile.new()
	if config.load(str(_desktop.get(&"settings_path"))) != OK:
		return null
	return config.get_value("display", "fullscreen", null)


func _check(condition: bool, label: String) -> bool:
	if condition:
		_log("ok : " + label)
		return true
	_fail(label)
	return false


func _fail(reason: String) -> void:
	if _failed:
		return
	_failed = true
	printerr("DESKTOP BOOT ÉCHEC : %s (phase %s)" % [reason, phase])
	# Un « Quitter » en cours ne doit pas remettre le code de sortie à 0.
	_desktop.set(&"quit_enabled", false)
	get_tree().quit(1)


func _log(text: String) -> void:
	print("[bureau] " + text)
