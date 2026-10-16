class_name GroundAtlas
extends RefCounted
## (F1) L'atlas du sol (assets/hd2d/ground/atlas/ground_atlas.png, tools/hd2d_assets.py atlas) :
## ordre de ses tuiles, repli d'une tuile absente et mipmaps calculées en jeu. Lu par le sol en
## relief des cartes (MapGround, MapGroundData, shaders/map_ground_atlas.gdshaderinc). Repris
## d'IslandTerrain, le sol de l'ancienne île, retirée avec elle.

## (H5) Côté d'une tuile de l'atlas du sol (px) : ses mipmaps ne mélangent pas deux tuiles tant
## que le côté reste divisible (384 = 3 × 2^7 : niveaux 0 à 7).
const ATLAS_TILE := 384
## (H9) Tuiles de l'atlas du sol dans l'ordre du contrat, ATLAS_COLUMNS par rangée : les 12 du
## cahier n° 1 puis les 15 du cahier n° 2 (docs/ASSETS_HD2D_MONDE.md, section 4) ; mêmes indices
## que GROUND_LAYERS de tools/hd2d_assets.py et que map_ground_atlas.gdshaderinc.
const ATLAS_COLUMNS := 4
const GROUND_LAYERS: Array[StringName] = [
	&"grass",
	&"grass_dry",
	&"forest_floor",
	&"path_dirt",
	&"flagstone",
	&"cobble",
	&"sand",
	&"rock",
	&"peat",
	&"water",
	&"mud",
	&"metal",
	&"grass_b",
	&"forest_floor_b",
	&"path_dirt_b",
	&"leaf_litter",
	&"moss",
	&"grass_dry_b",
	&"flagstone_b",
	&"cobble_b",
	&"meadow_flowers",
	&"gravel",
	&"garden_soil",
	&"sand_b",
	&"rock_b",
	&"planks",
	&"stream_bed",
]
## (H9) Tuile d'origine de chaque tuile du cahier n° 2, lue à sa place tant que l'atlas ne l'a pas
## (table GROUND_FALLBACK de map_ground_atlas.gdshaderinc).
const GROUND_FALLBACK := {
	&"grass_b": &"grass",
	&"forest_floor_b": &"forest_floor",
	&"path_dirt_b": &"path_dirt",
	&"leaf_litter": &"forest_floor",
	&"moss": &"forest_floor",
	&"grass_dry_b": &"grass_dry",
	&"flagstone_b": &"flagstone",
	&"cobble_b": &"cobble",
	&"meadow_flowers": &"grass",
	&"gravel": &"path_dirt",
	&"garden_soil": &"mud",
	&"sand_b": &"sand",
	&"rock_b": &"rock",
	&"planks": &"path_dirt",
	&"stream_bed": &"water",
}

## (H5) Atlas du sol avec ses mipmaps, calculé une fois en jeu.
static var _atlas_cache: Texture2D = null


## (H5) Atlas du sol avec ses mipmaps, pour que le sol se filtre au loin au lieu de scintiller
## (moiré) : les images importées n'en ont pas. Calculé une fois ; rend l'atlas tel quel si son
## image est illisible ou s'il a déjà des mipmaps.
static func mipmapped_atlas(atlas: Texture2D) -> Texture2D:
	if atlas == null or atlas == _atlas_cache:
		return atlas
	if _atlas_cache == null:
		var image := atlas.get_image()
		if image == null or image.is_empty() or image.has_mipmaps():
			return atlas
		_atlas_cache = ImageTexture.create_from_image(mipmapped_image(image))
	return _atlas_cache


## (H5) Copie de l'image (RGBA8) avec ses mipmaps : moyenne 2 × 2 par niveau, qui ne mélange
## jamais deux tuiles de ATLAS_TILE px jusqu'au niveau 7 (le shader du sol s'arrête avant).
static func mipmapped_image(source: Image) -> Image:
	var image := source.duplicate() as Image
	if image.is_compressed():
		image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	image.generate_mipmaps()
	return image


## (H9) Nombre de tuiles d'un atlas du sol de cette taille (px) : ATLAS_COLUMNS par rangée de
## ATLAS_TILE px (12 pour 1536 × 1152, 27 pour 1536 × 2688).
static func atlas_tile_count(atlas_size: Vector2i) -> int:
	var rows := maxi(roundi(float(atlas_size.y) / ATLAS_TILE), 1)
	return mini(ATLAS_COLUMNS * rows, GROUND_LAYERS.size())


## (H9) Tuile lue à la place de layer dans un atlas de tile_count tuiles : elle-même si l'atlas
## l'a, sinon sa tuile d'origine (GROUND_FALLBACK).
static func ground_layer(layer: StringName, tile_count: int) -> StringName:
	var index := GROUND_LAYERS.find(layer)
	if index < tile_count or not GROUND_FALLBACK.has(layer):
		return layer
	return GROUND_FALLBACK[layer]
