extends GutTest
## (E8b) Le duel ingagnable dans la cour de l'entrepôt (game.tscn, le vrai Player, le matin) : les
## trois phases dans l'ordre (Willem esquive sans jamais parer, la vision accélérée, l'élan
## retourné), la reprise « Encore une fois ! » (phases 2 et 3, plus vite), la graine fixe ; la
## réussite est impossible et aucun point de vie n'est perdu ; les effets (pâleur, ralenti, écran
## blanc) s'appliquent puis se retirent : le post-traitement revient à l'état d'avant. Le duel est
## avancé à la main (set_physics_process(false)), plus vite que le temps ; un coup du joueur est
## le signal attack_started de son combat (les vrais appuis : test_e8b_in_game.gd).

const GAME_SCENE := preload("res://src/game.tscn")
const SWORD := preload("res://data/attacks/sword_1.tres")
const MAP := &"entrepot"
const DT := 1.0 / 60.0

var _game: Node3D
var _player: Player
var _duel: Duel
var _outcomes: Array[Array] = []
var _phases: Array[StringName] = []
var _beats: Array[int] = []
var _results: Array[Dictionary] = []


func before_all() -> void:
	GameState.reset()
	WorldManager.fade_time = 0.0
	_game = GAME_SCENE.instantiate() as Node3D
	add_child(_game)
	_player = _game.get_node(^"Player") as Player
	LifeDirector.set_slot(&"matin", 0.0)
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
	LifeDirector.set_slot(&"matin", 0.0)
	LifeDirector.attach(WorldManager.current_map_node())
	LifeDirector.build_nav_now()
	_player.set_weapon(PlayerCombat.WEAPON_STICK)
	_player.hold_pose(&"", 0.0)
	_player.set_story_hold(false)
	_player.combat.charge_release()
	_player.velocity = Vector3.ZERO
	_outcomes.clear()
	_phases.clear()
	_beats.clear()
	_results.clear()


func after_each() -> void:
	if is_instance_valid(_duel):
		_duel.stop()
		if is_instance_valid(_duel):
			_duel.free()
	_duel = null
	_player.combat.charge_release()
	_player.set_weapon(PlayerCombat.WEAPON_SENIORIOUS)


func _start(options: Dictionary = {}) -> Duel:
	var merged := options.duplicate(true)
	if not merged.has("seed"):
		merged["seed"] = 8
	if not merged.has("place"):
		merged["place"] = true
	_duel = MiniGames.start_duel(merged)
	assert_not_null(_duel, "le duel démarre")
	_duel.set_physics_process(false)
	_duel.resolved.connect(
		func(kind: StringName, outcome: StringName) -> void: _outcomes.append([kind, outcome])
	)
	_duel.phase_changed.connect(func(next: StringName) -> void: _phases.append(next))
	_duel.heartbeat.connect(func(index: int) -> void: _beats.append(index))
	_duel.finished.connect(func(found: Dictionary) -> void: _results.append(found))
	return _duel


## Avance le duel de seconds s, ou jusqu'à ce que until soit vrai.
func _run(seconds: float, until: Callable = Callable()) -> void:
	for _i: int in roundi(seconds / DT):
		if not is_instance_valid(_duel) or _duel.is_done():
			return
		_duel.advance(DT)
		if until.is_valid() and until.call():
			return


func _willem() -> LifeActor:
	return LifeDirector.actor(&"willem")


func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _post() -> ShaderMaterial:
	return GameVision.post_material(_player)


## Le joueur à distance m au sud de Willem, tourné vers lui.
func _stand_before_willem(distance: float) -> void:
	var at := _willem().position() + Vector3(0.0, 0.0, distance)
	_player.global_position = at + Vector3(0.0, 0.1, 0.0)
	_player.set_aim_direction(Vector3.FORWARD)


## Un coup d'épée : le signal du combat (le vrai appui, test_e8b_in_game.gd).
func _strike() -> void:
	_player.combat.attack_started.emit(SWORD)


## Jusqu'à la phase 1 ; tient la charge jusqu'à la vision.
func _to_vision() -> void:
	_run(3.0, func() -> bool: return _duel.phase == &"dodge" or _duel.phase == &"ready")
	_player.combat.charge_begin()
	assert_eq(_player.combat.current_state(), &"charge", "la charge de Seniorious")
	_run(3.0, func() -> bool: return _duel.phase == &"vision")
	_player.combat.charge_release()


func test_the_duel_starts_with_seniorious_and_willem_holds_percival() -> void:
	_start()
	assert_eq(_player.weapon(), &"seniorious", "Seniorious pendant le duel")
	assert_false(_player.is_story_held(), "le joueur a la main")
	var willem := _willem()
	assert_eq(willem.outfit, &"duel", "Willem et le Carillon Percival")
	assert_eq(willem.npc.visual.skin.id, &"willem_duel")
	assert_eq(willem.npc.get_prompt(), "", "pas d'invite « Parler » pendant le duel")
	assert_eq(InteractSign.kind_of(willem.npc), &"", "pas de signe sur Willem")
	var places := LifeDirector.places()
	assert_lt(_flat_distance(willem.position(), places.center(&"cour_willem")), 0.1)
	assert_lt(_flat_distance(_player.global_position, places.center(&"cour_chtholly")), 0.2)
	assert_true(_duel.arena().has_point(Vector2(willem.position().x, willem.position().z)))
	assert_eq(_duel.phase, &"intro")
	_run(2.0, func() -> bool: return _duel.phase == &"dodge")
	assert_eq(_duel.phase, &"dodge", "phase 1")


func test_willem_steps_aside_from_every_strike_and_never_parries() -> void:
	_start()
	_run(2.0, func() -> bool: return _duel.phase == &"dodge")
	var health := _player.health.current
	for i: int in 4:
		_stand_before_willem(1.6)
		var before := _willem().position()
		_strike()
		_run(0.6)
		assert_eq(_outcomes.back(), [&"strike", &"dodged"], "coup %d : il fait un pas" % i)
		var moved := _willem().position() - before
		assert_almost_eq(Vector2(moved.x, moved.z).length(), 1.2, 0.15, "un pas de 1,2 m")
		assert_lt(absf(moved.z), 0.4, "de côté, pas en arrière")
	assert_eq(_duel.dodges, 4)
	for outcome: Array in _outcomes:
		assert_ne(outcome[1], &"parried", "jamais une parade")
	# Trop loin : le coup fend l'air.
	_stand_before_willem(4.0)
	_strike()
	_run(0.3)
	assert_eq(_outcomes.back(), [&"strike", &"missed"])
	assert_eq(_player.health.current, health, "aucun point de vie perdu")
	assert_eq(_duel.phase, &"dodge", "toujours la phase 1")


func test_willem_beckons_after_eight_seconds_without_an_attack() -> void:
	_start()
	_run(2.0, func() -> bool: return _duel.phase == &"dodge")
	_run(7.5)
	assert_eq(_duel.beckons, 0)
	_run(1.0)
	assert_eq(_duel.beckons, 1, "il lui fait signe d'approcher")
	assert_has(_outcomes, [&"beckon", &"waiting"])
	assert_true(_willem().npc.visual.current_animation() in [&"parle", &"repos"])


func test_the_three_phases_in_order_and_success_is_impossible() -> void:
	var post := _post()
	assert_not_null(post, "le post-traitement de la caméra du joueur")
	post.set_shader_parameter(&"pale_center", Vector2(0.25, 0.75))
	var before := {}
	for key: StringName in GameVision.UNIFORMS:
		before[key] = post.get_shader_parameter(key)
	var health := _player.health.current
	var outfit := _willem().outfit if _willem() != null else &""
	_start()
	_to_vision()
	assert_eq(_duel.phase, &"vision", "phase 2 : la charge tenue 2 s")
	assert_eq(_duel.vision_by, &"charge")
	# La vision accélérée : l'image pâlit de 60 %, le monde à 0,6.
	_run(0.5)
	assert_almost_eq(_duel.charge_time(), 0.0, 0.001, "relâchée")
	assert_almost_eq(float(post.get_shader_parameter(&"pale_amount")), 0.6, 0.01, "pâleur de 60 %")
	assert_gt(float(post.get_shader_parameter(&"pale_radius")), 0.0, "Chtholly reste nette")
	assert_almost_eq(_duel.vision.time_scale, 0.6, 0.001, "le monde ralentit")
	var willem_visual := _willem().npc.visual
	assert_true(_duel.vision.slowed().has(willem_visual), "Willem au ralenti")
	assert_false(willem_visual.is_processing(), "son horloge est menée par la vision")
	var game_before := _duel.game_time()
	var world_before := _duel.world_time()
	_run(1.0)
	assert_almost_eq(
		(_duel.world_time() - world_before) / (_duel.game_time() - game_before), 0.6, 0.01
	)
	# Le premier coup chargé : l'élan, au plus 8 m vers Willem.
	_stand_before_willem(7.0)
	var from := _player.global_position
	_strike()
	assert_eq(_outcomes.back(), [&"dash", &"started"])
	assert_true(_player.is_story_held(), "le duel mène l'élan")
	_run(1.0, func() -> bool: return _duel.phase == &"reversal")
	assert_eq(_duel.phase, &"reversal", "phase 3")
	assert_almost_eq(_duel.dash_distance, 6.1, 0.2, "l'élan jusqu'à Willem")
	assert_lt(_flat_distance(_player.global_position, _willem().position()), 1.2, "au contact")
	assert_gt(_flat_distance(_player.global_position, from), 5.0)
	var contact := _player.global_position
	# L'écran blanc, deux battements, puis plus rien.
	_run(0.3)
	assert_almost_eq(float(Color(post.get_shader_parameter(&"flash_color")).a), 1.0, 0.15)
	_run(0.5)
	assert_eq(_beats, [0, 1], "deux battements de cœur")
	# Projetée à 6 m, sur le dos ; Percival brille.
	_run(0.2, func() -> bool: return _duel.get_node_or_null(^"PercivalGlow") != null)
	assert_not_null(_duel.get_node_or_null(^"PercivalGlow"), "Percival brille")
	_run(3.0, func() -> bool: return _duel.phase == &"ended")
	assert_eq(_duel.phase, &"ended")
	assert_almost_eq(_duel.thrown_distance, 6.0, 0.6, "projetée à 6 m")
	assert_almost_eq(_flat_distance(_player.global_position, contact), _duel.thrown_distance, 0.2)
	assert_eq(_player.visual.current_animation(), &"degats", "sur le dos dans l'herbe")
	_run(3.0)
	assert_eq(_results.size(), 1, "finished, une fois")
	var result := _results[0]
	assert_false(result["success"], "la réussite est impossible")
	assert_eq(result["ended_by"], &"thrown")
	assert_eq(result["phases"], [&"intro", &"dodge", &"vision", &"reversal"], "dans l'ordre")
	assert_eq(_phases.back(), &"ended")
	assert_eq(_player.health.current, health, "aucun point de vie perdu")
	assert_false(_player.health.is_dead())
	# Tout revient : l'image, l'horloge des visuels, l'arme, la main, Willem.
	for key: StringName in GameVision.UNIFORMS:
		assert_eq(post.get_shader_parameter(key), before[key], "post-traitement : %s" % key)
	assert_true(willem_visual.is_processing(), "Willem retrouve son horloge")
	assert_eq(_player.weapon(), &"baton", "l'arme d'avant revient")
	assert_false(_player.is_story_held())
	assert_false(_player.is_posing())
	assert_eq(_willem().outfit, outfit, "sa tenue d'avant")
	assert_ne(_willem().npc.visual.skin.id, &"willem_duel", "Percival rangé")
	assert_ne(_willem().npc.get_prompt(), "", "on peut de nouveau lui parler")


func test_after_thirty_seconds_she_lights_the_venenum_by_herself() -> void:
	_start()
	_run(2.0, func() -> bool: return _duel.phase == &"dodge")
	_run(29.0)
	assert_eq(_duel.phase, &"dodge", "trente secondes au plus")
	_run(1.5)
	assert_eq(_duel.phase, &"vision")
	assert_eq(_duel.vision_by, &"time")
	# Elle n'attend pas : sans coup en 10 s, elle s'élance.
	_run(12.0, func() -> bool: return _duel.phase == &"reversal")
	assert_eq(_duel.phase, &"reversal")
	_run(6.0)
	assert_eq(_results.size(), 1)
	assert_false(_results[0]["success"])


func test_the_reprise_replays_phases_two_and_three_faster() -> void:
	_start({"reprise": true})
	assert_true(_duel.reprise)
	assert_eq(_willem().npc.visual.current_animation(), &"pare", "Willem en garde")
	_to_vision()
	_run(0.2)
	_stand_before_willem(6.0)
	_strike()
	var dash := _duel.current_move()
	assert_almost_eq(float(dash["duration"]), 0.42 / 1.5, 0.01, "l'élan, plus vite")
	_run(6.0)
	assert_eq(_results.size(), 1)
	var result := _results[0]
	assert_true(result["reprise"])
	assert_false(result["success"], "même fin")
	assert_eq(result["ended_by"], &"thrown")
	assert_eq(result["phases"], [&"intro", &"ready", &"vision", &"reversal"], "sans la phase 1")
	assert_lt(float(result["duration"]), 6.0)


func test_a_fixed_seed_replays_the_same_duel() -> void:
	var runs: Array = []
	for _attempt: int in 2:
		_start({"seed": 1234})
		_run(2.0, func() -> bool: return _duel.phase == &"dodge")
		var steps: Array[Vector3] = []
		for _i: int in 5:
			_stand_before_willem(1.6)
			var before := _willem().position()
			_strike()
			_run(0.5)
			steps.append((_willem().position() - before).snappedf(0.01))
		runs.append(steps)
		_duel.stop()
		_willem().set_position(LifeDirector.places().center(&"cour_willem"))
	assert_eq(runs[0], runs[1], "la même graine : les mêmes pas de côté")


func test_stopping_mid_vision_gives_everything_back() -> void:
	var post := _post()
	var before := {}
	for key: StringName in GameVision.UNIFORMS:
		before[key] = post.get_shader_parameter(key)
	_start()
	_to_vision()
	_run(0.6)
	assert_gt(float(post.get_shader_parameter(&"pale_amount")), 0.3)
	_duel.stop()
	assert_eq(_results.size(), 1)
	assert_eq(_results[0]["ended_by"], &"stopped")
	for key: StringName in GameVision.UNIFORMS:
		assert_eq(post.get_shader_parameter(key), before[key], "post-traitement : %s" % key)
	assert_true(_willem().npc.visual.is_processing())
	assert_eq(_player.weapon(), &"baton")
	assert_null(MiniGames.duel(), "plus de duel en cours")
