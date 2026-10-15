extends GutTest
## Base des tests de la faune (lot E5), dont ils héritent par chemin (pas de class_name, règle des
## stubs) : un sol plat, un joueur factice (tests/stubs/player_stub.tscn), des animaux faits de
## leurs vraies données (data/fauna/ile_68/) et le hasard global semé. Hors de toute carte, les
## règles de l'île ne s'appliquent pas (FaunaRules.allowed_at : permis), sauf quand le test pose
## l'animal dans une Map.
##
## Le joueur factice ne bouge pas : sa vitesse (velocity) dit le bruit qu'il fait aux animaux (0 :
## immobile, 3 : il marche, 6 : il court ; AnimalData.noise_*).

const PLAYER_STUB := preload("res://tests/stubs/player_stub.tscn")
const ANIMAL_SCENE := preload("res://src/fauna/animal.tscn")
const SWORD := preload("res://data/attacks/sword_1.tres")
const ISLAND := &"ile_68"
const RANDOM_SEED := 20261014
const WALK := 3.0
const RUN := 6.5

var world: Node3D
var player: CharacterBody3D


func before_each() -> void:
	seed(RANDOM_SEED)
	GameState.reset()
	FaunaRules.clear_cache()
	WorldAtlas.set_data_dirs()
	world = add_child_autofree(Node3D.new())
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200.0, 1.0, 200.0)
	shape.shape = box
	ground.add_child(shape)
	ground.position = Vector3(0.0, -0.5, 0.0)
	world.add_child(ground)


func after_each() -> void:
	GameState.reset()
	FaunaRules.clear_cache()
	WorldAtlas.set_data_dirs()


## Le joueur factice en at, qui fait le bruit d'une vitesse de speed m/s.
func make_player(at: Vector3 = Vector3.ZERO, speed: float = WALK) -> CharacterBody3D:
	player = PLAYER_STUB.instantiate() as CharacterBody3D
	player.position = at
	world.add_child(player)
	player.velocity = Vector3(speed, 0.0, 0.0)
	var health := player.get_node(^"Health") as Health
	health.max_hp = 500
	health.reset()
	return player


## Un animal de l'espèce species_id, posé en at (sous parent, le monde par défaut).
func make_animal(species_id: StringName, at: Vector3, parent: Node = null) -> Animal:
	var animal := ANIMAL_SCENE.instantiate() as Animal
	animal.data = FaunaRules.species(ISLAND, species_id)
	animal.position = at
	(parent if parent != null else world).add_child(animal)
	return animal


## Distance horizontale entre deux nœuds.
func flat_distance(a: Node3D, b: Node3D) -> float:
	var offset := a.global_position - b.global_position
	return Vector2(offset.x, offset.z).length()


## Un coup d'épée sur animal, venu de from (par défaut à sa gauche).
func strike(animal: Animal, from: Vector3 = Vector3.INF) -> bool:
	var source := Node3D.new()
	world.add_child(source)
	source.global_position = (
		animal.global_position + Vector3(-1.0, 0.0, 0.0) if from == Vector3.INF else from
	)
	var accepted := animal.hurtbox.receive_hit(SWORD, source)
	source.queue_free()
	return accepted


## Vrai si l'animal est toujours dans la partie : valide, dans l'arbre, pas en cours de libération.
func is_around(animal: Variant) -> bool:
	return (
		is_instance_valid(animal)
		and (animal as Node).is_inside_tree()
		and not (animal as Node).is_queued_for_deletion()
	)


## Attend (jusqu'à timeout s) que l'animal ait quitté la partie. La référence est faible : la
## fonction d'attente ne garde pas l'animal, que sa libération invaliderait.
func wait_gone(animal: Animal, timeout: float) -> bool:
	var ref: WeakRef = weakref(animal)
	var gone: bool = await wait_until(
		func() -> bool:
			var node := ref.get_ref() as Node
			return node == null or node.is_queued_for_deletion() or not node.is_inside_tree(),
		timeout
	)
	return gone
