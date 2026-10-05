class_name Health
extends Node
## Points de vie, commun au joueur et aux ennemis (PLAN.md section 3). Propriétaire : L4.
##
## PV pleins à la création ; changer max_hp avant le premier dégât garde les PV pleins.
## L'invincibilité (joueur : 1,2 s, réglée dans player.tscn ; ennemis : 0) décompte dans
## _physics_process.

signal changed(current: int, max_value: int)
## Émis à chaque dégât accepté, avant changed (relais vers EventBus par le propriétaire).
signal damaged(amount: int, source: Node3D)
signal died

## PV maximum (au moins 1).
@export var max_hp: int = 1:
	set(value):
		var new_max := maxi(1, value)
		if new_max == max_hp:
			return
		max_hp = new_max
		current = max_hp if not _touched else mini(current, max_hp)
		changed.emit(current, max_hp)
## Durée d'invincibilité après un dégât, en secondes.
@export var invincibility_time: float = 0.0

## PV courants.
var current: int = 1

var _touched: bool = false
var _invincible_left: float = 0.0


## Inflige amount dégâts ; false si refusé (mort, invincible ou amount <= 0).
func take_damage(amount: int, source: Node3D) -> bool:
	if amount <= 0 or is_dead() or is_invincible():
		return false
	_touched = true
	current = maxi(0, current - amount)
	_invincible_left = invincibility_time
	damaged.emit(amount, source)
	changed.emit(current, max_hp)
	if current == 0:
		died.emit()
	return true


## Rend amount PV (sans dépasser max_hp) ; sans effet sur un mort (voir reset()).
func heal(amount: int) -> void:
	if amount <= 0 or is_dead() or current >= max_hp:
		return
	_touched = true
	current = mini(max_hp, current + amount)
	changed.emit(current, max_hp)


## PV pleins, plus d'invincibilité (réapparition du joueur).
func reset() -> void:
	_touched = true
	current = max_hp
	_invincible_left = 0.0
	changed.emit(current, max_hp)


func is_dead() -> bool:
	return current <= 0


func is_invincible() -> bool:
	return _invincible_left > 0.0


## Temps d'invincibilité restant, en secondes.
func invincibility_left() -> float:
	return _invincible_left


func _physics_process(delta: float) -> void:
	if _invincible_left > 0.0:
		_invincible_left = maxf(0.0, _invincible_left - delta)
