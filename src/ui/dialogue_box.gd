class_name DialogueBox
extends Control
## Boîte de dialogue en bas d'écran (PLAN.md section 4). Propriétaire : L6.
## Instanciée dans game.tscn sous UI/DialogueBox ; masquée hors dialogue. N'écoute que l'EventBus :
## - dialogue_started(npc_id) : portrait du PNJ, retrouvé par data/npcs/<npc_id>.tres
##   (SkinData.portrait, sinon la 1re image de « repos » de sa planche) ;
## - dialogue_line(speaker, text, choices) : nom, texte lettre par lettre, puis 2 choix au plus ;
## - dialogue_ended : la boîte se ferme.
## Commandes : interact ou ui_accept termine la ligne, un second appui passe à la suite ou valide
## le choix sélectionné ; ui_up / ui_down (ou move_forward / move_back) changent de choix ; la
## souris sélectionne au survol et valide au clic, un clic sur la boîte vaut interact.
## Répond par EventBus.dialogue_choice_made(index), -1 pour « suite ». Tant que la boîte est
## ouverte, ces touches sont lues dans _input et consommées (le jeu ne les reçoit pas).

enum State { HIDDEN, TYPING, WAITING, CHOOSING, ANSWERED }

const NPCS_DIR := "res://data/npcs"
## Durée du fondu d'ouverture (s).
const FADE_TIME := 0.15

## Vitesse d'affichage du texte (caractères par seconde) ; 0 = texte affiché d'un coup.
@export var characters_per_second: float = 40.0

var _state: State = State.HIDDEN
var _choice_count: int = 0
var _selected: int = 0
var _revealed: float = 0.0
var _blink: float = 0.0
var _buttons: Array[Button] = []
var _fade: Tween

@onready var _choices_row: Control = %ChoicesRow
@onready var _panel: Control = %Panel
@onready var _portrait_frame: Control = %PortraitFrame
@onready var _portrait: TextureRect = %Portrait
@onready var _name_plate: Control = %NamePlate
@onready var _name_label: Label = %NameLabel
@onready var _text: Label = %Text
@onready var _hint: Control = %NextHint


func _ready() -> void:
	hide()
	set_process(false)
	_text.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	_buttons.assign([%Choice0, %Choice1])
	for index: int in _buttons.size():
		_buttons[index].pressed.connect(choose.bind(index))
		_buttons[index].mouse_entered.connect(select.bind(index))
		_buttons[index].focus_entered.connect(_on_choice_focused.bind(index))
	_panel.gui_input.connect(_on_panel_gui_input)
	_hint.draw.connect(_draw_hint)
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_line.connect(_on_dialogue_line)
	EventBus.dialogue_ended.connect(_on_dialogue_ended)


func _process(delta: float) -> void:
	if _state == State.TYPING:
		_revealed += delta * characters_per_second
		if _revealed >= _text.text.length():
			complete_line()
		else:
			_text.visible_characters = int(_revealed)
	elif _state == State.WAITING:
		_blink += delta
		_hint.modulate.a = 0.6 + 0.4 * cos(_blink * 5.0)


func _input(event: InputEvent) -> void:
	if _state == State.HIDDEN or event.is_echo():
		return
	if event.is_action_pressed(&"interact") or event.is_action_pressed(&"ui_accept"):
		advance()
	elif _state == State.CHOOSING and _is_any_pressed(event, [&"ui_up", &"move_forward"]):
		select(maxi(_selected - 1, 0))
	elif _state == State.CHOOSING and _is_any_pressed(event, [&"ui_down", &"move_back"]):
		select(mini(_selected + 1, _choice_count - 1))
	else:
		return
	get_viewport().set_input_as_handled()


## true tant qu'un dialogue est affiché.
func is_open() -> bool:
	return _state != State.HIDDEN


## true pendant l'affichage lettre par lettre.
func is_typing() -> bool:
	return _state == State.TYPING


## true quand la ligne est entière et attend « suite » (pas de choix).
func is_waiting() -> bool:
	return _state == State.WAITING


## true quand les choix sont affichés.
func is_choosing() -> bool:
	return _state == State.CHOOSING


## Index du choix sélectionné (surligné).
func selected_choice() -> int:
	return _selected


## Même effet qu'un appui sur interact : termine la ligne, puis passe à la suite ou valide le
## choix sélectionné.
func advance() -> void:
	match _state:
		State.TYPING:
			complete_line()
		State.WAITING:
			_answer(-1)
		State.CHOOSING:
			choose(_selected)


## Affiche toute la ligne en cours, puis l'indicateur de suite ou les choix.
func complete_line() -> void:
	if _state != State.TYPING:
		return
	_text.visible_characters = -1
	if _choice_count == 0:
		_state = State.WAITING
		_blink = 0.0
		_hint.show()
	else:
		_state = State.CHOOSING
		_choices_row.show()
		select(0)


## Sélectionne (surligne) le choix index, sans le valider.
func select(index: int) -> void:
	if _state != State.CHOOSING or index < 0 or index >= _choice_count:
		return
	_selected = index
	if _buttons[index].is_visible_in_tree():
		_buttons[index].grab_focus()


## Valide le choix index : émet EventBus.dialogue_choice_made(index).
func choose(index: int) -> void:
	if _state != State.CHOOSING or index < 0 or index >= _choice_count:
		return
	_answer(index)


## Portrait du PNJ npc_id (data/npcs/<npc_id>.tres), null s'il est inconnu.
static func portrait_for(npc_id: StringName) -> Texture2D:
	var path := "%s/%s.tres" % [NPCS_DIR, npc_id]
	if npc_id.is_empty() or not ResourceLoader.exists(path):
		return null
	var npc := load(path) as NpcData
	if npc == null or npc.skin == null:
		return null
	return portrait_of(npc.skin)


## SkinData.portrait, sinon la 1re image de « repos » de la planche, sinon null.
static func portrait_of(skin: SkinData) -> Texture2D:
	if skin.portrait != null:
		return skin.portrait
	if skin.sprite_sheet == null or skin.frames_json == null:
		return null
	var frame := _first_idle_frame(skin.frames_json.data)
	if frame.size() < 4:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = skin.sprite_sheet
	atlas.region = Rect2(float(frame[0]), float(frame[1]), float(frame[2]), float(frame[3]))
	return atlas


## [x, y, largeur, hauteur, ancreX, ancreY] de la 1re image de « repos » ([] si absente).
static func _first_idle_frame(sheet: Variant) -> Array:
	var anims: Variant = sheet.get("animations") if sheet is Dictionary else null
	var idle: Variant = anims.get("repos") if anims is Dictionary else null
	var images: Variant = idle.get("images") if idle is Dictionary else null
	if images is Array and not (images as Array).is_empty() and (images as Array)[0] is Array:
		return (images as Array)[0]
	return []


func _answer(index: int) -> void:
	# L'état change avant l'émission : le runner répond tout de suite (ligne suivante ou fin).
	_state = State.ANSWERED
	_hint.hide()
	_choices_row.hide()
	_release_choice_focus()
	EventBus.dialogue_choice_made.emit(index)


func _open() -> void:
	if visible:
		return
	show()
	modulate.a = 0.0
	if _fade != null:
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(self, ^"modulate:a", 1.0, FADE_TIME)


func _release_choice_focus() -> void:
	if not is_inside_tree():
		return
	var focused := get_viewport().gui_get_focus_owner()
	for button: Button in _buttons:
		if button == focused:
			button.release_focus()


func _is_any_pressed(event: InputEvent, actions: Array[StringName]) -> bool:
	for action: StringName in actions:
		if event.is_action_pressed(action):
			return true
	return false


func _draw_hint() -> void:
	var extent := _hint.size
	var points := PackedVector2Array(
		[Vector2.ZERO, Vector2(extent.x, 0.0), Vector2(extent.x * 0.5, extent.y)]
	)
	_hint.draw_colored_polygon(points, get_theme_color(&"accent", &"DialogueBox"))


func _on_dialogue_started(npc_id: StringName) -> void:
	var portrait := portrait_for(npc_id)
	_portrait.texture = portrait
	_portrait_frame.visible = portrait != null


func _on_dialogue_line(speaker: String, text: String, choices: Array) -> void:
	_name_label.text = speaker
	_name_plate.visible = not speaker.is_empty()
	_text.text = text
	_text.visible_characters = 0
	_revealed = 0.0
	_choice_count = mini(choices.size(), _buttons.size())
	for index: int in _buttons.size():
		_buttons[index].visible = index < _choice_count
		_buttons[index].text = str(choices[index]) if index < _choice_count else ""
	_selected = 0
	_hint.hide()
	_choices_row.hide()
	_state = State.TYPING
	set_process(true)
	_open()
	if text.strip_edges().is_empty() or characters_per_second <= 0.0:
		complete_line()


func _on_dialogue_ended(_npc_id: StringName) -> void:
	_state = State.HIDDEN
	_release_choice_focus()
	hide()
	set_process(false)
	_portrait.texture = null
	_portrait_frame.hide()


func _on_choice_focused(index: int) -> void:
	if _state == State.CHOOSING and index < _choice_count:
		_selected = index


func _on_panel_gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	if _state == State.TYPING or _state == State.WAITING:
		advance()
		_panel.accept_event()
