extends GutTest
## Base des tests de sauvegarde du Lot 8 (tests/unit/test_save*.gd), dont ils héritent par
## chemin (pas de class_name, règle des stubs) : fichier de test propre à chaque script
## (user://test_l8_<script>.json), SaveManager rétabli (chemin, délai, partie fermée, rien en
## attente), zone de WorldManager, pause levée et GameState remis à zéro après chaque test.

var _previous_path: String
var _previous_delay: float
var _previous_zone: StringName


func before_each() -> void:
	_previous_path = SaveManager.save_path
	_previous_delay = SaveManager.autosave_delay
	_previous_zone = WorldManager.current_zone()
	SaveManager.close_game(false)
	SaveManager.save_path = save_file()
	delete_save_files(save_file())
	GameState.reset()


func after_each() -> void:
	get_tree().paused = false
	if WorldManager.current_zone() != _previous_zone:
		EventBus.zone_entered.emit(_previous_zone)
	SaveManager.close_game(false)
	delete_save_files(save_file())
	SaveManager.save_path = _previous_path
	SaveManager.autosave_delay = _previous_delay
	SaveManager.last_error = ""
	GameState.reset()


## Fichier de sauvegarde propre à ce script de test.
func save_file() -> String:
	return "user://test_l8_%s.json" % get_script().resource_path.get_file().get_basename()


## Supprime une sauvegarde, sa copie .bak et son fichier temporaire (ou dossier vide).
func delete_save_files(path: String) -> void:
	for file: String in [path, path + SaveManager.BACKUP_SUFFIX, path + SaveManager.TEMP_SUFFIX]:
		if FileAccess.file_exists(file) or DirAccess.dir_exists_absolute(file):
			DirAccess.remove_absolute(file)


## Écrit un texte brut à la place de la sauvegarde courante (fichier abîmé, ancien format…).
func write_save_text(text: String) -> void:
	var file := FileAccess.open(SaveManager.save_path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


## Contenu JSON de la sauvegarde courante ({} si elle est absente ou illisible).
func read_save() -> Dictionary:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SaveManager.save_path))
	return data if data is Dictionary else {}


## Nouvelle partie dont la première écriture est déjà faite : plus rien en attente.
func start_game(skin_id: StringName = &"chtholly") -> void:
	SaveManager.new_game(skin_id)
	SaveManager.flush()


## Attend que predicate soit vrai (true) ou que max_seconds de temps réel passent (false), image
## par image : marche aussi quand l'arbre est en pause, où wait_seconds de GUT est gelé.
func wait_real_until(predicate: Callable, max_seconds: float) -> bool:
	var deadline := Time.get_ticks_msec() + int(max_seconds * 1000.0)
	while not predicate.call():
		if Time.get_ticks_msec() >= deadline:
			return false
		await get_tree().process_frame
	return true


## Attend seconds de temps réel, image par image (même en pause).
func wait_real(seconds: float) -> void:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
