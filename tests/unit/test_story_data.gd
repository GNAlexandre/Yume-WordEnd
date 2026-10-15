extends GutTest
## (E6) Le format des scènes du récit (StoryData) : clés strictes, étapes, déclencheurs, et chaque
## scène de l'île n° 68 vérifiée sans lancer le jeu (personnages, cartes, places, textes,
## dialogues, animations, tenues).

const ISLAND := &"ile_68"


func before_each() -> void:
	StoryData.use_root("")
	GameState.reset()


func after_each() -> void:
	StoryData.use_root("")
	GameState.reset()


## Une scène minimale valide (sans le monde).
func _scene() -> Dictionary:
	return {
		"day": 1,
		"map": "entrepot",
		"trigger": {"on": "ready"},
		"steps": [{"do": "wait", "time": 1.0}],
	}


func test_act_and_scenes_of_ile_68_are_valid() -> void:
	assert_true(StoryData.has_act(ISLAND), "l'île n° 68 a un récit (act.json)")
	var problems := StoryData.all_problems(ISLAND)
	assert_eq(problems, PackedStringArray(), "\n".join(problems))


func test_days_1_to_4_have_their_scenes() -> void:
	var ids := StoryData.scene_ids(ISLAND)
	for scene_id: StringName in [
		&"j1_1_port",
		&"j1_2_lumiere",
		&"j1_2_embuscade",
		&"j1_3_intrus",
		&"j1_4_chemin",
		&"j1_5_premiers_pas",
		&"j1_6_diner",
		&"j1_7_chambre",
		&"j2_1_matin",
		&"j2_2_fuite",
		&"j2_3_fenetre",
		&"j3_1_information",
		&"j3_2_chemin",
		&"j3_3_snack",
		&"j4_1_cuisine",
		&"j4_2_diner",
	]:
		assert_has(ids, scene_id)
		assert_false(StoryData.scene(ISLAND, scene_id).is_empty(), "%s se lit" % scene_id)
	for day: int in range(1, 5):
		assert_false(StoryData.text(ISLAND, "days/%d/calendar" % day).is_empty(), "ligne %d" % day)


func test_minimal_scene_is_valid() -> void:
	assert_eq(StoryData.scene_problems(&"essai", _scene(), ISLAND, false), PackedStringArray())


func test_unknown_keys_are_refused() -> void:
	var data := _scene()
	data["dya"] = 2
	assert_string_contains(_problems(data), "clé inconnue « dya »")
	data = _scene()
	data["trigger"] = {"on": "reach", "point": "porche_banc", "rayon": 3}
	assert_string_contains(_problems(data), "clé inconnue « rayon »")
	data = _scene()
	data["steps"] = [{"do": "wait", "time": 1.0, "temps": 2}]
	assert_string_contains(_problems(data), "clé inconnue « temps »")
	data = _scene()
	data["steps"] = [{"do": "danser"}]
	assert_string_contains(_problems(data), "« do » inconnu « danser »")
	var act := StoryData.act(ISLAND).duplicate(true)
	act["nuit_blanche"] = true
	assert_string_contains(
		"\n".join(StoryData.act_problems(act, ISLAND, false)), "clé inconnue « nuit_blanche »"
	)


func test_steps_check_their_values() -> void:
	var data := _scene()
	data["steps"] = [
		{"do": "walk", "who": "willem", "to": "porche_banc"},
		{"do": "fade", "to": "gris"},
		{"do": "slot", "slot": "goûter"},
		{"do": "control"},
		{"do": "wait_for", "reach": "porche_banc", "map": "entrepot", "talk": "willem"},
		{"do": "game", "game": "ballon", "fallback": [{"do": "wait"}]},
		{"do": "show", "node": "../ailleurs", "visible": true},
		{"do": "dialogue", "node": "a", "presentation": "cadre"},
	]
	var text := _problems(data)
	assert_string_contains(text, "willem n'est pas dans « present »")
	assert_string_contains(text, "steps[1].to")
	assert_string_contains(text, "créneau inconnu goûter")
	assert_string_contains(text, "« on » manque")
	assert_string_contains(text, "une seule de reach, map, examine, talk")
	assert_string_contains(text, "steps[5].fallback[0] : « time » manque")
	assert_string_contains(text, "chemin d'un nœud de la carte attendu")
	assert_string_contains(text, "bandeau ou nuit")


func test_world_is_checked() -> void:
	var data := _scene()
	data["present"] = ["willem", "inconnue"]
	data["steps"] = [
		{"do": "place", "who": "willem", "at": "nulle_part"},
		{"do": "anim", "who": "willem", "anim": "voler"},
		{"do": "outfit", "who": "willem", "outfit": "pyjama"},
		{"do": "go_to", "map": "atlantide"},
		{"do": "card", "text": "carton_absent"},
		{"do": "dialogue", "node": "nulle_part", "file": "j1_2_lumiere"},
	]
	var text := "\n".join(StoryData.scene_problems(&"essai", data, ISLAND, true))
	assert_string_contains(text, "PNJ inconnu inconnue")
	assert_string_contains(text, "nulle_part n'est ni une place ni un marqueur de entrepot")
	assert_string_contains(text, "n'a pas l'animation voler")
	assert_string_contains(text, "n'a pas la tenue pyjama")
	assert_string_contains(text, "carte inconnue atlantide")
	assert_string_contains(text, "texte absent essai/carton_absent")
	assert_string_contains(text, "nœud nulle_part absent")


func test_sequences_have_no_choice_nor_control() -> void:
	var data := _scene()
	data["sequence"] = true
	data["steps"] = [
		{"do": "control", "on": true},
		{"do": "dialogue", "node": "choix", "file": "j1_2_lumiere"},
	]
	var text := "\n".join(StoryData.scene_problems(&"essai", data, ISLAND, true))
	assert_string_contains(text, "ni control ni contrôle")
	assert_string_contains(text, "pas de choix dans une séquence")


func test_story_conditions_in_dialogue_grammar() -> void:
	GameState.day = 3
	assert_true(DialogueRunner.evaluate({"day": 3}))
	assert_true(DialogueRunner.evaluate({"day": [2, 4]}))
	assert_false(DialogueRunner.evaluate({"day": [4, 12]}))
	GameState.mark_scene_done(&"j1_1_port")
	assert_true(DialogueRunner.evaluate({"scene": "j1_1_port"}))
	assert_false(DialogueRunner.evaluate({"not_scene": ["j1_1_port", "j1_2_lumiere"]}))
	assert_true(DialogueRunner.evaluate({"not_scene": "j1_2_lumiere"}))
	GameState.moment = &"matin"
	assert_true(DialogueRunner.evaluate({"slot": ["aube", "matin"]}))
	assert_eq(DialogueRunner.condition_problem({"slot": "goûter"}).is_empty(), false)
	assert_eq(DialogueRunner.condition_problem({"day": [5, 2]}).is_empty(), false)


func _problems(data: Dictionary) -> String:
	return "\n".join(StoryData.scene_problems(&"essai", data, ISLAND, false))
