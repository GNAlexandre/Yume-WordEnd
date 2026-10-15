extends GutTest
## (E8) Le ballon (src/games/ball.gd) : il roule et s'arrête, rebondit sur le sol et les murs, entre
## dans un but, retombe où on le lance ; ses chiffres viennent de data/games/ballon.json.

var _ball: GameBall


func before_each() -> void:
	GameRules.clear_cache()
	_ball = GameBall.new()
	_ball.configure()
	_ball.walls = Rect2(0.0, 0.0, 18.0, 20.0)
	add_child_autofree(_ball)
	_ball.place(Vector3(9.0, 0.0, 10.0))


func _run(seconds: float) -> void:
	for _i: int in roundi(seconds * 60.0):
		_ball.step(1.0 / 60.0)


func test_the_rules_file_is_valid_and_has_every_number_the_game_reads() -> void:
	assert_eq(GameRules.problems(&"ballon"), PackedStringArray(), "format du fichier")
	for key: String in ["half_time", "team_size", "ball/bounce", "kick/shot_speed", "keeper/reach"]:
		assert_not_null(GameRules.value(&"ballon", key, null), "%s existe" % key)


func test_a_kicked_ball_rolls_then_stops() -> void:
	_ball.kick(Vector3.RIGHT, 5.0)
	assert_true(_ball.is_moving())
	_run(1.0)
	assert_gt(_ball.position.x, 9.0 + 3.0, "elle avance")
	assert_lt(_ball.speed(), 5.0, "elle ralentit (frottement du sol)")
	_run(6.0)
	assert_false(_ball.is_moving(), "elle s'arrête")
	assert_almost_eq(_ball.position.x, 9.0 + 5.0 * 5.0 / (2.0 * _ball.roll_friction), 0.6)
	assert_eq(_ball.height, 0.0, "au sol")


func test_a_lifted_ball_bounces_lower_each_time() -> void:
	var impacts: Array[float] = []
	_ball.bounced.connect(func(impact: float) -> void: impacts.append(impact))
	_ball.kick(Vector3.RIGHT, 2.0, 5.0)
	_run(0.2)
	assert_gt(_ball.height, 0.0, "elle monte")
	_run(4.0)
	assert_gt(impacts.size(), 2, "plusieurs rebonds")
	for i: int in range(1, impacts.size()):
		assert_lt(impacts[i], impacts[i - 1], "chaque rebond est plus bas")
	assert_eq(_ball.height, 0.0, "puis elle roule")


func test_the_walls_send_it_back() -> void:
	var hits: Array[StringName] = []
	_ball.wall_hit.connect(
		func(side: StringName, _at: Vector3, _s: float) -> void: hits.append(side)
	)
	_ball.kick(Vector3.RIGHT, 12.0)
	_run(2.0)
	assert_has(hits, &"east", "le mur est")
	assert_lt(_ball.position.x, 18.0, "elle reste dans le champ")
	assert_gt(_ball.position.x, 0.0)
	_ball.place(Vector3(9.0, 0.0, 10.0))
	_ball.kick(Vector3.FORWARD, 12.0)
	_run(2.0)
	assert_has(hits, &"north", "le mur nord")
	assert_gte(_ball.position.z, 0.0)


func test_a_goal_counts_once_and_the_net_holds_the_ball() -> void:
	_ball.goals = [
		{"id": &"north", "side": &"north", "x_min": 7.5, "x_max": 10.5, "height": 1.9, "depth": 1.0}
	]
	var scored: Array[StringName] = []
	_ball.entered_goal.connect(func(id: StringName) -> void: scored.append(id))
	_ball.kick(Vector3.FORWARD, 9.0, 0.0, &"tiat")
	_run(2.5)
	assert_eq(scored, [&"north"] as Array[StringName], "un seul but")
	assert_eq(_ball.in_goal, &"north")
	assert_lt(_ball.position.z, 0.0, "passée la ligne")
	assert_gt(_ball.position.z, -1.05, "retenue par le fond des filets")
	assert_eq(_ball.last_kicker, &"tiat", "qui a marqué")


func test_a_shot_over_the_bar_or_wide_is_not_a_goal() -> void:
	_ball.goals = [
		{"id": &"north", "side": &"north", "x_min": 7.5, "x_max": 10.5, "height": 1.9, "depth": 1.0}
	]
	var scored: Array[StringName] = []
	_ball.entered_goal.connect(func(id: StringName) -> void: scored.append(id))
	# À côté.
	_ball.place(Vector3(4.0, 0.0, 10.0))
	_ball.kick(Vector3.FORWARD, 9.0)
	_run(2.0)
	# Au-dessus de la barre : très haut, au-dessus des cages à leur ligne.
	_ball.place(Vector3(9.0, 0.0, 4.0))
	_ball.kick(Vector3.FORWARD, 6.0, 7.0)
	_run(3.0)
	assert_eq(scored.size(), 0, "ni à côté ni par-dessus")


func test_a_toss_lands_where_aimed() -> void:
	_ball.launch_to(Vector3(13.0, 0.0, 6.0), 1.2)
	_run(0.6)
	assert_gt(_ball.height, 1.0, "envoyée haut")
	_run(0.62)
	assert_almost_eq(_ball.position.x, 13.0, 0.35)
	assert_almost_eq(_ball.position.z, 6.0, 0.35)
	assert_lt(_ball.height, 0.3, "elle vient de retomber")


func test_predict_matches_the_roll() -> void:
	_ball.kick(Vector3.RIGHT, 4.0)
	var guess := _ball.predict(1.0)
	_run(1.0)
	assert_almost_eq(guess.x, _ball.position.x, 0.25)


func test_the_ball_has_an_image_and_a_ground_shadow() -> void:
	assert_not_null(_ball.get_node_or_null(^"Image"), "le panneau du ballon")
	var shadow := _ball.get_node_or_null(^"Shadow") as Node3D
	assert_not_null(shadow, "l'ombre")
	_ball.kick(Vector3.RIGHT, 2.0, 5.0)
	_run(0.3)
	assert_almost_eq(
		shadow.global_position.y, _ball.ground_y + CombatFx.SHADOW_LIFT, 0.01, "reste au sol"
	)
