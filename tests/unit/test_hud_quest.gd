extends "res://tests/stubs/l10_ui_test.gd"
## Objectifs de quête du HUD (L10) : état initial (GameState.quests()), quest_updated relu dans
## GameState en fin d'image, « done » refusé par le QuestTracker (L7) dans les deux ordres de
## branchement, « Quête terminée ! », progression des objets requis.

const HUD := preload("res://src/ui/hud.tscn")
const HudScript := preload("res://src/ui/hud.gd")


func _hud() -> HudScript:
	return add_child_autofree(HUD.instantiate())


func _tracker() -> QuestTracker:
	return add_child_autofree(QuestTracker.new())


func _banner(hud: Control) -> String:
	var banner := hud.get_node("%Banner") as Control
	return (hud.get_node("%BannerLabel") as Label).text if banner.visible else ""


func test_objective_shown_at_startup_from_game_state() -> void:
	GameState.set_quest_state(&"pages", &"active")
	var hud := _hud()
	var quest := QuestData.find(&"pages")
	assert_eq(hud.quest_objective(&"pages"), quest.objective, "objectif de la QuestData")
	var entry := hud.get_node("%Quests").get_child(0)
	assert_not_null(entry.find_child("Title", true, false))
	assert_eq((entry.find_child("Title", true, false) as Label).text, quest.title)
	assert_eq(_banner(hud), "", "pas de « Quête terminée » au chargement")


func test_done_quest_at_startup_is_not_shown() -> void:
	GameState.set_quest_state(&"pages", &"done")
	var hud := _hud()
	assert_eq(hud.quest_objective(&"pages"), "")
	assert_eq(_banner(hud), "")


func test_quest_updated_shows_objective_and_progress() -> void:
	var hud := _hud()
	assert_eq(hud.quest_objective(&"pages"), "")
	GameState.set_quest_state(&"pages", &"active")
	await wait_process_frames(1)
	assert_eq(hud.quest_objective(&"pages"), QuestData.find(&"pages").objective)
	assert_eq(hud.quest_progress(&"pages"), "Fragment de page : 0/5")
	GameState.add_item(&"page_fragment", 3)
	assert_eq(hud.quest_progress(&"pages"), "Fragment de page : 3/5", "inventory_changed")


func test_refused_completion_keeps_objective_tracker_first() -> void:
	_tracker()
	var hud := _hud()
	await _refused_completion(hud)


func test_refused_completion_keeps_objective_hud_first() -> void:
	var hud := _hud()
	_tracker()
	await _refused_completion(hud)


func _refused_completion(hud: HudScript) -> void:
	GameState.set_quest_state(&"pages", &"active")
	GameState.add_item(&"page_fragment", 2)
	await wait_process_frames(1)
	GameState.set_quest_state(&"pages", &"done")
	assert_eq(
		GameState.quest_state(&"pages"), &"active", "QuestTracker refuse : pas assez de pages"
	)
	await wait_process_frames(1)
	assert_eq(hud.quest_objective(&"pages"), QuestData.find(&"pages").objective, "objectif gardé")
	assert_ne(_banner(hud), "Quête terminée !", "pas de faux « Quête terminée »")


func test_completed_quest_shows_message_and_hides_objective() -> void:
	_tracker()
	var hud := _hud()
	GameState.set_quest_state(&"pages", &"active")
	GameState.add_item(&"page_fragment", 5)
	await wait_process_frames(1)
	GameState.set_quest_state(&"pages", &"done")
	assert_eq(GameState.quest_state(&"pages"), &"done")
	await wait_process_frames(1)
	assert_eq(_banner(hud), "Quête terminée !")
	assert_eq((hud.get_node("%BannerSub") as Label).text, QuestData.find(&"pages").title)
	assert_eq(hud.quest_objective(&"pages"), "", "objectif retiré")
