extends Node3D
## Démo du Lot 2 : l'île avec le joueur factice et la caméra de survol.
##
## Jouable dans l'éditeur (F6) : ZQSD / WASD ou flèches pour marcher (Maj : courir), Espace
## pour sauter, Tab pour passer de la caméra de survol à la caméra qui suit le joueur. En haut
## à gauche : zone courante, images/s et draw calls.
## Captures : L2_VIEW=<vue> tools/screenshot.sh res://tests/integration/demo_l2.tscn <png>
## cadre une vue fixe (overview, village, dunes) et écrit draw calls et primitives mesurés.

## Vues fixes des captures : position de l'œil, point visé.
const VIEWS := {
	"village": [Vector3(0.8, 1.6, 19.6), Vector3(-1.2, 2.0, -3.0)],
	"dunes": [Vector3(-27.0, 6.5, 8.0), Vector3(-57.0, 0.5, -2.0)],
}
const WALK_SPEED := 6.0
const RUN_SPEED := 11.0
const JUMP_SPEED := 5.0
const FOLLOW_OFFSET := Vector3(0.0, 6.0, 9.0)
## Image à laquelle les mesures sont écrites (la capture est prise à la 12e).
const MEASURE_FRAME := 10

var _view := ""
var _frames := 0
var _zone_name := ""

@onready var _player: CharacterBody3D = $PlayerStub
@onready var _follow: Camera3D = $FollowCamera
@onready var _overview: Camera3D = $Island/OverviewCamera
@onready var _label: Label = $HUD/Label


func _ready() -> void:
	EventBus.zone_entered.connect(_on_zone_entered)
	WorldManager.teleport(WorldManager.VILLAGE)
	_view = OS.get_environment("L2_VIEW")
	if not _view.is_empty():
		_label.hide()
	if VIEWS.has(_view):
		var view: Array = VIEWS[_view]
		_follow.look_at_from_position(view[0], view[1])
		_follow.make_current()


func _physics_process(delta: float) -> void:
	if not _view.is_empty():
		return
	var input := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	var speed := RUN_SPEED if Input.is_action_pressed(&"run") else WALK_SPEED
	_player.velocity.x = input.x * speed
	_player.velocity.z = input.y * speed
	if _player.is_on_floor():
		if Input.is_action_just_pressed(&"jump"):
			_player.velocity.y = JUMP_SPEED
	else:
		_player.velocity += _player.get_gravity() * delta
	_player.move_and_slide()


func _process(_delta: float) -> void:
	_frames += 1
	if _follow.current and _view.is_empty():
		var target := _player.global_position + Vector3.UP
		_follow.look_at_from_position(target + FOLLOW_OFFSET, target)
	var draw_calls := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var primitives := int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	_label.text = (
		"%s\n%d i/s, %d draw calls, %d primitives"
		% [_zone_name, Engine.get_frames_per_second(), draw_calls, primitives]
	)
	if not _view.is_empty() and _frames == MEASURE_FRAME:
		print("L2 vue %s : %d draw calls, %d primitives" % [_view, draw_calls, primitives])


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_TAB:
		if _follow.current:
			_overview.make_current()
		else:
			_follow.make_current()


func _on_zone_entered(zone_id: StringName) -> void:
	_zone_name = WorldManager.zone_display_name(zone_id)
