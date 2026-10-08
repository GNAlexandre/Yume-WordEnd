extends Control
## Menu pause (L10), enfant du HUD (game.tscn est figé). L'action pause (Échap, Start, bouton
## tactile Pause) est lue dans _unhandled_input : l'inventaire ouvert la consomme avant (L7), et
## le menu ne s'ouvre ni pendant un dialogue (dialogue_started → dialogue_ended) ni quand le jeu
## est déjà en pause (inventaire, fin d'arène). Ouvert : get_tree().paused, et ce nœud reste
## actif (PROCESS_MODE_ALWAYS).
## - Reprendre ; Sauvegarder : EventBus.save_requested, confirmé par SaveManager.saved ;
##   Commandes : rappel clavier et manette.
## - Retour au menu : la partie suivie est écrite (SaveManager.save(), puis close_game() coupe
##   l'auto-sauvegarde), la pause est levée, puis get_tree().reload_current_scene() recharge
##   main.tscn, qui rouvre le menu (rien n'est ajouté à main.gd).
## - (bureau) « Plein écran » et « Quitter le jeu » (partie écrite, puis fermeture), hors Web
##   seulement : DesktopApp.setup_menu_buttons.

signal opened
signal closed
## Émis juste avant le rechargement de la scène courante (retour au menu).
signal quit_to_menu_started

const MenuInput := preload("res://src/ui/main_menu_input.gd")
## Rappel des commandes : action, clavier et souris, manette (input map du Lot 0).
const CONTROLS := [
	["Se déplacer", "ZQSD ou WASD, flèches", "Stick gauche"],
	["Courir", "Maj (maintenue)", "L3 (clic du stick)"],
	["Sauter", "Espace", "A"],
	["Coup d'épée", "J ou X", "X"],
	["Charge magique", "K ou C (maintenue)", "B (maintenu)"],
	["Parler, ramasser", "E", "A"],
	["Caméra", "Souris (clic pour la tenir)", "Stick droit"],
	["Zoom", "Molette", "—"],
	["Verrouiller une cible", "Clic molette", "R3 (clic du stick)"],
	["Sac", "I", "Y"],
	["Journal de quêtes", "Tab ou L", "Select"],
	["Pause", "Échap", "Start"],
	["Performances", "F3", "—"],
]

## Recharge la scène courante au retour au menu. Les tests le coupent : sous GUT, la scène
## courante est celle de GUT.
var reload_on_quit: bool = true

var _paused_by_me: bool = false
var _in_dialogue: bool = false
var _pad := MenuInput.new()

@onready var _main_panel: Control = %MainPanel
@onready var _controls_panel: Control = %ControlsPanel
@onready var _resume_button: Button = %ResumeButton
@onready var _status: Label = %Status


func _ready() -> void:
	hide()
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_ended.connect(_on_dialogue_ended)
	SaveManager.saved.connect(_on_saved)
	_resume_button.pressed.connect(close)
	(%SaveButton as Button).pressed.connect(request_save)
	(%ControlsButton as Button).pressed.connect(show_controls)
	(%QuitButton as Button).pressed.connect(quit_to_menu)
	(%ControlsBack as Button).pressed.connect(hide_controls)
	DesktopApp.setup_menu_buttons(
		%FullscreenButton as Button, %ExitGameButton as Button, "quit_game"
	)
	var grid := %ControlsGrid as GridContainer
	for row: Array in CONTROLS:
		for column in row.size():
			var label := Label.new()
			label.text = row[column]
			label.theme_type_variation = &"" if column == 0 else &"MutedLabel"
			label.add_theme_font_size_override(&"font_size", 21)
			grid.add_child(label)
	MenuInput.focus_on_hover(self)


func _exit_tree() -> void:
	# Libéré ouvert (retour au menu, fin d'un test) : le jeu ne reste pas figé.
	if _paused_by_me:
		get_tree().paused = false
		_paused_by_me = false


func is_open() -> bool:
	return visible


## Hors dialogue et si rien d'autre n'a mis le jeu en pause (inventaire, fin d'arène).
func can_open() -> bool:
	return not visible and not _in_dialogue and is_inside_tree() and not get_tree().paused


func open() -> void:
	if not can_open():
		return
	show()
	get_tree().paused = true
	_paused_by_me = true
	_set_status("")
	_pad.reset()
	hide_controls()
	opened.emit()


func close() -> void:
	if not visible:
		return
	hide()
	_pad.reset()
	if _paused_by_me:
		get_tree().paused = false
		_paused_by_me = false
	closed.emit()


## Demande une sauvegarde (SaveManager l'écrit au plus 0,5 s plus tard, même en pause).
func request_save() -> void:
	if not SaveManager.is_game_loaded():
		_set_status("Aucune partie en cours à sauvegarder.")
		return
	_set_status("Sauvegarde en cours…")
	EventBus.save_requested.emit()


func status_text() -> String:
	return _status.text


func show_controls() -> void:
	_main_panel.hide()
	_controls_panel.show()
	(%ControlsBack as Button).grab_focus()


func hide_controls() -> void:
	_controls_panel.hide()
	_main_panel.show()
	_resume_button.grab_focus()


func is_controls_shown() -> bool:
	return _controls_panel.visible


## « Retour au menu » : partie écrite, auto-sauvegarde coupée, pause levée, main.tscn rechargée.
func quit_to_menu() -> void:
	if SaveManager.is_game_loaded():
		SaveManager.save()
	SaveManager.close_game(false)
	close()
	quit_to_menu_started.emit()
	if reload_on_quit and get_tree().current_scene != null:
		get_tree().reload_current_scene()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") or (visible and event.is_action_pressed(&"ui_cancel")):
		if not visible:
			if not can_open():
				return
			open()
		elif _controls_panel.visible:
			hide_controls()
		else:
			close()
		get_viewport().set_input_as_handled()
		return
	if not visible:
		return
	var command := _pad.read(event)
	match command:
		MenuInput.Command.ACCEPT:
			MenuInput.press_focused(self)
		MenuInput.Command.BACK:
			if _controls_panel.visible:
				hide_controls()
			else:
				close()
	if command != MenuInput.Command.NONE:
		get_viewport().set_input_as_handled()


func _set_status(text: String) -> void:
	_status.text = text
	_status.visible = not text.is_empty()


func _on_dialogue_started(_npc_id: StringName) -> void:
	_in_dialogue = true


func _on_dialogue_ended(_npc_id: StringName) -> void:
	_in_dialogue = false


func _on_saved(_path: String) -> void:
	if visible:
		_set_status("Partie sauvegardée.")
