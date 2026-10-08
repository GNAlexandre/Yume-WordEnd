extends SceneTree
## Audit des ressources livrées, sans placeholders : 52 personnages et Timere.
## tools/godot --headless --script tools/hd2d_library_check.gd
## Les ancres et cycles nécessitent toujours une revue artistique distincte.

const MANIFEST := "res://tools/hd2d_manifest.json"
const VISUAL := preload("res://src/visuals/character_visual.tscn")
const COMBATANTS: Array[String] = [
	"chtholly", "willem", "ithea", "nephren", "nopht", "rhantolk", "lillia"
]
const FACINGS: Dictionary[String, Vector3] = {
	"front": Vector3.BACK, "back": Vector3.FORWARD, "right": Vector3.RIGHT
}
## [nombre d'images, ips, boucle] : cahier + course PNJ demandée par l'utilisateur.
const NPC_CLIPS := {
	"repos": [2, 2, true],
	"marche": [6, 10, true],
	"course": [4, 12, true],
	"parle": [2, 6, true],
}
const COMBAT_CLIPS := {
	"repos": [2, 2, true],
	"marche": [6, 10, true],
	"course": [5, 14, true],
	"attaque": [4, 14, false],
	"charge": [4, 10, false],
	"degats": [1, 1, false],
	"mort": [1, 1, false],
}
const TIMERE_CLIPS := {
	"repos": [5, 6, true],
	"marche": [4, 7, true],
	"course": [6, 12, true],
	"fouet": [4, 8, false],
	"morsure": [4, 8, false],
	"degats": [5, 12, false],
	"mort": [6, 8, false],
}

var _failures: Array[String] = []
var _checks := 0
var _characters := 0
var _enemies := 0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var inventory: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not _require(inventory is Dictionary, "Le manifeste de livraison se charge"):
		_finish()
		return
	var ids: Array[String] = []
	for entry: Dictionary in inventory.get("entries", []):
		var path: String = entry.get("path", "")
		if not path.begins_with("assets/characters/") or entry.get("kind") != "sprite":
			continue
		var id: String = path.get_base_dir().get_file()
		if path.get_file() == id + ".png":
			ids.append(id)
	ids.sort()
	_require(ids.size() == 52, "Le manifeste contient les 52 identités attendues")
	for id: String in ids:
		var contract: Dictionary = COMBAT_CLIPS.duplicate(true) if id in COMBATANTS else NPC_CLIPS
		if id in ["ithea", "nephren"]:
			contract["parle"] = NPC_CLIPS["parle"]
		if _audit(id, "res://data/visuals2d/characters/%s/%s.tres" % [id, id], contract):
			_characters += 1
	if _audit("timere", "res://data/enemies/visuals/timere.tres", TIMERE_CLIPS):
		_enemies += 1
	_require(_characters == 52, "Les 52 ressources de personnages sont auditées")
	_require(_enemies == 1, "La ressource Timere est auditée")
	await process_frame
	_finish()


func _audit(id: String, path: String, contract: Dictionary) -> bool:
	if not _require(ResourceLoader.exists(path), "Ressource présente : " + path):
		return false
	var skin := load(path) as SkinData
	if not _require(skin != null, "Vraie ressource SkinData : " + id):
		return false
	_require(skin.mesh_scene == null, id + " : modèle 2D")
	_require(skin.directional_sheets.size() == 3, id + " : trois textures directionnelles")
	_require(skin.directional_frames_json.size() == 3, id + " : trois JSON directionnels")
	_require(skin.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST, id + " : pixels nets")
	_require(
		not str(skin.get_meta("status", "")).contains("pending"), id + " : aucune attente masquée"
	)
	if id != "timere":
		_require(skin.portrait != null, id + " : portrait présent")
	var visual := VISUAL.instantiate() as CharacterVisual
	root.add_child(visual)
	visual.set_process(false)
	visual.set_skin(skin)
	for direction: String in FACINGS:
		_audit_direction(id, direction, skin, visual, contract)
	for clip_name: String in contract:
		_audit_turning(id, visual, clip_name, contract[clip_name])
	visual.set_facing(Vector3.LEFT)
	_require(visual.current_direction() == "right", id + " : gauche partage le profil")
	var sprite := visual.get_node("Sprite") as AnimatedSprite3D
	_require(sprite.flip_h, id + " : miroir du profil gauche")
	visual.set_facing(Vector3.RIGHT)
	_require(not sprite.flip_h, id + " : profil droit sans miroir")
	visual.queue_free()
	return true


func _audit_direction(
	id: String, direction: String, skin: SkinData, visual: CharacterVisual, contract: Dictionary
) -> void:
	var label := id + "/" + direction
	var texture: Texture2D = skin.directional_sheets.get(direction)
	var metadata: JSON = skin.directional_frames_json.get(direction)
	if not _require(texture != null and metadata != null, label + " : fichiers réels présents"):
		return
	var directory := "enemies" if id == "timere" else "characters"
	var suffix := "" if direction == "right" else "_" + direction
	var stem := "res://assets/%s/%s/%s%s" % [directory, id, id, suffix]
	_require(texture.resource_path == stem + ".png", label + " : texture finale exacte")
	_require(metadata.resource_path == stem + ".json", label + " : JSON final exact")
	var frames := SheetLoader.frames_for(skin, direction)
	if not _require(frames != null, label + " : atlas chargé"):
		return
	_require(
		frames.get_animation_names().size() == contract.size(), label + " : inventaire des clips"
	)
	visual.set_facing(FACINGS[direction])
	_require(visual.current_direction() == direction, label + " : orientation effective")
	var sheet := SheetLoader.read_sheet(skin, direction)
	for clip_name: String in contract:
		var clip: Array = contract[clip_name]
		if not _require(
			frames.has_animation(clip_name), label + "/" + clip_name + " : clip présent"
		):
			continue
		var clip_label := label + "/" + clip_name
		_require(frames.get_frame_count(clip_name) == clip[0], clip_label + " : poses")
		_require(
			is_equal_approx(frames.get_animation_speed(clip_name), clip[1]), clip_label + " : ips"
		)
		_require(frames.get_animation_loop(clip_name) == clip[2], clip_label + " : boucle")
		var expected_hits: Array[int] = []
		if clip_name == "attaque":
			expected_hits = [1, 2, 3]
		elif clip_name in ["fouet", "morsure"]:
			expected_hits = [1, 2]
		_require(
			SheetLoader.hit_frames(sheet, StringName(clip_name)) == expected_hits,
			clip_label + " : coups"
		)
		var expected_wave := 3 if clip_name == "charge" else -1
		_require(
			SheetLoader.wave_frame(sheet, StringName(clip_name)) == expected_wave,
			clip_label + " : onde"
		)
		_audit_playback(visual, frames, texture, clip_name, clip, clip_label)


func _audit_playback(
	visual: CharacterVisual,
	frames: SpriteFrames,
	texture: Texture2D,
	clip_name: String,
	clip: Array,
	label: String
) -> void:
	visual.play(StringName(clip_name), true)
	_require(visual.current_animation() == StringName(clip_name), label + " : clip joué")
	var count: int = clip[0]
	var step := 1.0 / float(clip[1])
	for index: int in range(count):
		_require(visual.current_frame() == index, label + " : horloge image %d" % index)
		var atlas := frames.get_frame_texture(clip_name, index) as AtlasTexture
		if _require(atlas != null, label + " : vraie texture image %d" % index):
			_require(atlas.atlas == texture, label + " : bonne planche image %d" % index)
			_require(
				(
					atlas.region.size.x > 0.0
					and atlas.region.size.y > 0.0
					and Rect2(Vector2.ZERO, texture.get_size()).encloses(atlas.region)
				),
				label + " : rectangle valide image %d" % index
			)
		visual.advance(step)
	_require(visual.current_frame() == (0 if clip[2] else count - 1), label + " : fin du cycle")
	_require(visual.is_playing() == clip[2], label + " : arrêt ou reprise de boucle")


func _audit_turning(id: String, visual: CharacterVisual, clip_name: String, clip: Array) -> void:
	var label := id + "/" + clip_name + " : virage"
	var step := 1.0 / float(clip[1])
	visual.set_facing(Vector3.RIGHT)
	visual.play(StringName(clip_name), true)
	visual.advance(step * 0.45)
	for direction: String in FACINGS:
		visual.set_facing(FACINGS[direction])
		_require(visual.current_direction() == direction, label + " vers " + direction)
		_require(visual.current_frame() == 0, label + " conserve la pose")
		_require(visual.is_playing(), label + " conserve l'état de lecture")
	visual.advance(step * 0.55 + 0.000001)
	_require(
		visual.current_frame() == (1 if clip[0] > 1 else 0),
		label + " conserve le temps fractionnaire"
	)
	if clip[0] == 1 and not clip[2]:
		_require(not visual.is_playing(), label + " conserve la fin du clip unique")


func _require(condition: bool, description: String) -> bool:
	_checks += 1
	if not condition:
		_failures.append(description)
	return condition


func _finish() -> void:
	for failure: String in _failures:
		printerr("HD2D_LIBRARY_FAILURE: ", failure)
	print(
		(
			"HD2D_LIBRARY_CHECK: %d/52 personnages, %d/1 Timere, %d contrôles, %d échec(s)"
			% [_characters, _enemies, _checks, _failures.size()]
		)
	)
	quit(0 if _failures.is_empty() else 1)
