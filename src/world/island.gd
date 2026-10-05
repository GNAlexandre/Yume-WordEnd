extends Node3D
## Île greybox 160 × 160 m (PLAN.md section 4). Propriétaire : L2.
##
## Structure : WorldEnvironment, Sun, OverviewCamera (caméra de survol, courante quand l'île
## est seule ; la caméra du joueur, ajoutée après, prend le relais en jeu), Ground, Water,
## Walls (murs invisibles), KillZone (rattrapage sous l'eau) et Zones (une scène par zone).

@onready var _kill_zone: Area3D = $KillZone


func _ready() -> void:
	_kill_zone.body_entered.connect(_on_kill_zone_body_entered)


func _on_kill_zone_body_entered(body: Node3D) -> void:
	if not body.is_in_group(&"player"):
		return
	var zone := WorldManager.current_zone()
	if zone.is_empty():
		zone = WorldManager.VILLAGE
	WorldManager.teleport.call_deferred(zone, WorldManager.SPAWN_MARKER)
