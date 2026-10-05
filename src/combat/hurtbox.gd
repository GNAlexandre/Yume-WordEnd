class_name Hurtbox
extends Area3D
## Zone qui reçoit les coups (couche 5 hurtbox, aucun masque). Propriétaire : L4.
##
## Une Hitbox d'une autre équipe appelle receive_hit() ; si Health accepte le dégât,
## hit_taken est émis et le script du corps (player.gd, enemy.gd) applique le recul :
## attack.knockback m/s dans la direction source → corps (un ennemi stoic l'ignore sauf si
## attack.pierces).

signal hit_taken(attack: AttackData, source: Node3D)

## Health qui encaisse les dégâts (dans les scènes : le nœud frère « Health »).
@export var health: Health
## Équipe : une Hitbox ne touche pas une Hurtbox de la même équipe (&"player", &"enemy").
@export var team: StringName = &""


## Applique attack ; true si le dégât a été accepté par Health.
func receive_hit(attack: AttackData, source: Node3D) -> bool:
	if health == null or attack == null:
		return false
	if not health.take_damage(attack.damage, source):
		return false
	hit_taken.emit(attack, source)
	return true
