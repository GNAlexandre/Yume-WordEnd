extends "res://tests/stubs/m2_game_test.gd"
## Intégration M2, parcours 2 : la quête des pages de bout en bout dans le vrai jeu (main.tscn),
## au clavier puis à la manette seule, par des événements d'entrée réels. Bibliothécaire : on
## accepte ; objectif dans le HUD ; forêt à pied (nom affiché) ; ses quatre Timeres tués à l'épée
## lâchent quatre pages, les trois pages uniques ramassées en marchant dessus ; retour au village ;
## la bibliothécaire termine la quête : cinq pages retirées, marque-page dans l'inventaire, 6 PV
## max et six cœurs ; elle remercie ensuite. L'appui qui ferme une conversation (Espace, E, A) ne
## la relance pas et ne fait pas sauter Chtholly.
##
## Les Timeres de la forêt sont immobilisés le temps du test (IA arrêtée, cibles à l'épée) : leur
## combat est couvert par tests/integration/test_m1_forest.gd ; ici, c'est la quête qui compte.

const OBJECTIVE := "Rapporter 5 fragments de page à la bibliothécaire"
const FOREST_NAME := "Les bois du marais"
const PAGE := &"page_fragment"
## Pages uniques de la forêt (local à la zone) : forest_page_1..3 (src/items/placements).
const PAGES: Array[StringName] = [&"forest_page_1", &"forest_page_2", &"forest_page_3"]

## Manette (true) ou clavier (false) pour le test en cours.
var _pad: bool = false
var _started: int = 0
var _lines: Array[String] = []


func _listen_dialogues() -> void:
	_started = 0
	_lines.clear()
	listen(EventBus.dialogue_started, func(_npc: StringName) -> void: _started += 1)
	listen(
		EventBus.dialogue_line,
		func(_speaker: String, text: String, _choices: Array[String]) -> void: _lines.append(text)
	)


# --- Commandes : clavier ou manette ----------------------------------------------------------


## Parler, ramasser, ligne suivante : E ou A.
func _tap_talk() -> void:
	if _pad:
		await tap_joy(JOY_BUTTON_A)
	else:
		await tap_key(KEY_E)


## Choix suivant : flèche bas ou croix bas.
func _tap_down() -> void:
	if _pad:
		await tap_joy(JOY_BUTTON_DPAD_DOWN)
	else:
		await tap_key(KEY_DOWN)


func _tap_attack() -> void:
	if _pad:
		await tap_joy(JOY_BUTTON_X)
	else:
		await tap_key(KEY_J)


func _tap_inventory() -> void:
	if _pad:
		await tap_joy(JOY_BUTTON_Y)
	else:
		await tap_key(KEY_I)


## Fermer un écran : Échap ou B.
func _tap_back() -> void:
	if _pad:
		await tap_joy(JOY_BUTTON_B)
	else:
		await tap_key(KEY_ESCAPE)


## Tout droit (W, ou stick en avant) jusqu'à predicate ; run : Maj tenue ou L3.
func _forward_until(predicate: Callable, max_seconds: float, run: bool = false) -> bool:
	if _pad:
		await wait_physics_frames(1)
		stick(0.0, -1.0)
		if run:
			await tap_joy(JOY_BUTTON_LEFT_STICK)
		var reached: bool = await until(predicate, max_seconds)
		stick(0.0, 0.0)
		await wait_physics_frames(2)
		return reached
	var keys: Array[Key] = [KEY_W]
	if run:
		keys.append(KEY_SHIFT)
	return await walk_keys_until(keys, predicate, max_seconds)


## Tourne la caméra (et le joueur) vers target, puis avance jusqu'à predicate.
func _walk_toward(target: Vector3, predicate: Callable, max_seconds: float, run := false) -> bool:
	player.set_aim_direction(target - player.global_position, true)
	await wait_physics_frames(2)
	return await _forward_until(predicate, max_seconds, run)


# --- Dialogue ---------------------------------------------------------------------------------


## Lit la conversation ouverte jusqu'à sa fermeture : E ou A termine la ligne qui s'écrit ; une
## ligne entière passe à la suite par advance (Espace, E ou A) ; aux choix, choice est
## sélectionné (flèche ou croix bas) puis validé (E ou A). Puis, pendant 20 images physiques :
## pas de saut, pas de nouvelle conversation.
func _read_dialogue(choice: int, advance: Callable) -> void:
	var started := _started
	for _press in 40:
		if not dialogue_box.is_open():
			break
		if dialogue_box.is_choosing() and dialogue_box.selected_choice() != choice:
			await _tap_down()
		elif dialogue_box.is_waiting():
			await advance.call()
		else:
			await _tap_talk()
	assert_false(dialogue_box.is_open(), "conversation terminée")
	var jumped := false
	for _frame in 20:
		await wait_physics_frames(1)
		jumped = jumped or player.velocity.y > 0.5 or not player.is_on_floor()
	assert_false(jumped, "l'appui qui ferme la conversation ne fait pas sauter")
	assert_eq(_started, started, "ni ne la relance")
	assert_false(player.is_in_dialogue(), "le joueur repart")


## Va parler à la bibliothécaire (elle est dans le cône quand l'invite la désigne), E ou A.
func _talk_to_librarian(librarian: Npc) -> void:
	var near: bool = await _walk_toward(
		librarian.global_position,
		func() -> bool: return player.current_interactable() == librarian,
		8.0,
		true
	)
	assert_true(near, "invite « Parler » devant la bibliothécaire")
	assert_eq(player.current_prompt(), "Parler")
	var started := _started
	await _tap_talk()
	assert_eq(_started, started + 1, "la conversation commence")
	assert_true(dialogue_box.is_open(), "boîte de dialogue ouverte")


# --- Forêt ------------------------------------------------------------------------------------


func _forest_timeres() -> Array[Enemy]:
	var result: Array[Enemy] = []
	for child: Node in zone(&"forest").get_node(^"Enemies").get_children():
		if child is Enemy:
			result.append(child as Enemy)
	return result


## Pages lâchées (Pickup non persistants) encore dans la forêt.
func _dropped_pages() -> Array[Pickup]:
	var result: Array[Pickup] = []
	for child: Node in zone(&"forest").get_node(^"Enemies").get_children():
		if child is Pickup and not child.is_queued_for_deletion():
			result.append(child as Pickup)
	return result


## Le Timere, immobilisé, est posé devant le joueur ; épée (J ou X) jusqu'à sa mort ; puis la
## page qu'il lâche est ramassée en avançant dessus.
func _kill_and_collect(timere: Enemy) -> void:
	await place_player(&"forest", Vector3(0.0, 0.0, 9.0), Vector3.FORWARD)
	timere.global_position = ahead(1.0)
	await wait_physics_frames(2)
	for _swing in 4:
		if timere.is_dead():
			break
		await _tap_attack()
		await wait_until(func() -> bool: return timere.is_dead(), 0.5)
	assert_true(timere.is_dead(), "%s tué à l'épée" % timere.name)
	var dropped: bool = await wait_until(
		func() -> bool: return not _dropped_pages().is_empty(), 1.0
	)
	assert_true(dropped, "%s lâche une page" % timere.name)
	var before := GameState.count(PAGE)
	var picked: bool = await _forward_until(
		func() -> bool: return GameState.count(PAGE) > before, 2.0
	)
	assert_true(picked, "page de %s ramassée en marchant dessus" % timere.name)


## Depuis le centre de la clairière, marche vers la page unique jusqu'à la ramasser.
func _collect_unique_page(page_id: StringName) -> void:
	var page := zone(&"forest").get_node(NodePath("Pickups/%s" % page_id)) as Pickup
	assert_not_null(page, "%s encore là" % page_id)
	if page == null:
		return
	var target := page.global_position
	await place_player(&"forest", Vector3.ZERO, Vector3.FORWARD)
	var picked: bool = await _walk_toward(
		target, func() -> bool: return GameState.is_pickup_collected(page_id), 4.0
	)
	assert_true(picked, "%s ramassée en marchant dessus" % page_id)


# --- Parcours ---------------------------------------------------------------------------------


func _play_the_pages_quest() -> void:
	_listen_dialogues()
	var librarian := zone(&"village").get_node(^"NPCs/Librarian") as Npc
	# 1. Bibliothécaire : on accepte la quête (premier choix).
	assert_eq(GameState.quest_state(&"pages"), &"", "quête pas encore proposée")
	await _talk_to_librarian(librarian)
	# Clavier : les lignes entières passent à l'Espace (aussi le saut) ; manette : A.
	var advance := (
		(func() -> void: await tap_joy(JOY_BUTTON_A))
		if _pad
		else (func() -> void: await tap_key(KEY_SPACE))
	)
	await _read_dialogue(0, advance)
	assert_eq(GameState.quest_state(&"pages"), &"active", "quête acceptée")
	assert_true(GameState.has_flag(&"quest_pages_accepted"))
	assert_true(_lines.any(func(t: String) -> bool: return t.contains("La forêt est au nord")))
	await wait_process_frames(2)
	assert_eq(hud.call(&"quest_objective", &"pages"), OBJECTIVE, "objectif dans le HUD")
	assert_eq(hud.call(&"quest_progress", &"pages"), "Fragment de page\u00a0: 0/5")
	# 2. La forêt, à pied par la porte nord du village : son nom dans le HUD.
	await place_player(&"village", Vector3(0.0, 0.0, -19.0), Vector3.FORWARD)
	var entered: bool = await _forward_until(
		func() -> bool: return WorldManager.current_zone() == &"forest", 4.0
	)
	assert_true(entered, "entrée dans la forêt à pied")
	assert_eq(zone_banner(), FOREST_NAME, "nom de la forêt dans le HUD")
	var timeres := _forest_timeres()
	assert_eq(timeres.size(), 4, "quatre Timeres gardent les pages")
	for timere: Enemy in timeres:
		timere.set_physics_process(false)
	# 3. Les Timeres tués lâchent des pages ; les trois pages uniques.
	for timere: Enemy in timeres:
		await _kill_and_collect(timere)
	assert_eq(GameState.count(PAGE), 4, "quatre pages lâchées")
	for page_id: StringName in PAGES:
		await _collect_unique_page(page_id)
	assert_eq(GameState.count(PAGE), 7, "trois pages uniques en plus")
	await wait_process_frames(2)
	assert_eq(hud.call(&"quest_progress", &"pages"), "Fragment de page\u00a0: 5/5", "progression")
	# 4. Retour au village à pied par la porte nord.
	await place_player(&"forest", Vector3(0.0, 0.0, 26.0), Vector3.BACK)
	var home: bool = await _forward_until(
		func() -> bool: return WorldManager.current_zone() == &"village", 4.0
	)
	assert_true(home, "retour au village")
	assert_eq(zone_banner(), "L'entrepôt des fées", "nom du village dans le HUD")
	# 5. La bibliothécaire termine la quête (fermeture à E ou A).
	assert_eq(hearts_shown(), 5)
	await _talk_to_librarian(librarian)
	await _read_dialogue(0, _tap_talk)
	assert_eq(GameState.quest_state(&"pages"), &"done", "quête terminée")
	assert_eq(GameState.count(PAGE), 2, "cinq pages retirées")
	assert_eq(GameState.count(&"bookmark"), 1, "marque-page reçu")
	assert_eq(GameState.max_hp, 6, "6 PV max")
	assert_eq(health.max_hp, 6, "le joueur a 6 PV max")
	await wait_process_frames(2)
	assert_eq(hearts_shown(), 6, "six cœurs dans le HUD")
	assert_eq(hud.call(&"quest_objective", &"pages"), "", "objectif retiré")
	assert_true(_lines.any(func(t: String) -> bool: return t.begins_with("Les cinq pages")))
	# 6. Ensuite, elle remercie.
	_lines.clear()
	await wait_seconds(0.4)
	await _talk_to_librarian(librarian)
	await _read_dialogue(0, _tap_talk)
	assert_eq(_lines.size(), 1, "une seule réplique")
	assert_true(
		not _lines.is_empty() and _lines[0].begins_with("Grâce à toi"), "réplique de remerciement"
	)
	# 7. Inventaire : le marque-page.
	await _tap_inventory()
	assert_true(inventory.call(&"is_open"), "inventaire ouvert (I ou Y)")
	assert_true(get_tree().paused, "inventaire modal")
	var stacks: Array = inventory.call(&"displayed_stacks")
	assert_true(
		stacks.has({"item_id": &"bookmark", "quantity": 1}), "le marque-page dans l'inventaire"
	)
	await _tap_back()
	assert_false(inventory.call(&"is_open"), "fermé (Échap ou B)")
	assert_false(get_tree().paused)
	assert_eq(combat.current_state(), &"idle", "B qui ferme l'inventaire ne lance pas de charge")


func test_pages_quest_with_keyboard_and_mouse() -> void:
	_pad = false
	assert_true(await new_game_from_menu(), "nouvelle partie à la souris")
	await _play_the_pages_quest()


func test_pages_quest_with_a_gamepad_only() -> void:
	_pad = true
	await open_main()
	await tap_joy(JOY_BUTTON_A)
	assert_eq(get_viewport().gui_get_focus_owner(), menu_button("NewGameButton"))
	await tap_joy(JOY_BUTTON_A)
	assert_true(await wait_for_game(), "nouvelle partie à la manette")
	await _play_the_pages_quest()
