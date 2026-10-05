extends CharacterVisual
## Visuel factice pour les tests (pas de class_name : les stubs ne doivent pas entrer en
## collision entre lots). Hérite de character_visual.tscn, donc garde sa structure réelle,
## et permet de piloter frame_changed / animation_finished à la demande.
##
##   var visual: CharacterVisual = preload("res://tests/stubs/visual_stub.tscn").instantiate()
##   visual.forced_hit_frames[&"attaque"] = [1, 2, 3]
##   visual.emit_frame(&"attaque", 1)

## Images « coup » imposées par animation (sinon celles de la planche du skin).
var forced_hit_frames: Dictionary = {}
## Animations demandées par emit_frame / finish, dans l'ordre.
var emitted: Array[StringName] = []


func hit_frames(anim: StringName) -> Array[int]:
	if forced_hit_frames.has(anim):
		var frames: Array[int] = []
		for frame: Variant in forced_hit_frames[anim]:
			frames.append(int(frame))
		return frames
	return super.hit_frames(anim)


## Émet frame_changed(anim, frame) comme si l'animation atteignait cette image.
func emit_frame(anim: StringName, frame: int) -> void:
	emitted.append(anim)
	frame_changed.emit(anim, frame)


## Émet animation_finished(anim).
func finish(anim: StringName) -> void:
	emitted.append(anim)
	animation_finished.emit(anim)
