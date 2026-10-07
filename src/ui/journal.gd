extends Control
## Journal de quêtes (Lot Q), enfant « Journal » du HUD (game.tscn est figé, comme PauseMenu) :
## les quêtes actives puis terminées (principales d'abord), et pour la quête choisie son
## résumé, qui l'a confiée, ses étapes (validées, puis l'étape courante avec son aide et sa
## progression ; les suivantes restent cachées) et sa récompense.
##
## Écran modal comme l'inventaire (L7) : open() met le jeu en pause, close() la lève, racine en
## PROCESS_MODE_ALWAYS. L'action « journal » (Tab ou L, bouton Select / Back) l'ouvre dans
## _unhandled_input et le ferme ; ouvert, « ui_cancel » (Échap), « pause », « inventory » ou un
## clic hors du panneau le ferment aussi (événement consommé). Ne s'ouvre ni pendant un dialogue
## ni si le jeu est déjà en pause (menu pause, inventaire, fin d'arène). Choisir une quête :
## flèches, croix, stick, survol ; la valider (Entrée, A, clic) en fait la quête suivie
## (GameState.tracked_quest, affichée par le HUD). Manette : A presse, B ferme, au relâchement
## (src/ui/main_menu_input.gd, comme les écrans du L10). Lectures : GameState et QuestData, à
## chaque ouverture (le jeu est figé tant qu'il est ouvert).

## Le journal vient de s'ouvrir / de se fermer.
signal opened
signal closed

const MenuInput := preload("res://src/ui/main_menu_input.gd")
const QUEST_ICON := preload("res://assets/ui/quest.png")
const TITLE_COLOR := Color(0.33, 0.22, 0.4)
const MUTED_COLOR := Color(0.53, 0.4, 0.48)
const ACCENT_COLOR := Color(0.82, 0.33, 0.43)
const DONE_COLOR := Color(0.42, 0.72, 0.47)
const CURRENT_COLOR := Color(1.0, 0.72, 0.25)
## Côté (px) de la pastille d'une étape.
const MARK_SIZE := 26.0

var _paused_by_me: bool = false
var _dialogue_running: bool = false
var _pad := MenuInput.new()
var _entries: Dictionary[StringName, Button] = {}
var _order: Array[StringName] = []
var _selected: StringName = &""

@onready var _dim: ColorRect = %Dim
@onready var _list: VBoxContainer = %List
@onready var _close_button: Button = %CloseButton
@onready var _quest_title: Label = %QuestTitle
@onready var _kind: Label = %Kind
@onready var _summary: Label = %Summary
@onready var _steps: VBoxContainer = %Steps
@onready var _rewards: Label = %Rewards
@onready var _track_hint: Label = %TrackHint


func _ready() -> void:
	hide()
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_ended.connect(_on_dialogue_ended)
	_close_button.pressed.connect(close)
	_dim.gui_input.connect(_on_dim_gui_input)
	MenuInput.focus_on_hover(self)


func _exit_tree() -> void:
	# Libéré ouvert (retour au menu, fin d'un test) : le jeu ne reste pas figé.
	if _paused_by_me:
		get_tree().paused = false
		_paused_by_me = false


func is_open() -> bool:
	return visible


## Ouvre le journal et met le jeu en pause (sans effet pendant un dialogue ou une pause).
func open() -> void:
	if visible or _dialogue_running or not is_inside_tree() or get_tree().paused:
		return
	visible = true
	get_tree().paused = true
	_paused_by_me = true
	_pad.reset()
	refresh()
	_focus_selection()
	opened.emit()


## Ferme le journal et relance le jeu (s'il l'avait mis en pause).
func close() -> void:
	if not visible:
		return
	visible = false
	_pad.reset()
	if _paused_by_me:
		get_tree().paused = false
		_paused_by_me = false
	closed.emit()


func toggle() -> void:
	if visible:
		close()
	else:
		open()


## Quêtes listées, dans l'ordre affiché (actives puis terminées).
func listed_quests() -> Array[StringName]:
	return _order.duplicate()


## Quête dont le détail est affiché (&"" : aucune).
func selected_quest() -> StringName:
	return _selected


## Affiche le détail de quest_id (si elle est listée).
func select(quest_id: StringName) -> void:
	if not _entries.has(quest_id):
		return
	_selected = quest_id
	_show_details()


## Étapes affichées pour la quête choisie : [{"id", "objective", "state" (&"done" ou
## &"current"), "progress"}], dans l'ordre.
func shown_steps() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for row: Node in _steps.get_children():
		if row.is_queued_for_deletion():
			continue
		result.append(row.get_meta(&"step"))
	return result


## Fait de quest_id la quête suivie, si elle est active.
func track(quest_id: StringName) -> void:
	if GameState.quest_state(quest_id) != GameState.QUEST_ACTIVE:
		return
	GameState.tracked_quest = quest_id
	_update_entries()
	_show_details()


## Relit les quêtes (GameState, QuestData) et reconstruit la liste.
func refresh() -> void:
	var previous := _selected
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	_entries.clear()
	_order.clear()
	_add_section("En cours", QuestData.active_ids(), true)
	_add_section("Terminées", QuestData.done_ids(), false)
	if _order.is_empty():
		_list.add_child(_muted_label("Aucune quête pour l’instant.", 20))
	MenuInput.focus_on_hover(self)
	_update_entries()
	if _entries.has(previous):
		_selected = previous
	elif _entries.has(QuestData.shown_quest()):
		_selected = QuestData.shown_quest()
	else:
		_selected = _order[0] if not _order.is_empty() else &""
	_show_details()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	for action: StringName in [&"journal", &"ui_cancel", &"pause", &"inventory"]:
		if event.is_action_pressed(action):
			close()
			get_viewport().set_input_as_handled()
			return
	var command := _pad.read(event)
	match command:
		MenuInput.Command.ACCEPT:
			MenuInput.press_focused(self)
		MenuInput.Command.BACK:
			close()
	if command != MenuInput.Command.NONE:
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not visible and event.is_action_pressed(&"journal"):
		open()
		if visible:
			get_viewport().set_input_as_handled()


# --- Liste ------------------------------------------------------------------------------------


func _add_section(title: String, ids: Array[StringName], active: bool) -> void:
	var shown: Array[StringName] = []
	for quest_id: StringName in ids:
		if QuestData.find(quest_id) != null:
			shown.append(quest_id)
	if shown.is_empty():
		return
	var header := Label.new()
	header.text = title
	header.add_theme_color_override(&"font_color", ACCENT_COLOR)
	header.add_theme_font_size_override(&"font_size", 20)
	_list.add_child(header)
	for quest_id: StringName in shown:
		var quest := QuestData.find(quest_id)
		var button := Button.new()
		button.name = "Quest_" + String(quest_id)
		button.text = quest.title
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.custom_minimum_size = Vector2(300, 0)
		button.add_theme_font_size_override(&"font_size", 21)
		if not active:
			button.add_theme_color_override(&"font_color", MUTED_COLOR)
		button.focus_entered.connect(select.bind(quest_id))
		button.pressed.connect(_on_entry_pressed.bind(quest_id))
		_list.add_child(button)
		_entries[quest_id] = button
		_order.append(quest_id)


## Icône de la quête suivie sur son entrée.
func _update_entries() -> void:
	for quest_id: StringName in _entries:
		var tracked := quest_id == GameState.tracked_quest
		_entries[quest_id].icon = QUEST_ICON if tracked else null


func _focus_selection() -> void:
	if _entries.has(_selected):
		_entries[_selected].grab_focus()
	else:
		_close_button.grab_focus()


func _on_entry_pressed(quest_id: StringName) -> void:
	select(quest_id)
	track(quest_id)


# --- Détail -----------------------------------------------------------------------------------


func _show_details() -> void:
	for row: Node in _steps.get_children():
		_steps.remove_child(row)
		row.queue_free()
	var quest := QuestData.find(_selected) if not _selected.is_empty() else null
	if quest == null:
		_quest_title.text = "Journal vide"
		_kind.text = ""
		_summary.text = "Parle aux fées de l’entrepôt et aux gens du bourg : certains ont besoin d’aide."
		_rewards.text = ""
		_track_hint.text = ""
		return
	var state := GameState.quest_state(quest.id)
	_quest_title.text = quest.title
	var kind := "Quête principale" if quest.main else "Quête secondaire"
	var giver := _npc_name(quest.giver_npc)
	if not giver.is_empty():
		kind += " · " + giver
	if state == GameState.QUEST_DONE:
		kind += " · terminée"
	_kind.text = kind
	_summary.text = quest.summary
	_summary.visible = not quest.summary.is_empty()
	var current := quest.current_index()
	for index: int in mini(current + 1, quest.steps.size()):
		var step := quest.steps[index]
		var done := index < current
		var progress := "" if done else step.progress_text(GameState.quest_step_count(quest.id))
		_steps.add_child(_step_row(step, done, progress))
	_rewards.text = _rewards_text(quest)
	_rewards.visible = not _rewards.text.is_empty()
	if state != GameState.QUEST_ACTIVE:
		_track_hint.text = ""
	elif quest.id == GameState.tracked_quest:
		_track_hint.text = "Quête suivie : son objectif est affiché en jeu."
	else:
		_track_hint.text = "Entrée / A : suivre cette quête."


func _step_row(step: QuestStep, done: bool, progress: String) -> Control:
	var row := HBoxContainer.new()
	row.name = "Step_" + String(step.id)
	row.add_theme_constant_override(&"separation", 12)
	(
		row
		. set_meta(
			&"step",
			{
				"id": step.id,
				"objective": step.objective,
				"state": &"done" if done else &"current",
				"progress": progress,
			}
		)
	)
	var mark := Control.new()
	mark.custom_minimum_size = Vector2(MARK_SIZE, MARK_SIZE)
	mark.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	mark.draw.connect(_draw_mark.bind(mark, done))
	row.add_child(mark)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override(&"separation", 2)
	var objective := Label.new()
	objective.name = "Objective"
	objective.text = step.objective
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective.add_theme_font_size_override(&"font_size", 21)
	objective.add_theme_color_override(&"font_color", MUTED_COLOR if done else TITLE_COLOR)
	text.add_child(objective)
	if not done and not step.hint.is_empty():
		var hint := _muted_label(step.hint, 17)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.add_child(hint)
	if not progress.is_empty():
		var progress_label := Label.new()
		progress_label.text = progress
		progress_label.add_theme_font_size_override(&"font_size", 18)
		progress_label.add_theme_color_override(&"font_color", ACCENT_COLOR)
		text.add_child(progress_label)
	row.add_child(text)
	return row


## Pastille d'une étape : disque vert coché (validée) ou anneau doré (étape courante), dessinés
## (aucun glyphe hors de la police par défaut).
func _draw_mark(mark: Control, done: bool) -> void:
	var center := Vector2(MARK_SIZE, MARK_SIZE) * 0.5 + Vector2(0.0, 3.0)
	var radius := MARK_SIZE * 0.42
	if done:
		mark.draw_circle(center, radius, DONE_COLOR)
		var check := PackedVector2Array(
			[
				center + Vector2(-5.5, 0.5),
				center + Vector2(-1.5, 4.5),
				center + Vector2(6.0, -4.0),
			]
		)
		mark.draw_polyline(check, Color.WHITE, 3.0, true)
	else:
		mark.draw_arc(center, radius - 1.5, 0.0, TAU, 32, CURRENT_COLOR, 3.0, true)
		mark.draw_circle(center, radius * 0.38, CURRENT_COLOR)


func _rewards_text(quest: QuestData) -> String:
	var parts := PackedStringArray()
	for item_id: StringName in quest.reward_items:
		var amount: int = quest.reward_items[item_id]
		var item_name := ItemData.display_name_of(item_id)
		parts.append(item_name if amount == 1 else "%s × %d" % [item_name, amount])
	if quest.reward_max_hp > 0:
		parts.append("%d PV max" % quest.reward_max_hp)
	return "Récompense : " + ", ".join(parts) if not parts.is_empty() else ""


## Nom affiché d'un PNJ (data/npcs/<id>.tres), "" s'il est inconnu.
func _npc_name(npc_id: StringName) -> String:
	var path := "res://data/npcs/%s.tres" % npc_id
	if npc_id.is_empty() or not ResourceLoader.exists(path):
		return ""
	var npc := load(path) as NpcData
	return npc.display_name if npc != null else ""


func _muted_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override(&"font_color", MUTED_COLOR)
	label.add_theme_font_size_override(&"font_size", font_size)
	return label


# --- Événements -------------------------------------------------------------------------------


func _on_dim_gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		close()


func _on_dialogue_started(_npc_id: StringName) -> void:
	_dialogue_running = true
	close()


func _on_dialogue_ended(_npc_id: StringName) -> void:
	_dialogue_running = false
