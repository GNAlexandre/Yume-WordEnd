class_name QuestData
extends Resource
## Quête. Fichiers : data/quests/<id>.tres. Propriétaire : L7.
## États (GameState.quest_state) : &"" inconnue, &"available", &"active", &"done".

## Identifiant, ex. &"pages".
@export var id: StringName
## Titre / objectif affiché par le HUD.
@export var title: String = ""
## PNJ qui la donne (NpcData.id).
@export var giver_npc: StringName
## Objets à rapporter : item_id → quantité (retirés de l'inventaire à la complétion).
@export var required_items: Dictionary[StringName, int] = {}
## Drapeaux de GameState requis.
@export var required_flags: Array[StringName] = []
## Récompense : item_id → quantité.
@export var reward_items: Dictionary[StringName, int] = {}
