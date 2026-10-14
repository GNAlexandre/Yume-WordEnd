class_name LifeTexts
extends RefCounted
## (E4) Les textes de la vie (data/texts/life.json) : bulles de salutation, répliques des jeux,
## prénoms des fées génériques. Propriétaire : E4.
##
## Format : un objet ; chaque valeur est un texte, une liste de textes (une bulle tirée au
## hasard) ou un objet de même forme ; clés « _… » : commentaires. {player} et les variables des
## dialogues y sont remplacés (DialogueRunner.format_text). Chemins par « / » comme
## DialogueRunner.story_text : « greetings/willem », « games/chat/player_it ».

const PATH := "res://data/texts/life.json"
## Salutations : greetings/<npc_id>, sinon greetings/<groupe> (petites, aînées, adultes), sinon
## greetings/default.
const GROUPS := {
	&"tiat": "petites",
	&"collon": "petites",
	&"pannibal": "petites",
	&"lakhesh": "petites",
	&"almita": "petites",
	&"ithea": "ainees",
	&"nephren": "ainees",
}

static var _data: Dictionary = {}
static var _loaded: bool = false


## Les textes lus ({} si le fichier est invalide).
static func data() -> Dictionary:
	if not _loaded:
		_loaded = true
		_data = {}
		if FileAccess.file_exists(PATH):
			var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
			if parsed is Dictionary and problem(parsed).is_empty():
				_data = parsed
	return _data


## Valeur brute à un chemin (texte, liste, objet ; null si absente).
static func raw(key_path: String) -> Variant:
	var value: Variant = data()
	for key: String in key_path.split("/"):
		value = (value as Dictionary).get(key) if value is Dictionary else null
	return value


## Un texte au chemin (tiré au hasard dans une liste), variables remplacées ; fallback sinon.
static func text(
	key_path: String, fallback: String = "", rng: RandomNumberGenerator = null
) -> String:
	var value: Variant = raw(key_path)
	if value is Array and not (value as Array).is_empty():
		var list: Array = value
		var index := rng.randi_range(0, list.size() - 1) if rng != null else randi() % list.size()
		value = list[index]
	return DialogueRunner.format_text(value) if value is String else fallback


## Bulle de salutation d'un PNJ (greetings/<id>, puis son groupe, puis default) ; "" sans texte.
static func greeting(npc_id: StringName, rng: RandomNumberGenerator = null) -> String:
	for key: String in [String(npc_id), str(GROUPS.get(npc_id, "")), "default"]:
		if key.is_empty():
			continue
		var line := text("greetings/" + key, "", rng)
		if not line.is_empty():
			return line
	return ""


## Prénoms des fées génériques (fairy_names), dans l'ordre du fichier.
static func fairy_names() -> PackedStringArray:
	var names := PackedStringArray()
	var value: Variant = raw("fairy_names")
	if value is Array:
		for entry: Variant in value:
			names.append(str(entry))
	return names


## Prénom tiré pour une fée générique sans nom (stable : d'après son identifiant).
static func fairy_name(npc_id: StringName) -> String:
	var names := fairy_names()
	return names[absi(hash(String(npc_id))) % names.size()] if not names.is_empty() else ""


## Problème de forme d'un fichier de textes déjà lu, "" s'il est valide.
static func problem(value: Variant, where: String = "racine") -> String:
	if value is String:
		return ""
	if value is Array:
		if (value as Array).is_empty():
			return "%s : liste vide" % where
		for entry: Variant in value:
			if not entry is String:
				return "%s : liste de textes attendue" % where
		return ""
	if not value is Dictionary:
		return "%s : texte, liste de textes ou objet attendu" % where
	for key: Variant in value:
		var key_name := str(key)
		if key_name.begins_with("_"):
			continue
		var path := key_name if where == "racine" else where + "/" + key_name
		var found := problem((value as Dictionary)[key], path)
		if not found.is_empty():
			return found
	return ""


## Oublie ce qui a été lu.
static func clear_cache() -> void:
	_data = {}
	_loaded = false
