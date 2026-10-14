extends GutTest
## (T2) Examinable (src/world/examinable.gd) : zone d'interaction (couche 6, groupe
## « interactable »), invite « Examiner », texte lu dans un fichier de textes de l'histoire et
## affiché page par page par le protocole de DialogueRunner (dialogue_started, dialogue_line sans
## nom ni choix, dialogue_ended), {player} remplacé, signal examined à la fin.

const TEXTS := "user://t2_examinable_test.json"
const CONTENT := {
	"prompt": "Regarder",
	"salle":
	{
		"_comment": "commentaire ignoré",
		"vase": "Un vase ébréché.",
		"lettre": "Une lettre pour {player}.\n\nAu dos, un dessin d'enfant.",
	},
}

var _lines: Array[String] = []
var _started: Array[StringName] = []
var _ended: Array[StringName] = []


func before_each() -> void:
	GameState.reset()
	var file := FileAccess.open(TEXTS, FileAccess.WRITE)
	file.store_string(JSON.stringify(CONTENT))
	file.close()
	Examinable.forget_texts()
	_lines.clear()
	_started.clear()
	_ended.clear()
	EventBus.dialogue_line.connect(_on_line)
	EventBus.dialogue_started.connect(_on_started)
	EventBus.dialogue_ended.connect(_on_ended)


func after_each() -> void:
	EventBus.dialogue_line.disconnect(_on_line)
	EventBus.dialogue_started.disconnect(_on_started)
	EventBus.dialogue_ended.disconnect(_on_ended)
	Examinable.forget_texts()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEXTS))


func _on_line(speaker: String, text: String, choices: Array[String]) -> void:
	_lines.append("%s|%s|%d" % [speaker, text, choices.size()])


func _on_started(id: StringName) -> void:
	_started.append(id)


func _on_ended(id: StringName) -> void:
	_ended.append(id)


func _make(key: String) -> Examinable:
	var item := Examinable.new()
	item.texts_path = TEXTS
	item.text_key = key
	item.size = Vector3(1.2, 1.5, 0.6)
	add_child_autofree(item)
	return item


func test_is_an_interactable_zone_with_its_prompt() -> void:
	var item := _make("salle/vase")
	assert_eq(item.collision_layer, 32, "couche 6 (interactable)")
	assert_true(item.is_in_group(&"interactable"))
	assert_true(item.monitorable)
	assert_eq(item.get_prompt(), "Regarder", "invite du fichier")
	item.prompt = "Lire"
	assert_eq(item.get_prompt(), "Lire", "invite propre à l'objet")
	var shape := item.get_child(0, true) as CollisionShape3D
	assert_not_null(shape, "zone créée au chargement")
	if shape != null:
		assert_eq((shape.shape as BoxShape3D).size, Vector3(1.2, 1.5, 0.6))
		assert_almost_eq(shape.position.y, 0.75, 0.001, "posée sur le sol")
	assert_eq(Examinable.lookup(Examinable.TEXTS_PATH, "prompt"), "Examiner", "entrepot.json")


func test_shows_each_page_without_name_and_ends_with_examined() -> void:
	var item := _make("salle/lettre")
	watch_signals(item)
	item.interact(null)
	assert_true(DialogueRunner.is_any_running(), "un dialogue en cours")
	assert_eq(_started, [&"examine_salle_lettre"] as Array[StringName], "identifiant du dialogue")
	var player := DialogueRunner.player_name()
	assert_eq(_lines, ["|Une lettre pour %s.|0" % player] as Array[String], "première page")
	assert_false(item.show_text(), "un seul dialogue à la fois")
	EventBus.dialogue_choice_made.emit(0)
	assert_eq(_lines.size(), 2, "seconde page")
	assert_eq(_lines[1], "|Au dos, un dessin d'enfant.|0")
	EventBus.dialogue_choice_made.emit(0)
	assert_false(DialogueRunner.is_any_running(), "fin de la lecture")
	assert_eq(_ended, [&"examine_salle_lettre"] as Array[StringName])
	assert_signal_emitted_with_parameters(item, "examined", ["salle/lettre"])


func test_a_missing_text_shows_nothing() -> void:
	var item := _make("salle/absent")
	assert_eq(item.text_value(), "")
	assert_false(item.show_text(), "rien à afficher")
	assert_false(DialogueRunner.is_any_running())
	assert_eq(_started.size(), 0)
	assert_eq(Examinable.lookup(TEXTS, "salle/_comment"), "", "un commentaire n'est pas un texte")
