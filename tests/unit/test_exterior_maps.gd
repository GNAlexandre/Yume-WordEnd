extends GutTest
## (C1) L'outil des cartes du dehors (tools/exterior_maps.py, docs/lore/CARTE.md) :
## - `check` : toutes les cartes écrites (entrepot, sentier, colline, village, foret_profonde, port,
##   et la carte d'attente
##   du marché) sont celles que l'outil écrirait aujourd'hui d'après les plans ; passé si Python (et
## Pillow) n'est pas là ;
## - les cartes construites en dernier : la forêt profonde (CF) en plus du village, de la colline et
##   du port (tests/unit/
##   test_foret_profonde.gd, test_village.gd, test_colline.gd, test_port.gd) ; l'outil n'a plus de
## carte d'attente que
##   la place du marché (tests/unit/test_ville_attente.gd) ;
## - la carte du port est dans l'île n° 68 (ile_68.json : `maps` et son lieu) ;
## - les listes des places de la vie sont dans CARTE.md (`places`), celle de la forêt comprise.

const CARTE := "res://docs/lore/CARTE.md"


func test_the_tool_finds_every_written_map_up_to_date() -> void:
	var script := ProjectSettings.globalize_path("res://tools/exterior_maps.py")
	var output: Array = []
	var code := OS.execute("python3", [script, "check"], output, true)
	var text := "\n".join(PackedStringArray(output))
	if code == -1 or text.contains("No module named"):
		pending("python3 ou Pillow absent : %s" % text.substr(0, 120))
		return
	assert_eq(code, 0, "tools/exterior_maps.py check : %s" % text.substr(0, 600))
	for map_id: String in ["entrepot", "sentier", "colline", "village", "foret_profonde", "port"]:
		assert_true(text.contains("%s : à jour" % map_id), "%s : à jour" % map_id)


func test_the_port_is_in_the_island() -> void:
	assert_true(WorldAtlas.maps_of(&"ile_68").has(&"port"), "port dans les cartes de l'île n° 68")
	var place := WorldAtlas.place(&"ile_68", &"port")
	assert_true((place["maps"] as Array).has(&"port"), "le lieu du port a sa carte")
	assert_eq(WorldAtlas.island_of(&"port"), &"ile_68")
	assert_eq(WorldAtlas.place_of(&"port"), &"port")
	assert_eq(WorldAtlas.problems(), PackedStringArray(), "îles et mondes sans problème")


func test_the_places_of_life_are_listed_in_the_plan_document() -> void:
	var text := FileAccess.get_file_as_string(CARTE)
	for map_id: String in ["entrepot", "sentier", "village", "colline", "port", "foret_profonde"]:
		assert_true(text.contains("<!-- places:%s -->" % map_id), "liste des places de %s" % map_id)
	var start := text.find("<!-- places:sentier -->")
	var block := text.substr(start, text.find("<!-- /places:sentier -->") - start)
	for place_name: String in [
		"premiere_embuscade", "marais_chute", "embuscade", "corbeau_perchoir"
	]:
		assert_true(block.contains("`%s`" % place_name), "%s dans la liste" % place_name)
