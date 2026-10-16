class_name LifeActor
extends RefCounted
## (E4) Un PNJ qui vit : sa ligne d'emploi du temps, son activité, ses trajets. Créé et tenu par
## LifeDirector (un par PNJ présent sur la carte courante), qui l'avance à chaque image physique
## (tick). Propriétaire : E4.
##
## - Activité (data/life/activities.json) : poses enchaînées (en boucle ou au hasard, durée
##   tirée dans [min, max]), pose d'arrivée (s'asseoir) et de départ (se lever), errance entre
##   les points d'une zone (wander), conversation à deux (pair : face à face, à tour de rôle), jeu
##   de groupe (game : LifeGame mène alors le PNJ).
## - Trajets : chemin de LifeNav (par les portes), lissé, suivi sans physique à la vitesse de
##   l'allure (marche, course, porte) ; le dernier pas va droit au point exact (une chaise). On
##   s'écarte à droite d'un PNJ qui vient en face, on contourne ou on attend un PNJ arrêté et le
##   joueur ; bloqué BLOCKED_REPATH s, on cherche un autre chemin ; sans progrès STUCK_TIME s, on
##   se replace d'un coup au but (jamais de PNJ coincé).
## - Le joueur : à LOOK_DISTANCE, on le regarde ; en approchant, parfois une bulle de salutation
##   (LifeTexts) ; s'il nous pousse (on bloque un passage), on s'écarte puis on revient ; quand il
##   nous parle, on s'arrête (parle), puis on reprend.
## - (E6) Réservé par le récit (LifeDirector.stage, état SCENE) : plus d'activité ni de réaction
##   au joueur ; il ne fait que ce que la scène demande (walk_to, play, face, say), jusqu'à ce que
##   LifeDirector.release le rende à son emploi du temps.

enum State { ACTIVITY, WALKING, LEAVING, GAME, ASIDE, GONE, SCENE }

const ARRIVE_DISTANCE := 0.08
## (S2) Distance d'arrivée d'une joueuse d'un jeu de groupe sur une place d'un seul point.
const GAME_ARRIVE_DISTANCE := 1.4
const LOOK_DISTANCE := 3.5
const GREET_DISTANCE := 3.0
const GREET_CHANCE := 0.45
const GREET_COOLDOWN := 40.0
## On s'écarte quand le joueur est à moins d'ASIDE_DISTANCE m et vient vers nous ASIDE_TIME s ;
## on revient quand il est à plus d'ASIDE_CLEAR m depuis ASIDE_RETURN s.
const ASIDE_DISTANCE := 1.1
const ASIDE_TIME := 0.6
const ASIDE_STEP := 1.3
const ASIDE_CLEAR := 2.6
const ASIDE_RETURN := 1.5
const BLOCKED_REPATH := 0.8
const STUCK_TIME := 7.0
const PROGRESS := 0.4
## (L3) Un suiveur (follow_to) ne demande un nouveau chemin que si son but a bougé de tant de m.
const FOLLOW_REPATH := 1.2
## Animations assises ou couchées : on ne s'écarte pas (on n'est pas dans le passage).
const SEATED: Array[StringName] = [&"assis", &"lit", &"dort"]

var id: StringName
var data: NpcData
var npc: Npc
var line: Dictionary = {}
var activity: Dictionary = {}
var activity_id: StringName = &""
var place: StringName = &""
var point_index: int = -1
## Point exact de la place (position, regard −Z).
var spot: Transform3D = Transform3D.IDENTITY
var state: State = State.ACTIVITY
var outfit: StringName = &""
var role: StringName = &""
var game: LifeGame = null
var talking: bool = false
var rng := RandomNumberGenerator.new()
## Délai sans progrès au bout duquel on se replace d'un coup au but (s ; STUCK_TIME).
var stuck_time: float = STUCK_TIME
## (L3) Facteur des vitesses de marche (1 : celles de activities.json) ; le récit s'en sert pour
## accorder une marche attendue au pas du joueur.
var speed_factor: float = 1.0

var _path := PackedVector3Array()
var _path_index: int = 0
var _goal: Vector3 = Vector3.INF
var _goal_facing: Vector3 = Vector3.ZERO
var _gait: StringName = &"marche"
var _arrived: Callable = Callable()
var _direct: bool = false
var _path_pending: bool = false
## (L3) Un chemin attendu ne met pas « repos » : on garde l'allure (suiveur).
var _keep_gait: bool = false
## (L3) But du dernier chemin demandé pour un suiveur (un nouveau n'est demandé qu'au-delà de
## FOLLOW_REPATH m).
var _path_goal: Vector3 = Vector3.INF
var _delay: float = 0.0
var _stuck: float = 0.0
var _blocked: float = 0.0
var _progress_at: Vector3 = Vector3.ZERO
var _avoid: Array[Vector2i] = []
var _heading: Vector3 = Vector3.ZERO
var _poses: Array = []
var _pose_index: int = -1
var _pose_left: float = INF
var _wait: float = 0.0
var _hold_left: float = 0.0
var _greet_cooldown: float = 0.0
var _player_near: bool = false
var _aside_time: float = 0.0
var _aside_clear: float = 0.0
var _outfit_dirty: bool = false


func _init(npc_id: StringName, npc_data: NpcData, node: Npc) -> void:
	id = npc_id
	data = npc_data
	npc = node
	rng.seed = hash(String(npc_id)) ^ Time.get_ticks_usec()
	_greet_cooldown = rng.randf_range(2.0, 12.0)


# --- Ce que le directeur demande ---------------------------------------------------------------


## Pose le PNJ à sa place, déjà en activité (arrivée sur la carte, créneau changé hors de vue).
func place_now(new_line: Dictionary) -> void:
	_leave_game()
	_release_spot()
	_take_line(new_line)
	_wear_outfit()
	_stop_moving()
	_claim_spot()
	set_position(spot.origin)
	face(LifePlaces.facing_of(spot))
	_start_activity(false)


## Va à pied vers la place de sa nouvelle ligne (créneau changé sous les yeux du joueur), après
## un délai de départ (delay s : on ne part pas tous ensemble), en se levant d'abord.
func walk_to_line(new_line: Dictionary, delay: float = 0.0) -> void:
	var leave_delay := _stand_up()
	_leave_game()
	_release_spot()
	_take_line(new_line)
	_claim_spot()
	state = State.WALKING
	walk_to(spot.origin, LifePlaces.facing_of(spot), _line_gait(), _on_reached_place)
	_delay = delay + leave_delay


## Quitte la carte : marche jusqu'au point de départ (sortie, place vers_<carte>) puis disparaît.
func leave_by(exit_point: Transform3D, delay: float = 0.0) -> void:
	var leave_delay := _stand_up()
	_leave_game()
	_release_spot()
	state = State.LEAVING
	walk_to(exit_point.origin, LifePlaces.facing_of(exit_point), _line_gait(), _on_left)
	_delay = delay + leave_delay


## Pose de départ de l'activité (se lever), jouée tout de suite ; sa durée (s).
func _stand_up() -> float:
	var pose: Variant = activity.get("leave")
	if not pose is Dictionary or talking:
		return 0.0
	play(StringName(str((pose as Dictionary).get("anim", "repos"))), true)
	return LifeData.pose_time(pose, rng) if (pose as Dictionary).has("time") else 0.4


## Arrive d'une autre carte : posé au point d'entrée, il marche jusqu'à sa place.
func arrive_from(entry: Transform3D, new_line: Dictionary, delay: float = 0.0) -> void:
	_take_line(new_line)
	_wear_outfit()
	_claim_spot()
	set_position(entry.origin)
	face(spot.origin - entry.origin)
	state = State.WALKING
	walk_to(spot.origin, LifePlaces.facing_of(spot), _line_gait(), _on_reached_place)
	_delay = delay


## Une marche vers point (chemin de LifeNav, ou tout droit si direct) ; on_arrive appelé à
## l'arrivée (sans argument). La position finale est exacte, le regard final est facing.
func walk_to(
	point: Vector3, facing: Vector3, gait: StringName, on_arrive: Callable, direct: bool = false
) -> void:
	_goal = point
	_goal_facing = facing
	_gait = gait
	_arrived = on_arrive
	_direct = direct
	_path = PackedVector3Array()
	_path_index = 0
	_stuck = 0.0
	_blocked = 0.0
	_avoid.clear()
	_progress_at = position()
	_path_pending = not direct
	_path_goal = point
	_keep_gait = false
	if not direct:
		LifeDirector.request_path(self)


## (L3) Un trajet qui suit un but mobile (un suiveur) : sans trajet en cours, une marche vers
## point (tout droit si la ligne est libre) ; sinon, le but change sans qu'on s'arrête : en ligne
## libre on file droit vers lui, sinon on garde l'ancien chemin le temps que le nouveau soit
## calculé (set_path le remplace) ; l'allure change à chaud. Jamais « repos » pendant le calcul.
func follow_to(point: Vector3, facing: Vector3, gait: StringName) -> void:
	var nav := LifeDirector.nav()
	var clear := nav != null and nav.ready and nav.line_clear(position(), point)
	if not is_moving():
		walk_to(point, facing, gait, Callable(), clear)
		_keep_gait = true
		return
	_goal = point
	_goal_facing = facing
	_gait = gait
	_keep_gait = true
	if clear:
		_path = PackedVector3Array()
		_path_index = 0
		_path_pending = false
		_direct = true
		return
	_direct = false
	if _path_pending:
		return
	var exhausted := _path.is_empty() or _path_index >= _path.size()
	if not exhausted and point.distance_to(_path_goal) < FOLLOW_REPATH:
		return
	_path_goal = point
	if exhausted:
		_path_pending = true
	LifeDirector.request_path(self)


## Chemin trouvé par le directeur (vide : tout droit, en se fiant au délai de replacement).
func set_path(path: PackedVector3Array) -> void:
	_path = path
	_path_index = 0
	_path_pending = false


## Vrai pendant un trajet (chemin attendu compris).
func is_moving() -> bool:
	return _goal != Vector3.INF


## Allure du trajet en cours.
func current_gait() -> StringName:
	return _gait


## But du trajet en cours (Vector3.INF sans trajet).
func goal() -> Vector3:
	return _goal


## Chemin du trajet en cours (lissé).
func current_path() -> PackedVector3Array:
	return _path


## Cases à éviter pour le prochain chemin (PNJ arrêtés, joueur).
func avoid_cells() -> Array[Vector2i]:
	return _avoid


## Direction de marche (vide à l'arrêt).
func heading() -> Vector3:
	return _heading if is_moving() and _delay <= 0.0 and not _path_pending else Vector3.ZERO


## Tient une pose seconds s sur place (jeux) : le trajet s'arrête, l'animation (avec ses
## remplaçants) est relancée.
func hold(anim: StringName, seconds: float) -> void:
	_stop_moving()
	play(anim, true)
	_hold_left = seconds


## Bulle au-dessus de la tête (sans effet si le PNJ n'est plus là).
func say(text: String, seconds: float = Npc.BUBBLE_TIME) -> void:
	if is_instance_valid(npc):
		npc.say(text, seconds)


## Arrête le trajet en cours (jeux).
func stop() -> void:
	_stop_moving()


## Vrai pendant une pose tenue (hold).
func is_holding() -> bool:
	return _hold_left > 0.0


# --- Image par image ---------------------------------------------------------------------------


## Avance le PNJ de delta s ; player : le joueur (ou null).
func tick(delta: float, player: Node3D) -> void:
	if state == State.GONE or not is_instance_valid(npc):
		return
	_greet_cooldown = maxf(_greet_cooldown - delta, 0.0)
	if talking:
		if player != null and state != State.SCENE:
			face(player.global_position - position())
		return
	if _hold_left > 0.0:
		_hold_left -= delta
	if is_moving():
		_tick_move(delta)
		return
	match state:
		State.ACTIVITY:
			_tick_activity(delta, player)
		State.ASIDE:
			_tick_aside(delta, player)
		State.SCENE:
			pass


## (E6) Pris par le récit : plus de trajet, de jeu, de place ni d'activité ; debout (repos).
func take_for_scene() -> void:
	_leave_game()
	_release_spot()
	_stop_moving()
	_hold_left = 0.0
	line = {}
	state = State.SCENE
	play(&"repos")


func _tick_activity(delta: float, player: Node3D) -> void:
	if activity.get("wander", false):
		_wait -= delta
		if _wait <= 0.0:
			_wander_step()
			return
	_pose_left -= delta
	if _pose_left <= 0.0:
		_next_pose()
	_react_to_player(delta, player)


func _tick_move(delta: float) -> void:
	if _delay > 0.0:
		_delay -= delta
		return
	if _outfit_dirty:
		_wear_outfit()
	if _path_pending:
		play(_gait if _keep_gait else &"repos")
		return
	var pos := position()
	var last_leg := _path_index >= _path.size()
	var target := _goal if last_leg else _path[_path_index]
	var flat := Vector3(target.x - pos.x, 0.0, target.z - pos.z)
	var distance := flat.length()
	var speed := LifeData.speed(_gait) * speed_factor
	if distance <= maxf(ARRIVE_DISTANCE, speed * delta * 0.5):
		if not last_leg:
			_path_index += 1
			return
		_arrive()
		return
	if (
		last_leg
		and distance <= GAME_ARRIVE_DISTANCE
		and activity.has("game")
		and _arrived.is_valid()
	):
		# (S2) Un jeu de groupe sur une place d'un seul point (le ballon : champ_centre) : toutes les
		# joueuses visent le même point, la première l'occupe et les autres tourneraient autour
		# sans jamais l'atteindre ; à GAME_ARRIVE_DISTANCE m, elles sont arrivées (le jeu les range).
		_arrive()
		return
	npc.set_moving(true)
	var forward := flat / distance
	var avoidance: Dictionary = LifeDirector.avoidance(self, pos, forward)
	if avoidance.get("blocked", false):
		_blocked += delta
		# Un pas de côté pour contourner (sinon on attend), puis un autre chemin.
		var side: Vector3 = avoidance.get("side", Vector3.ZERO)
		var nav_side: LifeNav = LifeDirector.nav()
		var aside := pos + side * speed * delta * 0.6
		if (
			side != Vector3.ZERO
			and nav_side != null
			and nav_side.is_walkable_point(aside.x, aside.z)
		):
			aside.y = nav_side.height_at(aside.x, aside.z)
			set_position(aside)
			face(forward)
			play(_gait)
		else:
			play(&"repos")
		if _blocked > BLOCKED_REPATH and not _direct and not last_leg:
			_blocked = 0.0
			_avoid.assign(avoidance.get("cells", []))
			_path_pending = true
			LifeDirector.request_path(self)
		_check_stuck(delta, pos)
		return
	_blocked = 0.0
	var steer: Vector3 = avoidance.get("steer", Vector3.ZERO)
	var step := minf(speed * delta, distance)
	var next := pos + (forward + steer).normalized() * step
	var nav: LifeNav = LifeDirector.nav()
	if not last_leg and nav != null and nav.ready and not nav.is_walkable_point(next.x, next.z):
		next = pos + forward * step
		if _direct and not nav.is_walkable_point(next.x, next.z):
			next = _slide(pos, forward * step, nav)
	next.y = nav.height_at(next.x, next.z) if nav != null else pos.y
	if last_leg and _goal.y > next.y:
		next.y = lerpf(next.y, _goal.y, 1.0 - clampf(distance / 0.6, 0.0, 1.0))
	set_position(next)
	_heading = (next - pos).normalized()
	face(_heading)
	play(_gait)
	_speed_up_anim(delta)
	_check_stuck(delta, next)


## (L3) Une allure à l'animation plus vive (rattrape) : l'horloge de la planche avance en plus ;
## (AN) sauf si la planche suit déjà la vitesse au sol (match_stride), qui règle la cadence.
func _speed_up_anim(delta: float) -> void:
	var factor := LifeData.anim_speed(_gait)
	if factor > 1.0 and is_instance_valid(npc) and not npc.visual.match_stride:
		npc.visual.advance(delta * (factor - 1.0))


func _check_stuck(delta: float, pos: Vector3) -> void:
	if pos.distance_to(_progress_at) > PROGRESS:
		_progress_at = pos
		_stuck = 0.0
		return
	_stuck += delta
	if _stuck > stuck_time:
		# Jamais coincé : on se replace d'un coup au but.
		set_position(_goal)
		_arrive()


func _arrive() -> void:
	set_position(_goal)
	_goal = Vector3.INF
	_heading = Vector3.ZERO
	_path = PackedVector3Array()
	npc.set_moving(false)
	if _goal_facing != Vector3.ZERO:
		face(_goal_facing)
	var callback := _arrived
	_arrived = Callable()
	if callback.is_valid():
		callback.call()


func _slide(pos: Vector3, step: Vector3, nav: LifeNav) -> Vector3:
	for candidate: Vector3 in [Vector3(step.x, 0.0, 0.0), Vector3(0.0, 0.0, step.z)]:
		var next := pos + candidate
		if candidate.length() > 0.001 and nav.is_walkable_point(next.x, next.z):
			return next
	return pos


func _stop_moving() -> void:
	_keep_gait = false
	_goal = Vector3.INF
	_path = PackedVector3Array()
	_path_pending = false
	_delay = 0.0
	_heading = Vector3.ZERO
	if is_instance_valid(npc):
		npc.set_moving(false)


# --- Activité ---------------------------------------------------------------------------------


func _take_line(new_line: Dictionary) -> void:
	line = new_line
	activity_id = new_line.get("activity", LifeData.DEFAULT_ACTIVITY)
	activity = LifeData.activity(activity_id)
	place = new_line.get("place", &"")
	role = new_line.get("role", &"")
	var wanted: StringName = new_line.get("outfit", &"")
	if outfit != wanted or npc.outfit_skin == null:
		outfit = wanted
		_outfit_dirty = true


## Vrai si la tenue de la ligne n'est pas encore portée (elle se met au départ).
func outfit_pending() -> bool:
	return _outfit_dirty


func _wear_outfit() -> void:
	_outfit_dirty = false
	if is_instance_valid(npc):
		npc.set_outfit(LifeDirector.outfit_skin(data, outfit))


func _line_gait() -> StringName:
	var gait: StringName = activity.get("gait", line.get("gait", LifeData.DEFAULT_GAIT))
	return StringName(gait)


func _claim_spot() -> void:
	point_index = LifeDirector.claim_point(self, place)
	spot = (
		LifeDirector.places().point(place, point_index) if LifeDirector.places() != null else spot
	)


func _release_spot() -> void:
	if point_index >= 0:
		LifeDirector.release_point(self, place, point_index)
	point_index = -1


func _on_reached_place() -> void:
	_start_activity(true)


func _on_left() -> void:
	state = State.GONE
	LifeDirector.despawn(self)


func _start_activity(arriving: bool) -> void:
	state = State.ACTIVITY
	_poses = activity.get("poses", [])
	_pose_index = -1
	_wait = 0.0
	if activity.has("game"):
		state = State.GAME
		LifeDirector.join_game(self)
		return
	if activity.get("wander", false):
		_wait = _pause_time()
	if arriving and activity.get("arrive") is Dictionary:
		var pose: Dictionary = activity["arrive"]
		play(StringName(pose.get("anim", "repos")), true)
		_pose_left = LifeData.pose_time(pose, rng) if pose.has("time") else 0.5
		_pose_index = -1
		if activity.get("pair", false) and LifeDirector.pair_rank(self) % 2 == 1:
			_pose_index = 0
		return
	if activity.get("pair", false) and LifeDirector.pair_rank(self) % 2 == 1:
		_pose_index = 0
	_next_pose()
	if not arriving and _pose_left < INF:
		# Posé d'un coup : déjà en cours d'activité, pas tous au même instant.
		_pose_left = rng.randf_range(0.0, _pose_left)


func _next_pose() -> void:
	if _poses.is_empty():
		play(&"repos")
		_pose_left = INF
		return
	if str(activity.get("order", "loop")) == "random":
		_pose_index = rng.randi_range(0, _poses.size() - 1)
	else:
		_pose_index = (_pose_index + 1) % _poses.size()
	var pose: Dictionary = _poses[_pose_index]
	play(StringName(pose.get("anim", "repos")), true)
	_pose_left = LifeData.pose_time(pose, rng)


func _wander_step() -> void:
	var count: int = LifeDirector.places().size(place) if LifeDirector.places() != null else 0
	if count < 2:
		_wait = _pause_time()
		return
	var index := rng.randi_range(0, count - 1)
	if index == point_index:
		index = (index + 1) % count
	point_index = index
	var target: Transform3D = LifeDirector.places().point(place, index)
	var wander: Variant = activity.get("wander")
	var gait := &"marche"
	if wander is Dictionary:
		gait = StringName(str((wander as Dictionary).get("gait", "marche")))
	walk_to(target.origin, LifePlaces.facing_of(target), gait, _on_wander_arrived)


func _on_wander_arrived() -> void:
	_wait = _pause_time()
	_next_pose()


func _pause_time() -> float:
	var wander: Variant = activity.get("wander")
	if wander is Dictionary and (wander as Dictionary).has("pause"):
		return LifeData.pose_time({"time": (wander as Dictionary)["pause"]}, rng)
	return rng.randf_range(2.0, 5.0)


# --- Le joueur ---------------------------------------------------------------------------------


func _react_to_player(delta: float, player: Node3D) -> void:
	var partner: LifeActor = (
		LifeDirector.pair_partner(self) if activity.get("pair", false) else null
	)
	var looking := false
	if player != null and activity.get("look", true):
		var offset := player.global_position - position()
		offset.y = 0.0
		var distance := offset.length()
		if distance < LOOK_DISTANCE:
			face(offset)
			looking = true
		if distance < GREET_DISTANCE and not _player_near:
			_player_near = true
			_greet()
		elif distance > GREET_DISTANCE + 1.0:
			_player_near = false
		_check_aside(delta, player, distance)
	if not looking:
		if partner != null:
			face(partner.position() - position())
		else:
			face(LifePlaces.facing_of(spot))


func _greet() -> void:
	if _greet_cooldown > 0.0 or not activity.get("greet", true):
		return
	_greet_cooldown = GREET_COOLDOWN
	if rng.randf() < GREET_CHANCE and LifeDirector.may_greet():
		say(LifeTexts.greeting(id, rng))


func _check_aside(delta: float, player: Node3D, distance: float) -> void:
	var seated := SEATED.has(npc.visual.current_animation())
	if seated or not activity.get("step_aside", true) or activity.get("wander", false):
		_aside_time = 0.0
		return
	var pushing := distance < ASIDE_DISTANCE
	if pushing and player is CharacterBody3D:
		var velocity := (player as CharacterBody3D).velocity
		velocity.y = 0.0
		var toward := position() - player.global_position
		toward.y = 0.0
		pushing = (
			distance < 0.8
			or (velocity.length() > 0.5 and velocity.normalized().dot(toward.normalized()) > 0.5)
		)
	_aside_time = _aside_time + delta if pushing else 0.0
	if _aside_time < ASIDE_TIME:
		return
	_aside_time = 0.0
	var away := position() - player.global_position
	away.y = 0.0
	away = away.normalized() if away.length_squared() > 0.0001 else Vector3.RIGHT
	var side := Vector3(-away.z, 0.0, away.x)
	var nav: LifeNav = LifeDirector.nav()
	for candidate: Vector3 in [
		side, -side, away, (side + away).normalized(), (away - side).normalized()
	]:
		var target := position() + candidate * ASIDE_STEP
		if nav == null or nav.is_walkable_point(target.x, target.z):
			state = State.ASIDE
			_aside_clear = 0.0
			walk_to(target, -candidate, &"marche", Callable(), true)
			return


func _tick_aside(delta: float, player: Node3D) -> void:
	play(&"repos")
	var far := player == null or player.global_position.distance_to(position()) > ASIDE_CLEAR
	if player != null:
		face(player.global_position - position())
	_aside_clear = _aside_clear + delta if far else 0.0
	if _aside_clear > ASIDE_RETURN:
		state = State.WALKING
		walk_to(spot.origin, LifePlaces.facing_of(spot), &"marche", _on_back_in_place)


func _on_back_in_place() -> void:
	_start_activity(false)


## (E8) Vrai quand son jeu réserve le PNJ : ni invite « Parler » ni conversation
## (LifeGame.blocks_talk).
func talk_blocked() -> bool:
	return game != null and game.blocks_talk()


## Le joueur interagit (touche E) : un jeu peut répondre à la place du dialogue (vrai : rien
## d'autre ne se passe).
func on_interact() -> bool:
	# (E6) Le récit d'abord : une scène qui attend cette conversation, ou ce que le personnage dit
	# hors des scènes (LifeDirector.talk_handler).
	if LifeDirector.handle_talk(self):
		return true
	return game != null and game.on_player_interact(self)


## Début ou fin de conversation avec le joueur : on s'arrête, puis on reprend.
func set_talking(value: bool) -> void:
	if talking == value:
		return
	talking = value
	if not is_instance_valid(npc):
		return
	if value:
		npc.set_moving(false)
		return
	if game != null:
		game.on_talk_ended(self)
	elif not is_moving() and state == State.ACTIVITY:
		_pose_index = maxi(_pose_index - 1, -1)
		_next_pose()


func _leave_game() -> void:
	if game != null:
		LifeDirector.leave_game(self)
	game = null


# --- Outils ------------------------------------------------------------------------------------


## Position du PNJ (repère du monde).
func position() -> Vector3:
	return npc.global_position if is_instance_valid(npc) else Vector3.ZERO


## Pose le PNJ (sans physique).
func set_position(at: Vector3) -> void:
	if is_instance_valid(npc):
		npc.global_position = at


## Tourne le PNJ vers direction (au sol).
func face(direction: Vector3) -> void:
	if is_instance_valid(npc) and Vector2(direction.x, direction.z).length_squared() > 0.0001:
		npc.visual.set_facing(direction)


## Joue anim, ou son premier remplaçant que la planche a (activities.json, « fallbacks ») ;
## restart : relance une animation non bouclée.
func play(anim: StringName, restart: bool = false) -> void:
	if not is_instance_valid(npc):
		return
	var shown := resolve_anim(anim)
	if shown.is_empty():
		return
	var visual := npc.visual
	var finished := shown == visual.current_animation() and not visual.is_playing()
	visual.play(shown, restart and (shown != visual.current_animation() or finished))


## Animation jouée pour anim avec la planche portée (anim, un remplaçant, ou &"").
func resolve_anim(anim: StringName) -> StringName:
	var visual := npc.visual
	if visual.has_animation(anim):
		return anim
	for fallback: Variant in LifeData.fallbacks(anim):
		if visual.has_animation(StringName(fallback)):
			return StringName(fallback)
	return &"repos" if visual.has_animation(&"repos") else &""
