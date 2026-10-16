extends GutTest
## (E8) Le ballon sur l'entrepôt (game.tscn, WorldManager.enter_map, le vrai champ) : deux équipes,
## des gardiennes, un ballon qui roule ; un but se marque et se compte ; la mi-temps passe (on
## change de côté, les meilleures buteuses restent) ; le match finit avec un résultat ; le joueur
## entre, frappe et sort ; le ballon perdu dans le fourré est rapporté ; et l'IA joue, sans petite
## coincée, dans une partie simulée de deux minutes (le jeu est avancé à la main, plus vite que le
## temps).

const GAME_SCENE := preload("res://src/game.tscn")
const MAP := &"entrepot"
const DT := 1.0 / 60.0

var _game: Node3D
var _player: Player
var _match: BallMatch


func before_all() -> void:
	GameState.reset()
	WorldManager.fade_time = 0.0
	_game = GAME_SCENE.instantiate() as Node3D
	add_child(_game)
	_player = _game.get_node(^"Player") as Player
	LifeDirector.set_slot(&"apres_midi", 0.0)
	assert_true(WorldManager.enter_map(MAP))


func after_all() -> void:
	WorldManager.fade_time = WorldManager.DEFAULT_FADE_TIME
	_game.free()
	LifeDirector.attach(null)
	Atmosphere.dress(null)
	GameState.reset()
	GameRules.clear_cache()


func before_each() -> void:
	GameRules.clear_cache()
	# La carte est peuplée de nouveau (sans les petites du test d'avant), la navigation refaite.
	LifeDirector.set_slot(&"apres_midi", 0.0)
	LifeDirector.attach(WorldManager.current_map_node())
	LifeDirector.build_nav_now()
	# Loin du champ : le joueur n'entre pas dans la partie.
	_player.global_position = Vector3(30.0, 0.0, 40.0)
	_player.velocity = Vector3.ZERO
	_match = null


func after_each() -> void:
	if _match != null:
		MiniGames.stop_ball_match()
	_match = null


func _start(options: Dictionary = {}) -> BallMatch:
	var merged := options.duplicate(true)
	var rules: Dictionary = merged.get("overrides", {})
	if not rules.has("assemble_wait"):
		rules["assemble_wait"] = 0.1
	merged["overrides"] = rules
	_match = MiniGames.start_ball_match(merged)
	assert_not_null(_match, "le match démarre")
	# Les retardataires attendus, les équipes sont composées.
	_simulate(3.0, func() -> bool: return _match.phase != BallMatch.Phase.ASSEMBLE)
	_match.rng.seed = 20261015
	return _match


## Les petites ne réfléchissent plus pendant seconds s (un scénario sans personne dans le chemin).
func _freeze_ai(seconds: float = 100.0) -> void:
	for kid: BallKid in _match.kids.values():
		kid.think_left = seconds


## Avance le directeur (donc les petites, le jeu et le ballon) de seconds s, sans attendre le temps.
func _simulate(seconds: float, until: Callable = Callable()) -> void:
	for _i: int in roundi(seconds / DT):
		LifeDirector._physics_process(DT)
		if until.is_valid() and until.call():
			return


func _in_phase(phase: BallMatch.Phase) -> bool:
	return _match.phase == phase


func test_a_match_forms_two_teams_with_keepers_and_a_ball() -> void:
	_start()
	assert_true(_match.running, "en cours")
	assert_eq(_match.members.size(), 11, "dix petites et l'arbitre")
	assert_eq(_match.team_kids(BallMatch.WHITE).size(), 5)
	assert_eq(_match.team_kids(BallMatch.RED).size(), 5)
	assert_eq(_match.teams[BallMatch.WHITE].size(), 5, "LifeGame.assign_teams")
	assert_not_null(_match.referee, "Willem arbitre")
	assert_eq(_match.referee.id, &"willem")
	for team: StringName in [BallMatch.WHITE, BallMatch.RED]:
		var keepers := 0
		for kid: BallKid in _match.field_kids(team):
			keepers += 1 if kid.keeper else 0
		assert_eq(keepers, 1, "une gardienne chez %s" % team)
	assert_not_null(_match.ball, "le ballon")
	assert_true(_match.ball.is_inside_tree())
	assert_eq(_match.ball.get_parent().name, "Life", "dans la carte")
	assert_almost_eq(_match.ball.position.x, 75.0, 0.01, "au centre du champ")
	assert_almost_eq(_match.ball.position.z, 18.0, 0.01)
	assert_almost_eq(_match.ball.ground_y, -0.5, 0.01, "à la hauteur du champ")
	# Les cages de la carte : blanches au nord (z = 8), rouges au sud (z = 28).
	assert_almost_eq(
		float(_match.goal_position(BallMatch.WHITE).z), 28.0, 0.01, "elles visent le sud"
	)
	assert_almost_eq(float(_match.goal_position(BallMatch.RED).z), 8.0, 0.01)
	for kid: BallKid in _match.kids.values():
		if kid.on_field:
			assert_not_null(kid.ring, "un anneau d'équipe sous %s" % kid.actor.id)


func test_everyone_reaches_a_post_and_play_starts() -> void:
	_start()
	_simulate(30.0, func() -> bool: return _in_phase(BallMatch.Phase.PLAY))
	assert_true(_in_phase(BallMatch.Phase.PLAY), "coup d'envoi : %s" % _match.phase)
	for kid: BallKid in _match.kids.values():
		var at := _match.home_position(kid)
		assert_lt(
			Vector2(kid.actor.position().x - at.x, kid.actor.position().z - at.z).length(),
			4.0,
			"%s est vers son poste" % kid.actor.id
		)


func test_the_ai_scores_in_a_simulated_two_minutes_and_nobody_is_stuck() -> void:
	_start({"overrides": {"half_time": 130}})
	var started: Array = []
	_match.event.connect(
		func(kind: StringName, detail: Variant) -> void: started.append([kind, detail])
	)
	var stuck: Dictionary = {}
	var worst: Dictionary = {}
	var last: Dictionary = {}
	var inside := Rect2(60.0, 4.0, 30.0, 28.0)
	var outside: Array[String] = []
	for _i: int in roundi(135.0 / DT):
		LifeDirector._physics_process(DT)
		for kid: BallKid in _match.kids.values():
			var here := kid.actor.position()
			if not inside.has_point(Vector2(here.x, here.z)):
				outside.append("%s en %s" % [kid.actor.id, here])
			var id := kid.actor.id
			var before: Vector3 = last.get(id, here)
			last[id] = here
			var still := (
				_match.phase == BallMatch.Phase.PLAY
				and kid.chasing
				and kid.on_field
				and kid.down_left <= 0.0
				and not kid.actor.is_holding()
				and flat(before, here) < 0.002
			)
			stuck[id] = float(stuck.get(id, 0.0)) + DT if still else 0.0
			worst[id] = maxf(float(worst.get(id, 0.0)), float(stuck[id]))
	assert_eq(outside, [] as Array[String], "personne ne quitte les abords du champ")
	var goals := started.filter(func(entry: Array) -> bool: return entry[0] == &"goal")
	assert_gt(
		goals.size(),
		0,
		"au moins un but en deux minutes (%d coups de pied)" % _count(started, &"kick")
	)
	assert_gt(_count(started, &"kick"), 20, "elles jouent")
	var total := int(_match.score[BallMatch.RED]) + int(_match.score[BallMatch.WHITE])
	assert_eq(total, goals.size(), "le score compte les buts")
	for id: StringName in worst:
		assert_lt(float(worst[id]), 6.0, "%s n'est pas coincée" % id)
	gut.p(
		(
			"buts %d, coups de pied %d, chutes %d, arrêts %d"
			% [
				goals.size(),
				_count(started, &"kick"),
				_count(started, &"fall"),
				_count(started, &"save")
			]
		)
	)


func test_a_goal_is_scored_counted_and_play_restarts() -> void:
	_start({"overrides": {"keeper/miss_chance": 1.0}})
	_simulate(30.0, func() -> bool: return _in_phase(BallMatch.Phase.PLAY))
	var goals: Array = []
	_match.event.connect(
		func(kind: StringName, detail: Variant) -> void:
			if kind == &"goal":
				goals.append(detail)
	)
	# Un tir des blanches (qui visent le sud) dans la cage sud.
	_freeze_ai()
	_match.ball.place(Vector3(75.0, -0.5, 24.0))
	_match.ball.kick(Vector3(0.0, 0.0, 1.0), 9.0, 0.0, &"tiat")
	_simulate(3.0, func() -> bool: return not goals.is_empty())
	assert_eq(goals.size(), 1, "un but")
	assert_eq(goals[0][0], BallMatch.WHITE, "pour les blanches")
	assert_eq(_match.score[BallMatch.WHITE], 1)
	assert_eq(_match.score[BallMatch.RED], 0)
	assert_eq(_match.scorers.get(&"tiat", 0), 1, "Tiat a marqué")
	assert_eq((_match.kid_of(LifeDirector.actor(&"tiat")) as BallKid).goals, 1)
	assert_true(_in_phase(BallMatch.Phase.GOAL))
	assert_string_contains(_match.hud_text(), "1 – 0")
	# Après la pause, on s'aligne et l'on remet en jeu depuis le centre.
	_simulate(25.0, func() -> bool: return _in_phase(BallMatch.Phase.PLAY))
	assert_true(_in_phase(BallMatch.Phase.PLAY), "reprise")
	assert_eq(_match.score[BallMatch.WHITE], 1, "le score reste")


func test_the_goalkeeper_can_save_a_shot() -> void:
	_start({"overrides": {"keeper/miss_chance": 0.0}})
	_simulate(30.0, func() -> bool: return _in_phase(BallMatch.Phase.PLAY))
	_freeze_ai()
	var saves: Array = []
	_match.event.connect(
		func(kind: StringName, _detail: Variant) -> void:
			if kind == &"save":
				saves.append(1)
	)
	var keeper: BallKid = null
	for kid: BallKid in _match.field_kids(BallMatch.RED):
		if kid.keeper:
			keeper = kid
	var at := keeper.actor.position()
	# Le tir arrive sur la gardienne des rouges (elle défend le sud) : elle l'arrête.
	_match.ball.place(Vector3(at.x, -0.5, at.z - 0.5))
	_match.ball.kick(Vector3(0.0, 0.0, 1.0), 8.0, 0.0, &"tiat")
	_simulate(0.5, func() -> bool: return not saves.is_empty())
	assert_eq(saves.size(), 1, "arrêt de la gardienne")
	assert_lt(_match.ball.velocity.z, 0.0, "le ballon repart vers le jeu")
	assert_eq(int(_match.score[BallMatch.WHITE]), 0, "pas de but")


func test_half_time_swaps_sides_and_keeps_the_best_scorers() -> void:
	# Quatre par équipe sur le terrain : un remplaçant de chaque côté.
	_start({"overrides": {"half_time": 12, "team_size": 4, "break_time": 3}})
	_simulate(30.0, func() -> bool: return _in_phase(BallMatch.Phase.PLAY))
	assert_eq(_match.field_kids(BallMatch.WHITE).size(), 4)
	var benched_before: Array[StringName] = []
	for team: StringName in [BallMatch.WHITE, BallMatch.RED]:
		for kid: BallKid in _match.team_kids(team):
			if not kid.on_field:
				benched_before.append(kid.actor.id)
	assert_eq(benched_before.size(), 2, "un banc par équipe")
	# La meilleure buteuse de chaque équipe (une déjà sur le terrain, qui n'est pas la gardienne).
	var star := {}
	for team: StringName in [BallMatch.WHITE, BallMatch.RED]:
		for kid: BallKid in _match.field_kids(team):
			if not kid.keeper and not star.has(team):
				kid.goals = 2
				star[team] = kid.actor.id
	_simulate(40.0, func() -> bool: return _in_phase(BallMatch.Phase.HALFTIME))
	assert_true(_in_phase(BallMatch.Phase.HALFTIME), "mi-temps")
	assert_eq(_match.half, 1)
	var white_before := float(_match.sides[BallMatch.WHITE])
	_simulate(8.0, func() -> bool: return _match.half == 2)
	assert_eq(_match.half, 2, "seconde mi-temps")
	assert_eq(float(_match.sides[BallMatch.WHITE]), -white_before, "on change de côté")
	for team: StringName in [BallMatch.WHITE, BallMatch.RED]:
		assert_true((_match.kids[star[team]] as BallKid).on_field, "%s : la buteuse reste" % team)
	var entered := 0
	for id: StringName in benched_before:
		entered += 1 if (_match.kids[id] as BallKid).on_field else 0
	assert_eq(entered, 2, "les remplaçantes entrent")
	assert_string_contains(_match.hud_text(), "2e mi-temps")


func test_the_match_ends_with_a_result_for_the_story() -> void:
	_start({"overrides": {"half_time": 8, "break_time": 2}})
	var results: Array = []
	_match.match_finished.connect(func(found: Dictionary) -> void: results.append(found))
	_simulate(60.0, func() -> bool: return not results.is_empty())
	assert_eq(results.size(), 1, "match_finished une fois")
	var result: Dictionary = results[0]
	assert_true(_match.ended)
	assert_has([&"rouge", &"blanc", &"egalite"], result["winner"])
	assert_eq(
		result["score"][BallMatch.RED] + result["score"][BallMatch.WHITE],
		_match.score[BallMatch.RED] + _match.score[BallMatch.WHITE]
	)
	assert_eq(result["halves"], 2)
	assert_false(result["aborted"])
	assert_eq(_match.result(), result)
	await wait_physics_frames(2)
	assert_false(_match.running, "le jeu est fini")


func test_the_player_joins_by_approaching_kicks_and_leaves() -> void:
	_start()
	_simulate(30.0, func() -> bool: return _in_phase(BallMatch.Phase.PLAY))
	assert_false(_match.player_in, "il est loin")
	# Il approche du champ : il entre.
	_player.global_position = Vector3(64.5, -0.5, 18.0)
	_simulate(0.2)
	assert_true(_match.player_in, "il entre en approchant")
	assert_eq(_match.player_team, BallMatch.WHITE, "les blanches à égalité")
	assert_has(_match.teams[BallMatch.WHITE], &"player")
	assert_eq(_match.field_kids(BallMatch.WHITE).size(), 4, "une petite lui laisse sa place")
	assert_string_contains(_match.hud_text(), "Blanches")
	# Tant qu'il joue, personne du match ne propose de conversation (pas d'invite « Parler »).
	var tiat := LifeDirector.npc(&"tiat")
	assert_eq(tiat.get_prompt(), "", "pas d'invite pendant la partie")
	assert_eq(LifeDirector.npc(&"willem").get_prompt(), "")
	# (U1) L'invite est un signe posé au-dessus de la cible : aucun sur les joueurs du match.
	assert_eq(InteractSign.kind_of(tiat), &"", "pas de signe au-dessus des joueuses")
	assert_eq(InteractSign.kind_of(LifeDirector.npc(&"willem")), &"")
	# Il frappe de l'épée près du ballon : la balle part dans sa direction, sans mal.
	_player.global_position = Vector3(75.0, -0.5, 14.0)
	_player.set_aim_direction(Vector3(0.0, 0.0, 1.0))
	_match.ball.place(Vector3(75.0, -0.5, 15.0))
	_match.on_player_attack(_player)
	_simulate(0.4)
	assert_gt(_match.ball.position.z, 15.4, "elle part vers le sud")
	assert_eq(_match.player_touches, 1)
	assert_eq(_match.ball.last_kicker, &"player")
	assert_eq(_player.health.current, _player.health.max_hp, "personne n'est blessé")
	# Il sort du champ : il quitte la partie, la petite sur le banc revient.
	_player.global_position = Vector3(55.0, -0.5, 18.0)
	_simulate(0.2)
	assert_false(_match.player_in, "il sort en quittant le champ")
	assert_eq(tiat.get_prompt(), "Parler", "on peut de nouveau leur parler")
	assert_eq(InteractSign.kind_of(tiat), InteractSign.TALK, "le signe « parler » revient")
	assert_eq(_match.player_team, &"")
	_simulate(0.3)
	assert_eq(_match.field_kids(BallMatch.WHITE).size(), 5, "elle reprend sa place")


func test_the_player_can_score_for_his_team() -> void:
	_start({"overrides": {"keeper/miss_chance": 1.0}})
	_simulate(30.0, func() -> bool: return _in_phase(BallMatch.Phase.PLAY))
	_player.global_position = Vector3(75.0, -0.5, 22.0)
	_simulate(0.2)
	assert_true(_match.player_in)
	_freeze_ai()
	_player.set_aim_direction(Vector3(0.0, 0.0, 1.0))
	_match.ball.place(Vector3(75.0, -0.5, 23.0))
	_match.on_player_attack(_player)
	_simulate(3.0, func() -> bool: return _in_phase(BallMatch.Phase.GOAL))
	assert_eq(_match.player_goals, 1, "son but compte")
	assert_eq(int(_match.score[_match.player_team]), 1)


func test_the_ball_lost_in_the_thicket_is_brought_back() -> void:
	_start()
	_simulate(30.0, func() -> bool: return _in_phase(BallMatch.Phase.PLAY))
	var events: Array[StringName] = []
	_match.event.connect(func(kind: StringName, _detail: Variant) -> void: events.append(kind))
	_match.lose_ball()
	assert_true(_in_phase(BallMatch.Phase.LOST), "le jeu s'arrête")
	assert_false(_match.ball.visible, "le ballon est dans les ronces")
	assert_has(events, &"ball_lost")
	var clock := _match.clock
	_simulate(30.0, func() -> bool: return _in_phase(BallMatch.Phase.PLAY))
	assert_true(_in_phase(BallMatch.Phase.PLAY), "une petite l'a rapporté")
	assert_true(_match.ball.visible)
	assert_has(events, &"ball_found")
	assert_almost_eq(_match.clock, clock, 20.0, "l'horloge s'est arrêtée pendant la recherche")


func test_the_player_can_fetch_the_ball_himself() -> void:
	_start()
	_simulate(30.0, func() -> bool: return _in_phase(BallMatch.Phase.PLAY))
	_player.global_position = Vector3(70.0, -0.5, 18.0)
	_simulate(0.2)
	assert_true(_match.player_in)
	_match.lose_ball()
	var found: Array = []
	_match.event.connect(
		func(kind: StringName, detail: Variant) -> void:
			if kind == &"ball_found":
				found.append(detail)
	)
	_player.global_position = Vector3(83.0, -0.5, 10.0)
	_simulate(0.5)
	assert_eq(found, [&"player"], "il le rapporte")
	assert_true(_in_phase(BallMatch.Phase.PLAY))


func test_mud_slows_the_ball() -> void:
	_start({"muddy": true})
	var plain := GameRules.number(&"ballon", "ball/roll_friction", 1.4)
	assert_almost_eq(_match.ball.roll_friction, plain * 2.0, 0.001, "le ballon ralentit")


func test_nobody_is_hurt_and_the_match_disperses() -> void:
	_start()
	_simulate(40.0)
	assert_eq(_player.health.current, _player.health.max_hp)
	MiniGames.stop_ball_match()
	_match = null
	assert_null(MiniGames.ball_match(), "disperse")


func test_the_match_adds_few_drawables_to_the_map() -> void:
	# 200 draw calls au plus par vue (PLAN.md) : le décor fondu du champ plus 45 autres (test_entrepot)
	# laissent de la place ; mesuré en vrai (Xvfb) par tests/integration/demo_e8.gd, au plus fort du
	# match. Ici : ce que la vie et le match posent sur la carte (PNJ, ombres, anneaux, ballon).
	var before := _drawables(LifeDirector.current_map().get_node(^"Life"))
	_start()
	_simulate(30.0, func() -> bool: return _in_phase(BallMatch.Phase.PLAY))
	var added := _drawables(LifeDirector.current_map().get_node(^"Life")) - before
	gut.p("le match pose %d objets dessinables (11 PNJ, 10 anneaux, ballon)" % added)
	assert_lt(added, 45, "PNJ, ombres, anneaux et ballon")


## Objets dessinables visibles sous node (images, ombres, anneaux ; les enfants internes aussi).
func _drawables(node: Node) -> int:
	var count := 0
	for child: Node in node.get_children(true):
		var instance := child as GeometryInstance3D
		if instance != null and instance.is_visible_in_tree():
			if not (instance is MeshInstance3D and (instance as MeshInstance3D).mesh == null):
				count += 1
		count += _drawables(child)
	return count


func flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _count(events: Array, kind: StringName) -> int:
	return events.filter(func(entry: Array) -> bool: return entry[0] == kind).size()
