extends Control
## Menu principal (L10), instancié par main.gd qui passe au jeu sur EventBus.game_loaded (émis
## par SaveManager) et seulement sur ce signal.
##
## - « Cliquer pour jouer » d'abord : le navigateur exige un geste (clic, toucher, touche) avant
##   tout son, et le bus Master reste muet jusque-là. Le geste est retenu par une métadonnée de
##   la racine de l'arbre : un retour au menu (reload_current_scene) ne le redemande pas.
## - Skins en vignettes (SkinRegistry.all(), Chtholly d'abord) ; présélection du skin de la
##   sauvegarde (champ « skin » de SaveManager.save_path, lu sans charger la partie).
## - Continuer (si SaveManager.has_save()) → load_game() : OK, le jeu démarre ;
##   ERR_FILE_CORRUPT, la nouvelle partie de secours prend le skin choisi et last_error reste
##   affiché (avis qui survit au passage au jeu) ; ERR_INVALID_DATA, on reste au menu.
## - Nouvelle partie → SaveManager.new_game(skin choisi), confirmée si une sauvegarde existe.
## - Sauvegarde : export (texte sélectionnable, presse-papiers) et import (import_json) ; en
##   navigation privée (not SaveManager.is_persistent()), avertissement et export mis en avant.
## Clavier, manette (croix ou stick : focus ; A valide ; B revient), souris et toucher.

const CREDITS_SCENE := preload("res://src/ui/credits.tscn")
const CreditsScript := preload("res://src/ui/credits.gd")
const MenuInput := preload("res://src/ui/main_menu_input.gd")
const MenuNotice := preload("res://src/ui/main_menu_notice.gd")
## Métadonnée de la racine de l'arbre : le geste « Cliquer pour jouer » a eu lieu.
const GESTURE_META := &"wordend_user_gesture"
const MASTER_BUS := 0
const CARD_SIZE := Vector2(206, 194)
const PORTRAIT_SIZE := Vector2(128, 128)
const ERROR_COLOR := Color(1.0, 0.72, 0.66)
const PRIVATE_NOTICE := (
	"Navigation privée : ta progression sera perdue à la fermeture de l'onglet. "
	+ "Pense à exporter ta sauvegarde."
)

## Exige le geste « Cliquer pour jouer » (coupé par les aperçus de capture).
@export var require_gesture: bool = true

var _selected_skin: StringName = &""
var _skin_chosen_by_user: bool = false
var _cards: Dictionary[StringName, Button] = {}
var _credits: CreditsScript
var _overlay_return: Control
var _muted_by_me: bool = false
var _swallow_pointer: bool = false
var _pulse: float = 0.0
var _pad := MenuInput.new()

@onready var _content: Control = %Content
@onready var _click_screen: Control = %ClickScreen
@onready var _click_pill: Control = %ClickPill
@onready var _continue_button: Button = %ContinueButton
@onready var _new_game_button: Button = %NewGameButton
@onready var _save_button: Button = %SaveButton
@onready var _credits_button: Button = %CreditsButton
@onready var _message_panel: Control = %MessagePanel
@onready var _message: Label = %Message
@onready var _skin_grid: GridContainer = %SkinGrid
@onready var _confirm_overlay: Control = %ConfirmOverlay
@onready var _confirm_cancel: Button = %ConfirmCancel
@onready var _save_overlay: Control = %SaveOverlay
@onready var _export_text: TextEdit = %ExportText
@onready var _import_text: TextEdit = %ImportText
@onready var _copy_button: Button = %CopyButton
@onready var _save_status: Label = %SaveStatus
@onready var _storage_label: Label = %StorageWarning


func _ready() -> void:
	_build_skin_cards()
	select_skin(saved_skin_id(SaveManager.save_path))
	_continue_button.pressed.connect(continue_game)
	_new_game_button.pressed.connect(request_new_game)
	_save_button.pressed.connect(open_save_panel)
	_credits_button.pressed.connect(open_credits)
	_confirm_cancel.pressed.connect(close_overlay)
	(%ConfirmOk as Button).pressed.connect(start_new_game)
	_copy_button.pressed.connect(copy_export)
	(%ImportButton as Button).pressed.connect(_on_import_pressed)
	(%SaveBackButton as Button).pressed.connect(close_overlay)
	refresh_continue()
	show_storage_warning(SaveManager.is_persistent())
	MenuInput.focus_on_hover(self)
	if require_gesture and not gesture_done(get_tree()):
		_set_muted(true)
		_click_screen.show()
		_content.hide()
	else:
		_enter_menu(false)


func _exit_tree() -> void:
	_set_muted(false)


func _process(delta: float) -> void:
	if not _click_screen.visible:
		set_process(false)
		return
	_pulse += delta
	_click_pill.pivot_offset = _click_pill.size * 0.5
	_click_pill.scale = Vector2.ONE * (1.0 + 0.045 * sin(_pulse * 3.0))


## Le geste « Cliquer pour jouer » a déjà eu lieu dans ce processus.
static func gesture_done(tree: SceneTree) -> bool:
	return tree.root.has_meta(GESTURE_META)


## Un geste qui débloque le son dans un navigateur : touche, clic, toucher (et bouton de manette,
## qui ne débloque pas le son du navigateur mais ne doit pas laisser le joueur bloqué ici).
static func is_gesture(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.is_pressed() and not event.is_echo()
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		return event.is_pressed()
	return event is InputEventJoypadButton and event.is_pressed()


## Skin de la sauvegarde save_path (champ « skin », lu sans charger la partie) ; &"" si le fichier
## manque, est illisible ou n'en a pas.
static func saved_skin_id(path: String) -> StringName:
	if not FileAccess.file_exists(path):
		return &""
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		return &""
	var skin: Variant = (json.data as Dictionary).get("skin")
	return StringName(skin) if skin is String else &""


func is_waiting_for_gesture() -> bool:
	return _click_screen.visible


## Geste reçu : le son est débloqué et le menu apparaît.
func accept_gesture() -> void:
	if not _click_screen.visible:
		return
	get_tree().root.set_meta(GESTURE_META, true)
	_set_muted(false)
	_enter_menu(true)


func selected_skin() -> StringName:
	return _selected_skin


## Choisit le skin skin_id (le skin par défaut s'il n'a pas de vignette) ; by_user : choix du
## joueur, qui s'applique aussi à « Continuer ».
func select_skin(skin_id: StringName, by_user: bool = false) -> void:
	if not _cards.has(skin_id):
		var fallback := SkinRegistry.default_skin()
		skin_id = fallback.id if fallback != null else &""
	_selected_skin = skin_id
	_skin_chosen_by_user = _skin_chosen_by_user or by_user
	for id: StringName in _cards:
		_cards[id].theme_type_variation = &"SkinCardSelected" if id == skin_id else &"SkinCard"


## Vignette du skin skin_id (null s'il n'en a pas).
func skin_card(skin_id: StringName) -> Button:
	return _cards.get(skin_id)


## « Continuer » n'est visible que s'il existe une sauvegarde.
func refresh_continue() -> void:
	_continue_button.visible = SaveManager.has_save()


## « Continuer » : SaveManager.load_game() ; renvoie son code.
func continue_game() -> Error:
	var chosen := _selected_skin
	var err := SaveManager.load_game()
	match err:
		OK:
			if _skin_chosen_by_user and not chosen.is_empty():
				GameState.skin_id = chosen
		ERR_FILE_CORRUPT:
			# La partie démarre quand même (game_loaded est déjà émis) : on garde le skin choisi.
			if not chosen.is_empty():
				GameState.skin_id = chosen
			_show_message(SaveManager.last_error, true)
			_show_notice(SaveManager.last_error)
		_:
			_show_message(SaveManager.last_error, true)
			refresh_continue()
	return err


## « Nouvelle partie » : confirmation si une sauvegarde existe, sinon la partie démarre.
func request_new_game() -> void:
	if SaveManager.has_save():
		_open_overlay(_confirm_overlay, _confirm_cancel, _new_game_button)
	else:
		start_new_game()


func is_confirm_open() -> bool:
	return _confirm_overlay.visible


## Nouvelle partie avec le skin choisi (GameState.skin_id) ; main.gd passe au jeu.
func start_new_game() -> void:
	close_overlay()
	SaveManager.new_game(_selected_skin)


func open_save_panel() -> void:
	_export_text.text = export_text()
	_import_text.text = ""
	_set_save_status("", false)
	_open_overlay(_save_overlay, _copy_button, _save_button)


func is_save_panel_open() -> bool:
	return _save_overlay.visible


## Texte exporté : la partie suivie par SaveManager (export_json) ; au menu, avant tout
## chargement, celle du fichier de sauvegarde, que SaveManager écrit avec export_json().
func export_text() -> String:
	if not SaveManager.is_game_loaded() and SaveManager.has_save():
		var text := FileAccess.get_file_as_string(SaveManager.save_path)
		if not text.strip_edges().is_empty():
			return text
	return SaveManager.export_json()


## Sélectionne l'export et le copie dans le presse-papiers.
func copy_export() -> void:
	_export_text.grab_focus()
	_export_text.select_all()
	if DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD):
		DisplayServer.clipboard_set(_export_text.text)
		_set_save_status("Sauvegarde copiée dans le presse-papiers.", false)
	else:
		_set_save_status("Copie automatique impossible ici : le texte est sélectionné.", false)


## « Importer » : SaveManager.import_json(text) ; OK, le jeu démarre ; sinon last_error.
func import_save(text: String) -> Error:
	var err := SaveManager.import_json(text)
	if err != OK:
		_set_save_status("Import impossible : %s" % SaveManager.last_error, true)
	return err


func save_status() -> String:
	return _save_status.text


## Prévient le joueur si la sauvegarde n'est pas conservée (navigation privée sur le Web) et
## met l'export en avant. Appelé au démarrage avec SaveManager.is_persistent().
func show_storage_warning(persistent: bool) -> void:
	_storage_label.visible = not persistent
	_save_button.theme_type_variation = &"" if persistent else &"PrimaryButton"
	_save_button.text = "Sauvegarde" if persistent else "Exporter ma sauvegarde"
	if not persistent:
		_show_message(PRIVATE_NOTICE, false)
	elif _message.text == PRIVATE_NOTICE:
		_show_message("", false)


func open_credits() -> void:
	if _credits != null:
		return
	_credits = CREDITS_SCENE.instantiate()
	_credits.closed.connect(close_credits)
	add_child(_credits)
	_content.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED


func close_credits() -> void:
	if _credits == null:
		return
	_credits.hide()
	_credits.queue_free()
	_credits = null
	_content.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_INHERITED
	_credits_button.grab_focus()


func is_credits_open() -> bool:
	return _credits != null


## Ferme la confirmation ou le panneau de sauvegarde ; le focus revient au bouton d'origine.
func close_overlay() -> void:
	var was_open := _confirm_overlay.visible or _save_overlay.visible
	_confirm_overlay.hide()
	_save_overlay.hide()
	_content.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_INHERITED
	if was_open and _overlay_return != null:
		_overlay_return.grab_focus()
	_overlay_return = null


## Message affiché sous les boutons ("" : aucun).
func message() -> String:
	return _message.text if _message_panel.visible else ""


func _input(event: InputEvent) -> void:
	if _click_screen.visible:
		if is_gesture(event):
			accept_gesture()
			_swallow_pointer = event is InputEventMouseButton or event is InputEventScreenTouch
			get_viewport().set_input_as_handled()
		return
	# Le clic ou le doigt qui a fermé l'écran ne presse pas le bouton du menu placé dessous.
	if _swallow_pointer and (event is InputEventMouseButton or event is InputEventScreenTouch):
		_swallow_pointer = event.is_pressed()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if _click_screen.visible or _credits != null:
		return
	var command := _pad.read(event)
	match command:
		MenuInput.Command.ACCEPT:
			MenuInput.press_focused(self)
		MenuInput.Command.BACK:
			close_overlay()
	if command != MenuInput.Command.NONE:
		get_viewport().set_input_as_handled()


func _enter_menu(animate: bool) -> void:
	_click_screen.hide()
	_content.show()
	(_continue_button if _continue_button.visible else _new_game_button).grab_focus()
	if animate:
		_content.modulate.a = 0.0
		create_tween().tween_property(_content, ^"modulate:a", 1.0, 0.35)


func _build_skin_cards() -> void:
	for skin: SkinData in SkinRegistry.all():
		var card := Button.new()
		card.name = "Skin_" + String(skin.id)
		card.theme_type_variation = &"SkinCard"
		card.custom_minimum_size = CARD_SIZE
		card.tooltip_text = skin.display_name
		var box := VBoxContainer.new()
		box.name = "Box"
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		var portrait := TextureRect.new()
		portrait.name = "Portrait"
		portrait.texture = skin.portrait
		portrait.custom_minimum_size = PORTRAIT_SIZE
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var label := Label.new()
		label.name = "Name"
		label.text = skin.display_name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(portrait)
		box.add_child(label)
		card.add_child(box)
		box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
		card.pressed.connect(select_skin.bind(skin.id, true))
		_skin_grid.add_child(card)
		_cards[skin.id] = card


func _open_overlay(overlay: Control, focus: Control, return_to: Control) -> void:
	close_overlay()
	overlay.show()
	_content.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
	_overlay_return = return_to
	focus.grab_focus()


func _show_message(text: String, error: bool) -> void:
	_message.text = text
	if error:
		_message.add_theme_color_override(&"font_color", ERROR_COLOR)
	else:
		_message.remove_theme_color_override(&"font_color")
	_message_panel.visible = not text.is_empty()


func _show_notice(text: String) -> void:
	var previous := get_tree().root.get_node_or_null(NodePath(String(MenuNotice.NODE_NAME)))
	if previous != null:
		previous.name = "MenuNoticeOld"
		previous.queue_free()
	var notice := MenuNotice.new()
	notice.text = text
	get_tree().root.add_child.call_deferred(notice)


func _set_save_status(text: String, error: bool) -> void:
	_save_status.text = text
	_save_status.theme_type_variation = &"ErrorLabel" if error else &"MutedLabel"


func _set_muted(muted: bool) -> void:
	if muted and not _muted_by_me and not AudioServer.is_bus_mute(MASTER_BUS):
		AudioServer.set_bus_mute(MASTER_BUS, true)
		_muted_by_me = true
	elif not muted and _muted_by_me:
		AudioServer.set_bus_mute(MASTER_BUS, false)
		_muted_by_me = false


func _on_import_pressed() -> void:
	import_save(_import_text.text)
