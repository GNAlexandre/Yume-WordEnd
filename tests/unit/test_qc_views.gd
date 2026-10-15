extends GutTest
## (QC) La série standard de vues du garant de la qualité visuelle (tools/qc_views.json,
## docs/QUALITE.md) : chaque carte de l'île n° 68 a ses vues, chaque carte des vues est une carte
## de l'île qui existe, chaque vue est bien formée (nom unique, place dans la carte ou vue
## d'ensemble, regard, moments et temps connus). La couverture des pièces et des points nommés de
## CARTE.md est vérifiée par tools/qc_tool.py check (lancé par tools/qc_shots.sh).

const VIEWS_PATH := "res://tools/qc_views.json"
const ISLAND_PATH := "res://data/world/islands/ile_68.json"
const KINDS: Array[String] = ["dehors", "dedans", "attente"]
const LOOKS: Array[String] = ["N", "S", "E", "O"]

var _views: Dictionary = {}
var _island: Dictionary = {}


func before_all() -> void:
	_views = JSON.parse_string(FileAccess.get_file_as_string(VIEWS_PATH))
	_island = JSON.parse_string(FileAccess.get_file_as_string(ISLAND_PATH))


func test_every_island_map_has_views() -> void:
	var maps: Dictionary = _views.get("maps", {})
	for map_id: String in _island["maps"]:
		assert_true(maps.has(map_id), "%s : carte de l'île sans vue dans qc_views.json" % map_id)
		if maps.has(map_id):
			assert_gt((maps[map_id]["views"] as Array).size(), 0, "%s : aucune vue" % map_id)


func test_every_view_map_is_an_island_map() -> void:
	for map_id: String in _views.get("maps", {}):
		assert_true(map_id in _island["maps"], "%s : pas une carte de ile_68.json" % map_id)
		var path := "res://src/world/maps/%s/%s.tscn" % [map_id, map_id]
		assert_true(ResourceLoader.exists(path), "%s : scène absente" % path)


func test_views_are_well_formed() -> void:
	var maps: Dictionary = _views.get("maps", {})
	for map_id: String in maps:
		var entry: Dictionary = maps[map_id]
		assert_true(String(entry.get("kind", "")) in KINDS, "%s : kind inconnu" % map_id)
		var names: Array[String] = []
		for view: Dictionary in entry["views"]:
			var view_name := String(view.get("name", ""))
			assert_false(
				view_name.is_empty() or view_name in names, "%s : nom %s" % [map_id, view_name]
			)
			names.append(view_name)
			if entry["kind"] == "attente":
				assert_true(
					view.get("overview", false),
					"%s : carte d'attente, vue d'ensemble seule" % map_id
				)
			if not view.get("overview", false):
				var at: Array = view.get("at", [])
				assert_eq(at.size(), 2, "%s:%s : at = [x, z]" % [map_id, view_name])
				assert_true(
					String(view.get("look", "N")) in LOOKS, "%s:%s : look" % [map_id, view_name]
				)
			for spec: String in view.get("moments", []):
				var parts := spec.split(":")
				assert_true(
					StringName(parts[0]) in GameState.MOMENTS,
					"%s:%s : %s" % [map_id, view_name, spec]
				)
				if parts.size() > 1:
					assert_true(
						StringName(parts[1]) in GameState.WEATHERS, "%s : %s" % [view_name, spec]
					)
	for key: String in ["moments", "interior_moments", "overview_moments"]:
		for spec: String in _views["defaults"][key]:
			assert_true(StringName(spec) in GameState.MOMENTS, "defaults.%s : %s" % [key, spec])
