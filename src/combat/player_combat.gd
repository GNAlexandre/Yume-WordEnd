class_name PlayerCombat
extends Node3D
## Combat du joueur : nœud « Combat » de player.tscn (PLAN.md sections 3 et 4). Propriétaire : L4.
##
## Le joueur (L1) tourne ce nœud (-Z local = devant), appelle attack(), charge_begin() /
## charge_release() et ne bouge pas tant que is_busy() ; ce nœud joue attaque, charge, degats et
## mort sur ../Visual. États : idle → attack (sword_1 → 2 → 3, combo_window) ; idle → charge
## (jauge EventBus.charge_progress) → wave (onde sur l'image « onde ») ; hurt ; dead (jusqu'à
## player_respawned). SwordHitbox : secteur arc_deg × range_m, actif sur les images « coup »
## reçues par Visual.frame_changed. Visual.visible clignote pendant l'invincibilité.
##
## Relais Health ↔ EventBus (contrat du Lot 0) : au départ, Health.max_hp = GameState.max_hp,
## PV pleins, puis player_health_changed émis en différé (valeur initiale du HUD) ;
## Health.changed → player_health_changed ; Health.damaged → player_damaged ;
## Health.died → player_died ; player_respawned → Health.reset() ; player_heal_requested →
## Health.heal() ; max_hp_changed → Health.max_hp. Le recul du joueur est appliqué par
## player.gd (L1) sur Hurtbox.hit_taken. Aucun chiffre ici : data/attacks/*.tres et exports.
##
## (H7) Lisibilité en vue fixe, nœuds ajoutés sous Combat au démarrage : « Slash », le coup
## d'épée dessiné au sol à sa portée exacte (secteur de range_m × arc_deg, tourné avec Combat,
## sur les images « coup ») ; « AimMarker », chevron de visée au sol pendant le verrouillage et la
## charge ; « LockRing », réticule au sol sous la cible verrouillée (locked_target() du joueur) ;
## « GroundShadow », ombre nette qui reste au sol pendant un saut ; « HitFlash », éclair du
## joueur touché ; « ScreenShake », secousse de l'écran (AttackData.shake). Coup porté : la
## planche du joueur se fige AttackData.hitstop s (arrêt sur image). Rien ne dépend du dessin
## de la planche.

## Un coup d'épée ou l'onde commence (sword_1, sword_2, sword_3, charge_wave).
signal attack_started(attack_data: AttackData)
## L'onde de charge est partie (projectile charge_wave.tscn, ajouté à côté du joueur).
signal wave_launched(wave: Node3D)

enum State { IDLE, ATTACK, CHARGE, WAVE, HURT, DEAD }

## Enchaînement de l'épée : sword_1 → sword_2 → sword_3 si la touche est répétée.
const SWORD_COMBO: Array[String] = [
	"res://data/attacks/sword_1.tres",
	"res://data/attacks/sword_2.tres",
	"res://data/attacks/sword_3.tres",
]
## Charge magique (onde qui traverse).
const CHARGE_WAVE := "res://data/attacks/charge_wave.tres"
## Projectile de l'onde.
const CHARGE_WAVE_SCENE := "res://src/combat/charge_wave.tscn"
## Animations du contrat CharacterVisual jouées par ce nœud (hors AttackData.animation).
const ANIM_HURT := &"degats"
const ANIM_DEATH := &"mort"
const STATE_NAMES: Array[StringName] = [&"idle", &"attack", &"charge", &"wave", &"hurt", &"dead"]
## (H7) Coup d'épée au sol : image de 2,5 × 1,25 m (240 × 120 px), pointe au milieu du bord bas.
const SLASH_SIZE := Vector2(2.5, 1.25)
## (H7) Réticule de verrouillage (rayon à l'échelle 1 du Timere, m), vitesse de rotation (rad/s).
const LOCK_RING_RADIUS := 0.62
const LOCK_RING_SPIN := 1.5
## (H7) Chevron de visée : taille (m) et distance devant les pieds (m).
const AIM_SIZE := 0.34
const AIM_AHEAD := 0.9
## (H7) Éclair du joueur touché : rougeâtre, plus sobre que celui des Timeres.
const FLASH_COLOR := Color(1.0, 0.6, 0.55)
const FLASH_STRENGTH := 0.75
## (H7) Ombre nette : rayon (m) ; au-delà de SHADOW_RAY m de chute, plus d'ombre.
const SHADOW_RADIUS := 0.4
const SHADOW_RAY := 6.0
## (H7) Éclair du joueur touché (s), centre de sa Hurtbox (m), poussière du recul.
const FLASH_TIME := 0.1
const HURT_CENTER := 0.75
const DUST_KNOCKBACK := 2.0

## Fenêtre d'enchaînement (s) après la fin d'un coup : un nouvel appui joue le coup suivant.
@export var combo_window: float = 0.4
## Durée de l'état « dégâts » (s) : le joueur ne peut ni bouger ni attaquer (jeu.js : 0,35).
@export var hurt_time: float = 0.35
## Bascules de Visual.visible par seconde pendant l'invincibilité (jeu.js : 12).
@export var blink_rate: float = 12.0
## Bascules par seconde entre les deux dernières images de charge quand la jauge est pleine.
@export var charged_flicker_rate: float = 8.0
## Hauteur (m) de la zone de l'épée, centrée sur la hauteur de SwordHitbox.
@export var sword_height: float = 1.4
## Sécurité (s) : un coup se termine même si le Visual ne signale jamais la fin de son
## animation (skin sans « attaque »).
@export var animation_timeout: float = 2.0

var _state: State = State.IDLE
var _state_time: float = 0.0
var _swords: Array[AttackData] = []
var _wave_data: AttackData
var _wave_scene: PackedScene
var _swing: AttackData
var _combo_index: int = -1
var _combo_left: float = 0.0
var _attack_queued: bool = false
var _attack_cooldown: float = 0.0
var _swing_struck: bool = false
var _sword_shape_key: Vector2 = Vector2.ZERO
var _charge_time: float = 0.0
var _charge_held: bool = false
var _charge_frame: int = -1
var _wave_cooldown: float = 0.0
var _wave_pending: bool = false
var _progress: float = 0.0
var _blinking: bool = false
var _shake: ScreenShake
var _flash: HitFlash
var _slash: MeshInstance3D
var _lock_ring: MeshInstance3D
var _aim_marker: MeshInstance3D
var _shadow: MeshInstance3D

@onready var _health: Health = get_node_or_null(^"../Health") as Health
@onready var _visual: CharacterVisual = get_node_or_null(^"../Visual") as CharacterVisual
@onready var _sword: Hitbox = get_node_or_null(^"SwordHitbox") as Hitbox


func _ready() -> void:
	for path: String in SWORD_COMBO:
		var data := load(path) as AttackData
		if data != null:
			_swords.append(data)
	_wave_data = load(CHARGE_WAVE) as AttackData
	_wave_scene = load(CHARGE_WAVE_SCENE) as PackedScene
	if _sword != null:
		_sword.deactivate()
		_sword.source = get_parent() as Node3D
		if not _swords.is_empty():
			_set_sword_attack(_swords[0])
	if _visual != null:
		_visual.frame_changed.connect(_on_visual_frame_changed)
		_visual.animation_finished.connect(_on_visual_animation_finished)
	_build_fx()
	if _sword != null:
		_sword.hit_landed.connect(_on_sword_hit_landed)
	var hurtbox := get_node_or_null(^"../Hurtbox") as Hurtbox
	if hurtbox != null:
		hurtbox.hit_taken.connect(_on_hurtbox_hit_taken)
	if _health == null:
		return
	_health.max_hp = GameState.max_hp
	_health.reset()
	_health.changed.connect(_on_health_changed)
	_health.damaged.connect(_on_health_damaged)
	_health.died.connect(_on_health_died)
	EventBus.player_respawned.connect(_on_player_respawned)
	EventBus.player_heal_requested.connect(_on_player_heal_requested)
	EventBus.max_hp_changed.connect(_on_max_hp_changed)
	_emit_health.call_deferred()


## Coup d'épée ; enchaîne sword_1 → sword_2 → sword_3 si la touche est répétée pendant le coup
## ou juste après (combo_window). Sans effet pendant la charge, l'onde, les dégâts, la mort et
## la recharge d'un coup (AttackData.cooldown, 3e coup).
func attack() -> void:
	if _state == State.ATTACK:
		_attack_queued = true
	elif _state == State.IDLE and _attack_cooldown <= 0.0 and not _swords.is_empty():
		var chained := _combo_left > 0.0 and _combo_index + 1 < _swords.size()
		_start_swing(_combo_index + 1 if chained else 0)


## Démarre la jauge de charge (AttackData.charge_time minimum) ; si le joueur est occupé ou
## l'onde en recharge, la charge commencera dès que possible tant que la touche reste tenue.
func charge_begin() -> void:
	_charge_held = true
	_try_start_charge()


## Lance l'onde si la jauge est pleine, puis recharge (AttackData.cooldown) ; relâcher trop tôt
## ne fait rien.
func charge_release() -> void:
	_charge_held = false
	if _state != State.CHARGE:
		return
	_emit_progress(0.0)
	if _charge_time >= _wave_data.charge_time:
		_release_wave()
	else:
		_set_state(State.IDLE)


## true pendant attaque, charge, onde, dégâts et mort : le joueur ne se déplace pas.
func is_busy() -> bool:
	return _state != State.IDLE


## État courant : &"idle", &"attack", &"charge", &"wave", &"hurt" ou &"dead".
func current_state() -> StringName:
	return STATE_NAMES[_state]


## Coup d'épée en cours (sword_1, sword_2 ou sword_3), null hors attaque.
func current_attack() -> AttackData:
	return _swing if _state == State.ATTACK else null


## Temps de recharge restant de l'onde, en secondes.
func wave_cooldown_left() -> float:
	return _wave_cooldown


## (H7) Secousse de l'écran de ce joueur.
func screen_shake() -> ScreenShake:
	return _shake


## (H7) Nœuds d'effets (sous Combat) : &"Slash", &"AimMarker", &"LockRing", &"GroundShadow",
## &"HitFlash" ; null s'il n'existe pas.
func fx_node(fx_name: StringName) -> Node3D:
	return get_node_or_null(NodePath(String(fx_name))) as Node3D


func _notification(what: int) -> void:
	# Touche de charge relâchée pendant une pause (inventaire) : aucun « just_released » ne
	# viendra du joueur, on relâche à la reprise.
	if what == NOTIFICATION_UNPAUSED and _charge_held and not Input.is_action_pressed(&"charge"):
		charge_release()


func _physics_process(delta: float) -> void:
	_state_time += delta
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_wave_cooldown = maxf(0.0, _wave_cooldown - delta)
	match _state:
		State.IDLE:
			_combo_left = maxf(0.0, _combo_left - delta)
			if _charge_held:
				_try_start_charge()
		State.ATTACK:
			var limit := _swing.duration if _swing.duration > 0.0 else animation_timeout
			if _state_time >= limit:
				_end_swing()
		State.CHARGE:
			_charge_time += delta
			_update_charge()
		State.WAVE:
			if _state_time >= _wave_data.duration:
				_set_state(State.IDLE)
		State.HURT:
			if _state_time >= hurt_time:
				_set_state(State.IDLE)
	_update_blink()


func _process(delta: float) -> void:
	_update_lock_ring(delta)
	_update_aim_marker()
	_update_shadow()


# --- Épée -------------------------------------------------------------------------------------


func _start_swing(index: int) -> void:
	_combo_index = index
	_combo_left = 0.0
	_attack_queued = false
	_swing = _swords[index]
	_swing_struck = false
	_set_sword_attack(_swing)
	_set_state(State.ATTACK)
	_face_forward()
	attack_started.emit(_swing)
	if _visual != null:
		_visual.play(_swing.animation, true)


func _end_swing() -> void:
	if _sword != null:
		_sword.deactivate()
	_hide_slash()
	_attack_cooldown = _swing.cooldown
	var last := _combo_index + 1 >= _swords.size()
	if _attack_queued and not last and _attack_cooldown <= 0.0:
		_start_swing(_combo_index + 1)
		return
	_attack_queued = false
	_combo_left = 0.0 if last else combo_window
	if last:
		_combo_index = -1
	_set_state(State.IDLE)


## La Hitbox de l'épée n'est active que sur les images « coup » du Visual ; une seule
## activation par coup (resume() après une image sans coup), donc une cible touchée une fois.
func _update_sword(frame: int) -> void:
	if _sword == null:
		return
	var hits := _visual.hit_frames(_swing.animation)
	if hits.has(frame):
		if not _swing_struck:
			_swing_struck = true
			_sword.activate()
		else:
			_sword.resume()
		_show_slash(hits.find(frame))
	else:
		_sword.deactivate()
		if _swing_struck:
			_hide_slash()


func _set_sword_attack(data: AttackData) -> void:
	if _sword == null:
		return
	_sword.deactivate()
	_sword.attack = data
	var key := Vector2(data.range_m, data.arc_deg)
	if data.arc_deg <= 0.0 or key == _sword_shape_key:
		return
	_sword_shape_key = key
	# Pointe du secteur sur l'axe du joueur (origine de Combat), à la hauteur de SwordHitbox.
	var apex := _sword.transform.affine_inverse() * Vector3(0.0, _sword.position.y, 0.0)
	_sword.set_sector_shape(apex, data.range_m, data.arc_deg, sword_height)


# --- Charge et onde ---------------------------------------------------------------------------


func _try_start_charge() -> void:
	if _state != State.IDLE or _wave_cooldown > 0.0 or _wave_data == null:
		return
	_set_state(State.CHARGE)
	_combo_index = -1
	_combo_left = 0.0
	_charge_time = 0.0
	_charge_frame = -1
	_face_forward()
	_emit_progress(0.0, true)
	_update_charge()


## Jauge et image de charge maintenue : images 0 .. onde-2 pendant le remplissage, puis
## alternance des deux images qui précèdent l'onde (jeu.js).
func _update_charge() -> void:
	var needed := _wave_data.charge_time
	var ratio := 1.0 if needed <= 0.0 else clampf(_charge_time / needed, 0.0, 1.0)
	_emit_progress(ratio)
	if _visual == null:
		return
	var last := maxi(0, _visual.wave_frame(_wave_data.animation) - 1)
	var frame := 0
	if ratio < 1.0:
		frame = mini(int(ratio * last), maxi(0, last - 1))
	else:
		frame = last - int(_charge_time * charged_flicker_rate) % 2 if last > 0 else 0
	if frame != _charge_frame:
		_charge_frame = frame
		_visual.show_frame(_wave_data.animation, frame)


func _release_wave() -> void:
	_set_state(State.WAVE)
	_wave_cooldown = _wave_data.cooldown
	_wave_pending = true
	attack_started.emit(_wave_data)
	# L'onde part sur l'image « onde » de la charge (Visual.frame_changed) ; sans cette image
	# (skin sans « onde », visuel absent), elle part tout de suite.
	var frame := _visual.wave_frame(_wave_data.animation) if _visual != null else -1
	if frame >= 0 and _visual.has_animation(_wave_data.animation):
		_visual.show_frame(_wave_data.animation, frame)
	if _wave_pending:
		_launch_wave()


func _launch_wave() -> void:
	_wave_pending = false
	if _wave_scene == null:
		return
	# Frère du joueur : l'onde ne suit pas ses déplacements.
	var body := get_parent() as Node3D
	var parent: Node = body.get_parent() if body != null else null
	if parent == null:
		parent = get_tree().root
	var wave := _wave_scene.instantiate() as ChargeWave
	parent.add_child(wave)
	wave.global_position = global_position
	wave.launch(_forward(), body)
	wave.hitbox.hit_landed.connect(_on_wave_hit_landed.bind(wave))
	wave_launched.emit(wave)


func _emit_progress(ratio: float, force: bool = false) -> void:
	if force or not is_equal_approx(ratio, _progress):
		_progress = ratio
		EventBus.charge_progress.emit(ratio)


# --- États, dégâts, mort ----------------------------------------------------------------------


func _set_state(state: State) -> void:
	_state = state
	_state_time = 0.0


## Interrompt le coup ou la charge en cours (dégâts, mort, réapparition).
func _interrupt() -> void:
	if _sword != null:
		_sword.deactivate()
	_hide_slash()
	if _state == State.CHARGE:
		_emit_progress(0.0)
	_attack_queued = false
	_combo_index = -1
	_combo_left = 0.0
	_wave_pending = false


## Fait face à -Z de Combat (le Visual retourne le sprite selon la caméra).
func _face_forward() -> void:
	if _visual != null:
		_visual.set_facing(_forward())


## Direction horizontale « devant » : -Z de Combat.
func _forward() -> Vector3:
	var forward := -global_basis.z if is_inside_tree() else Vector3.FORWARD
	forward.y = 0.0
	return forward.normalized() if forward.length_squared() > 0.0001 else Vector3.FORWARD


func _update_blink() -> void:
	if _visual == null or _health == null:
		return
	if _state != State.DEAD and _health.is_invincible():
		_blinking = true
		_visual.visible = int(_health.invincibility_left() * blink_rate) % 2 == 0
	elif _blinking:
		_blinking = false
		_visual.visible = true


func _emit_health() -> void:
	if _health != null:
		EventBus.player_health_changed.emit(_health.current, _health.max_hp)


func _on_visual_frame_changed(anim: StringName, frame: int) -> void:
	if _state == State.ATTACK and anim == _swing.animation:
		_update_sword(frame)
	elif _state == State.WAVE and _wave_pending and anim == _wave_data.animation:
		if frame == _visual.wave_frame(anim):
			_launch_wave()


func _on_visual_animation_finished(anim: StringName) -> void:
	if _state == State.ATTACK and anim == _swing.animation:
		_end_swing()


func _on_health_changed(current: int, max_value: int) -> void:
	EventBus.player_health_changed.emit(current, max_value)


func _on_health_damaged(amount: int, source: Node3D) -> void:
	EventBus.player_damaged.emit(amount, source)
	if _health.is_dead():
		return  # died suit : état « mort ».
	_interrupt()
	_set_state(State.HURT)
	if _visual != null:
		_visual.play(ANIM_HURT, true)


func _on_health_died() -> void:
	_interrupt()
	_charge_held = false
	_set_state(State.DEAD)
	_update_blink()
	if _visual != null:
		_visual.play(ANIM_DEATH, true)
	EventBus.player_died.emit()


func _on_player_respawned() -> void:
	_interrupt()
	_charge_held = false
	_attack_cooldown = 0.0
	_wave_cooldown = 0.0
	_set_state(State.IDLE)
	_health.reset()
	_update_blink()


# --- (H7) Lisibilité : effets ---------------------------------------------------------------


func _build_fx() -> void:
	_shake = ScreenShake.new()
	_shake.name = "ScreenShake"
	add_child(_shake)
	_flash = HitFlash.new()
	_flash.name = "HitFlash"
	_flash.flash_color = FLASH_COLOR
	_flash.max_strength = FLASH_STRENGTH
	add_child(_flash)
	if _visual != null:
		_flash.bind(_visual.get_node_or_null(^"Sprite") as AnimatedSprite3D)
	_slash = CombatFx.make_decal("slash", SLASH_SIZE, Color.WHITE, "Slash")
	_slash.position = Vector3(0.0, CombatFx.GROUND_LIFT, -SLASH_SIZE.y * 0.5)
	_slash.visible = false
	add_child(_slash)
	_aim_marker = CombatFx.make_decal("aim", Vector2(AIM_SIZE, AIM_SIZE), Color.WHITE, "AimMarker")
	_aim_marker.position = Vector3(0.0, CombatFx.GROUND_LIFT, -AIM_AHEAD)
	_aim_marker.visible = false
	add_child(_aim_marker)
	_lock_ring = CombatFx.make_decal("lock_ring", Vector2.ONE, Color.WHITE, "LockRing")
	_lock_ring.top_level = true
	# Posés à chaque image sur la place affichée (interpolée) de leur porteur : pas interpolés.
	_lock_ring.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_lock_ring.visible = false
	add_child(_lock_ring)
	_shadow = CombatFx.make_shadow(SHADOW_RADIUS)
	_shadow.top_level = true
	_shadow.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(_shadow)


## Coup d'épée au sol : image index de la bande (0 : balayé à moitié, 1 : plein, 2 : effacé),
## retournée pour le 2e coup (il balaie dans l'autre sens), dorée pour le 3e.
func _show_slash(index: int) -> void:
	if _slash == null or index < 0:
		return
	var frame := mini(index, CombatFx.frame_count("slash") - 1)
	var final := _combo_index + 1 >= _swords.size() and _swords.size() > 1
	var color := CombatFx.COLOR_SWORD_FINAL if final else Color.WHITE
	_slash.material_override = CombatFx.ground_material("slash", color, frame, true)
	var reach := _swing.range_m if _swing != null and _swing.range_m > 0.0 else 1.2
	var size := reach / (SLASH_SIZE.y - 0.05)
	_slash.scale = Vector3(-size if _combo_index == 1 else size, 1.0, size)
	_slash.position = Vector3(0.0, CombatFx.GROUND_LIFT, -SLASH_SIZE.y * 0.5 * size)
	_slash.visible = true


func _hide_slash() -> void:
	if _slash != null:
		_slash.visible = false


## Coup d'épée porté : la planche du joueur se fige (arrêt sur image), l'écran tressaille.
func _on_sword_hit_landed(_hurtbox: Hurtbox) -> void:
	if _swing == null:
		return
	if _swing.hitstop > 0.0 and _visual != null:
		CombatFx.freeze(_visual, _swing.hitstop)
	if _shake != null:
		_shake.kick(_swing.shake, _forward())


func _on_wave_hit_landed(_hurtbox: Hurtbox, wave: ChargeWave) -> void:
	if _shake != null and is_instance_valid(wave) and wave.hitbox.attack != null:
		_shake.kick(wave.hitbox.attack.shake, wave.travel_direction())


## Joueur touché : éclair, éclats côté Timere, secousse dans le sens du coup, poussière du recul.
func _on_hurtbox_hit_taken(hit_attack: AttackData, source: Node3D) -> void:
	if hit_attack == null:
		return
	if _flash != null:
		_flash.flash(FLASH_TIME)
	var body := get_parent() as Node3D
	var feet := body.global_position if body != null else global_position
	var push := Vector3.ZERO
	if is_instance_valid(source):
		push = feet - source.global_position
		push.y = 0.0
		push = push.normalized() if push.length_squared() > 0.0001 else Vector3.ZERO
	var center := feet + Vector3.UP * HURT_CENTER - push * 0.25
	CombatFx.spawn_burst(body if body != null else self, "impact", center, CombatFx.COLOR_BITE)
	if _shake != null:
		_shake.kick(hit_attack.shake, push)
	if hit_attack.knockback >= DUST_KNOCKBACK:
		CombatFx.spawn_burst(body if body != null else self, "dust", feet, CombatFx.COLOR_DUST)


## Cible verrouillée par le joueur (son locked_target(), API de player.gd), ou null.
func _locked_target() -> Node3D:
	var body := get_parent()
	if body == null or not body.has_method(&"locked_target"):
		return null
	var target: Object = body.call(&"locked_target")
	return target as Node3D if is_instance_valid(target) else null


func _update_lock_ring(delta: float) -> void:
	if _lock_ring == null:
		return
	var target := _locked_target()
	if target == null or not target.is_inside_tree():
		_lock_ring.visible = false
		return
	var size := 1.0
	var data: Variant = target.get(&"data")
	if data is EnemyData:
		size = (data as EnemyData).scale
	var diameter := 2.0 * LOCK_RING_RADIUS * size
	var spin := _lock_ring.rotation.y + LOCK_RING_SPIN * delta
	_lock_ring.global_transform = Transform3D(
		Basis(Vector3.UP, wrapf(spin, -PI, PI)).scaled(Vector3(diameter, 1.0, diameter)),
		_shown_position(target) + Vector3.UP * CombatFx.GROUND_LIFT
	)
	_lock_ring.visible = true


func _update_aim_marker() -> void:
	if _aim_marker == null:
		return
	var aiming := _state == State.CHARGE or _locked_target() != null
	_aim_marker.visible = aiming and _state != State.DEAD


## Ombre nette : sous les pieds au sol ; pendant un saut, posée sur le sol sous le joueur (rayon
## vers le bas, couche 1), plus petite à mesure qu'il monte.
func _update_shadow() -> void:
	if _shadow == null or not is_inside_tree():
		return
	var body := get_parent() as Node3D
	var feet := _shown_position(body) if body != null else global_position
	var ground := feet
	var height := 0.0
	var character := body as CharacterBody3D
	if character != null and not character.is_on_floor():
		var query := PhysicsRayQueryParameters3D.create(
			feet + Vector3.UP * 0.1, feet + Vector3.DOWN * SHADOW_RAY, 1
		)
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty():
			_shadow.visible = false
			return
		ground = hit["position"]
		height = maxf(0.0, feet.y - ground.y)
	var shrink := clampf(1.0 - height / 3.0, 0.4, 1.0)
	_shadow.global_transform = Transform3D(
		Basis.from_scale(Vector3(shrink, 1.0, shrink)), ground + Vector3.UP * CombatFx.SHADOW_LIFT
	)
	_shadow.visible = _state != State.DEAD or height <= 0.0


## Place affichée d'un nœud : interpolée entre deux images physiques quand le lissage physique
## est actif (project.godot), sinon sa position.
static func _shown_position(node: Node3D) -> Vector3:
	if node.is_physics_interpolated_and_enabled():
		return node.get_global_transform_interpolated().origin
	return node.global_position


func _on_player_heal_requested(amount: int) -> void:
	_health.heal(amount)


func _on_max_hp_changed(max_value: int) -> void:
	_health.max_hp = max_value
