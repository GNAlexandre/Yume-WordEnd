extends SceneTree
## Test de fumée (PLAN.md section 9) : chaque script de res://src se compile, chaque scène de
## res://src et res://tests s'instancie, passe deux images dans l'arbre (process + physique)
## puis se libère sans erreur.
##
## Usage : tools/godot --headless --script tools/smoke.gd [-- res://chemin/scene.tscn ...]
## Code de retour 1 si un script ne compile pas ou si une scène ne s'instancie pas ; les
## erreurs et avertissements imprimés par Godot sont relevés par tools/check.sh.

const SCRIPT_ROOTS: Array[String] = ["res://src"]
const SCENE_ROOTS: Array[String] = ["res://src", "res://tests"]

var _failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	# Les autoloads n'existent qu'après la première image d'un script SceneTree.
	await process_frame
	var scenes: Array[String] = []
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		for base in SCRIPT_ROOTS:
			for path in _collect(base, ".gd"):
				_check_script(path)
		for base in SCENE_ROOTS:
			scenes.append_array(_collect(base, ".tscn"))
	else:
		scenes.append_array(args)
	for path in scenes:
		await _check_scene(path)
	for failure in _failures:
		printerr("SMOKE: ", failure)
	print("smoke : %d scène(s), %d échec(s)" % [scenes.size(), _failures.size()])
	quit(1 if not _failures.is_empty() else 0)


func _check_script(path: String) -> void:
	var script := load(path) as Script
	if script == null:
		_failures.append("script illisible : " + path)
	elif not script.can_instantiate() and not script.is_abstract():
		_failures.append("script qui ne compile pas : " + path)


func _check_scene(path: String) -> void:
	var packed := load(path) as PackedScene
	if packed == null:
		_failures.append("scène illisible : " + path)
		return
	var node := packed.instantiate()
	if node == null:
		_failures.append("scène qui ne s'instancie pas : " + path)
		return
	get_root().add_child(node)
	await process_frame
	await physics_frame
	await process_frame
	node.queue_free()
	await process_frame


func _collect(base: String, extension: String) -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(base)
	if dir == null:
		return result
	for sub in dir.get_directories():
		if not sub.begins_with("."):
			result.append_array(_collect(base.path_join(sub), extension))
	for file in dir.get_files():
		if file.ends_with(extension):
			result.append(base.path_join(file))
	result.sort()
	return result
