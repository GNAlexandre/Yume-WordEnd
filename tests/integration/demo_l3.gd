extends Node3D
## Démo du Lot 3 (visuel et skins) : la bibliothécaire (placeholder), Chtholly et le Timere aux
## échelles 0,8 / 1 / 1,3, côte à côte sur un damier d'un mètre, chacun enchaînant ses
## animations en boucle ; caméra fixe, toise de 1,5 m (marques tous les 50 cm) à gauche.
## Entrée ou Espace (ui_accept) : Chtholly passe au skin suivant, à chaud.
## Capture : tools/screenshot.sh res://tests/integration/demo_l3.tscn build/shots/l3.png

## Temps passé sur une animation en boucle (s).
const LOOP_TIME := 2.0
## Temps passé sur la dernière image d'une animation sans boucle (s).
const HOLD_TIME := 0.6
## Point visé par la caméra fixe.
const LOOK_AT := Vector3(-0.3, 0.7, 0.0)

## Temps restant avant l'animation suivante, par visuel.
var _left: Dictionary = {}

@onready var _characters: Node3D = $Characters
@onready var _chtholly: CharacterVisual = $Characters/Chtholly


func _ready() -> void:
	($Camera3D as Camera3D).look_at(LOOK_AT)
	for visual in _visuals():
		# Les Timeres (à droite) font face à Chtholly : leur planche est retournée.
		visual.set_facing(Vector3.LEFT if visual.position.x > 0.0 else Vector3.RIGHT)
		visual.animation_finished.connect(_on_animation_finished.bind(visual))
		_left[visual] = LOOP_TIME


func _process(delta: float) -> void:
	for visual in _visuals():
		_left[visual] -= delta
		if _left[visual] <= 0.0:
			_play_next(visual)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_accept"):
		var skins := SkinRegistry.all()
		var index := skins.find(_chtholly.skin)
		_chtholly.set_skin(skins[(index + 1) % skins.size()])


func _visuals() -> Array[CharacterVisual]:
	var result: Array[CharacterVisual] = []
	for child in _characters.get_children():
		if child is CharacterVisual:
			result.append(child)
	return result


## Animation suivante de la planche (ordre du JSON), relancée depuis l'image 0.
func _play_next(visual: CharacterVisual) -> void:
	var anims := SheetLoader.animations(SheetLoader.read_sheet(visual.skin))
	var names := anims.keys()
	var next: String = names[(names.find(String(visual.current_animation())) + 1) % names.size()]
	visual.play(StringName(next), true)
	_left[visual] = LOOP_TIME if bool(anims[next].get("boucle", false)) else INF


func _on_animation_finished(_anim: StringName, visual: CharacterVisual) -> void:
	_left[visual] = HOLD_TIME
