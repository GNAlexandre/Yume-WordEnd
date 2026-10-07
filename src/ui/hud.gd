extends Control
## HUD (L10), nœud UI/HUD de game.tscn. Alimenté uniquement par l'EventBus ; lectures permises en
## plus : WorldManager.zone_display_name(), GameState (valeurs de départ, états et étapes de
## quête, inventaire pour la progression, records), QuestData (find, shown_quest, étape courante),
## SaveManager.saved. Le marqueur de cible lit locked_target() du joueur (groupe player), la
## surcouche F3 Performance.get_monitor().
##
## - Cœurs : player_health_changed (avant la 1re émission, différée, GameState.max_hp pleins) ;
##   player_damaged les fait trembler et rougit les bords de l'écran.
## - Jauge de charge : charge_progress (cachée à 0, dorée et « Onde prête ! » à 1).
## - Arène : vague, score et record (wave_started, arena_score_changed), bannières « Vague n » et
##   « Vague n terminée +bonus » (wave_cleared) ; tout disparaît sur arena_finished.
## - Nom de la zone en fondu (zone_entered) ; invite « E / A : Parler » (interaction_available).
## - (Lot Q) Quête suivie : une seule quête affichée, la quête suivie (GameState.tracked_quest) si
##   elle est active, sinon la première quête active (QuestData.shown_quest()) ; son titre,
##   l'objectif de son étape courante et sa progression (« Fragment de page : 3/5 »,
##   « Ennemis vaincus : 1/2 »), et « +n quêtes · Tab / Select » s'il y en a d'autres. Mise à
##   jour sur quest_updated (relu dans GameState en fin d'image : le QuestTracker peut refuser
##   « done » et remettre « active »), quest_step_updated, tracked_quest_changed et
##   inventory_changed ; le panneau s'illumine à chaque nouvelle étape ; « Quête terminée ! ».
## - Mort : fondu au noir (player_died), retour (player_respawned) ; « Sauvegardé »
##   (SaveManager.saved) ; F3 : surcouche de performance (touche lue directement).
## - Invite et jauge masquées entre dialogue_started et dialogue_ended. Coin haut droit (Sac,
##   Pause tactiles) et bas de l'écran (joystick, boutons) laissés libres ; tout le HUD laisse
##   passer la souris (mouse_filter IGNORE). Le menu pause (PauseMenu) et le journal de quêtes
##   (Journal, Lot Q) sont des enfants du HUD (game.tscn est figé).

const HEART_FULL := preload("res://assets/ui/heart_full.png")
const HEART_EMPTY := preload("res://assets/ui/heart_empty.png")
const QUEST_ICON := preload("res://assets/ui/quest.png")
const PLAYER_GROUP := &"player"
const ENEMIES_GROUP := &"enemies"
const HEART_SIZE := Vector2(42, 42)
## Rafraîchissement de la surcouche F3 (s).
const PERF_PERIOD := 0.25

@export_group("Durées (s)")
## Bannière de vague ou de quête, sans les fondus.
@export var banner_time: float = 2.0
## Nom de la zone, sans les fondus.
@export var zone_time: float = 2.4
## Indicateur « Sauvegardé ».
@export var saved_time: float = 1.6
## Fondu d'apparition et de disparition des bannières.
@export var fade_time: float = 0.35
## Fondu au noir à la mort (commence après death_delay).
@export var death_fade_time: float = 1.0
@export var death_delay: float = 0.5
@export_group("")
## Hauteur du marqueur au-dessus d'une cible sans EnemyData (m).
@export var lock_marker_height: float = 1.6

var _hp: int = 0
var _max_hp: int = 0
var _charge: float = 0.0
var _prompt: String = ""
var _in_dialogue: bool = false
var _arena: StringName = &""
var _wave: int = 0
var _score: int = 0
var _quest_states: Dictionary[StringName, StringName] = {}
var _pending_quests: Dictionary[StringName, bool] = {}
## Panneau de la quête affichée (au plus une entrée : _shown_quest).
var _quest_entries: Dictionary[StringName, Control] = {}
var _shown_quest: StringName = &""
var _shown_step: StringName = &""
var _panel_pending: bool = false
var _tweens: Dictionary[StringName, Tween] = {}
var _perf_left: float = 0.0
var _time: float = 0.0

@onready var _hearts_holder: Control = %HeartsHolder
@onready var _hearts: HBoxContainer = %Hearts
@onready var _charge_row: Control = %ChargeRow
@onready var _charge_bar: ProgressBar = %ChargeBar
@onready var _charge_label: Label = %ChargeLabel
@onready var _quests: VBoxContainer = %Quests
@onready var _arena_panel: Control = %ArenaPanel
@onready var _wave_label: Label = %WaveLabel
@onready var _score_label: Label = %ScoreLabel
@onready var _record_label: Label = %RecordLabel
@onready var _zone_banner: Control = %ZoneBanner
@onready var _zone_label: Label = %ZoneLabel
@onready var _banner: Control = %Banner
@onready var _banner_label: Label = %BannerLabel
@onready var _banner_sub: Label = %BannerSub
@onready var _prompt_panel: Control = %Prompt
@onready var _prompt_label: Label = %PromptLabel
@onready var _saved_indicator: Control = %SavedIndicator
@onready var _perf_overlay: Control = %PerfOverlay
@onready var _perf_label: Label = %PerfLabel
@onready var _lock_marker: Control = %LockMarker
@onready var _damage_flash: Control = %DamageFlash
@onready var _death_fade: Control = %DeathFade


func _ready() -> void:
	EventBus.player_health_changed.connect(set_health)
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.player_died.connect(_on_player_died)
	EventBus.player_respawned.connect(_on_player_respawned)
	EventBus.charge_progress.connect(set_charge)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.wave_cleared.connect(_on_wave_cleared)
	EventBus.arena_score_changed.connect(_on_arena_score_changed)
	EventBus.arena_finished.connect(_on_arena_finished)
	EventBus.zone_entered.connect(_on_zone_entered)
	EventBus.interaction_available.connect(_on_interaction_available)
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_ended.connect(_on_dialogue_ended)
	EventBus.quest_updated.connect(_on_quest_updated)
	EventBus.quest_step_updated.connect(_on_quest_step_updated)
	EventBus.tracked_quest_changed.connect(_schedule_quest_panel.unbind(1))
	EventBus.inventory_changed.connect(_refresh_quest_progress)
	SaveManager.saved.connect(_on_saved)
	set_health(GameState.max_hp, GameState.max_hp)
	var states := GameState.quests()
	for quest_id: StringName in states:
		_quest_states[quest_id] = states[quest_id]
	_refresh_quest_panel()


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
	while _hearts.get_child_count() < _max_hp:
		var heart := TextureRect.new()
		heart.custom_minimum_size = HEART_SIZE
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
		heart.pivot_offset = HEART_SIZE * 0.5
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


# --- Arène ------------------------------------------------------------------------------------


func _on_wave_started(arena_id: StringName, wave: int, enemy_count: int) -> void:
	_arena = arena_id
	_wave = wave
	_refresh_arena()
	show_banner("Vague %d" % wave, "%d Timeres" % enemy_count)


func _on_wave_cleared(arena_id: StringName, wave: int, bonus: int) -> void:
	_arena = arena_id
	_wave = wave
	_refresh_arena()
	show_banner("Vague %d terminée" % wave, "+%d" % bonus)


func _on_arena_score_changed(arena_id: StringName, score: int) -> void:
	if arena_id != _arena:
		_wave = 0
	_arena = arena_id
	_score = score
	_refresh_arena()


func _on_arena_finished(_arena_id: StringName, _final_score: int, _best: bool) -> void:
	_arena = &""
	_wave = 0
	_score = 0
	_arena_panel.hide()
	_stop(&"banner", _banner)


func _refresh_arena() -> void:
	_arena_panel.visible = not _arena.is_empty()
	_wave_label.text = "Vague %d" % _wave if _wave > 0 else "Prépare-toi !"
	_score_label.text = "Score %d" % _score
	_record_label.text = "Record %d" % maxi(GameState.best_score(_arena), _score)


# --- Bannières, zone, invite, sauvegarde -----------------------------------------------------


## Grande bannière au centre (vague, quête terminée), en fondu.
func show_banner(title: String, subtitle: String = "") -> void:
	_banner_label.text = title
	_banner_sub.text = subtitle
	_banner_sub.visible = not subtitle.is_empty()
	_flash(&"banner", _banner, banner_time)


func _on_zone_entered(zone_id: StringName) -> void:
	_zone_label.text = WorldManager.zone_display_name(zone_id)
	_flash(&"zone", _zone_banner, zone_time)


func _on_interaction_available(prompt: String) -> void:
	_prompt = prompt
	_prompt_label.text = prompt
	_refresh_prompt()


func _refresh_prompt() -> void:
	_prompt_panel.visible = not _prompt.is_empty() and not _in_dialogue


func _on_dialogue_started(_npc_id: StringName) -> void:
	_in_dialogue = true
	_refresh_prompt()
	_refresh_charge()


func _on_dialogue_ended(_npc_id: StringName) -> void:
	_in_dialogue = false
	_refresh_prompt()
	_refresh_charge()


func _on_saved(_path: String) -> void:
	_flash(&"saved", _saved_indicator, saved_time)


# --- Quêtes -----------------------------------------------------------------------------------


func _on_quest_updated(quest_id: StringName, _state: StringName) -> void:
	# Le QuestTracker peut refuser « done » et remettre « active » pendant cette émission, avant
	# ou après ce HUD : l'état est relu dans GameState une fois l'émission terminée.
	if _pending_quests.is_empty():
		_flush_quests.call_deferred()
	_pending_quests[quest_id] = true


func _flush_quests() -> void:
	var ids: Array[StringName] = []
	ids.assign(_pending_quests.keys())
	_pending_quests.clear()
	for quest_id: StringName in ids:
		var state := GameState.quest_state(quest_id)
		var previous: StringName = _quest_states.get(quest_id, &"")
		_quest_states[quest_id] = state
		if state == GameState.QUEST_DONE and previous != GameState.QUEST_DONE:
			show_banner("Quête terminée\u00a0!", _quest_title(quest_id))
	_refresh_quest_panel()


func _on_quest_step_updated(_quest_id: StringName, _step_id: StringName, _count: int) -> void:
	_refresh_quest_progress()
	_schedule_quest_panel()


## Quête affichée en fin d'image (plusieurs signaux de la même image regroupés).
func _schedule_quest_panel() -> void:
	if not _panel_pending:
		_panel_pending = true
		_refresh_quest_panel.call_deferred()


## Objectif affiché pour quest_id ("" s'il n'est pas affiché).
func quest_objective(quest_id: StringName) -> String:
	var entry: Control = _quest_entries.get(quest_id)
	return (entry.get_node(^"Box/Objective") as Label).text if entry != null else ""


## Progression affichée pour quest_id (ex. « Fragment de page : 3/5 »).
func quest_progress(quest_id: StringName) -> String:
	var entry: Control = _quest_entries.get(quest_id)
	return (entry.get_node(^"Box/Progress") as Label).text if entry != null else ""


## Quête affichée (la quête suivie si elle est active, sinon la première active ; &"" : aucune).
func shown_quest() -> StringName:
	return _shown_quest


## Met le panneau sur la quête à afficher (QuestData.shown_quest()) et ses textes à jour.
func _refresh_quest_panel() -> void:
	_panel_pending = false
	var shown := QuestData.shown_quest()
	if shown != _shown_quest:
		for quest_id: StringName in _quest_entries:
			_quest_entries[quest_id].queue_free()
		_quest_entries.clear()
		_shown_quest = shown
		_shown_step = &""
		if not shown.is_empty():
			var entry := _make_quest_entry(shown)
			_quests.add_child(entry)
			_quest_entries[shown] = entry
	_refresh_quest_progress()


func _make_quest_entry(quest_id: StringName) -> Control:
	var panel := PanelContainer.new()
	panel.name = "Quest_" + String(quest_id)
	panel.theme_type_variation = &"HudPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := VBoxContainer.new()
	box.name = "Box"
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override(&"separation", 2)
	var title_row := HBoxContainer.new()
	title_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_row.add_theme_constant_override(&"separation", 8)
	var icon := TextureRect.new()
	icon.texture = QUEST_ICON
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_row.add_child(icon)
	title_row.add_child(_hud_label("Title", _quest_title(quest_id), &"HudAccent", 22))
	box.add_child(title_row)
	var objective := _hud_label("Objective", "", &"", 19)
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective.custom_minimum_size.x = 300.0
	box.add_child(objective)
	var progress := _hud_label("Progress", "", &"", 18)
	progress.modulate = Color(1.0, 0.9, 0.8)
	box.add_child(progress)
	var others := _hud_label("Others", "", &"", 15)
	others.modulate = Color(1.0, 0.95, 0.9, 0.75)
	box.add_child(others)
	panel.add_child(box)
	return panel


## Objectif de l'étape courante, progression et nombre d'autres quêtes actives de la quête
## affichée ; le panneau s'illumine quand l'étape change.
func _refresh_quest_progress() -> void:
	var entry: Control = _quest_entries.get(_shown_quest)
	if entry == null:
		return
	var quest := QuestData.find(_shown_quest)
	var step := quest.current_step() if quest != null else null
	(entry.get_node(^"Box/Objective") as Label).text = (
		quest.current_objective() if quest != null else ""
	)
	var progress := entry.get_node(^"Box/Progress") as Label
	progress.text = quest.current_progress() if quest != null else ""
	progress.visible = not progress.text.is_empty()
	var others := entry.get_node(^"Box/Others") as Label
	var other_count := QuestData.active_ids().size() - 1
	others.text = (
		"+%d quête%s · Tab / Select" % [other_count, "s" if other_count > 1 else ""]
		if other_count > 0
		else ""
	)
	others.visible = other_count > 0
	var step_id := step.id if step != null else &""
	if step_id != _shown_step:
		if not _shown_step.is_empty():
			_glow(entry)
		_shown_step = step_id


## Le panneau de quête s'illumine puis revient (nouvelle étape).
func _glow(entry: Control) -> void:
	var tween := _restart_tween(&"quest_glow")
	entry.modulate = Color(1.5, 1.3, 0.75)
	tween.tween_property(entry, ^"modulate", Color.WHITE, 0.8)


func _quest_title(quest_id: StringName) -> String:
	var quest := QuestData.find(quest_id)
	return quest.title if quest != null and not quest.title.is_empty() else String(quest_id)


# --- Mort ------------------------------------------------------------------------------------


func _on_player_died() -> void:
	_death_fade.show()
	var fade := _restart_tween(&"death")
	fade.tween_interval(death_delay)
	fade.tween_property(_death_fade, ^"modulate:a", 1.0, death_fade_time)


func _on_player_respawned() -> void:
	var fade := _restart_tween(&"death")
	# Fondu jusqu'au bout même si un écran met le jeu en pause aussitôt (fin d'arène).
	fade.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade.tween_property(_death_fade, ^"modulate:a", 0.0, 0.6)
	fade.tween_callback(_death_fade.hide)


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
	var point := target.global_position + Vector3.UP * _marker_height(target)
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


func _stop(key: StringName, node: Control) -> void:
	if _tweens.has(key):
		_tweens[key].kill()
		_tweens.erase(key)
	node.hide()


func _restart_tween(key: StringName) -> Tween:
	if _tweens.has(key):
		_tweens[key].kill()
	var tween := create_tween()
	_tweens[key] = tween
	return tween


func _hud_label(label_name: String, text: String, variation: StringName, font_size: int) -> Label:
	var label := Label.new()
	label.name = label_name
	label.text = text
	label.theme_type_variation = variation if not variation.is_empty() else &"HudLabel"
	label.add_theme_font_size_override(&"font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
