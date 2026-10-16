extends Node
## SaveManager : sauvegarde JSON de GameState (schéma v4, PLAN.md section 4). Propriétaire : L8
## ((F1) v4 : l'ancienne île retirée, sans zone, quêtes ni scores d'arène).
##
## Fichier save_path : {"version": 4, "saved_at": "AAAA-MM-JJTHH:MM:SSZ" (UTC), puis les champs
## de GameState.to_dict() dans leur ordre}. (E9) moment et weather, (X1) island et known_islands,
## (E4) day et slot, (E6) scenes_done, calendar et story_scene sont facultatifs : absents, le
## couchant sans pluie, l'île déduite de la carte à l'arrivée, hors de l'acte en jours, scènes et
## calendrier vierges (la nouvelle partie de l'acte est posée par StoryDirector à son arrivée sur
## l'île de l'acte, WorldManager.start_map). new_game(), load_game() et import_json() émettent
## EventBus.game_loaded en cas de succès : c'est le seul signal que main.gd écoute pour passer
## du menu au jeu. Choix détaillés : docs/DECISIONS.md, sections L8, Lot Q et F1. Le nom du
## fichier (save_v1.json) ne suit pas la version du schéma : il ne change jamais (sauvegardes
## gardées).
##
## - Écriture sûre : <save_path>.tmp est écrit et fermé, puis renommé en save_path ; une
##   écriture interrompue laisse l'ancienne sauvegarde intacte.
## - Fichier corrompu ou illisible : load_game() le met de côté dans backup_path(), démarre une
##   nouvelle partie et renvoie ERR_FILE_CORRUPT ; last_error (et push_error) l'explique.
## - Versions : (F1) une partie de l'ancienne île (is_legacy : version 0 à 2, ou v3 hors de
##   l'acte en jours, day = 0) ne se reprend plus : load_game() et import_json() en gardent une
##   copie (load_game : legacy_backup_path()), démarrent une nouvelle partie de l'acte 1 avec son
##   skin (started_new) et posent notice (data/texts/story.json, save/migrated), que le menu
##   affiche au chargement ; une partie v3 de l'acte en jours passe en v4 sans perte (les champs
##   de l'ancienne île sont retirés) ; version plus récente que SAVE_VERSION : refus
##   (ERR_INVALID_DATA), GameState et fichier intacts.
## - Auto-sauvegarde sur item_collected, (E1) map_entered et save_requested, seulement entre
##   game_loaded et close_game() : la première demande lance un minuteur de autosave_delay s
##   (actif même en pause) ; les demandes suivantes s'y regroupent et une seule écriture a lieu,
##   à la fin. L'état écrit est donc complet et il y a au plus une écriture par délai.
## - Web : user:// vit dans IndexedDB, que Godot ne met à jour qu'après la fermeture d'un
##   fichier ouvert en écriture : le fichier temporaire est toujours fermé explicitement.
## - Position (intégration M2) : aucun des signaux d'auto-sauvegarde ne suit le joueur qui se
##   promène. Toutes les checkpoint_interval s de jeu (pas en pause), l'état est écrit s'il a
##   changé depuis la dernière écriture, la position seulement au-delà de checkpoint_distance m :
##   rien n'est écrit tant que le joueur ne bouge pas. À la perte du focus, à la fermeture, à la
##   mise en arrière-plan et quand la page Web est masquée (save_on_leave), l'écriture en attente
##   est faite et, sans attente, l'état est écrit s'il a changé (position comprise). Ces
##   écritures-là sont discrètes (pas de signal saved : pas de « Sauvegardé » à chaque pas).

## Une sauvegarde vient d'être écrite (save, auto-sauvegarde, flush) : pour un indicateur du HUD.
signal saved(path: String)

const SAVE_VERSION := 4
## (F1) Dernière version qui pouvait porter une partie de l'ancienne île (v3 hors de l'acte).
const LEGACY_VERSION := 3
## (F1) Champs de l'ancienne île, retirés en v4.
const LEGACY_FIELDS: Array[String] = [
	"zone", "quests", "quest_progress", "tracked_quest", "best_scores"
]
## (F1) Texte de l'avis d'une partie de l'ancienne île reprise à l'acte 1 (data/texts/story.json).
const LEGACY_NOTICE_KEY := "save/migrated"
## Chemin historique, gardé quelle que soit la version du schéma (les parties y sont).
const DEFAULT_SAVE_PATH := "user://save_v1.json"
## Regroupement des auto-sauvegardes : au plus une écriture par délai (secondes).
const DEFAULT_AUTOSAVE_DELAY := 0.5
## Sauvegarde de la position pendant le jeu : intervalle (s de jeu) et déplacement minimal (m).
const DEFAULT_CHECKPOINT_INTERVAL := 5.0
const DEFAULT_CHECKPOINT_DISTANCE := 1.0
## Écart de position (m) en deçà duquel le joueur n'a pas bougé (départ du joueur).
const POSITION_EPSILON := 0.05
const TEMP_SUFFIX := ".tmp"
const BACKUP_SUFFIX := ".bak"
## (F1) Copie d'une partie de l'ancienne île, gardée quand load_game() la remplace.
const LEGACY_SUFFIX := ".ancienne"
## Fermeture, perte du focus, arrière-plan : l'écriture en attente est faite sans attendre, sinon
## l'état est écrit s'il a changé depuis la dernière écriture (save_on_leave).
const FLUSH_NOTIFICATIONS: Array[int] = [
	NOTIFICATION_WM_CLOSE_REQUEST,
	NOTIFICATION_WM_WINDOW_FOCUS_OUT,
	NOTIFICATION_APPLICATION_FOCUS_OUT,
	NOTIFICATION_APPLICATION_PAUSED,
]

## Fichier de sauvegarde ; les tests le remplacent pour ne pas écraser la vraie sauvegarde.
var save_path: String = DEFAULT_SAVE_PATH
## Délai de regroupement des auto-sauvegardes ; les tests peuvent le raccourcir.
var autosave_delay: float = DEFAULT_AUTOSAVE_DELAY
## Sauvegarde de la position pendant le jeu : toutes les checkpoint_interval s de jeu (0 : jamais),
## si l'état a changé, la position d'au moins checkpoint_distance m.
var checkpoint_interval: float = DEFAULT_CHECKPOINT_INTERVAL
var checkpoint_distance: float = DEFAULT_CHECKPOINT_DISTANCE
## Explication en français du dernier échec, ou de la sauvegarde mise de côté (pour le menu) ;
## "" après une opération réussie.
var last_error: String = ""
## (E6) Vrai si la dernière partie chargée est une nouvelle partie (new_game, ou fichier illisible
## remplacé par une nouvelle partie) ; faux pour une partie lue (load_game, import_json).
## StoryDirector n'ouvre l'acte qu'à une nouvelle partie. (F1) Vrai aussi pour une partie de
## l'ancienne île reprise à l'acte 1.
var started_new: bool = false
## (F1) Avis à montrer au joueur après le dernier chargement ("" : aucun) : une partie de
## l'ancienne île reprise à l'acte 1 (le menu l'affiche, MenuNotice).
var notice: String = ""

var _game_loaded: bool = false
## (F1) La dernière sauvegarde lue par _decode est une partie de l'ancienne île.
var _decoded_legacy: bool = false
var _timer: Timer
## GameState.to_dict() de la dernière écriture de la partie suivie ({} : rien d'écrit encore).
var _written: Dictionary = {}
var _checkpoint_left: float = DEFAULT_CHECKPOINT_INTERVAL
## Rappel JavaScript de « visibilitychange » (Web), gardé tant que SaveManager vit.
var _visibility_callback: JavaScriptObject


func _ready() -> void:
	_timer = Timer.new()
	_timer.name = "AutosaveTimer"
	_timer.one_shot = true
	# Pause et inventaire figent l'arbre (get_tree().paused) : l'auto-sauvegarde continue.
	_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_timer.ignore_time_scale = true
	_timer.timeout.connect(_on_autosave_timeout)
	add_child(_timer)
	EventBus.game_loaded.connect(_on_game_loaded)
	EventBus.item_collected.connect(_request_autosave.unbind(2))
	EventBus.map_entered.connect(_request_autosave.unbind(1))
	EventBus.save_requested.connect(_request_autosave)
	_watch_page_visibility()


func _notification(what: int) -> void:
	# Le navigateur ou le système ne donneront peut-être plus d'image pour finir le délai.
	if what in FLUSH_NOTIFICATIONS:
		save_on_leave()


func _process(delta: float) -> void:
	# Pausable (autoload) : pas de sauvegarde de position pendant la pause, où rien ne bouge.
	if not _game_loaded or checkpoint_interval <= 0.0:
		return
	_checkpoint_left -= delta
	if _checkpoint_left > 0.0:
		return
	_checkpoint_left = checkpoint_interval
	if not is_autosave_pending() and has_unsaved_changes(checkpoint_distance):
		_write(false)


func has_save() -> bool:
	return FileAccess.file_exists(save_path)


## Où load_game() met de côté une sauvegarde illisible.
func backup_path() -> String:
	return save_path + BACKUP_SUFFIX


## (F1) Où load_game() garde une partie de l'ancienne île avant de la remplacer.
func legacy_backup_path() -> String:
	return save_path + LEGACY_SUFFIX


## Faux si user:// n'est pas conservé (Web sans IndexedDB, navigation privée) : le menu peut
## prévenir le joueur et lui proposer l'export.
func is_persistent() -> bool:
	return OS.is_userfs_persistent()


## Écrit GameState dans save_path, puis émet saved.
func save() -> Error:
	return _write(true)


## Lit save_path, remplit GameState (from_dict) et émet game_loaded. Renvoie OK,
## ERR_FILE_NOT_FOUND (pas de sauvegarde : rien ne change), ERR_INVALID_DATA (version plus
## récente que le jeu : refusée, GameState et fichier intacts) ou ERR_FILE_CORRUPT (fichier
## illisible ou invalide : mis dans backup_path(), nouvelle partie démarrée, game_loaded émis).
## (F1) Une partie de l'ancienne île renvoie OK : copiée dans legacy_backup_path(), elle est
## remplacée par une nouvelle partie de l'acte 1 avec son skin, et notice dit pourquoi.
func load_game() -> Error:
	if not has_save():
		last_error = "Aucune sauvegarde dans %s." % save_path
		return ERR_FILE_NOT_FOUND
	var text := FileAccess.get_file_as_string(save_path)
	var err := FileAccess.get_open_error()
	if err != OK:
		return _recover("lecture impossible, %s" % error_string(err))
	var data := {}
	err = _decode(text, data)
	if err == ERR_INVALID_DATA:
		last_error = "Sauvegarde %s refusée : %s." % [save_path, last_error]
		push_warning("SaveManager : " + last_error)
		return err
	if err != OK:
		return _recover(last_error)
	last_error = ""
	if _decoded_legacy:
		DirAccess.copy_absolute(save_path, legacy_backup_path())
		_start_from_legacy(data)
		return OK
	_apply(data)
	return OK


## Nouvelle partie avec le skin choisi : GameState.reset(), skin, puis game_loaded. Elle remplace
## la sauvegarde autosave_delay s plus tard.
func new_game(skin_id: StringName) -> void:
	last_error = ""
	_start_new_game(skin_id, "")


## Sauvegarde courante en texte JSON (menu « Exporter », section 13).
func export_json() -> String:
	return _to_json(GameState.to_dict())


## Remplace GameState par une sauvegarde JSON de version gérée (menu « Importer ») et émet
## game_loaded ; elle remplace la sauvegarde autosave_delay s plus tard. ERR_PARSE_ERROR si le
## texte n'est pas un objet JSON, ERR_INVALID_DATA si la version est plus récente que le jeu ou
## si un champ est invalide ; GameState n'est alors pas modifié et last_error explique. (F1) Une
## partie de l'ancienne île démarre une nouvelle partie de l'acte 1 avec son skin (notice).
func import_json(text: String) -> Error:
	var data := {}
	var err := _decode(text, data)
	if err != OK:
		return ERR_INVALID_DATA if err == ERR_FILE_CORRUPT else err
	last_error = ""
	if _decoded_legacy:
		_start_from_legacy(data)
		return OK
	_apply(data)
	return OK


## Vrai entre game_loaded et close_game() : seule période où l'auto-sauvegarde écrit.
func is_game_loaded() -> bool:
	return _game_loaded


## Une auto-sauvegarde attend la fin du délai de regroupement.
func is_autosave_pending() -> bool:
	return _timer != null and not _timer.is_stopped()


## Écrit tout de suite l'auto-sauvegarde en attente, s'il y en a une (OK sinon).
func flush() -> Error:
	if not is_autosave_pending():
		return OK
	_timer.stop()
	return save()


## Vrai pendant une partie suivie si GameState diffère de la dernière écriture : un champ autre
## que la position, ou une position à plus de tolerance m de celle écrite.
func has_unsaved_changes(tolerance: float = POSITION_EPSILON) -> bool:
	if not _game_loaded:
		return false
	if _written.is_empty():
		return true
	var now := GameState.to_dict()
	var before := _written.duplicate()
	var moved := _vector(now["position"]).distance_to(_vector(before["position"]))
	now.erase("position")
	before.erase("position")
	return now != before or moved > tolerance


## Le joueur s'en va peut-être (focus perdu, fermeture, arrière-plan, page masquée) : l'écriture
## en attente est faite, sinon l'état est écrit s'il a changé (position comprise), discrètement.
## Rien n'est écrit si rien n'a changé : pas d'écriture en boucle.
func save_on_leave() -> Error:
	if is_autosave_pending():
		return flush()
	if has_unsaved_changes():
		return _write(false)
	return OK


## Fin du suivi de la partie (retour au menu, fin d'un test) : l'écriture en attente est faite
## (abandonnée si flush_pending est faux), puis plus rien n'est écrit automatiquement jusqu'au
## prochain game_loaded.
func close_game(flush_pending: bool = true) -> void:
	if flush_pending:
		flush()
	if _timer != null:
		_timer.stop()
	_game_loaded = false
	_written = {}


# --- Partie -----------------------------------------------------------------------------------


func _start_new_game(skin_id: StringName, notice_text: String) -> void:
	started_new = true
	notice = notice_text
	GameState.reset()
	GameState.skin_id = skin_id
	_begin()


## (F1) Partie de l'ancienne île : nouvelle partie de l'acte 1 avec le skin de la sauvegarde (un
## skin inconnu est remplacé par le skin par défaut, comme ailleurs), et l'avis du menu.
func _start_from_legacy(data: Dictionary) -> void:
	var skin: Variant = data.get("skin")
	var skin_id := StringName(skin) if skin is String else &""
	_start_new_game(skin_id, DialogueRunner.story_text(LEGACY_NOTICE_KEY))


func _apply(data: Dictionary) -> void:
	started_new = false
	notice = ""
	data.erase("version")
	data.erase("saved_at")
	GameState.from_dict(data)
	_begin()


## L'écriture en attente de la partie remplacée est abandonnée, game_loaded est émis, puis la
## nouvelle partie est écrite (nouvelle partie, migration et import ainsi conservés).
func _begin() -> void:
	_timer.stop()
	_written = {}
	EventBus.game_loaded.emit()
	_request_autosave()


## Fichier illisible : renommé en backup_path() (remplace une copie plus ancienne), puis
## nouvelle partie avec le skin courant.
func _recover(reason: String) -> Error:
	var backup := "Copie gardée dans " + backup_path()
	if DirAccess.rename_absolute(save_path, backup_path()) != OK:
		backup = "Copie impossible"
	last_error = (
		"Sauvegarde illisible (%s : %s). %s ; nouvelle partie." % [save_path, reason, backup]
	)
	push_error("SaveManager : " + last_error)
	_start_new_game(GameState.skin_id, "")
	return ERR_FILE_CORRUPT


func _on_game_loaded() -> void:
	_game_loaded = true
	_checkpoint_left = checkpoint_interval


# --- Auto-sauvegarde --------------------------------------------------------------------------


func _request_autosave() -> void:
	if _game_loaded and _timer.is_stopped():
		_timer.start(maxf(autosave_delay, 0.001))


func _on_autosave_timeout() -> void:
	if _game_loaded:
		save()


# --- Fichier ----------------------------------------------------------------------------------


## Écrit GameState dans save_path ; announce : émet saved (indicateur du HUD).
func _write(announce: bool) -> Error:
	var state := GameState.to_dict()
	var err := _write_atomically(save_path, _to_json(state))
	if err != OK:
		last_error = "Sauvegarde impossible dans %s (%s)." % [save_path, error_string(err)]
		push_error("SaveManager : " + last_error)
		return err
	last_error = ""
	if _game_loaded:
		_written = state
	if announce:
		saved.emit(save_path)
	return OK


## Texte du fichier : version, saved_at, puis les champs de GameState.to_dict() (state).
func _to_json(state: Dictionary) -> String:
	var data := {"version": SAVE_VERSION, "saved_at": _utc_now()}
	data.merge(state)
	return JSON.stringify(data, "  ", false)


## [x, y, z] (position de to_dict) → Vector3.
static func _vector(value: Variant) -> Vector3:
	if value is Array and (value as Array).size() == 3:
		var p: Array = value
		return Vector3(float(p[0]), float(p[1]), float(p[2]))
	return Vector3.ZERO


## Web : Godot 4.7 n'a pas de notification quand la page est masquée (onglet en arrière-plan,
## téléphone qui change d'application) ; SaveManager écoute lui-même « visibilitychange ».
func _watch_page_visibility() -> void:
	if not OS.has_feature("web"):
		return
	var document := JavaScriptBridge.get_interface("document")
	if document == null:
		return
	_visibility_callback = JavaScriptBridge.create_callback(_on_page_visibility_changed)
	document.call("addEventListener", "visibilitychange", _visibility_callback)


func _on_page_visibility_changed(_arguments: Array) -> void:
	var document := JavaScriptBridge.get_interface("document")
	if document != null and str(document.get("visibilityState")) == "hidden":
		save_on_leave()


## Écrit text dans <path>.tmp, le ferme puis le renomme en path. Sur le Web, la fermeture
## demande la copie vers IndexedDB au début de l'image suivante, qui emporte aussi le renommage
## fait dans cette image (un renommage seul ne déclenche pas de copie).
func _write_atomically(path: String, text: String) -> Error:
	var temp_path := path + TEMP_SUFFIX
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	var written := file.store_string(text)
	file.close()
	var err := DirAccess.rename_absolute(temp_path, path) if written else ERR_FILE_CANT_WRITE
	if err != OK:
		DirAccess.remove_absolute(temp_path)
	return err


func _utc_now() -> String:
	return Time.get_datetime_string_from_system(true) + "Z"


# --- Lecture, migration, validation -----------------------------------------------------------


## Analyse un texte de sauvegarde. OK : out reçoit les données migrées en v4 et vérifiées, ou
## (F1) celles d'une partie de l'ancienne île (_decoded_legacy vrai : seul son skin sera repris).
## Sinon last_error explique : ERR_PARSE_ERROR (pas un objet JSON), ERR_INVALID_DATA (version
## plus récente que le jeu), ERR_FILE_CORRUPT (version ou champ invalide).
func _decode(text: String, out: Dictionary) -> Error:
	_decoded_legacy = false
	var parsed: Variant = _parse_object(text)
	if parsed == null:
		return ERR_PARSE_ERROR
	var data: Dictionary = parsed
	var version := _version_of(data)
	if version > SAVE_VERSION:
		last_error = "version %d, plus récente que celle du jeu (%d)" % [version, SAVE_VERSION]
		return ERR_INVALID_DATA
	if version < 0:
		last_error = "champ « version » invalide"
		return ERR_FILE_CORRUPT
	if _is_legacy(data, version):
		_decoded_legacy = true
		out.merge(data, true)
		return OK
	if version == LEGACY_VERSION:
		data = _migrate_v3(data)
	var field := _invalid_field(data)
	if not field.is_empty():
		last_error = "champ « %s » invalide" % field
		return ERR_FILE_CORRUPT
	out.merge(data, true)
	return OK


## (F1) Vrai pour une partie de l'ancienne île, qui ne se reprend plus : versions 0 à 2 (toutes
## d'avant la refonte), ou v3 hors de l'acte en jours (day absent ou 0 : l'ancienne île, ou une
## partie jamais posée dans l'acte).
func _is_legacy(data: Dictionary, version: int) -> bool:
	if version < LEGACY_VERSION:
		return true
	if version > LEGACY_VERSION:
		return false
	var day: Variant = data.get("day", 0)
	return not (_is_number(day) and float(day) >= 1.0)


## Objet JSON du texte, ou null (last_error explique).
func _parse_object(text: String) -> Variant:
	if text.strip_edges().is_empty():
		last_error = "fichier vide"
		return null
	var json := JSON.new()
	if json.parse(text) != OK:
		var line := json.get_error_line() + 1
		last_error = "JSON invalide, ligne %d : %s" % [line, json.get_error_message()]
		return null
	if not json.data is Dictionary:
		last_error = "le JSON n'est pas un objet"
		return null
	return json.data


## Version déclarée : 0 si absente (format v0), -1 si ce n'est pas un entier positif ou nul.
func _version_of(data: Dictionary) -> int:
	var version: Variant = data.get("version", 0)
	if not _is_number(version) or float(version) < 0.0 or float(version) != floorf(version):
		return -1
	return int(version)


## (F1) Format v3 (une partie de l'acte en jours) → v4 : les champs de l'ancienne île (zone,
## quêtes, avancement, quête suivie, scores d'arène) sont retirés ; le reste ne change pas.
func _migrate_v3(data: Dictionary) -> Dictionary:
	for key: String in LEGACY_FIELDS:
		data.erase(key)
	data["version"] = SAVE_VERSION
	return data


## Premier champ dont la valeur ne suit pas le schéma v4, "" si tout va bien. Un champ absent est
## permis : GameState.from_dict lui donne sa valeur par défaut.
func _invalid_field(data: Dictionary) -> String:
	var checks: Dictionary[String, Callable] = {
		"saved_at": _is_text,
		"skin": _is_text,
		"max_hp": _is_hp,
		"position": _is_vector,
		"map": _is_text,
		"inventory": _is_map.bind(_is_count),
		"flags": _is_map.bind(_is_bool),
		"collected_pickups": _is_text_list,
		"moment": _is_text,
		"weather": _is_text,
		"island": _is_text,
		"known_islands": _is_text_list,
		"day": _is_count,
		"slot": _is_text,
		"scenes_done": _is_text_list,
		"calendar": _is_map.bind(_is_text),
		"story_scene": _is_text,
	}
	for key: String in checks:
		if data.has(key) and not checks[key].call(data[key]):
			return key
	return ""


func _is_number(value: Variant) -> bool:
	return value is float or value is int


func _is_text(value: Variant) -> bool:
	return value is String


func _is_bool(value: Variant) -> bool:
	return value is bool


func _is_count(value: Variant) -> bool:
	return _is_number(value) and value >= 0


func _is_hp(value: Variant) -> bool:
	return _is_number(value) and value >= 1


func _is_vector(value: Variant) -> bool:
	return value is Array and (value as Array).size() == 3 and (value as Array).all(_is_number)


func _is_text_list(value: Variant) -> bool:
	return value is Array and (value as Array).all(_is_text)


func _is_map(value: Variant, element_check: Callable) -> bool:
	return value is Dictionary and (value as Dictionary).values().all(element_check)
