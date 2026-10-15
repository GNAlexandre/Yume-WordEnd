extends LifeGame
## (E4) La tour de fées sur Willem (VEX ; docs/lore/VIE.md, 5.7) : un tableau animé. La base
## (rôle « base » de sa ligne : Willem) s'assoit par terre au premier point de la place ; les
## autres attendent assises aux points suivants, puis, l'une après l'autre (dans l'ordre de leur
## rôle « pile_1 », « pile_2 »…, sinon d'arrivée), sautent sur la pile : la première collée à son
## dos, les suivantes empilées. Les planches n'ont pas de pose empilée : chaque étage décale le
## sprite en hauteur et vers la caméra (son ordre d'affichage, LEVELS). Pleine, la pile tient un
## moment, puis s'écroule dans les rires (tombe ; la base s'effondre, effondre) ; on se relève, on
## se rassoit, on recommence. Le joueur, en parlant à l'une d'elles pendant la pile, prend son
## élan… et s'arrête au bord, rouge (le gag). Paramètres : stack_time, hold_time, rest_time.

enum Phase { GATHER, STACK, HOLD, FALLEN, REST }

const BASE := &"base"
## Étages de la pile autour de la base : décalage (x, y, z) en m (z > 0 : vers la caméra, donc
## dessiné devant) et pose.
const LEVELS: Array = [
	[Vector3(0.0, 0.35, -0.12), &"grimpe"],
	[Vector3(0.26, 0.85, 0.06), &"assis"],
	[Vector3(-0.24, 1.3, 0.1), &"assis"],
	[Vector3(0.2, 1.72, 0.14), &"grimpe"],
	[Vector3(-0.16, 2.12, 0.18), &"assis"],
	[Vector3(0.1, 2.5, 0.22), &"grimpe"],
]

var phase: Phase = Phase.GATHER
var stacked: Array[LifeActor] = []
var _left: float = 0.0


func _setup() -> void:
	min_members = int(param("min_members", 2))


func base_actor() -> LifeActor:
	var bases := with_role(BASE)
	return bases[0] if not bases.is_empty() else null


## Les grimpeuses, dans l'ordre de la pile.
func climbers() -> Array[LifeActor]:
	var result: Array[LifeActor] = []
	for actor: LifeActor in members:
		if role_of(actor) != BASE:
			result.append(actor)
	result.sort_custom(
		func(a: LifeActor, b: LifeActor) -> bool: return String(a.role) < String(b.role)
	)
	return result


func _started() -> void:
	_gather()


func _member_added(_actor: LifeActor) -> void:
	if running and phase == Phase.GATHER:
		_resend_homes()


func _member_removed(actor: LifeActor) -> void:
	stacked.erase(actor)
	if running and phase == Phase.GATHER:
		_resend_homes()


## (V1) L'ordre des grimpeuses change avec le groupe (leur rôle) : chacune rejoint le point qui lui revient
## maintenant, sinon deux PNJ visent le même point et se bloquent.
func _resend_homes() -> void:
	for actor: LifeActor in members:
		_send_home(actor)


func _gather() -> void:
	phase = Phase.GATHER
	stacked.clear()
	for actor: LifeActor in members:
		_send_home(actor)


func _home(actor: LifeActor) -> Transform3D:
	var places := LifeDirector.places()
	if role_of(actor) == BASE:
		return places.point(place, 0)
	var index := climbers().find(actor) + 1
	return places.point(place, mini(index, places.size(place) - 1))


func _send_home(actor: LifeActor) -> void:
	var home := _home(actor)
	actor.npc.set_moving(false)
	actor.walk_to(home.origin, LifePlaces.facing_of(home), &"marche", Callable())


func _tick(delta: float, _player: Node3D) -> void:
	var base := base_actor()
	match phase:
		Phase.GATHER:
			var ready := true
			for actor: LifeActor in members:
				if actor.is_moving():
					ready = false
				elif not actor.is_holding():
					actor.play(&"assis")
			if ready and base != null:
				phase = Phase.STACK
				_left = 1.5
		Phase.STACK:
			_left -= delta
			if _left <= 0.0:
				_left = float(param("stack_time", 2.2))
				_climb_next(base)
		Phase.HOLD:
			_left -= delta
			if _left <= 0.0:
				_collapse(base)
		Phase.FALLEN:
			_left -= delta
			if _left <= 0.0:
				phase = Phase.REST
				_left = float(param("rest_time", 6.0))
				for actor: LifeActor in members:
					_send_home(actor)
		Phase.REST:
			_left -= delta
			for actor: LifeActor in members:
				if not actor.is_moving() and not actor.is_holding():
					actor.play(&"assis")
			if _left <= 0.0:
				_gather()


func _climb_next(base: LifeActor) -> void:
	var queue := climbers()
	if stacked.size() >= queue.size() or stacked.size() >= LEVELS.size():
		phase = Phase.HOLD
		_left = float(param("hold_time", 6.0))
		if not stacked.is_empty():
			stacked[-1].say(text("top", "Plus haut !"), 2.0)
		_emit(&"stacked", stacked.size())
		return
	var actor := queue[stacked.size()]
	var level: Array = LEVELS[stacked.size()]
	stacked.append(actor)
	var at: Vector3 = base.position() + level[0]
	actor.stop()
	actor.npc.set_moving(true)
	actor.set_position(at)
	actor.face(Vector3.RIGHT if rng.randf() < 0.5 else Vector3.LEFT)
	actor.hold(level[1], 3600.0)
	base.hold(&"assis", 3600.0)
	_emit(&"climbed", [actor.id, stacked.size()])
	if stacked.size() == 1 and is_instance_valid(base.npc):
		base.say(text("base", "Hé, doucement…"), 1.8)


func _collapse(base: LifeActor) -> void:
	phase = Phase.FALLEN
	_left = 3.0
	var origin := base.position() if base != null else center()
	for i: int in stacked.size():
		var actor := stacked[i]
		var angle := PI * (0.15 + 0.7 * float(i) / maxf(stacked.size() - 1, 1))
		var at := origin + Vector3(cos(angle), 0.0, sin(angle)) * rng.randf_range(0.8, 1.3)
		var nav := LifeDirector.nav()
		at.y = nav.height_at(at.x, at.z) if nav != null else origin.y
		actor.set_position(at)
		actor.npc.set_moving(false)
		actor.face(at - origin)
		actor.hold(&"tombe", _left)
	if base != null:
		base.hold(&"effondre", _left + 1.0)
		base.say(text("collapse", "Ouf…"), 1.8)
	stacked.clear()
	_emit(&"collapsed", null)


func on_player_interact(actor: LifeActor) -> bool:
	if phase != Phase.STACK and phase != Phase.HOLD:
		return false
	actor.say(text("gag", "{player} prend son élan… et s’arrête au bord, toute rouge."), 3.0)
	_emit(&"gag", actor.id)
	return true


func _finished() -> void:
	for actor: LifeActor in members:
		if is_instance_valid(actor.npc):
			actor.npc.set_moving(false)
	stacked.clear()
