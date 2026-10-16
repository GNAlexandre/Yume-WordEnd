extends GutTest
## (T1, C1) Les cartes d'attente : la forêt profonde, d'attente en T1 et en C1, est construite
## depuis CF (tests/unit/test_foret_profonde.gd) ; le sentier l'est depuis C1 (test_sentier.gd), le
## village depuis C2 (test_village.gd), la colline depuis C3 (test_colline.gd), le port depuis CP
## (test_port.gd) ; la place du marché, d'attente jusqu'à son lot, a son test
## (test_ville_attente.gd). Ce fichier garde :
## - l'écriteau « Plus loin, bientôt » qu'on lit (boîte de dialogue, sans portrait) : celui qui
##   ferme encore le sentier de l'est de la forêt profonde tant que la montagne n'existe pas
##   (sortie vers_montagne omise) ;
## - le raccourci de développement ?map= (src/test_shortcuts.gd).

const TestShortcuts := preload("res://src/test_shortcuts.gd")
const SIGN_TEXT := "maps/waiting/text"

var _lines: Array = []


func after_each() -> void:
	DialogueRunner.clear_story_cache()


func _on_line(speaker: String, text: String, choices: Array[String]) -> void:
	_lines.append([speaker, text, choices])


func test_the_closed_path_has_a_sign_until_its_map_exists() -> void:
	var map := (load(Map.scene_path(&"foret_profonde")) as PackedScene).instantiate() as Map
	add_child_autofree(map)
	await wait_physics_frames(1)
	var sign_node := map.find_child("SignMontagne", true, false)
	if Map.exists(&"montagne"):
		assert_null(sign_node, "la montagne existe : plus d'écriteau, une sortie")
		assert_not_null(map.get_node_or_null(^"Exits/vers_montagne"), "la sortie est posée")
		return
	assert_not_null(sign_node, "écriteau")
	assert_null(
		map.get_node_or_null(^"Exits/vers_montagne"), "pas de sortie vers une carte absente"
	)
	var reader := sign_node.get_node_or_null(^"Reader") as Area3D
	assert_not_null(reader, "on le lit")
	if reader != null:
		assert_true(reader.is_in_group(&"interactable"), "interactable")
		assert_eq(reader.collision_layer, 32, "couche 6 (interactable)")


func test_reading_the_sign_shows_its_text_without_a_portrait() -> void:
	var map := (load(Map.scene_path(&"foret_profonde")) as PackedScene).instantiate() as Map
	add_child_autofree(map)
	await wait_physics_frames(1)
	var sign_node := map.find_child("SignMontagne", true, false)
	if sign_node == null:
		pending("la montagne existe : plus d'écriteau")
		return
	var reader := sign_node.get_node(^"Reader")
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
