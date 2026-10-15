class_name GameRules
extends RefCounted
## (E8) Les règles des jeux : un fichier JSON par jeu, data/games/<jeu>.json (ballon,
## staff_training). Les chiffres des jeux n'ont jamais leur place dans un script (CLAUDE.md) :
## chaque jeu lit ici sa durée de mi-temps, sa vitesse de frappe, la fenêtre de sa parade, etc.
## Propriétaire : E8.
##
## Format : un objet de sections (objets) et de valeurs (nombres, textes, listes) ; une clé qui
## commence par « _ » est un commentaire. On lit une valeur par son chemin (« kick/reach »), avec
## une valeur par défaut. Un jeu peut surcharger des chiffres à l'exécution par sa table
## `overrides` (mêmes chemins) : les tests raccourcissent ainsi une mi-temps sans toucher au
## fichier.

const DIR := "res://data/games"

static var _cache: Dictionary = {}


## Vide le cache des fichiers lus.
static func clear_cache() -> void:
	_cache.clear()


## Chemin du fichier des règles d'un jeu.
static func path(game_id: StringName) -> String:
	return DIR.path_join("%s.json" % game_id)


## Règles d'un jeu ({} si le fichier manque ou n'est pas un objet).
static func rules(game_id: StringName) -> Dictionary:
	if not _cache.has(game_id):
		var parsed: Variant = _read(path(game_id))
		_cache[game_id] = parsed if parsed is Dictionary else {}
	return _cache[game_id]


## Valeur d'un chemin (« kick/reach ») dans les règles d'un jeu ; overrides l'emporte (mêmes
## chemins), puis le fichier, puis default.
static func value(
	game_id: StringName, key_path: String, default: Variant, overrides: Dictionary = {}
) -> Variant:
	if overrides.has(key_path):
		return overrides[key_path]
	var node: Variant = rules(game_id)
	for part: String in key_path.split("/"):
		if not node is Dictionary or not (node as Dictionary).has(part):
			return default
		node = (node as Dictionary)[part]
	return node


## Nombre d'un chemin (float), default s'il manque ou n'est pas un nombre.
static func number(
	game_id: StringName, key_path: String, default: float, overrides: Dictionary = {}
) -> float:
	var found: Variant = value(game_id, key_path, default, overrides)
	return float(found) if found is float or found is int else default


## Problèmes d'un fichier de règles (vide : valide) : objet de sections, valeurs de types connus,
## nombres positifs, chemins `required` présents.
static func problems(game_id: StringName, required: Array[String] = []) -> PackedStringArray:
	var found := PackedStringArray()
	var parsed: Variant = _read(path(game_id))
	if not parsed is Dictionary:
		found.append("%s : le fichier manque ou sa racine n'est pas un objet" % path(game_id))
		return found
	_check_node(parsed, String(game_id), found)
	for key_path: String in required:
		if value(game_id, key_path, null) == null:
			found.append("%s : « %s » manque" % [game_id, key_path])
	return found


static func _check_node(node: Dictionary, label: String, found: PackedStringArray) -> void:
	for key: Variant in node:
		var key_name := str(key)
		if key_name.begins_with("_"):
			continue
		var child: Variant = node[key]
		if child is Dictionary:
			_check_node(child, "%s/%s" % [label, key_name], found)
		elif child is float or child is int:
			if float(child) < 0.0:
				found.append("%s/%s : un nombre négatif (%s)" % [label, key_name, child])
		elif not (child is String or child is Array or child is bool):
			found.append("%s/%s : type inattendu" % [label, key_name])


static func _read(file_path: String) -> Variant:
	if not FileAccess.file_exists(file_path):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(file_path))
