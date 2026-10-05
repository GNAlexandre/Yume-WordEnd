extends Node
## SkinRegistry : skins jouables, chargés depuis data/skins/*.tres (PLAN.md section 3).
## Propriétaire : L3.
##
## Un nouveau skin = un fichier data/skins/<id>.tres de plus (SkinData), sans code ; son id est
## le nom du fichier. Les visuels d'ennemis vivent ailleurs (data/enemies/visuals/) pour ne pas
## être jouables. Ordre de all() : Chtholly (skin par défaut) d'abord, puis par nom affiché.

const SKINS_DIR := "res://data/skins"
const DEFAULT_SKIN_ID := &"chtholly"

## Dossier relu par reload() (les tests en utilisent un autre).
var skins_dir: String = SKINS_DIR

var _skins: Array[SkinData] = []


func _ready() -> void:
	reload()


## Relit skins_dir (ResourceLoader.list_directory fonctionne aussi dans le build exporté). Les
## fichiers qui ne sont pas des SkinData, sans id ou d'un id déjà vu sont ignorés.
func reload() -> void:
	_skins.clear()
	var seen := {}
	for file_name: String in ResourceLoader.list_directory(skins_dir):
		if not file_name.ends_with(".tres"):
			continue
		var skin := load(skins_dir.path_join(file_name)) as SkinData
		if skin == null or skin.id.is_empty() or seen.has(skin.id):
			continue
		seen[skin.id] = true
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


## Chtholly, ou le premier skin disponible (null si aucun).
func default_skin() -> SkinData:
	var skin := get_skin(DEFAULT_SKIN_ID)
	if skin == null and not _skins.is_empty():
		skin = _skins[0]
	return skin


func _before(a: SkinData, b: SkinData) -> bool:
	if (a.id == DEFAULT_SKIN_ID) != (b.id == DEFAULT_SKIN_ID):
		return a.id == DEFAULT_SKIN_ID
	var order := a.display_name.naturalnocasecmp_to(b.display_name)
	return order < 0 if order != 0 else String(a.id) < String(b.id)
