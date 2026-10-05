extends Node3D
## Scène de jeu (src/game.tscn) : Island, Player, QuestTracker et l'interface (UI).
##
## Fichier d'intégration du Lot 0 : quand chaque lot remplit ses scènes, le jeu est câblé
## sans retouche ici. Au démarrage, place le joueur : nouvelle partie (GameState.zone vide) →
## Spawn du village ; partie chargée → GameState.position dans GameState.zone.

@onready var player: Node3D = $Player


func _ready() -> void:
	if GameState.zone.is_empty():
		WorldManager.teleport(WorldManager.VILLAGE, WorldManager.SPAWN_MARKER)
	else:
		WorldManager.load_zone(GameState.zone)
		player.global_position = GameState.position
