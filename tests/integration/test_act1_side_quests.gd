extends "res://tests/stubs/m2_game_test.gd"
## Acte 1, intégration : les six quêtes secondaires (HISTOIRE.md 3.2) jouées l'une après l'autre
## dans la vraie partie (main.tscn, nouvelle partie au menu), avec ce que l'île contient vraiment :
## les PNJ posés dans leurs zones et présents selon l'histoire (visible_if), abordés de face et
## E (invite « Parler ») ; les objets uniques des fichiers d'emplacement, ramassés en marchant
## dessus (Z/W) ; les deux veilles du registre de Tiat jouées au Couchant (cloche, vagues, sortie
## du cercle, écran de fin). Le joueur est posé près de chaque lieu (les trajets sont couverts par
## test_m2_world.gd et test_m1_world.gd) ; les répliques et les choix passent par
## dialogue_choice_made, comme la boîte de dialogue les envoie (les appuis réels qui les lisent
## sont couverts par test_m2_quest.gd), dans l'ordre des scénarios tests/unit/test_act1_*.gd.
## Les rejetons des bois sont immobilisés et les Timeres des veilles abattus d'office. À la fin :
## les six quêtes terminées, leurs souvenirs dans l'inventaire, 7 PV max et sept cœurs.

const BELL_FRONT := Vector3(10.6, 0.0, -2.0)
## Récompenses des six quêtes (objets) et drapeaux de fin.
const KEEPSAKES: Array[StringName] = [
	&"picture_book",
	&"dessert_cup",
	&"cheesecake_slice",
	&"pressed_forget_me_not",
	&"rami_card",
	&"tiat_drawing",
]
const END_FLAGS: Array[StringName] = [
	&"book_read",
	&"little_ones_trust_willem",
	&"laundry_done",
	&"forget_me_nots_given",
	&"rami_clock_fixed",
	&"vigil_record",
]

var _lines: Array[String] = []


func _listen_dialogues() -> void:
	_lines.clear()
	listen(
		EventBus.dialogue_line,
		func(_speaker: String, text: String, _choices: Array[String]) -> void: _lines.append(text)
	)


# --- PNJ et objets -----------------------------------------------------------------------------


## PNJ posé dans la zone (fichier d'emplacement : NPCs/<nom>).
func _npc(zone_id: StringName, node_name: String) -> Npc:
	return zone(zone_id).get_node(NodePath("NPCs/" + node_name)) as Npc


## Joueur posé à 1,6 m du PNJ (côté centre de sa zone), face à lui : invite « Parler », E ; puis
## les réponses (-1 : suite, sinon le rang du choix), et la suite jusqu'à la fin de la
## conversation. Renvoie les répliques affichées.
func _talk(zone_id: StringName, node_name: String, answers: Array[int]) -> Array[String]:
	var npc := _npc(zone_id, node_name)
	assert_true(npc.is_present(), "%s est là" % node_name)
	var local := zone(zone_id).to_local(npc.global_position)
	var away := Vector3(-local.x, 0.0, -local.z).normalized()
	var start := local + away * 1.6
	start.y = local.y - 0.2
	await place_player(zone_id, start, local - start)
	await wait_seconds(0.35)
	assert_eq(player.current_interactable(), npc, "invite devant %s" % node_name)
	assert_eq(player.current_prompt(), "Parler")
	_lines.clear()
	await tap_key(KEY_E)
	assert_true(DialogueRunner.is_any_running(), "conversation avec %s" % node_name)
	for answer: int in answers:
		EventBus.dialogue_choice_made.emit(answer)
	for _rest in 12:
		if not DialogueRunner.is_any_running():
			break
		EventBus.dialogue_choice_made.emit(-1)
	assert_false(DialogueRunner.is_any_running(), "fin de la conversation avec %s" % node_name)
	await wait_physics_frames(2)
	return _lines.duplicate()


## L'objet unique node_name de la zone, ramassé en marchant dessus (vers lui, depuis 1,5 m côté
## centre de la zone, ou depuis le décalage local `from` s'il est donné).
func _pick(zone_id: StringName, node_name: String, from := Vector3.ZERO) -> void:
	var pickup := zone(zone_id).get_node(NodePath("Pickups/" + node_name)) as Pickup
	assert_not_null(pickup, "%s est dans l'île" % node_name)
	if pickup == null:
		return
	var item_id := pickup.item_id
	var before := GameState.count(item_id)
	var local := zone(zone_id).to_local(pickup.global_position)
	var away := Vector3(-local.x, 0.0, -local.z).normalized()
	var start := local + (from if from != Vector3.ZERO else away * 1.5)
	await place_player(zone_id, start, local - start)
	var taken: bool = await walk_aim_until(
		func() -> bool: return GameState.count(item_id) > before, 3.0
	)
	assert_true(taken, "%s ramassé en marchant dessus" % node_name)


func _step(quest_id: StringName) -> StringName:
	return GameState.quest_step(quest_id)


# --- Veille ------------------------------------------------------------------------------------


## Abat d'office les Timeres vivants de la veille en cours.
func _strike_the_wave() -> void:
	for enemy: Enemy in director.alive_enemies():
		if is_instance_valid(enemy) and not enemy.is_dead():
			enemy.health.take_damage(enemy.health.current, player)


## Une veille : la cloche (E), vagues accélérées abattues jusqu'à done ; puis sortie du cercle à
## l'est (Z/W) : écran de fin, « Continuer » (Entrée).
func _vigil(done: Callable) -> void:
	director.set_config(fast_waves())
	await place_player(&"dunes", BELL_FRONT, Vector3.LEFT)
	await tap_key(KEY_E)
	assert_true(director.is_running(), "la cloche lance la veille")
	var held: bool = await until(
		func() -> bool:
			_strike_the_wave()
			return done.call(),
		40.0
	)
	assert_true(held, "veille tenue")
	player.set_aim_direction(Vector3.RIGHT, true)
	await wait_physics_frames(2)
	var left: bool = await walk_aim_until(
		func() -> bool:
			_strike_the_wave()
			return arena_end.call(&"is_open"),
		6.0
	)
	assert_true(left, "sortie du cercle : fin de la veille")
	await tap_key(KEY_ENTER)
	assert_false(arena_end.call(&"is_open"), "« Continuer »")


# --- Parcours ----------------------------------------------------------------------------------


func test_the_six_side_quests_in_the_real_game() -> void:
	assert_true(await new_game_from_menu(), "nouvelle partie")
	_listen_dialogues()
	# Les rejetons des bois sont immobilisés à l'écart des pages de la clairière.
	var aside := 0.0
	for child: Node in zone(&"forest").get_node(^"Enemies").get_children():
		if child is Enemy:
			(child as Enemy).set_physics_process(false)
			(child as Enemy).global_position = zone(&"forest").to_global(
				Vector3(5 + aside, 0.2, 10)
			)
			aside += 1.5
	# L'acte 1 ouvre les quêtes secondaires : Nygglatho, puis Willem salué.
	await _talk(&"village", "Nygglatho", [-1, -1, -1, -1, 0, -1])
	await _talk(&"village", "Willem", [-1, 0, -1, 0, -1, -1])
	assert_true(GameState.has_flag(&"met_willem"), "Willem salué")
	for quest_id: StringName in [&"picture_book", &"special_dessert", &"flying_laundry"]:
		assert_eq(QuestData.state_of(quest_id), &"available", "%s à prendre" % quest_id)
	assert_eq(QuestData.state_of(&"old_clock"), &"available")

	# 1. Le livre d'images : Nephren, cinq pages des bois, la lecture de Willem.
	await _talk(&"village", "Nephren", [-1, 0, -1])
	assert_eq(_step(&"picture_book"), &"pages")
	for n: int in range(1, 6):
		await _pick(&"forest", "forest_page_%d" % n)
	await _talk(&"village", "Nephren", [-1, -1, -1])
	assert_eq(_step(&"picture_book"), &"reading")
	var said := await _talk(&"village", "Willem", [-1, -1, -1, -1, -1, -1])
	assert_true(said.any(func(t: String) -> bool: return t.contains("emnetwiht")), "la lecture")
	assert_eq(GameState.quest_state(&"picture_book"), &"done")

	# 2. Le dessert spécial : Willem, les œufs du marché, trois grappes, la crème du café, Willem
	# cuisine, les petites dans le grand arbre, Lakhesh au réfectoire.
	await wait_seconds(0.4)
	await _talk(&"village", "Willem", [-1, 0, -1])
	assert_eq(_step(&"special_dessert"), &"eggs")
	await _talk(&"beach", "EggVendor", [0, -1])
	assert_eq(GameState.count(&"eggs"), 1, "les œufs")
	for n: int in range(1, 4):
		await _pick(&"forest", "forest_berries_%d" % n)
	assert_eq(_step(&"special_dessert"), &"cream")
	await _talk(&"beach", "CatWaiter", [])
	assert_eq(_step(&"special_dessert"), &"cook", "la crème")
	await _talk(&"village", "Willem", [-1, -1, -1])
	assert_eq(_step(&"special_dessert"), &"hiding")
	await _talk(&"village", "Collon", [-1, -1, -1, -1])
	await _talk(&"village", "Lakhesh", [-1, -1, -1, -1, -1])
	assert_eq(GameState.quest_state(&"special_dessert"), &"done")

	# 3. Le linge envolé : cinq draps, du port à la colline ; le thé chez Nygglatho.
	await _talk(&"village", "Nygglatho", [-1, 0, -1])
	assert_eq(_step(&"flying_laundry"), &"sheets")
	for spot: Array in [
		[&"forest", "forest_sheet_1"],
		[&"dunes", "dunes_sheet_1"],
		[&"beach", "beach_sheet_1"],
		[&"beach", "beach_sheet_2"],
	]:
		await _pick(spot[0], spot[1])
	# Le drap du belvédère, à son entrée (ouest) : on y arrive par le chemin.
	await _pick(&"hill", "hill_sheet_1", Vector3(-1.5, 0.0, 0.0))
	await _talk(&"village", "Nygglatho", [-1, 0, -1, -1, -1, 0, -1])
	assert_eq(GameState.quest_state(&"flying_laundry"), &"done")
	assert_eq(QuestData.state_of(&"forget_me_nots"), &"available", "la suite : les myosotis")

	# 4. Celles dont on se souvient : cinq myosotis (six dans l'île), le vase.
	await wait_seconds(0.4)
	await _talk(&"village", "Nygglatho", [-1, 0, -1])
	assert_eq(_step(&"forget_me_nots"), &"flowers")
	for spot: Array in [
		[&"village", "village_flower_1"],
		[&"forest", "forest_flower_1"],
		[&"dunes", "dunes_flower_1"],
		[&"hill", "hill_flower_1"],
		[&"hill", "hill_flower_2"],
		[&"hill", "hill_flower_3"],
	]:
		await _pick(spot[0], spot[1])
	await wait_seconds(0.4)
	said = await _talk(&"village", "Nygglatho", [-1, 0, -1, -1, -1, 0, -1])
	assert_true(said.any(func(t: String) -> bool: return t.contains("Tuca")), "le vase")
	assert_eq(GameState.quest_state(&"forget_me_nots"), &"done")

	# 5. L'homme-chat : Ithea, le serveur du café, M. Rami, trois engrenages et le peigne du
	# marais, Willem répare, l'horloge sonne.
	await _talk(&"village", "Ithea", [-1, 0, -1])
	assert_eq(_step(&"old_clock"), &"cafe")
	await wait_seconds(0.4)
	await _talk(&"beach", "CatWaiter", [-1, -1, -1])
	assert_eq(_step(&"old_clock"), &"rami")
	await _talk(&"beach", "Ramikeldi", [-1, -1, -1, -1, -1])
	assert_eq(_step(&"old_clock"), &"gears")
	await _pick(&"dunes", "dunes_gear_1")
	await _pick(&"dunes", "dunes_gear_2")
	await _pick(&"beach", "beach_gear_1")
	await _pick(&"forest", "forest_comb_1")
	assert_eq(_step(&"old_clock"), &"repair")
	await wait_seconds(0.4)
	await _talk(&"village", "Willem", [-1, -1, 0, -1])
	assert_eq(_step(&"old_clock"), &"chime")
	await wait_seconds(0.4)
	await _talk(&"beach", "Ramikeldi", [-1, -1, -1])
	assert_eq(GameState.quest_state(&"old_clock"), &"done")

	# 6. Le registre des veilles : après la première veille de l'acte 1 (drapeau posé ici), la
	# 4e vague, puis 1 000 points en une veille.
	GameState.set_flag(&"first_vigil_done")
	await _talk(&"village", "Tiat", [-1, 0, -1])
	assert_eq(_step(&"vigil_register"), &"wave4")
	await _vigil(func() -> bool: return _step(&"vigil_register") != &"wave4")
	assert_eq(_step(&"vigil_register"), &"tell_tiat", "la 4e vague")
	await _talk(&"village", "Tiat", [-1, -1, -1])
	assert_eq(_step(&"vigil_register"), &"score")
	await _vigil(func() -> bool: return _step(&"vigil_register") != &"score")
	assert_eq(_step(&"vigil_register"), &"record", "1 000 points")
	await wait_seconds(0.4)
	await _talk(&"village", "Tiat", [-1, -1, -1])
	assert_eq(GameState.quest_state(&"vigil_register"), &"done")

	# Les six quêtes terminées, leurs souvenirs, 7 PV max.
	for quest_id: StringName in [
		&"picture_book",
		&"special_dessert",
		&"flying_laundry",
		&"forget_me_nots",
		&"old_clock",
		&"vigil_register",
	]:
		assert_eq(GameState.quest_state(quest_id), &"done", "%s terminée" % quest_id)
	for item_id: StringName in KEEPSAKES:
		assert_eq(GameState.count(item_id), 1, "%s dans l'inventaire" % item_id)
	for flag: StringName in END_FLAGS:
		assert_true(GameState.has_flag(flag), flag)
	assert_eq(GameState.max_hp, 7, "7 PV max (registre des veilles)")
	assert_eq(health.max_hp, 7)
	await wait_process_frames(2)
	assert_eq(hearts_shown(), 7, "sept cœurs dans le HUD")
	assert_eq(GameState.quest_state(&"act1_main"), &"active", "la quête principale continue")
