class_name Npc
extends CharacterBody3D
## Personnage non joueur (PLAN.md section 4). Propriétaire : L6.
##
## Structure figée de npc.tscn : racine CharacterBody3D (couche 1 world) du groupe
## "interactable", enfants CollisionShape3D, Visual (CharacterVisual), InteractArea (Area3D,
## couche 6 interactable : c'est elle que détecte le joueur) et DialogueRunner.
## Comportement : visuel du skin data.skin, animation « repos » de la planche (sa respiration est
## dessinée : (AN) plus d'étirement du visuel, qui faisait apparaître et disparaître des lignes de
## pixels) ; se tourne vers le joueur (groupe "player") à moins de look_distance ;
## interact() lance son DialogueRunner. Un PNJ sans data reste invisible et muet, sans erreur.
## Le PNJ ne marche pas : à l'apparition, il tombe au plus SETTLE_TIME s sur le sol sous lui
## (couche 1), puis ne bouge plus (son emplacement peut donc être un peu au-dessus du sol).
## (Systèmes et textes) Présence selon l'histoire : data.is_present() (NpcData.visible_if, et
## jamais le PNJ dont le skin est celui du joueur). Absent, le PNJ est caché, retiré de la
## physique (process_mode DISABLED : ni collision ni InteractArea), sans invite ni dialogue.
## Réévaluée en fin d'image sur les signaux qui peuvent la changer (drapeaux, inventaire, partie
## chargée, skin) ; un PNJ qui parle ne disparaît qu'à la fin de son dialogue. (F1) Le marqueur de
## quête (« ! », « ? ») est parti avec les quêtes de l'ancienne île.
## (HD-2D) Pendant son dialogue, le PNJ joue l'animation TALK de sa planche (« parle » :
## docs/ASSETS_HD2D.md, section 3.2) si elle existe, puis revient à « repos ».
## (E4) La vie : un PNJ des emplois du temps (data/life/) est mené par LifeDirector, qui lui
## donne un LifeActor (life) : il marche (déplacé par le directeur, sans physique ; sa collision
## quitte la couche 1 pendant qu'il marche, pour ne jamais bloquer le joueur), change de tenue à
## chaud (set_outfit), regarde le joueur et le salue d'une bulle (say : enfant Bubble, Label3D) ;
## son activité s'interrompt pendant sa conversation et reprend après. Sans life (PNJ posé à la
## main, cartes de test), rien ne change. Un PNJ sans dialogue (fées génériques) répond d'une
## bulle (LifeTexts, talk/).

const PLAYER_GROUP := &"player"
## Durée maximale de la chute d'apparition (s).
const SETTLE_TIME := 1.0
## Hauteur de la tête du visuel sans skin (m).
const DEFAULT_HEIGHT := 1.6
## Animations de la planche : au repos, et en conversation (facultative).
const IDLE := &"repos"
const TALK := &"parle"
## (AN) Décalage maximal de l'horloge du repos à l'apparition (s).
const IDLE_PHASE_SPREAD := 1.0
## (E4) Couche « world » du corps (structure figée de npc.tscn).
const WORLD_LAYER := 1
## (E4) Hauteur de la bulle au-dessus de la tête (m) et durée par défaut (s).
const BUBBLE_GAP := 0.3
const BUBBLE_TIME := 2.6
## (QC2) Une bulle ne tombe jamais sur le joueur : vue de la caméra (inclinée de 32°, vers le
## nord), si elle couvrirait sa silhouette (à moins de BUBBLE_REACH m de part et d'autre, la
## demi-largeur de la bulle et celle du joueur), elle monte au-dessus de sa tête, à
## BUBBLE_CLEARANCE m (Pannibal couchée à ses pieds pendant l'embuscade).
const BUBBLE_REACH := 1.85
const BUBBLE_CLEARANCE := 0.2
const CAMERA_PITCH_DEG := 32.0
## Hauteur de la tête du joueur sans skin (m).
const PLAYER_HEIGHT := 1.5

## Données du PNJ (data/npcs/*.tres).
@export var data: NpcData:
	set(value):
		data = value
		if is_node_ready():
			_apply_data()
## Distance (m, dans le plan du sol) en deçà de laquelle le PNJ regarde le joueur.
@export var look_distance: float = 4.0
## Délai (s) pendant lequel interact() est ignoré après la fin de son dialogue : la touche qui
## ferme la dernière réplique ne doit pas relancer la conversation dans la même image.
@export var talk_cooldown: float = 0.3

## (E4) Le meneur de vie (LifeDirector) ; null : PNJ posé à la main, immobile.
var life: LifeActor = null
## (E4) Tenue affichée à la place de data.skin (LifeActor, set_outfit) ; null : data.skin.
var outfit_skin: SkinData = null

var _ended_at_msec: int = -1
var _settle_left: float = SETTLE_TIME
var _head_height: float = DEFAULT_HEIGHT
var _presence_pending: bool = false
var _talking: bool = false
var _present: bool = true
## process_mode d'origine, rendu quand le PNJ redevient présent.
var _present_process_mode: ProcessMode = PROCESS_MODE_INHERIT
var _bubble_left: float = 0.0

@onready var visual: CharacterVisual = $Visual
@onready var runner: DialogueRunner = $DialogueRunner
@onready var bubble: Label3D = $Bubble


func _ready() -> void:
	# (AN) La cadence de marche suit la vitesse réelle (LifeActor le déplace sans physique).
	visual.match_stride = true
	_present_process_mode = process_mode
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_ended.connect(_on_dialogue_ended)
	EventBus.inventory_changed.connect(_schedule_presence)
	EventBus.flag_changed.connect(_schedule_presence.unbind(2))
	EventBus.game_loaded.connect(_schedule_presence)
	EventBus.skin_changed.connect(_schedule_presence.unbind(1))
	if life != null:
		set_physics_process(false)
	_apply_data()
	# (AN) Chacun respire à son rythme : l'horloge du repos part d'un instant tiré au hasard (des
	# PNJ posés ensemble ne respirent plus à l'unisson).
	visual.advance(randf() * IDLE_PHASE_SPREAD)


func _process(delta: float) -> void:
	if _bubble_left > 0.0:
		_bubble_left -= delta
		if _bubble_left <= 0.0:
			hide_bubble()
		else:
			place_bubble()
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
	return "Parler" if _present and not (life != null and life.talk_blocked()) else ""


func interact(_player: Node3D) -> void:
	if data == null or not _present or runner.is_running() or _cooling_down():
		return
	if life != null and life.talk_blocked():
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
		_head_height = shown.height_m
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
	place_bubble()


## (QC2) Hauteur de la bulle (m au-dessus des pieds) : au-dessus de la tête, ou au-dessus de celle
## du joueur quand, vue de la caméra, elle tomberait sur lui (voir BUBBLE_REACH).
func bubble_height() -> float:
	var height := _head_height + BUBBLE_GAP
	var player: Node3D = null
	if is_inside_tree():
		player = get_tree().get_first_node_in_group(PLAYER_GROUP) as Node3D
	if player == null:
		return height
	var offset := player.global_position - global_position
	if absf(offset.x) > BUBBLE_REACH or offset.z > 0.5:
		return height
	# Le bas de la bulle, vu de la caméra, passe au-dessus de la tête du joueur : un point au nord
	# de dz m monte à l'écran de dz × tan 32° (en hauteur de bulle).
	var skin := SkinRegistry.get_skin(GameState.skin_id)
	var head := skin.height_m if skin != null else PLAYER_HEIGHT
	var above := offset.y + head + BUBBLE_CLEARANCE - offset.z * tan(deg_to_rad(CAMERA_PITCH_DEG))
	return maxf(height, above)


## (QC2) Pose la bulle à bubble_height().
func place_bubble() -> void:
	if is_node_ready():
		bubble.position.y = bubble_height()


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


## Réévalue tout de suite la présence (data.is_present()). Un PNJ qui parle ne disparaît pas :
## son absence attend la fin de la conversation (dialogue_ended).
func refresh_presence() -> void:
	_presence_pending = false
	var present := data == null or data.is_present()
	if present != _present and (present or not _talking):
		_set_present(present)


## Hauteur de la tête au-dessus des pieds (m) : celle de la tenue affichée (SkinData.height_m),
## DEFAULT_HEIGHT sans skin. Les signes d'interaction se posent au-dessus.
func head_height() -> float:
	return _head_height


## Tourne le visuel vers target s'il est à moins de look_distance ; true s'il s'est tourné.
func look_toward(target: Vector3) -> bool:
	var offset := target - global_position
	offset.y = 0.0
	if offset.length_squared() > look_distance * look_distance or offset.is_zero_approx():
		return false
	visual.set_facing(offset)
	return true


## Présence recalculée en fin d'image (plusieurs signaux de la même image regroupés).
func _schedule_presence() -> void:
	if not _presence_pending:
		_presence_pending = true
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
		_head_height = shown.height_m
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


func _on_dialogue_ended(npc_id: StringName) -> void:
	if data != null and npc_id == data.id:
		_ended_at_msec = Time.get_ticks_msec()
		_talking = false
		if life == null:
			visual.play(IDLE)
		_schedule_presence()
