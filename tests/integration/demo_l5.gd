extends Node3D
## Démo du Lot 5 : les quatre Timeres (data/enemies/) autour d'un joueur factice (Health + Hurtbox,
## visuel de Chtholly) sur un sol plat ; ils le poursuivent d'emblée (capture build/shots/l5.png).
## (F1) L'arène des dunes et ses vagues sont parties avec l'ancienne île : la démo garde le moteur
## des ennemis, qui sert à la surface. Jouable dans l'éditeur (F6) : ZQSD / flèches déplacent le
## joueur, J / X frappe à l'épée (sword_1), K / C lance l'onde (charge_wave) ; à la mort du joueur,
## les Timeres reviennent RESTART_DELAY s plus tard, le joueur à pleins PV.

const ENEMY_SCENE := preload("res://src/enemies/enemy.tscn")
const HITBOX_SCENE := preload("res://src/combat/hitbox.tscn")
const WAVE_SCENE := preload("res://src/combat/charge_wave.tscn")
const SWORD := preload("res://data/attacks/sword_1.tres")
const WAVE := preload("res://data/attacks/charge_wave.tres")
## Timeres placés autour du joueur (type → position), tous visibles depuis la caméra.
const SHOWCASE := {
	&"timere_small": Vector3(2.6, 0.0, 1.3),
	&"timere_normal": Vector3(-2.6, 0.0, 1.6),
	&"timere_runner": Vector3(-3.2, 0.0, -1.6),
	&"timere_big": Vector3(3.0, 0.0, -2.2),
}
const WALK_SPEED := 4.0
const RESTART_DELAY := 3.0

## PV du joueur factice (la démo dure plus longtemps qu'une partie).
@export var player_hp: int = 30

var _facing: Vector3 = Vector3.FORWARD
var _enemies: Array[Enemy] = []

@onready var player: CharacterBody3D = $Player
@onready var _health: Health = $Player/Health
@onready var _visual: CharacterVisual = $Player/Visual


func _ready() -> void:
	_health.max_hp = player_hp
	_health.died.connect(_on_player_died)
	_spawn_showcase()


func _physics_process(delta: float) -> void:
	var input := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	var direction := Vector3(input.x, 0.0, input.y)
	if direction != Vector3.ZERO:
		_facing = direction.normalized()
		_visual.set_facing(_facing)
	_visual.play(&"marche" if direction != Vector3.ZERO else &"repos")
	player.velocity.x = direction.x * WALK_SPEED
	player.velocity.z = direction.z * WALK_SPEED
	if not player.is_on_floor():
		player.velocity += player.get_gravity() * delta
	player.move_and_slide()
	if Input.is_action_just_pressed(&"attack"):
		_strike()
	if Input.is_action_just_pressed(&"charge"):
		_launch_wave()


## Un Timere de chaque type autour du joueur (les anciens, morts ou vivants, partent).
func _spawn_showcase() -> void:
	for enemy: Enemy in _enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	_enemies.clear()
	for enemy_id: StringName in SHOWCASE:
		var enemy := ENEMY_SCENE.instantiate() as Enemy
		enemy.data = load("res://data/enemies/%s.tres" % enemy_id) as EnemyData
		enemy.drops_enabled = false
		enemy.always_chase = true
		enemy.position = player.position + SHOWCASE[enemy_id]
		add_child(enemy)
		_enemies.append(enemy)


## Coup d'épée minimal : une Hitbox sword_1 devant le joueur pendant 0,15 s.
func _strike() -> void:
	var hitbox := HITBOX_SCENE.instantiate() as Hitbox
	hitbox.attack = SWORD
	hitbox.team = &"player"
	hitbox.source = player
	hitbox.position = player.position + _facing * 0.9 + Vector3.UP * 0.6
	add_child(hitbox)
	hitbox.activate()
	get_tree().create_timer(0.15).timeout.connect(hitbox.queue_free)


## Onde minimale : charge_wave.tscn qui file droit devant sur range_m à la vitesse speed.
func _launch_wave() -> void:
	var wave := WAVE_SCENE.instantiate() as Node3D
	add_child(wave)
	wave.global_position = player.global_position + _facing * 0.8
	wave.look_at(wave.global_position + _facing)
	var hitbox := wave.get_node(^"Hitbox") as Hitbox
	hitbox.source = player
	hitbox.activate()
	var tween := wave.create_tween()
	var target := wave.global_position + _facing * WAVE.range_m
	tween.tween_property(wave, ^"global_position", target, WAVE.range_m / WAVE.speed)
	tween.tween_callback(wave.queue_free)


func _on_player_died() -> void:
	get_tree().create_timer(RESTART_DELAY).timeout.connect(_restart)


func _restart() -> void:
	_health.reset()
	_spawn_showcase()
