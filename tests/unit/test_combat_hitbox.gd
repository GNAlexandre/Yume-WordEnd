extends GutTest
## Hitbox / Hurtbox : équipes, une touche par activation (resume() garde la liste), signaux,
## attaquant transmis, forme en secteur.

const DUMMY := preload("res://tests/stubs/dummy.tscn")
const HITBOX := preload("res://src/combat/hitbox.tscn")
const BITE := preload("res://data/attacks/bite.tres")
const SWORD := preload("res://data/attacks/sword_1.tres")


func _hitbox(attack: AttackData, team: StringName) -> Hitbox:
	var hitbox: Hitbox = add_child_autofree(HITBOX.instantiate())
	hitbox.attack = attack
	hitbox.team = team
	hitbox.position = Vector3(0, 0.6, 0)
	return hitbox


func test_enemy_hitbox_ignores_enemies() -> void:
	var dummy: Node3D = add_child_autofree(DUMMY.instantiate())
	var bite := _hitbox(BITE, &"enemy")
	await wait_physics_frames(3)
	bite.activate()
	await wait_physics_frames(3)
	assert_eq((dummy.get_node(^"Health") as Health).current, 3, "équipe enemy : jamais touché")


func test_hit_signals_and_attacker() -> void:
	var dummy: Node3D = add_child_autofree(DUMMY.instantiate())
	var sword := _hitbox(SWORD, &"player")
	var attacker: Node3D = add_child_autofree(Node3D.new())
	sword.source = attacker
	var hurtbox := dummy.get_node(^"Hurtbox") as Hurtbox
	watch_signals(sword)
	watch_signals(hurtbox)
	await wait_physics_frames(3)
	sword.activate()
	await wait_physics_frames(2)
	assert_signal_emitted_with_parameters(sword, "hit_landed", [hurtbox])
	assert_signal_emitted_with_parameters(hurtbox, "hit_taken", [SWORD, attacker])
	attacker.free()
	sword.activate()
	await wait_physics_frames(2)
	assert_signal_emit_count(hurtbox, "hit_taken", 2, "attaquant libéré : la Hitbox reste sûre")


func test_resume_keeps_the_hit_list() -> void:
	var dummy: Node3D = add_child_autofree(DUMMY.instantiate())
	var health := dummy.get_node(^"Health") as Health
	var sword := _hitbox(SWORD, &"player")
	await wait_physics_frames(3)
	sword.activate()
	await wait_physics_frames(2)
	sword.deactivate()
	sword.resume()
	assert_true(sword.is_active())
	await wait_physics_frames(3)
	assert_eq(health.current, 2, "resume() : pas de seconde touche")
	sword.activate()
	await wait_physics_frames(2)
	assert_eq(health.current, 1, "activate() : nouvelle activation")


func test_sector_points() -> void:
	var points := Hitbox.sector_points(1.2, 90.0, 1.4)
	assert_true(points.has(Vector3(0, -0.7, 0)) and points.has(Vector3(0, 0.7, 0)), "pointe")
	for point: Vector3 in points:
		var flat := Vector2(point.x, point.z)
		if flat.length() > 0.001:
			assert_almost_eq(flat.length(), 1.2, 0.001, "sur l'arc")
			assert_between(rad_to_deg(Vector2(0, -1).angle_to(flat)), -45.001, 45.001, "90° devant")
