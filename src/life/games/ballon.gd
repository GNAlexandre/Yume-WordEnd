class_name BallMatch
extends BallPlay
## (E8) Le ballon (V1 ; V5 ; docs/lore/VIE.md, 5.1) : deux équipes de petites, les rouges et les
## blanches, un vrai ballon (GameBall), deux cages, deux mi-temps, un arbitre. Se joue sur le
## cadre de LifeGame : les PNJ dont l'activité est « ballon » à la place du champ forment le
## groupe ; la clé « role » de leur ligne donne l'équipe (« rouge », « blanc ») ou l'arbitre
## (« arbitre » : Willem ou une aînée). Propriétaire : E8. Le terrain, les équipes et l'IA des
## petites sont dans BallPlay (src/games/ball_play.gd) ; ici le match :
## - les phases : on attend les retardataires (ASSEMBLE), on s'aligne (GATHER), coup d'envoi
##   (KICKOFF), on joue (PLAY), un but (GOAL), le ballon perdu (LOST), la mi-temps (HALFTIME), la
##   fin (ENDED) ;
## - le ballon perdu : une balle qui frappe le mur est (fourre_ballon) se perd parfois dans le
##   fourré ; une petite va le chercher (le joueur peut y aller aussi) ;
## - le joueur : entre dans le champ (à join_margin m du bord), rejoint l'équipe qui a le moins de
##   joueuses (les blanches à égalité), frappe avec la touche d'attaque quand le ballon est près
##   (sans blesser personne), pousse le ballon en courant contre lui ; il sort en quittant le champ
##   (leave_margin m du bord) ou par leave_player() ;
## - la fin : le résultat est signalé par match_finished(résultat) et par l'événement
##   « match_ended » (voir MiniGames.start_ball_match).
##
## Événements (LifeGame.event) : match_started, kickoff, goal [équipe, marqueuse, score],
## save [gardienne], kick [qui, sorte], fall [qui], half_time, ball_lost, ball_found [qui],
## player_kick [direction], match_ended [résultat].

## Le match est fini : résultat (voir result()).
signal match_finished(result: Dictionary)

const BALL_SCRIPT := preload("res://src/games/ball.gd")
const SCORE_SCRIPT := preload("res://src/games/game_score.gd")

var _phase_time: float = 0.0
var _chase_left: float = 0.0
var _assemble_left: float = 0.0
var _assemble_total: float = 0.0
var _hud: CanvasLayer = null
var _hud_left: float = 0.0
var _player: Node3D = null
var _player_kick_left: float = -1.0
var _player_touch_left: float = 0.0
var _fetcher: BallKid = null
var _fetch_left: float = 0.0
var _aborted: bool = false


func _setup() -> void:
	for key: String in params:
		overrides[key] = params[key]
	min_members = int(rule("min_members", min_members))
	join_distance = rule("player/join_margin", 1.5)
	leave_distance = rule("player/leave_margin", 4.5)
	muddy = GameState.weather == &"pluie" or bool(overrides.get("muddy", false))


## Vrai si le joueur peut entrer : le match est en cours.
func _accepts_player() -> bool:
	return running and not ended and phase != Phase.ASSEMBLE


## Le joueur entre dans le champ (à join_margin m du bord).
func _player_close(player: Node3D) -> bool:
	if _field.is_empty():
		return false
	var margin := rule("player/join_margin", 1.5)
	var inflated := _field_rect(margin)
	return inflated.has_point(Vector2(player.global_position.x, player.global_position.z))


## Le joueur sort quand il quitte le champ (leave_margin m au-delà du bord).
func _player_far(player: Node3D) -> bool:
	if _field.is_empty():
		return true
	var inflated := _field_rect(rule("player/leave_margin", 4.5))
	return not inflated.has_point(Vector2(player.global_position.x, player.global_position.z))


func start() -> void:
	# Un match fini ne recommence pas tout seul : le groupe se disperse au créneau suivant.
	if ended and not bool(rule("rematch", 0.0)):
		return
	super()


func _started() -> void:
	ended = false
	_result = {}
	_aborted = false
	half = 1
	elapsed = 0.0
	clock = rule("half_time", 180.0)
	score = {RED: 0, WHITE: 0}
	scorers.clear()
	kids.clear()
	referee = null
	player_goals = 0
	player_touches = 0
	sides = {WHITE: 1.0, RED: -1.0}
	_read_field()
	_make_ball()
	for actor: LifeActor in members:
		_enroll(actor)
	# Les petites arrivent une à une : on attend un peu les retardataires avant de composer les
	# équipes (les arrivées d'après vont sur le banc).
	_set_phase(Phase.ASSEMBLE)
	_assemble_left = rule("assemble_wait", 2.0)
	_assemble_total = 0.0
	_emit(&"match_started", members.size())


## Les équipes sont composées : rouges et blanches, une gardienne chacune, et l'on s'aligne.
func _begin_match() -> void:
	assign_teams([WHITE, RED], [REFEREE])
	for team: StringName in teams:
		for id: StringName in teams[team]:
			var kid: BallKid = kids.get(id)
			if kid != null:
				kid.team = team
	_kickoff_team = WHITE if rng.randf() < 0.5 else RED
	_apply_lineups(false)
	_to_gather()


func _finished() -> void:
	if not ended:
		_aborted = true
		_end_match()
	_clear_rings()
	_free_hud()


func _member_added(actor: LifeActor) -> void:
	actor.stuck_time = rule("ai/stuck_time", 3.5)
	if not running:
		return
	var kid := _enroll(actor)
	if kid == null:
		return
	if phase == Phase.ASSEMBLE:
		_assemble_left = rule("assemble_wait", 2.0)
		return
	# Une arrivée en cours de match va sur le banc de l'équipe qui a le moins de joueuses.
	kid.team = _smaller_team()
	(teams[kid.team] as Array).append(actor.id)
	kid.on_field = false
	_send_home(kid)


func _member_removed(actor: LifeActor) -> void:
	var kid: BallKid = kids.get(actor.id)
	if kid != null:
		_drop_ring(kid)
		kids.erase(actor.id)
		if _fetcher == kid:
			_fetcher = null
			if phase == Phase.LOST:
				_ball_found(&"")
		if kid.on_field and running and not ended:
			_refill_field(kid.team, kid.keeper)
	if actor == referee:
		referee = null
	if members.is_empty():
		_free_ball()
		_free_hud()


func _enroll(actor: LifeActor) -> BallKid:
	if role_of(actor) == REFEREE:
		referee = actor
		return null
	var kid := BallKid.new()
	kid.actor = actor
	kid.think_left = rng.randf_range(0.0, rule("think_period", 0.25))
	kids[actor.id] = kid
	return kid


func _make_ball() -> void:
	_free_ball()
	ball = BALL_SCRIPT.new() as GameBall
	ball.top_level = true
	ball.ground_y = float(_field["ground"])
	ball.configure(overrides)
	if muddy:
		ball.roll_friction *= rule("mud/friction_scale", 2.0)
	ball.walls = _field_rect()
	var goal_half := rule("field/goal_width", 2.9) * 0.5
	var cx := float(_field["cx"])
	for side: StringName in [&"north", &"south"]:
		(
			ball
			. goals
			. append(
				{
					"id": side,
					"side": side,
					"x_min": cx - goal_half,
					"x_max": cx + goal_half,
					"height": rule("field/goal_height", 1.9),
					"depth": rule("field/goal_depth", 1.0),
				}
			)
		)
	ball.entered_goal.connect(_on_ball_goal)
	ball.wall_hit.connect(_on_ball_wall)
	var parent: Node = null
	var map := LifeDirector.current_map()
	if map != null:
		parent = map.get_node_or_null(^"Life")
		if parent == null:
			parent = map
	if parent == null:
		parent = LifeDirector
	parent.add_child(ball)
	ball.place(_field_center())


func _free_ball() -> void:
	if ball != null and is_instance_valid(ball):
		ball.queue_free()
	ball = null


func _set_phase(next: Phase) -> void:
	phase = next
	_phase_time = 0.0


func _to_gather() -> void:
	_set_phase(Phase.GATHER)
	for kid: BallKid in kids.values():
		_send_home(kid)
	_place_referee()


func _to_kickoff() -> void:
	_set_phase(Phase.KICKOFF)
	if ball != null:
		ball.visible = true
		ball.place(_field_center())
	for kid: BallKid in kids.values():
		kid.pending = {}
		if kid.on_field and not kid.actor.is_moving():
			kid.actor.face(_field_center() - kid.actor.position())
	_say_referee("kickoff", "Coup d’envoi !")
	_emit(&"kickoff", _kickoff_team)


func _to_play() -> void:
	_set_phase(Phase.PLAY)
	_protect_left = rule("kick/kickoff_protect", 1.0)


func _tick(delta: float, player: Node3D) -> void:
	_player = player
	elapsed += delta
	_phase_time += delta
	if phase == Phase.ASSEMBLE:
		_tick_assemble(delta)
		return
	if ball != null:
		ball.step(delta)
	match phase:
		Phase.GATHER:
			_tick_gather()
		Phase.KICKOFF:
			if _phase_time >= rule("kickoff_wait", 1.2):
				_to_play()
		Phase.PLAY:
			_tick_play(delta)
		Phase.GOAL:
			if _phase_time >= rule("goal_pause", 3.0):
				_to_gather()
		Phase.LOST:
			_tick_lost(delta)
		Phase.HALFTIME:
			if _phase_time >= rule("break_time", 8.0):
				_start_second_half()
		Phase.ENDED:
			pass
	_tick_kids(delta)
	_tick_player(delta)
	_tick_referee(delta)
	_tick_hud(delta)


func _tick_assemble(delta: float) -> void:
	_assemble_left -= delta
	_assemble_total += delta
	for actor: LifeActor in members:
		if not actor.is_moving() and not actor.is_holding():
			actor.play(&"repos")
	if _assemble_left <= 0.0 or _assemble_total >= rule("assemble_max", 20.0):
		_begin_match()


func _tick_gather() -> void:
	var ready := true
	for kid: BallKid in kids.values():
		if kid.actor.is_moving():
			ready = false
	if _phase_time >= rule("gather_timeout", 14.0):
		for kid: BallKid in kids.values():
			if kid.actor.is_moving():
				var at := home_position(kid) if kid.on_field else bench_position(kid)
				kid.actor.stop()
				kid.actor.set_position(at)
		ready = true
	if ready and _phase_time >= 0.4:
		_to_kickoff()


func _tick_play(delta: float) -> void:
	clock -= delta
	_protect_left = maxf(_protect_left - delta, 0.0)
	_chase_left -= delta
	if _chase_left <= 0.0:
		_chase_left = rule("think_period", 0.25)
		_update_chasers()
	_keepers_block()
	if clock <= 0.0:
		_end_half()


func _end_half() -> void:
	if half >= int(rule("halves", 2.0)):
		_end_match()
		return
	_set_phase(Phase.HALFTIME)
	_say_referee("half_time", "Mi-temps !")
	_emit(&"half_time", score.duplicate())
	for kid: BallKid in kids.values():
		kid.pending = {}
		kid.actor.stop()
		kid.actor.play(&"parle")


func _start_second_half() -> void:
	half += 1
	clock = rule("half_time", 180.0)
	for team: StringName in sides:
		sides[team] = -float(sides[team])
	_kickoff_team = RED if _kickoff_team == WHITE else WHITE
	_apply_lineups(true)
	_to_gather()
	if player_in:
		_refresh_player_slot()


func _end_match() -> void:
	ended = true
	_set_phase(Phase.ENDED)
	var winner := &"egalite"
	if int(score[RED]) > int(score[WHITE]):
		winner = RED
	elif int(score[WHITE]) > int(score[RED]):
		winner = WHITE
	_result = {
		"winner": winner,
		"score": score.duplicate(),
		"scorers": scorers.duplicate(),
		"player_team": player_team,
		"player_goals": player_goals,
		"player_touches": player_touches,
		"duration": elapsed,
		"halves": half,
		"aborted": _aborted,
	}
	if not _aborted:
		_say_referee("full_time", "Fin du match !")
		for kid: BallKid in kids.values():
			kid.pending = {}
			if kid.team == winner:
				kid.actor.hold(&"saut", 1.4)
			else:
				kid.actor.stop()
				kid.actor.play(&"repos")
	_emit(&"match_ended", _result)
	match_finished.emit(_result)
	if running and not _aborted:
		call_deferred(&"finish")


func _on_ball_goal(goal_id: StringName) -> void:
	if phase != Phase.PLAY:
		return
	# La cage nord est celle des blanches (en première mi-temps) : le but y compte pour l'autre
	# équipe, selon le sens de l'attaque courant.
	var defender := WHITE
	for team: StringName in sides:
		var own_north := float(sides[team]) > 0.0
		if (goal_id == &"north") == own_north:
			defender = team
	var attacker := RED if defender == WHITE else WHITE
	score[attacker] = int(score[attacker]) + 1
	var scorer: StringName = ball.last_kicker
	var scorer_team := &""
	if scorer == PLAYER_ID:
		scorer_team = player_team
		if scorer_team == attacker:
			player_goals += 1
	elif kids.has(scorer):
		scorer_team = (kids[scorer] as BallKid).team
	if scorer_team == attacker and not scorer.is_empty():
		scorers[scorer] = int(scorers.get(scorer, 0)) + 1
		if kids.has(scorer):
			(kids[scorer] as BallKid).goals += 1
	_set_phase(Phase.GOAL)
	_kickoff_team = defender
	for kid: BallKid in kids.values():
		kid.pending = {}
		kid.chasing = false
	if kids.has(scorer) and scorer_team == attacker:
		var kid: BallKid = kids[scorer]
		kid.actor.hold(&"saut", 1.5)
		kid.actor.say(text("goal", "But !"))
	else:
		_say_referee("goal", "But !")
	_emit(&"goal", [attacker, scorer, score.duplicate()])
	_refresh_hud()


func _on_ball_wall(side: StringName, at: Vector3, impact: float) -> void:
	if side != &"east" or phase != Phase.PLAY:
		return
	var places := LifeDirector.places()
	var thicket_name := StringName(str(param("thicket", "fourre_ballon")))
	if places == null or not places.has(thicket_name):
		return
	var thicket := places.center(thicket_name)
	if absf(at.z - thicket.z) > rule("thicket/zone", 2.2):
		return
	if impact < rule("thicket/min_speed", 3.0) or rng.randf() > rule("thicket/chance", 0.5):
		return
	lose_ball()


## Le ballon file dans le fourré (est) : une petite va le chercher ; le joueur peut y aller aussi.
func lose_ball() -> void:
	var places := LifeDirector.places()
	var thicket_name := StringName(str(param("thicket", "fourre_ballon")))
	if ball == null or places == null or not places.has(thicket_name):
		return
	var thicket := places.point(thicket_name, 0)
	_set_phase(Phase.LOST)
	_fetch_left = rule("thicket/fetch_timeout", 14.0)
	ball.place(thicket.origin)
	ball.visible = false
	_fetcher = null
	var best := INF
	for kid: BallKid in kids.values():
		if not kid.on_field or kid.keeper or kid.down_left > 0.0:
			continue
		var distance := flat_distance(kid.actor.position(), thicket.origin)
		if distance < best:
			best = distance
			_fetcher = kid
	for kid: BallKid in kids.values():
		kid.pending = {}
		kid.chasing = false
		if kid != _fetcher and kid.on_field:
			kid.actor.stop()
			kid.actor.play(&"repos")
	if _fetcher != null:
		_fetcher.actor.say(text("lost", "Mon ballon !"))
		var stand := thicket.origin + Vector3(-1.1, 0.0, 0.2)
		_fetcher.actor.walk_to(stand, thicket.origin - stand, &"course", _on_fetcher_arrived, true)
	_emit(&"ball_lost", _fetcher.actor.id if _fetcher != null else &"")


func _on_fetcher_arrived() -> void:
	if phase != Phase.LOST or _fetcher == null:
		return
	_fetcher.actor.hold(&"saut", rule("thicket/dive_time", 1.6))
	_fetch_left = minf(_fetch_left, rule("thicket/dive_time", 1.6) + 0.2)


func _tick_lost(delta: float) -> void:
	_fetch_left -= delta
	var places := LifeDirector.places()
	var thicket_name := StringName(str(param("thicket", "fourre_ballon")))
	if places != null and places.has(thicket_name) and _player != null and player_in:
		if (
			flat_distance(_player.global_position, places.center(thicket_name))
			< rule("thicket/player_reach", 1.4)
		):
			_ball_found(PLAYER_ID)
			return
	if _fetch_left <= 0.0:
		_ball_found(_fetcher.actor.id if _fetcher != null else &"")


func _ball_found(by: StringName) -> void:
	if phase != Phase.LOST:
		return
	var places := LifeDirector.places()
	var thicket_name := StringName(str(param("thicket", "fourre_ballon")))
	var from := (
		places.center(thicket_name)
		if places != null and places.has(thicket_name)
		else _field_center()
	)
	var back := _clamp_to_field(from + Vector3(-rule("thicket/return_offset", 1.6), 0.0, 1.0))
	ball.visible = true
	ball.place(back)
	var landing := _clamp_to_field(
		_field_center() + Vector3(rng.randf_range(-3.0, 3.0), 0.0, rng.randf_range(-3.0, 3.0))
	)
	ball.launch_to(landing, 1.1, by)
	if by == PLAYER_ID:
		if _fetcher != null:
			_fetcher.actor.stop()
			_fetcher.actor.play(&"repos")
		_say_referee("found_player", "Merci, {player} !")
	elif _fetcher != null:
		_fetcher.actor.say(text("found", "Je l’ai !"))
		_fetcher.actor.hold(&"lance", 0.5)
	_set_phase(Phase.PLAY)
	_emit(&"ball_found", by)
	_fetcher = null


func _player_joined() -> void:
	player_team = _smaller_team()
	(teams[player_team] as Array).append(PLAYER_ID)
	_refresh_player_slot()
	_hud = SCORE_SCRIPT.new() as CanvasLayer
	LifeDirector.add_child(_hud)
	_refresh_hud()
	_say_referee("player_in_%s" % player_team, "{player} joue avec nous !")


func _player_left() -> void:
	var left_team := player_team
	if left_team != &"" and teams.has(left_team):
		(teams[left_team] as Array).erase(PLAYER_ID)
	player_team = &""
	_free_hud()
	if left_team != &"" and running and not ended:
		for kid: BallKid in team_kids(left_team):
			if not kid.on_field:
				var counts := field_kids(left_team).size()
				if counts < field_size():
					_refill_player_spot(kid)
				break


func _refill_player_spot(kid: BallKid) -> void:
	kid.on_field = true
	kid.keeper = false
	kid.home = Vector2(rng.randf_range(-0.6, 0.6), rng.randf_range(0.35, 0.7))
	_update_ring(kid)
	_send_home(kid)


## Le joueur prend une place sur le terrain : la dernière arrivée de son équipe va sur le banc.
func _refresh_player_slot() -> void:
	if player_team == &"":
		return
	var field := field_kids(player_team)
	while field.size() > 0 and field.size() + 1 > field_size():
		var out: BallKid = null
		for kid: BallKid in field:
			if not kid.keeper and (out == null or kid.touches < out.touches):
				out = kid
		if out == null:
			break
		out.on_field = false
		out.chasing = false
		out.actor.say(text("sub", "À toi !"))
		_drop_ring(out)
		_send_home(out)
		field.erase(out)


## Le joueur frappe de l'épée : si le ballon est près, il part (sans mal pour personne).
func on_player_attack(player: Node3D) -> void:
	if not player_in or phase != Phase.PLAY:
		return
	_player = player
	_player_kick_left = rule("player/kick_delay", 0.12)


func _tick_player(delta: float) -> void:
	if not player_in or _player == null or ball == null or phase == Phase.LOST:
		_player_kick_left = -1.0
		return
	_player_touch_left = maxf(_player_touch_left - delta, 0.0)
	var player := _player
	var ball_at := ball.ground_position()
	var offset := ball_at - player.global_position
	offset.y = 0.0
	if _player_kick_left >= 0.0:
		_player_kick_left -= delta
		if _player_kick_left < 0.0:
			_player_kicks(player, offset)
		return
	if phase != Phase.PLAY or ball.height > 0.6 or _player_touch_left > 0.0:
		return
	# En courant contre le ballon, on le pousse devant soi.
	var velocity := Vector3.ZERO
	if player is CharacterBody3D:
		velocity = (player as CharacterBody3D).velocity
	velocity.y = 0.0
	if (
		offset.length() < rule("player/touch_radius", 0.6)
		and velocity.length() >= rule("player/touch_min_speed", 2.4)
	):
		if velocity.normalized().dot(offset.normalized()) > 0.3:
			ball.kick(velocity.normalized(), maxf(velocity.length() * 1.3, 2.4), 0.0, PLAYER_ID)
			_player_touch_left = rule("player/touch_cooldown", 0.4)
			player_touches += 1


func _player_kicks(player: Node3D, offset: Vector3) -> void:
	if phase != Phase.PLAY or offset.length() > rule("player/kick_reach", 1.6) or ball.height > 1.0:
		return
	var aim := Vector3.FORWARD
	if player.has_method(&"aim_direction"):
		aim = player.call(&"aim_direction")
	var arc := deg_to_rad(rule("player/kick_arc_deg", 140.0)) * 0.5
	if offset.length() > 0.3 and offset.normalized().angle_to(aim) > arc:
		return
	ball.kick(aim, rule("player/kick_speed", 8.5), rule("player/kick_lift", 0.8), PLAYER_ID)
	player_touches += 1
	_player_touch_left = rule("player/touch_cooldown", 0.4)
	_emit(&"player_kick", aim)


func _place_referee() -> void:
	if referee == null:
		return
	var at := Vector3(float(_field["east"]) - 0.9, float(_field["ground"]), float(_field["cz"]))
	referee.walk_to(at, Vector3(-1.0, 0.0, 0.0), &"marche", Callable(), true)


func _tick_referee(_delta: float) -> void:
	if referee == null or not is_instance_valid(referee.npc) or referee.talking:
		return
	if referee.is_moving() or referee.is_holding():
		return
	referee.play(&"repos")
	if ball == null:
		return
	var ball_at := ball.ground_position()
	referee.face(ball_at - referee.position())
	# Il suit le jeu le long de la touche.
	var z := clampf(ball_at.z, float(_field["north"]) + 2.0, float(_field["south"]) - 2.0)
	if absf(z - referee.position().z) > 4.0 and phase == Phase.PLAY:
		var at := Vector3(float(_field["east"]) - 0.9, float(_field["ground"]), z)
		referee.walk_to(at, ball_at - at, &"marche", Callable(), true)


## Une réplique de l'arbitre (sinon d'une joueuse).
func _say_referee(key: String, fallback: String) -> void:
	var line := text(key, fallback)
	if referee != null and is_instance_valid(referee.npc):
		referee.say(line)
	elif not members.is_empty():
		members[0].say(line)


func _tick_hud(delta: float) -> void:
	_hud_left -= delta
	if _hud_left <= 0.0:
		_hud_left = 0.25
		_refresh_hud()


## Texte du score, sobre : « Blanches 1 – 0 Rouges · 1re mi-temps 2:41 ».
func hud_text() -> String:
	var white_name := text("team_blanc", "Blanches")
	var red_name := text("team_rouge", "Rouges")
	var label := text("half_%d" % half, "%de mi-temps" % half)
	if phase == Phase.HALFTIME:
		label = text("half_break", "Mi-temps")
	elif phase == Phase.ENDED:
		label = text("full_time_label", "Fin du match")
	else:
		var left := maxi(ceili(clock), 0)
		label += " %d:%02d" % [floori(left / 60.0), left % 60]
	return "%s %d – %d %s  ·  %s" % [white_name, score[WHITE], score[RED], red_name, label]


func _refresh_hud() -> void:
	if _hud != null and is_instance_valid(_hud):
		_hud.call(&"set_text", hud_text())


func _free_hud() -> void:
	if _hud != null and is_instance_valid(_hud):
		_hud.queue_free()
	_hud = null
