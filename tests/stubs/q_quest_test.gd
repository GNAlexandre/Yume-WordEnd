extends GutTest
## Base des tests de quêtes (Lot Q), dont ils héritent par chemin (pas de class_name, règle des
## stubs) : le vrai moteur (un QuestTracker et un DialogueRunner ajoutés au test), les quêtes du
## jeu (data/quests), les quêtes d'exemple des tests (tests/data/quests) et celles qu'un test
## écrit (write_quest). Des raccourcis jouent les événements du jeu par l'EventBus : parler à un
## PNJ avec son vrai dialogue (talk) ou sans (chat), entrer dans une zone ou un déclencheur,
## vaincre des ennemis, atteindre une vague ou un score. Mode d'emploi : docs/QUETES.md,
## « Tester une quête » ; exemple : tests/unit/test_quest_example.gd.
##
## Avant chaque test : GameState remis à zéro, dossiers de quêtes ajoutés ; après : dossiers
## retirés, quêtes écrites effacées, zone de WorldManager et GameState rétablis.

## Quêtes d'exemple des tests (absentes du jeu exporté).
const FIXTURES_DIR := "res://tests/data/quests"
## Quêtes écrites par write_quest.
const TEMP_DIR := "user://test_quests"
## PNJ : ceux des tests d'abord (tests/data/npcs), puis ceux du jeu (data/npcs).
const NPC_DIRS: Array[String] = ["res://tests/data/npcs", "res://data/npcs"]

var tracker: QuestTracker
var dialogue_runner: DialogueRunner
## Répliques de la dernière conversation (talk).
var dialogue_lines: Array[String] = []

var _previous_zone: StringName


func before_each() -> void:
	_previous_zone = WorldManager.current_zone()
	GameState.reset()
	DirAccess.make_dir_recursive_absolute(TEMP_DIR)
	_clear_temp_quests()
	QuestData.add_search_dir(FIXTURES_DIR)
	QuestData.add_search_dir(TEMP_DIR)
	dialogue_lines.clear()
	EventBus.dialogue_line.connect(_on_dialogue_line)
	tracker = add_child_autofree(QuestTracker.new())
	dialogue_runner = add_child_autofree(DialogueRunner.new())


func after_each() -> void:
	if is_instance_valid(dialogue_runner):
		dialogue_runner.stop()
	EventBus.dialogue_line.disconnect(_on_dialogue_line)
	QuestData.remove_search_dir(TEMP_DIR)
	QuestData.remove_search_dir(FIXTURES_DIR)
	_clear_temp_quests()
	if WorldManager.current_zone() != _previous_zone:
		EventBus.zone_entered.emit(_previous_zone)
	GameState.reset()


# --- Quêtes ------------------------------------------------------------------------------------


## Écrit une quête de test (user://test_quests/<id>.json) ; QuestData la lit aussitôt.
func write_quest(data: Dictionary) -> void:
	var path := TEMP_DIR.path_join("%s.json" % data["id"])
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "  ", false))
	file.close()
	QuestData.clear_cache()


## Démarre une quête comme l'effet de dialogue start_quest.
func start_quest(quest_id: StringName) -> void:
	GameState.set_quest_state(quest_id, &"active")


## Termine d'office une quête comme l'effet complete_quest, en donnant d'abord les objets qui
## manquent à ses étapes collect restantes (prérequis d'une autre quête, par exemple).
func complete_quest(quest_id: StringName) -> void:
	var quest := QuestData.find(quest_id)
	if quest != null:
		var missing := QuestTracker.missing_items(quest)
		for item_id: StringName in missing:
			GameState.add_item(item_id, missing[item_id])
	GameState.set_quest_state(quest_id, &"done")


## Étape courante (&"" : aucune) et compteur d'une quête.
func step_of(quest_id: StringName) -> StringName:
	return GameState.quest_step(quest_id)


func count_of(quest_id: StringName) -> int:
	return GameState.quest_step_count(quest_id)


# --- Événements du jeu --------------------------------------------------------------------------


## Données d'un PNJ (tests/data/npcs/<id>.tres, sinon data/npcs/<id>.tres), null s'il manque.
func find_npc(npc_id: StringName) -> NpcData:
	for dir: String in NPC_DIRS:
		var path := dir.path_join("%s.tres" % npc_id)
		if ResourceLoader.exists(path):
			return load(path) as NpcData
	return null


## Conversation avec le vrai dialogue du PNJ (NpcData, voir find_npc) : les réponses dans l'ordre
## (-1 : « suite », sinon le rang du choix proposé), puis fin du dialogue. Renvoie les répliques
## affichées.
func talk(who: NpcData, answers: Array[int] = []) -> Array[String]:
	dialogue_runner.stop()
	dialogue_lines.clear()
	dialogue_runner.start(who)
	for answer: int in answers:
		EventBus.dialogue_choice_made.emit(answer)
	dialogue_runner.stop()
	return dialogue_lines.duplicate()


## Conversation sans dialogue (début puis fin) : valide une étape talk vers ce PNJ.
func chat(npc_id: StringName) -> void:
	EventBus.dialogue_started.emit(npc_id)
	EventBus.dialogue_ended.emit(npc_id)


func enter_zone(zone_id: StringName) -> void:
	EventBus.zone_entered.emit(zone_id)


func enter_trigger(trigger_id: StringName) -> void:
	EventBus.trigger_entered.emit(trigger_id)


## times ennemis enemy_id vaincus (dans la zone courante, GameState.zone).
func kill(enemy_id: StringName, times: int = 1) -> void:
	for _i: int in times:
		EventBus.enemy_killed.emit(enemy_id, 10)


## Vague commencée, score atteint pendant une série de l'arène.
func reach_wave(arena_id: StringName, wave: int) -> void:
	EventBus.wave_started.emit(arena_id, wave, 3 + 2 * wave)


func reach_score(arena_id: StringName, score: int) -> void:
	EventBus.arena_score_changed.emit(arena_id, score)


# --- Outils ------------------------------------------------------------------------------------


func _on_dialogue_line(_speaker: String, text: String, _choices: Array[String]) -> void:
	dialogue_lines.append(text)


func _clear_temp_quests() -> void:
	for file_name: String in DirAccess.get_files_at(TEMP_DIR):
		DirAccess.remove_absolute(TEMP_DIR.path_join(file_name))
	QuestData.clear_cache()
