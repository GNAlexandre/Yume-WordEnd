extends LifeGame
## (E4) Le chat (la poursuite) dans les hautes herbes (VEX, ill. ; docs/lore/VIE.md, 5.2) :
## une chasseuse court après les autres dans la place (un terrain de points) ; celle qu'elle
## touche devient la chasseuse (elle compte un instant), l'autre s'enfuit. Une manche dure
## round_time s, puis elles s'effondrent dans l'herbe en riant (tombe) et recommencent.
## Le joueur entre en approchant (join_distance) : une petite le touche, c'est lui le chat ; il
## touche en courant contre une petite ou d'un coup d'épée (sans mal) ; on le poursuit à son
## tour ; il sort en s'éloignant (leave_distance). Paramètres (activities.json, params) :
## tag_radius, flee_radius, round_time, rest_time, count_time, sword_radius.

const CHASER := &"chat"
const RUNNER := &"fuyarde"

var chaser: LifeActor = null
var player_chases: bool = false
var _round_left: float = 0.0
var _rest_left: float = 0.0
var _count_left: float = 0.0
var _retarget: float = 0.0
var _player: Node3D = null


func _setup() -> void:
	join_distance = float(param("join_distance", 3.0))
	leave_distance = float(param("leave_distance", 8.0))


func _started() -> void:
	_new_round()


func _finished() -> void:
	chaser = null
	player_chases = false


func _member_added(actor: LifeActor) -> void:
	set_role(actor, RUNNER)


func _member_removed(actor: LifeActor) -> void:
	if actor == chaser:
		chaser = null
		if running and not player_chases and not members.is_empty():
			_make_chaser(members[0])


func _accepts_player() -> bool:
	return _rest_left <= 0.0


func _player_joined() -> void:
	# Une petite le touche : c'est lui le chat.
	var nearest := _nearest_member(_player.global_position if _player != null else center())
	if nearest != null:
		nearest.npc.say(text("player_it", "C’est toi le chat !"))
	_player_becomes_chaser()


func _player_left() -> void:
	if player_chases:
		player_chases = false
		if not members.is_empty():
			_make_chaser(members[rng.randi_range(0, members.size() - 1)])
	var nearest := _nearest_member(center())
	if nearest != null:
		nearest.npc.say(text("player_left", "Tu reviens jouer ?"))


func on_player_attack(player: Node3D) -> void:
	if not player_in or not player_chases:
		return
	var forward := Vector3.FORWARD
	if player.has_method(&"aim_direction"):
		forward = player.call(&"aim_direction")
	var reach := float(param("sword_radius", 1.6))
	for actor: LifeActor in members:
		var offset := actor.position() - player.global_position
		offset.y = 0.0
		if offset.length() < reach and offset.normalized().dot(forward) > 0.2:
			_player_tags(actor)
			return


func _tick(delta: float, player: Node3D) -> void:
	_player = player
	if _rest_left > 0.0:
		_rest_left -= delta
		if _rest_left <= 0.0:
			_new_round()
		return
	_round_left -= delta
	if _round_left <= 0.0:
		_end_round()
		return
	_retarget -= delta
	var retarget := _retarget <= 0.0
	if retarget:
		_retarget = 0.3
	if _count_left > 0.0:
		_count_left -= delta
	var tag_radius := float(param("tag_radius", 0.7))
	# Le joueur chasseur touche en courant contre une petite.
	if player_chases and player_in and player != null:
		var touched := _nearest_member(player.global_position)
		if (
			touched != null
			and flat_distance(touched.position(), player.global_position) < tag_radius + 0.2
		):
			_player_tags(touched)
	var hunter_at := _hunter_position()
	for actor: LifeActor in members:
		if actor == chaser:
			_tick_chaser(actor, retarget, tag_radius)
		else:
			_tick_runner(actor, hunter_at, retarget)


## Une petite touchée (ou le joueur, null) devient le chat.
func tag(target: LifeActor) -> void:
	if target == null:
		_player_becomes_chaser()
		return
	_make_chaser(target)


func _tick_chaser(actor: LifeActor, retarget: bool, tag_radius: float) -> void:
	if _count_left > 0.0:
		actor.play(&"repos")
		return
	var prey_at := Vector3.INF
	var prey: LifeActor = null
	var best := INF
	for other: LifeActor in members:
		if other == actor:
			continue
		var d := flat_distance(other.position(), actor.position())
		if d < best:
			best = d
			prey = other
			prey_at = other.position()
	if player_in and _player != null and not player_chases:
		var d := flat_distance(_player.global_position, actor.position())
		if d < best:
			best = d
			prey = null
			prey_at = _player.global_position
	if prey_at == Vector3.INF:
		return
	if best < tag_radius:
		_emit(&"tagged", [actor.id, prey.id if prey != null else &"player"])
		actor.npc.say(text("tag", "Touchée !"))
		tag(prey)
		return
	if retarget or not actor.is_moving():
		actor.walk_to(prey_at, prey_at - actor.position(), &"course", Callable(), true)


func _tick_runner(actor: LifeActor, hunter_at: Vector3, retarget: bool) -> void:
	if actor.is_holding():
		return
	var flee := float(param("flee_radius", 4.0))
	var danger := hunter_at != Vector3.INF and flat_distance(hunter_at, actor.position()) < flee
	if danger and (retarget or not actor.is_moving()):
		var away := actor.position() - hunter_at
		away.y = 0.0
		away = away.normalized() if away.length_squared() > 0.001 else Vector3.RIGHT
		var side := Vector3(-away.z, 0.0, away.x) * rng.randf_range(-0.8, 0.8)
		var target := _inside(actor.position() + (away + side).normalized() * 3.0)
		actor.walk_to(target, target - actor.position(), &"course", Callable(), true)
	elif not danger and not actor.is_moving() and rng.randf() < 0.01:
		var places := LifeDirector.places()
		var point := places.point(place, rng.randi_range(0, places.size(place) - 1))
		actor.walk_to(point.origin, point.origin - actor.position(), &"marche", Callable(), true)
	elif not actor.is_moving():
		actor.play(&"repos")
		if hunter_at != Vector3.INF:
			actor.face(hunter_at - actor.position())


## Point ramené dans la place (à son rayon du centre) et sur un sol praticable.
func _inside(point: Vector3) -> Vector3:
	var middle := center()
	var limit := maxf(radius(), 2.0)
	var offset := Vector3(point.x - middle.x, 0.0, point.z - middle.z)
	if offset.length() > limit:
		offset = offset.normalized() * limit
	var target := middle + offset
	var nav := LifeDirector.nav()
	if nav != null and nav.ready and not nav.is_walkable_point(target.x, target.z):
		target = middle + offset * 0.5
	if nav != null:
		target.y = nav.height_at(target.x, target.z)
	return target


func _hunter_position() -> Vector3:
	if player_chases and player_in and _player != null:
		return _player.global_position
	return chaser.position() if chaser != null else Vector3.INF


func _make_chaser(actor: LifeActor) -> void:
	if chaser != null and chaser != actor and members.has(chaser):
		set_role(chaser, RUNNER)
	chaser = actor
	player_chases = false
	set_role(actor, CHASER)
	_count_left = float(param("count_time", 1.2))
	actor.hold(&"repos", _count_left)


func _player_becomes_chaser() -> void:
	if chaser != null and members.has(chaser):
		set_role(chaser, RUNNER)
	chaser = null
	player_chases = true
	_emit(&"role", [&"player", CHASER])


func _player_tags(actor: LifeActor) -> void:
	_emit(&"tagged", [&"player", actor.id])
	actor.npc.say(text("tagged", "Zut, touchée !"))
	_make_chaser(actor)


func _new_round() -> void:
	_rest_left = 0.0
	_round_left = float(param("round_time", 180.0))
	if not player_chases and not members.is_empty():
		_make_chaser(members[rng.randi_range(0, members.size() - 1)])


func _end_round() -> void:
	_rest_left = float(param("rest_time", 6.0))
	for actor: LifeActor in members:
		actor.hold(&"tombe", _rest_left)
	var nearest := _nearest_member(center())
	if nearest != null:
		nearest.npc.say(text("end", "Pouce !"))
	_emit(&"round_ended", null)


func _nearest_member(at: Vector3) -> LifeActor:
	var best: LifeActor = null
	var best_distance := INF
	for actor: LifeActor in members:
		var d := flat_distance(actor.position(), at)
		if d < best_distance:
			best = actor
			best_distance = d
	return best
