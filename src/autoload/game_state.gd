extends Node
## GameState : état de la partie, sérialisable (PLAN.md sections 3 et 4). Propriétaire : L7.
##
## Inventaire (total par objet ; les piles sont déduites des ItemData, voir stacks()), drapeaux,
## quêtes, objets uniques ramassés, meilleurs scores par arène, PV max et skin.
## Signaux émis (via EventBus) :
## - inventory_changed à chaque add_item / remove_item réussi, from_dict et reset ;
## - quest_updated dans set_quest_state (si l'état change ; jamais dans from_dict, sinon
##   QuestTracker redonnerait la récompense d'une quête finie à chaque chargement) ;
## - skin_changed et max_hp_changed quand skin_id / max_hp changent.
## Mises à jour attendues des autres lots : zone par WorldManager (L2) à chaque zone_entered,
## position par le joueur (L1) quand il est au sol. SaveManager (L8) ajoute version et saved_at.

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

## Skin actif (SkinData.id) ; &"" = skin par défaut de SkinRegistry.
var skin_id: StringName = &"":
	set(value):
		if value == skin_id:
			return
		skin_id = value
		EventBus.skin_changed.emit(value)

## PV max du joueur (5, puis 6 avec le marque-page de la quête), entre 1 et MAX_HP_LIMIT.
var max_hp: int = DEFAULT_MAX_HP:
	set(value):
		value = clampi(value, 1, MAX_HP_LIMIT)
		if value == max_hp:
			return
		max_hp = value
		EventBus.max_hp_changed.emit(value)

## Zone courante (zone_id) ; &"" = nouvelle partie pas encore placée (game.gd téléporte alors
## le joueur au Spawn du village).
var zone: StringName = &""
## Dernière position au sol du joueur (sauvegardée, restaurée par game.gd).
var position: Vector3 = Vector3.ZERO

var _inventory: Dictionary[StringName, int] = {}
var _flags: Dictionary[StringName, bool] = {}
var _quests: Dictionary[StringName, StringName] = {}
var _collected_pickups: Dictionary[StringName, bool] = {}
var _best_scores: Dictionary[StringName, Dictionary] = {}


## Nouvelle partie : tout revient aux valeurs par défaut.
func reset() -> void:
	skin_id = &""
	max_hp = DEFAULT_MAX_HP
	zone = &""
	position = Vector3.ZERO
	_inventory.clear()
	_flags.clear()
	_quests.clear()
	_collected_pickups.clear()
	_best_scores.clear()
	EventBus.inventory_changed.emit()


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


func set_flag(flag: StringName, value: bool = true) -> void:
	if not flag.is_empty():
		_flags[flag] = value


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
func quests() -> Dictionary:
	return _quests.duplicate()


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


# --- Sérialisation (schéma de sauvegarde v1, PLAN.md section 4) --------------------------------


## Champs du schéma de sauvegarde, sauf version et saved_at (ajoutés par SaveManager).
## Types JSON uniquement (String, int, float, bool, Array, Dictionary).
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
	return {
		"skin": String(skin_id),
		"max_hp": max_hp,
		"position": [position.x, position.y, position.z],
		"zone": String(zone),
		"inventory": inventory,
		"flags": flags,
		"quests": quests_dict,
		"collected_pickups": pickups,
		"best_scores": scores,
	}


## Relit un dictionnaire produit par to_dict() (ou un JSON de sauvegarde). Un champ absent ou
## mal typé prend sa valeur par défaut, une entrée invalide est ignorée (quantité nulle ou non
## numérique, état de quête inconnu…) ; les nombres JSON (float) redeviennent des int.
## Sans position valide, zone est vidée : game.gd replace alors le joueur au Spawn du village.
func from_dict(data: Dictionary) -> void:
	skin_id = _read_name(data.get("skin"))
	var hp: Variant = data.get("max_hp")
	max_hp = int(hp) if _is_number(hp) and int(hp) >= 1 else DEFAULT_MAX_HP
	var saved_position: Variant = _read_vector3(data.get("position"))
	position = saved_position if saved_position is Vector3 else Vector3.ZERO
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
