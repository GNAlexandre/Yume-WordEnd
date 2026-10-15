extends "res://tests/stubs/e5_fauna_test.gd"
## (E5) Comportements de la faune : le paisible lève la tête puis fuit (au bruit du joueur qui
## court, à celui d'un combat proche), le fuyard et l'oiseau fuient, le vaincu s'enfuit au lieu
## de mourir, la meute encercle et attaque un par un, le sanglier gratte puis charge en ligne
## droite et reste étourdi contre un obstacle, l'ours lent frappe fort et ne quitte pas sa
## tanière, la navigation suit le sol (eau, falaise).

const FOREST := &"foret_essai"
const BOAR_CHARGE := &"boar_charge"
const ATTACKING: Array[StringName] = [&"attack", &"windup", &"rush"]

# --- Paisibles et fuyards -----------------------------------------------------------------------


func test_the_deer_raises_its_head_then_flees() -> void:
	make_player(Vector3.ZERO, WALK)
	var deer := make_animal(&"deer", Vector3(7.0, 0.0, 0.0))
	await wait_physics_frames(3)
	assert_eq(deer.mode_name(), &"alert", "à 7 m (8 m d'alerte) : il lève la tête")
	assert_eq(deer.visual.current_animation(), &"repos")
	var before := deer.global_position
	await wait_physics_frames(20)
	assert_lt(deer.global_position.distance_to(before), 0.3, "il reste sur place en regardant")
	player.global_position = Vector3(2.0, 0.0, 0.0)
	var fled: bool = await wait_until(func() -> bool: return deer.mode_name() == &"flee", 1.0)
	assert_true(fled, "à 5 m (6 m de fuite) : il fuit")
	var start := flat_distance(deer, player)
	await wait_physics_frames(60)
	assert_gt(flat_distance(deer, player), start + 4.0, "au galop, loin du joueur")
	assert_eq(deer.visual.current_animation(), &"course")


func test_a_far_deer_grazes_and_wanders_near_its_spot() -> void:
	make_player(Vector3.ZERO, WALK)
	var deer := make_animal(&"deer", Vector3(25.0, 0.0, 0.0))
	var seen: Array[StringName] = []
	for _i in 600:
		await wait_physics_frames(1)
		var anim := deer.visual.current_animation()
		if not anim in seen:
			seen.append(anim)
		assert_eq(deer.mode_name(), &"graze", "loin du joueur : il broute")
		assert_lt(
			flat_distance(deer, deer) + deer.global_position.distance_to(Vector3(25.0, 0.0, 0.0)),
			8.0
		)
	assert_true(&"broute" in seen or &"repos" in seen, "il broute ou se repose : %s" % [seen])
	assert_true(&"marche" in seen, "il marche aussi : %s" % [seen])


func test_the_noise_of_the_player_changes_the_distance(
	case: Array = use_parameters(
		[[WALK, 5.0, true], [0.0, 5.0, false], [RUN, 8.5, true], [WALK, 8.5, false]]
	)
) -> void:
	# Cerf : 8 m d'alerte et 6 m de fuite, × 1,5 si le joueur court, × 0,6 s'il reste immobile.
	make_player(Vector3.ZERO, case[0])
	var deer := make_animal(&"deer", Vector3(case[1], 0.0, 0.0))
	await wait_physics_frames(4)
	assert_eq(
		deer.mode_name() == &"flee",
		case[2],
		"vitesse %s, à %s m : %s" % [case[0], case[1], deer.mode_name()]
	)


func test_a_fox_flees_at_six_meters_and_calms_down_far_away() -> void:
	make_player(Vector3.ZERO, WALK)
	var fox := make_animal(&"fox", Vector3(7.0, 0.0, 0.0))
	await wait_physics_frames(5)
	assert_eq(fox.mode_name(), &"graze", "à 7 m : il ne fuit pas encore")
	player.global_position = Vector3(2.0, 0.0, 0.0)
	var fled: bool = await wait_until(func() -> bool: return fox.mode_name() == &"flee", 1.0)
	assert_true(fled, "à 5 m : il fuit")
	var calmed: bool = await wait_until(func() -> bool: return fox.mode_name() == &"graze", 8.0)
	assert_true(calmed, "loin (%s m) : il se calme" % fox.species().calm_distance())
	assert_gt(flat_distance(fox, player), 10.0)


func test_a_bird_takes_off_and_leaves() -> void:
	make_player(Vector3.ZERO, WALK)
	var bird := make_animal(&"blackbird", Vector3(2.5, 0.0, 0.0))
	var flying: bool = await wait_until(func() -> bool: return bird.is_flying(), 1.0)
	assert_true(flying, "à 2,5 m (3 m de fuite) : il s'envole")
	await wait_physics_frames(40)
	assert_gt(bird.visual.position.y, 0.8, "il monte")
	assert_eq(bird.visual.current_animation(), &"fuite", "battements d'ailes")
	var delay := bird.species().vanish_s
	var gone: bool = await wait_gone(bird, 4.0)
	assert_true(gone, "il quitte la scène après %s s" % delay)


func test_a_frog_dives_at_two_meters() -> void:
	make_player(Vector3.ZERO, WALK)
	var frog := make_animal(&"frog", Vector3(3.0, 0.0, 0.0))
	await wait_physics_frames(5)
	assert_eq(frog.mode_name(), &"graze", "à 3 m : elle reste là")
	player.global_position = Vector3(1.2, 0.0, 0.0)
	var dived: bool = await wait_until(func() -> bool: return frog.mode_name() == &"flee", 1.0)
	assert_true(dived, "à moins de 2 m : plongeon")
	assert_eq(frog.visual.current_animation(), &"fuite")
	var gone: bool = await wait_gone(frog, 2.0)
	assert_true(gone, "elle disparaît sous l'eau")


func test_a_fight_nearby_alarms_peaceful_animals() -> void:
	make_player(Vector3(40.0, 0.0, 40.0), 0.0)
	var near := make_animal(&"deer", Vector3(0.0, 0.0, 0.0))
	var far := make_animal(&"deer", Vector3(0.0, 0.0, 30.0))
	var brawler := Node3D.new()
	world.add_child(brawler)
	brawler.position = Vector3(8.0, 0.0, 0.0)
	await wait_physics_frames(2)
	EventBus.enemy_damaged.emit(brawler, 1)
	await wait_physics_frames(2)
	assert_eq(near.mode_name(), &"flee", "un combat à 8 m (14 m d'oreille) l'alarme")
	assert_eq(far.mode_name(), &"graze", "à 30 m, il n'entend rien")
	assert_lt(near.global_position.x, 0.0, "loin du combat")


func test_a_dangerous_animal_does_not_run_from_a_fight() -> void:
	make_player(Vector3(40.0, 0.0, 40.0), 0.0)
	var boar := make_animal(&"boar", Vector3.ZERO)
	var brawler := Node3D.new()
	world.add_child(brawler)
	brawler.position = Vector3(3.0, 0.0, 0.0)
	EventBus.enemy_damaged.emit(brawler, 1)
	await wait_physics_frames(3)
	assert_eq(boar.mode_name(), &"graze")


# --- Vaincu, il s'enfuit -------------------------------------------------------------------------


func test_a_defeated_wolf_flees_instead_of_dying() -> void:
	make_player(Vector3.ZERO, WALK)
	var wolf := make_animal(&"wolf", Vector3(4.0, 0.0, 0.0))
	await wait_physics_frames(2)
	watch_signals(EventBus)
	watch_signals(wolf)
	for _i in wolf.data.max_hp:
		assert_true(strike(wolf, player.global_position))
	assert_true(wolf.is_leaving(), "trois coups : il s'enfuit")
	assert_signal_emitted(wolf, "fled")
	assert_signal_emitted(wolf, "defeated")
	assert_signal_not_emitted(EventBus, "enemy_killed", "il n'est pas tué")
	assert_ne(wolf.state(), &"dead", "jamais d'état « mort »")
	assert_false(wolf.is_in_group(&"enemies"), "plus verrouillable")
	assert_false(wolf.is_in_group(&"fauna"))
	var start := flat_distance(wolf, player)
	await wait_physics_frames(30)
	assert_gt(flat_distance(wolf, player), start + 1.5, "il court, loin de celui qui l'a frappé")
	assert_ne(wolf.visual.current_animation(), &"mort", "ni couché, ni sang")
	var gone: bool = await wait_gone(wolf, 6.0)
	assert_true(gone, "puis il disparaît")


func test_a_blow_makes_a_peaceful_animal_run() -> void:
	make_player(Vector3.ZERO, WALK)
	var squirrel := make_animal(&"squirrel", Vector3(1.0, 0.0, 0.0))
	watch_signals(EventBus)
	assert_true(strike(squirrel, player.global_position))
	assert_true(squirrel.is_leaving(), "un coup de bâton : il file (c'était son seul point de vie)")
	assert_signal_not_emitted(EventBus, "enemy_killed")
	var gone: bool = await wait_gone(squirrel, 6.0)
	assert_true(gone)


func test_a_wolf_needs_three_hits_a_boar_four_and_a_bear_ten() -> void:
	make_player(Vector3(60.0, 0.0, 60.0), 0.0)
	for id: StringName in [&"wolf", &"boar", &"bear"]:
		var animal := make_animal(id, Vector3.ZERO)
		var hits := 0
		while not animal.is_leaving() and hits < 20:
			assert_true(strike(animal, Vector3(-1.0, 0.0, 0.0)))
			hits += 1
		assert_eq(
			hits, animal.data.max_hp, "%s : %d coups avant de fuir" % [id, animal.data.max_hp]
		)
		animal.queue_free()
		await wait_physics_frames(1)


# --- La meute ------------------------------------------------------------------------------------


func _pack(count: int, center: Vector3) -> Array[Animal]:
	var pack := AnimalPack.new()
	var wolves: Array[Animal] = []
	for i in count:
		var angle := TAU * i / count
		var wolf := make_animal(&"wolf", center + Vector3(cos(angle), 0.0, sin(angle)) * 1.2)
		pack.add(wolf)
		wolves.append(wolf)
	return wolves


func _max_gap_degrees(animals: Array[Animal], center: Vector3) -> float:
	var angles: Array[float] = []
	for animal: Animal in animals:
		var offset := animal.global_position - center
		angles.append(atan2(offset.z, offset.x))
	angles.sort()
	var worst := TAU - (angles[-1] - angles[0])
	for i in range(1, angles.size()):
		worst = maxf(worst, angles[i] - angles[i - 1])
	return rad_to_deg(worst)


func test_the_pack_surrounds_the_player_and_attacks_one_at_a_time() -> void:
	make_player(Vector3.ZERO, WALK)
	var wolves := _pack(3, Vector3(0.0, 0.0, -8.5))
	var worst := 0
	var attack_frames := 0
	var seen_ring := false
	for _i in 420:
		await wait_physics_frames(1)
		var attacking := 0
		for wolf: Animal in wolves:
			if wolf.state() in ATTACKING:
				attacking += 1
		worst = maxi(worst, attacking)
		attack_frames += attacking
		if _i == 300:
			seen_ring = _max_gap_degrees(wolves, player.global_position) < 200.0
	assert_lte(worst, 1, "une seule bête attaque à la fois")
	assert_gt(attack_frames, 20, "et la meute attaque bel et bien")
	assert_true(seen_ring, "la meute encercle : aucun côté du joueur n'est libre")
	for wolf: Animal in wolves:
		assert_lt(flat_distance(wolf, player), 7.0, "toutes ont rejoint le joueur")


func test_the_whole_pack_hunts_when_one_wolf_spots_the_player() -> void:
	make_player(Vector3.ZERO, WALK)
	var wolves := _pack(3, Vector3(0.0, 0.0, -9.0))
	wolves[0].global_position = Vector3(0.0, 0.0, -6.0)
	wolves[1].global_position = Vector3(3.0, 0.0, -15.0)
	wolves[2].global_position = Vector3(-3.0, 0.0, -16.0)
	await wait_physics_frames(30)
	for wolf: Animal in wolves:
		assert_ne(
			wolf.state(),
			&"idle",
			"alertée, toute la meute chasse (à %s m)" % flat_distance(wolf, player)
		)


func test_a_lone_wolf_far_away_stays_calm() -> void:
	make_player(Vector3.ZERO, WALK)
	var wolf := make_animal(&"wolf", Vector3(0.0, 0.0, -16.0))
	await wait_physics_frames(60)
	assert_eq(wolf.state(), &"idle", "au-delà de 10 m, sans meute : il ne chasse pas")


func test_half_the_pack_fleeing_routs_the_rest() -> void:
	make_player(Vector3(0.0, 0.0, 30.0), 0.0)
	var wolves := _pack(4, Vector3.ZERO)
	for wolf: Animal in [wolves[0], wolves[1]]:
		for _i in 3:
			strike(wolf, Vector3(0.0, 0.0, 30.0))
	assert_true(wolves[0].is_leaving() and wolves[1].is_leaving())
	for wolf: Animal in [wolves[2], wolves[3]]:
		assert_true(wolf.is_leaving(), "la moitié a fui : le reste suit")
	assert_true(wolves[0].pack.routed)


func test_less_than_half_gone_does_not_rout_the_pack() -> void:
	make_player(Vector3(0.0, 0.0, 30.0), 0.0)
	var wolves := _pack(4, Vector3.ZERO)
	for _i in 3:
		strike(wolves[0], Vector3(0.0, 0.0, 30.0))
	assert_true(wolves[0].is_leaving())
	for wolf: Animal in [wolves[1], wolves[2], wolves[3]]:
		assert_false(wolf.is_leaving(), "un seul sur quatre a fui")


# --- Le sanglier ---------------------------------------------------------------------------------


func test_the_boar_scratches_the_ground_then_charges_in_a_straight_line() -> void:
	make_player(Vector3.ZERO, WALK)
	var boar := make_animal(&"boar", Vector3(5.5, 0.0, 0.0))
	var winding: bool = await wait_until(func() -> bool: return boar.state() == &"windup", 3.0)
	assert_true(winding, "il se prépare")
	assert_eq(boar.prepared_attack().id, BOAR_CHARGE, "la charge, pas le coup de boutoir")
	assert_almost_eq(boar.windup_duration(boar.prepared_attack()), 1.0, 0.01, "il gratte 1 s")
	assert_eq(boar.visual.current_animation(), &"broute", "il fouille le sol du groin")
	var line_start := boar.global_position
	var rushing: bool = await wait_until(func() -> bool: return boar.state() == &"rush", 3.0)
	assert_true(rushing, "puis il charge")
	player.global_position = Vector3(0.0, 0.0, -6.0)
	var points: Array[Vector3] = []
	while boar.state() == &"rush" and points.size() < 200:
		points.append(boar.global_position)
		await wait_physics_frames(1)
	assert_gt(points.size(), 8, "la charge dure")
	var direction := (points[-1] - points[0]).normalized()
	for point: Vector3 in points:
		var off_line := (point - points[0]) - direction * (point - points[0]).dot(direction)
		off_line.y = 0.0
		assert_lt(
			off_line.length(), 0.2, "ligne droite : il ne vire pas vers le joueur qui s'écarte"
		)
	assert_lt(direction.x, -0.9, "vers où se tenait le joueur : l'ouest")
	assert_lt(line_start.distance_to(points[0]), 1.0)


func test_the_boar_stuns_itself_against_an_obstacle() -> void:
	make_player(Vector3.ZERO, WALK)
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.5, 3.0, 8.0)
	shape.shape = box
	wall.add_child(shape)
	wall.position = Vector3(-1.5, 1.5, 0.0)
	world.add_child(wall)
	var boar := make_animal(&"boar", Vector3(5.5, 0.0, 0.0))
	await wait_until(func() -> bool: return boar.state() == &"windup", 3.0)
	player.global_position = Vector3(0.0, 0.0, -9.0)
	var stunned: bool = await wait_until(func() -> bool: return boar.is_stunned(), 5.0)
	assert_true(stunned, "contre le mur, il reste étourdi")
	var rest := boar.global_position
	await wait_physics_frames(60)
	assert_lt(boar.global_position.distance_to(rest), 0.2, "immobile pendant l'étourdissement")
	assert_eq(boar.visual.current_animation(), &"degats")
	var recovered: bool = await wait_until(func() -> bool: return not boar.is_stunned(), 3.0)
	assert_true(recovered, "il se remet au bout de %s s" % boar.species().stun_s)


# --- L'ours --------------------------------------------------------------------------------------


func test_the_bear_is_slow_announces_its_blow_and_does_not_recoil() -> void:
	make_player(Vector3(6.0, 0.0, 0.0), WALK)
	var bear := make_animal(&"bear", Vector3.ZERO)
	var chasing: bool = await wait_until(func() -> bool: return bear.state() == &"chase", 3.0)
	assert_true(chasing, "il charge qui entre dans ses 15 m")
	await wait_physics_frames(30)
	var speed := Vector2(bear.velocity.x, bear.velocity.z).length()
	assert_lt(speed, 1.6, "il avance lentement (%s m/s)" % speed)
	var winding: bool = await wait_until(func() -> bool: return bear.state() == &"windup", 8.0)
	assert_true(winding, "il se dresse avant de frapper")
	assert_almost_eq(bear.windup_duration(bear.prepared_attack()), 0.8, 0.01, "annonce de 0,8 s")
	assert_eq(bear.prepared_attack().damage, 2, "dégâts 2")
	assert_true(strike(bear, player.global_position))
	assert_eq(bear.knockback(), Vector3.ZERO, "l'épée ne le fait pas reculer")


func test_the_bear_never_follows_beyond_its_den() -> void:
	make_player(Vector3(12.0, 0.0, 0.0), WALK)
	var bear := make_animal(&"bear", Vector3.ZERO)
	var chasing: bool = await wait_until(func() -> bool: return bear.state() != &"idle", 3.0)
	assert_true(chasing, "à 12 m de sa tanière, il vient")
	player.global_position = Vector3(20.0, 0.0, 0.0)
	var home: bool = await wait_until(func() -> bool: return bear.state() == &"idle", 3.0)
	assert_true(home, "le joueur à 20 m de la tanière : il ne poursuit pas au-delà de 15 m")
	await wait_physics_frames(120)
	assert_lt(bear.global_position.length(), 7.5, "il reste près de sa tanière")


# --- La navigation suit le sol -------------------------------------------------------------------


func _forest() -> Map:
	var map := (load(Map.scene_path(FOREST)) as PackedScene).instantiate() as Map
	map.get_node(^"Life/Fauna").free()
	world.add_child(map)
	return map


func test_a_fleeing_animal_never_steps_into_the_water() -> void:
	var map := _forest()
	await wait_physics_frames(3)
	var ground := map.get_node(^"Ground") as MapGround
	assert_false(ground.is_walkable(47.0, 34.0), "la mare est de l'eau dormante")
	make_player(Vector3(39.0, 0.0, 34.0), WALK)
	var squirrel := make_animal(&"squirrel", Vector3(42.5, 0.05, 34.0), map)
	await wait_physics_frames(3)
	assert_eq(squirrel.mode_name(), &"flee", "il fuit vers la mare")
	for _i in 240:
		await wait_physics_frames(1)
		if not is_around(squirrel):
			break
		var at := squirrel.global_position
		assert_true(ground.is_walkable(at.x, at.z), "pas dans l'eau, en %s" % at)


func test_a_fleeing_animal_does_not_climb_a_cliff() -> void:
	var map := _forest()
	await wait_physics_frames(3)
	var ground := map.get_node(^"Ground") as MapGround
	assert_gt(
		ground.level_at(20.0, 9.0) - ground.level_at(20.0, 13.0),
		1,
		"la terrasse domine de plus d'un cran"
	)
	make_player(Vector3(20.0, 0.0, 16.5), WALK)
	var fox := make_animal(&"fox", Vector3(20.0, 0.05, 13.5), map)
	for _i in 180:
		await wait_physics_frames(1)
		if not is_around(fox):
			break
		var at := fox.global_position
		assert_lt(at.y, 0.6, "il contourne la falaise au lieu de la grimper, en %s" % at)
