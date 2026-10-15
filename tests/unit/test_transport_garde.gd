extends "res://tests/stubs/c1_exterior_test.gd"
## (E7) Le pont du transport de la Garde (src/world/maps/transport_garde/, plan de
## docs/lore/CARTE.md, 6.3, écrit par tools/exterior_maps.py d'après
## tools/exterior_recipes/transport_garde.py). Base commune tests/stubs/c1_exterior_test.gd (plan,
## sorties, marqueurs, points, circulation à pied, rien ne cache le joueur, densité, sol nu, draw
## calls, aucune lumière), plus :
## - le pont praticable au-dessus du vide (la mer de nuages tout autour), son décalque, son
##   bastingage, la passerelle de commandement, les caisses, la manche à air, l'écoutille, les deux
##   rotors arrêtés en bout de bras ;
## - la passerelle de planches franchit le vide jusqu'à la bande du quai, d'où l'on redescend au
##   port (« Descendre à quai », sur from_transport_garde) ;
## - la carte est rangée au port (lieu `port` de l'île n° 68).


func before_all() -> void:
	map_id = "transport_garde"
	# Un seul écran (20 × 11 m) : le pont, et la passerelle vers le quai.
	density = {
		"pont": [Vector3(10.0, 0.0, 4.4), 30, 125],
		"passerelle": [Vector3(10.0, 0.0, 8.6), 30, 125],
	}
	walk_spots = [
		Vector3(10.0, 0.0, 4.4),
		Vector3(3.5, 0.0, 3.5),
		Vector3(16.5, 0.0, 4.4),
		Vector3(10.0, 0.0, 6.5),
		Vector3(10.0, 0.0, 9.0),
		Vector3(5.0, 0.0, 10.4),
		Vector3(16.0, 0.0, 10.4),
	]
	expected_camera_bounds = Rect2(9.5, 2, 1, 5)
	min_walk_area = 60.0
	min_checked_places = 80
	await super()


func test_the_deck_floats_above_the_void() -> void:
	for at: Vector2 in [
		Vector2(10.0, 0.5), Vector2(1.0, 3.5), Vector2(19.0, 3.5), Vector2(5.0, 6.5)
	]:
		assert_false(_ground.is_walkable(at.x, at.y), "le vide en (%.1f ; %.1f)" % [at.x, at.y])
	assert_true(_ground.is_walkable(10.0, 3.5), "le pont")
	assert_true(_ground.is_walkable(10.0, 6.5), "la passerelle")
	assert_true(_ground.is_walkable(10.0, 9.0), "le quai")
	var sky := _map.get_node_or_null(^"Geometry/Sky")
	assert_not_null(sky, "des îles, des nuages au loin")
	if sky != null:
		assert_gt(sky.get_child_count(), 6)


func test_the_deck_and_its_fittings() -> void:
	var deck := _map.find_child("PontNavire", true, false) as GroundDecal
	assert_not_null(deck, "le pont du navire, vu de dessus")
	if deck != null:
		assert_true(deck.texture.resource_path.ends_with("ships/garde_transport_deck.png"))
		assert_almost_eq(deck.global_position.x, 10.0, 0.01, "de x 2 à 18")
		assert_almost_eq(deck.global_position.z, 3.5, 0.01, "de z 1 à 6")
	for node_name: String in [
		"PasserelleCommandement", "DeckCratesLashed", "DeckVent", "DeckHatch", "Passerelle"
	]:
		assert_not_null(_map.find_child(node_name, true, false), node_name)
	var rotors := _map.get_node(^"Geometry/Rotors")
	assert_eq(rotors.get_child_count(), 2, "deux rotors, à la poupe et à la proue")
	for rotor: Node in rotors.get_children():
		var panel := rotor as DecorPanel
		assert_true(panel.texture.resource_path.ends_with("anim/garde_transport_rotor.png"))
		assert_eq(panel.fps, 0.0, "à quai, les pales sont arrêtées")
	var rails := 0
	for node: Node in _map.find_children("Bastingage*", "", true, false):
		rails += 1
	assert_gte(rails, 14, "le bastingage, au nord et au sud")


func test_the_gangway_leads_back_to_the_port() -> void:
	var down := _map.get_node(^"Exits/vers_port") as MapExit
	assert_eq([down.target_map, down.target_marker], [&"port", &"from_transport_garde"])
	assert_eq(down.prompt, "Descendre à quai")
	assert_true(_is_reached(Vector3(10.0, 0.0, 10.0)), "le quai, par la passerelle")
	var port := (load(Map.scene_path(&"port")) as PackedScene).instantiate() as Map
	var up := port.get_node_or_null(^"Exits/passerelle") as MapExit
	assert_not_null(up, "au port, la sortie « Monter à bord » existe")
	if up != null:
		assert_eq([up.target_map, up.target_marker], [&"transport_garde", &"from_port"])
	assert_not_null(port.marker(&"from_transport_garde"), "le port a le marqueur d'arrivée")
	port.free()


func test_the_map_belongs_to_the_port() -> void:
	assert_eq(_map.region, &"port")
	assert_has(WorldAtlas.maps_of(&"ile_68"), &"transport_garde")
	assert_has(WorldAtlas.maps_of(&"ile_68"), &"barocupot")


## Les draw calls, comme la base (tests/stubs/c1_exterior_test.gd), sur une grille plus fine : la
## carte ne fait que 20 × 11 m (une grille de 6 m n'y pose que cinq points de vue).
func test_batched_decor_in_each_view_stays_within_the_draw_call_budget() -> void:
	var batches: Array[MeshInstance3D] = []
	for child: Node in _map.get_node(^"Geometry").get_children():
		var mesh := child as MeshInstance3D
		if mesh != null and mesh.mesh != null and String(mesh.name).begins_with("Batch"):
			batches.append(mesh)
	assert_gt(batches.size(), 15, "décors fondus par image")
	var worst := 0
	var views := 0
	var x := 1.0
	while x < _map.size.x:
		var z := 1.0
		while z < _map.size.y:
			var feet := Vector3(x, 0.0, z)
			if _is_reached(feet):
				views += 1
				feet.y = _ground.height_at(x, z)
				var camera := _camera(feet)
				var drawn := 0
				for mesh in batches:
					if _box_on_screen(camera, mesh.global_transform * mesh.get_aabb()):
						drawn += 1
				worst = maxi(worst, drawn)
			z += 1.5
		x += 1.5
	gut.p("%d vues ; au plus %d lots de décor dans le champ" % [views, worst])
	assert_gt(views, 25, "une grille de points de vue")
	assert_lte(worst + OTHER_DRAW_CALLS, DRAW_CALL_BUDGET, "au plus 200 draw calls par vue")
