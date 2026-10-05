class_name Arena
extends Node3D
## Arène : zone de combat à vagues (PLAN.md sections 3 et 4). Propriétaire : L5.
##
## Structure figée de arena.tscn : racine Arena (Node3D) avec un enfant « WaveDirector ».
## Ajouts du Lot 5 : « Spawned » (Node3D qui reçoit les ennemis des vagues) et « Panel »
## (panneau « Affronter les Timeres » du groupe interactable, Area3D « InteractArea » couche 6)
## qui lance la série. Une arène est instanciée dans sa zone (ex. dunes.tscn) ; les points
## d'apparition (Marker3D nommés dans data/waves/<arena_id>.json, "spawn_points") sont des
## enfants de la zone, donc des frères de l'Arena : get_parent().get_node(nom). Les bornes sont
## le disque de rayon bounds_radius_m centré sur l'Arena : en sortir entre deux vagues termine
## la série.

## Identifiant de l'arène : data/waves/<arena_id>.json, clé des meilleurs scores.
@export var arena_id: StringName = &""
## Rayon des bornes de l'arène (m), autour de l'origine de l'Arena.
@export var bounds_radius_m: float = 12.0


## Marker3D d'apparition nommé marker_name, cherché parmi les frères de l'arène.
func spawn_point(marker_name: StringName) -> Marker3D:
	var parent := get_parent()
	if parent == null:
		return null
	return parent.get_node_or_null(NodePath(String(marker_name))) as Marker3D


## Le WaveDirector de l'arène.
func director() -> WaveDirector:
	return get_node_or_null(^"WaveDirector") as WaveDirector


## Vrai si point (position globale) est dans les bornes (distance horizontale au centre).
func contains(point: Vector3) -> bool:
	var offset := point - global_position
	return Vector2(offset.x, offset.z).length() <= bounds_radius_m


## Zone qui contient l'arène (zone_id() du premier ancêtre Zone), &"" hors d'une zone.
func zone_id() -> StringName:
	var node := get_parent()
	while node != null:
		if node is Zone:
			return (node as Zone).zone_id()
		node = node.get_parent()
	return &""
