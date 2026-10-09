extends SceneTree
## (E1) Banc des cartes : temps de chargement et mémoire d'un aller-retour de carte en carte
## dans la vraie partie (src/game.tscn), sans écrire de sauvegarde.
##
##   tools/godot --headless --script tools/map_bench.gd [-- --bench-rounds=3
##     --bench-maps=essai,ile_ancienne --bench-start=essai]
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1280x720x24" tools/godot \
##     --rendering-driver opengl3 --resolution 1280x720 --script tools/map_bench.gd
##
## Imprime, pour la carte de départ (WorldManager.enter_map, d'un bloc, comme au lancement
## d'une partie) puis pour chaque WorldManager.go_to : fondu, chargement découpé (et ses
## images), installation (ancienne carte libérée, nouvelle instanciée, joueur posé), total ;
## puis, à chaque arrivée, les nœuds, objets et ressources vivants et la mémoire statique.
## Une carte quittée doit être libérée : ResourceLoader.has_cached(sa scène) faux, et les mêmes
## comptes à chaque visite d'une même carte. Code de retour 1 sinon. Tout est libéré avant de
## quitter (pas de « resources still in use at exit »).

const GAME_SCENE := "res://src/game.tscn"

var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	# Les autoloads n'existent qu'après la première image d'un script SceneTree.
	await process_frame
	var options := _options()
	var rounds := int(options.get("bench-rounds", "2"))
	var maps := str(options.get("bench-maps", "essai,ile_ancienne")).split(",", false)
	var world := root.get_node(^"WorldManager")
	var game_state := root.get_node(^"GameState")
	game_state.call(&"reset")
	var start := StringName(str(options.get("bench-start", "")))
	if not start.is_empty():
		# Partie « chargée » dans cette carte, au Spawn (game.gd la pose comme une sauvegarde).
		game_state.set(&"map", start)
		game_state.set(&"position", Vector3(20.0, 0.2, 16.0))
	_report(world, "avant la partie")
	var started := Time.get_ticks_usec()
	var game := (load(GAME_SCENE) as PackedScene).instantiate()
	root.add_child(game)
	print(
		(
			"carte de départ %s : %.0f ms (chargement d'un bloc, instanciation, joueur posé)"
			% [world.call(&"current_map"), (Time.get_ticks_usec() - started) / 1000.0]
		)
	)
	await _frames(10)
	_report(world, "départ")
	var seen: Dictionary = {}
	for round_index in rounds:
		for map_id: String in maps:
			var previous := str(world.call(&"current_map"))
			world.call(&"go_to", StringName(map_id))
			await Signal(world, &"transition_finished")
			await _frames(10)
			var stats: Dictionary = world.call(&"last_transition")
			print(
				(
					(
						"tour %d, %s → %s : fondu %.0f ms, chargement %.0f ms en %d images, "
						% [
							round_index + 1,
							previous,
							map_id,
							stats.get("fade_out_ms", 0.0),
							stats.get("load_ms", 0.0),
							stats.get("load_frames", 0),
						]
					)
					+ (
						"installation %.0f ms, total %.0f ms"
						% [stats.get("install_ms", 0.0), stats.get("total_ms", 0.0)]
					)
				)
			)
			var counts := _report(world, map_id)
			var scene_path := "res://src/world/maps/%s/%s.tscn" % [previous, previous]
			if previous != map_id and ResourceLoader.has_cached(scene_path):
				_failures.append("%s encore en mémoire après le départ" % previous)
			if seen.has(map_id) and seen[map_id] != counts:
				_failures.append("%s : %s puis %s" % [map_id, seen[map_id], counts])
			seen[map_id] = counts
	game.free()
	game_state.call(&"reset")
	await _frames(3)
	for failure in _failures:
		printerr("MAP BENCH : ", failure)
	print("banc des cartes : %d échec(s)" % _failures.size())
	quit(1 if not _failures.is_empty() else 0)


## Nœuds et objets vivants (comparés d'une visite à l'autre) ; imprime aussi les ressources et
## la mémoire statique (indicatives : caches du moteur).
func _report(world: Node, label: String) -> Array[int]:
	var nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var objects := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	print(
		(
			"  %s (%s) : %d nœuds, %d objets, %d ressources, %.1f Mo de mémoire statique"
			% [
				label,
				world.call(&"current_map"),
				nodes,
				objects,
				int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),
				Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
			]
		)
	)
	return [nodes, objects] as Array[int]


func _frames(count: int) -> void:
	for _i in count:
		await process_frame


func _options() -> Dictionary:
	var result := {}
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--") and "=" in argument:
			result[argument.trim_prefix("--").get_slice("=", 0)] = argument.get_slice("=", 1)
	return result
