extends GutTest
## (R1) Le raccord de la lumière : une seule lumière, celle d'Atmosphere (src/autoload/
## atmosphere.gd, HD2DLightTargets), pour ce que E3, E2 et les personnages éclairaient à part :
## - un intérieur (InteriorRoom) suit le moment du dehors, transitions comprises : le jour des
##   fenêtres (window_light, window_tint du moment) et ses lampes, cheminées et cristaux
##   (lamp_energy, part de nuit) ; la carte ne porte aucune lumière, le moteur n'en ajoute
##   aucune (pas de draw call de plus) ; dedans, la pluie ne fait que baisser les fenêtres ;
## - le sol en relief (MapGround) reçoit la direction du soleil ou de la lune, à l'arrivée et
##   pendant une transition ; une seule mer de nuages (celle de MapGround) ;
## - un personnage (CharacterVisual) est teinté la nuit, pas au couchant, dehors comme dedans,
##   par-dessus la couleur que lui donne son ennemi (EnemyData.tint).
## La luminance des vues (nuit lisible et nettement différente du jour) est mesurée par
## tests/integration/test_e9_captures.gd (rendu réel, sous Xvfb).

const INTERIOR_MAP := &"entrepot_rdc_essai"
const RELIEF_MAP := &"essai_relief"
const OUTDOOR_MAP := &"essai"
const VISUAL := preload("res://src/visuals/character_visual.tscn")
## Devant la fenêtre du réfectoire (x = 8,5, mur nord à z = 2) et sous une de ses lampes.
const UNDER_WINDOW := Vector3(8.5, 0.0, 2.6)
const UNDER_LAMP := Vector3(5.3, 0.0, 6.0)

var _map: Map


func before_each() -> void:
	GameState.reset()
	Atmosphere.transition_time = Atmosphere.DEFAULT_TRANSITION_TIME


func after_each() -> void:
	Atmosphere.dress(null)
	if is_instance_valid(_map):
		_map.free()
	_map = null
	GameState.reset()


func _load(map_id: StringName) -> Map:
	_map = (load(Map.scene_path(map_id)) as PackedScene).instantiate() as Map
	add_child(_map)
	Atmosphere.dress(_map)
	return _map


func _room() -> InteriorRoom:
	return _map.get_node(^"Ground") as InteriorRoom


## Ce qu'un intérieur doit recevoir sous moment (au clair) : le préréglage « interieur ».
func _inside(moment: StringName) -> HD2DLighting:
	return Atmosphere.resolve(_map, moment, &"clair")


# --- Intérieurs ------------------------------------------------------------------------------


func test_interior_follows_the_moment_and_its_transitions() -> void:
	_load(INTERIOR_MAP)
	var room := _room()
	Atmosphere.set_moment(&"matin", 0.0)
	var morning := HD2DLighting.preset(&"matin")
	assert_eq(Atmosphere.preset_id(), HD2DLighting.INTERIOR, "préréglage des intérieurs")
	assert_eq(Atmosphere.targets().rooms, [room] as Array[InteriorRoom], "la pièce est relevée")
	assert_almost_eq(room.window_energy, morning.window_light, 0.001, "jour des fenêtres du matin")
	assert_eq(room.window_tint, morning.window_tint, "couleur du matin")
	assert_almost_eq(room.lamp_energy, _inside(&"matin").lamp_energy, 0.001, "lampes du jour")
	var surface := room.surfaces()[0].material_override as ShaderMaterial
	assert_almost_eq(
		float(surface.get_shader_parameter(&"window_energy")), room.window_energy, 0.001
	)
	var window_day := room.light_at(UNDER_WINDOW)
	var lamp_day := room.light_at(UNDER_LAMP)
	assert_gt(window_day.r, 1.0, "le jour : une flaque de soleil devant la fenêtre")
	# Vers la nuit, en 2 s : à mi-chemin, entre les deux.
	var night := HD2DLighting.preset(&"nuit")
	Atmosphere.set_moment(&"nuit", 2.0)
	Atmosphere.step(1.0)
	assert_true(Atmosphere.is_transitioning(), "transition en cours")
	assert_between(
		room.window_energy, night.window_light + 0.01, morning.window_light - 0.01, "fenêtres"
	)
	assert_between(
		room.lamp_energy,
		_inside(&"matin").lamp_energy + 0.01,
		_inside(&"nuit").lamp_energy - 0.01,
		"lampes"
	)
	Atmosphere.step(1.5)
	assert_false(Atmosphere.is_transitioning(), "transition finie")
	assert_almost_eq(room.window_energy, night.window_light, 0.001, "la nuit aux fenêtres")
	assert_eq(room.window_tint, night.window_tint, "bleutée")
	var night_inside := HD2DLighting.preset(HD2DLighting.INTERIOR_NIGHT)
	assert_almost_eq(room.lamp_energy, night_inside.lamp_energy, 0.001, "lampes de la nuit")
	assert_lt(room.window_energy, morning.window_light * 0.5, "fenêtres sombres")
	assert_gt(room.lamp_energy, _inside(&"matin").lamp_energy * 4.0, "lampes allumées")
	var window_night := room.light_at(UNDER_WINDOW)
	assert_lt(window_night.r, window_day.r * 0.5, "moins de jour devant la fenêtre")
	assert_gt(window_night.b, window_night.r, "un peu de lune, bleue")
	assert_gt(room.light_at(UNDER_LAMP).r, lamp_day.r * 3.0, "une flaque sous la lampe")
	assert_almost_eq(float(surface.get_shader_parameter(&"lamp_energy")), room.lamp_energy, 0.001)


func test_interior_carries_no_light_of_its_own() -> void:
	var map := _load(INTERIOR_MAP)
	var rig := Atmosphere.rig()
	for node: Node in map.find_children("*", "Light3D", true, false):
		assert_true(rig.is_ancestor_of(node), "%s : seule la lumière d'Atmosphere" % node.name)
	for node: Node in map.find_children("*", "WorldEnvironment", true, false):
		assert_true(rig.is_ancestor_of(node), "%s : l'environnement d'Atmosphere" % node.name)
	assert_null(map.get_node_or_null(^"Light"), "plus de nœud Light (interior_light.tscn)")
	assert_false(ResourceLoader.exists("res://src/world/interior_light.tscn"), "retirée")
	assert_eq(Atmosphere.targets().counts()["lamps"], 0, "aucune lumière ponctuelle dans la carte")
	assert_false(rig.player_light.visible, "pas de lumière du joueur dedans")
	var environment := Atmosphere.targets().environment
	assert_eq(environment.background_mode, Environment.BG_COLOR, "fond uni : aucun ciel")
	assert_eq(environment.background_color, InteriorRoom.VOID_COLOR, "le vide autour du bâtiment")
	# La lueur des vitres et des lampes suit la pièce (window_energy, lamp_energy), pas le
	# window_glow des panneaux du dehors : elle n'est pas multipliée deux fois.
	Atmosphere.set_moment(&"nuit", 0.0)
	var window := _room().get_node(^"Panel_window_cross_large") as MeshInstance3D
	var material := window.material_override as ShaderMaterial
	assert_almost_eq(
		float(material.get_shader_parameter(&"glow_strength")), InteriorRoom.WINDOW_GLOW, 0.001
	)
	assert_does_not_have(Atmosphere.targets().glow_materials, material, "lueur de la pièce")


func test_weather_only_dims_the_windows_inside() -> void:
	_load(INTERIOR_MAP)
	var room := _room()
	Atmosphere.set_atmosphere(&"matin", &"averse", 0.0)
	var morning := HD2DLighting.preset(&"matin")
	var shower := HD2DWeather.preset(&"averse")
	assert_almost_eq(
		room.window_energy, morning.window_light * shower.window_light_scale, 0.001, "averse"
	)
	assert_almost_eq(room.lamp_energy, _inside(&"matin").lamp_energy, 0.001, "lampes inchangées")
	assert_false(Atmosphere.is_raining(), "il ne pleut pas dedans")


func test_old_day_phases_reach_the_interior_through_the_moment() -> void:
	_load(INTERIOR_MAP)
	var room := _room()
	room.apply_phase(&"night")
	assert_eq(GameState.moment, &"nuit", "ancienne phase : le moment d'Atmosphere")
	assert_false(Atmosphere.is_transitioning(), "tout de suite")
	assert_almost_eq(room.window_energy, HD2DLighting.preset(&"nuit").window_light, 0.001)
	EventBus.day_phase_changed.emit(&"morning")
	Atmosphere.step(Atmosphere.transition_time + 1.0)
	assert_almost_eq(room.window_energy, HD2DLighting.preset(&"matin").window_light, 0.001)
	room.apply_phase(&"inconnue")
	assert_eq(GameState.moment, &"matin", "phase inconnue : rien")


# --- Sol en relief ---------------------------------------------------------------------------


func _toward_sun(ground: MapGround) -> Vector3:
	var material := ground.ground_mesh().surface_get_material(0) as ShaderMaterial
	return material.get_shader_parameter(&"toward_sun")


func test_map_ground_follows_the_sun_of_the_moment() -> void:
	_load(RELIEF_MAP)
	var ground := _map.get_node(^"Ground") as MapGround
	assert_eq(Atmosphere.targets().grounds, [ground] as Array[MapGround], "le sol est relevé")
	var sunset := HD2DLighting.preset(&"couchant")
	assert_true(_toward_sun(ground).is_equal_approx(sunset.toward_sun()), "à l'arrivée : couchant")
	Atmosphere.set_moment(&"matin", 0.0)
	var morning := HD2DLighting.preset(&"matin").toward_sun()
	assert_true(_toward_sun(ground).is_equal_approx(morning), "le soleil du matin, à l'est")
	# Vers la nuit : la direction tourne pendant la transition, jusqu'à la lune.
	var moon := HD2DLighting.preset(&"nuit").toward_sun()
	Atmosphere.set_moment(&"nuit", 2.0)
	Atmosphere.step(1.0)
	var halfway := _toward_sun(ground)
	assert_false(halfway.is_equal_approx(morning), "elle a bougé")
	assert_false(halfway.is_equal_approx(moon), "pas encore la lune")
	Atmosphere.step(1.5)
	assert_true(_toward_sun(ground).is_equal_approx(moon), "la lune")
	# La mer de nuages : celle du sol, la seule, réglée par Atmosphere (côté de la lune).
	assert_eq(Atmosphere.targets().counts()["clouds"], 1, "une seule mer de nuages relevée")
	var sea := ground.find_children("CloudSea", "MeshInstance3D", true, false)
	assert_eq(sea.size(), 1, "celle de MapGround")
	var seas := 0
	for node: Node in _map.find_children("*", "MeshInstance3D", true, false):
		var mesh := (node as MeshInstance3D).mesh
		if mesh == null or mesh.get_surface_count() == 0:
			continue
		var material := (node as MeshInstance3D).get_active_material(0) as ShaderMaterial
		if material != null and material.shader == HD2DLightTargets.CLOUD_SEA_SHADER:
			seas += 1
	assert_eq(seas, 1, "Atmosphere n'en ajoute pas : pas de seconde mer de nuages")
	var clouds := (sea[0] as MeshInstance3D).get_active_material(0) as ShaderMaterial
	var flat := Vector2(moon.x, moon.z).normalized()
	var side: Vector2 = clouds.get_shader_parameter(&"sun_direction")
	assert_true(side.is_equal_approx(flat), "côté de la lune : %s" % side)


func test_set_sun_reaches_the_cloud_sea_drawn() -> void:
	_load(RELIEF_MAP)
	var ground := _map.get_node(^"Ground") as MapGround
	ground.set_sun(Vector3(1.0, 1.0, 0.0))
	var sea := ground.find_children("CloudSea", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var clouds := sea.get_active_material(0) as ShaderMaterial
	assert_eq(clouds, sea.material_override, "la copie qu'Atmosphere règle")
	assert_true(
		(clouds.get_shader_parameter(&"sun_direction") as Vector2).is_equal_approx(Vector2.RIGHT)
	)
	assert_true(_toward_sun(ground).is_equal_approx(Vector3(1.0, 1.0, 0.0).normalized()))


# --- Personnages ------------------------------------------------------------------------------


func _sprite(visual: Node) -> AnimatedSprite3D:
	return visual.get_node(^"Sprite") as AnimatedSprite3D


func _rgb(color: Color) -> Color:
	return Color(color.r, color.g, color.b)


func test_characters_are_tinted_at_night_not_at_sunset() -> void:
	_load(OUTDOOR_MAP)
	var visual := VISUAL.instantiate() as CharacterVisual
	_map.add_child(visual)
	visual.set_skin(SkinRegistry.default_skin())
	await wait_process_frames(2)
	assert_eq(_sprite(visual).modulate, Color.WHITE, "au couchant : au naturel")
	Atmosphere.set_moment(&"nuit", 0.0)
	await wait_process_frames(2)
	var night := HD2DLighting.preset(&"nuit").sprite_tint
	assert_ne(night, Color.WHITE)
	assert_eq(_sprite(visual).modulate, _rgb(night), "la nuit : plus sombre, bleutée")
	# Par-dessus la couleur d'un ennemi (EnemyData.tint), posée sur le sprite.
	_sprite(visual).modulate = Color(1.0, 0.5, 0.5)
	await wait_process_frames(2)
	assert_true(
		_sprite(visual).modulate.is_equal_approx(Color(1.0, 0.5, 0.5) * _rgb(night)),
		"ennemi la nuit"
	)
	Atmosphere.set_moment(&"couchant", 0.0)
	await wait_process_frames(2)
	assert_true(
		_sprite(visual).modulate.is_equal_approx(Color(1.0, 0.5, 0.5)), "sa couleur revient"
	)
	# Pendant une transition, la teinte suit le mélange.
	Atmosphere.set_moment(&"nuit", 2.0)
	Atmosphere.step(1.0)
	await wait_process_frames(2)
	var red := _sprite(visual).modulate.r
	assert_true(red < 1.0 and red > night.r, "à mi-chemin : %s" % red)
	# Plus de carte (retour au menu) : au naturel.
	visual.reparent(self)
	_map.free()
	await wait_process_frames(3)
	assert_null(Atmosphere.current(), "plus de réglage")
	assert_true(_sprite(visual).modulate.is_equal_approx(Color(1.0, 0.5, 0.5)), "sans carte")
	visual.free()


func test_characters_are_tinted_inside_at_night() -> void:
	_load(INTERIOR_MAP)
	var visual := VISUAL.instantiate() as CharacterVisual
	_map.add_child(visual)
	Atmosphere.set_moment(&"nuit", 0.0)
	await wait_process_frames(2)
	var tint := _inside(&"nuit").sprite_tint
	assert_ne(tint, Color.WHITE, "dedans la nuit, une teinte aussi")
	assert_true(_sprite(visual).modulate.is_equal_approx(_rgb(tint)), "dedans, la nuit")
	Atmosphere.set_moment(&"apres_midi", 0.0)
	await wait_process_frames(2)
	assert_eq(_sprite(visual).modulate, Color.WHITE, "dedans, le jour : au naturel")
