extends "res://tests/stubs/m1_game_test.gd"
## Base des tests d'intégration M2 (tests/integration/test_m2_*.gd), dont ils héritent par
## chemin (pas de class_name, règle des stubs) : la vraie racine du jeu (src/main.tscn : « Cliquer
## pour jouer », menu, chargement, partie) et des événements d'entrée réels (InputEventKey,
## InputEventJoypadButton, InputEventJoypadMotion, clics de souris) passés à
## Input.parse_input_event, comme ceux d'un clavier, d'une manette ou d'une souris : l'état des
## actions (lu par le joueur) et l'interface (menus, dialogue, inventaire) les reçoivent.
## L'écran de fin d'arène n'est pas refermé automatiquement (il fige le jeu jusqu'à
## « Continuer »).
##
## Hérite de la base M1 (tests/stubs/m1_game_test.gd) : sauvegarde propre au script, horloge
## déterministe des visuels, hasard semé, état rétabli après chaque test. En plus : geste
## « Cliquer pour jouer » oublié avant et après chaque test, toutes les touches relâchées,
## main.tscn libéré, réglages de SaveManager rétablis.

const MAIN_SCENE := preload("res://src/main.tscn")
const MenuScript := preload("res://src/ui/main_menu.gd")
## Touches du clavier qu'un test peut laisser enfoncées (relâchées après chaque test).
const KEYS: Array[Key] = [
	KEY_W,
	KEY_A,
	KEY_S,
	KEY_D,
	KEY_E,
	KEY_I,
	KEY_J,
	KEY_K,
	KEY_SPACE,
	KEY_ENTER,
	KEY_ESCAPE,
	KEY_SHIFT,
	KEY_UP,
	KEY_DOWN,
	KEY_LEFT,
	KEY_RIGHT,
]
## Boutons de manette relâchés après chaque test.
const BUTTONS: Array[JoyButton] = [
	JOY_BUTTON_A,
	JOY_BUTTON_B,
	JOY_BUTTON_X,
	JOY_BUTTON_Y,
	JOY_BUTTON_START,
	JOY_BUTTON_DPAD_UP,
	JOY_BUTTON_DPAD_DOWN,
	JOY_BUTTON_DPAD_LEFT,
	JOY_BUTTON_DPAD_RIGHT,
	JOY_BUTTON_LEFT_STICK,
]
## Actions relâchées après chaque test, en plus de celles de la base M1.
const MORE_ACTIONS: Array[StringName] = [
	&"inventory",
	&"pause",
	&"ui_accept",
	&"ui_cancel",
	&"ui_up",
	&"ui_down",
	&"ui_left",
	&"ui_right",
	&"camera_left",
	&"camera_right",
	&"camera_up",
	&"camera_down",
]

## Racine du jeu (src/main.tscn), enfant du test.
var main: Node
var hud: Control
var dialogue_box: DialogueBox
var inventory: Control
var pause_menu: Control
var arena_end: Control

var _previous_checkpoint: float
## Couche d'affichage de GUT (au-dessus de tout) : cachée pendant le test, sinon elle prend les
## clics destinés au menu.
var _gut_layer: CanvasLayer


func before_each() -> void:
	super()
	_previous_checkpoint = SaveManager.checkpoint_interval
	get_tree().root.remove_meta(MenuScript.GESTURE_META)
	_gut_layer = get_tree().root.find_child("GutLayer", true, false) as CanvasLayer
	if _gut_layer != null:
		_gut_layer.visible = false


func after_each() -> void:
	release_all_input()
	if is_instance_valid(main):
		main.free()
	main = null
	SaveManager.checkpoint_interval = _previous_checkpoint
	get_tree().root.remove_meta(MenuScript.GESTURE_META)
	if is_instance_valid(_gut_layer):
		_gut_layer.visible = true
	super()


# --- Racine, menu, partie --------------------------------------------------------------------


## main.tscn ajouté au test : écran « Cliquer pour jouer » (aucun geste encore dans ce processus).
func open_main() -> Control:
	main = MAIN_SCENE.instantiate()
	add_child(main)
	await wait_process_frames(2)
	return menu()


## Menu principal affiché par main.tscn (null pendant la partie).
func menu() -> Control:
	return main.find_child("MainMenu", false, false) as Control if main != null else null


## Bouton du menu par son nom unique (%NewGameButton…).
func menu_button(unique_name: String) -> Button:
	return menu().get_node("%" + unique_name) as Button


## Attend que main.tscn ait ajouté la partie, puis branche game, player, l'interface… (false si
## elle n'arrive pas dans max_seconds).
func wait_for_game(max_seconds: float = 10.0) -> bool:
	var loaded: bool = await wait_until(
		func() -> bool: return main.call(&"game") != null and main.call(&"game").is_inside_tree(),
		max_seconds
	)
	if not loaded:
		return false
	bind_game(main.call(&"game") as Node3D)
	await wait_physics_frames(3)
	return true


## Branche les champs de la base sur une partie (src/game.tscn) déjà dans l'arbre.
func bind_game(node: Node3D) -> void:
	game = node
	player = game.get_node(^"Player") as Player
	combat = player.combat
	health = player.health
	dunes = game.get_node(^"Island/Zones/dunes") as Zone
	arena = dunes.get_node(^"Arena") as Arena
	director = arena.director()
	hud = game.get_node(^"UI/HUD") as Control
	dialogue_box = game.get_node(^"UI/DialogueBox") as DialogueBox
	inventory = game.get_node(^"UI/Inventory") as Control
	pause_menu = game.get_node(^"UI/HUD/PauseMenu") as Control
	arena_end = game.get_node(^"UI/ArenaEnd") as Control
	# Sous GUT, la scène courante est celle de GUT : le retour au menu ne la recharge pas.
	pause_menu.set(&"reload_on_quit", false)


## Nouvelle partie depuis le menu, au clavier et à la souris : clic « Cliquer pour jouer », clic
## sur la vignette du skin, clic sur « Nouvelle partie » ; attend la partie.
func new_game_from_menu(skin_id: StringName = &"chtholly") -> bool:
	await open_main()
	await click_center()
	await click(menu().call(&"skin_card", skin_id) as Control)
	await click(menu_button("NewGameButton"))
	return await wait_for_game()


## « Fermeture de l'onglet » simulée : la partie et main.tscn libérés (rien n'est écrit au
## passage), GameState remis à zéro, comme au chargement d'une nouvelle page.
func close_tab() -> void:
	SaveManager.close_game(false)
	main.free()
	main = null
	game = null
	player = null
	GameState.reset()
	get_tree().root.remove_meta(MenuScript.GESTURE_META)
	await wait_process_frames(2)


# --- Attentes qui marchent aussi en pause ------------------------------------------------------


## Attend count images physiques, même quand l'arbre est en pause (les attentes de GUT y sont
## gelées : fin d'arène, inventaire, menu pause ; le moteur, lui, continue de compter ses images
## physiques). Un appui tenu au moins une image physique n'est plus « just pressed » quand il est
## relâché, comme l'appui d'un vrai joueur : sous GUT, les images de rendu sans limite peuvent
## être bien plus nombreuses que les images physiques.
func frames(count: int) -> void:
	for _frame in count:
		await get_tree().physics_frame


## Attend que predicate soit vrai (true) ou que max_seconds de temps réel passent (false), image
## par image, même quand l'arbre se met en pause pendant l'attente.
func until(predicate: Callable, max_seconds: float) -> bool:
	var deadline := Time.get_ticks_msec() + int(max_seconds * 1000.0)
	while not predicate.call():
		if Time.get_ticks_msec() >= deadline:
			return false
		await get_tree().process_frame
	return true


# --- Événements d'entrée réels ----------------------------------------------------------------


## Touche du clavier (keycode et physical_keycode), comme un vrai clavier.
func key(keycode: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = pressed
	Input.parse_input_event(event)


## Appui bref sur une touche : enfoncée held images, puis relâchée.
func tap_key(keycode: Key, held: int = 2) -> void:
	await frames(1)
	key(keycode, true)
	await frames(held)
	key(keycode, false)
	await frames(2)


## Touche tenue seconds secondes de jeu, puis relâchée.
func hold_key(keycode: Key, seconds: float) -> void:
	await wait_physics_frames(1)
	key(keycode, true)
	await wait_seconds(seconds)
	key(keycode, false)
	await wait_physics_frames(1)


## Bouton de manette (appareil 0), appuyé ou relâché.
func joy_button(button: JoyButton, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = button
	event.pressed = pressed
	event.pressure = 1.0 if pressed else 0.0
	Input.parse_input_event(event)


## Appui bref sur un bouton de manette.
func tap_joy(button: JoyButton, held: int = 2) -> void:
	await frames(1)
	joy_button(button, true)
	await frames(held)
	joy_button(button, false)
	await frames(2)


## Axe de manette (appareil 0) : stick gauche JOY_AXIS_LEFT_X / LEFT_Y, droit RIGHT_X / RIGHT_Y.
func joy_axis(axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)


## Stick gauche incliné (x à droite, y vers le bas : -1 = en avant).
func stick(x: float, y: float) -> void:
	joy_axis(JOY_AXIS_LEFT_X, x)
	joy_axis(JOY_AXIS_LEFT_Y, y)


## Clic gauche (survol, appui et relâchement) au point position de l'interface (coordonnées du
## canevas, celles de Control.get_global_rect()). L'événement porte les coordonnées de la
## fenêtre : en headless, elle fait 64 × 64 px et l'étirement canvas_items la met à l'échelle.
func click_at(position: Vector2) -> void:
	var on_window := get_tree().root.get_final_transform() * position
	var motion := InputEventMouseMotion.new()
	motion.position = on_window
	motion.global_position = on_window
	Input.parse_input_event(motion)
	await frames(1)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.position = on_window
		event.global_position = on_window
		event.pressed = pressed
		Input.parse_input_event(event)
		await frames(1)
	await frames(1)


## Clic au centre d'un Control visible.
func click(control: Control) -> void:
	assert_true(control.is_visible_in_tree(), "%s visible pour le clic" % control.name)
	await click_at(control.get_global_rect().get_center())


## Clic au centre de l'écran.
func click_center() -> void:
	await click_at(get_viewport().get_visible_rect().get_center())


## Relâche toutes les touches, boutons et axes que les tests utilisent.
func release_all_input() -> void:
	for keycode: Key in KEYS:
		key(keycode, false)
	for button: JoyButton in BUTTONS:
		joy_button(button, false)
	stick(0.0, 0.0)
	joy_axis(JOY_AXIS_RIGHT_X, 0.0)
	joy_axis(JOY_AXIS_RIGHT_Y, 0.0)
	Input.flush_buffered_events()
	for action: StringName in MORE_ACTIONS:
		Input.action_release(action)


# --- Déplacements ----------------------------------------------------------------------------


## Marche au clavier (touches tenues) jusqu'à ce que predicate soit vrai ; true s'il l'est
## devenu avant max_seconds. Les touches sont relâchées à la fin.
func walk_keys_until(keys: Array[Key], predicate: Callable, max_seconds: float) -> bool:
	await frames(1)
	for keycode: Key in keys:
		key(keycode, true)
	var reached: bool = await until(predicate, max_seconds)
	for keycode: Key in keys:
		key(keycode, false)
	await frames(2)
	return reached


## Marche au stick gauche (x, y) jusqu'à ce que predicate soit vrai ; stick relâché à la fin.
func walk_stick_until(x: float, y: float, predicate: Callable, max_seconds: float) -> bool:
	await frames(1)
	stick(x, y)
	var reached: bool = await until(predicate, max_seconds)
	stick(0.0, 0.0)
	await frames(2)
	return reached


## Distance horizontale du joueur à un nœud.
func distance_to(node: Node3D) -> float:
	return flat_distance(player.global_position, node.global_position)


# --- Interface -------------------------------------------------------------------------------


## Nombre de cœurs affichés par le HUD (pleins et vides).
func hearts_shown() -> int:
	return (hud.get_node("%Hearts") as Control).get_child_count()


## Nom de zone affiché par le HUD ("" si la bannière est cachée).
func zone_banner() -> String:
	var banner := hud.get_node("%ZoneBanner") as Control
	return (hud.get_node("%ZoneLabel") as Label).text if banner.visible else ""
