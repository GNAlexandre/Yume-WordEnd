extends "res://tests/stubs/m2_game_test.gd"
## (E8) Les jeux dans la vraie partie (main.tscn, menu, nouvelle partie, appuis réels) : le
## raccourci ?jeu=ballon pose la partie sur l'entrepôt et lance le match au champ (le joueur y entre
## en marchant vers le terrain, ses coups sont de vrais appuis) ; ?jeu=baton lance l'entraînement
## à la clairière (le bâton en main, la touche de charge lève la parade, aucun dégât) ; un jeu
## inconnu est ignoré.

const MAP_ID := &"entrepot"

var _previous_fade: float
var _shortcuts: Node


func before_each() -> void:
	super()
	_previous_fade = WorldManager.fade_time
	WorldManager.fade_time = 0.0
	_shortcuts = null


func after_each() -> void:
	if is_instance_valid(_shortcuts):
		_shortcuts.free()
	MiniGames.stop_ball_match()
	MiniGames.stop_staff_training()
	WorldManager.fade_time = _previous_fade
	super()
	GameState.reset()


## Le raccourci de développement, posé comme le fait game.gd quand l'adresse en donne.
func _shortcut(parameters: Dictionary) -> void:
	_shortcuts = (load("res://src/test_shortcuts.gd") as GDScript).new() as Node
	_shortcuts.name = "TestShortcuts"
	_shortcuts.set(&"parameters", parameters)
	game.add_child(_shortcuts)


func test_the_ball_shortcut_starts_the_match_on_the_warehouse_field() -> void:
	assert_true(await new_game_from_menu(), "partie lancée depuis le menu")
	_shortcut({"jeu": "ballon"})
	var started: bool = await until(
		func() -> bool: return MiniGames.ball_match() != null and MiniGames.ball_match().running,
		20.0
	)
	assert_true(started, "le match démarre")
	assert_eq(WorldManager.current_map(), MAP_ID, "sur l'entrepôt")
	assert_eq(LifeSlots.current(), &"apres_midi", "l'après-midi")
	var ball_match := MiniGames.ball_match()
	assert_eq(ball_match.members.size(), 11, "dix petites et Willem à l'arbitrage")
	assert_true(await until(func() -> bool: return ball_match.phase == BallMatch.Phase.PLAY, 40.0))
	assert_not_null(ball_match.ball, "le ballon roule dans la carte")
	# Le joueur est posé hors du champ ; il marche vers lui et entre dans la partie.
	assert_false(ball_match.player_in)
	player.set_aim_direction(Vector3.RIGHT, true)
	assert_true(
		await walk_keys_until([KEY_D], func() -> bool: return ball_match.player_in, 8.0),
		"il entre en approchant du champ"
	)
	assert_ne(ball_match.player_team, &"")
	# Sa touche d'attaque est un vrai appui ; personne n'est blessé.
	await press(&"attack", 2)
	await frames(10)
	assert_eq(health.current, health.max_hp, "aucun mal fait ni subi")
	# Il retourne vers l'ouest : il sort.
	assert_true(
		await walk_keys_until([KEY_A], func() -> bool: return not ball_match.player_in, 10.0),
		"il sort en quittant le champ"
	)
	assert_eq(LifeDirector.actor(&"willem").role, &"arbitre")


func test_the_staff_shortcut_starts_the_training_with_a_real_guard_key() -> void:
	assert_true(await new_game_from_menu(), "partie lancée depuis le menu")
	_shortcut({"jeu": "baton"})
	var started: bool = await until(func() -> bool: return MiniGames.staff_training() != null, 20.0)
	assert_true(started, "l'entraînement démarre")
	var training := MiniGames.staff_training()
	assert_eq(WorldManager.current_map(), MAP_ID)
	assert_eq(LifeSlots.current(), &"matin", "le matin")
	assert_eq(player.weapon(), &"baton", "le bâton en main")
	assert_true(await until(func() -> bool: return training.phase == &"a", 10.0), "phase A")
	assert_lt(
		(
			Vector2(
				player.global_position.x - LifeDirector.actor(&"willem").position().x,
				player.global_position.z - LifeDirector.actor(&"willem").position().z
			)
			. length()
		),
		3.0,
		"face à Willem"
	)
	# La touche de charge (clic droit) lève la parade, sans charge de venenum.
	Input.action_press(&"charge")
	await frames(6)
	assert_true(player.combat.is_guarding(), "parade levée")
	assert_ne(player.combat.current_state(), &"charge")
	Input.action_release(&"charge")
	await frames(4)
	assert_false(player.combat.is_guarding())
	# Un coup arrive : il est annoncé, puis résolu ; la santé n'est jamais touchée.
	assert_true(
		await until(func() -> bool: return not training.current_blow().is_empty(), 10.0),
		"un coup est annoncé"
	)
	assert_true(
		await until(func() -> bool: return training.touches > 0 or training.streak > 0, 10.0),
		"résolu"
	)
	assert_eq(health.current, health.max_hp, "aucun vrai dégât")
	training.stop()
	await frames(2)
	assert_eq(player.weapon(), &"seniorious", "Seniorious revient")


func test_an_unknown_game_is_ignored() -> void:
	assert_true(await new_game_from_menu(), "partie lancée depuis le menu")
	_shortcut({"jeu": "echecs"})
	await frames(30)
	assert_eq(WorldManager.current_map(), WorldManager.LEGACY_MAP, "la partie reste où elle est")
	assert_null(MiniGames.ball_match())
	assert_null(MiniGames.staff_training())
