extends GutTest
## (Systèmes et textes) Les quatre corps de Timere de l'acte 1 (HISTOIRE.md, section 7.2) : mêmes
## données et mêmes chiffres, nouveaux noms affichés au niveau du volume 1 (rejeton, fragment,
## Timere bondissant, grand fragment), et aucun drop : Timere cherche les vivants et ignore les
## choses (V3). Les noms servent aussi à la progression des quêtes (QuestStep).

const NAMES := {
	&"timere_small": "Rejeton de Timere",
	&"timere_normal": "Fragment de Timere",
	&"timere_runner": "Timere bondissant",
	&"timere_big": "Grand fragment de Timere",
}
## Chiffres inchangés (PLAN.md section 4) : échelle, PV, vitesse, points.
const NUMBERS := {
	&"timere_small": [0.8, 1, 3.0, 10],
	&"timere_normal": [1.0, 2, 2.1, 15],
	&"timere_runner": [0.9, 1, 6.2, 20],
	&"timere_big": [1.3, 5, 1.6, 40],
}


func _data(enemy_id: StringName) -> EnemyData:
	return load("res://data/enemies/%s.tres" % enemy_id) as EnemyData


func test_bodies_have_their_act_one_names() -> void:
	for enemy_id: StringName in NAMES:
		var data := _data(enemy_id)
		assert_not_null(data, String(enemy_id))
		if data == null:
			continue
		assert_eq(data.display_name, NAMES[enemy_id], "%s : nom affiché" % enemy_id)
		assert_eq(QuestStep.enemy_display_name(enemy_id), NAMES[enemy_id], "nom des quêtes")
		var numbers: Array = NUMBERS[enemy_id]
		assert_almost_eq(data.scale, float(numbers[0]), 0.001, "%s : échelle" % enemy_id)
		assert_eq(data.max_hp, numbers[1], "%s : PV" % enemy_id)
		assert_almost_eq(data.speed, float(numbers[2]), 0.001, "%s : vitesse" % enemy_id)
		assert_eq(data.points, numbers[3], "%s : points" % enemy_id)
		assert_eq(data.visual.id, &"timere", "%s : la planche du Timere" % enemy_id)


func test_no_body_of_timere_drops_anything() -> void:
	var files := 0
	for file_name: String in DirAccess.get_files_at("res://data/enemies"):
		if not file_name.ends_with(".tres"):
			continue
		var data := load("res://data/enemies".path_join(file_name)) as EnemyData
		files += 1
		assert_true(data.drops.is_empty(), "%s : Timere ignore les objets" % file_name)
	assert_gte(files, NAMES.size(), "les quatre corps au moins")


func test_kill_progress_uses_the_new_names() -> void:
	var step := QuestStep.new()
	step.type = QuestStep.KILL
	step.count = 2
	for enemy_id: StringName in NAMES:
		step.enemy = enemy_id
		assert_eq(step.progress_text(1), "%s : 1/2" % NAMES[enemy_id])
	step.enemy = QuestStep.ANY_ENEMY
	assert_eq(step.progress_text(1), "Ennemis vaincus : 1/2", "« any » : ennemis vaincus")
