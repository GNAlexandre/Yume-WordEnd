extends "res://tests/stubs/c1_exterior_test.gd"
## (C1) La carte sentier, le sentier et le marais (src/world/maps/sentier/, plan de
## docs/lore/CARTE.md, section 4, écrite par tools/exterior_maps.py). Base commune
## tests/stubs/c1_exterior_test.gd (plan, sorties, marqueurs, points, circulation à pied, rien ne
## cache le joueur, densité, sol nu, draw calls, aucune lumière), plus :
## - les sorties vers l'entrepôt et le port (carte d'attente) ; le chemin de la ville n'a pas de
##   sortie tant que ville_haute n'existe pas, un écriteau à sa place ;
## - le relief : lisière +1 m, marais −0,5 m (eau basse praticable), levée du sentier à 0, chemin de
##   la ville qui descend par sa rampe, les deux descentes de la levée dans le marais ;
## - les décors du plan et les images du cahier n° 5 (lot R3) ;
## - le point premiere_embuscade de ACTE1.md sur le sentier, les places de la vie en plus du plan ;
## - la carte ne porte aucune lumière : la nuit est celle d'Atmosphere et de la lumière des fées.

const EXTRA_PLACES: Array[String] = [
	"sentier_ouest",
	"sentier_milieu",
	"sentier_est",
	"fourche_ville",
	"marais_berge_ouest",
	"marais_berge_est",
	"corbeau_perchoir",
	"lisiere_renard",
	"merle_sol",
]
const R3_IMAGES: Array[String] = [
	"marsh_reed_wall",
	"path_edge_ferns",
	"path_root_step",
	"bog_pool_a",
	"path_stones_a",
	"path_stones_b",
]


func before_all() -> void:
	map_id = "sentier"
	# Les vues du plan : l'entrée, le sentier, le marais, l'embuscade, la berge, la fourche. 80 à 120
	# éléments par écran (CARTE.md 4.2) ; la berge et le chemin de la ville, entre les roseaux et la
	# mousse, un peu plus.
	density = {
		"entrée": [Vector3(6.0, 0.0, 24.0), 80, 125],
		"ouest": [Vector3(14.0, 0.0, 24.0), 80, 125],
		"milieu": [Vector3(40.0, 0.0, 23.0), 80, 125],
		"marais": [Vector3(36.0, -0.5, 12.0), 80, 125],
		"embuscade": [Vector3(34.0, 0.0, 21.0), 80, 125],
		"berge": [Vector3(22.0, 0.0, 20.5), 80, 140],
		"est": [Vector3(70.0, 0.0, 22.0), 80, 125],
		"fourche": [Vector3(60.0, 0.0, 24.5), 80, 125],
		"chemin de la ville": [Vector3(67.0, -0.5, 34.0), 80, 140],
	}
	walk_spots = [
		Vector3(2.0, 0.0, 24.0),
		Vector3(78.0, 0.0, 21.6),
		Vector3(36.0, -0.5, 12.0),
		Vector3(20.0, -0.5, 9.0),
		Vector3(55.0, -0.5, 16.0),
		Vector3(62.0, 0.0, 27.0),
		Vector3(68.0, -0.5, 38.0),
		Vector3(30.0, 0.0, 20.0),
	]
	min_walk_area = 1400.0
	min_checked_places = 1000
	await super()


# --- Le plan -------------------------------------------------------------------------------------


func test_the_plan_has_what_the_chapter_needs() -> void:
	assert_eq(_lines("sortie").size(), 3, "vers l'entrepôt, le port, la ville")
	assert_eq(_lines("marqueur").size(), 4, "Spawn, from_entrepot, from_port, from_ville_haute")
	assert_eq(_lines("point").size(), 6, "marais_chute, lumiere_pannibal, chtholly_arrivee, …")
	assert_eq(_lines("place").size(), 1, "embuscade")


func test_the_exits_lead_to_the_warehouse_and_the_port() -> void:
	var to_warehouse := _map.get_node(^"Exits/vers_entrepot") as MapExit
	assert_eq(to_warehouse.target_map, &"entrepot")
	assert_eq(to_warehouse.target_marker, &"from_sentier")
	assert_eq(to_warehouse.prompt, "", "on passe en marchant")
	var to_port := _map.get_node(^"Exits/vers_port") as MapExit
	assert_eq(to_port.target_map, &"port")
	assert_eq(to_port.target_marker, &"from_sentier")
	assert_true(Map.exists(&"port"), "la carte du port existe (d'attente jusqu'à son lot)")
	assert_not_null(_map.marker(&"from_entrepot"), "arrivée de l'entrepôt")
	assert_not_null(_map.marker(&"from_port"), "arrivée du port")
	assert_not_null(_map.marker(&"from_ville_haute"), "arrivée de la ville")


## Le chemin de la ville : sa sortie vers ville_haute ne s'écrit que si la carte existe ; sinon un
## écriteau « Plus loin, bientôt » ferme le chemin (l'outil remet la sortie dès que la carte
## arrive).
func test_the_city_path_ends_in_a_sign_until_the_city_exists() -> void:
	var exit := _map.get_node_or_null(^"Exits/vers_ville") as MapExit
	var sign_node := _map.get_node_or_null(^"Geometry/Fork/SignVille")
	if Map.exists(&"ville_haute"):
		assert_not_null(exit, "la ville existe : sa sortie")
		assert_null(sign_node, "plus d'écriteau")
		return
	assert_null(exit, "pas de sortie vers une carte absente")
	assert_not_null(sign_node, "l'écriteau au bout du chemin de la ville")
	var at := (sign_node as Node3D).global_position
	assert_between(at.z, 34.0, 39.0, "au bout du chemin, près de son extrémité sud")
	assert_true(_is_reached(at), "on peut le lire")


# --- Le relief
# -------------------------------------------------------------------------------------


func test_the_relief_follows_the_plan() -> void:
	assert_almost_eq(_ground.height_at(40.0, 2.5), 1.0, 0.05, "la lisière nord, +1 m")
	assert_almost_eq(_ground.height_at(36.0, 12.0), -0.5, 0.05, "le marais, −0,5 m")
	assert_almost_eq(_ground.height_at(40.0, 23.0), 0.0, 0.05, "la levée du sentier, 0")
	assert_almost_eq(_ground.height_at(68.0, 37.0), -0.5, 0.05, "le chemin de la ville, −0,5 m")
	var ramp := _ground.height_at(66.0, 28.0)
	assert_between(ramp, -0.45, -0.05, "à mi-rampe (x 62 → 70, z 26 → 30)")
	for x: float in [34.5, 53.5]:
		var down := _ground.height_at(x, 19.0)
		assert_between(down, -0.45, -0.05, "à mi-descente de la levée dans le marais, x = %.1f" % x)
		assert_true(_is_reached(Vector3(x, down, 19.0)), "on descend sans sauter, x = %.1f" % x)
	assert_gte(_level_count(), 3, "au moins trois niveaux de relief")


func _level_count() -> int:
	var levels := {}
	for x in range(1, int(_map.size.x), 3):
		for z in range(1, int(_map.size.y), 3):
			levels[snappedf(_ground.height_at(float(x), float(z)), 0.5)] = true
	return levels.size()


func test_the_marsh_water_is_walkable() -> void:
	assert_true(_ground.is_walkable(36.0, 12.0), "l'eau basse du marais : on y marche")
	assert_true(_ground.is_walkable(35.5, 16.5), "marais_chute : là où tombe Willem")
	assert_true(_is_reached(Vector3(40.0, -0.5, 12.5)), "lumiere_pannibal : on y va")


# --- Les décors et les images --------------------------------------------------------------------


func test_the_decors_of_the_plan_are_there() -> void:
	var images := {}
	for element: Array in _elements:
		images[String(element[1]).get_file().get_basename()] = true
	for words in _lines("decor"):
		var found := false
		for suffix: String in ["", "_fg", "_forest"]:
			found = found or images.has(words[1] + suffix)
		assert_true(found, "décor %s (ligne du plan)" % words[1])
	for words in _lines("arbre"):
		var found := false
		for suffix: String in ["", "_fg", "_forest"]:
			found = found or images.has(words[1] + suffix)
		assert_true(found, "arbre %s" % words[1])


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
			ResourceLoader.exists("res://assets/hd2d/%s.png" % _folder_of(image_name)),
			"%s existe" % image_name
		)


func _folder_of(image_name: String) -> String:
	for folder: String in ["props", "decals"]:
		if FileAccess.file_exists("res://assets/hd2d/%s/%s.png" % [folder, image_name]):
			return "%s/%s" % [folder, image_name]
	return image_name


## (QC) La voûte de feuillage (`fg_canopy_a`) n'est plus posée en l'air au-dessus du sentier : vue
## par la caméra, c'était une masse sombre suspendue au milieu de l'écran (docs/QUALITE.md, QC-12).
## Elle attend le premier plan accroché à l'écran (E10).
func test_no_canopy_floats_over_the_path() -> void:
	for element: Array in _elements:
		var at: Vector3 = element[2]
		if String(element[1]).get_file() == "fg_canopy_a.png":
			fail_test("voûte fg_canopy_a posée en %s" % at)
	pass_test("aucune voûte suspendue")


# --- La vie ---------------------------------------------------------------------------------------


func test_the_first_ambush_point_is_on_the_path() -> void:
	var point := _map.get_node(^"Life/Places/premiere_embuscade") as Marker3D
	assert_almost_eq(point.global_position.x, 16.0, 0.01)
	assert_almost_eq(point.global_position.z, 23.0, 0.01)
	assert_true(_is_reached(point.global_position), "ACTE1.md 1.2 : on y marche")


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


# --- La nuit
# ----------------------------------------------------------------------------------------


func test_the_map_light_is_left_to_atmosphere() -> void:
	assert_eq(_map.light_preset, &"", "le préréglage du moment (nuit : celui d'E9)")
	assert_null(_map.get_node_or_null(^"Lights/lanterne_porte"), "aucune lanterne")
	var lights := _map.get_node_or_null(^"Lights")
	if lights != null:
		assert_eq(lights.get_child_count(), 0, "aucune lumière dans la carte")
