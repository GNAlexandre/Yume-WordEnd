extends GutTest
## Chemins praticables : une capsule de la taille du joueur suit chaque itinéraire principal
## (entrepôt → Spawn de chaque zone, cercle de veille, terrain d'entraînement, marais, rue du
## Port et quai, belvédère ; docs/lore/MONDE.md, section 2.7) au ras du sol sans toucher aucun
## décor (couche world, hors sol). Les portails de la palissade sont donc ouverts.

const FIXTURE := preload("res://tests/stubs/l2_island_fixture.gd")
## Itinéraires en coordonnées de l'île (x, z), le long des chemins.
const ROUTES := {
	"entrepôt → Couchant": [Vector2(0, 9), Vector2(-3, 3), Vector2(-9, 0), Vector2(-27, 0)],
	"entrepôt → bois":
	[Vector2(0, 9), Vector2(3, 3), Vector2(3, -3), Vector2(0, -9), Vector2(0, -27)],
	"entrepôt → port": [Vector2(0, 9), Vector2(0, 27)],
	"entrepôt → colline": [Vector2(0, 9), Vector2(3, 3), Vector2(9, 0), Vector2(27, 0)],
	"Couchant → cercle de veille": [Vector2(-27, 0), Vector2(-51, 0)],
	"bois → terrain d'entraînement": [Vector2(0, -27), Vector2(0, -51)],
	"bois → marais": [Vector2(1, -30), Vector2(-8, -38), Vector2(-15, -46), Vector2(-19, -51.5)],
	"port → quai":
	[Vector2(0, 27), Vector2(1.5, 33), Vector2(1, 44), Vector2(1.5, 55), Vector2(2, 60)],
	"rue du Port, ouest": [Vector2(1, 45), Vector2(-33, 45)],
	"rue du Port, est": [Vector2(1, 45), Vector2(33, 45)],
	"colline → belvédère": [Vector2(27, 0), Vector2(38, -2.5), Vector2(52, -3)],
}
const STEP := 0.5
const CLEARANCE := 0.2

var _island: Node3D


func before_all() -> void:
	_island = FIXTURE.island()
	add_child(_island)
	await wait_physics_frames(2)


func after_all() -> void:
	_island.free()


func test_main_routes_are_clear() -> void:
	var space := _island.get_world_3d().direct_space_state
	var ground := _island.get_node(^"Ground")
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.5
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = 1
	for route: String in ROUTES:
		var points: Array = ROUTES[route]
		var blocked: Array[String] = []
		for k in points.size() - 1:
			var a: Vector2 = points[k]
			var b: Vector2 = points[k + 1]
			var steps := ceili(a.distance_to(b) / STEP)
			for s in steps + 1:
				var p := a.lerp(b, float(s) / steps)
				var y := _floor_height(p) + CLEARANCE + capsule.height / 2.0
				query.transform = Transform3D(Basis.IDENTITY, Vector3(p.x, y, p.y))
				for hit: Dictionary in space.intersect_shape(query, 4):
					if hit["collider"] != ground:
						blocked.append("%s (%s)" % [p, (hit["collider"] as Node).get_parent().name])
		assert_eq(blocked, [] as Array[String], "%s : rien sur le chemin" % route)


## Hauteur du sol ou du plateau du belvédère (marche de 5 cm au-dessus du relief).
func _floor_height(p: Vector2) -> float:
	var h := IslandTerrain.height_at(p.x, p.y)
	if p.distance_to(IslandTerrain.HILL_CENTER) < 3.8:
		h += 0.05
	return h
