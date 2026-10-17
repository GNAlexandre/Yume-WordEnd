extends "res://tests/stubs/s2_story_test.gd"
## (X-L0) Le mode libre dans la vraie partie (main.tscn, vrais appuis) : une nouvelle partie sans
## écran noir, la main au joueur à Spawn tout de suite ; aucune scène ne part seule (ni en
## attendant, ni en marchant sur les anciens pièges du passage) ; les portes fermées jusqu'à un
## jour sont ouvertes en libre et fermées en scénarisé ; le mode survit à une sauvegarde suivie
## d'une reprise, une scène interrompue n'est pas rejouée en libre ; une ancienne partie sans
## drapeau de mode est scénarisée si elle a des scènes faites, libre sinon.

## Les anciens pièges du passage : jour, créneau, carte, départ, place, scène qu'elle lançait.
const TRAPS: Array[Array] = [
	[5, &"midi", &"entrepot", Vector3(61.0, 0.0, 18.0), &"champ_centre", &"j5_1_jeu_willem"],
	[7, &"aube", &"entrepot", Vector3(61.0, 0.0, 18.0), &"porte_seuil", &"j7_1_depart"],
	[
		6,
		&"matin",
		&"entrepot_rdc",
		Vector3(17.5, 0.0, 6.8),
		&"couloir_centre",
		&"j6_1_soif_de_sang"
	],
]


## Ces tests jouent le mode libre (la base M1 prend le mode scénarisé).
func mode_for_test() -> StringName:
	return StoryPacing.FREE


func _overlay() -> Control:
	return StoryDirector.stage().overlay()


func _fade() -> float:
	var overlay := _overlay()
	return float(overlay.call(&"fade_alpha")) if overlay != null else 0.0


func _no_scene() -> bool:
	return StoryDirector.current_scene().is_empty() and not StoryDirector.is_playing()


func _door(map_path: NodePath) -> Node:
	return current_map().get_node_or_null(map_path)


## Une partie d'avant les modes (aucun drapeau de mode) écrite au jour donné, puis « Continuer ».
func _resume_old(
	day: int, slot: StringName, scenes: Array[StringName], map: StringName, at: Vector3
) -> bool:
	SaveManager.new_game(&"chtholly")
	var state := GameState.to_dict()
	var flags: Dictionary = state["flags"]
	flags.erase(String(StoryPacing.FLAG))
	flags.erase(String(StoryPacing.FREE_FLAG))
	state["day"] = day
	state["slot"] = String(slot)
	state["moment"] = String(LifeSlots.moment_of(slot))
	var done: Array[String] = []
	for scene_id: StringName in scenes:
		done.append(String(scene_id))
	state["scenes_done"] = done
	state["map"] = String(map)
	state["position"] = [at.x, at.y, at.z]
	GameState.from_dict(state)
	SaveManager.save()
	await continue_game()
	return GameState.day == day and WorldManager.current_map() == map


func _go(map_id: StringName, marker: StringName) -> bool:
	await WorldManager.go_to(map_id, marker)
	return await until(
		func() -> bool:
			return WorldManager.current_map() == map_id and not WorldManager.is_transitioning(),
		10.0
	)


func test_a_new_free_game_gives_the_hand_at_spawn_at_once() -> void:
	assert_true(await new_game_from_menu(), "partie lancée depuis le menu")
	var since := Time.get_ticks_msec()
	var spawn := current_map().marker(&"Spawn")
	var in_hand := func() -> bool:
		return (
			WorldManager.current_map() == &"entrepot"
			and not WorldManager.is_transitioning()
			and not player.is_story_held()
			and _fade() == 0.0
			and flat_distance(player.global_position, spawn.global_position) < 1.0
		)
	assert_true(await until(in_hand, 2.0), "la main au joueur à Spawn, sans voile")
	assert_lt(Time.get_ticks_msec() - since, 2000, "en moins de 2 s")
	assert_eq(StoryDirector.mode(), StoryPacing.FREE, "mode libre par défaut")
	assert_true(GameState.has_flag(StoryPacing.FREE_FLAG), "écrit dans la partie")
	assert_false(GameState.has_flag(StoryPacing.FLAG))
	assert_eq(GameState.day, 1, "jour 1")
	assert_eq(LifeSlots.current(), &"soir", "le soir du jour 1 (act.json, free.start_slot)")
	assert_eq(str(_overlay().call(&"card_text")), "Jour 1", "le carton du jour")
	assert_eq(StoryDirector.mode_name(StoryPacing.FREE), "Mode libre")
	assert_eq(StoryDirector.mode_name(StoryPacing.SCENARIO), "Mode scénarisé")
	# De vrais appuis : elle marche.
	var start := player.global_position
	await hold_key(KEY_S, 0.6)
	var moved := flat_distance(player.global_position, start)
	if moved < 0.5:
		await hold_key(KEY_W, 0.6)
		moved = maxf(moved, flat_distance(player.global_position, start))
	assert_gt(moved, 0.5, "elle marche aux touches")
	assert_true(_no_scene(), "aucune scène")


func test_no_scene_plays_by_itself_for_fifteen_seconds() -> void:
	assert_true(await new_game_from_menu(), "partie lancée depuis le menu")
	var started := await until(func() -> bool: return not _no_scene() or _fade() > 0.0, 15.0)
	assert_false(started, "ni scène ni voile pendant 15 s")
	assert_eq(GameState.scenes_done(), [] as Array[StringName], "aucune scène jouée")
	assert_false(player.is_story_held(), "toujours la main")


func test_walking_on_the_old_traps_starts_nothing() -> void:
	for trap: Array in TRAPS:
		var day: int = trap[0]
		var scene_id: StringName = trap[5]
		var flags: Array[StringName] = [StoryPacing.FREE_FLAG]
		assert_true(
			await begin_day(day, flags, [], trap[1], trap[2], trap[3]),
			"partie libre reprise au jour %d" % day
		)
		assert_eq(StoryDirector.mode(), StoryPacing.FREE, "jour %d : libre" % day)
		assert_true(await walk_to_point(trap[4], 1.5, 60.0), "jusqu'à %s" % trap[4])
		var fired := await until(func() -> bool: return not _no_scene(), 2.0)
		assert_false(fired, "%s ne part pas en libre" % scene_id)
		assert_false(GameState.is_scene_done(scene_id))
		assert_false(player.is_story_held(), "%s : toujours la main" % trap[4])
		# Témoin : au même endroit, le mode scénarisé la lance.
		StoryDirector.set_mode(StoryPacing.SCENARIO)
		assert_true(
			await until(func() -> bool: return StoryDirector.current_scene() == scene_id, 5.0),
			"%s part en scénarisé" % scene_id
		)


func test_doors_are_open_in_free_mode_and_shut_in_scenario_mode() -> void:
	assert_true(await new_game_from_menu(), "partie lancée depuis le menu")
	assert_eq(GameState.day, 1)
	var projection := ^"Exits/porte_projection/ClosedDoor"
	var limashenka := ^"Exits/porte_limashenka/ClosedDoor"
	assert_true(await _go(&"ville_haute", &"from_sentier"), "la ville haute")
	assert_null(_door(projection), "la salle de projection est ouverte en libre")
	assert_true(await _go(&"village", &"from_entrepot"), "le village")
	assert_null(_door(limashenka), "la maison Limashenka est ouverte en libre")
	StoryDirector.set_mode(StoryPacing.SCENARIO)
	await frames(3)
	assert_not_null(_door(limashenka), "close au jour 1 en scénarisé")
	assert_true(await _go(&"ville_haute", &"from_sentier"), "la ville haute")
	assert_not_null(_door(projection), "close au jour 1 en scénarisé")
	StoryDirector.set_mode(StoryPacing.FREE)
	await frames(3)
	assert_null(_door(projection), "rouverte en libre")


func test_the_mode_survives_a_save_and_a_resume() -> void:
	assert_true(await new_game_from_menu(), "partie lancée depuis le menu")
	assert_true(await save_and_continue(), "reprise")
	assert_eq(StoryDirector.mode(), StoryPacing.FREE, "libre après la reprise")
	StoryDirector.set_mode(StoryPacing.SCENARIO)
	assert_true(await save_and_continue(), "reprise")
	assert_eq(StoryDirector.mode(), StoryPacing.SCENARIO, "scénarisé après la reprise")
	# En scénarisé, le port part tout seul au jour 1 ; repassée en libre en pleine scène, la
	# partie reprise ne la rejoue pas : elle redevient disponible.
	assert_true(
		await until(func() -> bool: return StoryDirector.current_scene() == &"j1_1_port", 5.0),
		"la scène du port en scénarisé"
	)
	StoryDirector.set_mode(StoryPacing.FREE)
	assert_eq(GameState.story_scene, &"j1_1_port", "interrompue en pleine scène")
	assert_true(await save_and_continue(), "reprise")
	assert_eq(StoryDirector.mode(), StoryPacing.FREE, "libre après la reprise")
	assert_eq(GameState.story_scene, &"", "pas de scène à reprendre")
	assert_false(await until(func() -> bool: return not _no_scene(), 2.0), "pas rejouée")
	assert_false(GameState.is_scene_done(&"j1_1_port"), "toujours à vivre")
	assert_false(player.is_story_held(), "la main")
	assert_eq(_fade(), 0.0, "sans voile")


func test_an_old_game_without_mode_keeps_its_scenes_in_scenario_mode() -> void:
	assert_true(await _resume_old(5, &"aube", DAYS_1_TO_4, WAKE_MAP, WAKE_AT), "jour 5")
	assert_eq(StoryDirector.mode(), StoryPacing.SCENARIO, "des scènes faites : scénarisée")
	assert_true(GameState.has_flag(StoryPacing.FLAG), "écrit dans la partie")
	var empty: Array[StringName] = []
	assert_true(
		await _resume_old(1, &"soir", empty, &"entrepot", Vector3(61.0, 0.0, 18.0)),
		"ancienne partie sans scène"
	)
	assert_eq(StoryDirector.mode(), StoryPacing.FREE, "aucune scène faite : libre")
	assert_false(GameState.has_flag(StoryPacing.FLAG))
