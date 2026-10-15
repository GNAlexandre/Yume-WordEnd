extends "res://tests/stubs/c1_exterior_test.gd"
## (C2) La carte village, le village des hommes-bêtes (src/world/maps/village/, plan de
## docs/lore/CARTE.md, section 5.2, écrite par tools/exterior_maps.py). Base commune
## tests/stubs/c1_exterior_test.gd (plan, sorties, marqueurs, points, circulation à pied, rien ne cache
## le joueur, densité, sol nu, draw calls), plus :
## - les trois sorties : l'entrepôt à l'est (à pied), le café et la maison Limashenka (à invite) ;
## - la maison Limashenka posée, avec la condition du jour 11 en métadonnée pour le récit ;
## - le relief : belvédère de roche à +1 m (rampe au sud), ruisseau à −0,5 m, le vide au nord, rive de
##   sous-bois à l'ouest ;
## - les maisons du plan, à leur emprise, et les scènes du lot R3 (images au manifeste, lot R3) ;
## - les jardins clos derrière les chaumières du sud (on n'y entre pas : un toit cacherait le joueur) ;
## - la place devant le café, libre (la scène `cafe_village`, sans les tables de celle de T1) ;
## - les places de la vie en plus du plan, les objets à examiner et leurs textes ;
## - aucune lumière : Atmosphere éclaire (l'image d'une lanterne est posée, pas une lampe).

const EXTRA_PLACES: Array[String] = [
	"rue_ouest",
	"rue_centre",
	"rue_est",
	"grange_porte",
	"terrasse_banc_1",
	"terrasse_banc_2",
	"meule",
	"charrette",
	"jardin",
	"etal_rue",
	"etal_grange",
	"porte_limashenka_attente",
	"ruisseau_berge",
	"jardins_sud",
]
## Images du lot R3 (cahier n° 5, 5.3) que le village emploie et que le cahier n'a pas livrées.
const R3_IMAGES: Array[String] = [
	"cottage_thatch_a",
	"cottage_thatch_b",
	"cottage_thatch_c",
	"village_barn",
	"village_house_stone",
	"village_shed",
	"fence_wattle",
	"beehives",
	"cart_hay",
	"haystack",
	"washing_trough",
]
const EXAMINABLES: Array[String] = [
	"enseigne_cle",
	"enseigne_cafe",
	"maison_close",
	"lavoir",
	"ruches",
	"belvedere",
	"cascade",
	"meule",
]
const TEXTS := "res://data/texts/village.json"


func before_all() -> void:
	map_id = "village"
	# Les vues du plan (70 à 100 éléments par écran, CARTE.md 5.2) : l'entrée par l'est, la rue, le café, le
	# belvédère, le grand jardin, les chaumières du sud, le lavoir ; un peu plus aux bords, un peu moins sur le
	# belvédère nu.
	density = {
		"entrée": [Vector3(52.0, 0.0, 12.5), 60, 125],
		"rue": [Vector3(30.0, 0.0, 12.5), 60, 125],
		"café": [Vector3(19.8, 0.0, 11.4), 60, 125],
		"grange": [Vector3(8.0, 0.0, 11.5), 60, 125],
		"belvédère": [Vector3(35.0, 1.0, 6.5), 50, 125],
		"jardin": [Vector3(27.0, 0.0, 20.5), 60, 125],
		"chaumières": [Vector3(9.5, 0.0, 28.8), 60, 125],
		"lavoir": [Vector3(8.0, 0.0, 30.2), 60, 125],
		"ruches": [Vector3(50.0, 0.0, 29.0), 60, 125],
	}
	walk_spots = [
		Vector3(50.0, 0.0, 12.5),
		Vector3(19.8, 0.0, 11.0),
		Vector3(44.0, 0.0, 10.6),
		Vector3(35.0, 1.0, 6.0),
		Vector3(27.0, 0.0, 21.0),
		Vector3(8.0, 0.0, 30.4),
		Vector3(53.0, 0.0, 29.6),
		Vector3(4.0, 0.0, 12.5),
		Vector3(2.0, -0.5, 20.0),
		Vector3(30.0, -0.5, 35.5),
	]
	min_walk_area = 1000.0
	min_checked_places = 900
	await super()


# --- Le plan -------------------------------------------------------------------------------------


func test_the_plan_has_what_the_chapter_needs() -> void:
	assert_eq(_lines("sortie").size(), 3, "l'entrepôt, le café, la maison Limashenka")
	assert_eq(_lines("marqueur").size(), 4, "Spawn, from_entrepot, from_cafe, from_maison_limashenka")
	assert_eq(_lines("point").size(), 7, "cafe_porte, cafe_terrasse, limashenka_porte, belvedere_vue, …")
	assert_eq(_lines("place").size(), 2, "devant_cafe, belvedere")
	assert_eq(_lines("bati").size(), 8, "la rangée du nord et la seconde rangée, basse")


func test_the_exits_lead_to_the_warehouse_the_cafe_and_the_house() -> void:
	var to_warehouse := _map.get_node(^"Exits/vers_entrepot") as MapExit
	assert_eq([to_warehouse.target_map, to_warehouse.target_marker], [&"entrepot", &"from_village"])
	assert_eq(to_warehouse.prompt, "", "on passe en marchant")
	var to_cafe := _map.get_node(^"Exits/porte_cafe") as MapExit
	assert_eq([to_cafe.target_map, to_cafe.target_marker], [&"cafe", &"from_village"])
	assert_eq(to_cafe.prompt, "Entrer")
	var to_house := _map.get_node(^"Exits/porte_limashenka") as MapExit
	assert_eq(
		[to_house.target_map, to_house.target_marker], [&"maison_limashenka", &"from_village"]
	)
	assert_eq(to_house.prompt, "Entrer")
	for target: StringName in [&"entrepot", &"cafe", &"maison_limashenka"]:
		assert_true(Map.exists(target), "la carte %s existe" % target)
	assert_eq(_map.get_node(^"Exits").get_child_count(), 3, "trois sorties, pas une de plus")


## Le café a sa porte au droit de celle de sa façade livrée (cafe.png : x = 19,76 m).
func test_the_cafe_door_is_where_its_facade_has_it() -> void:
	var door := _map.get_node(^"Exits/porte_cafe") as MapExit
	assert_almost_eq(door.global_position.x, 19.8, 0.1, "la sortie est devant la porte de la façade")
	var bell := _map.find_child("ClocheCafe", true, false) as DecorPanel
	assert_not_null(bell, "la clochette animée de la porte")
	if bell != null:
		assert_gt(bell.frames, 1, "elle bouge")
		assert_almost_eq(bell.global_position.x, 19.78, 0.05)


## La maison Limashenka n'ouvre qu'au jour 11 (ACTE1.md 11.3) : la porte est posée, la condition est dite en
## métadonnée pour le récit (le moteur des cartes ne sait pas encore fermer une porte).
func test_the_house_door_carries_the_day_eleven_condition() -> void:
	var door := _map.get_node(^"Exits/porte_limashenka") as MapExit
	assert_eq(int(door.get_meta(&"open_from_day", 0)), 11, "ouverte à partir du jour 11")
	var key := String(door.get_meta(&"closed_text_key", ""))
	assert_eq(key, "village/maison_close", "le texte de la maison close")
	var texts: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TEXTS))
	assert_true(String((texts["village"] as Dictionary)["maison_close"]).contains("close"))
	assert_false(_map.get_node(^"Exits/porte_cafe").has_meta(&"open_from_day"), "le café est toujours ouvert")


# --- Le relief et le bord de l'île --------------------------------------------------------------------


func test_the_relief_follows_the_plan() -> void:
	assert_almost_eq(_ground.height_at(35.0, 6.0), 1.0, 0.05, "le belvédère, +1 m")
	assert_almost_eq(_ground.height_at(30.0, 12.5), 0.0, 0.05, "la rue")
	assert_almost_eq(_ground.height_at(2.0, 20.0), -0.5, 0.05, "le ruisseau, −0,5 m")
	assert_almost_eq(_ground.height_at(30.0, 35.5), -0.5, 0.05, "le ruisseau du sud")
	assert_almost_eq(_ground.height_at(0.5, 20.0), -0.5, 0.05, "la rive de sous-bois à l'ouest")
	var ramp := _ground.height_at(35.0, 10.0)
	assert_between(ramp, 0.05, 0.95, "à mi-rampe du belvédère (x 33 → 37, z 9 → 11)")
	assert_true(_is_reached(Vector3(35.0, 1.0, 6.0)), "on monte au belvédère par la rampe, sans sauter")
	assert_gte(_level_count(), 3, "au moins trois niveaux de relief")


func _level_count() -> int:
	var levels := {}
	for x in range(1, int(_map.size.x), 3):
		for z in range(1, int(_map.size.y), 3):
			levels[snappedf(_ground.height_at(float(x), float(z)), 0.5)] = true
	return levels.size()


func test_the_island_ends_in_the_void_to_the_north() -> void:
	for x: float in [5.0, 20.0, 35.0, 50.0]:
		assert_false(_ground.is_walkable(x, 1.0), "le vide au nord, x = %.0f" % x)
	assert_true(_ground.is_walkable(35.0, 5.0), "le belvédère se marche jusqu'à son bord")
	var cascade := _map.find_child("Cascade", true, false) as DecorPanel
	assert_not_null(cascade, "la cascade du ruisseau, au coin nord-ouest")
	if cascade != null:
		assert_gt(cascade.frames, 1, "elle coule")
		assert_lt(cascade.global_position.z, 3.0, "au-dessus du vide")
	var sky := _map.get_node_or_null(^"Geometry/Sky")
	assert_not_null(sky, "les îles et les rochers au loin")
	if sky != null:
		assert_gt(sky.get_child_count(), 3)


func test_the_stream_water_is_walkable() -> void:
	assert_true(_ground.is_walkable(2.0, 20.0), "l'eau basse du ruisseau : on y marche")
	assert_true(_ground.is_walkable(30.0, 35.5), "le ruisseau du sud aussi")
	assert_true(_is_reached(Vector3(2.0, -0.5, 20.0)), "on y descend")


# --- Les maisons, les décors et les images -----------------------------------------------------------


## Chaque maison du plan est posée à son emprise (les rectangles du plan).
func test_every_house_of_the_plan_is_in_place() -> void:
	var houses := _map.get_node(^"Geometry/Houses")
	for words in _lines("bati"):
		var rect := _rect(words, 2)
		var scene := String(words[7])
		if scene == "cafe":
			scene = "cafe_village"
		var found: Building = null
		for child: Node in houses.get_children():
			var building := child as Building
			if building != null and building.facade.resource_path.get_file().get_basename() == String(words[7]):
				found = building
		assert_not_null(found, "bâtiment %s (%s)" % [words[1], words[7]])
		if found == null:
			continue
		assert_almost_eq(
			Vector2(found.global_position.x, found.global_position.z),
			rect.get_center(),
			Vector2.ONE * 0.01,
			"%s : au centre de son emprise" % words[1]
		)
		assert_almost_eq(found.footprint.x, rect.size.x, 0.01, "%s : largeur du plan" % words[1])
		assert_almost_eq(found.footprint.y, rect.size.y, 0.01, "%s : profondeur du plan" % words[1])
		assert_almost_eq(found.ridge_height, float(words[6]), 0.01, "%s : faîte du plan" % words[1])
		assert_not_null(found.side_facade, "%s : un flanc" % words[1])


func test_the_decors_of_the_plan_are_there() -> void:
	var images := {}
	for element: Array in _elements:
		images[String(element[1]).get_file().get_basename()] = true
	for words in _lines("decor"):
		var found := false
		for suffix: String in ["", "_fg", "_forest", "_libre"]:
			found = found or images.has(words[1] + suffix)
		assert_true(found, "décor %s (ligne du plan)" % words[1])


func test_the_replacement_images_of_lot_r3_are_in_the_manifest_and_used() -> void:
	var manifest: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://tools/hd2d_manifest.json")
	)
	var listed := {}
	for entry: Dictionary in manifest["images"]:
		listed[String(entry["path"]).get_file().get_basename()] = String(entry.get("lot", ""))
	var images := {}
	for element: Array in _elements:
		images[String(element[1]).get_file().get_basename()] = true
	for image_name in R3_IMAGES:
		assert_eq(listed.get(image_name, ""), "R3", "%s au manifeste, lot R3" % image_name)
		assert_true(images.has(image_name), "%s posée dans la carte" % image_name)
		assert_true(
			(
				FileAccess.file_exists("res://assets/hd2d/props/%s.png" % image_name)
				or FileAccess.file_exists("res://assets/hd2d/buildings/%s.png" % image_name)
			),
			"%s existe" % image_name
		)
	for material_name: String in ["roof_thatch", "wall_wattle_daub"]:
		assert_eq(listed.get(material_name, ""), "R3", "matière %s au manifeste" % material_name)


## Ce que dépasse 1,2 m au sud d'un endroit où l'on marche passe en premier plan : la meule, la charrette,
## l'épouvantail et le tas de bûches ont leur variante.
func test_tall_decors_in_the_garden_are_foreground_panels() -> void:
	for node_name: String in ["Meule", "Charrette", "Epouvantail", "Buches"]:
		var panel := _map.find_child(node_name, true, false) as DecorPanel
		assert_not_null(panel, node_name)
		if panel != null:
			assert_true(panel.foreground, "%s : premier plan, il s'efface devant le joueur" % node_name)


# --- Les jardins clos et la place du café -----------------------------------------------------------------


## Derrière une chaumière du sud, un toit de 5 m cacherait le joueur sur 7 m : rien n'y marche.
func test_the_gardens_behind_the_cottages_are_closed() -> void:
	for spot: Vector3 in [
		Vector3(9.0, 0.0, 19.0), Vector3(46.0, 0.0, 20.0), Vector3(52.0, 0.0, 19.5), Vector3(12.0, 0.0, 21.0)
	]:
		assert_false(_is_reached(spot), "%s : un jardin clos" % spot)
	for spot: Vector3 in [Vector3(16.0, 0.0, 19.0), Vector3(27.0, 0.0, 21.0), Vector3(41.0, 0.0, 20.0)]:
		assert_true(_is_reached(spot), "%s : les ruelles et le grand jardin se marchent" % spot)


func test_the_square_in_front_of_the_cafe_is_free() -> void:
	var cafe := _map.get_node(^"Geometry/Houses/Cafe") as Building
	assert_not_null(cafe, "le café a sa scène, sans les tables de celle de T1")
	var tables := 0
	for shape: Node in cafe.find_children("*", "CollisionShape3D", true, false):
		if (shape as CollisionShape3D).shape is CylinderShape3D:
			tables += 1
	assert_eq(tables, 0, "aucune table de terrasse dans la scène")
	var area := _map.get_node(^"Life/Areas/devant_cafe") as Marker3D
	assert_eq(_blocking_in((area.get_meta(&"area") as Rect2).grow(-0.4)), [] as Array[String])


# --- La vie ---------------------------------------------------------------------------------------


func test_the_extra_life_places_are_named_and_reached() -> void:
	for place_name in EXTRA_PLACES:
		var place := _map.get_node_or_null(NodePath("Life/Places/" + place_name)) as Marker3D
		assert_not_null(place, "place de la vie %s" % place_name)
		if place != null:
			assert_true(_is_reached(place.global_position), "%s : on y va" % place_name)
	assert_eq(
		_map.get_node(^"Life/Places").get_child_count(),
		_lines("point").size() + EXTRA_PLACES.size(),
		"les points du plan et les places en plus"
	)


## Les places que VIE.md et ACTE1.md citent par leur nom (village:cafe_terrasse, village:lavoir…).
func test_the_places_of_the_other_documents_exist() -> void:
	for place_name: String in ["cafe_terrasse", "lavoir", "ruche", "cascade_vue", "belvedere_vue", "limashenka_porte"]:
		assert_not_null(_map.get_node_or_null(NodePath("Life/Places/" + place_name)), place_name)


func test_the_things_to_examine_have_their_text() -> void:
	var root := _map.get_node_or_null(^"Examine")
	assert_not_null(root, "les objets à examiner")
	if root == null:
		return
	assert_eq(root.get_child_count(), EXAMINABLES.size())
	var json := JSON.new()
	assert_eq(json.parse(FileAccess.get_file_as_string(TEXTS)), OK, "village.json lisible")
	assert_eq(DialogueRunner.story_problem(json.data), "", "format des textes de l'histoire")
	for key in EXAMINABLES:
		var item := root.get_node_or_null(NodePath(key)) as Examinable
		assert_not_null(item, "objet %s" % key)
		if item == null:
			continue
		assert_eq(item.text_key, "village/" + key)
		assert_eq(item.texts_path, TEXTS)
		assert_false(item.text_value().is_empty(), "%s : un texte" % key)
		assert_true(item.is_in_group(&"interactable"), "%s : interactable" % key)
		assert_true(_is_reached(item.global_position), "%s : on s'en approche à pied" % key)


# --- Aucune lumière ---------------------------------------------------------------------------------


## Aucune lampe dans la carte : Atmosphere éclaire (la nuit, la lumière des fenêtres est celle des vitres de nuit).
## L'image d'une lanterne est posée sur la façade du café (le plan la cite), sans lumière.
func test_the_map_carries_no_light() -> void:
	var own: Array[String] = []
	for light: Node in _map.find_children("*", "Light3D", true, false):
		if not String(_map.get_path_to(light)).contains("AtmosphereRig"):
			own.append(String(_map.get_path_to(light)))
	assert_eq(own, [] as Array[String], "aucune lampe dans la carte")
	assert_null(_map.get_node_or_null(^"Lights"), "pas de nœud de lumières")
	for element: Array in _elements:
		var image: String = element[1]
		for lamp: String in ["lamp", "lampadaire", "torch"]:
			assert_false(image.get_file().contains(lamp), "%s : un décor de lampe" % image)


func test_the_map_light_is_left_to_atmosphere() -> void:
	assert_eq(_map.light_preset, &"", "le préréglage du moment")
