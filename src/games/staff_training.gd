class_name StaffTraining
extends Node3D
## (E8) L'entraînement au bâton (docs/lore/ACTE1.md, 3.2 ; scènes 9.2 et 10.1) : dans la clairière,
## Willem frappe en rythme ; Chtholly (le joueur) bloque, dévie ou esquive ; puis Ithea et Nephren
## se joignent à elle, trois contre un. Les coups sont des bâtons : aucun vrai dégât, jamais de
## Health touchée ; une jauge de touches compte les coups reçus. Propriétaire : E8. Chiffres :
## data/games/staff_training.json.
##
## - Phase A (« des attaques venues de partout ») : un coup toutes les 1,2 s (puis 0,8 s), de quatre
##   côtés, annoncé 0,5 s avant par la posture de Willem et un cercle au sol. Trois réponses :
##   bloquer (la parade est tenue à l'impact), dévier (la parade est relâchée dans les 0,15 s avant
##   l'impact : la garde de Willem s'ouvre), esquiver (le joueur est sorti du cercle). Une réponse
##   juste garde le rythme (l'enchaînement monte), un coup reçu le casse (retour à zéro). La
##   fenêtre de déviation rétrécit d'un cinquième toutes les 30 s ; à 90 s Chtholly s'assoit.
##   Réussite : 12 réponses de suite, dont 3 déviations.
## - Phase B (« trois contre un ») : les deux aînées attaquent Willem ; il pare tout et contre
##   les 2 s sur l'une des trois, annoncé 0,4 s avant. Sur Chtholly : esquiver ou dévier (la parade
##   tenue ne suffit pas). Une déviation découvre Willem 0,4 s. Réussite : tenir 60 s avec trois
##   contres reçus au plus, ou toucher Willem découvert d'un coup de bâton.
## - La parade est la touche de charge (clic droit), qui n'a plus de charge de venenum bâton en main
##   (PlayerCombat.set_weapon) ; le coup de bâton est la touche d'attaque.
## - Variante du jour 10 : phase A seule, la fenêtre de déviation se ferme au bout de 15 s (signal
##   window_closed), l'exercice s'arrête au troisième raté.
##
## Fin : finished(résultat) ; la scène continue toujours (pas d'écran de défaite). Résultat :
## {success, ended_by (&"success", &"fatigue", &"touches", &"misses", &"stopped"), phase_reached,
## phase_a {success, best_streak, deflections, hits, blocked, dodged}, phase_b {success, counters,
## touched_willem, survived}, touches, duration, variant}.
## Tout se fait au pas de advance(delta) : le nœud s'avance seul à chaque image physique, les tests
## le coupent (set_physics_process(false)) et l'avancent à la main.

## La phase a changé : &"intro", &"a", &"link", &"b", &"ended".
signal phase_changed(phase: StringName)
## Un coup de Willem est résolu : sorte (&"blow", &"counter"), issue (&"blocked", &"deflected",
## &"dodged", &"hit").
signal resolved(kind: StringName, outcome: StringName)
## La jauge de touches a changé.
signal touches_changed(touches: int, limit: int)
## La fenêtre de déviation se ferme (variante du jour 10) : le rythme tremble.
signal window_closed
## L'exercice est fini (résultat : voir plus haut).
signal finished(result: Dictionary)

const GAME_RULES := &"staff_training"
const TelegraphScript := preload("res://src/enemies/telegraph.gd")
const SCORE_SCRIPT := preload("res://src/games/game_score.gd")
const SIDE_GLYPHS := {&"gauche": "◀", &"droite": "▶", &"haut": "▲", &"estoc": "●"}
## Direction du coup au sol selon le côté (lacet, radians) : le trait de bâton y est dessiné.
const SIDE_YAW := {&"gauche": 1.5708, &"droite": -1.5708, &"haut": 0.0, &"estoc": 3.1416}
const SLASH_SIZE := Vector2(2.5, 1.25)
const SLASH_LIFE := 0.28

var player: Player = null
var willem: LifeActor = null
var allies: Array[LifeActor] = []
## Surcharges des règles (chemins du fichier), pour les tests.
var overrides: Dictionary = {}
var phase: StringName = &"idle"
var variant: StringName = &"default"
## Jauge de touches de la phase courante et sa limite.
var touches: int = 0
var touch_limit: int = 6
## Enchaînement de réponses justes, et déviations qu'il contient.
var streak: int = 0
var streak_deflections: int = 0
var best_streak: int = 0
## Contres reçus (phase B).
var counters: int = 0
var misses: int = 0
var counts: Dictionary = {&"blocked": 0, &"deflected": 0, &"dodged": 0, &"hit": 0}
## Willem est découvert jusqu'à ce temps (temps du jeu).
var open_until: float = -1.0
var touched_willem: bool = false
var window_is_closed: bool = false
var elapsed: float = 0.0
## Le HUD sobre (jauge) est posé.
var show_hud: bool = true

var _time: float = 0.0
var _phase_start: float = 0.0
var _result: Dictionary = {}
var _blow: Dictionary = {}
var _next_impact: float = 0.0
var _fatigue_level: int = 0
var _guard_up_since: float = -1.0
var _last_release: float = -100.0
var _last_hold: float = 0.0
var _pending_strike: float = -1.0
var _ally_next: Array[float] = []
var _counter_next: float = 0.0
var _previous_weapon: StringName = &""
var _restore_weapon: bool = true
var _telegraph: TelegraphScript = null
var _glyph: Label3D = null
var _hud: CanvasLayer = null
var _end_left: float = -1.0
var _reposition_left: float = 0.0
var _saved: Dictionary = {}
var _hush: Hush = null
var _rng := RandomNumberGenerator.new()
var _phase_a: Dictionary = {}
var _phase_b: Dictionary = {}
var _sequence: Array[StringName] = [&"a", &"b"]
var _sequence_index: int = 0


## Le jeu muet qui tient les PNJ de l'exercice : leur parler pendant l'entraînement ne fait rien.
class Hush:
	extends LifeGame

	var active: bool = true

	func on_player_interact(_actor: LifeActor) -> bool:
		return active

	func blocks_talk() -> bool:
		return active


func _init() -> void:
	name = "StaffTraining"
	_rng.seed = Time.get_ticks_usec()


## Fixe le tirage (tests, démonstrations) : la même graine rejoue le même exercice.
func seed_random(value: int) -> void:
	_rng.seed = value


func _physics_process(delta: float) -> void:
	advance(delta)


func _exit_tree() -> void:
	# La carte est quittée en plein exercice : le bâton est rendu comme à la fin.
	if is_running() and _restore_weapon and not _previous_weapon.is_empty():
		if is_instance_valid(player):
			player.set_weapon(_previous_weapon)
	_disconnect_player()
	_free_hud()


# --- Règles --------------------------------------------------------------------------------------


## Un chiffre des règles (chemin « phase_a/warn »).
func rule(key_path: String, default: float) -> float:
	return GameRules.number(GAME_RULES, key_path, default, overrides)


## Une liste d'animations des règles (« anims/strike »).
func anim_list(key_path: String) -> Array[StringName]:
	var found: Variant = GameRules.value(GAME_RULES, key_path, [], overrides)
	var list: Array[StringName] = []
	if found is Array:
		for entry: Variant in found:
			list.append(StringName(str(entry)))
	return list


## Texte du jeu (data/texts/life.json, games/baton/<clé>).
func line(key: String, fallback: String = "") -> String:
	return LifeTexts.text("games/baton/%s" % key, fallback, _rng)


# --- Mise en place et fin ------------------------------------------------------------------------


## Prépare l'exercice : le joueur, Willem, les aînées (le dossier des participants), et la variante
## (&"default" ou &"jour10"). Ne démarre rien : voir start().
func setup(
	the_player: Player,
	the_willem: LifeActor,
	the_allies: Array[LifeActor],
	the_variant: StringName = &"default"
) -> void:
	player = the_player
	willem = the_willem
	allies = the_allies
	variant = the_variant
	_sequence = [&"a", &"b"]
	if variant == &"jour10":
		_sequence = []
		for entry: Variant in GameRules.value(
			GAME_RULES, "variant_jour10/phases", ["a"], overrides
		):
			_sequence.append(StringName(str(entry)))
	touch_limit = int(rule("phase_a/touch_limit", 6.0))
	_phase_a = {}
	_phase_b = {}


## Commence : le bâton en main (Seniorious revient à la fin), Willem se tourne vers le joueur.
func start(restore_weapon: bool = true) -> void:
	if phase != &"idle" or player == null or willem == null:
		return
	_restore_weapon = restore_weapon
	_previous_weapon = player.weapon()
	player.set_weapon(PlayerCombat.WEAPON_STICK)
	_connect_player()
	for actor: LifeActor in _participants():
		_take_control(actor)
	_telegraph = TelegraphScript.new() as TelegraphScript
	_telegraph.name = "Telegraph"
	add_child(_telegraph)
	_glyph = Label3D.new()
	_glyph.name = "Glyph"
	_glyph.font_size = 64
	_glyph.pixel_size = 0.012
	_glyph.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_glyph.no_depth_test = true
	_glyph.modulate = Color(1.0, 0.86, 0.5)
	_glyph.outline_size = 16
	_glyph.visible = false
	add_child(_glyph)
	if show_hud:
		_hud = SCORE_SCRIPT.new() as CanvasLayer
		add_child(_hud)
	_set_phase(&"intro")
	willem.face(player.global_position - willem.position())
	willem.say(line("start", "Allez, Chtholly. Prends ton bâton."))


## Arrête l'exercice (la scène l'interrompt) : résultat « stopped ».
func stop() -> void:
	if phase == &"idle" or phase == &"ended":
		return
	_finish(&"stopped", false)


## Vrai tant que l'exercice court.
func is_running() -> bool:
	return phase != &"idle" and phase != &"ended"


## Résultat (vide tant que l'exercice n'est pas fini).
func result() -> Dictionary:
	return _result


## Le coup annoncé (vide entre deux coups) : kind (&"blow", &"counter"), target (où il tombe),
## start (début de l'annonce), impact (instant de l'impact, en temps du jeu), side.
func current_blow() -> Dictionary:
	return _blow


## Temps du jeu de l'exercice (s) : celui de start, avancé par advance().
func game_time() -> float:
	return _time


func _participants() -> Array[LifeActor]:
	var list: Array[LifeActor] = [willem]
	list.append_array(allies)
	return list


## Le PNJ passe sous la conduite de l'exercice : ni salutation ni pas de côté, rien de l'emploi du
## temps ; il est rendu à sa vie à la fin (release_all).
func _take_control(actor: LifeActor) -> void:
	_saved[actor.id] = {"state": actor.state, "activity": actor.activity, "line": actor.line}
	actor.stop()
	actor.activity = {
		"poses": [{"anim": "repos"}], "look": false, "greet": false, "step_aside": false
	}
	actor.state = LifeActor.State.GAME
	if _hush == null:
		_hush = Hush.new()
	actor.game = _hush
	actor.play(&"repos")


func _release_all() -> void:
	for actor: LifeActor in _participants():
		var saved: Dictionary = _saved.get(actor.id, {})
		if saved.is_empty() or actor.state == LifeActor.State.GONE:
			continue
		actor.stop()
		actor.game = null
		actor.activity = saved["activity"]
		actor.state = saved["state"]
		var scheduled: Dictionary = saved["line"]
		if scheduled.has("map") and LifeDirector.current_map() != null:
			actor.place_now(scheduled)
		else:
			actor.play(&"repos")
	_saved.clear()


func _set_phase(next: StringName) -> void:
	phase = next
	_phase_start = _time
	phase_changed.emit(next)


# --- Image par image -----------------------------------------------------------------------------


## Avance l'exercice de delta s.
func advance(delta: float) -> void:
	if phase == &"idle":
		return
	_time += delta
	if phase == &"ended":
		_end_left -= delta
		if _end_left <= 0.0 and _end_left > -1.0:
			_end_left = -2.0
			_release_all()
			_cleanup()
		return
	elapsed += delta
	_tick_actors(delta)
	match phase:
		&"intro":
			if _time - _phase_start >= rule("intro_time", 1.5):
				_next_phase()
		&"a":
			_advance_a()
		&"link":
			var waited := _time - _phase_start
			var arrived := true
			for ally: LifeActor in allies:
				arrived = arrived and not ally.is_moving()
			if (
				(waited >= rule("link_time", 1.5) and arrived)
				or waited >= rule("link_timeout", 10.0)
			):
				_next_phase()
		&"b":
			_advance_b()
	_update_telegraph()
	_update_hud()


func _next_phase() -> void:
	if _sequence_index >= _sequence.size():
		_finish(&"success", true)
		return
	var next := _sequence[_sequence_index]
	_sequence_index += 1
	if next == &"a":
		_enter_a()
	else:
		_enter_b()


# --- Phase A -------------------------------------------------------------------------------------


func _enter_a() -> void:
	_set_phase(&"a")
	touches = 0
	touch_limit = int(rule("phase_a/touch_limit", 6.0))
	streak = 0
	streak_deflections = 0
	_fatigue_level = 0
	_blow = {}
	counts = {&"blocked": 0, &"deflected": 0, &"dodged": 0, &"hit": 0}
	misses = 0
	_next_impact = _time + rule("phase_a/first_delay", 0.6) + rule("phase_a/warn", 0.5)
	touches_changed.emit(touches, touch_limit)


func _advance_a() -> void:
	var local := _time - _phase_start
	var level := int(local / maxf(rule("phase_a/fatigue_every", 30.0), 1.0))
	if level != _fatigue_level:
		_fatigue_level = level
		willem.say(line("tired", "Tes genoux tremblent. Tiens bon."))
	if local >= rule("phase_a/sit_at", 90.0):
		_phase_a = _summary_a(false)
		_finish(&"fatigue", false)
		return
	if (
		variant == &"jour10"
		and not window_is_closed
		and local >= rule("variant_jour10/deflect_closes_at", 15.0)
	):
		window_is_closed = true
		window_closed.emit()
		_shake(0.06)
	if _blow.is_empty():
		if _time >= _next_impact - rule("phase_a/warn", 0.5):
			_start_blow(&"blow", player.global_position, _next_impact, rule("phase_a/warn", 0.5))
	elif _time >= float(_blow["impact"]):
		_resolve_blow()
		if not is_running() or phase != &"a":
			return
		_next_impact = _time + _tempo(local)
	if (
		streak >= int(rule("phase_a/success_streak", 12.0))
		and (streak_deflections >= int(rule("phase_a/success_deflections", 3.0)))
	):
		_phase_a = _summary_a(true)
		willem.say(line("success_a", "Voilà. Tu y es."))
		_sequence_done_or_link()


## Le temps entre deux coups à l'instant local t de la phase A : de tempo_start à tempo_end.
func _tempo(local: float) -> float:
	var ratio := clampf(local / maxf(rule("phase_a/ramp_time", 60.0), 1.0), 0.0, 1.0)
	return lerpf(rule("phase_a/tempo_start", 1.2), rule("phase_a/tempo_end", 0.8), ratio)


## Fenêtre de déviation (s) : un cinquième de moins par palier de fatigue ; fermée le jour 10.
func deflect_window() -> float:
	if window_is_closed:
		return 0.0
	var shrink := rule("phase_a/fatigue_shrink", 0.2) * _fatigue_level if phase == &"a" else 0.0
	return maxf(
		rule("phase_a/deflect_window", 0.15) * (1.0 - shrink),
		rule("phase_a/deflect_min_window", 0.04)
	)


func _summary_a(success: bool) -> Dictionary:
	return {
		"success": success,
		"best_streak": best_streak,
		"deflections": int(counts[&"deflected"]),
		"hits": int(counts[&"hit"]),
		"blocked": int(counts[&"blocked"]),
		"dodged": int(counts[&"dodged"]),
	}


## Fin de la phase A réussie : la suite (phase B) ou la fin.
func _sequence_done_or_link() -> void:
	_blow = {}
	_clear_telegraph()
	if _sequence_index >= _sequence.size():
		_finish(&"success", true)
		return
	_set_phase(&"link")
	_start_link()


# --- Phase B -------------------------------------------------------------------------------------


## Les aînées se lèvent et vont à leur place, de part et d'autre de Willem, du côté du joueur.
func _start_link() -> void:
	var slots := ally_slots()
	for i: int in allies.size():
		var actor := allies[i]
		actor.stop()
		var at: Vector3 = slots[mini(i, slots.size() - 1)]
		actor.walk_to(at, willem.position() - at, &"course", Callable(), true)


## Places des aînées autour de Willem (du côté du joueur, à ± ring_angle_deg).
func ally_slots() -> Array[Vector3]:
	var slots: Array[Vector3] = []
	var toward := player.global_position - willem.position()
	toward.y = 0.0
	toward = toward.normalized() if toward.length_squared() > 0.01 else Vector3.BACK
	var angle := deg_to_rad(rule("ring_angle_deg", 55.0))
	var radius := rule("ring_radius", 2.0)
	for sign_value: float in [-1.0, 1.0]:
		var at := willem.position() + toward.rotated(Vector3.UP, angle * sign_value) * radius
		at.y = willem.position().y
		slots.append(at)
	return slots


func _enter_b() -> void:
	var from_link := phase == &"link"
	_set_phase(&"b")
	if not from_link:
		_start_link()
	touches = 0
	counters = 0
	touch_limit = int(rule("phase_b/max_counters", 3.0)) + 1
	_blow = {}
	_ally_next.clear()
	for _i: int in allies.size():
		_ally_next.append(_time + _rng.randf_range(0.8, rule("phase_b/ally_interval_max", 3.0)))
	_counter_next = _time + rule("phase_b/counter_first_delay", 1.5)
	counts = {&"blocked": 0, &"deflected": 0, &"dodged": 0, &"hit": 0}
	touches_changed.emit(touches, touch_limit)
	for ally: LifeActor in allies:
		ally.face(willem.position() - ally.position())
	willem.say(line("start_b", "Trois contre un. Voyons ça."))


func _advance_b() -> void:
	var local := _time - _phase_start
	if touched_willem:
		return
	for i: int in allies.size():
		if _time >= _ally_next[i] and not allies[i].is_moving():
			_ally_attacks(allies[i])
			_ally_next[i] = (
				_time
				+ _rng.randf_range(
					rule("phase_b/ally_interval_min", 2.0), rule("phase_b/ally_interval_max", 3.0)
				)
			)
	if _pending_strike >= 0.0 and _time >= _pending_strike:
		_pending_strike = -1.0
		_player_strikes()
		if touched_willem:
			return
	if _blow.is_empty():
		if _time >= _counter_next:
			_start_counter()
	elif _time >= float(_blow["impact"]):
		_resolve_blow()
		if phase != &"b":
			return
		_counter_next = _time + rule("phase_b/counter_interval", 2.0)
	if local >= rule("phase_b/success_time", 60.0):
		_phase_b = {
			"success": true, "counters": counters, "touched_willem": false, "survived": true
		}
		willem.say(line("success_b", "Soixante secondes. Pas mal."))
		_finish(&"success", true)


## Une aînée attaque Willem, qui pare : un trait de bâton, un éclat.
func _ally_attacks(ally: LifeActor) -> void:
	ally.face(willem.position() - ally.position())
	_play_first(ally, anim_list("anims/strike"), true)
	_play_first(willem, anim_list("anims/guard"), true)
	_flash_between(ally.position(), willem.position())


## Willem contre l'une des trois, « comme un serpent » : l'une des deux alliées ou Chtholly.
func _start_counter() -> void:
	var pick := _rng.randi_range(0, allies.size())
	if pick >= allies.size():
		_start_blow(
			&"counter",
			player.global_position,
			_time + rule("phase_b/counter_warn", 0.4),
			rule("phase_b/counter_warn", 0.4)
		)
	else:
		var ally := allies[pick]
		_start_blow(
			&"counter",
			ally.position(),
			_time + rule("phase_b/counter_warn", 0.4),
			rule("phase_b/counter_warn", 0.4),
			ally
		)


## Le joueur frappe de son bâton : Willem découvert au moment du coup, à portée, dans l'arc ?
func _player_strikes() -> void:
	if phase != &"b" or player == null:
		return
	var offset := willem.position() - player.global_position
	offset.y = 0.0
	var aim := player.aim_direction()
	var arc := deg_to_rad(rule("phase_b/touch_arc_deg", 140.0)) * 0.5
	var near := offset.length() <= rule("phase_b/touch_reach", 1.7)
	var in_front := offset.length() < 0.3 or offset.normalized().angle_to(aim) <= arc
	if not (near and in_front):
		return
	if _time <= open_until:
		touched_willem = true
		_phase_b = {
			"success": true, "counters": counters, "touched_willem": true, "survived": false
		}
		_play_first(willem, anim_list("anims/rest"), true)
		willem.say(line("touched", "Touché ! Bien joué."))
		_burst(willem.position() + Vector3.UP * 1.0, "impact", CombatFx.COLOR_SWORD_FINAL)
		_finish(&"success", true)
	else:
		_play_first(willem, anim_list("anims/guard"), true)
		_burst(willem.position() + Vector3.UP * 1.0, "glint", Color.WHITE)


# --- Un coup ou une contre -----------------------------------------------------------------------


## Annonce un coup : sorte, cible (le sol où il tombe), instant de l'impact, durée de l'annonce ;
## ally : l'aînée visée par une contre (null : le joueur).
func _start_blow(
	kind: StringName, at: Vector3, impact: float, warn: float, ally: LifeActor = null
) -> void:
	var sides: Array = GameRules.value(GAME_RULES, "phase_a/sides", ["gauche"], overrides)
	var side := StringName(str(sides[_rng.randi_range(0, sides.size() - 1)]))
	_blow = {
		"kind": kind,
		"target": Vector3(at.x, at.y, at.z),
		"start": _time,
		"impact": impact,
		"warn": warn,
		"side": side,
		"ally": ally,
	}
	willem.face(at - willem.position())
	_play_first(willem, anim_list("anims/strike"), true)
	if _glyph != null:
		_glyph.text = str(SIDE_GLYPHS.get(side, "●"))
		_glyph.visible = true


## L'instant de l'impact : l'issue, la jauge, l'enchaînement.
func _resolve_blow() -> void:
	var kind: StringName = _blow["kind"]
	var target: Vector3 = _blow["target"]
	var ally: LifeActor = _blow.get("ally")
	var side: StringName = _blow["side"]
	_blow = {}
	_clear_telegraph()
	var outcome := &"dodged"
	if ally != null:
		outcome = (
			&"deflected" if _rng.randf() < rule("phase_b/ally_deflect_chance", 0.5) else &"dodged"
		)
		_play_first(
			ally,
			anim_list("anims/guard") if outcome == &"deflected" else anim_list("anims/rest"),
			true
		)
	else:
		outcome = judge(target, kind == &"blow")
	_flash_blow(target, side, outcome)
	if outcome == &"deflected":
		open_until = (
			_time + rule("phase_a/open_time" if kind == &"blow" else "phase_b/open_time", 0.5)
		)
		if _rng.randf() < 0.2:
			willem.say(line("open", "Ah !"))
	if ally == null:
		_apply_outcome(kind, outcome)
	else:
		resolved.emit(kind, outcome)


## L'issue d'un coup qui tombe en target : esquivé (le joueur est sorti du cercle), dévié (parade
## relâchée dans la fenêtre), paré (parade tenue ; seulement aux coups de la phase A), sinon reçu.
func judge(target: Vector3, can_block: bool) -> StringName:
	var offset := player.global_position - target
	offset.y = 0.0
	if offset.length() >= rule("dodge_distance", 0.9):
		return &"dodged"
	var window := deflect_window()
	var released_in_window := (
		_last_release >= _time - window
		and _last_release <= _time
		and _last_hold >= rule("phase_a/deflect_min_hold", 0.05)
		and _guard_up_since < 0.0
	)
	if released_in_window and window > 0.0:
		return &"deflected"
	if can_block and player.combat.is_guarding():
		return &"blocked"
	return &"hit"


func _apply_outcome(kind: StringName, outcome: StringName) -> void:
	counts[outcome] = int(counts[outcome]) + 1
	match outcome:
		&"hit":
			touches += 1
			misses += 1
			streak = 0
			streak_deflections = 0
			if kind == &"counter":
				counters += 1
			_burst(player.global_position + Vector3.UP * 0.9, "impact", CombatFx.COLOR_BITE)
			touches_changed.emit(touches, touch_limit)
		&"deflected":
			streak += 1
			streak_deflections += 1
			_burst(player.global_position + Vector3.UP * 1.0, "glint", CombatFx.COLOR_SWORD_FINAL)
		_:
			streak += 1
	best_streak = maxi(best_streak, streak)
	resolved.emit(kind, outcome)
	if outcome != &"hit":
		return
	if phase == &"a":
		if variant == &"jour10" and misses >= int(rule("variant_jour10/end_on_misses", 3.0)):
			_phase_a = _summary_a(false)
			_finish(&"misses", false)
		elif touches >= touch_limit:
			_phase_a = _summary_a(false)
			_finish(&"touches", false)
	elif phase == &"b" and counters > int(rule("phase_b/max_counters", 3.0)):
		_phase_b = {
			"success": false, "counters": counters, "touched_willem": false, "survived": false
		}
		_finish(&"touches", false)


# --- Fin -----------------------------------------------------------------------------------------


func _finish(reason: StringName, success: bool) -> void:
	var reached := phase
	if reached == &"a" and _phase_a.is_empty():
		_phase_a = _summary_a(false)
	_blow = {}
	_clear_telegraph()
	_result = {
		"success": success,
		"ended_by": reason,
		"phase_reached": reached,
		"phase_a": _phase_a,
		"phase_b": _phase_b,
		"touches": touches,
		"duration": elapsed,
		"variant": variant,
	}
	if _hush != null:
		_hush.active = false
	if phase != &"ended":
		_set_phase(&"ended")
	_end_left = rule("end_time", 3.0)
	if not success and reason != &"stopped":
		# À bout de forces, Chtholly s'assoit dans l'herbe, essoufflée (ACTE1.md, 3.0).
		var tired := anim_list("anims/player_tired")
		player.hold_pose(
			tired[0] if not tired.is_empty() else &"degats",
			rule("player_tired_time", 2.5),
			tired.slice(1)
		)
		willem.say(line("fail", "Assez pour aujourd’hui. Reprends ton souffle."))
	if success and reason == &"success":
		_play_first(willem, anim_list("anims/rest"), true)
	for ally: LifeActor in allies:
		_play_first(ally, anim_list("anims/tired"), true)
	_free_hud()
	_disconnect_player()
	if _restore_weapon and not _previous_weapon.is_empty() and is_instance_valid(player):
		player.set_weapon(_previous_weapon)
	finished.emit(_result)


func _cleanup() -> void:
	if is_inside_tree():
		queue_free()


# --- Joueur : parade et coup de bâton ------------------------------------------------------------


func _connect_player() -> void:
	var combat := player.combat
	if not combat.guard_changed.is_connected(_on_guard_changed):
		combat.guard_changed.connect(_on_guard_changed)
	if not combat.attack_started.is_connected(_on_attack_started):
		combat.attack_started.connect(_on_attack_started)


func _disconnect_player() -> void:
	if player == null or not is_instance_valid(player):
		return
	var combat := player.combat
	if combat.guard_changed.is_connected(_on_guard_changed):
		combat.guard_changed.disconnect(_on_guard_changed)
	if combat.attack_started.is_connected(_on_attack_started):
		combat.attack_started.disconnect(_on_attack_started)


func _on_guard_changed(guarding: bool) -> void:
	if guarding:
		_guard_up_since = _time
	else:
		_last_hold = _time - _guard_up_since if _guard_up_since >= 0.0 else 0.0
		_last_release = _time
		_guard_up_since = -1.0


func _on_attack_started(_attack: AttackData) -> void:
	if phase == &"b":
		_pending_strike = _time + rule("phase_b/touch_delay", 0.12)


# --- Acteurs, signes, affichage ------------------------------------------------------------------


func _tick_actors(delta: float) -> void:
	_reposition_left -= delta
	if willem == null or _reposition_left > 0.0 or not _blow.is_empty():
		return
	_reposition_left = rule("reposition_period", 0.5)
	if phase != &"a" and phase != &"b" and phase != &"intro":
		return
	var toward := player.global_position - willem.position()
	toward.y = 0.0
	var distance := toward.length()
	var engage := rule("engage_distance", 1.9)
	if distance > engage * 1.5 and not willem.is_moving():
		var at := player.global_position - toward.normalized() * engage
		at.y = willem.position().y
		willem.walk_to(at, toward, &"marche", Callable(), true)
	elif not willem.is_moving():
		willem.face(toward)
		if not willem.is_holding():
			_play_first(willem, anim_list("anims/rest"), false)


## Joue la première animation de la liste que la planche de l'acteur a.
func _play_first(actor: LifeActor, anims: Array[StringName], restart: bool) -> void:
	if actor == null or not is_instance_valid(actor.npc):
		return
	for anim: StringName in anims:
		if actor.npc.visual.has_animation(anim):
			actor.play(anim, restart)
			return


func _update_telegraph() -> void:
	if _telegraph == null:
		return
	if _blow.is_empty():
		return
	var target: Vector3 = _blow["target"]
	var ratio := clampf(
		(_time - float(_blow["start"])) / maxf(float(_blow["warn"]), 0.05), 0.0, 1.0
	)
	var radius := rule("dodge_distance", 0.9)
	_telegraph.strike(Vector3(target.x, target.y, target.z), radius, target + Vector3.UP * 1.9)
	_telegraph.set_progress(ratio)
	if _glyph != null:
		_glyph.position = target + Vector3(0.0, 1.5, 0.0)


func _clear_telegraph() -> void:
	if _telegraph != null:
		_telegraph.clear()
	if _glyph != null:
		_glyph.visible = false


## Le trait de bâton d'un coup qui tombe, au sol, tourné selon son côté ; rouge s'il touche.
func _flash_blow(target: Vector3, side: StringName, outcome: StringName) -> void:
	var color := CombatFx.COLOR_BITE if outcome == &"hit" else CombatFx.COLOR_SWORD
	var decal := CombatFx.make_decal("slash", SLASH_SIZE, color, "BlowSlash")
	decal.material_override = CombatFx.ground_material_unique("slash", color, 1, true)
	add_child(decal)
	decal.global_position = Vector3(target.x, target.y + CombatFx.GROUND_LIFT, target.z)
	decal.rotation.y = float(SIDE_YAW.get(side, 0.0))
	var tween := decal.create_tween()
	tween.tween_property(decal.material_override, "albedo_color:a", 0.0, SLASH_LIFE)
	tween.tween_callback(decal.queue_free)


## Un trait entre deux points (l'aînée qui frappe Willem).
func _flash_between(from: Vector3, to: Vector3) -> void:
	var middle := (from + to) * 0.5
	var direction := to - from
	direction.y = 0.0
	if direction.length_squared() < 0.01:
		return
	var decal := CombatFx.make_decal("slash", SLASH_SIZE, CombatFx.COLOR_SWORD, "AllySlash")
	decal.material_override = CombatFx.ground_material_unique(
		"slash", CombatFx.COLOR_SWORD, 1, true
	)
	add_child(decal)
	decal.global_position = Vector3(middle.x, middle.y + CombatFx.GROUND_LIFT, middle.z)
	decal.rotation.y = atan2(-direction.x, -direction.z)
	var tween := decal.create_tween()
	tween.tween_property(decal.material_override, "albedo_color:a", 0.0, SLASH_LIFE)
	tween.tween_callback(decal.queue_free)


func _burst(at: Vector3, fx_name: String, color: Color) -> void:
	if is_inside_tree():
		CombatFx.spawn_burst(self, fx_name, at, color)


func _shake(amount: float) -> void:
	if is_instance_valid(player) and player.combat.screen_shake() != null:
		player.combat.screen_shake().kick(amount, Vector3.FORWARD)


## Texte de la jauge, sobre : « Enchaînement 7/12 · touches 1/6 ».
func hud_text() -> String:
	if phase == &"a":
		return (
			"%s %d/%d  ·  %s %d/%d"
			% [
				line("hud_streak", "Enchaînement"),
				streak,
				int(rule("phase_a/success_streak", 12.0)),
				line("hud_touches", "Touches"),
				touches,
				touch_limit,
			]
		)
	if phase == &"b":
		var left := maxi(ceili(rule("phase_b/success_time", 60.0) - (_time - _phase_start)), 0)
		return (
			"%s %d/%d  ·  %d:%02d"
			% [
				line("hud_counters", "Contres"),
				counters,
				int(rule("phase_b/max_counters", 3.0)),
				floori(left / 60.0),
				left % 60,
			]
		)
	return line("hud_title", "Entraînement au bâton")


func _update_hud() -> void:
	if _hud != null and is_instance_valid(_hud):
		_hud.call(&"set_text", hud_text())


func _free_hud() -> void:
	if _hud != null and is_instance_valid(_hud):
		_hud.queue_free()
	_hud = null
