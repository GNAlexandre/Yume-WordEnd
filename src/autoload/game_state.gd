extends Node
## GameState : état de la partie, sérialisable (PLAN.md sections 3 et 4). Propriétaire : L7.
##
## Inventaire (total par objet ; les piles sont déduites des ItemData, voir stacks()), drapeaux,
## quêtes (état, étape courante et compteur, quête suivie), objets uniques ramassés, meilleurs
## scores par arène, PV max et skin.
## Signaux émis (via EventBus) :
## - inventory_changed à chaque add_item / remove_item réussi, from_dict et reset ;
## - quest_updated dans set_quest_state (si l'état change ; jamais dans from_dict, sinon
##   QuestTracker redonnerait la récompense d'une quête finie à chaque chargement) ;
## - (Lot Q) flag_changed dans set_flag, quest_step_updated dans set_quest_step (si quelque
##   chose change ; jamais dans from_dict ni reset), tracked_quest_changed quand tracked_quest
##   change ;
## - skin_changed et max_hp_changed quand skin_id / max_hp changent.
## - (E9) atmosphere_changed quand moment ou weather changent (setters, from_dict et reset
##   compris) : Atmosphere pose alors la lumière.
## (X1) island (île courante) et les îles connues sont tenues par WorldManager à chaque arrivée
## sur une île (EventBus.island_entered) ; sauvegardées (champs facultatifs du schéma v3).
## Mises à jour attendues des autres lots : (E1) map par WorldManager à chaque changement de
## carte, zone par WorldManager (L2) à chaque zone_entered,
## position par le joueur (L1) quand il est au sol, étapes et quête suivie par le QuestTracker
## (Lot Q). SaveManager (L8) ajoute version et saved_at.

## PV max d'une nouvelle partie (règle de l'easter egg ; la quête des pages le porte à 6).
const DEFAULT_MAX_HP := 5
## États de quête du contrat.
const QUEST_AVAILABLE := &"available"
const QUEST_ACTIVE := &"active"
const QUEST_DONE := &"done"
## États reconnus par from_dict (les autres valeurs d'une sauvegarde sont ignorées).
const QUEST_STATES: Array[StringName] = [QUEST_AVAILABLE, QUEST_ACTIVE, QUEST_DONE]
## Plafonds de sécurité (sauvegarde trafiquée, boucle de ramassage…) : total d'un objet, PV max,
## coordonnée d'une position (m ; l'île fait 160 m de côté).
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

## Skin actif (SkinData.id) ; &"" = skin par défaut de SkinRegistry.
var skin_id: StringName = &"":
	set(value):
		if value == skin_id:
			return
		skin_id = value
		EventBus.skin_changed.emit(value)

## PV max du joueur (5, puis 6 avec la promesse de l'acte 1, 7 avec le registre des veilles),
## entre 1 et MAX_HP_LIMIT.
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
## Zone courante dans la carte (zone_id, zones de l'ancienne île) ; &"" hors des zones.
var zone: StringName = &""
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
## (Lot Q) Quête suivie, affichée par le HUD ; &"" = aucune (le HUD montre alors la première
## quête active). Tenue par le QuestTracker (une quête qui démarre devient la quête suivie) et
## par le journal (choix du joueur) ; émet tracked_quest_changed.
var tracked_quest: StringName = &"":
	set(value):
		if value == tracked_quest:
			return
		tracked_quest = value
		EventBus.tracked_quest_changed.emit(value)

var _inventory: Dictionary[StringName, int] = {}
var _flags: Dictionary[StringName, bool] = {}
var _quests: Dictionary[StringName, StringName] = {}
## (Lot Q) Quêtes actives : quest_id → {"step": StringName, "count": int}.
var _quest_progress: Dictionary[StringName, Dictionary] = {}
var _collected_pickups: Dictionary[StringName, bool] = {}
var _best_scores: Dictionary[StringName, Dictionary] = {}
## (X1) Îles où le joueur est déjà allé, dans l'ordre de découverte.
var _known_islands: Array[StringName] = []


## Nouvelle partie : tout revient aux valeurs par défaut.
func reset() -> void:
	skin_id = &""
	max_hp = DEFAULT_MAX_HP
	map = &""
	island = &""
	zone = &""
	position = Vector3.ZERO
	moment = DEFAULT_MOMENT
	weather = DEFAULT_WEATHER
	day = 0
	slot = &""
	tracked_quest = &""
	_inventory.clear()
	_flags.clear()
	_quests.clear()
	_quest_progress.clear()
	_collected_pickups.clear()
	_best_scores.clear()
	_known_islands.clear()
	EventBus.inventory_changed.emit()


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


# --- Drapeaux et quêtes -----------------------------------------------------------------------


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


## État d'une quête : &"available", &"active", &"done", ou &"" si inconnue.
func quest_state(quest_id: StringName) -> StringName:
	return _quests.get(quest_id, &"")


## Change l'état d'une quête et émet quest_updated s'il change (&"" l'oublie).
func set_quest_state(quest_id: StringName, state: StringName) -> void:
	if quest_id.is_empty() or quest_state(quest_id) == state:
		return
	if state.is_empty():
		_quests.erase(quest_id)
	else:
		_quests[quest_id] = state
	EventBus.quest_updated.emit(quest_id, state)


## Copie des états de quête (quest_id → état), ex. pour afficher les objectifs au chargement.
## L'ordre est celui où chaque quête a reçu son premier état (journal).
func quests() -> Dictionary:
	return _quests.duplicate()


## (Lot Q) Étape courante d'une quête (QuestStep.id), &"" si aucune n'est enregistrée.
func quest_step(quest_id: StringName) -> StringName:
	var entry: Dictionary = _quest_progress.get(quest_id, {})
	return StringName(entry.get("step", &""))


## (Lot Q) Compteur de l'étape courante (ennemis vaincus, vague ou score atteints), 0 sinon.
func quest_step_count(quest_id: StringName) -> int:
	var entry: Dictionary = _quest_progress.get(quest_id, {})
	return int(entry.get("count", 0))


## (Lot Q) Enregistre l'étape courante d'une quête et son compteur (step_id &"" efface) ; émet
## quest_step_updated si quelque chose change. Appelé par le QuestTracker.
func set_quest_step(quest_id: StringName, step_id: StringName, step_count: int = 0) -> void:
	if quest_id.is_empty():
		return
	var known := _quest_progress.has(quest_id)
	var value := maxi(step_count, 0)
	if step_id.is_empty():
		if not known:
			return
		_quest_progress.erase(quest_id)
		value = 0
	else:
		if known and quest_step(quest_id) == step_id and quest_step_count(quest_id) == value:
			return
		_quest_progress[quest_id] = {"step": step_id, "count": value}
	EventBus.quest_step_updated.emit(quest_id, step_id, value)


## (Lot Q) Copie de l'avancement des quêtes : quest_id → {"step": StringName, "count": int}.
func quest_progress() -> Dictionary:
	return _quest_progress.duplicate(true)


# --- Objets ramassés (pickups uniques du monde) -----------------------------------------------


func mark_pickup_collected(pickup_id: StringName) -> void:
	if not pickup_id.is_empty():
		_collected_pickups[pickup_id] = true


func is_pickup_collected(pickup_id: StringName) -> bool:
	return _collected_pickups.has(pickup_id)


# --- Scores d'arène ---------------------------------------------------------------------------


## Enregistre une partie de l'arène : une partie de plus ; si score bat strictement le meilleur
## (comme jeu.js), il devient le record avec la vague atteinte pendant cette partie. true si record.
func record_score(arena_id: StringName, score: int, wave: int) -> bool:
	if arena_id.is_empty():
		return false
	var entry := arena_record(arena_id)
	entry["games"] = int(entry["games"]) + 1
	var best: bool = score > int(entry["score"])
	if best:
		entry["score"] = score
		entry["wave"] = maxi(wave, 0)
	_best_scores[arena_id] = entry
	return best


func best_score(arena_id: StringName) -> int:
	return int(arena_record(arena_id)["score"])


## Record de l'arène (copie) : {"score": meilleur score, "wave": vague de cette partie,
## "games": nombre de parties} ; des zéros si l'arène n'a jamais été jouée.
func arena_record(arena_id: StringName) -> Dictionary:
	var entry: Dictionary = _best_scores.get(arena_id, {})
	return {
		"score": int(entry.get("score", 0)),
		"wave": int(entry.get("wave", 0)),
		"games": int(entry.get("games", 0)),
	}


# --- Sérialisation (schéma de sauvegarde v2, PLAN.md section 4) --------------------------------


## Champs du schéma de sauvegarde, sauf version et saved_at (ajoutés par SaveManager).
## Types JSON uniquement (String, int, float, bool, Array, Dictionary). Les champs du schéma v1
## d'abord (et, à côté de la position, la carte de la refonte : map, v3), puis ceux du Lot Q
## (v2) : quest_progress et tracked_quest ; enfin (E9) moment et weather, facultatifs dans le
## schéma v3 (absents d'une sauvegarde plus ancienne : le couchant sans pluie), (X1) island
## et known_islands, facultatifs aussi (absents : WorldManager les déduit de la carte), et (E4)
## day et slot, facultatifs aussi (absents : 0 et "").
func to_dict() -> Dictionary:
	var inventory := {}
	for item_id: StringName in _inventory:
		inventory[String(item_id)] = _inventory[item_id]
	var flags := {}
	for flag: StringName in _flags:
		flags[String(flag)] = _flags[flag]
	var quests_dict := {}
	for quest_id: StringName in _quests:
		quests_dict[String(quest_id)] = String(_quests[quest_id])
	var pickups: Array[String] = []
	for pickup_id: StringName in _collected_pickups:
		pickups.append(String(pickup_id))
	pickups.sort()
	var scores := {}
	for arena_id: StringName in _best_scores:
		scores[String(arena_id)] = arena_record(arena_id)
	var known: Array[String] = []
	for island_id: StringName in _known_islands:
		known.append(String(island_id))
	var progress := {}
	for quest_id: StringName in _quest_progress:
		progress[String(quest_id)] = {
			"step": String(quest_step(quest_id)), "count": quest_step_count(quest_id)
		}
	return {
		"skin": String(skin_id),
		"max_hp": max_hp,
		"position": [position.x, position.y, position.z],
		"map": String(map),
		"zone": String(zone),
		"inventory": inventory,
		"flags": flags,
		"quests": quests_dict,
		"collected_pickups": pickups,
		"best_scores": scores,
		"quest_progress": progress,
		"tracked_quest": String(tracked_quest),
		"moment": String(moment),
		"weather": String(weather),
		"island": String(island),
		"known_islands": known,
		"day": day,
		"slot": String(slot),
	}


## Relit un dictionnaire produit par to_dict() (ou un JSON de sauvegarde). Un champ absent ou
## mal typé prend sa valeur par défaut, une entrée invalide est ignorée (quantité nulle ou non
## numérique, état de quête inconnu, avancement d'une quête qui n'est pas active…) ; les nombres
## JSON (float) redeviennent des int. Sans position valide, map et zone sont vidées : game.gd
## replace alors le joueur au Spawn de la carte de départ (l'entrepôt de l'ancienne île). Aucun
## signal de quête (quest_updated, quest_step_updated) : le QuestTracker relit tout sur
## game_loaded.
func from_dict(data: Dictionary) -> void:
	skin_id = _read_name(data.get("skin"))
	var hp: Variant = data.get("max_hp")
	max_hp = int(hp) if _is_number(hp) and int(hp) >= 1 else DEFAULT_MAX_HP
	var saved_position: Variant = _read_vector3(data.get("position"))
	position = saved_position if saved_position is Vector3 else Vector3.ZERO
	map = _read_name(data.get("map")) if saved_position is Vector3 else &""
	zone = _read_name(data.get("zone")) if saved_position is Vector3 else &""
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
	_quests.clear()
	var quests_dict := _as_dict(data.get("quests"))
	for key: Variant in quests_dict:
		var quest_id := _read_name(key)
		var state := _read_name(quests_dict[key])
		if not quest_id.is_empty() and state in QUEST_STATES:
			_quests[quest_id] = state
	_collected_pickups.clear()
	var pickups: Variant = data.get("collected_pickups")
	if pickups is Array:
		for pickup_id: Variant in pickups:
			mark_pickup_collected(_read_name(pickup_id))
	_best_scores.clear()
	var scores := _as_dict(data.get("best_scores"))
	for key: Variant in scores:
		var arena_id := _read_name(key)
		var entry := _as_dict(scores[key])
		if not arena_id.is_empty():
			_best_scores[arena_id] = {
				"score": _read_count(entry.get("score")),
				"wave": _read_count(entry.get("wave")),
				"games": _read_count(entry.get("games")),
			}
	_quest_progress.clear()
	var progress := _as_dict(data.get("quest_progress"))
	for key: Variant in progress:
		var quest_id := _read_name(key)
		var entry := _as_dict(progress[key])
		var step_id := _read_name(entry.get("step"))
		if step_id.is_empty() or quest_state(quest_id) != QUEST_ACTIVE:
			continue
		_quest_progress[quest_id] = {"step": step_id, "count": _read_count(entry.get("count"))}
	tracked_quest = _read_name(data.get("tracked_quest"))
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
