extends Node3D
## Île de 160 × 160 m (PLAN.md sections 3 et 4). Propriétaire : L2.
##
## Structure figée : WorldEnvironment (ciel au couchant), Sun (seule DirectionalLight3D),
## OverviewCamera (caméra de survol, courante quand l'île est seule ; la caméra du joueur,
## ajoutée après, prend le relais en jeu), Ground (relief, IslandTerrain), Water (plan +
## shader), Walls (murs invisibles au bord du carré), KillZone (rattrapage sous l'île) et Zones
## (une scène par zone). Decor : bouées qui marquent la limite des murs dans l'eau.
##
## Un corps du groupe "player" qui tombe dans la KillZone revient au Spawn de la zone courante
## (du village si aucune zone n'a encore été visitée).

@onready var _kill_zone: Area3D = $KillZone
@onready var _water: MeshInstance3D = $Water


func _ready() -> void:
	_kill_zone.body_entered.connect(_on_kill_zone_body_entered)
	var water_material := _water.get_active_material(0) as ShaderMaterial
	if water_material != null:
		IslandTerrain.apply_shape_uniforms(water_material)


func _on_kill_zone_body_entered(body: Node3D) -> void:
	if body.is_in_group(WorldManager.PLAYER_GROUP):
		WorldManager.rescue.call_deferred()
