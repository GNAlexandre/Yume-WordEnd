extends Node
## (E9) Démo de la lumière et du temps : la vraie partie (game.tscn), vue par la caméra du joueur,
## sous chaque préréglage (moment × temps), dans le village de l'ancienne île et dans la carte
## d'essai (et au bord ouest de l'île, devant la mer de nuages) ; une capture par préréglage, avec sa luminance moyenne et ses draw calls. F6 dans
## l'éditeur. Lancée sous Xvfb par tools/e9_shots.sh (le rendu sans écran est factice) :
##   E9_SHOTS=<dossier> : où écrire les captures (défaut build/shots/e9) ;
##   E9_VIEWS=<liste>   : vues « carte:moment:temps » séparées par des virgules (défaut : toutes,
##                        VIEWS) ; lieu = village (l'entrepôt de l'ancienne île), bord (la côte
##                        ouest) ou essai ;
##   E9_FRAMES=<n>      : images attendues avant chaque capture (défaut WAIT_FRAMES).
## Une ligne par capture dans le journal : « E9 vue <nom> : luminance <l> (min LUMA_FLOOR), <d>
## draw calls, <p> primitives, lumière du joueur <a>, pluie <oui|non> », puis « E9 fin : <n>
## vues, <k> sous le seuil » ; le code de sortie est 1 si une vue est sous le seuil.

const GAME_SCENE := preload("res://src/game.tscn")
## Toutes les vues : chaque moment au clair, la pluie et l'averse au couchant et la nuit, sur
## les deux cartes ; plus le village à l'intérieur de rien (nuit sous l'averse).
const VIEWS: Array[String] = [
	"village:aube:clair",
	"village:matin:clair",
	"village:apres_midi:clair",
	"village:couchant:clair",
	"village:nuit:clair",
	"village:couchant:pluie",
	"village:matin:averse",
	"village:nuit:pluie",
	"village:nuit:averse",
	"essai:aube:clair",
	"essai:matin:clair",
	"essai:apres_midi:clair",
	"essai:couchant:clair",
	"essai:nuit:clair",
	"essai:couchant:pluie",
	"essai:nuit:averse",
	"bord:couchant:clair",
	"bord:nuit:clair",
]
## Où se tient le joueur dans le village (zone, position locale, direction) : la vue
## « village » de tests/integration/demo_hd2d.gd ; « bord » : la côte ouest du Couchant, la mer
## de nuages à gauche de l'écran.
const SPOTS := {
	"village": [&"village", Vector3(-5.0, 0.0, -2.5), Vector3(1.0, 0.0, 0.0)],
	"bord": [&"dunes", Vector3(-19.0, 0.0, -4.0), Vector3(0.0, 0.0, -1.0)],
}
const WAIT_FRAMES := 24
## Luminance moyenne (0..1, Rec. 709 sur les valeurs affichées) en deçà de laquelle une vue est
## jugée illisible.
const LUMA_FLOOR := 0.1

var _game: Node3D
var _player: Player
var _state: Dictionary = {}


func _ready() -> void:
	_state = GameState.to_dict()
	GameState.reset()
	_game = GAME_SCENE.instantiate() as Node3D
	add_child(_game)
	_player = _game.get_node(^"Player") as Player
	# Seulement lancée pour elle-même (F6, tools/e9_shots.sh) : la fumée l'instancie le temps de
	# deux images, sans captures ni quit().
	if get_tree().current_scene == self:
		_run.call_deferred()


func _exit_tree() -> void:
	Atmosphere.transition_time = Atmosphere.DEFAULT_TRANSITION_TIME
	GameState.from_dict.call_deferred(_state)


func _run() -> void:
	var out := OS.get_environment("E9_SHOTS")
	if out.is_empty():
		out = "res://build/shots/e9"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var frames := int(OS.get_environment("E9_FRAMES")) if OS.has_environment("E9_FRAMES") else 0
	if frames <= 0:
		frames = WAIT_FRAMES
	var views: Array[String] = []
	views.assign(VIEWS)
	if not OS.get_environment("E9_VIEWS").is_empty():
		views.assign(OS.get_environment("E9_VIEWS").split(",", false))
	var dark := 0
	var place := ""
	for _wait in 4:
		await get_tree().process_frame
	for view: String in views:
		var parts := view.split(":")
		if parts.size() != 3:
			continue
		if parts[0] != place:
			place = parts[0]
			await _stage(place)
		Atmosphere.set_atmosphere(StringName(parts[1]), StringName(parts[2]), 0.0)
		for _frame in frames:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		var luma := mean_luma(image)
		var file := "%s/e9_%s_%s_%s.png" % [out, parts[0], parts[1], parts[2]]
		image.save_png(ProjectSettings.globalize_path(file))
		if luma < LUMA_FLOOR:
			dark += 1
		print(
			(
				"E9 vue %s : luminance %.3f (min %.2f), %d draw calls, %d primitives, lumière du joueur %.2f, pluie %s"
				% [
					view,
					luma,
					LUMA_FLOOR,
					Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
					Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
					Atmosphere.player_light_amount() if Atmosphere.is_player_light_on() else 0.0,
					"oui" if Atmosphere.is_raining() else "non",
				]
			)
		)
	print("E9 fin : %d vues, %d sous le seuil" % [views.size(), dark])
	# Tout est libéré avant de quitter (sinon des ressources restent « en usage »).
	_game.queue_free()
	for _wait in 3:
		await get_tree().process_frame
	get_tree().quit(1 if dark > 0 else 0)


## Pose le joueur dans l'ancienne île (village, bord) ou au Spawn de la carte d'essai.
func _stage(place: String) -> void:
	if place == "essai":
		WorldManager.enter_map(&"essai")
	else:
		var spot: Array = SPOTS.get(place, SPOTS["village"])
		if WorldManager.current_map() != WorldManager.LEGACY_MAP:
			WorldManager.enter_map(WorldManager.LEGACY_MAP)
		var zone := _game.get_node(NodePath("World/ile_ancienne/Zones/%s" % spot[0])) as Node3D
		_player.global_position = WorldManager.ground_position(
			zone.to_global(spot[1] as Vector3), _player
		)
		_player.velocity = Vector3.ZERO
		_player.set_aim_direction(spot[2] as Vector3, true)
	for _wait in 6:
		await get_tree().process_frame


## Luminance moyenne d'une image (0..1), un pixel sur quatre dans chaque sens.
static func mean_luma(image: Image) -> float:
	var total := 0.0
	var count := 0
	for y in range(0, image.get_height(), 4):
		for x in range(0, image.get_width(), 4):
			var c := image.get_pixel(x, y)
			total += 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
			count += 1
	return total / maxf(count, 1.0)
