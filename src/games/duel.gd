class_name Duel
extends Node3D
## (E8b) Le duel ingagnable (docs/lore/ACTE1.md, 3.3 ; scène 8.3, le jour 8 au matin, place `duel`
## de la cour de l'entrepôt) : Chtholly, Seniorious en main, contre Willem et le Carillon de série
## Percival. Propriétaire : E8. Chiffres : data/games/duel.json. Sur le modèle de l'embuscade
## (src/games/ambush.gd).
##
## - Phase 1 (&"dodge", 30 s au plus) : Willem s'étire ; chaque coup de Chtholly passe à côté : il
##   fait un pas de côté, ne pare jamais. Sans attaque pendant 8 s, il lui fait signe d'approcher.
## - Phase 2 (&"vision") : la charge tenue 2 s allume le venenum (au bout des 30 s, elle l'allume
##   d'elle-même) : la vision accélérée. L'image pâlit de 60 % (sauf autour d'elle), le monde
##   ralentit à 0,6 (Willem, les spectatrices proches), la lumière sort des fissures de la lame.
##   Au premier coup (frappe ou onde), son élan franchit jusqu'à 8 m en deux foulées vers Willem.
## - Phase 3 (&"reversal") : Willem retourne l'élan. Écran blanc, silence, deux battements de cœur
##   puis plus rien (0,6 s : la mort hallucinée, sans corps ni sang) ; le blanc s'efface : il dévie
##   la lame, la touche à peine, et elle est projetée à 6 m, sur le dos dans l'herbe ; un instant,
##   Percival brille autant que Seniorious.
## - Reprise (option reprise, « Encore une fois ! ») : intro, Willem en garde (&"ready" : on tient
##   la charge), puis les phases 2 et 3, plus vite ; même fin.
## La réussite est impossible, et c'est voulu : aucun point de vie perdu (jamais de Health touchée),
## aucun écran de défaite ; la scène continue (ACTE1.md, 3.0).
##
## Pendant le duel : le joueur a la main jusqu'à l'élan (puis le duel le mène), Seniorious en main,
## Willem muet (un jeu Hush) dans sa tenue « duel » (willem_duel), les signes cachés ; à la fin,
## l'arme, la main de la scène, la tenue de Willem, le post-traitement et l'horloge des visuels
## reviennent. Les effets passent par GameVision (src/games/game_vision.gd). Résultat (finished,
## après la pose de fin) : {success (toujours faux), ended_by (&"thrown", &"stopped"), reprise,
## phases (les phases parcourues, dans l'ordre), strikes, dodges, beckons, vision_by (&"charge",
## &"time"), dash_distance, thrown_distance, duration}.
## Tout se fait au pas de advance(delta) : le nœud s'avance seul à chaque image physique, les tests
## le coupent (set_physics_process(false)) et l'avancent à la main.

## La phase a changé : &"intro", &"dodge", &"ready" (reprise), &"vision", &"reversal", &"ended".
signal phase_changed(phase: StringName)
## Un geste est résolu : (&"strike", &"dodged" | &"missed"), (&"beckon", &"waiting"), (&"venenum",
## &"charge" | &"time"), (&"dash", &"started"), (&"reversal", &"deflected"), (&"thrown", &"landed").
signal resolved(kind: StringName, outcome: StringName)
## La vision accélérée commence (vrai) ou finit (faux).
signal vision_changed(active: bool)
## Un battement de cœur dans le blanc (index 0, 1) ; un lot du son pourra s'y brancher.
signal heartbeat(index: int)
## Le duel est fini, la pose de fin jouée, tout rendu (résultat : voir plus haut).
signal finished(result: Dictionary)

const GAME_RULES := &"duel"
const SCORE_SCRIPT := preload("res://src/games/game_score.gd")
## Raison qui cache les signes d'interaction pendant le duel (InteractSign.suppress).
const SIGNS_REASON := &"duel"
## L'aire du duel sur la carte (Life/Areas/duel, métadonnée « area » : Rect2 en x, z).
const AREA_PATH := ^"Life/Areas/duel"
const BLADE_HEIGHT := 1.0
## La lumière du venenum, sur Percival et sur Seniorious.
const GLOW_COLOR := Color(1.0, 0.95, 0.8)

var player: Player = null
var willem: LifeActor = null
## Surcharges des règles (chemins du fichier), pour les tests.
var overrides: Dictionary = {}
## « Encore une fois ! » : les phases 2 et 3 seulement, plus vite.
var reprise: bool = false
## Le HUD sobre (une ligne) est posé.
var show_hud: bool = true
var phase: StringName = &"idle"
## Les phases parcourues, dans l'ordre.
var phases: Array[StringName] = []
var strikes: int = 0
var dodges: int = 0
var beckons: int = 0
var vision_by: StringName = &""
var dash_distance: float = 0.0
var thrown_distance: float = 0.0
var elapsed: float = 0.0
## Les effets (pâleur, écran blanc, ralenti).
var vision := GameVision.new()

var _time: float = 0.0
var _world_time: float = 0.0
var _phase_start: float = 0.0
var _speed: float = 1.0
var _arena: Rect2 = Rect2()
var _result: Dictionary = {}
var _done: bool = false
var _end_left: float = -1.0
var _pending_strike: float = -1.0
var _last_attack: float = 0.0
var _charge_held: float = 0.0
var _glint_left: float = 0.0
var _hop: Dictionary = {}
var _move: Dictionary = {}
var _beats_done: int = 0
var _reversal: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _hud: CanvasLayer = null
var _hush: Hush = null
var _saved_actor: Dictionary = {}
var _previous_weapon: StringName = &""
var _restore_weapon: bool = true
var _was_held: bool = false
var _holding: bool = false
var _ui_taken: bool = false
var _visual_rest: Vector3 = Vector3.ZERO
var _glow: MeshInstance3D = null


## Le jeu muet qui tient Willem : lui parler pendant le duel ne fait rien.
class Hush:
	extends LifeGame

	var active: bool = true

	func on_player_interact(_actor: LifeActor) -> bool:
		return active

	func blocks_talk() -> bool:
		return active


func _init() -> void:
	name = "Duel"
	_rng.seed = Time.get_ticks_usec()


## Fixe le tirage (tests, démonstrations) : la même graine rejoue le même duel.
func seed_random(value: int) -> void:
	_rng.seed = value


func _physics_process(delta: float) -> void:
	advance(delta)


func _exit_tree() -> void:
	# La carte est quittée en plein duel : l'arme, l'image, les visuels et Willem sont rendus.
	if not _done:
		_restore(false)


# --- Règles --------------------------------------------------------------------------------------


## Un chiffre des règles (chemin « phase_2/charge_hold »).
func rule(key_path: String, default: float) -> float:
	return GameRules.number(GAME_RULES, key_path, default, overrides)


## Une durée des règles, raccourcie dans la reprise (divisée par reprise/speed).
func span(key_path: String, default: float) -> float:
	return rule(key_path, default) / _speed


## Une liste d'animations des règles (« anims/willem_rest »).
func anim_list(key_path: String) -> Array[StringName]:
	var found: Variant = GameRules.value(GAME_RULES, key_path, [], overrides)
	var list: Array[StringName] = []
	if found is Array:
		for entry: Variant in found:
			list.append(StringName(str(entry)))
	return list


## Texte du duel (data/texts/life.json, games/duel/<clé> ; {player} accepté).
func line(key: String, fallback: String = "") -> String:
	return LifeTexts.text("games/duel/%s" % key, fallback, _rng)


# --- Mise en place et fin ------------------------------------------------------------------------


## Prépare le duel : le joueur, Willem, la reprise. Ne démarre rien : start().
func setup(the_player: Player, the_willem: LifeActor, with_reprise: bool = false) -> void:
	player = the_player
	willem = the_willem
	reprise = with_reprise
	_speed = maxf(rule("reprise/speed", 1.5), 0.1) if reprise else 1.0
	_arena = _read_arena()


## Commence : Seniorious en main (l'arme d'avant revient à la fin), la main au joueur, Willem muet
## dans sa tenue du duel, les signes cachés.
func start(restore_weapon: bool = true) -> void:
	if phase != &"idle" or player == null or willem == null:
		return
	_restore_weapon = restore_weapon
	_previous_weapon = player.weapon()
	player.set_weapon(PlayerCombat.WEAPON_SENIORIOUS)
	_was_held = player.is_story_held()
	player.set_story_hold(false)
	_visual_rest = player.visual.position
	_ui_taken = true
	InteractSign.suppress(SIGNS_REASON, true)
	_connect_player()
	_take_control()
	vision.begin(GameVision.post_material(player))
	if show_hud:
		_hud = SCORE_SCRIPT.new() as CanvasLayer
		_hud.name = "DuelScore"
		add_child(_hud)
	willem.face(player.global_position - willem.position())
	_set_phase(&"intro")
	if reprise:
		_play_willem(anim_list("anims/willem_guard"), true)
		willem.say(line("reprise", "Encore une fois, alors."), 1.6)
	else:
		_play_willem(anim_list("anims/willem_beckon"), true)
		willem.say(line("intro", "Quand tu veux."), 1.6)
	_update_hud()


## Arrête le duel (la scène l'interrompt) : résultat « stopped », tout est rendu tout de suite.
func stop() -> void:
	if not is_running():
		return
	_finish(&"stopped")
	_end_left = 0.0
	advance(0.0)


## Vrai tant que le duel court (la pose de fin n'en fait plus partie).
func is_running() -> bool:
	return phase != &"idle" and phase != &"ended"


## Vrai quand tout est fini et rendu (finished émis).
func is_done() -> bool:
	return _done


## Résultat (vide tant que le duel n'est pas fini).
func result() -> Dictionary:
	return _result


## Temps du duel (s) et temps du monde (ralenti pendant la vision).
func game_time() -> float:
	return _time


func world_time() -> float:
	return _world_time


## Durée de la charge tenue (s), remise à zéro quand elle cesse.
func charge_time() -> float:
	return _charge_held


## L'aire du duel (x, z).
func arena() -> Rect2:
	return _arena


## L'élan en cours ({} entre deux) : from, to, start, duration ; la projection : kind &"throw".
func current_move() -> Dictionary:
	return _move


func _set_phase(next: StringName) -> void:
	phase = next
	_phase_start = _time
	if next != &"ended":
		phases.append(next)
	phase_changed.emit(next)


## Willem passe sous la conduite du duel : muet (Hush), rien de son emploi du temps, sa tenue du
## duel ; un présent d'une scène (SCENE) le reste.
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


## Rend ce que le duel a pris : l'image, les visuels, l'arme, la main (with_hold : la scène la
## reprend comme avant), Willem.
func _restore(with_hold: bool) -> void:
	vision.end()
	if _ui_taken:
		_ui_taken = false
		InteractSign.suppress(SIGNS_REASON, false)
	_disconnect_player()
	_free_hud()
	_free_glow()
	if is_instance_valid(player):
		player.visual.position = _visual_rest
		if _holding:
			_holding = false
			player.set_story_hold(false)
		player.hold_pose(&"", 0.0)
		if _restore_weapon and not _previous_weapon.is_empty():
			player.set_weapon(_previous_weapon)
			_previous_weapon = &""
		if with_hold and _was_held:
			player.set_story_hold(true)
	if willem != null and is_instance_valid(willem.npc):
		_release_control()


# --- Image par image -----------------------------------------------------------------------------


## Avance le duel de delta s.
func advance(delta: float) -> void:
	if phase == &"idle" or _done:
		return
	_time += delta
	_world_time += delta * vision.time_scale
	vision.tick(delta)
	_tick_hop()
	_tick_move()
	if phase == &"ended":
		_end_left -= delta
		if _end_left <= 0.0:
			_close()
		return
	elapsed += delta
	_watch_charge(delta)
	if _pending_strike >= 0.0 and _time >= _pending_strike:
		_pending_strike = -1.0
		_player_strikes()
	match phase:
		&"intro":
			var intro := rule("reprise/intro_time", 0.8) if reprise else rule("intro_time", 1.2)
			if _time - _phase_start >= intro:
				_set_phase(&"ready" if reprise else &"dodge")
				_last_attack = _time
				_play_willem(_rest_anims(), false)
		&"dodge":
			_advance_dodge()
		&"ready":
			if _time - _phase_start >= rule("reprise/wait", 8.0):
				_enter_vision(&"time")
		&"vision":
			_advance_vision(delta)
		&"reversal":
			_advance_reversal()
	_face_willem()
	_update_hud()


# --- Phase 1 : il esquive ------------------------------------------------------------------------


func _advance_dodge() -> void:
	if _time - _phase_start >= rule("phase_1/max_time", 30.0):
		_enter_vision(&"time")
		return
	if _time - _last_attack >= rule("phase_1/beckon_after", 8.0) and _hop.is_empty():
		_last_attack = _time
		beckons += 1
		resolved.emit(&"beckon", &"waiting")
		willem.hold(_first(anim_list("anims/willem_beckon")), 1.4)
		willem.say(line("beckon", "Approche."), 1.6)


## La charge tenue (Seniorious : la touche de charge) : à charge_hold s, la vision s'allume.
func _watch_charge(delta: float) -> void:
	if player.combat.current_state() == &"charge":
		_charge_held += delta
	else:
		_charge_held = 0.0
	if phase != &"dodge" and phase != &"ready":
		return
	var needed := rule("reprise/charge_hold", 1.2) if reprise else rule("phase_2/charge_hold", 2.0)
	if _charge_held >= needed:
		_enter_vision(&"charge")


## Le coup de Chtholly arrive (strike_delay s après son départ) : à portée et devant elle, Willem
## fait un pas de côté ; sinon le coup fend l'air.
func _player_strikes() -> void:
	if phase != &"dodge" and phase != &"ready" and phase != &"intro":
		return
	strikes += 1
	var offset := _flat(willem.position() - player.global_position)
	var arc := deg_to_rad(rule("phase_1/arc_deg", 150.0)) * 0.5
	var near := offset.length() <= rule("phase_1/reach", 2.4)
	var in_front := (
		offset.length() < 0.3 or offset.normalized().angle_to(player.aim_direction()) <= arc
	)
	if not (near and in_front):
		resolved.emit(&"strike", &"missed")
		return
	dodges += 1
	resolved.emit(&"strike", &"dodged")
	if _hop.is_empty():
		_start_hop(_dodge_spot(offset), rule("phase_1/step_time", 0.24), 0.0)
		_play_willem(anim_list("anims/willem_step"), true)
	var every := int(rule("phase_1/say_every", 3.0))
	if every > 0 and dodges % every == 0:
		willem.say(line("dodge", "Trop large."), 1.2)
	_burst(willem.position() + Vector3.UP * 1.0, "glint", Color(0.85, 0.9, 1.0))


## Où Willem pose son pas de côté : de travers à l'axe du coup, d'un côté ou de l'autre, dans
## l'aire et sans franchir de mur ; à défaut, en arrière.
func _dodge_spot(offset: Vector3) -> Vector3:
	var origin := willem.position()
	var away := offset.normalized() if offset.length() > 0.05 else Vector3.FORWARD
	var side := away.cross(Vector3.UP).normalized()
	var step := rule("phase_1/step", 1.2)
	var first := 1.0 if _rng.randf() < 0.5 else -1.0
	for candidate: Vector3 in [
		origin + side * step * first, origin - side * step * first, origin + away * step
	]:
		if _inside(candidate) and _walkable(origin, candidate):
			return candidate
	return origin


# --- Phase 2 : la vision accélérée ---------------------------------------------------------------


func _enter_vision(by: StringName) -> void:
	vision_by = by
	resolved.emit(&"venenum", by)
	_set_phase(&"vision")
	var visuals: Array[CharacterVisual] = []
	var radius := rule("phase_2/slow_radius", 25.0)
	for actor: LifeActor in LifeDirector.actors():
		if actor.state == LifeActor.State.GONE or not is_instance_valid(actor.npc):
			continue
		if actor == willem or _flat(actor.position() - player.global_position).length() <= radius:
			visuals.append(actor.npc.visual)
	vision.slow(visuals, rule("phase_2/slow", 0.6))
	_glint_left = 0.0
	vision_changed.emit(true)
	if not reprise:
		_play_willem(anim_list("anims/willem_guard"), true)


func _advance_vision(delta: float) -> void:
	var fade := clampf((_time - _phase_start) / maxf(span("phase_2/fade_in", 0.4), 0.01), 0.0, 1.0)
	_set_pale(rule("phase_2/pale", 0.6) * fade)
	_glint_left -= delta
	if _glint_left <= 0.0:
		_glint_left = rule("phase_2/glint_every", 0.12)
		_blade_glint()
	if _move.is_empty() and _time - _phase_start >= span("phase_2/max_time", 10.0):
		# Elle n'y tient plus : elle s'élance d'elle-même.
		if player.combat.current_state() == &"charge":
			player.combat.charge_release()
		_start_dash()


## La lumière qui s'échappe des fissures de la lame : un éclat près de la main de Chtholly.
func _blade_glint() -> void:
	var aim := player.aim_direction()
	var jitter := Vector3(_rng.randf_range(-0.25, 0.25), _rng.randf_range(-0.2, 0.3), 0.0)
	var at := player.global_position + aim * 0.45 + Vector3.UP * BLADE_HEIGHT + jitter
	_burst(at, "glint", CombatFx.COLOR_WAVE, 0.7)


## L'élan : vers Willem, au plus dash_distance m, arrêté à stop_gap m de lui, en deux foulées.
func _start_dash() -> void:
	if not _move.is_empty() or phase != &"vision":
		return
	_take_player()
	var from := player.global_position
	var toward := _flat(willem.position() - from)
	var gap := rule("phase_2/stop_gap", 0.9)
	var length := clampf(toward.length() - gap, 0.0, rule("phase_2/dash_distance", 8.0))
	var heading := toward.normalized() if toward.length() > 0.05 else Vector3.ZERO
	var to := from + heading * length
	while length > 0.0 and not _walkable(from, to):
		length = maxf(length - 0.5, 0.0)
		to = from + heading * length
	dash_distance = length
	player.set_aim_direction(toward)
	var anims := anim_list("anims/player_dash")
	var duration := span("phase_2/dash_time", 0.42)
	if not anims.is_empty():
		player.hold_pose(anims[0], duration, anims.slice(1))
	_move = {
		"kind": &"dash",
		"from": from,
		"to": to,
		"start": _time,
		"duration": maxf(duration, 0.01),
		"height": rule("phase_2/stride_height", 0.22),
		"bumps": maxi(int(rule("phase_2/strides", 2.0)), 1),
	}
	resolved.emit(&"dash", &"started")


# --- Phase 3 : il retourne l'élan ----------------------------------------------------------------


func _enter_reversal() -> void:
	_set_phase(&"reversal")
	_beats_done = 0
	var white_in := span("phase_3/white_in", 0.06)
	var hold := span("phase_3/white_hold", 0.6)
	_reversal = {
		"white_in": white_in,
		"hold_end": white_in + hold,
		"out_end": white_in + hold + span("phase_3/white_out", 0.45),
		"thrown": false,
	}
	vision.set_flash(1.0 if white_in <= 0.0 else 0.0)
	_play_willem(anim_list("anims/willem_deflect"), true)
	resolved.emit(&"reversal", &"deflected")


func _advance_reversal() -> void:
	var local := _time - _phase_start
	var white_in: float = _reversal["white_in"]
	var hold_end: float = _reversal["hold_end"]
	var out_end: float = _reversal["out_end"]
	var amount := 1.0
	if local < white_in:
		amount = local / maxf(white_in, 0.001)
	elif local >= hold_end:
		amount = 1.0 - clampf((local - hold_end) / maxf(out_end - hold_end, 0.001), 0.0, 1.0)
	# Les battements : le blanc se voile un instant, la vue tressaille ; puis plus rien.
	var beats: Variant = GameRules.value(GAME_RULES, "phase_3/beat_at", [0.08, 0.3], overrides)
	var dip := 0.0
	if beats is Array:
		for index: int in (beats as Array).size():
			var at := white_in + float((beats as Array)[index]) / _speed
			if local >= at and _beats_done <= index:
				_beats_done = index + 1
				heartbeat.emit(index)
				_shake(rule("phase_3/shake", 0.08) * 0.5)
			var since := local - at
			if since >= 0.0 and since < 0.12:
				dip = maxf(dip, rule("phase_3/beat_dip", 0.14) * (1.0 - since / 0.12))
	vision.set_flash(clampf(amount - dip, 0.0, 1.0))
	if local >= hold_end and not bool(_reversal["thrown"]):
		_reversal["thrown"] = true
		_throw()
	if bool(_reversal["thrown"]):
		var after := clampf(
			(local - hold_end) / maxf(span("phase_3/throw_time", 0.55), 0.01), 0.0, 1.0
		)
		_set_pale(rule("phase_2/pale", 0.6) * (1.0 - after))
		if after >= 1.0 and vision.time_scale < 1.0:
			vision.unslow()
			vision_changed.emit(false)
	if local >= out_end and _move.is_empty() and vision.time_scale >= 1.0:
		_finish(&"thrown")


## Il dévie la lame, la touche à peine : elle est projetée loin de lui, sur le dos ; Percival
## brille un instant autant que Seniorious.
func _throw() -> void:
	var from := player.global_position
	var away := _flat(from - willem.position())
	away = away.normalized() if away.length() > 0.05 else Vector3.BACK
	var distance := rule("phase_3/throw_distance", 6.0)
	var to := from + away * distance
	while distance > 0.5 and not (_inside(to) and _walkable(from, to)):
		distance -= 0.5
		to = from + away * distance
	thrown_distance = distance
	var duration := span("phase_3/throw_time", 0.55)
	var anims := anim_list("anims/player_thrown")
	if not anims.is_empty():
		player.hold_pose(anims[0], 600.0, anims.slice(1))
	player.set_aim_direction(-away)
	_move = {
		"kind": &"throw",
		"from": from,
		"to": to,
		"start": _time,
		"duration": maxf(duration, 0.01),
		"height": rule("phase_3/throw_height", 1.0),
		"bumps": 1,
	}
	_percival_glow()
	var contact := willem.position() + Vector3.UP * BLADE_HEIGHT + away * 0.4
	_burst(contact, "impact", CombatFx.COLOR_SWORD_FINAL, 1.2)
	_shake(rule("phase_3/shake", 0.08))


## Percival brille autant que Seniorious : un halo de lumière (un disque doux, additif, devant
## tout) sur la lame de Willem, que la lueur du post-traitement fait déborder ; un éclat sur
## Seniorious, de la même lumière.
func _percival_glow() -> void:
	_free_glow()
	if not is_inside_tree():
		return
	var size := rule("phase_3/percival_size", 2.6)
	_glow = make_glow(size, GLOW_COLOR)
	_glow.name = "PercivalGlow"
	add_child(_glow)
	_glow.global_position = willem.position() + Vector3.UP * (BLADE_HEIGHT + 0.2)
	_glow.scale = Vector3.ONE * 0.4
	var glow_time := span("phase_3/percival_time", 1.0)
	var material := _glow.material_override as StandardMaterial3D
	var tween := _glow.create_tween()
	tween.tween_property(_glow, "scale", Vector3.ONE, glow_time * 0.15)
	tween.tween_interval(glow_time * 0.3)
	tween.tween_property(material, "albedo_color:a", 0.0, glow_time * 0.55)
	tween.tween_callback(_free_glow)
	_burst(player.global_position + Vector3.UP * BLADE_HEIGHT, "glint", GLOW_COLOR, 2.0)
	_burst(_glow.global_position, "glint", GLOW_COLOR, 2.4)


## Un halo de lumière : un carré de size m tourné vers la caméra, un disque doux additif.
static func make_glow(size: float, color: Color) -> MeshInstance3D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	gradient.add_point(0.25, Color(1.0, 1.0, 1.0, 0.85))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 64
	texture.height = 64
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.no_depth_test = true
	material.albedo_texture = texture
	material.albedo_color = color
	material.render_priority = 3
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	var glow := MeshInstance3D.new()
	glow.mesh = quad
	glow.material_override = material
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return glow


func _free_glow() -> void:
	if _glow != null and is_instance_valid(_glow):
		_glow.queue_free()
	_glow = null


# --- Fin -----------------------------------------------------------------------------------------


func _finish(reason: StringName) -> void:
	if not is_running():
		return
	_pending_strike = -1.0
	_result = {
		"success": false,
		"ended_by": reason,
		"reprise": reprise,
		"phases": phases.duplicate(),
		"strikes": strikes,
		"dodges": dodges,
		"beckons": beckons,
		"vision_by": vision_by,
		"dash_distance": dash_distance,
		"thrown_distance": thrown_distance,
		"duration": elapsed,
	}
	_set_phase(&"ended")
	_end_left = rule("end_time", 2.2)
	_set_pale(0.0)
	vision.set_flash(0.0)
	vision.unslow()
	_free_hud()
	if reason == &"thrown":
		_play_willem(_rest_anims(), true)


## La pose de fin est jouée : tout est rendu, finished part, le nœud s'en va.
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
	if not is_running():
		return
	_last_attack = _time
	if phase == &"vision":
		# Le venenum allumé, tout coup est chargé : l'élan part.
		_start_dash()
	elif phase == &"dodge" or phase == &"ready" or phase == &"intro":
		_pending_strike = _time + rule("strike_delay", 0.1)


## Le duel mène le joueur (l'élan, la projection) : ses commandes sont ignorées.
func _take_player() -> void:
	if _holding:
		return
	_holding = true
	if player.combat.current_state() == &"charge":
		player.combat.charge_release()
	player.set_story_hold(true)


## L'élan ou la projection en cours : le corps glisse au sol (le trajet a été vérifié sur la
## navigation : ni mur ni marche), la planche décrit des foulées ou un arc.
func _tick_move() -> void:
	if _move.is_empty() or not is_instance_valid(player):
		return
	var ratio := clampf((_time - float(_move["start"])) / float(_move["duration"]), 0.0, 1.0)
	var from: Vector3 = _move["from"]
	var to: Vector3 = _move["to"]
	var eased := ratio if _move["kind"] == &"dash" else 1.0 - pow(1.0 - ratio, 2.0)
	var wanted := from.lerp(to, eased)
	player.global_position = Vector3(
		wanted.x, _ground(wanted, player.global_position.y - 0.05) + 0.05, wanted.z
	)
	player.velocity = Vector3.ZERO
	var bumps := int(_move["bumps"])
	var lift := absf(sin(ratio * PI * bumps)) * float(_move["height"])
	player.visual.position = _visual_rest + Vector3.UP * lift
	if ratio < 1.0:
		return
	var kind: StringName = _move["kind"]
	_move = {}
	player.visual.position = _visual_rest
	_burst(player.global_position + Vector3.UP * 0.05, "dust", CombatFx.COLOR_DUST)
	if kind == &"dash":
		_enter_reversal()
	else:
		resolved.emit(&"thrown", &"landed")
		_shake(rule("phase_3/shake", 0.08) * 0.6)


# --- Willem --------------------------------------------------------------------------------------


func _rest_anims() -> Array[StringName]:
	return anim_list("anims/willem_guard") if reprise else anim_list("anims/willem_rest")


## Un pas de Willem (sans physique), au temps du monde (ralenti pendant la vision).
func _start_hop(to: Vector3, duration: float, height: float) -> void:
	var from := willem.position()
	_hop = {
		"from": from,
		"to": Vector3(to.x, _ground(to, from.y), to.z),
		"start": _world_time,
		"duration": maxf(duration, 0.01),
		"height": height,
	}


func _tick_hop() -> void:
	if _hop.is_empty() or willem == null:
		return
	var ratio := clampf((_world_time - float(_hop["start"])) / float(_hop["duration"]), 0.0, 1.0)
	var from: Vector3 = _hop["from"]
	var to: Vector3 = _hop["to"]
	var at := from.lerp(to, ratio)
	at.y += 4.0 * float(_hop["height"]) * ratio * (1.0 - ratio)
	willem.set_position(at)
	if ratio >= 1.0:
		_hop = {}
		if is_running() and phase != &"reversal":
			_play_willem(_rest_anims(), false)


func _face_willem() -> void:
	if willem != null and is_instance_valid(player) and _hop.is_empty():
		willem.face(player.global_position - willem.position())


## Joue la première animation de la liste que la planche de Willem a.
func _play_willem(anims: Array[StringName], restart: bool) -> void:
	if willem == null or not is_instance_valid(willem.npc):
		return
	for anim: StringName in anims:
		if willem.npc.visual.has_animation(anim):
			willem.play(anim, restart)
			return


static func _first(anims: Array[StringName]) -> StringName:
	return anims[0] if not anims.is_empty() else &"repos"


# --- L'aire, le sol ------------------------------------------------------------------------------


## L'aire du duel : Life/Areas/duel de la carte, sinon un carré autour de Willem.
func _read_arena() -> Rect2:
	var map := LifeDirector.current_map()
	var marker := map.get_node_or_null(AREA_PATH) if map != null else null
	if marker != null and marker.has_meta(&"area"):
		var area: Variant = marker.get_meta(&"area")
		if area is Rect2:
			return area
	var half := rule("arena_half_size", 6.0)
	var center := willem.position() if willem != null else Vector3.ZERO
	return Rect2(center.x - half, center.z - half, half * 2.0, half * 2.0)


func _inside(at: Vector3) -> bool:
	return _arena.has_area() and _arena.grow(-0.3).has_point(Vector2(at.x, at.z))


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


# --- Effets, affichage ---------------------------------------------------------------------------


## La pâleur, nette autour de Chtholly (sa place à l'écran).
func _set_pale(amount: float) -> void:
	var center := Vector2(0.5, 0.5)
	var camera := player.camera_rig.camera if is_instance_valid(player) else null
	if camera != null and camera.is_inside_tree():
		var size := camera.get_viewport().get_visible_rect().size
		var at := player.global_position + Vector3.UP * 0.8
		if size.y > 0.0 and not camera.is_position_behind(at):
			center = camera.unproject_position(at) / size
	vision.set_pale(amount, center, rule("phase_2/clear_radius", 0.12))


func _burst(at: Vector3, fx_name: String, color: Color, size: float = 1.0) -> void:
	if is_inside_tree():
		CombatFx.spawn_burst(self, fx_name, at, color, size)


func _shake(amount: float) -> void:
	if is_instance_valid(player) and player.combat.screen_shake() != null:
		player.combat.screen_shake().kick(amount, Vector3.FORWARD)


## La ligne du HUD : ce que demande la phase (vide pendant le blanc).
func hud_text() -> String:
	match phase:
		&"intro", &"dodge":
			return line("hud_dodge", "Willem esquive tout. Tiens la charge : le venenum.")
		&"ready":
			return line("hud_ready", "Encore une fois : tiens la charge.")
		&"vision":
			return line("hud_vision", "Vision accélérée : frappe !")
	return ""


func _update_hud() -> void:
	if _hud != null and is_instance_valid(_hud):
		var text := hud_text()
		_hud.visible = not text.is_empty()
		_hud.call(&"set_text", text)


func _free_hud() -> void:
	if _hud != null and is_instance_valid(_hud):
		_hud.queue_free()
	_hud = null


static func _flat(vector: Vector3) -> Vector3:
	return Vector3(vector.x, 0.0, vector.z)
