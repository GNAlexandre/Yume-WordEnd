extends Node3D
## (E3) Stub local de Map (src/world/map.gd, class_name Map, lot E1, créé en parallèle) : les
## exports du contrat des cartes (docs/REFONTE.md, section 7.1), rien d'autre. La carte d'essai
## des intérieurs (src/world/maps/entrepot_rdc_essai/) l'a pour racine jusqu'à la fusion avec E1 :
## il suffira de remplacer ce script par src/world/map.gd (docs/CONTRACT_REQUESTS.md, E3).

@export var display_name: String = ""
@export var region: StringName = &""
@export var interior: bool = false
@export var size: Vector2 = Vector2.ZERO
@export var camera_bounds: Rect2 = Rect2()
@export var light_preset: StringName = &""
