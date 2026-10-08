extends Node3D
## Île flottante n° 68, 160 × 160 m (PLAN.md sections 3 et 4 ; docs/lore/MONDE.md, section 2).
## Propriétaire : L2, repris pour l'acte 1.
##
## Structure figée : WorldEnvironment (ciel au couchant, brume sous l'île), Sun (seule
## DirectionalLight3D), OverviewCamera (caméra de survol, courante quand l'île est seule ; la
## caméra du joueur, ajoutée après, prend le relais en jeu), Ground (sol et roche,
## IslandTerrain), Water (la mer de nuages, très bas sous l'île : le nom vient de l'ancienne
## mer), Walls (murs invisibles au bord du carré), KillZone (rattrapage sous l'île) et Zones
## (une scène par zone). Ajouts : EdgeBarrier (couche 8 : retient les Timeres sur l'île, pas le
## joueur), Waterfall (cascade du ruisseau au bord nord-ouest), Decor (îles lointaines et
## rochers flottants, regroupés par PropBatcher).
##
## Un corps du groupe "player" qui saute dans le vide tombe dans la KillZone et revient au Spawn
## de la zone courante (du village si aucune zone n'a encore été visitée).

@onready var _kill_zone: Area3D = $KillZone
@onready var _water: MeshInstance3D = $Water
@onready var _sun: DirectionalLight3D = $Sun
@onready var _edge_barrier: CollisionShape3D = $EdgeBarrier/CollisionShape3D
@onready var _waterfall: MeshInstance3D = $Waterfall


func _ready() -> void:
	_kill_zone.body_entered.connect(_on_kill_zone_body_entered)
	_edge_barrier.shape = IslandRock.edge_barrier_shape()
	_waterfall.mesh = IslandRock.waterfall_mesh()
	var clouds := _water.get_active_material(0) as ShaderMaterial
	if clouds != null:
		# Le soleil éclaire selon −Z : il est du côté +Z de sa base.
		var toward_sun := _sun.global_basis.z
		clouds.set_shader_parameter(
			&"sun_direction", Vector2(toward_sun.x, toward_sun.z).normalized()
		)


func _on_kill_zone_body_entered(body: Node3D) -> void:
	if body.is_in_group(WorldManager.PLAYER_GROUP):
		WorldManager.rescue.call_deferred()
