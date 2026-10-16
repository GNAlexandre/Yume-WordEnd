extends GutTest
## (S2) Les jours 9 à 12 de l'acte 1 côté données : les scènes de chaque jour (ACTE1.md 9.1 à
## 12.3) valides ; la fin de chaque jour (sleep_after) et la ligne du calendrier ; les indices de
## 60 signes au plus ; jamais « Chtholly » en dur ; deux choix au plus ; l'entraînement au bâton
## inscrit au récit ; l'étape place et sa hauteur (« lift ») ; Kana et Giniette ; l'uniforme
## d'Ithea et de Nephren ; le ballon de l'après-midi ; les adieux du jour 12.

const ISLAND := &"ile_68"
const DAYS := {
	9: [&"j9_1_porte", &"j9_2_batons", &"j9_3_cafe", &"j9_4_moutarde", &"j9_5_veillee"],
	10: [&"j10_1_rater", &"j10_2_foret", &"j10_3_linge", &"j10_4_toit", &"j10_5_tour"],
	11: [&"j11_1_toilette", &"j11_2_ne_pars_pas", &"j11_3_horloge", &"j11_4_seniorious"],
	12: [&"j12_1_derniere_journee", &"j12_1_embuscade", &"j12_2_depart", &"j12_3_epilogue"],
}
const MAX_HINT := 60


func before_each() -> void:
	StoryData.use_root("")
	LifeData.use_content(&"ile_68")
	GameState.reset()


func after_each() -> void:
	LifeData.use_content(&"")
	GameState.reset()


func test_scenes_of_days_9_to_12_are_valid() -> void:
	var ids := StoryData.scene_ids(ISLAND)
	for day: int in DAYS:
		for scene_id: StringName in DAYS[day]:
			assert_has(ids, scene_id)
			var raw: Variant = JSON.parse_string(
				FileAccess.get_file_as_string(
					StoryData.file_path("scenes", ISLAND, String(scene_id) + ".json")
				)
			)
			assert_eq(
				StoryData.scene_problems(scene_id, raw, ISLAND, true),
				PackedStringArray(),
				String(scene_id)
			)
			var data := StoryData.scene(ISLAND, scene_id)
			assert_eq(
				DialogueRunner.day_range(data["day"]), Vector2i(day, day), "%s : jour" % scene_id
			)
	assert_eq(StoryData.all_problems(ISLAND), PackedStringArray(), "tout le récit")


func test_each_day_ends_and_writes_its_line() -> void:
	for day: int in [9, 10, 11]:
		var day_data := StoryData.day_data(ISLAND, day)
		assert_false((day_data.get("sleep_after", []) as Array).is_empty(), "jour %d" % day)
		for scene_id: Variant in day_data["sleep_after"]:
			assert_has(DAYS[day], StringName(str(scene_id)))
		assert_false(StoryData.text(ISLAND, "days/%d/calendar" % day).is_empty())
		assert_false(StoryData.text(ISLAND, "days/%d/sleep_hint" % day).is_empty())
	assert_eq(StoryData.text(ISLAND, "calendar/depart"), "Départ au couchant.")
	assert_eq(int(StoryData.act(ISLAND)["departure_day"]), 12)
	assert_false(StoryData.day_data(ISLAND, 12).has("sleep_after"), "le jour 12 finit l'acte")


func test_hints_texts_and_dialogues_follow_the_rules() -> void:
	var texts := StoryData.texts(ISLAND)
	for day: int in DAYS:
		for scene_id: StringName in DAYS[day]:
			var section: Dictionary = texts.get(String(scene_id), {})
			for key: String in section:
				var text: String = section[key]
				assert_false(text.contains("Chtholly"), "%s/%s : {player}" % [scene_id, key])
				if key.begins_with("hint"):
					assert_lte(text.length(), MAX_HINT, "%s/%s : %s" % [scene_id, key, text])
			var path := StoryData.dialogue_path(ISLAND, String(scene_id))
			if not FileAccess.file_exists(path):
				continue
			var dialogue: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
			assert_eq(DialogueRunner.validate(dialogue), "", String(scene_id))
			for node_id: String in dialogue["nodes"]:
				var node: Dictionary = dialogue["nodes"][node_id]
				var label := "%s/%s" % [scene_id, node_id]
				assert_false(str(node.get("text", "")).contains("Chtholly"), label)
				assert_lte((node.get("choices", []) as Array).size(), 2, label)
				for choice: Dictionary in node.get("choices", []):
					assert_lte(str(choice["text"]).length(), 31, label)


func test_staff_training_is_registered_with_the_story() -> void:
	assert_eq(MiniGames.STORY_STAFF, &"entrainement_baton")
	assert_true(StoryDirector.has_game(&"entrainement_baton"), "inscrit par StoryDirector._ready")
	assert_true(StoryDirector.has_game(&"entrainement_seniorious"))


func test_place_step_takes_a_lift() -> void:
	var good := {
		"map": "entrepot_rdc",
		"trigger": {"on": "ready"},
		"present": ["kana"],
		"steps": [{"do": "place", "who": "kana", "at": "jeux_tapis", "lift": 1.7}],
	}
	assert_eq(StoryData.scene_problems(&"essai", good, ISLAND, true), PackedStringArray())
	var bad := good.duplicate(true)
	bad["steps"][0]["lift"] = "haut"
	assert_false(StoryData.scene_problems(&"essai", bad, ISLAND, true).is_empty(), "un nombre")


func test_kana_giniette_and_the_uniforms() -> void:
	for npc_id: StringName in [&"kana", &"giniette"]:
		var npc := LifeData.find_npc(npc_id)
		assert_not_null(npc, "data/npcs/generic/%s.tres" % npc_id)
		if npc == null:
			continue
		assert_eq(npc.skin.id, npc_id, "planche livrée")
		var anims := SheetLoader.animations(SheetLoader.read_sheet(npc.skin))
		for anim: String in ["assis", "saut", "grimpe", "tombe"]:
			assert_true(anims.has(anim), "%s : %s (la tour de fées)" % [npc_id, anim])
	for npc_id: StringName in [&"ithea", &"nephren"]:
		var npc := LifeData.find_npc(npc_id)
		assert_true(npc.has_outfit(&"uniforme"), "%s : uniforme du départ" % npc_id)
		assert_eq(npc.load_outfit(&"uniforme"), npc.skin, "la planche de combat")


func test_afternoon_ball_on_days_9_to_12() -> void:
	for npc_id: StringName in [&"tiat", &"collon", &"fairy_01", &"pannibal"]:
		for day: int in [9, 10, 11, 12]:
			var line := LifeData.line_for(npc_id, &"apres_midi", day)
			assert_eq(line.get("activity"), &"ballon", "%s, jour %d" % [npc_id, day])
		assert_ne(LifeData.line_for(npc_id, &"apres_midi", 6).get("activity"), &"ballon")
	assert_eq(LifeData.line_for(&"willem", &"apres_midi", 12).get("role"), &"arbitre")
	GameState.set_flag(&"pluie_du_jour")
	assert_ne(
		LifeData.line_for(&"tiat", &"apres_midi", 10).get("activity"), &"ballon", "la pluie rentre"
	)


func test_farewells_of_day_12() -> void:
	GameState.day = 12
	for npc_id: StringName in [
		&"willem", &"nygglatho", &"ithea", &"nephren", &"tiat", &"lakhesh", &"collon", &"pannibal"
	]:
		var path := StoryData.talk_path(ISLAND, npc_id)
		var dialogue: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		assert_eq(DialogueRunner.validate(dialogue), "", String(npc_id))
		assert_eq(DialogueRunner.pick_entry(dialogue), "n12", "%s : l'adieu du jour 12" % npc_id)
	GameState.mark_scene_done(&"j12_2_depart")
	var willem: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(StoryData.talk_path(ISLAND, &"willem"))
	)
	assert_ne(DialogueRunner.pick_entry(willem), "n12", "après le départ, plus d'adieu")
