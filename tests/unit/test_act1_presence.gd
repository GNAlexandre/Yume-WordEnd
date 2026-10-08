extends "res://tests/stubs/q_quest_test.gd"
## Acte 1, présence des PNJ selon l'histoire (NpcData.visible_if, docs/QUETES.md) : act1_main
## jouée étape par étape avec le vrai moteur. Aucune étape ne devient impossible : à chaque étape
## « parler », le PNJ à qui parler est là et posé dans la zone de l'étape (HISTOIRE.md 3.1 et
## 3.3, fichiers src/npc/placements/<zone>.tscn) ; chaque déclencheur, zone ou arène visé est dans
## la zone de l'étape. Un seul Willem à la fois pendant l'acte : à l'entrepôt, sauf au terrain
## d'entraînement (training) et au sommet de la colline (promise) ; Limeskin au port à partir du
## bord du Couchant (le Barocupot vient la chercher). Après la promesse, Willem est à l'entrepôt
## et sur la colline (les derniers soirs avant le départ), et les PNJ des quêtes secondaires sont
## tous là ; pendant l'acte, ils le sont aussi, sauf Willem pendant training et promise.

const QUEST := &"act1_main"
## Zone de chaque étape d'act1_main (HISTOIRE.md 3.1, colonne « Zone ») : une étape ajoutée à la
## quête doit déclarer la sienne ici.
const STEP_ZONES := {
	&"morning": &"village",
	&"new_officer": &"village",
	&"to_the_woods": &"forest",
	&"rejetons": &"forest",
	&"pannibal": &"forest",
	&"report": &"village",
	&"first_vigil": &"dunes",
	&"fever": &"village",
	&"training": &"forest",
	&"the_edge": &"dunes",
	&"barocupot": &"beach",
	&"starry_hill": &"hill",
	&"promise": &"hill",
}
## Willem présent à chaque étape (les autres instances sont absentes).
const WILLEM_AT := {&"training": &"willem_training", &"promise": &"willem_stars"}
const WILLEMS: Array[StringName] = [&"willem", &"willem_training", &"willem_stars"]
const ZONES: Array[StringName] = [&"village", &"forest", &"dunes", &"beach", &"hill"]
## Arène → zone qui la contient.
const ARENA_ZONES := {&"dunes": &"dunes"}

## PNJ et déclencheurs posés : id → zone (fichiers d'emplacement des PNJ).
var _npc_zones: Dictionary[StringName, StringName] = {}
var _trigger_zones: Dictionary[StringName, StringName] = {}


func before_all() -> void:
	for zone_id: StringName in ZONES:
		var packed := load("res://src/npc/placements/%s.tscn" % zone_id) as PackedScene
		var root := packed.instantiate()
		for child: Node in root.get_children():
			if child is Npc and (child as Npc).data != null:
				_npc_zones[(child as Npc).data.id] = zone_id
			elif child is QuestTrigger:
				var trigger := child as QuestTrigger
				var trigger_id := trigger.trigger_id
				_trigger_zones[trigger_id if not trigger_id.is_empty() else StringName(child.name)] = zone_id
		root.free()


func before_each() -> void:
	super()
	release_auto_start()


func _present(npc_id: StringName) -> bool:
	var npc := find_npc(npc_id)
	return npc != null and npc.is_present()


func _present_willems() -> Array[StringName]:
	var present: Array[StringName] = []
	for npc_id: StringName in WILLEMS:
		if _present(npc_id):
			present.append(npc_id)
	return present


## PNJ des quêtes secondaires du jeu (data/quests) : donneurs et PNJ de leurs étapes (talk, ou
## collect « rapporter à »).
func _side_quest_npcs() -> Array[StringName]:
	var npcs: Array[StringName] = []
	for quest: QuestData in QuestData.all():
		var in_game := FileAccess.file_exists("%s/%s.json" % [QuestData.DATA_DIR, quest.id])
		if quest.id == QUEST or quest.main or not in_game:
			continue
		for step: QuestStep in quest.steps:
			if not step.npc.is_empty() and not npcs.has(step.npc):
				npcs.append(step.npc)
		if not quest.giver_npc.is_empty() and not npcs.has(quest.giver_npc):
			npcs.append(quest.giver_npc)
	return npcs


## L'étape en cours est jouable : son PNJ, son déclencheur, sa zone ou son arène est là où
## l'histoire la place.
func _check_step(step: QuestStep, index: int) -> void:
	var zone_id: StringName = STEP_ZONES[step.id]
	match step.type:
		QuestStep.TALK:
			assert_true(_present(step.npc), "%s : %s est là" % [step.id, step.npc])
			assert_eq(_npc_zones.get(step.npc, &""), zone_id, "%s : %s posé" % [step.id, step.npc])
			assert_eq(
				QuestData.npc_marker(step.npc), QuestData.MARKER_TURN_IN, "%s : « ? »" % step.id
			)
		QuestStep.REACH:
			if not step.trigger.is_empty():
				assert_eq(
					_trigger_zones.get(step.trigger, &""),
					zone_id,
					"%s : déclencheur %s posé" % [step.id, step.trigger]
				)
			else:
				assert_eq(step.zone, zone_id, "%s : zone" % step.id)
		QuestStep.KILL:
			assert_eq(step.zone, zone_id, "%s : zone de la chasse" % step.id)
		QuestStep.ARENA:
			assert_eq(ARENA_ZONES.get(step.arena, &""), zone_id, "%s : arène" % step.id)
	# Un seul Willem, au bon endroit.
	var willem: StringName = WILLEM_AT.get(step.id, &"willem")
	assert_eq(_present_willems(), [willem] as Array[StringName], "%s : un seul Willem" % step.id)
	# Limeskin : au port à partir du bord du Couchant.
	var edge := QuestData.find(QUEST).step_index(&"the_edge")
	assert_eq(_present(&"limeskin"), index >= edge, "%s : Limeskin" % step.id)
	# Les PNJ des quêtes secondaires restent là (Willem : sauf au terrain et au sommet).
	for npc_id: StringName in _side_quest_npcs():
		var expected := npc_id != &"willem" or not WILLEM_AT.has(step.id)
		assert_eq(_present(npc_id), expected, "%s : %s (quêtes secondaires)" % [step.id, npc_id])


## Joue l'étape en cours comme le joueur le ferait (événements du jeu par l'EventBus).
func _play(step: QuestStep) -> void:
	match step.type:
		QuestStep.TALK:
			chat(step.npc)
		QuestStep.REACH:
			if not step.trigger.is_empty():
				enter_zone(STEP_ZONES[step.id])
				enter_trigger(step.trigger)
			else:
				enter_zone(step.zone)
		QuestStep.KILL:
			enter_zone(step.zone)
			kill(&"timere_small" if step.enemy == QuestStep.ANY_ENEMY else step.enemy, step.count)
		QuestStep.ARENA:
			enter_zone(ARENA_ZONES[step.arena])
			if step.wave > 0:
				reach_wave(step.arena, step.wave)
			else:
				reach_score(step.arena, step.score)
		QuestStep.COLLECT:
			GameState.add_item(step.item, step.count)
			if not step.npc.is_empty():
				chat(step.npc)
		QuestStep.FLAG:
			GameState.set_flag(step.flag)


func test_every_step_has_a_zone() -> void:
	var quest := QuestData.find(QUEST)
	var ids: Array[StringName] = []
	for step: QuestStep in quest.steps:
		ids.append(step.id)
	var declared: Array[StringName] = []
	declared.assign(STEP_ZONES.keys())
	assert_eq(ids, declared, "STEP_ZONES suit les étapes")
	for npc_id: StringName in [&"willem", &"willem_training", &"willem_stars", &"limeskin"]:
		var npc := find_npc(npc_id)
		assert_false(npc.visible_if.is_empty(), "%s : présence selon l'histoire" % npc_id)
		assert_eq(npc.visible_if_problem(), "", "%s : condition valide" % npc_id)


func test_the_talk_target_is_there_at_every_step() -> void:
	var quest := QuestData.find(QUEST)
	for index: int in quest.steps.size():
		var step := quest.steps[index]
		assert_eq(step_of(QUEST), step.id, "étape %d" % (index + 1))
		_check_step(step, index)
		_play(step)
	assert_eq(GameState.quest_state(QUEST), &"done", "acte 1 joué jusqu'au bout")
	# Après l'acte : Willem à l'entrepôt et au sommet, plus au terrain ; Limeskin au port.
	var after: Array[StringName] = [&"willem", &"willem_stars"]
	assert_eq(_present_willems(), after, "après l'acte : l'entrepôt et la colline")
	assert_true(_present(&"limeskin"), "après l'acte : Limeskin")
	for npc_id: StringName in _side_quest_npcs():
		assert_true(_present(npc_id), "après l'acte : %s (quêtes secondaires)" % npc_id)


func test_a_save_at_the_promise_finds_willem_on_the_hill() -> void:
	# Partie reprise à l'étape promise (étapes et drapeaux de la sauvegarde) : Willem au sommet.
	var quest := QuestData.find(QUEST)
	for step: QuestStep in quest.steps:
		if step.id == &"promise":
			break
		_play(step)
	var saved := GameState.to_dict()
	GameState.reset()
	GameState.from_dict(saved)
	assert_eq(step_of(QUEST), &"promise")
	assert_eq(_present_willems(), [&"willem_stars"] as Array[StringName], "au sommet")
	assert_true(_present(&"limeskin"), "Limeskin au port")
