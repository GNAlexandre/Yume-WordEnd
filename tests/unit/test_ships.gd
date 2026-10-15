extends GutTest
## (E7) Les navires en volume : la scène du transport de la Garde (panneaux, rotors sur les moyeux,
## trappe, passerelle, projecteur), ses données, et son poste d'amarrage dans la carte du port
## (ShipBerth), piloté par ShipControl et avancé d'un coup (advance) : vide hors des scènes ; la
## descente (projecteur, roulis, ralentissement), les bras qui se referment de la poupe à la proue,
## les rotors qui s'arrêtent ; la trappe, la passerelle qui ouvre la porte du vide, la sortie
## « Monter à bord » permise par le récit seulement ; le départ, qui rentre tout et remonte ; l'état
## gardé dans GameState (une carte rechargée le retrouve) ; sans poste, seul l'état change ;
## l'ombre du Barocupot dans les nuages ; l'étape « ship » des scènes.

const SHIP := &"transport_garde"
const SHIP_SCENE := "res://src/world/props/ships/garde_transport.tscn"
const ISLAND := &"ile_68"
## Moyeux dessinés sur le flanc (px depuis le coin haut gauche de ships/garde_transport_side).
const HUBS: Array[Vector2] = [Vector2(526.0, 521.0), Vector2(1074.0, 521.0)]

var _map: Map
var _berth: ShipBerth
var _events: Array[StringName] = []


func before_all() -> void:
	GameState.reset()
	_map = (load(Map.scene_path(&"port")) as PackedScene).instantiate() as Map
	add_child(_map)
	await wait_physics_frames(2)
	_berth = _map.get_node(^"Berth") as ShipBerth


func after_all() -> void:
	_map.free()
	GameState.reset()


func before_each() -> void:
	GameState.reset()
	_berth.apply_state()
	_events.clear()
	_berth.ship_event.connect(_on_event)


func after_each() -> void:
	_berth.ship_event.disconnect(_on_event)
	_berth.finish_now()
	GameState.reset()
	_berth.apply_state()


func _on_event(event: StringName) -> void:
	_events.append(event)


func _ship() -> Ship:
	return _berth.ship()


func _exit() -> MapExit:
	return _map.get_node(^"Exits/passerelle") as MapExit


# --- La scène et les données ------------------------------------------------------------------


func test_the_ship_is_an_assembly_of_panels_with_its_parts() -> void:
	var ship := (load(SHIP_SCENE) as PackedScene).instantiate() as Ship
	add_child(ship)
	assert_eq(ship.ship_id, SHIP)
	var hull := ship.get_node(^"Hull") as DecorPanel
	assert_true(hull.texture.resource_path.ends_with("ships/garde_transport_side.png"), "le flanc")
	assert_eq(hull.size_m(), Vector2(16.0, 7.0), "16 × 7 m (CARTE.md 6.2)")
	var deck := ship.get_node(^"Deck") as DecorPanel
	assert_true(deck.keep_orientation, "le pont, couché")
	assert_almost_eq(deck.global_basis.z.y, 1.0, 0.001, "face vers le ciel")
	assert_almost_eq(deck.global_basis.y.z, -1.0, 0.001, "tiré vers le nord, derrière le flanc")
	# Les rotors sur les moyeux dessinés du flanc (à 0,1 m près), la trappe, le projecteur.
	var rotors := ship.rotors()
	assert_eq(rotors.size(), 2, "deux rotors")
	for k in rotors.size():
		var hub := HUBS[k]
		var at := Vector2((hub.x - 768.0) / 96.0, (672.0 - hub.y) / 96.0)
		var center := Vector2(
			rotors[k].position.x, rotors[k].position.y + rotors[k].size_m().y / 2.0
		)
		assert_almost_eq(center, at, Vector2.ONE * 0.1, "%s sur son moyeu" % rotors[k].name)
		assert_eq(rotors[k].frames, 4)
		assert_eq(rotors[k].fps, 0.0, "la bande tourne au pas du navire")
	assert_not_null(ship.get_node_or_null(^"Hatch") as ShipStrip, "la trappe")
	var light := ship.get_node(^"Searchlight") as ShipStrip
	assert_true(light.soft_alpha, "le projecteur, à alpha doux")
	assert_false(light.visible, "éteint au repos")
	# Rien d'autre que des panneaux et des volumes : aucun maillage hors d'eux.
	for mesh: Node in ship.find_children("*", "MeshInstance3D", true, false):
		var parent := mesh.get_parent()
		assert_true(
			parent is DecorPanel or parent is Building, "%s : maillage d'un panneau" % mesh.name
		)
	var body := ship.get_node(^"Collision") as StaticBody3D
	assert_eq(body.collision_layer, 1, "la coque bloque (couche 1)")
	assert_eq(ship.gangway_amount(), 0.0, "passerelle rentrée")
	assert_false((ship.get_node(^"Gangway") as Node3D).visible)
	ship.free()


func test_the_data_of_the_ships() -> void:
	assert_true(ShipControl.has_ship(SHIP))
	assert_true(ShipControl.has_ship(&"barocupot"))
	assert_false(ShipControl.has_ship(&"nulle_part"))
	var data := ShipControl.data(SHIP)
	var sections: Array[String] = [
		"descent", "searchlight", "mooring", "rotor", "hatch", "gangway", "departure"
	]
	for section: String in sections:
		assert_true(data.has(section), "transport_garde.%s" % section)
	assert_eq(str(data["scene"]), SHIP_SCENE)
	assert_true(ResourceLoader.exists(str(data["scene"])))
	var shadow: Dictionary = ShipControl.data(&"barocupot")["shadow"]
	assert_true(ResourceLoader.exists(str(shadow["image"])), "la silhouette du Barocupot")


# --- Au port : vide hors des scènes ---------------------------------------------------------------


func test_outside_the_scenes_the_berth_is_empty() -> void:
	assert_not_null(_berth, "le poste d'amarrage du port")
	assert_eq(_berth.ship_id, SHIP)
	assert_false(_ship().visible, "le poste est vide (CARTE.md 6.2)")
	assert_eq((_ship().get_node(^"Collision") as StaticBody3D).collision_layer, 0)
	assert_eq(_berth.clamps().size(), 3, "trois bras d'ancrage")
	var xs: Array[float] = []
	for arm in _berth.clamps():
		xs.append(arm.global_position.x)
		assert_eq(arm.frame, 0, "%s ouvert" % arm.name)
		assert_true(arm.visible)
	assert_eq(xs, [23.5, 29.5, 36.5] as Array[float], "de la poupe à la proue, aux x du plan")
	assert_false(_berth.gate_open(), "le bord du vide est fermé devant la passerelle")
	assert_false(_berth.boarding_open(), "pas de « Monter à bord »")
	assert_eq(_exit().prompt, "Monter à bord")
	assert_eq(_exit().target_map, &"transport_garde")
	assert_eq(ShipControl.ship(SHIP), _ship())


# --- La descente et l'amarrage --------------------------------------------------------------------


func test_the_descent_moors_the_ship_arm_after_arm_and_stops_the_rotors() -> void:
	var data := ShipControl.data(SHIP)
	var fall := float(data["descent"]["time"])
	var height := float(data["descent"]["height"])
	var rest := _ship().rest_transform().origin
	await ShipControl.play(SHIP, &"descend", false)
	assert_eq(_berth.current_action(), &"descend")
	assert_true(_ship().visible, "le navire paraît")
	assert_almost_eq(_ship().position.y, rest.y + height, 0.01, "au-dessus du quai")
	assert_almost_eq(
		(_ship().get_node(^"Searchlight") as ShipStrip).opacity, 1.0, 0.01, "le projecteur aveugle"
	)
	assert_eq(_ship().rotor_speed(), float(data["rotor"]["fps"]), "les pales tournent")
	# La descente ralentit : plus de la moitié de la hauteur est faite à mi-temps.
	var heights: Array[float] = []
	var rolls: Array[float] = []
	for _step in 18:
		_berth.advance(fall / 18.0)
		heights.append(_ship().position.y - rest.y)
		rolls.append(rad_to_deg(_ship().basis.get_euler().z))
	assert_lt(heights[8], height * 0.5, "plus de la moitié faite à mi-descente (ralentit)")
	for k in range(1, heights.size()):
		assert_lte(heights[k], heights[k - 1] + 0.0001, "elle descend toujours")
	assert_almost_eq(heights[-1], 0.0, 0.01, "posé au niveau du quai")
	var swing := 0.0
	for roll in rolls:
		swing = maxf(swing, absf(roll))
	assert_gt(swing, 0.3, "un léger roulis")
	assert_lt(swing, 3.0, "léger")
	assert_lt(
		(_ship().get_node(^"Searchlight") as ShipStrip).opacity, 0.05, "le projecteur s'est éteint"
	)
	assert_has(_events, &"landed")
	# Les bras se referment de l'arrière vers l'avant.
	var arms := _berth.clamps()
	_berth.advance(0.5)
	assert_gt(arms[0].frame, 0, "le bras de la poupe se referme d'abord")
	assert_eq(arms[2].frame, 0, "celui de la proue attend")
	_berth.advance(2.0)
	for arm in arms:
		assert_eq(arm.frame, arm.frames - 1, "%s refermé" % arm.name)
	assert_eq(
		_events.slice(_events.find(&"clamp_1"), _events.find(&"clamp_3") + 1),
		[&"clamp_1", &"clamp_2", &"clamp_3"] as Array[StringName],
		"de la poupe à la proue"
	)
	assert_gt(_ship().rotor_speed(), 0.0, "les pales ralentissent encore")
	_berth.advance(float(data["rotor"]["spin_down"]))
	assert_eq(_ship().rotor_speed(), 0.0, "les pales arrêtées")
	assert_has(_events, &"rotors_stopped")
	assert_false(_berth.is_busy(), "amarré")
	assert_true(ShipControl.is_docked(SHIP))
	assert_false(_berth.gate_open(), "trappe fermée, passerelle rentrée : le vide reste fermé")
	assert_almost_eq(_ship().position, rest, Vector3.ONE * 0.001, "à sa place de repos")


func test_the_hatch_the_gangway_boarding_and_the_departure() -> void:
	ShipControl.dock(SHIP)
	assert_true(_ship().visible)
	await ShipControl.play(SHIP, &"open_hatch", false)
	_berth.advance(0.1)
	assert_eq((_ship().get_node(^"Hatch") as ShipStrip).frame, 0, "la pression monte")
	_berth.advance(5.0)
	assert_eq((_ship().get_node(^"Hatch") as ShipStrip).frame, 3, "grande ouverte")
	assert_true(ShipControl.has_flag(SHIP, &"hatch"))
	await ShipControl.play(SHIP, &"deploy_gangway", false)
	_berth.advance(0.4)
	assert_true((_ship().get_node(^"Gangway") as Node3D).visible, "la passerelle sort")
	assert_false(_berth.gate_open(), "pas encore posée : le vide reste fermé")
	_berth.advance(5.0)
	assert_eq(_ship().gangway_amount(), 1.0)
	assert_true(_berth.gate_open(), "posée : le bord du vide s'ouvre devant elle")
	var foot := _ship().gangway_foot()
	assert_almost_eq(foot.x, 32.5, 0.01, "au droit du plan (x 32,5)")
	assert_between(foot.z, 6.2, 7.2, "son pied sur le quai, au nord de navire_quai")
	assert_almost_eq(foot.y, 0.0, 0.08, "au ras du quai")
	assert_almost_eq(_ship().gangway_top().y, 1.0, 0.05, "le pont à 1 m au-dessus du quai")
	var gangway_body := _ship().get_node(^"Gangway/Collision") as StaticBody3D
	assert_eq(gangway_body.collision_layer, 1, "on y marche")
	assert_false(_berth.boarding_open(), "à l'acte 1, on n'y monte jamais")
	ShipControl.allow_boarding(SHIP)
	assert_true(_berth.boarding_open(), "« Monter à bord » quand le récit le permet")
	# Le départ : la passerelle rentre (le vide se referme tout de suite), la trappe se ferme, les
	# bras s'ouvrent de la proue à la poupe, les rotors repartent, le navire remonte.
	await ShipControl.play(SHIP, &"depart", false)
	assert_false(_berth.gate_open(), "le vide se referme dès le départ")
	assert_false(_berth.boarding_open())
	var arms := _berth.clamps()
	_berth.advance(1.6 + 0.4 + 3.0 / 8.0 + 0.3)
	assert_eq(_ship().gangway_amount(), 0.0, "passerelle rentrée")
	assert_eq((_ship().get_node(^"Hatch") as ShipStrip).frame, 0, "trappe fermée")
	assert_lt(arms[2].frame, arms[2].frames - 1, "le bras de la proue s'ouvre d'abord")
	assert_eq(arms[0].frame, arms[0].frames - 1, "celui de la poupe tient encore")
	_berth.advance(4.0)
	assert_gt(_ship().rotor_speed(), 0.0, "les pales repartent")
	assert_gt(_ship().position.y, _ship().rest_transform().origin.y, "il remonte")
	_berth.advance(30.0)
	assert_false(_ship().visible, "parti")
	assert_false(ShipControl.is_docked(SHIP))
	assert_false(ShipControl.has_flag(SHIP, &"hatch"))
	for arm in arms:
		assert_eq(arm.frame, 0, "%s rouvert" % arm.name)
	assert_has(_events, &"gone")
	assert_true(ShipControl.has_flag(SHIP, &"boarding"), "le droit d'embarquer reste au récit")


func test_await_plays_the_action_to_its_end() -> void:
	ShipControl.dock(SHIP)
	var started := Time.get_ticks_msec()
	await ShipControl.open_hatch(SHIP)
	assert_true(ShipControl.has_flag(SHIP, &"hatch"), "attendue jusqu'au bout")
	assert_gt(Time.get_ticks_msec() - started, 300, "en temps de jeu")


func test_the_state_is_kept_by_the_flags_and_found_again_by_a_reloaded_map() -> void:
	ShipControl.pose(SHIP, &"deploy_gangway")
	assert_true(_ship().visible)
	assert_eq(_ship().gangway_amount(), 1.0)
	assert_true(_berth.gate_open())
	# Une autre carte du port (sous un autre parent : la carte garde son nom, qui nomme son sol).
	var holder := Node3D.new()
	add_child(holder)
	var other := (load(Map.scene_path(&"port")) as PackedScene).instantiate() as Map
	holder.add_child(other)
	await wait_physics_frames(1)
	var berth := other.get_node(^"Berth") as ShipBerth
	assert_true(berth.ship().visible, "toujours à quai")
	assert_eq(berth.ship().gangway_amount(), 1.0, "passerelle posée")
	assert_true(berth.gate_open())
	for arm in berth.clamps():
		assert_eq(arm.frame, arm.frames - 1, "bras refermés")
	holder.free()
	ShipControl.pose(SHIP, &"absent")
	assert_false(_ship().visible)


func test_without_a_berth_only_the_state_changes() -> void:
	_map.remove_child(_berth)
	await ShipControl.descend(SHIP)
	assert_true(ShipControl.is_docked(SHIP), "à quai quand on viendra au port")
	await ShipControl.deploy_gangway(SHIP)
	assert_true(ShipControl.has_flag(SHIP, &"gangway"))
	await ShipControl.depart(SHIP)
	assert_false(ShipControl.is_docked(SHIP))
	assert_false(ShipControl.has_flag(SHIP, &"gangway"))
	_map.add_child(_berth)
	_berth.apply_state()


func test_skipping_finishes_an_action_at_once() -> void:
	await ShipControl.play(SHIP, &"descend", false)
	ShipControl.finish(SHIP, &"descend")
	assert_false(_berth.is_busy())
	assert_true(ShipControl.is_docked(SHIP))
	assert_eq(_ship().rotor_speed(), 0.0)
	ShipControl.finish(SHIP, &"deploy_gangway")
	assert_true(_berth.gate_open())


# --- L'ombre du Barocupot -------------------------------------------------------------------------


func test_the_shadow_of_the_barocupot_passes_in_the_clouds() -> void:
	var shadow := await ShipControl.pass_shadow(&"barocupot", false)
	assert_not_null(shadow)
	assert_true(ShipControl.is_playing(&"barocupot", &"shadow"))
	var settings: Dictionary = ShipControl.data(&"barocupot")["shadow"]
	var start := shadow.global_position
	assert_almost_eq(shadow.shown_opacity(), 0.0, 0.01, "elle apparaît en fondu")
	shadow.advance(float(settings["time"]) / 2.0)
	assert_almost_eq(shadow.shown_opacity(), float(settings["opacity"]), 0.01, "sombre au milieu")
	assert_almost_eq(
		shadow.global_position.x - start.x, float(settings["span"]) / 2.0, 0.01, "d'ouest en est"
	)
	var panel := shadow.get_node(^"Silhouette") as ShipStrip
	assert_true(panel.texture.resource_path.ends_with("airship_barocupot.png"))
	assert_true(panel.soft_alpha)
	shadow.advance(100.0)
	assert_true(shadow.is_done())
	assert_false(ShipControl.is_playing(&"barocupot", &"shadow"), "passée")
	await wait_process_frames(2)
	assert_false(is_instance_valid(shadow), "puis libérée")


# --- L'étape « ship » des scènes ---------------------------------------------------------------


func _scene(step: Dictionary) -> Dictionary:
	return {
		"day": 7,
		"map": "port",
		"trigger": {"on": "ready"},
		"steps": [step],
	}


func test_the_ship_step_is_checked() -> void:
	var good := {"do": "ship", "ship": "transport_garde", "action": "descend"}
	assert_eq(StoryData.scene_problems(&"essai", _scene(good), ISLAND, false), PackedStringArray())
	var no_wait := {"do": "ship", "ship": "barocupot", "action": "shadow", "wait": false}
	assert_eq(
		StoryData.scene_problems(&"essai", _scene(no_wait), ISLAND, false), PackedStringArray()
	)
	var bad_ship := {"do": "ship", "ship": "nulle_part", "action": "descend"}
	assert_string_contains(
		"\n".join(StoryData.scene_problems(&"essai", _scene(bad_ship), ISLAND, false)),
		"navire inconnu"
	)
	var bad_action := {"do": "ship", "ship": "transport_garde", "action": "plonger"}
	assert_string_contains(
		"\n".join(StoryData.scene_problems(&"essai", _scene(bad_action), ISLAND, false)), "descend"
	)


func test_the_ship_step_plays_and_a_skipped_scene_finishes_it() -> void:
	var runner := StoryRunner.new()
	add_child(runner)
	await runner.call(&"_ship", {"do": "ship", "ship": "transport_garde", "action": "dock"})
	assert_true(ShipControl.is_docked(SHIP), "à quai")
	# Une séquence passée en pleine action : l'état final, d'un coup.
	runner.call(&"_ship", {"do": "ship", "ship": "transport_garde", "action": "open_hatch"})
	assert_eq(_berth.current_action(), &"open_hatch")
	runner.fast = true
	await wait_physics_frames(2)
	assert_false(_berth.is_busy())
	assert_true(ShipControl.has_flag(SHIP, &"hatch"), "trappe ouverte")
	runner.free()
