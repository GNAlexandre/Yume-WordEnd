extends Node
## Raccourcis de test (intégration M1), sans effet dans une partie normale. Paramètres lus dans
## l'adresse de la page sur le Web (`index.html?zone=dunes&timeres=12`) ou dans les arguments
## utilisateur ailleurs (`tools/godot -- --zone=dunes --timeres=12`) ; src/game.gd ne crée ce
## nœud que si l'un d'eux est présent (docs/web.md, « Raccourcis de test ») :
##   zone=<id>    place le joueur au Spawn de la zone, tourné vers le panneau de son arène s'il y
##                en a une (dunes : 15 m tout droit jusqu'au panneau), sinon vers son centre ;
##                une zone inconnue est ignorée ;
##   timeres=<n>  banc de performance : n Timeres (les quatre types, au plus MAX_BENCH) errent
##                devant le joueur, dans le champ de la caméra, sans le poursuivre ;
##   trace        (intégration M2) le journal seul : la partie est celle du menu, telle quelle
##                (nouvelle partie ou reprise, position et zone non touchées).
## (Acte 1) Sur le Web, la page reçoit aussi window.wordendFace(cible) : le joueur se tourne,
## caméra derrière lui, vers un PNJ (son NpcData.id, « nygglatho ») ou un point de l'île (x, z),
## comme un joueur qui oriente la caméra à la souris (impossible dans un navigateur sans écran) ;
## la marche reste aux touches ; window.wordendPos donne la position du joueur à chaque image
## ([x, z]). tools/web_m2.js s'en sert pour aller d'un PNJ à l'autre.
## Tant qu'il est actif, la console reçoit une ligne « [m1] … » par événement (zone, invite,
## dialogue, quête, (acte 1) étape de quête, objet, vague, Timere tué, fin de série, dégâts,
## mort, réapparition), une ligne au départ (zone, position du joueur, quêtes et étapes) et,
## toutes les REPORT_PERIOD s, images/s, draw calls, primitives, position et distance du Timere
## le plus proche : un navigateur sans écran (Playwright) suit ainsi la partie.

const ENEMY_SCENE := preload("res://src/enemies/enemy.tscn")
## Paramètres reconnus (les autres sont ignorés).
const KEYS: Array[String] = ["zone", "timeres", "trace"]
## Types du banc de performance, en rotation.
const BENCH_TYPES: Array[StringName] = [
	&"timere_small", &"timere_normal", &"timere_runner", &"timere_big"
]
const MAX_BENCH := 24
## Anneau où errent les Timeres du banc (m), centré BENCH_AHEAD m devant le joueur.
const BENCH_RING := Vector2(3.5, 7.0)
const BENCH_AHEAD := 6.5
const REPORT_PERIOD := 2.0

## Paramètres de cette exécution (clé → texte), posés par game.gd avant l'ajout à l'arbre.
var parameters: Dictionary = {}

var _report_left: float = REPORT_PERIOD
## Rappel JavaScript de window.wordendFace (gardé : sinon libéré par le moteur).
var _face_callback: JavaScriptObject


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
		spawn_bench(parent, player.global_position + player.aim_direction() * BENCH_AHEAD, count)
	EventBus.zone_entered.connect(_on_zone_entered)
	EventBus.interaction_available.connect(_on_interaction_available)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.wave_cleared.connect(_on_wave_cleared)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.arena_finished.connect(_on_arena_finished)
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.player_died.connect(_on_player_died)
	EventBus.player_respawned.connect(_on_player_respawned)
	EventBus.dialogue_line.connect(_on_dialogue_line)
	EventBus.dialogue_ended.connect(_on_dialogue_ended)
	EventBus.quest_updated.connect(_on_quest_updated)
	EventBus.quest_step_updated.connect(_on_quest_step_updated)
	EventBus.item_collected.connect(_on_item_collected)
	if OS.has_feature("web"):
		_face_callback = JavaScriptBridge.create_callback(_on_js_face)
		var window := JavaScriptBridge.get_interface("window")
		window.set("wordendFace", _face_callback)
	_log("raccourcis de test %s ; %d Timeres de banc" % [parameters, count])
	_log(
		(
			"partie : zone « %s », %s, quêtes %s, étapes %s, objets %s"
			% [
				GameState.zone,
				_position_text(player),
				GameState.quests(),
				GameState.quest_progress(),
				GameState.items()
			]
		)
	)


func _process(delta: float) -> void:
	if _face_callback != null:
		# Position du joueur à chaque image pour la page (window.wordendPos = [x, z]) : le script
		# du navigateur s'arrête au bon endroit sans attendre la mesure suivante.
		var player := get_tree().get_first_node_in_group(&"player") as Node3D
		if player != null:
			var at := player.global_position
			JavaScriptBridge.eval("window.wordendPos = [%.2f, %.2f];" % [at.x, at.z])
	_report_left -= delta
	if _report_left > 0.0:
		return
	_report_left = REPORT_PERIOD
	var enemies := get_tree().get_nodes_in_group(&"enemies")
	_log(
		(
			"%d i/s, %d draw calls, %d primitives, %s (%s), %d Timeres, le plus proche à %.1f m"
			% [
				Performance.get_monitor(Performance.TIME_FPS),
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
				Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
				_position_text(get_tree().get_first_node_in_group(&"player") as Node3D),
				"à écrire" if SaveManager.has_unsaved_changes() else "sauvegardée",
				enemies.size(),
				_nearest_enemy(enemies),
			]
		)
	)


func _notification(what: int) -> void:
	# SaveManager (autoload, servi avant la partie) vient d'écrire la position s'il le fallait.
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		var player := get_tree().get_first_node_in_group(&"player") as Node3D
		var state := "à écrire" if SaveManager.has_unsaved_changes() else "sauvegardée"
		_log("fenêtre sans focus : %s (%s)" % [_position_text(player), state])


## « position (x ; z) » du joueur, en mètres (« position inconnue » sans joueur).
func _position_text(player: Node3D) -> String:
	if player == null:
		return "position inconnue"
	return "position (%.1f ; %.1f)" % [player.global_position.x, player.global_position.z]


## Distance horizontale (m) du joueur au Timere vivant le plus proche (999 sans joueur ni Timere).
func _nearest_enemy(enemies: Array[Node]) -> float:
	var player := get_tree().get_first_node_in_group(&"player") as Node3D
	var nearest := 999.0
	if player == null:
		return nearest
	for node: Node in enemies:
		var offset := (node as Node3D).global_position - player.global_position
		nearest = minf(nearest, Vector2(offset.x, offset.z).length())
	return nearest


func _zone(zone_id: StringName) -> Node3D:
	for node: Node in get_tree().get_nodes_in_group(&"zones"):
		if node.name == zone_id:
			return node as Node3D
	return null


func _log(text: String) -> void:
	print("[m1] ", text)


func _on_zone_entered(zone_id: StringName) -> void:
	_log("zone %s" % zone_id)


func _on_interaction_available(prompt: String) -> void:
	if not prompt.is_empty():
		_log("invite « %s »" % prompt)


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


func _on_dialogue_line(speaker: String, text: String, choices: Array[String]) -> void:
	var line := "dialogue %s : %s" % [speaker, text]
	if not choices.is_empty():
		line += " [%s]" % " | ".join(choices)
	_log(line)


func _on_dialogue_ended(npc_id: StringName) -> void:
	_log("fin du dialogue (%s)" % npc_id)


func _on_quest_updated(quest_id: StringName, state: StringName) -> void:
	_log("quête %s : %s" % [quest_id, state])


func _on_quest_step_updated(quest_id: StringName, step_id: StringName, count: int) -> void:
	_log("étape %s : %s (%d)" % [quest_id, step_id if not step_id.is_empty() else &"-", count])


func _on_item_collected(item_id: StringName, quantity: int) -> void:
	_log("objet %s ×%d (%d en tout)" % [item_id, quantity, GameState.count(item_id)])


## Tourne le joueur (caméra derrière lui) vers une cible : face(&"nygglatho") vers ce PNJ, ou
## face_point(x, z) vers un point de l'île. Renvoie false si la cible est introuvable.
func face(npc_id: StringName) -> bool:
	for node: Node in get_tree().get_nodes_in_group(&"interactable"):
		var npc := node as Npc
		if npc != null and npc.data != null and npc.data.id == npc_id and npc.is_present():
			return face_point(npc.global_position.x, npc.global_position.z)
	_log("visée : PNJ %s introuvable" % npc_id)
	return false


func face_point(x: float, z: float) -> bool:
	var player := get_tree().get_first_node_in_group(&"player") as Player
	if player == null:
		return false
	var direction := Vector3(x, player.global_position.y, z) - player.global_position
	direction.y = 0.0
	if direction.is_zero_approx():
		return false
	player.set_aim_direction(direction, true)
	_log("visée (%.1f ; %.1f) depuis %s" % [x, z, _position_text(player)])
	return true


## window.wordendFace("nygglatho") ou window.wordendFace(x, z).
func _on_js_face(arguments: Array) -> void:
	if arguments.size() >= 2:
		face_point(float(arguments[0]), float(arguments[1]))
	elif arguments.size() == 1:
		face(StringName(str(arguments[0])))
