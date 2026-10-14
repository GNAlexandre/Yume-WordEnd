class_name Animal
extends Enemy
## Un animal sauvage (lot E5) : un Enemy (src/enemies/enemy.gd) dont les données sont une
## AnimalData, et que la garde des Timeres ne retire pas : c'est la liste « fauna » des règles de
## l'île qui l'admet (_is_admitted). La scène est animal.tscn (celle d'Enemy, ce script).
##
## Ce qui vient d'Enemy : le corps, la Health, la Hurtbox et la Hitbox, la préparation d'un coup
## (zone au sol), le recul, les éclairs, l'IA de poursuite d'un animal dangereux. Ce que la faune
## ajoute (comportement choisi par AnimalData.behavior) :
## - paisible et fuyard (mode GRAZE → ALERT → FLEE) : errent, broutent, regardent le joueur à
##   alert_range_m, fuient à flee_range_m (multipliée par le bruit : joueur qui court ou immobile),
##   fuient un combat proche, s'envolent (oiseaux) ou plongent (vanish_s) ; la fuite suit la
##   praticabilité du sol (FaunaNav : MapGround.is_walkable, level_at) ;
## - dangereux : l'IA d'Enemy ; la laisse (leash_m : la tanière de l'ours), la meute qui encercle
##   (AnimalPack), le bond du loup et la charge du sanglier (rush : préparation, ligne droite,
##   étourdissement s'il heurte un obstacle) ;
## - vaincu (Health à zéro) : il s'enfuit au lieu de mourir (mode LEAVE : « degats », puis course),
##   sans EventBus.enemy_killed ni cadavre ; la meute dont la moitié a fui se débande.
## Un animal paisible n'est pas dans le groupe « enemies » (pas de verrouillage, pas d'Ennemis au
## HUD) ; tous sont dans le groupe « fauna ».

## L'animal vaincu (ou débandé) a pris la fuite.
signal fled(animal: Animal)

enum Mode { GRAZE, ALERT, FLEE, LEAVE }

const FAUNA_GROUP := &"fauna"
const MODE_NAMES: Array[StringName] = [&"graze", &"alert", &"flee", &"leave"]
## Montée d'un oiseau qui s'envole (m/s), plafond (m) ; il continue en ligne droite.
const FLY_CLIMB := 2.4
const FLY_MAX := 4.5
## Réduction d'un animal qui quitte la scène (s) et pause de « degats » d'un vaincu (s).
const DISSOLVE_TIME := 0.25
const STAGGER_TIME := 0.25
## Un animal alerte se calme si le joueur reste hors de portée aussi longtemps (s).
const ALERT_CALM_TIME := 1.5
## Le joueur est « immobile » sous cette vitesse (m/s).
const STILL_SPEED := 0.3
## Un pas de la meute alertée : elle chasse jusqu'à ce multiple de la portée de repérage.
const PACK_ALERT_FACTOR := 2.0

## Meute (loups) : fixée par FaunaPopulator ou AnimalPack.add.
var pack: AnimalPack = null

var _species: AnimalData
var _mode: Mode = Mode.GRAZE
var _mode_time: float = 0.0
var _flee_from: Vector3 = Vector3.ZERO
var _startle_left: float = 0.0
var _pause_animation: StringName = &"repos"
var _can_walk: bool = true
var _can_run: bool = true
var _stun_left: float = 0.0
var _flying: bool = false
var _fly_height: float = 0.0
var _dissolving: bool = false
var _stagger_left: float = 0.0
var _last_hit_from: Vector3 = Vector3.ZERO
var _has_hit_from: bool = false
var _ground_cache: MapGround = null
var _ground_known: bool = false


## Données de l'espèce (null si l'animal n'a pas d'AnimalData).
func species() -> AnimalData:
	return _species


func _ready() -> void:
	_species = data as AnimalData
	if _species != null:
		leash_m = _species.leash_m
		wander_radius_m = _species.wander_radius_m
		drops_enabled = false
	super._ready()
	if is_queued_for_deletion() or _species == null:
		return
	add_to_group(FAUNA_GROUP)
	if not _species.is_dangerous():
		remove_from_group(ENEMIES_GROUP)
	_can_walk = visual.has_animation(&"marche")
	_can_run = visual.has_animation(&"course")
	EventBus.enemy_damaged.connect(_on_enemy_damaged_nearby)
	EventBus.player_damaged.connect(_on_player_damaged_nearby)


## Les règles de l'île admettent l'espèce ici (liste fauna, régions sans animaux), jamais
## enemies_allowed : un animal n'est pas un Timere.
func _is_admitted() -> bool:
	var species_data := data as AnimalData
	return species_data != null and FaunaRules.allowed_at(self, species_data.id)


## Comportement et mode courants, pour les tests et le journal.
func mode_name() -> StringName:
	return MODE_NAMES[_mode]


## Vrai si l'animal est en train de quitter la scène (vaincu, débandé, renvoyé, envolé).
func is_leaving() -> bool:
	return _mode == Mode.LEAVE or _dissolving


## Vrai si l'animal est étourdi (sa charge a heurté un obstacle).
func is_stunned() -> bool:
	return _stun_left > 0.0


## Vrai si l'animal vole (un oiseau qui s'est envolé).
func is_flying() -> bool:
	return _flying


## L'animal s'en va (le moment de la journée ne lui convient plus) : il s'éloigne du joueur et
## disparaît, sans que ce soit une défaite.
func dismiss() -> void:
	if is_leaving() or _species == null:
		return
	var player := _find_target()
	var from := player.global_position if player != null else global_position - _facing
	_begin_leave(from, false)


## La meute se débande : l'animal fuit comme un vaincu, loin de celui qui a fui le premier.
func rout(from: Node3D) -> void:
	if is_leaving() or _species == null:
		return
	_begin_leave(
		from.global_position if is_instance_valid(from) else global_position - _facing, false
	)
	fled.emit(self)


func _fit_shapes(_factor: float) -> void:
	var radius := _species.body_radius_m if _species != null else 0.4
	super._fit_shapes(radius / 0.4)


func _physics_process(delta: float) -> void:
	if _flying:
		var move := _think(delta)
		_fly_height = minf(_fly_height + FLY_CLIMB * delta, FLY_MAX)
		visual.position.y = _fly_height
		global_position += Vector3(move.x, 0.0, move.z) * delta
		return
	super._physics_process(delta)


func _think(delta: float) -> Vector3:
	if _species == null or _dissolving:
		return Vector3.ZERO
	_mode_time += delta
	if _mode == Mode.LEAVE:
		return _leave(delta)
	if _stun_left > 0.0:
		_stun_left -= delta
		visual.play(&"degats")
		return Vector3.ZERO
	if _species.is_dangerous():
		return super._think(delta)
	return _think_passive(delta)


# --- Paisibles et fuyards ------------------------------------------------------------------------


func _think_passive(delta: float) -> Vector3:
	var player := _find_target()
	match _mode:
		Mode.GRAZE:
			return _graze(delta, player)
		Mode.ALERT:
			return _alert(delta, player)
		Mode.FLEE:
			return _flee(delta, player)
	return Vector3.ZERO


func _graze(delta: float, player: Node3D) -> Vector3:
	if player != null:
		var distance := _flat(player.global_position - global_position).length()
		var noise := _noise(player)
		if distance <= _species.flee_range_m * noise:
			_begin_flee(player.global_position)
			return Vector3.ZERO
		if _species.alert_range_m > 0.0 and distance <= _species.alert_range_m * noise:
			_set_mode(Mode.ALERT)
			return Vector3.ZERO
	return _idle(delta)


func _alert(_delta: float, player: Node3D) -> Vector3:
	visual.play(&"repos")
	if player == null:
		_set_mode(Mode.GRAZE)
		return Vector3.ZERO
	var to_player := _flat(player.global_position - global_position)
	if to_player.length_squared() > 0.0001:
		_face(to_player.normalized())
	var noise := _noise(player)
	if to_player.length() <= _species.flee_range_m * noise:
		_begin_flee(player.global_position)
	elif to_player.length() > _species.alert_range_m * noise and _mode_time >= ALERT_CALM_TIME:
		_set_mode(Mode.GRAZE)
	return Vector3.ZERO


func _flee(_delta: float, player: Node3D) -> Vector3:
	if player != null:
		var player_position := player.global_position
		if (
			_flat(player_position - global_position).length()
			< _flat(_flee_from - global_position).length()
		):
			_flee_from = player_position
	var away := _flat(global_position - _flee_from)
	var distance := away.length()
	away = away / distance if distance > 0.01 else -_facing
	if _species.vanish_s > 0.0 and _mode_time >= _species.vanish_s:
		_dissolve()
		return Vector3.ZERO
	if _mode_time > 1.0 and distance >= _species.calm_distance():
		_wander_target = origin
		_set_mode(Mode.GRAZE)
		return Vector3.ZERO
	var direction := away if _flying else FaunaNav.steer(_ground(), global_position, away)
	if direction == Vector3.ZERO:
		visual.play(&"repos")
		return Vector3.ZERO
	if not _flying:
		direction = _detour(direction)
	_face(direction)
	_startle_left = maxf(0.0, _startle_left - get_physics_process_delta_time())
	if _startle_left > 0.0 and not _species.startle_animation.is_empty():
		visual.play(_species.startle_animation)
	else:
		visual.play(_flee_animation())
	return direction * _species.escape_speed()


## Animation de la fuite : celle de l'espèce si la planche l'a, sinon la course.
func _flee_animation() -> StringName:
	if visual.has_animation(_species.flee_animation):
		return _species.flee_animation
	return &"course" if _can_run else &"marche"


## Le joueur est alerté ou menaçant : fuite loin de from_point (un oiseau s'envole).
func _begin_flee(from_point: Vector3) -> void:
	if _mode == Mode.LEAVE or _dissolving:
		return
	_flee_from = from_point
	_startle_left = _species.startle_s
	_set_mode(Mode.FLEE)
	if _species.flies:
		_start_flying()
	if _startle_left > 0.0 and not _species.startle_animation.is_empty():
		visual.play(_species.startle_animation, true)
	else:
		visual.play(_flee_animation(), true)


func _start_flying() -> void:
	_flying = true
	remove_from_group(ENEMIES_GROUP)
	hurtbox.set_deferred(&"monitorable", false)
	set_deferred(&"collision_layer", 0)
	set_deferred(&"collision_mask", 0)


## Facteur de bruit du joueur : il court (plus fort), reste immobile (plus discret) ou marche.
func _noise(player: Node3D) -> float:
	var body := player as CharacterBody3D
	if body == null:
		return 1.0
	var speed := _flat(body.velocity).length()
	if speed < STILL_SPEED:
		return _species.noise_still_factor
	if speed >= _species.run_speed_m_s:
		return _species.noise_run_factor
	return 1.0


## Errance : pause (qui broute ou se repose), puis un but praticable près du point de départ.
## Remplace celle d'Enemy : l'animation de pause est celle de l'espèce, la marche suit le sol.
func _idle(delta: float) -> Vector3:
	if _species.is_dangerous() and _can_hunt(false):
		_enter(State.CHASE)
		return Vector3.ZERO
	if _wander_pause > 0.0:
		_wander_pause -= delta
		visual.play(_pause_animation)
		return Vector3.ZERO
	_wander_clock += delta
	var to_goal := _flat(_wander_target - global_position)
	if not _can_walk or to_goal.length() < 0.3 or _wander_clock > WANDER_GIVE_UP:
		_pick_wander_target()
		return Vector3.ZERO
	var direction := FaunaNav.steer(_ground(), global_position, to_goal)
	if direction == Vector3.ZERO:
		_pick_wander_target()
		return Vector3.ZERO
	_face(direction)
	visual.play(&"marche")
	var returning := _flat(global_position - origin).length() > wander_radius_m + 1.0
	return _detour(direction) * _walk_speed() * (1.0 if returning else WANDER_SPEED_RATIO)


func _pick_wander_target() -> void:
	_wander_target = origin + _random_offset(wander_radius_m)
	if not FaunaNav.can_stand(_ground(), _wander_target):
		_wander_target = origin
	_wander_pause = randf_range(WANDER_PAUSE.x, WANDER_PAUSE.y)
	_wander_clock = 0.0
	var grazes := _species.graze_animation != &"repos" and randf() < _species.graze_ratio
	_pause_animation = _species.graze_animation if grazes else &"repos"


# --- Dangereux -----------------------------------------------------------------------------------


## Un animal de meute la rejoint dans la chasse : alertée, elle chasse jusqu'à PACK_ALERT_FACTOR
## fois la portée de repérage de chacun.
func _can_hunt(keep: bool) -> bool:
	if super._can_hunt(keep):
		if pack != null:
			pack.raise_alert()
		return true
	if pack == null or not pack.is_alert() or _target == null:
		return false
	if _player_down or _player_talking or _player_in_safe_zone():
		return false
	var distance := _flat(_target.global_position - global_position).length()
	return distance <= data.aggro_range_m * PACK_ALERT_FACTOR


## Meute : un seul porteur du jeton s'approche et attaque ; les autres tournent sur le cercle.
func _chase() -> Vector3:
	if pack == null or _species.ring_radius_m <= 0.0 or pack.active().size() < 2:
		return super._chase()
	if not _can_hunt(true):
		pack.release(self)
		pack.reset_ring()
		_enter(State.IDLE)
		return Vector3.ZERO
	if pack.request_attack(self):
		return super._chase()
	return _circle()


func _circle() -> Vector3:
	var point := pack.ring_point(
		self, _target.global_position, _species.ring_radius_m, _species.ring_speed
	)
	var to_point := _flat(point - global_position)
	var distance := to_point.length()
	if distance < 0.4:
		var to_player := _flat(_target.global_position - global_position)
		if to_player.length_squared() > 0.0001:
			_face(to_player.normalized())
		visual.play(&"repos")
		return Vector3.ZERO
	var direction := to_point / distance
	_face(direction)
	var running := distance > 2.5 and _can_run
	visual.play(&"course" if running else &"marche")
	var steer := (direction + _separation() * SEPARATION_WEIGHT).limit_length(1.0)
	return _detour(steer) * (_speed() if running else _walk_speed())


func _end_attack() -> void:
	super._end_attack()
	if pack != null:
		pack.release(self)


## La charge du sanglier : gratte le sol pendant la préparation (windup_animation), puis ligne
## droite ; contre un arbre ou un rocher il reste étourdi stun_s secondes.
func _prepare(attack: AttackData, direction: Vector3, distance: float) -> void:
	super._prepare(attack, direction, distance)
	if (
		_state == State.WINDUP
		and attack == _rush_attack
		and not _species.windup_animation.is_empty()
	):
		visual.play(_species.windup_animation)


func _rush(delta: float) -> Vector3:
	var blocked := is_on_wall() and _blocking_normal() != Vector3.ZERO
	var move := super._rush(delta)
	if blocked and _state == State.CHASE and _species.stun_s > 0.0:
		_stun_left = _species.stun_s
		_knockback = Vector3.ZERO
		return Vector3.ZERO
	return move


# --- Coups reçus, défaite et fuite ---------------------------------------------------------------


func _on_health_damaged(amount: int, source: Node3D) -> void:
	if is_instance_valid(source):
		_last_hit_from = source.global_position
		_has_hit_from = true
	super._on_health_damaged(amount, source)


func _on_hurtbox_hit_taken(attack: AttackData, source: Node3D) -> void:
	if attack == null or _species == null:
		return
	if _species.is_dangerous():
		if pack != null:
			pack.release(self)
		if _mode != Mode.LEAVE and not _dissolving:
			super._on_hurtbox_hit_taken(attack, source)
		else:
			_hit_feedback(attack, source)
		return
	# Un coup sur un paisible : l'éclair, un petit recul, puis il file (ou, si c'était le dernier
	# point de vie, _on_health_died l'a déjà fait fuir).
	_hit_feedback(attack, source)
	if is_instance_valid(source):
		var away := _flat(global_position - source.global_position)
		if away.length_squared() > 0.0001:
			_knockback = away.normalized() * attack.knockback
	if _mode != Mode.LEAVE and not _dissolving and is_instance_valid(source):
		_begin_flee(source.global_position)


## Vaincu, un animal s'enfuit : il ne meurt jamais à l'écran (docs/lore/ACTE1.md, 3.5).
func _on_health_died() -> void:
	if _mode == Mode.LEAVE or _dissolving:
		return
	_interrupt()
	_enter(State.IDLE)
	remove_from_group(ENEMIES_GROUP)
	remove_from_group(FAUNA_GROUP)
	hurtbox.set_deferred(&"monitorable", false)
	set_deferred(&"collision_layer", 0)
	var from := _last_hit_from if _has_hit_from else global_position - _facing
	_begin_leave(from, true)
	defeated.emit(self, 0)
	fled.emit(self)
	if pack != null:
		pack.report_fled(self)


func _begin_leave(from_point: Vector3, staggers: bool) -> void:
	_interrupt()
	telegraph.clear()
	visual.scale = Vector3.ONE * _base_scale
	_flee_from = from_point
	_stagger_left = STAGGER_TIME if staggers else 0.0
	_stun_left = 0.0
	remove_from_group(ENEMIES_GROUP)
	_set_mode(Mode.LEAVE)
	if _species.flies:
		_start_flying()
	if pack != null:
		pack.release(self)


func _leave(_delta: float) -> Vector3:
	if _stagger_left > 0.0:
		_stagger_left -= get_physics_process_delta_time()
		visual.play(&"degats")
		return Vector3.ZERO
	var away := _flat(global_position - _flee_from)
	var distance := away.length()
	away = away / distance if distance > 0.01 else -_facing
	if _mode_time >= _species.defeat_flee_s or distance >= _species.defeat_flee_m:
		_dissolve()
		return Vector3.ZERO
	var direction := away if _flying else FaunaNav.steer(_ground(), global_position, away)
	if direction == Vector3.ZERO:
		direction = away
	_face(direction)
	visual.play(_flee_animation() if _species.flies else (&"course" if _can_run else &"marche"))
	return direction * _speed()


## L'animal disparaît : il rétrécit vite, puis il est libéré (ni cadavre, ni sang).
func _dissolve() -> void:
	if _dissolving:
		return
	_dissolving = true
	remove_from_group(ENEMIES_GROUP)
	remove_from_group(FAUNA_GROUP)
	hurtbox.set_deferred(&"monitorable", false)
	set_deferred(&"collision_layer", 0)
	var tween := create_tween()
	tween.tween_property(visual, ^"scale", Vector3.ZERO, DISSOLVE_TIME)
	tween.tween_callback(queue_free)


# --- Bruit du combat -----------------------------------------------------------------------------


func _on_enemy_damaged_nearby(enemy: Node3D, _amount: int) -> void:
	if enemy != self and is_instance_valid(enemy):
		_hear(enemy.global_position)


func _on_player_damaged_nearby(_amount: int, _source: Node3D) -> void:
	var player := _find_target()
	if player != null:
		_hear(player.global_position)


## Un combat à portée d'oreille alarme un animal qui n'est pas dangereux.
func _hear(at: Vector3) -> void:
	if _species == null or _species.is_dangerous() or _species.combat_noise_m <= 0.0:
		return
	if _mode == Mode.FLEE or _mode == Mode.LEAVE or _dissolving:
		return
	if _flat(at - global_position).length() <= _species.combat_noise_m:
		_begin_flee(at)


func _set_mode(new_mode: Mode) -> void:
	_mode = new_mode
	_mode_time = 0.0


func _ground() -> MapGround:
	if not _ground_known:
		_ground_known = true
		_ground_cache = FaunaNav.ground_of(self)
	return _ground_cache
