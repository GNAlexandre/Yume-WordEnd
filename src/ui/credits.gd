extends Control
## Crédits (L10), ouverts par le menu principal. Le texte est dans la scène (les .md ne sont pas
## exportés dans le build Web) : il reprend assets/CREDITS.md et assets/characters/CREDITS.md et
## l'hommage à SukaSuka ; la licence du moteur (Engine.get_license_text()) est ajoutée à la fin.
## Défilable à la molette, au doigt, aux flèches, à la croix et au stick gauche ; « Retour »,
## Échap ou B (manette) émettent closed : le menu libère alors l'écran.

signal closed

const MenuInput := preload("res://src/ui/main_menu_input.gd")
## Défilement par appui sur haut / bas (pixels).
const SCROLL_STEP := 80

var _pad := MenuInput.new()

@onready var _scroll: ScrollContainer = %Scroll
@onready var _text: RichTextLabel = %Text
@onready var _license: Label = %EngineLicense
@onready var _back: Button = %BackButton


func _ready() -> void:
	_license.text = Engine.get_license_text()
	_back.pressed.connect(close)
	MenuInput.focus_on_hover(self)
	_back.grab_focus.call_deferred()


## Texte affiché : crédits de la scène puis licence du moteur.
func full_text() -> String:
	return _text.get_parsed_text() + "\n" + _license.text


func close() -> void:
	closed.emit()


func scroll_by(pixels: int) -> void:
	_scroll.scroll_vertical += pixels


func _input(event: InputEvent) -> void:
	# Avant l'interface : haut / bas font défiler (un seul bouton, rien à parcourir au focus).
	if not is_visible_in_tree():
		return
	var step := 0
	if event.is_action_pressed(&"ui_down", true):
		step = SCROLL_STEP
	elif event.is_action_pressed(&"ui_up", true):
		step = -SCROLL_STEP
	elif event.is_action_pressed(&"ui_page_down", true):
		step = int(_scroll.size.y * 0.8)
	elif event.is_action_pressed(&"ui_page_up", true):
		step = -int(_scroll.size.y * 0.8)
	if step != 0:
		scroll_by(step)
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	var command := _pad.read(event)
	match command:
		MenuInput.Command.ACCEPT:
			MenuInput.press_focused(self)
		MenuInput.Command.BACK:
			close()
	if command != MenuInput.Command.NONE:
		get_viewport().set_input_as_handled()
