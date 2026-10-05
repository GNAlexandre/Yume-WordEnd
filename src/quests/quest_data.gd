class_name QuestData
extends Resource
## Quête. Fichiers : data/quests/<id>.tres (le nom du fichier est l'id). Propriétaire : L7.
## États (GameState.quest_state) : &"" inconnue, &"available", &"active", &"done".
## Le HUD (L10) affiche title / objective des quêtes actives (EventBus.quest_updated, puis
## QuestData.find(id)) ; QuestTracker applique retraits et récompenses à &"done".

## Dossier des données de quêtes.
const DATA_DIR := "res://data/quests"

## Identifiant, ex. &"pages".
@export var id: StringName
## Titre affiché par le HUD, ex. « Les pages envolées ».
@export var title: String = ""
## Objectif affiché par le HUD, ex. « Rapporter 5 fragments de page à la bibliothécaire ».
@export_multiline var objective: String = ""
## PNJ qui la donne (NpcData.id).
@export var giver_npc: StringName
## Objets à rapporter : item_id → quantité (retirés de l'inventaire à la complétion).
@export var required_items: Dictionary[StringName, int] = {}
## Drapeaux de GameState requis.
@export var required_flags: Array[StringName] = []
## Récompense : item_id → quantité.
@export var reward_items: Dictionary[StringName, int] = {}
## PV max portés à cette valeur à la complétion (s'ils sont plus bas) ; 0 = aucun effet.
@export var reward_max_hp: int = 0


## Données de la quête quest_id (data/quests/<id>.tres), null si elle est inconnue.
static func find(quest_id: StringName) -> QuestData:
	if not String(quest_id).is_valid_identifier():
		return null
	var path := "%s/%s.tres" % [DATA_DIR, quest_id]
	if not ResourceLoader.exists(path):
		return null
	return load(path) as QuestData
