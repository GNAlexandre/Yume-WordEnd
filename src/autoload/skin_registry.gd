extends Node
## SkinRegistry : skins jouables, chargés depuis data/skins/*.tres (PLAN.md section 3).
## Propriétaire : L3.
##
## Un nouveau skin = un fichier data/skins/<id>.tres de plus (SkinData), sans code.
## Les visuels d'ennemis vivent ailleurs (data/enemies/visuals/) pour ne pas être jouables.

const SKINS_DIR := "res://data/skins"
const DEFAULT_SKIN_ID := &"chtholly"

var _skins: Array[SkinData] = []


func _ready() -> void:
	reload()


## Relit data/skins/ (ResourceLoader.list_directory fonctionne aussi dans le build exporté).
func reload() -> void:
	_skins.clear()
	for file_name: String in ResourceLoader.list_directory(SKINS_DIR):
		if not file_name.ends_with(".tres"):
			continue
		var skin := load(SKINS_DIR.path_join(file_name)) as SkinData
		if skin != null:
			_skins.append(skin)
	_skins.sort_custom(_before)


## Tous les skins jouables, le skin par défaut en premier puis par nom affiché.
func all() -> Array[SkinData]:
	return _skins.duplicate()


## Skin d'identifiant skin_id, ou null s'il n'existe pas.
func get_skin(skin_id: StringName) -> SkinData:
	for skin: SkinData in _skins:
		if skin.id == skin_id:
			return skin
	return null


## Chtholly, ou le premier skin disponible.
func default_skin() -> SkinData:
	var skin := get_skin(DEFAULT_SKIN_ID)
	if skin == null and not _skins.is_empty():
		skin = _skins[0]
	return skin


func _before(a: SkinData, b: SkinData) -> bool:
	if a.id == DEFAULT_SKIN_ID or b.id == DEFAULT_SKIN_ID:
		return a.id == DEFAULT_SKIN_ID
	return a.display_name.naturalnocasecmp_to(b.display_name) < 0
