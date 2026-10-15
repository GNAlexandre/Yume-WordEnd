extends Node
## (QC) La série standard de vues du garant de la qualité visuelle (docs/QUALITE.md) : la vraie
## partie (game.tscn), posée par WorldManager.enter_map dans chaque carte de l'île, vue par la
## caméra du joueur (bornée à camera_bounds, post-traitement compris) sous la lumière
## d'Atmosphere, ou par une caméra haute pour les vues d'ensemble. La liste des vues est une
## donnée : tools/qc_views.json (carte → vues : at, look, moments). Lancée sous Xvfb par
## tools/qc_shots.sh (le rendu sans écran est factice) :
##   QC_SHOTS=<dossier>  : où écrire les captures (défaut res://build/qc/dernier) ;
##   QC_SELECT=<liste>   : « carte », « carte:vue » ou « carte:vue:moment[:temps] », séparés par
##                         des virgules (défaut : toutes les vues) ;
##   QC_FRAMES=<n>       : images attendues avant chaque capture (défaut WAIT_FRAMES).
## Une ligne par capture : « QC vue <carte>:<vue>:<moment>:<temps> : <d> draw calls, <p>
## primitives, <o> objets, luminance <l>, centre <c>, personnages <n> », plus une ligne dans
## <dossier>/index.tsv (planches contact : tools/qc_tool.py contact) ; puis « QC fin : <n> vues,
## <k> au-delà de 200 draw calls, <s> sous le seuil de luminance ».

const GAME_SCENE := preload("res://src/game.tscn")
const VIEWS_PATH := "res://tools/qc_views.json"
const WAIT_FRAMES := 30
const DRAW_CALL_BUDGET := 200
## Luminance moyenne sous laquelle une vue est jugée illisible (comme tests/integration/demo_e9.gd).
const LUMA_FLOOR := 0.1
## Vue d'ensemble : caméra haute au sud de la carte (pas celle du jeu).
const OVERVIEW_FOV := 45.0
const OVERVIEW_PITCH := 52.0
const LOOKS := {
	"N": Vector3(0, 0, -1),
	"S": Vector3(0, 0, 1),
	"E": Vector3(1, 0, 0),
	"O": Vector3(-1, 0, 0),
}
const INDEX_HEADER := "map\tview\tmoment\tweather\tfile\tdraw_calls\tprimitives\tluma\tcenter"

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
	# Seulement lancée pour elle-même (tools/qc_shots.sh) : la fumée l'instancie le temps de
	# deux images, sans captures ni quit().
	if get_tree().current_scene == self:
		_run.call_deferred()


func _exit_tree() -> void:
	WorldManager.fade_time = WorldManager.DEFAULT_FADE_TIME
	Atmosphere.transition_time = Atmosphere.DEFAULT_TRANSITION_TIME
	GameState.from_dict.call_deferred(_state)


## Les captures à faire, dans l'ordre : [carte, vue (Dictionary), moment, temps].
static func plan(data: Dictionary, select: PackedStringArray) -> Array[Array]:
	var shots: Array[Array] = []
	var defaults: Dictionary = data.get("defaults", {})
	var maps: Dictionary = data.get("maps", {})
	for map_id: String in maps:
		var entry: Dictionary = maps[map_id]
		for view: Dictionary in entry.get("views", []):
			var moments: Array = view.get("moments", [])
			if moments.is_empty():
				if view.get("overview", false):
					moments = defaults.get("overview_moments", ["apres_midi"])
				elif entry.get("kind", "") == "dedans":
					moments = defaults.get("interior_moments", ["matin", "nuit"])
				else:
					moments = defaults.get("moments", ["matin"])
			for spec: String in moments:
				var parts := spec.split(":")
				var moment := parts[0]
				var weather := parts[1] if parts.size() > 1 else "clair"
				if _selected(select, [map_id, String(view["name"]), moment, weather]):
					shots.append([map_id, view, moment, weather])
	return shots


static func _selected(select: PackedStringArray, keys: Array) -> bool:
	if select.is_empty():
		return true
	for item: String in select:
		var parts := item.split(":")
		var ok := true
		for i in parts.size():
			if i < keys.size() and parts[i] != String(keys[i]):
				ok = false
		if ok:
			return true
	return false


func _run() -> void:
	var out := OS.get_environment("QC_SHOTS")
	if out.is_empty():
		out = "res://build/qc/dernier"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var frames := int(OS.get_environment("QC_FRAMES")) if OS.has_environment("QC_FRAMES") else 0
	if frames <= 0:
		frames = WAIT_FRAMES
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(VIEWS_PATH))
	var select := OS.get_environment("QC_SELECT").split(",", false)
	var shots := plan(data, select)
	var index_path := ProjectSettings.globalize_path(out + "/index.tsv")
	var fresh := not FileAccess.file_exists(index_path)
	var index := FileAccess.open(
		index_path, FileAccess.READ_WRITE if not fresh else FileAccess.WRITE
	)
	index.seek_end()
	if fresh:
		index.store_line(INDEX_HEADER)
	for _wait in 4:
		await get_tree().process_frame
	var current := ""
	var heavy := 0
	var dark := 0
	for shot: Array in shots:
		var map_id: String = shot[0]
		var view: Dictionary = shot[1]
		if map_id != current:
			current = map_id
			WorldManager.enter_map(StringName(map_id))
			await _wait_banner()
		Atmosphere.set_atmosphere(StringName(shot[2]), StringName(shot[3]), 0.0)
		_stage(view)
		for _frame in frames:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		var luma := mean_luma(image)
		var third := Vector2i(floori(image.get_width() / 3.0), floori(image.get_height() / 3.0))
		var middle := mean_luma(image, Rect2i(third, third))
		var base := "%s_%s_%s" % [map_id, view["name"], shot[2]]
		if shot[3] != "clair":
			base += "_" + String(shot[3])
		image.save_png(ProjectSettings.globalize_path("%s/%s.png" % [out, base]))
		var calls := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		var primitives := int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
		var objects := int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
		heavy += 1 if calls > DRAW_CALL_BUDGET else 0
		dark += 1 if luma < LUMA_FLOOR else 0
		(
			index
			. store_line(
				(
					"\t"
					. join(
						[
							map_id,
							view["name"],
							shot[2],
							shot[3],
							base + ".png",
							str(calls),
							str(primitives),
							"%.3f" % luma,
							"%.3f" % middle,
						]
					)
				)
			)
		)
		index.flush()
		print(
			(
				(
					"QC vue %s:%s:%s:%s : %d draw calls, %d primitives, %d objets, luminance %.3f, "
					+ "centre %.3f, personnages %d"
				)
				% [
					map_id,
					view["name"],
					shot[2],
					shot[3],
					calls,
					primitives,
					objects,
					luma,
					middle,
					_characters(),
				]
			)
		)
		_end_overview()
	index.close()
	print(
		(
			"QC fin : %d vues, %d au-delà de %d draw calls, %d sous le seuil de luminance"
			% [shots.size(), heavy, DRAW_CALL_BUDGET, dark]
		)
	)
	_game.queue_free()
	for _wait in 3:
		await get_tree().process_frame
	get_tree().quit(0)


## Attend que le nom de la carte (UI/MapFade) se soit effacé.
func _wait_banner() -> void:
	for _wait in 6:
		await get_tree().process_frame
	var fade := _game.get_node_or_null(^"UI/MapFade")
	for _wait in 600:
		if fade == null or String(fade.call(&"title_text")).is_empty():
			break
		await get_tree().process_frame


func _stage(view: Dictionary) -> void:
	var map := WorldManager.current_map_node()
	if view.get("overview", false):
		_stage_overview(map)
		return
	var at_xz: Array = view["at"]
	var at := Vector3(float(at_xz[0]), 0.0, float(at_xz[1]))
	var ground := map.get_node_or_null(^"Ground") as MapGround
	if ground != null:
		at.y = ground.height_at(at.x, at.z)
	_player.global_position = map.to_global(at) + Vector3.UP * 0.05
	_player.velocity = Vector3.ZERO
	_player.set_aim_direction(LOOKS.get(String(view.get("look", "N")), Vector3.FORWARD), true)
	_player.reset_physics_interpolation()
	_player.camera_rig.snap()
	var room := map.get_node_or_null(^"Ground") as InteriorRoom
	if room != null:
		room.snap_cut()


func _stage_overview(map: Node3D) -> void:
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


## Personnages et animaux visibles de la carte (nœuds CharacterVisual affichés sous Life).
func _characters() -> int:
	var life := WorldManager.current_map_node().get_node_or_null(^"Life")
	if life == null:
		return 0
	var count := 0
	for node: Node in life.find_children("*", "Node3D", true, false):
		if node is CharacterVisual and (node as Node3D).is_visible_in_tree():
			count += 1
	return count


## Luminance moyenne d'une image (0..1), ou de sa région rect, un pixel sur quatre dans chaque
## sens (comme tests/integration/demo_e9.gd).
static func mean_luma(image: Image, rect: Rect2i = Rect2i()) -> float:
	if not rect.has_area():
		rect = Rect2i(Vector2i.ZERO, image.get_size())
	var total := 0.0
	var count := 0
	for y in range(rect.position.y, rect.end.y, 4):
		for x in range(rect.position.x, rect.end.x, 4):
			var c := image.get_pixel(x, y)
			total += 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
			count += 1
	return total / maxf(count, 1.0)
