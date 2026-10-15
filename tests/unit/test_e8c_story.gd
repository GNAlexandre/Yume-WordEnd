extends GutTest
## (E8c) Le récit branché sur les jeux et les places : l'embuscade de Pannibal inscrite au récit
## (« embuscade_pannibal ») et appelée par l'étape « game » de j1_2_embuscade, son repli gardé ; les
## règles de l'embuscade (data/games/embuscade.json, chiffres de ACTE1.md 3.1) ; ses textes ; la
## place de Willem au réfectoire (refectoire_porte_est) dans le plan d'entrepot_rdc et dans
## j2_2_fuite, sans point en dur.

const ISLAND := &"ile_68"
const AMBUSH_REQUIRED: Array[String] = [
	"touch_limit",
	"success_streak",
	"recoil",
	"leap/distance",
	"leap/warn",
	"leap/radius",
	"leap/feint_from_day",
	"leap/feint_every",
	"slash/count",
	"slash/interval",
	"slash/reach",
	"riposte/window",
	"riposte/reach",
	"anims/leap",
	"anims/slash",
	"anims/fall",
	"anims/victory",
]
const RDC_SCENE := "res://src/world/maps/entrepot_rdc/entrepot_rdc.tscn"


func before_each() -> void:
	GameRules.clear_cache()


func _steps(scene_id: StringName) -> Array:
	return StoryData.scene(ISLAND, scene_id).get("steps", [])


func test_the_ambush_is_registered_with_the_story() -> void:
	assert_true(StoryDirector.has_game(&"embuscade_pannibal"), "inscrite par StoryDirector._ready")
	assert_eq(MiniGames.STORY_AMBUSH, &"embuscade_pannibal")


func test_the_ambush_scene_calls_the_game_and_keeps_its_fallback() -> void:
	var game: Dictionary = {}
	var vaincue := false
	for step: Dictionary in _steps(&"j1_2_embuscade"):
		if step.get("do") == "game":
			game = step
		if step.get("do") == "dialogue" and step.get("node") == "vaincue":
			vaincue = step.get("if", {}).get("flag") == "j1_embuscade_gagnee"
	assert_eq(game.get("game"), "embuscade_pannibal")
	var params: Dictionary = game.get("params", {})
	assert_eq(int(params.get("day", 0)), 1)
	assert_true(params.get("help", false), "les deux lignes d'aide du jour 1")
	assert_eq(params.get("success_flag"), "j1_embuscade_gagnee")
	assert_false((game.get("fallback", []) as Array).is_empty(), "le repli reste (carte d'essai)")
	assert_true(vaincue, "la réplique de plus quand Chtholly l'emporte")
	assert_eq(StoryData.all_problems(ISLAND), PackedStringArray(), "toutes les scènes valides")


func test_the_ambush_rules_are_those_of_the_scenario() -> void:
	assert_eq(GameRules.problems(&"embuscade", AMBUSH_REQUIRED), PackedStringArray())
	# ACTE1.md 3.1 : le bond annoncé 0,8 s avant, lancé de 4 m ; trois taillades à 0,35 s ;
	# une feinte sur trois à partir du jour 5 ; recul de 0,5 m ; cinq de suite ; trois points.
	assert_eq(GameRules.number(&"embuscade", "leap/warn", 0.0), 0.8)
	assert_eq(GameRules.number(&"embuscade", "leap/distance", 0.0), 4.0)
	assert_eq(GameRules.number(&"embuscade", "slash/count", 0.0), 3.0)
	assert_eq(GameRules.number(&"embuscade", "slash/interval", 0.0), 0.35)
	assert_eq(GameRules.number(&"embuscade", "leap/feint_from_day", 0.0), 5.0)
	assert_eq(GameRules.number(&"embuscade", "leap/feint_every", 0.0), 3.0)
	assert_eq(GameRules.number(&"embuscade", "recoil", 0.0), 0.5)
	assert_eq(GameRules.number(&"embuscade", "success_streak", 0.0), 5.0)
	assert_eq(GameRules.number(&"embuscade", "touch_limit", 0.0), 3.0)


func test_every_text_the_ambush_says_exists() -> void:
	LifeTexts.clear_cache()
	for key: String in [
		"point", "fall", "victory", "help_dodge", "help_guard", "hud_streak", "hud_points"
	]:
		assert_ne(LifeTexts.text("games/embuscade/%s" % key), "", "games/embuscade/%s" % key)


func test_willem_has_a_real_place_at_the_refectory() -> void:
	var map := (load(RDC_SCENE) as PackedScene).instantiate()
	var place := map.get_node_or_null(^"Life/Places/refectoire_porte_est") as Marker3D
	assert_not_null(place, "la place refectoire_porte_est (CARTE.md 3.1)")
	if place != null:
		assert_almost_eq(place.position.x, 15.75, 0.01, "au seuil de la porte est")
		assert_almost_eq(place.position.z, 7.85, 0.01)
	map.free()
	var walks: Array = []
	for step: Dictionary in _steps(&"j2_2_fuite"):
		for key: String in ["at", "to"]:
			assert_false(step.get(key) is Array, "pas de point en dur dans j2_2 (%s)" % step)
		if step.get("do") == "walk" and step.get("who") == "willem":
			walks.append(step.get("to"))
	assert_has(walks, "refectoire_porte_est", "Willem paraît à la porte")
