extends LifeGame
## (E4) La course du couloir (V5 ; V1 ; docs/lore/VIE.md, 5.6) : deux ou trois petites partent
## ensemble de la ligne de départ et courent vers l'arrivée, le dessert du soir en jeu ; une
## grande ou Nygglatho (rôle « gronde » de sa ligne), postée sur le parcours, les gronde (poings
## sur les hanches) : on ne court pas dans les couloirs ; elles finissent en marchant, la première
## arrivée lève les bras. Puis elles reviennent au départ et recommencent un peu plus tard.
## Points de la place : 0 départ, 1 arrivée, 2 (facultatif) poste de celle qui gronde (sinon le
## milieu). Le joueur entre en se tenant près du départ quand elles s'alignent : il court avec
## elles et peut gagner. Paramètres : ready_time, pause, scold_radius, lane.

const SCOLDER := &"gronde"
const RUNNER := &"coureuse"

enum Phase { GATHER, READY, RUN, PAUSE }

var phase: Phase = Phase.GATHER
var scolded: bool = false
var winner: StringName = &""
var _left: float = 0.0
var _arrived: Array[StringName] = []


func _setup() -> void:
	join_distance = float(param("join_distance", 2.0))
	leave_distance = float(param("leave_distance", 6.0))


func _member_added(actor: LifeActor) -> void:
	if role_of(actor) != SCOLDER:
		set_role(actor, RUNNER)
	if running:
		_send_to_post(actor)


func _started() -> void:
	for actor: LifeActor in members:
		_send_to_post(actor)
	phase = Phase.GATHER


func runners() -> Array[LifeActor]:
	return with_role(RUNNER)


func _point(index: int) -> Transform3D:
	var places := LifeDirector.places()
	if places == null or places.size(place) == 0:
		return Transform3D.IDENTITY
	if index >= places.size(place):
		var a := places.point(place, 0).origin
		var b := places.point(place, 1).origin
		return Transform3D(Basis.IDENTITY, (a + b) / 2.0)
	return places.point(place, index)


## Couloir de course d'une coureuse (décalage latéral, lane m entre deux).
func _lane(actor: LifeActor, at: Vector3, toward: Vector3) -> Vector3:
	var list := runners()
	var index := list.find(actor)
	var lane := float(param("lane", 0.6))
	var forward := (toward - at)
	forward.y = 0.0
	forward = forward.normalized()
	var side := Vector3(-forward.z, 0.0, forward.x)
	return at + side * (index - (list.size() - 1) / 2.0) * lane


func _send_to_post(actor: LifeActor) -> void:
	if role_of(actor) == SCOLDER:
		var post := _point(2)
		actor.walk_to(post.origin, LifePlaces.facing_of(post), &"marche", Callable())
		return
	var start := _point(0).origin
	var finish := _point(1).origin
	var at := _lane(actor, start, finish)
	actor.walk_to(at, finish - start, &"marche", Callable())


func _tick(delta: float, player: Node3D) -> void:
	var start := _point(0).origin
	var finish := _point(1).origin
	match phase:
		Phase.GATHER:
			var ready := true
			for actor: LifeActor in runners():
				if actor.is_moving():
					ready = false
				else:
					actor.play(&"repos")
					actor.face(finish - start)
			if ready and not runners().is_empty():
				phase = Phase.READY
				_left = float(param("ready_time", 1.6))
				runners()[0].npc.say(text("start", "Le premier arrivé a deux desserts !"))
		Phase.READY:
			_left -= delta
			if _left <= 0.0:
				_go(start, finish)
		Phase.RUN:
			_tick_run(player, finish)
		Phase.PAUSE:
			_left -= delta
			if _left <= 0.0:
				phase = Phase.GATHER
				for actor: LifeActor in runners():
					_send_to_post(actor)
	for actor: LifeActor in with_role(SCOLDER):
		if not actor.is_moving() and not actor.is_holding():
			actor.play(&"repos")


func _go(start: Vector3, finish: Vector3) -> void:
	phase = Phase.RUN
	scolded = false
	winner = &""
	_arrived.clear()
	_emit(&"race_started", runners().size())
	for actor: LifeActor in runners():
		actor.walk_to(_lane(actor, finish, start + (finish - start) * 2.0), finish - start, &"course", Callable())


func _tick_run(player: Node3D, finish: Vector3) -> void:
	var scold_radius := float(param("scold_radius", 2.5))
	var scolders := with_role(SCOLDER)
	for actor: LifeActor in runners():
		if actor.is_moving():
			if not scolded:
				for scolder: LifeActor in scolders:
					if flat_distance(scolder.position(), actor.position()) < scold_radius:
						_scold(scolder)
			continue
		if not _arrived.has(actor.id):
			_arrived.append(actor.id)
			if winner.is_empty():
				winner = actor.id
				actor.hold(&"saut", 1.0)
				actor.npc.say(text("won", "Gagné !"))
				_emit(&"race_won", actor.id)
	if player_in and player != null and winner.is_empty():
		if flat_distance(player.global_position, finish) < 1.2:
			winner = &"player"
			var first := runners()[0] if not runners().is_empty() else null
			if first != null:
				first.npc.say(text("player_won", "{player} a gagné le dessert !"))
			_emit(&"race_won", &"player")
	if _arrived.size() >= runners().size():
		phase = Phase.PAUSE
		_left = LifeData.pose_time({"time": param("pause", [8.0, 12.0])}, rng)
		if player_in:
			leave_player()


func _scold(scolder: LifeActor) -> void:
	scolded = true
	scolder.hold(&"hanches", 3.0)
	scolder.npc.say(text("scold", "On ne court pas dans les couloirs !"))
	_emit(&"scolded", scolder.id)
	for actor: LifeActor in runners():
		if actor.is_moving():
			actor.walk_to(actor.goal(), actor.goal() - actor.position(), &"marche", Callable(), true)


func _accepts_player() -> bool:
	return phase == Phase.GATHER or phase == Phase.READY


func _player_close(player: Node3D) -> bool:
	return flat_distance(player.global_position, _point(0).origin) < join_distance


func _player_far(player: Node3D) -> bool:
	return phase != Phase.RUN and flat_distance(player.global_position, _point(0).origin) > leave_distance
