extends "res://tests/stubs/m2_game_test.gd"
## Lot Q, intégration : la quête de démonstration demo_tour (tests/data/quests, cinq étapes) jouée
## de bout en bout dans le vrai jeu (main.tscn), par des appuis réels, puis sa suite
## demo_followup. Le guide, le soldat de la Garde et le déclencheur du puits viennent de
## tests/data/placements/village.tscn, posé dans le village comme un fichier d'emplacement.
## Marqueurs « ! » et « ? », objectif et progression du HUD, journal (Tab, L, Select ; pause),
## sauvegarde de l'étape en cours. La quête principale de l'acte 1, commencée seule, n'en bouge
## pas : elle se joue dans tests/integration/test_m2_quest.gd.
## Comme dans test_m2_quest.gd, les Timeres de la forêt sont immobilisés (cibles de l'épée).

const FIXTURES_DIR := "res://tests/data/quests"
const VILLAGE_DEMO := preload("res://tests/data/placements/village.tscn")
const PAGE := &"page_fragment"

var journal: Control
var _started: int = 0


func before_each() -> void:
	super()
	QuestData.add_search_dir(FIXTURES_DIR)


func after_each() -> void:
	super()
	QuestData.remove_search_dir(FIXTURES_DIR)


# --- Outils ------------------------------------------------------------------------------------


func _npc(zone_id: StringName, path: String) -> Npc:
	return zone(zone_id).get_node(NodePath(path)) as Npc


func _marker(npc: Npc) -> String:
	return npc.quest_marker.text if npc.quest_marker.visible else ""


## Tout droit dans la visée (la caméra fixe regarde le nord) jusqu'à predicate ; run : Maj
## tenue.
func _forward_until(predicate: Callable, max_seconds: float, run: bool = false) -> bool:
	return await walk_aim_until(predicate, max_seconds, run)


func _walk_toward(target: Vector3, predicate: Callable, max_seconds: float) -> bool:
	player.set_aim_direction(target - player.global_position, true)
	await wait_physics_frames(2)
	return await _forward_until(predicate, max_seconds, true)


## Marche jusqu'au PNJ (invite « Parler » sur lui), puis E : la conversation commence.
func _talk_to(npc: Npc) -> void:
	var near: bool = await _walk_toward(
		npc.global_position, func() -> bool: return player.current_interactable() == npc, 8.0
	)
	assert_true(near, "devant %s" % npc.name)
	var started := _started
	await tap_key(KEY_E)
	assert_eq(_started, started + 1, "la conversation avec %s commence" % npc.name)


## Lit la conversation jusqu'au bout, E pour chaque ligne ; aux choix, choice (flèche bas).
func _read_dialogue(choice: int) -> void:
	for _press in 40:
		if not dialogue_box.is_open():
			break
		if dialogue_box.is_choosing() and dialogue_box.selected_choice() != choice:
			await tap_key(KEY_DOWN)
		else:
			await tap_key(KEY_E)
	assert_false(dialogue_box.is_open(), "conversation terminée")
	await wait_physics_frames(2)


func _step() -> StringName:
	return GameState.quest_step(&"demo_tour")


## Timere de la forêt, immobilisé, posé devant le joueur ; épée (J) jusqu'à sa mort. Il ne lâche
## rien (Timere ignore les objets, V3) : les pages sont posées dans la clairière.
func _kill(timere: Enemy) -> void:
	await place_player(&"forest", Vector3(0.0, 0.0, 9.0), Vector3.FORWARD)
	timere.global_position = ahead(1.0)
	await wait_physics_frames(2)
	for _swing in 4:
		if timere.is_dead():
			break
		await tap_key(KEY_J)
		await wait_until(func() -> bool: return timere.is_dead(), 0.5)
	assert_true(timere.is_dead(), "%s vaincu à l'épée" % timere.name)


## Depuis le centre de la clairière, marche jusqu'à la page posée page_id et la ramasse.
func _collect_page(page_id: StringName) -> void:
	var page := zone(&"forest").get_node(NodePath("Pickups/%s" % page_id)) as Node3D
	await place_player(&"forest", Vector3.ZERO, Vector3.FORWARD)
	var picked: bool = await _walk_toward(
		page.global_position, func() -> bool: return GameState.is_pickup_collected(page_id), 4.0
	)
	assert_true(picked, "%s ramassée" % page_id)


func _journal_steps() -> Array[Dictionary]:
	return journal.call(&"shown_steps")


# --- Parcours ----------------------------------------------------------------------------------


func test_demo_quest_from_offer_to_followup() -> void:
	listen(EventBus.dialogue_started, func(_npc_id: StringName) -> void: _started += 1)
	assert_true(await new_game_from_menu(), "nouvelle partie")
	journal = hud.get_node(^"Journal") as Control
	zone(&"village").add_child(VILLAGE_DEMO.instantiate())
	await wait_physics_frames(30)
	var guide := _npc(&"village", "QuestDemo/DemoGuide")
	var guard := _npc(&"village", "QuestDemo/Guard")
	var nygglatho := _npc(&"village", "NPCs/Nygglatho")

	# 0. Marqueurs : le guide a une quête à donner ; Nygglatho attend l'aînée (act1_main).
	assert_eq(_marker(guide), "!", "« ! » au-dessus du guide")
	assert_eq(_marker(nygglatho), "?", "« ? » au-dessus de Nygglatho (quête principale)")
	assert_eq(_marker(guard), "")

	# 1. Le guide propose la visite : on accepte.
	await _talk_to(guide)
	await _read_dialogue(0)
	assert_eq(GameState.quest_state(&"demo_tour"), &"active", "quête acceptée")
	assert_eq(_step(), &"guard")
	await wait_process_frames(2)
	assert_eq(
		hud.call(&"quest_objective", &"demo_tour"),
		"Saluer le soldat de la Garde",
		"objectif du HUD"
	)
	assert_eq(_marker(guard), "?", "« ? » au-dessus du soldat de la Garde")
	assert_eq(_marker(guide), "", "plus de « ! » au-dessus du guide")

	# 2. Étape talk : la conversation avec le soldat de la Garde (« Une autre fois. »).
	await _talk_to(guard)
	await _read_dialogue(1)
	assert_eq(_step(), &"well", "fin du dialogue du soldat : étape suivante")
	await wait_process_frames(2)
	assert_eq(hud.call(&"quest_objective", &"demo_tour"), "Aller voir le puits de la place")
	assert_eq(_marker(guard), "")

	# 3. Étape reach (déclencheur) : vers le puits, depuis le Spawn.
	await place_player(&"village", Vector3(0.0, 0.0, 8.5), Vector3.FORWARD)
	var at_well: bool = await _forward_until(func() -> bool: return _step() == &"forest", 3.0)
	assert_true(at_well, "le déclencheur du puits valide l'étape")
	# L'étape en cours est sauvegardée (auto-sauvegarde sur quest_step_completed).
	var written: bool = await until(
		func() -> bool: return not SaveManager.is_autosave_pending(), 3.0
	)
	assert_true(written)
	var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(SaveManager.save_path))
	assert_eq(int(saved["version"]), 2)
	assert_eq(saved["quest_progress"]["demo_tour"]["step"], "forest", "étape sauvegardée")
	assert_eq(saved["tracked_quest"], "demo_tour")

	# 4. Journal (Tab) : étapes validées et courante ; fermé par L.
	await tap_key(KEY_TAB)
	assert_true(journal.call(&"is_open"), "journal ouvert (Tab)")
	assert_true(get_tree().paused, "jeu en pause")
	assert_eq(journal.call(&"listed_quests"), [&"act1_main", &"demo_tour"] as Array[StringName])
	assert_eq(journal.call(&"selected_quest"), &"demo_tour", "la quête suivie")
	var steps := _journal_steps()
	assert_eq(steps.size(), 3)
	assert_eq(
		[steps[0]["state"], steps[1]["state"], steps[2]["state"]], [&"done", &"done", &"current"]
	)
	assert_eq(steps[2]["objective"], "Entrer dans la forêt, au nord du village")
	await tap_key(KEY_L)
	assert_false(journal.call(&"is_open"), "fermé (L)")
	assert_false(get_tree().paused)

	# 5. Étape reach (zone) : la forêt, à pied par la porte nord.
	await place_player(&"village", Vector3(0.0, 0.0, -19.0), Vector3.FORWARD)
	var entered: bool = await _forward_until(func() -> bool: return _step() == &"timeres", 4.0)
	assert_true(entered, "entrée dans la forêt")
	await wait_process_frames(2)
	assert_eq(hud.call(&"quest_progress", &"demo_tour"), "Ennemis vaincus : 0/2")

	# 6. Étape kill : deux Timeres ; puis deux pages posées dans la clairière.
	var timeres: Array[Enemy] = []
	for child: Node in zone(&"forest").get_node(^"Enemies").get_children():
		if child is Enemy:
			(child as Enemy).set_physics_process(false)
			timeres.append(child as Enemy)
	await _kill(timeres[0])
	assert_eq(hud.call(&"quest_progress", &"demo_tour"), "Ennemis vaincus : 1/2")
	await _kill(timeres[1])
	assert_eq(_step(), &"pages", "deux Timeres : étape suivante")
	assert_true(GameState.has_flag(&"demo_tour_brave"), "récompense de l'étape")
	await wait_process_frames(2)
	assert_eq(hud.call(&"quest_progress", &"demo_tour"), "Page du livre d’images : 0/2")
	await _collect_page(&"forest_page_1")
	await _collect_page(&"forest_page_2")
	await wait_process_frames(2)
	assert_eq(hud.call(&"quest_progress", &"demo_tour"), "Page du livre d’images : 2/2")

	# 7. Étape collect « rapporter à » : retour au village, le guide prend les pages.
	await place_player(&"forest", Vector3(0.0, 0.0, 26.0), Vector3.BACK)
	var home: bool = await _forward_until(
		func() -> bool: return WorldManager.current_zone() == &"village", 4.0
	)
	assert_true(home, "retour au village")
	assert_eq(_marker(guide), "?", "« ? » : les pages sont à rendre")
	await _talk_to(guide)
	await _read_dialogue(0)
	assert_eq(GameState.quest_state(&"demo_tour"), &"done", "quête terminée")
	assert_eq(GameState.count(PAGE), 0, "deux pages rendues")
	assert_eq(GameState.count(&"flower_blue"), 1, "récompense de la quête")
	await wait_process_frames(2)
	assert_eq(hud.call(&"quest_objective", &"demo_tour"), "", "objectif retiré")
	assert_eq(_marker(guide), "!", "la suite est disponible")

	# 8. La suite : une étape flag posée par le dialogue.
	await wait_seconds(0.4)
	await _talk_to(guide)
	await _read_dialogue(0)
	assert_eq(GameState.quest_state(&"demo_followup"), &"done", "histoire écoutée")
	assert_eq(_marker(guide), "")

	# 9. Journal à la manette : Select, les deux quêtes terminées ; B ferme sans charger.
	await tap_joy(JOY_BUTTON_BACK)
	assert_true(journal.call(&"is_open"), "journal ouvert (Select)")
	var expected: Array[StringName] = [&"act1_main", &"demo_tour", &"demo_followup"]
	assert_eq(journal.call(&"listed_quests"), expected, "la principale, puis les terminées")
	await tap_joy(JOY_BUTTON_B)
	assert_false(journal.call(&"is_open"), "fermé (B)")
	assert_false(get_tree().paused)
	assert_eq(combat.current_state(), &"idle", "B qui ferme le journal ne lance pas de charge")

	# 10. La quête principale n'a pas bougé.
	assert_eq(GameState.quest_step(&"act1_main"), &"morning", "act1_main à sa première étape")
	assert_eq(_marker(nygglatho), "?")
