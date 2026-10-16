class_name StorySkip
extends RefCounted
## (X-L0, X-L2) Passer une scène (PLAN.md, « (X) Exploration libre : le rythme ») ; le directeur
## n'appelle que ces points d'entrée. Propriétaire : X-L2.
##
## - Mode scénarisé : la règle d'E6, inchangée (une séquence déjà vue se passe par l'action
##   « pause »).
## - Mode libre : un seul appui sur « pause » (Échap, Start) passe toute scène, à toute étape ;
##   l'invite « Échap : passer » paraît dès son début ; l'appui est pris avant le menu pause
##   (StoryDirector._input passe avant le _unhandled_input du menu).
## - Passer (StoryRunner.skip) : le reste de la scène se joue d'un coup (mode rapide « fast ») ;
##   les jeux en cours s'arrêtent (MiniGames.stop_all) ; un choix sauté qui change l'état prend la
##   clé « skip » de la scène (skip_flags), sinon le premier choix proposé ; puis la fin de scène
##   d'E6 (scène nettoyée, caméra rendue, voile levé, main rendue).
## - Dans les deux modes, l'action FORWARD_ACTION tenue accélère la scène en cours sans la passer
##   (StoryRunner.FAST_FORWARD).

## Action qui passe une scène.
const SKIP_ACTION := &"pause"
## (X-L2) Action qui, tenue, accélère la scène en cours (celle qui fait avancer les dialogues).
const FORWARD_ACTION := &"interact"

## Section du fichier des séquences vues (StoryDirector.seen_path, hors sauvegarde).
const SEEN_SECTION := "seen"

## Le directeur (autoload StoryDirector), posé par lui.
var director: Node

var _seen: ConfigFile = null


## Vrai si la scène en cours (scene_id, ses données) se passe : en libre, toute scène ; en
## scénarisé, une séquence déjà vue.
func is_skippable(scene_id: StringName, data: Dictionary) -> bool:
	if scene_id.is_empty() or director == null:
		return false
	if bool(director.call(&"is_free")):
		return true
	var path := str(director.get(&"seen_path"))
	return data.get("sequence", false) == true and has_seen(scene_id, path)


## Texte de l'invite « Échap : passer » de la scène qui commence ("" : pas d'invite).
func prompt_text(scene_id: StringName, data: Dictionary) -> String:
	if not is_skippable(scene_id, data):
		return ""
	return str(director.call(&"ui_text", "skip", "Échap : passer"))


## Passe la scène en cours (le mode rapide du joueur de scènes, les jeux arrêtés).
func skip(runner: StoryRunner) -> void:
	runner.skip()


## Un appui pendant une scène (StoryDirector._input) : vrai s'il l'a passée (l'appui est pris,
## avant le menu pause ; en libre, aussi un second appui pendant le passage).
func handle_input(
	event: InputEvent, runner: StoryRunner, scene_id: StringName, data: Dictionary
) -> bool:
	if not runner.is_running() or not event.is_action_pressed(SKIP_ACTION):
		return false
	if not is_skippable(scene_id, data):
		return false
	skip(runner)
	return true


## (X-L2) Les drapeaux que pose une scène passée à la place d'un choix sauté qui change l'état
## (clé « skip » : {"flags": [...]}) ; vide sans clé « skip » (le premier choix s'applique).
static func skip_flags(data: Dictionary) -> Array[StringName]:
	var result: Array[StringName] = []
	var settings: Variant = data.get("skip")
	if not settings is Dictionary:
		return result
	var flags: Variant = (settings as Dictionary).get("flags", [])
	for flag: Variant in flags if flags is Array else [flags]:
		if not str(flag).is_empty():
			result.append(StringName(str(flag)))
	return result


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
