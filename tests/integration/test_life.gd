extends GutTest
## (E4) La vie sur les cartes d'essai, dans game.tscn (WorldManager.enter_map, sans menu) : le
## directeur pose chacun à sa place selon le créneau, les PNJ marchent vers leurs nouvelles places
## quand le créneau change (par les portes), partent vers une autre carte ; les jeux de groupe
## (le chat change de chasseuse, le joueur y entre et en sort ; l'avalanche ; la tour ; la course).

const GAME_SCENE := preload("res://src/game.tscn")
const RDC := &"entrepot_rdc_essai"
const RELIEF := &"essai_relief"

var _game: Node3D
var _player: Player


func before_each() -> void:
	LifeData.use_content(&"essai")
	GameState.reset()
	WorldManager.fade_time = 0.0
	_game = GAME_SCENE.instantiate() as Node3D
	add_child(_game)
	_player = _game.get_node(^"Player") as Player
	await wait_physics_frames(2)


func after_each() -> void:
	WorldManager.fade_time = WorldManager.DEFAULT_FADE_TIME
	_game.queue_free()
	await wait_physics_frames(2)
	LifeDirector.attach(null)
	Atmosphere.dress(null)
	GameState.reset()
	LifeData.use_content(&"")


func _enter(map_id: StringName, slot: StringName, at: Vector3 = Vector3(1.0, 0.0, 1.0)) -> void:
	LifeDirector.set_slot(slot, 0.0)
	assert_true(WorldManager.enter_map(map_id))
	LifeDirector.build_nav_now()
	_player.global_position = at
	_player.velocity = Vector3.ZERO


func _place_of(npc_id: StringName) -> Vector3:
	var who := LifeDirector.actor(npc_id)
	return who.spot.origin if who != null else Vector3.INF


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


## Attend (images physiques) que predicate soit vrai, au plus seconds s.
func _until(predicate: Callable, seconds: float) -> bool:
	var frames := ceili(seconds * Engine.physics_ticks_per_second)
	for _i: int in frames:
		if predicate.call():
			return true
		await wait_physics_frames(1)
	return predicate.call()


func test_everyone_appears_at_their_place_already_busy() -> void:
	_enter(RDC, &"matin")
	assert_eq(LifeDirector.actors().size(), 15, "15 PNJ au matin dans le rez-de-chaussée")
	var willem := LifeDirector.actor(&"willem")
	assert_not_null(willem)
	assert_lt(_flat(willem.position(), _place_of(&"willem")), 0.05, "Willem à sa place")
	assert_eq(willem.place, &"cuisine_table")
	assert_eq(willem.npc.visual.skin.id, &"willem_cook", "en tablier")
	assert_eq(willem.npc.visual.current_animation(), &"travaille", "déjà en cuisine")
	var tiat := LifeDirector.npc(&"tiat")
	assert_eq(tiat.get_parent().name, "Life", "dans le nœud Life de la carte")
	assert_eq(tiat.visual.skin.id, &"tiat_life", "tenue de la vie (planche complémentaire)")
	assert_true(tiat.visual.has_animation(&"course") and tiat.visual.has_animation(&"marche"))
	assert_null(LifeDirector.actor(&"lakhesh") if GameState.day >= 3 else null)
	assert_eq(LifeDirector.where(&"ithea")["place"], &"refectoire_table_c", "consultation")


func test_outside_the_map_nothing_runs_but_where_answers() -> void:
	_enter(RELIEF, &"matin")
	assert_eq(LifeDirector.actors().size(), 0, "au matin, personne dehors")
	assert_eq(LifeDirector.where(&"tiat")["map"], RDC, "Tiat est au réfectoire")
	LifeDirector.set_slot(&"apres_midi", 0.0)
	await wait_physics_frames(2)
	assert_eq(LifeDirector.actors().size(), 7, "l'après-midi : le chat, le belvédère, le pré")


func test_slot_change_makes_them_walk_through_the_doors() -> void:
	_enter(RDC, &"matin", Vector3(19.0, 0.0, 17.0))
	var nephren := LifeDirector.actor(&"nephren")
	var tiat := LifeDirector.actor(&"tiat")
	var start := nephren.position()
	LifeDirector.set_slot(&"apres_midi", 0.0)
	await wait_physics_frames(2)
	assert_true(nephren.is_moving(), "Nephren part à pied")
	assert_true(
		await _until(func() -> bool: return not nephren.current_path().is_empty(), 4.0), "un chemin"
	)
	# Du réfectoire à la salle de lecture : par le couloir.
	var through_corridor := false
	for point: Vector3 in nephren.current_path():
		through_corridor = through_corridor or (point.z > 10.0 and point.z < 13.0)
	assert_true(through_corridor, "par le couloir, donc par les portes")
	var arrived := await _until(
		func() -> bool: return not nephren.is_moving() and nephren.place == &"lecture_table", 30.0
	)
	assert_true(arrived, "arrivée à la salle de lecture")
	assert_lt(_flat(nephren.position(), _place_of(&"nephren")), 0.05)
	assert_gt(_flat(start, nephren.position()), 5.0)
	assert_true(
		await _until(func() -> bool: return LifeDirector.actor(&"tiat") == null, 40.0),
		"Tiat sort (vers le pré) et disparaît"
	)
	assert_eq(tiat.state, LifeActor.State.GONE)


func test_talking_interrupts_then_resumes() -> void:
	_enter(RDC, &"matin")
	var willem := LifeDirector.actor(&"willem")
	EventBus.dialogue_started.emit(&"willem")
	await wait_physics_frames(2)
	assert_true(willem.talking)
	EventBus.dialogue_ended.emit(&"willem")
	await wait_physics_frames(2)
	assert_false(willem.talking)
	assert_has([&"travaille", &"repos"], willem.npc.visual.current_animation(), "reprend")


func test_tag_changes_the_chaser_and_the_player_joins_and_leaves() -> void:
	_enter(RELIEF, &"apres_midi", Vector3(30.0, 0.0, 40.0))
	var chat := LifeDirector.game_at(&"chat", &"herbes_chat")
	assert_not_null(chat, "le chat est en cours")
	assert_true(chat.running)
	var first: LifeActor = chat.chaser
	assert_not_null(first)
	var prey: LifeActor = null
	for member: LifeActor in chat.members:
		if member != first:
			prey = member
	# La chasseuse rattrape une fuyarde : les rôles changent.
	first.set_position(prey.position() + Vector3(0.3, 0.0, 0.0))
	chat._count_left = 0.0
	await wait_physics_frames(3)
	assert_ne(chat.chaser, first, "nouvelle chasseuse")
	assert_eq(chat.role_of(first), &"fuyarde")
	# Le joueur approche : on le touche, c'est lui le chat.
	_player.global_position = chat.center() + Vector3(0.0, 0.0, 1.0)
	await wait_physics_frames(3)
	assert_true(chat.player_in, "le joueur est entré")
	assert_true(chat.player_chases, "c'est lui le chat")
	# Il touche une petite (contact) : elle devient le chat.
	var target := chat.members[0]
	_player.global_position = target.position() + Vector3(0.3, 0.0, 0.0)
	await wait_physics_frames(2)
	assert_false(chat.player_chases)
	assert_eq(chat.chaser, target)
	# Il s'éloigne : il sort.
	_player.global_position = Vector3(30.0, 0.0, 42.0)
	await wait_physics_frames(3)
	assert_false(chat.player_in, "sorti en s'éloignant")


func test_avalanche_falls_when_the_door_opens() -> void:
	_enter(RDC, &"nuit", Vector3(25.0, 0.0, 11.6))
	var game := LifeDirector.game_at(&"avalanche", &"porte_nygglatho")
	assert_not_null(game)
	assert_true(
		await _until(func() -> bool: return game.phase == game.Phase.SPYING, 15.0), "collées"
	)
	assert_ne(game.door, Vector3.INF, "la porte de Nygglatho")
	_player.global_position = game.door + Vector3(0.0, 0.0, 0.8)
	await wait_physics_frames(3)
	assert_eq(game.phase, game.Phase.FALLEN, "avalanche")
	for member: LifeActor in game.members:
		assert_eq(member.npc.visual.current_animation(), &"tombe", "%s tombe" % member.id)
	assert_true(await _until(func() -> bool: return game.phase == game.Phase.FLEEING, 4.0), "fuite")


func test_fairy_tower_stacks_on_willem() -> void:
	_enter(RDC, &"soir", Vector3(27.0, 0.0, 20.0))
	var tour := LifeDirector.game_at(&"tour", &"jeux_tour")
	assert_not_null(tour)
	var base: LifeActor = tour.base_actor()
	assert_eq(base.id, &"willem", "Willem est la base")
	assert_true(
		await _until(func() -> bool: return tour.stacked.size() >= 2, 30.0), "elles grimpent"
	)
	var first: LifeActor = tour.stacked[0]
	var second: LifeActor = tour.stacked[1]
	assert_eq(first.id, &"nephren", "Nephren d'abord, collée à son dos")
	assert_gt(second.position().y, first.position().y, "empilées en hauteur")
	assert_gt(second.position().z, base.position().z, "devant Willem à l'écran")
	assert_true(tour.on_player_interact(second), "le gag remplace le dialogue")


func test_corridor_race_and_scolding() -> void:
	_enter(RDC, &"soir", Vector3(19.0, 0.0, 17.0))
	var race := LifeDirector.game_at(&"course", &"couloir_course")
	assert_not_null(race)
	assert_eq(race.with_role(&"gronde").size(), 1, "Nygglatho gronde")
	assert_gte(race.runners().size(), 2)
	assert_true(
		await _until(
			func() -> bool:
				return race.events.any(func(e: Array) -> bool: return e[0] == &"scolded"),
			60.0
		),
		"on ne court pas dans les couloirs"
	)
	assert_true(
		await _until(
			func() -> bool:
				return race.events.any(func(e: Array) -> bool: return e[0] == &"race_won"),
			40.0
		),
		"une gagnante"
	)


func test_a_sword_touch_tags_without_harm() -> void:
	_enter(RELIEF, &"apres_midi", Vector3(30.0, 0.0, 40.0))
	var chat := LifeDirector.game_at(&"chat", &"herbes_chat")
	_player.global_position = chat.center() + Vector3(0.0, 0.0, 1.0)
	await wait_physics_frames(3)
	assert_true(chat.player_chases, "c'est lui le chat")
	var target: LifeActor = chat.members[1]
	_player.global_position = target.position() + Vector3(-1.2, 0.0, 0.0)
	_player.set_aim_direction(Vector3.RIGHT)
	_player.get_node(^"Combat").emit_signal(&"attack_started", null)
	assert_eq(chat.chaser, target, "touchée d'un coup d'épée")
	assert_eq(GameState.max_hp, GameState.DEFAULT_MAX_HP)
