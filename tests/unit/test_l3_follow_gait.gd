extends GutTest
## (L3) L'allure adaptative des suiveurs (StoryStage) : marche près de la garde, course au-delà de
## garde + 1,5 m, poursuite (« rattrape ») au-delà de 6 m, avec hystérésis ; et l'allure dans les
## données de la vie.

var _stage: StoryStage


func before_each() -> void:
	_stage = StoryStage.new()


func after_each() -> void:
	_stage.free()


func _settings(gait: StringName = &"marche") -> Dictionary:
	return {"distance": 2.0, "stop_beyond": 60.0, "gait": gait}


func test_gait_follows_the_distance() -> void:
	var settings := _settings()
	assert_eq(_stage._follow_gait(settings, 2.5, 2.0), &"marche", "près de la garde : marche")
	assert_eq(_stage._follow_gait(settings, 3.4, 2.0), &"marche", "pas encore garde + 1,5 m")
	assert_eq(_stage._follow_gait(settings, 3.7, 2.0), &"course", "au-delà de garde + 1,5 m")
	assert_eq(_stage._follow_gait(settings, 5.9, 2.0), &"course")
	assert_eq(_stage._follow_gait(settings, 6.3, 2.0), &"rattrape", "au-delà de 6 m")


func test_gait_has_hysteresis() -> void:
	var settings := _settings()
	_stage._follow_gait(settings, 7.0, 2.0)
	assert_eq(_stage._follow_gait(settings, 5.5, 2.0), &"rattrape", "pas de va-et-vient à 6 m")
	assert_eq(_stage._follow_gait(settings, 5.0, 2.0), &"course", "il redescend plus bas")
	assert_eq(_stage._follow_gait(settings, 3.0, 2.0), &"course", "pas de va-et-vient à 3,5 m")
	assert_eq(_stage._follow_gait(settings, 2.6, 2.0), &"marche", "il se calme près de la garde")


func test_scene_gait_is_the_floor() -> void:
	var settings := _settings(&"course")
	assert_eq(_stage._follow_gait(settings, 2.4, 2.0), &"course", "la course de la scène reste")
	assert_eq(_stage._follow_gait(settings, 7.0, 2.0), &"rattrape")


func test_catch_up_gait_is_in_the_life_data() -> void:
	assert_true(LifeData.is_gait(&"rattrape"))
	var player := Player.new()
	assert_gt(LifeData.speed(&"rattrape"), player.run_speed, "plus vif que la course du joueur")
	player.free()
	assert_gt(LifeData.speed(&"rattrape"), LifeData.speed(&"course"))
	assert_gt(LifeData.anim_speed(&"rattrape"), 1.0, "une course accélérée")
	assert_eq(LifeData.anim_speed(&"marche"), 1.0)
	assert_eq(LifeData.activities_problems().size(), 0)
