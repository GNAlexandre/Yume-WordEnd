extends "res://tests/stubs/m2_game_test.gd"
## (E8b) Le duel et l'entraînement avec Seniorious dans la vraie partie (main.tscn, menu, nouvelle
## partie, vrais appuis du clavier) : le raccourci ?jeu=duel pose la partie dans la cour de
## l'entrepôt ; le joueur marche vers Willem (W), frappe (J) : Willem fait un pas de côté ; il tient
## la charge (K) 2 s : la vision accélérée ; il la relâche : l'onde part, l'élan, l'écran blanc, la
## projection ; aucun point de vie perdu ; tout est rendu ; la reprise suit. ?jeu=seniorious lance
## l'entraînement à la clairière, la touche de charge rythme le souffle.

const MAP_ID := &"entrepot"

var _previous_fade: float
var _shortcuts: Node


func before_each() -> void:
	super()
	_previous_fade = WorldManager.fade_time
	WorldManager.fade_time = 0.0
	_shortcuts = null


func after_each() -> void:
	key(KEY_K, false)
	key(KEY_J, false)
	key(KEY_W, false)
	MiniGames.stop_duel()
	MiniGames.stop_seniorious_training()
	if is_instance_valid(_shortcuts):
		_shortcuts.free()
	WorldManager.fade_time = _previous_fade
	super()
	GameState.reset()


## Le raccourci de développement, posé comme le fait game.gd quand l'adresse en donne.
func _shortcut(parameters: Dictionary) -> void:
	_shortcuts = (load("res://src/test_shortcuts.gd") as GDScript).new() as Node
	_shortcuts.name = "TestShortcuts"
	_shortcuts.set(&"parameters", parameters)
	game.add_child(_shortcuts)


func _willem_distance() -> float:
	var willem := LifeDirector.actor(&"willem")
	var offset := willem.position() - player.global_position
	return Vector2(offset.x, offset.z).length()


func test_the_duel_is_played_with_real_keys_and_cannot_be_won() -> void:
	assert_true(await new_game_from_menu(), "partie lancée depuis le menu")
	_shortcut({"jeu": "duel"})
	assert_true(await until(func() -> bool: return MiniGames.duel() != null, 20.0), "le duel")
	var duel := MiniGames.duel()
	var results: Array[Dictionary] = []
	duel.finished.connect(func(found: Dictionary) -> void: results.append(found))
	assert_eq(WorldManager.current_map(), MAP_ID, "dans la cour de l'entrepôt")
	assert_eq(LifeSlots.current(), &"matin", "le matin")
	assert_eq(player.weapon(), &"seniorious", "Seniorious en main")
	var post := GameVision.post_material(player)
	var pale_before: Variant = post.get_shader_parameter(&"pale_amount")
	var flash_before: Variant = post.get_shader_parameter(&"flash_color")
	var hp := health.current
	assert_true(await until(func() -> bool: return duel.phase == &"dodge", 6.0), "phase 1")
	# Il marche vers Willem (W : le nord) et frappe (J) : Willem fait un pas de côté.
	assert_true(
		await walk_keys_until([KEY_W], func() -> bool: return _willem_distance() < 1.8, 8.0),
		"près de Willem"
	)
	await tap_key(KEY_J, 3)
	assert_true(await until(func() -> bool: return duel.dodges >= 1, 3.0), "il esquive")
	assert_eq(duel.phase, &"dodge")
	# La charge tenue (K) 2 s : la vision accélérée.
	await frames(20)
	key(KEY_K, true)
	assert_true(await until(func() -> bool: return duel.phase == &"vision", 5.0), "phase 2")
	assert_eq(duel.vision_by, &"charge")
	await frames(20)
	assert_gt(float(post.get_shader_parameter(&"pale_amount")), 0.2, "l'image pâlit")
	assert_lt(duel.vision.time_scale, 1.0, "le monde ralentit")
	# Relâchée : l'onde part, l'élan, l'écran blanc.
	key(KEY_K, false)
	assert_true(await until(func() -> bool: return duel.phase == &"reversal", 4.0), "phase 3")
	assert_true(await until(func() -> bool: return duel.vision.flash() > 0.5, 2.0), "le blanc")
	assert_true(await until(func() -> bool: return not results.is_empty(), 10.0), "la fin")
	assert_false(results[0]["success"], "la réussite est impossible")
	assert_eq(results[0]["phases"], [&"intro", &"dodge", &"vision", &"reversal"])
	assert_eq(health.current, hp, "aucun point de vie perdu")
	assert_eq(post.get_shader_parameter(&"pale_amount"), pale_before, "l'image revient")
	assert_eq(post.get_shader_parameter(&"flash_color"), flash_before)
	assert_false(player.is_story_held(), "la main revient")
	# « Encore une fois ! » : le raccourci enchaîne la reprise.
	assert_true(
		await until(
			func() -> bool: return MiniGames.duel() != null and MiniGames.duel().reprise, 5.0
		),
		"la reprise"
	)


func test_the_seniorious_shortcut_starts_the_breathing_with_the_charge_key() -> void:
	assert_true(await new_game_from_menu(), "partie lancée depuis le menu")
	_shortcut({"jeu": "seniorious"})
	assert_true(
		await until(func() -> bool: return MiniGames.seniorious_training() != null, 20.0),
		"l'entraînement"
	)
	var training := MiniGames.seniorious_training()
	assert_eq(WorldManager.current_map(), MAP_ID)
	assert_eq(player.weapon(), &"seniorious")
	assert_true(await until(func() -> bool: return training.stage == &"breath", 6.0), "le souffle")
	var outcomes: Array[StringName] = []
	training.resolved.connect(
		func(kind: StringName, outcome: StringName) -> void:
			if kind == &"breath":
				outcomes.append(outcome)
	)
	var hp := health.current
	# Inspirer : la charge (K) tenue ; relâchée vers la fin du souffle.
	assert_true(
		await until(
			func() -> bool:
				return (
					training.breath_phase()[0] == &"in"
					and training.game_time() >= training.breath_end() - 4.0
				),
			6.0
		)
	)
	key(KEY_K, true)
	var release_at := training.breath_end() - 0.05
	assert_true(await until(func() -> bool: return training.game_time() >= release_at, 6.0))
	key(KEY_K, false)
	assert_true(await until(func() -> bool: return not outcomes.is_empty(), 3.0), "jugé")
	assert_true(outcomes[0] in [&"good", &"late", &"early"], "un souffle compté : %s" % outcomes[0])
	assert_eq(health.current, hp, "aucun dégât")
	training.stop()
	await frames(2)
	assert_null(MiniGames.seniorious_training())
