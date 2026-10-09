extends Node3D
## (E2) Remplaçant local de Map (src/world/map.gd, lot E1, docs/REFONTE.md section 7.1), le temps
## que les deux lots se rejoignent : mêmes exports que le contrat, aucun comportement. La carte de
## démonstration du sol en relief (src/world/maps/essai_relief/essai_relief.tscn) s'en sert comme
## script de racine ; à la fusion avec E1, la racine prend res://src/world/map.gd (une ligne de la
## scène) et ce fichier disparaît (docs/CONTRACT_REQUESTS.md, « E2 »).

## Nom affiché à l'entrée.
@export var display_name: String = ""
## Lieu sur la carte de l'île.
@export var region: StringName = &""
@export var interior: bool = false
## Largeur et profondeur (m).
@export var size: Vector2 = Vector2.ZERO
## Bornes du point visé par la caméra (x, z) ; vide : la carte entière.
@export var camera_bounds: Rect2 = Rect2()
## Préréglage de lumière (E9) ; vide : celui du moment de la journée.
@export var light_preset: StringName = &""
