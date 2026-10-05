extends RefCounted
## Fixture des tests du Lot 2 (pas de class_name) : l'île seule, sans le contenu des fichiers
## d'emplacement des autres lots (NPCs, Enemies, Pickups), pour tester le monde sans dépendre
## des PNJ, ennemis et objets que L5, L6 et L7 y posent.
##
##   const FIXTURE := preload("res://tests/stubs/l2_island_fixture.gd")
##   var island := FIXTURE.island()
##   add_child(island)

const ISLAND := preload("res://src/world/island.tscn")
const PLACEMENTS: Array[NodePath] = [^"NPCs", ^"Enemies", ^"Pickups"]


## Instance de island.tscn (hors de l'arbre) dont les emplacements des zones sont vidés.
static func island() -> Node3D:
	var node := ISLAND.instantiate() as Node3D
	for zone: Node in node.get_node(^"Zones").get_children():
		for path in PLACEMENTS:
			var placement := zone.get_node_or_null(path)
			if placement != null:
				for child: Node in placement.get_children():
					child.free()
	return node
