class_name Arena
extends Node3D
## Arène : zone de combat à vagues (PLAN.md sections 3 et 4). Propriétaire : L5.
##
## Structure figée de arena.tscn : racine Arena (Node3D) avec un enfant « WaveDirector ».
## Une arène est instanciée dans sa zone (ex. src/world/zones/dunes/dunes.tscn) ; les points
## d'apparition (Marker3D nommés dans data/waves/<arena_id>.json, "spawn_points") sont des
## enfants de la zone, donc des frères de l'Arena : get_parent().get_node(nom).

## Identifiant de l'arène : data/waves/<arena_id>.json, clé des meilleurs scores.
@export var arena_id: StringName = &""


## Marker3D d'apparition nommé marker_name, cherché parmi les frères de l'arène.
func spawn_point(marker_name: StringName) -> Marker3D:
	var parent := get_parent()
	if parent == null:
		return null
	return parent.get_node_or_null(NodePath(String(marker_name))) as Marker3D
