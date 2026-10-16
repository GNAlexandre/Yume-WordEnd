class_name FaunaPopulator
extends Node3D
## Peuple une carte de faune (lot E5) : le nœud « Fauna » (fauna.tscn) posé sous le nœud « Life »
## d'une carte. Il lit les groupes de sa carte dans data/fauna/<île>/peuplement.json
## (FaunaRules.entries_for) et fait vivre, selon GameState.moment et le temps qu'il fait :
## - les animaux (Animal, animal.tscn) des espèces que les règles de l'île permettent
##   (WorldAtlas.rules_for(carte).fauna) et que la carte n'interdit pas (régions sans animaux) ;
## - les bandes animées d'ambiance (papillons, libellules : AmbientSprites).
## Un groupe hors de saison est renvoyé (Animal.dismiss : les bêtes s'éloignent et disparaissent) ;
## un groupe de saison dont des bêtes ont fui ou se sont envolées est regarni plus tard, hors de la
## vue du joueur (au moins SPAWN_DISTANCE de lui et hors du champ de la caméra), au bout de
## respawn_s secondes. Au chargement de la carte, tout est posé tout de suite.
##
## Où : « at » est le nom d'un Marker3D de la carte (Life/Places, Markers…), « radius » le rayon
## autour de lui ; ou « rect » : [x0, z0, x1, z1] en m. Une meute (« pack ») est un AnimalPack.

signal group_filled(group_id: StringName, count: int)

const ANIMAL_SCENE := preload("res://src/fauna/animal.tscn")
const AmbientScript := preload("res://src/world/ambient_sprites.gd")
## Distance minimale (m) au joueur d'une bête qui apparaît après coup, et période du contrôle (s).
const SPAWN_DISTANCE := 14.0
const CHECK_PERIOD := 1.0

## Graine fixe du tirage des bêtes (0 : au hasard). Pour les démonstrations et les captures, qui
## doivent rejouer la même scène sur toutes les machines (tools/e5_shots.sh).
static var fixed_seed: int = 0

## Carte à peupler ; vide : celle qui contient ce nœud.
@export var map_id: StringName = &""

var _groups: Array[Dictionary] = []
var _clock: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	if fixed_seed != 0:
		_rng.seed = fixed_seed
	else:
		_rng.randomize()
	if map_id.is_empty():
		var map := WorldAtlas.map_of_node(self)
		map_id = map.map_id() if map != null else &""
	_read_groups()
	EventBus.atmosphere_changed.connect(_on_atmosphere_changed)
	refresh(true)


## Groupes de la carte, lus du peuplement ; un groupe d'une espèce que les règles refusent ou dont
## le fichier manque est écarté (FaunaRules.problems le signale).
func _read_groups() -> void:
	_groups.clear()
	var island_id := WorldAtlas.island_of(map_id)
	if map_id.is_empty() or FaunaRules.is_banned(map_id, _region()):
		return
	for entry: Dictionary in FaunaRules.entries_for(map_id):
		if not FaunaRules.entry_problem(entry).is_empty():
			continue
		var species_id := StringName(str(entry["species"]))
		var data := FaunaRules.species(island_id, species_id)
		if data == null or not FaunaRules.island_allows(map_id, species_id):
			continue
		(
			_groups
			. append(
				{
					"id": StringName(str(entry["id"])),
					"entry": entry,
					"data": data,
					"animals": [] as Array[Animal],
					"pack": null,
					"ambient": null,
					"timer": 0.0,
					"wanted": false,
					"serial": 0,
				}
			)
		)


func _region() -> StringName:
	var map := WorldAtlas.map_of_node(self)
	return map.region if map != null else &""


## Identifiants des groupes que la carte porte.
func group_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for group: Dictionary in _groups:
		ids.append(group["id"])
	return ids


## Animaux vivants d'un groupe (tous si group_id est vide).
func animals(group_id: StringName = &"") -> Array[Animal]:
	var result: Array[Animal] = []
	for group: Dictionary in _groups:
		if group_id.is_empty() or group["id"] == group_id:
			for animal: Animal in _alive(group):
				result.append(animal)
	return result


## Bande d'ambiance d'un groupe (null si ce n'en est pas un).
func ambient_of(group_id: StringName) -> Node3D:
	var group := _group(group_id)
	return group["ambient"] as Node3D if not group.is_empty() else null


## Le groupe est-il de saison (moment, temps) ?
func is_wanted(group_id: StringName) -> bool:
	var group := _group(group_id)
	return bool(group.get("wanted", false))


## Compare chaque groupe à la saison : renvoie ceux qui n'y sont plus, regarnit ceux qui y sont.
## fill_all : tout poser tout de suite (chargement de la carte), sans se soucier de la vue.
func refresh(fill_all: bool = false) -> void:
	for group: Dictionary in _groups:
		var data := group["data"] as AnimalData
		var wanted := FaunaRules.entry_wanted(
			group["entry"], data, GameState.moment, GameState.weather
		)
		group["wanted"] = wanted
		if data.behavior == AnimalData.AMBIENT:
			_refresh_ambient(group, wanted)
		elif not wanted:
			for animal: Animal in _alive(group):
				animal.dismiss()
			group["animals"] = [] as Array[Animal]
			group["pack"] = null
		else:
			_refill(group, fill_all)


func _refresh_ambient(group: Dictionary, wanted: bool) -> void:
	var node := group["ambient"] as Node3D
	if wanted and node == null:
		node = _make_ambient(group)
		group["ambient"] = node
		group_filled.emit(group["id"], 1)
	if node != null:
		node.visible = wanted


func _make_ambient(group: Dictionary) -> Node3D:
	var data := group["data"] as AnimalData
	var node := AmbientScript.new() as AmbientSprites
	node.name = "Ambient_%s" % group["id"]
	node.texture = data.ambient_texture
	node.frames = data.ambient_frames
	node.fps = data.ambient_fps
	node.motion = data.ambient_motion as AmbientSprites.Motion
	node.count = data.ambient_count
	node.lift = data.ambient_lift
	node.speed = data.ambient_speed
	node.sway = data.ambient_sway
	node.region_size = Vector2.ONE * data.ambient_region_m
	var center := _center(group["entry"])
	node.position = to_local(center)
	add_child(node)
	return node


## Complète le groupe jusqu'à son effectif. fill_all : tout de suite, où que soit le joueur ; sinon
## chaque bête n'apparaît que hors de la vue du joueur (et loin de lui).
func _refill(group: Dictionary, fill_all: bool) -> void:
	var entry := group["entry"] as Dictionary
	var wanted_count := int(entry["count"])
	var alive := _alive(group)
	var missing := wanted_count - alive.size()
	if missing <= 0:
		return
	var pack := group["pack"] as AnimalPack
	if bool(entry.get("pack", false)) and (pack == null or pack.active().is_empty()):
		pack = AnimalPack.new()
		group["pack"] = pack
	var spawned := 0
	for _i in missing:
		var spot := _pick_spot(entry, fill_all)
		if spot == Vector3.INF:
			break
		group["serial"] = int(group["serial"]) + 1
		var animal := _make_animal(group, spot)
		if pack != null and bool(entry.get("pack", false)):
			pack.add(animal)
		(group["animals"] as Array[Animal]).append(animal)
		add_child(animal)
		spawned += 1
	if spawned > 0:
		group_filled.emit(group["id"], spawned)


func _make_animal(group: Dictionary, spot: Vector3) -> Animal:
	var animal := ANIMAL_SCENE.instantiate() as Animal
	animal.data = group["data"]
	animal.name = "%s_%d" % [group["id"], group["serial"]]
	animal.position = to_local(spot)
	return animal


## Un point praticable du groupe ; hors du chargement, hors de la vue et loin du joueur. Vector3.INF
## si aucun ne convient maintenant.
func _pick_spot(entry: Dictionary, anywhere: bool) -> Vector3:
	var ground := FaunaNav.ground_of(self)
	var center := _center(entry)
	for _try in 1 if anywhere else 10:
		var spot := _random_spot(ground, entry, center)
		if anywhere or _hidden(spot):
			return spot
	return Vector3.INF


func _random_spot(ground: MapGround, entry: Dictionary, center: Vector3) -> Vector3:
	if entry.has("rect"):
		var rect := entry["rect"] as Array
		for _try in 16:
			var spot := Vector3(
				_rng.randf_range(float(rect[0]), float(rect[2])),
				0.0,
				_rng.randf_range(float(rect[1]), float(rect[3]))
			)
			if FaunaNav.can_stand(ground, spot):
				return FaunaNav.on_ground(ground, spot)
		return FaunaNav.on_ground(ground, center)
	var radius := float(entry.get("radius", FaunaRules.DEFAULT_RADIUS))
	return FaunaNav.random_spot(ground, center, radius, _rng)


## Centre du groupe : son marqueur (« at ») ou le milieu de son rectangle.
func _center(entry: Dictionary) -> Vector3:
	if entry.has("rect"):
		var rect := entry["rect"] as Array
		return Vector3(
			(float(rect[0]) + float(rect[2])) * 0.5, 0.0, (float(rect[1]) + float(rect[3])) * 0.5
		)
	var map := WorldAtlas.map_of_node(self)
	var marker: Node = null
	if map != null:
		marker = map.find_child(str(entry["at"]), true, false)
	if marker is Node3D:
		return (marker as Node3D).global_position
	push_warning("FaunaPopulator %s : marqueur « %s » introuvable" % [map_id, entry["at"]])
	return global_position


## Hors du champ de la caméra et à SPAWN_DISTANCE du joueur au moins.
func _hidden(spot: Vector3) -> bool:
	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	if player != null:
		var offset := spot - player.global_position
		offset.y = 0.0
		if offset.length() < SPAWN_DISTANCE:
			return false
	var camera := get_viewport().get_camera_3d()
	return camera == null or not camera.is_position_in_frustum(spot)


func _alive(group: Dictionary) -> Array[Animal]:
	var list: Array[Animal] = []
	# Variant : une bête déjà libérée ne se range pas dans un Array[Animal].
	for entry: Variant in group["animals"]:
		if not is_instance_valid(entry):
			continue
		var animal := entry as Animal
		if not animal.is_queued_for_deletion() and not animal.is_leaving():
			list.append(animal)
	group["animals"] = list
	return list


func _group(group_id: StringName) -> Dictionary:
	for group: Dictionary in _groups:
		if group["id"] == group_id:
			return group
	return {}


func _physics_process(delta: float) -> void:
	_clock += delta
	if _clock < CHECK_PERIOD:
		return
	_clock = 0.0
	_tick(CHECK_PERIOD)


## Un contrôle : un groupe de saison sans aucune bête est regarni dès qu'un point caché existe ;
## s'il lui en manque seulement, au bout de respawn_s.
func _tick(period: float) -> void:
	for group: Dictionary in _groups:
		var data := group["data"] as AnimalData
		if not bool(group["wanted"]) or data.behavior == AnimalData.AMBIENT:
			continue
		var entry := group["entry"] as Dictionary
		if _alive(group).size() >= int(entry["count"]):
			group["timer"] = 0.0
			continue
		group["timer"] = float(group["timer"]) + period
		var empty := _alive(group).is_empty()
		if (
			empty
			or float(group["timer"]) >= float(entry.get("respawn_s", FaunaRules.DEFAULT_RESPAWN))
		):
			_refill(group, false)
			group["timer"] = 0.0


func _on_atmosphere_changed(_moment: StringName, _weather: StringName) -> void:
	refresh()
