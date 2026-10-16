extends Node
## GameState : état de la partie, sérialisable (PLAN.md sections 3 et 4). Propriétaire : L7.
##
## Inventaire (total par objet ; les piles sont déduites des ItemData, voir stacks()), drapeaux,
## objets uniques ramassés, PV max et skin. (F1) Quêtes, quête suivie, zone et scores d'arène sont
## partis avec l'ancienne île (schéma de sauvegarde v4).
## Signaux émis (via EventBus) :
## - inventory_changed à chaque add_item / remove_item réussi, from_dict et reset ;
## - flag_changed dans set_flag (si la valeur change ; jamais dans from_dict ni reset) ;
## - skin_changed et max_hp_changed quand skin_id / max_hp changent.
## - (E9) atmosphere_changed quand moment ou weather changent (setters, from_dict et reset
##   compris) : Atmosphere pose alors la lumière.
## (E6) Le récit : day (jour de l'acte, 1 à 12 ; 0 hors de l'acte en jours), les scènes jouées
## (scenes_done), les lignes du calendrier de la protagoniste (calendar) et la scène en cours
## (story_scene, rejouée depuis son début à la reprise d'une partie) ; tenus par StoryDirector,
## sauvegardés. story_running() : vrai pendant l'acte en jours.
## (X1) island (île courante) et les îles connues sont tenues par WorldManager à chaque arrivée
## sur une île (EventBus.island_entered) ; sauvegardées.
## Mises à jour attendues des autres lots : (E1) map par WorldManager à chaque changement de
## carte, position par le joueur (L1) quand il est au sol. SaveManager (L8) ajoute version et
## saved_at.

## PV max d'une nouvelle partie (règle de l'easter egg).
const DEFAULT_MAX_HP := 5
## Plafonds de sécurité (sauvegarde trafiquée, boucle de ramassage…) : total d'un objet, PV max,
## coordonnée d'une position (m).
const MAX_QUANTITY := 999
const MAX_HP_LIMIT := 20
const MAX_COORDINATE := 1000.0
## (E9) Moments de la journée et temps qu'il fait (préréglages de lumière : data/lighting/,
## src/autoload/atmosphere.gd), dans l'ordre du jour. Le couchant, sans pluie, est le monde de
## toujours : celui d'une nouvelle partie et d'une sauvegarde d'avant E9.
const MOMENTS: Array[StringName] = [&"aube", &"matin", &"apres_midi", &"couchant", &"nuit"]
const WEATHERS: Array[StringName] = [&"clair", &"pluie", &"averse"]
const DEFAULT_MOMENT := &"couchant"
const DEFAULT_WEATHER := &"clair"
## (E4) Créneaux de la vie (emplois du temps, data/life/ ; docs/lore/VIE.md, 0.1), dans l'ordre
## du jour : un de plus que les moments (midi), le soir est le couchant (LifeSlots.moment_of).
const SLOTS: Array[StringName] = [&"aube", &"matin", &"midi", &"apres_midi", &"soir", &"nuit"]
## (E4) Plus grand jour de l'acte accepté (sauvegarde trafiquée).
const MAX_DAY := 99
## (E6) Plus grand nombre de scènes jouées retenues (sauvegarde trafiquée).
const MAX_SCENES := 999

## Skin actif (SkinData.id) ; &"" = skin par défaut de SkinRegistry.
var skin_id: StringName = &"":
	set(value):
		if value == skin_id:
			return
		skin_id = value
		EventBus.skin_changed.emit(value)

## PV max du joueur (5 au départ), entre 1 et MAX_HP_LIMIT.
var max_hp: int = DEFAULT_MAX_HP:
	set(value):
		value = clampi(value, 1, MAX_HP_LIMIT)
		if value == max_hp:
			return
		max_hp = value
		EventBus.max_hp_changed.emit(value)

## (E1) Carte courante (map_id, tenue par WorldManager) ; &"" = nouvelle partie pas encore
## placée (game.gd pose alors le joueur au Spawn de WorldManager.START_MAP).
var map: StringName = &""
## (X1) Île courante (data/world/islands/<id>.json, WorldAtlas.island_of(map)), tenue par
## WorldManager ; &"" : pas encore placée, ou carte hors de toute île.
var island: StringName = &""
## Dernière position au sol du joueur, dans le repère de la carte (sauvegardée, restaurée par
## game.gd).
var position: Vector3 = Vector3.ZERO
## (E9) Moment de la journée (un de MOMENTS ; une autre valeur est refusée, avertissement) et
## temps qu'il fait (un de WEATHERS). Tenus par le récit (E6) ou les raccourcis de test, par
## Atmosphere.set_moment / set_weather (transition douce) ou directement (transition par
## défaut) ; émettent atmosphere_changed. Sauvegardés.
var moment: StringName = DEFAULT_MOMENT:
	set(value):
		if value == moment:
			return
		if not value in MOMENTS:
			push_warning("GameState : moment inconnu %s" % value)
			return
		moment = value
		EventBus.atmosphere_changed.emit(moment, weather)
var weather: StringName = DEFAULT_WEATHER:
	set(value):
		if value == weather:
			return
		if not value in WEATHERS:
			push_warning("GameState : temps inconnu %s" % value)
			return
		weather = value
		EventBus.atmosphere_changed.emit(moment, weather)
## (E4) Jour de l'acte (docs/lore/ACTE1.md : 1 à 12), tenu par le récit (E6) ; 0 (défaut) : pas
## de jour, les lignes d'emploi du temps qui demandent un jour (clé « day ») ne s'appliquent pas.
## Lu par LifeDirector. Sauvegardé (champ facultatif du schéma v3, absent : 0).
var day: int = 0:
	set(value):
		day = clampi(value, 0, MAX_DAY)
## (E4) Créneau de la vie (un de SLOTS, ou &"" : celui du moment, LifeSlots.default_for). Il ne
## sert qu'à distinguer deux créneaux d'un même moment de lumière (midi garde la lumière du
## matin) : LifeDirector.set_slot le pose avec le moment ; un moment qui change ailleurs (F7, le
## récit par Atmosphere.set_moment) le remet à &"" s'il ne lui va plus. Une autre valeur est
## refusée (avertissement). Sauvegardé (champ facultatif du schéma v3, absent : &"").
var slot: StringName = &"":
	set(value):
		if not value.is_empty() and not value in SLOTS:
			push_warning("GameState : créneau inconnu %s" % value)
			return
		slot = value
## (E6) Scène du récit en cours (data/scenes/<île>/<id>.json), &"" hors scène : tenue par
## StoryDirector ; une partie reprise au milieu d'une scène la rejoue depuis son début.
var story_scene: StringName = &""

var _inventory: Dictionary[StringName, int] = {}
var _flags: Dictionary[StringName, bool] = {}
var _collected_pickups: Dictionary[StringName, bool] = {}
## (X1) Îles où le joueur est déjà allé, dans l'ordre de découverte.
var _known_islands: Array[StringName] = []
## (E6) Scènes du récit jouées jusqu'au bout, dans l'ordre.
var _scenes_done: Array[StringName] = []
## (E6) Calendrier : jour → ligne écrite (&"" : la ligne du jour, sinon une clé de ligne).
var _calendar: Dictionary[int, StringName] = {}


## Nouvelle partie : tout revient aux valeurs par défaut.
func reset() -> void:
	skin_id = &""
	max_hp = DEFAULT_MAX_HP
	map = &""
	island = &""
	position = Vector3.ZERO
	moment = DEFAULT_MOMENT
	weather = DEFAULT_WEATHER
	day = 0
	slot = &""
	story_scene = &""
	_inventory.clear()
	_flags.clear()
	_collected_pickups.clear()
	_known_islands.clear()
	_scenes_done.clear()
	_calendar.clear()
	EventBus.inventory_changed.emit()


# --- Récit (E6) -------------------------------------------------------------------------------


## Vrai pendant l'acte en jours (day ≥ 1) : le récit mène.
func story_running() -> bool:
	return day > 0


## Vrai si la scène a été jouée jusqu'au bout.
func is_scene_done(scene_id: StringName) -> bool:
	return _scenes_done.has(scene_id)


## Retient une scène jouée (sans effet si elle l'est déjà).
func mark_scene_done(scene_id: StringName) -> void:
	if scene_id.is_empty() or is_scene_done(scene_id) or _scenes_done.size() >= MAX_SCENES:
		return
	_scenes_done.append(scene_id)


## Oublie une scène jouée (outils de test, raccourcis de développement).
func forget_scene(scene_id: StringName) -> void:
	_scenes_done.erase(scene_id)


## Scènes jouées, dans l'ordre (copie).
func scenes_done() -> Array[StringName]:
	return _scenes_done.duplicate()


## Écrit la ligne du jour au calendrier (line : &"" la ligne du jour, sinon une clé de ligne).
func write_calendar(calendar_day: int, line: StringName = &"") -> void:
	if calendar_day >= 1 and calendar_day <= MAX_DAY:
		_calendar[calendar_day] = line


## Vrai si le calendrier porte une ligne pour ce jour.
func has_calendar_line(calendar_day: int) -> bool:
	return _calendar.has(calendar_day)


## Calendrier : jour → clé de ligne (&"" : la ligne du jour), copie.
func calendar() -> Dictionary[int, StringName]:
	return _calendar.duplicate()


# --- Îles (X1) --------------------------------------------------------------------------------


## Îles connues (où le joueur est déjà allé), dans l'ordre de découverte (copie).
func known_islands() -> Array[StringName]:
	return _known_islands.duplicate()


## Vrai si le joueur est déjà allé sur l'île.
func knows_island(island_id: StringName) -> bool:
	return _known_islands.has(island_id)


## Ajoute une île connue ; vrai si elle ne l'était pas (WorldManager, à l'arrivée).
func discover_island(island_id: StringName) -> bool:
	if island_id.is_empty() or knows_island(island_id):
		return false
	_known_islands.append(island_id)
	return true


# --- Inventaire -------------------------------------------------------------------------------


## Ajoute quantity objets (un objet sans data/items/<id>.tres est accepté aussi).
func add_item(item_id: StringName, quantity: int = 1) -> void:
	if quantity <= 0 or item_id.is_empty():
		return
	var current := count(item_id)
	var total := mini(current + quantity, MAX_QUANTITY)
	if total == current:
		return
	_inventory[item_id] = total
	EventBus.inventory_changed.emit()


## Retire quantity objets ; false (et rien ne change) s'il n'y en a pas assez.
func remove_item(item_id: StringName, quantity: int = 1) -> bool:
	if quantity <= 0:
		return false
	var current := count(item_id)
	if current < quantity:
		return false
	if current == quantity:
		_inventory.erase(item_id)
	else:
		_inventory[item_id] = current - quantity
	EventBus.inventory_changed.emit()
	return true


func count(item_id: StringName) -> int:
	return _inventory.get(item_id, 0)


## Copie de l'inventaire (item_id → quantité totale), pour l'interface.
func items() -> Dictionary:
	return _inventory.duplicate()


## Piles de l'inventaire, triées par item_id : une case par pile, selon ItemData.stackable et
## max_stack (valeurs par défaut d'ItemData pour un objet inconnu). Exemple pour 120 fragments :
## [{"item_id": &"page_fragment", "quantity": 99}, {"item_id": &"page_fragment", "quantity": 21}].
func stacks() -> Array[Dictionary]:
	var ids: Array[StringName] = []
	ids.assign(_inventory.keys())
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	var result: Array[Dictionary] = []
	for item_id: StringName in ids:
		var data := ItemData.find(item_id)
		if data == null:
			data = ItemData.new()
		for size: int in data.stack_sizes(_inventory[item_id]):
			result.append({"item_id": item_id, "quantity": size})
	return result


# --- Drapeaux ----------------------------------------------------------------------------------


## Pose (ou retire, value = false) un drapeau ; émet flag_changed si sa valeur change.
func set_flag(flag: StringName, value: bool = true) -> void:
	if flag.is_empty():
		return
	var changed := has_flag(flag) != value
	_flags[flag] = value
	if changed:
		EventBus.flag_changed.emit(flag, value)


func has_flag(flag: StringName) -> bool:
	return _flags.get(flag, false)


# --- Objets ramassés (pickups uniques du monde) -----------------------------------------------


func mark_pickup_collected(pickup_id: StringName) -> void:
	if not pickup_id.is_empty():
		_collected_pickups[pickup_id] = true


func is_pickup_collected(pickup_id: StringName) -> bool:
	return _collected_pickups.has(pickup_id)


# --- Sérialisation (schéma de sauvegarde v4, PLAN.md section 4) --------------------------------


## Champs du schéma de sauvegarde, sauf version et saved_at (ajoutés par SaveManager).
## Types JSON uniquement (String, int, float, bool, Array, Dictionary). Les champs du schéma v1
## gardés d'abord (et, à côté de la position, la carte de la refonte : map) ; puis (E9) moment et
## weather, (X1) island et known_islands, (E4) day et slot, (E6) scenes_done, calendar et
## story_scene, tous facultatifs (absents : le couchant sans pluie, l'île déduite de la carte, pas
## de jour, aucune scène, calendrier vierge, hors scène). (F1) v4 n'a plus zone, quests,
## quest_progress, tracked_quest ni best_scores (l'ancienne île) : from_dict les ignore.
func to_dict() -> Dictionary:
	var inventory := {}
	for item_id: StringName in _inventory:
		inventory[String(item_id)] = _inventory[item_id]
	var flags := {}
	for flag: StringName in _flags:
		flags[String(flag)] = _flags[flag]
	var pickups: Array[String] = []
	for pickup_id: StringName in _collected_pickups:
		pickups.append(String(pickup_id))
	pickups.sort()
	var known: Array[String] = []
	for island_id: StringName in _known_islands:
		known.append(String(island_id))
	var scenes: Array[String] = []
	for scene_id: StringName in _scenes_done:
		scenes.append(String(scene_id))
	var calendar_lines := {}
	for calendar_day: int in _calendar:
		calendar_lines[str(calendar_day)] = String(_calendar[calendar_day])
	return {
		"skin": String(skin_id),
		"max_hp": max_hp,
		"position": [position.x, position.y, position.z],
		"map": String(map),
		"inventory": inventory,
		"flags": flags,
		"collected_pickups": pickups,
		"moment": String(moment),
		"weather": String(weather),
		"island": String(island),
		"known_islands": known,
		"day": day,
		"slot": String(slot),
		"scenes_done": scenes,
		"calendar": calendar_lines,
		"story_scene": String(story_scene),
	}


## Relit un dictionnaire produit par to_dict() (ou un JSON de sauvegarde). Un champ absent ou
## mal typé prend sa valeur par défaut, une entrée invalide est ignorée (quantité nulle ou non
## numérique…), un champ inconnu aussi ; les nombres JSON (float) redeviennent des int. Sans
## position valide, map est vidée : game.gd replace alors le joueur au Spawn de la carte de
## départ.
func from_dict(data: Dictionary) -> void:
	skin_id = _read_name(data.get("skin"))
	var hp: Variant = data.get("max_hp")
	max_hp = int(hp) if _is_number(hp) and int(hp) >= 1 else DEFAULT_MAX_HP
	var saved_position: Variant = _read_vector3(data.get("position"))
	position = saved_position if saved_position is Vector3 else Vector3.ZERO
	map = _read_name(data.get("map")) if saved_position is Vector3 else &""
	_inventory.clear()
	var inventory := _as_dict(data.get("inventory"))
	for key: Variant in inventory:
		var item_id := _read_name(key)
		var quantity := _read_count(inventory[key])
		if not item_id.is_empty() and quantity > 0:
			_inventory[item_id] = mini(quantity, MAX_QUANTITY)
	_flags.clear()
	var flags := _as_dict(data.get("flags"))
	for key: Variant in flags:
		var flag := _read_name(key)
		var value: Variant = flags[key]
		if not flag.is_empty() and (value is bool or _is_number(value)):
			_flags[flag] = bool(value)
	_collected_pickups.clear()
	var pickups: Variant = data.get("collected_pickups")
	if pickups is Array:
		for pickup_id: Variant in pickups:
			mark_pickup_collected(_read_name(pickup_id))
	# (E9) Absents (sauvegarde d'avant E9) ou inconnus : le couchant sans pluie.
	var saved_moment := _read_name(data.get("moment"))
	moment = saved_moment if saved_moment in MOMENTS else DEFAULT_MOMENT
	var saved_weather := _read_name(data.get("weather"))
	weather = saved_weather if saved_weather in WEATHERS else DEFAULT_WEATHER
	# (X1) Absents (sauvegarde d'avant X1) : vides ; WorldManager les remplit à l'arrivée.
	island = _read_name(data.get("island")) if saved_position is Vector3 else &""
	_known_islands.clear()
	var known: Variant = data.get("known_islands")
	if known is Array:
		for island_id: Variant in known:
			discover_island(_read_name(island_id))
	# (E4) Absents ou invalides : pas de jour, le créneau du moment.
	day = _read_count(data.get("day"))
	var saved_slot := _read_name(data.get("slot"))
	slot = saved_slot if saved_slot in SLOTS else &""
	# (E6) Absents ou invalides : aucune scène, calendrier vierge, hors scène.
	_scenes_done.clear()
	var scenes: Variant = data.get("scenes_done")
	if scenes is Array:
		for scene_id: Variant in scenes:
			mark_scene_done(_read_name(scene_id))
	_calendar.clear()
	var calendar_lines := _as_dict(data.get("calendar"))
	for key: Variant in calendar_lines:
		var calendar_day := str(key).to_int() if str(key).is_valid_int() else 0
		var line: Variant = calendar_lines[key]
		if line is String:
			write_calendar(calendar_day, StringName(line))
	story_scene = _read_name(data.get("story_scene"))
	EventBus.inventory_changed.emit()


static func _as_dict(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}


## int, ou float fini (les nombres d'un JSON).
static func _is_number(value: Variant) -> bool:
	return value is int or (value is float and is_finite(value))


## String ou StringName → StringName ; tout autre type → &"".
static func _read_name(value: Variant) -> StringName:
	return StringName(value) if value is String or value is StringName else &""


## Nombre positif ou nul ; 0 si la valeur n'est pas un nombre.
static func _read_count(value: Variant) -> int:
	return maxi(int(value), 0) if _is_number(value) else 0


## [x, y, z] (trois nombres d'au plus MAX_COORDINATE en valeur absolue) → Vector3 ; null sinon.
static func _read_vector3(value: Variant) -> Variant:
	if not value is Array or (value as Array).size() != 3:
		return null
	for component: Variant in value:
		if not _is_number(component) or absf(float(component)) > MAX_COORDINATE:
			return null
	var p: Array = value
	return Vector3(float(p[0]), float(p[1]), float(p[2]))
