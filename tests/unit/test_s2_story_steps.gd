extends GutTest
## (S2) Les ajouts au moteur du récit des jours 7 et 8 : l'étape « player » (la protagoniste cachée
## le temps d'une séquence sans elle) et l'étape « props » (les talismans de la colline : des images
## animées en cercle et leur lueur), vérifiées par StoryData ; les scènes des jours 7 et 8 et la
## fin de leurs jours (act.json : sleep_after, lignes du calendrier).

const ISLAND := &"ile_68"


func _problems(steps: Array) -> PackedStringArray:
	var scene := {"map": "colline", "trigger": {"on": "ready"}, "steps": steps}
	return StoryData.scene_problems(&"essai_s2", scene, ISLAND, false)


func test_player_and_props_steps_are_checked() -> void:
	assert_eq(_problems([{"do": "player", "visible": false}]), PackedStringArray())
	var ring := {
		"do": "props",
		"id": "talismans",
		"image": "anim/talisman_float",
		"at": "talismans_centre",
		"count": 41,
		"radius": 3.5,
		"lift": 1.1,
		"frames": 4,
		"fps": 6,
		"light": 1.6,
		"color": "#cfe2ff",
	}
	assert_eq(_problems([ring]), PackedStringArray())
	assert_eq(_problems([{"do": "props", "id": "talismans", "clear": true}]), PackedStringArray())
	assert_eq(_problems([{"do": "player"}]).size(), 1, "visible obligatoire")
	assert_eq(_problems([{"do": "props", "id": "x"}]).size(), 1, "image et at, ou clear")
	var unknown := ring.duplicate()
	unknown["image"] = "anim/absente"
	assert_eq(_problems([unknown]).size(), 1, "image inconnue")
	var bad_color := ring.duplicate()
	bad_color["color"] = "bleu"
	assert_eq(_problems([bad_color]).size(), 1, "couleur")


func test_days_7_and_8_have_their_scenes_and_end_on_a_scene() -> void:
	var ids := StoryData.scene_ids(ISLAND)
	for scene_id: StringName in [
		&"j7_1_depart",
		&"j7_2_match",
		&"j7_3_armes",
		&"j7_4_port",
		&"j7_5_fievre",
		&"j7_6_archives",
		&"j8_1_reveil",
		&"j8_2_archives",
		&"j8_3_duel",
		&"j8_4_cristal",
		&"j8_5_refectoire",
		&"j8_6_fugue",
		&"j8_7_barocupot",
		&"j8_8_colline",
	]:
		assert_has(ids, scene_id)
		assert_false(StoryData.scene(ISLAND, scene_id).is_empty(), "%s valide" % scene_id)
	assert_eq(StoryData.day_data(ISLAND, 7).get("sleep_after"), ["j7_6_archives"])
	assert_eq(StoryData.day_data(ISLAND, 8).get("sleep_after"), ["j8_8_colline"])
	for scene_id: StringName in [&"j7_6_archives", &"j8_8_colline"]:
		var kinds: Array[String] = []
		for step: Dictionary in StoryData.scene(ISLAND, scene_id)["steps"]:
			kinds.append(str(step["do"]))
		assert_has(kinds, "calendar", "%s écrit la ligne du jour" % scene_id)
		assert_has(kinds, "next_day", "%s ouvre le jour suivant" % scene_id)
	for day: int in [7, 8]:
		assert_ne(
			StoryData.raw_text(ISLAND, "days/%d/calendar" % day), "", "ligne du jour %d" % day
		)
	assert_eq(StoryData.all_problems(ISLAND), PackedStringArray())


func test_hints_are_short_and_never_name_the_heroine() -> void:
	var texts := StoryData.texts(ISLAND)
	for scene_id: String in texts:
		if not scene_id.begins_with("j7_") and not scene_id.begins_with("j8_"):
			continue
		for key: String in texts[scene_id]:
			var text := str(texts[scene_id][key])
			assert_false(text.contains("Chtholly"), "%s/%s : {player}" % [scene_id, key])
			if key.begins_with("hint"):
				assert_lte(text.length(), 60, "%s/%s : 60 signes au plus" % [scene_id, key])
