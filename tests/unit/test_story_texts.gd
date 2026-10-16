extends GutTest
## (Systèmes et textes) Textes de la chute et de la défaite en données (HISTOIRE.md, section
## 3.5 et développement n° 4) : data/texts/story.json, lu par DialogueRunner.story_text ; fondu et
## message de la défaite, fondu au blanc et message du rattrapage de chute (WorldManager.rescued),
## (F1) avis d'une partie de l'ancienne île ; fichiers invalides. Les textes de l'arène sont partis
## avec elle.

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
		"fall/message": "Tes ailes se sont ouvertes%s: te revoilà au bord." % NBSP,
		"defeat/fade": "Retour à l%sentrepôt…" % APOSTROPHE,
		"defeat/message": "Les autres t%sont ramenée à l%sentrepôt." % [APOSTROPHE, APOSTROPHE],
	}
	for key_path: String in expected:
		assert_eq(DialogueRunner.story_text(key_path), expected[key_path], key_path)
	var migrated := DialogueRunner.story_text("save/migrated")
	assert_string_contains(migrated, "ancienne île", "avis de la partie migrée")
	assert_string_contains(migrated, "premier jour")
	assert_eq(DialogueRunner.story_text("arenas/default/prompt"), "", "(F1) plus de textes d'arène")


func test_lookups_fall_back() -> void:
	assert_eq(DialogueRunner.story_text("absent/message", "secours"), "secours", "clé absente")
	assert_eq(
		DialogueRunner.story_text("fall", "secours"), "secours", "un objet n'est pas un texte"
	)
	assert_eq(DialogueRunner.story_text("fall/message/plus"), "", "trop profond")


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
	# (F1) Le rattrapage se fait sur une carte : une carte vide suffit.
	var map := Map.new()
	map.name = "essai"
	add_child_autofree(map)
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
