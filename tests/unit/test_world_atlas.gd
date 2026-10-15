extends GutTest
## (X1) L'atlas du monde (src/world/world_atlas.gd, data/world/) : format des mondes et des îles
## (clé inconnue refusée, carte ou marqueur absents signalés), chaque carte de src/world/maps dans
## une île déclarée (et Map.island qui le répète), les cartes de chaque île existantes, règles
## (pas de Timere sur l'île n° 68, Timeres permis à la surface et sur l'ancienne île ; mer de
## nuages ou sol jusqu'à l'horizon), ports et arrivées, graphe des lieux, quais des cartes,
## chemins du contenu par île.

const ILE_68 := &"ile_68"
const ILE_ESSAI := &"ile_essai"
const LEGACY := &"ile_ancienne"
const SURFACE := &"surface_essai"
## Dossier de travail des fichiers d'essai (mondes et îles écrits par les tests).
const TEMP_DIR := "user://test_world_atlas"


func before_each() -> void:
	WorldAtlas.set_data_dirs()


func after_each() -> void:
	WorldAtlas.set_data_dirs()
	_remove_temp_dir()


## Une île valide minimale (à modifier par chaque test).
func _island() -> Dictionary:
	return {
		"name": "Île de test",
		"maps": ["essai"],
		"arrival_map": "essai",
		"places": {"essai": {"name": "Essai", "maps": ["essai"]}},
		"ports": {"quai": {"name": "Quai", "map": "essai", "marker": "from_dirigeable"}},
	}


func _joined(problems: PackedStringArray) -> String:
	return "; ".join(problems)


## Écrit des mondes et des îles d'essai dans TEMP_DIR et y fait lire l'atlas.
func _use_files(worlds: Dictionary, islands: Dictionary) -> void:
	_remove_temp_dir()
	for kind: String in ["worlds", "islands"]:
		DirAccess.make_dir_recursive_absolute(TEMP_DIR.path_join(kind))
		var files: Dictionary = worlds if kind == "worlds" else islands
		for id: String in files:
			var file := FileAccess.open(
				TEMP_DIR.path_join(kind).path_join(id + ".json"), FileAccess.WRITE
			)
			var content: Variant = files[id]
			file.store_string(content if content is String else JSON.stringify(content))
			file.close()
	WorldAtlas.set_data_dirs(TEMP_DIR.path_join("worlds"), TEMP_DIR.path_join("islands"))


func _remove_temp_dir() -> void:
	for kind: String in ["worlds", "islands"]:
		var dir := TEMP_DIR.path_join(kind)
		if not DirAccess.dir_exists_absolute(dir):
			continue
		for file: String in DirAccess.get_files_at(dir):
			DirAccess.remove_absolute(dir.path_join(file))
		DirAccess.remove_absolute(dir)
	if DirAccess.dir_exists_absolute(TEMP_DIR):
		DirAccess.remove_absolute(TEMP_DIR)


# --- Les vraies données -----------------------------------------------------------------------


func test_world_data_is_valid() -> void:
	var problems := WorldAtlas.problems()
	assert_eq(problems.size(), 0, _joined(problems))


func test_worlds_and_their_islands() -> void:
	assert_eq(WorldAtlas.worlds(), [&"regule_aire", &"surface"] as Array[StringName])
	assert_eq(WorldAtlas.world_name(&"regule_aire"), "Regule Aire")
	assert_eq(WorldAtlas.islands(&"regule_aire"), [ILE_68, ILE_ESSAI, LEGACY] as Array[StringName])
	assert_eq(WorldAtlas.islands(&"surface"), [SURFACE] as Array[StringName])
	assert_eq(WorldAtlas.world_of(ILE_68), &"regule_aire")
	assert_eq(WorldAtlas.world_of(SURFACE), &"surface")
	assert_eq(WorldAtlas.island_name(ILE_68), "L'île n° 68")
	assert_eq(WorldAtlas.island_number(ILE_68), 68)
	assert_eq(WorldAtlas.island_number(SURFACE), 0, "la surface n'a pas de numéro")
	assert_true(WorldAtlas.is_legacy(LEGACY), "l'ancienne île, retirée en phase 5")
	assert_false(WorldAtlas.is_legacy(ILE_68))
	assert_eq(WorldAtlas.arrival_map(ILE_68), &"entrepot", "carte d'arrivée par défaut")


func test_every_map_belongs_to_a_declared_island() -> void:
	for map_id: StringName in Map.all_ids():
		var island := WorldAtlas.island_of(map_id)
		assert_ne(island, &"", "%s : dans une île de data/world/islands" % map_id)
		assert_eq(WorldAtlas.scene_island(map_id), island, "%s : Map.island = son île" % map_id)
	for island: StringName in WorldAtlas.islands():
		assert_false(WorldAtlas.maps_of(island).is_empty(), "%s a des cartes" % island)
		for map_id: StringName in WorldAtlas.maps_of(island):
			assert_true(Map.exists(map_id), "%s : carte %s existante" % [island, map_id])
	for map_id: StringName in [
		&"entrepot",
		&"entrepot_rdc",
		&"entrepot_etage",
		&"entrepot_toit",
		&"salle_des_armes",
		&"essai",
	]:
		assert_eq(WorldAtlas.island_of(map_id), ILE_68, "%s sur l'île n° 68" % map_id)
	assert_eq(WorldAtlas.island_of(&"ile_ancienne"), LEGACY, "l'ancienne île à part")
	assert_eq(WorldAtlas.island_of(&"nulle_part"), &"", "carte inconnue : aucune île")


func test_map_island_defaults_to_68() -> void:
	var map := Map.new()
	assert_eq(map.island, ILE_68, "aucune carte existante n'a à le dire")
	map.free()


func test_places_follow_the_regions_of_their_maps() -> void:
	for island: StringName in WorldAtlas.islands():
		for place_id: StringName in WorldAtlas.places_of(island):
			for map_id: StringName in WorldAtlas.place(island, place_id)["maps"]:
				assert_eq(_scene_region(map_id), place_id, "%s : region = lieu" % map_id)
	var entrepot := WorldAtlas.place(ILE_68, &"entrepot")
	assert_eq(entrepot["name"], "L'entrepôt des fées")
	assert_true(entrepot["start_known"], "connu dès le début (CARTE.md 1.2)")
	assert_eq((entrepot["links"] as Dictionary).get(&"village"), 250.0, "250 marmer du village")
	var port := WorldAtlas.place(ILE_68, &"port")
	assert_eq(
		(port["links"] as Dictionary).get(&"sentier"), 250.0, "lien déclaré dans l'autre sens"
	)
	assert_eq((port["links"] as Dictionary).get(&"ville"), 2000.0, "2 000 marmer (le panneau)")
	assert_eq(WorldAtlas.place_of(&"entrepot_rdc"), &"entrepot")
	assert_eq(WorldAtlas.place_of(&"essai"), &"", "carte d'essai hors du graphe")
	assert_eq(WorldAtlas.place(ILE_68, &"nulle_part"), {})


func test_ports_and_arrivals() -> void:
	assert_eq(WorldAtlas.ports_of(ILE_68), [&"essai"] as Array[StringName])
	assert_eq(WorldAtlas.port(ILE_68, &"essai")["map"], &"essai", "port provisoire")
	assert_eq(
		WorldAtlas.arrival(ILE_ESSAI),
		{"map": &"quai_essai", "marker": &"from_dirigeable", "port": &"quai"},
		"sans port : le premier"
	)
	assert_eq(WorldAtlas.arrival(SURFACE, &"campement")["map"], &"surface_essai")
	assert_eq(
		WorldAtlas.arrival(LEGACY),
		{"map": &"ile_ancienne", "marker": &"Spawn", "port": &""},
		"sans port du tout : la carte d'arrivée"
	)
	assert_eq(WorldAtlas.arrival(&"nulle_part"), {}, "île inconnue")
	assert_eq(WorldAtlas.arrival(ILE_68, &"nulle_part"), {}, "port inconnu")


func test_every_port_has_a_dock_and_every_dock_a_destination() -> void:
	var docks_by_map := {}
	for map_id: StringName in Map.all_ids():
		var map := (load(Map.scene_path(map_id)) as PackedScene).instantiate() as Map
		var docks: Array[AirshipDock] = []
		for node: Node in map.find_children("*", "", true, false):
			if node is AirshipDock:
				docks.append(node as AirshipDock)
		for dock: AirshipDock in docks:
			assert_eq(dock.destination_problem(), "", "%s/%s" % [map_id, dock.name])
			assert_eq(dock.get_parent().name, &"Docks", "%s/%s sous Docks" % [map_id, dock.name])
		docks_by_map[map_id] = docks.size()
		map.free()
	for island: StringName in WorldAtlas.islands():
		for port_id: StringName in WorldAtlas.ports_of(island):
			var map_id: StringName = WorldAtlas.port(island, port_id)["map"]
			assert_gt(
				int(docks_by_map.get(map_id, 0)),
				0,
				"%s/%s : un quai pour repartir" % [island, port_id]
			)


# --- Règles -----------------------------------------------------------------------------------


func test_no_timere_on_island_68() -> void:
	for map_id: StringName in WorldAtlas.maps_of(ILE_68):
		var rules := WorldAtlas.rules_for(map_id)
		assert_false(rules.enemies_allowed, "%s : pas de Timere" % map_id)
		assert_true(rules.clouds_below(), "%s : la mer de nuages sous le bord" % map_id)
		assert_eq(rules.sky, &"", "%s : le ciel du moment" % map_id)
		assert_eq(rules.void_fall, IslandRules.FALL_LAST_SAFE)
		assert_eq(rules.island, ILE_68)
	assert_false(WorldAtlas.rules_of_island(ILE_ESSAI).enemies_allowed, "règle du monde")


func test_timeres_allowed_on_the_surface_and_the_legacy_island() -> void:
	var surface := WorldAtlas.rules_for(&"surface_essai")
	assert_true(surface.enemies_allowed, "la surface : leurs nids")
	assert_true(surface.ground_below(), "un sol jusqu'à l'horizon")
	assert_false(surface.clouds_below(), "pas de mer de nuages")
	assert_eq(surface.sky, &"apres_midi", "un désert gris sous un ciel bleu")
	var legacy := WorldAtlas.rules_for(&"ile_ancienne")
	assert_true(legacy.enemies_allowed, "l'ancienne île garde ses Timeres (phase 5)")
	assert_eq(legacy.void_fall, IslandRules.FALL_ARRIVAL, "ses zones ramènent au Spawn")
	var unruled := WorldAtlas.rules_for(&"carte_de_test")
	assert_true(unruled.enemies_allowed, "hors de toute île : comme avant X1")
	assert_true(unruled.clouds_below())
	assert_eq(unruled.island, &"")


func test_enemies_allowed_follows_the_map_of_a_node() -> void:
	var on_68 := Map.new()
	on_68.name = "essai"
	var enemy_spot := Node3D.new()
	on_68.add_child(enemy_spot)
	assert_false(WorldAtlas.enemies_allowed_at(enemy_spot), "dans une carte de l'île n° 68")
	on_68.name = "surface_essai"
	assert_true(WorldAtlas.enemies_allowed_at(enemy_spot), "dans une carte de la surface")
	on_68.free()
	var loose := Node3D.new()
	assert_true(WorldAtlas.enemies_allowed_at(loose), "hors carte : pas de règle")
	loose.free()


func test_rules_merge_world_then_island() -> void:
	var world := {
		"name": "Monde",
		"islands": ["ile_a", "ile_b"],
		"rules": {"enemies_allowed": false, "void_below": "clouds", "sky": "matin"},
	}
	var island_a := _island()
	island_a["rules"] = {"enemies_allowed": true}
	var island_b := _island()
	island_b["maps"] = ["essai_relief"]
	island_b["arrival_map"] = "essai_relief"
	island_b["places"] = {}
	island_b["ports"] = {}
	_use_files({"monde": world}, {"ile_a": island_a, "ile_b": island_b})
	var a := WorldAtlas.rules_of_island(&"ile_a")
	assert_true(a.enemies_allowed, "l'île remplace la règle du monde")
	assert_eq(a.sky, &"matin", "et garde les autres")
	assert_eq(a.void_fall, IslandRules.FALL_ARRIVAL, "règle absente partout : UNRULED")
	assert_false(WorldAtlas.rules_of_island(&"ile_b").enemies_allowed)
	assert_eq(WorldAtlas.island_of(&"essai_relief"), &"ile_b")


# --- Format -----------------------------------------------------------------------------------


func test_valid_island_has_no_problem() -> void:
	assert_eq(_joined(WorldAtlas.island_problems(_island(), "ile_test", true)), "")


func test_unknown_keys_are_refused() -> void:
	var island := _island()
	island["nmae"] = "faute de frappe"
	island["_commentaire"] = "permis"
	assert_string_contains(_joined(WorldAtlas.island_problems(island)), "clé inconnue « nmae »")
	assert_false(_joined(WorldAtlas.island_problems(island)).contains("_commentaire"))
	island = _island()
	island["places"]["essai"]["lien"] = {}
	assert_string_contains(
		_joined(WorldAtlas.island_problems(island)), "places.essai.clé inconnue « lien »"
	)
	island = _island()
	island["ports"]["quai"]["marqueur"] = "x"
	assert_string_contains(
		_joined(WorldAtlas.island_problems(island)), "ports.quai.clé inconnue « marqueur »"
	)
	island = _island()
	island["rules"] = {"enemies": false}
	assert_string_contains(_joined(WorldAtlas.island_problems(island)), "rules : clé inconnue")
	var world := {"name": "Monde", "islands": [], "regles": {}}
	assert_string_contains(_joined(WorldAtlas.world_problems(world)), "clé inconnue « regles »")


func test_missing_fields_and_bad_values_are_reported() -> void:
	var island := _island()
	island.erase("maps")
	assert_string_contains(_joined(WorldAtlas.island_problems(island)), "maps manquant")
	island = _island()
	island["number"] = 6.5
	assert_string_contains(_joined(WorldAtlas.island_problems(island)), "entier positif")
	island = _island()
	island["rules"] = {"void_below": "lava"}
	assert_string_contains(_joined(WorldAtlas.island_problems(island)), "void_below")
	island = _island()
	island["rules"] = {"sky": "aurore_boreale"}
	assert_string_contains(_joined(WorldAtlas.island_problems(island)), "aurore_boreale")
	island = _island()
	island["places"]["essai"]["links"] = {"nulle_part": 100}
	assert_string_contains(_joined(WorldAtlas.island_problems(island)), "lieu inconnu")
	island = _island()
	island["arrival_map"] = "entrepot"
	assert_string_contains(_joined(WorldAtlas.island_problems(island)), "arrival_map")


func test_missing_map_and_marker_are_reported() -> void:
	var island := _island()
	island["maps"] = ["essai", "nulle_part"]
	assert_string_contains(
		_joined(WorldAtlas.island_problems(island)), "carte « nulle_part » introuvable"
	)
	island = _island()
	island["ports"]["quai"]["marker"] = "from_ailleurs"
	assert_eq(_joined(WorldAtlas.island_problems(island)), "", "sans scènes : pas de lecture")
	assert_string_contains(
		_joined(WorldAtlas.island_problems(island, "", true)),
		"marqueur from_ailleurs absent de la carte essai"
	)
	island = _island()
	island["ports"]["quai"]["map"] = "entrepot"
	assert_string_contains(_joined(WorldAtlas.island_problems(island)), "hors de maps")
	island = _island()
	island["places"]["essai"]["maps"] = ["entrepot"]
	assert_string_contains(_joined(WorldAtlas.island_problems(island)), "hors de maps")


func test_invalid_files_are_ignored_and_cross_checks_reported() -> void:
	var bad := _island()
	bad["inconnue"] = true
	var world := {
		"name": "Monde", "islands": ["ile_ok", "ile_ko", "ile_sans_fichier", "ile_double"]
	}
	var other_world := {"name": "Autre", "islands": ["ile_double"]}
	_use_files(
		{"monde": world, "autre": other_world},
		{
			"ile_ok": _island(),
			"ile_double": _island(),
			"ile_ko": bad,
			"ile_orpheline": _island(),
			"ile_cassee": "{ pas du JSON"
		}
	)
	assert_eq(WorldAtlas.islands(&"monde"), [&"ile_ok"] as Array[StringName], "invalide ignorée")
	assert_eq(WorldAtlas.world_of(&"ile_double"), &"autre", "deux mondes : le premier (trié)")
	assert_false(WorldAtlas.has_island(&"ile_ko"))
	assert_false(WorldAtlas.has_island(&"ile_orpheline"), "rangée dans aucun monde")
	var text := _joined(WorldAtlas.problems())
	for expected: String in [
		"île ile_ko : clé inconnue « inconnue »",
		"île « ile_sans_fichier » sans fichier",
		"île ile_double dans deux mondes",
		"île ile_orpheline : rangée dans aucun monde",
		"carte essai dans deux îles",
		"île ile_cassee : fichier : objet JSON attendu",
	]:
		assert_string_contains(text, expected)


# --- Contenu par île --------------------------------------------------------------------------


func test_data_path_convention() -> void:
	assert_eq(
		WorldAtlas.data_path("life", ILE_68, "journee.json"), "res://data/life/ile_68/journee.json"
	)
	assert_eq(WorldAtlas.data_path("fauna", &"", "ours.tres"), "res://data/fauna/ours.tres")
	assert_eq(
		WorldAtlas.find_data("texts", ILE_68, "story.json"),
		"res://data/texts/ile_68/story.json",
		"(E6) le fichier de l'île d'abord"
	)
	assert_eq(
		WorldAtlas.find_data("texts", ILE_68, "life.json"),
		"res://data/texts/life.json",
		"sans fichier de l'île : le fichier commun"
	)
	assert_eq(WorldAtlas.find_data("texts", ILE_68, "absent.json"), "")
	assert_eq(
		WorldAtlas.data_dirs("texts", ILE_68),
		PackedStringArray(["res://data/texts/ile_68", "res://data/texts"])
	)
	assert_eq(
		WorldAtlas.data_dirs("world", &"islands"),
		PackedStringArray(["res://data/world/islands", "res://data/world"]),
		"le dossier de l'île d'abord"
	)


## Region écrite dans la scène d'une carte (lue sans l'instancier).
func _scene_region(map_id: StringName) -> StringName:
	var state := (load(Map.scene_path(map_id)) as PackedScene).get_state()
	while state != null:
		for i in state.get_node_property_count(0):
			if state.get_node_property_name(0, i) == &"region":
				return StringName(state.get_node_property_value(0, i))
		state = state.get_base_scene_state()
	return &""
