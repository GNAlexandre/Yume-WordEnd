extends "res://tests/stubs/l8_save_test.gd"
## SaveManager, versions (L8, Lot Q, E1, puis F1) : (F1) une partie de l'ancienne île (versions 0
## à 2, dont le localStorage['yn.wordend'] de l'easter egg, ou v3 hors de l'acte en jours) ne se
## reprend plus : copiée à côté (load_game), elle devient une nouvelle partie de l'acte 1 avec son
## skin, et SaveManager.notice porte la ligne du menu (data/texts/story.json, save/migrated) ; une
## partie v3 de l'acte passe en v4 sans perte (les champs de l'ancienne île sont retirés) ; refus
## propre d'une version future ; aller-retour de la carte (v3 puis v4).

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
## (E1) Vraie sauvegarde de la version d'avant la refonte (schéma v2), écrite par le jeu du
## commit 50ec961 : quête principale à « to_the_woods », deux pages, un record d'arène, le joueur
## dans la rue du port.
const V2_REAL_SAVE := "res://tests/data/saves/save_v2_avant_refonte.json"
## Sauvegarde v1 (jalon M2) de l'ancienne île.
const V1_SAVE := """{
	"version": 1,
	"saved_at": "2026-10-06T10:00:00Z",
	"skin": "ithea",
	"max_hp": 5,
	"position": [-3.0, 0.2, 6.0],
	"zone": "village",
	"inventory": {"page_fragment": 3},
	"flags": {"quest_pages_accepted": true},
	"quests": {"picture_book": "active", "lost_quest": "active", "old": "done"},
	"collected_pickups": ["forest_page_1"],
	"best_scores": {"dunes": {"score": 120, "wave": 2, "games": 1}}
}"""
## (F1) Sauvegarde v3 de l'ancienne île (carte héritée, hors de l'acte en jours : day 0).
const V3_LEGACY_SAVE := """{
	"version": 3,
	"skin": "chtholly",
	"max_hp": 6,
	"position": [0.0, 0.2, 9.0],
	"map": "ile_ancienne",
	"zone": "village",
	"inventory": {"page_fragment": 5},
	"flags": {"met_willem": true},
	"quests": {"act1_main": "active"},
	"quest_progress": {"act1_main": {"step": "to_the_woods", "count": 0}},
	"tracked_quest": "act1_main",
	"best_scores": {"dunes": {"score": 640, "wave": 6, "games": 4}},
	"day": 0
}"""
## (F1) Sauvegarde v3 de l'acte en jours (île n° 68), avec les champs vides de l'ancienne île
## qu'écrivait encore GameState.
const V3_ACT_SAVE := """{
	"version": 3,
	"saved_at": "2026-10-15T20:00:00Z",
	"skin": "nephren",
	"max_hp": 5,
	"position": [20.0, 0.2, 16.0],
	"map": "essai",
	"zone": "",
	"inventory": {"test_page": 1},
	"flags": {"j2_seen": true},
	"collected_pickups": [],
	"quests": {},
	"quest_progress": {},
	"tracked_quest": "",
	"best_scores": {},
	"island": "ile_68",
	"known_islands": ["ile_68"],
	"day": 3,
	"slot": "matin",
	"scenes_done": ["j1_1_port", "j2_1"]
}"""
const OLD_ISLAND_FIELDS: Array[String] = [
	"zone", "quests", "quest_progress", "tracked_quest", "best_scores"
]


## Vérifie la nouvelle partie qui remplace une partie de l'ancienne île : rien de l'ancienne
## partie sauf le skin, l'avis posé, game_loaded émis, la réécriture demandée.
func _assert_restarted(skin_id: StringName, label: String) -> void:
	assert_true(SaveManager.started_new, "%s : nouvelle partie" % label)
	assert_eq(SaveManager.notice, DialogueRunner.story_text("save/migrated"), "%s : avis" % label)
	assert_false(SaveManager.notice.is_empty(), "%s : l'avis a un texte" % label)
	assert_eq(GameState.skin_id, skin_id, "%s : son skin" % label)
	assert_true(GameState.items().is_empty(), "%s : rien de l'ancienne île" % label)
	assert_eq(GameState.max_hp, GameState.DEFAULT_MAX_HP, "%s : PV de départ" % label)
	assert_eq(GameState.map, &"", "%s : game.gd la pose au départ de l'acte" % label)
	assert_lte(GameState.day, 1, "%s : au premier jour de l'acte" % label)
	assert_eq(GameState.scenes_done().size(), 0, "%s : aucune scène jouée" % label)
	assert_eq(WorldManager.starting_map(), WorldManager.START_MAP, "%s : l'entrepôt" % label)
	assert_true(SaveManager.is_autosave_pending(), "%s : réécriture demandée" % label)
	var data := GameState.to_dict()
	for key: String in OLD_ISLAND_FIELDS:
		assert_false(data.has(key), "%s : plus de %s" % [label, key])


# --- (F1) Parties de l'ancienne île : nouvelle partie de l'acte 1 ------------------------------


func test_real_v2_save_restarts_the_first_act_and_is_kept_aside() -> void:
	var text := FileAccess.get_file_as_string(V2_REAL_SAVE)
	write_save_text(text)
	watch_signals(EventBus)
	assert_eq(SaveManager.load_game(), OK, "aucun plantage, aucune erreur")
	assert_signal_emitted(EventBus, "game_loaded")
	_assert_restarted(&"chtholly", "v2")
	assert_true(FileAccess.file_exists(SaveManager.legacy_backup_path()), "copie gardée")
	assert_eq(
		FileAccess.get_file_as_string(SaveManager.legacy_backup_path()), text, "copie intacte"
	)
	assert_eq(SaveManager.flush(), OK)
	var data := read_save()
	assert_eq(data["version"], float(SaveManager.SAVE_VERSION), "réécrite en v4")
	for key: String in OLD_ISLAND_FIELDS:
		assert_false(data.has(key), "fichier : plus de %s" % key)
	assert_eq(SaveManager.load_game(), OK, "relue")
	assert_eq(SaveManager.notice, "", "une partie v4 ne dit rien au chargement")
	assert_false(SaveManager.started_new)


func test_every_old_island_version_restarts_the_first_act() -> void:
	var cases := {
		"v0": [V0_SAVE, &"forgeron"],
		"v1": [V1_SAVE, &"ithea"],
		"v3 hors de l'acte": [V3_LEGACY_SAVE, &"chtholly"],
		"v0 explicite": ['{"version": 0, "best": 120, "games": 2}', &""],
		"easter egg": [EASTER_EGG, &""],
		"v3 sans jour": ['{"version": 3, "map": "ile_ancienne"}', &""],
	}
	for label: String in cases:
		GameState.reset()
		GameState.add_item(&"test_page")
		write_save_text(cases[label][0])
		assert_eq(SaveManager.load_game(), OK, label)
		_assert_restarted(cases[label][1], label)
		SaveManager.close_game(false)


func test_import_of_an_old_island_save_restarts_too() -> void:
	assert_eq(SaveManager.import_json(V1_SAVE), OK)
	_assert_restarted(&"ithea", "import v1")
	assert_false(FileAccess.file_exists(SaveManager.legacy_backup_path()), "l'import ne copie rien")


func test_old_island_save_with_bad_fields_still_restarts() -> void:
	# Elle ne se reprend pas : ses champs ne sont plus lus, rien ne plante.
	assert_eq(SaveManager.import_json('{"best": 100, "inventory": "beaucoup"}'), OK)
	_assert_restarted(&"", "v0 abîmée")


# --- v3 de l'acte en jours → v4 ----------------------------------------------------------------


func test_v3_act_save_becomes_v4_without_loss() -> void:
	write_save_text(V3_ACT_SAVE)
	assert_eq(SaveManager.load_game(), OK)
	assert_false(SaveManager.started_new, "reprise, pas de nouvelle partie")
	assert_eq(SaveManager.notice, "", "rien à dire")
	assert_false(FileAccess.file_exists(SaveManager.legacy_backup_path()), "rien de côté")
	assert_eq(GameState.skin_id, &"nephren")
	assert_eq(GameState.map, &"essai")
	assert_eq(GameState.position, Vector3(20.0, 0.2, 16.0))
	assert_eq(GameState.count(&"test_page"), 1)
	assert_true(GameState.has_flag(&"j2_seen"))
	assert_eq(GameState.day, 3)
	assert_true(GameState.is_scene_done(&"j2_1"))
	assert_eq(WorldManager.starting_map(), &"essai")
	assert_eq(SaveManager.flush(), OK)
	var data := read_save()
	assert_eq(data["version"], 4.0, "réécrite en v4")
	for key: String in OLD_ISLAND_FIELDS:
		assert_false(data.has(key), "plus de %s" % key)
	assert_eq(data["day"], 3.0)


func test_v4_round_trip_and_unknown_map() -> void:
	GameState.map = &"essai"
	GameState.position = Vector3(4.0, 0.0, 15.0)
	GameState.day = 2
	assert_eq(SaveManager.save(), OK)
	assert_eq(read_save()["map"], "essai")
	assert_eq(read_save()["version"], 4.0)
	GameState.reset()
	assert_eq(GameState.map, &"", "nouvelle partie : pas de carte")
	assert_eq(SaveManager.load_game(), OK)
	assert_eq(GameState.map, &"essai")
	assert_eq(GameState.position, Vector3(4.0, 0.0, 15.0))
	assert_eq(WorldManager.starting_map(), &"essai")
	var story := '{"version": 4, "position": [1, 0, 1], "map": "x", "day": 2}'
	assert_eq(SaveManager.import_json(story), OK)
	assert_eq(GameState.map, &"x", "gardée telle quelle")
	assert_eq(WorldManager.starting_map(), WorldManager.START_MAP, "carte inconnue : départ")


func test_invalid_v4_fields_are_refused() -> void:
	GameState.add_item(&"test_page")
	for text: String in [
		'{"version": 4, "map": 4}',
		'{"version": 3, "day": 2, "map": ["essai"]}',
		'{"version": 4, "inventory": "beaucoup"}',
	]:
		assert_eq(SaveManager.import_json(text), ERR_INVALID_DATA, text)
	assert_eq(GameState.count(&"test_page"), 1, "GameState inchangé")


# --- Version future ----------------------------------------------------------------------------


func test_future_version_is_refused_by_load() -> void:
	write_save_text(FUTURE_SAVE)
	GameState.add_item(&"test_page")
	watch_signals(EventBus)
	assert_eq(SaveManager.load_game(), ERR_INVALID_DATA)
	assert_push_warning("version 99")
	assert_string_contains(SaveManager.last_error, "plus récente")
	assert_signal_not_emitted(EventBus, "game_loaded")
	assert_eq(GameState.count(&"test_page"), 1, "GameState inchangé")
	assert_eq(GameState.skin_id, &"")
	assert_eq(FileAccess.get_file_as_string(SaveManager.save_path), FUTURE_SAVE, "fichier intact")
	assert_false(FileAccess.file_exists(SaveManager.backup_path()), "pas mis de côté")
	assert_false(SaveManager.is_game_loaded(), "pas d'auto-sauvegarde qui l'écraserait")


func test_future_version_is_refused_by_import() -> void:
	GameState.add_item(&"test_page")
	watch_signals(EventBus)
	assert_eq(SaveManager.import_json(FUTURE_SAVE), ERR_INVALID_DATA)
	assert_signal_not_emitted(EventBus, "game_loaded")
	assert_eq(GameState.count(&"test_page"), 1)
	assert_eq(GameState.skin_id, &"")
