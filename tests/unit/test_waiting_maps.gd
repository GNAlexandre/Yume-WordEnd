extends GutTest
## (T1) Les cartes d'attente de la phase 2 (village, colline, sentier, foret_profonde ;
## docs/DECISIONS.md, T1) : chacune suit le contrat des cartes, a son sol plat, sa lisière, son
## écriteau « Plus loin, bientôt » qu'on lit (boîte de dialogue, sans portrait), la sortie de
## retour vers l'entrepôt (au marqueur from_<carte> du plan de l'entrepôt) et le marqueur
## from_entrepot ; et le raccourci de développement ?map= (src/test_shortcuts.gd).

const TestShortcuts := preload("res://src/test_shortcuts.gd")
const WAITING: Array[StringName] = [&"village", &"colline", &"sentier", &"foret_profonde"]
const SIGN_TEXT := "maps/waiting/text"

var _lines: Array = []


func after_each() -> void:
	DialogueRunner.clear_story_cache()


func _on_line(speaker: String, text: String, choices: Array[String]) -> void:
	_lines.append([speaker, text, choices])


func test_waiting_maps_follow_the_contract_and_lead_back_to_the_warehouse() -> void:
	var entrepot := (load(Map.scene_path(&"entrepot")) as PackedScene).instantiate() as Map
	var back_markers := entrepot.marker_names()
	entrepot.free()
	for map_id in WAITING:
		assert_true(Map.exists(map_id), "%s existe" % map_id)
		var map := (load(Map.scene_path(map_id)) as PackedScene).instantiate() as Map
		add_child(map)
		await wait_physics_frames(1)
		assert_eq(Map.problems(map), PackedStringArray(), "%s : contrat" % map_id)
		assert_eq(
			Map.exit_problems(map, {&"entrepot": back_markers}),
			PackedStringArray(),
			"%s : sortie vers l'entrepôt" % map_id
		)
		var exit := map.get_node(^"Exits/vers_entrepot") as MapExit
		assert_eq(exit.target_map, &"entrepot")
		assert_eq(exit.target_marker, StringName("from_" + String(map_id)), "%s : retour" % map_id)
		assert_not_null(map.marker(&"from_entrepot"), "%s : from_entrepot" % map_id)
		var ground := map.get_node(^"Ground") as MapGround
		assert_not_null(ground, "%s : sol en relief" % map_id)
		var spawn := map.spawn().global_position
		assert_almost_eq(ground.height_at(spawn.x, spawn.z), 0.0, 0.001, "%s : sol plat" % map_id)
		assert_false(map.display_name.is_empty(), "%s : nom affiché" % map_id)
		var reader := map.get_node_or_null(^"Geometry/Sign/Reader") as Area3D
		assert_not_null(reader, "%s : écriteau" % map_id)
		assert_true(reader.is_in_group(&"interactable"), "%s : on le lit" % map_id)
		assert_eq(reader.collision_layer, 32, "%s : couche 6 (interactable)" % map_id)
		map.free()


func test_reading_the_sign_shows_its_text_without_a_portrait() -> void:
	var map := (load(Map.scene_path(&"village")) as PackedScene).instantiate() as Map
	add_child_autofree(map)
	await wait_physics_frames(1)
	var reader := map.get_node(^"Geometry/Sign/Reader")
	assert_eq(reader.call(&"get_prompt"), "Lire")
	watch_signals(EventBus)
	EventBus.dialogue_line.connect(_on_line)
	reader.call(&"interact", null)
	EventBus.dialogue_line.disconnect(_on_line)
	assert_signal_emitted(EventBus, "dialogue_started")
	assert_eq(_lines.size(), 1, "une réplique")
	assert_eq(_lines[0][0], "Écriteau")
	assert_eq(_lines[0][1], DialogueRunner.story_text(SIGN_TEXT))
	assert_string_contains(String(_lines[0][1]), "Plus loin, bientôt")
	assert_null(DialogueRunner.find_npc(&"ecriteau"), "pas de portrait")
	assert_eq(reader.call(&"get_prompt"), "", "pas d'invite pendant la lecture")
	EventBus.dialogue_choice_made.emit(-1)
	assert_signal_emitted(EventBus, "dialogue_ended")
	assert_false(reader.call(&"is_reading"), "refermé")


func test_map_shortcut_parameters() -> void:
	var query := TestShortcuts.parse_query("?map=entrepot&marker=from_sentier&autre=1")
	assert_eq(query, {"map": "entrepot", "marker": "from_sentier"})
	var arguments := TestShortcuts.parse_arguments(PackedStringArray(["--map=entrepot"]))
	assert_eq(arguments, {"map": "entrepot"})
