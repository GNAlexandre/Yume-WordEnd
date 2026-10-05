class_name ItemData
extends Resource
## Objet d'inventaire. Fichiers : data/items/<id>.tres. Propriétaire : L7.

## Identifiant, ex. &"page_fragment" (clé de GameState.add_item / count).
@export var id: StringName
## Nom affiché.
@export var display_name: String = ""
## Icône de l'inventaire.
@export var icon: Texture2D
## Empilable dans une seule case.
@export var stackable: bool = true
## Quantité maximale par case.
@export var max_stack: int = 99
## Description affichée dans l'inventaire.
@export_multiline var description: String = ""
