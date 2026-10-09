extends Node3D
## Scène de jeu (src/game.tscn) : World (la carte courante), Player, QuestTracker et l'interface
## (UI, dont UI/MapFade, le fondu des changements de carte).
##
## Fichier d'intégration (Lot 0, puis E1 : cartes) : quand chaque lot remplit ses scènes, le jeu
## est câblé sans retouche ici. Au démarrage, pose la carte et le joueur
## (WorldManager.enter_map) : nouvelle partie (GameState.map vide) → Spawn de
## WorldManager.START_MAP (celui du village de l'ancienne île) ; partie chargée →
## GameState.position dans GameState.map (une carte qui n'existe plus ramène au Spawn de
## START_MAP). main.gd a déjà chargé la carte avec l'écran de chargement : elle sort du cache.
## Raccourcis de test (intégration M1) : si l'adresse de la page (Web) ou la ligne de commande
## en donne (?zone=dunes, --timeres=12…), un nœud src/test_shortcuts.gd les applique ensuite ;
## sans paramètre, rien ne change.

const TestShortcuts := preload("res://src/test_shortcuts.gd")

@onready var player: Node3D = $Player


func _ready() -> void:
	var map_id := WorldManager.starting_map()
	if map_id == GameState.map and not GameState.map.is_empty():
		WorldManager.enter_map(map_id, WorldManager.SPAWN_MARKER, GameState.position)
	else:
		if not GameState.map.is_empty():
			push_warning("Partie : carte %s inconnue, retour à %s" % [GameState.map, map_id])
		WorldManager.enter_map(map_id)
	var parameters := TestShortcuts.read_parameters()
	if not parameters.is_empty():
		var shortcuts := TestShortcuts.new()
		shortcuts.name = "TestShortcuts"
		shortcuts.parameters = parameters
		add_child(shortcuts)
