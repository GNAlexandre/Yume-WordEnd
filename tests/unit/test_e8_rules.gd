extends GutTest
## (E8) Les données des jeux : data/games/ballon.json et staff_training.json (format, chiffres de
## ACTE1.md et de VIE.md), l'activité « ballon » d'activities.json, les textes des jeux
## (data/texts/life.json, games/ballon et games/baton), le raccourci de développement ?jeu=.

const BALL_REQUIRED: Array[String] = [
	"min_members",
	"half_time",
	"halves",
	"team_size",
	"keep_top_scorers",
	"break_time",
	"field/width",
	"field/length",
	"field/goal_width",
	"field/goal_height",
	"ball/gravity",
	"ball/bounce",
	"ball/roll_friction",
	"kick/reach",
	"kick/shot_speed",
	"ai/fair_bonus",
	"fall/chance_per_s",
	"keeper/reach",
	"keeper/miss_chance",
	"thicket/chance",
	"player/join_margin",
	"player/leave_margin",
	"player/kick_reach",
]
const STAFF_REQUIRED: Array[String] = [
	"dodge_distance",
	"phase_a/tempo_start",
	"phase_a/tempo_end",
	"phase_a/warn",
	"phase_a/deflect_window",
	"phase_a/open_time",
	"phase_a/fatigue_every",
	"phase_a/fatigue_shrink",
	"phase_a/sit_at",
	"phase_a/success_streak",
	"phase_a/success_deflections",
	"phase_b/ally_interval_min",
	"phase_b/ally_interval_max",
	"phase_b/counter_interval",
	"phase_b/counter_warn",
	"phase_b/open_time",
	"phase_b/success_time",
	"phase_b/max_counters",
	"variant_jour10/deflect_closes_at",
	"variant_jour10/end_on_misses",
	"anims/strike",
	"anims/guard",
]
const BALL_TEXTS: Array[String] = [
	"kickoff",
	"half_time",
	"full_time",
	"goal",
	"save",
	"fall",
	"lost",
	"found",
	"found_player",
	"bench",
	"sub",
	"player_in_blanc",
	"player_in_rouge",
	"team_blanc",
	"team_rouge",
	"half_1",
	"half_2",
	"half_break",
	"full_time_label",
]


func before_each() -> void:
	GameRules.clear_cache()


func test_the_ball_rules_file_is_valid_and_complete() -> void:
	assert_eq(GameRules.problems(&"ballon", BALL_REQUIRED), PackedStringArray())


func test_the_training_rules_file_is_valid_and_complete() -> void:
	assert_eq(GameRules.problems(&"staff_training", STAFF_REQUIRED), PackedStringArray())


func test_the_numbers_are_the_ones_of_the_scenario() -> void:
	# VIE.md 5.1 : deux mi-temps de trois minutes ; une mi-temps ; les meilleures buteuses gardées.
	assert_eq(GameRules.number(&"ballon", "half_time", 0.0), 180.0)
	assert_eq(GameRules.number(&"ballon", "halves", 0.0), 2.0)
	assert_eq(GameRules.number(&"ballon", "keep_top_scorers", 0.0), 1.0)
	# ACTE1.md 3.2 : de 50 à 75 coups par minute, annoncés 0,5 s avant ; fenêtre de 0,15 s ;
	# fatigue d'un cinquième toutes les 30 s ; assise à 90 s ; douze réponses dont trois déviations.
	assert_eq(GameRules.number(&"staff_training", "phase_a/tempo_start", 0.0), 1.2)
	assert_eq(GameRules.number(&"staff_training", "phase_a/tempo_end", 0.0), 0.8)
	assert_eq(GameRules.number(&"staff_training", "phase_a/warn", 0.0), 0.5)
	assert_eq(GameRules.number(&"staff_training", "phase_a/deflect_window", 0.0), 0.15)
	assert_eq(GameRules.number(&"staff_training", "phase_a/open_time", 0.0), 0.5)
	assert_eq(GameRules.number(&"staff_training", "phase_a/fatigue_every", 0.0), 30.0)
	assert_eq(GameRules.number(&"staff_training", "phase_a/fatigue_shrink", 0.0), 0.2)
	assert_eq(GameRules.number(&"staff_training", "phase_a/sit_at", 0.0), 90.0)
	assert_eq(GameRules.number(&"staff_training", "phase_a/success_streak", 0.0), 12.0)
	assert_eq(GameRules.number(&"staff_training", "phase_a/success_deflections", 0.0), 3.0)
	# Phase B : une contre toutes les 2 s, annoncée 0,4 s avant ; 60 s, trois contres au plus.
	assert_eq(GameRules.number(&"staff_training", "phase_b/counter_interval", 0.0), 2.0)
	assert_eq(GameRules.number(&"staff_training", "phase_b/counter_warn", 0.0), 0.4)
	assert_eq(GameRules.number(&"staff_training", "phase_b/open_time", 0.0), 0.4)
	assert_eq(GameRules.number(&"staff_training", "phase_b/success_time", 0.0), 60.0)
	assert_eq(GameRules.number(&"staff_training", "phase_b/max_counters", 0.0), 3.0)
	# Jour 10 : la fenêtre se ferme à 15 s, l'exercice s'arrête au troisième raté.
	assert_eq(GameRules.number(&"staff_training", "variant_jour10/deflect_closes_at", 0.0), 15.0)
	assert_eq(GameRules.number(&"staff_training", "variant_jour10/end_on_misses", 0.0), 3.0)


func test_overrides_win_over_the_file() -> void:
	var overrides := {"half_time": 10, "kick/reach": 1.5}
	assert_eq(GameRules.number(&"ballon", "half_time", 0.0, overrides), 10.0)
	assert_eq(GameRules.number(&"ballon", "kick/reach", 0.0, overrides), 1.5)
	assert_eq(GameRules.number(&"ballon", "halves", 0.0, overrides), 2.0, "le reste du fichier")
	assert_eq(GameRules.number(&"ballon", "inconnu/chemin", 7.0), 7.0, "défaut")


func test_a_broken_rules_file_is_reported() -> void:
	assert_gt(GameRules.problems(&"n_existe_pas").size(), 0, "fichier absent")
	assert_gt(GameRules.problems(&"ballon", ["rien/du/tout"]).size(), 0, "chemin exigé absent")


func test_the_ball_activity_is_declared_and_points_at_the_game_script() -> void:
	LifeData.clear_cache()
	assert_eq(LifeData.activities_problems(), PackedStringArray(), "activities.json valide")
	assert_true(LifeData.has_activity(&"ballon"))
	var activity := LifeData.activity(&"ballon")
	assert_eq(activity["game"], "ballon")
	assert_true(ResourceLoader.exists("res://src/life/games/ballon.gd"))
	assert_true(LifeData.all_problems().is_empty(), "toute la vie reste valide")


func test_every_text_the_games_say_exists() -> void:
	LifeTexts.clear_cache()
	for key: String in BALL_TEXTS:
		assert_ne(LifeTexts.text("games/ballon/%s" % key), "", "games/ballon/%s" % key)
	for key: String in [
		"start",
		"start_b",
		"tired",
		"success_a",
		"success_b",
		"touched",
		"fail",
		"open",
		"hud_streak",
		"hud_touches",
		"hud_counters",
		"hud_title",
	]:
		assert_ne(LifeTexts.text("games/baton/%s" % key), "", "games/baton/%s" % key)


func test_the_dev_shortcut_is_recognised() -> void:
	const Shortcuts := preload("res://src/test_shortcuts.gd")
	assert_eq(Shortcuts.parse_query("?jeu=ballon"), {"jeu": "ballon"})
	assert_eq(Shortcuts.parse_arguments(PackedStringArray(["--jeu=baton"])), {"jeu": "baton"})
	assert_eq(MiniGames.dev_start("inconnu"), null, "un jeu inconnu est ignoré")
