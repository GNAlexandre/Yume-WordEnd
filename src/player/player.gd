class_name Player
extends CharacterBody3D
## Joueur : nœud unique du groupe "player" (PLAN.md section 4). Propriétaire : L1.
##
## Structure figée de player.tscn (d'autres lots s'en servent ; noms et chemins inchangés) :
## CollisionShape3D, Visual (CharacterVisual), Combat (PlayerCombat) et son enfant SwordHitbox
## (Hitbox, équipe &"player"), Health (5 PV et 1,2 s d'invincibilité, réglés dans la scène),
## Hurtbox (équipe &"player", health = ../Health), CameraRig (camera_rig.tscn).
## Squelette du Lot 0 : déplacement relatif à la caméra, course, saut, gravité, skin de
## GameState (et EventBus.skin_changed), recul sur Hurtbox.hit_taken, GameState.position mise
## à jour au sol, touches d'attaque et de charge relayées à Combat.
## Les animations repos / marche / course ne sont jouées que si Combat.is_busy() est faux ;
## PlayerCombat joue attaque, charge, degats et mort.

## Vitesse de marche (m/s, easter egg : 72 px/s).
@export var walk_speed: float = 4.0
## Vitesse de course (m/s).
@export var run_speed: float = 7.0
## Vitesse verticale du saut (m/s).
@export var jump_velocity: float = 4.5
## Amortissement du recul (m/s perdus par seconde).
@export var knockback_damping: float = 12.0

var _knockback: Vector3 = Vector3.ZERO

@onready var visual: CharacterVisual = $Visual
@onready var combat: PlayerCombat = $Combat
@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox


func _ready() -> void:
	visual.set_skin(_current_skin())
	EventBus.skin_changed.connect(_on_skin_changed)
	hurtbox.hit_taken.connect(_on_hit_taken)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	var busy := combat.is_busy()
	var direction := Vector3.ZERO if busy else _input_direction()
	var running := Input.is_action_pressed(&"run")
	var speed := run_speed if running else walk_speed
	velocity.x = direction.x * speed + _knockback.x
	velocity.z = direction.z * speed + _knockback.z
	_knockback = _knockback.move_toward(Vector3.ZERO, knockback_damping * delta)
	if not busy and is_on_floor() and Input.is_action_just_pressed(&"jump"):
		velocity.y = jump_velocity
	move_and_slide()
	if is_on_floor():
		GameState.position = global_position
	_handle_combat_input()
	if not combat.is_busy():
		_animate(direction, running)


## Direction de déplacement dans le plan du sol, relative à la caméra active.
func _input_direction() -> Vector3:
	var input := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	if input == Vector2.ZERO:
		return Vector3.ZERO
	var forward := Vector3.FORWARD
	var right := Vector3.RIGHT
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		forward = Vector3(-camera.global_basis.z.x, 0.0, -camera.global_basis.z.z).normalized()
		right = Vector3(camera.global_basis.x.x, 0.0, camera.global_basis.x.z).normalized()
	return right * input.x - forward * input.y


func _handle_combat_input() -> void:
	if Input.is_action_just_pressed(&"attack"):
		combat.attack()
	if Input.is_action_just_pressed(&"charge"):
		combat.charge_begin()
	if Input.is_action_just_released(&"charge"):
		combat.charge_release()


func _animate(direction: Vector3, running: bool) -> void:
	if direction == Vector3.ZERO:
		visual.play(&"repos")
		return
	visual.set_facing(direction)
	visual.play(&"course" if running else &"marche")


func _current_skin() -> SkinData:
	var skin := SkinRegistry.get_skin(GameState.skin_id)
	return skin if skin != null else SkinRegistry.default_skin()


func _on_skin_changed(_skin_id: StringName) -> void:
	visual.set_skin(_current_skin())


func _on_hit_taken(attack: AttackData, source: Node3D) -> void:
	if source == null:
		return
	var away := global_position - source.global_position
	away.y = 0.0
	if away.length_squared() > 0.0001:
		_knockback = away.normalized() * attack.knockback
