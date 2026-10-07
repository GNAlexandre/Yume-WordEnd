extends "res://tests/stubs/m2_game_test.gd"
## Intégration M2, parcours 2, acte 1 : la quête principale act1_main (« Dans la forêt céleste »,
## 13 étapes) de bout en bout dans le vrai jeu (main.tscn), au clavier puis à la manette seule,
## par des événements d'entrée réels : Nygglatho sous le porche, Willem et ses conseils, les bois
## à pied (nom affiché), quatre rejetons tués à l'épée, Pannibal ramenée, le rapport, la première
## veille au Couchant (cloche, trois vagues, écran de fin, « Continuer »), la fièvre, l'assaut au
## terrain d'entraînement, le bord du Couchant, le thé du Barocupot, la colline des étoiles et la
## promesse : quête terminée, promesse du gâteau au beurre dans l'inventaire, 6 PV max et six
## cœurs. L'objectif du HUD suit chaque étape. L'appui qui ferme une conversation (Espace, E, A)
## ne la relance pas et ne fait pas sauter Chtholly. Les PNJ sont là selon l'histoire
## (visible_if) : Willem à l'entrepôt, puis au terrain d'entraînement, puis au sommet ; Limeskin
## au port à partir du bord du Couchant.
##
## Raccourcis : entre deux scènes, le joueur est posé près du lieu suivant (seul le trajet vers
## les bois se fait à pied, de zone à zone ; les autres sont couverts par test_m2_world.gd) ; les
## rejetons des bois sont immobilisés (cibles de l'épée) et les Timeres des vagues de la veille
## abattus d'office (leur combat est couvert par test_m1_forest.gd et test_m2_arena.gd) : ici,
## c'est la quête qui compte. Les points de départ sont ceux du décor de l'île n° 68 (locaux à
## leur zone, sol mesuré) ; devant un PNJ, à 3 m de lui, côté centre de sa zone.

const QUEST := &"act1_main"
## Sous la cloche du cercle de veille, côté village (local au Couchant : la cloche est en
## (9 ; 0 ; −2), son battant pend à l'est) : départ des veilles.
const BELL_FRONT := Vector3(10.6, 0.0, -2.0)
## À l'est du cercle, à 5,5 m du déclencheur couchant_edge (−21 ; 0 ; −12), face au vide.
const EDGE_START := Vector3(-15.5, 0.0, -12.0)
## Au sud du sommet de la colline, sur le chemin qui monte au déclencheur hill_summit (1 ; 8 ; −3).
const HILL_START := Vector3(1.0, 8.0, 3.0)
## Sur l'herbe du sommet, au sud du belvédère (fermé de rambardes sauf à l'ouest) : à 3 m de
## Willem, qui se tient à côté du belvédère en (3 ; 8,2 ; 0).
const SUMMIT_FRONT := Vector3(1.0, 8.0, 2.0)

## Manette (true) ou clavier (false) pour le test en cours.
var _pad: bool = false
var _started: int = 0
## Répliques affichées depuis le début du test (jamais remis à zéro) et dernières répliques.
var _line_count: int = 0
var _lines: Array[String] = []


func _listen_dialogues() -> void:
	_started = 0
	_line_count = 0
	_lines.clear()
	listen(EventBus.dialogue_started, func(_npc_id: StringName) -> void: _started += 1)
	listen(
		EventBus.dialogue_line,
		func(_speaker: String, text: String, _choices: Array[String]) -> void:
			_line_count += 1
			_lines.append(text)
	)


# --- Commandes : clavier ou manette ----------------------------------------------------------


## Parler, ligne suivante, valider un choix : E ou A.
func _tap_talk() -> void:
	if _pad:
		await tap_joy(JOY_BUTTON_A)
	else:
		await tap_key(KEY_E)


## Ligne entière suivante : Espace (aussi le saut) ou A.
func _advance() -> void:
	if _pad:
		await tap_joy(JOY_BUTTON_A)
	else:
		await tap_key(KEY_SPACE)


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


## Valider l'écran de fin de veille : Entrée ou A.
func _tap_accept() -> void:
	if _pad:
		await tap_joy(JOY_BUTTON_A)
	else:
		await tap_key(KEY_ENTER)


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
func _walk_toward(target: Vector3, predicate: Callable, max_seconds: float) -> bool:
	player.set_aim_direction(target - player.global_position, true)
	await wait_physics_frames(2)
	return await _forward_until(predicate, max_seconds)


# --- Quête ------------------------------------------------------------------------------------


func _step() -> StringName:
	return GameState.quest_step(QUEST)


## Objectif de l'étape step_id, d'après les données de la quête.
func _objective(step_id: StringName) -> String:
	var quest := QuestData.find(QUEST)
	return quest.steps[quest.step_index(step_id)].objective


## L'étape courante est step_id, et le HUD affiche son objectif.
func _expect_step(step_id: StringName) -> void:
	assert_eq(_step(), step_id, "étape %s" % step_id)
	await wait_process_frames(2)
	assert_eq(hud.call(&"quest_objective", QUEST), _objective(step_id), "objectif : %s" % step_id)


# --- Conversations ----------------------------------------------------------------------------


## PNJ posé dans la zone (fichier d'emplacement : NPCs/<nom>).
func _npc(zone_id: StringName, node_name: String) -> Npc:
	return zone(zone_id).get_node(NodePath("NPCs/" + node_name)) as Npc


## Joueur posé à 3 m du PNJ (côté centre de la zone, ou au point local start s'il est donné),
## qui marche vers lui jusqu'à l'invite « Parler » ; E ou A : la conversation commence.
func _talk_to(zone_id: StringName, npc: Npc, start := Vector3.INF) -> void:
	var local := zone(zone_id).to_local(npc.global_position)
	var away := Vector3(-local.x, 0.0, -local.z).normalized()
	if start == Vector3.INF:
		start = local + away * 3.0
	await place_player(zone_id, start, local - start)
	var near: bool = await _walk_toward(
		npc.global_position, func() -> bool: return player.current_interactable() == npc, 4.0
	)
	assert_true(near, "invite « Parler » devant %s" % npc.name)
	assert_eq(player.current_prompt(), "Parler")
	var started := _started
	await _tap_talk()
	assert_eq(_started, started + 1, "la conversation avec %s commence" % npc.name)
	assert_true(dialogue_box.is_open(), "boîte de dialogue ouverte")


## Lit la conversation ouverte jusqu'à sa fermeture : E ou A termine la ligne qui s'écrit, une
## ligne entière passe à la suite (Espace ou A) ; à chaque question, la réponse suivante de
## answers (rang du choix) est sélectionnée (flèche ou croix bas) puis validée (E ou A). Puis,
## pendant 20 images physiques : pas de saut, pas de nouvelle conversation.
func _read_dialogue(answers: Array[int] = []) -> void:
	var started := _started
	var left := answers.duplicate()
	var asked_at := -1
	var choice := 0
	for _press in 80:
		if not dialogue_box.is_open():
			break
		if dialogue_box.is_choosing():
			if asked_at != _line_count:
				asked_at = _line_count
				choice = int(left.pop_front()) if not left.is_empty() else 0
			if dialogue_box.selected_choice() != choice:
				await _tap_down()
			else:
				await _tap_talk()
		elif dialogue_box.is_waiting():
			await _advance()
		else:
			await _tap_talk()
	assert_false(dialogue_box.is_open(), "conversation terminée")
	assert_eq(left, [] as Array[int], "toutes les réponses données")
	var jumped := false
	for _frame in 20:
		await wait_physics_frames(1)
		jumped = jumped or player.velocity.y > 0.5 or not player.is_on_floor()
	assert_false(jumped, "l'appui qui ferme la conversation ne fait pas sauter")
	assert_eq(_started, started, "ni ne la relance")
	assert_false(player.is_in_dialogue(), "le joueur repart")


## Conversation complète avec le PNJ, réponses answers ; l'étape suivante est next_step.
func _scene(
	zone_id: StringName, node_name: String, answers: Array[int], next_step: StringName
) -> void:
	await _talk_to(zone_id, _npc(zone_id, node_name))
	await _read_dialogue(answers)
	await _expect_step(next_step)


# --- Combats ----------------------------------------------------------------------------------


## Les quatre rejetons des bois, immobilisés, posés tour à tour devant le joueur : épée (J ou X)
## jusqu'à leur mort.
func _kill_the_rejetons() -> void:
	var timeres: Array[Enemy] = []
	for child: Node in zone(&"forest").get_node(^"Enemies").get_children():
		if child is Enemy:
			timeres.append(child as Enemy)
	assert_eq(timeres.size(), 4, "quatre rejetons dans les bois")
	for timere: Enemy in timeres:
		timere.set_physics_process(false)
	for timere: Enemy in timeres:
		await place_player(&"forest", Vector3(0.0, 0.0, 9.0), Vector3.FORWARD)
		timere.global_position = ahead(1.0)
		await wait_physics_frames(2)
		for _swing in 4:
			if timere.is_dead():
				break
			await _tap_attack()
			await wait_until(func() -> bool: return timere.is_dead(), 0.5)
		assert_true(timere.is_dead(), "%s tué à l'épée" % timere.name)


## Abat d'office les Timeres vivants de la veille en cours.
func _strike_the_wave() -> void:
	for enemy: Enemy in director.alive_enemies():
		if is_instance_valid(enemy) and not enemy.is_dead():
			enemy.health.take_damage(enemy.health.current, player)


## Première veille : la cloche (E ou A) lance des vagues accélérées, abattues jusqu'à la 3e ;
## puis le joueur sort du cercle à l'est : écran de fin de veille, « Continuer » (Entrée ou A).
func _first_vigil() -> void:
	director.set_config(fast_waves())
	await place_player(&"dunes", BELL_FRONT, Vector3.LEFT)
	await _tap_talk()
	assert_true(director.is_running(), "la cloche lance la veille")
	var held: bool = await until(
		func() -> bool:
			_strike_the_wave()
			return _step() != &"first_vigil",
		20.0
	)
	assert_true(held, "veille tenue jusqu'à la 3e vague")
	assert_gte(director.current_wave(), 3)
	player.set_aim_direction(Vector3.RIGHT, true)
	await wait_physics_frames(2)
	var left: bool = await _forward_until(
		func() -> bool:
			_strike_the_wave()
			return arena_end.call(&"is_open"),
		6.0
	)
	assert_true(left, "sortie du cercle : fin de la veille")
	await _tap_accept()
	assert_false(arena_end.call(&"is_open"), "« Continuer »")
	assert_false(get_tree().paused, "le jeu reprend")


# --- Parcours ---------------------------------------------------------------------------------


func _play_the_first_act() -> void:
	_listen_dialogues()
	# 0. La quête principale commence seule, suivie dans le HUD.
	assert_eq(GameState.quest_state(QUEST), &"active", "act1_main démarre seule")
	assert_eq(GameState.tracked_quest, QUEST, "quête suivie")
	await _expect_step(&"morning")
	assert_eq(hearts_shown(), 5)
	# 1. Nygglatho, sous le porche : le grand vent, le nouveau responsable.
	await _scene(&"village", "Nygglatho", [0], &"new_officer")
	assert_true(_lines.any(func(t: String) -> bool: return t.contains("Le vent a hurlé")))
	# 2. Willem : « On se connaît ? », il ne touche pas à l'épée, ses conseils.
	_lines.clear()
	await _scene(&"village", "Willem", [0, 0], &"to_the_woods")
	assert_true(GameState.has_flag(&"met_willem"), "Willem salué")
	assert_true(_lines.any(func(t: String) -> bool: return t.contains("verrouille ta cible")))
	# 3. Les bois, à pied par le portail nord : leur nom dans le HUD.
	await place_player(&"village", Vector3(0.0, 0.0, -19.0), Vector3.FORWARD)
	var entered: bool = await _forward_until(
		func() -> bool: return WorldManager.current_zone() == &"forest", 4.0
	)
	assert_true(entered, "entrée dans les bois à pied")
	assert_eq(zone_banner(), WorldManager.zone_display_name(&"forest"), "nom des bois")
	await _expect_step(&"rejetons")
	# 4. Quatre rejetons à l'épée.
	await _kill_the_rejetons()
	await _expect_step(&"pannibal")
	# 5. Pannibal, en embuscade au marais : elle rentre.
	await _scene(&"forest", "Pannibal", [0], &"report")
	assert_true(GameState.has_flag(&"pannibal_found"))
	# 6. Le rapport à Nygglatho : la veille du soir.
	await _scene(&"village", "Nygglatho", [], &"first_vigil")
	# 7. La première veille au Couchant.
	await _first_vigil()
	assert_true(GameState.has_flag(&"first_vigil_done"))
	await _expect_step(&"fever")
	# 8. La fièvre : Willem soigne, Nephren apporte deux cafés.
	await _scene(&"village", "Willem", [0], &"training")
	assert_true(GameState.has_flag(&"departure_told"))
	# 9. L'assaut au terrain d'entraînement.
	await _scene(&"forest", "WillemTraining", [1], &"the_edge")
	assert_true(GameState.has_flag(&"duel_lost"))
	# 10. Seule au bord de l'île, face au couchant.
	await place_player(&"dunes", EDGE_START, Vector3.LEFT)
	var at_edge: bool = await _forward_until(func() -> bool: return _step() != &"the_edge", 4.0)
	assert_true(at_edge, "le bord du Couchant")
	await _expect_step(&"barocupot")
	# 11. Le thé brûlant du Barocupot, avec Limeskin.
	await _scene(&"beach", "Limeskin", [0], &"starry_hill")
	assert_true(GameState.has_flag(&"limeskin_tea"))
	# 12. Le sommet de la colline des étoiles.
	await place_player(&"hill", HILL_START, Vector3.FORWARD)
	var at_top: bool = await _forward_until(func() -> bool: return _step() != &"starry_hill", 4.0)
	assert_true(at_top, "au sommet de la colline")
	await _expect_step(&"promise")
	# 13. La promesse : quête terminée, récompenses.
	_lines.clear()
	var stars := _npc(&"hill", "WillemStars")
	await _talk_to(&"hill", stars, SUMMIT_FRONT)
	await _read_dialogue([1, 0])
	assert_eq(GameState.quest_state(QUEST), &"done", "acte 1 terminé")
	assert_true(_lines.any(func(t: String) -> bool: return t.contains("C’est promis.")))
	assert_true(GameState.has_flag(&"act1_promise"), "récompense de l'étape")
	assert_true(GameState.has_flag(&"act1_done"), "récompense de la quête")
	assert_eq(GameState.count(&"butter_cake_promise"), 1, "la promesse du gâteau au beurre")
	assert_eq(GameState.max_hp, 6, "6 PV max")
	assert_eq(health.max_hp, 6, "le joueur a 6 PV max")
	await wait_process_frames(2)
	assert_eq(hearts_shown(), 6, "six cœurs dans le HUD")
	assert_eq(hud.call(&"quest_objective", QUEST), "", "objectif retiré")
	# Ensuite, Willem regarde les étoiles : une seule réplique.
	_lines.clear()
	await wait_seconds(0.4)
	await _talk_to(&"hill", stars, SUMMIT_FRONT)
	await _read_dialogue()
	assert_eq(_lines.size(), 1, "une seule réplique")
	assert_true(
		not _lines.is_empty() and _lines[0].begins_with("Les étoiles"), "réplique d'après l'acte"
	)
	# Inventaire : la promesse.
	await _tap_inventory()
	assert_true(inventory.call(&"is_open"), "inventaire ouvert (I ou Y)")
	assert_true(get_tree().paused, "inventaire modal")
	var stacks: Array = inventory.call(&"displayed_stacks")
	assert_true(
		stacks.has({"item_id": &"butter_cake_promise", "quantity": 1}), "la promesse, rangée"
	)
	await _tap_back()
	assert_false(inventory.call(&"is_open"), "fermé (Échap ou B)")
	assert_false(get_tree().paused)
	assert_eq(combat.current_state(), &"idle", "B qui ferme l'inventaire ne lance pas de charge")


func test_first_act_with_keyboard_and_mouse() -> void:
	_pad = false
	assert_true(await new_game_from_menu(), "nouvelle partie à la souris")
	await _play_the_first_act()


func test_first_act_with_a_gamepad_only() -> void:
	_pad = true
	await open_main()
	await tap_joy(JOY_BUTTON_A)
	assert_eq(get_viewport().gui_get_focus_owner(), menu_button("NewGameButton"))
	await tap_joy(JOY_BUTTON_A)
	assert_true(await wait_for_game(), "nouvelle partie à la manette")
	await _play_the_first_act()
