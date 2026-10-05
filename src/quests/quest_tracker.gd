class_name QuestTracker
extends Node
## Suivi des quêtes (data/quests/*.tres) : objectifs, complétion, récompenses (PLAN.md
## section 4). Propriétaire : L7. Un seul, nœud « QuestTracker » de src/game.tscn.
##
## Contrat avec les dialogues (L6) : le DialogueRunner appelle
## GameState.set_quest_state(id, &"active") (start_quest) puis &"done" (complete_quest) ;
## le QuestTracker écoute EventBus.quest_updated et, à &"done", retire required_items et
## donne reward_items (et applique les effets, ex. GameState.max_hp = 6 pour le marque-page).
## Squelette du Lot 0 : vide.

const QUESTS_DIR := "res://data/quests"
