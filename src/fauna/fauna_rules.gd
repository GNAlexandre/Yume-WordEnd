class_name FaunaRules
extends RefCounted
## Règles et données de la faune (lot E5) : quelles espèces vivent sur une île, lesquelles sur une
## carte, combien, où et à quel moment. Fonctions statiques, sans état sauf un cache de fichiers
## (clear_cache() pour le vider).
##
## Trois couches, de la plus générale à la plus précise :
## 1. les règles de l'île (WorldAtlas.rules_for(carte).fauna) : les espèces permises ;
## 2. data/fauna/<île>/peuplement.json : les régions où l'on ne croise jamais d'animaux
##    (« banned_regions » : l'entrepôt, le village, la ville, le port, d'après docs/REFONTE.md 4.4)
##    et, par carte, la liste des groupes (« maps ») ;
## 3. l'espèce (AnimalData.moments) et le groupe (« moments ») : le moment de la journée
##    (GameState.moment).
## Format du peuplement : PLAN.md, « (E5) Ajouter un animal ».

const KIND := "fauna"
const POPULATION_FILE := "peuplement.json"
## Clés permises d'un groupe (une clé « _… » est un commentaire).
const GROUP_KEYS := [
	"id", "species", "count", "at", "rect", "radius", "moments", "pack", "weather", "respawn_s"
]
const DEFAULT_RADIUS := 4.0
const DEFAULT_RESPAWN := 40.0

static var _species_cache: Dictionary[String, AnimalData] = {}
static var _population_cache: Dictionary[StringName, Dictionary] = {}


## Vide le cache des espèces et des peuplements.
static func clear_cache() -> void:
	_species_cache.clear()
	_population_cache.clear()


## Remplace le peuplement d'une île (tests) ; clear_cache() rétablit celui du fichier.
static func set_population(island_id: StringName, data: Dictionary) -> void:
	_population_cache[island_id] = data


# --- Espèces ----------------------------------------------------------------------------------


## Chemin du fichier d'une espèce de l'île (celui de l'île, sinon le commun) ; "" s'il n'existe pas.
static func species_path(island_id: StringName, species_id: StringName) -> String:
	return WorldAtlas.find_data(KIND, island_id, "%s.tres" % species_id)


## Données d'une espèce de l'île ; null si elle n'existe pas ou n'est pas une AnimalData.
static func species(island_id: StringName, species_id: StringName) -> AnimalData:
	var key := "%s/%s" % [island_id, species_id]
	if _species_cache.has(key):
		return _species_cache[key]
	var path := species_path(island_id, species_id)
	var data := load(path) as AnimalData if not path.is_empty() else null
	if data != null:
		_species_cache[key] = data
	return data


## Identifiants des espèces dont l'île a le fichier (le sien et le commun), triés.
static func species_ids(island_id: StringName) -> Array[StringName]:
	var names: Array[String] = []
	for dir: String in WorldAtlas.data_dirs(KIND, island_id):
		for file: String in DirAccess.get_files_at(dir):
			if file.ends_with(".tres") and not file.get_basename() in names:
				names.append(file.get_basename())
	names.sort()
	var found: Array[StringName] = []
	for id: String in names:
		found.append(StringName(id))
	return found


# --- Règles de l'île ---------------------------------------------------------------------------


## Vrai si l'île de la carte permet l'espèce (WorldAtlas.rules_for(map_id).fauna).
static func island_allows(map_id: StringName, species_id: StringName) -> bool:
	return species_id in WorldAtlas.rules_for(map_id).fauna


## Régions (lieux de la carte de l'île, Map.region) où l'on ne croise aucun animal.
static func banned_regions(island_id: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	var banned: Variant = population(island_id).get("banned_regions", [])
	if banned is Array:
		for region: Variant in banned:
			result.append(StringName(str(region)))
	return result


## Vrai si la carte est dans une région interdite : sa région (Map.region d'un nœud, sinon le lieu
## que le fichier de l'île lui donne).
static func is_banned(map_id: StringName, region: StringName = &"") -> bool:
	var island_id := WorldAtlas.island_of(map_id)
	var banned := banned_regions(island_id)
	if not region.is_empty() and region in banned:
		return true
	return WorldAtlas.place_of(map_id) in banned


## Vrai si l'espèce peut vivre à l'endroit de node : les règles de l'île de sa carte la permettent
## et la carte n'est pas dans une région interdite. Hors de toute carte (tests) : permis.
static func allowed_at(node: Node, species_id: StringName) -> bool:
	var map := WorldAtlas.map_of_node(node)
	if map == null and node != null and node.is_inside_tree():
		map = WorldManager.current_map_node()
	if map == null:
		return true
	var map_id := map.map_id()
	return island_allows(map_id, species_id) and not is_banned(map_id, map.region)


# --- Peuplement --------------------------------------------------------------------------------


## Le fichier de peuplement de l'île, lu (objet vide s'il manque ou s'il est illisible).
static func population(island_id: StringName) -> Dictionary:
	if _population_cache.has(island_id):
		return _population_cache[island_id]
	var path := WorldAtlas.find_data(KIND, island_id, POPULATION_FILE)
	var data: Dictionary = {}
	if not path.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary:
			data = parsed
		else:
			push_error("FaunaRules : %s illisible" % path)
	_population_cache[island_id] = data
	return data


## Les groupes de la carte, tels que le fichier de son île les donne (liste vide si aucun).
static func entries_for(map_id: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var maps: Variant = population(WorldAtlas.island_of(map_id)).get("maps", {})
	if maps is Dictionary and (maps as Dictionary).get(String(map_id)) is Array:
		for entry: Variant in (maps as Dictionary)[String(map_id)]:
			if entry is Dictionary:
				result.append(entry)
	return result


## Moments où un groupe est dehors : les siens (« moments »), sinon ceux de l'espèce.
static func entry_active_at(entry: Dictionary, data: AnimalData, moment: StringName) -> bool:
	if entry.get("moments") is Array and not (entry["moments"] as Array).is_empty():
		for listed: Variant in entry["moments"]:
			if StringName(str(listed)) == moment:
				return true
		return false
	return data.active_at(moment)


## Un groupe est-il de saison, à ce moment et par ce temps ?
static func entry_wanted(
	entry: Dictionary, data: AnimalData, moment: StringName, weather: StringName
) -> bool:
	if not entry_active_at(entry, data, moment):
		return false
	var weathers: Array[StringName] = []
	for listed: Variant in entry.get("weather", []):
		weathers.append(StringName(str(listed)))
	if weathers.is_empty():
		weathers = data.ambient_weather
	return weathers.is_empty() or weather in weathers


# --- Vérification ------------------------------------------------------------------------------


## Premier problème d'un groupe lu dans un JSON, "" s'il est valide (format seulement).
static func entry_problem(entry: Variant) -> String:
	if not entry is Dictionary:
		return "objet attendu"
	var dict := entry as Dictionary
	for key: Variant in dict:
		var name := str(key)
		if not name.begins_with("_") and not name in GROUP_KEYS:
			return "clé inconnue « %s »" % name
	if not dict.get("id") is String or not Map.is_valid_id(StringName(dict["id"])):
		return "id : identifiant snake_case attendu"
	if not dict.get("species") is String or not Map.is_valid_id(StringName(dict["species"])):
		return "species : identifiant snake_case attendu"
	if not dict.get("count") is float or int(dict["count"]) < 1:
		return "count : entier ≥ 1 attendu"
	if dict.has("at") == dict.has("rect"):
		return "at (marqueur de Life/Places ou Markers) ou rect : l'un des deux, pas les deux"
	if dict.has("at") and not dict["at"] is String:
		return "at : nom de marqueur attendu"
	if dict.has("rect"):
		var rect: Variant = dict["rect"]
		if not rect is Array or (rect as Array).size() != 4:
			return "rect : [x0, z0, x1, z1] attendu"
		for number: Variant in rect:
			if not number is float:
				return "rect : nombres attendus"
	for key: String in ["radius", "respawn_s"]:
		if dict.has(key) and (not dict[key] is float or float(dict[key]) <= 0.0):
			return "%s : nombre > 0 attendu" % key
	for key: String in ["moments", "weather"]:
		if dict.has(key) and not dict[key] is Array:
			return "%s : liste attendue" % key
	for moment: Variant in dict.get("moments", []):
		if not StringName(str(moment)) in GameState.MOMENTS:
			return "moments : « %s » n'est pas un moment" % moment
	for weather: Variant in dict.get("weather", []):
		if not StringName(str(weather)) in GameState.WEATHERS:
			return "weather : « %s » n'est pas un temps" % weather
	if dict.has("pack") and not dict["pack"] is bool:
		return "pack : vrai ou faux attendu"
	return ""


## Tous les problèmes d'une île (vide : tout est valide) : fichiers des espèces (comportement,
## planche, attaques d'un dangereux), liste fauna des règles, peuplement (groupes, cartes de
## l'île, espèces permises, régions interdites, ids uniques).
static func problems(island_id: StringName) -> PackedStringArray:
	var found := PackedStringArray()
	for id: StringName in species_ids(island_id):
		var animal := species(island_id, id)
		if animal == null:
			found.append("espèce %s : ce n'est pas une AnimalData" % id)
			continue
		if animal.id != id:
			found.append("espèce %s : id %s au lieu du nom du fichier" % [id, animal.id])
		if not animal.behavior in AnimalData.BEHAVIORS:
			found.append("espèce %s : comportement « %s » inconnu" % [id, animal.behavior])
		if animal.has_body() and animal.visual == null:
			found.append("espèce %s : pas de planche (visual)" % id)
		if animal.is_dangerous() and animal.attacks.is_empty():
			found.append("espèce %s : dangereuse sans attaque" % id)
		if animal.behavior == AnimalData.AMBIENT and animal.ambient_texture == null:
			found.append("espèce %s : ambiance sans bande animée" % id)
		for moment: StringName in animal.moments:
			if not moment in GameState.MOMENTS:
				found.append("espèce %s : moment « %s » inconnu" % [id, moment])
	var island_maps := WorldAtlas.maps_of(island_id)
	var rules := WorldAtlas.rules_of_island(island_id)
	for allowed: StringName in rules.fauna:
		if species(island_id, allowed) == null:
			found.append("règles : espèce « %s » sans fichier" % allowed)
	var data: Dictionary = population(island_id)
	for section: String in ["maps", "planned"]:
		var maps: Variant = data.get(section, {})
		if not maps is Dictionary:
			found.append("peuplement : %s : objet attendu" % section)
			continue
		for map_key: Variant in maps:
			var map_id := StringName(str(map_key))
			if section == "maps" and not map_id in island_maps:
				found.append("peuplement : carte « %s » hors de l'île" % map_id)
				continue
			if is_banned(map_id):
				found.append("peuplement : carte « %s » dans une région sans animaux" % map_id)
			if not (maps as Dictionary)[map_key] is Array:
				found.append("peuplement %s : liste attendue" % map_id)
				continue
			found.append_array(
				_entries_problems(island_id, map_id, (maps as Dictionary)[map_key], rules)
			)
	if not data.get("banned_regions", []) is Array:
		found.append("peuplement : banned_regions : liste attendue")
	return found


## Problèmes des groupes d'une carte (format, espèce existante et permise par les règles, ids
## uniques, meute seulement pour une espèce qui encercle).
static func _entries_problems(
	island_id: StringName, map_id: StringName, entries: Array, rules: IslandRules
) -> PackedStringArray:
	var found := PackedStringArray()
	var seen: Array[String] = []
	for entry: Variant in entries:
		var problem := entry_problem(entry)
		if not problem.is_empty():
			found.append("peuplement %s : %s" % [map_id, problem])
			continue
		var group := entry as Dictionary
		var label := "peuplement %s/%s" % [map_id, group["id"]]
		if str(group["id"]) in seen:
			found.append("%s : id en double" % label)
		seen.append(str(group["id"]))
		var species_id := StringName(group["species"])
		var species_data := species(island_id, species_id)
		if species_data == null:
			found.append("%s : espèce « %s » sans fichier" % [label, species_id])
		elif not species_id in rules.fauna:
			found.append(
				"%s : espèce « %s » absente des règles fauna de l'île" % [label, species_id]
			)
		elif bool(group.get("pack", false)) and species_data.ring_radius_m <= 0.0:
			found.append("%s : meute d'une espèce sans ring_radius_m" % label)
	return found
