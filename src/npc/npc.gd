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
## (Systèmes et textes) Présence selon l'histoire : data.is_present() (NpcData.visible_if, et
## jamais le PNJ dont le skin est celui du joueur). Absent, le PNJ est caché, retiré de la
## physique (process_mode DISABLED : ni collision ni InteractArea), sans invite, sans dialogue
## ni marqueur. Réévaluée en fin d'image avec le marqueur (quête, étape, drapeaux, inventaire,
## partie chargée, skin, fin de série d'arène pour best_score) ; un PNJ qui parle ne disparaît
## qu'à la fin de son dialogue.
## (HD-2D) Pendant son dialogue, le PNJ joue l'animation TALK de sa planche (« parle » :
## docs/ASSETS_HD2D.md, section 3.2) si elle existe, puis revient à « repos ».
## (E4) La vie : un PNJ des emplois du temps (data/life/) est mené par LifeDirector, qui lui
## donne un LifeActor (life) : il marche (déplacé par le directeur, sans physique ; sa collision
## quitte la couche 1 pendant qu'il marche, pour ne jamais bloquer le joueur), change de tenue à
## chaud (set_outfit), regarde le joueur et le salue d'une bulle (say : enfant Bubble, Label3D) ;
## son activité s'interrompt pendant sa conversation et reprend après. Sans life (l'ancienne île),
## rien ne change. Un PNJ sans dialogue (fées génériques) répond d'une bulle (LifeTexts, talk/).

const PLAYER_GROUP := &"player"
## Durée maximale de la chute d'apparition (s).
const SETTLE_TIME := 1.0
## Hauteur du marqueur au-dessus de la tête (m) et du visuel sans skin.
const MARKER_GAP := 0.5
const DEFAULT_HEIGHT := 1.6
## Animations de la planche : au repos, et en conversation (facultative).
const IDLE := &"repos"
const TALK := &"parle"
## (E4) Couche « world » du corps (structure figée de npc.tscn).
const WORLD_LAYER := 1
## (E4) Hauteur de la bulle au-dessus de la tête (m) et durée par défaut (s).
const BUBBLE_GAP := 0.3
const BUBBLE_TIME := 2.6

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
var _present: bool = true
## process_mode d'origine, rendu quand le PNJ redevient présent.
var _present_process_mode: ProcessMode = PROCESS_MODE_INHERIT
## (E4) Le meneur de vie (LifeDirector) ; null : PNJ posé à la main, immobile (ancienne île).
var life: LifeActor = null
## (E4) Tenue affichée à la place de data.skin (LifeActor, set_outfit) ; null : data.skin.
var outfit_skin: SkinData = null
var _bubble_left: float = 0.0

@onready var visual: CharacterVisual = $Visual
@onready var runner: DialogueRunner = $DialogueRunner
@onready var quest_marker: Label3D = $QuestMarker
@onready var bubble: Label3D = $Bubble


func _ready() -> void:
	_breath_time = randf() * breath_period
	_base_scale = visual.scale
	_present_process_mode = process_mode
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_ended.connect(_on_dialogue_ended)
	EventBus.quest_updated.connect(_schedule_marker.unbind(2))
	EventBus.quest_step_updated.connect(_schedule_marker.unbind(3))
	EventBus.inventory_changed.connect(_schedule_marker)
	EventBus.flag_changed.connect(_schedule_marker.unbind(2))
	EventBus.game_loaded.connect(_schedule_marker)
	EventBus.skin_changed.connect(_schedule_marker.unbind(1))
	EventBus.arena_finished.connect(_schedule_marker.unbind(3))
	if life != null:
		set_physics_process(false)
	_apply_data()


func _process(delta: float) -> void:
	_breath_time += delta
	var breath := sin(_breath_time * TAU / maxf(breath_period, 0.1)) * breath_amount
	visual.scale = _base_scale * Vector3(1.0, 1.0 + breath, 1.0)
	if quest_marker.visible:
		quest_marker.position.y = _marker_height + sin(_breath_time * 2.6) * 0.06
	if _bubble_left > 0.0:
		_bubble_left -= delta
		if _bubble_left <= 0.0:
			hide_bubble()
	if life != null:
		return
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
	return "Parler" if _present else ""


func interact(_player: Node3D) -> void:
	if data == null or not _present or runner.is_running() or _cooling_down():
		return
	if life != null and life.on_interact():
		return
	if data.dialogue_path.is_empty():
		# (E4) Fée générique : une bulle, pas de conversation.
		say(LifeTexts.text("talk/" + String(data.id), LifeTexts.text("talk/generic")))
		return
	runner.start(data)


## (E4) Entre dans la vie : mené par actor (LifeDirector), plus de chute d'apparition.
func enter_life(actor: LifeActor) -> void:
	life = actor
	set_physics_process(false)


## (E4) Change de tenue à chaud (CharacterVisual.set_skin : même animation au même instant, même
## sens) ; null : data.skin.
func set_outfit(skin: SkinData) -> void:
	outfit_skin = skin
	var shown := skin if skin != null else (data.skin if data != null else null)
	if shown != null and is_node_ready():
		visual.set_skin(shown)
		_marker_height = shown.height_m + MARKER_GAP
		bubble.position.y = shown.height_m + BUBBLE_GAP


## (E4) Pendant qu'il marche, le corps quitte la couche 1 : un PNJ qui passe ne bloque jamais le
## joueur (il l'évite) ; arrêté, il redevient un obstacle.
func set_moving(moving: bool) -> void:
	collision_layer = 0 if moving else WORLD_LAYER


## (E4) Bulle au-dessus de la tête pendant seconds s (texte vide : rien).
func say(text: String, seconds: float = BUBBLE_TIME) -> void:
	if text.is_empty() or not is_node_ready():
		return
	bubble.text = text
	bubble.visible = true
	_bubble_left = seconds


## (E4) Cache la bulle.
func hide_bubble() -> void:
	_bubble_left = 0.0
	if is_node_ready():
		bubble.visible = false


## (E4) Texte de la bulle affichée ("" sans bulle).
func bubble_text() -> String:
	return bubble.text if is_node_ready() and bubble.visible else ""


## Vrai si le PNJ est là (data.is_present() à la dernière évaluation ; un PNJ sans data l'est).
func is_present() -> bool:
	return _present


## Réévalue tout de suite la présence (data.is_present()), puis le marqueur. Un PNJ qui parle ne
## disparaît pas : son absence attend la fin de la conversation (dialogue_ended).
func refresh_presence() -> void:
	var present := data == null or data.is_present()
	if present != _present and (present or not _talking):
		_set_present(present)
	refresh_quest_marker()


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
	if data != null and _present and not _talking:
		_marker_kind = QuestData.npc_marker(data.id)
	quest_marker.visible = not _marker_kind.is_empty()
	quest_marker.text = "?" if _marker_kind == QuestData.MARKER_TURN_IN else "!"
	quest_marker.position.y = _marker_height


## Présence et marqueur recalculés en fin d'image (plusieurs signaux de la même image regroupés).
func _schedule_marker() -> void:
	if not _marker_pending:
		_marker_pending = true
		refresh_presence.call_deferred()


## Absent : caché et retiré de la physique (corps et InteractArea, disable_mode REMOVE).
func _set_present(present: bool) -> void:
	_present = present
	visible = present
	process_mode = _present_process_mode if present else PROCESS_MODE_DISABLED


func _apply_data() -> void:
	set_process(data != null)
	var shown := outfit_skin if outfit_skin != null else (data.skin if data != null else null)
	if shown != null:
		_marker_height = shown.height_m + MARKER_GAP
		bubble.position.y = shown.height_m + BUBBLE_GAP
	refresh_presence()
	if data == null:
		return
	if shown != null:
		visual.set_skin(shown)
	visual.play(TALK if _talking and visual.has_animation(TALK) else IDLE)


func _cooling_down() -> bool:
	return _ended_at_msec >= 0 and Time.get_ticks_msec() - _ended_at_msec < talk_cooldown * 1000.0


func _on_dialogue_started(npc_id: StringName) -> void:
	if data != null and npc_id == data.id:
		_talking = true
		if visual.has_animation(TALK):
			visual.play(TALK)
		refresh_quest_marker()


func _on_dialogue_ended(npc_id: StringName) -> void:
	if data != null and npc_id == data.id:
		_ended_at_msec = Time.get_ticks_msec()
		_talking = false
		if life == null:
			visual.play(IDLE)
		_schedule_marker()
