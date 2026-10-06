extends Node3D
## Scène de jeu (src/game.tscn) : Island, Player, QuestTracker et l'interface (UI).
##
## Fichier d'intégration du Lot 0 : quand chaque lot remplit ses scènes, le jeu est câblé
## sans retouche ici. Au démarrage, place le joueur : nouvelle partie (GameState.zone vide) →
## Spawn du village ; partie chargée → GameState.position dans GameState.zone.
## Raccourcis de test (intégration M1) : si l'adresse de la page (Web) ou la ligne de commande
## en donne (?zone=dunes, --timeres=12…), un nœud src/test_shortcuts.gd les applique ensuite ;
## sans paramètre, rien ne change.

const TestShortcuts := preload("res://src/test_shortcuts.gd")

@onready var player: Node3D = $Player


func _ready() -> void:
	if GameState.zone.is_empty():
		WorldManager.teleport(WorldManager.VILLAGE, WorldManager.SPAWN_MARKER)
	else:
		WorldManager.load_zone(GameState.zone)
		player.global_position = GameState.position
	var parameters := TestShortcuts.read_parameters()
	if not parameters.is_empty():
		var shortcuts := TestShortcuts.new()
		shortcuts.name = "TestShortcuts"
		shortcuts.parameters = parameters
		add_child(shortcuts)
