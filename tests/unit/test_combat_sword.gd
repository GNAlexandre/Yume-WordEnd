extends GutTest
## PlayerCombat, épée : images « coup » seulement, une touche par coup et par cible, jamais sa
## propre équipe, enchaînement sword_1 → sword_2 → sword_3, secteur de 90° × 1,2 m devant
## (-Z de Combat), 3e coup qui repousse davantage. Joueur de test : tests/stubs/l4_player_rig.tscn
## (structure de player.tscn, visuel factice piloté par emit_frame / finish).

const RIG := preload("res://tests/stubs/l4_player_rig.tscn")
const DUMMY := preload("res://tests/stubs/dummy.tscn")
const PLAYER_STUB := preload("res://tests/stubs/player_stub.tscn")

var _combat: PlayerCombat
var _visual: CharacterVisual
var _sword: Hitbox


func before_each() -> void:
	GameState.reset()
	var rig: Node3D = add_child_autofree(RIG.instantiate())
	_combat = rig.get_node(^"Combat") as PlayerCombat
	_visual = rig.get_node(^"Visual") as CharacterVisual
	_sword = rig.get_node(^"Combat/SwordHitbox") as Hitbox
	_visual.set(&"forced_hit_frames", {&"attaque": [1, 2, 3]})


func _dummy(at: Vector3, hp: int = 10) -> Node3D:
	var dummy: Node3D = add_child_autofree(DUMMY.instantiate())
	dummy.position = at
	(dummy.get_node(^"Health") as Health).max_hp = hp
	return dummy


func _hp(target: Node) -> int:
	return (target.get_node(^"Health") as Health).current


## Un coup complet : attack(), images données (attente physique entre chacune), fin.
func _swing(frames: Array[int]) -> void:
	_combat.attack()
	for frame: int in frames:
		_visual.call(&"emit_frame", &"attaque", frame)
		await wait_physics_frames(3)
	_visual.call(&"finish", &"attaque")


func test_damage_only_on_coup_frames() -> void:
	var dummy := _dummy(Vector3(0, 0, -1))
	await wait_physics_frames(3)
	_combat.attack()
	_visual.call(&"emit_frame", &"attaque", 0)
	await wait_physics_frames(4)
	assert_false(_sword.is_active(), "image 0 : épée inactive")
	assert_eq(_hp(dummy), 10, "aucun dégât hors des images coup")
	_visual.call(&"emit_frame", &"attaque", 1)
	await wait_physics_frames(3)
	assert_true(_sword.is_active(), "image 1 (coup) : épée active")
	assert_eq(_hp(dummy), 9, "1 dégât sur une image coup")
	_visual.call(&"finish", &"attaque")
	assert_false(_sword.is_active(), "fin de l'animation : épée inactive")


func test_coup_frames_come_from_the_visual() -> void:
	_visual.set(&"forced_hit_frames", {&"attaque": [2]})
	var dummy := _dummy(Vector3(0, 0, -1))
	await wait_physics_frames(3)
	_combat.attack()
	_visual.call(&"emit_frame", &"attaque", 1)
	await wait_physics_frames(3)
	assert_eq(_hp(dummy), 10, "image 1 hors de hit_frames : refusé")
	_visual.call(&"emit_frame", &"attaque", 2)
	await wait_physics_frames(3)
	assert_eq(_hp(dummy), 9)


func test_one_swing_hits_each_target_once() -> void:
	var dummy := _dummy(Vector3(0, 0, -1))
	await wait_physics_frames(3)
	await _swing([0, 1, 2, 3])
	assert_eq(_hp(dummy), 9, "trois images coup, un seul dégât")
	assert_eq((dummy.get(&"hits") as Array).size(), 1)


func test_split_coup_frames_keep_one_activation() -> void:
	_visual.set(&"forced_hit_frames", {&"attaque": [1, 3]})
	var dummy := _dummy(Vector3(0, 0, -1))
	await wait_physics_frames(3)
	_combat.attack()
	_visual.call(&"emit_frame", &"attaque", 1)
	await wait_physics_frames(3)
	_visual.call(&"emit_frame", &"attaque", 2)
	assert_false(_sword.is_active(), "image 2 : pas de coup")
	await wait_physics_frames(3)
	_visual.call(&"emit_frame", &"attaque", 3)
	await wait_physics_frames(3)
	assert_true(_sword.is_active())
	assert_eq(_hp(dummy), 9, "même coup : pas de seconde touche")


func test_enemy_without_invincibility_takes_successive_swings() -> void:
	var dummy := _dummy(Vector3(0, 0, -1))
	await wait_physics_frames(3)
	await _swing([1])
	await _swing([1])
	assert_eq(_hp(dummy), 8, "deux coups, deux dégâts")


func test_sword_never_hits_its_own_team() -> void:
	var ally: Node3D = add_child_autofree(PLAYER_STUB.instantiate())
	ally.position = Vector3(0, 0, -1)
	await wait_physics_frames(3)
	await _swing([1, 2, 3])
	assert_eq(_hp(ally), 5, "équipe player : jamais touché")


func test_combo_chains_then_restarts() -> void:
	for expected: StringName in [&"sword_1", &"sword_2", &"sword_3"]:
		_combat.attack()
		assert_eq(_combat.current_attack().id, expected)
		assert_eq(_sword.attack.id, expected, "la Hitbox porte l'AttackData du coup")
		_visual.call(&"finish", &"attaque")
	_combat.attack()
	assert_false(_combat.is_busy(), "recharge du 3e coup (sword_3.cooldown)")
	simulate(_combat, 4, 0.1)
	_combat.attack()
	assert_eq(_combat.current_attack().id, &"sword_1", "après sword_3 : retour à sword_1")


func test_combo_resets_after_the_window() -> void:
	_combat.attack()
	_visual.call(&"finish", &"attaque")
	simulate(_combat, 1, _combat.combo_window + 0.05)
	_combat.attack()
	assert_eq(_combat.current_attack().id, &"sword_1", "fenêtre dépassée : sword_1")
	_visual.call(&"finish", &"attaque")
	simulate(_combat, 1, _combat.combo_window - 0.1)
	_combat.attack()
	assert_eq(_combat.current_attack().id, &"sword_2", "dans la fenêtre : sword_2")


func test_press_during_swing_queues_next() -> void:
	_combat.attack()
	_combat.attack()
	assert_eq(_combat.current_attack().id, &"sword_1")
	_visual.call(&"finish", &"attaque")
	assert_eq(_combat.current_attack().id, &"sword_2", "enchaîné sans repasser au repos")
	assert_true(_combat.is_busy())


func test_third_swing_pushes_harder() -> void:
	var dummy := _dummy(Vector3(0, 0, -1))
	await wait_physics_frames(3)
	for _i in 3:
		await _swing([1])
	var hits: Array = dummy.get(&"hits")
	assert_eq(hits.size(), 3)
	if hits.size() == 3:
		assert_eq((hits[2] as AttackData).id, &"sword_3")
		assert_gt((hits[2] as AttackData).knockback, (hits[0] as AttackData).knockback)
		assert_gt((hits[2] as AttackData).knockback, (hits[1] as AttackData).knockback)


func test_reach_is_a_90_degree_sector_of_1_2_m() -> void:
	var inside: Array[Node3D] = [
		_dummy(Vector3(0, 0, -1)), _dummy(Vector3(0.6, 0, -0.8)), _dummy(Vector3(-0.6, 0, -0.8))
	]
	var outside: Array[Node3D] = [
		_dummy(Vector3(0, 0, -2)),
		_dummy(Vector3(0, 0, 1)),
		_dummy(Vector3(1.1, 0, -0.2)),
		_dummy(Vector3(-1.1, 0, -0.2)),
	]
	await wait_physics_frames(3)
	await _swing([1, 2, 3])
	for dummy: Node3D in inside:
		assert_eq(_hp(dummy), 9, "dans le secteur : %s" % dummy.position)
	for dummy: Node3D in outside:
		assert_eq(_hp(dummy), 10, "hors du secteur : %s" % dummy.position)


func test_sector_follows_combat_rotation() -> void:
	var front := _dummy(Vector3(1, 0, 0))
	var former_front := _dummy(Vector3(0, 0, -1))
	_combat.rotation.y = -PI / 2.0  # -Z de Combat vers +X
	await wait_physics_frames(3)
	await _swing([1])
	assert_eq(_hp(front), 9, "devant après rotation")
	assert_eq(_hp(former_front), 10)


func test_damage_interrupts_the_swing() -> void:
	var health := _combat.get_node(^"../Health") as Health
	_combat.attack()
	_combat.attack()
	_visual.call(&"emit_frame", &"attaque", 1)
	assert_true(_sword.is_active())
	health.take_damage(1, null)
	assert_eq(_combat.current_state(), &"hurt")
	assert_false(_sword.is_active(), "épée coupée par les dégâts")
	assert_null(_combat.current_attack())
	_visual.call(&"finish", &"attaque")
	assert_eq(_combat.current_state(), &"hurt", "l'appui mis en file est oublié")
