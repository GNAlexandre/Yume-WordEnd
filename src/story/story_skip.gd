class_name StorySkip
extends RefCounted
## (X-L0) Passer une scène (PLAN.md, « (X) Exploration libre : le rythme ») : la règle d'E6 (une
## séquence déjà vue se passe par l'action « pause ») sortie du directeur, qui n'appelle que ces
## points d'entrée. Le lot L2 l'étend au libre (toute scène, à toute étape, clé « skip » des
## scènes : StoryFreeData.SKIP_KEYS). L0 : la règle d'E6, en libre comme en scénarisé.

## Action qui passe une scène.
const SKIP_ACTION := &"pause"

## Section du fichier des séquences vues (StoryDirector.seen_path, hors sauvegarde).
const SEEN_SECTION := "seen"

## Le directeur (autoload StoryDirector), posé par lui.
var director: Node

var _seen: ConfigFile = null


## Vrai si la scène en cours (scene_id, ses données) se passe : une séquence déjà vue.
func is_skippable(scene_id: StringName, data: Dictionary) -> bool:
	if scene_id.is_empty() or director == null:
		return false
	var path := str(director.get(&"seen_path"))
	return data.get("sequence", false) == true and has_seen(scene_id, path)


## Texte de l'invite « Échap : passer » de la scène qui commence ("" : pas d'invite).
func prompt_text(scene_id: StringName, data: Dictionary) -> String:
	if not is_skippable(scene_id, data):
		return ""
	return str(director.call(&"ui_text", "skip", "Échap : passer"))


## Passe la scène en cours (le mode rapide du joueur de scènes).
func skip(runner: StoryRunner) -> void:
	runner.skip()


## Un appui pendant une scène (StoryDirector._input) : vrai s'il l'a passée (l'appui est pris).
func handle_input(
	event: InputEvent, runner: StoryRunner, scene_id: StringName, data: Dictionary
) -> bool:
	if not runner.is_running() or not event.is_action_pressed(SKIP_ACTION):
		return false
	if not is_skippable(scene_id, data):
		return false
	skip(runner)
	return true


## Vrai si la séquence a déjà été vue (fichier path, toutes parties confondues).
func has_seen(scene_id: StringName, path: String) -> bool:
	return _seen_file(path).has_section_key(SEEN_SECTION, String(scene_id))


## Retient une séquence vue (fichier path).
func mark_seen(scene_id: StringName, path: String) -> void:
	var file := _seen_file(path)
	if file.has_section_key(SEEN_SECTION, String(scene_id)):
		return
	file.set_value(SEEN_SECTION, String(scene_id), true)
	file.save(path)


## Oublie les séquences vues (efface le fichier path).
func forget_seen(path: String) -> void:
	_seen = ConfigFile.new()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func _seen_file(path: String) -> ConfigFile:
	if _seen == null:
		_seen = ConfigFile.new()
		if FileAccess.file_exists(path):
			_seen.load(path)
	return _seen
