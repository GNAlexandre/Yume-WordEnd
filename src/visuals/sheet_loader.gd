class_name SheetLoader
extends RefCounted
## Lecture des planches au format de l'easter egg (PLAN.md section 5). Propriétaire : L3, H6.
##
## JSON repris tel quel : { "version", "echelle", "planche": [l, h], "animations": { nom: {
## "ips", "boucle", "images": [[x, y, l, h, ancreX, ancreY], …], "coup": [i, …], "onde": i } } }.
## build_frames() crée un AtlasTexture par image (sans marge) et range son ancre dans la
## métadonnée ANCHOR_META ; CharacterVisual remet l'ancre à l'origine du nœud à chaque image
## avec frame_offset(). Des marges d'AtlasTexture ne suffiraient pas : en 3D, flip_h retourne
## l'image mais pas ses marges, et l'ancre sauterait à chaque image d'un sprite retourné.
##
## (H6) Vues : SIDE (profil, la planche de SkinData.sprite_sheet / frames_json), FRONT (face) et
## BACK (dos), facultatives. Une vue n'est utilisée que si elle a les mêmes animations, nombres
## d'images, cadences, « coup » et « onde » que le profil (view_problem() vide) : l'horloge et
## les fenêtres de combat ne dépendent jamais de la vue affichée.
## (E4) Planche complémentaire (SkinData.extra_* : `<id>_life`, docs/ASSETS_HD2D_SUKASUKA.md 4.1) :
## read_sheet et frames_for fusionnent ses animations absentes de la planche principale (chaque
## image garde sa planche : EXTRA_KEY dans le JSON fusionné) ; même échelle, même ancrage.
## (E4) Cache en références faibles : un SpriteFrames (et ses images) vit tant qu'un visuel
## l'affiche, puis il est libéré avec la carte quittée (une planche par tenue en mémoire).

## Taille d'un pixel de planche si le skin ne permet pas de la calculer (Chtholly : 1,5 m / 144 px).
const DEFAULT_PIXEL_SIZE := 0.0104
## Métadonnée de chaque AtlasTexture : ancre (Vector2, px depuis le coin haut gauche de l'image).
const ANCHOR_META := &"anchor"
## (H6) Vues d'une planche : profil (tourné vers la droite), face, dos.
const SIDE := &"side"
const FRONT := &"front"
const BACK := &"back"
const VIEWS: Array[StringName] = [SIDE, FRONT, BACK]
## (E4) Clé posée sur les animations d'un JSON fusionné qui viennent de la planche complémentaire.
const EXTRA_KEY := "_complement"

## SpriteFrames déjà construits, par planche (texture + JSON, et planche complémentaire) : un seul
## jeu d'images partagé par tous les visuels qui l'affichent ; (E4) WeakRef, libérés quand plus
## aucun visuel ne les affiche.
static var _cache: Dictionary = {}


## Le JSON de la planche du skin (Dictionary vide si absent ou invalide) ; (H6) view : SIDE
## (profil, par défaut), FRONT ou BACK.
## (E4) Avec une planche complémentaire (SkinData.extra_*), ses animations absentes de la planche
## principale y sont ajoutées (copies marquées EXTRA_KEY) ; sans planche principale : {}.
static func read_sheet(skin: SkinData, view: StringName = SIDE) -> Dictionary:
	var main := _json_data(view_json(skin, view))
	var extra := (
		_json_data(extra_view_json(skin, view)) if extra_view_texture(skin, view) != null else {}
	)
	if main.is_empty() or extra.is_empty():
		return main
	return merge_sheets(main, extra)


## (E4) JSON d'une planche principale et de sa planche complémentaire fusionnés : les animations
## de extra absentes de main y sont ajoutées, copiées et marquées EXTRA_KEY (sans toucher aux
## JSON partagés).
static func merge_sheets(main: Dictionary, extra: Dictionary) -> Dictionary:
	var merged := main.duplicate()
	var anims := animations(main).duplicate()
	var extra_anims := animations(extra)
	for anim_name: String in extra_anims:
		if anims.has(anim_name) or not extra_anims[anim_name] is Dictionary:
			continue
		var copy: Dictionary = (extra_anims[anim_name] as Dictionary).duplicate()
		copy[EXTRA_KEY] = true
		anims[anim_name] = copy
	merged["animations"] = anims
	return merged


## (E4) Planche complémentaire d'une vue (null si le skin n'en a pas).
static func extra_view_texture(skin: SkinData, view: StringName = SIDE) -> Texture2D:
	if skin == null:
		return null
	match view:
		FRONT:
			return skin.extra_front_sheet
		BACK:
			return skin.extra_back_sheet
	return skin.extra_sheet


## (E4) JSON de la planche complémentaire d'une vue (null si le skin n'en a pas).
static func extra_view_json(skin: SkinData, view: StringName = SIDE) -> JSON:
	if skin == null:
		return null
	match view:
		FRONT:
			return skin.extra_front_json
		BACK:
			return skin.extra_back_json
	return skin.extra_json


## (H6) Planche PNG d'une vue (null si le skin ne l'a pas).
static func view_texture(skin: SkinData, view: StringName = SIDE) -> Texture2D:
	if skin == null:
		return null
	match view:
		FRONT:
			return skin.front_sheet
		BACK:
			return skin.back_sheet
	return skin.sprite_sheet


## (H6) JSON d'une vue (null si le skin ne l'a pas).
static func view_json(skin: SkinData, view: StringName = SIDE) -> JSON:
	if skin == null:
		return null
	match view:
		FRONT:
			return skin.front_json
		BACK:
			return skin.back_json
	return skin.frames_json


## (H6) Vrai si la vue est affichable : planche et JSON présents et, pour la face et le dos,
## compatibles avec le profil (view_problem).
static func has_view(skin: SkinData, view: StringName) -> bool:
	if view_texture(skin, view) == null or view_json(skin, view) == null:
		return false
	return view == SIDE or view_problem(skin, view).is_empty()


## (H6) Ce qui empêche une vue de remplacer le profil sans toucher à l'horloge ni au combat ("" si
## rien) : animation absente ou en trop, nombre d'images, ips, boucle, coup ou onde différents.
static func view_problem(skin: SkinData, view: StringName) -> String:
	var side := animations(read_sheet(skin, SIDE))
	var other := animations(read_sheet(skin, view))
	if other.is_empty():
		return "vue %s absente" % view
	for anim_name: String in side:
		if not other.has(anim_name):
			return "%s : animation %s absente" % [view, anim_name]
	for anim_name: String in other:
		if not side.has(anim_name):
			return "%s : animation %s en trop" % [view, anim_name]
		if _signature(other[anim_name]) != _signature(side[anim_name]):
			return (
				"%s : %s diffère du profil (images, ips, boucle, coup ou onde)" % [view, anim_name]
			)
	return ""


## Animations de la planche : nom → { ips, boucle, images, coup?, onde? }.
static func animations(sheet: Dictionary) -> Dictionary:
	var anims: Variant = sheet.get("animations", {})
	return anims if anims is Dictionary else {}


## SpriteFrames d'une vue de la planche du skin (profil par défaut), construit à la première
## demande puis partagé (null si le skin n'a pas cette planche).
## (E4) Avec une planche complémentaire, ses animations absentes de la planche principale sont
## ajoutées (images découpées dans sa propre planche).
static func frames_for(skin: SkinData, view: StringName = SIDE) -> SpriteFrames:
	var texture := view_texture(skin, view)
	var json := view_json(skin, view)
	if texture == null or json == null:
		return null
	var extra_texture := extra_view_texture(skin, view)
	var extra_json := extra_view_json(skin, view)
	var has_extra := extra_texture != null and extra_json != null
	var key := _cache_key(texture, json)
	if has_extra:
		key += "+" + _cache_key(extra_texture, extra_json)
	var cached: WeakRef = _cache.get(key)
	var frames: SpriteFrames = cached.get_ref() if cached != null else null
	if frames == null:
		frames = build_frames(texture, _json_data(json))
		if has_extra:
			add_frames(frames, extra_texture, _json_data(extra_json), false)
		_cache[key] = weakref(frames)
	return frames


## Vide le cache (planches modifiées, tests).
static func clear_cache() -> void:
	_cache.clear()


## (E4) Nombre de jeux d'images encore en vie dans le cache (mesures, tests de mémoire).
static func cached_count() -> int:
	var alive := 0
	for key: String in _cache.keys():
		if (_cache[key] as WeakRef).get_ref() == null:
			_cache.erase(key)
		else:
			alive += 1
	return alive


## SpriteFrames construit depuis la planche (sans cache) : une animation par entrée qui a au
## moins une image valide, cadence « ips », boucle « boucle », un AtlasTexture par image.
static func build_frames(texture: Texture2D, sheet: Dictionary) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	add_frames(frames, texture, sheet, true)
	return frames


## (E4) Ajoute à frames les animations de la planche (texture, sheet) ; replace faux : celles que
## frames a déjà sont gardées (planche complémentaire).
static func add_frames(
	frames: SpriteFrames, texture: Texture2D, sheet: Dictionary, replace: bool
) -> void:
	if texture == null:
		return
	var anims := animations(sheet)
	for anim_name: String in anims:
		var images := _images(anims[anim_name])
		if images.is_empty():
			continue
		var anim: Dictionary = anims[anim_name]
		var anim_id := StringName(anim_name)
		if frames.has_animation(anim_id):
			if not replace:
				continue
			frames.remove_animation(anim_id)
		frames.add_animation(anim_id)
		frames.set_animation_speed(anim_id, maxf(float(anim.get("ips", 10)), 0.01))
		frames.set_animation_loop(anim_id, bool(anim.get("boucle", false)))
		for image: Array in images:
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(float(image[0]), float(image[1]), float(image[2]), float(image[3]))
			atlas.set_meta(ANCHOR_META, Vector2(float(image[4]), float(image[5])))
			frames.add_frame(anim_id, atlas)


## Décalage (px) d'un sprite 3D non centré (centered = false) qui met l'ancre de l'image à
## l'origine du nœud, image retournée (flip_h) ou non. En 3D, offset.y monte.
static func frame_offset(texture: Texture2D, flipped: bool) -> Vector2:
	var size := texture.get_size()
	var anchor: Vector2 = texture.get_meta(ANCHOR_META, Vector2(size.x / 2.0, size.y))
	return Vector2(anchor.x - size.x if flipped else -anchor.x, anchor.y - size.y)


## Taille d'un pixel de planche en mètres : height_m / hauteur debout de la 1re image de
## « repos » du profil (sheet), du haut de l'image aux pieds (l'ancre) : ce qui dépasse sous les
## pieds (pointe de l'épée de bois de Pannibal, pattes du Timere) ne compte pas. (H6) Pour une
## autre vue (view_sheet) : la même hauteur debout que le profil (de l'ancre au haut de la 1re
## image de « repos »), pour que le personnage garde sa taille en se tournant même si la vue est
## dessinée un peu plus petite ou plus grande.
static func pixel_size(skin: SkinData, sheet: Dictionary, view_sheet: Dictionary = {}) -> float:
	var first := _first_idle_image(sheet)
	if first.is_empty() or skin == null or skin.height_m <= 0.0:
		return DEFAULT_PIXEL_SIZE
	var standing := float(first[5]) if float(first[5]) > 0.0 else float(first[3])
	var size := skin.height_m / standing
	var other := _first_idle_image(view_sheet)
	if other.is_empty() or float(other[5]) <= 0.0 or float(first[5]) <= 0.0:
		return size
	return size * float(first[5]) / float(other[5])


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


## Ce qui doit être identique d'une vue à l'autre : nombre d'images, ips, boucle, coup, onde.
static func _signature(anim: Variant) -> Array:
	if not anim is Dictionary:
		return []
	var data: Dictionary = anim
	var hits: Array[int] = []
	var raw_hits: Variant = data.get("coup", [])
	if raw_hits is Array:
		for index: Variant in raw_hits:
			hits.append(int(index))
	return [
		_images(data).size(),
		float(data.get("ips", 10)),
		bool(data.get("boucle", false)),
		hits,
		int(data.get("onde", -1)),
	]


static func _json_data(json: JSON) -> Dictionary:
	if json == null:
		return {}
	var data: Variant = json.data
	return data if data is Dictionary else {}


static func _cache_key(texture: Texture2D, json: JSON) -> String:
	if texture.resource_path.is_empty() or json.resource_path.is_empty():
		return "%d|%d" % [texture.get_instance_id(), json.get_instance_id()]
	return texture.resource_path + "|" + json.resource_path
