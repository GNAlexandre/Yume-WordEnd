class_name BallPlay
extends LifeGame
## (E8) Le ballon, première moitié : le terrain, les équipes et les postes, l'IA des petites, leurs
## frappes (BallMatch, src/life/games/ballon.gd, mène le match par-dessus : phases, buts, fourré,
## joueur, arbitre, score). Propriétaire : E8. Chiffres : data/games/ballon.json.
##
## - Le terrain : un rectangle de field/width × field/length m centré sur la place du jeu ; les
##   places `champ_but_nord` (cages des blanches) et `champ_but_sud` (cages des rouges) donnent le
##   poste des gardiennes. Les blanches défendent le nord en première mi-temps.
## - Les équipes : au plus team_size joueuses par équipe sur le terrain, les autres sur le banc
##   (assises au bord ouest). À la mi-temps, les meilleures buteuses restent (keep_top_scorers),
##   les remplaçantes entrent (V5). Chaque équipe a une gardienne.
## - L'IA : une ou deux joueuses par équipe courent au ballon (la plus proche, avec un petit
##   avantage à celle qui l'a le moins touché : le jeu de Willem, V1), les autres tiennent leur
##   poste en suivant le ballon ; au pied, elle tire (près des cages), passe, dribble ou le lance
##   haut à deux mains (il retombe au hasard dans toss_range m). Rien de parfait : elles ratent
##   leur frappe, tombent (tombe), la gardienne laisse passer un tir sur quatre.

enum Phase { ASSEMBLE, GATHER, KICKOFF, PLAY, GOAL, LOST, HALFTIME, ENDED }

const RED := &"rouge"
const WHITE := &"blanc"
const REFEREE := &"arbitre"
const PLAYER_ID := &"player"
const GAME_RULES := &"ballon"
const RING_COLORS := {RED: Color(1.0, 0.3, 0.26, 0.95), WHITE: Color(1.0, 1.0, 1.0, 0.95)}
const RING_SIZE := 0.95

## Surcharges des règles (chemins de data/games/ballon.json) : activities.json (params) puis les
## tests.
var overrides: Dictionary = {}
var phase: Phase = Phase.GATHER
## Mi-temps courante (1, 2) et temps restant dans celle-ci (s).
var half: int = 1
var clock: float = 0.0
var score: Dictionary = {RED: 0, WHITE: 0}
## Marqueuses : id → buts.
var scorers: Dictionary = {}
var ball: GameBall = null
var referee: LifeActor = null
## Équipe du joueur (&"" hors partie) et ses compteurs.
var player_team: StringName = &""
var player_goals: int = 0
var player_touches: int = 0
## Les petites en jeu : id → BallKid.
var kids: Dictionary = {}
## Équipe → sens de l'attaque (+1 : vers le sud).
var sides: Dictionary = {WHITE: 1.0, RED: -1.0}
## Boue (le sol après la pluie) : le ballon ralentit, les petites tombent plus.
var muddy: bool = false
## Match terminé (résultat dans result()).
var ended: bool = false
var elapsed: float = 0.0

var _keeper_homes: Dictionary = {}
var _protect_left: float = 0.0
var _kickoff_team: StringName = WHITE
var _field: Dictionary = {}
var _result: Dictionary = {}


## Un chiffre des règles du ballon (chemin « kick/reach »).
func rule(key_path: String, default: float) -> float:
	return GameRules.number(GAME_RULES, key_path, default, overrides)


## Résultat du match (vide tant qu'il n'est pas fini) : winner (&"rouge", &"blanc", &"egalite"),
## score, scorers, player_team, player_goals, player_touches, duration, aborted.
func result() -> Dictionary:
	return _result


## Les petites d'une équipe en jeu (sur le terrain ou sur le banc).
func team_kids(team: StringName) -> Array[BallKid]:
	var list: Array[BallKid] = []
	for kid: BallKid in kids.values():
		if kid.team == team:
			list.append(kid)
	return list


## Les joueuses d'une équipe sur le terrain.
func field_kids(team: StringName) -> Array[BallKid]:
	var list: Array[BallKid] = []
	for kid: BallKid in team_kids(team):
		if kid.on_field:
			list.append(kid)
	return list


## La petite d'un PNJ (null si elle ne joue pas).
func kid_of(actor: LifeActor) -> BallKid:
	return kids.get(actor.id)


## Lit le terrain : un rectangle de field/width × field/length m centré sur la place du jeu ; les
## cages de la carte (places champ_but_nord et champ_but_sud) donnent le poste des gardiennes.
func _read_field() -> void:
	var places := LifeDirector.places()
	var middle := center()
	var half_w := rule("field/width", 18.0) * 0.5
	var half_l := rule("field/length", 20.0) * 0.5
	var keeper_offset := rule("field/keeper_offset", 1.2)
	_field = {
		"cx": middle.x,
		"cz": middle.z,
		"ground": middle.y,
		"half_w": half_w,
		"half_l": half_l,
		"north": middle.z - half_l,
		"south": middle.z + half_l,
		"west": middle.x - half_w,
		"east": middle.x + half_w,
	}
	_keeper_homes = {
		&"north": Vector3(middle.x, middle.y, middle.z - half_l + keeper_offset),
		&"south": Vector3(middle.x, middle.y, middle.z + half_l - keeper_offset),
	}
	var north_name := StringName(str(param("goal_north", "champ_but_nord")))
	var south_name := StringName(str(param("goal_south", "champ_but_sud")))
	if places != null and places.has(north_name):
		_keeper_homes[&"north"] = places.center(north_name)
	if places != null and places.has(south_name):
		_keeper_homes[&"south"] = places.center(south_name)


func _field_rect(margin: float = 0.0) -> Rect2:
	return Rect2(
		float(_field["west"]) - margin,
		float(_field["north"]) - margin,
		(float(_field["half_w"]) + margin) * 2.0,
		(float(_field["half_l"]) + margin) * 2.0
	)


func _field_center() -> Vector3:
	return Vector3(_field["cx"], _field["ground"], _field["cz"])


func _smaller_team() -> StringName:
	var white := team_kids(WHITE).size() + (1 if player_team == WHITE else 0)
	var red := team_kids(RED).size() + (1 if player_team == RED else 0)
	return RED if red < white else WHITE


## Joueuses par équipe sur le terrain : team_size, ou moins s'il n'y a pas assez de monde.
func field_size() -> int:
	var white := team_kids(WHITE).size() + (1 if player_team == WHITE else 0)
	var red := team_kids(RED).size() + (1 if player_team == RED else 0)
	return clampi(mini(int(rule("team_size", 5.0)), mini(white, red)), 1, 11)


## Compose les équipes sur le terrain et sur le banc ; second : la seconde mi-temps (les
## meilleures buteuses restent, les remplaçantes entrent).
func _apply_lineups(second: bool) -> void:
	for team: StringName in [WHITE, RED]:
		_lineup(team, second)
	for kid: BallKid in kids.values():
		_update_ring(kid)


func _lineup(team: StringName, second: bool) -> void:
	var members_of := team_kids(team)
	var slots := field_size() - (1 if player_in and player_team == team else 0)
	slots = clampi(slots, 0, members_of.size())
	var keepers_before: Array[BallKid] = []
	for kid: BallKid in members_of:
		kid.was_on_field = kid.on_field
		if kid.keeper:
			keepers_before.append(kid)
		kid.keeper = false
	var kept: Array[BallKid] = []
	if second:
		var by_goals := members_of.duplicate()
		by_goals.sort_custom(
			func(a: BallKid, b: BallKid) -> bool:
				return a.goals > b.goals or (a.goals == b.goals and a.touches > b.touches)
		)
		for kid: BallKid in by_goals:
			if kid.goals > 0 and kept.size() < int(rule("keep_top_scorers", 1.0)):
				kept.append(kid)
	var ranked := members_of.duplicate()
	ranked.sort_custom(
		func(a: BallKid, b: BallKid) -> bool:
			var ka := kept.has(a)
			var kb := kept.has(b)
			if ka != kb:
				return ka
			if second and a.was_on_field != b.was_on_field:
				return not a.was_on_field
			return a.touches < b.touches
	)
	var chosen: Array[BallKid] = []
	for kid: BallKid in ranked:
		if chosen.size() < slots:
			chosen.append(kid)
	for kid: BallKid in members_of:
		kid.on_field = chosen.has(kid)
	if chosen.is_empty():
		return
	# La gardienne : la dernière gardienne si elle joue encore, sinon celle qui a le moins marqué.
	var keeper: BallKid = null
	for kid: BallKid in keepers_before:
		if chosen.has(kid) and not kept.has(kid):
			keeper = kid
	if keeper == null:
		for kid: BallKid in chosen:
			if kept.has(kid):
				continue
			if keeper == null or kid.goals < keeper.goals:
				keeper = kid
	if keeper == null:
		keeper = chosen[0]
	keeper.keeper = true
	keeper.home = Vector2(0.0, rule("field/keeper_offset", 1.2) / (float(_field["half_l"]) * 2.0))
	var index := 0
	var field_players := chosen.size() - 1
	var lateral: Array[float] = [0.0, -0.55, 0.55, -0.25, 0.25, -0.8, 0.8]
	for kid: BallKid in chosen:
		if kid == keeper:
			continue
		var depth := lerpf(0.28, 0.8, float(index) / maxf(field_players - 1, 1.0))
		if field_players == 1:
			depth = 0.45
		kid.home = Vector2(lateral[index % lateral.size()], depth)
		index += 1


## Position au sol du poste d'une joueuse (repère du monde).
func home_position(kid: BallKid) -> Vector3:
	var dir := float(sides[kid.team])
	if kid.keeper:
		return _keeper_homes[&"north" if dir > 0.0 else &"south"]
	var own_line := float(_field["north"]) if dir > 0.0 else float(_field["south"])
	var z := own_line + dir * kid.home.y * float(_field["half_l"]) * 2.0
	var x := float(_field["cx"]) - dir * kid.home.x * float(_field["half_w"]) * 0.8
	return Vector3(x, float(_field["ground"]), z)


## Place sur le banc de l'équipe (assise au bord ouest, hors du terrain).
func bench_position(kid: BallKid) -> Vector3:
	var list: Array[BallKid] = []
	for other: BallKid in team_kids(kid.team):
		if not other.on_field:
			list.append(other)
	var index := maxi(list.find(kid), 0)
	var side := -1.0 if kid.team == WHITE else 1.0
	var offset := rule("field/bench_offset", 1.1)
	var at := Vector3(
		float(_field["west"]) - offset,
		float(_field["ground"]),
		float(_field["cz"]) + side * (1.6 + 0.85 * index)
	)
	var nav := LifeDirector.nav()
	if nav != null and nav.ready and not nav.is_walkable_point(at.x, at.z):
		at.x = float(_field["west"]) + 0.6
	return at


## Envoie une petite à son poste ou sur le banc.
func _send_home(kid: BallKid) -> void:
	kid.seated = false
	kid.chasing = false
	kid.pending = {}
	var at := home_position(kid) if kid.on_field else bench_position(kid)
	_walk(kid, at, &"course" if kid.on_field else &"marche", true)


func _walk(kid: BallKid, at: Vector3, gait: StringName, force: bool = false) -> void:
	if not force and kid.actor.is_moving() and kid.target != Vector3.INF:
		if flat_distance(kid.target, at) < 0.7:
			return
	kid.target = at
	kid.actor.walk_to(at, at - kid.actor.position(), gait, Callable(), true)


func _refill_field(team: StringName, keeper_left: bool) -> void:
	var benched: BallKid = null
	for kid: BallKid in team_kids(team):
		if not kid.on_field and (benched == null or kid.touches < benched.touches):
			benched = kid
	if benched == null:
		return
	benched.on_field = true
	var present := field_kids(team)
	benched.keeper = keeper_left
	benched.home = Vector2(0.0, 0.4) if not keeper_left else Vector2(0.0, 0.07)
	if present.size() > 1:
		benched.home.x = rng.randf_range(-0.6, 0.6)
	_update_ring(benched)
	_send_home(benched)


func _update_ring(kid: BallKid) -> void:
	if not kid.on_field or not is_instance_valid(kid.actor.npc):
		_drop_ring(kid)
		return
	if kid.ring == null:
		var color: Color = RING_COLORS.get(kid.team, Color.WHITE)
		kid.ring = CombatFx.make_decal(
			"lock_ring", Vector2(RING_SIZE, RING_SIZE), color, "TeamRing"
		)
		kid.actor.npc.add_child(kid.ring)


func _drop_ring(kid: BallKid) -> void:
	if kid.ring != null and is_instance_valid(kid.ring):
		kid.ring.queue_free()
	kid.ring = null


func _clear_rings() -> void:
	for kid: BallKid in kids.values():
		_drop_ring(kid)


func _tick_kids(delta: float) -> void:
	var period := rule("think_period", 0.25)
	for kid: BallKid in kids.values():
		if not is_instance_valid(kid.actor.npc):
			continue
		kid.kick_left = maxf(kid.kick_left - delta, 0.0)
		kid.block_left = maxf(kid.block_left - delta, 0.0)
		if kid.down_left > 0.0:
			kid.down_left -= delta
			if kid.down_left <= 0.0 and not kid.actor.is_moving():
				kid.actor.play(&"repos")
				kid.target = Vector3.INF
		_fire_pending(kid, delta)
		kid.think_left -= delta
		if kid.think_left <= 0.0:
			kid.think_left = period * rng.randf_range(0.8, 1.2)
			_think(kid)


func _think(kid: BallKid) -> void:
	var actor := kid.actor
	if actor.talking or kid.down_left > 0.0 or actor.is_holding():
		return
	if not kid.on_field:
		_think_bench(kid)
		return
	if phase == Phase.PLAY:
		_think_play(kid)
	else:
		_think_wait(kid)


func _think_bench(kid: BallKid) -> void:
	var actor := kid.actor
	if actor.is_moving():
		return
	if not kid.seated:
		kid.seated = true
		actor.face(Vector3(_field["cx"], 0.0, _field["cz"]) - actor.position())
		actor.play(&"assis", true)
	elif rng.randf() < 0.04:
		actor.say(text("bench", "Allez !"))


func _think_wait(kid: BallKid) -> void:
	var actor := kid.actor
	if actor.is_moving():
		return
	var at := home_position(kid)
	if (
		flat_distance(actor.position(), at) > 1.2
		and phase != Phase.GOAL
		and phase != Phase.HALFTIME
	):
		_walk(kid, at, &"marche")
		return
	actor.play(&"repos")
	var ball_at := ball.ground_position() if ball != null else _field_center()
	actor.face(ball_at - actor.position())


func _think_play(kid: BallKid) -> void:
	var actor := kid.actor
	var ball_at := ball.ground_position()
	var here := actor.position()
	var distance := flat_distance(here, ball_at)
	if kid.keeper:
		_think_keeper(kid, ball_at, distance)
		return
	var reach := rule("kick/reach", 0.8)
	if distance <= reach and kid.kick_left <= 0.0 and ball.height < 0.7 and not _off_limits(kid):
		_start_kick(kid)
		return
	if _maybe_fall(kid, distance):
		return
	if kid.chasing and not _off_limits(kid):
		var lead := minf(distance / 3.2, rule("ai/lead_max", 1.0))
		var aim := ball.predict(lead)
		_walk(kid, _clamp_to_field(aim), &"course")
		return
	var home_at := home_position(kid)
	var follow := rule("ai/follow_front", 0.3)
	if kid.home.y < 0.4:
		follow = rule("ai/follow_back", 0.2)
	elif kid.home.y < 0.65:
		follow = rule("ai/follow_middle", 0.4)
	var support := _clamp_to_field(home_at.lerp(ball_at, follow))
	if flat_distance(here, support) > rule("ai/arrive_tolerance", 0.9):
		_walk(kid, support, &"course" if flat_distance(here, support) > 4.0 else &"marche")
	elif not actor.is_moving():
		actor.play(&"repos")
		actor.face(ball_at - here)


## Pas le droit de toucher le ballon : le coup d'envoi appartient à l'équipe qui engage.
func _off_limits(kid: BallKid) -> bool:
	return _protect_left > 0.0 and kid.team != _kickoff_team


func _think_keeper(kid: BallKid, ball_at: Vector3, distance: float) -> void:
	var actor := kid.actor
	var home_at := home_position(kid)
	var dir := float(sides[kid.team])
	var own_line := float(_field["north"]) if dir > 0.0 else float(_field["south"])
	var zone := rule("keeper/zone", 3.2)
	var from_line := absf(ball_at.z - own_line)
	var reach := rule("kick/reach", 0.8)
	if from_line < zone and ball.speed() < 2.0 and ball.height < 0.7 and ball.in_goal == &"":
		if distance <= reach and kid.kick_left <= 0.0:
			_start_clear(kid)
			return
		_walk(kid, _clamp_to_field(ball_at), &"course")
		return
	var lateral := rule("keeper/range", 1.4)
	var target := Vector3(
		clampf(ball_at.x, home_at.x - lateral, home_at.x + lateral), home_at.y, home_at.z
	)
	if flat_distance(actor.position(), target) > 0.35:
		_walk(kid, target, &"marche")
	elif not actor.is_moving():
		actor.play(&"repos")
		actor.face(ball_at - actor.position())


func _clamp_to_field(point: Vector3) -> Vector3:
	var margin := rule("field/margin", 0.8)
	return Vector3(
		clampf(point.x, float(_field["west"]) + margin, float(_field["east"]) - margin),
		float(_field["ground"]),
		clampf(point.z, float(_field["north"]) + margin, float(_field["south"]) - margin)
	)


## Les une ou deux joueuses de chaque équipe qui courent au ballon : les plus proches, avec un petit
## avantage à celles qui l'ont le moins touché (le jeu de Willem : le ballon roule plus souvent
## vers celle qui ne l'a pas encore eu).
func _update_chasers() -> void:
	if ball == null:
		return
	var ball_at := ball.predict(0.5)
	var bonus := rule("ai/fair_bonus", 0.4)
	var bonus_max := rule("ai/fair_bonus_max", 2.5)
	for team: StringName in [WHITE, RED]:
		var runners: Array[BallKid] = []
		var touches_total := 0
		for kid: BallKid in field_kids(team):
			kid.chasing = false
			if not kid.keeper and kid.down_left <= 0.0:
				runners.append(kid)
				touches_total += kid.touches
		if runners.is_empty():
			continue
		var average := float(touches_total) / runners.size()
		var scored: Array = []
		for kid: BallKid in runners:
			var advantage := clampf((average - kid.touches) * bonus, 0.0, bonus_max)
			scored.append([flat_distance(kid.actor.position(), ball_at) - advantage, kid])
		scored.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
		var count := mini(int(rule("chasers", 2.0)) if runners.size() >= 4 else 1, scored.size())
		for i: int in count:
			(scored[i][1] as BallKid).chasing = true


## Une chute : en courant après le ballon, ou en se bousculant à deux.
func _maybe_fall(kid: BallKid, _distance: float) -> bool:
	if not kid.actor.is_moving() or kid.down_left > 0.0:
		return false
	var scale := rule("mud/fall_scale", 2.5) if muddy else 1.0
	var chance := rule("fall/chance_per_s", 0.01) * rule("think_period", 0.25) * scale
	var fell := rng.randf() < chance
	if not fell:
		var contact := rule("fall/collide_radius", 0.5)
		for other: BallKid in kids.values():
			if other == kid or not other.on_field or other.team == kid.team:
				continue
			if (
				other.actor.is_moving()
				and flat_distance(other.actor.position(), kid.actor.position()) < contact
			):
				fell = rng.randf() < rule("fall/collide_chance", 0.3)
				break
	if fell:
		_fall(kid)
	return fell


func _fall(kid: BallKid) -> void:
	var time := rule("fall/time", 1.5)
	kid.down_left = time
	kid.chasing = false
	kid.pending = {}
	kid.actor.hold(&"tombe", time)
	if rng.randf() < 0.5:
		kid.actor.say(text("fall", "Aïe !"))
	_emit(&"fall", kid.actor.id)


## Où est le but que la joueuse attaque (centre de la ligne).
func goal_position(team: StringName) -> Vector3:
	var dir := float(sides[team])
	var line := float(_field["south"]) if dir > 0.0 else float(_field["north"])
	return Vector3(_field["cx"], _field["ground"], line)


func _start_kick(kid: BallKid) -> void:
	var actor := kid.actor
	var ball_at := ball.ground_position()
	var here := actor.position()
	var goal := goal_position(kid.team)
	var to_goal := goal - ball_at
	to_goal.y = 0.0
	var plan := {"kind": &"dribble", "target": ball_at}
	var roll := rng.randf()
	var error := deg_to_rad(rule("kick/error_deg", 12.0))
	var direction := to_goal.normalized()
	var speed_value := rule("kick/dribble_speed", 3.6)
	var lift := 0.0
	if to_goal.length() < rule("kick/shoot_range", 9.5) and roll < rule("kick/shoot_prob", 0.75):
		plan["kind"] = &"shot"
		var half_goal := rule("field/goal_width", 2.9) * 0.45
		var aim := goal + Vector3(rng.randf_range(-half_goal, half_goal), 0.0, 0.0)
		direction = (aim - ball_at).normalized()
		speed_value = rule("kick/shot_speed", 9.0) * rng.randf_range(0.85, 1.1)
		lift = rng.randf_range(0.0, rule("kick/shot_lift_max", 2.6))
	elif rng.randf() < rule("kick/toss_prob", 0.05):
		plan["kind"] = &"toss"
		var angle := rng.randf() * TAU
		var distance := rng.randf_range(2.0, rule("kick/toss_range", 6.0))
		var landing := _clamp_to_field(ball_at + Vector3(cos(angle), 0.0, sin(angle)) * distance)
		plan["target"] = landing
		plan["flight"] = rng.randf_range(
			rule("kick/toss_time_min", 0.9), rule("kick/toss_time_max", 1.5)
		)
		direction = (landing - ball_at).normalized()
	elif rng.randf() < rule("kick/pass_prob", 0.5):
		var mate := _best_mate(kid)
		if mate != null:
			var lead := mate.actor.position() + mate.actor.heading() * 0.6
			direction = (lead - ball_at).normalized()
			var distance := flat_distance(lead, ball_at)
			speed_value = clampf(
				sqrt(2.0 * ball.roll_friction * distance) * 1.1 + 0.8,
				rule("kick/pass_speed_min", 3.2),
				rule("kick/pass_speed_max", 8.5)
			)
			plan["kind"] = &"pass"
			plan["mate"] = mate.actor.id
	if plan["kind"] == &"dribble":
		direction = direction.rotated(Vector3.UP, rng.randf_range(-0.5, 0.5))
	if plan["kind"] != &"toss":
		direction = direction.rotated(Vector3.UP, rng.randf_range(-error, error))
	plan["dir"] = direction
	plan["speed"] = speed_value
	plan["lift"] = lift
	plan["time"] = rule("kick/delay", 0.14)
	kid.pending = plan
	kid.kick_left = rule("kick/cooldown", 0.7)
	actor.face(direction if direction != Vector3.ZERO else ball_at - here)
	actor.hold(&"lance" if plan["kind"] == &"toss" else &"frappe", rule("kick/anim_time", 0.45))


## La gardienne dégage le ballon qui traîne devant sa cage.
func _start_clear(kid: BallKid) -> void:
	var ball_at := ball.ground_position()
	var out := Vector3(_field["cx"], _field["ground"], _field["cz"]) - ball_at
	out.y = 0.0
	out = out.normalized().rotated(Vector3.UP, rng.randf_range(-0.5, 0.5))
	kid.pending = {
		"kind": &"clear",
		"dir": out,
		"speed": rule("keeper/clear_speed", 6.5),
		"lift": 0.5,
		"time": rule("kick/delay", 0.14),
	}
	kid.kick_left = rule("kick/cooldown", 0.7)
	kid.actor.face(out)
	kid.actor.hold(&"frappe", rule("kick/anim_time", 0.45))


## La coéquipière à qui passer : plus avancée, pas trop près ni trop loin, de préférence celle qui a
## le moins touché le ballon.
func _best_mate(kid: BallKid) -> BallKid:
	var best: BallKid = null
	var best_score := -INF
	var ball_at := ball.ground_position()
	var dir := float(sides[kid.team])
	var minimum := rule("kick/pass_min", 2.0)
	var maximum := rule("kick/pass_max", 9.0)
	var total := 0
	var count := 0
	for other: BallKid in field_kids(kid.team):
		total += other.touches
		count += 1
	var average := float(total) / maxf(count, 1)
	for mate: BallKid in field_kids(kid.team):
		if mate == kid or mate.keeper or mate.down_left > 0.0:
			continue
		var offset := mate.actor.position() - ball_at
		offset.y = 0.0
		var distance := offset.length()
		if distance < minimum or distance > maximum:
			continue
		var progress := offset.z * dir
		var candidate := (
			progress * 0.35
			- distance * 0.12
			+ (average - mate.touches) * rule("ai/fair_pass", 0.6)
			+ rng.randf_range(0.0, 1.0)
		)
		if candidate > best_score:
			best_score = candidate
			best = mate
	return best


func _fire_pending(kid: BallKid, delta: float) -> void:
	if kid.pending.is_empty() or phase != Phase.PLAY:
		return
	kid.pending["time"] = float(kid.pending["time"]) - delta
	if float(kid.pending["time"]) > 0.0:
		return
	var plan := kid.pending
	kid.pending = {}
	if (
		ball == null
		or (
			flat_distance(kid.actor.position(), ball.ground_position())
			> rule("kick/reach", 0.8) * 1.7
		)
	):
		return
	var by := kid.actor.id
	if plan["kind"] == &"toss":
		ball.launch_to(plan["target"], float(plan["flight"]), by)
	else:
		ball.kick(plan["dir"], float(plan["speed"]), float(plan["lift"]), by)
	kid.touches += 1
	_emit(&"kick", [by, plan["kind"]])


## Une gardienne arrête le tir qui passe devant elle (sauf une fois sur quatre : elle ne regardait
## pas).
func _keepers_block() -> void:
	if ball == null or ball.in_goal != &"" or ball.height > 1.5:
		return
	var reach := rule("keeper/reach", 1.0)
	for team: StringName in [WHITE, RED]:
		for kid: BallKid in field_kids(team):
			if not kid.keeper or kid.block_left > 0.0 or kid.down_left > 0.0:
				continue
			var offset := ball.ground_position() - kid.actor.position()
			offset.y = 0.0
			if offset.length() > reach:
				continue
			var dir := float(sides[kid.team])
			if ball.velocity.z * dir > -1.0:
				# Le ballon ne file pas vers la cage : elle le laissera à ses pieds.
				continue
			kid.block_left = rule("keeper/block_cooldown", 0.8)
			if rng.randf() < rule("keeper/miss_chance", 0.25):
				continue
			var away := Vector3(offset.x, 0.0, -offset.z * 0.2 + dir * 1.0).normalized()
			ball.kick(away, maxf(ball.speed() * 0.5, 2.5), 1.4, kid.actor.id)
			kid.touches += 1
			kid.actor.hold(&"saut", 0.5)
			kid.actor.say(text("save", "Arrêt !"))
			_emit(&"save", kid.actor.id)
