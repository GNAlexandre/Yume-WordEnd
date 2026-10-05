extends Node3D
## Démos du Lot 1, jouables dans l'éditeur (F6) et instanciées par la fumée :
## - demo_l1.tscn : sol et obstacles CSG (couche 1), pentes de 40° (praticable) et 50° (trop
##   raide), interactable factice (faux dialogue de 1,5 s) et deux ennemis factices ;
## - demo_l1.beach.tscn : l'île (lecture seule), joueur au Spawn de la plage, caméra du joueur
##   (capture build/shots/l1.png).
## Affiche l'aide, l'invite d'interaction (EventBus.interaction_available) et la cible
## verrouillée (Player.locked_target()).

const HELP := (
	"ZQSD / WASD / flèches : bouger · Maj : courir · Espace : sauter · E : interagir\n"
	+ "Clic : capturer la souris (Échap la libère) · molette : zoom · clic molette : verrouiller"
)

## Zone où placer le joueur au départ (WorldManager.teleport sur son Spawn) ; &"" : sur place.
@export var spawn_zone: StringName = &""
## Direction de départ du joueur ; la caméra se place derrière lui.
@export var facing: Vector3 = Vector3.FORWARD
## Affiche l'aide des commandes.
@export var show_help: bool = true

var _prompt: String = ""

@onready var _player: Player = $Player
@onready var _label: Label = $HUD/Label


func _ready() -> void:
	EventBus.interaction_available.connect(_on_interaction_available)
	if not spawn_zone.is_empty():
		WorldManager.teleport(spawn_zone, WorldManager.SPAWN_MARKER)
	_player.set_aim_direction(facing, true)
	_refresh_label()


func _process(_delta: float) -> void:
	_refresh_label()


func _refresh_label() -> void:
	var lines := PackedStringArray()
	if show_help:
		lines.append(HELP)
	if not _prompt.is_empty():
		lines.append("[E / A] %s" % _prompt)
	var target := _player.locked_target()
	if target != null:
		lines.append("Verrou : %s" % target.name)
	if _player.is_in_dialogue():
		lines.append("Dialogue en cours : le joueur ne bouge pas")
	_label.text = "\n".join(lines)
	_label.visible = not lines.is_empty()


func _on_interaction_available(prompt: String) -> void:
	_prompt = prompt
