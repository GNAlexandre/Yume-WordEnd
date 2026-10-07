extends "res://tests/stubs/q_quest_test.gd"
## Lot Q, marqueur de quête des PNJ (QuestMarker de src/npc/npc.tscn) : « ! » au-dessus de la
## bibliothécaire tant que la quête des pages est à prendre, rien pendant la collecte, « ? » quand
## les pages sont en poche, rien une fois la quête rendue ; caché pendant son dialogue ; au-dessus
## de la tête (hauteur du skin) ; « ? » au-dessus du PNJ d'une étape talk.

const NPC_SCENE := preload("res://src/npc/npc.tscn")
const LIBRARIAN := preload("res://data/npcs/librarian.tres")
const BLACKSMITH := preload("res://data/npcs/blacksmith.tres")


func _npc(data: NpcData) -> Npc:
	var npc: Npc = NPC_SCENE.instantiate()
	npc.data = data
	return add_child_autofree(npc)


func _marker(npc: Npc) -> String:
	return npc.quest_marker.text if npc.quest_marker.visible else ""


func test_librarian_marker_follows_the_pages_quest() -> void:
	var librarian := _npc(LIBRARIAN)
	assert_eq(_marker(librarian), "!", "quête des pages à prendre")
	assert_eq(librarian.quest_marker_kind(), QuestData.MARKER_AVAILABLE)
	start_quest(&"pages")
	await wait_process_frames(1)
	assert_eq(_marker(librarian), "", "quête en cours, pas encore les pages")
	GameState.add_item(&"page_fragment", 5)
	await wait_process_frames(1)
	assert_eq(_marker(librarian), "?", "les pages sont à rendre")
	assert_eq(librarian.quest_marker_kind(), QuestData.MARKER_TURN_IN)
	GameState.set_quest_state(&"pages", &"done")
	await wait_process_frames(1)
	assert_eq(_marker(librarian), "", "quête rendue")


func test_marker_is_hidden_during_its_own_dialogue() -> void:
	var librarian := _npc(LIBRARIAN)
	var blacksmith := _npc(BLACKSMITH)
	write_quest(
		{
			"id": "q",
			"title": "Q",
			"steps": [{"id": "a", "type": "talk", "npc": "blacksmith", "objective": "A"}],
		}
	)
	start_quest(&"q")
	await wait_process_frames(1)
	assert_eq(_marker(blacksmith), "?", "étape talk : à qui parler")
	EventBus.dialogue_started.emit(&"librarian")
	assert_eq(_marker(librarian), "", "caché pendant son dialogue")
	assert_eq(_marker(blacksmith), "?", "pas celui des autres")
	EventBus.dialogue_ended.emit(&"librarian")
	await wait_process_frames(1)
	assert_eq(_marker(librarian), "!", "revenu après")


func test_marker_sits_above_the_head_and_floats() -> void:
	var librarian := _npc(LIBRARIAN)
	var top := LIBRARIAN.skin.height_m
	assert_between(librarian.quest_marker.position.y, top + 0.2, top + 0.8, "au-dessus de la tête")
	var heights: Array[float] = []
	for _i: int in 20:
		await wait_process_frames(1)
		heights.append(librarian.quest_marker.position.y)
	assert_gt(heights.max() - heights.min(), 0.0, "il flotte doucement")
	assert_lt(heights.max() - heights.min(), 0.2, "sans s'éloigner")
	assert_eq(librarian.quest_marker.billboard, BaseMaterial3D.BILLBOARD_ENABLED, "face caméra")


func test_npc_without_data_has_no_marker() -> void:
	var npc := _npc(null)
	assert_eq(_marker(npc), "")
	assert_eq(npc.quest_marker_kind(), &"")
