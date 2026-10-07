extends GutTest
## Les 45 assets inventoriés traversent la vraie interface CharacterVisual : scène skinnée,
## clips et métadonnées de combat, progression de l'horloge, boucles et orientation +Z.

const VISUAL_SCENE := preload("res://src/visuals/character_visual.tscn")
const COMBAT_ANIMS := ["attaque", "charge", "course", "degats", "marche", "mort", "repos"]
const NPC_ANIMS := ["marche", "parle", "repos"]


func test_all_45_models_are_animated_character_visuals() -> void:
	var inventory := load("res://docs/sprites/reference_inventory.json") as JSON
	assert_not_null(inventory, "inventaire des références")
	if inventory == null:
		return
	var entries: Array = inventory.data["entries"]
	assert_eq(entries.size(), 45, "tous les personnages et variantes inventoriés")
	var checked := 0
	var seen := {}
	for entry: Dictionary in entries:
		var ident := String(entry["id"])
		assert_false(seen.has(ident), ident + " : identifiant unique")
		seen[ident] = true
		if _check_model(ident, entry["kind"] == "combat"):
			checked += 1
	assert_eq(checked, 45, "45 scènes réellement instanciées")


func _check_model(ident: String, combat: bool) -> bool:
	var prefix := "res://assets/models/characters/%s/%s" % [ident, ident]
	var skin := load(prefix + ".tres") as SkinData
	var metadata := load(prefix + ".anim.json") as JSON
	assert_not_null(skin, ident + " : SkinData")
	assert_not_null(metadata, ident + " : cadences et images clés")
	if skin == null or metadata == null:
		return false
	assert_null(skin.sprite_sheet, ident + " : visuel 3D")
	assert_not_null(skin.mesh_scene, ident + " : modèle importé")
	if skin.mesh_scene == null:
		return false
	var visual := VISUAL_SCENE.instantiate() as CharacterVisual
	add_child(visual)
	visual.set_process(false)
	visual.set_skin(skin)
	var mesh := visual.get_node_or_null(^"Mesh") as Node3D
	assert_not_null(mesh, ident + " : modèle instancié")
	if mesh == null:
		visual.free()
		return false
	assert_false((visual.get_node(^"Sprite") as Node3D).visible, ident + " : sprite caché")
	var players := mesh.find_children("*", "AnimationPlayer", true, false)
	assert_false(players.is_empty(), ident + " : lecteur d'animations")
	if not players.is_empty():
		_check_clips(
			visual, players[0] as AnimationPlayer, metadata.data["animations"], ident, combat
		)
	if combat:
		assert_eq(visual.hit_frames(&"attaque"), [1, 2, 3] as Array[int], ident + " : coups")
		assert_eq(visual.wave_frame(&"charge"), 3, ident + " : onde")
	visual.set_facing(Vector3.RIGHT)
	assert_almost_eq(mesh.global_rotation.y, PI / 2.0, 0.001, ident + " : +Z vers la cible")
	visual.free()
	return true


func _check_clips(
	visual: CharacterVisual, player: AnimationPlayer, clips: Dictionary, ident: String, combat: bool
) -> void:
	var names := clips.keys()
	names.sort()
	assert_eq(names, COMBAT_ANIMS if combat else NPC_ANIMS, ident + " : clips prescrits")
	for clip_name: String in clips:
		var label := "%s / %s" % [ident, clip_name]
		assert_true(visual.has_animation(StringName(clip_name)), label + " : animation chargée")
		if not player.has_animation(clip_name):
			continue
		var clip := player.get_animation(clip_name)
		var description: Dictionary = clips[clip_name]
		var fps := float(description["ips"])
		assert_almost_eq(clip.length, float(description["images"]) / fps, 0.001, label + " : durée")
		assert_almost_eq(float(clip.get_meta(&"ips", 0.0)), fps, 0.001, label + " : cadence")
		assert_eq(clip.loop_mode != Animation.LOOP_NONE, description["boucle"], label + " : boucle")
		visual.play(StringName(clip_name), true)
		visual.advance(clip.length * 0.4)
		assert_eq(
			visual.current_frame(), floori(float(description["images"]) * 0.4), label + " : horloge"
		)
