extends GutTest
## (E8c) La levée du sentier à l'ouest de marais_chute (docs/CONTRACT_REQUESTS.md, E6 : « C1
## (sentier) ») : la descente dans le marais (x 33 → 36, z 18 → 20) est une rampe taillée dans la
## levée ; son bord ouest est une marche franche de 0 à 0,5 m. Le joueur ne franchit pas une marche
## de plus de 0,1 m ; la navigation (LifeNav, MAX_STEP) ne le fait plus passer par là : remonter du
## marais vers l'ouest à pied, en suivant son chemin avec de vrais appuis, se fait sans buter.

const GAME_SCENE := preload("res://src/game.tscn")
## Le bord ouest de la rampe (CARTE.md 4.2 ; tools/exterior_recipes/sentier.py).
const RAMP_WEST := 33.0
const RAMP_Z := Vector2(18.0, 20.0)

var _game: Node3D
var _player: Player


func before_all() -> void:
	GameState.reset()
	WorldManager.fade_time = 0.0
	_game = GAME_SCENE.instantiate() as Node3D
	add_child(_game)
	_player = _game.get_node(^"Player") as Player
	assert_true(WorldManager.enter_map(&"sentier"))


func after_all() -> void:
	WorldManager.fade_time = WorldManager.DEFAULT_FADE_TIME
	_game.free()
	LifeDirector.attach(null)
	Atmosphere.dress(null)
	GameState.reset()


func before_each() -> void:
	LifeDirector.attach(WorldManager.current_map_node())
	LifeDirector.build_nav_now()


func after_each() -> void:
	for action: StringName in [&"move_left", &"move_right", &"move_forward", &"move_back"]:
		Input.action_release(action)


func _ground() -> MapGround:
	return WorldManager.current_map_node().get_node(^"Ground") as MapGround


func _point(place: StringName) -> Vector3:
	return LifeDirector.places().center(place)


## La plus haute marche franche le long d'une ligne brisée (mesures tous les 0,05 m).
func _highest_step(points: PackedVector3Array) -> float:
	var ground := _ground()
	var highest := 0.0
	for i: int in range(1, points.size()):
		var a := points[i - 1]
		var b := points[i]
		var count := maxi(1, ceili(Vector2(b.x - a.x, b.z - a.z).length() / 0.05))
		var previous := ground.height_at(a.x, a.z)
		for k: int in range(1, count + 1):
			var t := float(k) / count
			var h := ground.height_at(lerpf(a.x, b.x, t), lerpf(a.z, b.z, t))
			highest = maxf(highest, absf(h - previous))
			previous = h
	return highest


func _hold_toward(direction: Vector3) -> void:
	var flat := Vector3(direction.x, 0.0, direction.z).normalized()
	for pair: Array in [
		[&"move_right", flat.x],
		[&"move_left", -flat.x],
		[&"move_back", flat.z],
		[&"move_forward", -flat.z]
	]:
		if float(pair[1]) > 0.001:
			Input.action_press(pair[0], float(pair[1]))
		else:
			Input.action_release(pair[0])


func test_the_ramp_side_is_a_real_step_the_player_cannot_climb() -> void:
	var ground := _ground()
	# Au milieu de la rampe, le bord ouest est une marche de 0,25 m : la navigation la croyait
	# franchissable (MAX_RISE 0,3 m).
	var low := ground.height_at(RAMP_WEST + 0.2, 19.0)
	var high := ground.height_at(RAMP_WEST - 0.2, 19.0)
	assert_almost_eq(high - low, 0.25, 0.02, "une marche franche de 0,25 m")
	assert_gt(high - low, LifeNav.MAX_STEP)
	assert_lt(high - low, LifeNav.MAX_RISE, "sous MAX_RISE : la cause de l'erreur")


func test_the_navigation_no_longer_crosses_the_ramp_side() -> void:
	var nav := LifeDirector.nav()
	assert_true(nav.ready)
	# Les deux cases de part et d'autre du bord, au milieu de la rampe, ne sont plus reliées.
	assert_false(
		nav.line_clear(Vector3(RAMP_WEST + 0.5, 0.0, 19.2), Vector3(RAMP_WEST - 0.5, 0.0, 19.2)),
		"pas de ligne droite par la marche"
	)
	assert_true(
		nav.line_clear(Vector3(34.5, 0.0, 18.2), Vector3(34.5, 0.0, 20.8)),
		"la rampe se monte dans son sens"
	)
	# Du marais (marais_chute) vers l'ouest : le chemin monte la rampe et ne passe pas la marche.
	var start := _point(&"marais_chute")
	var goal := _point(&"premiere_embuscade")
	var path := nav.find_path(start, goal)
	assert_gt(path.size(), 0, "un chemin")
	var points := PackedVector3Array([start])
	points.append_array(path)
	assert_lte(_highest_step(points), 0.1, "aucune marche de plus de 0,1 m sur le chemin")
	# Et la ligne droite d'autrefois, du haut de la rampe vers l'ouest, est refusée.
	assert_false(nav.line_clear(Vector3(33.5, 0.0, 19.5), Vector3(20.5, 0.0, 22.5)))


func test_walking_up_from_the_marsh_to_the_west_does_not_get_stuck() -> void:
	var nav := LifeDirector.nav()
	var start := _point(&"marais_chute")
	var goal := _point(&"premiere_embuscade")
	_player.global_position = start + Vector3(0.0, 0.1, 0.0)
	_player.velocity = Vector3.ZERO
	await wait_physics_frames(5)
	var waypoints := nav.find_path(_player.global_position, goal)
	waypoints.append(goal)
	var index := 0
	var stalled := 0
	var worst_stall := 0
	var last := _player.global_position
	for _frame: int in 60 * 20:
		if index >= waypoints.size():
			break
		var toward := waypoints[index] - _player.global_position
		toward.y = 0.0
		if toward.length() < (1.0 if index == waypoints.size() - 1 else 0.5):
			index += 1
			continue
		_hold_toward(toward)
		await wait_physics_frames(1)
		var moved := Vector2(_player.global_position.x - last.x, _player.global_position.z - last.z)
		last = _player.global_position
		stalled = stalled + 1 if moved.length() < 0.01 else 0
		worst_stall = maxi(worst_stall, stalled)
	for action: StringName in [&"move_left", &"move_right", &"move_forward", &"move_back"]:
		Input.action_release(action)
	assert_eq(index, waypoints.size(), "arrivée à l'ouest, sur la levée")
	assert_lt(worst_stall, 10, "sans buter (au plus 10 images sur place)")
	assert_lt(
		Vector2(_player.global_position.x - goal.x, _player.global_position.z - goal.z).length(),
		1.2
	)
