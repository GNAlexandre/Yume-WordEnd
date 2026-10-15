extends Node
## (E5) Démonstration de la faune : la vraie partie (game.tscn) dans la forêt d'essai (foret_essai),
## le joueur et sa caméra fixe, la lumière du moment. Une capture par vue, avec ses draw calls et
## le nombre d'animaux dans le champ. F6 dans l'éditeur ; sous Xvfb, par tools/e5_shots.sh (le
## rendu sans écran des tests est factice) :
##   E5_SHOTS=<dossier> : où écrire les captures (défaut build/shots/e5) ;
##   E5_VIEWS=<liste>   : vues séparées par des virgules (défaut : toutes, VIEWS).
## Vues :
##   cerfs     couchant : le joueur marche vers la clairière des trois cerfs, qui galopent ;
##   ecureuils matin : les écureuils (et les grenouilles de la mare) fuient le joueur qui court ;
##   meute     couchant : la clairière des loups ; la meute descend la rampe, encercle le joueur
##             et attaque un par un ;
##   sanglier  matin : le sanglier gratte le sol (la zone de sa charge se dessine) ;
##   ours      matin : l'ours se dresse avant de frapper (annonce de 0,8 s, zone au sol) ;
##   troupeau  couchant : seize animaux de plus autour du joueur, au moins douze dans le champ
##             (mesure des draw calls, budget 200).
## Une ligne par vue dans le journal : « E5 vue <nom> : <d> draw calls, <p> primitives, <a> animaux
## dans le champ, <s> animaux en tout », puis « E5 fin ».

const GAME_SCENE := preload("res://src/game.tscn")
const ANIMAL_SCENE := preload("res://src/fauna/animal.tscn")
const MAP := &"foret_essai"
const OTHER_MAP := &"essai"
## Vue → moment, temps, place du joueur, direction, touche de marche (vide : il reste là), durée de
## la marche (images), état attendu d'un animal (espèce:état, vide : durée fixe), images ensuite.
const VIEWS := {
	"cerfs":
	{
		"moment": &"couchant",
		"at": Vector3(25.0, 0.0, 22.5),
		"aim": Vector3(-1.0, 0.0, 0.0),
		"walk": &"move_left",
		"until": "deer:flee",
		"after": 12,
		"limit": 400,
	},
	"ecureuils":
	{
		"moment": &"matin",
		"at": Vector3(26.0, 0.0, 29.5),
		"aim": Vector3(1.0, 0.0, 0.0),
		"walk": &"move_right",
		"run": true,
		"until": "squirrel:flee",
		"after": 6,
		"limit": 400,
	},
	"meute":
	{
		"moment": &"couchant",
		"at": Vector3(28.5, 0.0, 17.0),
		"aim": Vector3(0.0, 0.0, -1.0),
		"until": "wolf:attack",
		"after": 40,
		"limit": 900,
	},
	"sanglier":
	{
		"moment": &"matin",
		"at": Vector3(37.8, 0.0, 24.5),
		"aim": Vector3(1.0, 0.0, 0.0),
		"until": "boar:windup",
		"after": 25,
		"limit": 600,
	},
	"ours":
	{
		"moment": &"matin",
		"at": Vector3(14.0, 0.0, 31.0),
		"aim": Vector3(-1.0, 0.0, 0.0),
		"until": "bear:windup",
		"after": 30,
		"limit": 1200,
	},
	"troupeau":
	{
		"moment": &"couchant",
		"at": Vector3(28.0, 0.0, 26.0),
		"aim": Vector3(0.0, 0.0, -1.0),
		"crowd": 16,
		"after": 6,
	},
}
const SETTLE_FRAMES := 8
## Espèces du troupeau de la vue « troupeau », posées dans le champ autour du joueur.
const CROWD: Array[StringName] = [
	&"deer",
	&"deer",
	&"fox",
	&"squirrel",
	&"boar",
	&"deer",
	&"wolf",
	&"fox",
	&"squirrel",
	&"frog",
	&"crow",
	&"wolf"
]

var _state: Dictionary = {}
var _game: Node3D
var _player: Player


func _ready() -> void:
	_state = GameState.to_dict()
	GameState.reset()
	_game = GAME_SCENE.instantiate() as Node3D
	add_child(_game)
	_player = _game.get_node(^"Player") as Player
	# Seulement lancée pour elle-même (F6, tools/e5_shots.sh) : la fumée l'instancie le temps de
	# deux images, sans captures ni quit().
	if get_tree().current_scene == self:
		_run.call_deferred()


func _exit_tree() -> void:
	Atmosphere.transition_time = Atmosphere.DEFAULT_TRANSITION_TIME
	GameState.from_dict.call_deferred(_state)


func _run() -> void:
	var out := OS.get_environment("E5_SHOTS")
	if out.is_empty():
		out = "res://build/shots/e5"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var views: Array[String] = []
	views.assign(VIEWS.keys())
	if not OS.get_environment("E5_VIEWS").is_empty():
		views.assign(OS.get_environment("E5_VIEWS").split(",", false))
	for _wait in 4:
		await get_tree().process_frame
	var failed := 0
	for view: String in views:
		if not VIEWS.has(view):
			continue
		var reached := await _shoot(view, out)
		failed += 0 if reached else 1
	print("E5 fin : %d vues, %d sans l'état attendu" % [views.size(), failed])
	_game.queue_free()
	for _wait in 3:
		await get_tree().process_frame
	get_tree().quit(1 if failed > 0 else 0)


## Une vue : la carte rechargée au moment voulu, le joueur posé, le scénario joué, la capture.
func _shoot(view: String, out: String) -> bool:
	var spec: Dictionary = VIEWS[view]
	Atmosphere.set_atmosphere(spec["moment"], &"clair", 0.0)
	if WorldManager.current_map() == MAP:
		WorldManager.enter_map(OTHER_MAP)
		await get_tree().process_frame
	var at: Vector3 = spec["at"]
	WorldManager.enter_map(MAP, &"Spawn", at)
	_player.global_position = WorldManager.ground_position(at + Vector3.UP * 0.2, _player)
	_player.velocity = Vector3.ZERO
	_player.set_aim_direction(spec["aim"] as Vector3, true)
	_player.reset_physics_interpolation()
	_player.camera_rig.snap()
	var health := _player.get_node(^"Health") as Health
	health.max_hp = 999
	health.reset()
	# Sans interface (cœurs, quête) : les captures montrent la forêt et ses bêtes.
	(_game.get_node(^"UI") as CanvasLayer).visible = false
	for _wait in SETTLE_FRAMES:
		await get_tree().process_frame
	if spec.has("crowd"):
		_add_crowd(int(spec["crowd"]))
	var walk := StringName(spec.get("walk", &""))
	if walk != &"":
		Input.action_press(walk)
		if bool(spec.get("run", false)):
			Input.action_press(&"run")
	var reached := true
	if spec.has("until"):
		reached = await _wait_for(String(spec["until"]), int(spec.get("limit", 600)))
	else:
		for _wait in int(spec.get("walk_frames", 0)):
			await get_tree().physics_frame
	for _wait in int(spec.get("after", 0)):
		await get_tree().physics_frame
	Input.action_release(walk)
	Input.action_release(&"run")
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var file := "%s/e5_%s.png" % [out, view]
	image.save_png(ProjectSettings.globalize_path(file))
	print(
		(
			"E5 vue %s : %d draw calls, %d primitives, %d animaux dans le champ, %d animaux en tout%s"
			% [
				view,
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
				Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
				_in_view(),
				get_tree().get_nodes_in_group(&"fauna").size(),
				"" if reached else " (état attendu jamais atteint)",
			]
		)
	)
	if OS.get_environment("E5_DEBUG") != "":
		for node: Node in get_tree().get_nodes_in_group(&"fauna"):
			var animal := node as Animal
			print(
				(
					"E5 bête %s %s %s (%.1f, %.1f) joueur (%.1f, %.1f)"
					% [
						animal.name,
						animal.state(),
						animal.mode_name(),
						animal.global_position.x,
						animal.global_position.z,
						_player.global_position.x,
						_player.global_position.z,
					]
				)
			)
	return reached


## Attend (limit images au plus) qu'un animal de l'espèce soit dans l'état voulu (« espèce:état »).
func _wait_for(condition: String, limit: int) -> bool:
	var parts := condition.split(":")
	for frame: int in limit:
		for node: Node in get_tree().get_nodes_in_group(&"fauna"):
			var animal := node as Animal
			if (
				animal != null
				and String(animal.species().id) == parts[0]
				and parts[1] in [String(animal.state()), String(animal.mode_name())]
			):
				if OS.get_environment("E5_DEBUG") != "":
					print(
						(
							"E5 déclenché à l'image %d : %s (%s) joueur %s vitesse %s"
							% [
								frame,
								animal.global_position,
								animal.name,
								_player.global_position,
								_player.velocity
							]
						)
					)
				return true
		await get_tree().physics_frame
	return false


## Des animaux de plus dans le champ, autour du joueur (la vue « troupeau »).
func _add_crowd(count: int) -> void:
	var map := WorldManager.current_map_node()
	var around := _player.global_position
	for i in count:
		var angle := TAU * i / count
		var radius := 4.0 + 2.5 * (i % 3)
		var spot := (
			around + Vector3(cos(angle) * radius * 1.4, 0.0, sin(angle) * radius * 0.7 - 3.0)
		)
		var animal := ANIMAL_SCENE.instantiate() as Animal
		animal.data = FaunaRules.species(&"ile_68", CROWD[i % CROWD.size()])
		animal.name = "troupeau_%d" % i
		animal.position = map.to_local(spot) + Vector3.UP * 0.3
		map.add_child(animal)


## Animaux du groupe « fauna » dans le champ de la caméra.
func _in_view() -> int:
	var camera := get_viewport().get_camera_3d()
	var count := 0
	for node: Node in get_tree().get_nodes_in_group(&"fauna"):
		var animal := node as Node3D
		if (
			camera != null
			and animal != null
			and camera.is_position_in_frustum(animal.global_position)
		):
			count += 1
	return count
