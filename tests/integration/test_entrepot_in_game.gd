extends "res://tests/stubs/m2_game_test.gd"
## (T1) La carte entrepot dans la vraie partie (main.tscn, appuis réels) : on part du Spawn, on
## longe la façade jusqu'au flanc est et l'on descend par la rampe dans le champ (−0,5 m) ; on monte
## à la clairière d'entraînement par sa rampe (+0,5 m) ; on descend au marais de l'ouest (eau
## basse, on y marche) ; puis on prend chaque sortie à pied (village, colline, sentier, forêt
## profonde) et l'on en revient par la sortie de la carte d'attente, au marqueur du plan ; les deux
## portes du bâtiment s'ouvrent par « Entrer » (vers le rez-de-chaussée, ou, tant qu'il n'existe
## pas, la carte d'essai des intérieurs), et l'on revient sur leur marqueur.

const MAP_ID := &"entrepot"
## Sorties à pied : touche vers la sortie depuis le marqueur de retour, carte d'attente, touche
## vers la sortie de retour.
const WALK_EXITS := {
	"vers_village": [&"from_village", KEY_A, &"village", KEY_D],
	"vers_colline": [&"from_colline", KEY_W, &"colline", KEY_S],
	"vers_sentier": [&"from_sentier", KEY_D, &"sentier", KEY_A],
	"vers_foret": [&"from_foret_profonde", KEY_S, &"foret_profonde", KEY_W],
}
const DOORS := {
	"porte_entree": [&"from_entrepot_rdc", KEY_W],
	"porte_service": [&"from_entrepot_rdc_service", KEY_D],
}

var _previous_fade: float


func before_each() -> void:
	super()
	_previous_fade = WorldManager.fade_time
	WorldManager.fade_time = 0.0


func after_each() -> void:
	WorldManager.fade_time = _previous_fade
	super()


func _map() -> Map:
	return WorldManager.current_map_node()


func _ground() -> MapGround:
	return _map().get_node(^"Ground") as MapGround


func wait_transition(max_seconds: float = 10.0) -> bool:
	return await until(func() -> bool: return not WorldManager.is_transitioning(), max_seconds)


## Pose le joueur au sol en (x, z) de la carte, visée aim, et attend qu'il touche le sol.
func put_player(x: float, z: float, aim: Vector3) -> void:
	player.global_position = Vector3(x, _ground().height_at(x, z) + 0.1, z)
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	player.set_aim_direction(aim, true)
	await frames(3)
	await until(func() -> bool: return player.is_on_floor(), 2.0)
	await frames(1)


func _enter_entrepot() -> void:
	assert_true(await new_game_from_menu(), "partie lancée depuis le menu")
	await WorldManager.go_to(MAP_ID)
	assert_true(await wait_transition(), "arrivée")
	assert_eq(WorldManager.current_map(), MAP_ID)


## Le raccourci de développement ?map=entrepot&marker=from_sentier (src/test_shortcuts.gd, posé
## par game.gd quand l'adresse ou la ligne de commande en donne).
func test_map_shortcut_puts_the_game_on_the_warehouse() -> void:
	assert_true(await new_game_from_menu(), "partie lancée depuis le menu")
	var shortcuts := (load("res://src/test_shortcuts.gd") as GDScript).new() as Node
	shortcuts.name = "TestShortcuts"
	shortcuts.set(&"parameters", {"map": "entrepot", "marker": "from_sentier"})
	game.add_child(shortcuts)
	assert_true(await wait_transition(), "arrivée sans fondu")
	assert_eq(WorldManager.current_map(), MAP_ID, "carte entrepot")
	assert_lt(distance_to(_map().marker(&"from_sentier")), 0.3, "sur from_sentier")
	shortcuts.queue_free()


func test_walk_from_the_yard_to_the_field_the_clearing_and_the_marsh() -> void:
	await _enter_entrepot()
	assert_lt(distance_to(_map().spawn()), 0.3, "posé au Spawn, dans la cour")
	assert_eq(player.camera_rig.limits, _map().bounds(), "caméra bornée à la carte")
	# Vers l'est le long de la cour, au nord le long du flanc est, puis la rampe du champ.
	assert_true(
		await walk_keys_until([KEY_D], func() -> bool: return player.global_position.x > 61.3, 10.0),
		"au coin est de la cour"
	)
	assert_true(
		await walk_keys_until([KEY_W], func() -> bool: return player.global_position.z < 18.4, 8.0),
		"le long du flanc est"
	)
	assert_true(
		await walk_keys_until([KEY_D], func() -> bool: return player.global_position.x > 68.0, 6.0),
		"par la rampe, dans le champ"
	)
	await until(func() -> bool: return player.is_on_floor(), 2.0)
	assert_almost_eq(player.global_position.y, -0.5, 0.08, "le champ est 0,5 m plus bas")
	# La clairière d'entraînement : la rampe du sud-est, depuis le potager.
	await put_player(24.0, 27.6, Vector3.FORWARD)
	assert_almost_eq(player.global_position.y, 0.0, 0.08, "au pied de la rampe")
	assert_true(
		await walk_keys_until([KEY_W], func() -> bool: return player.global_position.z < 20.5, 6.0),
		"en haut de la rampe"
	)
	await until(func() -> bool: return player.is_on_floor(), 2.0)
	assert_almost_eq(player.global_position.y, 0.5, 0.08, "la clairière est 0,5 m plus haut")
	# Le marais de l'ouest : sa rampe au sud, puis l'eau basse où l'on marche.
	await put_player(4.0, 34.0, Vector3.FORWARD)
	assert_true(
		await walk_keys_until([KEY_W], func() -> bool: return player.global_position.z < 26.0, 6.0),
		"descendu dans le marais"
	)
	await until(func() -> bool: return player.is_on_floor(), 2.0)
	assert_almost_eq(player.global_position.y, -0.5, 0.08, "le marais est 0,5 m plus bas")
	assert_eq(WorldManager.current_map(), MAP_ID, "toujours à l'entrepôt")


func test_each_path_leads_to_its_waiting_map_and_back() -> void:
	await _enter_entrepot()
	for exit_name: String in WALK_EXITS:
		var spec: Array = WALK_EXITS[exit_name]
		var marker := _map().marker(spec[0] as StringName)
		await put_player(marker.global_position.x, marker.global_position.z, -marker.global_basis.z)
		assert_true(
			await walk_keys_until(
				[spec[1] as Key], func() -> bool: return WorldManager.current_map() == spec[2], 6.0
			),
			"%s : vers %s" % [exit_name, spec[2]]
		)
		release_all_input()
		assert_true(await wait_transition(), "%s : arrivée" % exit_name)
		var arrival := _map().marker(&"from_entrepot")
		assert_lt(distance_to(arrival), 0.3, "%s : posé sur from_entrepot" % exit_name)
		assert_true(
			await walk_keys_until(
				[spec[3] as Key], func() -> bool: return WorldManager.current_map() == MAP_ID, 6.0
			),
			"%s : retour à l'entrepôt" % exit_name
		)
		release_all_input()
		assert_true(await wait_transition(), "%s : retour" % exit_name)
		assert_lt(distance_to(_map().marker(spec[0] as StringName)), 0.3, "%s : sur %s" % [exit_name, spec[0]])


func test_the_doors_open_on_enter_and_lead_back_to_their_markers() -> void:
	await _enter_entrepot()
	for exit_name: String in DOORS:
		var spec: Array = DOORS[exit_name]
		var target := (_map().get_node(NodePath("Exits/" + exit_name)) as MapExit).target_map
		var marker := _map().marker(spec[0] as StringName)
		await put_player(marker.global_position.x, marker.global_position.z, -marker.global_basis.z)
		assert_true(
			await walk_keys_until(
				[spec[1] as Key], func() -> bool: return player.current_prompt() == "Entrer", 4.0
			),
			"%s : invite « Entrer »" % exit_name
		)
		release_all_input()
		await tap_key(KEY_E)
		assert_true(
			await until(func() -> bool: return WorldManager.current_map() == target, 10.0),
			"%s : vers %s" % [exit_name, target]
		)
		assert_true(await wait_transition(), "%s : arrivée" % exit_name)
		await WorldManager.go_to(MAP_ID, spec[0] as StringName)
		assert_true(await wait_transition(), "%s : retour" % exit_name)
		assert_lt(distance_to(_map().marker(spec[0] as StringName)), 0.3, "%s : sur %s" % [exit_name, spec[0]])
