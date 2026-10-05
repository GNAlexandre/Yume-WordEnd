class_name WaveDirector
extends Node
## Vagues d'une arène, lues dans data/waves/<arena_id>.json (PLAN.md section 4 ; jeu.js
## l. 726-770 et 1085-1112). Propriétaire : L5. Un par arène : enfant « WaveDirector » de
## arena.tscn.
##
## start() lance une série : pause, vague n (wave_started), apparition progressive aux points
## "spawn_points" de l'Arena (un Timere toutes les max(0,5 ; 2,2 − 0,15 n) × [0,7 ; 1,2] s),
## vague nettoyée quand tous sont morts (bonus 50 × n, wave_cleared, player_heal_requested
## toutes les heal_every_waves vagues), pause, vague suivante. Score : points des ennemis de la
## série + bonus ; arena_score_changed à chaque variation. compose(n) donne les ennemis de la
## vague n (liste explicite, puis generator) sans scène : même graine et même n, même liste.
## Fin de série (stop()) : mort du joueur, entrée dans une autre zone, ou sortie des bornes de
## l'Arena entre deux vagues ; GameState.record_score puis arena_finished, ennemis retirés.
## Clés facultatives du JSON (défauts de jeu.js) : heal_amount, timing (délais en s),
## generator.min_wave (première vague de chaque type), music (chemin d'un AudioStream).

## Émis quand une série commence (true) ou se termine (false) ; le panneau de l'arène l'écoute.
signal running_changed(running: bool)

enum Phase { IDLE, PAUSE, SPAWNING }

const WAVES_DIR := "res://data/waves"
const ENEMIES_DIR := "res://data/enemies"
const ENEMY_SCENE := preload("res://src/enemies/enemy.tscn")
const PLAYER_GROUP := &"player"
## Délais par défaut (s), ceux de jeu.js : clés de "timing".
const TIMING_DEFAULTS := {
	"start_delay": 1.2,
	"wave_pause": 1.8,
	"first_spawn_delay": 0.8,
	"spawn_interval": 2.2,
	"spawn_interval_per_wave": 0.15,
	"spawn_interval_min": 0.5,
}
## Tirage du délai entre deux apparitions, par défaut (jeu.js : × [0,7 ; 1,2]).
const DEFAULT_JITTER := Vector2(0.7, 1.2)
## Écart aléatoire autour d'un point d'apparition (m).
const SPAWN_SPREAD := 1.0

## Arène ; vide = celui de l'Arena parente.
@export var arena_id: StringName = &""
## Graine des tirages (compose, points et délais d'apparition) ; 0 = nouvelle graine par série.
@export var random_seed: int = 0

var _config: Dictionary = {}
var _wave: int = 0
var _running: bool = false
var _phase: Phase = Phase.IDLE
var _timer: float = 0.0
var _score: int = 0
var _series_seed: int = 0
var _queue: Array[StringName] = []
var _alive: Array[Enemy] = []
var _rng := RandomNumberGenerator.new()
var _music: AudioStreamPlayer


func _ready() -> void:
	if arena_id.is_empty() and get_parent() is Arena:
		arena_id = (get_parent() as Arena).arena_id
	if not arena_id.is_empty():
		load_config("%s/%s.json" % [WAVES_DIR, arena_id])
	EventBus.player_died.connect(_on_player_died)
	EventBus.zone_entered.connect(_on_zone_entered)


## Charge un fichier de vagues (format de PLAN.md section 4).
func load_config(path: String) -> Error:
	if not ResourceLoader.exists(path):
		return ERR_FILE_NOT_FOUND
	var json := load(path) as JSON
	if json == null or not json.data is Dictionary:
		return ERR_PARSE_ERROR
	_config = json.data
	return OK


## Remplace la configuration (même format que data/waves/*.json) ; sert aux tests et démos.
func set_config(new_config: Dictionary) -> void:
	_config = new_config.duplicate(true)


## Configuration lue (copie).
func config() -> Dictionary:
	return _config.duplicate(true)


## Lance une série (sans effet pendant une série) : score à 0, première vague après start_delay.
func start() -> void:
	if _running:
		return
	_running = true
	_wave = 0
	_score = 0
	_queue.clear()
	_alive.clear()
	_series_seed = random_seed if random_seed != 0 else randi()
	_rng.seed = hash([_series_seed, "spawn"])
	_phase = Phase.PAUSE
	_timer = _timing("start_delay")
	EventBus.arena_score_changed.emit(arena_id, _score)
	_play_music()
	running_changed.emit(true)


## Termine la série : GameState.record_score, arena_finished, ennemis restants retirés.
func stop() -> void:
	if not _running:
		return
	_running = false
	_phase = Phase.IDLE
	_queue.clear()
	var best: bool = GameState.record_score(arena_id, _score, _wave)
	EventBus.arena_finished.emit(arena_id, _score, best)
	for enemy: Enemy in _alive:
		if is_instance_valid(enemy):
			enemy.queue_free()
	_alive.clear()
	if _music != null:
		_music.stop()
	running_changed.emit(false)


func is_running() -> bool:
	return _running


## Numéro de la vague en cours (0 avant la première).
func current_wave() -> int:
	return _wave


## Score de la série en cours (ou de la dernière) : points des ennemis + bonus de vague.
func score() -> int:
	return _score


## Ennemis vivants de la série (copie).
func alive_enemies() -> Array[Enemy]:
	return _alive.duplicate()


## Identifiants des ennemis de la vague (1 = première), dans l'ordre d'apparition : liste
## explicite de "waves" mélangée, puis "generator" au-delà ("count" ennemis tirés selon
## "weights", chaque type à partir de sa vague "min_wave").
func compose(wave: int) -> Array[StringName]:
	var result: Array[StringName] = []
	if wave < 1:
		return result
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([_seed(), wave])
	var waves: Array = _config.get("waves", [])
	if wave <= waves.size():
		var entry: Variant = waves[wave - 1]
		var enemies: Variant = (entry as Dictionary).get("enemies") if entry is Dictionary else null
		if enemies is Dictionary:
			for enemy_id: Variant in enemies:
				for _i in int((enemies as Dictionary)[enemy_id]):
					result.append(StringName(str(enemy_id)))
	else:
		var weights := _weights(wave)
		for _i in _generator_count(wave):
			var picked := _pick(weights, rng)
			if not picked.is_empty():
				result.append(picked)
	for i in range(result.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap := result[i]
		result[i] = result[j]
		result[j] = swap
	return result


## Vitesse × (1 + min(speed_bonus_max ; speed_bonus_per_wave × n)) : +4 % par vague, +50 % max.
func speed_multiplier(wave: int) -> float:
	var generator := _generator()
	var per_wave := float(generator.get("speed_bonus_per_wave", 0.0))
	var cap := float(generator.get("speed_bonus_max", 0.0))
	return 1.0 + minf(cap, per_wave * maxi(wave, 0))


## PV de plus pour enemy_id à la vague n (generator.hp_bonus : Normal +1 dès la vague 6).
func hp_bonus(enemy_id: StringName, wave: int) -> int:
	var bonuses: Variant = _generator().get("hp_bonus", {})
	if not (bonuses is Dictionary):
		return 0
	var bonus: Variant = (bonuses as Dictionary).get(enemy_id)
	if bonus is Dictionary and wave >= int((bonus as Dictionary).get("from_wave", 1)):
		return int((bonus as Dictionary).get("amount", 0))
	return 0


## Bonus de la vague n nettoyée : bonus_per_wave × n (50 × n).
func wave_bonus(wave: int) -> int:
	return int(_config.get("bonus_per_wave", 0)) * wave


## PV rendus quand la vague n est nettoyée : heal_amount toutes les heal_every_waves vagues.
func heal_after(wave: int) -> int:
	var every := int(_config.get("heal_every_waves", 0))
	if every <= 0 or wave % every != 0:
		return 0
	return int(_config.get("heal_amount", 1))


## Nombre maximal de enemy_id vivants à la fois (generator.max_simultaneous), -1 = illimité.
func max_alive(enemy_id: StringName) -> int:
	var limits: Variant = _generator().get("max_simultaneous", {})
	if limits is Dictionary and (limits as Dictionary).has(enemy_id):
		return int((limits as Dictionary)[enemy_id])
	return -1


## Délai moyen entre deux apparitions de la vague n, avant le tirage : max(min ; base − pas × n).
func spawn_interval(wave: int) -> float:
	var interval := _timing("spawn_interval") - _timing("spawn_interval_per_wave") * wave
	return maxf(_timing("spawn_interval_min"), interval)


func _physics_process(delta: float) -> void:
	if not _running:
		return
	_timer -= delta
	if _phase == Phase.PAUSE:
		if not _player_in_bounds():
			stop()
		elif _timer <= 0.0:
			_begin_wave(_wave + 1)
		return
	if _timer <= 0.0 and not _queue.is_empty() and _spawn_next():
		_timer = spawn_interval(_wave) * _jitter()
	if _queue.is_empty() and _alive.is_empty():
		_clear_wave()


func _begin_wave(wave: int) -> void:
	_wave = wave
	_queue = compose(wave)
	_phase = Phase.SPAWNING
	_timer = _timing("first_spawn_delay")
	EventBus.wave_started.emit(arena_id, wave, _queue.size())


func _clear_wave() -> void:
	var bonus := wave_bonus(_wave)
	_score += bonus
	EventBus.wave_cleared.emit(arena_id, _wave, bonus)
	EventBus.arena_score_changed.emit(arena_id, _score)
	var heal := heal_after(_wave)
	if heal > 0:
		EventBus.player_heal_requested.emit(heal)
	_phase = Phase.PAUSE
	_timer = _timing("wave_pause")


## Fait apparaître le premier ennemi de la file que max_simultaneous autorise ; false si tous
## attendent (le Grand suivant attend que le premier meure).
func _spawn_next() -> bool:
	for index in _queue.size():
		var enemy_id := _queue[index]
		var limit := max_alive(enemy_id)
		if limit >= 0 and _count_alive(enemy_id) >= limit:
			continue
		_queue.remove_at(index)
		_spawn(enemy_id)
		return true
	return false


func _spawn(enemy_id: StringName) -> Enemy:
	var path := "%s/%s.tres" % [ENEMIES_DIR, enemy_id]
	var container := _container()
	if container == null or not ResourceLoader.exists(path):
		push_warning("WaveDirector : impossible de faire apparaître %s" % enemy_id)
		return null
	var enemy := ENEMY_SCENE.instantiate() as Enemy
	enemy.data = load(path) as EnemyData
	enemy.drops_enabled = false
	enemy.always_chase = true
	enemy.speed_multiplier = speed_multiplier(_wave)
	enemy.bonus_hp = hp_bonus(enemy_id, _wave)
	enemy.position = container.to_local(_spawn_position())
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.tree_exiting.connect(_on_enemy_exiting.bind(enemy))
	_alive.append(enemy)
	container.add_child(enemy, true)
	return enemy


## Un point de "spawn_points" (Marker3D frère de l'Arena) au hasard, à SPAWN_SPREAD près ; à
## défaut, un point du cercle juste au-delà des bornes.
func _spawn_position() -> Vector3:
	var arena := get_parent() as Arena
	var names: Array = _config.get("spawn_points", [])
	var marker: Marker3D = null
	if arena != null and not names.is_empty():
		marker = arena.spawn_point(StringName(str(names[_rng.randi() % names.size()])))
	var point := Vector3.ZERO
	if marker != null:
		point = marker.global_position
	elif arena != null:
		var angle := _rng.randf() * TAU
		var ring := Vector3(cos(angle), 0.0, sin(angle)) * (arena.bounds_radius_m + 1.0)
		point = arena.global_position + ring
	var spread := Vector3(_rng.randf_range(-1.0, 1.0), 0.0, _rng.randf_range(-1.0, 1.0))
	return point + spread * SPAWN_SPREAD


## Nœud qui reçoit les ennemis : « Spawned » de l'Arena, sinon le parent.
func _container() -> Node3D:
	var parent := get_parent()
	if parent == null:
		return null
	var spawned := parent.get_node_or_null(^"Spawned") as Node3D
	return spawned if spawned != null else parent as Node3D


func _count_alive(enemy_id: StringName) -> int:
	var total := 0
	for enemy: Enemy in _alive:
		if is_instance_valid(enemy) and enemy.enemy_id() == enemy_id:
			total += 1
	return total


func _player_in_bounds() -> bool:
	var arena := get_parent() as Arena
	var player := get_tree().get_first_node_in_group(PLAYER_GROUP) as Node3D
	return arena == null or player == null or arena.contains(player.global_position)


func _generator() -> Dictionary:
	var generator: Variant = _config.get("generator", {})
	return generator if generator is Dictionary else {}


## "count" du generator : un nombre, ou une expression en n (ex. "3 + 2 * n").
func _generator_count(wave: int) -> int:
	var formula: Variant = _generator().get("count", 0)
	if formula is int or formula is float:
		return maxi(0, int(formula))
	var expression := Expression.new()
	if expression.parse(str(formula), PackedStringArray(["n"])) != OK:
		push_warning("WaveDirector : count invalide (%s)" % formula)
		return 0
	var value: Variant = expression.execute([wave], null, false)
	if expression.has_execute_failed() or not (value is int or value is float):
		return 0
	return maxi(0, int(value))


## Poids du tirage de la vague n : types de poids > 0 dont la vague "min_wave" est atteinte.
func _weights(wave: int) -> Dictionary:
	var generator := _generator()
	var weights: Dictionary = generator.get("weights", {})
	var min_wave: Dictionary = generator.get("min_wave", {})
	var allowed := {}
	for enemy_id: Variant in weights:
		var weight := float(weights[enemy_id])
		if weight > 0.0 and wave >= int(min_wave.get(enemy_id, 1)):
			allowed[StringName(str(enemy_id))] = weight
	return allowed


func _pick(weights: Dictionary, rng: RandomNumberGenerator) -> StringName:
	var total := 0.0
	for enemy_id: StringName in weights:
		total += float(weights[enemy_id])
	var roll := rng.randf() * total
	var picked := &""
	for enemy_id: StringName in weights:
		picked = enemy_id
		roll -= float(weights[enemy_id])
		if roll < 0.0:
			break
	return picked


func _timing(key: String) -> float:
	var timing: Variant = _config.get("timing", {})
	if timing is Dictionary and (timing as Dictionary).has(key):
		return float((timing as Dictionary)[key])
	return float(TIMING_DEFAULTS.get(key, 0.0))


## Facteur aléatoire du délai d'apparition ("timing.spawn_jitter" : [min, max]).
func _jitter() -> float:
	var bounds := DEFAULT_JITTER
	var timing: Variant = _config.get("timing", {})
	if timing is Dictionary:
		var pair: Variant = (timing as Dictionary).get("spawn_jitter")
		if pair is Array and (pair as Array).size() == 2:
			bounds = Vector2(float((pair as Array)[0]), float((pair as Array)[1]))
	return _rng.randf_range(bounds.x, bounds.y)


func _seed() -> int:
	return random_seed if random_seed != 0 else _series_seed


func _play_music() -> void:
	var path := str(_config.get("music", ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	if _music == null:
		_music = AudioStreamPlayer.new()
		add_child(_music)
	_music.stream = load(path) as AudioStream
	_music.play()


func _on_enemy_defeated(enemy: Enemy, points: int) -> void:
	_alive.erase(enemy)
	if _running:
		_score += points
		EventBus.arena_score_changed.emit(arena_id, _score)


func _on_enemy_exiting(enemy: Enemy) -> void:
	_alive.erase(enemy)


func _on_player_died() -> void:
	stop()


## Entrer dans une autre zone que celle de l'arène met fin à la série (fuite vers le village).
func _on_zone_entered(zone_id: StringName) -> void:
	var arena := get_parent() as Arena
	if not _running or arena == null:
		return
	var home := arena.zone_id()
	if not home.is_empty() and zone_id != home:
		stop()
