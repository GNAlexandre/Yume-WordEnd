extends Node
## SaveManager : sauvegarde JSON de GameState (schéma v1, PLAN.md section 4). Propriétaire : L8.
##
## Implémentation minimale du Lot 0 : aller-retour JSON, sans migration ni auto-sauvegarde
## (L8 ajoute les auto-sauvegardes sur arena_finished, item_collected, quest_updated,
## zone_entered, la migration v0 → v1 et la reprise sur fichier corrompu).
## new_game(), load_game() et import_json() émettent EventBus.game_loaded en cas de succès :
## c'est le seul signal que main.gd écoute pour passer du menu au jeu.

const SAVE_VERSION := 1
const DEFAULT_SAVE_PATH := "user://save_v1.json"

## Fichier de sauvegarde ; les tests le remplacent pour ne pas écraser la vraie sauvegarde.
var save_path: String = DEFAULT_SAVE_PATH


func _ready() -> void:
	EventBus.save_requested.connect(_on_save_requested)


func has_save() -> bool:
	return FileAccess.file_exists(save_path)


## Écrit GameState dans save_path.
func save() -> Error:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(export_json())
	file.close()
	return OK


## Lit save_path, remplit GameState et émet game_loaded.
func load_game() -> Error:
	if not has_save():
		return ERR_FILE_NOT_FOUND
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return FileAccess.get_open_error()
	var text := file.get_as_text()
	file.close()
	return import_json(text)


## Nouvelle partie avec le skin choisi : GameState.reset(), puis game_loaded.
func new_game(skin_id: StringName) -> void:
	GameState.reset()
	GameState.skin_id = skin_id
	EventBus.game_loaded.emit()


## Sauvegarde courante en texte JSON (menu « Exporter », section 13).
func export_json() -> String:
	var data := GameState.to_dict()
	data["version"] = SAVE_VERSION
	data["saved_at"] = Time.get_datetime_string_from_system(true) + "Z"
	return JSON.stringify(data, "  ", true)


## Remplace GameState par une sauvegarde JSON (menu « Importer ») et émet game_loaded.
## ERR_PARSE_ERROR si le texte n'est pas un objet JSON, ERR_INVALID_DATA si la version
## n'est pas gérée ; GameState n'est pas modifié en cas d'erreur.
func import_json(text: String) -> Error:
	var json := JSON.new()
	if json.parse(text) != OK or not json.data is Dictionary:
		return ERR_PARSE_ERROR
	var data: Dictionary = json.data
	if int(data.get("version", 0)) != SAVE_VERSION:
		return ERR_INVALID_DATA
	GameState.from_dict(data)
	EventBus.game_loaded.emit()
	return OK


func _on_save_requested() -> void:
	save()
