extends Node
## (C2) Démonstration du village des hommes-bêtes, du café et de la maison Limashenka : la vraie partie
## (game.tscn), posée par WorldManager.enter_map dans chaque carte, vue par la caméra du joueur (bornée à
## camera_bounds), sous la lumière d'Atmosphere. Lancée sous Xvfb :
##   C2_SHOTS=<dossier>  : où écrire les captures (défaut build/shots/c2) ;
##   C2_VIEWS=<liste>    : vues « carte:lieu:moment[:temps] » séparées par des virgules (défaut : VIEWS) ;
##                         lieu = une clé de SPOTS[carte], ou « ensemble » (vue d'ensemble) ;
##   C2_FRAMES=<n>       : images attendues avant chaque capture (défaut WAIT_FRAMES).
## Une ligne par capture : « C2 vue <nom> : <d> draw calls, <p> primitives, <o> objets, chargement <ms> ms »,
## puis « C2 fin : <n> vues ». Lancement (tools/c2_shots.sh) :
##   C2_SHOTS=res://build/shots/c2 LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1280x720x24" \
##     tools/godot --rendering-driver opengl3 --resolution 1280x720 res://tests/integration/demo_c2.tscn

const GAME_SCENE := preload("res://src/game.tscn")
const WAIT_FRAMES := 30
## Secondes d'attente à l'entrée d'une carte (bannière de son nom, src/ui/hud.gd).
const BANNER_WAIT := 4.0
## Où se tient le joueur (repère de la carte) et où il regarde, par carte et par lieu.
const SPOTS := {
	"village":
	{
		"entree": [Vector3(52.0, 0, 12.5), Vector3(-1, 0, 0)],
		"rue_est": [Vector3(44.0, 0, 12.5), Vector3(-1, 0, 0)],
		"rue": [Vector3(30.0, 0, 12.5), Vector3(1, 0, 0)],
		"cafe": [Vector3(19.8, 0, 11.4), Vector3(0, 0, -1)],
		"terrasse": [Vector3(17.0, 0, 12.5), Vector3(0, 0, -1)],
		"grange": [Vector3(8.0, 0, 11.5), Vector3(0, 0, -1)],
		"limashenka": [Vector3(44.0, 0, 11.4), Vector3(0, 0, -1)],
		"belvedere": [Vector3(35.0, 1.0, 6.5), Vector3(0, 0, -1)],
		"rampe": [Vector3(35.0, 0, 12.4), Vector3(0, 0, -1)],
		"cascade": [Vector3(6.0, 0, 11.5), Vector3(-1, 0, 0)],
		"jardin": [Vector3(27.0, 0, 20.5), Vector3(0, 0, -1)],
		"ruelle": [Vector3(16.0, 0, 21.0), Vector3(0, 0, -1)],
		"chaumieres": [Vector3(9.5, 0, 28.8), Vector3(0, 0, -1)],
		"lavoir": [Vector3(8.0, 0, 30.2), Vector3(0, 0, -1)],
		"ruches": [Vector3(50.0, 0, 29.0), Vector3(1, 0, 0)],
		"sud": [Vector3(30.0, 0, 30.0), Vector3(0, 0, -1)],
		"chemin_est": [Vector3(48.0, 0, 28.8), Vector3(-1, 0, 0)],
		"ensemble": [Vector3(28.0, 0, 1.0), Vector3(0, 0, 1)],
	},
	"cafe":
	{
		"entree": [Vector3(4.75, 0, 8.2), Vector3(0, 0, -1)],
		"salle": [Vector3(4.75, 0, 6.8), Vector3(0, 0, -1)],
		"comptoir": [Vector3(4.0, 0, 4.2), Vector3(0, 0, -1)],
		"table_fees": [Vector3(7.4, 0, 5.6), Vector3(-1, 0, 0)],
		"buveurs": [Vector3(3.4, 0, 7.2), Vector3(0, 0, -1)],
		"arriere": [Vector3(9.75, 0, 3.6), Vector3(0, 0, -1)],
		"arriere_sud": [Vector3(9.75, 0, 7.0), Vector3(0, 0, -1)],
		"ensemble": [Vector3(6.0, 0, 0.4), Vector3(0, 0, 1)],
	},
	"maison_limashenka":
	{
		"entree": [Vector3(2.25, 0, 6.0), Vector3(0, 0, -1)],
		"vestibule": [Vector3(2.25, 0, 3.4), Vector3(0, 0, -1)],
		"salon": [Vector3(6.0, 0, 6.2), Vector3(0, 0, -1)],
		"horloge": [Vector3(6.2, 0, 3.6), Vector3(0, 0, -1)],
		"canape": [Vector3(6.0, 0, 6.25), Vector3(0, 0, -1)],
		"ensemble": [Vector3(5.0, 0, 0.4), Vector3(0, 0, 1)],
	},
}
const VIEWS: Array[String] = [
	"village:entree:apres_midi",
	"village:rue:apres_midi",
	"village:cafe:apres_midi",
	"village:belvedere:apres_midi",
	"village:jardin:apres_midi",
	"village:chaumieres:apres_midi",
	"village:cafe:nuit",
	"village:rue:nuit",
	"village:ensemble:apres_midi",
	"cafe:salle:apres_midi",
	"cafe:comptoir:apres_midi",
	"cafe:arriere:apres_midi",
	"cafe:salle:nuit",
	"maison_limashenka:salon:apres_midi",
	"maison_limashenka:horloge:apres_midi",
	"maison_limashenka:salon:nuit",
]
## Vue d'ensemble : caméra haute au sud de la carte (pas celle du jeu).
const OVERVIEW_FOV := 45.0
const OVERVIEW_PITCH := 52.0

var _game: Node3D
var _player: Player
var _state: Dictionary = {}
var _overview: Camera3D


func _ready() -> void:
	_state = GameState.to_dict()
	GameState.reset()
	WorldManager.fade_time = 0.0
	_game = GAME_SCENE.instantiate() as Node3D
	add_child(_game)
	_player = _game.get_node(^"Player") as Player
	if get_tree().current_scene == self:
		_run.call_deferred()


func _exit_tree() -> void:
	WorldManager.fade_time = WorldManager.DEFAULT_FADE_TIME
	Atmosphere.transition_time = Atmosphere.DEFAULT_TRANSITION_TIME
	GameState.from_dict.call_deferred(_state)


func _run() -> void:
	var out := OS.get_environment("C2_SHOTS")
	if out.is_empty():
		out = "res://build/shots/c2"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var frames := int(OS.get_environment("C2_FRAMES")) if OS.has_environment("C2_FRAMES") else 0
	if frames <= 0:
		frames = WAIT_FRAMES
	var views: Array[String] = []
	views.assign(VIEWS)
	if not OS.get_environment("C2_VIEWS").is_empty():
		views.assign(OS.get_environment("C2_VIEWS").split(",", false))
	for _wait in 4:
		await get_tree().process_frame
	var current := ""
	var load_ms := 0.0
	for view: String in views:
		var parts := view.split(":")
		if parts.size() < 3 or not SPOTS.has(parts[0]):
			continue
		if parts[0] != current:
			current = parts[0]
			var start := Time.get_ticks_usec()
			WorldManager.enter_map(StringName(current))
			load_ms = (Time.get_ticks_usec() - start) / 1000.0
			# La bannière du nom de la carte (HUD) passe avant la capture.
			await get_tree().create_timer(BANNER_WAIT).timeout
		var weather: StringName = StringName(parts[3]) if parts.size() > 3 else &"clair"
		Atmosphere.set_atmosphere(StringName(parts[2]), weather, 0.0)
		_stage(current, parts[1])
		for _frame in frames:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		var file := "%s/c2_%s_%s_%s.png" % [out, parts[0], parts[1], parts[2]]
		image.save_png(ProjectSettings.globalize_path(file))
		print(
			(
				"C2 vue %s : %d draw calls, %d primitives, %d objets, chargement %.0f ms"
				% [
					view,
					Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
					Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
					Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
					load_ms,
				]
			)
		)
		_end_overview()
	print("C2 fin : %d vues" % views.size())
	_game.queue_free()
	for _wait in 3:
		await get_tree().process_frame
	get_tree().quit(0)


func _stage(map_id: String, spot_name: String) -> void:
	var map := WorldManager.current_map_node()
	var spot: Array = SPOTS[map_id].get(spot_name, SPOTS[map_id].values()[0])
	var at: Vector3 = spot[0]
	var ground := map.get_node_or_null(^"Ground") as MapGround
	if ground != null:
		at.y = ground.height_at(at.x, at.z)
	_player.global_position = map.to_global(at) + Vector3.UP * 0.05
	_player.velocity = Vector3.ZERO
	_player.set_aim_direction(spot[1] as Vector3, true)
	_player.reset_physics_interpolation()
	var rig := _player.camera_rig
	rig.snap()
	var room := map.get_node_or_null(^"Ground") as InteriorRoom
	if room != null:
		room.snap_cut()
	if spot_name == "ensemble":
		var size := (map as Map).size
		_overview = Camera3D.new()
		_overview.fov = OVERVIEW_FOV
		_game.add_child(_overview)
		var target := map.to_global(Vector3(size.x / 2.0, 0.0, size.y / 2.0))
		var reach := maxf(size.x, size.y * 1.6) * 0.75
		var pitch := deg_to_rad(OVERVIEW_PITCH)
		_overview.global_position = target + Vector3(0.0, sin(pitch), cos(pitch)) * reach
		_overview.look_at(target, Vector3.UP)
		_overview.make_current()


func _end_overview() -> void:
	if _overview != null:
		_overview.queue_free()
		_overview = null
		_player.camera_rig.get_node(^"Camera3D").call(&"make_current")
