class_name IslandRules
extends RefCounted
## Règles d'une île (lot X1, PLAN.md section 3, « Ajouter une île ») : ce que les systèmes
## demandent avant d'agir, lues dans les données et jamais déduites d'un nom de carte.
##
## Les règles d'une île sont celles de son monde (data/world/worlds/<monde>.json, « rules »),
## complétées ou remplacées par les siennes (data/world/islands/<île>.json, « rules ») ; une règle
## que ni l'un ni l'autre ne donne prend sa valeur de UNRULED. WorldAtlas.rules_for(map_id) les
## donne pour une carte ; une carte qui n'appartient à aucune île (cartes de test) n'a pas de
## règle : UNRULED, le comportement d'avant X1.
##
## Clés (format des fichiers) :
## - enemies_allowed (bool) : les Timeres peuvent apparaître (vagues, arène, Timeres libres) ;
## - fauna (liste d'id de data/fauna/) : les animaux permis (E5) ;
## - void_below (« clouds » ou « ground ») : sous le bord du vide, la mer de nuages (Regule
##   Aire) ou le sol jusqu'à l'horizon (la surface) ; MapGround le lit ;
## - sky (id d'un préréglage de data/lighting/, vide : le moment de la journée) : le ciel par
##   défaut d'une carte qui n'a pas de light_preset (Atmosphere) ;
## - void_fall (« last_safe » ou « arrival ») : où ramène une chute hors de l'île sur une carte
##   sans zone (WorldManager.rescue) : au dernier point sûr, ou au marqueur d'arrivée.

const VOID_CLOUDS := &"clouds"
const VOID_GROUND := &"ground"
const VOID_KINDS: Array[StringName] = [VOID_CLOUDS, VOID_GROUND]
const FALL_LAST_SAFE := &"last_safe"
const FALL_ARRIVAL := &"arrival"
const FALL_KINDS: Array[StringName] = [FALL_LAST_SAFE, FALL_ARRIVAL]
## Clés permises dans « rules » et type JSON attendu.
const KEYS := {
	"enemies_allowed": TYPE_BOOL,
	"fauna": TYPE_ARRAY,
	"void_below": TYPE_STRING,
	"sky": TYPE_STRING,
	"void_fall": TYPE_STRING,
}
## Valeurs hors de toute île (et règles qu'un monde ne donne pas) : le comportement d'avant X1.
const UNRULED := {
	"enemies_allowed": true,
	"fauna": [],
	"void_below": "clouds",
	"sky": "",
	"void_fall": "arrival",
}

## Timeres permis (vagues, arène, Timeres libres, banc de performance).
var enemies_allowed: bool = true
## Animaux permis (id de data/fauna/, E5).
var fauna: Array[StringName] = []
## Sous le bord du vide : VOID_CLOUDS (mer de nuages) ou VOID_GROUND (sol jusqu'à l'horizon).
var void_below: StringName = VOID_CLOUDS
## Ciel par défaut (préréglage de lumière) ; vide : le moment de la journée.
var sky: StringName = &""
## Chute hors de l'île : FALL_LAST_SAFE ou FALL_ARRIVAL.
var void_fall: StringName = FALL_ARRIVAL
## Île d'où viennent ces règles (&"" : hors de toute île).
var island: StringName = &""


## Règles faites des couches données, dans l'ordre (les dernières l'emportent), par-dessus
## UNRULED. Chaque couche est un « rules » déjà vérifié (problem()).
static func merged(layers: Array[Dictionary], island_id: StringName = &"") -> IslandRules:
	var values := UNRULED.duplicate(true)
	for layer: Dictionary in layers:
		for key: Variant in layer:
			if KEYS.has(str(key)):
				values[str(key)] = layer[key]
	var rules := IslandRules.new()
	rules.island = island_id
	rules.enemies_allowed = bool(values["enemies_allowed"])
	for animal: Variant in values["fauna"]:
		rules.fauna.append(StringName(str(animal)))
	rules.void_below = StringName(str(values["void_below"]))
	rules.sky = StringName(str(values["sky"]))
	rules.void_fall = StringName(str(values["void_fall"]))
	return rules


## Règles hors de toute île (UNRULED).
static func unruled() -> IslandRules:
	return merged([])


## Premier problème d'un objet « rules » lu dans un JSON, "" s'il est valide : clé inconnue
## (sauf « _… »), type, valeur hors de VOID_KINDS ou FALL_KINDS, préréglage de ciel inconnu.
static func problem(data: Variant) -> String:
	if not data is Dictionary:
		return "rules : objet attendu"
	for key: Variant in data:
		var key_name := str(key)
		if key_name.begins_with("_"):
			continue
		if not KEYS.has(key_name):
			return "rules : clé inconnue « %s »" % key_name
		var value: Variant = (data as Dictionary)[key]
		if typeof(value) != KEYS[key_name]:
			return "rules.%s : type %s attendu" % [key_name, type_string(KEYS[key_name])]
	var dict := data as Dictionary
	if dict.has("fauna"):
		for animal: Variant in dict["fauna"]:
			if not animal is String or not Map.is_valid_id(StringName(animal)):
				return "rules.fauna : identifiants snake_case attendus"
	if dict.has("void_below") and not StringName(dict["void_below"]) in VOID_KINDS:
		return "rules.void_below : %s attendu" % " ou ".join(VOID_KINDS)
	if dict.has("void_fall") and not StringName(dict["void_fall"]) in FALL_KINDS:
		return "rules.void_fall : %s attendu" % " ou ".join(FALL_KINDS)
	if dict.has("sky") and not str(dict["sky"]).is_empty():
		if not HD2DLighting.has_preset(StringName(dict["sky"])):
			return "rules.sky : préréglage de lumière « %s » introuvable" % dict["sky"]
	return ""


## Vrai si la mer de nuages est sous le bord du vide (Regule Aire).
func clouds_below() -> bool:
	return void_below == VOID_CLOUDS


## Vrai si un sol s'étend jusqu'à l'horizon (la surface).
func ground_below() -> bool:
	return void_below == VOID_GROUND


## Copie des règles, en dictionnaire (journal, tests).
func to_dict() -> Dictionary:
	var animals: Array[String] = []
	for animal: StringName in fauna:
		animals.append(String(animal))
	return {
		"enemies_allowed": enemies_allowed,
		"fauna": animals,
		"void_below": String(void_below),
		"sky": String(sky),
		"void_fall": String(void_fall),
	}
