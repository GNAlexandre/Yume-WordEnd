extends "res://tests/stubs/m2_game_test.gd"
## (E4) La vie dans la vraie partie (main.tscn, menu, nouvelle partie) : l'ancienne île garde ses
## PNJ immobiles, ses dialogues et ses quêtes (aucun emploi du temps n'y mène) ; dans le
## rez-de-chaussée d'essai, le moment changé par l'API d'E9 (Atmosphere.set_moment) change le
## créneau, et les PNJ marchent vers leurs nouvelles places ; on change de carte par les sorties
## d'essai et l'on retrouve ceux qui sont passés de l'autre côté.

const RDC := &"entrepot_rdc_essai"
const RELIEF := &"essai_relief"

var _previous_fade: float


func before_each() -> void:
	super()
	LifeData.use_content(&"essai")
	_previous_fade = WorldManager.fade_time
	WorldManager.fade_time = 0.0


func after_each() -> void:
	WorldManager.fade_time = _previous_fade
	super()
	GameState.reset()
	LifeData.use_content(&"")


func test_the_old_island_keeps_its_npcs() -> void:
	assert_true(await new_game_from_menu(), "partie lancée depuis le menu")
	assert_eq(WorldManager.current_map(), WorldManager.LEGACY_MAP)
	assert_eq(LifeDirector.actors().size(), 0, "aucun emploi du temps sur l'ancienne île")
	var npcs := get_tree().get_nodes_in_group(&"interactable").filter(
		func(node: Node) -> bool: return node is Npc
	)
	assert_gt(npcs.size(), 5, "les PNJ de l'île sont là")
	for npc: Npc in npcs:
		assert_null(npc.life, "%s : immobile, comme avant" % npc.name)
	# Un dialogue de l'île marche toujours : on parle à Nygglatho.
	var nygglatho: Npc = null
	for npc: Npc in npcs:
		if npc.data != null and npc.data.id == &"nygglatho" and npc.is_present():
			nygglatho = npc
	assert_not_null(nygglatho)
	if nygglatho != null:
		nygglatho.interact(player)
		assert_true(DialogueRunner.is_any_running(), "dialogue de l'île lancé")


func test_slot_change_by_the_light_api_makes_them_walk() -> void:
	assert_true(await new_game_from_menu(), "partie lancée depuis le menu")
	Atmosphere.set_moment(&"matin", 0.0)
	await WorldManager.go_to(RDC)
	assert_true(
		await until(func() -> bool: return not WorldManager.is_transitioning(), 10.0), "arrivée"
	)
	assert_eq(LifeSlots.current(), &"matin")
	assert_eq(LifeDirector.actors().size(), 15, "le petit-déjeuner")
	var almita := LifeDirector.actor(&"almita")
	var before := almita.position()
	assert_true(
		await until(func() -> bool: return LifeDirector.nav().ready, 15.0), "navigation construite"
	)
	Atmosphere.set_moment(&"apres_midi")
	await frames(3)
	assert_eq(LifeSlots.current(), &"apres_midi", "le créneau suit le moment")
	assert_true(almita.is_moving(), "Almita se lève et part")
	assert_true(
		await until(func() -> bool: return not almita.is_moving(), 40.0), "arrivée sur le tapis"
	)
	assert_eq(almita.place, &"jeux_tapis")
	assert_gt(Vector2(before.x - almita.position().x, before.z - almita.position().z).length(), 8.0)
	assert_eq(almita.npc.get_parent(), WorldManager.current_map_node().get_node(^"Life"))


func test_npcs_who_went_out_are_found_outside() -> void:
	assert_true(await new_game_from_menu(), "partie lancée depuis le menu")
	Atmosphere.set_moment(&"apres_midi", 0.0)
	await WorldManager.go_to(RDC)
	assert_true(await until(func() -> bool: return not WorldManager.is_transitioning(), 10.0))
	assert_null(LifeDirector.actor(&"tiat"), "Tiat joue dehors")
	# La sortie d'essai, à invite, mène au pré.
	var exit := WorldManager.current_map_node().get_node(^"Exits/vers_essai_relief") as MapExit
	assert_true(exit.needs_interaction())
	exit.use()
	assert_true(
		await until(func() -> bool: return WorldManager.current_map() == RELIEF, 10.0),
		"dans le pré"
	)
	assert_true(await until(func() -> bool: return not WorldManager.is_transitioning(), 10.0))
	assert_not_null(LifeDirector.actor(&"tiat"), "Tiat est là")
	assert_not_null(LifeDirector.game_at(&"chat", &"herbes_chat"), "on joue au chat")
