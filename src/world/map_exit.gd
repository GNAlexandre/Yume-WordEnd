class_name MapExit
extends Area3D
## Sortie d'une carte (docs/REFONTE.md, section 7.1) : enfant du nœud « Exits » d'une Map, avec
## une forme (CollisionShape3D) qui couvre le passage. Propriétaire : E1.
##
## - prompt vide : on passe en marchant dedans (bout de sentier). Area3D couche 0, masque 2
##   (player) ; le joueur qui y entre part vers target_map, arrivée sur target_marker.
## - prompt rempli (« Entrer », « Monter à bord ») : on passe par une interaction, comme un PNJ
##   ou un objet. La sortie rejoint alors le groupe "interactable" et la couche 6 (interactable)
##   dans son _ready, pour que le joueur la détecte : invite du HUD, touche E ou bouton A.
## Rien ne part pendant un changement de carte (WorldManager.is_transitioning()) : ni pendant le
## fondu, ni juste après l'arrivée. Un joueur posé sur une sortie à son arrivée doit donc en
## sortir puis y revenir pour la prendre (pas d'aller-retour immédiat).

## Le joueur (couche 2) déclenche les sorties.
const PLAYER_MASK := 2
## Couche 6 (interactable, valeur 32) des sorties à invite.
const INTERACTABLE_LAYER := 32
const INTERACTABLE_GROUP := &"interactable"
const PLAYER_GROUP := &"player"

## Carte où mène la sortie (son map_id).
@export var target_map: StringName = &""
## Marqueur d'arrivée dans la carte cible, nommé comme la carte d'où l'on vient
## (`from_<cette carte>`) ; Spawn par défaut.
@export var target_marker: StringName = &"Spawn"
## Invite de l'interaction (« Entrer ») ; vide : on passe en marchant.
@export var prompt: String = ""


func _ready() -> void:
	collision_mask = PLAYER_MASK
	if needs_interaction():
		collision_layer = INTERACTABLE_LAYER
		monitorable = true
		add_to_group(INTERACTABLE_GROUP)
	else:
		collision_layer = 0
		monitorable = false
		body_entered.connect(_on_body_entered)


## Vrai si l'on passe par une interaction (prompt rempli), faux si l'on passe en marchant.
func needs_interaction() -> bool:
	return not prompt.is_empty()


## Invite de l'interactable (contrat Interactable) : prompt.
func get_prompt() -> String:
	return prompt


## Interaction du joueur (contrat Interactable) : prend la sortie.
func interact(_player: Node3D) -> void:
	use()


## Prend la sortie : WorldManager.go_to(target_map, target_marker). Sans effet pendant un
## changement de carte ; renvoie vrai si le voyage commence.
func use() -> bool:
	if target_map.is_empty() or WorldManager.is_transitioning():
		return false
	WorldManager.go_to(target_map, target_marker)
	return WorldManager.is_transitioning()


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group(PLAYER_GROUP):
		use()
