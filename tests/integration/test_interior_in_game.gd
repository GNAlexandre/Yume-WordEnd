extends "res://tests/stubs/m2_game_test.gd"
## (E3) L'intérieur d'essai dans la vraie partie (game.tscn, WorldManager du lot E1) : on y
## arrive (lumière « interieur », caméra bornée, coupe sur la limite au sud du joueur), on marche
## de l'entrée au couloir (la coupe passe à la limite suivante), on ressort par la porte d'entrée
## en marchant (sortie vers la carte héritée), et rien ne reste de l'intérieur (étalonnage du
## dehors, carte libérée).

const INTERIOR := &"entrepot_rdc_essai"

var _previous_fade: float


func before_each() -> void:
	super()
	_previous_fade = WorldManager.fade_time
	WorldManager.fade_time = 0.0


func after_each() -> void:
	WorldManager.fade_time = _previous_fade
	super()


func _post(parameter: StringName) -> Variant:
	var screen := player.camera_rig.get_node(^"PostFX/Screen") as CanvasItem
	return (screen.material as ShaderMaterial).get_shader_parameter(parameter)


func _room() -> InteriorRoom:
	return WorldManager.current_map_node().get_node(^"Ground") as InteriorRoom


func test_walk_in_the_interior_and_out_by_the_front_door() -> void:
	assert_true(await new_game_from_menu(), "partie lancée depuis le menu")
	await WorldManager.go_to(INTERIOR)
	assert_true(
		await until(func() -> bool: return not WorldManager.is_transitioning(), 10.0), "arrivée"
	)
	var map := WorldManager.current_map_node()
	assert_eq(map.map_id(), INTERIOR)
	var map_ref: WeakRef = weakref(map)
	assert_lt(distance_to(map.spawn()), 0.3, "posé au Spawn, dans l'entrée")
	assert_eq(player.camera_rig.limits, map.bounds(), "caméra bornée à l'étage")
	# (R1) La lumière d'Atmosphere : le préréglage « interieur » sous le moment du dehors.
	assert_null(map.get_node_or_null(^"Light"), "la carte ne porte aucune lumière")
	assert_eq(Atmosphere.preset_id(), HD2DLighting.INTERIOR, "préréglage des intérieurs")
	var inside := Atmosphere.resolve()
	assert_almost_eq(float(_post(&"vignette")), inside.vignette, 0.001, "étalonnage intérieur")
	var room := _room()
	assert_almost_eq(room.lamp_energy, inside.lamp_energy, 0.001, "lampes de la pièce")
	await frames(2)
	assert_eq(room.cut_line(), 21.0, "dans l'entrée : coupe sur son mur sud")
	# La nuit tombe dehors : les fenêtres s'éteignent, les lampes s'allument, Chtholly se teinte.
	var day_windows := room.window_energy
	var moment := GameState.moment
	Atmosphere.set_moment(&"nuit", 0.0)
	await frames(2)
	assert_lt(room.window_energy, day_windows, "fenêtres de nuit")
	assert_gt(room.lamp_energy, inside.lamp_energy, "lampes de nuit")
	var sprite := player.get_node(^"Visual/Sprite") as AnimatedSprite3D
	var tint := HD2DLighting.active_sprite_tint()
	assert_ne(tint, Color.WHITE, "teinte de la nuit")
	assert_true(
		sprite.modulate.is_equal_approx(Color(tint.r, tint.g, tint.b)),
		"Chtholly teintée : %s (%s)" % [sprite.modulate, tint]
	)
	Atmosphere.set_moment(moment, 0.0)
	await frames(2)
	# Vers le nord, par l'arche de l'entrée, jusque dans le couloir.
	assert_true(
		await walk_keys_until([KEY_W], func() -> bool: return player.global_position.z < 12.4, 6.0),
		"de l'entrée au couloir"
	)
	release_all_input()
	assert_true(
		await until(func() -> bool: return room.cut_line() == 13.0, 2.0),
		"dans le couloir : la coupe a glissé sur la limite sud du couloir"
	)
	# Retour au sud, puis dehors par la porte d'entrée (sortie franchie en marchant).
	assert_true(
		await walk_keys_until(
			[KEY_S], func() -> bool: return WorldManager.current_map() != INTERIOR, 8.0
		),
		"sortie par la porte d'entrée"
	)
	release_all_input()
	assert_true(
		await until(func() -> bool: return not WorldManager.is_transitioning(), 10.0), "dehors"
	)
	assert_eq(WorldManager.current_map(), &"essai", "dehors, sur la carte d'essai")
	await frames(2)
	assert_null(map_ref.get_ref(), "l'intérieur est libéré")
	# (R1) Dehors, la lumière du moment (celle de l'île au couchant), plus celle de l'intérieur.
	var outside := HD2DLighting.preset(GameState.moment)
	assert_eq(Atmosphere.preset_id(), GameState.moment, "préréglage du moment")
	assert_almost_eq(float(_post(&"vignette")), outside.vignette, 0.001, "étalonnage du dehors")
	assert_ne(outside.vignette, inside.vignette, "il a changé")
	assert_eq(HD2DLighting.active_sprite_tint(), outside.sprite_tint, "personnages du dehors")
