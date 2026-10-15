class_name SenioriousTraining
extends Node3D
## (E8b) L'entraînement spécial avec Seniorious (docs/lore/ACTE1.md, 3.4 ; scène 11.4, le jour 11 en
## fin d'après-midi, la clairière) : Willem et Chtholly seuls, Seniorious en main.
## Propriétaire : E8. Chiffres : data/games/seniorious.json. Sur le modèle du duel (duel.gd).
##
## - Étape 1, la respiration (&"breath") : une jauge de souffle, inspirer 2 s, expirer 2 s ; le
##   joueur tient la charge (le venenum) à l'inspiration et la relâche à la fin de l'expiration,
##   à 0,3 s près ; cinq cycles. Pas d'échec : Willem corrige (« plus lent », « plus vite »).
## - Étape 2, les mouvements de base (&"moves") : Willem annonce un geste (« Trois coups. »,
##   « Pare. », « Côté. ») ; le joueur l'exécute dans les 1,5 s ; neuf annonces.
## - Étape 3, la Grue de Gossamer (&"crane") : Willem fend (annoncé 0,6 s : sa garde, un cercle au
##   sol) ; une parade parfaite (la touche de charge pressée dans les 0,2 s avant l'impact) suivie
##   d'une attaque fait pivoter Chtholly, qui détourne son coup et le renvoie. Trois Grues : la
##   troisième arrache Seniorious, qui tourne en l'air et plonge dans le marais.
## - Étape 4 (&"pickup") : ramasser l'épée dans le marais (marais_epee), invite « Ramasser
##   Seniorious » ; option pickup = false : l'exercice finit quand l'épée est tombée (le récit s'en
##   charge).
## Réussite : trois Grues (et l'épée ramassée). Échec : douze fends sans trois Grues, ou à bout de
## forces (fatigue_time) : Chtholly s'assoit, la scène continue (ACTE1.md, 3.0 : pas de défaite).
## Aucun vrai dégât : jamais de Health touchée. Option start_stage (1 à 3) : la réussite du jour 9
## fait commencer à l'étape 2 (ACTE1.md, 3.2).
##
## Pendant l'exercice : le joueur a la main, Seniorious en main, Willem muet (Hush) dans sa tenue
## « duel » (willem_duel, avec Percival), les signes cachés ; tout revient à la fin. Résultat
## (finished, après la pose de fin) : {success, ended_by (&"grues", &"fatigue", &"stopped"),
## stage_reached, start_stage, breaths {good, early, late, missed, cycles}, moves {done, missed,
## announced}, grues, fends, parried, hits, picked_up, duration}.
## Tout se fait au pas de advance(delta) : le nœud s'avance seul à chaque image physique, les tests
## le coupent (set_physics_process(false)) et l'avancent à la main.

## L'étape a changé : &"intro", &"breath", &"moves", &"crane", &"pickup", &"ended".
signal stage_changed(stage: StringName)
## Un geste est jugé : (&"breath", &"good" | &"early" | &"late" | &"missed"), (&"move", &"done" |
## &"missed"), (&"fend", &"crane" | &"parried" | &"hit" | &"dodged"), (&"sword", &"flew" |
## &"landed" | &"picked").
signal resolved(kind: StringName, outcome: StringName)
## Willem annonce un geste (étape 2 : &"trois_coups", &"pare", &"cote").
signal announced(gesture: StringName)
## L'exercice est fini, la pose de fin jouée, tout rendu (résultat : voir plus haut).
signal finished(result: Dictionary)

const GAME_RULES := &"seniorious"
const STAGES: Array[StringName] = [&"breath", &"moves", &"crane"]
const TelegraphScript := preload("res://src/enemies/telegraph.gd")
const SCORE_SCRIPT := preload("res://src/games/game_score.gd")
const SIGNS_REASON := &"seniorious"
## Couche 6 (interactable) et groupe des interactables (PLAN.md, section 3).
const INTERACTABLE_LAYER := 32
const INTERACTABLE_GROUP := &"interactable"
const BLADE_HEIGHT := 1.0

var player: Player = null
var willem: LifeActor = null
var overrides: Dictionary = {}
var show_hud: bool = true
## L'épée tombée se ramasse (étape 4) ; faux : l'exercice finit quand elle est tombée.
var with_pickup: bool = true
## Étape de départ (1 : la respiration ; 2 : les mouvements ; 3 : la Grue).
var start_stage: int = 1
var stage: StringName = &"idle"
var breaths: Dictionary = {&"good": 0, &"early": 0, &"late": 0, &"missed": 0, &"cycles": 0}
var moves: Dictionary = {&"done": 0, &"missed": 0, &"announced": 0}
var grues: int = 0
var fends: int = 0
var parried: int = 0
var hits: int = 0
var picked_up: bool = false
var elapsed: float = 0.0

var _time: float = 0.0
var _stage_start: float = 0.0
var _stage_index: int = 0
var _link_left: float = -1.0
var _end_left: float = -1.0
var _done: bool = false
var _result: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _was_charging: bool = false
var _last_press: float = -100.0
var _last_release: float = -100.0
var _attacks: Array[float] = []
var _cycle_start: float = 0.0
var _gesture: Dictionary = {}
var _gesture_order: Array = []
var _next_at: float = 0.0
var _fend: Dictionary = {}
var _hop: Dictionary = {}
var _sword: Dictionary = {}
var _sword_sprite: AnimatedSprite3D = null
var _pickup: Area3D = null
var _telegraph: TelegraphScript = null
var _hud: CanvasLayer = null
var _hush: Hush = null
var _saved_actor: Dictionary = {}
var _previous_weapon: StringName = &""
var _restore_weapon: bool = true
var _was_held: bool = false
var _ui_taken: bool = false


## Le jeu muet qui tient Willem : lui parler pendant l'exercice ne fait rien.
class Hush:
	extends LifeGame

	var active: bool = true

	func on_player_interact(_actor: LifeActor) -> bool:
		return active

	func blocks_talk() -> bool:
		return active


## L'épée dans le marais : invite « Ramasser Seniorious » (contrat Interactable).
class SwordPickup:
	extends Area3D

	var training: SenioriousTraining = null
	var prompt: String = ""

	func get_prompt() -> String:
		return prompt

	func interact(_player: Node3D) -> void:
		if training != null and is_instance_valid(training):
			training.pick_up()


func _init() -> void:
	name = "SenioriousTraining"
	_rng.seed = Time.get_ticks_usec()


## Fixe le tirage (tests, démonstrations) : la même graine rejoue le même exercice.
func seed_random(value: int) -> void:
	_rng.seed = value


func _physics_process(delta: float) -> void:
	advance(delta)


func _exit_tree() -> void:
	if not _done:
		_restore(false)


# --- Règles --------------------------------------------------------------------------------------


## Un chiffre des règles (chemin « crane/window »).
func rule(key_path: String, default: float) -> float:
	return GameRules.number(GAME_RULES, key_path, default, overrides)


func anim_list(key_path: String) -> Array[StringName]:
	var found: Variant = GameRules.value(GAME_RULES, key_path, [], overrides)
	var list: Array[StringName] = []
	if found is Array:
		for entry: Variant in found:
			list.append(StringName(str(entry)))
	return list


## Texte de l'exercice (data/texts/life.json, games/seniorious/<clé> ; {player} accepté).
func line(key: String, fallback: String = "") -> String:
	return LifeTexts.text("games/seniorious/%s" % key, fallback, _rng)


# --- Mise en place et fin ------------------------------------------------------------------------


## Prépare l'exercice : le joueur, Willem, l'étape de départ (1 à 3), l'étape 4.
func setup(
	the_player: Player, the_willem: LifeActor, first_stage: int = 1, pickup: bool = true
) -> void:
	player = the_player
	willem = the_willem
	start_stage = clampi(first_stage, 1, STAGES.size())
	with_pickup = pickup


## Commence : Seniorious en main, la main au joueur, Willem muet, les signes cachés.
func start(restore_weapon: bool = true) -> void:
	if stage != &"idle" or player == null or willem == null:
		return
	_restore_weapon = restore_weapon
	_previous_weapon = player.weapon()
	player.set_weapon(PlayerCombat.WEAPON_SENIORIOUS)
	_was_held = player.is_story_held()
	player.set_story_hold(false)
	_ui_taken = true
	InteractSign.suppress(SIGNS_REASON, true)
	_connect_player()
	_take_control()
	_telegraph = TelegraphScript.new() as TelegraphScript
	_telegraph.name = "Telegraph"
	add_child(_telegraph)
	if show_hud:
		_hud = SCORE_SCRIPT.new() as CanvasLayer
		_hud.name = "SenioriousScore"
		add_child(_hud)
	_stage_index = start_stage - 1
	_set_stage(&"intro")
	willem.face(player.global_position - willem.position())
	_play_willem(anim_list("anims/willem_announce"), true)
	willem.say(line("intro", "Respire d'abord. Le reste viendra."), 2.0)
	_update_hud()


## Arrête l'exercice : résultat « stopped », tout est rendu tout de suite.
func stop() -> void:
	if not is_running():
		return
	_finish(&"stopped", false)
	_end_left = 0.0
	advance(0.0)


func is_running() -> bool:
	return stage != &"idle" and stage != &"ended"


func is_done() -> bool:
	return _done


func result() -> Dictionary:
	return _result


func game_time() -> float:
	return _time


## Le cycle de souffle : &"in" (inspirer) ou &"out" (expirer), et sa part écoulée (0..1).
func breath_phase() -> Array:
	var inhale := rule("breath/inhale", 2.0)
	var local := _time - _cycle_start
	if local < inhale:
		return [&"in", clampf(local / inhale, 0.0, 1.0)]
	return [&"out", clampf((local - inhale) / rule("breath/exhale", 2.0), 0.0, 1.0)]


## Fin du cycle de souffle en cours (temps du jeu) : là qu'il faut relâcher.
func breath_end() -> float:
	return _cycle_start + rule("breath/inhale", 2.0) + rule("breath/exhale", 2.0)


## Le geste annoncé ({} entre deux) : gesture, start, deadline.
func current_gesture() -> Dictionary:
	return _gesture


## Le fend en cours ({} entre deux) : start, impact, warn, perfect (parade parfaite), follow_until.
func current_fend() -> Dictionary:
	return _fend


## L'épée tombée (étape 4) : le point où elle est, Vector3.INF avant.
func sword_spot() -> Vector3:
	return _sword.get("to", Vector3.INF) if _sword.get("landed", false) else Vector3.INF


## L'invite de l'épée tombée (null avant).
func pickup_area() -> Area3D:
	return _pickup


func _set_stage(next: StringName) -> void:
	stage = next
	_stage_start = _time
	stage_changed.emit(next)


func _take_control() -> void:
	_saved_actor = {
		"state": willem.state,
		"activity": willem.activity,
		"line": willem.line,
		"outfit": willem.outfit,
	}
	willem.stop()
	_hush = Hush.new()
	if willem.state != LifeActor.State.SCENE:
		willem.activity = {
			"poses": [{"anim": "repos"}], "look": false, "greet": false, "step_aside": false
		}
		willem.state = LifeActor.State.GAME
	willem.game = _hush
	var outfit := StringName(str(GameRules.value(GAME_RULES, "willem_outfit", "duel", overrides)))
	if willem.data != null and willem.data.outfits.has(outfit) and willem.outfit != outfit:
		willem.outfit = outfit
		willem.npc.set_outfit(LifeDirector.outfit_skin(willem.data, outfit))
	if is_instance_valid(willem.npc):
		InteractSign.set_hidden(willem.npc, true)


func _release_control() -> void:
	if willem == null or _saved_actor.is_empty():
		return
	if _hush != null:
		_hush.active = false
	willem.game = null
	if is_instance_valid(willem.npc):
		InteractSign.set_hidden(willem.npc, false)
		var outfit: StringName = _saved_actor["outfit"]
		if willem.outfit != outfit and willem.data != null:
			willem.outfit = outfit
			willem.npc.set_outfit(LifeDirector.outfit_skin(willem.data, outfit))
	var saved_state: LifeActor.State = _saved_actor["state"]
	if saved_state != LifeActor.State.SCENE and willem.state != LifeActor.State.GONE:
		willem.stop()
		willem.activity = _saved_actor["activity"]
		willem.state = saved_state
		var scheduled: Dictionary = _saved_actor["line"]
		if scheduled.has("map") and LifeDirector.current_map() != null:
			willem.place_now(scheduled)
	elif willem.state != LifeActor.State.GONE:
		willem.play(&"repos")
	_saved_actor = {}


func _restore(with_hold: bool) -> void:
	if _ui_taken:
		_ui_taken = false
		InteractSign.suppress(SIGNS_REASON, false)
	_disconnect_player()
	_free_hud()
	_free_sword()
	if is_instance_valid(player):
		player.hold_pose(&"", 0.0)
		if _restore_weapon and not _previous_weapon.is_empty():
			player.set_weapon(_previous_weapon)
			_previous_weapon = &""
		if with_hold and _was_held:
			player.set_story_hold(true)
	if willem != null and is_instance_valid(willem.npc):
		_release_control()


# --- Image par image -----------------------------------------------------------------------------


## Avance l'exercice de delta s.
func advance(delta: float) -> void:
	if stage == &"idle" or _done:
		return
	_time += delta
	_tick_hop()
	_tick_sword()
	if stage == &"ended":
		_end_left -= delta
		if _end_left <= 0.0:
			_close()
		return
	elapsed += delta
	_watch_charge()
	if elapsed >= rule("fatigue_time", 150.0) and stage != &"pickup":
		_finish(&"fatigue", false)
		return
	if _link_left >= 0.0:
		_link_left -= delta
		if _link_left < 0.0:
			_enter_stage(STAGES[_stage_index])
	else:
		match stage:
			&"intro":
				if _time - _stage_start >= rule("intro_time", 1.4):
					_enter_stage(STAGES[_stage_index])
			&"breath":
				_advance_breath()
			&"moves":
				_advance_moves()
			&"crane":
				_advance_crane()
	if is_running():
		_face_willem()
		_update_telegraph()
		_update_hud()


func _enter_stage(next: StringName) -> void:
	_set_stage(next)
	_gesture = {}
	_fend = {}
	match next:
		&"breath":
			_cycle_start = _time + rule("breath/first_delay", 0.6)
			willem.say(
				line("breath_start", "Inspire avec la charge. Relâche à la fin du souffle."), 2.4
			)
		&"moves":
			_next_at = _time + rule("moves/gap", 1.0)
			willem.say(line("moves_start", "Les gestes de base. Écoute, puis fais."), 2.0)
		&"crane":
			_next_at = _time + rule("crane/first_delay", 1.2)
			willem.say(
				line("crane_start", "La Grue de Gossamer. Pare au dernier instant, puis rends."),
				2.6
			)
	_play_willem(anim_list("anims/willem_rest"), false)


## L'étape suivante après un temps de liaison, ou la fin.
func _next_stage() -> void:
	_stage_index += 1
	_gesture = {}
	_fend = {}
	_clear_telegraph()
	if _stage_index >= STAGES.size():
		return
	_link_left = rule("link_time", 1.6)


# --- Le souffle ----------------------------------------------------------------------------------


func _advance_breath() -> void:
	if _time < _cycle_start:
		return
	var tolerance := rule("breath/tolerance", 0.3)
	var end := breath_end()
	if _time < end + tolerance:
		return
	# Le cycle est jugé : relâchée près de la fin, après un souffle tenu ?
	var inhale_end := _cycle_start + rule("breath/inhale", 2.0)
	var outcome := &"missed"
	var held := _last_release - _last_press
	if _was_charging:
		outcome = &"late"
	elif (
		_last_press >= _cycle_start - tolerance
		and _last_press <= inhale_end
		and _last_release > _last_press
	):
		if absf(_last_release - end) <= tolerance and held >= rule("breath/hold_min", 1.5):
			outcome = &"good"
		elif _last_release < end - tolerance:
			outcome = &"early"
		else:
			outcome = &"late"
	breaths[outcome] = int(breaths[outcome]) + 1
	breaths[&"cycles"] = int(breaths[&"cycles"]) + 1
	resolved.emit(&"breath", outcome)
	willem.say(line("breath_%s" % outcome, "…"), 1.4)
	if int(breaths[&"cycles"]) >= int(rule("breath/cycles", 5.0)):
		_next_stage()
		return
	_cycle_start = end


# --- Les mouvements de base ----------------------------------------------------------------------


func _advance_moves() -> void:
	if _gesture.is_empty():
		if int(moves[&"announced"]) >= int(rule("moves/count", 9.0)):
			_next_stage()
			return
		if _time >= _next_at:
			_announce()
		return
	if _gesture_done():
		_end_gesture(&"done")
	elif _time >= float(_gesture["deadline"]):
		_end_gesture(&"missed")


func _announce() -> void:
	var list: Variant = GameRules.value(GAME_RULES, "moves/gestures", [], overrides)
	var gestures: Array = list if list is Array and not (list as Array).is_empty() else ["pare"]
	var index := int(moves[&"announced"])
	# Chaque geste revient une fois par tour, dans un ordre tiré (graine) : neuf annonces, trois
	# de chaque.
	var round_start := index - index % gestures.size()
	if index == round_start:
		_gesture_order = gestures.duplicate()
		for i: int in range(_gesture_order.size() - 1, 0, -1):
			var j := _rng.randi_range(0, i)
			var swap: Variant = _gesture_order[i]
			_gesture_order[i] = _gesture_order[j]
			_gesture_order[j] = swap
	var gesture := StringName(str(_gesture_order[index - round_start]))
	moves[&"announced"] = index + 1
	_gesture = {
		"gesture": gesture,
		"start": _time,
		"deadline": _time + rule("moves/window", 1.5),
		"from": player.global_position,
		"attacks": _attacks.size(),
		"press": _last_press,
	}
	_play_willem(anim_list("anims/willem_announce"), true)
	willem.say(line("gesture_%s" % gesture, String(gesture)), 1.3)
	announced.emit(gesture)


func _gesture_done() -> bool:
	match _gesture["gesture"]:
		&"trois_coups":
			var count := 0
			for at: float in _attacks:
				if at >= float(_gesture["start"]):
					count += 1
			return count >= int(rule("moves/combo", 3.0))
		&"pare":
			return _last_press >= float(_gesture["start"])
		&"cote":
			var from: Vector3 = _gesture["from"]
			var toward := _flat(from - willem.position())
			var side := (
				toward.normalized().cross(Vector3.UP) if toward.length() > 0.05 else Vector3.RIGHT
			)
			var moved := _flat(player.global_position - from)
			return absf(moved.dot(side)) >= rule("moves/side_distance", 0.8)
	return false


func _end_gesture(outcome: StringName) -> void:
	var gesture: StringName = _gesture["gesture"]
	moves[outcome] = int(moves[outcome]) + 1
	_gesture = {}
	_next_at = _time + rule("moves/gap", 1.0)
	resolved.emit(&"move", outcome)
	if outcome == &"done":
		willem.say(line("move_done", "Bien."), 0.9)
	else:
		willem.say(line("move_missed_%s" % gesture, "Encore."), 1.3)


# --- La Grue de Gossamer -------------------------------------------------------------------------


func _advance_crane() -> void:
	if _fend.is_empty():
		if fends >= int(rule("crane/max_fends", 12.0)):
			_finish(&"fatigue", false)
			return
		if _time >= _next_at - rule("crane/warn", 0.6):
			_start_fend(_next_at)
		return
	var impact := float(_fend["impact"])
	if not bool(_fend["struck"]):
		if not bool(_fend["swung"]) and _time >= impact - 0.14:
			_fend["swung"] = true
			_play_willem(anim_list("anims/willem_fend"), true)
		if _time < impact:
			return
		_fend["struck"] = true
		_clear_telegraph()
		_strike_fend()
		return
	# Parade parfaite : on attend l'attaque qui suit.
	if bool(_fend["perfect"]):
		for at: float in _attacks:
			if at >= impact - 0.05 and at <= float(_fend["follow_until"]):
				_crane()
				return
		if _time <= float(_fend["follow_until"]):
			return
		_end_fend(&"parried")


## Le fend annoncé : Willem s'avance à sa distance, lève Percival ; un cercle sous Chtholly.
func _start_fend(impact: float) -> void:
	fends += 1
	var warn := maxf(impact - _time, 0.05)
	_fend = {
		"start": _time,
		"impact": impact,
		"warn": warn,
		"perfect": false,
		"swung": false,
		"struck": false,
		"follow_until": -1.0,
	}
	var toward := _flat(player.global_position - willem.position())
	var engage := rule("crane/engage_distance", 1.7)
	if toward.length() > engage + 0.2:
		var spot := player.global_position - toward.normalized() * engage
		if _walkable(willem.position(), spot):
			_start_hop(spot, warn * 0.6)
	_play_willem(anim_list("anims/willem_guard"), true)


func _strike_fend() -> void:
	var impact := float(_fend["impact"])
	var window := rule("crane/window", 0.2)
	var charging := player.combat.current_state() == &"charge"
	if _last_press >= impact - window and _last_press <= impact + 0.001:
		_fend["perfect"] = true
		_fend["follow_until"] = impact + rule("crane/follow", 0.7)
		_burst(player.global_position + Vector3.UP * BLADE_HEIGHT, "glint", CombatFx.COLOR_WAVE)
		return
	if charging:
		_end_fend(&"parried")
		return
	var distance := _flat(player.global_position - willem.position()).length()
	if distance <= rule("crane/reach", 2.0):
		_end_fend(&"hit")
	else:
		_end_fend(&"dodged")


func _end_fend(outcome: StringName) -> void:
	match outcome:
		&"parried":
			parried += 1
			_burst(
				player.global_position + Vector3.UP * BLADE_HEIGHT, "glint", CombatFx.COLOR_SWORD
			)
			willem.say(line("crane_parried", "Trop tôt. Au dernier instant."), 1.4)
		&"hit":
			hits += 1
			_recoil()
			willem.say(line("crane_hit", "Pare. Puis rends."), 1.4)
	_fend = {}
	_next_at = _time + rule("crane/interval", 2.2)
	resolved.emit(&"fend", outcome)
	_play_willem(anim_list("anims/willem_rest"), false)


## La Grue : Chtholly pivote, détourne le coup et le renvoie ; Willem recule. La dernière arrache
## Seniorious.
func _crane() -> void:
	grues += 1
	_fend = {}
	_next_at = _time + rule("crane/interval", 2.2)
	var pivot := anim_list("anims/player_pivot")
	if not pivot.is_empty():
		player.hold_pose(pivot[0], rule("crane/pivot_time", 0.3))
	var away := _flat(willem.position() - player.global_position)
	away = away.normalized() if away.length() > 0.05 else Vector3.FORWARD
	var back := willem.position() + away * rule("crane/push", 0.6)
	if _walkable(willem.position(), back):
		_start_hop(back, 0.2)
	_burst(willem.position() + Vector3.UP * BLADE_HEIGHT, "impact", CombatFx.COLOR_SWORD_FINAL)
	_shake(0.05)
	resolved.emit(&"fend", &"crane")
	if grues >= int(rule("crane/needed", 3.0)):
		_throw_sword()
	else:
		willem.say(line("crane_done", "C'est ça."), 1.2)


# --- L'épée arrachée -----------------------------------------------------------------------------


func _throw_sword() -> void:
	_set_stage(&"pickup")
	_clear_telegraph()
	var target := Vector3.INF
	var place := StringName(
		str(GameRules.value(GAME_RULES, "pickup/place", "marais_epee", overrides))
	)
	var places := LifeDirector.places()
	if places != null and places.has(place):
		target = places.center(place)
	else:
		var offset: Variant = GameRules.value(
			GAME_RULES, "pickup/offset", [-4.0, 0.0, 2.0], overrides
		)
		var shift := Vector3(-4.0, 0.0, 2.0)
		if offset is Array and (offset as Array).size() >= 3:
			shift = Vector3(float(offset[0]), float(offset[1]), float(offset[2]))
		target = player.global_position + shift
	var from := player.global_position + Vector3.UP * BLADE_HEIGHT
	_sword = {
		"from": from,
		"to": target,
		"start": _time,
		"duration": rule("pickup/fly_time", 1.1),
		"height": rule("pickup/fly_height", 3.0),
		"landed": false,
	}
	_sword_sprite = CombatFx.make_sprite("glint", 1.6)
	_sword_sprite.name = "Seniorious"
	_sword_sprite.no_depth_test = true
	_sword_sprite.modulate = Color(0.78, 0.92, 1.0)
	add_child(_sword_sprite)
	_sword_sprite.global_position = from
	_sword_sprite.play(&"default")
	resolved.emit(&"sword", &"flew")
	willem.say(line("sword_flew", "… Elle t'a échappé. Va la chercher."), 2.2)


func _tick_sword() -> void:
	if _sword.is_empty() or _sword_sprite == null or not is_instance_valid(_sword_sprite):
		return
	if bool(_sword["landed"]):
		# Elle luit dans l'eau basse : l'éclat se rejoue.
		if not _sword_sprite.is_playing():
			_sword_sprite.play(&"default")
		return
	var ratio := clampf((_time - float(_sword["start"])) / float(_sword["duration"]), 0.0, 1.0)
	var from: Vector3 = _sword["from"]
	var to: Vector3 = _sword["to"]
	var at := from.lerp(to + Vector3.UP * 0.2, ratio)
	at.y += 4.0 * float(_sword["height"]) * ratio * (1.0 - ratio)
	_sword_sprite.global_position = at
	if ratio < 1.0:
		return
	_sword["landed"] = true
	_burst(to + Vector3.UP * 0.1, "dust", Color(0.7, 0.8, 0.85))
	_burst(to + Vector3.UP * 0.3, "impact", CombatFx.COLOR_WAVE)
	resolved.emit(&"sword", &"landed")
	if with_pickup:
		_make_pickup(to)
	else:
		_finish(&"grues", true)


func _make_pickup(at: Vector3) -> void:
	var area := SwordPickup.new()
	area.name = "SwordPickup"
	area.training = self
	area.prompt = line("pickup_prompt", "Ramasser Seniorious")
	area.collision_layer = INTERACTABLE_LAYER
	area.collision_mask = 0
	area.monitoring = false
	area.add_to_group(INTERACTABLE_GROUP)
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = rule("pickup/reach", 1.2)
	shape.shape = sphere
	area.add_child(shape)
	add_child(area)
	area.global_position = at + Vector3.UP * 0.5
	_pickup = area


## Chtholly ramasse Seniorious (l'invite du marais) : l'exercice est réussi.
func pick_up() -> void:
	if stage != &"pickup" or not bool(_sword.get("landed", false)) or picked_up:
		return
	picked_up = true
	resolved.emit(&"sword", &"picked")
	_finish(&"grues", true)


func _free_sword() -> void:
	if _sword_sprite != null and is_instance_valid(_sword_sprite):
		_sword_sprite.queue_free()
	_sword_sprite = null
	if _pickup != null and is_instance_valid(_pickup):
		_pickup.remove_from_group(INTERACTABLE_GROUP)
		_pickup.queue_free()
	_pickup = null


# --- Fin -----------------------------------------------------------------------------------------


func _finish(reason: StringName, success: bool) -> void:
	if not is_running():
		return
	_clear_telegraph()
	var reached := _stage_index + 1 if stage != &"pickup" else 4
	_result = {
		"success": success,
		"ended_by": reason,
		"stage_reached": mini(reached, 4),
		"start_stage": start_stage,
		"breaths": breaths.duplicate(),
		"moves": moves.duplicate(),
		"grues": grues,
		"fends": fends,
		"parried": parried,
		"hits": hits,
		"picked_up": picked_up,
		"duration": elapsed,
	}
	_gesture = {}
	_fend = {}
	_set_stage(&"ended")
	_end_left = rule("end_time", 1.6)
	_free_hud()
	if _pickup != null and is_instance_valid(_pickup):
		_pickup.remove_from_group(INTERACTABLE_GROUP)
	if reason == &"fatigue":
		var tired := anim_list("anims/player_tired")
		if not tired.is_empty():
			player.hold_pose(tired[0], _end_left + 0.5, tired.slice(1))
		willem.say(line("tired", "Assez pour aujourd'hui. Souffle."), 2.0)
	elif success:
		_play_willem(anim_list("anims/willem_rest"), true)


func _close() -> void:
	if _done:
		return
	_done = true
	_restore(true)
	finished.emit(_result)
	if is_inside_tree():
		queue_free()


# --- Joueur --------------------------------------------------------------------------------------


func _connect_player() -> void:
	var combat := player.combat
	if not combat.attack_started.is_connected(_on_attack_started):
		combat.attack_started.connect(_on_attack_started)


func _disconnect_player() -> void:
	if player == null or not is_instance_valid(player):
		return
	var combat := player.combat
	if combat.attack_started.is_connected(_on_attack_started):
		combat.attack_started.disconnect(_on_attack_started)


func _on_attack_started(_attack_data: AttackData) -> void:
	if is_running():
		_attacks.append(_time)
		if _attacks.size() > 16:
			_attacks.pop_front()


## La touche de charge, pressée (le venenum s'allume) puis relâchée.
func _watch_charge() -> void:
	var charging := player.combat.current_state() == &"charge"
	if charging and not _was_charging:
		_last_press = _time
	elif not charging and _was_charging:
		_last_release = _time
	_was_charging = charging


## Un fend reçu, sans mal : Chtholly recule à peine.
func _recoil() -> void:
	var away := _flat(player.global_position - willem.position())
	away = away.normalized() if away.length() > 0.01 else Vector3.BACK
	player.move_and_collide(away * rule("crane/recoil", 0.4))
	_burst(player.global_position + Vector3.UP * 0.9, "impact", CombatFx.COLOR_BITE)
	_shake(0.04)


# --- Willem --------------------------------------------------------------------------------------


func _start_hop(to: Vector3, duration: float) -> void:
	var from := willem.position()
	_hop = {
		"from": from,
		"to": Vector3(to.x, _ground(to, from.y), to.z),
		"start": _time,
		"duration": maxf(duration, 0.01),
	}
	_play_willem(anim_list("anims/willem_step"), true)


func _tick_hop() -> void:
	if _hop.is_empty() or willem == null:
		return
	var ratio := clampf((_time - float(_hop["start"])) / float(_hop["duration"]), 0.0, 1.0)
	var from: Vector3 = _hop["from"]
	var to: Vector3 = _hop["to"]
	willem.set_position(from.lerp(to, ratio))
	if ratio >= 1.0:
		_hop = {}
		if is_running():
			var anims := (
				anim_list("anims/willem_guard")
				if not _fend.is_empty()
				else anim_list("anims/willem_rest")
			)
			_play_willem(anims, false)


func _face_willem() -> void:
	if willem != null and is_instance_valid(player) and _hop.is_empty():
		willem.face(player.global_position - willem.position())


func _play_willem(anims: Array[StringName], restart: bool) -> void:
	if willem == null or not is_instance_valid(willem.npc):
		return
	for anim: StringName in anims:
		if willem.npc.visual.has_animation(anim):
			willem.play(anim, restart)
			return


func _walkable(from: Vector3, to: Vector3) -> bool:
	var nav := LifeDirector.nav()
	if nav == null or not nav.ready:
		return true
	return nav.is_walkable_point(to.x, to.z) and nav.line_clear(from, to)


func _ground(at: Vector3, fallback: float) -> float:
	var nav := LifeDirector.nav()
	if nav == null or not nav.ready:
		return fallback
	return nav.height_at(at.x, at.z)


# --- Affichage -----------------------------------------------------------------------------------


func _update_telegraph() -> void:
	if _telegraph == null:
		return
	if _fend.is_empty() or bool(_fend["struck"]):
		return
	var ratio := clampf(
		(_time - float(_fend["start"])) / maxf(float(_fend["warn"]), 0.05), 0.0, 1.0
	)
	var at := player.global_position
	_telegraph.strike(
		Vector3(at.x, _ground(at, at.y), at.z), 0.6, willem.position() + Vector3.UP * 1.9
	)
	_telegraph.set_progress(ratio)


func _clear_telegraph() -> void:
	if _telegraph != null:
		_telegraph.clear()


func _burst(at: Vector3, fx_name: String, color: Color) -> void:
	if is_inside_tree():
		CombatFx.spawn_burst(self, fx_name, at, color)


func _shake(amount: float) -> void:
	if is_instance_valid(player) and player.combat.screen_shake() != null:
		player.combat.screen_shake().kick(amount, Vector3.FORWARD)


## La ligne du HUD : la jauge de souffle, l'annonce, le compte des Grues, l'invite.
func hud_text() -> String:
	match stage:
		&"breath":
			if _time < _cycle_start:
				return line("hud_breath", "Souffle")
			var now := breath_phase()
			var filled := roundi(float(now[1]) * 8.0)
			var gauge := "▮".repeat(filled) + "▯".repeat(8 - filled)
			var label := line("hud_in", "Inspire") if now[0] == &"in" else line("hud_out", "Expire")
			return (
				"%s %s  ·  %d/%d"
				% [label, gauge, int(breaths[&"cycles"]) + 1, int(rule("breath/cycles", 5.0))]
			)
		&"moves":
			var shown := (
				"« %s »" % line("gesture_%s" % _gesture["gesture"], "")
				if not _gesture.is_empty()
				else ""
			)
			return (
				"%s %d/%d  %s"
				% [
					line("hud_moves", "Mouvements"),
					int(moves[&"done"]),
					int(rule("moves/count", 9.0)),
					shown,
				]
			)
		&"crane":
			return (
				"%s %d/%d"
				% [line("hud_crane", "Grue de Gossamer"), grues, int(rule("crane/needed", 3.0))]
			)
		&"pickup":
			return line("pickup_prompt", "Ramasser Seniorious")
	return line("hud_title", "Entraînement avec Seniorious")


func _update_hud() -> void:
	if _hud != null and is_instance_valid(_hud):
		_hud.call(&"set_text", hud_text())


func _free_hud() -> void:
	if _hud != null and is_instance_valid(_hud):
		_hud.queue_free()
	_hud = null


static func _flat(vector: Vector3) -> Vector3:
	return Vector3(vector.x, 0.0, vector.z)
