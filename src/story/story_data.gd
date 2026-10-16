class_name StoryData
extends RefCounted
## (E6) Le récit en données : l'acte (jours, sommeil, calendrier) et ses scènes, lus et vérifiés
## sans lancer le jeu (PLAN.md, « (E6) Le récit : écrire une scène »). Propriétaire : E6.
##
## Fichiers d'une île (convention X1, WorldAtlas.data_path) :
## - data/scenes/<île>/act.json : l'acte (ACT_KEYS) ; une île sans ce fichier n'a pas de récit ;
## - data/scenes/<île>/<scène>.json : une scène par fichier, son id est le nom du fichier ;
## - data/dialogues/<île>/<fichier>.json : les dialogues des scènes (format de DialogueRunner ;
##   par défaut, le fichier qui porte l'id de la scène) et, dans talk/<pnj>.json, ce que disent
##   les personnages quand on leur parle hors des scènes ;
## - data/texts/<île>/story.json : les textes (indices, cartons, bulles, calendrier, invites), au
##   format des textes de l'histoire ; une clé sans « / » est cherchée sous l'id de la scène.
## Format strict : une clé inconnue est une faute (clé « _… » : commentaire) ; une scène fautive
## n'est pas jouée (avertissement). scene_problems() et act_problems() disent tout ce qui ne va
## pas, monde compris (personnages, cartes, places, textes, animations, tenues, dialogues).
## (X-L0) Rythme libre : clés facultatives d'une scène « offer », « skip » et « free », et de
## l'acte « free », vérifiées par StoryFreeData.

## Fichier de l'acte, dans le dossier des scènes de l'île.
const ACT_FILE := "act.json"
## Dossiers de données (sous root()).
const SCENES_KIND := "scenes"
const DIALOGUES_KIND := "dialogues"
const TEXTS_KIND := "texts"
## Fichier des textes de l'île et dossier des conversations libres (dans ses dialogues).
const TEXTS_FILE := "story.json"
const TALK_DIR := "talk"
const DEFAULT_ROOT := "res://data"
## (S2) Dossier des images du décor (étape « props »).
const IMAGES_DIR := "res://assets/hd2d"
## Qui : le joueur, ou l'id d'un PNJ présent.
const PLAYER := &"player"
## Clés d'une scène, de son déclencheur, de l'acte.
const SCENE_KEYS: Array[String] = [
	"title",
	"day",
	"slot",
	"after",
	"if",
	"trigger",
	"map",
	"marker",
	"present",
	"sequence",
	"key",
	"hint",
	"steps",
	"offer",
	"skip",
	"free",
]
const TRIGGERS: Dictionary = {
	"ready": [],
	"enter": ["map", "marker"],
	"reach": ["point", "radius", "map"],
	"talk": ["npc"],
	"examine": ["key"],
	"prompt": ["point", "prompt", "map", "size"],
}
const ACT_KEYS: Array[String] = [
	"start", "departure_day", "sleep", "rest", "calendar", "days", "free"
]
const START_KEYS: Array[String] = ["map", "marker", "day", "slot", "weather"]
const SLEEP_KEYS: Array[String] = ["map", "point", "prompt", "slots", "wake_slot"]
const REST_KEYS: Array[String] = ["prompt", "points"]
const REST_POINT_KEYS: Array[String] = ["map", "point"]
const CALENDAR_KEYS: Array[String] = ["examine"]
const DAY_KEYS: Array[String] = ["weather", "sleep_after", "sleep_hint"]
## Étapes : « do » → {clé: type} ; un type finissant par « ! » est obligatoire. Toute étape
## accepte aussi « if » (condition de dialogue, avec day, slot, scene, not_scene : l'étape est
## passée si elle est fausse).
const STEPS: Dictionary = {
	"control": {"on": "bool!"},
	"place":
	{
		"who": "who!",
		"at": "point!",
		"offset": "offset",
		"facing": "toward",
		"outfit": "outfit",
		"anim": "anim",
		# (S2) Hauteur en m au-dessus du sol (la pile de la tour de fées, 10.5) : le PNJ n'y
		# retombe pas tant qu'une autre étape ne le repose pas.
		"lift": "number",
	},
	"walk":
	{
		"who": "who!",
		"to": "point!",
		"offset": "offset",
		"gait": "gait",
		"wait": "bool",
		"facing": "toward",
		"direct": "bool",
	},
	"follow": {"who": "who!", "distance": "number", "stop_beyond": "number", "gait": "gait"},
	"unfollow": {"who": "who!"},
	"face": {"who": "who!", "toward": "toward!"},
	"anim": {"who": "who!", "anim": "anim!", "time": "number", "wait": "bool"},
	"outfit": {"who": "npc_who!", "outfit": "outfit!"},
	"leave": {"who": "npc_who!"},
	"release": {"who": "npc_who!"},
	"bubble": {"who": "npc_who!", "text": "text!", "time": "number"},
	"dialogue": {"node": "node!", "file": "file", "npc": "npc", "presentation": "presentation"},
	"camera":
	{
		"to": "toward!",
		"offset": "offset",
		"distance": "number",
		"pitch": "number",
		"time": "number",
		"wait": "bool",
	},
	"camera_reset": {"time": "number", "wait": "bool"},
	"fade": {"to": "fade!", "time": "number"},
	"card": {"text": "text!", "time": "number"},
	"go_to": {"map": "map!", "marker": "marker"},
	"moment": {"moment": "moment", "weather": "weather", "time": "number"},
	"slot": {"slot": "slot!", "time": "number"},
	"next_day": {},
	"flag": {"set": "names", "clear": "names"},
	"wait": {"time": "number!"},
	"wait_for":
	{
		"reach": "point",
		"radius": "number",
		"map": "map",
		"examine": "name",
		"talk": "npc",
		"timeout": "number",
		"timeout_flag": "name",
	},
	"game": {"game": "name!", "params": "dict", "fallback": "steps"},
	"hint": {"text": "text"},
	"calendar": {"line": "name"},
	"show": {"node": "path!", "visible": "bool!"},
	# (E7) Un navire (ShipControl) : descend, s'amarre, ouvre sa trappe, pose sa passerelle, repart ;
	# l'ombre du Barocupot dans les nuages (action « shadow »).
	"ship": {"ship": "ship!", "action": "ship_action!", "wait": "bool"},
	# (S2) La protagoniste cachée le temps d'une séquence sans elle (rendue à la fin de la scène).
	"player": {"visible": "bool!"},
	# (S2) Des images animées posées en cercle autour d'un point, et leur lueur (les talismans de
	# la colline, 8.8) ; retirées par « clear » ou à la fin de la scène.
	"props":
	{
		"id": "name!",
		"image": "image",
		"at": "point",
		"count": "number",
		"radius": "number",
		"lift": "number",
		"frames": "number",
		"fps": "number",
		"light": "number",
		"color": "color",
		"clear": "bool",
	},
}
## Ce qu'attend wait_for : une seule de ces clés.
const WAIT_FOR_KINDS: Array[String] = ["reach", "map", "examine", "talk"]
## Directions nommées (face, facing, camera.to) : le haut de l'écran est le nord.
const DIRECTIONS: Dictionary = {
	"north": Vector3.FORWARD,
	"south": Vector3.BACK,
	"east": Vector3.RIGHT,
	"west": Vector3.LEFT,
}
const GAITS: Array[String] = ["marche", "course"]
## Présentations d'un dialogue (interface « Nuit douce », lot U1) : bandeau (sans boîte, scène
## sans contrôle) ou nuit (la boîte).
const PRESENTATIONS: Array[String] = ["bandeau", "nuit"]
## Couleurs du voile des scènes (fondu au noir, au blanc).
const BLACK := Color(0.043, 0.027, 0.075)
const WHITE := Color(1.0, 0.98, 0.94)
const FADES: Array[String] = ["black", "white", "clear"]

static var _root: String = DEFAULT_ROOT
static var _scenes: Dictionary = {}
static var _acts: Dictionary = {}
static var _texts: Dictionary = {}
static var _ids: Dictionary = {}

# --- Chemins ----------------------------------------------------------------------------------


## Racine des données du récit (res://data ; les tests en prennent une autre).
static func root() -> String:
	return _root


## Change la racine des données (tests) ; vide : res://data. Oublie ce qui a été lu.
static func use_root(path: String) -> void:
	_root = path if not path.is_empty() else DEFAULT_ROOT
	clear_cache()


## Chemin d'un fichier de récit d'une île : <racine>/<kind>/<île>/<fichier>.
static func file_path(kind: String, island_id: StringName, file: String) -> String:
	return "%s/%s/%s/%s" % [_root, kind, island_id, file]


## Fichier d'un dialogue de l'île (file : son id, « talk/willem »…).
static func dialogue_path(island_id: StringName, file: String) -> String:
	return file_path(DIALOGUES_KIND, island_id, file + ".json")


## Conversation libre d'un PNJ sur l'île ("" s'il n'en a pas).
static func talk_path(island_id: StringName, npc_id: StringName) -> String:
	var found := dialogue_path(island_id, "%s/%s" % [TALK_DIR, npc_id])
	return found if FileAccess.file_exists(found) else ""


## (S2) Image d'une étape « props » : « anim/talisman_float » → son PNG sous IMAGES_DIR.
static func image_path(image: String) -> String:
	return "%s/%s.png" % [IMAGES_DIR, image]


## Oublie les fichiers lus.
static func clear_cache() -> void:
	_scenes.clear()
	_acts.clear()
	_texts.clear()
	_ids.clear()


# --- Lecture ----------------------------------------------------------------------------------


## Vrai si l'île a un récit (act.json lisible et valide).
static func has_act(island_id: StringName) -> bool:
	return not island_id.is_empty() and not act(island_id).is_empty()


## L'acte de l'île ({} : pas de récit, ou fichier fautif — avertissement).
static func act(island_id: StringName) -> Dictionary:
	if _acts.has(island_id):
		return _acts[island_id]
	var data: Dictionary = {}
	var file := file_path(SCENES_KIND, island_id, ACT_FILE)
	if FileAccess.file_exists(file):
		var raw: Variant = _read_json(file)
		var problems := act_problems(raw, island_id, false)
		if problems.is_empty():
			data = raw
		else:
			push_warning("StoryData : acte %s invalide : %s" % [file, "; ".join(problems)])
	_acts[island_id] = data
	return data


## Ids des scènes de l'île (noms des fichiers, sans act.json), triés.
static func scene_ids(island_id: StringName) -> Array[StringName]:
	if _ids.has(island_id):
		return _ids[island_id]
	var ids: Array[StringName] = []
	var dir := "%s/%s/%s" % [_root, SCENES_KIND, island_id]
	if DirAccess.dir_exists_absolute(dir):
		for file_name: String in DirAccess.get_files_at(dir):
			if file_name.get_extension() == "json" and file_name != ACT_FILE:
				ids.append(StringName(file_name.get_basename()))
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	_ids[island_id] = ids
	return ids


## Une scène lue et vérifiée ({} si elle est absente ou fautive — avertissement).
static func scene(island_id: StringName, scene_id: StringName) -> Dictionary:
	var key := "%s/%s" % [island_id, scene_id]
	if _scenes.has(key):
		return _scenes[key]
	var data: Dictionary = {}
	var file := file_path(SCENES_KIND, island_id, String(scene_id) + ".json")
	if FileAccess.file_exists(file):
		var raw: Variant = _read_json(file)
		var problems := scene_problems(scene_id, raw, island_id, false)
		if problems.is_empty():
			data = raw
		else:
			push_warning("StoryData : scène %s invalide : %s" % [file, "; ".join(problems)])
	_scenes[key] = data
	return data


## Textes de l'île (data/texts/<île>/story.json ; {} sans fichier).
static func texts(island_id: StringName) -> Dictionary:
	if not _texts.has(island_id):
		var file := file_path(TEXTS_KIND, island_id, TEXTS_FILE)
		_texts[island_id] = (
			DialogueRunner.load_story_texts(file) if FileAccess.file_exists(file) else {}
		)
	return _texts[island_id]


## Texte brut d'une clé ("" s'il manque) : « a/b » absolue ; sans « / », sous scene_id.
static func raw_text(island_id: StringName, key: String, scene_id: StringName = &"") -> String:
	var full := key if key.contains("/") or scene_id.is_empty() else "%s/%s" % [scene_id, key]
	var value: Variant = texts(island_id)
	for part: String in full.split("/"):
		if part.begins_with("_"):
			return ""
		value = (value as Dictionary).get(part) if value is Dictionary else null
	return value if value is String else ""


## Texte affiché d'une clé ({player}… remplacés) ; fallback s'il manque.
static func text(
	island_id: StringName, key: String, scene_id: StringName = &"", fallback: String = ""
) -> String:
	var found := raw_text(island_id, key, scene_id)
	return DialogueRunner.format_text(found) if not found.is_empty() else fallback


## Jour de l'acte : {weather, sleep_after, sleep_hint} ({} s'il n'est pas décrit).
static func day_data(island_id: StringName, day: int) -> Dictionary:
	var days: Variant = act(island_id).get("days", {})
	return (days as Dictionary).get(str(day), {}) if days is Dictionary else {}


# --- Vérification ---------------------------------------------------------------------------


## Tous les problèmes du récit d'une île (acte, chaque scène, monde compris).
static func all_problems(island_id: StringName) -> PackedStringArray:
	var problems := PackedStringArray()
	var act_file := file_path(SCENES_KIND, island_id, ACT_FILE)
	if FileAccess.file_exists(act_file):
		for problem: String in act_problems(_read_json(act_file), island_id, true):
			problems.append("act.json : " + problem)
	for scene_id: StringName in scene_ids(island_id):
		var file := file_path(SCENES_KIND, island_id, String(scene_id) + ".json")
		for problem: String in scene_problems(scene_id, _read_json(file), island_id, true):
			problems.append("%s : %s" % [scene_id, problem])
	return problems


## Problèmes de l'acte (vide : valide) ; check_world : cartes, places, textes, scènes.
static func act_problems(
	raw: Variant, island_id: StringName, check_world: bool = true
) -> PackedStringArray:
	var found := PackedStringArray()
	if not raw is Dictionary:
		found.append("objet attendu")
		return found
	var data: Dictionary = raw
	_unknown(data, ACT_KEYS, "acte", found)
	var start: Variant = data.get("start")
	if not start is Dictionary:
		found.append("« start » : objet attendu")
	else:
		_unknown(start, START_KEYS, "start", found)
		_check_map(start.get("map"), "start.map", check_world, found, true)
		if not _is_day(start.get("day")):
			found.append("start.day : jour ≥ 1 attendu")
		if not LifeSlots.is_slot(StringName(str(start.get("slot", "")))):
			found.append("start.slot : créneau attendu")
		if start.has("weather") and not GameState.WEATHERS.has(StringName(str(start["weather"]))):
			found.append("start.weather : temps inconnu")
		if check_world and start.has("marker") and Map.exists(StringName(str(start.get("map")))):
			_check_point(StringName(str(start.get("map"))), start["marker"], "start", found)
	if not _is_day(data.get("departure_day")):
		found.append("« departure_day » : jour ≥ 1 attendu")
	_act_sleep(data.get("sleep"), island_id, check_world, found)
	_act_rest(data.get("rest"), island_id, check_world, found)
	var calendar: Variant = data.get("calendar", {})
	if not calendar is Dictionary:
		found.append("« calendar » : objet attendu")
	else:
		_unknown(calendar, CALENDAR_KEYS, "calendar", found)
	_act_days(data.get("days"), island_id, check_world, found)
	StoryFreeData.check_act(data.get("free"), found)
	return found


## Problèmes d'une scène (vide : valide) ; check_world : personnages, cartes, places, textes,
## dialogues, animations et tenues existent.
static func scene_problems(
	scene_id: StringName, raw: Variant, island_id: StringName, check_world: bool = true
) -> PackedStringArray:
	var found := PackedStringArray()
	if not raw is Dictionary:
		found.append("objet attendu")
		return found
	var data: Dictionary = raw
	_unknown(data, SCENE_KEYS, "scène", found)
	if data.has("day") and not _is_day_spec(data["day"]):
		found.append("« day » : un jour ≥ 1 ou [premier, dernier]")
	if data.has("slot") and not _is_slots(data["slot"]):
		found.append("« slot » : un créneau ou une liste de créneaux")
	if data.has("after") and _names(data["after"]).is_empty():
		found.append("« after » : un id de scène ou une liste")
	if data.has("if"):
		var condition := DialogueRunner.condition_problem(data["if"])
		if not condition.is_empty():
			found.append("« if » : " + condition)
	for key: String in ["sequence", "key"]:
		if data.has(key) and not data[key] is bool:
			found.append("« %s » : vrai ou faux" % key)
	var map_id := StringName(str(data.get("map", "")))
	_check_map(data.get("map"), "map", check_world, found, true)
	var present: Array[StringName] = []
	if data.has("present"):
		var names := _names(data["present"])
		if names.is_empty() and not (data["present"] is Array and data["present"].is_empty()):
			found.append("« present » : une liste d'ids de PNJ")
		for npc_id: String in names:
			present.append(StringName(npc_id))
			if check_world and LifeData.find_npc(StringName(npc_id)) == null:
				found.append("present : PNJ inconnu %s" % npc_id)
	if data.has("marker") and check_world and Map.exists(map_id):
		_check_point(map_id, data["marker"], "marker", found)
	if data.has("hint"):
		_check_text(island_id, data["hint"], scene_id, "hint", check_world, found)
	if check_world and data.has("after"):
		for other: String in _names(data["after"]):
			if not FileAccess.file_exists(file_path(SCENES_KIND, island_id, other + ".json")):
				found.append("after : scène inconnue %s" % other)
	var context := {
		"scene": scene_id,
		"island": island_id,
		"present": present,
		"map": map_id,
		"world": check_world,
		"sequence": data.get("sequence", false) == true,
	}
	_check_trigger(data.get("trigger"), context, found)
	StoryFreeData.check_scene(data, context, found)
	var steps: Variant = data.get("steps")
	if not steps is Array or (steps as Array).is_empty():
		found.append("« steps » : une liste d'étapes non vide")
	else:
		_check_steps(steps, "steps", context, found)
	return found


# --- Vérification : l'acte ----------------------------------------------------------------------


static func _act_sleep(
	value: Variant, island_id: StringName, check_world: bool, found: PackedStringArray
) -> void:
	if not value is Dictionary:
		found.append("« sleep » : objet attendu")
		return
	var sleep: Dictionary = value
	_unknown(sleep, SLEEP_KEYS, "sleep", found)
	_check_map(sleep.get("map"), "sleep.map", check_world, found, true)
	if check_world and Map.exists(StringName(str(sleep.get("map", "")))):
		_check_point(StringName(str(sleep["map"])), sleep.get("point"), "sleep.point", found)
	_check_text(island_id, sleep.get("prompt"), &"", "sleep.prompt", check_world, found)
	if not _is_slots(sleep.get("slots")):
		found.append("sleep.slots : créneaux attendus")
	if not LifeSlots.is_slot(StringName(str(sleep.get("wake_slot", "")))):
		found.append("sleep.wake_slot : créneau attendu")


static func _act_rest(
	value: Variant, island_id: StringName, check_world: bool, found: PackedStringArray
) -> void:
	if value == null:
		return
	if not value is Dictionary:
		found.append("« rest » : objet attendu")
		return
	var rest: Dictionary = value
	_unknown(rest, REST_KEYS, "rest", found)
	_check_text(island_id, rest.get("prompt"), &"", "rest.prompt", check_world, found)
	var points: Variant = rest.get("points", [])
	if not points is Array:
		found.append("rest.points : liste attendue")
		return
	for point: Variant in points:
		if not point is Dictionary:
			found.append("rest.points : objets {map, point} attendus")
			continue
		_unknown(point, REST_POINT_KEYS, "rest.points", found)
		_check_map((point as Dictionary).get("map"), "rest.map", check_world, found, true)
		if check_world and Map.exists(StringName(str((point as Dictionary).get("map", "")))):
			_check_point(StringName(str(point["map"])), point.get("point"), "rest.point", found)


static func _act_days(
	value: Variant, island_id: StringName, check_world: bool, found: PackedStringArray
) -> void:
	if not value is Dictionary:
		found.append("« days » : objet attendu (jour → description)")
		return
	for key: Variant in value:
		if str(key).begins_with("_"):
			continue
		if not str(key).is_valid_int() or str(key).to_int() < 1:
			found.append("days : clé %s, un jour ≥ 1 attendu" % key)
			continue
		var day: Variant = (value as Dictionary)[key]
		if not day is Dictionary:
			found.append("days.%s : objet attendu" % key)
			continue
		_unknown(day, DAY_KEYS, "days.%s" % key, found)
		var weather := StringName(str((day as Dictionary).get("weather", "clair")))
		if not GameState.WEATHERS.has(weather):
			found.append("days.%s.weather : temps inconnu" % key)
		if day.has("sleep_after"):
			var after := _names(day["sleep_after"])
			if after.is_empty() and not (day["sleep_after"] is Array):
				found.append("days.%s.sleep_after : ids de scènes" % key)
			for scene_id: String in after:
				var file := file_path(SCENES_KIND, island_id, scene_id + ".json")
				if check_world and not FileAccess.file_exists(file):
					found.append("days.%s.sleep_after : scène inconnue %s" % [key, scene_id])
		if day.has("sleep_hint"):
			_check_text(island_id, day["sleep_hint"], &"", "days.%s" % key, check_world, found)


# --- Vérification : déclencheur et étapes ------------------------------------------------------


static func _check_trigger(value: Variant, context: Dictionary, found: PackedStringArray) -> void:
	if not value is Dictionary:
		found.append('« trigger » : objet attendu ({"on": …})')
		return
	var trigger: Dictionary = value
	var kind := str(trigger.get("on", ""))
	if not TRIGGERS.has(kind):
		found.append("trigger.on : %s inconnu (%s)" % [kind, ", ".join(TRIGGERS.keys())])
		return
	var allowed: Array[String] = ["on"]
	for key: String in TRIGGERS[kind]:
		allowed.append(key)
	_unknown(trigger, allowed, "trigger", found)
	var map_id: StringName = context["map"]
	if trigger.has("map"):
		_check_map(trigger["map"], "trigger.map", context["world"], found, true)
		map_id = StringName(str(trigger["map"]))
	var world: bool = context["world"]
	match kind:
		"enter":
			if trigger.has("marker") and world and Map.exists(map_id):
				_check_point(map_id, trigger["marker"], "trigger.marker", found)
		"reach", "prompt":
			if world and Map.exists(map_id):
				_check_point(map_id, trigger.get("point"), "trigger.point", found)
			elif not _is_point(trigger.get("point")):
				found.append("trigger.point : place ou [x, z] attendus")
			if trigger.has("radius") and not _is_number(trigger["radius"]):
				found.append("trigger.radius : nombre attendu")
			if kind == "prompt":
				_check_text(
					context["island"],
					trigger.get("prompt"),
					context["scene"],
					"trigger.prompt",
					world,
					found
				)
				if trigger.has("size") and not _is_number(trigger["size"]):
					found.append("trigger.size : nombre attendu")
		"talk":
			_check_npc(trigger.get("npc"), "trigger.npc", world, found)
		"examine":
			if not _is_name(trigger.get("key")):
				found.append("trigger.key : clé d'un objet à examiner attendue")


static func _check_steps(
	steps: Array, where: String, context: Dictionary, found: PackedStringArray
) -> void:
	for index: int in steps.size():
		_check_step(steps[index], "%s[%d]" % [where, index], context, found)


static func _check_step(
	value: Variant, where: String, context: Dictionary, found: PackedStringArray
) -> void:
	if not value is Dictionary:
		found.append("%s : objet attendu" % where)
		return
	var step: Dictionary = value
	var kind := str(step.get("do", ""))
	if not STEPS.has(kind):
		found.append("%s : « do » inconnu « %s »" % [where, kind])
		return
	var schema: Dictionary = STEPS[kind]
	var allowed: Array[String] = ["do", "if"]
	for key: String in schema:
		allowed.append(key)
	_unknown(step, allowed, where, found)
	if step.has("if"):
		var condition := DialogueRunner.condition_problem(step["if"])
		if not condition.is_empty():
			found.append("%s.if : %s" % [where, condition])
	for key: String in schema:
		var type: String = schema[key]
		var required := type.ends_with("!")
		type = type.trim_suffix("!")
		if not step.has(key):
			if required:
				found.append("%s : « %s » manque" % [where, key])
			continue
		_check_value(type, step[key], step, "%s.%s" % [where, key], context, found)
	match kind:
		"wait_for":
			var kinds := 0
			for wanted: String in WAIT_FOR_KINDS:
				# « map » précise la carte de « reach » (StoryDirector.expected_met).
				if step.has(wanted) and not (wanted == "map" and step.has("reach")):
					kinds += 1
			if kinds != 1:
				found.append("%s : une seule de reach, map, examine, talk" % where)
			if step.has("map") and not step.has("reach"):
				context["map"] = StringName(str(step["map"]))
		"go_to":
			context["map"] = StringName(str(step.get("map", "")))
		"dialogue":
			_check_dialogue(step, where, context, found)
		"props":
			if not step.get("clear", false) and not (step.has("image") and step.has("at")):
				found.append("%s : « image » et « at » (ou « clear »)" % where)
	if context["sequence"] and (kind == "wait_for" or kind == "control"):
		found.append("%s : une séquence se passe d'une touche, ni %s ni contrôle" % [where, kind])


static func _check_value(
	type: String,
	value: Variant,
	step: Dictionary,
	where: String,
	context: Dictionary,
	found: PackedStringArray
) -> void:
	var world: bool = context["world"]
	match type:
		"bool":
			if not value is bool:
				found.append("%s : vrai ou faux" % where)
		"number":
			if not _is_number(value) or float(value) < 0.0:
				found.append("%s : nombre positif attendu" % where)
		"name":
			if not _is_name(value):
				found.append("%s : nom attendu" % where)
		"names":
			if _names(value).is_empty():
				found.append("%s : un nom ou une liste" % where)
		"dict":
			if not value is Dictionary:
				found.append("%s : objet attendu" % where)
		"offset":
			if not _is_pair(value):
				found.append("%s : [dx, dz] attendu" % where)
		"gait":
			if not GAITS.has(str(value)):
				found.append("%s : allure %s" % [where, " ou ".join(GAITS)])
		"fade":
			if not FADES.has(str(value)):
				found.append("%s : %s" % [where, ", ".join(FADES)])
		"moment":
			if not GameState.MOMENTS.has(StringName(str(value))):
				found.append("%s : moment inconnu %s" % [where, value])
		"weather":
			if not GameState.WEATHERS.has(StringName(str(value))):
				found.append("%s : temps inconnu %s" % [where, value])
		"slot":
			if str(value) != "next" and not LifeSlots.is_slot(StringName(str(value))):
				found.append("%s : créneau inconnu %s" % [where, value])
		"map":
			_check_map(value, where, world, found, true)
		"marker":
			var target_map := StringName(str(step.get("map", "")))
			if world and Map.exists(target_map):
				_check_point(target_map, value, where, found)
		"who", "npc_who":
			_check_who(value, type == "npc_who", where, context, found)
		"npc":
			_check_npc(value, where, world, found)
		"point":
			_check_scene_point(value, where, context, found)
		"toward":
			if not (_is_name(value) and DIRECTIONS.has(str(value))):
				_check_scene_point(value, where, context, found)
		"anim":
			_check_anim(value, step, where, context, found)
		"outfit":
			_check_outfit(value, step, where, context, found)
		"text":
			_check_text(context["island"], value, context["scene"], where, world, found)
		"node", "file":
			if not _is_name(value):
				found.append("%s : nom attendu" % where)
		"presentation":
			if not PRESENTATIONS.has(str(value)):
				found.append("%s : %s" % [where, " ou ".join(PRESENTATIONS)])
		"path":
			var node_path := str(value) if value is String else ""
			if node_path.is_empty() or node_path.begins_with("/") or node_path.contains(".."):
				found.append("%s : chemin d'un nœud de la carte attendu" % where)
		"steps":
			if not value is Array:
				found.append("%s : liste d'étapes attendue" % where)
			else:
				_check_steps(value, where, context, found)
		"ship":
			if not _is_name(value) or not ShipControl.has_ship(StringName(str(value))):
				found.append("%s : navire inconnu %s (data/ships/)" % [where, value])
		"ship_action":
			if not ShipControl.ACTIONS.has(StringName(str(value))):
				found.append("%s : %s" % [where, ", ".join(ShipControl.ACTIONS)])
		"image":
			if not _is_name(value) or not ResourceLoader.exists(image_path(str(value))):
				found.append("%s : image inconnue %s (assets/hd2d/<nom>.png)" % [where, value])
		"color":
			if not _is_name(value) or not Color.html_is_valid(str(value)):
				found.append("%s : couleur attendue (« #cfe4ff »)" % where)
		_:
			found.append("%s : type %s inconnu (moteur)" % [where, type])


static func _check_who(
	value: Variant, npc_only: bool, where: String, context: Dictionary, found: PackedStringArray
) -> void:
	if not _is_name(value):
		found.append("%s : « player » ou un PNJ présent" % where)
		return
	var who := StringName(str(value))
	if who == PLAYER:
		if npc_only:
			found.append("%s : un PNJ présent attendu (pas le joueur)" % where)
		return
	var present: Array[StringName] = context["present"]
	if not present.has(who):
		found.append("%s : %s n'est pas dans « present »" % [where, who])


static func _check_npc(
	value: Variant, where: String, world: bool, found: PackedStringArray
) -> void:
	if not _is_name(value):
		found.append("%s : id de PNJ attendu" % where)
	elif world and LifeData.find_npc(StringName(str(value))) == null:
		found.append("%s : PNJ inconnu %s" % [where, value])


## Une place d'une scène : [x, z], « player », un PNJ présent, ou une place / un marqueur de la
## carte courante de la scène.
static func _check_scene_point(
	value: Variant, where: String, context: Dictionary, found: PackedStringArray
) -> void:
	if _is_pair(value):
		return
	if not _is_name(value):
		found.append("%s : place, marqueur, « player », PNJ ou [x, z]" % where)
		return
	var name := StringName(str(value))
	var present: Array[StringName] = context["present"]
	if name == PLAYER or present.has(name):
		return
	var map_id: StringName = context["map"]
	if context["world"] and Map.exists(map_id):
		_check_point(map_id, value, where, found)


## Place (Life/Places) ou marqueur (Markers) de la carte ; [x, z] aussi.
static func _check_point(
	map_id: StringName, value: Variant, where: String, found: PackedStringArray
) -> void:
	if _is_pair(value):
		return
	if not _is_name(value):
		found.append("%s : place, marqueur ou [x, z] attendus" % where)
		return
	var name := String(value)
	if LifeData.map_places(map_id).has(name):
		return
	if WorldAtlas.scene_markers(map_id).has(StringName(name)):
		return
	found.append("%s : %s n'est ni une place ni un marqueur de %s" % [where, name, map_id])


static func _check_map(
	value: Variant, where: String, world: bool, found: PackedStringArray, required: bool
) -> void:
	if value == null and not required:
		return
	if not _is_name(value):
		found.append("%s : id de carte attendu" % where)
	elif world and not Map.exists(StringName(str(value))):
		found.append("%s : carte inconnue %s" % [where, value])


static func _check_text(
	island_id: StringName,
	value: Variant,
	scene_id: StringName,
	where: String,
	world: bool,
	found: PackedStringArray
) -> void:
	if not _is_name(value):
		found.append("%s : clé de texte attendue" % where)
	elif world and raw_text(island_id, str(value), scene_id).is_empty():
		var full := str(value) if str(value).contains("/") else "%s/%s" % [scene_id, value]
		found.append("%s : texte absent %s" % [where, full])


## Animation d'un PNJ (une de ses planches : la sienne ou une tenue) ou du joueur (sa planche) ;
## un remplaçant de activities.json compte.
static func _check_anim(
	value: Variant, step: Dictionary, where: String, context: Dictionary, found: PackedStringArray
) -> void:
	if not _is_name(value):
		found.append("%s : animation attendue" % where)
		return
	if not context["world"]:
		return
	var anim := StringName(str(value))
	var known := _animations_of(StringName(str(step.get("who", ""))))
	if known.has(anim):
		return
	for fallback: Variant in LifeData.fallbacks(anim):
		if known.has(StringName(str(fallback))):
			return
	found.append("%s : %s n'a pas l'animation %s" % [where, step.get("who"), anim])


static func _check_outfit(
	value: Variant, step: Dictionary, where: String, context: Dictionary, found: PackedStringArray
) -> void:
	if not _is_name(value):
		found.append("%s : nom de tenue attendu" % where)
		return
	var who := StringName(str(step.get("who", "")))
	if who == PLAYER:
		found.append("%s : le joueur garde sa planche" % where)
		return
	var npc := LifeData.find_npc(who) if context["world"] else null
	if npc != null and not npc.has_outfit(StringName(str(value))):
		found.append("%s : %s n'a pas la tenue %s" % [where, who, value])


static func _check_dialogue(
	step: Dictionary, where: String, context: Dictionary, found: PackedStringArray
) -> void:
	if step.has("npc"):
		_check_npc(step["npc"], where + ".npc", context["world"], found)
	if not context["world"]:
		return
	var file := str(step.get("file", context["scene"]))
	var dialogue_file := dialogue_path(context["island"], file)
	if not FileAccess.file_exists(dialogue_file):
		found.append("%s : dialogue absent %s" % [where, dialogue_file])
		return
	var raw: Variant = _read_json(dialogue_file)
	var problem := DialogueRunner.validate(raw)
	if not problem.is_empty():
		found.append("%s : %s : %s" % [where, dialogue_file, problem])
		return
	var nodes: Dictionary = (raw as Dictionary)["nodes"]
	var node := str(step.get("node", ""))
	if not nodes.has(node):
		found.append("%s : nœud %s absent de %s" % [where, node, dialogue_file])
		return
	_check_dialogue_chain(nodes, node, where, context, found)


## Les répliques suivies depuis node : orateurs connus ; dans une séquence (qu'on peut passer),
## aucun choix.
static func _check_dialogue_chain(
	nodes: Dictionary, start: String, where: String, context: Dictionary, found: PackedStringArray
) -> void:
	var seen := {}
	var queue: Array[String] = [start]
	while not queue.is_empty():
		var id: String = queue.pop_front()
		if seen.has(id) or not nodes.has(id):
			continue
		seen[id] = true
		var node: Dictionary = nodes[id]
		var speaker: Variant = node.get("speaker_id")
		if speaker != null and DialogueRunner.find_npc(StringName(str(speaker))) == null:
			found.append("%s → %s.speaker_id : PNJ inconnu de data/npcs %s" % [where, id, speaker])
		var choices: Array = node.get("choices", [])
		if context["sequence"]:
			if not choices.is_empty():
				found.append("%s → %s : pas de choix dans une séquence" % [where, id])
			for effect: String in DialogueRunner.EFFECT_KEYS:
				if node.has(effect):
					found.append(
						"%s → %s : pas d'effet dans une séquence (%s)" % [where, id, effect]
					)
		for choice: Variant in choices:
			if choice is Dictionary and (choice as Dictionary).get("next") is String:
				queue.append(str(choice["next"]))
		if node.get("next") is String:
			queue.append(str(node["next"]))


# --- Outils -------------------------------------------------------------------------------------


## Animations connues d'un personnage : toutes ses planches (PNJ : skin et tenues ; joueur : la
## planche du skin par défaut).
static func _animations_of(who: StringName) -> Dictionary:
	var result := {}
	var skins: Array[SkinData] = []
	if who == PLAYER:
		skins.append(SkinRegistry.default_skin())
	else:
		var npc := LifeData.find_npc(who)
		if npc != null:
			skins.append(npc.skin)
			for outfit: StringName in npc.outfits:
				skins.append(npc.load_outfit(outfit))
	for skin: SkinData in skins:
		if skin != null:
			for anim: Variant in SheetLoader.animations(SheetLoader.read_sheet(skin)):
				result[StringName(str(anim))] = true
	return result


static func _read_json(file: String) -> Variant:
	if not FileAccess.file_exists(file):
		return null
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(file)) != OK:
		return null
	return json.data


static func _unknown(
	data: Dictionary, allowed: Array[String], where: String, found: PackedStringArray
) -> void:
	for key: Variant in data:
		if not str(key).begins_with("_") and not allowed.has(str(key)):
			found.append("%s : clé inconnue « %s »" % [where, key])


static func _is_number(value: Variant) -> bool:
	return value is int or (value is float and is_finite(value))


static func _is_name(value: Variant) -> bool:
	return value is String and not (value as String).is_empty()


static func _is_pair(value: Variant) -> bool:
	return (
		value is Array
		and (value as Array).size() == 2
		and _is_number(value[0])
		and _is_number(value[1])
	)


static func _is_point(value: Variant) -> bool:
	return _is_name(value) or _is_pair(value)


static func _is_day(value: Variant) -> bool:
	return _is_number(value) and int(value) >= 1 and float(value) == int(value)


static func _is_day_spec(value: Variant) -> bool:
	return DialogueRunner.day_range(value).x >= 1


static func _is_slots(value: Variant) -> bool:
	var slots := _names(value)
	if slots.is_empty():
		return false
	for slot: String in slots:
		if not LifeSlots.is_slot(StringName(slot)):
			return false
	return true


## Un nom ou une liste de noms → la liste ([] si mal formé).
static func _names(value: Variant) -> Array[String]:
	var result: Array[String] = []
	var items: Array = value if value is Array else [value]
	for item: Variant in items:
		if not _is_name(item):
			return [] as Array[String]
		result.append(str(item))
	return result
