extends Node3D
## Applique les cadences et les événements du fichier .anim.json au GLB animé.
## Cette scène enveloppe le modèle sans modifier le gameplay ni le fichier importé.

@export var animation_metadata: JSON


func _ready() -> void:
	if animation_metadata == null or not animation_metadata.data is Dictionary:
		push_error("Métadonnées 3D absentes ou invalides : " + scene_file_path)
		return
	var document: Dictionary = animation_metadata.data
	var descriptions: Dictionary = document.get("animations", {})
	var players := find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		push_error("AnimationPlayer absent : " + scene_file_path)
		return
	var player := players[0] as AnimationPlayer
	for clip_name: String in descriptions:
		if not player.has_animation(clip_name):
			push_error("Animation 3D absente : " + clip_name + " / " + scene_file_path)
			continue
		var clip := player.get_animation(clip_name)
		var description: Dictionary = descriptions[clip_name]
		var fps := float(description.get("ips", 10))
		var frame_count := int(description.get("images", 1))
		if fps <= 0.0 or frame_count <= 0:
			push_error("Cadence 3D invalide : " + clip_name)
			continue
		var expected_length := frame_count / fps
		if absf(clip.length - expected_length) > 0.001:
			push_error("Durée 3D invalide : " + clip_name + " / " + scene_file_path)
			continue
		clip.set_meta(&"ips", fps)
		clip.set_meta(&"coup", description.get("coup", []))
		clip.set_meta(&"onde", int(description.get("onde", -1)))
		clip.loop_mode = (
			Animation.LOOP_LINEAR if description.get("boucle", false) else Animation.LOOP_NONE
		)
