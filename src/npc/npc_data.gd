class_name NpcData
extends Resource
## Personnage non joueur. Fichiers : data/npcs/<id>.tres. Propriétaire : L6.

## Identifiant, ex. &"librarian" (transmis par EventBus.dialogue_started / dialogue_ended).
@export var id: StringName
## Nom affiché (locuteur par défaut).
@export var display_name: String = ""
## Apparence (un skin de data/skins/, partagé avec les skins jouables).
@export var skin: SkinData
## Dialogue au format JSON de PLAN.md section 4 (data/dialogues/<id>.json).
@export_file("*.json") var dialogue_path: String = ""
## Quête donnée par ce PNJ (data/quests/<id>.tres), &"" si aucune.
@export var quest_id: StringName
## Zone où il vit (zone_id).
@export var home_zone: StringName = &"village"
