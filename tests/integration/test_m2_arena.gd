extends "res://tests/stubs/m2_game_test.gd"
## Intégration M2, parcours 3 : l'arène des dunes dans la vraie partie, avec l'écran de fin
## d'arène du L10 tel quel (il fige le jeu jusqu'à « Continuer » ; les tests M1 le referment
## d'office). Série lancée au panneau (E), un Timere tué à l'épée, mort sous les morsures : le
## panneau attend la réapparition (le minuteur de WorldManager n'est jamais figé), Chtholly
## revient au village avec ses PV pleins, l'écran montre le score et le record, « Continuer »
## (Entrée) rend la main ; inventaire, quête et meilleur score sont gardés. Sortie de l'arène
## entre deux vagues : écran tout de suite, « Continuer » à la manette (A) sans saut.
## (Systèmes et textes) Les textes de la veille viennent de data/texts/story.json : invite
## « Sonner la cloche de veille », « Fin de la veille », « Nouveau record de veille ! », fondu
## « Retour à l'entrepôt… » puis « Les autres t'ont ramenée à l'entrepôt. » au retour.

## Devant le panneau, côté village (local à la zone des dunes) : départ des séries.
const PANEL_FRONT := Vector3(10.6, 0.0, -2.0)
## Textes de la veille du Couchant (data/texts/story.json).
const PROMPT := "Sonner la cloche de veille"
const END_TITLE := "Fin de la veille"
const NEW_RECORD := "Nouveau record de veille !"
const DEFEAT_FADE := "Retour à l’entrepôt…"
const DEFEAT_MESSAGE := "Les autres t’ont ramenée à l’entrepôt."


func _text(unique_name: String) -> String:
	return (arena_end.get_node("%" + unique_name) as Label).text


## Joueur devant le panneau, tourné vers lui ; E lance la série (fast : vagues accélérées ;
## sinon les délais de data/waves/dunes.json, 1,2 s avant la vague 1).
func _start_series(fast: bool = true) -> void:
	if fast:
		director.set_config(fast_waves())
	await place_player(&"dunes", PANEL_FRONT, Vector3.LEFT)
	assert_eq(player.current_prompt(), PROMPT, "invite du panneau")
	assert_eq(hud.get_node("%PromptLabel").get(&"text"), PROMPT, "invite dans le HUD")
	await tap_key(KEY_E)
	assert_true(director.is_running(), "E lance la série")


## true si le joueur s'est déplacé en avançant tenue_s secondes (W).
func _can_walk() -> bool:
	var before := player.global_position
	await hold_key(KEY_W, 0.3)
	return flat_distance(before, player.global_position) > 0.3


func test_death_in_the_arena_then_end_screen_at_the_village() -> void:
	assert_true(await new_game_from_menu(), "nouvelle partie")
	watch_signals(EventBus)
	# Ce que la mort ne doit pas faire perdre : des pages, la quête en cours.
	GameState.add_item(&"page_fragment", 3)
	GameState.set_quest_state(&"pages", &"active")
	await _start_series()
	await wait_until(func() -> bool: return director.alive_enemies().size() == 5, 3.0)
	# Un Timere tué à l'épée (J) : des points.
	var target := director.alive_enemies()[0]
	var points := target.data.points
	target.set_physics_process(false)
	target.global_position = ahead(1.0)
	await wait_physics_frames(2)
	for _swing in 3:
		if not target.is_dead():
			await tap_key(KEY_J)
			await wait_until(func() -> bool: return target.is_dead(), 0.5)
	assert_true(target.is_dead(), "Timere tué à l'épée")
	assert_eq(director.score(), points, "score de la série")
	# Plus qu'un PV : les morsures des Timeres de la vague font le reste.
	health.take_damage(4, game)
	var died: bool = await wait_until(func() -> bool: return health.is_dead(), 15.0)
	assert_true(died, "mordu à mort dans l'arène")
	assert_signal_emitted_with_parameters(EventBus, "arena_finished", [&"dunes", points, true])
	await wait_physics_frames(2)
	assert_eq(hud.get_node("%DeathLabel").get(&"text"), DEFEAT_FADE, "fondu de la mort")
	assert_false(arena_end.call(&"is_open"), "pas d'écran pendant la mort")
	assert_true(arena_end.call(&"is_waiting"), "l'écran attend la réapparition")
	assert_false(get_tree().paused, "le minuteur de réapparition n'est pas figé")
	var back: bool = await until(func() -> bool: return arena_end.call(&"is_open"), 5.0)
	assert_true(back, "réapparition, puis l'écran de fin d'arène")
	assert_false(health.is_dead(), "vivant")
	assert_eq(health.current, health.max_hp, "PV pleins")
	var spawn := zone(&"village").get_node(^"Spawn") as Node3D
	assert_lt(distance_to(spawn), 1.0, "au Spawn du village")
	assert_true(get_tree().paused, "l'écran fige le jeu")
	assert_eq(_text("ScoreValue"), str(points), "score")
	assert_eq(_text("BestValue"), str(points), "meilleur score")
	assert_eq(_text("WaveValue"), "1", "vague atteinte")
	assert_true(arena_end.get_node("%RecordBadge").visible, "« Nouveau record ! »")
	assert_eq(_text("Header"), END_TITLE, "titre de l'écran")
	assert_eq(_text("RecordLabel"), NEW_RECORD, "bandeau du record")
	assert_eq(hud.call(&"story_message"), DEFEAT_MESSAGE, "les autres l'ont ramenée")
	assert_eq(get_viewport().gui_get_focus_owner(), arena_end.get_node("%ContinueButton"))
	# « Continuer » à l'Entrée.
	await tap_key(KEY_ENTER)
	assert_false(arena_end.call(&"is_open"), "Entrée : Continuer")
	assert_false(get_tree().paused, "le jeu reprend")
	assert_true(await _can_walk(), "le joueur repart")
	assert_eq(GameState.count(&"page_fragment"), 3, "inventaire gardé")
	assert_eq(GameState.quest_state(&"pages"), &"active", "quête gardée")
	assert_eq(GameState.best_score(&"dunes"), points, "meilleur score gardé")
	assert_eq(hearts_shown(), 5)
	assert_eq(hud.call(&"health"), Vector2i(5, 5), "cœurs pleins dans le HUD")


func test_leaving_the_arena_between_waves_then_continue_with_a_gamepad() -> void:
	assert_true(await new_game_from_menu(), "nouvelle partie")
	GameState.record_score(&"dunes", 120, 3)
	await _start_series(false)
	# Avant la vague 1, le joueur ressort à l'est au stick.
	player.set_aim_direction(Vector3.RIGHT, true)
	await wait_physics_frames(2)
	var shown: bool = await walk_stick_until(
		0.0, -1.0, func() -> bool: return arena_end.call(&"is_open"), 4.0
	)
	assert_true(shown, "sortie de l'arène : fin de la série et écran tout de suite")
	assert_false(director.is_running())
	assert_true(get_tree().paused, "l'écran fige le jeu")
	assert_eq(_text("ScoreValue"), "0")
	assert_eq(_text("BestValue"), "120", "le record d'avant reste")
	assert_false(arena_end.get_node("%RecordBadge").visible, "pas de record")
	assert_eq(_text("Header"), END_TITLE, "fin de la veille, même sans combat")
	assert_eq(hud.call(&"story_message"), "", "pas de message de défaite sans mort")
	# A presse « Continuer » au relâchement ; l'appui n'arrive pas au joueur (saut).
	var y_before := player.global_position.y
	await tap_joy(JOY_BUTTON_A)
	assert_false(arena_end.call(&"is_open"), "A : Continuer")
	assert_false(get_tree().paused, "le jeu reprend")
	var jumped := false
	for _frame in 20:
		await wait_physics_frames(1)
		jumped = jumped or player.global_position.y > y_before + 0.2
	assert_false(jumped, "pas de saut parasite")
	assert_eq(GameState.best_score(&"dunes"), 120, "meilleur score gardé")
	assert_eq(int(GameState.arena_record(&"dunes")["games"]), 2, "une série de plus")
