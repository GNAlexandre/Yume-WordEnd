class_name ItemData
extends Resource
## Objet d'inventaire. Fichiers : data/items/<id>.tres (le nom du fichier est l'id).
## Propriétaire : L7.
##
## Piles : un objet empilable (stackable) occupe une case par tranche de max_stack ; un objet
## non empilable occupe une case par exemplaire. GameState garde le total par objet (schéma de
## sauvegarde) et en déduit les piles (GameState.stacks()).

## Dossier des données d'objets.
const DATA_DIR := "res://data/items"

## Identifiant, ex. &"page_fragment" (clé de GameState.add_item / count).
@export var id: StringName
## Nom affiché.
@export var display_name: String = ""
## Icône de l'inventaire et du pickup (64 × 64, assets/items/<id>.png).
@export var icon: Texture2D
## Empilable dans une seule case.
@export var stackable: bool = true
## Quantité maximale par case.
@export var max_stack: int = 99
## Description affichée dans l'inventaire.
@export_multiline var description: String = ""
## Couleur dominante : halo du pickup dans le monde.
@export var color: Color = Color(1.0, 0.86, 0.45)


## Données de l'objet item_id (data/items/<id>.tres), null s'il est inconnu.
static func find(item_id: StringName) -> ItemData:
	if not String(item_id).is_valid_identifier():
		return null
	var path := "%s/%s.tres" % [DATA_DIR, item_id]
	if not ResourceLoader.exists(path):
		return null
	return load(path) as ItemData


## Nom affiché de item_id, ou son id s'il est inconnu.
static func display_name_of(item_id: StringName) -> String:
	var data := find(item_id)
	return (
		data.display_name if data != null and not data.display_name.is_empty() else String(item_id)
	)


## Tailles des piles nécessaires pour ranger quantity exemplaires (ex. 120 → [99, 21]).
func stack_sizes(quantity: int) -> Array[int]:
	var sizes: Array[int] = []
	var per_stack := maxi(max_stack, 1) if stackable else 1
	var left := quantity
	while left > 0:
		var size := mini(left, per_stack)
		sizes.append(size)
		left -= size
	return sizes
