extends "res://tests/stubs/m2_game_test.gd"
## (T2) L'entrepôt dans la vraie partie (main.tscn, appuis réels) : on entre au rez-de-chaussée,
## on monte à l'étage par l'escalier (« Monter »), on suit le couloir jusqu'à l'échelle et on monte
## sur le toit (« Monter sur le toit »), on redescend par la trappe, on revient à l'escalier et on
## descend, on traverse le couloir jusqu'à la porte rivetée et on descend à la salle des armes
## (« Ouvrir ») ; on y examine les râteliers (texte de data/texts/entrepot.json dans la boîte de
## dialogue, sans nom), puis on remonte (« Remonter »). Chaque passage se fait à pied jusqu'à
## l'invite de la sortie, puis par la touche d'interaction (E).

var _previous_fade: float
var _lines: Array[String] = []


func before_each() -> void:
	super()
	_previous_fade = WorldManager.fade_time
	WorldManager.fade_time = 0.0
	_lines.clear()
	EventBus.dialogue_line.connect(_on_line)


func after_each() -> void:
	EventBus.dialogue_line.disconnect(_on_line)
	WorldManager.fade_time = _previous_fade
	super()


func _on_line(speaker: String, text: String, _choices: Array[String]) -> void:
	_lines.append("%s|%s" % [speaker, text])


## Position du joueur dans le repère de la carte courante.
func _at() -> Vector3:
	return WorldManager.current_map_node().to_local(player.global_position)


func _arrived(map_id: StringName) -> bool:
	return WorldManager.current_map() == map_id and not WorldManager.is_transitioning()


## Marche (touches tenues) jusqu'à predicate, en suivant le repère de la carte.
func _walk(keys: Array[Key], predicate: Callable, max_seconds: float = 6.0) -> bool:
	return await walk_keys_until(keys, predicate, max_seconds)


## Marche jusqu'à ce que l'invite de la sortie exit_name s'affiche, puis appuie sur E et attend
## l'arrivée dans target.
func _take_exit(keys: Array[Key], exit_name: String, target: StringName) -> bool:
	var exit := WorldManager.current_map_node().get_node(NodePath("Exits/" + exit_name)) as MapExit
	var shown := await _walk(keys, func() -> bool: return player.current_interactable() == exit)
	assert_true(shown, "invite de %s" % exit_name)
	if not shown:
		return false
	assert_eq(player.current_prompt(), exit.prompt, "%s : invite « %s »" % [exit_name, exit.prompt])
	await tap_key(KEY_E)
	var arrived: bool = await until(_arrived.bind(target), 10.0)
	assert_true(arrived, "%s : arrivée dans %s" % [exit_name, target])
	await frames(2)
	return arrived


func _near_marker(marker: StringName) -> void:
	var node := WorldManager.current_map_node().marker(marker)
	assert_lt(distance_to(node), 0.4, "posé au marqueur %s" % marker)


func test_from_the_ground_floor_to_the_roof_and_down_to_the_armory() -> void:
	assert_true(await new_game_from_menu(), "partie lancée depuis le menu")
	await WorldManager.go_to(&"entrepot_rdc", &"from_entrepot_etage")
	assert_true(await until(_arrived.bind(&"entrepot_rdc"), 10.0), "au rez-de-chaussée")
	var map := WorldManager.current_map_node()
	assert_true(map.interior, "un intérieur")
	assert_eq(player.camera_rig.limits, map.bounds(), "caméra bornée au rez-de-chaussée")
	if not await _up_to_the_roof_and_back():
		return
	if not await _down_to_the_armory():
		return
	await _examine_the_racks_and_go_up()


## Du pied de l'escalier du rez-de-chaussée à l'étage, au toit, et retour au rez-de-chaussée.
func _up_to_the_roof_and_back() -> bool:
	# Au pied de l'escalier : on monte.
	if not await _take_exit([KEY_W], "vers_etage", &"entrepot_etage"):
		return false
	_near_marker(&"from_entrepot_rdc")
	# Du palier à l'est, au sud par l'ouverture de la trémie, puis le couloir jusqu'à l'échelle.
	assert_true(await _walk([KEY_D], func() -> bool: return _at().x > 19.2), "le long du palier")
	assert_true(await _walk([KEY_S], func() -> bool: return _at().z > 9.3), "dans le couloir")
	if not await _take_exit([KEY_D], "vers_toit", &"entrepot_toit"):
		return false
	_near_marker(&"from_entrepot_etage")
	assert_false(WorldManager.current_map_node().interior, "le toit est dehors")
	# La trappe, à l'est : on redescend.
	if not await _take_exit([KEY_D], "trappe", &"entrepot_etage"):
		return false
	_near_marker(&"from_entrepot_toit")
	# Le couloir vers l'ouest, au nord par la trémie, puis le haut de l'escalier.
	assert_true(await _walk([KEY_A], func() -> bool: return _at().x < 19.6, 8.0), "le couloir")
	assert_true(await _walk([KEY_W], func() -> bool: return _at().z < 2.1), "sur le palier")
	if not await _take_exit([KEY_A], "vers_rdc", &"entrepot_rdc"):
		return false
	_near_marker(&"from_entrepot_etage")
	return true


## Du pied de l'escalier du rez-de-chaussée à la salle des armes.
func _down_to_the_armory() -> bool:
	# Au sud dans le couloir, à l'est jusqu'au palier des armes, au nord jusqu'à la porte rivetée.
	assert_true(await _walk([KEY_S], func() -> bool: return _at().z > 9.4), "dans le couloir")
	assert_true(await _walk([KEY_D], func() -> bool: return _at().x > 21.4), "vers l'est")
	if not await _take_exit([KEY_W], "vers_armes", &"salle_des_armes"):
		return false
	_near_marker(&"from_entrepot_rdc")
	return true


## Dans la salle des armes : examiner les râteliers, puis remonter.
func _examine_the_racks_and_go_up() -> void:
	# Les râteliers, au nord-est (au nord des piliers) : on les examine.
	assert_true(await _walk([KEY_W], func() -> bool: return _at().z < 4.5), "au nord")
	assert_true(await _walk([KEY_D], func() -> bool: return _at().x > 8.4), "vers les épées")
	var examined := await _walk(
		[KEY_W], func() -> bool: return player.current_interactable() is Examinable, 4.0
	)
	assert_true(examined, "invite « Examiner »")
	if not examined:
		return
	var item := player.current_interactable() as Examinable
	assert_eq(player.current_prompt(), "Examiner")
	# (U1) Le HUD montre le signe de la cible au-dessus d'elle (plus de pastille).
	var signs := hud.call(&"interact_signs") as Control
	assert_true(
		await until(func() -> bool: return signs.call(&"full_kind") == InteractSign.EXAMINE, 2.0),
		"signe « examiner »"
	)
	assert_eq(signs.call(&"full_target"), player.current_interactable())
	await tap_key(KEY_E)
	assert_true(await until(func() -> bool: return dialogue_box.is_open(), 2.0), "boîte ouverte")
	var pages := item.text_value().split("\n\n", false)
	assert_eq(_lines.size(), 1, "la première page")
	if _lines.size() == 1:
		var first := DialogueRunner.format_text(pages[0].strip_edges())
		assert_eq(_lines[0], "|%s" % first, "sans nom ni portrait")
	for _page in 6:
		if not DialogueRunner.is_any_running():
			break
		await tap_key(KEY_E)
		await frames(3)
	assert_false(DialogueRunner.is_any_running(), "texte refermé")
	assert_eq(_lines.size(), pages.size(), "toutes les pages lues")
	assert_false(dialogue_box.is_open())
	# Retour au pied des marches, et on remonte.
	assert_true(await _walk([KEY_S], func() -> bool: return _at().z > 4.2), "au sud")
	assert_true(await _walk([KEY_A], func() -> bool: return _at().x < 2.7, 8.0), "vers l'escalier")
	if not await _take_exit([KEY_W], "remonter", &"entrepot_rdc"):
		return
	_near_marker(&"from_salle_des_armes")
