extends Node3D
## Démo de l'intégration M1 : la vraie partie (src/game.tscn : île, joueur, interface), le
## joueur posé devant le panneau de l'arène des dunes. Jouable dans l'éditeur (F6) : ZQSD /
## WASD ou flèches, Maj pour courir, E devant le panneau pour lancer les vagues, J l'épée (trois
## coups enchaînés), K maintenu puis relâché pour l'onde, clic molette pour verrouiller.
##
## Captures : M1_SHOT=<vue> tools/screenshot.sh res://tests/integration/demo_m1.tscn <png> 300
##   dunes  : Chtholly en plein coup d'épée au milieu de Timeres des quatre types ;
##   wave   : l'onde en vol entre des Timeres alignés ;
##   forest : la clairière de la forêt et ses quatre Timeres ;
##   perf   : 12 Timeres devant le joueur dans l'arène (banc de src/test_shortcuts.gd) ;
##   village: la vue de départ au village (budget de draw calls).
## La scène se fige (get_tree().paused) au moment choisi ; draw calls, primitives et images/s
## de l'image figée sont écrits dans le journal (« M1 vue … »).

const TestShortcuts := preload("res://src/test_shortcuts.gd")
## Devant le panneau « Affronter les Timeres » (local à la zone des dunes).
const PANEL_FRONT := Vector3(10.6, 0.0, -2.0)
## Images rendues entre le gel et la mesure.
const MEASURE_DELAY := 4

var _shot := ""
var _time := 0.0
var _step := 0
var _frozen_frames := -1
var _actors: Array[Enemy] = []
var _wave: ChargeWave

@onready var _game: Node3D = $Game
@onready var _player: Player = $Game/Player


func _ready() -> void:
	_shot = OS.get_environment("M1_SHOT")
	_player.combat.wave_launched.connect(func(wave: Node3D) -> void: _wave = wave as ChargeWave)
	match _shot:
		"dunes":
			_stage_duel()
		"wave":
			_stage_wave()
		"forest":
			_place(&"forest", Vector3(0.0, 0.0, 10.5), Vector3.FORWARD)
			_player.camera_rig.rotate_view(0.0, deg_to_rad(-10.0))
		"perf":
			# Les 12 Timeres du banc devant le joueur, tous dans le champ de la caméra.
			_place(&"dunes", Vector3(0.0, 0.0, 6.0), Vector3.FORWARD)
			_player.camera_rig.zoom(4.0)
			TestShortcuts.spawn_bench(_game, _player.global_position + Vector3(0, 0, -6.5), 12)
		"village":
			pass
		_:
			_place(&"dunes", PANEL_FRONT, Vector3.LEFT)
	if not _shot.is_empty():
		RenderingServer.frame_post_draw.connect(_on_frame_post_draw)


func _exit_tree() -> void:
	if _frozen_frames >= 0:
		get_tree().paused = false


func _physics_process(delta: float) -> void:
	if _shot.is_empty() or _frozen_frames >= 0:
		return
	_time += delta
	match _shot:
		"dunes":
			# Un coup d'épée part à 0,2 s ; gel sur sa 3e image (_on_player_frame_changed).
			if _step == 0 and _time >= 0.2:
				_player.visual.frame_changed.connect(_on_player_frame_changed)
				_player.combat.attack()
				_step = 1
		"wave":
			# Charge maintenue 0,65 s, relâchée ; gel quand l'onde a fait 3 m.
			if _step == 0 and _time >= 0.2:
				_player.combat.charge_begin()
				_step = 1
			elif _step == 1 and _time >= 0.85:
				_player.combat.charge_release()
				_step = 2
			elif _step == 2 and is_instance_valid(_wave) and _wave.traveled() >= 3.0:
				_freeze()
		"forest":
			if _time >= 0.6:
				_freeze()
		_:
			if _time >= 1.0:
				_freeze()


## Joueur au point local `local_position` de la zone, visée `aim`, caméra derrière lui.
func _place(zone_id: StringName, local_position: Vector3, aim: Vector3) -> void:
	var zone := _game.get_node(NodePath("Island/Zones/%s" % zone_id)) as Node3D
	_player.global_position = WorldManager.ground_position(zone.to_global(local_position), _player)
	_player.velocity = Vector3.ZERO
	_player.set_aim_direction(aim, true)


## Timere immobile (IA arrêtée, il garde sa pose) en `offset` du joueur, tourné vers lui.
func _actor(enemy_id: StringName, offset: Vector3) -> Enemy:
	var enemy := TestShortcuts.ENEMY_SCENE.instantiate() as Enemy
	enemy.data = load("res://data/enemies/%s.tres" % enemy_id) as EnemyData
	enemy.drops_enabled = false
	enemy.position = _game.to_local(_player.global_position + offset)
	_game.add_child(enemy)
	enemy.set_physics_process(false)
	enemy.visual.set_facing(-offset)
	_actors.append(enemy)
	return enemy


## Combat dans l'arène : un Normal sous l'épée, un Petit qui mord, un Grand qui fouette, un
## Coureur qui arrive.
func _stage_duel() -> void:
	_place(&"dunes", Vector3(-1.0, 0.0, 3.0), Vector3.FORWARD)
	_player.camera_rig.zoom(-1.5)
	_actor(&"timere_normal", Vector3(0.75, 0.0, -0.85))
	_actor(&"timere_small", Vector3(-1.35, 0.0, -0.55)).visual.show_frame(&"morsure", 1)
	_actor(&"timere_big", Vector3(1.75, 0.0, -1.9)).visual.show_frame(&"fouet", 2)
	_actor(&"timere_runner", Vector3(-2.9, 0.0, -3.4)).visual.play(&"course")
	_actor(&"timere_small", Vector3(3.6, 0.0, -4.6)).visual.play(&"marche")


## L'onde : trois Timeres alignés vers le couchant (ouest), le joueur charge puis relâche.
func _stage_wave() -> void:
	_place(&"dunes", Vector3(6.0, 0.0, 1.5), Vector3.LEFT)
	_player.camera_rig.rotate_view(deg_to_rad(-35.0), 0.0)
	_player.camera_rig.zoom(-1.0)
	_actor(&"timere_small", Vector3(-2.4, 0.0, 0.55))
	_actor(&"timere_normal", Vector3(-4.4, 0.0, -0.65)).visual.play(&"marche")
	_actor(&"timere_big", Vector3(-6.6, 0.0, 0.7)).visual.play(&"marche")


func _on_player_frame_changed(anim: StringName, frame: int) -> void:
	if anim == &"attaque" and frame == 2 and _frozen_frames < 0:
		_freeze()


func _freeze() -> void:
	_frozen_frames = 0
	get_tree().paused = true


func _on_frame_post_draw() -> void:
	if _frozen_frames < 0:
		return
	_frozen_frames += 1
	if _frozen_frames == MEASURE_DELAY:
		print(
			(
				"M1 vue %s : %d draw calls, %d primitives, %d i/s, %d Timeres"
				% [
					_shot,
					Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
					Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
					Performance.get_monitor(Performance.TIME_FPS),
					get_tree().get_nodes_in_group(&"enemies").size(),
				]
			)
		)
