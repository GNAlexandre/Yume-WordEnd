extends "res://tests/stubs/m1_game_test.gd"
## (E6) Le moteur du récit dans une vraie partie (game.tscn), sur un acte d'essai
## (tests/data/story : le rez-de-chaussée de l'entrepôt) : chaque étape fait ce qu'elle dit, les
## conditions et les drapeaux décident des scènes, les déclencheurs partent, les présents sont
## réservés puis rendus à la vie, la séquence se passe, le temps passe (jamais au-delà de la
## scène suivante), on se couche et le jour avance ; le crochet des jeux (E8) ; la conversation
## libre ; la reprise d'une scène commencée ; une partie de l'ancienne île n'a pas de récit.

const TEST_ROOT := "res://tests/data/story"
const SEEN := "user://test_story_runner_seen.cfg"

var _previous_seen: String
var _game_params: Dictionary = {}


func start_map_for_test() -> StringName:
	return &"entrepot_rdc"


func before_each() -> void:
	super()
	StoryData.use_root(TEST_ROOT)
	_previous_seen = StoryDirector.seen_path
	StoryDirector.seen_path = SEEN
	StoryDirector.forget_seen()
	WorldManager.fade_time = 0.0


func after_each() -> void:
	StoryDirector.register_game(&"jeu_essai", Callable())
	super()
	StoryDirector.forget_seen()
	StoryDirector.seen_path = _previous_seen
	StoryDirector.forget_seen()
	StoryData.use_root("")
	WorldManager.fade_time = WorldManager.DEFAULT_FADE_TIME


func _box() -> DialogueBox:
	return game.get_node(^"UI/DialogueBox") as DialogueBox


## Attend que la scène soit jouée en répondant aux dialogues (choix index, sinon « suite »).
func _play(scene_id: StringName, choice: int = 0, seconds: float = 15.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while not GameState.is_scene_done(scene_id):
		if Time.get_ticks_msec() > deadline:
			return false
		var box := _box()
		if box.is_open():
			box.complete_line()
			if box.is_choosing():
				box.choose(choice)
			elif box.is_waiting():
				box.advance()
		await wait_physics_frames(1)
	return true


func _place(spec: Variant) -> void:
	var at := StoryDirector.stage().resolve(spec).origin
	player.global_position = WorldManager.ground_position(at, player)
	player.velocity = Vector3.ZERO
	await wait_physics_frames(4)


func test_steps_conditions_triggers_and_days() -> void:
	await start_game()
	assert_eq(WorldManager.current_map(), &"entrepot_rdc")
	assert_eq(GameState.day, 1, "l'acte d'essai commence au jour 1")
	assert_eq(LifeSlots.current(), &"matin")
	assert_true(await wait_until(func() -> bool: return StoryDirector.current_scene() == &"t1_etapes", 3.0))
	assert_true(player.is_story_held(), "la scène prend le contrôle")
	assert_true(LifeDirector.is_reserved(&"willem"), "les présents sont réservés")
	assert_true(await wait_until(func() -> bool: return _box().is_choosing(), 20.0), "le dialogue")
	var willem := LifeDirector.actor(&"willem")
	var corner: Vector3 = StoryDirector.stage().resolve(&"refectoire_bout_est").origin
	assert_lt(Vector2(willem.position().x - corner.x, willem.position().z - corner.z).length(), 0.4, "marche")
	assert_eq(willem.outfit, &"cuisine", "tenue")
	assert_eq(willem.state, LifeActor.State.SCENE)
	assert_eq(willem.npc.visual.current_animation(), &"parle", "il parle")
	assert_true(GameState.has_flag(&"t_drapeau"), "drapeau")
	assert_eq(LifeSlots.current(), &"midi", "créneau")
	assert_eq(GameState.weather, &"pluie", "temps")
	assert_eq(GameState.calendar().get(1), &"special", "ligne du calendrier")
	assert_eq(StoryDirector.hint(), "Un indice d'essai.", "indice de l'étape")
	assert_true(player.camera_rig.is_story_framed(), "cadrage")
	_box().choose(1)
	assert_true(await _play(&"t1_etapes", 1))
	assert_true(GameState.has_flag(&"t_choix_b") and GameState.has_flag(&"t_suite_b"), "choix et « if »")
	assert_true(GameState.has_flag(&"t_trop_tard"), "wait_for : délai écoulé")
	assert_false(player.camera_rig.is_story_framed(), "caméra rendue")
	# t2 : sa condition (le choix B) tient, elle part tout de suite.
	assert_true(await _play(&"t2_drapeau"))
	await wait_physics_frames(3)
	assert_false(LifeDirector.is_reserved(&"willem"), "rendu à la vie après la scène")
	assert_false(player.is_story_held(), "le joueur a la main")
	# t3 : un lieu atteint, un suiveur, une conversation attendue.
	assert_eq(StoryDirector.hint(), "Va au point d'eau.")
	await _place(&"point_eau")
	assert_true(await wait_until(func() -> bool: return StoryDirector.current_scene() == &"t3_lieu", 3.0))
	assert_true(await wait_until(func() -> bool: return not player.is_story_held(), 3.0))
	assert_has(StoryDirector.stage().followers(), &"willem")
	await _place(&"couloir_est")
	assert_true(await wait_until(func() -> bool: return LifeDirector.actor(&"willem").position().distance_to(player.global_position) < 2.6, 15.0), "Willem suit")
	await _place(&"couloir_centre")
	await wait_physics_frames(30)
	assert_false(LifeDirector.actor(&"willem").is_moving(), "trop loin (plus de 8 m) : il s'arrête")
	assert_true(LifeDirector.actor(&"willem").on_interact(), "la conversation attendue")
	# t4 : le jeu inscrit (E8) reçoit ses paramètres ; pas de repli.
	StoryDirector.register_game(&"jeu_essai", _fake_game)
	assert_true(await _play(&"t3_lieu"))
	assert_true(await _play(&"t4_jeu"))
	assert_eq(_game_params, {"n": 2.0})
	assert_false(GameState.has_flag(&"t4_repli"))
	# t5 : séquence pas encore vue : elle ne se passe pas ; vue, Échap la passe.
	assert_true(await wait_until(func() -> bool: return StoryDirector.current_scene() == &"t5_sequence", 3.0))
	assert_false(StoryDirector.is_skippable())
	StoryDirector.mark_seen(&"t5_sequence")
	assert_true(StoryDirector.is_skippable())
	var skip := InputEventAction.new()
	skip.action = &"pause"
	skip.pressed = true
	Input.parse_input_event(skip)
	assert_true(await _play(&"t5_sequence", 0, 3.0), "séquence passée")
	assert_true(GameState.has_flag(&"t5_fin"), "la fin passée s'applique quand même")
	skip.pressed = false
	Input.parse_input_event(skip)
	# t6 attend le soir : on laisse passer le temps, pas au-delà.
	await wait_physics_frames(5)
	assert_eq(StoryDirector.hint(), "Rien ne presse : tu peux laisser passer le temps.")
	assert_true(StoryDirector.can_rest())
	await StoryDirector.pass_time()
	assert_eq(LifeSlots.current(), &"apres_midi")
	await StoryDirector.pass_time()
	assert_eq(LifeSlots.current(), &"soir")
	assert_false(StoryDirector.can_rest(), "pas au-delà de la scène du soir")
	assert_false(StoryDirector.can_sleep(), "pas de coucher avant la scène")
	await wait_physics_frames(5)
	assert_eq(StoryDirector.hint(), "Il attend le soir.")
	await _place(&"entree")
	assert_true(await _play(&"t6_soir"))
	# Dormir : la ligne choisie reste, le jour 2 commence à l'aube sous la pluie.
	await wait_physics_frames(5)
	assert_true(StoryDirector.can_sleep())
	assert_eq(StoryDirector.hint(), "Au lit, Chtholly.")
	await StoryDirector.sleep()
	assert_eq(GameState.day, 2)
	assert_eq(LifeSlots.current(), &"aube")
	assert_eq(GameState.weather, &"pluie")
	assert_eq(StoryDirector.calendar_line(1), "Une ligne choisie par une scène.")
	assert_eq(GameState.quests(), {}, "aucune quête pendant l'acte")


func test_free_talk_by_day() -> void:
	await start_game()
	assert_true(await _play(&"t1_etapes", 0))
	GameState.day = 2
	var lines: Array[String] = []
	listen(EventBus.dialogue_line, func(_s: String, text: String, _c: Array[String]) -> void: lines.append(text))
	var willem := LifeDirector.stage(&"willem", player.global_position + Vector3(1.5, 0, 0))
	LifeDirector.release(&"willem", false)
	await wait_physics_frames(2)
	willem = LifeDirector.actor(&"willem")
	if willem == null:
		willem = LifeDirector.stage(&"willem", player.global_position + Vector3(1.5, 0, 0))
	assert_true(LifeDirector.handle_talk(willem), "le récit prend la conversation")
	assert_eq(lines.back() if not lines.is_empty() else "", "Deuxième jour.", "talk/willem.json, jour 2")
	_box().complete_line()
	_box().advance()


func test_reserved_npc_ignores_schedule_then_returns_to_life() -> void:
	StoryDirector.enabled = false
	WorldManager.start_map = &"entrepot_rdc_essai"
	await start_game()
	StoryDirector.enabled = true
	var willem := LifeDirector.actor(&"willem")
	if willem == null:
		pending("pas d'emploi du temps de Willem sur la carte d'essai")
		return
	LifeDirector.reserve(&"willem")
	assert_eq(willem.state, LifeActor.State.SCENE)
	LifeDirector.set_slot(&"apres_midi", 0.0)
	await wait_physics_frames(5)
	assert_eq(willem.state, LifeActor.State.SCENE, "réservé : il ne suit plus son emploi du temps")
	assert_false(willem.is_moving())
	LifeDirector.release(&"willem")
	assert_ne(willem.state, LifeActor.State.SCENE, "rendu à la vie")
	assert_true(willem.is_moving(), "il rejoint sa ligne")


func test_resume_restarts_scene_in_progress() -> void:
	await start_game()
	assert_true(await wait_until(func() -> bool: return _box().is_choosing(), 20.0))
	var saved := GameState.to_dict()
	assert_eq(saved["story_scene"], "t1_etapes", "la scène en cours est sauvegardée")
	assert_eq(saved["day"], 1)
	game.free()
	game = null
	GameState.from_dict(saved)
	EventBus.game_loaded.emit()
	game = GAME_SCENE.instantiate() as Node3D
	add_child(game)
	player = game.get_node(^"Player") as Player
	assert_true(await wait_until(func() -> bool: return StoryDirector.current_scene() == &"t1_etapes", 5.0), "reprise de la scène")
	assert_true(await _play(&"t1_etapes", 0))
	assert_eq(GameState.story_scene, &"")


func test_legacy_island_has_no_story() -> void:
	WorldManager.start_map = WorldManager.LEGACY_MAP
	StoryData.use_root("")
	await start_game()
	assert_eq(WorldManager.current_map(), WorldManager.LEGACY_MAP)
	assert_false(GameState.story_running(), "l'ancienne île garde ses quêtes")
	assert_eq(GameState.quest_state(&"act1_main"), &"active", "la quête principale y démarre")
	assert_eq(StoryDirector.hint(), "")


func _fake_game(params: Dictionary) -> void:
	_game_params = params
	await get_tree().physics_frame
