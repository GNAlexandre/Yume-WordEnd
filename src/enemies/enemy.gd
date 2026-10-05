class_name Enemy
extends CharacterBody3D
## Ennemi générique piloté par ses données (PLAN.md sections 3 et 4). Propriétaire : L5.
##
## Structure figée de enemy.tscn : CollisionShape3D, Visual (CharacterVisual), Health,
## Hurtbox (équipe &"enemy"), Hitbox (équipe &"enemy"). Groupe "enemies" tant qu'il est vivant.
## Squelette du Lot 0 : applique EnemyData (PV, skin, échelle), gravité, relais EventBus
## (enemy_spawned, enemy_damaged, enemy_killed) et disparition à la mort. L5 ajoute la machine
## à états idle → chase → attack → hurt → dead, rush, stoic, recul, drops.

## Type d'ennemi (data/enemies/*.tres).
@export var data: EnemyData

@onready var visual: CharacterVisual = $Visual
@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Hitbox


func _ready() -> void:
	if data != null:
		health.max_hp = data.max_hp
		visual.set_skin(data.visual)
		visual.scale = Vector3.ONE * data.scale
		if not data.attacks.is_empty():
			hitbox.attack = data.attacks[0]
	health.damaged.connect(_on_health_damaged)
	health.died.connect(_on_health_died)
	EventBus.enemy_spawned.emit(self, enemy_id())


## Identifiant du type (EnemyData.id), &"" sans données.
func enemy_id() -> StringName:
	return data.id if data != null else &""


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()


func _on_health_damaged(amount: int, _source: Node3D) -> void:
	EventBus.enemy_damaged.emit(self, amount)


func _on_health_died() -> void:
	remove_from_group(&"enemies")
	EventBus.enemy_killed.emit(enemy_id(), data.points if data != null else 0)
	queue_free()
