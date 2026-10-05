extends RefCounted
## Manette et retour dans les écrans du Lot 10 (menu, crédits, pause, fin d'arène).
##
## Dans Godot 4.7, ui_accept et ui_cancel n'ont aucun bouton de manette : A (bouton 0) presse le
## bouton qui a le focus, B (bouton 1) revient en arrière comme Échap (ui_cancel). A et B agissent
## au relâchement d'un appui reçu par l'écran, comme un Button à la souris : l'appui qui ferme la
## pause n'arrive pas au joueur (A = jump et interact, B = charge, lus par sondage), et le
## relâchement d'un appui commencé ailleurs (geste « Cliquer pour jouer ») est ignoré. Les flèches,
## la croix et le stick gauche (ui_up/down/left/right) déplacent le focus, comme dans Godot.

enum Command { NONE, CONSUMED, ACCEPT, BACK }

var _armed: Dictionary[int, bool] = {}


## Presse le bouton qui a le focus s'il est dans root, visible et actif ; true si c'est fait.
static func press_focused(root: Control) -> bool:
	var button := root.get_viewport().gui_get_focus_owner() as BaseButton
	if button == null or button.disabled or not button.is_visible_in_tree():
		return false
	if not root.is_ancestor_of(button):
		return false
	if button.toggle_mode:
		button.button_pressed = not button.button_pressed
	else:
		button.pressed.emit()
	return true


## Le survol de la souris donne le focus aux boutons de root : un seul bouton en surbrillance.
static func focus_on_hover(root: Node) -> void:
	for node: Node in root.find_children("*", "BaseButton", true, false):
		var button := node as BaseButton
		if not button.mouse_entered.is_connected(button.grab_focus):
			button.mouse_entered.connect(button.grab_focus)


## ACCEPT (A relâché), BACK (Échap, ou B relâché), CONSUMED (appui de A ou B, à consommer sans
## agir), NONE (le reste).
func read(event: InputEvent) -> Command:
	if event.is_action_pressed(&"ui_cancel"):
		return Command.BACK
	var joy := event as InputEventJoypadButton
	if joy == null or not joy.button_index in [JOY_BUTTON_A, JOY_BUTTON_B]:
		return Command.NONE
	if joy.pressed:
		_armed[joy.button_index] = true
		return Command.CONSUMED
	if not _armed.erase(joy.button_index):
		return Command.NONE
	return Command.ACCEPT if joy.button_index == JOY_BUTTON_A else Command.BACK


## Oublie les appuis en cours (écran fermé : leur relâchement ne doit plus agir).
func reset() -> void:
	_armed.clear()
