extends LifeGame
## (E4) L'avalanche (V1 ; docs/lore/VIE.md, 5.3) : des petites collées à une porte pour épier
## (les points de la place, tournées vers la porte) ; quand le joueur l'ouvre ou la franchit
## (il arrive à trigger_distance de son milieu, ou les bouscule), elles s'écroulent les unes sur les autres (tombe),
## se relèvent, gênées, et s'enfuient en courant (vers la place flee, où elles disparaissent) ;
## cooldown s plus tard, elles reviennent épier. La porte : params.door, l'id d'une porte de
## l'intérieur (InteriorRoom.door_position) ou les deux pièces qu'elle sépare ([pièce, pièce]) ;
## sans porte, le milieu de la place. Paramètres : door, trigger_distance, fall_time, flee,
## cooldown, whisper.

enum Phase { GATHER, SPYING, FALLEN, FLEEING, AWAY }

var phase: Phase = Phase.GATHER
var door: Vector3 = Vector3.INF
var _left: float = 0.0
var _whisper: float = 4.0


func _setup() -> void:
	min_members = int(param("min_members", 1))


func _started() -> void:
	door = door_center(param("door", null))
	_gather()


func _member_added(actor: LifeActor) -> void:
	if running and (phase == Phase.GATHER or phase == Phase.SPYING):
		_send_to_door(actor)


func _gather() -> void:
	phase = Phase.GATHER
	for actor: LifeActor in members:
		actor.npc.visible = true
		_send_to_door(actor)


func _send_to_door(actor: LifeActor) -> void:
	# Chacune à son point de la place (celui que le directeur lui a donné).
	var spot := actor.spot
	var facing := door - spot.origin if door != Vector3.INF else LifePlaces.facing_of(spot)
	if LifeGame.flat_distance(actor.position(), spot.origin) < 0.05:
		actor.face(facing)
		return
	actor.walk_to(spot.origin, facing, &"marche", Callable())


func _tick(delta: float, player: Node3D) -> void:
	match phase:
		Phase.GATHER:
			var ready := true
			for actor: LifeActor in members:
				ready = ready and not actor.is_moving()
			if ready:
				phase = Phase.SPYING
				_emit(&"spying", members.size())
		Phase.SPYING:
			_tick_spying(delta, player)
		Phase.FALLEN:
			_left -= delta
			if _left <= 0.0:
				_flee()
		Phase.FLEEING:
			var gone := true
			for actor: LifeActor in members:
				if actor.is_moving():
					gone = false
				else:
					actor.npc.visible = false
			if gone:
				phase = Phase.AWAY
				_left = float(param("cooldown", 60.0))
		Phase.AWAY:
			_left -= delta
			if _left <= 0.0:
				_gather()


func _tick_spying(delta: float, player: Node3D) -> void:
	_whisper -= delta
	for actor: LifeActor in members:
		if not actor.is_holding():
			actor.play(&"repos")
			if door != Vector3.INF:
				actor.face(door - actor.position())
	if _whisper <= 0.0 and not members.is_empty():
		_whisper = rng.randf_range(4.0, 9.0)
		var who := members[rng.randi_range(0, members.size() - 1)]
		who.hold(&"parle", 1.2)
		who.npc.say(text("whisper", "Chut…"), 1.4)
	if player == null:
		return
	var near_door := door != Vector3.INF and (
		flat_distance(player.global_position, door) < float(param("trigger_distance", 1.1))
	)
	var bumped := false
	for actor: LifeActor in members:
		bumped = bumped or flat_distance(player.global_position, actor.position()) < 0.75
	if near_door or bumped:
		fall()


## L'avalanche : elles tombent (la porte s'ouvre, ou le joueur la franchit).
func fall() -> void:
	if phase != Phase.SPYING:
		return
	phase = Phase.FALLEN
	_left = float(param("fall_time", 1.8))
	for actor: LifeActor in members:
		actor.hold(&"tombe", _left)
	if not members.is_empty():
		members[0].npc.say(text("fall", "Waaah !"), 1.6)
	_emit(&"fell", members.size())


func _flee() -> void:
	phase = Phase.FLEEING
	var flee := StringName(str(param("flee", "")))
	var places := LifeDirector.places()
	var target := center()
	if places != null and places.has(flee):
		target = places.point(flee, 0).origin
	for i: int in members.size():
		var actor := members[i]
		if i == members.size() - 1:
			actor.npc.say(text("sorry", "On n’écoutait pas, promis !"), 2.0)
		actor.walk_to(target, target - actor.position(), &"course", Callable())
	_emit(&"fled", members.size())


func _finished() -> void:
	for actor: LifeActor in members:
		if is_instance_valid(actor.npc):
			actor.npc.visible = true


func _member_removed(actor: LifeActor) -> void:
	if is_instance_valid(actor.npc):
		actor.npc.visible = true


## Milieu au sol d'une porte de l'intérieur courant : spec = id (InteriorRoom.door_position) ou
## [pièce, pièce] (la porte entre ces deux pièces) ; Vector3.INF si elle n'existe pas.
static func door_center(spec: Variant) -> Vector3:
	var map := LifeDirector.current_map()
	var room := map.get_node_or_null(^"Ground") as InteriorRoom if map != null else null
	if room == null or room.plan == null or spec == null:
		return Vector3.INF
	if spec is String or spec is StringName:
		return room.door_position(StringName(spec))
	if spec is Array and (spec as Array).size() == 2:
		var pair := [room.plan.room_index(str(spec[0])), room.plan.room_index(str(spec[1]))]
		var found := Vector3.INF
		for opening: Dictionary in room.plan.doors:
			var sides := [int(opening.get("low", -1)), int(opening.get("high", -1))]
			if pair.has(sides[0]) and pair.has(sides[1]) and sides[0] != sides[1]:
				found = room.to_global(InteriorLayout.opening_center(opening))
				if opening.get("passable", true):
					return found
		return found
	return Vector3.INF
