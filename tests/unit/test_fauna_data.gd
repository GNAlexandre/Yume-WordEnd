extends GutTest
## (E5) Format des données de la faune : une espèce par fichier data/fauna/ile_68/<id>.tres
## (AnimalData), ses planches de remplacement (assets/fauna/<id>/, 96 px par mètre, animations du
## cahier n° 5), ses attaques, et le peuplement (peuplement.json) que FaunaRules vérifie.

const ISLAND := &"ile_68"
const SPECIES: Array[StringName] = [
	&"bear",
	&"blackbird",
	&"boar",
	&"butterfly",
	&"crow",
	&"deer",
	&"dragonfly",
	&"fox",
	&"frog",
	&"owl",
	&"squirrel",
	&"wolf",
]
## Hauteur au repos (m) du cahier n° 5, section 7.3.
const HEIGHTS := {
	&"bear": 1.2,
	&"boar": 0.9,
	&"crow": 0.4,
	&"deer": 1.9,
	&"fox": 0.45,
	&"frog": 0.12,
	&"owl": 0.4,
	&"squirrel": 0.25,
	&"wolf": 0.85,
	&"blackbird": 0.2,
}
## Animations exigées par comportement (docs/REFONTE.md, 8.1).
const ANIMATIONS := {
	&"dangereux": [&"repos", &"marche", &"course", &"attaque", &"degats", &"mort"],
	&"paisible": [&"repos"],
	&"fuyard": [&"repos", &"fuite"],
}


func before_each() -> void:
	FaunaRules.clear_cache()


func after_each() -> void:
	FaunaRules.clear_cache()


func test_every_species_has_a_file() -> void:
	assert_eq(
		FaunaRules.species_ids(ISLAND), SPECIES, "les douze espèces de l'île, ni plus ni moins"
	)
	for id: StringName in SPECIES:
		var data := FaunaRules.species(ISLAND, id)
		assert_not_null(data, "%s : AnimalData" % id)
		if data != null:
			assert_eq(data.id, id, "%s : id = nom du fichier" % id)
			assert_ne(data.display_name, "", "%s : un nom affiché" % id)
			assert_true(data.behavior in AnimalData.BEHAVIORS, "%s : comportement" % id)


func test_the_island_rules_list_every_species() -> void:
	var allowed := WorldAtlas.rules_of_island(ISLAND).fauna
	for id: StringName in SPECIES:
		assert_true(id in allowed, "%s : permise par rules.fauna de l'île n° 68" % id)
	assert_eq(allowed.size(), SPECIES.size(), "et rien de plus")


func test_data_and_population_have_no_problem() -> void:
	var problems := FaunaRules.problems(ISLAND)
	assert_eq(problems.size(), 0, "; ".join(problems))


func test_behaviors_match_the_lore() -> void:
	var expected := {
		&"bear": &"dangereux",
		&"wolf": &"dangereux",
		&"boar": &"dangereux",
		&"deer": &"paisible",
		&"crow": &"paisible",
		&"owl": &"paisible",
		&"fox": &"fuyard",
		&"squirrel": &"fuyard",
		&"frog": &"fuyard",
		&"blackbird": &"fuyard",
		&"butterfly": &"ambiant",
		&"dragonfly": &"ambiant",
	}
	for id: StringName in expected:
		assert_eq(FaunaRules.species(ISLAND, id).behavior, expected[id], "%s : comportement" % id)
	for id: StringName in [&"blackbird", &"crow", &"owl"]:
		assert_true(FaunaRules.species(ISLAND, id).flies, "%s : un oiseau s'envole" % id)
	for id: StringName in [&"bear", &"wolf", &"boar", &"deer", &"fox", &"squirrel", &"frog"]:
		assert_false(FaunaRules.species(ISLAND, id).flies, "%s : il ne vole pas" % id)


func test_combat_numbers_live_in_the_data() -> void:
	var wolf := FaunaRules.species(ISLAND, &"wolf")
	var boar := FaunaRules.species(ISLAND, &"boar")
	var bear := FaunaRules.species(ISLAND, &"bear")
	# docs/lore/ACTE1.md, 3.5 : un loup touché trois fois s'enfuit, le sanglier quatre, l'ours dix.
	assert_eq([wolf.max_hp, boar.max_hp, bear.max_hp], [3, 4, 10], "coups avant la fuite")
	assert_eq(_melee_damage(wolf), 1, "loup : dégâts 1")
	assert_eq(_melee_damage(boar), 1, "sanglier : dégâts 1")
	assert_eq(_melee_damage(bear), 2, "ours : dégâts 2")
	assert_almost_eq(
		bear.leash_m, 15.0, 0.01, "l'ours ne poursuit pas au-delà de 15 m de sa tanière"
	)
	assert_almost_eq(boar.stun_s, 2.0, 0.01, "le sanglier reste étourdi 2 s")
	assert_true(boar.rush, "le sanglier charge")
	assert_true(bear.stoic, "l'ours ne recule pas sous l'épée")
	assert_true(wolf.ring_radius_m > 0.0, "la meute encercle")
	assert_true(
		wolf.active_at(&"couchant") and wolf.active_at(&"nuit"), "dehors au crépuscule et la nuit"
	)
	assert_false(wolf.active_at(&"matin"), "caché le jour")
	for attack: AttackData in bear.attacks:
		assert_almost_eq(attack.windup, 0.8, 0.01, "l'ours : annonce 0,8 s")
	for attack: AttackData in wolf.attacks:
		if attack.damage <= 0:
			assert_almost_eq(attack.windup, 0.5, 0.01, "le loup se ramasse 0,5 s avant son bond")
	for attack: AttackData in boar.attacks:
		if attack.damage <= 0:
			assert_almost_eq(attack.windup, 1.0, 0.01, "le sanglier gratte le sol 1 s")


func _melee_damage(data: AnimalData) -> int:
	for attack: AttackData in data.attacks:
		if attack.damage > 0:
			return attack.damage
	return 0


func test_sheets_follow_the_format_of_the_characters() -> void:
	for id: StringName in HEIGHTS:
		var data := FaunaRules.species(ISLAND, id)
		assert_not_null(data.visual, "%s : planche" % id)
		assert_almost_eq(
			data.visual.height_m, float(HEIGHTS[id]), 0.001, "%s : hauteur au repos" % id
		)
		var sheet := SheetLoader.read_sheet(data.visual)
		var animations: Dictionary = sheet.get("animations", {})
		for anim: StringName in ANIMATIONS[data.behavior]:
			if id == &"owl" and anim != &"repos" and anim != &"fuite":
				continue
			assert_true(animations.has(String(anim)), "%s : animation %s" % [id, anim])
		if data.is_dangerous():
			var attack: Dictionary = animations["attaque"]
			assert_eq(
				int((attack["coup"] as Array)[0]),
				2,
				"%s : « coup » sur l'image 2 de l'attaque" % id
			)
			assert_eq((attack["images"] as Array).size(), 4, "%s : attaque en 4 images" % id)
			assert_eq(
				(animations["mort"]["images"] as Array).size(), 2, "%s : mort en 2 images" % id
			)
		for anim_name: String in animations:
			var info: Dictionary = animations[anim_name]
			assert_true(float(info["ips"]) > 0.0, "%s/%s : cadence" % [id, anim_name])
			assert_true((info["images"] as Array).size() > 0, "%s/%s : images" % [id, anim_name])


func test_bird_and_frog_hops_have_four_images() -> void:
	for id: StringName in [&"blackbird", &"crow", &"frog"]:
		var animations: Dictionary = (
			SheetLoader.read_sheet(FaunaRules.species(ISLAND, id).visual)["animations"]
		)
		for anim: String in ["marche", "course", "fuite"]:
			assert_eq(
				(animations[anim]["images"] as Array).size(), 4, "%s/%s : 4 images" % [id, anim]
			)


func test_ambient_species_name_a_strip() -> void:
	for id: StringName in [&"butterfly", &"dragonfly"]:
		var data := FaunaRules.species(ISLAND, id)
		assert_not_null(data.ambient_texture, "%s : bande animée" % id)
		assert_false(data.has_body(), "%s : pas de corps" % id)
		assert_eq(
			data.ambient_texture.get_width() % data.ambient_frames,
			0,
			"%s : images côte à côte" % id
		)
		assert_true(data.ambient_weather.has(&"clair"), "%s : par beau temps seulement" % id)


func test_entry_format_is_checked() -> void:
	var good := {"id": "cerfs", "species": "deer", "count": 2.0, "at": "cerfs"}
	assert_eq(FaunaRules.entry_problem(good), "")
	assert_eq(
		FaunaRules.entry_problem(
			{"id": "a", "species": "deer", "count": 1.0, "rect": [0.0, 0.0, 4.0, 4.0]}
		),
		""
	)
	var bad: Array[Dictionary] = [
		{"id": "x", "species": "deer", "count": 1.0},
		{"id": "x", "species": "deer", "count": 1.0, "at": "a", "rect": [0.0, 0.0, 1.0, 1.0]},
		{"id": "X", "species": "deer", "count": 1.0, "at": "a"},
		{"id": "x", "species": "deer", "count": 0.0, "at": "a"},
		{"id": "x", "species": "deer", "count": 1.0, "at": "a", "momentum": []},
		{"id": "x", "species": "deer", "count": 1.0, "at": "a", "moments": ["minuit"]},
		{"id": "x", "species": "deer", "count": 1.0, "at": "a", "weather": ["neige"]},
		{"id": "x", "species": "deer", "count": 1.0, "rect": [0.0, 0.0, 1.0]},
		{"id": "x", "species": "deer", "count": 1.0, "at": "a", "radius": 0.0},
	]
	for entry: Dictionary in bad:
		assert_ne(FaunaRules.entry_problem(entry), "", "refusé : %s" % entry)
	var commented := good.duplicate()
	commented["_note"] = "commentaire"
	assert_eq(FaunaRules.entry_problem(commented), "", "une clé _… est un commentaire")


func test_every_placed_marker_exists_on_the_map() -> void:
	for map_key: String in FaunaRules.population(ISLAND)["maps"] as Dictionary:
		var map := (load(Map.scene_path(StringName(map_key))) as PackedScene).instantiate() as Map
		add_child_autofree(map)
		assert_not_null(
			map.get_node_or_null(^"Life/Fauna"), "%s : un nœud Fauna sous Life" % map_key
		)
		for entry: Dictionary in FaunaRules.entries_for(StringName(map_key)):
			if entry.has("at"):
				var marker := map.find_child(str(entry["at"]), true, false)
				assert_true(
					marker is Marker3D,
					"%s/%s : marqueur « %s »" % [map_key, entry["id"], entry["at"]]
				)
