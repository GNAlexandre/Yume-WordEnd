extends GutTest
## Écran de chargement (Lot 9) : contrat de main.gd, progression bornée, fin signalée une fois,
## chargement découpé en plusieurs images (export Web mono-thread).

const Loading := preload("res://src/ui/loading.gd")
const SCENE := preload("res://src/ui/loading.tscn")

var _loading: Loading


func before_each() -> void:
	_loading = SCENE.instantiate() as Loading
	add_child_autofree(_loading)


func test_main_gd_contract() -> void:
	assert_eq(String(_loading.name), "Loading", "racine nommée Loading")
	assert_true(_loading.has_method(&"set_progress"))
	_loading.call(&"set_progress", 0.0)
	assert_false(_loading.is_finished(), "0 : chargement en cours")
	_loading.call(&"set_progress", 1.0)
	assert_true(_loading.is_finished(), "1 : chargement terminé")


func test_progress_updates_bar_and_text() -> void:
	var bar := _loading.get_node("Bar") as ProgressBar
	_loading.set_progress(0.0)
	assert_eq(bar.value, 0.0)
	assert_eq(_loading.status_text(), "Chargement de l'île…", "pas de « 0 % » figé à l'écran")
	_loading.set_progress(0.5)
	assert_almost_eq(bar.value, 0.5, 0.001)
	assert_eq(_loading.status_text(), "Chargement de l'île… 50 %")
	_loading.set_progress(1.7)
	assert_eq(_loading.progress, 1.0, "borné à 1")
	assert_eq(_loading.status_text(), "Prêt !")
	_loading.set_progress(-2.0)
	assert_eq(_loading.progress, 0.0, "borné à 0")


func test_finished_is_emitted_once() -> void:
	watch_signals(_loading)
	_loading.set_progress(0.3)
	assert_signal_not_emitted(_loading, "finished")
	_loading.set_progress(1.0)
	_loading.set_progress(1.0)
	assert_signal_emit_count(_loading, "finished", 1, "une seule fin")
	assert_signal_emit_count(_loading, "progress_changed", 3)
	_loading.set_progress(0.2)
	_loading.set_progress(1.0)
	assert_signal_emit_count(_loading, "finished", 2, "un nouveau chargement se termine à nouveau")


func test_dependency_order_puts_dependencies_first() -> void:
	var order := Loading.dependency_order("res://src/game.tscn")
	assert_gt(order.size(), 5, "game.tscn a des dépendances")
	assert_does_not_have(order, "res://src/game.tscn")
	var seen := {}
	for path: String in order:
		assert_false(seen.has(path), "sans doublon : %s" % path)
		seen[path] = true
		for dependency: String in Loading.dependency_order(path):
			assert_lt(order.find(dependency), order.find(path), "%s avant %s" % [dependency, path])


func test_load_scene_advances_over_several_frames() -> void:
	var ratios: Array[float] = []
	_loading.progress_changed.connect(func(ratio: float) -> void: ratios.append(ratio))
	var start_frame := Engine.get_process_frames()
	var scene: PackedScene = await _loading.load_scene("res://src/ui/touch_controls.tscn", 0.0)
	assert_not_null(scene, "la scène est renvoyée")
	assert_gt(Engine.get_process_frames() - start_frame, 1, "l'écran a été redessiné entre-temps")
	assert_gt(ratios.size(), 3, "plusieurs étapes visibles")
	for i in range(1, ratios.size()):
		assert_true(ratios[i] >= ratios[i - 1], "progression croissante")
	assert_eq(ratios[-1], 1.0)
	assert_true(_loading.is_finished())


func test_load_scene_rejects_missing_scene() -> void:
	var scene: PackedScene = await _loading.load_scene("res://src/ui/absente.tscn")
	assert_push_error("introuvable")
	assert_null(scene)
