class_name Ambush
extends Node3D
## (E8c) L'embuscade de Pannibal (docs/lore/ACTE1.md, 3.1 ; scène 1.2, le jour 1 sur le sentier) :
## Pannibal bondit de l'ombre avec son épée de bois, frappe trois fois, esquive ; Chtholly (le
## joueur) esquive le bond, pare ou esquive les taillades, riposte au bâton. L'épée est en bois et
## le bâton aussi : aucun vrai dégât, jamais de Health touchée ; une jauge compte les points de
## Pannibal. Propriétaire : E8. Chiffres : data/games/embuscade.json. Sur le modèle de
## StaffTraining (src/games/staff_training.gd).
##
## - Le bond : une lumière qui zigzague au-dessus de Pannibal et un cercle au sol, là où elle va
##   retomber, l'annoncent 0,8 s avant ; elle le lance de 4 m. On l'esquive en sortant du cercle (un
##   pas de côté) : la parade n'y suffit pas. À partir du jour 5, un bond sur trois est une feinte
##   (elle s'arrête au milieu).
## - Les taillades : trois coups rapides (0,35 s d'écart) après le bond ; parée = la parade (touche
##   de charge, bâton en main) tenue à l'impact ; esquivée = hors de portée. Une taillade reçue
##   compte un point pour Pannibal (Chtholly recule de 0,5 m) et finit la série.
## - La riposte : après une esquive, Pannibal reste découverte 0,8 s ; un coup de bâton qui la
##   trouve alors la touche. Couverte, elle esquive le coup d'un saut en arrière.
## - Réussite : cinq attaques esquivées ou parées de suite, ou la riposte : Pannibal tombe à plat
##   ventre, vexée, et rit. Échec : trois points pour Pannibal ; elle lève son épée et proclame sa
##   victoire. Le récit continue dans les deux cas (ACTE1.md, 3.0 : pas de « Défaite »).
## - Le jour 1 (help) : deux lignes d'aide, une seule fois : esquiver le bond, parer les taillades.
##
## Pendant le jeu : le joueur a la main (la scène la reprend à la fin), Pannibal est muette (un jeu
## Hush : ni invite « Parler » ni signe d'interaction), les signes sont cachés, la boîte de dialogue
## est en présentation « nuit » ; tout revient à la fin. Résultat (finished, après la pose de fin) :
## {success, ended_by (&"streak", &"riposte", &"points", &"time", &"fled", &"stopped"), points,
## touch_limit, best_streak, parried, dodged, hits, leaps, feints, touched, duration, day}.
## Tout se fait au pas de advance(delta) : le nœud s'avance seul à chaque image physique, les tests
## le coupent (set_physics_process(false)) et l'avancent à la main.

## La phase a changé : &"intro", &"leap", &"slash", &"rest", &"ended".
signal phase_changed(phase: StringName)
## Une attaque est résolue : sorte (&"leap", &"slash", &"riposte"), issue (&"parried", &"dodged",
## &"hit", &"feint" ; pour la riposte : &"touched", &"evaded").
signal resolved(kind: StringName, outcome: StringName)
## La jauge des points de Pannibal a changé.
signal touches_changed(points: int, limit: int)
## Une ligne d'aide paraît (&"dodge", &"guard").
signal help_shown(key: StringName)
## Le jeu est fini, la pose de fin jouée, tout rendu (résultat : voir plus haut).
signal finished(result: Dictionary)

const GAME_RULES := &"embuscade"
const TelegraphScript := preload("res://src/enemies/telegraph.gd")
const SCORE_SCRIPT := preload("res://src/games/game_score.gd")
## Raison qui cache les signes d'interaction pendant le jeu (InteractSign.suppress).
const SIGNS_REASON := &"embuscade"
const LIGHT_HEIGHT := 1.05
const LIGHT_ZIGZAG := Vector2(0.35, 0.12)
const SLASH_SIZE := Vector2(2.0, 1.0)
const SLASH_LIFE := 0.25

var player: Player = null
var pannibal: LifeActor = null
## Surcharges des règles (chemins du fichier), pour les tests.
var overrides: Dictionary = {}
## Le jour de l'acte (les feintes viennent à partir du jour 5).
var day: int = 1
## Les deux lignes d'aide (jour 1).
var help: bool = false
## Le HUD sobre (jauge) est posé.
var show_hud: bool = true
var phase: StringName = &"idle"
## Points de Pannibal (taillades et bonds reçus) et leur limite.
var points: int = 0
var touch_limit: int = 3
## Attaques esquivées ou parées de suite.
var streak: int = 0
var best_streak: int = 0
var counts: Dictionary = {&"parried": 0, &"dodged": 0, &"hit": 0}
var leaps: int = 0
var feints: int = 0
var touched: bool = false
## Pannibal est découverte jusqu'à ce temps (temps du jeu).
var open_until: float = -1.0
var elapsed: float = 0.0

var _time: float = 0.0
var _phase_start: float = 0.0
var _result: Dictionary = {}
var _attack: Dictionary = {}
var _slash_left: int = 0
var _next_at: float = 0.0
var _pending_strike: float = -1.0
var _end_left: float = -1.0
var _done: bool = false
var _hop: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _telegraph: TelegraphScript = null
var _light: Label3D = null
var _hud: CanvasLayer = null
var _hush: Hush = null
var _saved_actor: Dictionary = {}
var _previous_weapon: StringName = &""
var _restore_weapon: bool = true
var _was_held: bool = false
var _presentation: StringName = &""
var _ui_taken: bool = false
var _help_done: Dictionary = {}
var _help_left: float = 0.0
var _help_text: String = ""


## Le jeu muet qui tient Pannibal : lui parler pendant l'embuscade ne fait rien.
class Hush:
	extends LifeGame

	var active: bool = true

	func on_player_interact(_actor: LifeActor) -> bool:
		return active

	func blocks_talk() -> bool:
		return active


func _init() -> void:
	name = "Ambush"
	_rng.seed = Time.get_ticks_usec()


## Fixe le tirage (tests, démonstrations) : la même graine rejoue la même embuscade.
func seed_random(value: int) -> void:
	_rng.seed = value


func _physics_process(delta: float) -> void:
	advance(delta)


func _exit_tree() -> void:
	# La carte est quittée en plein jeu : l'arme, les signes et la présentation sont rendus.
	if not _done:
		_restore(false)


# --- Règles --------------------------------------------------------------------------------------


## Un chiffre des règles (chemin « leap/warn »).
func rule(key_path: String, default: float) -> float:
	return GameRules.number(GAME_RULES, key_path, default, overrides)


## Une liste d'animations des règles (« anims/slash »).
func anim_list(key_path: String) -> Array[StringName]:
	var found: Variant = GameRules.value(GAME_RULES, key_path, [], overrides)
	var list: Array[StringName] = []
	if found is Array:
		for entry: Variant in found:
			list.append(StringName(str(entry)))
	return list


## Texte du jeu (data/texts/life.json, games/embuscade/<clé> ; {player} accepté).
func line(key: String, fallback: String = "") -> String:
	return LifeTexts.text("games/embuscade/%s" % key, fallback, _rng)


# --- Mise en place et fin ------------------------------------------------------------------------


## Prépare le jeu : le joueur, Pannibal, le jour et les lignes d'aide. Ne démarre rien : start().
func setup(
	the_player: Player, the_pannibal: LifeActor, the_day: int = 1, with_help: bool = false
) -> void:
	player = the_player
	pannibal = the_pannibal
	day = the_day
	help = with_help
	touch_limit = int(rule("touch_limit", 3.0))


## Commence : le bâton en main (l'arme d'avant revient à la fin), la main au joueur, Pannibal
## muette, les signes cachés ; Pannibal recule d'un bond à la distance de son attaque.
func start(restore_weapon: bool = true) -> void:
	if phase != &"idle" or player == null or pannibal == null:
		return
	_restore_weapon = restore_weapon
	_previous_weapon = player.weapon()
	player.set_weapon(PlayerCombat.WEAPON_STICK)
	_was_held = player.is_story_held()
	player.set_story_hold(false)
	_take_ui()
	_connect_player()
	_take_control()
	_telegraph = TelegraphScript.new() as TelegraphScript
	_telegraph.name = "Telegraph"
	add_child(_telegraph)
	_light = Label3D.new()
	_light.name = "Light"
	_light.text = "●"
	_light.font_size = 40
	_light.pixel_size = 0.006
	_light.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_light.no_depth_test = true
	_light.modulate = Color(1.0, 0.93, 0.62)
	_light.outline_size = 10
	_light.outline_modulate = Color(1.0, 0.8, 0.35, 0.45)
	_light.visible = false
	add_child(_light)
	if show_hud:
		_hud = SCORE_SCRIPT.new() as CanvasLayer
		_hud.name = "AmbushScore"
		add_child(_hud)
	points = 0
	touches_changed.emit(points, touch_limit)
	_set_phase(&"intro")
	pannibal.face(player.global_position - pannibal.position())
	var back := _spot_away(rule("leap/distance", 4.0))
	_start_hop(
		back, rule("intro_time", 0.8), rule("leap/height", 0.9) * 0.6, anim_list("anims/hop")
	)


## Arrête le jeu (la scène l'interrompt) : résultat « stopped », tout est rendu tout de suite.
func stop() -> void:
	if not is_running():
		return
	_finish(&"stopped", false)
	_end_left = 0.0
	advance(0.0)


## Vrai tant que le jeu court (la pose de fin n'en fait plus partie).
func is_running() -> bool:
	return phase != &"idle" and phase != &"ended"


## Vrai quand tout est fini et rendu (finished émis).
func is_done() -> bool:
	return _done


## Résultat (vide tant que le jeu n'est pas fini).
func result() -> Dictionary:
	return _result


## L'attaque annoncée (vide entre deux) : kind (&"leap", &"slash"), start, impact, warn, target
## (où elle tombe), feint.
func current_attack() -> Dictionary:
	return _attack


## Temps du jeu (s) : celui de start, avancé par advance().
func game_time() -> float:
	return _time


## La ligne d'aide affichée ("" : aucune).
func help_text() -> String:
	return _help_text if _help_left > 0.0 else ""


func _set_phase(next: StringName) -> void:
	phase = next
	_phase_start = _time
	phase_changed.emit(next)


## Pannibal passe sous la conduite du jeu : muette (Hush), rien de son emploi du temps ; une
## présente d'une scène (SCENE) le reste.
func _take_control() -> void:
	_saved_actor = {"state": pannibal.state, "activity": pannibal.activity, "line": pannibal.line}
	pannibal.stop()
	_hush = Hush.new()
	if pannibal.state != LifeActor.State.SCENE:
		pannibal.activity = {
			"poses": [{"anim": "repos"}], "look": false, "greet": false, "step_aside": false
		}
		pannibal.state = LifeActor.State.GAME
	pannibal.game = _hush
	if is_instance_valid(pannibal.npc):
		InteractSign.set_hidden(pannibal.npc, true)
	_play_first(anim_list("anims/ready"), true)


func _release_control() -> void:
	if pannibal == null or _saved_actor.is_empty():
		return
	if _hush != null:
		_hush.active = false
	pannibal.game = null
	if is_instance_valid(pannibal.npc):
		InteractSign.set_hidden(pannibal.npc, false)
	var saved_state: LifeActor.State = _saved_actor["state"]
	if saved_state != LifeActor.State.SCENE and pannibal.state != LifeActor.State.GONE:
		pannibal.stop()
		pannibal.activity = _saved_actor["activity"]
		pannibal.state = saved_state
		var scheduled: Dictionary = _saved_actor["line"]
		if scheduled.has("map") and LifeDirector.current_map() != null:
			pannibal.place_now(scheduled)
	_saved_actor = {}


## Interface du jeu : signes cachés, présentation « nuit » (le joueur a la main).
func _take_ui() -> void:
	_ui_taken = true
	InteractSign.suppress(SIGNS_REASON, true)
	_presentation = DialogueBox.presentation()
	if _presentation != DialogueBox.PRESENTATION_NUIT:
		DialogueBox.set_presentation(DialogueBox.PRESENTATION_NUIT)


## Rend ce que le jeu a pris : l'interface, l'arme, la main (with_hold : la scène la reprend comme
## avant le jeu), Pannibal.
func _restore(with_hold: bool) -> void:
	if _ui_taken:
		_ui_taken = false
		InteractSign.suppress(SIGNS_REASON, false)
		if not _presentation.is_empty() and DialogueBox.presentation() != _presentation:
			DialogueBox.set_presentation(_presentation)
	_disconnect_player()
	_free_hud()
	if is_instance_valid(player):
		if _restore_weapon and not _previous_weapon.is_empty():
			player.set_weapon(_previous_weapon)
			_previous_weapon = &""
		if with_hold and _was_held:
			player.set_story_hold(true)
	if pannibal != null and is_instance_valid(pannibal.npc):
		_release_control()


# --- Image par image -----------------------------------------------------------------------------


## Avance le jeu de delta s.
func advance(delta: float) -> void:
	if phase == &"idle" or _done:
		return
	_time += delta
	_tick_hop()
	if phase == &"ended":
		_end_left -= delta
		if _end_left <= 0.0:
			_close()
		return
	elapsed += delta
	if _help_left > 0.0:
		_help_left -= delta
	if elapsed >= rule("max_time", 75.0):
		_finish(&"time", false)
		return
	if _flat(player.global_position - pannibal.position()).length() > rule("flee_distance", 10.0):
		_finish(&"fled", false)
		return
	if _pending_strike >= 0.0 and _time >= _pending_strike:
		_pending_strike = -1.0
		_player_strikes()
		if not is_running():
			return
	match phase:
		&"intro":
			if _time - _phase_start >= rule("intro_time", 0.8) and _hop.is_empty():
				_begin_leap()
		&"leap":
			_advance_leap()
		&"slash":
			_advance_slashes()
		&"rest":
			if _time >= _next_at and _hop.is_empty():
				_begin_leap()
	_update_light()
	_update_telegraph()
	_update_hud()


# --- Le bond -------------------------------------------------------------------------------------


func _begin_leap() -> void:
	_set_phase(&"leap")
	leaps += 1
	var every := int(rule("leap/feint_every", 3.0))
	var feint := day >= int(rule("leap/feint_from_day", 5.0)) and every > 0 and leaps % every == 0
	var warn := rule("leap/warn", 0.8)
	var target := player.global_position
	_attack = {
		"kind": &"leap",
		"start": _time,
		"impact": _time + warn,
		"warn": warn,
		"target": target,
		"from": pannibal.position(),
		"feint": feint,
		"flying": false,
	}
	pannibal.face(target - pannibal.position())
	_play_first(anim_list("anims/ready"), true)
	_show_help(&"dodge")


func _advance_leap() -> void:
	if _attack.is_empty():
		return
	var impact := float(_attack["impact"])
	if not bool(_attack["flying"]) and _time >= impact - rule("leap/flight", 0.35):
		_attack["flying"] = true
		var from: Vector3 = _attack["from"]
		var target: Vector3 = _attack["target"]
		var toward := _flat(target - from)
		var gap := rule("leap/land_gap", 0.55)
		var land := target - (toward.normalized() * gap if toward.length() > gap else Vector3.ZERO)
		if bool(_attack["feint"]):
			land = from + (land - from) * 0.5
		_start_hop(
			land, maxf(impact - _time, 0.05), rule("leap/height", 0.9), anim_list("anims/leap")
		)
	if _time < impact:
		return
	var attack := _attack
	_attack = {}
	_clear_telegraph()
	if bool(attack["feint"]):
		feints += 1
		resolved.emit(&"leap", &"feint")
		_begin_slashes()
		return
	var away := _flat(player.global_position - Vector3(attack["target"])).length()
	var outcome := &"dodged" if away >= rule("leap/radius", 0.9) else &"hit"
	_apply(&"leap", outcome)
	if not is_running():
		return
	if outcome == &"hit":
		_begin_rest()
	else:
		_begin_slashes()


# --- Les taillades -------------------------------------------------------------------------------


func _begin_slashes() -> void:
	_set_phase(&"slash")
	_slash_left = int(rule("slash/count", 3.0))
	_next_at = _time + rule("slash/first_delay", 0.45)
	_attack = {}


func _advance_slashes() -> void:
	var warn := rule("slash/warn", 0.25)
	if _attack.is_empty():
		if _time >= _next_at - warn:
			_start_slash(_next_at, warn)
		return
	if _time < float(_attack["impact"]):
		return
	_attack = {}
	_clear_telegraph()
	var reach := rule("slash/reach", 1.25)
	var outcome := &"hit"
	if _flat(player.global_position - pannibal.position()).length() > reach:
		outcome = &"dodged"
	elif player.combat.is_guarding():
		outcome = &"parried"
	_flash_slash(outcome)
	_apply(&"slash", outcome)
	if not is_running():
		return
	_slash_left -= 1
	if outcome == &"hit" or _slash_left <= 0:
		_begin_rest()
	else:
		_next_at = _time + rule("slash/interval", 0.35)


## Une taillade annoncée : Pannibal s'avance vers Chtholly (au plus lunge m, jamais plus près que
## stand_off m) et lève son épée de bois ; l'impact tombe à impact.
func _start_slash(impact: float, warn: float) -> void:
	var at := pannibal.position()
	var toward := _flat(player.global_position - at)
	var step := clampf(
		toward.length() - rule("slash/stand_off", 0.75), 0.0, rule("slash/lunge", 0.9)
	)
	var end := at + (toward.normalized() * step if toward.length() > 0.01 else Vector3.ZERO)
	_attack = {
		"kind": &"slash",
		"start": _time,
		"impact": impact,
		"warn": warn,
		"target": end,
		"feint": false,
		"flying": false,
	}
	if step > 0.05 and _hop.is_empty():
		_start_hop(end, maxf(impact - _time, 0.05), 0.0, [])
	pannibal.face(toward)
	_play_first(anim_list("anims/slash"), true)
	_show_help(&"guard")


# --- Repos, riposte ------------------------------------------------------------------------------


## Après une série : Pannibal recule d'un bond à la distance de son attaque, souffle, recommence.
func _begin_rest() -> void:
	_set_phase(&"rest")
	_attack = {}
	_clear_telegraph()
	var back := _spot_away(rule("leap/distance", 4.0))
	var hop_time := rule("intro_time", 0.8) * 0.7
	_start_hop(back, hop_time, rule("leap/height", 0.9) * 0.6, anim_list("anims/hop"))
	_next_at = _time + hop_time + _rng.randf_range(rule("rest_min", 0.7), rule("rest_max", 1.3))


## Le joueur frappe de son bâton : Pannibal découverte, à portée, dans l'arc ? Couverte, elle
## esquive d'un saut en arrière.
func _player_strikes() -> void:
	var offset := _flat(pannibal.position() - player.global_position)
	var arc := deg_to_rad(rule("riposte/arc_deg", 140.0)) * 0.5
	var near := offset.length() <= rule("riposte/reach", 1.7)
	var in_front := (
		offset.length() < 0.3 or offset.normalized().angle_to(player.aim_direction()) <= arc
	)
	if not (near and in_front):
		return
	if _time <= open_until:
		touched = true
		resolved.emit(&"riposte", &"touched")
		_burst(pannibal.position() + Vector3.UP * 0.8, "impact", CombatFx.COLOR_SWORD_FINAL)
		_finish(&"riposte", true)
		return
	resolved.emit(&"riposte", &"evaded")
	_play_first(anim_list("anims/dodge"), true)
	if _hop.is_empty() and (_attack.is_empty() or _attack["kind"] == &"slash"):
		var back := pannibal.position() - offset.normalized() * rule("riposte/dodge_step", 1.0)
		if _walkable(pannibal.position(), back):
			_start_hop(back, 0.25, 0.3, [])
	_burst(pannibal.position() + Vector3.UP * 0.9, "glint", Color.WHITE)


## L'issue d'une attaque : la jauge, l'enchaînement, le recul, la riposte possible.
func _apply(kind: StringName, outcome: StringName) -> void:
	counts[outcome] = int(counts[outcome]) + 1
	match outcome:
		&"hit":
			points += 1
			streak = 0
			_recoil()
			pannibal.say(line("point", "Un point !"), 1.2)
			touches_changed.emit(points, touch_limit)
		&"dodged":
			streak += 1
			open_until = _time + rule("riposte/window", 0.8)
		_:
			streak += 1
			_burst(player.global_position + Vector3.UP * 1.0, "glint", CombatFx.COLOR_SWORD)
	best_streak = maxi(best_streak, streak)
	resolved.emit(kind, outcome)
	if points >= touch_limit:
		_finish(&"points", false)
	elif streak >= int(rule("success_streak", 5.0)):
		_finish(&"streak", true)


## Un coup d'épée de bois : aucun dégât ; Chtholly recule de recoil m (contre les murs, sans les
## traverser), un éclat, une courte pose.
func _recoil() -> void:
	var away := _flat(player.global_position - pannibal.position())
	away = away.normalized() if away.length() > 0.01 else Vector3.BACK
	player.move_and_collide(away * rule("recoil", 0.5))
	var hurt := anim_list("anims/player_hit")
	if not hurt.is_empty():
		player.hold_pose(hurt[0], rule("player_hit_time", 0.18), hurt.slice(1))
	_burst(player.global_position + Vector3.UP * 0.9, "impact", CombatFx.COLOR_BITE)
	_shake(0.05)


# --- Fin -----------------------------------------------------------------------------------------


func _finish(reason: StringName, success: bool) -> void:
	if not is_running():
		return
	_attack = {}
	_pending_strike = -1.0
	_clear_telegraph()
	if _light != null:
		_light.visible = false
	_result = {
		"success": success,
		"ended_by": reason,
		"points": points,
		"touch_limit": touch_limit,
		"best_streak": best_streak,
		"parried": int(counts[&"parried"]),
		"dodged": int(counts[&"dodged"]),
		"hits": int(counts[&"hit"]),
		"leaps": leaps,
		"feints": feints,
		"touched": touched,
		"duration": elapsed,
		"day": day,
	}
	_set_phase(&"ended")
	_end_left = rule("end_time", 1.6)
	_free_hud()
	_help_left = 0.0
	if success:
		# Vexée, à plat ventre dans l'herbe, et elle rit (ACTE1.md, 3.1).
		_hop = {}
		_play_first(anim_list("anims/fall"), true)
		pannibal.say(line("fall", "Pfff… Bon. Celle-là, tu l'as."), 2.0)
	elif reason == &"points":
		pannibal.face(player.global_position - pannibal.position())
		_play_first(anim_list("anims/victory"), true)
		pannibal.say(line("victory", "Trois points. Victoire !"), 2.0)


## La pose de fin est jouée : tout est rendu, finished part, le nœud s'en va.
func _close() -> void:
	if _done:
		return
	_done = true
	_restore(true)
	finished.emit(_result)
	if is_inside_tree():
		queue_free()


# --- Joueur : parade et coup de bâton ------------------------------------------------------------


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
		_pending_strike = _time + rule("riposte/touch_delay", 0.12)


# --- Déplacements de Pannibal --------------------------------------------------------------------


## Un bond de Pannibal (sans physique) : de là où elle est à to, en duration s, hauteur height.
func _start_hop(to: Vector3, duration: float, height: float, anims: Array[StringName]) -> void:
	var from := pannibal.position()
	var end := Vector3(to.x, _ground(to, from.y), to.z)
	_hop = {
		"from": from, "to": end, "start": _time, "duration": maxf(duration, 0.01), "height": height
	}
	if is_instance_valid(player):
		pannibal.face(player.global_position - end)
	if not anims.is_empty():
		_play_first(anims, true)


func _tick_hop() -> void:
	if _hop.is_empty() or pannibal == null:
		return
	var ratio := clampf((_time - float(_hop["start"])) / float(_hop["duration"]), 0.0, 1.0)
	var from: Vector3 = _hop["from"]
	var to: Vector3 = _hop["to"]
	var at := from.lerp(to, ratio)
	at.y += 4.0 * float(_hop["height"]) * ratio * (1.0 - ratio)
	pannibal.set_position(at)
	if ratio >= 1.0:
		_hop = {}
		if phase != &"ended":
			pannibal.face(player.global_position - pannibal.position())
			if phase == &"intro" or phase == &"rest":
				_play_first(anim_list("anims/ready"), true)


## Un point à distance m du joueur, du côté de Pannibal (ou le plus près de ce côté), où l'on se
## tient et qu'on rejoint sans franchir de mur ni de marche.
func _spot_away(distance: float) -> Vector3:
	var origin := player.global_position
	var toward := _flat(pannibal.position() - origin)
	toward = toward.normalized() if toward.length() > 0.05 else Vector3.RIGHT
	for degrees: float in [0.0, 30.0, -30.0, 60.0, -60.0, 90.0, -90.0, 135.0, -135.0, 180.0]:
		var candidate := origin + toward.rotated(Vector3.UP, deg_to_rad(degrees)) * distance
		if _walkable(origin, candidate):
			return candidate
	return pannibal.position()


## Vrai si l'on se tient en to et qu'on le rejoint depuis from (navigation de la carte ; sans
## navigation, toujours vrai).
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


## Joue la première animation de la liste que la planche de Pannibal a.
func _play_first(anims: Array[StringName], restart: bool) -> void:
	if pannibal == null or not is_instance_valid(pannibal.npc):
		return
	for anim: StringName in anims:
		if pannibal.npc.visual.has_animation(anim):
			pannibal.play(anim, restart)
			return


# --- Signes, affichage ---------------------------------------------------------------------------


## La lumière de fée de Pannibal, qui zigzague pendant l'annonce du bond.
func _update_light() -> void:
	if _light == null:
		return
	var leaping: bool = not _attack.is_empty() and _attack["kind"] == &"leap"
	_light.visible = leaping
	if not leaping:
		return
	var t := _time - float(_attack["start"])
	var zig := Vector3(sin(t * 22.0) * LIGHT_ZIGZAG.x, absf(cos(t * 15.0)) * LIGHT_ZIGZAG.y, 0.0)
	_light.global_position = pannibal.position() + Vector3(0.0, LIGHT_HEIGHT, 0.0) + zig


func _update_telegraph() -> void:
	if _telegraph == null or _attack.is_empty():
		return
	var ratio := clampf(
		(_time - float(_attack["start"])) / maxf(float(_attack["warn"]), 0.05), 0.0, 1.0
	)
	if _attack["kind"] == &"leap":
		var target: Vector3 = _attack["target"]
		_telegraph.strike(target, rule("leap/radius", 0.9), target + Vector3.UP * 1.6)
	else:
		var at := pannibal.position()
		_telegraph.strike(
			Vector3(at.x, _ground(at, at.y), at.z), rule("slash/reach", 1.25), at + Vector3.UP * 1.5
		)
	_telegraph.set_progress(ratio)


func _clear_telegraph() -> void:
	if _telegraph != null:
		_telegraph.clear()


## Le trait d'une taillade entre Pannibal et Chtholly ; rouge si elle touche.
func _flash_slash(outcome: StringName) -> void:
	var from := pannibal.position()
	var to := player.global_position
	var direction := _flat(to - from)
	if direction.length_squared() < 0.01 or not is_inside_tree():
		return
	var color := CombatFx.COLOR_BITE if outcome == &"hit" else CombatFx.COLOR_SWORD
	var decal := CombatFx.make_decal("slash", SLASH_SIZE, color, "AmbushSlash")
	decal.material_override = CombatFx.ground_material_unique("slash", color, 1, true)
	add_child(decal)
	var middle := from + direction * 0.5
	decal.global_position = Vector3(
		middle.x, _ground(middle, from.y) + CombatFx.GROUND_LIFT, middle.z
	)
	decal.rotation.y = atan2(-direction.x, -direction.z)
	var tween := decal.create_tween()
	tween.tween_property(decal.material_override, "albedo_color:a", 0.0, SLASH_LIFE)
	tween.tween_callback(decal.queue_free)


func _show_help(key: StringName) -> void:
	if not help or _help_done.has(key):
		return
	_help_done[key] = true
	_help_text = line("help_%s" % key, "")
	_help_left = rule("help_time", 2.6)
	help_shown.emit(key)


func _burst(at: Vector3, fx_name: String, color: Color) -> void:
	if is_inside_tree():
		CombatFx.spawn_burst(self, fx_name, at, color)


func _shake(amount: float) -> void:
	if is_instance_valid(player) and player.combat.screen_shake() != null:
		player.combat.screen_shake().kick(amount, Vector3.FORWARD)


## Texte de la jauge, sobre : « Esquives et parades 2/5 · Points de Pannibal 1/3 », ou la ligne
## d'aide tant qu'elle est affichée.
func hud_text() -> String:
	if _help_left > 0.0 and not _help_text.is_empty():
		return _help_text
	return (
		"%s %d/%d  ·  %s %d/%d"
		% [
			line("hud_streak", "Esquives et parades"),
			streak,
			int(rule("success_streak", 5.0)),
			line("hud_points", "Points de Pannibal"),
			points,
			touch_limit,
		]
	)


func _update_hud() -> void:
	if _hud != null and is_instance_valid(_hud):
		_hud.call(&"set_text", hud_text())


func _free_hud() -> void:
	if _hud != null and is_instance_valid(_hud):
		_hud.queue_free()
	_hud = null


static func _flat(vector: Vector3) -> Vector3:
	return Vector3(vector.x, 0.0, vector.z)
