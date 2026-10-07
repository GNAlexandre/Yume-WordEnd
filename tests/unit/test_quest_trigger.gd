extends "res://tests/stubs/q_quest_test.gd"
## Lot Q, déclencheur de lieu (src/quests/quest_trigger.tscn) : le joueur qui entre émet
## trigger_entered et pose le drapeau ; les autres corps sont ignorés ; identifiant par défaut,
## volume réglable propre à chaque déclencheur ; étape reach validée, y compris quand elle
## commence alors que le joueur est déjà dedans.

const TRIGGER := preload("res://src/quests/quest_trigger.tscn")
const PLAYER_STUB := preload("res://tests/stubs/player_stub.tscn")
## Loin de tout déclencheur.
const AWAY := Vector3(40.0, 0.0, 0.0)

var _entered: Array[StringName] = []


func before_each() -> void:
	super()
	_entered.clear()
	EventBus.trigger_entered.connect(_on_trigger_entered)


func after_each() -> void:
	EventBus.trigger_entered.disconnect(_on_trigger_entered)
	super()


func _on_trigger_entered(trigger_id: StringName) -> void:
	_entered.append(trigger_id)


func _trigger(trigger_id: StringName = &"rock") -> QuestTrigger:
	var trigger: QuestTrigger = TRIGGER.instantiate()
	trigger.trigger_id = trigger_id
	return add_child_autofree(trigger)


func _player(at: Vector3 = AWAY) -> CharacterBody3D:
	var player: CharacterBody3D = PLAYER_STUB.instantiate()
	player.position = at
	return add_child_autofree(player)


func test_player_entering_emits_and_sets_the_flag() -> void:
	var trigger := _trigger()
	trigger.set_flag = &"rock_seen"
	var player := _player()
	await wait_physics_frames(3)
	assert_eq(_entered, [] as Array[StringName], "joueur loin")
	player.position = Vector3(0.8, 0.0, 0.5)
	await wait_physics_frames(3)
	assert_eq(_entered, [&"rock"] as Array[StringName])
	assert_true(GameState.has_flag(&"rock_seen"), "drapeau posé")
	assert_true(trigger.has_player())
	player.position = AWAY
	await wait_physics_frames(3)
	player.position = Vector3.ZERO
	await wait_physics_frames(3)
	assert_eq(_entered.size(), 2, "chaque entrée")


func test_other_bodies_are_ignored() -> void:
	_trigger()
	var stranger: CharacterBody3D = _player()
	stranger.remove_from_group(&"player")
	await wait_physics_frames(2)
	stranger.position = Vector3.ZERO
	await wait_physics_frames(3)
	assert_eq(_entered, [] as Array[StringName], "pas le joueur")


func test_id_defaults_to_the_node_name() -> void:
	var trigger: QuestTrigger = TRIGGER.instantiate()
	trigger.name = "beach_rock"
	add_child_autofree(trigger)
	assert_eq(trigger.id(), &"beach_rock")
	trigger.trigger_id = &"other"
	assert_eq(trigger.id(), &"other")


func test_volume_is_a_cylinder_of_its_own() -> void:
	var wide := _trigger(&"wide")
	wide.radius = 3.5
	wide.height = 2.0
	var narrow := _trigger(&"narrow")
	var wide_shape := wide.get_node(^"CollisionShape3D") as CollisionShape3D
	var narrow_shape := narrow.get_node(^"CollisionShape3D") as CollisionShape3D
	var cylinder := wide_shape.shape as CylinderShape3D
	assert_eq([cylinder.radius, cylinder.height], [3.5, 2.0])
	assert_almost_eq(wide_shape.position.y, 1.0, 0.001, "posé sur le sol")
	assert_ne(wide_shape.shape, narrow_shape.shape, "forme propre à chaque déclencheur")
	assert_eq((narrow_shape.shape as CylinderShape3D).radius, 2.0, "rayon par défaut")
	assert_eq(wide.collision_mask, 2, "masque player")
	assert_eq(wide.collision_layer, 0)


func test_reach_step_validated_by_walking_in() -> void:
	write_quest(
		{
			"id": "q",
			"title": "Q",
			"steps":
			[
				{"id": "rock", "type": "reach", "trigger": "rock", "objective": "Rocher"},
				{"id": "end", "type": "flag", "flag": "end", "objective": "Fin"},
			],
		}
	)
	start_quest(&"q")
	_trigger()
	var player := _player()
	await wait_physics_frames(2)
	player.position = Vector3.ZERO
	await wait_physics_frames(3)
	assert_eq(step_of(&"q"), &"end")


func test_refires_when_its_step_starts_with_the_player_inside() -> void:
	write_quest(
		{
			"id": "q",
			"title": "Q",
			"steps":
			[
				{"id": "talk", "type": "talk", "npc": "child", "objective": "Parler"},
				{"id": "rock", "type": "reach", "trigger": "rock", "objective": "Rocher"},
				{"id": "end", "type": "flag", "flag": "end", "objective": "Fin"},
			],
		}
	)
	_trigger()
	_player(Vector3.ZERO)
	await wait_physics_frames(3)
	start_quest(&"q")
	_entered.clear()
	chat(&"child")
	assert_eq(step_of(&"q"), &"rock", "le joueur est déjà dans le déclencheur")
	await wait_process_frames(2)
	assert_eq(_entered, [&"rock"] as Array[StringName], "il se redéclenche")
	assert_eq(step_of(&"q"), &"end")
