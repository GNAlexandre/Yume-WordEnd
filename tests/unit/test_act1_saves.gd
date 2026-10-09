extends "res://tests/stubs/l8_save_test.gd"
## Acte 1, sauvegardes d'avant l'acte 1 : la quête des pages, le coquillage, le marque-page et le
## skin « enfant » n'existent plus. Une sauvegarde du jalon M2 (v1) et une du moteur de quêtes
## (v2, pages en cours et suivies) se chargent sans erreur dans la vraie partie : le joueur
## reprend Chtholly, les objets retirés restent des objets inconnus (l'inventaire s'ouvre sans
## erreur), la quête des pages, sans données, n'est plus listée au journal, et la quête principale
## de l'acte 1 démarre et prend le suivi du HUD (même si les pages étaient suivies). Une quête des
## pages restée « active » ne compte plus parmi les quêtes en cours (QuestData.active_ids) : pas
## de « +1 quête » fantôme dans le HUD.

const GAME_SCENE := preload("res://src/game.tscn")
## Jalon M2 : pages rendues, marque-page et coquillages, skin de l'enfant, 6 PV max.
const M2_SAVE := """{
	"version": 1,
	"saved_at": "2026-10-06T18:00:00Z",
	"skin": "enfant",
	"max_hp": 6,
	"position": [-3.0, 0.2, 6.0],
	"zone": "village",
	"inventory": {"page_fragment": 2, "shell": 3, "bookmark": 1, "flower_blue": 1},
	"flags": {"quest_pages_accepted": true},
	"quests": {"pages": "done"},
	"collected_pickups": ["forest_page_1", "beach_shell_1", "beach_shell_2"],
	"best_scores": {"dunes": {"score": 240, "wave": 4, "games": 2}}
}"""
## Moteur de quêtes (v2) : la quête des pages en cours, suivie, et son étape.
const PAGES_SAVE := """{
	"version": 2,
	"saved_at": "2026-10-07T09:00:00Z",
	"skin": "bibliothecaire",
	"max_hp": 5,
	"position": [0.0, 0.2, 9.0],
	"zone": "village",
	"inventory": {"page_fragment": 3},
	"flags": {"quest_pages_accepted": true},
	"quests": {"pages": "active"},
	"quest_progress": {"pages": {"step": "deliver", "count": 0}},
	"tracked_quest": "pages",
	"collected_pickups": [],
	"best_scores": {}
}"""
## Jalon M2 publié (v1) : la quête des pages acceptée, pas encore rendue (trois pages en poche).
const M2_PAGES_ACTIVE_SAVE := """{
	"version": 1,
	"saved_at": "2026-10-05T20:00:00Z",
	"skin": "chtholly",
	"max_hp": 5,
	"position": [2.0, 0.2, 6.0],
	"zone": "village",
	"inventory": {"page_fragment": 3},
	"flags": {"quest_pages_accepted": true},
	"quests": {"pages": "active"},
	"collected_pickups": ["forest_page_1", "forest_page_2", "forest_page_3"],
	"best_scores": {}
}"""


## Charge la sauvegarde (texte), puis la vraie partie (src/game.tscn).
func _load_into_the_game(text: String) -> Node3D:
	write_save_text(text)
	assert_eq(SaveManager.load_game(), OK, "sauvegarde chargée")
	var game: Node3D = add_child_autofree(GAME_SCENE.instantiate())
	await wait_physics_frames(3)
	return game


func _listed(game: Node3D) -> Array[StringName]:
	var journal := game.get_node(^"UI/HUD/Journal") as Control
	journal.call(&"refresh")
	return journal.call(&"listed_quests")


func test_m2_save_with_removed_content_loads_into_the_first_act() -> void:
	var game := await _load_into_the_game(M2_SAVE)
	var player := game.get_node(^"Player") as Player
	assert_eq(GameState.skin_id, &"enfant", "le skin de la sauvegarde est gardé")
	assert_eq(player.visual.skin.id, &"chtholly", "skin retiré : Chtholly")
	assert_eq(player.health.max_hp, 6, "PV max gardés")
	assert_eq(GameState.count(&"page_fragment"), 2, "objets de l'acte 1 gardés")
	assert_null(ItemData.find(&"shell"), "coquillage retiré")
	assert_eq(GameState.best_score(&"dunes"), 240, "record gardé")
	assert_eq(GameState.quest_state(&"act1_main"), &"active", "l'acte 1 commence")
	assert_eq(GameState.quest_step(&"act1_main"), &"morning")
	assert_eq(_listed(game), [&"act1_main"] as Array[StringName], "pages : plus au journal")
	await wait_process_frames(2)
	var hud := game.get_node(^"UI/HUD") as Control
	assert_eq(hud.call(&"shown_quest"), &"act1_main", "le HUD suit l'acte 1")
	var forest := game.get_node(^"World/ile_ancienne/Zones/forest/Pickups")
	assert_null(forest.get_node_or_null(^"forest_page_1"), "page déjà prise : absente")
	assert_not_null(forest.get_node_or_null(^"forest_page_4"), "les nouvelles pages sont là")
	var inventory := game.get_node(^"UI/Inventory") as Control
	inventory.call(&"open")
	assert_true(inventory.call(&"is_open"), "l'inventaire s'ouvre avec des objets retirés")
	inventory.call(&"close")
	assert_false(get_tree().paused)


func test_save_with_the_pages_quest_in_progress() -> void:
	var game := await _load_into_the_game(PAGES_SAVE)
	var player := game.get_node(^"Player") as Player
	assert_eq(player.visual.skin.id, &"chtholly", "skin retiré : Chtholly")
	assert_eq(GameState.quest_state(&"act1_main"), &"active", "l'acte 1 commence")
	assert_eq(_listed(game), [&"act1_main"] as Array[StringName], "pages : plus au journal")
	await wait_process_frames(2)
	var hud := game.get_node(^"UI/HUD") as Control
	assert_eq(GameState.tracked_quest, &"act1_main", "l'acte 1 prend le suivi des pages")
	assert_eq(hud.call(&"shown_quest"), &"act1_main", "et le HUD l'affiche")
	assert_eq(hud.call(&"quest_objective", &"act1_main"), "Rejoindre Nygglatho sous le porche")


func test_m2_save_with_the_pages_quest_active_shows_no_ghost_quest() -> void:
	var game := await _load_into_the_game(M2_PAGES_ACTIVE_SAVE)
	assert_eq(GameState.quest_state(&"pages"), &"active", "l'état de la sauvegarde est gardé")
	assert_eq(GameState.quest_state(&"act1_main"), &"active", "l'acte 1 commence")
	assert_eq(QuestData.active_ids(), [&"act1_main"] as Array[StringName], "pages : plus en cours")
	assert_eq(_listed(game), [&"act1_main"] as Array[StringName], "ni au journal")
	await wait_process_frames(2)
	var hud := game.get_node(^"UI/HUD") as Control
	assert_eq(hud.call(&"shown_quest"), &"act1_main")
	assert_eq(_other_quests(hud), "", "pas de « +1 quête » fantôme dans le HUD")
	# Une vraie quête secondaire compte, elle (suivie dès qu'elle commence).
	GameState.set_flag(&"met_willem")
	GameState.set_quest_state(&"picture_book", &"active")
	await wait_process_frames(2)
	assert_eq(QuestData.active_ids().size(), 2, "act1_main et le livre d'images")
	assert_eq(hud.call(&"shown_quest"), &"picture_book")
	assert_eq(_other_quests(hud), "+1 quête · Tab / Select", "l'acte 1, et pas les pages")


## Texte « +n quêtes » du panneau de quête du HUD ("" s'il est caché).
func _other_quests(hud: Control) -> String:
	var entry := hud.get_node(^"%Quests").get_child(0)
	var label := entry.find_child("Others", true, false) as Label
	return label.text if label.visible else ""
