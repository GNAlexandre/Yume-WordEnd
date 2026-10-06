extends Node
## Raccourcis de test (intégration M1), sans effet dans une partie normale. Paramètres lus dans
## l'adresse de la page sur le Web (`index.html?zone=dunes&timeres=12`) ou dans les arguments
## utilisateur ailleurs (`tools/godot -- --zone=dunes --timeres=12`) ; src/game.gd ne crée ce
## nœud que si l'un d'eux est présent (docs/web.md, « Raccourcis de test ») :
##   zone=<id>    place le joueur au Spawn de la zone, tourné vers le panneau de son arène s'il y
##                en a une (dunes : 15 m tout droit jusqu'au panneau), sinon vers son centre ;
##                une zone inconnue est ignorée ;
##   timeres=<n>  banc de performance : n Timeres (les quatre types, au plus MAX_BENCH) errent
##                autour du joueur sans le poursuivre.
## Tant qu'il est actif, la console reçoit une ligne « [m1] … » par événement (zone, vague,
## Timere tué, fin de série, dégâts, mort, réapparition) et, toutes les REPORT_PERIOD s,
## images/s, draw calls et primitives : un navigateur sans écran (Playwright) suit la partie.

const ENEMY_SCENE := preload("res://src/enemies/enemy.tscn")
## Paramètres reconnus (les autres sont ignorés).
const KEYS: Array[String] = ["zone", "timeres"]
## Types du banc de performance, en rotation.
const BENCH_TYPES: Array[StringName] = [
	&"timere_small", &"timere_normal", &"timere_runner", &"timere_big"
]
const MAX_BENCH := 24
## Anneau où errent les Timeres du banc, autour du joueur (m).
const BENCH_RING := Vector2(3.5, 7.0)
const REPORT_PERIOD := 2.0

## Paramètres de cette exécution (clé → texte), posés par game.gd avant l'ajout à l'arbre.
var parameters: Dictionary = {}

var _report_left: float = REPORT_PERIOD


## Paramètres de test de cette exécution ({} en partie normale).
static func read_parameters() -> Dictionary:
	if OS.has_feature("web"):
		var search: Variant = JavaScriptBridge.eval("window.location.search", true)
		return parse_query(str(search) if search != null else "")
	return parse_arguments(OS.get_cmdline_user_args())


## Paramètres reconnus d'une chaîne de requête d'URL (« ?zone=dunes&timeres=12 »).
static func parse_query(query: String) -> Dictionary:
	var result := {}
	for pair: String in query.trim_prefix("?").split("&", false):
		_keep(result, pair)
	return result


## Paramètres reconnus d'arguments utilisateur (« --zone=dunes », « --timeres=12 »).
static func parse_arguments(arguments: PackedStringArray) -> Dictionary:
	var result := {}
	for argument: String in arguments:
		if argument.begins_with("--"):
			_keep(result, argument.trim_prefix("--"))
	return result


## Fait apparaître count Timeres (types en rotation) qui errent sur un anneau autour de center,
## sans poursuivre le joueur (laisse nulle) ; ils sont ajoutés à parent. Sert au banc de
## performance (paramètre timeres, démo M1).
static func spawn_bench(parent: Node3D, center: Vector3, count: int) -> Array[Enemy]:
	var bench: Array[Enemy] = []
	for i in clampi(count, 0, MAX_BENCH):
		var angle := TAU * i / maxf(count, 1.0) + 0.4
		var radius := lerpf(BENCH_RING.x, BENCH_RING.y, float(i % 3) / 2.0)
		var enemy := ENEMY_SCENE.instantiate() as Enemy
		var enemy_id := BENCH_TYPES[i % BENCH_TYPES.size()]
		enemy.data = load("res://data/enemies/%s.tres" % enemy_id) as EnemyData
		enemy.drops_enabled = false
		enemy.leash_m = 0.001
		enemy.position = (
			parent.to_local(center + Vector3(cos(angle), 0.0, sin(angle)) * radius)
			+ Vector3.UP * 0.2
		)
		enemy.name = "bench_%s_%d" % [enemy_id, i]
		parent.add_child(enemy)
		bench.append(enemy)
	return bench


static func _keep(result: Dictionary, pair: String) -> void:
	var key := pair.get_slice("=", 0).strip_edges()
	if key in KEYS:
		result[key] = pair.get_slice("=", 1).uri_decode().strip_edges() if "=" in pair else ""


func _ready() -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Player
	var zone_id := StringName(str(parameters.get("zone", "")))
	var zone := _zone(zone_id)
	if player != null and zone != null:
		WorldManager.teleport(zone_id)
		var panel := zone.get_node_or_null(^"Arena/Panel") as Node3D
		var target := panel.global_position if panel != null else zone.global_position
		player.set_aim_direction(target - player.global_position, true)
	elif not zone_id.is_empty():
		_log("zone inconnue : %s" % zone_id)
	var count := clampi(int(str(parameters.get("timeres", "0"))), 0, MAX_BENCH)
	var parent := get_parent() as Node3D
	if player != null and parent != null and count > 0:
		spawn_bench(parent, player.global_position, count)
	EventBus.zone_entered.connect(_on_zone_entered)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.wave_cleared.connect(_on_wave_cleared)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.arena_finished.connect(_on_arena_finished)
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.player_died.connect(_on_player_died)
	EventBus.player_respawned.connect(_on_player_respawned)
	_log("raccourcis de test %s ; %d Timeres de banc" % [parameters, count])


func _process(delta: float) -> void:
	_report_left -= delta
	if _report_left > 0.0:
		return
	_report_left = REPORT_PERIOD
	_log(
		(
			"%d i/s, %d draw calls, %d primitives, %d Timeres"
			% [
				Performance.get_monitor(Performance.TIME_FPS),
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
				Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
				get_tree().get_nodes_in_group(&"enemies").size(),
			]
		)
	)


func _zone(zone_id: StringName) -> Node3D:
	for node: Node in get_tree().get_nodes_in_group(&"zones"):
		if node.name == zone_id:
			return node as Node3D
	return null


func _log(text: String) -> void:
	print("[m1] ", text)


func _on_zone_entered(zone_id: StringName) -> void:
	_log("zone %s" % zone_id)


func _on_wave_started(arena_id: StringName, wave: int, enemy_count: int) -> void:
	_log("vague %d (%s) : %d Timeres" % [wave, arena_id, enemy_count])


func _on_wave_cleared(arena_id: StringName, wave: int, bonus: int) -> void:
	_log("vague %d (%s) nettoyée, bonus %d" % [wave, arena_id, bonus])


func _on_enemy_killed(enemy_id: StringName, points: int) -> void:
	_log("%s tué (%d points)" % [enemy_id, points])


func _on_arena_finished(arena_id: StringName, score: int, best: bool) -> void:
	_log("fin de série %s : %d points%s" % [arena_id, score, " (record)" if best else ""])


func _on_player_damaged(amount: int, _source: Node3D) -> void:
	_log("joueur blessé (%d)" % amount)


func _on_player_died() -> void:
	_log("joueur mort")


func _on_player_respawned() -> void:
	_log("joueur réapparu")
