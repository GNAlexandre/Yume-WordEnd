extends Node
## WorldManager : zones, points d'apparition, téléportation et réapparition (PLAN.md section 3).
## Propriétaire : L2.
##
## Implémentation minimale du Lot 0 :
## - les zones sont les nœuds du groupe "zones" (racines Zone nommées comme leur zone_id) ;
##   en M2, island.tscn les contient toutes ; load_zone() instancie
##   res://src/world/zones/<id>/<id>.tscn si la zone manque ;
## - teleport() place le joueur (groupe "player") sur un Marker3D de la zone ;
## - respawn() le ramène au Spawn du village et émet player_respawned (PlayerCombat remet
##   les PV au maximum) ; déclenché respawn_delay secondes après EventBus.player_died, si le
##   joueur mort est toujours dans l'arbre ;
## - zone_entered met à jour current_zone() et GameState.zone.

const VILLAGE := &"village"
const SPAWN_MARKER := &"Spawn"
const ZONES_GROUP := &"zones"
const PLAYER_GROUP := &"player"

## Délai entre la mort du joueur et sa réapparition (animation de mort + fondu, jeu.js : 2,2 s).
var respawn_delay: float = 2.2

var _current_zone: StringName = &""


func _ready() -> void:
	EventBus.zone_entered.connect(_on_zone_entered)
	EventBus.player_died.connect(_on_player_died)


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


## Place le joueur sur le Marker3D `marker` de la zone (et annule sa vitesse).
func teleport(zone_id: StringName, marker: StringName = SPAWN_MARKER) -> void:
	load_zone(zone_id)
	var zone := _find_zone(zone_id)
	var player := get_tree().get_first_node_in_group(PLAYER_GROUP) as Node3D
	if zone == null or player == null:
		return
	var target := zone.get_node_or_null(NodePath(String(marker))) as Node3D
	if target == null:
		target = zone.find_child(String(marker), true, false) as Node3D
	if target == null:
		return
	player.global_position = target.global_position
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO


## Réapparition au Spawn du village avec PV pleins (appliqués par PlayerCombat).
func respawn() -> void:
	teleport(VILLAGE, SPAWN_MARKER)
	EventBus.player_respawned.emit()


func current_zone() -> StringName:
	return _current_zone


## Nom affiché d'une zone (Zone.display_name), ou son identifiant à défaut.
func zone_display_name(zone_id: StringName) -> String:
	var zone := _find_zone(zone_id)
	if zone is Zone and not (zone as Zone).display_name.is_empty():
		return (zone as Zone).display_name
	return String(zone_id)


func _find_zone(zone_id: StringName) -> Node3D:
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
