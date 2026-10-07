class_name Npc
extends CharacterBody3D
## Personnage non joueur (PLAN.md section 4). Propriétaire : L6.
##
## Structure figée de npc.tscn : racine CharacterBody3D (couche 1 world) du groupe
## "interactable", enfants CollisionShape3D, Visual (CharacterVisual), InteractArea (Area3D,
## couche 6 interactable : c'est elle que détecte le joueur) et DialogueRunner.
## Comportement : visuel du skin data.skin, animation « repos » de la planche et légère
## respiration ; se tourne vers le joueur (groupe "player") à moins de look_distance ;
## interact() lance son DialogueRunner. Un PNJ sans data reste invisible et muet, sans erreur.
## Le PNJ ne marche pas : à l'apparition, il tombe au plus SETTLE_TIME s sur le sol sous lui
## (couche 1), puis ne bouge plus (son emplacement peut donc être un peu au-dessus du sol).
## (Lot Q) Marqueur de quête QuestMarker (Label3D doré face à la caméra, au-dessus de la tête,
## qui flotte doucement) : « ! » s'il propose une quête disponible, « ? » si l'étape courante
## d'une quête active se valide en lui parlant (QuestData.npc_marker) ; caché pendant son
## dialogue. Recalculé en fin d'image sur les signaux de quête, d'inventaire et de drapeaux.

const PLAYER_GROUP := &"player"
## Durée maximale de la chute d'apparition (s).
const SETTLE_TIME := 1.0
## Hauteur du marqueur au-dessus de la tête (m) et du visuel sans skin.
const MARKER_GAP := 0.5
const DEFAULT_HEIGHT := 1.6

## Données du PNJ (data/npcs/*.tres).
@export var data: NpcData:
	set(value):
		data = value
		if is_node_ready():
			_apply_data()
## Distance (m, dans le plan du sol) en deçà de laquelle le PNJ regarde le joueur.
@export var look_distance: float = 4.0
## Amplitude de la respiration au repos (fraction de la hauteur du visuel ; Visual.scale.y oscille
## autour de sa valeur de départ).
@export var breath_amount: float = 0.02
## Durée d'une respiration (s).
@export var breath_period: float = 2.8
## Délai (s) pendant lequel interact() est ignoré après la fin de son dialogue : la touche qui
## ferme la dernière réplique ne doit pas relancer la conversation dans la même image.
@export var talk_cooldown: float = 0.3

var _breath_time: float = 0.0
var _base_scale: Vector3 = Vector3.ONE
var _ended_at_msec: int = -1
var _settle_left: float = SETTLE_TIME
var _marker_kind: StringName = &""
var _marker_height: float = DEFAULT_HEIGHT + MARKER_GAP
var _marker_pending: bool = false
var _talking: bool = false

@onready var visual: CharacterVisual = $Visual
@onready var runner: DialogueRunner = $DialogueRunner
@onready var quest_marker: Label3D = $QuestMarker


func _ready() -> void:
	_breath_time = randf() * breath_period
	_base_scale = visual.scale
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_ended.connect(_on_dialogue_ended)
	EventBus.quest_updated.connect(_schedule_marker.unbind(2))
	EventBus.quest_step_updated.connect(_schedule_marker.unbind(3))
	EventBus.inventory_changed.connect(_schedule_marker)
	EventBus.flag_changed.connect(_schedule_marker.unbind(2))
	EventBus.game_loaded.connect(_schedule_marker)
	_apply_data()


func _process(delta: float) -> void:
	_breath_time += delta
	var breath := sin(_breath_time * TAU / maxf(breath_period, 0.1)) * breath_amount
	visual.scale = _base_scale * Vector3(1.0, 1.0 + breath, 1.0)
	if quest_marker.visible:
		quest_marker.position.y = _marker_height + sin(_breath_time * 2.6) * 0.06
	var player := get_tree().get_first_node_in_group(PLAYER_GROUP) as Node3D
	if player != null:
		look_toward(player.global_position)


func _physics_process(delta: float) -> void:
	_settle_left -= delta
	if is_on_floor() or _settle_left <= 0.0:
		velocity = Vector3.ZERO
		set_physics_process(false)
		return
	velocity += get_gravity() * delta
	move_and_slide()


func get_prompt() -> String:
	return "Parler"


func interact(_player: Node3D) -> void:
	if data == null or runner.is_running() or _cooling_down():
		return
	runner.start(data)


## Tourne le visuel vers target s'il est à moins de look_distance ; true s'il s'est tourné.
func look_toward(target: Vector3) -> bool:
	var offset := target - global_position
	offset.y = 0.0
	if offset.length_squared() > look_distance * look_distance or offset.is_zero_approx():
		return false
	visual.set_facing(offset)
	return true


## Marqueur affiché : QuestData.MARKER_AVAILABLE (« ! »), MARKER_TURN_IN (« ? ») ou &"".
func quest_marker_kind() -> StringName:
	return _marker_kind


## Recalcule le marqueur tout de suite (sinon : en fin d'image, après les signaux).
func refresh_quest_marker() -> void:
	_marker_pending = false
	_marker_kind = &""
	if data != null and not _talking:
		_marker_kind = QuestData.npc_marker(data.id)
	quest_marker.visible = not _marker_kind.is_empty()
	quest_marker.text = "?" if _marker_kind == QuestData.MARKER_TURN_IN else "!"
	quest_marker.position.y = _marker_height


func _schedule_marker() -> void:
	if not _marker_pending:
		_marker_pending = true
		refresh_quest_marker.call_deferred()


func _apply_data() -> void:
	set_process(data != null)
	if data != null and data.skin != null:
		_marker_height = data.skin.height_m + MARKER_GAP
	refresh_quest_marker()
	if data == null:
		return
	if data.skin != null:
		visual.set_skin(data.skin)
	visual.play(&"repos")


func _cooling_down() -> bool:
	return _ended_at_msec >= 0 and Time.get_ticks_msec() - _ended_at_msec < talk_cooldown * 1000.0


func _on_dialogue_started(npc_id: StringName) -> void:
	if data != null and npc_id == data.id:
		_talking = true
		refresh_quest_marker()


func _on_dialogue_ended(npc_id: StringName) -> void:
	if data != null and npc_id == data.id:
		_ended_at_msec = Time.get_ticks_msec()
		_talking = false
		_schedule_marker()
