class_name StoryActivities
extends RefCounted
## (X-L6) Les jeux à la demande du mode libre : un PNJ propose de rejouer un jeu (l'entraînement au
## bâton, une revanche du duel, l'embuscade, l'entraînement avec Seniorious, le ballon), hors du
## récit et sans changer le moindre drapeau (PLAN.md, « (X) Exploration libre : le rythme »).
## Propriétaire : X-L6. Le directeur (StoryDirector) n'appelle que talk(npc), handle_input(event)
## et busy(). Rien ne se passe en scénarisé (active() faux).
##
## - Les données : data/activities/<île>.json (all, problems), une activité par PNJ proposeur : où
##   il doit se trouver (map, place : sa ligne d'emploi du temps, LifeDirector.where), ce qui
##   l'occupe déjà (not_activity : le match de la vie), les conditions d'une scène (day, slot,
##   after, if : StoryOffers.conditions_met), le jeu (game) et ses options (options, variants).
## - Proposer (talk) : parler au PNJ, si aucune scène n'est proposée par lui (StoryOffers.talk
##   passe d'abord), dit la proposition (activities/<id>/offer, dite par lui) avec « Allons-y »
##   (le jeu se lance : MiniGames.start_*) et « Plus tard » (la conversation libre habituelle).
## - Pendant le jeu : Échap l'arrête (MiniGames.stop_all, ou stop_ball_match) et rend la main, avant
##   le menu pause (StoryDirector._input passe avant lui) ; un message dit la fin (le HUD :
##   activities/<id>/result_<issue>), jamais gardé par le récit : aucun drapeau, aucune scène,
##   aucun résultat n'est écrit dans GameState.

## Une activité commence (id), finit (id, issue : STOPPED, SUCCESS…).
signal started(activity_id: StringName)
signal finished(activity_id: StringName, outcome: StringName)

## Dossier des données (<racine>/activities/<île>.json) et jeux connus.
const KIND := "activities"
const GAMES: Array[String] = ["baton", "duel", "seniorious", "ballon", "embuscade"]
## Clés d'une activité et d'une variante.
const KEYS: Array[String] = [
	"game",
	"npc",
	"map",
	"place",
	"day",
	"slot",
	"after",
	"if",
	"not_activity",
	"options",
	"variants",
]
const VARIANT_KEYS: Array[String] = ["if", "options"]
## Action qui arrête le jeu (celle du menu pause : Échap, Start).
const STOP_ACTION := &"pause"
## Issues d'une activité (result_<issue>).
const STOPPED := &"stopped"
const SUCCESS := &"success"
const FAILURE := &"failure"
const VICTORY := &"victory"
const DEFEAT := &"defeat"
const DRAW := &"draw"
const DONE := &"done"
const HUD_GROUP := &"hud"
## Le ballon : le joueur est posé à cette distance (m) à l'ouest du centre du champ.
const BALL_APPROACH := 12.0
## Replis des textes (data/texts/<île>/story.json, « ui/… »).
const FALLBACK_STOP := "Échap : arrêter"
const FALLBACK_OFFER := "Une partie ?"

static var _cache: Dictionary = {}
static var _cache_root: String = ""

## Le directeur (autoload StoryDirector), posé par lui.
var director: Node
## Graine du tirage des jeux (>= 0 : un jeu rejouable, pour les tests ; -1 : le hasard).
var seed_value: int = -1

var _dialogue: StoryOffers.OfferTalk
var _pending: StringName = &""
var _pending_npc: StringName = &""
var _running: StringName = &""
var _game: Object = null
var _rng := RandomNumberGenerator.new()

# --- Points d'entrée (StoryDirector) -----------------------------------------------------------


## Conversation avec un PNJ, en libre, hors scène : vraie si une activité la prend (sa proposition
## s'ouvre).
func talk(npc_id: StringName) -> bool:
	if not active() or busy() or DialogueRunner.is_any_running():
		return false
	var activity_id := offered_by(npc_id)
	if activity_id.is_empty():
		return false
	return propose(activity_id, npc_id)


## Un appui pendant un jeu à la demande (StoryDirector._input) : vrai s'il l'a arrêté (l'appui est
## pris, avant le menu pause).
func handle_input(event: InputEvent) -> bool:
	if not busy() or not event.is_action_pressed(STOP_ACTION):
		return false
	stop()
	return true


## Vrai pendant un jeu lancé à la demande.
func busy() -> bool:
	if _running.is_empty():
		return false
	if not _game_alive():
		# Le jeu a quitté la carte (changement de carte) : plus rien à arrêter.
		_forget()
		return false
	return true


# --- État --------------------------------------------------------------------------------------


## Vrai si les activités ont cours : récit allumé, acte en cours, mode libre, aucune scène.
func active() -> bool:
	return (
		StoryDirector.enabled
		and GameState.story_running()
		and StoryDirector.mode() == StoryPacing.FREE
		and not StoryDirector.is_playing()
	)


## L'activité en cours (&"" : aucune).
func running() -> StringName:
	return _running


## Activités proposables par le PNJ maintenant (ordre des ids) : il est là où l'activité le veut,
## les conditions tiennent. Vide hors du mode libre.
func offered_by(npc_id: StringName) -> StringName:
	if not active():
		return &""
	var island := StoryDirector.island()
	var all_data := all(island)
	var line := LifeDirector.where(npc_id)
	if LifeDirector.npc(npc_id) == null:
		return &""
	var ids: Array = all_data.keys()
	ids.sort()
	for activity_id: Variant in ids:
		var data: Dictionary = all_data[activity_id]
		if (
			str(data["npc"]) == String(npc_id)
			and available(data, line, GameState.day, LifeSlots.current())
		):
			return StringName(str(activity_id))
	return &""


# --- Proposer, lancer, arrêter -----------------------------------------------------------------


## Dit la proposition de l'activité (par le PNJ npc_id), avec « Allons-y » et « Plus tard » ; vrai
## si le dialogue s'ouvre.
func propose(activity_id: StringName, npc_id: StringName) -> bool:
	if DialogueRunner.is_any_running():
		return false
	var island := StoryDirector.island()
	_ensure_dialogue()
	var line := {
		"speaker": _display_name(npc_id),
		"text": StoryData.text(island, text_key(activity_id, "offer"), &"", FALLBACK_OFFER),
		"choices":
		[
			{"text": StoryDirector.ui_text("offer_go", StoryOffers.FALLBACK_GO)},
			{"text": StoryDirector.ui_text("offer_later", StoryOffers.FALLBACK_LATER)},
		],
	}
	_pending = activity_id
	_pending_npc = npc_id
	if not _dialogue.open({StoryOffers.OFFER_NODE: line}, npc_id):
		_pending = &""
		_pending_npc = &""
		return false
	return true


## Lance l'activité (le jeu de MiniGames) ; vrai s'il démarre. Aucun drapeau n'est posé.
func start(activity_id: StringName) -> bool:
	var data: Dictionary = all(StoryDirector.island()).get(activity_id, {})
	if data.is_empty() or busy() or StoryDirector.is_playing():
		return false
	var game := _launch(StringName(str(data["game"])), options_of(data))
	if game == null:
		return false
	_running = activity_id
	_game = game
	# La fin d'un jeu déjà arrêté (sa pose de fin) ne conclut pas l'activité suivante.
	var done := func(result: Dictionary) -> void:
		if _game == game:
			_conclude(_outcome(result))
	if game.has_signal(&"finished"):
		game.connect(&"finished", done, CONNECT_ONE_SHOT)
	elif game.has_signal(&"match_finished"):
		game.connect(&"match_finished", done, CONNECT_ONE_SHOT)
	_show(StoryDirector.ui_text("activity_stop", FALLBACK_STOP))
	started.emit(activity_id)
	return true


## Arrête le jeu en cours : il rend la main (arme, personnages, emplois du temps) ; le message de
## fin s'affiche. Sans effet hors d'une activité.
func stop() -> void:
	if _running.is_empty():
		return
	if is_instance_valid(_game) and _game is BallMatch:
		MiniGames.stop_ball_match()
	else:
		MiniGames.stop_all()
	_conclude(STOPPED)


# --- Données (statiques : tests) ---------------------------------------------------------------


## Chemin du fichier des activités d'une île.
static func path_of(island_id: StringName) -> String:
	return "%s/%s/%s.json" % [StoryData.root(), KIND, island_id]


## Les activités d'une île, vérifiées : id → données ({} sans fichier ; fautif : avertissement).
static func all(island_id: StringName) -> Dictionary:
	if _cache_root != StoryData.root():
		_cache.clear()
		_cache_root = StoryData.root()
	if _cache.has(island_id):
		return _cache[island_id]
	var found: Dictionary = {}
	var file := path_of(island_id)
	if FileAccess.file_exists(file):
		var json := JSON.new()
		var raw: Variant = (
			json.data if json.parse(FileAccess.get_file_as_string(file)) == OK else null
		)
		var problems := problems_of(raw)
		if problems.is_empty():
			found = (raw as Dictionary)["activities"]
		else:
			push_warning("StoryActivities : %s invalide : %s" % [file, "; ".join(problems)])
	_cache[island_id] = found
	return found


## Oublie ce qui a été lu (tests).
static func clear_cache() -> void:
	_cache.clear()


## Vrai si l'activité peut être proposée par son PNJ dont la ligne d'emploi du temps est line
## ({map, place, activity…}), au jour et au créneau donnés : sa carte, sa place, ce qui l'occupe,
## puis les conditions d'une scène (StoryOffers.conditions_met).
static func available(data: Dictionary, line: Dictionary, day: int, slot: StringName) -> bool:
	if data.is_empty() or line.is_empty() or not str(line.get("away", "")).is_empty():
		return false
	if str(line.get("map", "")) != str(data.get("map", "")):
		return false
	if data.has("place") and str(line.get("place", "")) != str(data["place"]):
		return false
	if StoryOffers._names(data.get("not_activity", [])).has(str(line.get("activity", ""))):
		return false
	return StoryOffers.conditions_met(data, day, slot)


## Les options du jeu : « options », fusionnées avec celles de la première variante dont « if »
## tient.
static func options_of(data: Dictionary) -> Dictionary:
	var options: Dictionary = (data.get("options", {}) as Dictionary).duplicate(true)
	var variants: Variant = data.get("variants", [])
	for variant: Variant in variants if variants is Array else []:
		if variant is Dictionary and DialogueRunner.evaluate((variant as Dictionary).get("if")):
			options.merge((variant as Dictionary).get("options", {}), true)
			break
	return options


## Clé d'un texte de l'activité sous « activities/ ».
static func text_key(activity_id: StringName, name: String) -> String:
	return "activities/%s/%s" % [activity_id, name]


## Problèmes d'un fichier d'activités lu (vide : valide) : racine, clés, jeux, conditions.
static func problems_of(raw: Variant) -> PackedStringArray:
	var found := PackedStringArray()
	if not raw is Dictionary or not (raw as Dictionary).get("activities") is Dictionary:
		found.append('la racine doit être {"activities": {…}}')
		return found
	for key: Variant in raw:
		if not str(key).begins_with("_") and str(key) != "activities":
			found.append("clé inconnue « %s »" % key)
	var all_data: Dictionary = (raw as Dictionary)["activities"]
	if all_data.is_empty():
		found.append("aucune activité")
	for activity_id: Variant in all_data:
		var data: Variant = all_data[activity_id]
		if not data is Dictionary:
			found.append("%s : objet attendu" % activity_id)
			continue
		_problems_of_one(str(activity_id), data, found)
	return found


static func _problems_of_one(id: String, data: Dictionary, found: PackedStringArray) -> void:
	StoryData._unknown(data, KEYS, id, found)
	if not GAMES.has(str(data.get("game", ""))):
		found.append("%s : « game » parmi %s" % [id, GAMES])
	for key: String in ["npc", "map"]:
		if str(data.get(key, "")).is_empty():
			found.append("%s : « %s » manque" % [id, key])
	if data.has("day") and DialogueRunner.day_range(data["day"]).y < 0:
		found.append("%s : « day » : un jour ou [premier, dernier]" % id)
	if data.has("slot"):
		for slot: String in StoryOffers._names(data["slot"]):
			if not LifeSlots.is_slot(StringName(slot)):
				found.append("%s : créneau inconnu « %s »" % [id, slot])
	var problem := DialogueRunner.condition_problem(data.get("if"))
	if not problem.is_empty():
		found.append("%s : « if » : %s" % [id, problem])
	if data.has("options") and not data["options"] is Dictionary:
		found.append("%s : « options » : objet attendu" % id)
	var variants: Variant = data.get("variants", [])
	if not variants is Array:
		found.append("%s : « variants » : liste attendue" % id)
		return
	for variant: Variant in variants:
		if not variant is Dictionary:
			found.append("%s : une variante est un objet" % id)
			continue
		StoryData._unknown(variant, VARIANT_KEYS, "%s/variants" % id, found)
		var variant_problem := DialogueRunner.condition_problem((variant as Dictionary).get("if"))
		if not variant_problem.is_empty():
			found.append("%s : variante, « if » : %s" % [id, variant_problem])


# --- Outils ------------------------------------------------------------------------------------


## Le jeu de MiniGames d'une activité (null : il n'a pas pu démarrer). La graine (seed_value) rend
## le tirage rejouable.
func _launch(game: StringName, options: Dictionary) -> Object:
	if seed_value >= 0:
		options["seed"] = seed_value
	match String(game):
		"baton":
			return MiniGames.start_staff_training(options)
		"duel":
			return MiniGames.start_duel(options)
		"seniorious":
			return MiniGames.start_seniorious_training(options)
		"embuscade":
			return MiniGames.start_ambush(options)
		"ballon":
			var places := LifeDirector.places()
			var player := LifeDirector.player_node()
			if places != null and player != null and places.has(MiniGames.BALL_PLACE):
				var field := places.center(MiniGames.BALL_PLACE)
				options["player_at"] = Vector3(field.x - BALL_APPROACH, field.y + 0.2, field.z)
			return MiniGames.start_ball_match(options)
	return null


## Vrai tant que le jeu lancé est sur la carte (un exercice : dans l'arbre ; le match : en cours).
func _game_alive() -> bool:
	if not is_instance_valid(_game):
		return false
	if _game is Node:
		return (_game as Node).is_inside_tree()
	if _game is BallMatch:
		return (_game as BallMatch).running and not (_game as BallMatch).ended
	return false


## Fin de l'activité (une seule fois) : le message, le signal ; l'état du récit n'est jamais touché.
func _conclude(outcome: StringName) -> void:
	if _running.is_empty():
		return
	var activity_id := _running
	_forget()
	var island := StoryDirector.island()
	var key := text_key(activity_id, "result_" + String(outcome))
	var text := StoryData.text(island, key)
	if text.is_empty():
		text = StoryData.text(island, "activities/result_" + String(outcome))
	_show(text)
	finished.emit(activity_id, outcome)


func _forget() -> void:
	_running = &""
	_game = null


## L'issue d'un résultat de jeu : arrêté, ou selon le jeu (ballon : l'équipe du joueur ; duel :
## toujours « fait » ; les autres : réussi ou non).
func _outcome(result: Dictionary) -> StringName:
	if result.get("ended_by") == &"stopped" or bool(result.get("aborted", false)):
		return STOPPED
	if result.has("winner"):
		var winner := StringName(str(result["winner"]))
		var team := StringName(str(result.get("player_team", "")))
		if team.is_empty():
			return DONE
		if winner == &"egalite":
			return DRAW
		return VICTORY if winner == team else DEFEAT
	if result.has("reprise"):
		return DONE
	return SUCCESS if bool(result.get("success", false)) else FAILURE


## Un message en bas de l'écran (le HUD de la partie ; rien sans lui).
func _show(text: String) -> void:
	if text.is_empty() or director == null or not director.is_inside_tree():
		return
	var hud := director.get_tree().get_first_node_in_group(HUD_GROUP)
	if hud != null and hud.has_method(&"show_story_message"):
		hud.call(&"show_story_message", text)


func _ensure_dialogue() -> void:
	if is_instance_valid(_dialogue):
		return
	_dialogue = StoryOffers.OfferTalk.new()
	_dialogue.name = "ActivityDialogue"
	director.add_child(_dialogue)
	if not EventBus.dialogue_ended.is_connected(_on_dialogue_ended):
		EventBus.dialogue_ended.connect(_on_dialogue_ended)


func _display_name(npc_id: StringName) -> String:
	var node := LifeDirector.npc(npc_id)
	if node != null and node.data != null and not node.data.display_name.is_empty():
		return node.data.display_name
	var data := LifeData.find_npc(npc_id)
	return data.display_name if data != null else ""


## La conversation libre du PNJ (« Plus tard ») : celle de StoryDirector hors scène.
func _free_talk(npc_id: StringName) -> void:
	if DialogueRunner.is_any_running() or StoryDirector.is_playing():
		return
	var path := StoryData.talk_path(StoryDirector.island(), npc_id)
	var npc := LifeData.find_npc(npc_id)
	_ensure_dialogue()
	if not path.is_empty() and npc != null and _dialogue.play(path, "", npc_id, npc):
		return
	var actor := LifeDirector.actor(npc_id)
	if actor != null:
		actor.say(LifeTexts.greeting(npc_id, _rng))


func _on_dialogue_ended(dialogue_id: StringName) -> void:
	if _pending.is_empty() or dialogue_id != _pending_npc:
		return
	var activity_id := _pending
	var npc_id := _pending_npc
	var chosen := _dialogue.chosen if is_instance_valid(_dialogue) else -1
	_pending = &""
	_pending_npc = &""
	if chosen == StoryOffers.GO:
		start.call_deferred(activity_id)
	elif chosen == StoryOffers.LATER:
		_free_talk.call_deferred(npc_id)
