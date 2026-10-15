extends "res://tests/stubs/m1_game_test.gd"
## (E6) Les jours 2 à 4 de l'acte 1, scène après scène, dans une vraie partie (game.tscn), à
## partir d'une sauvegarde prise au réveil du jour 2 : chaque scène part de son déclencheur et va
## au bout, le temps passe, on se couche, le jour 5 commence. Les déplacements sont des poses
## (le jour 1 est joué avec de vrais appuis par test_e6_day1.gd) ; les dialogues se lisent par
## la boîte de dialogue.

const SEEN := "user://test_e6_days_seen.cfg"
const DAY_1 := [
	"j1_1_port",
	"j1_2_lumiere",
	"j1_2_embuscade",
	"j1_3_intrus",
	"j1_4_chemin",
	"j1_5_premiers_pas",
	"j1_6_diner",
	"j1_7_chambre",
]

var _previous_seen: String


func start_map_for_test() -> StringName:
	return WorldManager.START_MAP


func before_each() -> void:
	super()
	_previous_seen = StoryDirector.seen_path
	StoryDirector.seen_path = SEEN
	StoryDirector.forget_seen()
	WorldManager.fade_time = 0.0


func after_each() -> void:
	super()
	StoryDirector.forget_seen()
	StoryDirector.seen_path = _previous_seen
	StoryDirector.forget_seen()
	WorldManager.fade_time = WorldManager.DEFAULT_FADE_TIME


## Une partie reprise au réveil du jour 2, dans la chambre de la protagoniste.
func _resume_day_2() -> void:
	SaveManager.new_game(&"chtholly")
	var state := GameState.to_dict()
	state["day"] = 2
	state["slot"] = "aube"
	state["moment"] = "aube"
	state["scenes_done"] = DAY_1
	state["calendar"] = {"1": ""}
	state["map"] = "entrepot_etage"
	state["position"] = [6.2, 0.0, 7.4]
	GameState.from_dict(state)
	EventBus.game_loaded.emit()
	game = GAME_SCENE.instantiate() as Node3D
	add_child(game)
	player = game.get_node(^"Player") as Player
	await wait_physics_frames(3)


func _box() -> DialogueBox:
	return game.get_node(^"UI/DialogueBox") as DialogueBox


## Lit les dialogues (premier choix) jusqu'à predicate.
func _read_until(predicate: Callable, seconds: float = 30.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while not predicate.call():
		if Time.get_ticks_msec() > deadline:
			return false
		var box := _box()
		if box.is_open():
			box.complete_line()
			if box.is_choosing():
				box.choose(0)
			elif box.is_waiting():
				box.advance()
		await wait_physics_frames(1)
	return true


func _done(scene_id: StringName) -> bool:
	return await _read_until(func() -> bool: return GameState.is_scene_done(scene_id))


func _free() -> bool:
	return await _read_until(
		func() -> bool: return not StoryDirector.is_playing() and not player.is_story_held()
	)


func _go(map_id: StringName, marker: StringName = &"Spawn") -> void:
	await WorldManager.go_to(map_id, marker)
	await wait_physics_frames(4)


func _place(spec: Variant) -> void:
	var at := StoryDirector.stage().resolve(spec).origin
	player.global_position = WorldManager.ground_position(at, player)
	player.velocity = Vector3.ZERO
	await wait_physics_frames(4)


func _sleep() -> void:
	if WorldManager.current_map() != &"entrepot_etage":
		await _go(&"entrepot_etage")
	assert_true(StoryDirector.can_sleep(), "on peut se coucher (jour %d)" % GameState.day)
	var day := GameState.day
	await StoryDirector.sleep()
	assert_eq(GameState.day, day + 1)
	assert_true(GameState.has_calendar_line(day), "ligne du jour %d" % day)


func test_days_2_to_4() -> void:
	await _resume_day_2()
	assert_eq(GameState.day, 2)
	# Jour 2 : la toilette, la fuite, la fenêtre.
	assert_true(
		await _read_until(func() -> bool: return StoryDirector.current_scene() == &"j2_1_matin")
	)
	assert_true(await _read_until(func() -> bool: return not player.is_story_held()))
	await _go(&"entrepot_rdc", &"from_entrepot_etage")
	await _place(&"point_eau")
	assert_true(
		await _read_until(func() -> bool: return LifeSlots.current() == &"matin"), "la cloche"
	)
	assert_true(await _read_until(func() -> bool: return not player.is_story_held()))
	await _place(&"refectoire_allee")
	assert_true(await _done(&"j2_1_matin"))
	assert_true(await _done(&"j2_2_fuite"))
	assert_false(GameState.has_flag(&"j2_petit_dejeuner_rate"), "à l'heure")
	assert_true(await _free())
	assert_true(StoryDirector.can_rest())
	await StoryDirector.pass_time()
	await StoryDirector.pass_time()
	assert_eq(LifeSlots.current(), &"apres_midi")
	assert_false(StoryDirector.can_rest(), "pas au-delà de la fenêtre de Willem")
	await _go(&"entrepot_etage", &"from_entrepot_rdc")
	assert_eq(StoryDirector.hint(), "Willem n'est pas sorti de sa chambre de l'après-midi.")
	await _place(&"willem_porte")
	assert_true(await _done(&"j2_3_fenetre"))
	assert_true(await _free())
	assert_false(StoryDirector.can_sleep(), "pas avant le soir")
	await StoryDirector.pass_time()
	await _sleep()
	# Jour 3 : le porche, le chemin, le snack-bar (sur le noir), le retour au soir.
	assert_true(await _free())
	await _go(&"entrepot", &"from_entrepot_rdc")
	assert_true(await _read_until(_porch_done))
	assert_has(StoryDirector.stage().followers(), &"ithea", "Ithea suit")
	await _go(&"sentier", &"from_entrepot")
	assert_true(await _done(&"j3_1_information"))
	assert_true(await _done(&"j3_3_snack"))
	assert_eq(WorldManager.current_map(), &"entrepot")
	assert_eq(LifeSlots.current(), &"soir")
	assert_true(await _free())
	await _sleep()
	# Jour 4 : la cuisine l'après-midi, le dîner le soir.
	assert_true(await _free())
	for _slot in 3:
		await StoryDirector.pass_time()
	assert_eq(LifeSlots.current(), &"apres_midi")
	await _go(&"entrepot_rdc", &"from_entrepot_etage")
	await _place(&"refectoire_porte_cuisine")
	assert_true(await _done(&"j4_1_cuisine"))
	assert_true(await _free())
	await StoryDirector.pass_time()
	await _place(&"refectoire_allee")
	assert_true(await _done(&"j4_2_diner"))
	assert_true(await _free())
	await _sleep()
	assert_eq(GameState.day, 5, "le jour 5 (scènes du lot S2) commence")
	assert_eq(GameState.calendar().size(), 4, "quatre lignes au calendrier")
	assert_eq(GameState.quests(), {}, "aucune quête à collecter")


func _porch_done() -> bool:
	return StoryDirector.current_scene() == &"j3_1_information" and not player.is_story_held()
