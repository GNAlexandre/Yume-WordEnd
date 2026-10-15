extends GutTest
## (V1) La vie de l'entrepôt sur les vraies cartes (data/life/ile_68/, docs/lore/VIE.md), dans
## game.tscn
## (WorldManager.enter_map) : à chaque créneau, le directeur peuple chaque carte (chacun à sa
## place, déjà
## en activité, sans personne coincé) ; en changeant de créneau, les PNJ marchent vers leurs
## places par
## les portes et les escaliers, sans se replacer d'un coup ; les jeux des petites sont aux bons
## endroits
## (le chat dans les hautes herbes, la course du couloir, l'avalanche à la porte de Nygglatho, la
## tour sur
## Willem, l'escalade du grand arbre) ; les variations par jour et par temps changent la journée.

const GAME_SCENE := preload("res://src/game.tscn")
const RDC := &"entrepot_rdc"
const ETAGE := &"entrepot_etage"
const TOIT := &"entrepot_toit"
const DEHORS := &"entrepot"
const MAPS: Array[StringName] = [RDC, ETAGE, TOIT, DEHORS]
## Allure du temps pendant les attentes : les trajets se jouent plus vite que l'horloge.
const TIME_SCALE := 4.0
## Un PNJ qui avance de plus que ceci en une image physique a été replacé d'un coup (m).
const JUMP := 0.5

var _game: Node3D
var _player: Player
var _previous_scale: float = 1.0


func before_each() -> void:
	GameState.reset()
	LifeData.use_content(&"")  # le contenu de l'île de la carte : le chemin de la vraie partie
	WorldManager.fade_time = 0.0
	_previous_scale = Engine.time_scale
	_game = GAME_SCENE.instantiate() as Node3D
	add_child(_game)
	_player = _game.get_node(^"Player") as Player
	await wait_physics_frames(2)


func after_each() -> void:
	Engine.time_scale = _previous_scale
	WorldManager.fade_time = WorldManager.DEFAULT_FADE_TIME
	_game.queue_free()
	await wait_physics_frames(2)
	LifeDirector.attach(null)
	Atmosphere.dress(null)
	GameState.reset()
	LifeData.use_content(&"")


func _enter(map_id: StringName, slot: StringName, day: int = 0, at: Vector3 = Vector3.INF) -> void:
	GameState.day = day
	LifeDirector.set_slot(slot, 0.0)
	assert_true(WorldManager.enter_map(map_id), "carte %s" % map_id)
	LifeDirector.build_nav_now()
	if at != Vector3.INF:
		_player.global_position = at
		_player.velocity = Vector3.ZERO


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _until(predicate: Callable, seconds: float) -> bool:
	var frames := ceili(seconds * Engine.physics_ticks_per_second)
	for _i: int in frames:
		if predicate.call():
			return true
		await wait_physics_frames(1)
	return predicate.call()


func _ids() -> Array[String]:
	var ids: Array[String] = []
	for who: LifeActor in LifeDirector.actors():
		ids.append(String(who.id))
	ids.sort()
	return ids


func test_every_slot_populates_every_map() -> void:
	var seen := {}
	for slot: StringName in GameState.SLOTS:
		for map_id: StringName in MAPS:
			_enter(map_id, slot)
			var actors := LifeDirector.actors()
			seen["%s/%s" % [map_id, slot]] = actors.size()
			for who: LifeActor in actors:
				var tag := "%s/%s : %s" % [map_id, slot, who.id]
				assert_eq(who.line["map"], map_id, "%s : sa ligne est ici" % tag)
				if not who.activity.get("wander", false):
					assert_lt(_flat(who.position(), who.spot.origin), 0.05, "%s : à sa place" % tag)
				assert_not_null(who.npc, "%s : posé dans Life" % tag)
				assert_eq(who.npc.get_parent().name, "Life", "%s : dans le nœud Life" % tag)
				assert_false(
					who.activity.is_empty(), "%s : une activité (%s)" % [tag, who.activity_id]
				)
			# Personne n'est posé dans un mur ou hors de la carte.
			var nav := LifeDirector.nav()
			for who: LifeActor in actors:
				var at := who.position()
				var seated := (
					who.activity_id
					in [&"manger", &"lire", &"dormir", &"regarder", &"jouer", &"jardiner"]
				)
				if not seated and not String(who.place).begins_with("arbre_"):
					assert_true(
						nav.is_walkable_point(at.x, at.z),
						"%s/%s : %s marche sur du sol libre" % [map_id, slot, who.id]
					)
	gut.p("peuplement : %s" % seen)
	# Le petit-déjeuner et le déjeuner remplissent le réfectoire ; la nuit, les dortoirs.
	assert_gte(seen["%s/matin" % RDC], 10, "le petit-déjeuner au réfectoire")
	assert_gte(seen["%s/midi" % RDC], 18, "le déjeuner : presque toute la maison")
	assert_gte(seen["%s/nuit" % ETAGE], 15, "la nuit, les petites couchées dans leurs lits")
	assert_gte(seen["%s/apres_midi" % DEHORS], 8, "l'après-midi, la cour et les hautes herbes")
	assert_gte(seen["%s/aube" % TOIT], 2, "le linge sur le toit à l'aube")


func test_nobody_is_stuck_when_the_slot_changes_three_times() -> void:
	Engine.time_scale = TIME_SCALE
	_enter(RDC, &"aube", 0, Vector3(13.0, 0.0, 9.5))
	var last := {}
	var jumps: Array[String] = []
	for slot: StringName in [&"matin", &"midi", &"apres_midi"]:
		LifeDirector.set_slot(slot, 0.0)
		await wait_physics_frames(2)
		var done := false
		var frames := 0
		while not done and frames < 90 * 60:
			await wait_physics_frames(1)
			frames += 1
			done = true
			for who: LifeActor in LifeDirector.actors():
				var at := who.position()
				if last.has(who.id) and _flat(last[who.id], at) > JUMP:
					jumps.append(
						"%s (%s) : %.1f m d'un coup" % [who.id, slot, _flat(last[who.id], at)]
					)
				last[who.id] = at
				if who.is_moving():
					done = false
		assert_true(done, "%s : tout le monde est arrivé" % slot)
		for who: LifeActor in LifeDirector.actors():
			assert_eq(who.line["map"], RDC, "%s : %s est ici" % [slot, who.id])
			if not who.activity.get("wander", false):
				assert_lt(
					_flat(who.position(), who.spot.origin),
					0.6,
					"%s : %s à sa place" % [slot, who.id]
				)
	assert_eq(
		jumps, [] as Array[String], "personne n'a été replacé d'un coup : %s" % "\n".join(jumps)
	)
	# Au bout des trois changements, l'après-midi : Nephren à la lecture, plus personne au réfectoire.
	assert_eq(LifeDirector.where(&"nephren")["place"], &"lecture_fauteuil")
	assert_null(LifeDirector.actor(&"tiat"), "Tiat est sortie jouer dans les hautes herbes")


func test_people_use_the_stairs_and_the_front_door() -> void:
	Engine.time_scale = TIME_SCALE
	# Du dortoir (étage) au réfectoire (rez-de-chaussée) : par l'escalier ; on les voit arriver au
	# pied.
	_enter(RDC, &"aube", 0, Vector3(13.0, 0.0, 9.5))
	assert_null(LifeDirector.actor(&"fairy_03"), "à l'aube, fairy_03 dort à l'étage")
	LifeDirector.set_slot(&"matin", 0.0)
	assert_true(
		await _until(func() -> bool: return LifeDirector.actor(&"fairy_03") != null, 20.0),
		"fairy_03 descend l'escalier"
	)
	var arriving := LifeDirector.actor(&"fairy_03")
	var stairs := LifeDirector.places().point(&"vers_entrepot_etage", 0).origin
	assert_lt(_flat(arriving.position(), stairs), 4.0, "elle arrive au pied de l'escalier")
	# Du réfectoire au dehors : par la porte d'entrée.
	LifeDirector.set_slot(&"apres_midi", 0.0)
	var door := LifeDirector.places().point(&"vers_entrepot", 0).origin
	var tiat := LifeDirector.actor(&"tiat")
	assert_not_null(tiat)
	var closest := 1000.0
	for _i: int in 60 * 40:
		await wait_physics_frames(1)
		if tiat.state == LifeActor.State.GONE:
			break
		closest = minf(closest, _flat(tiat.position(), door))
	assert_eq(tiat.state, LifeActor.State.GONE, "Tiat sort")
	assert_lt(closest, 1.0, "par la porte d'entrée (%.2f m)" % closest)


func test_the_cat_plays_in_the_tall_grass() -> void:
	_enter(DEHORS, &"apres_midi", 0, Vector3(30.0, 0.0, 40.0))
	var chat := LifeDirector.game_at(&"chat", &"herbes_chat")
	assert_not_null(chat, "le chat dans les hautes herbes du coin au soleil")
	assert_true(chat.running)
	assert_gte(chat.members.size(), 5, "Tiat, Collon et les fées du chat")
	for member: LifeActor in chat.members:
		assert_between(member.position().x, 16.0, 28.0, "%s dans le coin d'herbe" % member.id)
		assert_between(member.position().z, 30.0, 37.0, "%s dans le coin d'herbe" % member.id)


func test_the_big_tree_scene_has_climbers_at_the_foot_and_in_the_tree() -> void:
	_enter(DEHORS, &"matin", 0, Vector3(60.0, 0.0, 40.0))
	var heights := {}
	for who: LifeActor in LifeDirector.actors():
		if who.activity_id == &"grimper":
			heights[who.id] = (
				who.position().y - LifeDirector.nav().height_at(who.position().x, who.position().z)
			)
	assert_has(heights, &"collon", "Collon grimpe")
	assert_has(heights, &"pannibal", "Pannibal grimpe")
	assert_has(heights, &"lakhesh", "Lakhesh tremble sur la branche basse")
	assert_gt(
		heights[&"collon"], heights[&"pannibal"], "Collon tout en haut, Pannibal à mi-hauteur"
	)
	assert_gt(heights[&"pannibal"], heights[&"lakhesh"], "Lakhesh sur la branche basse")
	var foot := 0
	for id: StringName in heights:
		if heights[id] < 0.5:
			foot += 1
	assert_gte(foot, 1, "des fées en grimpe au pied de l'arbre")
	for who: LifeActor in LifeDirector.actors():
		if who.activity_id == &"grimper":
			assert_eq(who.npc.visual.current_animation(), &"grimpe", "%s grimpe" % who.id)


func test_the_corridor_race_and_the_tower() -> void:
	Engine.time_scale = TIME_SCALE
	_enter(RDC, &"soir", 0, Vector3(13.0, 0.0, 13.0))
	var race := LifeDirector.game_at(&"course", &"couloir_course")
	assert_not_null(race, "la course du couloir")
	assert_eq(race.with_role(&"gronde").size(), 1, "Nygglatho gronde")
	assert_gte(race.runners().size(), 4, "quatre coureuses au moins")
	var tour := LifeDirector.game_at(&"tour", &"jeux_tour")
	assert_not_null(tour, "la tour de fées dans la salle de jeux")
	assert_eq(tour.base_actor().id, &"willem", "Willem est la base")
	assert_true(
		await _until(func() -> bool: return tour.stacked.size() >= 2, 40.0), "elles grimpent"
	)
	assert_eq(tour.stacked[0].id, &"nephren", "Nephren d'abord, collée à son dos")
	assert_true(
		await _until(func() -> bool: return race.phase == race.Phase.RUN or race.scolded, 40.0),
		"la course part"
	)


func test_the_avalanche_at_nygglatho_s_door() -> void:
	Engine.time_scale = TIME_SCALE
	_enter(ETAGE, &"apres_midi", 0, Vector3(19.4, 0.0, 9.5))
	var game := LifeDirector.game_at(&"avalanche", &"epie_nygglatho")
	assert_not_null(game, "collées à la porte de Nygglatho")
	assert_true(
		await _until(func() -> bool: return game.phase == game.Phase.SPYING, 20.0), "elles épient"
	)
	assert_ne(game.door, Vector3.INF, "la porte de la chambre")
	assert_almost_eq(game.door.x, 11.0, 0.3, "la porte de Nygglatho (x = 11)")
	_player.global_position = game.door + Vector3(0.0, 0.0, 0.8)
	await wait_physics_frames(3)
	assert_eq(game.phase, game.Phase.FALLEN, "avalanche")


func test_the_night_beds_the_lamp_and_the_archives() -> void:
	_enter(ETAGE, &"nuit")
	var sleeping := 0
	for who: LifeActor in LifeDirector.actors():
		if who.activity_id == &"dormir":
			sleeping += 1
			assert_eq(who.npc.visual.current_animation(), &"dort", "%s dort" % who.id)
			assert_gte(who.position().y, 0.4, "%s sur son lit" % who.id)
	assert_gte(sleeping, 14, "les petites couchées")
	assert_eq(
		LifeDirector.actor(&"nygglatho").place, &"nygglatho_bureau", "la lumière sous sa porte"
	)
	assert_eq(LifeDirector.where(&"willem")["place"], &"archives_bureau", "Willem aux archives")
	assert_eq(LifeDirector.where(&"ithea")["place"], &"refectoire_veillee", "la veillée des aînées")


func test_laundry_on_the_roof_at_dawn() -> void:
	_enter(TOIT, &"aube")
	var ids := _ids()
	assert_has(ids, "nygglatho", "Nygglatho monte le linge")
	assert_has(ids, "fairy_10", "une grande l'aide")
	for who: LifeActor in LifeDirector.actors():
		assert_eq(who.activity_id, &"porter_linge")


func test_days_change_the_day() -> void:
	LifeData.use_content(&"ile_68")
	# Jour 7 : les aînées sont parties ; la petite blessée est à l'infirmerie, dans son lit.
	assert_eq(LifeData.line_for(&"ithea", &"matin", 7)["away"], &"port")
	assert_eq(LifeData.line_for(&"nephren", &"nuit", 7)["away"], &"port")
	assert_eq(LifeData.line_for(&"fairy_06", &"matin", 8)["place"], &"infirmerie_lit_2")
	assert_eq(LifeData.line_for(&"fairy_06", &"midi", 10)["place"], &"refectoire_rang_c", "guérie")
	# Jour 8 : Willem malade, couché à l'infirmerie ; les petites agglutinées devant sa porte.
	assert_eq(LifeData.line_for(&"willem", &"apres_midi", 8)["place"], &"infirmerie_lit_3")
	assert_eq(LifeData.line_for(&"willem", &"apres_midi", 8)["activity"], &"dormir")
	assert_eq(LifeData.line_for(&"fairy_01", &"apres_midi", 8)["activity"], &"avalanche_infirmerie")
	# Jour 12 : toute la maison dans la cour au couchant.
	for npc_id: StringName in LifeData.cast():
		var line := LifeData.line_for(npc_id, &"soir", 12)
		if npc_id == &"nygglatho":
			assert_eq(line["place"], &"porte_seuil", "Nygglatho au porche")
		elif npc_id == &"willem":
			assert_eq(line["place"], &"cour_willem")
		else:
			assert_eq(line["place"], &"cour_cercle", "%s dans le cercle" % npc_id)
	# Jour 11 : Willem chez les Limashenka jusqu'à la 6e cloche.
	assert_eq(LifeData.line_for(&"willem", &"matin", 11)["away"], &"maison_limashenka")
	# Jours 9 à 12 : l'entraînement du matin à la clairière.
	assert_eq(LifeData.line_for(&"willem", &"matin", 9)["place"], &"clairiere_centre")
	# Lakhesh à la boulangerie dès le jour 3.
	assert_eq(LifeData.line_for(&"lakhesh", &"aube", 3)["away"], &"ville_boulangerie")
	assert_eq(LifeData.line_for(&"lakhesh", &"aube", 2)["place"], &"eau_toilette")


func test_rain_brings_everyone_inside_and_mud_follows() -> void:
	Engine.time_scale = TIME_SCALE
	_enter(DEHORS, &"apres_midi", 0, Vector3(30.0, 0.0, 40.0))
	var outside := LifeDirector.actors().size()
	assert_gte(outside, 8)
	# Il pleut : les petites rentrent (la salle de jeux, la lecture).
	Atmosphere.set_weather(&"pluie", 0.0)
	await wait_physics_frames(2)
	assert_true(GameState.has_flag(LifeDirector.RAIN_FLAG), "le drapeau de la pluie")
	assert_true(
		await _until(func() -> bool: return LifeDirector.actors().size() < outside, 15.0),
		"dehors, on part"
	)
	assert_true(
		await _until(func() -> bool: return LifeDirector.actors().size() <= 3, 60.0),
		"dehors, presque personne sous la pluie (%d)" % LifeDirector.actors().size()
	)
	assert_eq(
		LifeData.line_for(&"tiat", &"apres_midi", 0)["place"], &"jeux_societe", "Tiat aux jeux"
	)
	# Elle cesse : la boue du champ, les petites sautent dans les flaques.
	Atmosphere.set_weather(&"clair", 0.0)
	await wait_physics_frames(2)
	assert_false(GameState.has_flag(LifeDirector.RAIN_FLAG))
	assert_true(GameState.has_flag(LifeDirector.AFTER_RAIN_FLAG), "après la pluie")
	assert_eq(LifeData.line_for(&"tiat", &"apres_midi", 0)["activity"], &"boue")
	assert_true(
		await _until(
			func() -> bool:
				return LifeDirector.game_at(&"boue", &"champ_boue") == null and _mud() >= 5,
			60.0
		),
		"la boue : on revient jouer dehors"
	)
	# À l'aube suivante, la boue est oubliée.
	LifeDirector.set_slot(&"aube", 0.0)
	await wait_physics_frames(2)
	assert_false(GameState.has_flag(LifeDirector.AFTER_RAIN_FLAG), "plus de boue à l'aube")


func _mud() -> int:
	var count := 0
	for who: LifeActor in LifeDirector.actors():
		if who.activity_id == &"boue":
			count += 1
	return count
