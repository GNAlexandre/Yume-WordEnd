extends GutTest
## (E8b) Le duel et l'entraînement avec Seniorious côté données et récit : inscrits au récit
## (« duel_willem », « entrainement_seniorious ») ; leurs règles (data/games/duel.json et
## seniorious.json : les chiffres d'ACTE1.md 3.3 et 3.4) ; leurs textes ; la planche de
## remplacement willem_duel (Willem et le Carillon Percival : repos, marche, parle, attaque, pare,
## trois vues, 96 px par mètre) et la tenue « duel » de Willem ; les raccourcis `?jeu=`.

const DUEL_REQUIRED: Array[String] = [
	"phase_1/max_time",
	"phase_1/beckon_after",
	"phase_2/charge_hold",
	"phase_2/pale",
	"phase_2/slow",
	"phase_2/dash_distance",
	"phase_2/strides",
	"phase_3/white_hold",
	"phase_3/beat_at",
	"phase_3/throw_distance",
	"reprise/speed",
	"anims/willem_deflect",
	"anims/player_thrown",
]
const SENIORIOUS_REQUIRED: Array[String] = [
	"breath/inhale",
	"breath/exhale",
	"breath/tolerance",
	"breath/cycles",
	"moves/gestures",
	"moves/count",
	"moves/window",
	"crane/warn",
	"crane/window",
	"crane/needed",
	"crane/max_fends",
	"pickup/place",
]
const WILLEM := preload("res://data/npcs/willem.tres")


func before_each() -> void:
	GameRules.clear_cache()
	LifeTexts.clear_cache()


func test_both_games_are_registered_with_the_story() -> void:
	assert_eq(MiniGames.STORY_DUEL, &"duel_willem")
	assert_eq(MiniGames.STORY_SENIORIOUS, &"entrainement_seniorious")
	assert_true(StoryDirector.has_game(&"duel_willem"), "inscrit par StoryDirector._ready")
	assert_true(StoryDirector.has_game(&"entrainement_seniorious"))
	assert_true(StoryDirector.has_game(&"embuscade_pannibal"), "l'embuscade reste inscrite")


func test_the_duel_rules_are_those_of_the_scenario() -> void:
	assert_eq(GameRules.problems(&"duel", DUEL_REQUIRED), PackedStringArray())
	# ACTE1.md 3.3 : 30 s au plus, signe au bout de 8 s, charge tenue 2 s, désaturation de 60 %,
	# le monde à 0,6, un élan de 8 m en deux foulées, 0,6 s de blanc, projetée à 6 m.
	assert_eq(GameRules.number(&"duel", "phase_1/max_time", 0.0), 30.0)
	assert_eq(GameRules.number(&"duel", "phase_1/beckon_after", 0.0), 8.0)
	assert_eq(GameRules.number(&"duel", "phase_2/charge_hold", 0.0), 2.0)
	assert_eq(GameRules.number(&"duel", "phase_2/pale", 0.0), 0.6)
	assert_eq(GameRules.number(&"duel", "phase_2/slow", 0.0), 0.6)
	assert_eq(GameRules.number(&"duel", "phase_2/dash_distance", 0.0), 8.0)
	assert_eq(GameRules.number(&"duel", "phase_2/strides", 0.0), 2.0)
	assert_eq(GameRules.number(&"duel", "phase_3/white_hold", 0.0), 0.6)
	assert_eq(GameRules.number(&"duel", "phase_3/throw_distance", 0.0), 6.0)
	assert_gt(GameRules.number(&"duel", "reprise/speed", 0.0), 1.0, "la reprise, plus vite")


func test_the_seniorious_rules_are_those_of_the_scenario() -> void:
	assert_eq(GameRules.problems(&"seniorious", SENIORIOUS_REQUIRED), PackedStringArray())
	# ACTE1.md 3.4 : inspirer 2 s, expirer 2 s, à 0,3 s près, cinq cycles ; neuf annonces en
	# 1,5 s ; le fend annoncé 0,6 s, la parade parfaite de 0,2 s, trois Grues.
	assert_eq(GameRules.number(&"seniorious", "breath/inhale", 0.0), 2.0)
	assert_eq(GameRules.number(&"seniorious", "breath/exhale", 0.0), 2.0)
	assert_eq(GameRules.number(&"seniorious", "breath/tolerance", 0.0), 0.3)
	assert_eq(GameRules.number(&"seniorious", "breath/cycles", 0.0), 5.0)
	assert_eq(GameRules.number(&"seniorious", "moves/count", 0.0), 9.0)
	assert_eq(GameRules.number(&"seniorious", "moves/window", 0.0), 1.5)
	assert_eq(GameRules.number(&"seniorious", "crane/warn", 0.0), 0.6)
	assert_eq(GameRules.number(&"seniorious", "crane/window", 0.0), 0.2)
	assert_eq(GameRules.number(&"seniorious", "crane/needed", 0.0), 3.0)
	assert_eq(GameRules.value(&"seniorious", "pickup/place", ""), "marais_epee")


func test_every_text_the_games_say_exists() -> void:
	for key: String in [
		"intro", "reprise", "dodge", "beckon", "hud_dodge", "hud_ready", "hud_vision"
	]:
		assert_ne(LifeTexts.text("games/duel/%s" % key, ""), "", "duel : %s" % key)
	var seniorious_keys: Array[String] = [
		"intro",
		"breath_start",
		"moves_start",
		"crane_start",
		"move_done",
		"crane_parried",
		"crane_hit",
		"crane_done",
		"sword_flew",
		"tired",
		"pickup_prompt",
		"hud_title",
		"hud_breath",
		"hud_in",
		"hud_out",
		"hud_moves",
		"hud_crane",
	]
	for outcome: String in ["good", "early", "late", "missed"]:
		seniorious_keys.append("breath_%s" % outcome)
	for gesture: String in ["trois_coups", "pare", "cote"]:
		seniorious_keys.append("gesture_%s" % gesture)
		seniorious_keys.append("move_missed_%s" % gesture)
	for key: String in seniorious_keys:
		assert_ne(LifeTexts.text("games/seniorious/%s" % key, ""), "", "Seniorious : %s" % key)
	assert_eq(LifeTexts.text("games/seniorious/pickup_prompt", ""), "Ramasser Seniorious")


func test_willem_has_his_duel_outfit_with_percival() -> void:
	assert_true(WILLEM.has_outfit(&"duel"), "la tenue « duel » de Willem")
	var skin := WILLEM.load_outfit(&"duel")
	assert_eq(skin.id, &"willem_duel")
	var sheet := SheetLoader.read_sheet(skin)
	assert_almost_eq(SheetLoader.pixel_size(skin, sheet), 1.0 / 96.0, 0.0004, "96 px par mètre")
	var anims := SheetLoader.animations(sheet)
	for anim: String in ["repos", "marche", "parle", "attaque", "pare"]:
		assert_true(anims.has(anim), "willem_duel : %s (cahier n° 6, C.10)" % anim)
	assert_eq(
		SheetLoader.hit_frames(sheet, &"attaque"), [2] as Array[int], "la déviation : coup [2]"
	)
	for view: StringName in [SheetLoader.FRONT, SheetLoader.BACK]:
		assert_true(SheetLoader.has_view(skin, view), "vue %s" % view)
		assert_eq(SheetLoader.view_problem(skin, view), "", "vue %s" % view)


func test_the_dev_shortcut_knows_the_new_games() -> void:
	for game: String in ["ballon", "baton", "duel", "seniorious"]:
		assert_has(MiniGames.DEV_GAMES, game)
