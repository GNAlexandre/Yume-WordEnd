extends Control
## HUD (L10), nœud UI/HUD de game.tscn. Alimenté uniquement par l'EventBus ; lectures permises en
## plus : GameState (valeurs de départ), SaveManager.saved. Le marqueur de cible lit
## locked_target() du joueur (groupe player), la surcouche F3 Performance.get_monitor().
##
## - Cœurs : player_health_changed (avant la 1re émission, différée, GameState.max_hp pleins) ;
##   player_damaged les fait trembler et rougit les bords de l'écran.
## - Jauge de charge : charge_progress (cachée à 0, dorée et « Onde prête ! » à 1).
## - (U1) Signes d'interaction posés dans le monde (InteractSigns, src/ui/interact_signs.gd) à la
##   place de l'invite « E / A : Parler ».
## - Mort : fondu au noir (player_died), retour (player_respawned) ; « Sauvegardé »
##   (SaveManager.saved) ; F3 : surcouche de performance (touche lue directement).
## - (Systèmes et textes) Textes de l'histoire, data/texts/story.json (DialogueRunner.story_text) :
##   le fondu de la mort dit « Retour à l'entrepôt… » (defeat/fade) ; à la réapparition, message
##   « Les autres t'ont ramenée à l'entrepôt. » (defeat/message) ; à un rattrapage de chute
##   (WorldManager.rescued), fondu au blanc puis « Tes ailes se sont ouvertes… » (fall/message).
##   Messages en bas de l'écran (StoryMessage), en fondu.
## - Invite et jauge masquées entre dialogue_started et dialogue_ended. Coin haut droit (Sac,
##   Pause tactiles) et bas de l'écran (joystick, boutons) laissés libres ; tout le HUD laisse
##   passer la souris (mouse_filter IGNORE). Le menu pause (PauseMenu) est un enfant du HUD
##   (game.tscn est figé).
## - (E6) Le récit : enfants StoryOverlay (fondus et cartons des scènes), StoryHint (l'indice
##   discret) et Calendar (le calendrier de l'acte en jours, action « journal »). (F1) L'arène,
##   le nom des zones, la bannière et l'encadré de quête sont partis avec l'ancienne île.

const HEART_FULL := preload("res://assets/ui/heart_full.png")
const HEART_EMPTY := preload("res://assets/ui/heart_empty.png")
const PLAYER_GROUP := &"player"
const ENEMIES_GROUP := &"enemies"
## Rafraîchissement de la surcouche F3 (s).
const PERF_PERIOD := 0.25

@export_group("Durées (s)")
## Indicateur « Sauvegardé ».
@export var saved_time: float = 1.6
## Fondu d'apparition et de disparition des bannières.
@export var fade_time: float = 0.35
## Fondu au noir à la mort (commence après death_delay).
@export var death_fade_time: float = 1.0
@export var death_delay: float = 0.5
## Message de l'histoire (chute, défaite), sans les fondus.
@export var story_time: float = 3.2
## Fondu au blanc d'un rattrapage de chute (les ailes de lumière).
@export var fall_flash_time: float = 0.9
@export_group("")
## Hauteur du marqueur au-dessus d'une cible sans EnemyData (m).
@export var lock_marker_height: float = 1.6

var _hp: int = 0
var _max_hp: int = 0
var _charge: float = 0.0
var _in_dialogue: bool = false
var _tweens: Dictionary[StringName, Tween] = {}
var _perf_left: float = 0.0
var _time: float = 0.0

@onready var _hearts_holder: Control = %HeartsHolder
@onready var _hearts: HBoxContainer = %Hearts
@onready var _charge_row: Control = %ChargeRow
@onready var _charge_bar: ProgressBar = %ChargeBar
@onready var _charge_label: Label = %ChargeLabel
@onready var _signs: Control = %InteractSigns
@onready var _saved_indicator: Control = %SavedIndicator
@onready var _perf_overlay: Control = %PerfOverlay
@onready var _perf_label: Label = %PerfLabel
@onready var _lock_marker: Control = %LockMarker
@onready var _damage_flash: Control = %DamageFlash
@onready var _death_fade: Control = %DeathFade
@onready var _death_label: Label = %DeathLabel
@onready var _fall_flash: Control = %FallFlash
@onready var _story_message: Control = %StoryMessage
@onready var _story_label: Label = %StoryLabel


func _ready() -> void:
	EventBus.player_health_changed.connect(set_health)
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.player_died.connect(_on_player_died)
	EventBus.player_respawned.connect(_on_player_respawned)
	EventBus.charge_progress.connect(set_charge)
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_ended.connect(_on_dialogue_ended)
	SaveManager.saved.connect(_on_saved)
	WorldManager.rescued.connect(_on_rescued)
	_death_label.text = DialogueRunner.story_text("defeat/fade", _death_label.text)
	# (U1) Fondus transparents au départ ; panneaux en verre dépoli (UiStyle).
	_death_fade.modulate.a = 0.0
	_fall_flash.modulate.a = 0.0
	for panel: Control in [_saved_indicator, _story_message]:
		UiStyle.frost(panel)
	set_health(GameState.max_hp, GameState.max_hp)


func _process(delta: float) -> void:
	_time += delta
	_update_lock_marker()
	if _charge >= 1.0:
		_charge_label.modulate = Color(1, 1, 1, 0.7 + 0.3 * absf(sin(_time * 6.0)))
	if _perf_overlay.visible:
		_perf_left -= delta
		if _perf_left <= 0.0:
			_perf_left = PERF_PERIOD
			_perf_label.text = perf_text()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_F3:
		toggle_perf_overlay()
		get_viewport().set_input_as_handled()


# --- Cœurs et dégâts --------------------------------------------------------------------------


## Cœurs : current pleins sur max_value (contrat de player_health_changed).
func set_health(current: int, max_value: int) -> void:
	var healed := _max_hp > 0 and current > _hp
	_max_hp = maxi(max_value, 0)
	_hp = clampi(current, 0, _max_hp)
	var heart_size := Vector2.ONE * UiStyle.constant(&"heart_px")
	while _hearts.get_child_count() < _max_hp:
		var heart := TextureRect.new()
		heart.custom_minimum_size = heart_size
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
		heart.pivot_offset = heart_size * 0.5
		_hearts.add_child(heart)
	while _hearts.get_child_count() > _max_hp:
		var extra := _hearts.get_child(_hearts.get_child_count() - 1)
		_hearts.remove_child(extra)
		extra.queue_free()
	for i in _max_hp:
		(_hearts.get_child(i) as TextureRect).texture = HEART_FULL if i < _hp else HEART_EMPTY
	_hearts_holder.custom_minimum_size = _hearts.get_combined_minimum_size()
	if healed:
		var heart := _hearts.get_child(_hp - 1) as Control
		heart.scale = Vector2.ONE * 1.4
		create_tween().tween_property(heart, ^"scale", Vector2.ONE, 0.3)


## PV affichés : Vector2i(pleins, total).
func health() -> Vector2i:
	return Vector2i(_hp, _max_hp)


func _on_player_damaged(_amount: int, _source: Node3D) -> void:
	_damage_flash.show()
	var flash := _restart_tween(&"flash")
	_damage_flash.modulate.a = 1.0
	flash.tween_property(_damage_flash, ^"modulate:a", 0.0, 0.5)
	flash.tween_callback(_damage_flash.hide)
	var shake := _restart_tween(&"shake")
	for offset: float in [9.0, -8.0, 6.0, -4.0, 0.0]:
		shake.tween_property(_hearts, ^"position:x", offset, 0.05)


## Tremblement ou flash rouge en cours (dégât récent).
func is_damage_feedback_playing() -> bool:
	return _damage_flash.visible


# --- Jauge de charge --------------------------------------------------------------------------


## Jauge de la charge magique (contrat de charge_progress) : 0 la cache, 1 = onde prête.
func set_charge(ratio: float) -> void:
	_charge = clampf(ratio, 0.0, 1.0)
	_charge_bar.value = _charge
	var full := _charge >= 1.0
	_charge_bar.theme_type_variation = &"ChargeBarFull" if full else &""
	_charge_label.text = "Onde prête !" if full else "Charge"
	if not full:
		_charge_label.modulate = Color.WHITE
	_refresh_charge()


func _refresh_charge() -> void:
	_charge_row.visible = _charge > 0.0 and not _in_dialogue


# --- Invite, sauvegarde ----------------------------------------------------------------------


## (U1) Signes d'interaction posés dans le monde (src/ui/interact_signs.gd), à la place de
## l'ancienne invite « E / A : Parler ».
func interact_signs() -> Control:
	return _signs


func _on_dialogue_started(_npc_id: StringName) -> void:
	_in_dialogue = true
	_refresh_charge()


func _on_dialogue_ended(_npc_id: StringName) -> void:
	_in_dialogue = false
	_refresh_charge()


func _on_saved(_path: String) -> void:
	_flash(&"saved", _saved_indicator, saved_time)


## Message de l'histoire en bas de l'écran (chute, défaite), en fondu ; "" n'affiche rien.
func show_story_message(text: String) -> void:
	if text.is_empty():
		return
	_story_label.text = text
	_flash(&"story", _story_message, story_time)


## Message de l'histoire affiché ("" : aucun).
func story_message() -> String:
	return _story_label.text if _story_message.visible else ""


## Opacité du fondu au blanc d'un rattrapage de chute (0 : invisible).
func fall_flash_alpha() -> float:
	return _fall_flash.modulate.a if _fall_flash.visible else 0.0


## Rattrapage de chute : les ailes de lumière (fondu au blanc), puis le message.
func _on_rescued(_map_id: StringName) -> void:
	_fall_flash.show()
	_fall_flash.modulate.a = 1.0
	var flash := _restart_tween(&"fall")
	flash.tween_property(_fall_flash, ^"modulate:a", 0.0, fall_flash_time)
	flash.tween_callback(_fall_flash.hide)
	show_story_message(DialogueRunner.story_text("fall/message"))


# --- Mort ------------------------------------------------------------------------------------


func _on_player_died() -> void:
	_death_fade.show()
	var fade := _restart_tween(&"death")
	fade.tween_interval(death_delay)
	fade.tween_property(_death_fade, ^"modulate:a", 1.0, death_fade_time)


func _on_player_respawned() -> void:
	var fade := _restart_tween(&"death")
	# Fondu jusqu'au bout même si un écran met le jeu en pause aussitôt (menu pause).
	fade.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade.tween_property(_death_fade, ^"modulate:a", 0.0, 0.6)
	fade.tween_callback(_death_fade.hide)
	show_story_message(DialogueRunner.story_text("defeat/message"))


## Opacité du fondu au noir (0 : invisible).
func death_fade_alpha() -> float:
	return _death_fade.modulate.a if _death_fade.visible else 0.0


# --- Cible verrouillée et surcouche F3 ------------------------------------------------------


## Ennemi verrouillé par le joueur (locked_target() du nœud du groupe player), ou null.
func locked_target() -> Node3D:
	var player := get_tree().get_first_node_in_group(PLAYER_GROUP)
	if player == null or not player.has_method(&"locked_target"):
		return null
	var target: Object = player.call(&"locked_target")
	return target as Node3D if is_instance_valid(target) else null


func _update_lock_marker() -> void:
	var target := locked_target()
	var camera := get_viewport().get_camera_3d()
	if target == null or camera == null or not target.is_inside_tree():
		_lock_marker.hide()
		return
	var point := shown_position(target) + Vector3.UP * _marker_height(target)
	if camera.is_position_behind(point):
		_lock_marker.hide()
		return
	var bob := Vector2(0.0, -6.0 * absf(sin(_time * 4.0)))
	_lock_marker.position = (
		camera.unproject_position(point)
		- Vector2(_lock_marker.size.x * 0.5, _lock_marker.size.y)
		+ bob
	)
	_lock_marker.show()


## Place affichée d'un nœud qui bouge aux images physiques (un Timere) : interpolée entre deux
## images physiques quand le lissage physique est actif (project.godot), sinon sa position. Le
## marqueur, dessiné à chaque image, suit ainsi le sprite tel qu'il est rendu, sans trembler.
static func shown_position(node: Node3D) -> Vector3:
	if node.is_physics_interpolated_and_enabled():
		return node.get_global_transform_interpolated().origin
	return node.global_position


## Hauteur du marqueur : haut du visuel d'un Enemy (EnemyData), sinon lock_marker_height.
func _marker_height(target: Node3D) -> float:
	var data: Variant = target.get(&"data")
	if data is EnemyData and (data as EnemyData).visual != null:
		return (data as EnemyData).visual.height_m * (data as EnemyData).scale + 0.3
	return lock_marker_height


func toggle_perf_overlay() -> void:
	_perf_overlay.visible = not _perf_overlay.visible
	_perf_left = 0.0
	_perf_label.text = perf_text()


## Texte de la surcouche F3.
func perf_text() -> String:
	var memory := Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0
	return (
		"\n"
		. join(
			[
				"FPS : %d" % roundi(Performance.get_monitor(Performance.TIME_FPS)),
				(
					"Appels de dessin : %d"
					% roundi(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
				),
				(
					"Primitives : %d"
					% roundi(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
				),
				"Mémoire vidéo : %s Mo" % ("%.1f" % memory).replace(".", ","),
				"Ennemis : %d" % get_tree().get_nodes_in_group(ENEMIES_GROUP).size(),
			]
		)
	)


# --- Outils -----------------------------------------------------------------------------------


## Montre node en fondu, le garde hold secondes, puis l'efface.
func _flash(key: StringName, node: Control, hold: float) -> void:
	var tween := _restart_tween(key)
	node.show()
	node.modulate.a = 0.0
	tween.tween_property(node, ^"modulate:a", 1.0, fade_time)
	tween.tween_interval(hold)
	tween.tween_property(node, ^"modulate:a", 0.0, fade_time * 1.5)
	tween.tween_callback(node.hide)


func _restart_tween(key: StringName) -> Tween:
	if _tweens.has(key):
		_tweens[key].kill()
	var tween := create_tween()
	_tweens[key] = tween
	return tween
