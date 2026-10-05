extends Control
## Démo du Lot 8 (tests/integration/demo_l8.tscn, F6 dans l'éditeur) : Sauvegarder, Charger,
## Exporter, Importer et Nouvelle partie sur un fichier de test (DEMO_PATH). À gauche, le texte
## exporté (modifiable, lu par « Importer ») ; à droite, le fichier sur disque, relu en continu :
## l'auto-sauvegarde y arrive ~0,5 s après une action de la deuxième ligne de boutons.
## SaveManager.save_path est rétabli quand la scène quitte l'arbre.

const DEMO_PATH := "user://test_l8_demo.json"
const DEMO_SKIN := &"chtholly"
## Période de relecture du fichier (s).
const REFRESH_PERIOD := 0.2
## Ce que laisse une écriture coupée net, pour montrer la reprise sur fichier corrompu.
const DAMAGED_TEXT := '{"version": 1, "skin": "chtholly", "inventory": {"page_fr'

var _previous_path: String
var _refresh_left: float = 0.0

@onready var _info: Label = %Info
@onready var _status: Label = %Status
@onready var _json_edit: TextEdit = %JsonEdit
@onready var _file_view: TextEdit = %FileView


func _enter_tree() -> void:
	_previous_path = SaveManager.save_path
	SaveManager.save_path = DEMO_PATH


func _exit_tree() -> void:
	SaveManager.flush()
	SaveManager.save_path = _previous_path


func _ready() -> void:
	var actions: Dictionary[String, Callable] = {
		"SaveButton": _on_save_pressed,
		"LoadButton": _on_load_pressed,
		"ExportButton": _on_export_pressed,
		"ImportButton": _on_import_pressed,
		"NewGameButton": _on_new_game_pressed,
		"PickupButton": _on_pickup_pressed,
		"ScoreButton": _on_score_pressed,
		"DamageButton": _on_damage_pressed,
	}
	for button_name: String in actions:
		(get_node("%" + button_name) as Button).pressed.connect(actions[button_name])
	_json_edit.text = SaveManager.export_json()
	_status.text = "« Nouvelle partie » démarre le suivi : l'auto-sauvegarde n'écrit qu'après."
	_refresh()


func _process(delta: float) -> void:
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = REFRESH_PERIOD
		_refresh()


func _on_save_pressed() -> void:
	_report("Sauvegarder", SaveManager.save())


func _on_load_pressed() -> void:
	_report("Charger", SaveManager.load_game())
	_json_edit.text = SaveManager.export_json()


func _on_export_pressed() -> void:
	_json_edit.text = SaveManager.export_json()
	if DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD):
		DisplayServer.clipboard_set(_json_edit.text)
	_report("Exporter (copié dans le presse-papiers)", OK)


func _on_import_pressed() -> void:
	_report("Importer", SaveManager.import_json(_json_edit.text))


func _on_new_game_pressed() -> void:
	SaveManager.new_game(DEMO_SKIN)
	_json_edit.text = SaveManager.export_json()
	_report("Nouvelle partie", OK)


func _on_pickup_pressed() -> void:
	GameState.add_item(&"page_fragment")
	EventBus.item_collected.emit(&"page_fragment", 1)
	_report("Fragment ramassé (item_collected)", OK)


func _on_score_pressed() -> void:
	var score := 10 * randi_range(5, 80)
	var best := GameState.record_score(&"dunes", score, randi_range(1, 9))
	EventBus.arena_finished.emit(&"dunes", score, best)
	_report("Série des dunes finie à %d points (arena_finished)" % score, OK)


## Simule un arrêt brutal pendant l'écriture : le jeu ne tourne plus (rien en attente) et le
## fichier est coupé ; « Charger » le met alors de côté (.bak) et démarre une nouvelle partie.
func _on_damage_pressed() -> void:
	SaveManager.close_game(false)
	var file := FileAccess.open(SaveManager.save_path, FileAccess.WRITE)
	if file != null:
		file.store_string(DAMAGED_TEXT)
		file.close()
	_report("Fichier abîmé : « Charger » va le mettre de côté", OK)


func _report(action: String, err: Error) -> void:
	_status.text = "%s : %s" % [action, "OK" if err == OK else error_string(err)]
	if err != OK and not SaveManager.last_error.is_empty():
		_status.text += "\n" + SaveManager.last_error
	_refresh()


func _refresh() -> void:
	var text := "(aucune sauvegarde)"
	if SaveManager.has_save():
		text = FileAccess.get_file_as_string(SaveManager.save_path)
	if _file_view.text != text:
		_file_view.text = text
	var parts: Array[String] = [
		"Fichier %s" % SaveManager.save_path,
		"partie suivie : %s" % _yes_no(SaveManager.is_game_loaded()),
		"écriture en attente : %s" % _yes_no(SaveManager.is_autosave_pending()),
		"copie .bak : %s" % _yes_no(FileAccess.file_exists(SaveManager.backup_path())),
		"user:// conservé : %s" % _yes_no(SaveManager.is_persistent()),
	]
	_info.text = " — ".join(parts)


func _yes_no(value: bool) -> String:
	return "oui" if value else "non"
