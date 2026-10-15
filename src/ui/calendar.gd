extends Control
## (E6) Le calendrier de la protagoniste (docs/REFONTE.md, 6.2 ; ACTE1.md, 0.1) : enfant Calendar
## du HUD (groupe GROUP), la page qui remplace le journal de quêtes pendant l'acte en jours.
## Propriétaire : E6.
##
## - Les jours de l'acte (StoryDirector.day_count()), le jour courant mis en avant, les jours
##   passés rayés, le jour du départ entouré dès le premier jour ; sous la grille, les lignes
##   écrites au coucher (GameState.calendar(), textes StoryDirector.calendar_line) ; en bas,
##   l'indice du moment.
## - S'ouvre par l'action « journal » (Tab, L, Select) pendant l'acte en jours (lue dans _input :
##   le journal de quêtes ne la reçoit plus), par le bouton « Calendrier » du menu pause, et en
##   examinant le calendrier de la chambre (StoryDirector.calendar_requested). Ouvert, il met le
##   jeu en pause (PROCESS_MODE_ALWAYS) ; journal, Échap ou « Fermer » le referment, et l'indice
##   se rappelle (StoryHint.recall).
## - Aucun style en dur : panneaux et textes prennent le thème du HUD ; les couleurs de la page
##   (papier, encre, trait, cercle, jour courant) se lisent dans le type de thème « Calendar »
##   (couleurs paper, ink, strike, ring, today), à défaut DEFAULT_COLORS.

signal opened
signal closed

const GROUP := &"story_calendar"
const CELL_SIZE := Vector2(118, 96)
## Type de thème des couleurs de la page, et leurs valeurs quand le thème ne les donne pas.
const THEME_TYPE := &"Calendar"
const DEFAULT_COLORS := {
	&"paper": Color(1.0, 0.98, 0.94, 0.9),
	&"ink": Color(0.33, 0.22, 0.4),
	&"strike": Color(0.75, 0.22, 0.2, 0.85),
	&"ring": Color(0.82, 0.33, 0.43),
	&"today": Color(1.0, 0.84, 0.45, 0.55),
}

var _paused_by_me: bool = false
var _in_dialogue: bool = false

@onready var _title: Label = %CalendarTitle
@onready var _grid: GridContainer = %Days
@onready var _lines: VBoxContainer = %Lines
@onready var _hint: Label = %CalendarHint


func _ready() -> void:
	add_to_group(GROUP)
	hide()
	(%CloseButton as Button).pressed.connect(close)
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_ended.connect(_on_dialogue_ended)
	StoryDirector.calendar_requested.connect(open)
	var pause_menu := get_parent().get_node_or_null(^"PauseMenu")
	if pause_menu != null and pause_menu.has_signal(&"calendar_requested"):
		pause_menu.connect(&"calendar_requested", open)


func _exit_tree() -> void:
	if _paused_by_me:
		get_tree().paused = false
		_paused_by_me = false


func is_open() -> bool:
	return visible


## Ouvre la page (pendant l'acte en jours, hors dialogue) et met le jeu en pause.
func open() -> void:
	if visible or _in_dialogue or not GameState.story_running() or not is_inside_tree():
		return
	refresh()
	show()
	if not get_tree().paused:
		get_tree().paused = true
		_paused_by_me = true
	(%CloseButton as Button).grab_focus()
	opened.emit()


## Referme la page, relance le jeu et rappelle l'indice.
func close() -> void:
	if not visible:
		return
	hide()
	if _paused_by_me:
		get_tree().paused = false
		_paused_by_me = false
	closed.emit()
	var hint := get_tree().get_first_node_in_group(&"story_hint")
	if hint != null and hint.has_method(&"recall"):
		hint.call(&"recall")


func toggle() -> void:
	if visible:
		close()
	else:
		open()


## Relit le récit : jours, lignes écrites, indice.
func refresh() -> void:
	_title.text = StoryDirector.ui_text("calendar_title", "Le calendrier de {player}")
	for child: Node in _grid.get_children():
		child.queue_free()
	var count := StoryDirector.day_count()
	_grid.columns = 6 if count > 6 else maxi(count, 1)
	for day: int in range(1, count + 1):
		_grid.add_child(_day_cell(day))
	for child: Node in _lines.get_children():
		child.queue_free()
	var written := GameState.calendar()
	var days: Array = written.keys()
	days.sort()
	for day: int in days:
		var row := Label.new()
		row.text = "%s — %s" % [_day_label(day), StoryDirector.calendar_line(day)]
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_theme_font_size_override(&"font_size", 22)
		_lines.add_child(row)
	if days.is_empty():
		var empty := Label.new()
		empty.text = StoryDirector.ui_text("calendar_empty", "Rien d'écrit encore.")
		empty.theme_type_variation = &"MutedLabel"
		_lines.add_child(empty)
	var hint := StoryDirector.hint()
	_hint.text = (
		"%s : %s" % [StoryDirector.ui_text("hint_label", "En ce moment"), hint]
		if not hint.is_empty()
		else ""
	)
	_hint.visible = not hint.is_empty()


## Couleur de la page (paper, ink, strike, ring, today) : celle du thème (type Calendar), à
## défaut DEFAULT_COLORS.
func page_color(color_name: StringName) -> Color:
	if has_theme_color(color_name, THEME_TYPE):
		return get_theme_color(color_name, THEME_TYPE)
	return DEFAULT_COLORS.get(color_name, Color.WHITE)


## Lignes affichées (tests) : « Jour N — texte ».
func shown_lines() -> PackedStringArray:
	var result := PackedStringArray()
	for child: Node in _lines.get_children():
		if child is Label and not child.is_queued_for_deletion():
			result.append((child as Label).text)
	return result


func _day_label(day: int) -> String:
	return StoryDirector.ui_text("day", "Jour {day}").replace("{day}", str(day))


func _day_cell(day: int) -> Control:
	var cell := Panel.new()
	cell.custom_minimum_size = CELL_SIZE
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.set_meta(&"day", day)
	var label := Label.new()
	label.text = str(day)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override(&"font_size", 34)
	label.add_theme_color_override(&"font_color", page_color(&"ink"))
	cell.add_child(label)
	if day == StoryDirector.departure_day():
		var note := Label.new()
		note.text = StoryDirector.ui_text("departure", "Départ")
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		note.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		note.offset_top = -26
		note.add_theme_font_size_override(&"font_size", 16)
		note.add_theme_color_override(&"font_color", page_color(&"ring"))
		cell.add_child(note)
	cell.draw.connect(_draw_cell.bind(cell, day))
	return cell


func _draw_cell(cell: Control, day: int) -> void:
	var rect := Rect2(Vector2.ZERO, cell.size)
	cell.draw_rect(rect, page_color(&"paper"))
	cell.draw_rect(rect, Color(page_color(&"ink"), 0.35), false, 2.0)
	if day == GameState.day:
		cell.draw_rect(rect.grow(-4), page_color(&"today"))
	if day < GameState.day:
		# Les jours passés sont rayés, de sa main (ACTE1.md, 0.1).
		var strike := page_color(&"strike")
		cell.draw_line(rect.position + Vector2(14, 16), rect.end - Vector2(14, 16), strike, 4.0)
	if day == StoryDirector.departure_day():
		var center := rect.get_center() - Vector2(0, 6)
		cell.draw_arc(center, 30.0, 0.0, TAU, 40, page_color(&"ring"), 3.0)


func _input(event: InputEvent) -> void:
	if not GameState.story_running() or not is_inside_tree():
		return
	if visible:
		for action: StringName in [&"journal", &"ui_cancel", &"pause"]:
			if event.is_action_pressed(action):
				close()
				get_viewport().set_input_as_handled()
				return
		return
	if event.is_action_pressed(&"journal") and not get_tree().paused and not _in_dialogue:
		open()
		get_viewport().set_input_as_handled()


func _on_dialogue_started(_npc_id: StringName) -> void:
	_in_dialogue = true


func _on_dialogue_ended(_npc_id: StringName) -> void:
	_in_dialogue = false
