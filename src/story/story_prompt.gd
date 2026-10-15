class_name StoryPrompt
extends Area3D
## (E6) Invite du récit posée sur la carte courante par StoryDirector (« Dormir », « Laisser passer
## le temps », « S'asseoir à la fenêtre »…) : un interactable (couche 6, groupe « interactable »,
## contrat Interactable de PLAN.md section 3) dont le texte et la présence suivent l'état du récit.
## Indisponible (texte vide), il quitte la couche 6 : le joueur ne le voit plus. Propriétaire : E6.

## Le joueur l'a utilisé.
signal used(prompt: StoryPrompt)

const INTERACTABLE_LAYER := 32
const INTERACTABLE_GROUP := &"interactable"

## Rôles : le lit (dormir, laisser passer le temps), un siège (laisser passer le temps), le
## déclencheur d'une scène.
const ROLE_SLEEP := &"sleep"
const ROLE_REST := &"rest"
const ROLE_SCENE := &"scene"

## Rôles de l'invite (ROLE_*) et scène qu'elle déclenche (ROLE_SCENE).
var roles: Array[StringName] = []
var scene_id: StringName = &""
## Place de la carte où elle est posée (pour les tests et la trace).
var point_name: String = ""

var _text: String = ""


func _init(size: float = 1.6) -> void:
	collision_layer = 0
	collision_mask = 0
	monitoring = false
	monitorable = true
	add_to_group(INTERACTABLE_GROUP)
	var shape := BoxShape3D.new()
	shape.size = Vector3(size, 1.6, size)
	var holder := CollisionShape3D.new()
	holder.name = "CollisionShape3D"
	holder.shape = shape
	holder.position = Vector3(0.0, 0.8, 0.0)
	add_child(holder)


## Texte affiché ; vide : indisponible (hors de la couche 6).
func set_text(text: String) -> void:
	_text = text
	collision_layer = INTERACTABLE_LAYER if not text.is_empty() else 0


## Vrai si l'invite est proposée.
func is_available() -> bool:
	return not _text.is_empty()


## Invite (contrat Interactable).
func get_prompt() -> String:
	return _text


## Interaction du joueur (contrat Interactable).
func interact(_player: Node3D) -> void:
	if is_available():
		used.emit(self)
