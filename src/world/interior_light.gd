extends Node3D
## (E3) Lumière d'une carte intérieure, en attendant les préréglages de E9 (comme
## src/world/map_light.tscn pour les cartes du dehors) : racine de src/world/interior_light.tscn,
## instanciée dans la carte (nœud « Light »). Ses enfants WorldEnvironment (fond VOID_COLOR, aucun
## ciel n'est visible) et Sun reçoivent à l'entrée le préréglage de la carte (preset :
## « interieur », src/world/materials/lighting_interieur.tres), qui règle aussi l'étalonnage de
## la caméra du joueur et la teinte des personnages. En partant, elle rend à la caméra et aux
## personnages le réglage par défaut (le couchant de l'île), que les cartes du dehors supposent.
## Le moment de la journée d'un intérieur passe par InteriorRoom.apply_phase (fenêtres, lampes).

## Préréglage posé à l'entrée.
@export var preset: HD2DLighting = preload("res://src/world/materials/lighting_interieur.tres")


func _ready() -> void:
	if preset != null:
		preset.apply(self)


func _exit_tree() -> void:
	# Les enfants (WorldEnvironment, Sun) ont déjà quitté l'arbre : le réglage par défaut se pose
	# par la carte (sans environnement ni soleil à elle), pour l'étalonnage et les personnages.
	var map := get_parent() as Node3D
	if preset != null and map != null and map.is_inside_tree():
		HD2DLighting.for_phase(&"day").apply(map)
