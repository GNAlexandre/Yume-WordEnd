extends "res://tests/stubs/q_quest_test.gd"
## Lot Q, marqueur de quête des PNJ (QuestMarker de src/npc/npc.tscn) : « ! » au-dessus de
## Nephren tant que le livre d'images est à prendre (après avoir salué Willem), rien pendant la
## collecte, « ? » quand les pages sont en poche, rien une fois la quête rendue ; caché pendant son
## dialogue ; au-dessus de la tête (hauteur du skin) ; « ? » au-dessus du PNJ d'une étape talk.

const NPC_SCENE := preload("res://src/npc/npc.tscn")
const NEPHREN := preload("res://data/npcs/nephren.tres")
const COLLON := preload("res://data/npcs/collon.tres")


func _npc(data: NpcData) -> Npc:
	var npc: Npc = NPC_SCENE.instantiate()
	npc.data = data
	return add_child_autofree(npc)


func _marker(npc: Npc) -> String:
	return npc.quest_marker.text if npc.quest_marker.visible else ""


func test_nephren_marker_follows_the_picture_book_quest() -> void:
	var nephren := _npc(NEPHREN)
	assert_eq(_marker(nephren), "", "pas avant d'avoir salué Willem")
	GameState.set_flag(&"met_willem")
	await wait_process_frames(1)
	assert_eq(_marker(nephren), "!", "livre d'images à prendre")
	assert_eq(nephren.quest_marker_kind(), QuestData.MARKER_AVAILABLE)
	start_quest(&"picture_book")
	await wait_process_frames(1)
	assert_eq(_marker(nephren), "", "quête en cours, pas encore les pages")
	GameState.add_item(&"page_fragment", 5)
	await wait_process_frames(1)
	assert_eq(_marker(nephren), "?", "les pages sont à rendre")
	assert_eq(nephren.quest_marker_kind(), QuestData.MARKER_TURN_IN)
	GameState.set_quest_state(&"picture_book", &"done")
	await wait_process_frames(1)
	assert_eq(_marker(nephren), "", "quête rendue")


func test_marker_is_hidden_during_its_own_dialogue() -> void:
	GameState.set_flag(&"met_willem")
	var nephren := _npc(NEPHREN)
	var collon := _npc(COLLON)
	write_quest(
		{
			"id": "q",
			"title": "Q",
			"steps": [{"id": "a", "type": "talk", "npc": "collon", "objective": "A"}],
		}
	)
	start_quest(&"q")
	await wait_process_frames(1)
	assert_eq(_marker(collon), "?", "étape talk : à qui parler")
	EventBus.dialogue_started.emit(&"nephren")
	assert_eq(_marker(nephren), "", "caché pendant son dialogue")
	assert_eq(_marker(collon), "?", "pas celui des autres")
	EventBus.dialogue_ended.emit(&"nephren")
	await wait_process_frames(1)
	assert_eq(_marker(nephren), "!", "revenu après")


func test_marker_sits_above_the_head_and_floats() -> void:
	GameState.set_flag(&"met_willem")
	var nephren := _npc(NEPHREN)
	var top := NEPHREN.skin.height_m
	assert_between(nephren.quest_marker.position.y, top + 0.2, top + 0.8, "au-dessus de la tête")
	var heights: Array[float] = []
	for _i: int in 20:
		await wait_process_frames(1)
		heights.append(nephren.quest_marker.position.y)
	assert_gt(heights.max() - heights.min(), 0.0, "il flotte doucement")
	assert_lt(heights.max() - heights.min(), 0.2, "sans s'éloigner")
	assert_eq(nephren.quest_marker.billboard, BaseMaterial3D.BILLBOARD_ENABLED, "face caméra")


func test_npc_without_data_has_no_marker() -> void:
	var npc := _npc(null)
	assert_eq(_marker(npc), "")
	assert_eq(npc.quest_marker_kind(), &"")
