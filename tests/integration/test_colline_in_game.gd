extends "res://tests/stubs/m2_game_test.gd"
## (C3) La colline des étoiles dans la vraie partie (main.tscn, appuis réels) : de l'entrepôt à la
## colline par la sortie à pied, de jour et de nuit (on arrive sur from_entrepot) ; la colline est
## de nuit quel que soit le moment (light_preset), l'entrepôt suit le moment ; la montée par les
## trois rampes, de terrasse en terrasse jusqu'au sommet (+1, +2,5, +3,5 m) ; au bord, on ne tombe
## pas ; puis le retour à l'entrepôt par la sortie, sur from_colline.

const ENTREPOT := &"entrepot"
const COLLINE := &"colline"

var _previous_fade: float


func before_each() -> void:
	super()
	_previous_fade = WorldManager.fade_time
	WorldManager.fade_time = 0.0


func after_each() -> void:
	WorldManager.fade_time = _previous_fade
	Atmosphere.player_light_mode = Atmosphere.LIGHT_AUTO
	GameState.reset()
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


func _enter_entrepot(moment: StringName) -> void:
	assert_true(await new_game_from_menu(), "partie lancée depuis le menu")
	await WorldManager.go_to(ENTREPOT)
	assert_true(await wait_transition(), "arrivée à l'entrepôt")
	Atmosphere.set_moment(moment, 0.0)
	await frames(4)


## De l'entrepôt à la colline, à pied : depuis le marqueur de la sortie nord, vers le nord.
func _walk_to_the_hill() -> void:
	var marker := _map().marker(&"from_colline")
	await put_player(marker.global_position.x, marker.global_position.z, -marker.global_basis.z)
	assert_true(
		await walk_keys_until(
			[KEY_W], func() -> bool: return WorldManager.current_map() == COLLINE, 8.0
		),
		"de l'entrepôt à la colline"
	)
	release_all_input()
	assert_true(await wait_transition(), "arrivée sur la colline")
	await frames(4)
	assert_eq(WorldManager.current_map(), COLLINE)
	assert_lt(distance_to(_map().marker(&"from_entrepot")), 0.3, "posé sur from_entrepot")
	assert_eq(WorldManager.map_display_name(COLLINE), "La colline des étoiles")
	assert_eq(player.camera_rig.limits, _map().bounds(), "caméra bornée à la carte")


## Monte jusqu'au sommet par les trois rampes : chaque terrasse a sa hauteur.
func _climb_to_the_summit() -> void:
	await put_player(12.5, 35.4, Vector3.FORWARD)
	assert_almost_eq(player.global_position.y, 0.0, 0.08, "au pied de la première rampe")
	assert_true(
		await walk_keys_until([KEY_W], func() -> bool: return player.global_position.z < 28.6, 6.0),
		"la première rampe"
	)
	release_all_input()
	await until(func() -> bool: return player.is_on_floor(), 2.0)
	assert_almost_eq(player.global_position.y, 1.0, 0.08, "la terrasse basse, +1 m")
	await put_player(25.5, 30.8, Vector3.FORWARD)
	assert_true(
		await walk_keys_until([KEY_W], func() -> bool: return player.global_position.z < 22.6, 6.0),
		"la deuxième rampe"
	)
	release_all_input()
	await until(func() -> bool: return player.is_on_floor(), 2.0)
	assert_almost_eq(player.global_position.y, 2.5, 0.08, "la terrasse haute, +2,5 m")
	await put_player(16.5, 24.6, Vector3.FORWARD)
	assert_true(
		await walk_keys_until([KEY_W], func() -> bool: return player.global_position.z < 17.6, 6.0),
		"la troisième rampe"
	)
	release_all_input()
	await until(func() -> bool: return player.is_on_floor(), 2.0)
	assert_almost_eq(player.global_position.y, 3.5, 0.08, "le sommet, +3,5 m")
	assert_eq(WorldManager.current_map(), COLLINE, "toujours sur la colline")


## Au bord du vide : le joueur marche vers le nord et s'arrête avant la côte.
func _stop_at_the_rim() -> void:
	await put_player(20.0, 9.0, Vector3.FORWARD)
	await walk_keys_until([KEY_W], func() -> bool: return player.global_position.z < 3.0, 3.0)
	release_all_input()
	await frames(6)
	assert_gt(player.global_position.z, 3.3, "la bande du bord arrête le joueur")
	assert_almost_eq(player.global_position.y, 3.5, 0.1, "il ne tombe pas")
	assert_eq(WorldManager.current_map(), COLLINE)


func _walk_back_to_the_warehouse() -> void:
	var marker := _map().marker(&"from_entrepot")
	await put_player(marker.global_position.x, marker.global_position.z, -marker.global_basis.z)
	assert_true(
		await walk_keys_until(
			[KEY_S], func() -> bool: return WorldManager.current_map() == ENTREPOT, 8.0
		),
		"retour à l'entrepôt"
	)
	release_all_input()
	assert_true(await wait_transition(), "arrivée à l'entrepôt")
	assert_eq(WorldManager.current_map(), ENTREPOT)
	assert_lt(distance_to(_map().marker(&"from_colline")), 0.3, "posé sur from_colline")


func test_by_day_from_the_warehouse_to_the_hill_the_summit_and_back() -> void:
	await _enter_entrepot(&"matin")
	assert_eq(Atmosphere.preset_id(), &"matin", "l'entrepôt suit le moment")
	await _walk_to_the_hill()
	assert_eq(GameState.moment, &"matin", "c'est toujours le matin pour le monde")
	assert_eq(Atmosphere.preset_id(), &"nuit", "mais la colline est de nuit")
	assert_gt(Atmosphere.current().night_amount, 0.9, "la nuit claire")
	await _climb_to_the_summit()
	await _stop_at_the_rim()
	await _walk_back_to_the_warehouse()
	assert_eq(Atmosphere.preset_id(), &"matin", "l'entrepôt retrouve la lumière du matin")


func test_by_night_from_the_warehouse_to_the_hill_the_summit_and_back() -> void:
	await _enter_entrepot(&"nuit")
	assert_eq(Atmosphere.preset_id(), &"nuit")
	await _walk_to_the_hill()
	assert_eq(Atmosphere.preset_id(), &"nuit", "la nuit claire")
	assert_true(Atmosphere.is_player_light_on(), "la lumière des fées du joueur est allumée")
	await _climb_to_the_summit()
	# Les points de la scène de l'acte 1 (8.8) : on marche jusqu'au cristal, et l'on s'y arrête.
	var centre := _map().get_node(^"Life/Places/talismans_centre") as Marker3D
	await put_player(centre.global_position.x, centre.global_position.z + 3.0, Vector3.FORWARD)
	assert_true(
		await walk_keys_until(
			[KEY_W],
			func() -> bool: return player.global_position.z < centre.global_position.z + 0.5,
			4.0
		),
		"jusqu'au cristal"
	)
	release_all_input()
	assert_lt(
		Vector2(player.global_position.x, player.global_position.z).distance_to(
			Vector2(centre.global_position.x, centre.global_position.z)
		),
		1.2,
		"au centre du cercle"
	)
	await _walk_back_to_the_warehouse()
