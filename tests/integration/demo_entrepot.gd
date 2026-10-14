extends Node
## (T2) Démo des cartes de l'entrepôt (rez-de-chaussée, étage, toit, salle des armes) : la vraie
## partie (game.tscn), posée par WorldManager.enter_map dans chaque carte, vue par la caméra du
## joueur (bornée à camera_bounds), sous la lumière d'Atmosphere (préréglage « interieur » dedans,
## moment du dehors sur le toit). F6 dans l'éditeur. Lancée sous Xvfb :
##   T2_SHOTS=<dossier>  : où écrire les captures (défaut build/shots/t2) ;
##   T2_VIEWS=<liste>    : vues « carte:lieu:moment » séparées par des virgules (défaut : VIEWS) ;
##                         lieu = une clé de SPOTS[carte], ou « ensemble » (vue d'ensemble : murs
##                         coupés au ras du sol, caméra haute qui embrasse l'étage) ;
##   T2_FRAMES=<n>       : images attendues avant chaque capture (défaut WAIT_FRAMES).
## Une ligne par capture : « T2 vue <nom> : <d> draw calls, <p> primitives, <o> objets,
## chargement <ms> ms », puis « T2 fin : <n> vues ».
## Lancement :
##   T2_SHOTS=res://build/shots/t2 LIBGL_ALWAYS_SOFTWARE=1 \
##     xvfb-run -a -s "-screen 0 1280x720x24" tools/godot --rendering-driver opengl3 \
##     --resolution 1280x720 res://tests/integration/demo_entrepot.tscn

const GAME_SCENE := preload("res://src/game.tscn")
const WAIT_FRAMES := 30
## Secondes d'attente à l'entrée d'une carte (bannière de son nom, src/ui/hud.gd).
const BANNER_WAIT := 4.0
## Où se tient le joueur (repère de la carte) et où il regarde, par carte et par lieu.
const SPOTS := {
	"entrepot_rdc":
	{
		"cuisine": [Vector3(3.3, 0, 6.6), Vector3(0, 0, -1)],
		"refectoire": [Vector3(11.0, 0, 5.55), Vector3(0, 0, -1)],
		"escalier": [Vector3(19.3, 0, 6.8), Vector3(0, 0, -1)],
		"armes": [Vector3(21.5, 0, 3.0), Vector3(0, 0, -1)],
		"archives": [Vector3(24.6, 0, 7.4), Vector3(0, 0, -1)],
		"lecture": [Vector3(29.0, 0, 6.2), Vector3(0, 0, -1)],
		"couloir": [Vector3(13.0, 0, 9.6), Vector3(1, 0, 0)],
		"bains": [Vector3(4.0, 0, 12.6), Vector3(-1, 0, 0)],
		"placard": [Vector3(10.0, 0, 12.4), Vector3(0, 0, 1)],
		"entree": [Vector3(13.0, 0, 12.8), Vector3(0, 0, -1)],
		"jeux": [Vector3(19.4, 0, 14.0), Vector3(0, 0, -1)],
		"infirmerie": [Vector3(27.5, 0, 12.6), Vector3(0, 0, -1)],
		"derriere_chaises": [Vector3(11.0, 0, 2.4), Vector3(0, 0, -1)],
		"derriere_lit": [Vector3(26.5, 0, 13.3), Vector3(0, 0, 1)],
		"ensemble": [Vector3(16.0, 0, 0.4), Vector3(0, 0, 1)],
	},
	"entrepot_etage":
	{
		"willem": [Vector3(2.8, 0, 4.0), Vector3(0, 0, -1)],
		"chtholly": [Vector3(6.6, 0, 5.4), Vector3(0, 0, -1)],
		"nygglatho": [Vector3(10.4, 0, 5.8), Vector3(0, 0, -1)],
		"grande_soeur": [Vector3(14.5, 0, 4.8), Vector3(0, 0, -1)],
		"tremie": [Vector3(19.4, 0, 3.0), Vector3(-1, 0, 0)],
		"ithea": [Vector3(22.0, 0, 6.6), Vector3(0, 0, -1)],
		"absentes": [Vector3(25.0, 0, 4.8), Vector3(0, 0, -1)],
		"nephren": [Vector3(29.4, 0, 6.6), Vector3(0, 0, -1)],
		"couloir": [Vector3(26.0, 0, 9.6), Vector3(1, 0, 0)],
		"dortoir_a": [Vector3(4.2, 0, 12.6), Vector3(0, 0, -1)],
		"dortoir_b": [Vector3(10.0, 0, 12.6), Vector3(0, 0, -1)],
		"dortoir_c": [Vector3(19.8, 0, 12.8), Vector3(0, 0, -1)],
		"dortoir_d": [Vector3(27.8, 0, 12.8), Vector3(0, 0, -1)],
		"ensemble": [Vector3(16.0, 0, 0.4), Vector3(0, 0, 1)],
	},
	"entrepot_toit":
	{
		"terrasse": [Vector3(12.2, 0, 9.1), Vector3(-1, 0, 0)],
		"balustrade": [Vector3(12.6, 0, 2.6), Vector3(0, 0, -1)],
		"sechoir": [Vector3(8.5, 0, 8.5), Vector3(0, 0, -1)],
		"bord_sud": [Vector3(11.0, 0, 13.2), Vector3(0, 0, 1)],
		"ensemble": [Vector3(8.0, 0, 8.0), Vector3(0, 0, -1)],
	},
	"salle_des_armes":
	{
		"crypte": [Vector3(7.2, 0, 4.5), Vector3(0, 0, -1)],
		"escalier": [Vector3(2.5, 0, 5.0), Vector3(0, 0, -1)],
		"tissu": [Vector3(11.0, 0, 6.5), Vector3(0, 0, -1)],
		"ensemble": [Vector3(7.0, 0, 0.4), Vector3(0, 0, 1)],
	},
}
const VIEWS: Array[String] = [
	"entrepot_rdc:cuisine:apres_midi",
	"entrepot_rdc:refectoire:apres_midi",
	"entrepot_rdc:escalier:apres_midi",
	"entrepot_rdc:armes:apres_midi",
	"entrepot_rdc:archives:apres_midi",
	"entrepot_rdc:lecture:apres_midi",
	"entrepot_rdc:couloir:apres_midi",
	"entrepot_rdc:bains:apres_midi",
	"entrepot_rdc:placard:apres_midi",
	"entrepot_rdc:entree:apres_midi",
	"entrepot_rdc:jeux:apres_midi",
	"entrepot_rdc:infirmerie:apres_midi",
	"entrepot_rdc:derriere_chaises:apres_midi",
	"entrepot_rdc:derriere_lit:apres_midi",
	"entrepot_rdc:refectoire:nuit",
	"entrepot_rdc:ensemble:apres_midi",
	"entrepot_etage:willem:apres_midi",
	"entrepot_etage:chtholly:apres_midi",
	"entrepot_etage:nygglatho:nuit",
	"entrepot_etage:grande_soeur:apres_midi",
	"entrepot_etage:tremie:apres_midi",
	"entrepot_etage:ithea:apres_midi",
	"entrepot_etage:absentes:apres_midi",
	"entrepot_etage:nephren:apres_midi",
	"entrepot_etage:couloir:apres_midi",
	"entrepot_etage:dortoir_a:apres_midi",
	"entrepot_etage:dortoir_b:apres_midi",
	"entrepot_etage:dortoir_c:apres_midi",
	"entrepot_etage:dortoir_d:apres_midi",
	"entrepot_etage:ensemble:apres_midi",
	"entrepot_toit:terrasse:apres_midi",
	"entrepot_toit:balustrade:apres_midi",
	"entrepot_toit:sechoir:apres_midi",
	"entrepot_toit:bord_sud:apres_midi",
	"entrepot_toit:balustrade:nuit",
	"entrepot_toit:ensemble:apres_midi",
	"salle_des_armes:crypte:apres_midi",
	"salle_des_armes:escalier:apres_midi",
	"salle_des_armes:tissu:apres_midi",
	"salle_des_armes:ensemble:apres_midi",
]
## Vue d'ensemble : caméra haute au sud de la carte, qui embrasse l'étage (pas celle du jeu).
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
	var out := OS.get_environment("T2_SHOTS")
	if out.is_empty():
		out = "res://build/shots/t2"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var frames := int(OS.get_environment("T2_FRAMES")) if OS.has_environment("T2_FRAMES") else 0
	if frames <= 0:
		frames = WAIT_FRAMES
	var views: Array[String] = []
	views.assign(VIEWS)
	if not OS.get_environment("T2_VIEWS").is_empty():
		views.assign(OS.get_environment("T2_VIEWS").split(",", false))
	for _wait in 4:
		await get_tree().process_frame
	var current := ""
	var load_ms := 0.0
	for view: String in views:
		var parts := view.split(":")
		if parts.size() != 3 or not SPOTS.has(parts[0]):
			continue
		if parts[0] != current:
			current = parts[0]
			var start := Time.get_ticks_usec()
			WorldManager.enter_map(StringName(current))
			load_ms = (Time.get_ticks_usec() - start) / 1000.0
			# La bannière du nom de la carte (HUD, zone_time puis fondu) passe avant la capture.
			await get_tree().create_timer(BANNER_WAIT).timeout
		Atmosphere.set_atmosphere(StringName(parts[2]), &"clair", 0.0)
		_stage(current, parts[1])
		for _frame in frames:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		var file := "%s/t2_%s_%s_%s.png" % [out, parts[0], parts[1], parts[2]]
		image.save_png(ProjectSettings.globalize_path(file))
		print(
			(
				"T2 vue %s : %d draw calls, %d primitives, %d objets, chargement %.0f ms"
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
	print("T2 fin : %d vues" % views.size())
	_game.queue_free()
	for _wait in 3:
		await get_tree().process_frame
	get_tree().quit(0)


func _stage(map_id: String, spot_name: String) -> void:
	var map := WorldManager.current_map_node()
	var spot: Array = SPOTS[map_id].get(spot_name, SPOTS[map_id].values()[0])
	_player.global_position = map.to_global(spot[0] as Vector3) + Vector3.UP * 0.05
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
