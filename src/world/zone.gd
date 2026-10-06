class_name Zone
extends Node3D
## Racine d'une zone de l'île (PLAN.md section 3). Propriétaire : L2.
##
## Structure figée : la racine est nommée comme son zone_id et appartient au groupe "zones" ;
## enfants « Spawn » (Marker3D, point d'arrivée) et « Bounds » (Area3D, couche 0, masque 2
## player) qui émet EventBus.zone_entered quand le joueur y entre.
##
## Intégration M2 : zone_entered n'est émis que pour un changement de zone. Les Bounds voisins
## se touchent : un joueur qui longe une frontière effleure la zone voisine, revient, l'effleure
## encore… sans jamais quitter la sienne. Chaque effleurement était une « entrée » (nom répété
## dans le HUD, auto-sauvegarde). La dernière zone annoncée est retenue sur le corps du joueur
## (métadonnée LAST_ZONE_META, oubliée avec lui : une nouvelle partie repart de zéro) ; une
## entrée dans cette même zone est ignorée.

## Métadonnée du corps du joueur : identifiant de la dernière zone annoncée par zone_entered.
const LAST_ZONE_META := &"zone_last_entered"

## Nom affiché par le HUD à l'entrée de la zone.
@export var display_name: String = ""
## Zone sûre : aucun ennemi n'y entre (le village est entouré d'une barrière couche 8).
@export var safe: bool = false


func _ready() -> void:
	var bounds := get_node_or_null(^"Bounds") as Area3D
	if bounds != null:
		bounds.body_entered.connect(_on_bounds_body_entered)


## Identifiant de la zone (le nom du nœud racine).
func zone_id() -> StringName:
	return StringName(name)


func _on_bounds_body_entered(body: Node3D) -> void:
	if not body.is_in_group(&"player"):
		return
	var id := zone_id()
	if body.get_meta(LAST_ZONE_META, &"") == id:
		return
	body.set_meta(LAST_ZONE_META, id)
	EventBus.zone_entered.emit(id)
