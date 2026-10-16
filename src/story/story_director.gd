extends Node
## (E6) StoryDirector (autoload) : le récit en jours et en scènes (docs/REFONTE.md, 6 ; ACTE1.md,
## 0.1 et 0.2 ; PLAN.md, « (E6) Le récit »). Propriétaire : E6.
##
## - L'acte : une île qui a data/scenes/<île>/act.json a un récit. Une nouvelle partie posée sur
##   cette île (WorldManager.start_map) l'ouvre : jour, créneau et temps de « start », écran noir
##   jusqu'à ce que la première scène le lève. GameState.day ≥ 1 tant que l'acte dure
##   (story_running).
## - Les scènes (StoryData) : quand aucune ne se joue, la première (par id) dont les conditions
##   tiennent (jour, créneau, scènes jouées, « if ») et dont le déclencheur part est jouée par
##   StoryRunner : « ready » (tout de suite, sur la carte de la scène), « enter » (sur la
##   carte, arrivé par un marqueur), « reach » (le joueur à moins de radius m d'une place),
##   « talk » (parler à un PNJ), « examine » (lire un objet à examiner), « prompt » (une
##   invite posée sur la carte). Ses présents sont réservés (LifeDirector.reserve) et rendus à
##   la vie à la fin ; le joueur perd le contrôle au début (étape « control » pour le rendre)
##   et le retrouve à la fin ; la scène
##   jouée est retenue (GameState) et la partie écrite. Une partie reprise au milieu d'une scène
##   la rejoue depuis son début, sur sa carte.
## - Le temps : le jour et le créneau n'avancent que par les scènes (étapes slot, next_day) et
##   par le joueur : « Dormir » dans son lit le soir ou la nuit quand les scènes du jour sont
##   faites (fondu, ligne du calendrier écrite, aube du jour suivant), « Laisser passer le temps »
##   (un créneau, jamais au-delà de celui de la prochaine scène clé). La lumière suit le créneau
##   (LifeDirector.set_slot).
## - L'indice (hint, hint_changed) : celui de l'étape « hint » de la scène en cours, sinon celui
##   de la première scène qui attend son déclencheur, sinon celui du coucher.
## - Le calendrier (calendar_requested, day_count, departure_day, calendar_line) ; les séquences
##   déjà vues (user://story_seen.cfg, hors sauvegarde) se passent par l'action « pause ».
## - Crochet des jeux (E8) : register_game(id, appel) ; sans jeu inscrit, l'étape « game » joue
##   son « fallback ».
## - (X-L0) Deux modes de jeu (mode, set_mode) : « scénarisé », tout ce qui précède ; « libre »
##   (défaut) : les règles de StoryPacing et les points d'entrée de StoryOffers (L1), StorySkip
##   (L2) et StoryResolve (L4), seuls appelés ici.

## Une scène commence / finit.
signal scene_started(scene_id: StringName)
signal scene_finished(scene_id: StringName)
## L'indice du récit a changé ("" : plus rien n'attend le joueur).
signal hint_changed(text: String)
## Un jour commence (début de l'acte, réveil).
signal day_started(day: int)
## Une étape « game » demande un jeu (E8) ; émis aussi sans jeu inscrit (le fallback se joue).
signal game_requested(game_id: StringName, params: Dictionary)
## Le calendrier doit s'ouvrir (le joueur a lu celui de sa chambre).
signal calendar_requested
## (X-L0) Le mode de jeu de la partie a changé (StoryPacing.FREE ou SCENARIO).
signal mode_changed(value: StringName)

const SEEN_PATH := "user://story_seen.cfg"
const SEEN_SECTION := StorySkip.SEEN_SECTION
## Réévaluation des déclencheurs, des invites et de l'indice (s).
const CHECK_TIME := 0.1
const REFRESH_TIME := 0.3
const DEFAULT_RADIUS := 2.5
## Action qui passe une séquence déjà vue.
const SKIP_ACTION := StorySkip.SKIP_ACTION
const PROMPTS_NODE := "StoryPrompts"
const EXAMINE_PREFIX := "examine_"
const SLEEP_FADE := 0.8
const REST_FADE := 0.5
const CALENDAR_CARD_TIME := 2.6
## (X-L0) Carton « Jour 1 » d'une nouvelle partie en libre (s, sans les fondus).
const START_CARD_TIME := 1.6
## Au plus ce temps (ms) d'attente de la fin d'une marche de scène avant de rendre un PNJ à la vie.
const RELEASE_WAIT_MS := 12000
## Ce que fait le directeur entre deux scènes (_busy) : dormir, laisser passer le temps.
## Raison qui cache les signes d'interaction pendant une scène (InteractSign.suppress).
const SCENE_SIGNS := &"scene"
const BUSY_SLEEP := &"_sommeil"
const BUSY_REST := &"_repos"

## Directeur actif (un test qui joue sans le récit le coupe).
var enabled: bool = true
## Fichier des séquences déjà vues (les tests en prennent un autre).
var seen_path: String = SEEN_PATH
## (X-L0) Mode d'une partie sans drapeau de mode, et d'une nouvelle partie sans next_game_mode :
## libre dans le jeu ; les tests en prennent un autre (base M1 : mode_for_test, scénarisé).
var default_mode: StringName = StoryPacing.FREE
## (X-L0) Mode demandé pour la prochaine nouvelle partie (à poser avant SaveManager.new_game ; &"" :
## default_mode) ; consommé au chargement de la partie suivante, quelle qu'elle soit.
var next_game_mode: StringName = &""

var _runner: StoryRunner
var _stage: StoryStage
var _talk: StoryDialogue
var _offers: StoryOffers
var _skip: StorySkip
var _resolve: StoryResolve
var _island: StringName = &""
var _current: StringName = &""
var _busy: StringName = &""
var _resume: StringName = &""
var _begin_pending: bool = false
var _doors_day: int = -1
var _doors_mode: StringName = &""
## (X-L0) La dernière scène finie et sa carte : sa suite peut partir en libre.
var _chain := StoryPacing.Chain.new()
var _check_left: float = 0.0
var _refresh_left: float = 0.0
var _hint: String = ""
## Un jeu (E8) de la scène en cours se joue : l'indice se tait.
var _gaming: bool = false
var _scene_hint: String = ""
var _examined: Dictionary = {}
var _talked: Dictionary = {}
var _expect: Dictionary = {}
var _games: Dictionary = {}
var _releases: Array[StringName] = []
var _release_since: Dictionary = {}
var _prompts: Array[StoryPrompt] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_stage = StoryStage.new()
	_stage.name = "Stage"
	add_child(_stage)
	_runner = StoryRunner.new()
	_runner.name = "Runner"
	_runner.director = self
	_runner.stage = _stage
	add_child(_runner)
	_talk = StoryDialogue.new()
	_talk.name = "TalkDialogue"
	add_child(_talk)
	_offers = StoryOffers.new()
	_offers.director = self
	_skip = StorySkip.new()
	_skip.director = self
	_resolve = StoryResolve.new()
	_resolve.director = self
	EventBus.game_loaded.connect(_on_game_loaded)
	EventBus.map_entered.connect(_on_map_entered)
	EventBus.dialogue_ended.connect(_on_dialogue_ended)
	LifeDirector.talk_handler = _on_talk
	# (E8c) Les jeux du récit : l'embuscade de Pannibal (« embuscade_pannibal »).
	MiniGames.register_story_games()


func _physics_process(delta: float) -> void:
	if _runner.is_running() and _stage.player() == null:
		# Partie libérée en pleine scène (retour au menu) : la scène s'arrête, elle sera rejouée.
		_runner.stop()
	var mode_now := mode()
	if GameState.day != _doors_day or mode_now != _doors_mode:
		# Le jour a changé (sommeil, scène, chargement) : les portes fermées jusqu'à un jour ;
		# (X-L0) en libre, toutes ouvertes.
		_doors_day = GameState.day
		_doors_mode = mode_now
		_stage.doors_by_day = StoryPacing.doors_by_day(mode_now)
		_stage.apply_doors(WorldManager.current_map_node())
	if not enabled or not GameState.story_running():
		return
	_serve_releases()
	_stage.tick(delta)
	if _runner.is_running() or not _busy.is_empty():
		return
	if not _stage_ready():
		return
	if not _resume.is_empty():
		_start_resume()
		return
	_check_left -= delta
	if _check_left <= 0.0:
		_check_left = CHECK_TIME
		if _check_triggers():
			return
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = REFRESH_TIME
		refresh()


func _input(event: InputEvent) -> void:
	if not _runner.is_running():
		return
	if _skip.handle_input(event, _runner, _current, StoryData.scene(_island, _current)):
		get_viewport().set_input_as_handled()


# --- État ----------------------------------------------------------------------------------------


## Île du récit (celle de la carte courante).
func island() -> StringName:
	return _island


## Scène en cours (&"" : aucune).
func current_scene() -> StringName:
	return _current


## Vrai pendant une scène (ou pendant le sommeil et le temps qui passe).
func is_playing() -> bool:
	return _runner.is_running() or not _busy.is_empty()


## Le joueur de scènes (tests : étape en cours).
func runner() -> StoryRunner:
	return _runner


## Les outils de scène (places, joueur, voile, suiveurs).
func stage() -> StoryStage:
	return _stage


## Vrai si la scène en cours se passe par SKIP_ACTION (StorySkip : une séquence déjà vue).
func is_skippable() -> bool:
	if not _runner.is_running() or _current.is_empty():
		return false
	return _skip.is_skippable(_current, StoryData.scene(_island, _current))


## Passe la scène en cours (sans effet si elle ne se passe pas).
func skip() -> void:
	if is_skippable():
		_skip.skip(_runner)


## (X-L0) Mode de jeu de la partie : StoryPacing.SCENARIO (drapeau « mode_scenario ») ou
## StoryPacing.FREE (« mode_libre ») ; sans drapeau, default_mode (StoryPacing.FREE dans le jeu).
func mode() -> StringName:
	return StoryPacing.of_game(default_mode)


## Vrai en mode libre.
func is_free() -> bool:
	return mode() == StoryPacing.FREE


## Nom affiché d'un mode : « Mode scénarisé », « Mode libre » (textes ui/mode_*).
func mode_name(value: StringName) -> String:
	return ui_text("mode_" + String(value), StoryPacing.NAMES.get(value, ""))


## (X-L0) Change le mode de la partie (ses drapeaux, écrits avec elle) : portes, propositions et
## invites suivent ; avant la première carte d'une nouvelle partie, son début aussi (noir ou
## carton, créneau).
func set_mode(value: StringName) -> void:
	if not StoryPacing.is_mode(value):
		push_warning("StoryDirector : mode inconnu %s" % value)
		return
	var before := mode()
	StoryPacing.store(value)
	var after := mode()
	if after == before:
		return
	if _begin_pending and StoryData.has_act(_island):
		_apply_day_state(StoryPacing.start_slot(StoryData.act(_island), after))
	_offers.rebuild(WorldManager.current_map_node())
	refresh()
	mode_changed.emit(after)


## (X-L0) Les points d'entrée des lots du libre (L1, L2, L4 ; tests).
func offers() -> StoryOffers:
	return _offers


func skipper() -> StorySkip:
	return _skip


func resolver() -> StoryResolve:
	return _resolve


## Indice courant ("" : rien n'attend le joueur).
func hint() -> String:
	return _hint


## Nombre de jours de l'acte (le plus grand jour décrit, au moins le départ).
func day_count() -> int:
	var count := departure_day()
	var days: Variant = StoryData.act(_island).get("days", {})
	if days is Dictionary:
		for key: Variant in days:
			if str(key).is_valid_int():
				count = maxi(count, str(key).to_int())
	return count


## Jour du départ, entouré au calendrier (0 sans acte).
func departure_day() -> int:
	return int(StoryData.act(_island).get("departure_day", 0))


## Ligne du calendrier d'un jour (celle écrite au coucher, ou une ligne choisie par une scène).
func calendar_line(day: int) -> String:
	var line: StringName = GameState.calendar().get(day, &"")
	if not line.is_empty():
		return StoryData.text(_island, "calendar/" + String(line))
	return StoryData.text(_island, "days/%d/calendar" % day)


## Texte de l'interface du récit (data/texts/<île>/story.json, « ui/<clé> »).
func ui_text(key: String, fallback: String = "") -> String:
	return StoryData.text(_island, "ui/" + key, &"", DialogueRunner.format_text(fallback))


## Vrai si la séquence a déjà été vue (sur cette machine, toutes parties confondues : StorySkip).
func has_seen(scene_id: StringName) -> bool:
	return _skip.has_seen(scene_id, seen_path)


## Oublie les séquences vues (tests).
func forget_seen() -> void:
	_skip.forget_seen(seen_path)


func mark_seen(scene_id: StringName) -> void:
	_skip.mark_seen(scene_id, seen_path)


# --- Jouer -------------------------------------------------------------------------------------


## Joue une scène tout de suite (tests, raccourcis), sans vérifier ses conditions ; faux si une
## scène se joue déjà ou si elle n'existe pas.
func play(scene_id: StringName) -> bool:
	if is_playing():
		return false
	var data := StoryData.scene(_island, scene_id)
	if data.is_empty():
		return false
	_run_scene(scene_id, data)
	return true


## Inscrit un jeu (E8) : handler.call(params) est attendu par l'étape « game » ; s'il rend false,
## le jeu n'a pas pu démarrer et l'étape joue son repli (toute autre valeur : le jeu a eu lieu). Un
## Callable vide le retire.
func register_game(game_id: StringName, handler: Callable) -> void:
	if handler.is_valid():
		_games[game_id] = handler
	else:
		_games.erase(game_id)


func has_game(game_id: StringName) -> bool:
	return _games.has(game_id) and (_games[game_id] as Callable).is_valid()


## Joue le jeu inscrit (coroutine) ; faux s'il n'a pas pu démarrer (le repli se joue alors).
func run_game(game_id: StringName, params: Dictionary) -> bool:
	game_requested.emit(game_id, params)
	# L'indice se tait pendant un jeu (il revient à la fin).
	_gaming = true
	_update_hint()
	var played: Variant = await (_games[game_id] as Callable).call(params)
	_gaming = false
	_update_hint()
	return not (played is bool and not played)


func announce_game(game_id: StringName, params: Dictionary) -> void:
	game_requested.emit(game_id, params)


# --- Le temps ------------------------------------------------------------------------------------


## Vrai si le joueur peut se coucher : créneau du coucher, scènes du jour (sleep_after) faites,
## aucune scène en cours ; (X-L0) en libre, StoryResolve.can_sleep en décide.
func can_sleep() -> bool:
	var rule := _can_sleep_by_day()
	return _resolve.can_sleep(rule) if is_free() else rule


func _can_sleep_by_day() -> bool:
	if is_playing() or not GameState.story_running():
		return false
	var sleep_data: Dictionary = StoryData.act(_island).get("sleep", {})
	if not _names(sleep_data.get("slots", [])).has(String(LifeSlots.current())):
		return false
	var day := StoryData.day_data(_island, GameState.day)
	for scene_id: String in _names(day.get("sleep_after", [])):
		if not GameState.is_scene_done(StringName(scene_id)):
			return false
	return GameState.day < day_count()


## Vrai si le joueur peut laisser passer le temps : pas la nuit, pas au-delà du créneau de la
## prochaine scène clé du jour ; (X-L0) en libre, StoryResolve.can_rest en décide.
func can_rest() -> bool:
	var rule := _can_rest_by_day()
	return _resolve.can_rest(rule) if is_free() else rule


func _can_rest_by_day() -> bool:
	if is_playing() or not GameState.story_running():
		return false
	var slots := GameState.SLOTS
	var current := slots.find(LifeSlots.current())
	return current >= 0 and current < slots.size() - 1 and current < _rest_cap()


## Se couche : fondu, ligne du jour au calendrier, jour suivant à l'aube, réveil (coroutine).
func sleep() -> void:
	if not can_sleep():
		return
	_busy = BUSY_SLEEP
	_stage.set_control(false)
	# L'indice ne reste pas sur le noir (il se rappelle au réveil).
	get_tree().call_group(&"story_hint", &"show_text", "")
	await _stage.fade_overlay(StoryData.BLACK, 1.0, SLEEP_FADE)
	var day := GameState.day
	if is_free():
		# (X-L4) Les scènes laissées passer sont réglées sans être jouées, la ligne du jour choisie.
		_resolve.before_sleep(_island, day)
	if not GameState.has_calendar_line(day):
		GameState.write_calendar(day)
	var title := ui_text("day", "Jour {day}").replace("{day}", str(day))
	var overlay_node := _stage.overlay()
	if overlay_node != null:
		overlay_node.call(&"show_card", "%s\n%s" % [title, calendar_line(day)], CALENDAR_CARD_TIME)
	await _stage.wait_overlay()
	advance_day()
	EventBus.save_requested.emit()
	await get_tree().physics_frame
	await _stage.fade_overlay(StoryData.BLACK, 0.0, SLEEP_FADE)
	_stage.set_control(true)
	_busy = &""
	refresh()


## Laisse passer un créneau (fondu court) ; coroutine.
func pass_time() -> void:
	if not can_rest():
		return
	_busy = BUSY_REST
	_stage.set_control(false)
	# L'indice ne reste pas sur le noir (il se rappelle au réveil).
	get_tree().call_group(&"story_hint", &"show_text", "")
	await _stage.fade_overlay(StoryData.BLACK, 1.0, REST_FADE)
	LifeDirector.set_slot(LifeSlots.next(LifeSlots.current()), 0.0)
	await get_tree().physics_frame
	await _stage.fade_overlay(StoryData.BLACK, 0.0, REST_FADE)
	_stage.set_control(true)
	_busy = &""
	EventBus.save_requested.emit()
	refresh()


## Passe au jour suivant : jour + 1, créneau du réveil, temps du jour (tout de suite).
func advance_day() -> void:
	var act := StoryData.act(_island)
	var sleep_data: Dictionary = act.get("sleep", {})
	GameState.day = GameState.day + 1
	_apply_day_state(StringName(str(sleep_data.get("wake_slot", "aube"))))
	day_started.emit(GameState.day)


# --- Outils des scènes (StoryRunner) ----------------------------------------------------------


## Indice de l'étape « hint » de la scène en cours ("" : aucun).
func set_scene_hint(text: String) -> void:
	_scene_hint = text
	_update_hint()


## Ce qu'attend l'étape wait_for en cours ({} : rien).
func expect(step: Dictionary) -> void:
	_expect = step
	_talked.clear()
	if step.is_empty():
		_examined.clear()


## Ce qu'attend l'étape wait_for en cours ({} : rien ; démonstrations, tests).
func expected() -> Dictionary:
	return _expect.duplicate()


## Vrai quand ce qu'attend wait_for est arrivé.
func expected_met(step: Dictionary) -> bool:
	if WorldManager.is_transitioning():
		return false
	var map_id := WorldManager.current_map()
	if step.has("reach"):
		var on_map := not step.has("map") or StringName(str(step["map"])) == map_id
		var radius := float(step.get("radius", DEFAULT_RADIUS))
		return on_map and _stage.player_within(step["reach"], radius)
	if step.has("map"):
		return map_id == StringName(str(step["map"]))
	if step.has("examine"):
		return _examined.has(str(step["examine"]).replace("/", "_"))
	return not step.has("talk") or _talked.has(StringName(str(step["talk"])))


# --- Invites et indice ----------------------------------------------------------------------------


## Réévalue les invites de la carte et l'indice.
func refresh() -> void:
	for prompt: StoryPrompt in _prompts:
		if is_instance_valid(prompt):
			prompt.set_text(_prompt_text(prompt))
	_offers.refresh()
	_update_hint()


## Invites posées sur la carte courante.
func prompts() -> Array[StoryPrompt]:
	var result: Array[StoryPrompt] = []
	for prompt: StoryPrompt in _prompts:
		if is_instance_valid(prompt):
			result.append(prompt)
	return result


func _prompt_text(prompt: StoryPrompt) -> String:
	if is_playing() or not GameState.story_running():
		return ""
	if prompt.roles.has(StoryPrompt.ROLE_SCENE):
		var data := StoryData.scene(_island, prompt.scene_id)
		if not GameState.is_scene_done(prompt.scene_id) and _conditions_met(data):
			return StoryData.text(_island, str(data["trigger"]["prompt"]), prompt.scene_id)
	var act := StoryData.act(_island)
	if prompt.roles.has(StoryPrompt.ROLE_SLEEP) and can_sleep():
		var sleep_key := str((act.get("sleep", {}) as Dictionary).get("prompt", ""))
		return StoryData.text(_island, sleep_key, &"", "Dormir")
	if prompt.roles.has(StoryPrompt.ROLE_REST) and can_rest():
		var rest_key := str((act.get("rest", {}) as Dictionary).get("prompt", ""))
		return StoryData.text(_island, rest_key, &"", "Laisser passer le temps")
	return ""


func _rebuild_prompts(map: Map) -> void:
	_prompts.clear()
	if map == null or not StoryData.has_act(_island):
		return
	var holder := Node3D.new()
	holder.name = PROMPTS_NODE
	map.add_child(holder)
	var act := StoryData.act(_island)
	var spots: Dictionary = {}
	var sleep_data: Dictionary = act.get("sleep", {})
	if StringName(str(sleep_data.get("map", ""))) == map.map_id():
		_add_role(spots, sleep_data.get("point"), StoryPrompt.ROLE_SLEEP)
		_add_role(spots, sleep_data.get("point"), StoryPrompt.ROLE_REST)
	var rest: Dictionary = act.get("rest", {})
	for point: Variant in rest.get("points", []):
		if point is Dictionary and StringName(str(point.get("map", ""))) == map.map_id():
			_add_role(spots, point.get("point"), StoryPrompt.ROLE_REST)
	for key: Variant in spots:
		_add_prompt(holder, spots[key]["point"], spots[key]["roles"], &"", 1.6)
	for scene_id: StringName in StoryData.scene_ids(_island):
		var data := StoryData.scene(_island, scene_id)
		var trigger: Dictionary = data.get("trigger", {})
		if trigger.get("on") != "prompt":
			continue
		var on_map := StringName(str(trigger.get("map", data.get("map", ""))))
		if on_map == map.map_id() and not GameState.is_scene_done(scene_id):
			var roles: Array[StringName] = [StoryPrompt.ROLE_SCENE]
			_add_prompt(holder, trigger["point"], roles, scene_id, float(trigger.get("size", 1.6)))
	refresh()


func _add_role(spots: Dictionary, point: Variant, role: StringName) -> void:
	var key := str(point)
	if not spots.has(key):
		spots[key] = {"point": point, "roles": [] as Array[StringName]}
	(spots[key]["roles"] as Array[StringName]).append(role)


func _add_prompt(
	holder: Node3D, point: Variant, roles: Array[StringName], scene_id: StringName, size: float
) -> void:
	var prompt := StoryPrompt.new(size)
	prompt.name = "Prompt_%d" % _prompts.size()
	prompt.roles = roles
	prompt.scene_id = scene_id
	prompt.point_name = str(point)
	holder.add_child(prompt)
	prompt.global_position = _stage.resolve(point).origin
	prompt.used.connect(_on_prompt_used)
	_prompts.append(prompt)


func _update_hint() -> void:
	# Pendant une scène (dès son début : S1b, S2), seul l'indice de ses étapes « hint » ; l'indice
	# qui l'annonçait ne traîne pas sur elle ; rien pendant un jeu.
	var in_scene := _runner.is_running() or not _current.is_empty()
	var text := _scene_hint if in_scene else _waiting_hint()
	if _gaming:
		text = ""
	if text != _hint:
		_hint = text
		hint_changed.emit(text)


## Indice hors scène : la première scène qui attend son déclencheur, sinon le coucher.
func _waiting_hint() -> String:
	if not GameState.story_running() or not _busy.is_empty():
		return ""
	if is_free():
		return _resolve.waiting_hint()
	for scene_id: StringName in StoryData.scene_ids(_island):
		if GameState.is_scene_done(scene_id):
			continue
		var data := StoryData.scene(_island, scene_id)
		if data.has("hint") and _conditions_met(data):
			return StoryData.text(_island, str(data["hint"]), scene_id)
	var day := StoryData.day_data(_island, GameState.day)
	if can_sleep() and day.has("sleep_hint"):
		return StoryData.text(_island, str(day["sleep_hint"]))
	if can_rest() and _rest_cap() < GameState.SLOTS.size():
		# Une scène du jour attend un créneau plus tard : le joueur peut laisser passer le temps.
		return ui_text("rest_hint", "Rien ne presse : tu peux laisser passer le temps.")
	return ""


# --- Déclencheurs ------------------------------------------------------------------------------


## Vrai si une scène a commencé.
func _check_triggers() -> bool:
	var map_id := WorldManager.current_map()
	var mode_now := mode()
	var head := _chain.head_on(map_id)
	for scene_id: StringName in StoryData.scene_ids(_island):
		if GameState.is_scene_done(scene_id):
			continue
		var data := StoryData.scene(_island, scene_id)
		if data.is_empty() or not _conditions_met(data):
			continue
		if not StoryPacing.allows_trigger(mode_now, data, head):
			continue
		if _trigger_fires(data, map_id):
			_examined.clear()
			_run_scene(scene_id, data)
			return true
	_examined.clear()
	return false


func _trigger_fires(data: Dictionary, map_id: StringName) -> bool:
	var trigger: Dictionary = data.get("trigger", {})
	var on_map := StringName(str(trigger.get("map", data.get("map", "")))) == map_id
	match str(trigger.get("on", "")):
		"ready":
			return on_map
		"enter":
			var marker := StringName(str(trigger.get("marker", "")))
			return on_map and (marker.is_empty() or WorldManager.arrival_marker() == marker)
		"reach":
			var radius := float(trigger.get("radius", DEFAULT_RADIUS))
			return on_map and _stage.player_within(trigger["point"], radius)
		"examine":
			return _examined.has(str(trigger["key"]).replace("/", "_"))
	return false


## Conditions d'une scène (sans son déclencheur) : jour, créneau, scènes jouées, « if ».
func _conditions_met(data: Dictionary, ignore_slot: bool = false) -> bool:
	if data.is_empty():
		return false
	if data.has("day"):
		var days := DialogueRunner.day_range(data["day"])
		if GameState.day < days.x or GameState.day > days.y:
			return false
	if data.has("slot") and not ignore_slot:
		if not _names(data["slot"]).has(String(LifeSlots.current())):
			return false
	for scene_id: String in _names(data.get("after", [])):
		if not GameState.is_scene_done(StringName(scene_id)):
			return false
	return not data.has("if") or DialogueRunner.evaluate(data["if"])


## Créneau (index) au-delà duquel on ne laisse pas passer le temps : le premier créneau de la
## prochaine scène clé du jour (jour, scènes et « if » remplis) ; SLOTS.size() sans elle.
func _rest_cap() -> int:
	var cap := GameState.SLOTS.size()
	for scene_id: StringName in StoryData.scene_ids(_island):
		if GameState.is_scene_done(scene_id):
			continue
		var data := StoryData.scene(_island, scene_id)
		if data.get("key", true) != true or not data.has("slot"):
			continue
		if not _conditions_met(data, true):
			continue
		var first := GameState.SLOTS.find(StringName(_names(data["slot"])[0]))
		if first >= 0:
			cap = mini(cap, first)
	return cap


## Prêt à juger les déclencheurs : une carte et un joueur, pas de changement de carte, ni
## dialogue, ni pause.
func _stage_ready() -> bool:
	return (
		_stage.player() != null
		and WorldManager.current_map_node() != null
		and not WorldManager.is_transitioning()
		and not DialogueRunner.is_any_running()
		and not get_tree().paused
	)


# --- Scènes ---------------------------------------------------------------------------------------


func _run_scene(scene_id: StringName, data: Dictionary, resume: bool = false) -> void:
	_current = scene_id
	_chain.clear()
	_stage.scene_label = scene_id
	GameState.story_scene = scene_id
	_scene_hint = ""
	_update_hint()
	for npc_id: String in _names(data.get("present", [])):
		LifeDirector.reserve(StringName(npc_id))
		_releases.erase(StringName(npc_id))
	_stage.set_control(false)
	_scene_ui(true)
	_update_skip_prompt(scene_id, data)
	scene_started.emit(scene_id)
	if resume and WorldManager.current_map() != StringName(str(data.get("map", ""))):
		await WorldManager.go_to(
			StringName(str(data["map"])), StringName(str(data.get("marker", "Spawn")))
		)
	var completed: bool = await _runner.run(scene_id, data, _island)
	_end_scene(scene_id, data, completed)


func _end_scene(scene_id: StringName, data: Dictionary, completed: bool) -> void:
	var rig := _stage.camera_rig()
	if rig != null:
		rig.call(&"release_story", 1.0)
	var overlay_node := _stage.overlay()
	if overlay_node != null:
		overlay_node.call(&"set_skip_text", "")
		overlay_node.call(&"hide_card")
		if float(overlay_node.call(&"fade_alpha")) > 0.0 and completed:
			overlay_node.call(&"fade_to", overlay_node.call(&"fade_color"), 0.0, 0.6)
	_stage.clear()
	_scene_ui(false)
	_scene_hint = ""
	_current = &""
	_offers.scene_ended(scene_id, completed)
	if not completed:
		return
	# (X-L0) Sa suite peut partir en libre, sur la carte où elle finit.
	_chain.finished(scene_id)
	_stage.set_control(true)
	for npc_id: String in _names(data.get("present", [])):
		_releases.append(StringName(npc_id))
	GameState.mark_scene_done(scene_id)
	GameState.story_scene = &""
	mark_seen(scene_id)
	scene_finished.emit(scene_id)
	EventBus.save_requested.emit()
	if _stage_ready() and not _check_triggers():
		refresh()
	elif _current.is_empty():
		# (S2) Pas prêt (dialogue, changement de carte) : l'indice de ce qui suit, tout de suite.
		_update_hint()


func _start_resume() -> void:
	var scene_id := _resume
	_resume = &""
	var data := StoryData.scene(_island, scene_id)
	if data.is_empty() or GameState.is_scene_done(scene_id):
		GameState.story_scene = &""
		return
	_run_scene(scene_id, data, true)


func _update_skip_prompt(scene_id: StringName, data: Dictionary) -> void:
	var overlay_node := _stage.overlay()
	if overlay_node == null:
		return
	overlay_node.call(&"set_skip_text", _skip.prompt_text(scene_id, data))


## Pendant une scène (on) : signes d'interaction cachés (InteractSign.suppress) ; après : rendus,
## et la boîte de dialogue reprend sa présentation « nuit ».
func _scene_ui(on: bool) -> void:
	InteractSign.suppress(SCENE_SIGNS, on)
	if not on and DialogueBox.presentation() != DialogueBox.PRESENTATION_NUIT:
		DialogueBox.set_presentation(DialogueBox.PRESENTATION_NUIT)


## Rend à la vie les présents d'une scène finie, une fois leur dernière marche de scène finie
## (Pannibal file vers le marais au lieu de rentrer tout de suite ; RELEASE_WAIT_MS au plus).
func _serve_releases() -> void:
	if _releases.is_empty() or _runner.is_running():
		return
	var waiting: Array[StringName] = []
	for npc_id: StringName in _releases:
		var actor := LifeDirector.actor(npc_id)
		var since: int = _release_since.get(npc_id, Time.get_ticks_msec())
		var walking := actor != null and actor.state == LifeActor.State.SCENE and actor.is_moving()
		if walking and Time.get_ticks_msec() - since < RELEASE_WAIT_MS:
			_release_since[npc_id] = since
			waiting.append(npc_id)
		else:
			_release_since.erase(npc_id)
			LifeDirector.release(npc_id)
	_releases = waiting


# --- Début de l'acte, parties ----------------------------------------------------------------


func _apply_day_state(slot: StringName) -> void:
	var day := StoryData.day_data(_island, GameState.day)
	var weather := StringName(str(day.get("weather", GameState.weather)))
	LifeDirector.set_slot(slot, 0.0)
	Atmosphere.set_atmosphere(LifeSlots.moment_of(slot), weather, 0.0)
	GameState.slot = slot
	Atmosphere.snap()


func _on_game_loaded() -> void:
	_runner.stop()
	_stage.clear()
	_scene_ui(false)
	_examined.clear()
	_talked.clear()
	_expect = {}
	_releases.clear()
	_release_since.clear()
	_scene_hint = ""
	_gaming = false
	_current = &""
	_busy = &""
	_begin_pending = false
	_chain.clear()
	var start_island := WorldAtlas.island_of(WorldManager.starting_map())
	_island = start_island
	var fresh := (
		SaveManager.started_new
		and GameState.map.is_empty()
		and GameState.day == 0
		and GameState.scenes_done().is_empty()
	)
	var wanted := next_game_mode
	next_game_mode = &""
	var opens_act := enabled and fresh and StoryData.has_act(start_island)
	if opens_act:
		# (X-L0) Le mode de la nouvelle partie : demandé, sinon celui par défaut (écrit s'il est libre
		# ou demandé ; les tests au mode par défaut scénarisé n'ont pas de drapeau de plus).
		if StoryPacing.is_mode(wanted):
			StoryPacing.store(wanted)
		elif default_mode == StoryPacing.FREE:
			StoryPacing.store(StoryPacing.FREE)
	elif enabled and not fresh:
		# (X-L0) Une ancienne partie sans drapeau de mode, des scènes faites : scénarisée.
		StoryPacing.migrate()
	_resume = GameState.story_scene
	if not _resume.is_empty() and not StoryPacing.replays_interrupted(mode()):
		# (X-L0) En libre, la scène interrompue n'est pas rejouée : elle redevient disponible.
		_resume = &""
		GameState.story_scene = &""
	if opens_act:
		var start: Dictionary = StoryData.act(start_island)["start"]
		GameState.day = int(start["day"])
		if start.has("weather"):
			GameState.weather = StringName(str(start["weather"]))
		_apply_day_state(StoryPacing.start_slot(StoryData.act(start_island), mode()))
		_begin_pending = true
		day_started.emit(GameState.day)
	_update_hint()


func _on_map_entered(map_id: StringName) -> void:
	_island = WorldAtlas.island_of(map_id)
	var map := WorldManager.current_map_node()
	var mode_now := mode()
	_stage.doors_by_day = StoryPacing.doors_by_day(mode_now)
	_stage.set_map(map)
	_rebuild_prompts(map)
	_offers.rebuild(map)
	if not _runner.is_running():
		_chain.entered(map_id)
	if _begin_pending:
		_begin_pending = false
		var act := StoryData.act(_island)
		var start: Dictionary = act.get("start", {})
		var overlay_node := _stage.overlay()
		if overlay_node != null and StoryPacing.starts_in_black(mode_now):
			overlay_node.call(&"set_fade", StoryData.BLACK, 1.0)
		elif overlay_node != null and StoryPacing.shows_start_card(act, mode_now):
			# (X-L0) Libre : pas de noir, un carton « Jour 1 », la main au joueur.
			var title := ui_text("day", "Jour {day}").replace("{day}", str(GameState.day))
			overlay_node.call(&"show_card", title, START_CARD_TIME)
		if start.has("marker") and str(start.get("map", "")) == String(map_id):
			var marker := map.marker(StringName(str(start["marker"]))) if map != null else null
			if marker != null:
				_stage.place_player(marker.global_position, -marker.global_basis.z)
	if _runner.is_running() and not _stage.followers().is_empty():
		_stage.restage_followers()


func _on_dialogue_ended(dialogue_id: StringName) -> void:
	var text := String(dialogue_id)
	if not text.begins_with(EXAMINE_PREFIX) or not GameState.story_running():
		return
	var key := text.trim_prefix(EXAMINE_PREFIX)
	_examined[key] = true
	var calendar: Dictionary = StoryData.act(_island).get("calendar", {})
	if str(calendar.get("examine", "")).replace("/", "_") == key and not _runner.is_running():
		calendar_requested.emit.call_deferred()


## Conversation avec un PNJ de la vie (LifeDirector.talk_handler) : vraie si le récit la prend.
func _on_talk(npc_id: StringName) -> bool:
	if not enabled or not GameState.story_running():
		return false
	if not _busy.is_empty():
		return true
	if _runner.is_running():
		if _expect.get("talk", "") == String(npc_id):
			_talked[npc_id] = true
			return true
		return _free_talk(npc_id)
	if is_free():
		# (X-L0) En libre, « talk » ne lance pas de scène : une proposition (L1) ou la conversation.
		return _offers.talk(npc_id) or _free_talk(npc_id)
	return _talk_scene(npc_id) or _free_talk(npc_id)


## Joue la scène que lance la conversation avec ce PNJ (déclencheur « talk ») ; vrai si elle part.
func _talk_scene(npc_id: StringName) -> bool:
	var map_id := WorldManager.current_map()
	for scene_id: StringName in StoryData.scene_ids(_island):
		var data := StoryData.scene(_island, scene_id)
		var trigger: Dictionary = data.get("trigger", {})
		if trigger.get("on") != "talk" or StringName(str(trigger.get("npc", ""))) != npc_id:
			continue
		var on_map := StringName(str(trigger.get("map", data.get("map", ""))))
		if on_map == map_id and not GameState.is_scene_done(scene_id) and _conditions_met(data):
			_run_scene(scene_id, data)
			return true
	return false


## Ce que dit un personnage hors des scènes : data/dialogues/<île>/talk/<pnj>.json, sinon une
## bulle de salutation.
func _free_talk(npc_id: StringName) -> bool:
	if DialogueRunner.is_any_running():
		return true
	var path := StoryData.talk_path(_island, npc_id)
	var npc := LifeData.find_npc(npc_id)
	if not path.is_empty() and npc != null and _talk.play(path, "", npc_id, npc):
		return true
	var actor := LifeDirector.actor(npc_id)
	if actor != null:
		actor.say(LifeTexts.greeting(npc_id, _rng))
	return true


func _on_prompt_used(prompt: StoryPrompt) -> void:
	if is_playing():
		return
	if prompt.roles.has(StoryPrompt.ROLE_SCENE):
		var data := StoryData.scene(_island, prompt.scene_id)
		if not GameState.is_scene_done(prompt.scene_id) and _conditions_met(data):
			_run_scene(prompt.scene_id, data)
			return
	if prompt.roles.has(StoryPrompt.ROLE_SLEEP) and can_sleep():
		sleep()
	elif prompt.roles.has(StoryPrompt.ROLE_REST) and can_rest():
		pass_time()


# --- Outils ------------------------------------------------------------------------------------


static func _names(value: Variant) -> Array[String]:
	var result: Array[String] = []
	for item: Variant in value if value is Array else [value]:
		if item is String or item is StringName:
			result.append(str(item))
	return result
