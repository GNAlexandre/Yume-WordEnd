class_name SheetLoader
extends RefCounted
## Lecture des planches au format de l'easter egg (PLAN.md section 5). Propriétaire : L3.
##
## JSON : { "version", "echelle", "planche": [l, h], "animations": { nom: { "ips", "boucle",
## "images": [[x, y, l, h, ancreX, ancreY], …], "coup": [i, …], "onde": i } } }.
## build_frames() aligne toutes les images sur leur ancre : chaque AtlasTexture reçoit une
## marge qui place l'ancre au même point d'un cadre commun ; anchor_offset() donne le décalage
## du sprite (centered) qui met ce point à l'origine du nœud (les pieds au sol).

## Taille d'un pixel de planche si le skin ne permet pas de la calculer (Chtholly : 1,5 m / 144 px).
const DEFAULT_PIXEL_SIZE := 0.0104


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


## Cadre commun à toutes les images : Rect2i(gauche, haut, droite, bas) autour de l'ancre.
static func anchor_extents(sheet: Dictionary) -> Rect2i:
	var left := 0
	var top := 0
	var right := 0
	var bottom := 0
	var anims := animations(sheet)
	for anim_name: String in anims:
		for image: Array in anims[anim_name].get("images", []):
			var w := int(image[2])
			var h := int(image[3])
			var ax := int(image[4])
			var ay := int(image[5])
			left = maxi(left, ax)
			top = maxi(top, ay)
			right = maxi(right, w - ax)
			bottom = maxi(bottom, h - ay)
	return Rect2i(left, top, right, bottom)


## SpriteFrames construit depuis la planche ; chaque image garde son ancre au même point.
static func build_frames(texture: Texture2D, sheet: Dictionary) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	if texture == null:
		return frames
	var ext := anchor_extents(sheet)
	var canvas := Vector2i(ext.position.x + ext.size.x, ext.position.y + ext.size.y)
	var anims := animations(sheet)
	for anim_name: String in anims:
		var anim: Dictionary = anims[anim_name]
		var anim_id := StringName(anim_name)
		frames.add_animation(anim_id)
		frames.set_animation_speed(anim_id, float(anim.get("ips", 10)))
		frames.set_animation_loop(anim_id, bool(anim.get("boucle", false)))
		for image: Array in anim.get("images", []):
			var x := int(image[0])
			var y := int(image[1])
			var w := int(image[2])
			var h := int(image[3])
			var ax := int(image[4])
			var ay := int(image[5])
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(x, y, w, h)
			var pad_left := ext.position.x - ax
			var pad_top := ext.position.y - ay
			atlas.margin = Rect2(pad_left, pad_top, canvas.x - w, canvas.y - h)
			frames.add_frame(anim_id, atlas)
	return frames


## Décalage (px) d'un AnimatedSprite3D centré pour que l'ancre soit à l'origine du nœud.
static func anchor_offset(sheet: Dictionary) -> Vector2:
	var ext := anchor_extents(sheet)
	return Vector2((ext.size.x - ext.position.x) / 2.0, (ext.position.y - ext.size.y) / 2.0)


## Taille d'un pixel de planche en mètres : height_m / hauteur de la 1re image de « repos ».
static func pixel_size(skin: SkinData, sheet: Dictionary) -> float:
	var anims := animations(sheet)
	var reference_height := 0
	if anims.has("repos") and not anims["repos"].get("images", []).is_empty():
		reference_height = int(anims["repos"]["images"][0][3])
	if reference_height <= 0 or skin == null:
		return DEFAULT_PIXEL_SIZE
	return skin.height_m / reference_height


## Images « coup » d'une animation (celles où l'attaque touche).
static func hit_frames(sheet: Dictionary, anim: StringName) -> Array[int]:
	var result: Array[int] = []
	var anim_data: Variant = animations(sheet).get(String(anim))
	if anim_data is Dictionary:
		for index: Variant in (anim_data as Dictionary).get("coup", []):
			result.append(int(index))
	return result


## Image « onde » d'une animation (celle qui lance l'onde), -1 si absente.
static func wave_frame(sheet: Dictionary, anim: StringName) -> int:
	var anim_data: Variant = animations(sheet).get(String(anim))
	if anim_data is Dictionary:
		return int((anim_data as Dictionary).get("onde", -1))
	return -1
