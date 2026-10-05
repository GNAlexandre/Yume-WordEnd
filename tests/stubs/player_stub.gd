extends CharacterBody3D
## Joueur factice pour les tests (pas de class_name) : nœud du groupe "player" avec Health
## (5 PV, 1,2 s d'invincibilité) et Hurtbox (équipe &"player"), sans contrôle ni caméra.
## Retient les coups reçus ; sert de cible aux ennemis et de « player » pour interact().
##
##   const PLAYER_STUB := preload("res://tests/stubs/player_stub.tscn")
##   var player: CharacterBody3D = add_child_autofree(PLAYER_STUB.instantiate())

## Attaques reçues (Hurtbox.hit_taken), dans l'ordre.
var hits: Array[AttackData] = []

@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox


func _ready() -> void:
	hurtbox.hit_taken.connect(_on_hit_taken)


func _on_hit_taken(attack: AttackData, _source: Node3D) -> void:
	hits.append(attack)
