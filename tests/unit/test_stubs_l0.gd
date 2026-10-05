extends GutTest
## Stubs du Lot 0 et règle « une Hitbox ne touche chaque Hurtbox qu'une fois par activation ».
## Sert d'exemple d'utilisation des stubs pour les lots (L4, L5, L6, L7).

const VISUAL_STUB := preload("res://tests/stubs/visual_stub.tscn")
const DUMMY := preload("res://tests/stubs/dummy.tscn")
const PLAYER_STUB := preload("res://tests/stubs/player_stub.tscn")
const HITBOX := preload("res://src/combat/hitbox.tscn")
const SWORD := preload("res://data/attacks/sword_1.tres")


func test_visual_stub_emits_on_demand() -> void:
	var visual: CharacterVisual = add_child_autofree(VISUAL_STUB.instantiate())
	visual.set("forced_hit_frames", {&"attaque": [1, 2, 3]})
	assert_eq(visual.hit_frames(&"attaque"), [1, 2, 3] as Array[int])
	watch_signals(visual)
	visual.call(&"emit_frame", &"attaque", 2)
	visual.call(&"finish", &"attaque")
	assert_signal_emitted_with_parameters(visual, "frame_changed", [&"attaque", 2])
	assert_signal_emitted_with_parameters(visual, "animation_finished", [&"attaque"])


func test_visual_reads_hit_frames_from_sheet() -> void:
	var visual: CharacterVisual = add_child_autofree(VISUAL_STUB.instantiate())
	visual.set_skin(SkinRegistry.default_skin())
	assert_eq(visual.hit_frames(&"attaque"), [1, 2, 3] as Array[int], "coup de chtholly.json")
	assert_eq(visual.wave_frame(&"charge"), 3, "onde de chtholly.json")
	assert_true(visual.has_animation(&"mort"))


func test_hitbox_hits_each_hurtbox_once_per_activation() -> void:
	var dummy: CharacterBody3D = add_child_autofree(DUMMY.instantiate())
	var hitbox: Hitbox = add_child_autofree(HITBOX.instantiate())
	hitbox.attack = SWORD
	hitbox.team = &"player"
	hitbox.position = Vector3(0, 0.5, 0)
	await wait_physics_frames(3)
	var health := dummy.get_node(^"Health") as Health
	hitbox.activate()
	await wait_physics_frames(5)
	assert_eq(health.current, 2, "un seul dégât malgré cinq images de chevauchement")
	hitbox.deactivate()
	hitbox.activate()
	await wait_physics_frames(2)
	assert_eq(health.current, 1, "nouvelle activation : nouveau coup")


func test_hitbox_ignores_same_team() -> void:
	var player: CharacterBody3D = add_child_autofree(PLAYER_STUB.instantiate())
	var hitbox: Hitbox = add_child_autofree(HITBOX.instantiate())
	hitbox.attack = SWORD
	hitbox.team = &"player"
	hitbox.position = Vector3(0, 0.7, 0)
	await wait_physics_frames(3)
	hitbox.activate()
	await wait_physics_frames(3)
	assert_eq((player.get_node(^"Health") as Health).current, 5, "pas de coup sur sa propre équipe")
