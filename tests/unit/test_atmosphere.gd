extends "res://tests/stubs/l8_save_test.gd"
## (E9) La lumière et le temps (src/autoload/atmosphere.gd, data/lighting/) : chaque préréglage
## (moment × temps) s'applique et se sauvegarde, les transitions se font en douceur ou d'un coup,
## le light_preset d'une carte l'emporte, un intérieur suit le moment du dehors, la lumière du
## joueur s'allume la nuit dehors et s'éteint dedans ou le jour, la pluie tombe puis s'arrête et
## le sol sèche, les images de nuit et les vitres éclairées suivent la nuit, la lueur des
## fenêtres suit le préréglage, les raccourcis de développement. La luminance des captures est
## vérifiée par tests/integration/test_e9_captures.gd (rendu réel, sous Xvfb).

## Carte d'essai, chargée à chaque test (jamais préchargée : une carte en cache resterait en
## mémoire pendant toute la suite, test_m2_maps.gd le vérifie).
const MAP_ID := &"essai"
const PANEL_SHADER := preload("res://src/world/shaders/panel.gdshader")
const WINDOW := preload("res://tests/data/lighting/window_e9.png")
const WINDOW_NIGHT := preload("res://tests/data/lighting/window_e9_night.png")
const WINDOW_LIT := preload("res://tests/data/lighting/window_lit_e9.png")

var _map: Map


func before_each() -> void:
	super.before_each()
	Atmosphere.transition_time = Atmosphere.DEFAULT_TRANSITION_TIME
	Atmosphere.player_light_mode = Atmosphere.LIGHT_AUTO
	_map = (load(Map.scene_path(MAP_ID)) as PackedScene).instantiate() as Map
	add_child(_map)
	Atmosphere.dress(_map)


func after_each() -> void:
	Atmosphere.dress(null)
	if is_instance_valid(_map):
		_map.free()
	Atmosphere.transition_time = Atmosphere.DEFAULT_TRANSITION_TIME
	Atmosphere.player_light_mode = Atmosphere.LIGHT_AUTO
	super.after_each()


func _sun() -> DirectionalLight3D:
	return Atmosphere.targets().sun


func _environment() -> Environment:
	return Atmosphere.targets().environment


## Le préréglage attendu pour moment et temps dehors (sans passer par Atmosphere).
func _expected(moment: StringName, weather: StringName) -> HD2DLighting:
	var base := HD2DLighting.preset(moment)
	var modifier := HD2DWeather.preset(weather)
	return modifier.applied_to(base, true) if modifier != null else base


# --- Préréglages ------------------------------------------------------------------------------


func test_every_moment_weather_and_interior_has_its_preset() -> void:
	for moment: StringName in GameState.MOMENTS:
		assert_not_null(HD2DLighting.preset(moment), "moment %s" % moment)
	assert_null(HD2DWeather.preset(&"clair"), "le clair ne change rien")
	for weather: StringName in [&"pluie", &"averse"]:
		assert_not_null(HD2DWeather.preset(weather), "temps %s" % weather)
	assert_not_null(HD2DLighting.preset(HD2DLighting.INTERIOR), "intérieur de jour")
	assert_not_null(HD2DLighting.preset(HD2DLighting.INTERIOR_NIGHT), "intérieur de nuit")
	assert_eq(GameState.moment, &"couchant", "nouvelle partie : le couchant")
	assert_eq(GameState.weather, &"clair", "sans pluie")
	var night := HD2DLighting.preset(&"nuit")
	var sunset := HD2DLighting.preset(&"couchant")
	assert_lt(night.sun_energy, sunset.sun_energy, "la nuit est plus sombre")
	assert_gt(night.lamp_energy, sunset.lamp_energy, "les lanternes portent la nuit")
	assert_gt(night.window_glow, sunset.window_glow, "les fenêtres s'allument")
	assert_gt(night.ambient_energy, 0.4, "jamais noire : l'ambiance reste")
	assert_eq(night.player_light, 1.0, "la lumière des fées, la nuit")
	for moment: StringName in [&"aube", &"matin", &"apres_midi", &"couchant"]:
		assert_eq(HD2DLighting.preset(moment).player_light, 0.0, "pas de lumière au %s" % moment)


func test_each_preset_applies_and_is_saved() -> void:
	for moment: StringName in GameState.MOMENTS:
		for weather: StringName in GameState.WEATHERS:
			var label := "%s, %s" % [moment, weather]
			Atmosphere.set_atmosphere(moment, weather, 0.0)
			assert_false(Atmosphere.is_transitioning(), "%s : tout de suite" % label)
			var want := _expected(moment, weather)
			assert_eq(Atmosphere.preset_id(), moment, label)
			assert_almost_eq(_sun().light_energy, want.sun_energy, 0.001, "%s : soleil" % label)
			assert_eq(_sun().light_color, want.sun_color, "%s : couleur du soleil" % label)
			assert_eq(
				_environment().ambient_light_color, want.ambient_color, "%s : ambiance" % label
			)
			assert_almost_eq(_environment().fog_density, want.fog_density, 0.00001, label)
			assert_almost_eq(
				Atmosphere.rig().rain.intensity, want.rain, 0.001, "%s : pluie" % label
			)
			assert_eq(Atmosphere.sprite_tint(), want.sprite_tint, "%s : personnages" % label)
			var saved := GameState.to_dict()
			assert_eq(saved["moment"], String(moment), "%s : moment écrit" % label)
			assert_eq(saved["weather"], String(weather), "%s : temps écrit" % label)
	# Aller-retour par le fichier : la partie reprend sous la même lumière, sans transition.
	Atmosphere.set_atmosphere(&"nuit", &"averse", 0.0)
	assert_eq(SaveManager.save(), OK)
	Atmosphere.set_atmosphere(&"matin", &"clair", 0.0)
	assert_eq(SaveManager.load_game(), OK)
	assert_eq(GameState.moment, &"nuit", "moment relu")
	assert_eq(GameState.weather, &"averse", "temps relu")
	assert_false(Atmosphere.is_transitioning(), "partie chargée : tout de suite")
	var night_rain := _expected(&"nuit", &"averse")
	assert_almost_eq(_sun().light_energy, night_rain.sun_energy, 0.001, "lumière relue")
	assert_true(Atmosphere.is_raining(), "il pleut encore")


func test_old_or_tampered_saves_fall_back_to_the_sunset() -> void:
	GameState.from_dict({"moment": "minuit", "weather": 3})
	assert_eq(GameState.moment, &"couchant", "moment inconnu")
	assert_eq(GameState.weather, &"clair", "temps illisible")
	GameState.from_dict({"moment": "aube", "weather": "pluie"})
	assert_eq(GameState.moment, &"aube")
	GameState.from_dict({})
	assert_eq(GameState.moment, &"couchant", "sauvegarde d'avant E9")
	assert_eq(GameState.weather, &"clair")
	GameState.moment = &"minuit"
	assert_eq(GameState.moment, &"couchant", "un moment inconnu est refusé")


func test_changes_are_announced_on_the_event_bus() -> void:
	watch_signals(EventBus)
	Atmosphere.set_moment(&"matin", 0.0)
	assert_signal_emitted_with_parameters(EventBus, "atmosphere_changed", [&"matin", &"clair"])
	Atmosphere.set_weather(&"pluie", 0.0)
	assert_signal_emitted_with_parameters(EventBus, "atmosphere_changed", [&"matin", &"pluie"])
	var count: int = get_signal_emit_count(EventBus, "atmosphere_changed")
	Atmosphere.set_weather(&"pluie", 0.0)
	assert_signal_emit_count(EventBus, "atmosphere_changed", count, "rien ne change")


# --- Transitions ------------------------------------------------------------------------------


func test_transition_is_gradual_then_exact() -> void:
	Atmosphere.set_atmosphere(&"couchant", &"clair", 0.0)
	var sunset := _expected(&"couchant", &"clair")
	var night := _expected(&"nuit", &"clair")
	watch_signals(Atmosphere)
	Atmosphere.set_moment(&"nuit", 2.0)
	assert_true(Atmosphere.is_transitioning(), "transition en cours")
	assert_eq(GameState.moment, &"nuit", "le moment change tout de suite")
	assert_almost_eq(_sun().light_energy, sunset.sun_energy, 0.001, "rien n'a bougé encore")
	Atmosphere.step(1.0)
	var middle := _sun().light_energy
	assert_lt(middle, sunset.sun_energy - 0.01, "le soleil baisse")
	assert_gt(middle, night.sun_energy + 0.01, "la lune n'est pas encore là")
	assert_almost_eq(Atmosphere.transition_progress(), 0.5, 0.01)
	var sky := Atmosphere.targets().sky_material
	var blend: float = sky.get_shader_parameter(&"blend")
	assert_true(blend > 0.0 and blend < 1.0, "les deux ciels se fondent : %s" % blend)
	assert_eq(sky.get_shader_parameter(&"panorama"), night.sky_image(), "vers le ciel étoilé")
	assert_signal_not_emitted(Atmosphere, "preset_applied")
	Atmosphere.step(1.1)
	assert_false(Atmosphere.is_transitioning(), "transition finie")
	assert_almost_eq(_sun().light_energy, night.sun_energy, 0.001, "la lune")
	assert_eq(_environment().ambient_light_color, night.ambient_color)
	assert_eq(sky.get_shader_parameter(&"blend"), 1.0, "un seul ciel")
	assert_signal_emitted_with_parameters(Atmosphere, "preset_applied", [&"nuit"])


func test_transition_time_and_immediate_changes() -> void:
	Atmosphere.transition_time = 3.0
	Atmosphere.set_moment(&"matin")
	assert_true(Atmosphere.is_transitioning(), "durée par défaut")
	Atmosphere.step(1.5)
	assert_almost_eq(Atmosphere.transition_progress(), 0.5, 0.01, "transition_time")
	# Un changement en cours de transition repart de la lumière du moment.
	var halfway := _sun().light_energy
	Atmosphere.set_moment(&"apres_midi", 0.0)
	assert_false(Atmosphere.is_transitioning(), "0 s : tout de suite")
	assert_ne(_sun().light_energy, halfway)
	assert_almost_eq(
		_sun().light_energy, _expected(&"apres_midi", &"clair").sun_energy, 0.001, "après-midi"
	)
	# GameState changé directement (récit, chargement d'une ancienne phase) : transition par
	# défaut.
	GameState.moment = &"aube"
	assert_true(Atmosphere.is_transitioning(), "GameState.moment = … : transition")
	Atmosphere.step(10.0)
	assert_almost_eq(_sun().light_energy, _expected(&"aube", &"clair").sun_energy, 0.001)


func test_old_day_phases_give_their_moment() -> void:
	EventBus.day_phase_changed.emit(&"night")
	assert_eq(GameState.moment, &"nuit")
	Atmosphere.step(10.0)
	assert_almost_eq(_sun().light_energy, _expected(&"nuit", &"clair").sun_energy, 0.001)
	EventBus.day_phase_changed.emit(&"morning")
	assert_eq(GameState.moment, &"matin")
	EventBus.day_phase_changed.emit(&"evening")
	assert_eq(GameState.moment, &"couchant")
	EventBus.day_phase_changed.emit(&"day")
	assert_eq(GameState.moment, &"apres_midi")


# --- Cartes : la carte l'emporte, les intérieurs ---------------------------------------------


func test_map_preset_wins_over_the_moment() -> void:
	Atmosphere.set_moment(&"matin", 0.0)
	_map.light_preset = &"nuit"
	Atmosphere.dress(_map)
	assert_eq(Atmosphere.preset_id(), &"nuit", "la carte l'emporte")
	assert_almost_eq(_sun().light_energy, _expected(&"nuit", &"clair").sun_energy, 0.001)
	Atmosphere.set_moment(&"apres_midi", 0.0)
	assert_eq(Atmosphere.preset_id(), &"nuit", "le moment change, la carte reste la nuit")
	assert_true(Atmosphere.is_player_light_on(), "nuit de la carte : la lumière du joueur")
	# Le temps qu'il fait s'ajoute au préréglage de la carte, dehors.
	Atmosphere.set_weather(&"averse", 0.0)
	assert_almost_eq(_sun().light_energy, _expected(&"nuit", &"averse").sun_energy, 0.001)
	assert_true(Atmosphere.is_raining())
	_map.light_preset = &""
	Atmosphere.dress(_map)
	assert_eq(Atmosphere.preset_id(), &"apres_midi", "carte sans préréglage : le moment")


func test_interior_follows_the_moment_outside() -> void:
	_map.interior = true
	Atmosphere.set_atmosphere(&"apres_midi", &"averse", 0.0)
	Atmosphere.dress(_map)
	assert_eq(Atmosphere.preset_id(), HD2DLighting.INTERIOR, "carte intérieure")
	assert_false(Atmosphere.is_raining(), "il ne pleut pas dedans")
	assert_almost_eq(Atmosphere.current().wetness, 0.0, 0.001, "sol sec dedans")
	var day := Atmosphere.current()
	Atmosphere.set_moment(&"nuit", 0.0)
	var night := Atmosphere.current()
	var night_preset := HD2DLighting.preset(HD2DLighting.INTERIOR_NIGHT)
	assert_almost_eq(night.lamp_energy, night_preset.lamp_energy, 0.001, "lampes et cristaux")
	assert_gt(night.lamp_energy, day.lamp_energy, "les lampes portent la nuit")
	assert_lt(night.sun_energy, day.sun_energy, "les fenêtres s'éteignent")
	assert_false(Atmosphere.is_player_light_on(), "pas de lumière du joueur dedans")
	# Le préréglage « interieur » posé par la carte fait de même sur une carte du dehors.
	_map.interior = false
	_map.light_preset = HD2DLighting.INTERIOR
	Atmosphere.dress(_map)
	assert_eq(Atmosphere.preset_id(), HD2DLighting.INTERIOR)
	assert_false(Atmosphere.is_player_light_on())


# --- Lumière du joueur ------------------------------------------------------------------------


func test_player_light_at_night_outdoors_only() -> void:
	var player := Node3D.new()
	player.add_to_group(DecorPanel.PLAYER_GROUP)
	add_child(player)
	player.global_position = Vector3(20.0, 0.0, 15.0)
	Atmosphere.set_moment(&"nuit", 0.0)
	assert_true(Atmosphere.is_player_light_on(), "la nuit dehors")
	var light := Atmosphere.rig().player_light
	assert_true(light.visible)
	assert_almost_eq(light.light_energy, Atmosphere.rig().light_energy, 0.001, "pleine force")
	assert_lt(light.global_position.distance_to(player.global_position), 2.0, "à côté du joueur")
	assert_true(Atmosphere.rig().orb.visible, "l'orbe dans la main")
	for moment: StringName in [&"aube", &"matin", &"apres_midi", &"couchant"]:
		Atmosphere.set_moment(moment, 0.0)
		assert_false(Atmosphere.is_player_light_on(), "éteinte : %s" % moment)
		assert_false(light.visible, moment)
	# Elle s'allume en douceur avec la nuit.
	Atmosphere.set_moment(&"nuit", 2.0)
	Atmosphere.step(1.0)
	assert_true(light.light_energy > 0.0 and light.light_energy < Atmosphere.rig().light_energy)
	Atmosphere.step(1.5)
	# Réglable : toujours ou jamais, pour une scène.
	Atmosphere.player_light_mode = Atmosphere.LIGHT_OFF
	assert_false(Atmosphere.is_player_light_on(), "Willem arrive sans lumière")
	Atmosphere.player_light_mode = Atmosphere.LIGHT_AUTO
	assert_true(Atmosphere.is_player_light_on())
	Atmosphere.set_moment(&"matin", 0.0)
	Atmosphere.player_light_mode = Atmosphere.LIGHT_ON
	assert_true(Atmosphere.is_player_light_on(), "allumée sur demande")
	# Dedans, éteinte.
	Atmosphere.player_light_mode = Atmosphere.LIGHT_AUTO
	Atmosphere.set_moment(&"nuit", 0.0)
	_map.interior = true
	Atmosphere.dress(_map)
	assert_false(Atmosphere.is_player_light_on(), "éteinte dedans")
	player.free()


# --- Pluie ------------------------------------------------------------------------------------


func test_rain_falls_wets_the_ground_and_stops() -> void:
	var ground := _map.get_node(^"Ground/Grass") as MeshInstance3D
	var grass := ground.mesh.surface_get_material(0) as BaseMaterial3D
	var dry_roughness := grass.roughness
	Atmosphere.set_weather(&"pluie", 0.0)
	var rig := Atmosphere.rig()
	assert_true(Atmosphere.is_raining(), "pluie fine")
	assert_almost_eq(rig.rain.intensity, HD2DWeather.preset(&"pluie").rain, 0.001)
	assert_true(rig.curtain_layer.visible, "rideau à l'écran")
	assert_lt(grass.roughness, dry_roughness, "sol mouillé, un peu brillant")
	Atmosphere.set_weather(&"averse", 0.0)
	assert_almost_eq(rig.rain.intensity, 1.0, 0.001, "averse")
	assert_lt(_sun().light_energy, _expected(&"couchant", &"pluie").sun_energy, "plus sombre")
	# La pluie s'arrête en douceur, puis tout sèche.
	Atmosphere.set_weather(&"clair", 2.0)
	Atmosphere.step(1.0)
	assert_true(rig.rain.intensity > 0.0 and rig.rain.intensity < 1.0, "elle faiblit")
	Atmosphere.step(1.5)
	assert_almost_eq(rig.rain.intensity, 0.0, 0.001, "la pluie s'arrête")
	assert_false(Atmosphere.is_raining(), "plus de gouttes")
	assert_false(rig.curtain_layer.visible, "plus de rideau")
	assert_almost_eq(grass.roughness, dry_roughness, 0.001, "le sol a séché")
	assert_almost_eq(_sun().light_energy, _expected(&"couchant", &"clair").sun_energy, 0.001)


# --- Matériaux : lueur, images de nuit, vitres éclairées, sol mouillé ------------------------


func _panel(texture: Texture2D, glow: float) -> MeshInstance3D:
	var material := ShaderMaterial.new()
	material.shader = PANEL_SHADER
	material.set_shader_parameter(&"albedo_texture", texture)
	material.set_shader_parameter(&"glow_strength", glow)
	var instance := MeshInstance3D.new()
	instance.mesh = QuadMesh.new()
	instance.material_override = material
	return instance


func test_night_images_lit_windows_glow_and_wetness() -> void:
	var holder := Node3D.new()
	var window := _panel(WINDOW, 0.8)
	var lit := _panel(WINDOW_LIT, 0.0)
	holder.add_child(window)
	holder.add_child(lit)
	add_child(holder)
	var targets := HD2DLightTargets.scan(holder)
	assert_eq(targets.counts()["night"], 1, "une fenêtre a son image de nuit")
	assert_eq(targets.counts()["lit"], 1, "une vitre éclairée")
	assert_eq(targets.counts()["glow"], 1, "une fenêtre qui luit")
	assert_eq(targets.counts()["wet"], 2, "deux matériaux de panneau")
	var window_material := window.material_override as ShaderMaterial
	var lit_material := lit.material_override as ShaderMaterial
	targets.apply(_expected(&"apres_midi", &"clair"))
	assert_eq(window_material.get_shader_parameter(&"albedo_texture"), WINDOW, "le jour")
	assert_gt(float(lit_material.get_shader_parameter(&"alpha_cut")), 1.0, "vitre éteinte")
	assert_almost_eq(
		float(window_material.get_shader_parameter(&"glow_strength")),
		0.8 * HD2DLighting.preset(&"apres_midi").window_glow,
		0.001,
		"lueur de jour"
	)
	targets.apply(_expected(&"nuit", &"averse"))
	assert_eq(window_material.get_shader_parameter(&"albedo_texture"), WINDOW_NIGHT, "la nuit")
	assert_almost_eq(float(lit_material.get_shader_parameter(&"alpha_cut")), 0.5, 0.001, "allumée")
	assert_gt(float(window_material.get_shader_parameter(&"glow_strength")), 0.8, "lueur de nuit")
	assert_almost_eq(
		float(window_material.get_shader_parameter(&"hd2d_wetness")), 1.0, 0.001, "mouillé"
	)
	targets.apply(_expected(&"matin", &"clair"))
	assert_eq(window_material.get_shader_parameter(&"albedo_texture"), WINDOW, "le matin revient")
	assert_almost_eq(float(window_material.get_shader_parameter(&"hd2d_wetness")), 0.0, 0.001)
	holder.free()


## (F1) Carte qui porte ses propres nœuds de lumière (comme l'ancienne île, retirée) : un
## WorldEnvironment, un soleil, une lanterne et une mer de nuages.
func _map_with_own_light() -> Node3D:
	var holder := Node3D.new()
	holder.name = "own_light"
	var world := WorldEnvironment.new()
	world.name = "WorldEnvironment"
	world.environment = Environment.new()
	var panorama := PanoramaSkyMaterial.new()
	panorama.panorama = load("res://assets/hd2d/sky/sky.png") as Texture2D
	world.environment.sky = Sky.new()
	world.environment.sky.sky_material = panorama
	world.environment.background_mode = Environment.BG_SKY
	holder.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	holder.add_child(sun)
	var lamp := OmniLight3D.new()
	lamp.name = "Lantern"
	holder.add_child(lamp)
	var water := MeshInstance3D.new()
	water.name = "Water"
	water.mesh = PlaneMesh.new()
	var clouds := ShaderMaterial.new()
	clouds.shader = HD2DLightTargets.CLOUD_SEA_SHADER
	clouds.set_shader_parameter(&"clouds", load("res://assets/hd2d/sky/cloud_sea.png"))
	water.material_override = clouds
	holder.add_child(water)
	return holder


func test_a_map_with_its_own_light_is_driven_through_its_nodes() -> void:
	# Une carte qui a son WorldEnvironment et son soleil : la lumière les règle, sans en ajouter,
	# et la mer de nuages reçoit sa teinte et ses étoiles.
	var island := _map_with_own_light()
	add_child(island)
	Atmosphere.set_moment(&"nuit", 0.0)
	Atmosphere.dress(island)
	var rig := Atmosphere.rig()
	assert_null(rig.get_node_or_null(^"WorldEnvironment"), "pas de second environnement")
	assert_null(rig.get_node_or_null(^"Sun"), "pas de second soleil")
	assert_eq(Atmosphere.targets().world, island.get_node(^"WorldEnvironment"))
	assert_eq(Atmosphere.targets().sun, island.get_node(^"Sun"))
	var night := _expected(&"nuit", &"clair")
	assert_eq((island.get_node(^"Sun") as DirectionalLight3D).light_color, night.sun_color)
	var water := island.get_node(^"Water") as MeshInstance3D
	var clouds := water.material_override as ShaderMaterial
	assert_eq(clouds.get_shader_parameter(&"tint"), night.clouds_tint, "nuages de nuit")
	assert_eq(clouds.get_shader_parameter(&"stars"), 1.0, "étoiles")
	assert_gt(Atmosphere.targets().counts()["lamps"], 0, "lanterne de la carte")
	Atmosphere.dress(_map)
	island.free()


func test_new_maps_get_their_light_from_the_rig() -> void:
	var rig := Atmosphere.rig()
	assert_not_null(rig, "rig posé")
	assert_eq(rig.get_parent(), _map, "enfant de la carte")
	assert_not_null(rig.get_node_or_null(^"WorldEnvironment"), "environnement fourni")
	assert_not_null(rig.get_node_or_null(^"Sun"), "soleil fourni")
	assert_eq(_map.find_children("*", "WorldEnvironment", true, false).size(), 1, "un seul")
	assert_eq(AtmosphereRig.dress(_map), rig, "un seul rig par carte")


# --- Raccourcis de développement --------------------------------------------------------------


func test_dev_parameters() -> void:
	var pairs := PackedStringArray(["moment=nuit", "temps=averse", "zone=dunes", "x"])
	assert_eq(Atmosphere.parse_pairs(pairs), {"moment": &"nuit", "temps": &"averse"})
	var wrong := PackedStringArray(["moment=minuit", "temps=neige"])
	assert_eq(Atmosphere.parse_pairs(wrong), {}, "valeurs inconnues ignorées")
	var previous := Atmosphere.dev_parameters
	Atmosphere.dev_parameters = {"moment": &"aube", "temps": &"pluie"}
	SaveManager.new_game(&"chtholly")
	assert_eq(GameState.moment, &"aube", "posé à la partie chargée")
	assert_eq(GameState.weather, &"pluie")
	assert_false(Atmosphere.is_transitioning(), "tout de suite")
	Atmosphere.dev_parameters = previous
