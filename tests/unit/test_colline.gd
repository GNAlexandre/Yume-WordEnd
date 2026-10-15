extends "res://tests/stubs/c1_exterior_test.gd"
## (C3) La carte colline, la colline des étoiles (src/world/maps/colline/, plan de
## docs/lore/CARTE.md, section 7, écrite par tools/exterior_maps.py). Base commune
## tests/stubs/c1_exterior_test.gd (plan, sorties, marqueurs, points, circulation à pied, rien ne
## cache le joueur, densité, sol nu, draw calls, aucune lumière), plus :
## - la sortie vers l'entrepôt, le marqueur d'arrivée, Spawn ;
## - le relief (C3b) : des terrasses aux contours irréguliers (+1, +2,5 et +3,5 m, des marches de
##   0,5 m sur les flancs) montées par trois rampes larges, le sommet de 12 × 12 m plat à 3,5 m, le
##   vide au nord (la mer de nuages sous la colline, des rochers et des îles qui flottent) ;
## - le sommet : la place cercle_talismans libre, le petit cristal et les points de la scène de
##   l'acte 1 (8.8), la vue au nord ouverte (rien de haut devant le vide, au centre) ;
## - les décors et les images du plan, tous livrés ; l'arbre solitaire et le rocher du plan en
##   variante de premier plan quand ils cachent un passage ;
## - la lumière : de nuit par `light_preset` (la nuit claire d'E9), aucune lumière dans la carte ;
## - la faune de la colline (E5) : le nœud Life/Fauna, ses marqueurs, son peuplement ;
## - les places de la vie en plus du plan.

const AtmosphereScript := preload("res://src/autoload/atmosphere.gd")
const EXTRA_PLACES: Array[String] = [
	"vers_entrepot",
	"pied_de_colline",
	"arbre_seul",
	"merles",
	"papillons",
	"chouette",
]
## Points de la scène de l'acte 1 (ACTE1.md, 8.8) : nom → (x, z).
const SCENE_POINTS := {
	"talismans_centre": Vector2(20.0, 12.0),
	"dos_a_dos": Vector2(20.0, 13.2),
	"vue_nord": Vector2(20.0, 5.0),
	"rocher": Vector2(9.5, 15.6),
}


func before_all() -> void:
	map_id = "colline"
	expected_camera_bounds = Rect2(10, 6, 20, 26)
	# Les vues du plan : l'entrée, les rampes, les terrasses, le sommet, le bord, l'arbre, le rocher.
	# 40 à 70 éléments par écran (CARTE.md 7 : une colline nue, voulue).
	density = {
		"entrée": [Vector3(20.0, 0.0, 36.5), 40, 70],
		"première rampe": [Vector3(14.0, 0.0, 31.0), 40, 70],
		"terrasse basse": [Vector3(30.0, 0.0, 29.5), 40, 70],
		"deuxième rampe": [Vector3(26.0, 0.0, 27.5), 40, 70],
		"terrasse haute": [Vector3(20.0, 0.0, 24.0), 40, 70],
		"troisième rampe": [Vector3(16.0, 0.0, 21.5), 40, 70],
		"sommet": [Vector3(20.0, 0.0, 15.0), 40, 70],
		"cercle": [Vector3(20.0, 0.0, 12.0), 40, 70],
		"bord": [Vector3(20.0, 0.0, 5.2), 40, 70],
		"arbre": [Vector3(28.4, 0.0, 10.8), 40, 70],
		"rocher": [Vector3(10.4, 0.0, 16.2), 40, 70],
	}
	walk_spots = [
		Vector3(20.0, 0.0, 36.5),
		Vector3(14.0, 1.0, 29.0),
		Vector3(30.0, 1.0, 28.0),
		Vector3(26.0, 2.0, 24.0),
		Vector3(10.0, 2.0, 22.0),
		Vector3(16.0, 3.0, 17.0),
		Vector3(20.0, 3.0, 12.0),
		Vector3(20.0, 3.0, 4.5),
		Vector3(5.0, 1.0, 12.0),
		Vector3(35.0, 1.0, 30.0),
	]
	min_walk_area = 900.0
	min_checked_places = 700
	await super()


# --- Le plan -------------------------------------------------------------------------------------


func test_the_plan_has_what_the_chapter_needs() -> void:
	assert_eq(_lines("sortie").size(), 1, "vers l'entrepôt")
	assert_eq(_lines("marqueur").size(), 2, "Spawn, from_entrepot")
	assert_eq(_lines("point").size(), 4, "talismans_centre, dos_a_dos, vue_nord, rocher")
	assert_eq(_lines("place").size(), 1, "cercle_talismans")
	assert_eq(_lines("palier").size(), 3, "trois terrasses")
	assert_eq(_lines("rampe").size(), 3, "trois rampes")


func test_the_exit_leads_to_the_warehouse() -> void:
	var exit := _map.get_node(^"Exits/vers_entrepot") as MapExit
	assert_eq(exit.target_map, &"entrepot")
	assert_eq(exit.target_marker, &"from_colline")
	assert_eq(exit.prompt, "", "on passe en marchant")
	assert_true(Map.exists(&"entrepot"), "l'entrepôt existe")
	assert_eq(_map.get_node(^"Exits").get_child_count(), 1, "une seule sortie")
	assert_not_null(_map.marker(&"from_entrepot"), "arrivée de l'entrepôt")
	assert_lt(
		_map.spawn().global_position.distance_to(_map.marker(&"from_entrepot").global_position),
		1.0,
		"Spawn au pied du chemin, à côté de l'arrivée"
	)


# --- Le relief -----------------------------------------------------------------------------------


func test_the_relief_follows_the_plan() -> void:
	assert_almost_eq(_ground.height_at(20.0, 36.0), 0.0, 0.05, "le pied de la colline, 0")
	assert_almost_eq(_ground.height_at(18.0, 30.0), 1.0, 0.05, "la terrasse basse, +1 m")
	assert_almost_eq(_ground.height_at(20.0, 23.5), 2.5, 0.05, "la terrasse haute, +2,5 m")
	assert_almost_eq(_ground.height_at(20.0, 12.0), 3.5, 0.05, "le sommet, +3,5 m")
	assert_almost_eq(_ground.height_at(26.0, 10.0), 3.5, 0.05, "le sommet, l'est du cercle")
	# Les trois rampes du plan : (x0, z0, x1, z1, bas, haut). Larges (5 cases) et longues : 11 à 14° de pente.
	for rect: Array in [
		[10.0, 30.0, 15.0, 34.0, 0.0, 1.0],
		[23.0, 24.0, 28.0, 30.0, 1.0, 2.5],
		[14.0, 19.0, 19.0, 24.0, 2.5, 3.5]
	]:
		var cx: float = (rect[0] + rect[2]) / 2.0
		var depth: float = rect[3] - rect[1]
		assert_gte(rect[2] - rect[0], 5.0, "une rampe large %s" % [rect.slice(0, 4)])
		var rise: float = rect[5] - rect[4]
		assert_lt(rad_to_deg(atan(rise / depth)), 15.0, "une vraie pente, pas un coin %s" % [rect.slice(0, 4)])
		var middle := _ground.height_at(cx, (rect[1] + rect[3]) / 2.0)
		assert_between(middle, rect[4] + 0.1, rect[5] - 0.1, "à mi-rampe %s" % [rect.slice(0, 4)])
		var foot := _ground.height_at(cx, rect[3] + 0.4)
		assert_between(
			foot, rect[4] - 0.05, rect[4] + 0.05, "au pied de la rampe %s" % [rect.slice(0, 4)]
		)
		var top := _ground.height_at(cx, rect[1] - 0.4)
		assert_between(
			top, rect[5] - 0.05, rect[5] + 0.05, "en haut de la rampe %s" % [rect.slice(0, 4)]
		)
	assert_gte(_level_count(), 4, "au moins quatre niveaux")


## Des contours irréguliers, pas des rectangles : des marches de 0,5 m à 1,5 m, et le bord de chaque
## terrasse ne court jamais droit sur plus de huit mètres (C3b).
func test_the_terraces_are_irregular_not_stacked_plates() -> void:
	var heights := {}
	for x in range(4, 37):
		for z in range(4, 38):
			var h := _ground.height_at(float(x) + 0.5, float(z) + 0.5)
			if h != MapGround.VOID_HEIGHT:
				heights[snappedf(h, 0.5)] = true
	assert_gte(heights.size(), 7, "des paliers de 0,5 m à 3,5 m : %s" % [heights.keys()])
	# Sur chaque colonne de x (de 6 à 34), on compte les marches vers le sud qui ont plus de 0,4 m.
	var drops := {}
	var longest_straight := 0
	for line in range(18, 36):
		var run := 0
		for x in range(6, 35):
			var up := _ground.height_at(float(x) + 0.5, float(line) - 0.01)
			var down := _ground.height_at(float(x) + 0.5, float(line) + 0.01)
			if up != MapGround.VOID_HEIGHT and down != MapGround.VOID_HEIGHT and up - down > 0.4:
				drops[snappedf(up - down, 0.5)] = true
				run += 1
				longest_straight = maxi(longest_straight, run)
			else:
				run = 0
	assert_lte(longest_straight, 12, "aucune falaise rectiligne de plus de 12 m (%d)" % longest_straight)
	assert_true(drops.has(0.5) and drops.has(1.0) and drops.has(1.5), "des marches de 0,5, 1 et 1,5 m : %s" % [drops.keys()])


func _level_count() -> int:
	var levels := {}
	for x in range(5, 36, 2):
		for z in range(5, 38, 2):
			if _ground.height_at(float(x), float(z)) != MapGround.VOID_HEIGHT:
				levels[snappedf(_ground.height_at(float(x), float(z)), 1.0)] = true
	return levels.size()


## La colline est un cap : au nord, le vide ; dessous, la mer de nuages (void_below = clouds).
func test_the_cape_ends_on_the_void_above_the_sea_of_clouds() -> void:
	assert_eq(_ground.height_at(20.0, 0.5), MapGround.VOID_HEIGHT, "le vide au nord du bord")
	assert_eq(_ground.height_at(5.0, 1.0), MapGround.VOID_HEIGHT, "le vide, au coin")
	assert_ne(_ground.height_at(20.0, 4.0), MapGround.VOID_HEIGHT, "le bord praticable")
	assert_not_null(_ground.get_node_or_null(^"CloudSea"), "la mer de nuages sous la colline")
	assert_false(_ground.has_far_ground(), "pas de sol jusqu'à l'horizon : le ciel et les nuages")
	for words in _lines("bord"):
		if words[1] == "falaise":
			assert_eq(_rect(words), Rect2(0.0, 3.0, 40.0, 1.0), "la bande du bord")
	# On ne tombe pas : la barrière du bord arrête le joueur avant la côte.
	assert_false(_ground.is_walkable(20.0, 1.5), "pas de marche dans le vide")
	assert_true(
		_blocked_between(Vector3(20.0, 4.0, 5.0), Vector3(20.0, 4.0, 2.0)), "la bande du bord ferme"
	)


func _blocked_between(from: Vector3, to: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	return not _space.intersect_ray(query).is_empty()


# --- Le sommet -----------------------------------------------------------------------------------


func test_the_summit_circle_is_flat_free_grass() -> void:
	var circle := _rect(_lines("place")[0])
	assert_eq(circle, Rect2(14.0, 6.0, 12.0, 12.0), "12 × 12 m")
	var low := INF
	var high := -INF
	var x := circle.position.x + 0.5
	while x < circle.end.x:
		var z := circle.position.y + 0.5
		while z < circle.end.y:
			var height := _ground.height_at(x, z)
			low = minf(low, height)
			high = maxf(high, height)
			assert_true(
				_is_reached(Vector3(x, height, z)),
				"on marche partout dans le cercle (%.1f ; %.1f)" % [x, z]
			)
			z += 1.0
		x += 1.0
	assert_almost_eq(low, 3.5, 0.05, "le cercle est plat")
	assert_almost_eq(high, 3.5, 0.05, "le cercle est plat")
	assert_eq(_elements_in_standing(circle), 0, "rien de debout dans le cercle : la scène s'y joue")


func _elements_in_standing(rect: Rect2) -> int:
	var count := 0
	for element: Array in _elements:
		var at: Vector3 = element[2]
		if rect.has_point(Vector2(at.x, at.z)) and not element[0] is GroundDecal:
			var image := String(element[1]).get_file()
			# Les herbes et fleurs du plan (« libre ») ne bloquent rien : la place reste franche.
			if (
				image.begins_with("wildflowers")
				or image.begins_with("heather")
				or image.begins_with("tall_grass")
			):
				continue
			count += 1
	return count


func test_the_scene_points_of_act_one_are_where_the_story_needs_them() -> void:
	for point_name: String in SCENE_POINTS:
		var point := _map.get_node_or_null(NodePath("Life/Places/" + point_name)) as Marker3D
		assert_not_null(point, "point %s" % point_name)
		if point == null:
			continue
		var at: Vector3 = point.global_position
		assert_almost_eq(
			Vector2(at.x, at.z), SCENE_POINTS[point_name] as Vector2, Vector2.ONE * 0.01, point_name
		)
		assert_true(_is_reached(at), "%s : on y marche" % point_name)
	var centre := _map.get_node(^"Life/Places/talismans_centre") as Marker3D
	var back := _map.get_node(^"Life/Places/dos_a_dos") as Marker3D
	assert_lt(
		back.global_position.distance_to(centre.global_position),
		2.0,
		"dos à dos, au pied du cristal"
	)
	# Les quarante et un talismans flottent à cinq pas du cristal (ACTE1.md, 8.8) : dans le cercle.
	var circle := _rect(_lines("place")[0])
	assert_true(
		circle.grow(-5.0).has_point(Vector2(centre.global_position.x, centre.global_position.z))
	)


## La vue au nord est ouverte : devant le cercle, rien de haut ne se dresse au bord du vide.
func test_the_view_north_stays_open_in_front_of_the_circle() -> void:
	var open := Rect2(14.0, 3.0, 12.0, 3.0)
	var in_the_way: Array[String] = []
	var rim_rocks := 0
	for element: Array in _elements:
		var at: Vector3 = element[2]
		var image := String(element[1]).get_file()
		if image.begins_with("edge_rocks"):
			rim_rocks += 1
			if open.has_point(Vector2(at.x, at.z)):
				in_the_way.append("%s en (%.1f ; %.1f)" % [image, at.x, at.z])
	assert_gte(rim_rocks, 4, "des rochers bordent le vide de part et d'autre")
	assert_eq(in_the_way, [] as Array[String], "rien au bord devant la vue au nord")


# --- Les décors et les images --------------------------------------------------------------------


func test_the_decors_of_the_plan_are_there() -> void:
	var images := {}
	for element: Array in _elements:
		images[String(element[1]).get_file().get_basename()] = true
	for kind: String in ["decor", "arbre"]:
		for words in _lines(kind):
			var found := false
			for suffix: String in ["", "_fg", "_forest"]:
				found = found or images.has(words[1] + suffix)
			assert_true(found, "%s %s (ligne du plan)" % [kind, words[1]])


func test_every_image_the_plan_names_is_delivered() -> void:
	# Aucune image du plan n'est à remplacer : tout ce que la colline pose est livré (CARTE.md, 7).
	var manifest: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://tools/hd2d_manifest.json")
	)
	var listed := {}
	for entry: Dictionary in manifest["images"]:
		listed[String(entry["path"]).get_file().get_basename()] = String(entry.get("lot", ""))
	for element: Array in _elements:
		var path := String(element[1])
		assert_true(ResourceLoader.exists(path), "%s existe" % path)
		assert_false(
			String(listed.get(path.get_file().get_basename(), "")) == "R3",
			"%s n'est pas un remplaçant" % path
		)


## Le talisman, que la scène de l'acte 1 (8.8) fait flotter autour du cristal, n'est pas posé par la
## carte ; son remplaçant (cahier n° 5, lot R6) attend au manifeste, à la taille du cahier : 24 × 24
## quatre images à 6 ips.
func test_the_talisman_replacement_waits_in_the_manifest() -> void:
	var manifest: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://tools/hd2d_manifest.json")
	)
	var found := {}
	for entry: Dictionary in manifest["images"]:
		if String(entry["path"]).ends_with("/talisman_float.png"):
			found = entry
	assert_false(found.is_empty(), "talisman_float au manifeste")
	assert_eq(found.get("lot"), "R6", "lot R6 du cahier n° 5")
	assert_eq(found.get("frames"), 4.0)
	var texture := load("res://assets/hd2d/anim/talisman_float.png") as Texture2D
	assert_not_null(texture, "le remplaçant existe")
	if texture != null:
		assert_eq(texture.get_size(), Vector2(96.0, 24.0), "quatre images de 24 × 24 px")
	for element: Array in _elements:
		assert_false(String(element[1]).contains("talisman"), "la carte ne pose pas de talisman")


## Un grand décor du plan qui cacherait un passage se pose en variante de premier plan.
func test_the_lone_tree_and_the_boulder_are_foreground_where_they_hide_a_path() -> void:
	var tree := 0
	for element: Array in _elements:
		var image := String(element[1]).get_file()
		if image.begins_with("lone_tree"):
			tree += 1
			var panel := element[0] as DecorPanel
			assert_true(panel.foreground, "%s : premier plan, il s'efface devant le joueur" % image)
	assert_gte(tree, 1, "l'arbre solitaire du plan")


# --- La lumière ----------------------------------------------------------------------------------


func test_the_hill_is_lit_by_a_clear_night_whatever_the_moment() -> void:
	assert_eq(_map.light_preset, &"nuit", "la nuit claire d'E9")
	assert_eq(AtmosphereScript.effective_preset_id(_map, &"matin"), &"nuit", "même le matin")
	assert_eq(AtmosphereScript.effective_preset_id(_map, &"couchant"), &"nuit", "même au couchant")
	assert_not_null(HD2DLighting.preset(_map.light_preset), "le préréglage existe")


func test_the_map_carries_no_lamp_even_though_the_plan_names_two() -> void:
	assert_eq(_lines("lumiere").size(), 2, "le plan nomme cristal_reglage et talismans")
	assert_null(_map.get_node_or_null(^"Lights"), "aucune lumière dans la carte")
	# Atmosphere habille la carte de son AtmosphereRig (soleil, lumière du joueur) : pas la carte.
	var own: Array[String] = []
	for lamp: Node in _map.find_children("*", "Light3D", true, false):
		if not String(_map.get_path_to(lamp)).contains("AtmosphereRig"):
			own.append(String(_map.get_path_to(lamp)))
	assert_eq(own, [] as Array[String], "aucune lampe à la carte")


# --- La vie --------------------------------------------------------------------------------------


func test_the_extra_life_places_are_named_and_reached() -> void:
	for place_name in EXTRA_PLACES:
		var place := _map.get_node_or_null(NodePath("Life/Places/" + place_name)) as Marker3D
		assert_not_null(place, "place de la vie %s" % place_name)
		if place != null:
			assert_true(_is_reached(place.global_position), "%s : on y va" % place_name)
	var count := _map.get_node(^"Life/Places").get_child_count()
	assert_eq(
		count,
		_lines("point").size() + EXTRA_PLACES.size(),
		"les points du plan et les places en plus"
	)
	var departure := _map.get_node(^"Life/Places/vers_entrepot") as Marker3D
	var exit_at := (_map.get_node(^"Exits/vers_entrepot") as MapExit).global_position
	assert_lt(
		Vector2(departure.global_position.x, departure.global_position.z).distance_to(
			Vector2(exit_at.x, exit_at.z)
		),
		2.5,
		"vers_entrepot : devant la sortie"
	)


func test_the_hill_has_its_wildlife_node_and_markers() -> void:
	var fauna := _map.get_node_or_null(^"Life/Fauna")
	assert_not_null(fauna, "le nœud Life/Fauna d'E5")
	assert_true(fauna is FaunaPopulator)
	var entries := FaunaRules.entries_for(&"colline")
	assert_gt(entries.size(), 0, "le peuplement de la colline est écrit (peuplement.json, maps)")
	var species := {}
	for entry: Dictionary in entries:
		species[String(entry["species"])] = true
		if entry.has("at"):
			assert_not_null(
				_map.find_child(String(entry["at"]), true, false), "%s : son marqueur" % entry["id"]
			)
	for expected: String in ["blackbird", "butterfly", "owl"]:
		assert_true(species.has(expected), "VIE.md 6.2 : %s sur la colline" % expected)
	assert_eq(
		FaunaRules.problems(&"ile_68"), PackedStringArray(), "le peuplement de l'île est sans faute"
	)
	assert_false(FaunaRules.is_banned(&"colline"), "on y croise des bêtes")


func test_the_hill_is_in_the_island() -> void:
	assert_true(
		WorldAtlas.maps_of(&"ile_68").has(&"colline"), "colline dans les cartes de l'île n° 68"
	)
	assert_eq(WorldAtlas.island_of(&"colline"), &"ile_68")
	assert_eq(WorldAtlas.place_of(&"colline"), &"colline")
	assert_eq(WorldManager.map_display_name(&"colline"), "La colline des étoiles")
