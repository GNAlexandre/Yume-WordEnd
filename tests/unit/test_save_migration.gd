extends "res://tests/stubs/l8_save_test.gd"
## SaveManager, versions (L8, puis Lot Q) : migration du format v0 (sans version, scores à plat,
## dont le localStorage['yn.wordend'] de l'easter egg) vers v1 puis v2, migration v1 → v2
## (avancement des quêtes en étapes), refus propre d'une version future.

## Sauvegarde v0 : pas de version ni de best_scores, le score des dunes à plat.
const V0_SAVE := """{
	"skin": "forgeron",
	"max_hp": 6,
	"position": [3.5, 0.5, -2.0],
	"zone": "beach",
	"inventory": {"page_fragment": 2},
	"flags": {"quest_pages_accepted": true},
	"quests": {"picture_book": "active"},
	"collected_pickups": ["beach_shell_2"],
	"best": 640,
	"wave": 6,
	"games": 4
}"""
## localStorage['yn.wordend'] tel que jeu.js l'écrit (score, parties, date, son).
const EASTER_EGG := (
	'{"meilleur": 410, "parties": 12, "maj": "2026-09-30", ' + '"volume": 0.5, "muet": false}'
)
const FUTURE_SAVE := '{"version": 99, "saved_at": "2027-01-01T00:00:00Z", "skin": "enfant"}'
## Sauvegarde v1 (jalon M2) : une quête du jeu en cours (le livre d'images, qui a remplacé celle
## des pages à l'acte 1), trois pages en poche, une quête active sans données et une terminée.
const V1_SAVE := """{
	"version": 1,
	"saved_at": "2026-10-06T10:00:00Z",
	"skin": "chtholly",
	"max_hp": 5,
	"position": [-3.0, 0.2, 6.0],
	"zone": "village",
	"inventory": {"page_fragment": 3},
	"flags": {"quest_pages_accepted": true},
	"quests": {"picture_book": "active", "lost_quest": "active", "old": "done"},
	"collected_pickups": ["forest_page_1"],
	"best_scores": {"dunes": {"score": 120, "wave": 2, "games": 1}}
}"""


func test_v0_file_is_migrated_to_v1() -> void:
	write_save_text(V0_SAVE)
	watch_signals(EventBus)
	assert_eq(SaveManager.load_game(), OK)
	assert_signal_emitted(EventBus, "game_loaded")
	var data := GameState.to_dict()
	assert_eq(data["best_scores"], {"dunes": {"score": 640, "wave": 6, "games": 4}})
	assert_eq(GameState.skin_id, &"forgeron")
	assert_eq(GameState.max_hp, 6)
	assert_eq(GameState.position, Vector3(3.5, 0.5, -2.0))
	assert_eq(GameState.zone, &"beach")
	assert_eq(GameState.count(&"page_fragment"), 2)
	assert_true(GameState.has_flag(&"quest_pages_accepted"))
	assert_eq(GameState.quest_state(&"picture_book"), &"active")
	assert_true(GameState.is_pickup_collected(&"beach_shell_2"))
	assert_false(data.has("best") or data.has("games"), "plus de champ à plat")


func test_migrated_save_is_rewritten_at_the_current_version() -> void:
	write_save_text(V0_SAVE)
	assert_eq(SaveManager.load_game(), OK)
	assert_true(SaveManager.is_autosave_pending(), "réécriture demandée")
	assert_eq(SaveManager.flush(), OK)
	var data := read_save()
	assert_eq(data["version"], float(SaveManager.SAVE_VERSION), "v0 → v1 → v2")
	assert_true(data.has("saved_at"))
	assert_eq(data["best_scores"], {"dunes": {"score": 640.0, "wave": 6.0, "games": 4.0}})
	assert_false(data.has("best") or data.has("wave") or data.has("games"))
	assert_eq(SaveManager.load_game(), OK, "relue en v2")
	assert_eq(GameState.best_score(&"dunes"), 640)


func test_version_zero_is_the_v0_format() -> void:
	assert_eq(SaveManager.import_json('{"version": 0, "best": 120, "games": 2}'), OK)
	assert_eq(GameState.to_dict()["best_scores"], {"dunes": {"score": 120, "wave": 0, "games": 2}})


func test_easter_egg_storage_imports_as_v0() -> void:
	assert_eq(SaveManager.import_json(EASTER_EGG), OK)
	assert_eq(GameState.best_score(&"dunes"), 410, "meilleur score de l'easter egg")
	assert_eq(GameState.to_dict()["best_scores"]["dunes"]["games"], 12, "nombre de parties")
	assert_eq(GameState.max_hp, GameState.DEFAULT_MAX_HP, "le reste : nouvelle partie")
	assert_eq(GameState.zone, &"")
	assert_true(GameState.items().is_empty())


func test_v0_without_score_has_no_best_scores() -> void:
	assert_eq(SaveManager.import_json('{"skin": "enfant", "best": 0, "games": 0}'), OK)
	assert_eq(GameState.skin_id, &"enfant")
	assert_eq(GameState.to_dict()["best_scores"], {})


func test_invalid_v0_is_refused() -> void:
	GameState.add_item(&"page_fragment")
	assert_eq(SaveManager.import_json('{"best": 100, "inventory": "beaucoup"}'), ERR_INVALID_DATA)
	assert_eq(GameState.count(&"page_fragment"), 1, "GameState inchangé")


func test_future_version_is_refused_by_load() -> void:
	write_save_text(FUTURE_SAVE)
	GameState.add_item(&"page_fragment")
	watch_signals(EventBus)
	assert_eq(SaveManager.load_game(), ERR_INVALID_DATA)
	assert_push_warning("version 99")
	assert_string_contains(SaveManager.last_error, "plus récente")
	assert_signal_not_emitted(EventBus, "game_loaded")
	assert_eq(GameState.count(&"page_fragment"), 1, "GameState inchangé")
	assert_eq(GameState.skin_id, &"")
	assert_eq(FileAccess.get_file_as_string(SaveManager.save_path), FUTURE_SAVE, "fichier intact")
	assert_false(FileAccess.file_exists(SaveManager.backup_path()), "pas mis de côté")
	assert_false(SaveManager.is_game_loaded(), "pas d'auto-sauvegarde qui l'écraserait")


func test_future_version_is_refused_by_import() -> void:
	GameState.add_item(&"page_fragment")
	watch_signals(EventBus)
	assert_eq(SaveManager.import_json(FUTURE_SAVE), ERR_INVALID_DATA)
	assert_signal_not_emitted(EventBus, "game_loaded")
	assert_eq(GameState.count(&"page_fragment"), 1)
	assert_eq(GameState.skin_id, &"")


# --- v1 → v2 (Lot Q : quêtes en étapes) --------------------------------------------------------


func test_v1_file_is_migrated_to_v2() -> void:
	write_save_text(V1_SAVE)
	watch_signals(EventBus)
	assert_eq(SaveManager.load_game(), OK)
	assert_signal_emitted(EventBus, "game_loaded")
	assert_eq(GameState.quest_state(&"picture_book"), &"active", "états v1 gardés")
	assert_eq(GameState.quest_state(&"old"), &"done")
	assert_eq(GameState.quest_step(&"picture_book"), &"pages", "quête active : sa 1re étape")
	assert_eq(GameState.quest_step_count(&"picture_book"), 0)
	assert_eq(GameState.quest_step(&"lost_quest"), &"", "quête sans données : pas d'étape")
	assert_eq(GameState.quest_step(&"old"), &"", "quête terminée : pas d'étape")
	assert_eq(GameState.tracked_quest, &"picture_book", "première quête active suivie")
	assert_eq(GameState.count(&"page_fragment"), 3, "le reste est inchangé")
	assert_eq(GameState.best_score(&"dunes"), 120)
	assert_true(SaveManager.is_autosave_pending(), "réécriture demandée")
	assert_eq(SaveManager.flush(), OK)
	var data := read_save()
	assert_eq(data["version"], 2.0, "réécrite en v2")
	assert_eq(data["quest_progress"], {"picture_book": {"step": "pages", "count": 0.0}})
	assert_eq(data["tracked_quest"], "picture_book")
	assert_eq(data["quests"], {"picture_book": "active", "lost_quest": "active", "old": "done"})


func test_v0_is_migrated_through_v1_to_v2() -> void:
	write_save_text(V0_SAVE)
	assert_eq(SaveManager.load_game(), OK)
	assert_eq(GameState.quest_step(&"picture_book"), &"pages", "v0 → v1 → v2 : 1re étape")
	assert_eq(GameState.tracked_quest, &"picture_book")
	assert_eq(GameState.best_score(&"dunes"), 640, "migration v0 toujours faite")


func test_v2_progress_round_trip() -> void:
	GameState.set_quest_state(&"pages", &"active")
	GameState.set_quest_step(&"pages", &"deliver", 4)
	GameState.tracked_quest = &"pages"
	assert_eq(SaveManager.save(), OK)
	GameState.reset()
	assert_eq(SaveManager.load_game(), OK)
	assert_eq(GameState.quest_step(&"pages"), &"deliver")
	assert_eq(GameState.quest_step_count(&"pages"), 4, "compteur gardé")
	assert_eq(GameState.tracked_quest, &"pages")


func test_invalid_v2_fields_are_refused() -> void:
	GameState.add_item(&"page_fragment")
	for text: String in [
		'{"version": 2, "quest_progress": {"pages": "deliver"}}',
		'{"version": 2, "quest_progress": {"pages": {"step": 3}}}',
		'{"version": 2, "quest_progress": {"pages": {"step": "deliver", "count": -1}}}',
		'{"version": 2, "tracked_quest": 3}',
		'{"version": 1, "quests": {"pages": 1}}',
	]:
		assert_eq(SaveManager.import_json(text), ERR_INVALID_DATA, text)
	assert_eq(GameState.count(&"page_fragment"), 1, "GameState inchangé")
