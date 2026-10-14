class_name WorldAtlas
extends RefCounted
## L'atlas du monde (lot X1, PLAN.md section 3, « Ajouter une île ») : les mondes, leurs îles,
## les cartes de chaque île, ses lieux, ses ports et ses règles, lus dans les données. Classe
## statique (comme QuestData) : rien n'y vit d'une partie à l'autre, aucun nœud ni autoload.
##
## - Un monde : data/world/worlds/<world_id>.json (« regule_aire », « surface ») : name, islands
##   (ses îles, dans l'ordre), rules (règles communes, facultatives).
## - Une île : data/world/islands/<island_id>.json : name, number (facultatif), maps (ses cartes),
##   arrival_map (carte d'arrivée par défaut), places (graphe des lieux : name, maps, links en
##   marmer, start_known), ports (name, map, marker), rules (facultatives), legacy (facultatif :
##   l'ancienne île, retirée en phase 5). Format détaillé : PLAN.md, « Ajouter une île ».
## - Une clé inconnue rend le fichier invalide (sauf « _… », commentaire), comme pour les quêtes :
##   un fichier invalide est ignoré, avec un avertissement qui dit pourquoi. problems() vérifie
##   aussi les cartes (existantes), les marqueurs des ports (présents dans la scène) et les liens.
## - Les fichiers sont lus une fois et gardés en cache (clear_cache() : les tests).
##
## Une carte appartient à l'île dont « maps » la nomme ; Map.island le répète dans la scène
## (tests/unit/test_world_atlas.gd vérifie que les deux disent la même chose). Une carte hors de
## toute île (cartes de test) n'a ni île ni règle : IslandRules.unruled().

## Dossiers des données (les tests en posent d'autres par set_data_dirs()).
const WORLDS_DIR := "res://data/world/worlds"
const ISLANDS_DIR := "res://data/world/islands"
## Racine des données par île (data_path) : data/<kind>/<island_id>/<fichier>.
const DATA_ROOT := "res://data"
## Île par défaut d'une carte (Map.island) : l'île n° 68.
const DEFAULT_ISLAND := &"ile_68"
## Marqueur d'arrivée d'un port, par convention (`from_dirigeable`, ou `from_dirigeable_<suffixe>`
## s'il y a plusieurs ports sur la carte).
const PORT_MARKER := &"from_dirigeable"
## Clés d'un monde : nom → [type JSON, obligatoire].
const WORLD_KEYS := {
	"name": [TYPE_STRING, true],
	"islands": [TYPE_ARRAY, true],
	"rules": [TYPE_DICTIONARY, false],
}
## Clés d'une île.
const ISLAND_KEYS := {
	"name": [TYPE_STRING, true],
	"number": [TYPE_FLOAT, false],
	"maps": [TYPE_ARRAY, true],
	"arrival_map": [TYPE_STRING, true],
	"places": [TYPE_DICTIONARY, true],
	"ports": [TYPE_DICTIONARY, true],
	"rules": [TYPE_DICTIONARY, false],
	"legacy": [TYPE_BOOL, false],
}
## Clés d'un lieu (graphe de la carte de l'île).
const PLACE_KEYS := {
	"name": [TYPE_STRING, true],
	"maps": [TYPE_ARRAY, true],
	"links": [TYPE_DICTIONARY, false],
	"start_known": [TYPE_BOOL, false],
}
## Clés d'un port.
const PORT_KEYS := {
	"name": [TYPE_STRING, true],
	"map": [TYPE_STRING, true],
	"marker": [TYPE_STRING, true],
}

static var _worlds_dir: String = WORLDS_DIR
static var _islands_dir: String = ISLANDS_DIR
static var _loaded: bool = false
## world_id → données lues (valides).
static var _worlds: Dictionary[StringName, Dictionary] = {}
## island_id → données lues (valides).
static var _islands: Dictionary[StringName, Dictionary] = {}
## island_id → world_id.
static var _world_of: Dictionary[StringName, StringName] = {}
## map_id → island_id.
static var _island_of: Dictionary[StringName, StringName] = {}
## island_id → IslandRules (calculées à la demande).
static var _rules: Dictionary[StringName, IslandRules] = {}

# --- Mondes et îles ---------------------------------------------------------------------------


## Mondes (fichiers valides de data/world/worlds), triés.
static func worlds() -> Array[StringName]:
	_ensure_loaded()
	var ids: Array[StringName] = []
	ids.assign(_worlds.keys())
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return ids


## Nom affiché d'un monde ("" s'il est inconnu).
static func world_name(world_id: StringName) -> String:
	_ensure_loaded()
	return str(_worlds.get(world_id, {}).get("name", ""))


## Îles d'un monde dans l'ordre de son fichier ; sans monde : toutes, monde par monde.
static func islands(world_id: StringName = &"") -> Array[StringName]:
	_ensure_loaded()
	var ids: Array[StringName] = []
	for world: StringName in worlds():
		if not world_id.is_empty() and world != world_id:
			continue
		for island: Variant in _worlds[world]["islands"]:
			if _world_of.get(StringName(str(island)), &"") == world:
				ids.append(StringName(str(island)))
	return ids


## Vrai si l'île existe (fichier valide, rangée dans un monde).
static func has_island(island_id: StringName) -> bool:
	_ensure_loaded()
	return _islands.has(island_id) and _world_of.has(island_id)


## Monde de l'île (&"" si inconnue).
static func world_of(island_id: StringName) -> StringName:
	_ensure_loaded()
	return _world_of.get(island_id, &"")


## Nom affiché de l'île (« L'île n° 68 ») ; "" si inconnue.
static func island_name(island_id: StringName) -> String:
	return str(_island(island_id).get("name", ""))


## Numéro de l'île (68) ; 0 si elle n'en a pas (la surface) ou si elle est inconnue.
static func island_number(island_id: StringName) -> int:
	return int(_island(island_id).get("number", 0))


## Vrai pour l'ancienne île (« legacy » : retirée en phase 5 avec sa carte).
static func is_legacy(island_id: StringName) -> bool:
	return bool(_island(island_id).get("legacy", false))


# --- Cartes, lieux, ports ---------------------------------------------------------------------


## Île de la carte (celle dont « maps » la nomme) ; &"" hors de toute île.
static func island_of(map_id: StringName) -> StringName:
	_ensure_loaded()
	return _island_of.get(map_id, &"")


## Cartes de l'île, dans l'ordre de son fichier.
static func maps_of(island_id: StringName) -> Array[StringName]:
	return _names(_island(island_id).get("maps", []))


## Carte d'arrivée par défaut de l'île (&"" si inconnue).
static func arrival_map(island_id: StringName) -> StringName:
	return StringName(str(_island(island_id).get("arrival_map", "")))


## Ports de l'île (leurs id), dans l'ordre de son fichier.
static func ports_of(island_id: StringName) -> Array[StringName]:
	return _ids(_island(island_id).get("ports", {}))


## Un port : {"id", "name", "map", "marker"} ; {} s'il est inconnu.
static func port(island_id: StringName, port_id: StringName) -> Dictionary:
	var ports: Dictionary = _island(island_id).get("ports", {})
	if not _ids(ports).has(port_id):
		return {}
	var data: Dictionary = ports[String(port_id)]
	return {
		"id": port_id,
		"name": str(data["name"]),
		"map": StringName(str(data["map"])),
		"marker": StringName(str(data["marker"])),
	}


## Où arrive un voyage vers l'île : {"map", "marker", "port"} ; le port nommé, sinon le premier
## port de l'île, sinon sa carte d'arrivée au Spawn (port &"") ; {} pour une île ou un port
## inconnus.
static func arrival(island_id: StringName, port_id: StringName = &"") -> Dictionary:
	if not has_island(island_id):
		return {}
	var ports := ports_of(island_id)
	if port_id.is_empty() and not ports.is_empty():
		port_id = ports[0]
	if not port_id.is_empty():
		var found := port(island_id, port_id)
		if found.is_empty():
			return {}
		return {"map": found["map"], "marker": found["marker"], "port": port_id}
	return {"map": arrival_map(island_id), "marker": Map.SPAWN_MARKER, "port": &""}


## Lieux de l'île (graphe de la carte de l'île), dans l'ordre de son fichier.
static func places_of(island_id: StringName) -> Array[StringName]:
	return _ids(_island(island_id).get("places", {}))


## Un lieu : {"id", "name", "maps", "links" (lieu → marmer, dans les deux sens), "start_known"} ;
## {} s'il est inconnu.
static func place(island_id: StringName, place_id: StringName) -> Dictionary:
	var places: Dictionary = _island(island_id).get("places", {})
	if not _ids(places).has(place_id):
		return {}
	var data: Dictionary = places[String(place_id)]
	var links: Dictionary[StringName, float] = {}
	for other: StringName in _ids(places):
		var other_links: Dictionary = (places[String(other)] as Dictionary).get("links", {})
		if other == place_id:
			for target: StringName in _ids(other_links):
				links[target] = float(other_links[String(target)])
		elif other_links.has(String(place_id)):
			links[other] = float(other_links[String(place_id)])
	return {
		"id": place_id,
		"name": str(data["name"]),
		"maps": _names(data["maps"]),
		"links": links,
		"start_known": bool(data.get("start_known", false)),
	}


## Lieu de la carte sur la carte de l'île (&"" si elle n'est dans aucun lieu).
static func place_of(map_id: StringName) -> StringName:
	var island_id := island_of(map_id)
	for place_id: StringName in places_of(island_id):
		if (place(island_id, place_id)["maps"] as Array).has(map_id):
			return place_id
	return &""


# --- Règles -----------------------------------------------------------------------------------


## Règles de la carte : celles de son île (monde, puis île) ; hors de toute île : unruled().
static func rules_for(map_id: StringName) -> IslandRules:
	return rules_of_island(island_of(map_id))


## Règles d'une île (monde, puis île) ; île inconnue : unruled().
static func rules_of_island(island_id: StringName) -> IslandRules:
	_ensure_loaded()
	if not has_island(island_id):
		return IslandRules.unruled()
	if not _rules.has(island_id):
		var layers: Array[Dictionary] = [
			_worlds[_world_of[island_id]].get("rules", {}), _islands[island_id].get("rules", {})
		]
		_rules[island_id] = IslandRules.merged(layers, island_id)
	return _rules[island_id]


## Carte qui contient node (son premier ancêtre Map, lui compris) ; null hors d'une carte.
static func map_of_node(node: Node) -> Map:
	var current := node
	while current != null:
		if current is Map:
			return current as Map
		current = current.get_parent()
	return null


## Vrai si un Timere peut apparaître à l'endroit de node (vagues, arène, Timeres libres, banc de
## performance) : selon les règles de la carte qui le contient, ou, s'il n'est pas dans une carte
## (ajouté à côté, sous Game), de la carte courante ; sans carte (tests), rien ne l'interdit.
static func enemies_allowed_at(node: Node) -> bool:
	var map := map_of_node(node)
	if map == null and node != null and node.is_inside_tree():
		map = WorldManager.current_map_node()
	return map == null or rules_for(map.map_id()).enemies_allowed


# --- Contenu par île --------------------------------------------------------------------------


## Chemin d'un fichier de contenu propre à une île : res://data/<kind>/<island_id>/<file>
## (kind : life, texts, fauna, scenes…) ; island_id vide : res://data/<kind>/<file> (contenu
## commun). Ne vérifie pas que le fichier existe (voir find_data).
static func data_path(kind: String, island_id: StringName, file: String) -> String:
	if island_id.is_empty():
		return "%s/%s/%s" % [DATA_ROOT, kind, file]
	return "%s/%s/%s/%s" % [DATA_ROOT, kind, island_id, file]


## Le fichier de l'île s'il existe, sinon le fichier commun (data/<kind>/<file>) s'il existe,
## sinon "" : les fichiers d'avant la convention, à la racine de leur dossier, restent lus.
static func find_data(kind: String, island_id: StringName, file: String) -> String:
	for path: String in [data_path(kind, island_id, file), data_path(kind, &"", file)]:
		if FileAccess.file_exists(path) or ResourceLoader.exists(path):
			return path
	return ""


## Dossiers de contenu à lire pour une île, le sien d'abord : data/<kind>/<island_id>, puis
## data/<kind> (ceux qui existent).
static func data_dirs(kind: String, island_id: StringName) -> PackedStringArray:
	var dirs := PackedStringArray()
	var candidates: Array[String] = ["%s/%s" % [DATA_ROOT, kind]]
	if not island_id.is_empty():
		candidates.push_front("%s/%s/%s" % [DATA_ROOT, kind, island_id])
	for dir: String in candidates:
		if DirAccess.dir_exists_absolute(dir):
			dirs.append(dir)
	return dirs


# --- Lecture et vérification ------------------------------------------------------------------


## Oublie les fichiers lus : la prochaine requête relit les dossiers.
static func clear_cache() -> void:
	_loaded = false
	_worlds.clear()
	_islands.clear()
	_world_of.clear()
	_island_of.clear()
	_rules.clear()


## Lit les mondes et les îles ailleurs (tests) ; set_data_dirs() sans argument : les vrais.
static func set_data_dirs(
	worlds_dir: String = WORLDS_DIR, islands_dir: String = ISLANDS_DIR
) -> void:
	_worlds_dir = worlds_dir
	_islands_dir = islands_dir
	clear_cache()


## Tous les problèmes des données (vide : tout est valide) : chaque fichier (format, cartes,
## marqueurs des ports), chaque île rangée dans un seul monde, chaque carte dans une seule île.
static func problems() -> PackedStringArray:
	var found := PackedStringArray()
	var raw_worlds := _read_dir(_worlds_dir)
	var raw_islands := _read_dir(_islands_dir)
	var owner: Dictionary[String, String] = {}
	for world_id: String in raw_worlds:
		for problem: String in world_problems(raw_worlds[world_id], world_id):
			found.append("monde %s : %s" % [world_id, problem])
		var data: Variant = raw_worlds[world_id]
		if not data is Dictionary or not (data as Dictionary).get("islands") is Array:
			continue
		for island: Variant in data["islands"]:
			var island_id := str(island)
			if not raw_islands.has(island_id):
				found.append("monde %s : île « %s » sans fichier" % [world_id, island_id])
			elif owner.has(island_id):
				found.append("île %s dans deux mondes" % island_id)
			owner[island_id] = world_id
	var map_owner: Dictionary[String, String] = {}
	for island_id: String in raw_islands:
		if not owner.has(island_id):
			found.append("île %s : rangée dans aucun monde" % island_id)
		for problem: String in island_problems(raw_islands[island_id], island_id, true):
			found.append("île %s : %s" % [island_id, problem])
		var data: Variant = raw_islands[island_id]
		if not data is Dictionary or not (data as Dictionary).get("maps") is Array:
			continue
		for map_id: Variant in data["maps"]:
			if map_owner.has(str(map_id)):
				found.append("carte %s dans deux îles" % map_id)
			map_owner[str(map_id)] = island_id
	return found


## Problèmes d'un monde déjà lu (vide : valide) : clés, types, îles, règles.
static func world_problems(data: Variant, world_id: String = "") -> PackedStringArray:
	var found := _keys_problems(data, WORLD_KEYS, "")
	if not found.is_empty():
		return found
	if not world_id.is_empty() and not Map.is_valid_id(StringName(world_id)):
		found.append("identifiant « %s » : snake_case sans accent attendu" % world_id)
	for island: Variant in data["islands"]:
		if not island is String or not Map.is_valid_id(StringName(island)):
			found.append("islands : identifiant « %s » invalide" % island)
	if (data as Dictionary).has("rules"):
		var rules_problem := IslandRules.problem(data["rules"])
		if not rules_problem.is_empty():
			found.append(rules_problem)
	return found


## Problèmes d'une île déjà lue (vide : valide) : clés et types (une clé inconnue est refusée),
## cartes existantes, carte d'arrivée parmi elles, lieux (cartes de l'île, liens vers des lieux
## de l'île, distances positives), ports (carte de l'île ; avec scenes, marqueur présent dans la
## scène de la carte), règles.
static func island_problems(
	data: Variant, island_id: String = "", scenes: bool = false
) -> PackedStringArray:
	var found := _keys_problems(data, ISLAND_KEYS, "")
	if not found.is_empty():
		return found
	var island := data as Dictionary
	if not island_id.is_empty() and not Map.is_valid_id(StringName(island_id)):
		found.append("identifiant « %s » : snake_case sans accent attendu" % island_id)
	if island.has("number"):
		var number := float(island["number"])
		if number < 1.0 or number != floorf(number):
			found.append("number : entier positif attendu")
	var maps: Array[StringName] = []
	for map_id: Variant in island["maps"]:
		if not map_id is String or not Map.exists(StringName(map_id)):
			found.append("maps : carte « %s » introuvable" % map_id)
		else:
			maps.append(StringName(map_id))
	if not maps.has(StringName(island["arrival_map"])):
		found.append("arrival_map « %s » : une carte de maps attendue" % island["arrival_map"])
	found.append_array(_places_problems(island["places"], maps))
	found.append_array(_ports_problems(island["ports"], maps, scenes))
	if island.has("rules"):
		var rules_problem := IslandRules.problem(island["rules"])
		if not rules_problem.is_empty():
			found.append(rules_problem)
	return found


## Marqueurs (Marker3D enfants de « Markers ») d'une scène de carte, lus sans l'instancier.
static func scene_markers(map_id: StringName) -> Array[StringName]:
	var names: Array[StringName] = []
	if not Map.exists(map_id):
		return names
	var state := (load(Map.scene_path(map_id)) as PackedScene).get_state()
	while state != null:
		for i in state.get_node_count():
			var path := String(state.get_node_path(i)).trim_prefix("./")
			if path.begins_with("Markers/") and path.count("/") == 1:
				var marker_name := StringName(path.get_file())
				if not names.has(marker_name):
					names.append(marker_name)
		state = state.get_base_scene_state()
	return names


## Île écrite dans la scène d'une carte (Map.island ; DEFAULT_ISLAND si elle ne la donne pas),
## lue sans l'instancier ; &"" pour une carte inconnue.
static func scene_island(map_id: StringName) -> StringName:
	if not Map.exists(map_id):
		return &""
	var state := (load(Map.scene_path(map_id)) as PackedScene).get_state()
	while state != null:
		for i in state.get_node_property_count(0):
			if state.get_node_property_name(0, i) == &"island":
				return StringName(state.get_node_property_value(0, i))
		state = state.get_base_scene_state()
	return DEFAULT_ISLAND


# --- Interne ----------------------------------------------------------------------------------


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	var raw_islands := _read_dir(_islands_dir)
	for island_id: String in raw_islands:
		var problems_found := island_problems(raw_islands[island_id], island_id)
		if not problems_found.is_empty():
			push_warning(
				(
					"WorldAtlas : île %s invalide, ignorée : %s"
					% [island_id, "; ".join(problems_found)]
				)
			)
			continue
		_islands[StringName(island_id)] = raw_islands[island_id]
	var raw_worlds := _read_dir(_worlds_dir)
	for world_id: String in raw_worlds:
		var problems_found := world_problems(raw_worlds[world_id], world_id)
		if not problems_found.is_empty():
			push_warning(
				(
					"WorldAtlas : monde %s invalide, ignoré : %s"
					% [world_id, "; ".join(problems_found)]
				)
			)
			continue
		_worlds[StringName(world_id)] = raw_worlds[world_id]
		for island: Variant in raw_worlds[world_id]["islands"]:
			var island_id := StringName(str(island))
			if _islands.has(island_id) and not _world_of.has(island_id):
				_world_of[island_id] = StringName(world_id)
	for island_id: StringName in _islands:
		if not _world_of.has(island_id):
			continue
		for map_id: Variant in _islands[island_id]["maps"]:
			if not _island_of.has(StringName(str(map_id))):
				_island_of[StringName(str(map_id))] = island_id


## Données d'une île connue ({} sinon).
static func _island(island_id: StringName) -> Dictionary:
	_ensure_loaded()
	return _islands.get(island_id, {}) if _world_of.has(island_id) else {}


## Fichiers JSON d'un dossier : nom sans extension → contenu lu (null si illisible : la
## vérification le dit).
static func _read_dir(dir: String) -> Dictionary:
	var result := {}
	var files: PackedStringArray = (
		ResourceLoader.list_directory(dir)
		if dir.begins_with("res://")
		else DirAccess.get_files_at(dir)
	)
	var sorted := Array(files)
	sorted.sort()
	for file: String in sorted:
		if file.get_extension() != "json":
			continue
		var json := JSON.new()
		var text := FileAccess.get_file_as_string(dir.path_join(file))
		result[file.get_basename()] = json.data if json.parse(text) == OK else null
	return result


## Problèmes de clés et de types d'un objet lu (spec : clé → [type, obligatoire]).
static func _keys_problems(data: Variant, spec: Dictionary, where: String) -> PackedStringArray:
	var found := PackedStringArray()
	var prefix := where + "." if not where.is_empty() else ""
	if not data is Dictionary:
		found.append("%s objet JSON attendu" % (where if not where.is_empty() else "fichier :"))
		return found
	for key: Variant in data:
		var key_name := str(key)
		if not key_name.begins_with("_") and not spec.has(key_name):
			found.append("%sclé inconnue « %s »" % [prefix, key_name])
	for key: String in spec:
		var rule: Array = spec[key]
		if not (data as Dictionary).has(key):
			if bool(rule[1]):
				found.append("%s%s manquant" % [prefix, key])
		elif typeof(data[key]) != int(rule[0]):
			found.append("%s%s : type %s attendu" % [prefix, key, type_string(int(rule[0]))])
	return found


static func _places_problems(places: Dictionary, maps: Array[StringName]) -> PackedStringArray:
	var found := PackedStringArray()
	for place_id: StringName in _ids(places):
		var where := "places.%s" % place_id
		var spec_problems := _keys_problems(places[String(place_id)], PLACE_KEYS, where)
		if not spec_problems.is_empty():
			found.append_array(spec_problems)
			continue
		if not Map.is_valid_id(place_id):
			found.append("%s : identifiant snake_case attendu" % where)
		var data: Dictionary = places[String(place_id)]
		for map_id: Variant in data["maps"]:
			if not maps.has(StringName(str(map_id))):
				found.append("%s : carte « %s » hors de maps" % [where, map_id])
		var links: Dictionary = data.get("links", {})
		for target: StringName in _ids(links):
			if not _ids(places).has(target) or target == place_id:
				found.append("%s : lien vers un lieu inconnu « %s »" % [where, target])
			elif typeof(links[String(target)]) != TYPE_FLOAT or float(links[String(target)]) <= 0.0:
				found.append("%s.links.%s : distance positive (marmer) attendue" % [where, target])
	return found


static func _ports_problems(
	ports: Dictionary, maps: Array[StringName], scenes: bool
) -> PackedStringArray:
	var found := PackedStringArray()
	for port_id: StringName in _ids(ports):
		var where := "ports.%s" % port_id
		var spec_problems := _keys_problems(ports[String(port_id)], PORT_KEYS, where)
		if not spec_problems.is_empty():
			found.append_array(spec_problems)
			continue
		if not Map.is_valid_id(port_id):
			found.append("%s : identifiant snake_case attendu" % where)
		var data: Dictionary = ports[String(port_id)]
		var map_id := StringName(str(data["map"]))
		var marker := StringName(str(data["marker"]))
		if not maps.has(map_id):
			found.append("%s : carte « %s » hors de maps" % [where, map_id])
		elif scenes and not scene_markers(map_id).has(marker):
			found.append("%s : marqueur %s absent de la carte %s" % [where, marker, map_id])
	return found


## Clés d'un objet lu, sans les commentaires (« _… »).
static func _ids(data: Variant) -> Array[StringName]:
	var ids: Array[StringName] = []
	if data is Dictionary:
		for key: Variant in data:
			if not str(key).begins_with("_"):
				ids.append(StringName(str(key)))
	return ids


static func _names(values: Array) -> Array[StringName]:
	var names: Array[StringName] = []
	for value: Variant in values:
		names.append(StringName(str(value)))
	return names
