extends Node
## GameState : état de la partie, sérialisable (PLAN.md sections 3 et 4). Propriétaire : L7.
##
## Implémentation minimale du Lot 0 : dictionnaires en mémoire, API complète du contrat.
## Signaux émis (via EventBus) :
## - inventory_changed à chaque add_item / remove_item réussi, from_dict et reset ;
## - quest_updated dans set_quest_state (si l'état change) ;
## - skin_changed et max_hp_changed quand skin_id / max_hp changent.
## Mises à jour attendues des autres lots : zone par WorldManager (L2) à chaque zone_entered,
## position par le joueur (L1) quand il est au sol. SaveManager (L8) ajoute version et saved_at.

## PV max d'une nouvelle partie (règle de l'easter egg ; la quête des pages le porte à 6).
const DEFAULT_MAX_HP := 5
## États de quête du contrat.
const QUEST_AVAILABLE := &"available"
const QUEST_ACTIVE := &"active"
const QUEST_DONE := &"done"

## Skin actif (SkinData.id) ; &"" = skin par défaut de SkinRegistry.
var skin_id: StringName = &"":
	set(value):
		if value == skin_id:
			return
		skin_id = value
		EventBus.skin_changed.emit(value)

## PV max du joueur (5, puis 6 avec le marque-page de la quête).
var max_hp: int = DEFAULT_MAX_HP:
	set(value):
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


func add_item(item_id: StringName, quantity: int = 1) -> void:
	if quantity <= 0 or item_id.is_empty():
		return
	_inventory[item_id] = count(item_id) + quantity
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


## Copie de l'inventaire (item_id → quantité), pour l'interface.
func items() -> Dictionary:
	return _inventory.duplicate()


# --- Drapeaux et quêtes -----------------------------------------------------------------------


func set_flag(flag: StringName, value: bool = true) -> void:
	_flags[flag] = value


func has_flag(flag: StringName) -> bool:
	return _flags.get(flag, false)


## État d'une quête : &"available", &"active", &"done", ou &"" si inconnue.
func quest_state(quest_id: StringName) -> StringName:
	return _quests.get(quest_id, &"")


func set_quest_state(quest_id: StringName, state: StringName) -> void:
	if quest_state(quest_id) == state:
		return
	_quests[quest_id] = state
	EventBus.quest_updated.emit(quest_id, state)


# --- Objets ramassés (pickups uniques du monde) -----------------------------------------------


func mark_pickup_collected(pickup_id: StringName) -> void:
	_collected_pickups[pickup_id] = true


func is_pickup_collected(pickup_id: StringName) -> bool:
	return _collected_pickups.has(pickup_id)


# --- Scores d'arène ---------------------------------------------------------------------------


## Enregistre une partie de l'arène ; true si score bat strictement le meilleur (comme jeu.js).
func record_score(arena_id: StringName, score: int, wave: int) -> bool:
	var entry: Dictionary = _best_scores.get(arena_id, {"score": 0, "wave": 0, "games": 0})
	entry["games"] = int(entry["games"]) + 1
	var best: bool = score > int(entry["score"])
	if best:
		entry["score"] = score
		entry["wave"] = wave
	_best_scores[arena_id] = entry
	return best


func best_score(arena_id: StringName) -> int:
	return int(_best_scores.get(arena_id, {}).get("score", 0))


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
	var quests := {}
	for quest_id: StringName in _quests:
		quests[String(quest_id)] = String(_quests[quest_id])
	var pickups: Array[String] = []
	for pickup_id: StringName in _collected_pickups:
		pickups.append(String(pickup_id))
	pickups.sort()
	var scores := {}
	for arena_id: StringName in _best_scores:
		var entry: Dictionary = _best_scores[arena_id]
		scores[String(arena_id)] = {
			"score": int(entry.get("score", 0)),
			"wave": int(entry.get("wave", 0)),
			"games": int(entry.get("games", 0)),
		}
	return {
		"skin": String(skin_id),
		"max_hp": max_hp,
		"position": [position.x, position.y, position.z],
		"zone": String(zone),
		"inventory": inventory,
		"flags": flags,
		"quests": quests,
		"collected_pickups": pickups,
		"best_scores": scores,
	}


## Relit un dictionnaire produit par to_dict() (ou un JSON de sauvegarde) ; les champs absents
## prennent leur valeur par défaut, les nombres JSON (float) sont reconvertis en int.
func from_dict(data: Dictionary) -> void:
	skin_id = StringName(str(data.get("skin", "")))
	max_hp = int(data.get("max_hp", DEFAULT_MAX_HP))
	zone = StringName(str(data.get("zone", "")))
	position = Vector3.ZERO
	var pos: Variant = data.get("position", [])
	if pos is Array and (pos as Array).size() == 3:
		var p: Array = pos
		position = Vector3(float(p[0]), float(p[1]), float(p[2]))
	_inventory.clear()
	var inventory := _as_dict(data.get("inventory"))
	for key: Variant in inventory:
		var quantity := int(inventory[key])
		if quantity > 0:
			_inventory[StringName(str(key))] = quantity
	_flags.clear()
	var flags := _as_dict(data.get("flags"))
	for key: Variant in flags:
		_flags[StringName(str(key))] = bool(flags[key])
	_quests.clear()
	var quests := _as_dict(data.get("quests"))
	for key: Variant in quests:
		_quests[StringName(str(key))] = StringName(str(quests[key]))
	_collected_pickups.clear()
	var pickups: Variant = data.get("collected_pickups", [])
	if pickups is Array:
		for pickup_id: Variant in pickups:
			_collected_pickups[StringName(str(pickup_id))] = true
	_best_scores.clear()
	var scores := _as_dict(data.get("best_scores"))
	for key: Variant in scores:
		var entry := _as_dict(scores[key])
		_best_scores[StringName(str(key))] = {
			"score": int(entry.get("score", 0)),
			"wave": int(entry.get("wave", 0)),
			"games": int(entry.get("games", 0)),
		}
	EventBus.inventory_changed.emit()


func _as_dict(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}
