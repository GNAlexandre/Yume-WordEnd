extends "res://tests/stubs/q_quest_test.gd"
## Lot Q, HUD et quêtes en étapes : la quête suivie seule (titre, objectif de l'étape courante,
## progression « 1/2 »), changement de quête suivie, nombre d'autres quêtes actives, panneau qui
## s'illumine à chaque nouvelle étape, « Quête terminée ! » à la fin.

const HUD := preload("res://src/ui/hud.tscn")
const HudScript := preload("res://src/ui/hud.gd")

var _hud: HudScript


func before_each() -> void:
	super()
	_hud = HUD.instantiate()
	_hud.fade_time = 0.02
	_hud.banner_time = 0.05
	add_child_autofree(_hud)
	write_quest(
		{
			"id": "q",
			"title": "Le tour",
			"steps":
			[
				{"id": "a", "type": "talk", "npc": "child", "objective": "Parler à l'enfant"},
				{"id": "b", "type": "kill", "count": 2, "objective": "Vaincre 2 Timeres"},
			],
		}
	)
	write_quest(
		{
			"id": "r",
			"title": "Autre",
			"steps": [{"id": "x", "type": "flag", "flag": "x", "objective": "Faire x"}],
		}
	)


func _title() -> String:
	var quests := _hud.get_node("%Quests")
	if quests.get_child_count() == 0:
		return ""
	return (quests.get_child(0).find_child("Title", true, false) as Label).text


func _others() -> String:
	var entry: Node = _hud.get_node("%Quests").get_child(0)
	var label := entry.find_child("Others", true, false) as Label
	return label.text if label.visible else ""


func test_current_step_and_progress_of_the_tracked_quest() -> void:
	start_quest(&"q")
	await wait_process_frames(1)
	assert_eq(_hud.shown_quest(), &"q")
	assert_eq(_title(), "Le tour")
	assert_eq(_hud.quest_objective(&"q"), "Parler à l'enfant")
	assert_eq(_hud.quest_progress(&"q"), "", "talk : pas de progression chiffrée")
	chat(&"child")
	assert_eq(_hud.quest_objective(&"q"), "Vaincre 2 Timeres", "étape suivante, tout de suite")
	assert_eq(_hud.quest_progress(&"q"), "Ennemis vaincus : 0/2")
	kill(&"timere_small")
	assert_eq(_hud.quest_progress(&"q"), "Ennemis vaincus : 1/2")
	kill(&"timere_small")
	await wait_process_frames(1)
	assert_eq(_hud.quest_objective(&"q"), "", "quête terminée : panneau retiré")
	assert_eq((_hud.get_node("%BannerLabel") as Label).text, "Quête terminée !")
	assert_eq((_hud.get_node("%BannerSub") as Label).text, "Le tour")


func test_only_the_tracked_quest_is_shown() -> void:
	start_quest(&"q")
	start_quest(&"r")
	await wait_process_frames(1)
	assert_eq(_hud.shown_quest(), &"r", "la dernière commencée est suivie")
	assert_eq(_hud.get_node("%Quests").get_child_count(), 1, "une seule quête affichée")
	assert_eq(_hud.quest_objective(&"q"), "")
	assert_eq(_hud.quest_objective(&"r"), "Faire x")
	assert_eq(_others(), "+1 quête · Tab / Select", "les autres quêtes, et le journal")
	GameState.tracked_quest = &"q"
	await wait_process_frames(2)
	assert_eq(_hud.shown_quest(), &"q", "le joueur a choisi q dans le journal")
	assert_eq(_hud.quest_objective(&"q"), "Parler à l'enfant")
	GameState.set_flag(&"x")
	await wait_process_frames(1)
	assert_eq(_others(), "", "r terminée : plus d'autre quête")


func test_panel_glows_on_a_new_step() -> void:
	start_quest(&"q")
	await wait_process_frames(1)
	var entry: Control = _hud.get_node("%Quests").get_child(0)
	assert_eq(entry.modulate, Color.WHITE, "pas au démarrage")
	chat(&"child")
	assert_ne(entry.modulate, Color.WHITE, "nouvelle étape : il s'illumine")
	await wait_seconds(1.0)
	assert_eq(entry.modulate, Color.WHITE, "puis revient")
