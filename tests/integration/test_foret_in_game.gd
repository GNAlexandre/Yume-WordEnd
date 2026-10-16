extends "res://tests/stubs/m2_game_test.gd"
## (CF) La forêt profonde dans la vraie partie (main.tscn, appuis réels) : de l'entrepôt à la forêt
## par la sortie sud à pied, de jour et de nuit (on arrive sur from_entrepot, au haut du sentier) ;
## la forêt suit le moment (pas de préréglage propre) ; on descend le sentier jusqu'à la rivière
## et on la passe au gué à pied, sans sauter (le lit est au ras du sol) ; on marche jusqu'au refuge
## de Chtholly, devant le chêne creux ; puis le retour à l'entrepôt par le sentier du nord, sur
## from_foret_profonde.

const ENTREPOT := &"entrepot"
const FORET := &"foret_profonde"

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


## De l'entrepôt à la forêt, à pied : depuis le marqueur de la sortie sud, vers le sud.
func _walk_into_the_forest() -> void:
	var marker := _map().marker(&"from_foret_profonde")
	await put_player(marker.global_position.x, marker.global_position.z, -marker.global_basis.z)
	assert_true(
		await walk_keys_until(
			[KEY_S], func() -> bool: return WorldManager.current_map() == FORET, 8.0
		),
		"de l'entrepôt à la forêt"
	)
	release_all_input()
	assert_true(await wait_transition(), "arrivée dans la forêt")
	await frames(4)
	assert_eq(WorldManager.current_map(), FORET)
	assert_lt(distance_to(_map().marker(&"from_entrepot")), 0.3, "posé sur from_entrepot")
	assert_eq(WorldManager.map_display_name(FORET), "La forêt profonde")
	assert_eq(player.camera_rig.limits, _map().bounds(), "caméra bornée à la carte")


## Du haut du sentier à la rive nord de la rivière, puis le gué : on passe de l'autre côté sans
## sauter.
func _cross_the_ford() -> void:
	await put_player(40.0, 12.0, Vector3.BACK)
	assert_true(
		await walk_keys_until([KEY_S], func() -> bool: return player.global_position.z > 20.0, 8.0),
		"le sentier jusqu'à la rivière"
	)
	release_all_input()
	await put_player(44.4, 22.5, Vector3.BACK)
	assert_true(
		await walk_keys_until([KEY_S], func() -> bool: return player.global_position.z > 31.0, 8.0),
		"le gué : d'une rive à l'autre"
	)
	release_all_input()
	await until(func() -> bool: return player.is_on_floor(), 2.0)
	assert_almost_eq(player.global_position.y, 0.0, 0.08, "le lit est au ras du sol")
	assert_eq(WorldManager.current_map(), FORET, "toujours dans la forêt")


## Du bout du sentier de l'ouest, la place du refuge : on arrive devant le chêne creux.
func _walk_to_the_refuge() -> void:
	var hollow := _map().get_node(^"Life/Places/refuge_creux") as Marker3D
	await put_player(24.0, 40.6, Vector3.LEFT)
	assert_true(
		await walk_keys_until(
			[KEY_A],
			func() -> bool:
				return (
					Vector2(player.global_position.x, player.global_position.z).distance_to(
						Vector2(hollow.global_position.x, hollow.global_position.z)
					)
					< 3.5
				),
			10.0
		),
		"jusqu'au creux du chêne"
	)
	release_all_input()
	assert_between(player.global_position.x, 12.0, 20.0, "devant le chêne")


func _walk_back_to_the_warehouse() -> void:
	var marker := _map().marker(&"from_entrepot")
	await put_player(marker.global_position.x, marker.global_position.z, -marker.global_basis.z)
	assert_true(
		await walk_keys_until(
			[KEY_W], func() -> bool: return WorldManager.current_map() == ENTREPOT, 8.0
		),
		"retour à l'entrepôt"
	)
	release_all_input()
	assert_true(await wait_transition(), "arrivée à l'entrepôt")
	assert_eq(WorldManager.current_map(), ENTREPOT)
	assert_lt(
		distance_to(_map().marker(&"from_foret_profonde")), 0.3, "posé sur from_foret_profonde"
	)


func test_by_day_from_the_warehouse_to_the_refuge_across_the_ford_and_back() -> void:
	await _enter_entrepot(&"matin")
	assert_eq(Atmosphere.preset_id(), &"matin", "l'entrepôt suit le moment")
	await _walk_into_the_forest()
	assert_eq(Atmosphere.preset_id(), &"matin", "la forêt suit le moment du monde")
	await _cross_the_ford()
	await _walk_to_the_refuge()
	await _walk_back_to_the_warehouse()


func test_by_night_the_forest_is_dark_and_the_fairies_light_the_way() -> void:
	await _enter_entrepot(&"nuit")
	await _walk_into_the_forest()
	assert_eq(Atmosphere.preset_id(), &"nuit", "la forêt suit la nuit")
	assert_true(Atmosphere.is_player_light_on(), "la lumière des fées du joueur est allumée")
	await _cross_the_ford()
	await _walk_back_to_the_warehouse()
