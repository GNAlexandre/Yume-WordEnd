extends Node3D
## Démo du Lot 5 : l'arène des dunes (arena.tscn) sur un sol plat avec SpawnN/S/E/W, un joueur
## factice (Health + Hurtbox, visuel de Chtholly) et la série lancée automatiquement. Avec
## showcase, un Timere de chaque type entoure d'emblée le joueur (capture build/shots/l5.png).
## Jouable dans l'éditeur (F6) : ZQSD / flèches déplacent le joueur, J / X frappe à l'épée
## (sword_1), K / C lance l'onde (charge_wave) ; la mort du joueur termine la série, qui repart
## RESTART_DELAY s plus tard.

const ENEMY_SCENE := preload("res://src/enemies/enemy.tscn")
const HITBOX_SCENE := preload("res://src/combat/hitbox.tscn")
const WAVE_SCENE := preload("res://src/combat/charge_wave.tscn")
const SWORD := preload("res://data/attacks/sword_1.tres")
const WAVE := preload("res://data/attacks/charge_wave.tres")
## Timeres placés autour du joueur au départ (type → position), tous visibles depuis la caméra.
const SHOWCASE := {
	&"timere_small": Vector3(2.6, 0.0, 1.3),
	&"timere_normal": Vector3(-2.6, 0.0, 1.6),
	&"timere_runner": Vector3(-3.2, 0.0, -1.6),
	&"timere_big": Vector3(3.0, 0.0, -2.2),
}
const WALK_SPEED := 4.0
const RESTART_DELAY := 3.0

## Place un Timere de chaque type autour du joueur au départ.
@export var showcase: bool = true
## PV du joueur factice (la démo dure plus longtemps qu'une partie).
@export var player_hp: int = 30

var _facing: Vector3 = Vector3.FORWARD

@onready var arena: Arena = $Arena
@onready var player: CharacterBody3D = $Player
@onready var _health: Health = $Player/Health
@onready var _visual: CharacterVisual = $Player/Visual


func _ready() -> void:
	_health.max_hp = player_hp
	_health.died.connect(arena.director().stop)
	EventBus.arena_finished.connect(_on_arena_finished)
	if showcase:
		for enemy_id: StringName in SHOWCASE:
			var enemy := ENEMY_SCENE.instantiate() as Enemy
			enemy.data = load("res://data/enemies/%s.tres" % enemy_id) as EnemyData
			enemy.drops_enabled = false
			enemy.always_chase = true
			enemy.position = SHOWCASE[enemy_id]
			add_child(enemy)
	arena.director().start()


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


func _on_arena_finished(_arena_id: StringName, _score: int, _best: bool) -> void:
	get_tree().create_timer(RESTART_DELAY).timeout.connect(_restart)


func _restart() -> void:
	_health.reset()
	arena.director().start()
