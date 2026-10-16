class_name DecorGenre
extends RefCounted
## (RD) Genre d'un décor en panneau (DecorPanel) : ce qui règle son ombre peinte, son balancement
## dans le vent et sa variation automatique (PropScatter). Le genre vient de la catégorie de sa
## scène (métadonnée hd2d_category, tools/hd2d_scenes.json : tree, plant, fence…), sinon du nom de
## son image (oak_a, reeds, fence_low…). Les réglages sont des données, ici, par genre (SETTINGS) :
## - shadow : traîne (part de la hauteur de l'image), largeur de la traîne (part de celle du
##   cœur), opacité du cœur et de la traîne, forme (« long » : bande au pied et ombre portée en
##   parallélogramme, pour les clôtures, murs et lisières ; sinon un ovale et une traîne ronde) ;
## - wind : déplacement du haut de l'image (part de sa hauteur en px, plafonné à wind_max px) et
##   part de la hauteur où il commence (wind_from) ;
## - tone : variation de luminosité et de teinte (± part) ; scale : plage d'échelle quand le
##   PropScatter n'en donne pas ; jitter : recul (m, ± en z) ; sink : enfoncement (m, au plus).

const NONE := &"none"
const TREE := &"tree"
const LISIERE := &"lisiere"
const BUSH := &"bush"
const GRASS := &"grass"
const REED := &"reed"
const ROCK := &"rock"
const FENCE := &"fence"
const WALL := &"wall"
const POST := &"post"
const PROP := &"prop"

## Genres qui bougent au vent (DecorPanel.wind_px).
const WINDY: Array[StringName] = [TREE, LISIERE, BUSH, GRASS, REED]

## Catégorie de scène (metadata/hd2d_category) → genre ; absente : d'après le nom de l'image.
const CATEGORY_GENRES := {
	&"tree_large": TREE,
	&"tree": TREE,
	&"tree_thin": TREE,
	&"sapling": TREE,
	&"foreground_canopy": TREE,
	&"lisiere": LISIERE,
	&"plant": BUSH,
	&"foreground": BUSH,
	&"plant_low": GRASS,
	&"plant_tall": REED,
	&"rock": ROCK,
	&"rock_small": ROCK,
	&"edge_rocks": ROCK,
	&"fence": FENCE,
	&"ruin": WALL,
	&"board": POST,
	&"post": POST,
	&"mast": POST,
	&"lamp": POST,
	&"stake": POST,
	&"tower": POST,
	&"foreground_trunk": PROP,
	&"object": PROP,
	&"object_large": PROP,
	&"object_small": PROP,
	&"small_object": PROP,
	&"object_glow": PROP,
	&"seat": PROP,
	&"log": PROP,
	&"fountain": PROP,
	&"line": PROP,
	&"deck_cabin": PROP,
}
## Catégories sans variation ni vent (posées contre un mur, sur un toit, en l'air, au lointain).
const STILL_CATEGORIES: Array[StringName] = [
	&"sky",
	&"hung",
	&"hanging",
	&"roof_detail",
	&"wall_detail",
	&"wall_light",
	&"stairs",
	&"walkable",
	&"fire",
	&"ship",
	&"building",
	&"water",
	&"propeller",
]
## Nom de l'image (sans dossier ni extension) → genre : premières règles qui collent, dans
## l'ordre (un morceau du nom).
const NAME_RULES: Array = [
	["forest_wall", LISIERE],
	["treeline", LISIERE],
	["grove_dense", LISIERE],
	["marsh_reed_wall", LISIERE],
	["reed", REED],
	["cattail", REED],
	["fg_trunk", PROP],
	["stump", PROP],
	["log", PROP],
	["fallen", PROP],
	["flower_pot", PROP],
	["flower_bed", PROP],
	["planter", PROP],
	["window_box", PROP],
	["grass", GRASS],
	["wildflower", GRASS],
	["myosotis", GRASS],
	["fern", GRASS],
	["heather", GRASS],
	["nettle", GRASS],
	["thistle", GRASS],
	["tuft", GRASS],
	["flower", GRASS],
	["hummock", GRASS],
	["bush", BUSH],
	["thicket", BUSH],
	["hedge", BUSH],
	["bramble", BUSH],
	["shrub", BUSH],
	["canopy", TREE],
	["oak", TREE],
	["beech", TREE],
	["birch", TREE],
	["maple", TREE],
	["pine", TREE],
	["alder", TREE],
	["willow", TREE],
	["rowan", TREE],
	["sapling", TREE],
	["snag", TREE],
	["tree", TREE],
	["boulder", ROCK],
	["cairn", ROCK],
	["pebble", ROCK],
	["rock", ROCK],
	["railing", FENCE],
	["fence", FENCE],
	["parapet", FENCE],
	["ruined_wall", WALL],
	["wall_low", WALL],
	["sandbag", WALL],
	["arch", WALL],
	["signpost", POST],
	["lamp", POST],
	["sock", POST],
	["pennant", POST],
	["stake", POST],
	["post", POST],
]

## Réglages par genre (voir l'en-tête).
const SETTINGS := {
	TREE:
	{
		"tail": 0.5,
		"tail_width": 0.7,
		"core_alpha": 0.65,
		"tail_alpha": 0.48,
		"long": false,
		"wind": 0.0065,
		"wind_max": 5.0,
		"wind_from": 0.4,
		"tone": Vector2(0.06, 0.03),
		"scale": Vector2(0.9, 1.1),
		"jitter": 0.25,
		"sink": 0.04,
	},
	LISIERE:
	{
		"tail": 0.35,
		"tail_width": 1.0,
		"core_alpha": 0.5,
		"tail_alpha": 0.35,
		"long": true,
		"wind": 0.005,
		"wind_max": 3.0,
		"wind_from": 0.45,
		"tone": Vector2(0.05, 0.02),
		"scale": Vector2.ONE,
		"jitter": 0.0,
		"sink": 0.0,
	},
	BUSH:
	{
		"tail": 0.6,
		"tail_width": 0.8,
		"core_alpha": 0.5,
		"tail_alpha": 0.36,
		"long": false,
		"wind": 0.02,
		"wind_max": 3.0,
		"wind_from": 0.25,
		"tone": Vector2(0.06, 0.03),
		"scale": Vector2(0.85, 1.15),
		"jitter": 0.25,
		"sink": 0.04,
	},
	GRASS:
	{
		"tail": 0.5,
		"tail_width": 0.8,
		"core_alpha": 0.38,
		"tail_alpha": 0.26,
		"long": false,
		"wind": 0.045,
		"wind_max": 3.0,
		"wind_from": 0.0,
		"tone": Vector2(0.06, 0.03),
		"scale": Vector2(0.8, 1.2),
		"jitter": 0.3,
		"sink": 0.03,
	},
	REED:
	{
		"tail": 0.5,
		"tail_width": 0.8,
		"core_alpha": 0.42,
		"tail_alpha": 0.3,
		"long": false,
		"wind": 0.04,
		"wind_max": 4.0,
		"wind_from": 0.05,
		"tone": Vector2(0.06, 0.03),
		"scale": Vector2(0.85, 1.15),
		"jitter": 0.3,
		"sink": 0.05,
	},
	ROCK:
	{
		"tail": 0.45,
		"tail_width": 0.85,
		"core_alpha": 0.6,
		"tail_alpha": 0.4,
		"long": false,
		"wind": 0.0,
		"wind_max": 0.0,
		"wind_from": 1.0,
		"tone": Vector2(0.04, 0.01),
		"scale": Vector2(0.8, 1.2),
		"jitter": 0.2,
		"sink": 0.06,
	},
	FENCE:
	{
		"tail": 0.6,
		"tail_width": 1.0,
		"core_alpha": 0.45,
		"tail_alpha": 0.3,
		"long": true,
		"wind": 0.0,
		"wind_max": 0.0,
		"wind_from": 1.0,
		"tone": Vector2(0.035, 0.0),
		"scale": Vector2.ONE,
		"jitter": 0.0,
		"sink": 0.0,
	},
	WALL:
	{
		"tail": 0.5,
		"tail_width": 1.0,
		"core_alpha": 0.55,
		"tail_alpha": 0.36,
		"long": true,
		"wind": 0.0,
		"wind_max": 0.0,
		"wind_from": 1.0,
		"tone": Vector2(0.035, 0.0),
		"scale": Vector2.ONE,
		"jitter": 0.0,
		"sink": 0.0,
	},
	POST:
	{
		"tail": 0.8,
		"tail_width": 0.6,
		"core_alpha": 0.45,
		"tail_alpha": 0.36,
		"long": false,
		"wind": 0.0,
		"wind_max": 0.0,
		"wind_from": 1.0,
		"tone": Vector2(0.03, 0.0),
		"scale": Vector2.ONE,
		"jitter": 0.0,
		"sink": 0.0,
	},
	PROP:
	{
		"tail": 0.45,
		"tail_width": 0.8,
		"core_alpha": 0.5,
		"tail_alpha": 0.34,
		"long": false,
		"wind": 0.0,
		"wind_max": 0.0,
		"wind_from": 1.0,
		"tone": Vector2(0.03, 0.01),
		"scale": Vector2.ONE,
		"jitter": 0.1,
		"sink": 0.0,
	},
	NONE:
	{
		"tail": 0.45,
		"tail_width": 0.8,
		"core_alpha": 0.5,
		"tail_alpha": 0.3,
		"long": false,
		"wind": 0.0,
		"wind_max": 0.0,
		"wind_from": 1.0,
		"tone": Vector2.ZERO,
		"scale": Vector2.ONE,
		"jitter": 0.0,
		"sink": 0.0,
	},
}

## Genres retenus par chemin d'image et catégorie (le nom d'une image ne change pas).
static var _cache: Dictionary = {}


## Genre d'une image (chemin res://… ou nom) dans une catégorie de scène (vide : inconnue).
static func of(image_path: String, category: StringName = &"") -> StringName:
	var key := "%s|%s" % [image_path, category]
	if _cache.has(key):
		return _cache[key]
	var genre := NONE
	if category != &"" and STILL_CATEGORIES.has(category):
		genre = NONE
	elif category != &"" and CATEGORY_GENRES.has(category):
		genre = CATEGORY_GENRES[category]
	else:
		genre = _from_name(image_path.get_file().get_basename())
	_cache[key] = genre
	return genre


## Genre d'après le nom d'une image (PROP si aucune règle ne colle, NONE sans nom).
static func _from_name(image_name: String) -> StringName:
	if image_name.is_empty():
		return NONE
	for rule: Array in NAME_RULES:
		if image_name.contains(String(rule[0])):
			return rule[1]
	return PROP


## Réglages d'un genre (SETTINGS ; NONE pour un genre inconnu).
static func settings(genre: StringName) -> Dictionary:
	return SETTINGS.get(genre, SETTINGS[NONE])


## Vrai si le genre bouge au vent.
static func is_windy(genre: StringName) -> bool:
	return WINDY.has(genre)
