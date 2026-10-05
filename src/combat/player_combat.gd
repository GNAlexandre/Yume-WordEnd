class_name PlayerCombat
extends Node3D
## Combat du joueur : nœud « Combat » de player.tscn (PLAN.md sections 3 et 4). Propriétaire : L4.
##
## Squelette du Lot 0 : l'API du contrat est en place (attack, charge_begin, charge_release,
## is_busy renvoie false), ainsi que les relais Health ↔ EventBus que L4 doit conserver :
## - au départ, Health.max_hp = GameState.max_hp, PV pleins, puis player_health_changed émis
##   en différé (valeur initiale du HUD) ;
## - Health.changed → player_health_changed ; Health.damaged → player_damaged ;
##   Health.died → player_died ;
## - player_respawned → Health.reset() ; player_heal_requested → Health.heal() ;
##   max_hp_changed → Health.max_hp.
## Voisins trouvés par nom (structure figée de player.tscn) : ../Health, ../Visual, ../Hurtbox,
## et l'enfant SwordHitbox. Données lues par chemin dans data/attacks/ (aucun chiffre ici).
## Le recul du joueur est appliqué par player.gd (L1) sur Hurtbox.hit_taken.

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

@onready var _health: Health = get_node_or_null(^"../Health") as Health


func _ready() -> void:
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


## Coup d'épée ; enchaîne sword_1 → sword_2 → sword_3 si la touche est répétée (L4).
func attack() -> void:
	pass


## Démarre la jauge de charge (0,55 s minimum, AttackData.charge_time) (L4).
func charge_begin() -> void:
	pass


## Lance l'onde si la jauge est pleine, puis recharge (AttackData.cooldown) (L4).
func charge_release() -> void:
	pass


## true pendant attaque, charge, dégâts et mort : le joueur ne se déplace pas.
func is_busy() -> bool:
	return false


func _emit_health() -> void:
	if _health != null:
		EventBus.player_health_changed.emit(_health.current, _health.max_hp)


func _on_health_changed(current: int, max_value: int) -> void:
	EventBus.player_health_changed.emit(current, max_value)


func _on_health_damaged(amount: int, source: Node3D) -> void:
	EventBus.player_damaged.emit(amount, source)


func _on_health_died() -> void:
	EventBus.player_died.emit()


func _on_player_respawned() -> void:
	_health.reset()


func _on_player_heal_requested(amount: int) -> void:
	_health.heal(amount)


func _on_max_hp_changed(max_value: int) -> void:
	_health.max_hp = max_value
