class_name StoryFreeData
extends RefCounted
## (X-L0) Les clés du rythme libre dans les données du récit (PLAN.md, « (X) Exploration libre :
## le rythme »), vérifiées pour StoryData (même format strict : une clé inconnue est une faute,
## « _… » : commentaire). Propriétaire : X-L0 (les lots L1, L2, L4 y ajoutent leurs clés).
##
## - Une scène : « offer » (l'ancre de sa proposition : {"npc": id} ou {"point": nom,
##   "map": id}, la carte de la scène par défaut ; « text » : la clé de son texte) ; « skip »
##   ({"flags": [...]} : les drapeaux posés quand on la passe) ; « free » (FREE_SCENE_KEYS ;
##   chain : une suite qui s'enchaîne juste après sa tête, StoryPacing.is_chained).
## - L'acte : « free » (FREE_ACT_KEYS ; start_slot : créneau du jour 1 en libre ; start_card :
##   carton « Jour 1 » d'une nouvelle partie).

## Clés de l'ancre d'une proposition, de ce que pose une scène passée, des réglages d'une scène
## et de l'acte.
const OFFER_KEYS: Array[String] = ["npc", "point", "map", "text"]
const SKIP_KEYS: Array[String] = ["flags"]
const FREE_SCENE_KEYS: Array[String] = ["chain"]
const FREE_ACT_KEYS: Array[String] = ["start_slot", "start_card"]


## Les clés du libre d'une scène (offer, skip, free).
static func check_scene(data: Dictionary, context: Dictionary, found: PackedStringArray) -> void:
	check_offer(data.get("offer"), context, found)
	check_skip(data.get("skip"), found)
	check_free(data.get("free"), found)


## Réglages du libre de l'acte (facultatifs).
static func check_act(value: Variant, found: PackedStringArray) -> void:
	if value == null:
		return
	if not value is Dictionary:
		found.append("« free » : objet attendu")
		return
	var settings: Dictionary = value
	StoryData._unknown(settings, FREE_ACT_KEYS, "free", found)
	if (
		settings.has("start_slot")
		and not LifeSlots.is_slot(StringName(str(settings["start_slot"])))
	):
		found.append("free.start_slot : créneau attendu")
	if settings.has("start_card") and not settings["start_card"] is bool:
		found.append("free.start_card : vrai ou faux")


## L'ancre d'une proposition : {"npc": id} ou {"point": nom, "map": id} (la carte de la scène
## par défaut), « text » facultatif (clé de texte, sous l'id de la scène sans « / »).
static func check_offer(value: Variant, context: Dictionary, found: PackedStringArray) -> void:
	if value == null:
		return
	if not value is Dictionary:
		found.append('« offer » : objet attendu ({"npc": …} ou {"point": …, "map": …})')
		return
	var offer: Dictionary = value
	StoryData._unknown(offer, OFFER_KEYS, "offer", found)
	var world: bool = context["world"]
	if offer.has("npc") == offer.has("point"):
		found.append("offer : « npc » ou « point », un seul des deux")
	if offer.has("npc"):
		StoryData._check_npc(offer["npc"], "offer.npc", world, found)
		if offer.has("map"):
			found.append("offer.map : seulement avec « point »")
	if offer.has("point"):
		var map_id: StringName = context["map"]
		if offer.has("map"):
			StoryData._check_map(offer["map"], "offer.map", world, found, true)
			map_id = StringName(str(offer["map"]))
		if world and Map.exists(map_id):
			StoryData._check_point(map_id, offer["point"], "offer.point", found)
		elif not StoryData._is_point(offer["point"]):
			found.append("offer.point : place ou [x, z] attendus")
	if offer.has("text"):
		StoryData._check_text(
			context["island"], offer["text"], context["scene"], "offer.text", world, found
		)


## Ce que pose une scène passée : {"flags": [...]}.
static func check_skip(value: Variant, found: PackedStringArray) -> void:
	if value == null:
		return
	if not value is Dictionary:
		found.append('« skip » : objet attendu ({"flags": […]})')
		return
	var skip: Dictionary = value
	StoryData._unknown(skip, SKIP_KEYS, "skip", found)
	if skip.has("flags") and StoryData._names(skip["flags"]).is_empty():
		found.append("skip.flags : un drapeau ou une liste")


## Réglages du libre d'une scène.
static func check_free(value: Variant, found: PackedStringArray) -> void:
	if value == null:
		return
	if not value is Dictionary:
		found.append("« free » : objet attendu")
		return
	var settings: Dictionary = value
	StoryData._unknown(settings, FREE_SCENE_KEYS, "free", found)
	if settings.has("chain") and not settings["chain"] is bool:
		found.append("free.chain : vrai ou faux")
