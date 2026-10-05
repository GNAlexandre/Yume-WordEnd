extends Node
## WorldManager : zones, points d'apparition, téléportation et réapparition (PLAN.md section 3).
## Propriétaire : L2.
##
## - les zones sont les nœuds du groupe "zones" (racines Zone nommées comme leur zone_id) ;
##   en M2, island.tscn les contient toutes : load_zone() ne fait rien si la zone est déjà là,
##   sinon instancie res://src/world/zones/<id>/<id>.tscn ;
## - teleport() pose le joueur (groupe "player") sur un Marker3D de la zone, au ras du sol
##   (rayon vers le bas sur la couche world, décor statique seulement) et annule sa vitesse ;
## - respawn() le ramène au Spawn du village et émet player_respawned (PlayerCombat remet les
##   PV au maximum) ; déclenché respawn_delay secondes après EventBus.player_died, si le
##   joueur mort est toujours dans l'arbre ;
## - rescue() ramène le joueur au Spawn de la zone courante : appelé par la KillZone de l'île
##   et, en filet de sécurité, quand le joueur passe sous FALL_LIMIT ;
## - zone_entered met à jour current_zone() et GameState.zone ;
## - is_zone_safe() dit si une zone est sûre (Zone.safe), pour l'IA des Timeres.

const VILLAGE := &"village"
const SPAWN_MARKER := &"Spawn"
const ZONES_GROUP := &"zones"
const PLAYER_GROUP := &"player"
## Couche « world » (1) : sol et décor sur lesquels on pose le joueur.
const WORLD_MASK := 1
## Sous cette hauteur (m), le joueur est rattrapé (rescue) même sans KillZone.
const FALL_LIMIT := -30.0
## Le rayon qui cherche le sol part GROUND_PROBE_UP m au-dessus du marqueur et descend de
## GROUND_PROBE_DOWN m ; le joueur est posé GROUND_CLEARANCE m au-dessus du point touché.
const GROUND_PROBE_UP := 1.5
const GROUND_PROBE_DOWN := 30.0
const GROUND_CLEARANCE := 0.05

## Délai entre la mort du joueur et sa réapparition (animation de mort + fondu, jeu.js : 2,2 s).
var respawn_delay: float = 2.2

var _current_zone: StringName = &""


func _ready() -> void:
	EventBus.zone_entered.connect(_on_zone_entered)
	EventBus.player_died.connect(_on_player_died)


func _physics_process(_delta: float) -> void:
	var player := _player()
	if player != null and player.global_position.y < FALL_LIMIT:
		rescue()


## S'assure que la zone est dans l'arbre (toutes le sont déjà en M2).
func load_zone(zone_id: StringName) -> void:
	if zone_id.is_empty() or _find_zone(zone_id) != null:
		return
	var path := "res://src/world/zones/%s/%s.tscn" % [zone_id, zone_id]
	if not ResourceLoader.exists(path):
		push_warning("WorldManager : zone inconnue %s" % zone_id)
		return
	var packed := load(path) as PackedScene
	var zone := packed.instantiate()
	var parent := _zones_parent()
	if parent == null:
		zone.free()
		return
	parent.add_child(zone)


## Pose le joueur sur le Marker3D `marker` de la zone, au ras du sol, et annule sa vitesse.
func teleport(zone_id: StringName, marker: StringName = SPAWN_MARKER) -> void:
	load_zone(zone_id)
	var zone := _find_zone(zone_id)
	var player := _player()
	if zone == null or player == null:
		return
	var target := zone.get_node_or_null(NodePath(String(marker))) as Node3D
	if target == null:
		target = zone.find_child(String(marker), true, false) as Node3D
	if target == null:
		return
	player.global_position = ground_position(target.global_position, player)
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO


## Réapparition au Spawn du village avec PV pleins (appliqués par PlayerCombat).
func respawn() -> void:
	teleport(VILLAGE, SPAWN_MARKER)
	EventBus.player_respawned.emit()


## Rattrapage : ramène le joueur au Spawn de la zone courante (du village à défaut).
func rescue() -> void:
	var zone := _current_zone if _find_zone(_current_zone) != null else VILLAGE
	teleport(zone, SPAWN_MARKER)


func current_zone() -> StringName:
	return _current_zone


## Vrai si la zone zone_id est sûre (Zone.safe, le village : aucun ennemi n'y poursuit le
## joueur) ; faux pour une zone inconnue ou &"". Les Timeres l'appellent avec current_zone().
func is_zone_safe(zone_id: StringName) -> bool:
	var zone := _find_zone(zone_id)
	return zone is Zone and (zone as Zone).safe


## Nom affiché d'une zone (Zone.display_name), ou son identifiant à défaut.
func zone_display_name(zone_id: StringName) -> String:
	var zone := _find_zone(zone_id)
	if zone is Zone and not (zone as Zone).display_name.is_empty():
		return (zone as Zone).display_name
	return String(zone_id)


## Point au ras du décor statique (couche world) sous `point`, ou `point` s'il n'y a rien
## dessous. `body` (le joueur) est ignoré, ainsi que les corps non statiques (PNJ…).
func ground_position(point: Vector3, body: Node3D = null) -> Vector3:
	if body == null or not body.is_inside_tree():
		return point
	var space := body.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		point + Vector3.UP * GROUND_PROBE_UP, point + Vector3.DOWN * GROUND_PROBE_DOWN, WORLD_MASK
	)
	var excluded: Array[RID] = []
	if body is CollisionObject3D:
		excluded.append((body as CollisionObject3D).get_rid())
	for _attempt in 4:
		query.exclude = excluded
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			return point
		if hit["collider"] is StaticBody3D:
			return (hit["position"] as Vector3) + Vector3.UP * GROUND_CLEARANCE
		excluded.append(hit["rid"] as RID)
	return point


func _player() -> Node3D:
	return get_tree().get_first_node_in_group(PLAYER_GROUP) as Node3D


func _find_zone(zone_id: StringName) -> Node3D:
	if zone_id.is_empty():
		return null
	for node: Node in get_tree().get_nodes_in_group(ZONES_GROUP):
		if node.name == zone_id and node is Node3D:
			return node as Node3D
	return null


func _zones_parent() -> Node:
	var any_zone := get_tree().get_first_node_in_group(ZONES_GROUP)
	if any_zone != null:
		return any_zone.get_parent()
	return get_tree().current_scene


func _on_zone_entered(zone_id: StringName) -> void:
	_current_zone = zone_id
	GameState.zone = zone_id


func _on_player_died() -> void:
	# Seul le joueur mort réapparaît : s'il a quitté l'arbre entre-temps (retour au menu, fin
	# d'un test), rien ne se passe. Le délai s'arrête pendant la pause.
	var player := get_tree().get_first_node_in_group(PLAYER_GROUP)
	await get_tree().create_timer(respawn_delay, false).timeout
	if player != null and is_instance_valid(player) and player.is_inside_tree():
		respawn()
