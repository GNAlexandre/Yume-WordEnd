class_name LifeData
extends RefCounted
## (E4) Les données de la vie, écrites à la main (PLAN.md, « (E4) La vie ») : les emplois du
## temps (data/life/<npc_id>.json) et les activités (data/life/activities.json). Lecture,
## vérification (clé inconnue refusée, sauf « _… » : commentaire ; carte, place, activité, tenue
## absentes signalées) et choix de la ligne d'un créneau. Propriétaire : E4.
##
## Emploi du temps : { "gait": allure par défaut, "lines": [ligne…] } ; une ligne :
## - "slot" : un créneau (GameState.SLOTS) ou une liste de créneaux (obligatoire) ;
## - "day" : un jour de l'acte (GameState.day) ou un intervalle [premier, dernier] (facultatif) ;
## - "if" : une condition sur l'histoire, grammaire du « if » des dialogues (DialogueRunner) ;
## - "map" et "place" : la carte (Map.exists) et une place de son nœud Life/Places ; ou "away" :
##   le PNJ est hors des cartes construites (identifiant de la carte à venir, « entrepot_etage ») ;
## - "activity" (activities.json ; défaut « attendre »), "outfit" (NpcData.outfits ; défaut : la
##   tenue de NpcData.skin), "gait" (allure du trajet : une clé de « speeds »), "role" (rôle dans
##   un jeu de groupe).
## Choix (line_for) : la première ligne du créneau dont le jour et la condition sont vrais, les
## lignes à « day » ou « if » d'abord (on écrit la journée de base, puis ses variations, dans
## l'ordre qu'on veut) ; aucune : le PNJ n'est nulle part (absent de toutes les cartes).

const DATA_DIR := "res://data/life"
const ACTIVITIES_FILE := "activities.json"
const FILE_EXTENSION := ".json"
## Dossiers des PNJ : ceux de DialogueRunner (data/npcs, add_npc_dir), puis les fées génériques.
const GENERIC_NPC_DIR := "res://data/npcs/generic"
## Nœud des places d'une carte (Marker3D nommés ; enfants Marker3D : une zone de points).
const PLACES_PATH := "Life/Places"
const DEFAULT_ACTIVITY := &"attendre"
const DEFAULT_GAIT := &"marche"
const SCHEDULE_KEYS: Array[String] = ["gait", "lines"]
const LINE_KEYS: Array[String] = [
	"slot", "day", "if", "map", "place", "away", "activity", "outfit", "gait", "role"
]
const ACTIVITIES_KEYS: Array[String] = ["speeds", "fallbacks", "activities"]
const ACTIVITY_KEYS: Array[String] = [
	"poses",
	"order",
	"arrive",
	"leave",
	"wander",
	"pair",
	"look",
	"step_aside",
	"greet",
	"game",
	"params",
	"gait",
]
const POSE_KEYS: Array[String] = ["anim", "time"]
const WANDER_KEYS: Array[String] = ["pause", "gait"]
const ORDERS: Array[String] = ["loop", "random"]
## Animations connues (cahier n° 1, docs/REFONTE.md 8.1) : une pose n'en nomme pas d'autre.
const ANIMS: Array[StringName] = [
	&"repos",
	&"marche",
	&"parle",
	&"course",
	&"saut",
	&"frappe",
	&"lance",
	&"grimpe",
	&"assis",
	&"lit",
	&"dort",
	&"tombe",
	&"porte",
	&"travaille",
	&"effondre",
	&"hanches",
	&"etreinte",
	&"attaque",
]
## Jeux de groupe : un script par jeu, src/life/games/<jeu>.gd (extends LifeGame).
const GAMES_DIR := "res://src/life/games"

static var _dirs: PackedStringArray = [DATA_DIR]
static var _schedules: Dictionary = {}
static var _activities: Dictionary = {}
static var _activities_loaded: bool = false
static var _places: Dictionary = {}

# --- Emplois du temps --------------------------------------------------------------------------


## Identifiants des PNJ qui ont un emploi du temps (fichiers des dossiers de la vie), triés.
static func cast() -> Array[StringName]:
	var ids: Array[StringName] = []
	for dir: String in _dirs:
		for file_name: String in _list(dir):
			var id := StringName(file_name.get_basename())
			if file_name != ACTIVITIES_FILE and not ids.has(id):
				ids.append(id)
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return ids


## Emploi du temps lu et normalisé d'un PNJ ({} s'il n'en a pas ou s'il est illisible : voir
## problems_of). { "gait": StringName, "lines": [ligne normalisée…] } ; une ligne normalisée :
## slots (Array[StringName]), day (Vector2i, ou Vector2i.ZERO sans jour), condition (Variant,
## null sans « if »), map, place, away, activity, outfit, gait, role (StringName), index (int).
static func schedule(npc_id: StringName) -> Dictionary:
	if _schedules.has(npc_id):
		return _schedules[npc_id]
	var result := {}
	var raw: Variant = _read_json(schedule_path(npc_id))
	if raw is Dictionary and schedule_problems(npc_id, raw, false).is_empty():
		result = _normalize(raw)
	_schedules[npc_id] = result
	return result


## Chemin du fichier d'emploi du temps d'un PNJ ("" s'il n'existe pas).
static func schedule_path(npc_id: StringName) -> String:
	for dir: String in _dirs:
		var path := dir.path_join(String(npc_id) + FILE_EXTENSION)
		if FileAccess.file_exists(path):
			return path
	return ""


## Ligne de l'emploi du temps de npc_id pour un créneau et un jour ({} : aucune, le PNJ n'est
## sur aucune carte). evaluate : faux pour ne pas évaluer les conditions (vraies).
static func line_for(
	npc_id: StringName, slot: StringName, day: int, evaluate: bool = true
) -> Dictionary:
	var lines: Array = schedule(npc_id).get("lines", [])
	for pass_index: int in 2:
		for line: Dictionary in lines:
			var special: bool = line["day"] != Vector2i.ZERO or line["condition"] != null
			if special != (pass_index == 0) or not line["slots"].has(slot):
				continue
			if line["day"] != Vector2i.ZERO:
				var days: Vector2i = line["day"]
				if day < days.x or day > days.y:
					continue
			if evaluate and line["condition"] != null:
				if not DialogueRunner.evaluate(line["condition"]):
					continue
			return line
	return {}


## Ligne du créneau courant (LifeSlots.current(), GameState.day).
static func current_line(npc_id: StringName) -> Dictionary:
	return line_for(npc_id, LifeSlots.current(), GameState.day)


## NpcData d'un PNJ : DialogueRunner.find_npc (data/npcs et les dossiers d'add_npc_dir), puis les
## fées génériques (data/npcs/generic) ; null s'il n'existe pas.
static func find_npc(npc_id: StringName) -> NpcData:
	var npc := DialogueRunner.find_npc(npc_id)
	if npc != null:
		return npc
	var path := GENERIC_NPC_DIR.path_join("%s.tres" % npc_id)
	return load(path) as NpcData if ResourceLoader.exists(path) else null


## Problèmes d'un emploi du temps (vide : valide), en français. raw : le JSON lu (sinon le
## fichier) ; check_world : vérifier aussi cartes, places et tenues (chargement des scènes).
static func schedule_problems(
	npc_id: StringName, raw: Variant = null, check_world: bool = true
) -> PackedStringArray:
	var found := PackedStringArray()
	if raw == null:
		raw = _read_json(schedule_path(npc_id))
	if not raw is Dictionary:
		found.append("%s : la racine doit être un objet {gait, lines}" % npc_id)
		return found
	var data: Dictionary = raw
	_unknown_keys(data, SCHEDULE_KEYS, "%s" % npc_id, found)
	var npc := find_npc(npc_id)
	if npc == null:
		found.append("%s : PNJ introuvable (data/npcs/%s.tres ou generic/)" % [npc_id, npc_id])
	if data.has("gait") and not is_gait(data["gait"]):
		found.append(
			"%s : « gait » %s inconnue (speeds d'activities.json)" % [npc_id, data["gait"]]
		)
	var lines: Variant = data.get("lines")
	if not lines is Array or (lines as Array).is_empty():
		found.append("%s : « lines » doit être une liste non vide" % npc_id)
		return found
	for index: int in (lines as Array).size():
		_line_problems(npc_id, npc, index, (lines as Array)[index], check_world, found)
	return found


## Problèmes de tous les fichiers de la vie (emplois du temps et activités).
static func all_problems() -> PackedStringArray:
	var found := activities_problems()
	for npc_id: StringName in cast():
		found.append_array(schedule_problems(npc_id))
	return found


# --- Activités --------------------------------------------------------------------------------


## Données d'activities.json (lues une fois ; {} si le fichier est invalide).
static func activities_data() -> Dictionary:
	if not _activities_loaded:
		_activities_loaded = true
		var raw: Variant = _read_json(DATA_DIR.path_join(ACTIVITIES_FILE))
		_activities = raw if raw is Dictionary and activities_problems(raw).is_empty() else {}
	return _activities


## Une activité ({} si elle n'existe pas).
static func activity(activity_id: StringName) -> Dictionary:
	var activities: Dictionary = activities_data().get("activities", {})
	return activities.get(String(activity_id), {})


## Vrai si l'activité existe.
static func has_activity(activity_id: StringName) -> bool:
	return not activity(activity_id).is_empty()


## Vitesse d'une allure (m/s) ; 1,3 si elle est inconnue.
static func speed(gait: StringName) -> float:
	var speeds: Dictionary = activities_data().get("speeds", {})
	return float(speeds.get(String(gait), 1.3))


## Vrai si gait est une allure de « speeds ».
static func is_gait(gait: Variant) -> bool:
	if not (gait is String or gait is StringName):
		return false
	var speeds: Dictionary = activities_data().get("speeds", {})
	return speeds.has(String(gait))


## Animations de remplacement d'une animation qu'une planche n'a pas (« fallbacks »).
static func fallbacks(anim: StringName) -> Array:
	var table: Dictionary = activities_data().get("fallbacks", {})
	return table.get(String(anim), [])


## Durée d'une pose ({anim, time}) : time (nombre) ou tirée dans [min, max] ; INF sans time.
static func pose_time(pose: Dictionary, rng: RandomNumberGenerator) -> float:
	var time: Variant = pose.get("time")
	if time is float or time is int:
		return float(time)
	if time is Array and (time as Array).size() == 2:
		return rng.randf_range(float(time[0]), float(time[1]))
	return INF


## Problèmes d'activities.json (raw : le JSON lu, sinon le fichier).
static func activities_problems(raw: Variant = null) -> PackedStringArray:
	var found := PackedStringArray()
	if raw == null:
		raw = _read_json(DATA_DIR.path_join(ACTIVITIES_FILE))
	if not raw is Dictionary:
		found.append("activities.json : la racine doit être un objet")
		return found
	var data: Dictionary = raw
	_unknown_keys(data, ACTIVITIES_KEYS, "activities.json", found)
	var speeds: Variant = data.get("speeds")
	if not speeds is Dictionary or (speeds as Dictionary).is_empty():
		found.append("activities.json : « speeds » doit associer une allure à une vitesse")
	else:
		for gait: String in speeds:
			if gait.begins_with("_"):
				continue
			if not StringName(gait) in ANIMS or not _is_number(speeds[gait]):
				found.append("activities.json : allure %s (animation connue, m/s)" % gait)
	var table: Variant = data.get("fallbacks", {})
	if not table is Dictionary:
		found.append("activities.json : « fallbacks » doit être un objet")
	else:
		for anim: String in table:
			if anim.begins_with("_"):
				continue
			if not StringName(anim) in ANIMS or not _is_anim_list(table[anim]):
				found.append("activities.json : fallbacks.%s (animations connues)" % anim)
	var activities: Variant = data.get("activities")
	if not activities is Dictionary or (activities as Dictionary).is_empty():
		found.append("activities.json : « activities » doit être un objet non vide")
		return found
	for activity_id: String in activities:
		if not activity_id.begins_with("_"):
			_activity_problems(activity_id, activities[activity_id], speeds, found)
	return found


# --- Places -----------------------------------------------------------------------------------


## Noms des places d'une carte (Life/Places, lus dans sa scène sans l'instancier ; gardés en
## noms seulement : la carte n'est pas retenue).
static func map_places(map_id: StringName) -> PackedStringArray:
	if _places.has(map_id):
		return _places[map_id]
	var names := PackedStringArray()
	if Map.exists(map_id):
		var scene := load(Map.scene_path(map_id)) as PackedScene
		var state := scene.get_state() if scene != null else null
		if state != null:
			for i: int in state.get_node_count():
				var parent := String(state.get_node_path(i, true))
				if parent == "./" + PLACES_PATH or parent == PLACES_PATH:
					names.append(String(state.get_node_name(i)))
	_places[map_id] = names
	return names


# --- Dossiers et caches -----------------------------------------------------------------------


## Ajoute un dossier d'emplois du temps (tests, démonstrations).
static func add_dir(dir: String) -> void:
	if not _dirs.has(dir):
		_dirs.append(dir)
	clear_cache()


## Retire un dossier ajouté par add_dir.
static func remove_dir(dir: String) -> void:
	if dir != DATA_DIR and _dirs.has(dir):
		_dirs.remove_at(_dirs.find(dir))
	clear_cache()


## Oublie ce qui a été lu (fichiers modifiés, tests).
static func clear_cache() -> void:
	_schedules.clear()
	_activities.clear()
	_activities_loaded = false
	_places.clear()


# --- Interne ----------------------------------------------------------------------------------


static func _line_problems(
	npc_id: StringName,
	npc: NpcData,
	index: int,
	value: Variant,
	check_world: bool,
	found: PackedStringArray
) -> void:
	var label := "%s, ligne %d" % [npc_id, index + 1]
	if not value is Dictionary:
		found.append("%s : objet attendu" % label)
		return
	var line: Dictionary = value
	_unknown_keys(line, LINE_KEYS, label, found)
	var slots := _slot_list(line.get("slot"))
	if slots.is_empty():
		found.append("%s : « slot » : un créneau (%s) ou une liste" % [label, GameState.SLOTS])
	if line.has("day") and _day_range(line["day"]) == Vector2i.ZERO:
		found.append("%s : « day » : un jour (≥ 1) ou [premier, dernier]" % label)
	if line.has("if"):
		var problem := DialogueRunner.condition_problem(line["if"])
		if not problem.is_empty():
			found.append("%s : « if » : %s" % [label, problem])
	var has_map := line.has("map")
	if has_map == line.has("away"):
		found.append("%s : « map » (et « place ») ou « away », l'un des deux" % label)
	if has_map:
		var map_id := StringName(str(line["map"]))
		if not line.get("place") is String:
			found.append("%s : « place » obligatoire avec « map »" % label)
		elif check_world and not Map.exists(map_id):
			found.append("%s : carte %s absente" % [label, map_id])
		elif check_world and not map_places(map_id).has(str(line["place"])):
			found.append(
				"%s : place %s absente de %s/%s" % [label, line["place"], map_id, PLACES_PATH]
			)
	elif line.has("place"):
		found.append("%s : « place » sans « map »" % label)
	if line.has("away") and not Map.is_valid_id(StringName(str(line["away"]))):
		found.append("%s : « away » : identifiant de carte (snake_case)" % label)
	var activity_id := StringName(str(line.get("activity", DEFAULT_ACTIVITY)))
	if not has_activity(activity_id):
		found.append("%s : activité %s inconnue (activities.json)" % [label, activity_id])
	if line.has("outfit"):
		var outfit := StringName(str(line["outfit"]))
		if npc != null and not npc.has_outfit(outfit):
			found.append("%s : tenue %s absente de NpcData.outfits" % [label, outfit])
		elif npc != null and check_world and not ResourceLoader.exists(npc.outfit_path(outfit)):
			found.append(
				"%s : tenue %s : %s introuvable" % [label, outfit, npc.outfit_path(outfit)]
			)
	if line.has("gait") and not is_gait(line["gait"]):
		found.append("%s : « gait » %s inconnue" % [label, line["gait"]])
	if (
		line.has("role")
		and not (line["role"] is String and Map.is_valid_id(StringName(line["role"])))
	):
		found.append("%s : « role » : un identifiant" % label)


static func _activity_problems(
	activity_id: String, value: Variant, speeds: Variant, found: PackedStringArray
) -> void:
	var label := "activities.json, %s" % activity_id
	if not value is Dictionary:
		found.append("%s : objet attendu" % label)
		return
	var activity_data: Dictionary = value
	_unknown_keys(activity_data, ACTIVITY_KEYS, label, found)
	if activity_data.has("game"):
		var game := str(activity_data["game"])
		if not ResourceLoader.exists(GAMES_DIR.path_join(game + ".gd")):
			found.append("%s : jeu %s inconnu (%s/%s.gd)" % [label, game, GAMES_DIR, game])
	elif not activity_data.has("poses") and not activity_data.has("wander"):
		found.append("%s : « poses », « wander » ou « game »" % label)
	var poses: Variant = activity_data.get("poses", [])
	if not poses is Array:
		found.append("%s : « poses » doit être une liste de {anim, time}" % label)
	else:
		for pose: Variant in poses:
			_pose_problems(label, pose, found)
	for key: String in ["arrive", "leave"]:
		if activity_data.has(key):
			_pose_problems("%s, %s" % [label, key], activity_data[key], found)
	if activity_data.has("order") and not str(activity_data["order"]) in ORDERS:
		found.append("%s : « order » : %s" % [label, ORDERS])
	for key: String in ["pair", "look", "step_aside", "greet"]:
		if activity_data.has(key) and not activity_data[key] is bool:
			found.append("%s : « %s » : true ou false" % [label, key])
	var wander: Variant = activity_data.get("wander", false)
	if wander is Dictionary:
		_unknown_keys(wander, WANDER_KEYS, label + ", wander", found)
		if (wander as Dictionary).has("pause") and not _is_time((wander as Dictionary)["pause"]):
			found.append("%s : wander.pause : un nombre ou [min, max]" % label)
		if (wander as Dictionary).has("gait") and not _has_key(speeds, wander["gait"]):
			found.append("%s : wander.gait inconnue" % label)
	elif not wander is bool:
		found.append("%s : « wander » : true ou {pause, gait}" % label)
	if activity_data.has("gait") and not _has_key(speeds, activity_data["gait"]):
		found.append("%s : « gait » inconnue" % label)
	if activity_data.has("params") and not activity_data["params"] is Dictionary:
		found.append("%s : « params » doit être un objet" % label)


static func _pose_problems(label: String, value: Variant, found: PackedStringArray) -> void:
	if not value is Dictionary:
		found.append("%s : pose {anim, time} attendue" % label)
		return
	var pose: Dictionary = value
	_unknown_keys(pose, POSE_KEYS, label + ", pose", found)
	if not StringName(str(pose.get("anim", ""))) in ANIMS:
		found.append("%s : animation %s inconnue" % [label, pose.get("anim", "")])
	if pose.has("time") and not _is_time(pose["time"]):
		found.append("%s : « time » : un nombre ou [min, max]" % label)


static func _normalize(raw: Dictionary) -> Dictionary:
	var lines: Array[Dictionary] = []
	var default_gait := StringName(str(raw.get("gait", DEFAULT_GAIT)))
	var index := 0
	for value: Dictionary in raw["lines"]:
		(
			lines
			. append(
				{
					"slots": _slot_list(value["slot"]),
					"day": _day_range(value["day"]) if value.has("day") else Vector2i.ZERO,
					"condition": value.get("if"),
					"map": StringName(str(value.get("map", ""))),
					"place": StringName(str(value.get("place", ""))),
					"away": StringName(str(value.get("away", ""))),
					"activity": StringName(str(value.get("activity", DEFAULT_ACTIVITY))),
					"outfit": StringName(str(value.get("outfit", ""))),
					"gait": StringName(str(value.get("gait", default_gait))),
					"role": StringName(str(value.get("role", ""))),
					"index": index,
				}
			)
		)
		index += 1
	return {"gait": default_gait, "lines": lines}


static func _slot_list(value: Variant) -> Array[StringName]:
	var slots: Array[StringName] = []
	var raw: Array = value if value is Array else [value]
	for entry: Variant in raw:
		var slot := StringName(str(entry)) if entry is String else &""
		if not LifeSlots.is_slot(slot):
			return [] as Array[StringName]
		slots.append(slot)
	return slots


static func _day_range(value: Variant) -> Vector2i:
	if _is_number(value) and int(value) >= 1:
		return Vector2i(int(value), int(value))
	if value is Array and (value as Array).size() == 2:
		if _is_number(value[0]) and _is_number(value[1]):
			var first := int(value[0])
			var last := int(value[1])
			if first >= 1 and last >= first:
				return Vector2i(first, last)
	return Vector2i.ZERO


static func _unknown_keys(
	data: Dictionary, allowed: Array[String], label: String, found: PackedStringArray
) -> void:
	for key: Variant in data:
		var text := str(key)
		if not text.begins_with("_") and not allowed.has(text):
			found.append("%s : clé inconnue « %s »" % [label, text])


static func _is_number(value: Variant) -> bool:
	return value is int or (value is float and is_finite(value))


static func _is_time(value: Variant) -> bool:
	if _is_number(value):
		return float(value) >= 0.0
	if value is Array and (value as Array).size() == 2:
		return (
			_is_number(value[0])
			and _is_number(value[1])
			and float(value[0]) >= 0.0
			and float(value[1]) >= float(value[0])
		)
	return false


static func _is_anim_list(value: Variant) -> bool:
	if not value is Array:
		return false
	for entry: Variant in value:
		if not StringName(str(entry)) in ANIMS:
			return false
	return true


static func _has_key(table: Variant, key: Variant) -> bool:
	return table is Dictionary and (table as Dictionary).has(str(key))


static func _list(dir: String) -> PackedStringArray:
	var files := PackedStringArray()
	for file_name: String in ResourceLoader.list_directory(dir):
		if file_name.ends_with(FILE_EXTENSION):
			files.append(file_name)
	files.sort()
	return files


## JSON lu (null s'il manque ou ne se lit pas) ; lecture brute puis JSON.parse : jamais
## d'erreur moteur.
static func _read_json(path: String) -> Variant:
	if path.is_empty() or not FileAccess.file_exists(path):
		return null
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		push_warning(
			(
				"LifeData : JSON invalide dans %s, ligne %d : %s"
				% [path, json.get_error_line() + 1, json.get_error_message()]
			)
		)
		return null
	return json.data
