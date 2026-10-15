class_name DialogueBox
extends Control
## Boîte de dialogue en bas d'écran (PLAN.md section 4). Propriétaire : L6.
## Instanciée dans game.tscn sous UI/DialogueBox ; masquée hors dialogue. N'écoute que l'EventBus :
## - dialogue_started(npc_id) : portrait du PNJ, retrouvé par data/npcs/<npc_id>.tres
##   (DialogueRunner.find_npc ; SkinData.portrait, sinon la 1re image de « repos » de sa planche) ;
## - dialogue_line(speaker, text, choices) : nom, texte lettre par lettre, puis 2 choix au plus ;
##   (Systèmes et textes) portrait de l'orateur de la réplique, DialogueRunner.current_speaker_id()
##   (le "speaker_id" du nœud : scènes à plusieurs voix), sinon celui du PNJ du dialogue ;
## - dialogue_ended : la boîte se ferme.
## Commandes : interact ou ui_accept termine la ligne, un second appui passe à la suite ou valide
## le choix sélectionné ; ui_up / ui_down (ou move_forward / move_back) changent de choix ; la
## souris sélectionne au survol et valide au clic, un clic sur la boîte vaut interact.
## Répond par EventBus.dialogue_choice_made(index), -1 pour « suite ». Tant que la boîte est
## ouverte, ces touches sont lues dans _input et consommées (le jeu ne les reçoit pas).
##
## (U1) Deux présentations, au style du thème src/ui/wordend_theme.tres (UiStyle) :
## - &"nuit" (défaut) : panneau de verre dépoli prune, filet doré, nom en serif doré, portrait en
##   buste qui déborde du panneau à gauche et s'estompe vers le bas, triangle doré qui respire ;
## - &"bandeau" (les scènes du récit, sans contrôle du joueur) : pas de boîte, un dégradé sombre
##   monte du bas de l'écran, nom en capitales serif espacées, texte blanc ombré.
## DialogueBox.set_presentation(&"bandeau") la choisit pour la boîte ouverte et les suivantes,
## jusqu'au prochain appel (set_presentation(&"nuit") à la fin de la scène). Les choix (deux au
## plus) gardent le même panneau dans les deux présentations.

enum State { HIDDEN, TYPING, WAITING, CHOOSING, ANSWERED }

## Dossier des PNJ (portraits) : celui de DialogueRunner.find_npc.
const NPCS_DIR := DialogueRunner.NPCS_DIR
## Présentations (set_presentation).
const PRESENTATION_NUIT := &"nuit"
const PRESENTATION_BANDEAU := &"bandeau"
const PRESENTATIONS: Array[StringName] = [PRESENTATION_NUIT, PRESENTATION_BANDEAU]
## Groupe des boîtes de dialogue (set_presentation s'applique aux boîtes déjà là).
const GROUP := &"dialogue_box"
## Type du thème qui porte les couleurs de l'indicateur et la géométrie des présentations.
const THEME_TYPE := &"DialogueBox"

## Présentation demandée (commune à toutes les boîtes).
static var _presentation: StringName = PRESENTATION_NUIT

## Vitesse d'affichage du texte (caractères par seconde) ; 0 = texte affiché d'un coup.
@export var characters_per_second: float = 40.0

var _state: State = State.HIDDEN
## PNJ du dialogue (dialogue_started) et PNJ dont le portrait est affiché.
var _dialogue_npc: StringName = &""
var _portrait_npc: StringName = &""
var _choice_count: int = 0
var _selected: int = 0
var _revealed: float = 0.0
var _blink: float = 0.0
var _buttons: Array[Button] = []
## Présentation appliquée à cette boîte (&"" : pas encore).
var _shown_presentation: StringName = &""

@onready var _veil: Control = %Veil
@onready var _layout: Control = %Layout
@onready var _choices_row: Control = %ChoicesRow
@onready var _choices_panel: Control = %ChoicesPanel
@onready var _panel: Control = %Panel
@onready var _portrait_frame: Control = %PortraitFrame
@onready var _portrait: TextureRect = %Portrait
@onready var _name_plate: Control = %NamePlate
@onready var _name_label: Label = %NameLabel
@onready var _text: Label = %Text
@onready var _hint: Control = %NextHint


func _ready() -> void:
	add_to_group(GROUP)
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
	_portrait.resized.connect(_fit_portrait_fade)
	UiStyle.frost(_choices_panel)
	apply_presentation()
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
		# Respiration douce de l'indicateur de suite (période breath_ms du thème).
		_blink += delta
		var phase := _blink * TAU / maxf(UiStyle.seconds(&"breath_ms"), 0.1)
		_hint.modulate.a = 0.6 + 0.4 * cos(phase)
		_hint.position.y = _hint_rest_y() + 2.0 * (1.0 - cos(phase)) * 0.5


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


## PNJ dont le portrait est affiché (orateur de la réplique), &"" sans portrait.
func portrait_npc() -> StringName:
	return _portrait_npc if _portrait_frame.visible else &""


## Choisit la présentation des dialogues (&"nuit" ou &"bandeau") : la boîte ouverte change tout
## de suite, les suivantes l'ont aussi, jusqu'au prochain appel. Une autre valeur est refusée.
static func set_presentation(presentation_id: StringName) -> void:
	if not presentation_id in PRESENTATIONS:
		push_warning("DialogueBox : présentation inconnue %s" % presentation_id)
		return
	_presentation = presentation_id
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	for node: Node in tree.get_nodes_in_group(GROUP):
		(node as DialogueBox).apply_presentation()


## Présentation demandée (&"nuit" par défaut).
static func presentation() -> StringName:
	return _presentation


## Présentation affichée par cette boîte.
func shown_presentation() -> StringName:
	return _shown_presentation


## Met la boîte dans la présentation demandée (set_presentation) : styles du thème, place du
## panneau, du portrait et du texte, verre dépoli, dégradé du bandeau.
func apply_presentation() -> void:
	var bandeau := _presentation == PRESENTATION_BANDEAU
	_shown_presentation = _presentation
	var prefix := "bandeau_" if bandeau else "nuit_"
	_veil.visible = bandeau
	_panel.theme_type_variation = &"BandeauPanel" if bandeau else &"DialoguePanel"
	_name_label.theme_type_variation = &"BandeauName" if bandeau else &"DialogueName"
	_name_label.uppercase = bandeau
	_text.theme_type_variation = &"BandeauText" if bandeau else &"DialogueText"
	if bandeau:
		UiStyle.unfrost(_panel)
	else:
		UiStyle.frost(_panel)
	var box := _panel.get_theme_stylebox(&"panel")
	var margin_left := box.content_margin_left if box != null else 0.0
	var margin_bottom := box.content_margin_bottom if box != null else 0.0
	var left := float(_geometry("bandeau_left" if bandeau else "nuit_side"))
	_layout.offset_left = left
	_layout.offset_right = -float(_geometry("bandeau_right" if bandeau else "nuit_side"))
	_layout.offset_bottom = -float(_geometry(prefix + "bottom"))
	_layout.offset_top = _layout.offset_bottom - float(_geometry(prefix + "height"))
	_panel.custom_minimum_size.y = float(_geometry(prefix + "height"))
	# Le texte commence à text_left : depuis le bord du panneau (nuit), de l'écran (bandeau).
	var text_left := float(_geometry(prefix + "text_left")) - (left if bandeau else 0.0)
	_portrait_frame.custom_minimum_size.x = maxf(text_left - margin_left, 0.0)
	var portrait_size := float(_geometry(prefix + "portrait"))
	var portrait_left := 0.0 if bandeau else float(_geometry("nuit_portrait_left")) - margin_left
	var portrait_bottom := margin_bottom - float(_geometry(prefix + "portrait_drop"))
	if bandeau:
		portrait_bottom = -float(_geometry("bandeau_portrait_drop"))
	_portrait.offset_left = portrait_left
	_portrait.offset_right = portrait_left + portrait_size
	_portrait.offset_bottom = portrait_bottom
	_portrait.offset_top = portrait_bottom - portrait_size
	var fade := _portrait.material as ShaderMaterial
	if fade != null:
		fade.set_shader_parameter(&"fade_from", _geometry(prefix + "fade_pct") / 100.0)
	_fit_portrait_fade()
	_hint.queue_redraw()


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


## Portrait du PNJ npc_id (data/npcs/<npc_id>.tres, DialogueRunner.find_npc), null s'il est
## inconnu.
static func portrait_for(npc_id: StringName) -> Texture2D:
	var npc := DialogueRunner.find_npc(npc_id)
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
	if _shown_presentation != _presentation:
		apply_presentation()
	if visible:
		return
	show()
	UiStyle.appear(_layout, Vector2.DOWN)


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
	var color_name := (
		&"hint_bandeau" if _shown_presentation == PRESENTATION_BANDEAU else &"hint_nuit"
	)
	_hint.draw_colored_polygon(points, get_theme_color(color_name, THEME_TYPE))


## Ordonnée de repos de l'indicateur (bas de sa rangée).
func _hint_rest_y() -> float:
	var row := _hint.get_parent_control()
	return row.size.y - _hint.size.y if row != null else _hint.position.y


## Constante de géométrie name (type DialogueBox du thème).
func _geometry(geometry_name: String) -> int:
	return get_theme_constant(StringName(geometry_name), THEME_TYPE)


## Le fondu du portrait suit sa hauteur.
func _fit_portrait_fade() -> void:
	var fade := _portrait.material as ShaderMaterial
	if fade != null:
		fade.set_shader_parameter(&"height", _portrait.size.y)


## Portrait du PNJ npc_id (cadre caché s'il n'en a pas) ; rien à relire s'il est déjà affiché.
func _show_portrait(npc_id: StringName) -> void:
	if npc_id == _portrait_npc and _portrait.texture != null:
		return
	_portrait_npc = npc_id
	var portrait := portrait_for(npc_id)
	_portrait.texture = portrait
	_portrait_frame.visible = portrait != null


func _on_dialogue_started(npc_id: StringName) -> void:
	_dialogue_npc = npc_id
	_show_portrait(npc_id)


func _on_dialogue_line(speaker: String, text: String, choices: Array) -> void:
	var speaker_id := DialogueRunner.current_speaker_id()
	_show_portrait(speaker_id if not speaker_id.is_empty() else _dialogue_npc)
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
	UiStyle.settle(_layout)
	hide()
	set_process(false)
	_dialogue_npc = &""
	_portrait_npc = &""
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
