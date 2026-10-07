extends GutTest
## Acte 1, intégration : les rejetons des bois (ennemis libres de
## src/enemies/placements/forest.tscn, racine src/enemies/free_enemies.gd) ne bloquent jamais
## l'étape rejetons d'act1_main (quatre à abattre, quatre dans les bois), dans la vraie partie
## (src/game.tscn : île, QuestTracker) :
## tués avant l'étape, ils réapparaissent quand elle commence ; tué hors des bois pendant
## l'étape (ça ne compte pas), un rejeton revient quand le joueur rentre dans les bois. Hors d'une
## étape qui les vise, un rejeton tué reste mort jusqu'au rechargement de la partie.

const GAME_SCENE := preload("res://src/game.tscn")
const QUEST := &"act1_main"

var _game: Node3D
var _player: Node3D
var _enemies: Node3D
var _previous_zone: StringName


func before_each() -> void:
	_previous_zone = WorldManager.current_zone()
	GameState.reset()
	_game = add_child_autofree(GAME_SCENE.instantiate())
	await wait_physics_frames(3)
	_player = _game.get_node(^"Player") as Node3D
	_enemies = _game.get_node(^"Island/Zones/forest/Enemies") as Node3D


func after_each() -> void:
	if WorldManager.current_zone() != _previous_zone:
		EventBus.zone_entered.emit(_previous_zone)
	GameState.reset()


func after_all() -> void:
	GameState.reset()


## Rejetons vivants des bois.
func _alive() -> Array[Enemy]:
	var alive: Array[Enemy] = []
	for child: Node in _enemies.get_children():
		var enemy := child as Enemy
		if enemy != null and not enemy.is_dead() and not enemy.is_queued_for_deletion():
			alive.append(enemy)
	return alive


## Le joueur entre dans la zone (comme les Bounds de la zone), puis une image passe.
func _enter(zone_id: StringName) -> void:
	EventBus.zone_entered.emit(zone_id)
	await wait_process_frames(2)


## Conversation (début, fin) avec un PNJ : valide une étape talk.
func _chat(npc_id: StringName) -> void:
	EventBus.dialogue_started.emit(npc_id)
	EventBus.dialogue_ended.emit(npc_id)


## Abat count rejetons vivants (dans la zone où se trouve le joueur).
func _kill(count: int) -> void:
	for enemy: Enemy in _alive().slice(0, count):
		enemy.health.take_damage(enemy.health.current, _player)
	await wait_process_frames(2)


## Nygglatho puis Willem : l'étape to_the_woods (les bois).
func _to_the_woods() -> void:
	_chat(&"nygglatho")
	_chat(&"willem")
	assert_eq(GameState.quest_step(QUEST), &"to_the_woods")


func test_the_forest_placement_respawns_with_its_zone() -> void:
	assert_eq(_enemies.call(&"zone_id"), &"forest")
	assert_eq(_alive().size(), 4, "quatre rejetons dans les bois")
	assert_false(_enemies.call(&"is_hunted"), "matin : personne ne les chasse")
	for zone_id: StringName in [&"village", &"dunes", &"beach", &"hill"]:
		var placement := _game.get_node(NodePath("Island/Zones/%s/Enemies" % zone_id))
		assert_eq(placement.call(&"zone_id"), zone_id, "%s : même racine" % zone_id)
		assert_eq(placement.call(&"respawn_dead"), 0, "%s : aucun ennemi libre" % zone_id)


func test_rejetons_killed_before_the_step_come_back_when_it_begins() -> void:
	assert_eq(GameState.quest_step(QUEST), &"morning", "l'acte 1 commence")
	# Le matin, le joueur file aux bois avant d'avoir vu Nygglatho, et les abat tous.
	await _enter(&"forest")
	await _kill(4)
	assert_eq(_alive().size(), 0, "plus de rejetons")
	await wait_seconds(2.6)
	assert_eq(_enemies.get_child_count(), 0, "les corps ont disparu")
	await _enter(&"village")
	await _enter(&"forest")
	assert_eq(_alive().size(), 0, "hors de l'étape : ils restent morts")
	await _enter(&"village")
	_to_the_woods()
	# Les bois : l'étape rejetons commence, les quatre sont revenus.
	await _enter(&"forest")
	assert_eq(GameState.quest_step(QUEST), &"rejetons")
	assert_eq(_alive().size(), 4, "les rejetons sont revenus pour l'étape")
	var names: Array[String] = []
	for enemy: Enemy in _alive():
		names.append(String(enemy.name))
	names.sort()
	assert_eq(
		names,
		(
			[
				"forest_timere_normal_1",
				"forest_timere_runner_1",
				"forest_timere_small_1",
				"forest_timere_small_2",
			]
			as Array[String]
		),
		"à leur place, sous leur nom"
	)
	await _kill(4)
	assert_eq(GameState.quest_step(QUEST), &"pannibal", "étape menée à bout")


func test_a_rejeton_killed_outside_the_woods_comes_back() -> void:
	_to_the_woods()
	await _enter(&"forest")
	assert_eq(GameState.quest_step(QUEST), &"rejetons")
	await _kill(3)
	assert_eq(GameState.quest_step_count(QUEST), 3)
	# Le dernier poursuit le joueur jusqu'au Couchant et y tombe : ça ne compte pas.
	await _enter(&"dunes")
	await _kill(1)
	assert_eq(GameState.quest_step_count(QUEST), 3, "hors des bois : ne compte pas")
	assert_eq(_alive().size(), 0)
	assert_eq(GameState.quest_step(QUEST), &"rejetons", "l'étape attend")
	# De retour dans les bois : les rejetons tués sont revenus, l'étape peut finir.
	await _enter(&"forest")
	assert_eq(_alive().size(), 4, "les rejetons tués sont revenus")
	await _kill(1)
	assert_eq(GameState.quest_step(QUEST), &"pannibal", "le quatrième rejeton")
	# L'étape finie, les bois se vident pour de bon (jusqu'au rechargement).
	await _kill(3)
	await _enter(&"village")
	await _enter(&"forest")
	assert_eq(_alive().size(), 0, "plus d'étape qui les vise : ils restent morts")
