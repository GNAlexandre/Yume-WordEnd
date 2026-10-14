class_name LifePlaces
extends RefCounted
## (E4) Les places d'une carte : les Marker3D nommés de son nœud Life/Places (refectoire_banc_3,
## champ_centre, archives_bureau…). Propriétaire : E4.
##
## Une place est un Marker3D : on s'y tient à sa position, tourné vers son −Z (comme les
## marqueurs d'arrivée). Ses enfants Marker3D en font une zone de points : les sièges d'une
## table (un PNJ par point, le premier libre), les deux bouts d'une conversation, les points où
## l'on erre, le terrain d'un jeu. La hauteur d'un point compte (un lit à 0,45 m) ; sur un sol
## en relief, poser le marqueur à la hauteur du sol (y du palier).
## Place spéciale : `vers_<carte>` (une carte à venir, « vers_entrepot_etage ») est le point par
## où l'on quitte la carte vers une carte qui n'a pas de sortie (MapExit) ici.

const DEPARTURE_PREFIX := "vers_"

## place → [Transform3D…] (repère du monde ; un seul point pour une place sans enfant).
var _points: Dictionary = {}


## Lit les places de map (Life/Places) ; une carte sans places n'en a aucune.
static func read(map: Node3D) -> LifePlaces:
	var places := LifePlaces.new()
	var root := map.get_node_or_null(NodePath(LifeData.PLACES_PATH)) if map != null else null
	if root == null:
		return places
	for child: Node in root.get_children():
		if not child is Marker3D:
			continue
		var marker := child as Marker3D
		var spots: Array[Transform3D] = []
		for child_point: Node in marker.get_children():
			if child_point is Marker3D:
				spots.append((child_point as Marker3D).global_transform)
		if spots.is_empty():
			spots.append(marker.global_transform)
		places._points[StringName(marker.name)] = spots
	return places


## Vrai si la place existe.
func has(place: StringName) -> bool:
	return _points.has(place)


## Noms des places.
func names() -> Array[StringName]:
	var result: Array[StringName] = []
	for key: StringName in _points:
		result.append(key)
	return result


## Points d'une place (repère du monde ; vide si elle n'existe pas).
func points(place: StringName) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	result.assign(_points.get(place, []))
	return result


## Nombre de points d'une place.
func size(place: StringName) -> int:
	return (_points.get(place, []) as Array).size()


## Point index d'une place (Transform3D.IDENTITY si elle n'existe pas).
func point(place: StringName, index: int) -> Transform3D:
	var list: Array = _points.get(place, [])
	if list.is_empty():
		return Transform3D.IDENTITY
	return list[clampi(index, 0, list.size() - 1)]


## Centre d'une place : la moyenne de ses points.
func center(place: StringName) -> Vector3:
	var list: Array = _points.get(place, [])
	if list.is_empty():
		return Vector3.INF
	var sum := Vector3.ZERO
	for xform: Transform3D in list:
		sum += xform.origin
	return sum / list.size()


## Rayon d'une place (plus grande distance au sol d'un point à son centre).
func radius(place: StringName) -> float:
	var middle := center(place)
	var result := 0.0
	for xform: Transform3D in _points.get(place, []):
		result = maxf(result, Vector2(xform.origin.x - middle.x, xform.origin.z - middle.z).length())
	return result


## Regard d'un point (son −Z, au sol).
static func facing_of(xform: Transform3D) -> Vector3:
	var forward := -xform.basis.z
	forward.y = 0.0
	return forward.normalized() if forward.length_squared() > 0.0001 else Vector3.FORWARD


## Place de départ vers une carte (« vers_<carte> »), &"" si la carte n'en a pas.
func departure(map_id: StringName) -> StringName:
	var place := StringName(DEPARTURE_PREFIX + String(map_id))
	return place if has(place) else &""
