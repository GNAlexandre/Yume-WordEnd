class_name Enemy
extends CharacterBody3D
## Ennemi générique piloté par ses données (PLAN.md sections 3 et 4, jeu.js l. 940-1050).
## Propriétaire : L5.
##
## Structure figée de enemy.tscn : CollisionShape3D, Visual (CharacterVisual), Health,
## Hurtbox (équipe &"enemy"), Hitbox (équipe &"enemy"). Groupe "enemies" tant qu'il est vivant.
## Machine à états : idle (errance autour de origin, retour au besoin) → chase (droit vers le
## joueur dans aggro_range_m, séparation légère : les ennemis ne se bloquent pas entre eux) →
## attack à portée (morsure / fouet ; la Hitbox, tournée vers la cible, n'est active que sur
## les images « coup » reçues par Visual.frame_changed) → hurt (recul) → dead (animation mort,
## sortie du groupe, enemy_killed, drops, disparition après corpse_time). Coureur (data.rush) :
## rush en ligne droite dès la portée de son attaque sans dégâts (8 m), puis morsure. Stoic :
## ni recul ni hurt, sauf sous une attaque qui traverse (onde). La poursuite cesse si le joueur
## est mort, dans une zone sûre (WorldManager.is_zone_safe(current_zone())) ou à plus de
## leash_m de origin : l'ennemi rentre chez lui. Portée d'une attaque : AttackData.range_m ×
## data.scale devant le corps (capsule, Hurtbox et Hitbox sont aussi mises à l'échelle) ; la
## distance de déclenchement du rush ne l'est pas. Un obstacle du décor heurté de face
## (poteau, tronc) est longé au lieu de bloquer la poursuite.
##
## (H7, lisibilité en vue fixe) Avant chaque coup et chaque charge, état windup : le Timere se
## ramasse sur la première image de l'attaque, un éclat brille au-dessus de lui et la zone exacte
## de sa Hitbox (ou le couloir de sa charge) se dessine au sol (Telegraph) pendant
## AttackData.windup × EnemyData.windup_scale ; la préparation commence dès que la recharge en
## reste moins que cela, si bien que la cadence des coups au contact ne change pas. De près, il
## vient par les côtés de l'écran (FLANK_MIN_DEG) plutôt que pile au nord ou au sud du joueur,
## où les sprites se cachent ; les Timeres s'écartent davantage dans la profondeur de l'écran
## (SEPARATION_DEPTH). Touché : éclair, éclats, arrêt sur image (AttackData.hitstop), poussière
## au recul. Ombre nette au sol (GroundShadow), teinte du corps (EnemyData.tint), traînée du
## bondissant ; rien ne dépend du dessin de la planche.

## Émis à la mort, avec EventBus.enemy_killed : le WaveDirector compte ainsi ses ennemis.
signal defeated(enemy: Enemy, points: int)

enum State { IDLE, CHASE, RUSH, ATTACK, HURT, DEAD, WINDUP }

const PICKUP_SCENE := preload("res://src/items/pickup.tscn")
const TelegraphScript := preload("res://src/enemies/telegraph.gd")
const PLAYER_GROUP := &"player"
const ENEMIES_GROUP := &"enemies"
const STATE_NAMES: Array[StringName] = [
	&"idle", &"chase", &"rush", &"attack", &"hurt", &"dead", &"windup"
]
## Recharge après une attaque : AttackData.cooldown × [0,7 ; 1,3] (jeu.js : 0,8 à 1,5 s).
const COOLDOWN_JITTER := Vector2(0.7, 1.3)
## Recharge à l'apparition (jeu.js : 0,2 à 0,8 s).
const FIRST_COOLDOWN := Vector2(0.2, 0.8)
## Durée de hurt : celle de l'animation degats, bornée (jeu.js : min(0,45 s ; degats)).
const HURT_TIME := Vector2(0.35, 0.45)
## Durée d'une animation absente de la planche (s).
const DEFAULT_ANIMATION_TIME := 0.5
## Décroissance du recul, par seconde (jeu.js : × 0,86 par image à 60 ips).
const KNOCKBACK_DECAY := 9.0
## Une poursuite continue jusqu'à aggro_range_m × ce facteur.
const CHASE_KEEP_FACTOR := 1.5
## Errance : fraction de la vitesse de marche, pause entre deux buts, abandon d'un but (s).
const WANDER_SPEED_RATIO := 0.4
const WANDER_PAUSE := Vector2(1.0, 3.0)
const WANDER_GIVE_UP := 8.0
## Séparation entre ennemis : écart voulu (m, à l'échelle 1) et poids dans la direction.
const SEPARATION_DISTANCE := 1.1
const SEPARATION_WEIGHT := 1.2
## Le rush ne part que si la cible est au-delà de la portée d'attaque + cet écart (m), et
## dépasse le point visé de RUSH_OVERSHOOT (m).
const RUSH_MIN_GAP := 1.0
const RUSH_OVERSHOOT := 1.5
## L'ennemi s'approche jusqu'à cette fraction de sa plus longue portée.
const APPROACH_RATIO := 0.85
## Contournement : un mur du décor est « de face » quand le cosinus entre la direction voulue
## et l'opposé de sa normale dépasse ce seuil (en deçà, move_and_slide glisse déjà le long) ;
## l'ennemi le longe alors pendant DETOUR_TIME s avant de reprendre sa direction.
const DETOUR_HEAD_ON := 0.8
const DETOUR_TIME := 0.5
## Hauteur du centre de la Hitbox à l'échelle 1 (m) et rayon minimal de sa sphère.
const HITBOX_HEIGHT := 0.5
const HITBOX_MIN_RADIUS := 0.2
## Retiré s'il tombe à plus de FALL_LIMIT m sous son origine (hors du monde).
const FALL_LIMIT := 30.0
## Le cadavre rétrécit pendant SHRINK_TIME s avant de disparaître.
const SHRINK_TIME := 0.3
## (H7) De près (à moins de FLANK_RANGE m), le Timere s'approche par les côtés : il vise un point
## à au moins FLANK_MIN_DEG de l'axe nord-sud du joueur (l'épée, 90°, l'atteint encore).
const FLANK_MIN_DEG := 30.0
const FLANK_RANGE := 4.0
## (H7) Dans la séparation, un écart nord-sud compte pour SEPARATION_DEPTH × sa longueur : la
## caméra inclinée l'écrase à l'écran, deux Timeres l'un derrière l'autre s'y chevauchent.
const SEPARATION_DEPTH := 0.7
## (H7) Préparation : élargi de x, tassé de y à la fin (fraction de l'échelle).
const WINDUP_SQUASH := Vector2(0.1, 0.14)
## (H7) Éclair d'un Timere touché (s), éclats et poussière (taille × 96 px/m).
const FLASH_TIME := 0.09
const IMPACT_SIZE := 1.0
const DUST_SIZE := 1.2
## (H7) Recul à partir duquel la poussière se soulève (m/s).
const DUST_KNOCKBACK := 2.0
## (H7) Traînée du bondissant pendant sa charge : poussière et images rémanentes (s).
const RUSH_DUST_EVERY := 0.1
const RUSH_GHOST_EVERY := 0.06
const GHOST_COLOR := Color(1.0, 0.72, 0.5, 0.5)
## (H7) Hauteur du centre de la Hurtbox (m, à l'échelle 1) : là où naissent les éclats.
const HURT_CENTER := 0.65
## (H7) Rayon de l'ombre nette : celui du corps (capsule) un peu élargi (m, à l'échelle 1).
const SHADOW_MARGIN := 0.08
## (H7) Éclat de préparation : à cette fraction de la hauteur du corps (la tête), devant le
## marqueur de cible du HUD qui se pose plus haut.
const GLINT_HEIGHT := 0.85

## Côté préféré du prochain Timere créé : il alterne, pour que deux Timeres arrivés en file
## partent l'un à gauche, l'autre à droite (la parité des identifiants d'objets ne le garantit
## pas : elle dépend de tout ce qui a été créé avant).
static var _next_flank_side: float = 1.0

## Type d'ennemi (data/enemies/*.tres).
@export var data: EnemyData
## Lâche data.drops à sa mort (faux pour les ennemis d'une arène).
@export var drops_enabled: bool = true
## Poursuit le joueur où qu'il soit, sans laisse (ennemis d'une arène).
@export var always_chase: bool = false
## Laisse : abandonne la poursuite si le joueur est à plus de leash_m de origin (0 = aucune).
@export var leash_m: float = 20.0
## Rayon d'errance autour de origin (m).
@export var wander_radius_m: float = 3.0
## Bonus de vitesse de vague (WaveDirector.speed_multiplier).
@export var speed_multiplier: float = 1.0
## PV ajoutés à data.max_hp (WaveDirector.hp_bonus : Normal dès la vague 6).
@export var bonus_hp: int = 0
## Délai entre la mort et la disparition (s).
@export var corpse_time: float = 2.2

## Point d'origine (position à l'entrée dans l'arbre) : errance, laisse, retour.
var origin: Vector3 = Vector3.ZERO

var _state: State = State.IDLE
var _state_time: float = 0.0
var _target: Node3D
var _player_down: bool = false
## Le joueur est en conversation (EventBus.dialogue_started → dialogue_ended) : on ne le chasse
## pas. Sinon une mort en pleine réplique le faisait réapparaître figé, la boîte encore ouverte.
var _player_talking: bool = false
var _zone_checked: bool = false
var _zone_seen: StringName = &""
var _zone_safe: bool = false
var _melee: Array[AttackData] = []
var _rush_attack: AttackData
var _attack: AttackData
var _attack_time: float = 0.0
var _hit_started: bool = false
var _cooldown: float = 0.0
var _rush_cooldown: float = 0.0
var _rush_dir: Vector3 = Vector3.FORWARD
var _rush_left: float = 0.0
var _facing: Vector3 = Vector3.FORWARD
var _knockback: Vector3 = Vector3.ZERO
var _wander_target: Vector3 = Vector3.ZERO
var _wander_pause: float = 0.0
var _wander_clock: float = 0.0
var _detour_side: float = 0.0
var _detour_left: float = 0.0
var _detour_direction: Vector3 = Vector3.ZERO
var _body_radius: float = 0.4
var _hurt_time: float = 0.4
var _shrinking: bool = false
var _sheet: Dictionary = {}
var _hitbox_shape: SphereShape3D
var _windup_attack: AttackData
var _windup_time: float = 0.0
var _rush_distance: float = 0.0
var _flank_side: float = 0.0
var _hitstop_left: float = 0.0
var _fx_clock: float = 0.0
var _ghost_clock: float = 0.0
var _base_scale: float = 1.0
var _sprite: AnimatedSprite3D
var _shadow: MeshInstance3D

@onready var visual: CharacterVisual = $Visual
@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Hitbox
@onready var telegraph: TelegraphScript = $Telegraph
@onready var hit_flash: HitFlash = $HitFlash
@onready var _body_shape: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	origin = global_position
	hitbox.source = self
	_sprite = visual.get_node_or_null(^"Sprite") as AnimatedSprite3D
	if data != null:
		health.max_hp = data.max_hp + bonus_hp
		visual.set_skin(data.visual)
		_base_scale = data.scale
		visual.scale = Vector3.ONE * data.scale
		_sheet = SheetLoader.read_sheet(data.visual)
		_read_attacks()
		_fit_shapes(data.scale)
		if _sprite != null:
			_sprite.modulate = data.tint
		telegraph.glint_size *= maxf(1.0, data.scale)
	_shadow = CombatFx.make_shadow(_body_radius + SHADOW_MARGIN * _base_scale)
	add_child(_shadow)
	hit_flash.bind(_sprite)
	_flank_side = _next_flank_side
	_next_flank_side = -_next_flank_side
	_hurt_time = clampf(_animation_time(&"degats"), HURT_TIME.x, HURT_TIME.y)
	_cooldown = randf_range(FIRST_COOLDOWN.x, FIRST_COOLDOWN.y)
	health.damaged.connect(_on_health_damaged)
	health.died.connect(_on_health_died)
	hurtbox.hit_taken.connect(_on_hurtbox_hit_taken)
	visual.frame_changed.connect(_on_visual_frame_changed)
	hitbox.hit_landed.connect(_on_hitbox_hit_landed)
	EventBus.player_died.connect(_on_player_died)
	EventBus.player_respawned.connect(_on_player_respawned)
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_ended.connect(_on_dialogue_ended)
	_enter(State.IDLE)
	EventBus.enemy_spawned.emit(self, enemy_id())


## Identifiant du type (EnemyData.id), &"" sans données.
func enemy_id() -> StringName:
	return data.id if data != null else &""


## État courant : &"idle", &"chase", &"rush", &"attack", &"hurt" ou &"dead".
func state() -> StringName:
	return STATE_NAMES[_state]


func is_dead() -> bool:
	return _state == State.DEAD


## Attaque en cours (null hors de l'état attack).
func current_attack() -> AttackData:
	return _attack if _state == State.ATTACK else null


## (H7) Attaque (ou charge) en préparation (null hors de l'état windup).
func prepared_attack() -> AttackData:
	return _windup_attack if _state == State.WINDUP else null


## (H7) Durée de préparation de attack pour ce Timere (s) : windup × windup_scale.
func windup_duration(attack: AttackData) -> float:
	if attack == null:
		return 0.0
	return maxf(0.0, attack.windup) * (data.windup_scale if data != null else 1.0)


## (H7) Arrêt sur image restant (s) : le corps ne bouge pas, son recul attend.
func hitstop_left() -> float:
	return _hitstop_left


## Vitesse de recul courante (m/s, horizontale).
func knockback() -> Vector3:
	return _knockback


## Portée de attack devant le corps : AttackData.range_m × data.scale.
func attack_reach(attack: AttackData) -> float:
	return attack.range_m * (data.scale if data != null else 1.0)


## Distance (centre à centre, horizontale) à laquelle attack peut partir.
func engage_distance(attack: AttackData) -> float:
	return _body_radius + attack_reach(attack)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	var move := Vector3.ZERO
	if data != null:
		move = _think(delta)
	if _hitstop_left > 0.0:
		# Arrêt sur image : le corps attend, son recul partira juste après (même distance).
		_hitstop_left = maxf(0.0, _hitstop_left - delta)
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		velocity.x = move.x + _knockback.x
		velocity.z = move.z + _knockback.z
		_knockback *= exp(-KNOCKBACK_DECAY * delta)
	move_and_slide()
	if global_position.y < origin.y - FALL_LIMIT:
		queue_free()


## Une image de la machine à états ; renvoie la vitesse horizontale voulue.
func _think(delta: float) -> Vector3:
	_state_time += delta
	_cooldown = maxf(0.0, _cooldown - delta)
	_rush_cooldown = maxf(0.0, _rush_cooldown - delta)
	match _state:
		State.IDLE:
			return _idle(delta)
		State.CHASE:
			return _chase()
		State.RUSH:
			return _rush(delta)
		State.WINDUP:
			return _windup()
		State.ATTACK:
			if _state_time >= _attack_time:
				_end_attack()
				_enter(State.CHASE)
		State.HURT:
			if _state_time >= _hurt_time:
				_enter(State.CHASE)
		State.DEAD:
			_corpse()
	return Vector3.ZERO


func _idle(delta: float) -> Vector3:
	if _can_hunt(false):
		_enter(State.CHASE)
		return Vector3.ZERO
	if _wander_pause > 0.0:
		_wander_pause -= delta
		visual.play(&"repos")
		return Vector3.ZERO
	_wander_clock += delta
	var to_goal := _flat(_wander_target - global_position)
	if to_goal.length() < 0.3 or _wander_clock > WANDER_GIVE_UP:
		_wander_target = origin + _random_offset(wander_radius_m)
		_wander_pause = randf_range(WANDER_PAUSE.x, WANDER_PAUSE.y)
		_wander_clock = 0.0
		return Vector3.ZERO
	var direction := to_goal.normalized()
	_face(direction)
	visual.play(&"marche")
	var returning := _flat(global_position - origin).length() > wander_radius_m + 1.0
	return _detour(direction) * _walk_speed() * (1.0 if returning else WANDER_SPEED_RATIO)


func _chase() -> Vector3:
	if not _can_hunt(true):
		_enter(State.IDLE)
		return Vector3.ZERO
	var to_target := _flat(_target.global_position - global_position)
	var distance := to_target.length()
	var direction := to_target / distance if distance > 0.001 else _facing
	_face(direction)
	if _cooldown <= _melee_lead():
		var attack := _choose_attack(distance)
		if attack != null:
			_prepare(attack, direction, distance)
			return Vector3.ZERO
	if _can_rush(distance):
		_prepare(_rush_attack, direction, distance)
		return Vector3.ZERO
	var approach := _approach_direction(to_target, distance)
	if distance > _reach_distance() * APPROACH_RATIO:
		visual.play(&"marche")
		var steer := (approach + _separation() * SEPARATION_WEIGHT).limit_length(1.0)
		return _detour(steer) * _walk_speed()
	visual.play(&"repos")
	# À portée, en attendant sa recharge : il glisse vers un côté de l'écran et s'écarte des autres.
	var drift := _separation().limit_length(1.0) + _flank_drift(to_target, distance)
	return drift.limit_length(1.0) * _walk_speed() * WANDER_SPEED_RATIO


func _rush(delta: float) -> Vector3:
	_target = _find_target()
	if _target != null and not _player_down and _cooldown <= 0.0:
		var to_target := _flat(_target.global_position - global_position)
		var attack := _choose_attack(to_target.length())
		if attack != null:
			_end_rush()
			_start_attack(attack, to_target.normalized())
			return Vector3.ZERO
	_rush_left -= _speed() * delta
	if _rush_left <= 0.0 or is_on_wall():
		_end_rush()
		_enter(State.CHASE)
		return Vector3.ZERO
	_face(_rush_dir)
	_rush_trail(delta)
	return _rush_dir * _speed()


## Le joueur peut-il être (encore, si keep) poursuivi ? Met _target à jour.
func _can_hunt(keep: bool) -> bool:
	_target = _find_target()
	if _target == null or _player_down or _player_talking or _player_in_safe_zone():
		return false
	if always_chase:
		return true
	var target_position := _target.global_position
	if leash_m > 0.0 and _flat(target_position - origin).length() > leash_m:
		return false
	var aggro := data.aggro_range_m * (CHASE_KEEP_FACTOR if keep else 1.0)
	return _flat(target_position - global_position).length() <= aggro


func _find_target() -> Node3D:
	if is_instance_valid(_target) and _target.is_inside_tree():
		return _target
	return get_tree().get_first_node_in_group(PLAYER_GROUP) as Node3D


## Zone sûre : celle où se trouve le joueur selon WorldManager (WorldManager.is_zone_safe),
## relue seulement quand la zone courante change.
func _player_in_safe_zone() -> bool:
	var zone_id := WorldManager.current_zone()
	if not _zone_checked or zone_id != _zone_seen:
		_zone_checked = true
		_zone_seen = zone_id
		_zone_safe = WorldManager.is_zone_safe(zone_id)
	return _zone_safe


## Attaque au contact possible à distance (jeu.js : le fouet quand la morsure ne porte pas,
## sinon l'une ou l'autre au hasard).
func _choose_attack(distance: float) -> AttackData:
	var usable: Array[AttackData] = []
	for attack: AttackData in _melee:
		if distance <= engage_distance(attack):
			usable.append(attack)
	if usable.is_empty():
		return null
	return usable[randi() % usable.size()]


func _can_rush(distance: float) -> bool:
	return (
		_rush_attack != null
		and _rush_cooldown <= 0.0
		and distance <= _rush_attack.range_m
		and distance > _reach_distance() + RUSH_MIN_GAP
	)


## Plus longue préparation des attaques au contact : la préparation commence quand la recharge
## n'en est plus qu'à cette durée (la cadence des coups reste celle de la recharge).
func _melee_lead() -> float:
	var lead := 0.0
	for attack: AttackData in _melee:
		lead = maxf(lead, windup_duration(attack))
	return lead


## Prépare attack (coup au contact ou charge) : état windup, ou l'attaque tout de suite si elle
## n'a pas de préparation. La préparation dure au moins windup_duration(attack), et au moins le
## reste de la recharge.
func _prepare(attack: AttackData, direction: Vector3, distance: float) -> void:
	var rushing := attack == _rush_attack
	var duration := windup_duration(attack)
	if not rushing:
		duration = maxf(duration, _cooldown)
	if duration <= 0.0:
		if rushing:
			_start_rush(direction, distance)
		else:
			_start_attack(attack, direction)
		return
	_enter(State.WINDUP)
	_windup_attack = attack
	_windup_time = duration
	_face(direction)
	var glint := Vector3.UP * _body_height() * GLINT_HEIGHT
	if rushing:
		_rush_dir = direction
		_rush_distance = distance
		telegraph.rush(direction, distance + RUSH_OVERSHOOT, 2.0 * _body_radius, glint)
	else:
		_show_strike_zone(attack, glint)
	visual.show_frame(attack.animation, 0)
	_pose(0.0)


## Une image de préparation : suit la cible (coup au contact), signes, posture ; puis l'attaque.
func _windup() -> Vector3:
	var rushing := _windup_attack == _rush_attack
	if not rushing:
		_target = _find_target()
		if _target == null or _player_down or _player_in_safe_zone():
			_cancel_windup()
			_enter(State.IDLE)
			return Vector3.ZERO
		var to_target := _flat(_target.global_position - global_position)
		if to_target.length_squared() > 0.0001:
			_face(to_target.normalized())
		_show_strike_zone(_windup_attack, Vector3.UP * _body_height() * GLINT_HEIGHT)
	var ratio := clampf(_state_time / _windup_time, 0.0, 1.0) if _windup_time > 0.0 else 1.0
	telegraph.set_progress(ratio)
	_pose(ratio)
	if _state_time < _windup_time:
		return Vector3.ZERO
	var attack := _windup_attack
	if rushing:
		_start_rush(_rush_dir, _rush_distance)
		return _rush_dir * _speed()
	_start_attack(attack, _facing)
	return Vector3.ZERO


## Préparation interrompue (dégâts, mort) : la recharge court comme après l'attaque.
func _cancel_windup() -> void:
	if _windup_attack == null:
		return
	if _windup_attack == _rush_attack:
		_end_rush()
	else:
		_start_cooldown(_windup_attack)
	_windup_attack = null


func _show_strike_zone(attack: AttackData, glint: Vector3) -> void:
	var geometry := _hitbox_geometry(attack, _facing)
	telegraph.strike(geometry[0], geometry[1], glint)


## Posture de préparation : le corps se ramasse (élargi, tassé) jusqu'au coup.
func _pose(ratio: float) -> void:
	var eased := ratio * ratio * (3.0 - 2.0 * ratio)
	var squash := Vector3(1.0 + WINDUP_SQUASH.x * eased, 1.0 - WINDUP_SQUASH.y * eased, 1.0)
	visual.scale = squash * _base_scale


## Hauteur du corps à l'échelle (planche : SkinData.height_m).
func _body_height() -> float:
	var height := data.visual.height_m if data != null and data.visual != null else 1.0
	return height * _base_scale


func _start_rush(direction: Vector3, distance: float) -> void:
	_enter(State.RUSH)
	_rush_dir = direction
	_rush_left = distance + RUSH_OVERSHOOT
	_face(direction)
	visual.play(_rush_attack.animation)


func _end_rush() -> void:
	if _rush_attack != null:
		_rush_cooldown = _rush_attack.cooldown


func _start_attack(attack: AttackData, direction: Vector3) -> void:
	_enter(State.ATTACK)
	_attack = attack
	_hit_started = false
	_attack_time = attack.duration if attack.duration > 0.0 else _animation_time(attack.animation)
	_face(direction)
	_aim_hitbox(attack, _facing)
	visual.play(attack.animation, true)


func _end_attack() -> void:
	hitbox.deactivate()
	if _attack != null:
		_start_cooldown(_attack)


func _start_cooldown(attack: AttackData) -> void:
	var jitter := randf_range(COOLDOWN_JITTER.x, COOLDOWN_JITTER.y)
	_cooldown = attack.cooldown * jitter * data.cooldown_scale


## Tourne la Hitbox vers la cible : sphère qui couvre [corps ; corps + portée] devant l'ennemi.
func _aim_hitbox(attack: AttackData, direction: Vector3) -> void:
	var geometry := _hitbox_geometry(attack, direction)
	if _hitbox_shape != null:
		_hitbox_shape.radius = geometry[1]
	hitbox.position = geometry[0] + Vector3.UP * HITBOX_HEIGHT * data.scale
	hitbox.attack = attack


## Centre au sol (local) et rayon de la sphère de la Hitbox de attack tournée vers direction : ce
## que la zone de préparation montre au sol, au centimètre près.
func _hitbox_geometry(attack: AttackData, direction: Vector3) -> Array:
	var reach := attack_reach(attack)
	var radius := maxf(reach * 0.5, HITBOX_MIN_RADIUS)
	return [direction * (_body_radius + reach - radius), radius]


## Interrompt une préparation, une attaque ou un rush (la recharge court quand même).
func _interrupt() -> void:
	if _state == State.ATTACK:
		_end_attack()
	elif _state == State.RUSH:
		_end_rush()
	elif _state == State.WINDUP:
		_cancel_windup()
	hitbox.deactivate()


func _corpse() -> void:
	if not _shrinking and _state_time >= corpse_time - SHRINK_TIME:
		_shrinking = true
		create_tween().tween_property(visual, ^"scale", Vector3.ZERO, SHRINK_TIME)
	if _state_time >= corpse_time:
		queue_free()


func _spawn_drops() -> void:
	var parent := get_parent()
	if data == null or parent == null:
		return
	for item_id: StringName in data.drops:
		if randf() >= data.drops[item_id]:
			continue
		var pickup := PICKUP_SCENE.instantiate() as Pickup
		pickup.item_id = item_id
		pickup.quantity = 1
		pickup.persistent = false
		pickup.name = "drop_%s" % item_id
		var parent_3d := parent as Node3D
		pickup.position = parent_3d.to_local(global_position) if parent_3d else global_position
		parent.add_child(pickup, true)


func _enter(new_state: State) -> void:
	if _state == State.WINDUP and new_state != State.WINDUP:
		telegraph.clear()
		visual.scale = Vector3.ONE * _base_scale
	_state = new_state
	_state_time = 0.0
	_detour_left = 0.0
	_detour_side = 0.0
	if new_state == State.IDLE:
		_wander_target = origin
		_wander_pause = 0.0
		_wander_clock = 0.0


func _read_attacks() -> void:
	for attack: AttackData in data.attacks:
		if attack == null:
			continue
		if data.rush and attack.damage <= 0 and _rush_attack == null:
			_rush_attack = attack
		else:
			_melee.append(attack)
	if not _melee.is_empty():
		hitbox.attack = _melee[0]


## Met la capsule du corps, la Hurtbox et la Hitbox à l'échelle du type (formes dupliquées : la
## ressource d'une scène est partagée par toutes ses instances).
func _fit_shapes(factor: float) -> void:
	var body := _body_shape.shape as CapsuleShape3D
	if body != null:
		body = body.duplicate() as CapsuleShape3D
		body.radius *= factor
		body.height *= factor
		_body_shape.shape = body
		_body_shape.position.y = body.height * 0.5
		_body_radius = body.radius
	var hurt_shape := hurtbox.get_node_or_null(^"CollisionShape3D") as CollisionShape3D
	if hurt_shape != null and hurt_shape.shape is CapsuleShape3D:
		var capsule := hurt_shape.shape.duplicate() as CapsuleShape3D
		capsule.radius *= factor
		capsule.height *= factor
		hurt_shape.shape = capsule
		hurt_shape.position.y *= factor
	var hit_shape := hitbox.get_node_or_null(^"CollisionShape3D") as CollisionShape3D
	if hit_shape != null:
		_hitbox_shape = SphereShape3D.new()
		hit_shape.shape = _hitbox_shape


## Durée d'une animation de la planche (images / ips), lue dans le JSON du visuel.
func _animation_time(anim: StringName) -> float:
	var animations: Variant = _sheet.get("animations", {})
	if animations is Dictionary:
		var info: Variant = (animations as Dictionary).get(String(anim))
		if info is Dictionary:
			var fps := float((info as Dictionary).get("ips", 0))
			var images: Variant = (info as Dictionary).get("images", [])
			if fps > 0.0 and images is Array and not (images as Array).is_empty():
				return (images as Array).size() / fps
	return DEFAULT_ANIMATION_TIME


func _speed() -> float:
	return data.speed * speed_multiplier


func _walk_speed() -> float:
	return (data.walk_speed if data.walk_speed > 0.0 else data.speed) * speed_multiplier


## Plus longue distance d'engagement des attaques au contact.
func _reach_distance() -> float:
	var reach := _body_radius
	for attack: AttackData in _melee:
		reach = maxf(reach, engage_distance(attack))
	return reach


## Poussée qui écarte des autres ennemis vivants (ils ne se bloquent pas physiquement). (H7) Un
## écart nord-sud compte pour SEPARATION_DEPTH × sa longueur (deux Timeres l'un derrière l'autre
## se chevauchent à l'écran) et la poussée penche vers les côtés de l'écran.
func _separation() -> Vector3:
	var push := Vector3.ZERO
	var spacing := SEPARATION_DISTANCE * data.scale
	for node: Node in get_tree().get_nodes_in_group(ENEMIES_GROUP):
		var other := node as Node3D
		if other == null or other == self:
			continue
		var offset := _flat(global_position - other.global_position)
		var seen := Vector3(offset.x, 0.0, offset.z * SEPARATION_DEPTH)
		var distance := seen.length()
		if distance >= spacing:
			continue
		if distance < 0.001:
			seen = Vector3.RIGHT.rotated(Vector3.UP, float(get_instance_id() % 628) * 0.01)
		elif absf(seen.x) < 0.25 * spacing:
			# Pile l'un derrière l'autre : l'un part à gauche, l'autre à droite.
			var side := 1.0 if get_instance_id() > other.get_instance_id() else -1.0
			seen.x += 0.25 * spacing * side
		push += seen.normalized() * (1.0 - distance / spacing)
	return push


## (H7) Direction d'approche : droit sur la cible de loin ; à moins de FLANK_RANGE m, vers un
## point à au moins FLANK_MIN_DEG de l'axe nord-sud de la cible, du côté où le Timere se trouve
## déjà (ou de son côté préféré s'il est pile dans l'axe).
func _approach_direction(to_target: Vector3, distance: float) -> Vector3:
	var direct := to_target / distance if distance > 0.001 else _facing
	if distance > FLANK_RANGE or distance < 0.001:
		return direct
	var to_spot := _flank_spot(to_target, distance) - global_position
	to_spot.y = 0.0
	if to_spot.length_squared() < 0.0001:
		return direct
	# Plus il est proche, plus il vise le côté ; au loin, il fond droit sur la cible.
	var weight := clampf((FLANK_RANGE - distance) / (FLANK_RANGE * 0.5), 0.0, 1.0)
	return direct.lerp(to_spot.normalized(), weight).normalized()


## (H7) Point d'arrivée de côté (global) : à la distance d'approche de la cible, hors du cône
## nord-sud de FLANK_MIN_DEG.
func _flank_spot(to_target: Vector3, distance: float) -> Vector3:
	var away := -to_target / distance
	var side := signf(away.x)
	if absf(away.x) < 0.05:
		side = _flank_side
	var angle := atan2(absf(away.x), absf(away.z))
	var min_angle := deg_to_rad(FLANK_MIN_DEG)
	if angle < min_angle:
		var north := -1.0 if away.z < 0.0 else 1.0
		away = Vector3(side * sin(min_angle), 0.0, north * cos(min_angle))
	var target := global_position + to_target
	return target + away * _reach_distance() * APPROACH_RATIO


## (H7) À portée, en attendant : petit pas vers le point de côté s'il en est loin.
func _flank_drift(to_target: Vector3, distance: float) -> Vector3:
	if distance < 0.001:
		return Vector3.ZERO
	var to_spot := _flank_spot(to_target, distance) - global_position
	to_spot.y = 0.0
	if to_spot.length() < 0.15:
		return Vector3.ZERO
	return to_spot.normalized() * 0.6


## Contourne un obstacle du décor heurté de face (poteau du panneau, tronc, rocher) au lieu de
## rester bloqué derrière : longe le mur pendant DETOUR_TIME s, toujours du même côté jusqu'au
## prochain changement d'état. Le joueur et les corps mobiles ne sont pas des obstacles.
func _detour(direction: Vector3) -> Vector3:
	var length := direction.length()
	if length < 0.001:
		return direction
	var normal := _blocking_normal()
	if normal != Vector3.ZERO and direction.dot(-normal) >= DETOUR_HEAD_ON * length:
		var tangent := normal.cross(Vector3.UP)
		if _detour_side == 0.0:
			_detour_side = 1.0 if tangent.dot(direction) >= 0.0 else -1.0
		_detour_direction = tangent * _detour_side
		_detour_left = DETOUR_TIME
	if _detour_left <= 0.0:
		return direction
	_detour_left -= get_physics_process_delta_time()
	return _detour_direction * length


## Normale horizontale du mur du décor statique heurté au dernier move_and_slide (ZERO sinon) ;
## le sol et les pentes praticables (jusqu'à floor_max_angle) n'en sont pas.
func _blocking_normal() -> Vector3:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		if collision.get_collider() is StaticBody3D and collision.get_angle() > floor_max_angle:
			var normal := _flat(collision.get_normal())
			if normal.length_squared() > 0.0001:
				return normal.normalized()
	return Vector3.ZERO


func _face(direction: Vector3) -> void:
	if direction.length_squared() < 0.0001:
		return
	_facing = direction.normalized()
	visual.set_facing(_facing)


func _flat(vector: Vector3) -> Vector3:
	return Vector3(vector.x, 0.0, vector.z)


func _random_offset(radius: float) -> Vector3:
	var angle := randf() * TAU
	var length := sqrt(randf()) * radius
	return Vector3(cos(angle) * length, 0.0, sin(angle) * length)


func _on_health_damaged(amount: int, _source: Node3D) -> void:
	EventBus.enemy_damaged.emit(self, amount)


func _on_health_died() -> void:
	_interrupt()
	_enter(State.DEAD)
	remove_from_group(ENEMIES_GROUP)
	hurtbox.set_deferred(&"monitorable", false)
	set_deferred(&"collision_layer", 0)
	set_deferred(&"collision_mask", 1)
	visual.play(&"mort", true)
	var points := data.points if data != null else 0
	EventBus.enemy_killed.emit(enemy_id(), points)
	defeated.emit(self, points)
	if drops_enabled:
		_spawn_drops.call_deferred()


## Recul en s'éloignant de la source, puis hurt ; un ennemi stoic ne bronche que sous une
## attaque qui traverse (le Grand ne recule que sous l'onde, jeu.js l. 948). (H7) Tout coup
## porté se voit : éclair, éclats, arrêt sur image, poussière au recul.
func _on_hurtbox_hit_taken(attack: AttackData, source: Node3D) -> void:
	if attack == null:
		return
	_hit_feedback(attack, source)
	if data != null and data.stoic and not attack.pierces:
		return
	if is_instance_valid(source):
		var away := _flat(global_position - source.global_position)
		if away.length_squared() > 0.0001:
			_knockback = away.normalized() * attack.knockback
			if attack.knockback >= DUST_KNOCKBACK:
				_dust(global_position)
	if _state != State.DEAD:
		_interrupt()
		_enter(State.HURT)
		visual.play(&"degats", true)


## (H7) Éclair blanc, éclats côté attaquant (or pour l'épée, bleus pour l'onde), arrêt sur image.
func _hit_feedback(attack: AttackData, source: Node3D) -> void:
	hit_flash.flash(FLASH_TIME)
	var center := global_position + Vector3.UP * HURT_CENTER * _base_scale
	if is_instance_valid(source):
		var toward := _flat(source.global_position - global_position)
		if toward.length_squared() > 0.0001:
			center += toward.normalized() * 0.3 * _base_scale
	var color := CombatFx.COLOR_WAVE if attack.pierces else CombatFx.COLOR_SWORD
	if attack.knockback > 5.0 and not attack.pierces:
		color = CombatFx.COLOR_SWORD_FINAL
	CombatFx.spawn_burst(self, "impact", center, color, IMPACT_SIZE * maxf(1.0, _base_scale))
	if attack.hitstop > 0.0:
		_hitstop_left = maxf(_hitstop_left, attack.hitstop)
		CombatFx.freeze(visual, attack.hitstop)


## (H7) Sa Hitbox a porté (le joueur est touché) : ses crocs se figent un instant.
func _on_hitbox_hit_landed(_hurtbox: Hurtbox) -> void:
	if hitbox.attack != null and hitbox.attack.hitstop > 0.0:
		CombatFx.freeze(visual, hitbox.attack.hitstop)


## (H7) Coup lancé (première image « coup ») : crocs ou fouet dessinés à la place exacte de la
## Hitbox, qu'ils touchent ou non ; le Grand fait trembler le sol.
func _strike_fx(attack: AttackData) -> void:
	var at := hitbox.global_position
	if attack.animation == &"fouet":
		var camera := get_viewport().get_camera_3d()
		var left := CombatFx.screen_direction(camera, _facing).x < 0.0
		CombatFx.spawn_burst(self, "whip", at, CombatFx.COLOR_BITE, _base_scale, left)
	else:
		CombatFx.spawn_burst(self, "bite", at, CombatFx.COLOR_BITE, _base_scale)
	if data != null and data.strike_shake > 0.0:
		ScreenShake.kick_in(get_tree(), data.strike_shake, _facing)


## (H7) Traînée de la charge du bondissant : poussière derrière lui, images rémanentes.
func _rush_trail(delta: float) -> void:
	_fx_clock += delta
	_ghost_clock += delta
	if _fx_clock >= RUSH_DUST_EVERY:
		_fx_clock = 0.0
		_dust(global_position - _rush_dir * 0.3 * _base_scale)
	if _ghost_clock >= RUSH_GHOST_EVERY:
		_ghost_clock = 0.0
		CombatFx.spawn_ghost(_sprite, GHOST_COLOR * Color(data.tint, 1.0))


## (H7) Bouffée de poussière au sol en at (teinte du corps sur le sable).
func _dust(at: Vector3) -> void:
	var tint := data.tint if data != null else Color.WHITE
	CombatFx.spawn_burst(self, "dust", at, tint * CombatFx.COLOR_DUST, DUST_SIZE)


func _on_visual_frame_changed(anim: StringName, frame: int) -> void:
	if _state != State.ATTACK or _attack == null or anim != _attack.animation:
		return
	if visual.hit_frames(anim).has(frame):
		if not _hit_started:
			_hit_started = true
			hitbox.activate()
			_strike_fx(_attack)
	elif hitbox.is_active():
		hitbox.deactivate()


func _on_player_died() -> void:
	_player_down = true


func _on_player_respawned() -> void:
	_player_down = false


func _on_dialogue_started(_npc_id: StringName) -> void:
	_player_talking = true


func _on_dialogue_ended(_npc_id: StringName) -> void:
	_player_talking = false
