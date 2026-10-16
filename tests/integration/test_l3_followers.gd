extends "res://tests/stubs/e6_story_test.gd"
## (L3) Les suiveurs au pas du joueur, dans la vraie partie : la scène j3_2_chemin (Ithea et Nephren
## suivent Chtholly sur le sentier), le joueur court 25 m, puis s'arrête.
## - Pendant la course, un suiveur à plus de garde + 0,8 m ne joue jamais « repos » plus de 0,1 s
##   (avant : un arrêt tous les 1,2 m, le chemin remis à zéro).
## - 1,5 s après l'arrêt du joueur, ils sont à moins de 4 m.
## Les mesures sont écrites au journal (« [l3] ») ; l'horloge est celle des images physiques.

const DAYS_1_2 := [
	"j1_1_port",
	"j1_2_lumiere",
	"j1_2_embuscade",
	"j1_3_intrus",
	"j1_4_chemin",
	"j1_5_premiers_pas",
	"j1_6_diner",
	"j1_7_chambre",
	"j2_1_matin",
	"j2_2_fuite",
	"j2_3_fenetre",
	"j3_1_information",
]
## Garde d'Ithea et de Nephren dans la scène (distance du pas « follow »).
const KEEP := {&"ithea": 1.6, &"nephren": 2.6}
const RUN_METERS := 25.0
const IDLE_LIMIT := 0.1
const CATCH_UP_LIMIT := 4.0
const CATCH_UP_TIME := 1.5


## La scène j3_2_chemin est laissée en cours : on la coupe et on rend Ithea et Nephren à la vie,
## sinon leur réservation survit au test (test_life compte les PNJ de la carte).
func after_each() -> void:
	StoryDirector.stage().repose_lost = false
	StoryDirector.runner().stop()
	StoryDirector.stage().clear()
	for npc_id: StringName in LifeDirector.reserved():
		LifeDirector.release(npc_id, false)
	await frames(3)
	super()


func _resume_at(day: int, slot: StringName, map_id: StringName, at: Vector3, done: Array) -> bool:
	GameState.reset()
	var state := GameState.to_dict()
	state["skin"] = "chtholly"
	state["day"] = day
	state["slot"] = String(slot)
	state["moment"] = String(LifeSlots.moment_of(slot))
	state["map"] = String(map_id)
	state["island"] = "ile_68"
	state["position"] = [at.x, at.y, at.z]
	state["scenes_done"] = done
	var calendar := {}
	for past: int in range(1, day):
		calendar[str(past)] = ""
	state["calendar"] = calendar
	GameState.from_dict(state)
	SaveManager.save()
	await open_main()
	await click_center()
	await click(menu_button("ContinueButton"))
	return await wait_for_game()


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _anim_of(npc_id: StringName) -> StringName:
	var actor := LifeDirector.actor(npc_id)
	if actor == null or not is_instance_valid(actor.npc):
		return &""
	return actor.npc.visual.current_animation()


func test_followers_keep_up_with_a_running_player() -> void:
	await _chase(true)


func test_followers_keep_up_with_a_walking_player() -> void:
	await _chase(false)


## Le joueur (run : il court, sinon il marche) fait RUN_METERS m sur le sentier, suivi d'Ithea et
## de Nephren ; mesures au journal, puis les deux attentes de l'en-tête.
func test_a_lost_follower_is_set_down_behind_the_player_out_of_view() -> void:
	# (AN) La poursuite (6,6 m/s) va plus vite que la course du joueur (5,8) : les suiveuses,
	# ralenties de moitié le temps de la course, se perdent comme un PNJ gêné en chemin.
	var jumps := await _chase(true, 8.0, 50.0, 0.5)
	assert_gt(jumps, 0, "un suiveur perdu est reposé derrière le joueur")


## Renvoie le nombre de repositions (follower_reposed). stop_beyond > 0 :
## les deux suiveuses sont reprises avec cette distance d'arrêt ; slow : leur facteur de vitesse
## pendant la course (rendu à 1 à l'arrêt).
func _chase(
	run: bool, stop_beyond: float = 0.0, meters: float = RUN_METERS, slow: float = 1.0
) -> int:
	var label := "course" if run else "marche"
	if stop_beyond > 0.0:
		label += " (stop_beyond %.0f)" % stop_beyond
	assert_true(
		await _resume_at(3, &"matin", &"sentier", Vector3(2.5, 0.2, 24.0), DAYS_1_2.duplicate())
	)
	assert_true(
		await until(func() -> bool: return StoryDirector.current_scene() == &"j3_2_chemin", 10.0)
	)
	assert_true(await until(func() -> bool: return dialogue_box.is_open(), 20.0), "le bavardage")
	assert_true(await wait_control(), "la main est rendue")
	for npc_id: StringName in KEEP:
		assert_has(StoryDirector.stage().followers(), npc_id)
	StoryDirector.stage().repose_lost = stop_beyond > 0.0
	if stop_beyond > 0.0:
		for npc_id: StringName in KEEP:
			StoryDirector.stage().add_follower(npc_id, KEEP[npc_id], stop_beyond, &"course")
	# Un temps pour qu'elles prennent leur garde.
	await frames(90)
	# La course : par le chemin de la navigation, vers la sortie de la ville, sur 25 m.
	var nav: LifeNav = StoryDirector.stage().ensure_nav()
	var exit_point := Vector3.ZERO
	for candidate: MapExit in WorldManager.current_map_node().exits():
		if candidate.target_map == &"ville_haute":
			exit_point = candidate.global_position
	assert_ne(exit_point, Vector3.ZERO, "la sortie vers la ville")
	var route := StoryDirector.stage().route(
		player.global_position, nav.find_path(player.global_position, exit_point)
	)
	route.append(exit_point)
	var walked := 0.0
	var last := player.global_position
	var index := 0
	var idle_frames := {}
	var worst_idle := {}
	var still_frames := {}
	var worst_still := {}
	var worst_distance := {}
	var gaits := {}
	for npc_id: StringName in KEEP:
		idle_frames[npc_id] = 0
		worst_idle[npc_id] = 0
		still_frames[npc_id] = 0
		worst_still[npc_id] = 0
		worst_distance[npc_id] = 0.0
		gaits[npc_id] = {}
	var tick := 1.0 / float(Engine.physics_ticks_per_second)
	var frame_count := 0
	var jumps := []
	var on_reposed := func(npc_id: StringName) -> void: jumps.append(npc_id)
	StoryDirector.stage().follower_reposed.connect(on_reposed)
	var previous := {}
	for npc_id: StringName in KEEP:
		previous[npc_id] = LifeDirector.actor(npc_id).position()
	await frames(1)
	for npc_id: StringName in KEEP:
		LifeDirector.actor(npc_id).speed_factor = slow
	if run:
		Input.action_press(&"run")
	while walked < meters and index < route.size() and frame_count < 60 * 40:
		var here := player.global_position
		if _flat(here, route[index]) < 0.7:
			index += 1
			continue
		var toward := route[index] - here
		hold_toward(toward)
		await frames(1)
		frame_count += 1
		walked += _flat(player.global_position, last)
		last = player.global_position
		for npc_id: StringName in KEEP:
			var actor := LifeDirector.actor(npc_id)
			var away := _flat(actor.position(), player.global_position)
			if _flat(actor.position(), previous[npc_id]) > 0.9:
				print(
					(
						"[l3] %s reposée : de %.1f m à %.1f m du joueur"
						% [npc_id, _flat(previous[npc_id], player.global_position), away]
					)
				)
			# Immobile (moins de 2 mm par image) alors qu'il devrait rejoindre le joueur.
			var moved := _flat(actor.position(), previous[npc_id])
			if away > float(KEEP[npc_id]) + 0.8 and moved < 0.002:
				still_frames[npc_id] += 1
				worst_still[npc_id] = maxi(worst_still[npc_id], still_frames[npc_id])
			else:
				still_frames[npc_id] = 0
			previous[npc_id] = actor.position()
			worst_distance[npc_id] = maxf(worst_distance[npc_id], away)
			var anim := _anim_of(npc_id)
			var gait := actor.current_gait() if actor.is_moving() else &"-"
			gaits[npc_id][gait] = int(gaits[npc_id].get(gait, 0)) + 1
			if away > float(KEEP[npc_id]) + 0.8 and anim == &"repos":
				idle_frames[npc_id] += 1
				worst_idle[npc_id] = maxi(worst_idle[npc_id], idle_frames[npc_id])
			else:
				idle_frames[npc_id] = 0
	release_move()
	Input.action_release(&"run")
	for npc_id: StringName in KEEP:
		LifeDirector.actor(npc_id).speed_factor = 1.0
	print("[l3] %s : %.1f m en %.1f s" % [label, walked, frame_count * tick])
	assert_gt(walked, RUN_METERS - 2.0, "le joueur a couru ses 25 m")
	for npc_id: StringName in KEEP:
		print(
			(
				"[l3] %s, %s : écart max %.1f m, repos continu max %.2f s, immobile max %.2f s, allures %s"
				% [
					label,
					npc_id,
					worst_distance[npc_id],
					worst_idle[npc_id] * tick,
					worst_still[npc_id] * tick,
					gaits[npc_id]
				]
			)
		)
		assert_lte(worst_idle[npc_id] * tick, IDLE_LIMIT, "%s ne s'arrête pas en route" % npc_id)
		assert_lte(worst_still[npc_id] * tick, IDLE_LIMIT, "%s ne reste pas sur place" % npc_id)
	# L'arrêt : 1,5 s plus tard, elles sont tout près.
	await frames(int(CATCH_UP_TIME / tick))
	for npc_id: StringName in KEEP:
		var away := _flat(LifeDirector.actor(npc_id).position(), player.global_position)
		print("[l3] %s, %s à %.1f m, %.1f s après l'arrêt" % [label, npc_id, away, CATCH_UP_TIME])
		assert_lt(away, CATCH_UP_LIMIT, "%s a rattrapé le joueur" % npc_id)
	StoryDirector.stage().follower_reposed.disconnect(on_reposed)
	StoryDirector.stage().repose_lost = false
	return jumps.size()
