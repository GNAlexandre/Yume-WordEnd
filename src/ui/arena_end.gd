extends Control
## Fin d'arène (L10), nœud UI/ArenaEnd de game.tscn. Sur EventBus.arena_finished(arena_id, score,
## best) : panneau « Fin de la série » avec le score, la vague atteinte (dernier wave_started de
## l'arène), le meilleur score et le nombre de séries (GameState.arena_record, déjà mis à jour par
## le WaveDirector via record_score), et « Nouveau record ! » si best. « Continuer », Échap ou B
## le ferment. (Systèmes et textes) Titre, bandeau du record et (acte 1) légende du nombre de
## séries lus pour chaque arène dans data/texts/story.json (DialogueRunner.arena_text :
## end_title, new_record, games) ; aux dunes, « Fin de la veille », « Nouveau record de veille ! »
## et « Veilles tenues » ; sous le titre, le nom de la zone de l'arène (Zone.display_name : « Le
## bord du Couchant »).
##
## Pause : affiché, le panneau fige le jeu (get_tree().paused, s'il ne l'était pas déjà ; ce nœud
## est en PROCESS_MODE_ALWAYS), mais seulement le joueur vivant. Mort dans l'arène :
## arena_finished arrive pendant l'émission de player_died ; le panneau attend player_respawned,
## car WorldManager fait réapparaître le joueur respawn_delay s après sa mort avec un minuteur que
## la pause arrêterait. La réapparition n'est donc jamais retardée ; le panneau s'ouvre au village.

signal shown
signal closed

const MenuInput := preload("res://src/ui/main_menu_input.gd")

var _waves: Dictionary[StringName, int] = {}
var _pending: Dictionary = {}
var _player_dead: bool = false
var _paused_by_me: bool = false
var _pad := MenuInput.new()

@onready var _header: Label = %Header
@onready var _record_label: Label = %RecordLabel
@onready var _arena_name: Label = %ArenaName
@onready var _score_value: Label = %ScoreValue
@onready var _wave_value: Label = %WaveValue
@onready var _best_value: Label = %BestValue
@onready var _games_value: Label = %GamesValue
@onready var _games_caption: Label = $Panel/Box/Stats/GamesCaption
@onready var _record_badge: Control = %RecordBadge
@onready var _continue: Button = %ContinueButton
## Légende par défaut du nombre de séries (« Séries jouées »), avant tout texte d'arène.
@onready var _default_games_caption: String = _games_caption.text


func _ready() -> void:
	hide()
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.arena_finished.connect(_on_arena_finished)
	EventBus.player_died.connect(_on_player_died)
	EventBus.player_respawned.connect(_on_player_respawned)
	_continue.pressed.connect(close)
	_record_badge.resized.connect(_center_record_pivot)
	MenuInput.focus_on_hover(self)


func _exit_tree() -> void:
	if _paused_by_me:
		get_tree().paused = false
		_paused_by_me = false


func is_open() -> bool:
	return visible


## Un résultat attend la réapparition du joueur.
func is_waiting() -> bool:
	return not _pending.is_empty()


## Affiche le panneau de fin de série et fige le jeu (public pour la démo et les tests).
func show_result(arena_id: StringName, score: int, best: bool, wave: int) -> void:
	var record := GameState.arena_record(arena_id)
	_header.text = DialogueRunner.arena_text(arena_id, "end_title", _header.text)
	_record_label.text = DialogueRunner.arena_text(arena_id, "new_record", _record_label.text)
	_games_caption.text = DialogueRunner.arena_text(arena_id, "games", _default_games_caption)
	_arena_name.text = WorldManager.zone_display_name(arena_id)
	_score_value.text = str(score)
	_wave_value.text = str(wave) if wave > 0 else "–"
	_best_value.text = str(record["score"])
	_games_value.text = str(record["games"])
	_record_badge.visible = best
	show()
	if not get_tree().paused:
		get_tree().paused = true
		_paused_by_me = true
	_pad.reset()
	_continue.grab_focus()
	if best:
		_record_badge.scale = Vector2.ONE * 0.6
		var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(_record_badge, ^"scale", Vector2.ONE, 0.45)
	shown.emit()


## Ferme le panneau et rend la main au jeu.
func close() -> void:
	if not visible:
		return
	hide()
	_pad.reset()
	if _paused_by_me:
		get_tree().paused = false
		_paused_by_me = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var command := _pad.read(event)
	match command:
		MenuInput.Command.ACCEPT:
			MenuInput.press_focused(self)
		MenuInput.Command.BACK:
			close()
	if command != MenuInput.Command.NONE:
		get_viewport().set_input_as_handled()


## « Nouveau record ! » grossit depuis son centre, quelle que soit la mise en page du panneau.
func _center_record_pivot() -> void:
	_record_badge.pivot_offset = _record_badge.size * 0.5


func _on_wave_started(arena_id: StringName, wave: int, _enemy_count: int) -> void:
	_waves[arena_id] = wave


func _on_arena_finished(arena_id: StringName, score: int, best: bool) -> void:
	_pending = {"arena": arena_id, "score": score, "best": best, "wave": _waves.get(arena_id, 0)}
	_waves.erase(arena_id)
	# Pendant une mort, player_died n'a peut-être pas encore été reçu ici : on décide en fin d'image.
	_show_pending.call_deferred()


func _show_pending() -> void:
	if _pending.is_empty() or _player_dead:
		return
	var result := _pending
	_pending = {}
	show_result(result["arena"], result["score"], result["best"], result["wave"])


func _on_player_died() -> void:
	_player_dead = true


func _on_player_respawned() -> void:
	_player_dead = false
	if not _pending.is_empty():
		_show_pending.call_deferred()
