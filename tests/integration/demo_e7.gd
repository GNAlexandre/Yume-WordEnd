extends Node
## (E7) Démonstration des navires dans la vraie partie (game.tscn, caméra du joueur, lumière
## d'Atmosphere, post-traitement), sous Xvfb (tools/e7_shots.sh) : la descente du transport de la
## Garde au port, une image toutes les 0,5 s de jeu (le poste d'amarrage avancé pas à pas), la
## trappe, la passerelle, le départ ; le pont du transport, l'intérieur du Barocupot, et l'ombre du
## Barocupot qui passe dans les nuages de la colline.
##   E7_SHOTS=<dossier> : où écrire les captures (défaut res://build/e7/shots) ;
##   E7_SELECT=<liste>  : séries à faire (descente, depart, cartes, ombre), séparées par des
##                        virgules.
## Une ligne par capture : « E7 vue <nom> : <d> draw calls, <p> primitives » ; puis « E7 fin ».

const GAME_SCENE := preload("res://src/game.tscn")
const SHIP := &"transport_garde"
const STEP := 0.5
const WAIT_FRAMES := 8

var _game: Node3D
var _player: Player
var _state: Dictionary = {}
var _out := "res://build/e7/shots"
var _heavy := 0


func _ready() -> void:
	_state = GameState.to_dict()
	GameState.reset()
	WorldManager.fade_time = 0.0
	_game = GAME_SCENE.instantiate() as Node3D
	add_child(_game)
	_player = _game.get_node(^"Player") as Player
	# Seulement lancée pour elle-même (tools/e7_shots.sh) : la fumée l'instancie le temps de deux
	# images, sans captures ni quit().
	if get_tree().current_scene == self:
		_run.call_deferred()


func _exit_tree() -> void:
	WorldManager.fade_time = WorldManager.DEFAULT_FADE_TIME
	Atmosphere.transition_time = Atmosphere.DEFAULT_TRANSITION_TIME
	GameState.from_dict.call_deferred(_state)


func _run() -> void:
	if OS.has_environment("E7_SHOTS"):
		_out = OS.get_environment("E7_SHOTS")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
	var select := OS.get_environment("E7_SELECT").split(",", false)
	for _wait in 4:
		await get_tree().process_frame
	if select.is_empty() or select.has("descente"):
		await _descent()
	if select.is_empty() or select.has("depart"):
		await _departure()
	if select.is_empty() or select.has("cartes"):
		await _maps()
	if select.is_empty() or select.has("ombre"):
		await _shadow()
	print("E7 fin : %d vues au-delà de 200 draw calls" % _heavy)
	_game.queue_free()
	for _wait in 3:
		await get_tree().process_frame
	get_tree().quit(0)


## Pose le joueur en (x, z) de la carte, regard look, caméra posée.
func _stand(x: float, z: float, look: Vector3 = Vector3.FORWARD) -> void:
	var map := WorldManager.current_map_node()
	var at := Vector3(x, 0.0, z)
	var ground := map.get_node_or_null(^"Ground") as MapGround
	if ground != null:
		at.y = ground.height_at(x, z)
	_player.global_position = map.to_global(at) + Vector3.UP * 0.05
	_player.velocity = Vector3.ZERO
	_player.set_aim_direction(look, true)
	_player.reset_physics_interpolation()
	_player.camera_rig.snap()


func _enter(map_id: StringName, moment: StringName, weather: StringName = &"clair") -> void:
	WorldManager.enter_map(map_id)
	for _wait in 30:
		await get_tree().process_frame
	Atmosphere.set_atmosphere(moment, weather, 0.0)


func _shot(label: String, frames: int = WAIT_FRAMES) -> void:
	for _frame in frames:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path("%s/%s.png" % [_out, label]))
	var calls := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var primitives := int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	_heavy += 1 if calls > 200 else 0
	print("E7 vue %s : %d draw calls, %d primitives" % [label, calls, primitives])


## La descente au crépuscule sous la pluie fine (7.4), une image toutes les 0,5 s de jeu, puis
## la trappe et la passerelle ; et trois images au matin, pour juger le navire en pleine lumière.
func _descent() -> void:
	await _enter(&"port", &"couchant", &"pluie")
	_stand(30.0, 12.0)
	ShipControl.pose(SHIP, &"absent")
	await _shot("port_vide_couchant")
	var berth := ShipControl.berth(SHIP)
	berth.set_physics_process(false)
	await ShipControl.play(SHIP, &"descend", false)
	var k := 0
	while berth.is_busy():
		await _shot("descente_%02d" % k, 4)
		berth.advance(STEP)
		k += 1
	await _shot("descente_%02d_amarre" % k)
	await ShipControl.play(SHIP, &"open_hatch", false)
	berth.advance(0.4 + 1.0 / 8.0)
	await _shot("trappe_1")
	berth.advance(5.0)
	await _shot("trappe_ouverte")
	await ShipControl.play(SHIP, &"deploy_gangway", false)
	berth.advance(0.6)
	await _shot("passerelle_sort")
	berth.advance(5.0)
	await _shot("passerelle_posee")
	_stand(32.5, 7.6)
	await _shot("passerelle_pied")
	Atmosphere.set_atmosphere(&"matin", &"clair", 0.0)
	_stand(30.0, 12.0)
	await _shot("navire_matin")
	_stand(26.0, 9.0)
	await _shot("navire_matin_ouest")
	Atmosphere.set_atmosphere(&"nuit", &"clair", 0.0)
	_stand(30.0, 12.0)
	await _shot("navire_nuit")
	berth.set_physics_process(true)


## Le départ, une image par seconde de jeu.
func _departure() -> void:
	await _enter(&"port", &"couchant")
	_stand(30.0, 12.0)
	ShipControl.pose(SHIP, &"deploy_gangway")
	var berth := ShipControl.berth(SHIP)
	berth.set_physics_process(false)
	await ShipControl.play(SHIP, &"depart", false)
	var k := 0
	while berth.is_busy():
		await _shot("depart_%02d" % k, 4)
		berth.advance(1.0)
		k += 1
	await _shot("depart_%02d_parti" % k)
	berth.set_physics_process(true)


## Le pont du transport et l'intérieur du Barocupot.
func _maps() -> void:
	await _enter(&"transport_garde", &"matin")
	_stand(10.0, 4.4)
	await _shot("pont_matin")
	_stand(10.0, 8.6)
	await _shot("pont_passerelle_matin")
	_stand(16.5, 4.4, Vector3.RIGHT)
	await _shot("pont_proue_matin")
	Atmosphere.set_atmosphere(&"couchant", &"pluie", 0.0)
	_stand(10.0, 4.4)
	await _shot("pont_couchant_pluie")
	await _enter(&"barocupot", &"apres_midi")
	_stand(4.5, 6.0)
	await _shot("barocupot_coursive")
	_stand(2.6, 3.9, Vector3.RIGHT)
	await _shot("barocupot_conseil")
	_stand(10.5, 3.5)
	await _shot("barocupot_sas")


## L'ombre du Barocupot passe dans les nuages, vue du bord de la colline (8.6).
func _shadow() -> void:
	await _enter(&"colline", &"apres_midi")
	var map := WorldManager.current_map_node()
	var edge := map.get_node_or_null(^"Life/Places/vue_nord") as Node3D
	var at := map.to_local(edge.global_position) if edge != null else Vector3(30.0, 0.0, 8.0)
	_stand(at.x, at.z)
	var shadow := await ShipControl.pass_shadow(&"barocupot", false)
	shadow.set_physics_process(false)
	for k in 5:
		shadow.advance(7.0 / 6.0)
		await _shot("ombre_%d" % k)
	shadow.advance(100.0)
