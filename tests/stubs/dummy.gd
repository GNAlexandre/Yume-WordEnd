extends CharacterBody3D
## Mannequin pour les tests (pas de class_name) : Health + Hurtbox (équipe &"enemy"), dans le
## groupe "enemies", immobile. Retient les coups reçus.
##
##   const DUMMY := preload("res://tests/stubs/dummy.tscn")
##   var dummy: CharacterBody3D = add_child_autofree(DUMMY.instantiate())
##   dummy.health.max_hp = 3

## Attaques reçues (Hurtbox.hit_taken), dans l'ordre.
var hits: Array[AttackData] = []

@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox


func _ready() -> void:
	hurtbox.hit_taken.connect(_on_hit_taken)


func _on_hit_taken(attack: AttackData, _source: Node3D) -> void:
	hits.append(attack)
