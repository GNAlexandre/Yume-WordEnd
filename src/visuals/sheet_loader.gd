class_name SheetLoader
extends RefCounted
## Lecture des planches au format de l'easter egg (PLAN.md section 5). Propriétaire : L3.
##
## JSON repris tel quel : { "version", "echelle", "planche": [l, h], "animations": { nom: {
## "ips", "boucle", "images": [[x, y, l, h, ancreX, ancreY], …], "coup": [i, …], "onde": i } } }.
## build_frames() crée un AtlasTexture par image (sans marge) et range son ancre dans la
## métadonnée ANCHOR_META ; CharacterVisual remet l'ancre à l'origine du nœud à chaque image
## avec frame_offset(). Des marges d'AtlasTexture ne suffiraient pas : en 3D, flip_h retourne
## l'image mais pas ses marges, et l'ancre sauterait à chaque image d'un sprite retourné.

## Taille d'un pixel de planche si le skin ne permet pas de la calculer (Chtholly : 1,5 m / 144 px).
const DEFAULT_PIXEL_SIZE := 0.0104
## Métadonnée de chaque AtlasTexture : ancre (Vector2, px depuis le coin haut gauche de l'image).
const ANCHOR_META := &"anchor"

## SpriteFrames déjà construits, par planche (texture + JSON) : un seul jeu d'images partagé
## par tous les visuels qui l'affichent.
static var _cache: Dictionary = {}


## Le JSON de la planche du skin (Dictionary vide si absent ou invalide).
static func read_sheet(skin: SkinData) -> Dictionary:
	if skin == null or skin.frames_json == null:
		return {}
	var data: Variant = skin.frames_json.data
	return data if data is Dictionary else {}


## Animations de la planche : nom → { ips, boucle, images, coup?, onde? }.
static func animations(sheet: Dictionary) -> Dictionary:
	var anims: Variant = sheet.get("animations", {})
	return anims if anims is Dictionary else {}


## SpriteFrames de la planche du skin, construit à la première demande puis partagé (null si le
## skin n'a pas de planche).
static func frames_for(skin: SkinData) -> SpriteFrames:
	if skin == null or skin.sprite_sheet == null or skin.frames_json == null:
		return null
	var key := _cache_key(skin.sprite_sheet, skin.frames_json)
	if not _cache.has(key):
		_cache[key] = build_frames(skin.sprite_sheet, read_sheet(skin))
	return _cache[key]


## Vide le cache (planches modifiées, tests).
static func clear_cache() -> void:
	_cache.clear()


## SpriteFrames construit depuis la planche (sans cache) : une animation par entrée qui a au
## moins une image valide, cadence « ips », boucle « boucle », un AtlasTexture par image.
static func build_frames(texture: Texture2D, sheet: Dictionary) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	if texture == null:
		return frames
	var anims := animations(sheet)
	for anim_name: String in anims:
		var images := _images(anims[anim_name])
		if images.is_empty():
			continue
		var anim: Dictionary = anims[anim_name]
		var anim_id := StringName(anim_name)
		frames.add_animation(anim_id)
		frames.set_animation_speed(anim_id, maxf(float(anim.get("ips", 10)), 0.01))
		frames.set_animation_loop(anim_id, bool(anim.get("boucle", false)))
		for image: Array in images:
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(float(image[0]), float(image[1]), float(image[2]), float(image[3]))
			atlas.set_meta(ANCHOR_META, Vector2(float(image[4]), float(image[5])))
			frames.add_frame(anim_id, atlas)
	return frames


## Décalage (px) d'un sprite 3D non centré (centered = false) qui met l'ancre de l'image à
## l'origine du nœud, image retournée (flip_h) ou non. En 3D, offset.y monte.
static func frame_offset(texture: Texture2D, flipped: bool) -> Vector2:
	var size := texture.get_size()
	var anchor: Vector2 = texture.get_meta(ANCHOR_META, Vector2(size.x / 2.0, size.y))
	return Vector2(anchor.x - size.x if flipped else -anchor.x, anchor.y - size.y)


## Taille d'un pixel de planche en mètres : height_m / hauteur de la 1re image de « repos ».
static func pixel_size(skin: SkinData, sheet: Dictionary) -> float:
	var first := _first_idle_image(sheet)
	if first.is_empty() or skin == null or skin.height_m <= 0.0:
		return DEFAULT_PIXEL_SIZE
	return skin.height_m / float(first[3])


## Demi-largeur du corps (px) dans la 1re image de « repos » : distance de l'ancre au bord le
## plus proche (le côté sans arme). Sert à dimensionner l'ombre ; 0 sans planche.
static func body_half_width(sheet: Dictionary) -> float:
	var first := _first_idle_image(sheet)
	if first.is_empty():
		return 0.0
	return minf(float(first[4]), float(first[2]) - float(first[4]))


## Images « coup » d'une animation (celles où l'attaque touche).
static func hit_frames(sheet: Dictionary, anim: StringName) -> Array[int]:
	var result: Array[int] = []
	var anim_data: Variant = animations(sheet).get(String(anim))
	if anim_data is Dictionary:
		var hits: Variant = (anim_data as Dictionary).get("coup", [])
		if hits is Array:
			for index: Variant in hits:
				result.append(int(index))
	return result


## Image « onde » d'une animation (celle qui lance l'onde), -1 si absente.
static func wave_frame(sheet: Dictionary, anim: StringName) -> int:
	var anim_data: Variant = animations(sheet).get(String(anim))
	if anim_data is Dictionary:
		return int((anim_data as Dictionary).get("onde", -1))
	return -1


## Images valides d'une animation : [x, y, l, h, ancreX, ancreY] avec l et h > 0.
static func _images(anim: Variant) -> Array[Array]:
	var result: Array[Array] = []
	if not anim is Dictionary:
		return result
	var images: Variant = (anim as Dictionary).get("images", [])
	if not images is Array:
		return result
	for image: Variant in images:
		if image is Array and (image as Array).size() >= 6 and image[2] > 0 and image[3] > 0:
			result.append(image)
	return result


static func _first_idle_image(sheet: Dictionary) -> Array:
	var images := _images(animations(sheet).get("repos"))
	return images[0] if not images.is_empty() else []


static func _cache_key(texture: Texture2D, json: JSON) -> String:
	if texture.resource_path.is_empty() or json.resource_path.is_empty():
		return "%d|%d" % [texture.get_instance_id(), json.get_instance_id()]
	return texture.resource_path + "|" + json.resource_path
