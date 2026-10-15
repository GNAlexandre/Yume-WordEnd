extends GutTest
## (C1) L'outil des cartes du dehors (tools/exterior_maps.py, docs/lore/CARTE.md) :
## - `check` : toutes les cartes écrites (entrepot, sentier, village, et les cartes d'attente) sont
## celles
##   que l'outil écrirait aujourd'hui d'après les plans ; passé si Python (et Pillow) n'est pas là ;
## - les cartes d'attente (colline, foret_profonde, port) : le nom et le lieu du plan, la
##   sortie de retour vers la carte construite, au marqueur d'arrivée du plan, `Spawn` et marqueur
##   d'arrivée, écriteau « Plus loin, bientôt », rien de plus ;
## - la carte du port d'attente est dans l'île n° 68 (ile_68.json : `maps` et son lieu) ;
## - les listes des places de la vie sont dans CARTE.md (`places`).

const CARTE := "res://docs/lore/CARTE.md"
## Cartes d'attente : [nom du plan, lieu, sortie de retour, carte cible, marqueur de retour,
## marqueur d'arrivée].
const WAITING := {
	&"colline":
	[
		"La colline des étoiles",
		&"colline",
		&"vers_entrepot",
		&"entrepot",
		&"from_colline",
		&"from_entrepot"
	],
	&"foret_profonde":
	[
		"La forêt profonde",
		&"foret_profonde",
		&"vers_entrepot",
		&"entrepot",
		&"from_foret_profonde",
		&"from_entrepot"
	],
	&"port": ["Le port", &"port", &"vers_sentier", &"sentier", &"from_port", &"from_sentier"],
}


func test_the_tool_finds_every_written_map_up_to_date() -> void:
	var script := ProjectSettings.globalize_path("res://tools/exterior_maps.py")
	var output: Array = []
	var code := OS.execute("python3", [script, "check"], output, true)
	var text := "\n".join(PackedStringArray(output))
	if code == -1 or text.contains("No module named"):
		pending("python3 ou Pillow absent : %s" % text.substr(0, 120))
		return
	assert_eq(code, 0, "tools/exterior_maps.py check : %s" % text.substr(0, 600))
	for map_id: String in ["entrepot", "sentier", "village", "colline", "foret_profonde", "port"]:
		assert_true(text.contains("%s : à jour" % map_id), "%s : à jour" % map_id)


func test_waiting_maps_keep_their_exit_back_and_their_sign() -> void:
	for map_id: StringName in WAITING:
		var spec: Array = WAITING[map_id]
		assert_true(Map.exists(map_id), "%s existe" % map_id)
		var map := (load(Map.scene_path(map_id)) as PackedScene).instantiate() as Map
		add_child(map)
		await wait_physics_frames(1)
		assert_eq(map.display_name, spec[0], "%s : nom du plan" % map_id)
		assert_eq(map.region, spec[1], "%s : lieu" % map_id)
		assert_eq(map.size, Vector2(32, 24), "%s : carte d'attente de 32 × 24 m" % map_id)
		assert_eq(Map.problems(map), PackedStringArray(), "%s : contrat des cartes" % map_id)
		var exit := map.get_node_or_null(NodePath("Exits/" + String(spec[2]))) as MapExit
		assert_not_null(exit, "%s : sortie %s" % [map_id, spec[2]])
		if exit != null:
			assert_eq(exit.target_map, spec[3], "%s : carte cible" % map_id)
			assert_eq(exit.target_marker, spec[4], "%s : marqueur de retour" % map_id)
			assert_eq(exit.prompt, "", "%s : on passe en marchant" % map_id)
		assert_not_null(map.marker(spec[5] as StringName), "%s : marqueur d'arrivée" % map_id)
		assert_not_null(map.marker(&"Spawn"), "%s : Spawn" % map_id)
		assert_not_null(map.get_node_or_null(^"Geometry/Sign"), "%s : écriteau" % map_id)
		assert_eq(map.get_node(^"Exits").get_child_count(), 1, "%s : une seule sortie" % map_id)
		map.free()


func test_the_waiting_port_is_in_the_island() -> void:
	assert_true(WorldAtlas.maps_of(&"ile_68").has(&"port"), "port dans les cartes de l'île n° 68")
	var place := WorldAtlas.place(&"ile_68", &"port")
	assert_true((place["maps"] as Array).has(&"port"), "le lieu du port a sa carte")
	assert_eq(WorldAtlas.island_of(&"port"), &"ile_68")
	assert_eq(WorldAtlas.place_of(&"port"), &"port")
	assert_eq(WorldAtlas.problems(), PackedStringArray(), "îles et mondes sans problème")


func test_the_places_of_life_are_listed_in_the_plan_document() -> void:
	var text := FileAccess.get_file_as_string(CARTE)
	for map_id: String in ["entrepot", "sentier", "village"]:
		assert_true(text.contains("<!-- places:%s -->" % map_id), "liste des places de %s" % map_id)
	var start := text.find("<!-- places:sentier -->")
	var block := text.substr(start, text.find("<!-- /places:sentier -->") - start)
	for place_name: String in [
		"premiere_embuscade", "marais_chute", "embuscade", "corbeau_perchoir"
	]:
		assert_true(block.contains("`%s`" % place_name), "%s dans la liste" % place_name)
