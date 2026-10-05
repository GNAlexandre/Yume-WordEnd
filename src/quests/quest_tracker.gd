class_name QuestTracker
extends Node
## Suivi des quêtes (data/quests/*.tres) : complétion et récompenses (PLAN.md section 4).
## Propriétaire : L7. Un seul, nœud « QuestTracker » de src/game.tscn (seul le premier nœud du
## groupe quest_tracker agit, pour qu'une récompense ne soit jamais donnée deux fois).
##
## Contrat avec les dialogues (L6) : le DialogueRunner appelle
## GameState.set_quest_state(id, &"active") (start_quest) puis &"done" (complete_quest).
## Le QuestTracker écoute EventBus.quest_updated et, à &"done" :
## - s'il manque des objets (count < required) ou des drapeaux requis, il remet la quête à
##   &"active" et le signale (completion_refused et un avertissement) ;
## - sinon il retire required_items, donne reward_items, porte GameState.max_hp à
##   reward_max_hp (6 avec le marque-page des pages) puis émet quest_completed.
## Tout se passe pendant l'émission de quest_updated : un écouteur branché après lui qui reçoit
## &"done" pour une quête refusée doit relire GameState.quest_state().

## Quête terminée, récompense donnée.
signal quest_completed(quest_id: StringName)
## Complétion refusée (quête remise à &"active") ; missing_items : item_id → quantité manquante.
signal completion_refused(quest_id: StringName, missing_items: Dictionary)

const QUESTS_DIR := QuestData.DATA_DIR
const GROUP := &"quest_tracker"


func _enter_tree() -> void:
	add_to_group(GROUP)
	EventBus.quest_updated.connect(_on_quest_updated)


func _exit_tree() -> void:
	EventBus.quest_updated.disconnect(_on_quest_updated)


## Objets qui manquent pour terminer quest : item_id → quantité manquante (vide si rien).
static func missing_items(quest: QuestData) -> Dictionary:
	var missing := {}
	for item_id: StringName in quest.required_items:
		var lacking := quest.required_items[item_id] - GameState.count(item_id)
		if lacking > 0:
			missing[item_id] = lacking
	return missing


## Drapeaux requis par quest que GameState n'a pas.
static func missing_flags(quest: QuestData) -> Array[StringName]:
	var missing: Array[StringName] = []
	for flag: StringName in quest.required_flags:
		if not GameState.has_flag(flag):
			missing.append(flag)
	return missing


## true si GameState a tout ce que demande quest (objets en quantité suffisante, drapeaux).
static func can_complete(quest: QuestData) -> bool:
	return missing_items(quest).is_empty() and missing_flags(quest).is_empty()


func _on_quest_updated(quest_id: StringName, state: StringName) -> void:
	if state != GameState.QUEST_DONE or get_tree().get_first_node_in_group(GROUP) != self:
		return
	var quest := QuestData.find(quest_id)
	if quest == null:
		return
	if not can_complete(quest):
		var missing := missing_items(quest)
		var details := "%s %s" % [missing, missing_flags(quest)]
		push_warning("QuestTracker : %s n'est pas terminée (manque %s)" % [quest_id, details])
		GameState.set_quest_state(quest_id, GameState.QUEST_ACTIVE)
		completion_refused.emit(quest_id, missing)
		return
	for item_id: StringName in quest.required_items:
		GameState.remove_item(item_id, quest.required_items[item_id])
	for item_id: StringName in quest.reward_items:
		GameState.add_item(item_id, quest.reward_items[item_id])
	if quest.reward_max_hp > GameState.max_hp:
		GameState.max_hp = quest.reward_max_hp
	quest_completed.emit(quest_id)
