extends GutTest
## (V1) La navigation sur les vraies cartes de l'entrepôt : chaque place nommée par un emploi du temps de
## data/life/ile_68/ (et chacun de ses points) est atteignable à pied depuis le point d'arrivée de la carte,
## par un chemin dégagé qui finit dans la même pièce (dedans) ou à la bonne hauteur (dehors) ; chaque
## carte a ses départs `vers_<carte>` ; aucune place n'est posée dans un mur.

const MAPS: Array[StringName] = [&"entrepot_rdc", &"entrepot_etage", &"entrepot_toit", &"entrepot"]
## Distance au sol où le dernier pas se fait « tout droit » (un siège derrière une chaise, un lit) : on
## accepte une case libre à moins de ce rayon.
const SEAT_REACH := 1.7

var _navs: Dictionary = {}
var _maps: Dictionary = {}


func before_all() -> void:
	GameState.reset()
	LifeData.use_content(&"ile_68")
	for map_id: StringName in MAPS:
		var map := (load(Map.scene_path(map_id)) as PackedScene).instantiate() as Map
		add_child(map)
		var nav := LifeNav.for_map(map)
		nav.build_now()
		_maps[map_id] = map
		_navs[map_id] = nav


func after_all() -> void:
	for map: Node in _maps.values():
		map.queue_free()
	_maps.clear()
	_navs.clear()
	LifeData.use_content(&"")


## Places (par carte) que les emplois du temps nomment.
func _wanted() -> Dictionary:
	var wanted := {}
	for npc_id: StringName in LifeData.cast():
		for line: Dictionary in LifeData.schedule(npc_id).get("lines", []):
			var map_id: StringName = line["map"]
			if map_id.is_empty():
				continue
			var list: Dictionary = wanted.get(map_id, {})
			list[line["place"]] = true
			wanted[map_id] = list
	return wanted


func _start_of(map: Map) -> Vector3:
	var spawn := map.spawn()
	return spawn.global_position if spawn != null else Vector3(map.size.x / 2.0, 0.0, map.size.y / 2.0)


func _room_of(map: Map, at: Vector3) -> StringName:
	var room := map.get_node_or_null(^"Ground") as InteriorRoom
	return room.room_at(at.x, at.z) if room != null else &""


func test_the_schedules_only_name_the_maps_of_the_warehouse() -> void:
	var wanted := _wanted()
	for map_id: StringName in wanted:
		assert_true(MAPS.has(map_id), "%s : une carte de l'entrepôt" % map_id)
	for map_id: StringName in MAPS:
		assert_true(wanted.has(map_id) or map_id == &"entrepot_toit", "%s : de la vie" % map_id)


func test_every_named_place_is_reachable_on_foot() -> void:
	var wanted := _wanted()
	var checked := 0
	for map_id: StringName in wanted:
		var map: Map = _maps[map_id]
		var nav: LifeNav = _navs[map_id]
		var places := LifePlaces.read(map)
		var start := _start_of(map)
		for place: StringName in wanted[map_id]:
			assert_true(places.has(place), "%s/%s : la place existe" % [map_id, place])
			for index: int in places.size(place):
				var spot := places.point(place, index)
				var goal := spot.origin
				var path := nav.find_path(start, goal)
				assert_false(path.is_empty(), "%s/%s p%d : un chemin depuis l'arrivée" % [map_id, place, index + 1])
				if path.is_empty():
					continue
				checked += 1
				var last := path[path.size() - 1]
				var gap := Vector2(last.x - goal.x, last.z - goal.z).length()
				assert_lt(
					gap, SEAT_REACH, "%s/%s p%d : le chemin finit près du point (%.2f m)" % [map_id, place, index + 1, gap]
				)
				assert_eq(
					_room_of(map, last),
					_room_of(map, goal),
					"%s/%s p%d : dans la même pièce" % [map_id, place, index + 1]
				)
				var previous := start
				for point: Vector3 in path:
					assert_true(
						nav.line_clear(previous, point), "%s/%s p%d : chemin dégagé" % [map_id, place, index + 1]
					)
					previous = point
	gut.p("%d chemins vérifiés" % checked)
	assert_gt(checked, 150, "toutes les places de la vie sont éprouvées")


func test_places_stand_on_the_ground() -> void:
	for map_id: StringName in [&"entrepot"]:
		var map: Map = _maps[map_id]
		var nav: LifeNav = _navs[map_id]
		var places := LifePlaces.read(map)
		for place: StringName in places.names():
			for spot: Transform3D in places.points(place):
				var ground := nav.height_at(spot.origin.x, spot.origin.z)
				assert_gte(spot.origin.y, ground - 0.15, "%s : pas sous le sol" % place)
				if not String(place).begins_with("arbre_"):
					assert_almost_eq(spot.origin.y, ground, 0.35, "%s : posée au sol" % place)


func test_every_map_has_its_departures() -> void:
	var expected := {
		&"entrepot_rdc": [&"vers_entrepot", &"vers_entrepot_etage"],
		&"entrepot_etage": [&"vers_entrepot_rdc", &"vers_entrepot_toit"],
		&"entrepot_toit": [&"vers_entrepot_etage"],
		&"entrepot": [&"vers_entrepot_rdc", &"vers_sentier", &"vers_village"],
	}
	for map_id: StringName in expected:
		var places := LifePlaces.read(_maps[map_id])
		for place: StringName in expected[map_id]:
			assert_true(places.has(place), "%s : %s" % [map_id, place])
			var spot := places.point(place, 0).origin
			var nav: LifeNav = _navs[map_id]
			assert_true(nav.is_walkable_point(spot.x, spot.z), "%s/%s : on y marche" % [map_id, place])
	# Le premier départ de chaque carte est le repli des cartes à venir.
	for map_id: StringName in [&"entrepot_rdc", &"entrepot_etage", &"entrepot"]:
		var first := &""
		for place: StringName in LifePlaces.read(_maps[map_id]).names():
			if String(place).begins_with(LifePlaces.DEPARTURE_PREFIX):
				first = place
				break
		assert_false(first.is_empty(), "%s : un départ" % map_id)
