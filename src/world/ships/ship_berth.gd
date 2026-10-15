class_name ShipBerth
extends Node3D
## (E7) Poste d'amarrage d'un navire dans une carte (le transport de la Garde au port : nœud
## « Berth » de port.tscn, écrit par tools/exterior_recipes/port.py). Il tient le navire (enfant
## Ship), les bras d'ancrage du quai (enfant « Arms » : ShipStrip de la bande mooring_arm_clamp,
## ouverts à l'image 0, refermés à la dernière), la porte du vide devant la passerelle (enfant
## « Gate », StaticBody3D, couche 1, fermée tant que la passerelle n'est pas posée) et la sortie
## « Monter à bord » (exit_path : active seulement navire à quai, passerelle posée et
## embarquement permis). Propriétaire : E7.
##
## Le récit passe par ShipControl (descend, open_hatch, deploy_gangway, depart…) : chaque action
## est une ligne de temps jouée à l'image physique (advance), que les tests avancent d'un coup ;
## finish_now() la termine (séquence passée). L'état durable (à quai, trappe, passerelle,
## embarquement) est dans les drapeaux de GameState (ShipControl.flag) : une carte rechargée
## (sortie, sauvegarde) retrouve le navire comme il était. Les durées viennent de
## data/ships/<ship_id>.json.

## Une action commence, finit.
signal action_started(action: StringName)
signal action_finished(action: StringName)
## Un moment d'une action, pour le son et le récit : landed, clamp, rotors_stopped, hatch_opened,
## gangway_down, gangway_up, released, gone.
signal ship_event(event: StringName)

const GROUP := &"ship_berths"

## Navire tenu (data/ships/<ship_id>.json).
@export var ship_id: StringName = &""
## Sortie « Monter à bord » de la carte (MapExit), active selon l'état.
@export var exit_path: NodePath = ^"../Exits/passerelle"

var _ship: Ship
var _clamps: Array[ShipStrip] = []
var _gate: CollisionObject3D
var _data: Dictionary = {}
var _action: StringName = &""
var _time: float = 0.0
var _duration: float = 0.0
var _events: Dictionary = {}
## Bornes des étapes du départ, fixées à son début (_depart_parts).
var _parts: Array[float] = []


func _ready() -> void:
	add_to_group(GROUP)
	for child: Node in get_children():
		if child is Ship and _ship == null:
			_ship = child as Ship
	var holder := get_node_or_null(^"Arms")
	if holder != null:
		for child: Node in holder.get_children():
			if child is ShipStrip:
				_clamps.append(child as ShipStrip)
	# Les bras se referment de l'arrière vers l'avant : de l'ouest (poupe) vers l'est (proue).
	_clamps.sort_custom(
		func(a: ShipStrip, b: ShipStrip) -> bool: return a.position.x < b.position.x
	)
	_gate = get_node_or_null(^"Gate") as CollisionObject3D
	_data = ShipControl.data(ship_id)
	apply_state()


func _physics_process(delta: float) -> void:
	if _action != &"":
		advance(delta)


## Le navire tenu.
func ship() -> Ship:
	return _ship


## Bras d'ancrage (bandes), de la poupe à la proue.
func clamps() -> Array[ShipStrip]:
	return _clamps


## Action en cours ("" : aucune).
func current_action() -> StringName:
	return _action


func is_busy() -> bool:
	return _action != &""


## Pose le navire comme le disent les drapeaux (à quai ou parti, trappe, passerelle), sans animer.
func apply_state() -> void:
	if _ship == null:
		return
	var docked := ShipControl.is_docked(ship_id)
	_ship.set_present(docked)
	_ship.set_flight(Vector3.ZERO, 0.0)
	_ship.set_rotor_speed(0.0)
	_ship.set_searchlight(0.0)
	_ship.set_hatch(1.0 if docked and ShipControl.has_flag(ship_id, &"hatch") else 0.0)
	_ship.set_gangway(1.0 if docked and ShipControl.has_flag(ship_id, &"gangway") else 0.0)
	for arm in _clamps:
		arm.frame = arm.frames - 1 if docked else 0
	_update_access()


## Lance une action (ShipControl.ACTIONS) ; celle en cours se termine d'abord d'un coup.
func start(action: StringName) -> void:
	if _action != &"":
		finish_now()
	_action = action
	_time = 0.0
	_events.clear()
	_duration = _plan(action)
	action_started.emit(action)
	advance(0.0)


## Avance l'action en cours de delta s (les tests avancent d'un coup).
func advance(delta: float) -> void:
	if _action == &"":
		return
	_time = minf(_time + delta, _duration)
	match _action:
		&"descend":
			_pose_descend(_time)
		&"open_hatch":
			_pose_hatch(_time, true)
		&"close_hatch":
			_pose_hatch(_time, false)
		&"deploy_gangway":
			_pose_gangway(_time, true)
		&"stow_gangway":
			_pose_gangway(_time, false)
		&"depart":
			_pose_depart(_time)
	if _time >= _duration:
		_end()


## Termine l'action en cours d'un coup (séquence passée, changement de carte).
func finish_now() -> void:
	if _action != &"":
		advance(INF)


## Durée de l'action en cours (s).
func duration() -> float:
	return _duration


func elapsed() -> float:
	return _time


# --- Lignes de temps ---------------------------------------------------------------------------


func _num(section: String, key: String, fallback: float) -> float:
	var part: Dictionary = _data.get(section, {})
	return float(part.get(key, fallback))


func _clamp_time() -> float:
	var fps := maxf(_num("mooring", "fps", 6.0), 0.1)
	var frames := _clamps[0].frames if not _clamps.is_empty() else 4
	return float(frames - 1) / fps


func _mooring_time() -> float:
	if _clamps.is_empty():
		return 0.0
	return _num("mooring", "interval", 0.6) * float(_clamps.size() - 1) + _clamp_time()


func _hatch_time() -> float:
	return _num("hatch", "delay", 0.3) + 3.0 / maxf(_num("hatch", "fps", 8.0), 0.1)


func _plan(action: StringName) -> float:
	match action:
		&"descend":
			_ship.set_present(true)
			return _num("descent", "time", 9.0) + _mooring_time() + _num("rotor", "spin_down", 3.0)
		&"open_hatch", &"close_hatch":
			return _hatch_time()
		&"deploy_gangway", &"stow_gangway":
			if action == &"stow_gangway":
				ShipControl.set_flag(ship_id, &"gangway", false)
				_update_access()
			return _num("gangway", "time", 1.6)
		&"depart":
			_parts = _depart_parts()
			ShipControl.set_flag(ship_id, &"gangway", false)
			_update_access()
			return _parts[4]
	return 0.0


## Bornes des étapes du départ : passerelle rentrée, trappe fermée, bras ouverts, rotors lancés,
## fin de la montée.
func _depart_parts() -> Array[float]:
	var gangway := _num("gangway", "time", 1.6) if _ship.gangway_amount() > 0.0 else 0.0
	var hatch := _hatch_time() if _ship.hatch_amount() > 0.0 else 0.0
	var a := gangway
	var b := a + hatch
	var c := b + _mooring_time()
	var d := c + _num("rotor", "spin_up", 1.5)
	var e := d + _num("departure", "time", 8.0)
	return [a, b, c, d, e]


func _event(event: StringName) -> void:
	if not _events.has(event):
		_events[event] = true
		ship_event.emit(event)


func _pose_descend(t: float) -> void:
	var fall := _num("descent", "time", 9.0)
	var height := _num("descent", "height", 18.0)
	var roll := _num("descent", "roll_degrees", 2.0)
	var period := maxf(_num("descent", "roll_period", 3.2), 0.1)
	var full := _num("rotor", "fps", 12.0)
	var u := clampf(t / maxf(fall, 0.01), 0.0, 1.0)
	# La descente ralentit à l'approche ; le roulis s'éteint en fin de course.
	var sway := roll * sin(TAU * t / period) * (1.0 - 0.85 * u)
	_ship.set_flight(Vector3(0.0, height * pow(1.0 - u, 2.0), 0.0), sway)
	# Le projecteur aveugle d'abord (on ne voit pas la forme du navire), puis s'éteint.
	var fade_from := _num("searchlight", "fade_from", 0.35)
	var fade_to := _num("searchlight", "fade_to", 0.85)
	_ship.set_searchlight(1.0 - smoothstep(fade_from, fade_to, u))
	var spin_down := _num("rotor", "spin_down", 3.0)
	var moored := fall + _mooring_time()
	_ship.set_rotor_speed(full * (1.0 - clampf((t - moored) / maxf(spin_down, 0.01), 0.0, 1.0)))
	if u >= 1.0:
		_event(&"landed")
	_pose_clamps(t - fall, true)
	if t >= moored + spin_down:
		_event(&"rotors_stopped")


## Les bras se referment (closing) ou s'ouvrent, l'un après l'autre, t s après le début.
func _pose_clamps(t: float, closing: bool) -> void:
	var interval := _num("mooring", "interval", 0.6)
	var fps := maxf(_num("mooring", "fps", 6.0), 0.1)
	var count := _clamps.size()
	for k in count:
		# Fermeture de la poupe à la proue, ouverture de la proue à la poupe.
		var arm := _clamps[k] if closing else _clamps[count - 1 - k]
		var local := t - interval * float(k)
		var last := arm.frames - 1
		var step := clampi(floori(local * fps), 0, last)
		arm.frame = step if closing else last - step
		if closing and step == last:
			_event(StringName("clamp_%d" % (k + 1)))
	if t >= interval * float(count - 1) + _clamp_time():
		_event(&"moored" if closing else &"released")


func _pose_hatch(t: float, opening: bool) -> void:
	var delay := _num("hatch", "delay", 0.3)
	var fps := maxf(_num("hatch", "fps", 8.0), 0.1)
	var amount := clampf(floorf((t - delay) * fps) / 3.0, 0.0, 1.0) if t >= delay else 0.0
	_ship.set_hatch(amount if opening else 1.0 - amount)


func _pose_gangway(t: float, deploying: bool) -> void:
	var u := clampf(t / maxf(_num("gangway", "time", 1.6), 0.01), 0.0, 1.0)
	_ship.set_gangway(u if deploying else 1.0 - u)


func _pose_depart(t: float) -> void:
	var parts := _parts
	var gangway_time := _num("gangway", "time", 1.6)
	if parts[0] > 0.0:
		_ship.set_gangway(1.0 - clampf(t / gangway_time, 0.0, 1.0))
	if parts[1] > parts[0]:
		_pose_hatch(t - parts[0], false)
	if t >= parts[1]:
		_pose_clamps(t - parts[1], false)
	var full := _num("rotor", "fps", 12.0)
	var spin := clampf((t - parts[2]) / maxf(parts[3] - parts[2], 0.01), 0.0, 1.0)
	_ship.set_rotor_speed(full * spin if t >= parts[2] else 0.0)
	var rise := clampf((t - parts[3]) / maxf(parts[4] - parts[3], 0.01), 0.0, 1.0)
	var height := _num("departure", "height", 22.0)
	var roll := _num("descent", "roll_degrees", 2.0)
	var period := maxf(_num("descent", "roll_period", 3.2), 0.1)
	var sway := roll * sin(TAU * maxf(t - parts[3], 0.0) / period) * rise
	_ship.set_flight(Vector3(0.0, height * rise * rise, 0.0), sway)


func _end() -> void:
	var action := _action
	_action = &""
	match action:
		&"descend":
			ShipControl.set_flag(ship_id, &"docked", true)
		&"open_hatch":
			ShipControl.set_flag(ship_id, &"hatch", true)
			_event(&"hatch_opened")
		&"close_hatch":
			ShipControl.set_flag(ship_id, &"hatch", false)
		&"deploy_gangway":
			ShipControl.set_flag(ship_id, &"gangway", true)
			_event(&"gangway_down")
		&"stow_gangway":
			_event(&"gangway_up")
		&"depart":
			ShipControl.clear(ship_id)
			_event(&"gone")
	apply_state()
	action_finished.emit(action)


## La porte du vide (fermée sauf passerelle posée) et la sortie « Monter à bord » (navire à quai,
## passerelle posée, embarquement permis).
func _update_access() -> void:
	var down := (
		ShipControl.is_docked(ship_id)
		and ShipControl.has_flag(ship_id, &"gangway")
		and _ship != null
		and is_equal_approx(_ship.gangway_amount(), 1.0)
	)
	if _gate != null:
		_gate.collision_layer = 0 if down else 1
	var exit := get_node_or_null(exit_path) as MapExit
	if exit != null:
		var open := down and ShipControl.has_flag(ship_id, &"boarding")
		exit.collision_layer = MapExit.INTERACTABLE_LAYER if open else 0
		exit.monitorable = open
		# Ni invite ni signe d'interaction (interact_signs.gd lit le groupe) tant qu'elle est fermée.
		exit.visible = open
		if open:
			exit.add_to_group(MapExit.INTERACTABLE_GROUP)
		else:
			exit.remove_from_group(MapExit.INTERACTABLE_GROUP)


## La sortie « Monter à bord » est-elle ouverte ?
func boarding_open() -> bool:
	var exit := get_node_or_null(exit_path) as MapExit
	return exit != null and exit.collision_layer != 0


## La porte du vide devant la passerelle est-elle ouverte ?
func gate_open() -> bool:
	return _gate != null and _gate.collision_layer == 0


## Rafraîchit l'accès (embarquement permis ou retiré par le récit).
func refresh_access() -> void:
	_update_access()
