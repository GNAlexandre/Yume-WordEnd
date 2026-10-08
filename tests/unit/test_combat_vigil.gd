extends "res://tests/stubs/m1_game_test.gd"
## (H7) La veille au Couchant jouée dans la vraie partie par un « joueur correct », jusqu'à la
## vague 5 (PLAN.md section 7, H7 : « vague 5 atteignable ») : de vraies touches (verrouillage,
## épée, déplacement, course), au rythme réel des vagues de data/waves/dunes.json, avec les 5 PV
## de départ. Il ne lit que ce que l'écran montre : la zone d'un coup en préparation et le
## couloir d'une charge (Telegraph), le coup déjà parti (animation de morsure ou de fouet). Il
## s'écarte d'une préparation qui le couvre, attend la fin d'un coup parti pour revenir frapper,
## coupe d'un coup d'épée une préparation commencée à sa portée, et reste dans le cercle.
##
## Ce n'est pas un joueur parfait : il n'utilise pas l'onde, se laisse entourer et s'écarte
## parfois dans la gueule d'un autre Timere. Mesures (graines 1 à 3 et celle du test) : vague 5
## en 76 à 81 s, 1 à 3 morsures reçues ; le même joueur qui ne lit pas les signes reçoit 3 à 6
## morsures et peut tomber à la vague 4.

## Il frappe à cette distance (centre à centre), sous la portée réelle de l'épée (1,48 m sur un
## Petit, docs/REGLAGES_COMBAT.md).
const STRIKE_DISTANCE := 1.35
## Marge (m) autour d'une zone de préparation dans laquelle il s'écarte.
const DODGE_MARGIN := 0.35
## Durée d'un écart (images physiques, en courant).
const DODGE_FRAMES := 15
## Il reste à moins de KEEP m du centre du cercle (en sortir entre deux vagues finit la veille).
const KEEP := 7.0
## Un appui sur l'épée toutes les ATTACK_EVERY images (l'enchaînement suit).
const ATTACK_EVERY := 5
const WAVE_GOAL := 5
## Temps de jeu maximal (s) : vagues 1 à 4 puis début de la 5e au rythme réel, environ 80 s.
const TIME_LIMIT := 130.0

var _frame := 0
var _dodge_left := 0
var _dodge := Vector3.ZERO
var _relock := 0
var _taps: Dictionary = {}
var _stats: Dictionary = {}
var _best_wave := 0
var _log: Array[String] = []
var _last_threat: Dictionary = {}


func test_a_correct_player_reaches_wave_five() -> void:
	await start_game()
	await place_player(&"dunes", Vector3.ZERO, Vector3.FORWARD)
	_stats = {"dodges": 0, "swings": 0, "hits_taken": 0, "kills": 0, "heals": 0}
	listen(
		EventBus.wave_started,
		func(_arena: StringName, wave: int, _count: int) -> void:
			_best_wave = maxi(_best_wave, wave)
	)
	listen(EventBus.player_damaged, _on_damaged)
	listen(EventBus.enemy_killed, func(_id: StringName, _points: int) -> void: _note(&"kills"))
	listen(EventBus.player_heal_requested, func(_amount: int) -> void: _note(&"heals"))
	listen(get_tree().physics_frame, _bot)
	director.start()
	var started := Engine.get_physics_frames()
	var ended: bool = await wait_until(
		func() -> bool: return _best_wave >= WAVE_GOAL or health.is_dead(), TIME_LIMIT
	)
	var seconds := float(Engine.get_physics_frames() - started) / Engine.physics_ticks_per_second
	release_move()
	gut.p(
		(
			"Veille du joueur correct : vague %d en %.0f s, %d PV, %s"
			% [_best_wave, seconds, health.current, _stats]
		)
	)
	for line: String in _log:
		gut.p(line)
	assert_true(ended, "la veille avance (vague %d en %.0f s)" % [_best_wave, seconds])
	assert_gte(_best_wave, WAVE_GOAL, "vague 5 atteinte (%s)" % [_stats])
	assert_false(health.is_dead(), "encore debout au début de la vague 5")
	assert_gt(int(_stats["dodges"]), 0, "il a lu des préparations et s'est écarté")
	director.stop()


func _on_damaged(_amount: int, source: Node3D) -> void:
	_note(&"hits_taken")
	var enemy := source as Enemy
	if enemy == null:
		return
	var seen: int = int(_last_threat.get(enemy.get_instance_id(), -999))
	_log.append(
		(
			"f%d %s d=%.2f state=%s busy=%s dodge=%d threat_seen=%d frames ago, n=%d"
			% [
				_frame,
				enemy.enemy_id(),
				flat_distance(player.global_position, enemy.global_position),
				combat.current_state(),
				combat.is_busy(),
				_dodge_left,
				_frame - seen,
				_alive().size()
			]
		)
	)


func _note(key: StringName) -> void:
	_stats[key] = int(_stats.get(key, 0)) + 1


## Une image du joueur : relâche les appuis brefs, puis s'écarte, frappe ou s'approche.
func _bot() -> void:
	_frame += 1
	for action: StringName in _taps.keys():
		if _frame >= int(_taps[action]):
			Input.action_release(action)
			_taps.erase(action)
	if not is_instance_valid(player) or health.is_dead():
		return
	var me := player.global_position
	var enemies := _alive()
	var target := _nearest(me, enemies)
	if target != null:
		_keep_locked(me, target)
	if _dodge_left <= 0 and not combat.is_busy():
		var escape := _threat(me, enemies)
		if escape != Vector3.ZERO:
			if _can_cut(me, target, enemies):
				# Le Timere qui se prépare est à portée et seul : un coup l'interrompt.
				release_move()
				_swing()
				return
			_dodge = escape.normalized()
			_dodge_left = DODGE_FRAMES
			_note(&"dodges")
	if _dodge_left > 0:
		_dodge_left -= 1
		Input.action_press(&"run")
		hold_toward(_inside(me, _dodge))
		return
	Input.action_release(&"run")
	if target == null:
		var home := arena.global_position - me
		if Vector2(home.x, home.z).length() > 1.5:
			hold_toward(home)
		else:
			release_move()
		return
	var distance := flat_distance(me, target.global_position)
	if distance <= STRIKE_DISTANCE:
		release_move()
		_swing()
	elif target.state() in [&"windup", &"attack"] or _striking_near(me, enemies):
		# Il attend que le coup parti soit fini (on le voit) avant de revenir punir.
		release_move()
	else:
		hold_toward(_inside(me, (target.global_position - me).normalized()))


func _swing() -> void:
	if player.locked_target() != null and _frame % ATTACK_EVERY == 0:
		_tap(&"attack")
		_note(&"swings")


## Un seul Timere menace, il est la cible verrouillée, à portée d'épée et au début de sa
## préparation : le frapper l'interrompt (Enemy : un coup pendant windup annule l'attaque).
func _can_cut(me: Vector3, target: Enemy, enemies: Array[Enemy]) -> bool:
	if target == null or player.locked_target() != target or target.state() != &"windup":
		return false
	if flat_distance(me, target.global_position) > STRIKE_DISTANCE:
		return false
	if target.telegraph.progress() > 0.5:
		return false
	for enemy: Enemy in enemies:
		if enemy != target and enemy.state() in [&"windup", &"attack", &"rush"]:
			if flat_distance(me, enemy.global_position) < 3.0:
				return false
	return true


## Un coup déjà parti (animation de morsure ou de fouet) qui peut encore l'atteindre.
func _striking_near(me: Vector3, enemies: Array[Enemy]) -> bool:
	for enemy: Enemy in enemies:
		var attack := enemy.current_attack()
		if attack != null:
			var distance := flat_distance(me, enemy.global_position)
			if distance < enemy.engage_distance(attack) + 0.9:
				return true
	return false


## Direction d'écart (somme) des signes visibles qui couvrent le joueur, ZERO sinon : zone de
## préparation, couloir de charge, coup déjà parti à portée.
func _threat(me: Vector3, enemies: Array[Enemy]) -> Vector3:
	var escape := Vector3.ZERO
	for enemy: Enemy in enemies:
		var offset := me - enemy.global_position
		offset.y = 0.0
		var telegraph := enemy.telegraph
		var attack := enemy.current_attack()
		if telegraph.mode() == &"strike":
			var strike_at := enemy.global_position + telegraph.zone_center()
			if flat_distance(strike_at, me) < telegraph.zone_radius() + DODGE_MARGIN:
				escape += offset.normalized()
				_last_threat[enemy.get_instance_id()] = _frame
		elif telegraph.mode() == &"rush":
			var lane := telegraph.lane_direction()
			var along := offset.dot(lane)
			var side := offset - lane * along
			var size := telegraph.lane_size()
			if along > -0.5 and along < size.y + 0.5 and side.length() < size.x * 0.5 + 0.6:
				escape += side.normalized() if side.length() > 0.05 else lane.cross(Vector3.UP)
		elif attack != null and offset.length() < enemy.engage_distance(attack) + 0.5:
			escape += offset.normalized()
	return escape


## Ramène une direction vers le centre du cercle quand le joueur s'en éloigne trop.
func _inside(me: Vector3, direction: Vector3) -> Vector3:
	var home := arena.global_position - me
	home.y = 0.0
	if home.length() <= KEEP:
		return direction
	return (direction + home.normalized() * 1.5).normalized()


## Verrouille le Timere le plus proche (appui sur lock_target ; deux appuis pour changer).
func _keep_locked(me: Vector3, target: Enemy) -> void:
	if _taps.has(&"lock_target"):
		return
	var locked := player.locked_target()
	if locked == null:
		if _relock <= _frame:
			_tap(&"lock_target")
			_relock = _frame + 3
		return
	if locked == target:
		return
	var gap := flat_distance(me, locked.global_position) - flat_distance(me, target.global_position)
	if gap > 0.8 and _relock <= _frame:
		# Un appui libère la cible, le suivant prend la plus proche.
		_tap(&"lock_target")
		_relock = _frame + 3


func _tap(action: StringName) -> void:
	Input.action_press(action)
	_taps[action] = _frame + 1


func _alive() -> Array[Enemy]:
	var alive: Array[Enemy] = []
	for enemy: Enemy in director.alive_enemies():
		if is_instance_valid(enemy) and not enemy.is_dead():
			alive.append(enemy)
	return alive


func _nearest(me: Vector3, enemies: Array[Enemy]) -> Enemy:
	var best: Enemy = null
	var best_distance := INF
	for enemy: Enemy in enemies:
		var distance := flat_distance(me, enemy.global_position)
		if distance < best_distance:
			best = enemy
			best_distance = distance
	return best
