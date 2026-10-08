extends Node
## (H5) Nœud « Lighting » d'island.tscn : pose sur l'île (son parent) le réglage de lumière HD-2D
## de la phase de la journée quand l'histoire l'annonce (EventBus.day_phase_changed :
## evening → crépuscule, night → nuit, morning et day → couchant ; HD2DLighting.for_phase). Rien
## n'émet encore ce signal : l'île de l'acte 1 reste au couchant (MONDE.md 5.4) ; la promesse de
## nuit sur la colline (M3) n'aura qu'à l'émettre.

## Phase posée en dernier (vide : aucune, l'île est telle qu'island.tscn la décrit).
var phase: StringName = &""


func _ready() -> void:
	EventBus.day_phase_changed.connect(_on_day_phase_changed)


func _on_day_phase_changed(new_phase: StringName) -> void:
	var island := get_parent() as Node3D
	if island == null or new_phase == phase:
		return
	phase = new_phase
	HD2DLighting.for_phase(new_phase).apply(island)
