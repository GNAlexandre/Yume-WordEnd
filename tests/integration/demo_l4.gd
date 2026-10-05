extends Node3D
## Démo du Lot 4 : le joueur (src/player/player.tscn) et trois mannequins (dummy.tscn + visuel de
## Timere, PV affichés) alignés devant lui (-Z). Jouable dans l'éditeur (F6) : ZQSD/WASD, J pour
## l'épée (trois coups enchaînés), K maintenu puis relâché pour l'onde. Un mannequin mort se
## relève après dummy_respawn secondes.
## Capture (capture = true, forcé sous tools/screenshot.gd) : ShotCamera cadre la scène, le joueur
## charge puis lance l'onde par script, l'arbre se fige quand l'onde traverse le 2e mannequin :
##   tools/screenshot.sh res://tests/integration/demo_l4.tscn build/shots/l4.png 400

@export var capture: bool = false
@export var dummy_hp: int = 6
@export var dummy_respawn: float = 1.5
## Capture : cadrage de ShotCamera et distance de l'onde (m) quand l'image se fige.
@export var shot_position: Vector3 = Vector3(5.2, 2.4, 1.6)
@export var shot_target: Vector3 = Vector3(0, 0.7, -3.4)
@export var freeze_at: float = 4.3

var _healths: Array[Health] = []
var _labels: Array[Label3D] = []
var _dead_for: Array[float] = []
var _player_hp: String = ""
var _charge: float = 0.0
var _step: int = 0
var _step_time: float = 0.0
var _wave: ChargeWave

@onready var _combat: PlayerCombat = $Player/Combat
@onready var _status: Label = $UI/Status


func _ready() -> void:
	for dummy: Node3D in [$Dummy1, $Dummy2, $Dummy3]:
		var health := dummy.get_node(^"Health") as Health
		health.max_hp = dummy_hp
		var label := Label3D.new()
		label.position = Vector3(0, 1.45, 0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 40
		label.outline_size = 10
		label.pixel_size = 0.006
		dummy.add_child(label)
		_healths.append(health)
		_labels.append(label)
		_dead_for.append(0.0)
		health.changed.connect(_on_dummy_changed.bind(_labels.size() - 1))
		_on_dummy_changed(health.current, health.max_hp, _labels.size() - 1)
	EventBus.player_health_changed.connect(_on_player_health_changed)
	EventBus.charge_progress.connect(_on_charge_progress)
	_combat.wave_launched.connect(func(wave: Node3D) -> void: _wave = wave as ChargeWave)
	var loop_script := get_tree().get_script() as Script
	capture = (
		capture or (loop_script != null and loop_script.resource_path.ends_with("screenshot.gd"))
	)


func _exit_tree() -> void:
	if _step == 3:
		get_tree().paused = false


func _physics_process(delta: float) -> void:
	for i in _healths.size():
		_dead_for[i] = _dead_for[i] + delta if _healths[i].is_dead() else 0.0
		if _dead_for[i] >= dummy_respawn:
			_healths[i].reset()
	if capture:
		_run_capture(delta)


## Capture : cadrage, charge maintenue 0,65 s, relâche, pause quand l'onde est à freeze_at m.
func _run_capture(delta: float) -> void:
	_step_time += delta
	if _step == 0 and _step_time >= 0.2:
		var camera := $ShotCamera as Camera3D
		camera.look_at_from_position(shot_position, shot_target)
		camera.make_current()
		for dummy: Node3D in [$Dummy1, $Dummy2, $Dummy3]:
			(dummy.get_node(^"Visual") as CharacterVisual).set_facing(Vector3.BACK)
		_combat.charge_begin()
		_step = 1
		_step_time = 0.0
	elif _step == 1 and _step_time >= 0.65:
		_combat.charge_release()
		_step = 2
	elif _step == 2 and is_instance_valid(_wave) and _wave.traveled() >= freeze_at:
		_step = 3
		get_tree().paused = true


func _show_status() -> void:
	_status.text = "Chtholly : %s PV   ·   charge : %d %%" % [_player_hp, roundi(_charge * 100.0)]


func _on_dummy_changed(current: int, max_value: int, index: int) -> void:
	_labels[index].text = "PV %d/%d" % [current, max_value]
	_labels[index].modulate = Color(1, 0.45, 0.4) if current < max_value else Color.WHITE


func _on_player_health_changed(current: int, max_value: int) -> void:
	_player_hp = "%d/%d" % [current, max_value]
	_show_status()


func _on_charge_progress(ratio: float) -> void:
	_charge = ratio
	_show_status()
