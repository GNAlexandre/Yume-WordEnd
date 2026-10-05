extends PlayerCombat
## Combat factice du Lot 1 (pas de class_name) : is_busy() répond busy, et les appels du
## joueur sont retenus dans calls. Garde les relais de PlayerCombat (Health ↔ EventBus).
##
##   var player: Player = PLAYER.instantiate()
##   player.get_node(^"Combat").set_script(preload("res://tests/stubs/l1_combat_stub.gd"))
##   add_child_autofree(player)
##   player.combat.set("busy", true)

## Réponse de is_busy().
var busy: bool = false
## Appels reçus, dans l'ordre : &"attack", &"charge_begin", &"charge_release".
var calls: Array[StringName] = []


func attack() -> void:
	calls.append(&"attack")


func charge_begin() -> void:
	calls.append(&"charge_begin")


func charge_release() -> void:
	calls.append(&"charge_release")


func is_busy() -> bool:
	return busy
