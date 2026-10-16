extends GutTest
## (X-L1) Les propositions du mode libre, sans lancer le jeu : l'ancre de chaque tête de l'île
## n° 68 se résout à chaque créneau permis (les emplois du temps de la vie, LifeData), les règles
## de l'ancre (clé « offer », talk, reach, prompt, enter, ready, PNJ absent), les conditions, et le
## signe du récit (InteractSign.STORY).

const ISLAND := &"ile_68"


func before_each() -> void:
	StoryData.use_root("")
	GameState.reset()
	LifeData.enter_island(ISLAND)


func after_each() -> void:
	StoryData.use_root("")
	GameState.reset()
	LifeData.enter_island(&"")


## Carte d'un PNJ au jour et au créneau donnés (emplois du temps, conditions de la partie).
func _where(day: int, slot: StringName) -> Callable:
	return func(npc_id: StringName) -> StringName:
		return LifeData.line_for(npc_id, slot, day).get("map", &"")


## Partie libre où les scènes d'avant celle-ci (ses « after ») sont jouées.
func _prepare(data: Dictionary) -> void:
	GameState.reset()
	StoryPacing.store(StoryPacing.FREE)
	for scene_id: String in StoryOffers._names(data.get("after", [])):
		GameState.mark_scene_done(StringName(scene_id))


func _first_day(data: Dictionary) -> int:
	return DialogueRunner.day_range(data.get("day", 1)).x


func test_every_head_has_an_anchor_at_every_allowed_slot() -> void:
	var heads := 0
	for scene_id: StringName in StoryData.scene_ids(ISLAND):
		var data := StoryData.scene(ISLAND, scene_id)
		if StoryPacing.is_chained(data):
			continue
		heads += 1
		_prepare(data)
		var day := _first_day(data)
		for slot: StringName in StoryOffers.slots_of(data):
			var anchor := StoryOffers.anchor_for(data, _where(day, slot))
			assert_false(anchor.is_empty(), "%s : une ancre au jour %d, %s" % [scene_id, day, slot])
			if anchor.is_empty():
				continue
			var map_id: StringName = anchor["map"]
			assert_true(Map.exists(map_id), "%s : %s est une carte" % [scene_id, map_id])
			if anchor.has("point") and anchor["point"] is String:
				var point := StringName(str(anchor["point"]))
				assert_true(
					(
						LifeData.map_places(map_id).has(String(point))
						or WorldAtlas.scene_markers(map_id).has(point)
					),
					"%s : %s est une place ou un marqueur de %s" % [scene_id, point, map_id]
				)
	assert_eq(heads, 35, "35 têtes (docs : PLAN.md, « (X) »)")


func test_the_book_anchors_asked_for() -> void:
	var port := StoryData.scene(ISLAND, &"j1_1_port")
	_prepare(port)
	for slot: StringName in GameState.SLOTS:
		assert_eq(
			StoryOffers.anchor_for(port, _where(1, slot)),
			{"npc": &"nygglatho", "map": &"entrepot"},
			"le port est proposé par Nygglatho sous le porche (%s)" % slot
		)
	assert_eq(
		LifeData.line_for(&"nygglatho", &"soir", 1).get("place", &""),
		&"porte_seuil",
		"Nygglatho attend sous le porche le soir du jour 1, en libre"
	)
	StoryPacing.store(StoryPacing.SCENARIO)
	assert_eq(
		LifeData.line_for(&"nygglatho", &"soir", 1).get("place", &""),
		&"couloir_course",
		"en scénarisé, sa journée de base"
	)
	var sticks := StoryData.scene(ISLAND, &"j9_2_batons")
	_prepare(sticks)
	assert_eq(
		StoryOffers.anchor_for(sticks, _where(9, &"matin")),
		{"npc": &"willem", "map": &"entrepot"},
		"les bâtons : Willem, à la clairière, le matin du jour 9"
	)
	var ambush := StoryData.scene(ISLAND, &"j12_1_embuscade")
	_prepare(ambush)
	for slot: StringName in StoryOffers.slots_of(ambush):
		var anchor := StoryOffers.anchor_for(ambush, _where(12, slot))
		assert_eq(
			anchor.get("npc", &""), &"pannibal", "la dernière embuscade : Pannibal (%s)" % slot
		)


func test_anchor_rules() -> void:
	var everywhere := func(_npc_id: StringName) -> StringName: return &"entrepot"
	var nowhere := func(_npc_id: StringName) -> StringName: return &""
	var upstairs := func(npc_id: StringName) -> StringName:
		return &"entrepot" if npc_id == &"nephren" else &"entrepot_etage"
	var reach := {
		"map": "entrepot", "trigger": {"on": "reach", "point": "clairiere_centre", "radius": 4}
	}
	assert_eq(
		StoryOffers.anchor_for(reach, everywhere),
		{"point": "clairiere_centre", "map": &"entrepot"},
		"reach : le point"
	)
	var prompt := {"map": "entrepot_rdc", "trigger": {"on": "prompt", "point": [1, 2]}}
	assert_eq(StoryOffers.anchor_for(prompt, everywhere), {"point": [1, 2], "map": &"entrepot_rdc"})
	var enter := {"map": "village", "trigger": {"on": "enter", "marker": "from_entrepot"}}
	assert_eq(
		StoryOffers.anchor_for(enter, everywhere),
		{"point": "from_entrepot", "map": &"village"},
		"enter : le marqueur"
	)
	var talk := {"map": "entrepot", "trigger": {"on": "talk", "npc": "willem"}}
	assert_eq(
		StoryOffers.anchor_for(talk, everywhere),
		{"npc": &"willem", "map": &"entrepot"},
		"talk : le PNJ"
	)
	assert_eq(StoryOffers.anchor_for(talk, nowhere), {}, "talk sans PNJ ni point : aucune")
	var on_ready := {
		"map": "entrepot", "trigger": {"on": "ready"}, "present": ["willem", "nephren"]
	}
	assert_eq(
		StoryOffers.anchor_for(on_ready, upstairs),
		{"npc": &"nephren", "map": &"entrepot"},
		"ready : le premier présent sur la carte de la scène"
	)
	var elsewhere := func(_npc_id: StringName) -> StringName: return &"entrepot_rdc"
	assert_eq(
		StoryOffers.anchor_for(on_ready, elsewhere),
		{"npc": &"willem", "map": &"entrepot_rdc"},
		"ready : sinon le premier présent, ailleurs"
	)
	assert_eq(
		StoryOffers.anchor_for(on_ready, nowhere), {}, "ready sans personne ni point : aucune"
	)
	var offered := reach.duplicate(true)
	offered["offer"] = {"npc": "nygglatho", "text": "offer"}
	assert_eq(
		StoryOffers.anchor_for(offered, everywhere),
		{"npc": &"nygglatho", "map": &"entrepot"},
		"offer.npc"
	)
	assert_eq(
		StoryOffers.anchor_for(offered, nowhere),
		{"point": "clairiere_centre", "map": &"entrepot"},
		"PNJ nulle part : le point de la scène"
	)
	var placed := on_ready.duplicate(true)
	placed["offer"] = {"point": "porte_seuil", "map": "entrepot_rdc"}
	assert_eq(
		StoryOffers.anchor_for(placed, everywhere),
		{"point": "porte_seuil", "map": &"entrepot_rdc"},
		"offer.point, sur sa carte (les présents ne comptent plus)"
	)


func test_conditions() -> void:
	var data := {"day": [3, 4], "slot": ["matin", "midi"], "after": ["j1_1_port"]}
	assert_false(StoryOffers.conditions_met(data, 3, &"matin"), "après le port seulement")
	GameState.mark_scene_done(&"j1_1_port")
	assert_true(StoryOffers.conditions_met(data, 3, &"matin"))
	assert_true(StoryOffers.conditions_met(data, 4, &"midi"))
	assert_false(StoryOffers.conditions_met(data, 5, &"matin"), "jour 5 : trop tard")
	assert_false(StoryOffers.conditions_met(data, 3, &"soir"), "pas le soir")
	data["if"] = {"flag": "x_l1_essai"}
	assert_false(StoryOffers.conditions_met(data, 3, &"matin"), "« if »")
	GameState.set_flag(&"x_l1_essai", true)
	assert_true(StoryOffers.conditions_met(data, 3, &"matin"))
	assert_eq(StoryOffers.slots_of({}), GameState.SLOTS, "sans « slot » : tous les créneaux")
	assert_eq(StoryOffers.slots_of({"slot": "nuit"}), [&"nuit"] as Array[StringName])


func test_offer_texts_exist_and_old_texts_are_kept() -> void:
	for key: String in ["ui/offer_go", "ui/offer_later", "ui/offer_default"]:
		assert_ne(StoryData.raw_text(ISLAND, key), "", "texte %s" % key)
	assert_eq(StoryData.raw_text(ISLAND, "ui/offer_go"), "Allons-y")
	assert_eq(StoryData.raw_text(ISLAND, "ui/offer_later"), "Plus tard")
	for scene_id: StringName in StoryData.scene_ids(ISLAND):
		var offer: Variant = StoryData.scene(ISLAND, scene_id).get("offer")
		if offer is Dictionary and (offer as Dictionary).has("text"):
			var text := StoryData.raw_text(ISLAND, str(offer["text"]), scene_id)
			assert_ne(text, "", "%s : le texte de sa proposition" % scene_id)
	assert_eq(
		StoryData.raw_text(ISLAND, "hint", &"j9_2_batons"),
		"Willem t'attend dans la clairière.",
		"les indices d'avant ne changent pas"
	)


func test_story_sign_kind() -> void:
	var target := Node3D.new()
	add_child_autofree(target)
	assert_eq(InteractSign.kind_of(target), InteractSign.EXAMINE)
	InteractSign.set_story(target, true)
	assert_true(InteractSign.is_story(target))
	assert_eq(InteractSign.kind_of(target), InteractSign.STORY, "le ruban du récit")
	assert_true(InteractSign.KINDS.has(InteractSign.STORY))
	InteractSign.set_hidden(target, true)
	assert_eq(InteractSign.kind_of(target), &"", "caché : rien")
	InteractSign.set_hidden(target, false)
	assert_eq(InteractSign.kind_of(target), InteractSign.STORY)
	InteractSign.set_story(target, false)
	assert_eq(InteractSign.kind_of(target), InteractSign.EXAMINE, "rendu")
