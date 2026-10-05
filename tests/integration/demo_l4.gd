extends Node3D
## Démo du Lot 4 (tests/integration/demo_l4.tscn) : le joueur (src/player/player.tscn) et trois
## mannequins (tests/stubs/dummy.tscn + visuel de Timere) alignés devant lui (-Z). Jouable dans
## l'éditeur (F6) : ZQSD/WASD pour bouger, J pour l'épée (trois coups enchaînés), K maintenu
## puis relâché pour l'onde. Un mannequin mort se relève après dummy_respawn secondes.
##
## Capture (capture = true, ou automatiquement sous tools/screenshot.gd) : la caméra ShotCamera
## cadre la scène, le joueur charge puis lance l'onde par script, et l'arbre est mis en pause
## quand l'onde traverse le 2e mannequin :
##   tools/screenshot.sh res://tests/integration/demo_l4.tscn build/shots/l4.png 400

## Lance l'onde par script et fige l'image (forcé quand la scène tourne sous screenshot.gd).
@export var capture: bool = false
## PV des mannequins (l'onde en retire 3, l'épée 1).
@export var dummy_hp: int = 6
## Délai (s) avant qu'un mannequin mort ne se relève.
@export var dummy_respawn: float = 1.5
## Capture : position et cible de ShotCamera.
@export var shot_position: Vector3 = Vector3(5.2, 2.4, 1.6)
@export var shot_target: Vector3 = Vector3(0, 0.7, -3.4)
## Capture : distance parcourue par l'onde (m) quand l'image est figée.
@export var freeze_at: float = 4.3

var _dummies: Array[Node3D] = []
var _labels: Array[Label3D] = []
var _dead_for: Array[float] = []
var _hp_text: String = ""
var _charge_text: String = ""
var _capture_step: int = 0
var _capture_time: float = 0.0
var _wave: ChargeWave
var _froze: bool = false

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
		_dummies.append(dummy)
		_labels.append(label)
		_dead_for.append(-1.0)
		health.changed.connect(_on_dummy_changed.bind(_dummies.size() - 1))
		_on_dummy_changed(health.current, health.max_hp, _dummies.size() - 1)
	EventBus.player_health_changed.connect(_on_player_health_changed)
	EventBus.charge_progress.connect(_on_charge_progress)
	_combat.wave_launched.connect(_on_wave_launched)
	_on_charge_progress(0.0)
	var loop_script := get_tree().get_script() as Script
	if loop_script != null and loop_script.resource_path.ends_with("screenshot.gd"):
		capture = true


func _exit_tree() -> void:
	if _froze:
		get_tree().paused = false


func _physics_process(delta: float) -> void:
	for i in _dummies.size():
		var health := _dummies[i].get_node(^"Health") as Health
		if not health.is_dead():
			continue
		_dead_for[i] += delta
		if _dead_for[i] >= dummy_respawn:
			_dead_for[i] = -1.0
			health.reset()
	if capture:
		_run_capture(delta)


## Capture : cadrage, charge maintenue charge_time + marge, relâche, pause quand l'onde est
## à freeze_at mètres.
func _run_capture(delta: float) -> void:
	_capture_time += delta
	match _capture_step:
		0:
			if _capture_time >= 0.2:
				var camera := $ShotCamera as Camera3D
				camera.look_at_from_position(shot_position, shot_target)
				camera.make_current()
				for dummy: Node3D in _dummies:
					(dummy.get_node(^"Visual") as CharacterVisual).set_facing(Vector3.BACK)
				_combat.charge_begin()
				_capture_step = 1
				_capture_time = 0.0
		1:
			if _capture_time >= 0.65:
				_combat.charge_release()
				_capture_step = 2
		2:
			if is_instance_valid(_wave) and _wave.traveled() >= freeze_at:
				_froze = true
				get_tree().paused = true
				_capture_step = 3


func _show_status() -> void:
	_status.text = "%s   ·   %s" % [_hp_text, _charge_text]


func _on_dummy_changed(current: int, max_value: int, index: int) -> void:
	if current <= 0:
		_dead_for[index] = 0.0
	_labels[index].text = "PV %d/%d" % [current, max_value]
	_labels[index].modulate = Color(1, 0.45, 0.4) if current < max_value else Color(1, 1, 1)


func _on_player_health_changed(current: int, max_value: int) -> void:
	_hp_text = "Chtholly : %d/%d PV" % [current, max_value]
	_show_status()


func _on_charge_progress(ratio: float) -> void:
	_charge_text = "charge : %d %%" % roundi(ratio * 100.0)
	_show_status()


func _on_wave_launched(wave: Node3D) -> void:
	_wave = wave as ChargeWave
