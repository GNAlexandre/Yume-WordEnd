class_name AirshipDock
extends Area3D
## Quai d'embarquement (lot X1) : on y prend le dirigeable vers une autre île
## (WorldManager.travel). Un interactable comme une sortie à invite (MapExit) : couche 6
## (interactable), masque 2 (player), groupe « interactable », posés par son _ready ; une
## CollisionShape3D enfant couvre l'endroit où l'on se tient pour embarquer.
##
## Il se pose dans la carte d'un port (data/world/islands/<île>.json, « ports »), à côté du
## marqueur d'arrivée du port (`from_dirigeable`), sous un nœud « Docks » de la carte (Exits
## n'accepte que des MapExit).
## Le récit (E6) déclenchera aussi les voyages lui-même ; les quais d'essai servent au
## développement et aux tests (tests/integration/test_x1_travel.gd).

const PLAYER_MASK := 2
const INTERACTABLE_LAYER := 32
const INTERACTABLE_GROUP := &"interactable"
## Invite par défaut (data/texts/story.json ; {island} : nom de l'île d'arrivée).
const PROMPT_KEY := "travel/dock_prompt"

## Île d'arrivée (data/world/islands/<island>.json).
@export var island: StringName = &""
## Port d'arrivée sur cette île (vide : son premier port).
@export var port: StringName = &""
## Invite ; vide : celle de data/texts/story.json (« Embarquer pour … »).
@export var prompt: String = ""


func _ready() -> void:
	collision_layer = INTERACTABLE_LAYER
	collision_mask = PLAYER_MASK
	monitorable = true
	monitoring = false
	add_to_group(INTERACTABLE_GROUP)


## Invite de l'interactable (contrat Interactable).
func get_prompt() -> String:
	if not prompt.is_empty():
		return prompt
	var text := DialogueRunner.story_text(PROMPT_KEY, "Embarquer")
	return text.replace("{island}", WorldAtlas.island_name(island))


## Interaction du joueur (contrat Interactable) : embarque.
func interact(_player: Node3D) -> void:
	board()


## Part vers island (WorldManager.travel) ; sans effet pendant un changement de carte ou si la
## destination est inconnue. Vrai si le voyage commence.
func board() -> bool:
	if WorldManager.is_transitioning() or WorldAtlas.arrival(island, port).is_empty():
		return false
	WorldManager.travel(island, port)
	return WorldManager.is_transitioning()


## Problème de destination (vide : île et port connus), pour les tests des cartes.
func destination_problem() -> String:
	if not WorldAtlas.has_island(island):
		return "île « %s » inconnue" % island
	if not port.is_empty() and WorldAtlas.port(island, port).is_empty():
		return "port « %s » inconnu sur %s" % [port, island]
	return ""
