extends GutTest
## (E8) L'arme de Chtholly hors des scènes : un bâton, sans charge de venenum (ACTE1.md, 3.0 ;
## décision de D2). Le récit la choisit : Player.set_weapon(&"baton" | &"seniorious").
## PlayerCombat : set_weapon, can_charge, parade (la touche de charge tient la parade bâton en
## main), enchaînement des trois coups du bâton (data/attacks/stick_*.tres).

const RIG := preload("res://tests/stubs/l4_player_rig.tscn")
const PLAYER_SCENE := preload("res://src/player/player.tscn")

var _combat: PlayerCombat
var _visual: CharacterVisual
var _guards: Array[bool] = []
var _weapons: Array[StringName] = []
var _attacks: Array[String] = []


func before_each() -> void:
	GameState.reset()
	_guards.clear()
	_weapons.clear()
	_attacks.clear()
	var rig: Node3D = add_child_autofree(RIG.instantiate())
	_combat = rig.get_node(^"Combat") as PlayerCombat
	_visual = rig.get_node(^"Visual") as CharacterVisual
	_combat.guard_changed.connect(func(guarding: bool) -> void: _guards.append(guarding))
	_combat.weapon_changed.connect(func(weapon: StringName) -> void: _weapons.append(weapon))
	_combat.attack_started.connect(func(attack: AttackData) -> void: _attacks.append(attack.id))


func test_seniorious_is_the_default_and_keeps_its_charge() -> void:
	assert_eq(_combat.weapon(), &"seniorious")
	assert_true(_combat.can_charge())
	_combat.charge_begin()
	assert_eq(_combat.current_state(), &"charge", "la charge de venenum")
	assert_false(_combat.is_guarding())
	assert_eq(_guards.size(), 0)


func test_set_weapon_changes_the_weapon_and_refuses_unknown_ones() -> void:
	assert_true(_combat.set_weapon(&"baton"))
	assert_eq(_combat.weapon(), &"baton")
	assert_eq(_weapons, [&"baton"] as Array[StringName], "weapon_changed")
	assert_true(_combat.set_weapon(&"baton"), "déjà en main : rien ne change")
	assert_eq(_weapons.size(), 1)
	assert_false(_combat.set_weapon(&"hache"), "arme inconnue")
	assert_eq(_combat.weapon(), &"baton")
	assert_true(_combat.set_weapon(&"seniorious"))
	assert_eq(_combat.weapon(), &"seniorious")
	assert_eq(_weapons.size(), 2)


func test_the_player_exposes_set_weapon() -> void:
	var player: Player = add_child_autofree(PLAYER_SCENE.instantiate())
	await wait_physics_frames(1)
	assert_eq(player.weapon(), &"seniorious")
	assert_true(player.set_weapon(&"baton"))
	assert_eq(player.weapon(), &"baton")
	assert_false(player.combat.can_charge())
	assert_false(player.set_weapon(&"inconnue"))


func test_the_stick_has_no_charge_but_a_guard() -> void:
	_combat.set_weapon(&"baton")
	assert_false(_combat.can_charge(), "pas de charge de venenum")
	var progress: Array[float] = []
	EventBus.charge_progress.connect(func(ratio: float) -> void: progress.append(ratio))
	_combat.charge_begin()
	assert_eq(_combat.current_state(), &"idle", "aucun état de charge")
	assert_true(_combat.is_guarding(), "la parade est levée")
	assert_eq(_guards, [true] as Array[bool])
	simulate(_combat, 60, 1.0 / 60.0)
	assert_true(_combat.is_guarding(), "tenue tant que la touche l'est")
	_combat.charge_release()
	assert_false(_combat.is_guarding())
	assert_eq(_guards, [true, false] as Array[bool], "guard_changed au changement seulement")
	assert_eq(progress.size(), 0, "aucune jauge de charge, aucune onde")
	assert_eq(_combat.wave_cooldown_left(), 0.0)


func test_you_cannot_swing_while_guarding_and_the_guard_drops_when_hit() -> void:
	_combat.set_weapon(&"baton")
	_combat.charge_begin()
	_combat.attack()
	assert_eq(_combat.current_state(), &"idle", "la parade empêche de frapper")
	_combat.charge_release()
	_combat.attack()
	assert_eq(_combat.current_state(), &"attack")
	_combat.charge_begin()
	assert_false(_combat.is_guarding(), "pas de parade pendant un coup")


func test_the_stick_chains_three_blows_from_its_own_data() -> void:
	_combat.set_weapon(&"baton")
	for expected: StringName in [&"stick_1", &"stick_2", &"stick_3"]:
		_combat.attack()
		assert_eq(_combat.current_attack().id, expected, "le coup du bâton")
		_visual.call(&"finish", &"attaque")
	assert_eq(_attacks, ["stick_1", "stick_2", "stick_3"] as Array[String])
	var stick := load("res://data/attacks/stick_1.tres") as AttackData
	var sword := load("res://data/attacks/sword_1.tres") as AttackData
	assert_eq(stick.damage, sword.damage, "mêmes chiffres : la faune reste combattable")
	assert_eq(stick.animation, &"attaque", "sans planche _stick : l'animation d'épée")


func test_changing_weapon_during_a_charge_cancels_it() -> void:
	_combat.charge_begin()
	assert_eq(_combat.current_state(), &"charge")
	_combat.set_weapon(&"baton")
	assert_eq(_combat.current_state(), &"idle", "la charge est interrompue")
	assert_false(_combat.is_busy())


func test_the_guard_animation_falls_back_to_the_charge_frame() -> void:
	_combat.set_weapon(&"baton")
	assert_eq(_combat.guard_animation(), &"charge", "la planche n'a pas encore « pare »")
