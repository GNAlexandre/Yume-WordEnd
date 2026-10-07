extends GutTest
## (Systèmes et textes) Textes de l'arène, de la chute et de la défaite en données
## (HISTOIRE.md, section 3.5 et développement n° 4) : data/texts/story.json, lu par
## DialogueRunner.story_text / arena_text ; invite et panneau de l'arène, titre et record de fin de
## série par arène (repli sur « default »), fondu et message de la défaite, fondu au blanc et
## message du rattrapage de chute (WorldManager.rescued) ; fichiers invalides.

const ARENA_SCENE := preload("res://src/enemies/arena.tscn")
const ARENA_END := preload("res://src/ui/arena_end.tscn")
const HUD := preload("res://src/ui/hud.tscn")
const HudScript := preload("res://src/ui/hud.gd")
const PLAYER_STUB := preload("res://tests/stubs/player_stub.tscn")
const DIR := "user://test_story_texts"
const NBSP := " "
const APOSTROPHE := "’"


func before_each() -> void:
	GameState.reset()
	get_tree().paused = false
	DirAccess.make_dir_recursive_absolute(DIR)


func after_each() -> void:
	get_tree().paused = false
	for file_name: String in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(file_name))
	GameState.reset()


func _write(file_name: String, text: String) -> String:
	var path := DIR.path_join(file_name)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()
	return path


func _hud() -> HudScript:
	var hud: HudScript = HUD.instantiate()
	hud.fade_time = 0.02
	hud.story_time = 0.2
	hud.fall_flash_time = 0.2
	return add_child_autofree(hud)


# --- Le fichier -------------------------------------------------------------------------------


func test_story_file_is_valid_and_has_every_text() -> void:
	var story := DialogueRunner.load_story_texts(DialogueRunner.STORY_PATH)
	assert_false(story.is_empty(), "data/texts/story.json lu")
	assert_eq(DialogueRunner.story_problem(story), "", "forme valide")
	var expected := {
		"arenas/dunes/prompt": "Sonner la cloche de veille",
		"arenas/dunes/sign": "Cloche\nde veille",
		"arenas/dunes/end_title": "Fin de la veille",
		"arenas/dunes/new_record": "Nouveau record de veille%s!" % NBSP,
		"arenas/default/prompt": "Affronter les Timeres",
		"arenas/default/end_title": "Fin de la série",
		"arenas/default/new_record": "Nouveau record%s!" % NBSP,
		"fall/message": "Tes ailes se sont ouvertes%s: te revoilà au bord." % NBSP,
		"defeat/fade": "Retour à l%sentrepôt…" % APOSTROPHE,
		"defeat/message": "Les autres t%sont ramenée à l%sentrepôt." % [APOSTROPHE, APOSTROPHE],
	}
	for key_path: String in expected:
		assert_eq(DialogueRunner.story_text(key_path), expected[key_path], key_path)


func test_lookups_fall_back() -> void:
	assert_eq(DialogueRunner.story_text("absent/message", "secours"), "secours", "clé absente")
	assert_eq(
		DialogueRunner.story_text("fall", "secours"), "secours", "un objet n'est pas un texte"
	)
	assert_eq(DialogueRunner.story_text("fall/message/plus"), "", "trop profond")
	assert_eq(
		DialogueRunner.arena_text(&"sys_ailleurs", "prompt"),
		"Affronter les Timeres",
		"arène sans textes : ceux de default"
	)
	assert_eq(DialogueRunner.arena_text(&"dunes", "absent", "secours"), "secours")


func test_invalid_story_files_warn_and_give_nothing() -> void:
	assert_eq(DialogueRunner.load_story_texts(DIR.path_join("absent.json")), {})
	assert_push_warning("introuvables")
	assert_eq(DialogueRunner.load_story_texts(_write("bad.json", "{ pas du json")), {})
	assert_push_warning("JSON invalide")
	var wrong := _write("wrong.json", JSON.stringify({"fall": {"message": 3}, "_note": 1}))
	assert_eq(DialogueRunner.load_story_texts(wrong), {})
	assert_push_warning("fall/message : texte ou objet attendu")
	assert_string_contains(DialogueRunner.story_problem([]), "objet attendu")
	var commented := {"_comment": 1, "a": {"_b": [], "c": "texte"}}
	assert_eq(DialogueRunner.story_problem(commented), "", "clés « _… » : commentaires")


# --- L'arène ----------------------------------------------------------------------------------


func _arena(arena_id: StringName) -> Arena:
	var root: Node3D = add_child_autofree(Node3D.new())
	var arena := ARENA_SCENE.instantiate() as Arena
	arena.arena_id = arena_id
	root.add_child(arena)
	return arena


func test_arena_panel_prompt_and_sign_come_from_the_story_texts() -> void:
	var dunes := _arena(&"dunes")
	var panel := dunes.get_node(^"Panel")
	assert_eq(panel.call(&"get_prompt"), "Sonner la cloche de veille", "invite de la veille")
	assert_eq(panel.call(&"prompt"), "Sonner la cloche de veille", "prompt() hors série")
	assert_null(panel.get_node_or_null(^"Label"), "la cloche du monde remplace la planche")
	var other := _arena(&"sys_ailleurs")
	assert_eq(other.get_node(^"Panel").call(&"get_prompt"), "Affronter les Timeres", "default")
	# Une planche facultative (Label3D « Label ») reçoit le texte « sign » de son arène.
	assert_eq(_signed_arena(&"dunes").text, "Cloche\nde veille", "planche de la veille")
	assert_eq(_signed_arena(&"sys_ailleurs").text, "Affronter\nles Timeres", "planche par défaut")


func _signed_arena(arena_id: StringName) -> Label3D:
	var arena := ARENA_SCENE.instantiate() as Arena
	arena.arena_id = arena_id
	var label := Label3D.new()
	label.name = "Label"
	arena.get_node(^"Panel").add_child(label)
	var root: Node3D = add_child_autofree(Node3D.new())
	root.add_child(arena)
	return label


func test_arena_end_title_and_record_come_from_the_story_texts() -> void:
	var panel: Control = add_child_autofree(ARENA_END.instantiate())
	panel.call(&"show_result", &"dunes", 640, true, 6)
	assert_eq((panel.get_node(^"%Header") as Label).text, "Fin de la veille")
	assert_eq((panel.get_node(^"%RecordLabel") as Label).text, "Nouveau record de veille%s!" % NBSP)
	assert_true(panel.get_node(^"%RecordBadge").visible)
	panel.call(&"close")
	panel.call(&"show_result", &"sys_ailleurs", 10, false, 1)
	assert_eq((panel.get_node(^"%Header") as Label).text, "Fin de la série", "default")
	assert_eq((panel.get_node(^"%RecordLabel") as Label).text, "Nouveau record%s!" % NBSP)
	panel.call(&"close")


# --- Défaite et chute -------------------------------------------------------------------------


func test_defeat_fade_then_message_at_the_warehouse() -> void:
	var hud := _hud()
	hud.death_delay = 0.0
	hud.death_fade_time = 0.05
	var label := hud.get_node(^"%DeathLabel") as Label
	assert_eq(label.text, "Retour à l%sentrepôt…" % APOSTROPHE, "texte du fondu au noir")
	assert_eq(hud.story_message(), "", "aucun message au départ")
	EventBus.player_died.emit()
	await wait_seconds(0.2)
	assert_eq(hud.story_message(), "", "pas pendant la mort")
	EventBus.player_respawned.emit()
	assert_eq(
		hud.story_message(),
		"Les autres t%sont ramenée à l%sentrepôt." % [APOSTROPHE, APOSTROPHE],
		"message au retour"
	)
	await wait_seconds(0.6)
	assert_eq(hud.story_message(), "", "puis il s'efface")


func test_rescue_shows_wings_of_light_and_the_fall_message() -> void:
	var hud := _hud()
	add_child_autofree(PLAYER_STUB.instantiate())
	watch_signals(WorldManager)
	WorldManager.rescue()
	assert_signal_emitted(WorldManager, "rescued", "rattrapage annoncé")
	assert_gt(hud.fall_flash_alpha(), 0.9, "fondu au blanc")
	assert_eq(
		hud.story_message(),
		"Tes ailes se sont ouvertes%s: te revoilà au bord." % NBSP,
		"message de la chute"
	)
	await wait_seconds(0.3)
	assert_eq(hud.fall_flash_alpha(), 0.0, "le blanc s'est dissipé")
	await wait_seconds(0.5)
	assert_eq(hud.story_message(), "", "le message aussi")


func test_rescue_without_player_does_nothing() -> void:
	watch_signals(WorldManager)
	WorldManager.rescue()
	assert_signal_not_emitted(WorldManager, "rescued", "personne à rattraper")
