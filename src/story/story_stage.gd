class_name StoryStage
extends Node
## (E6) La scène du récit, côté monde : enfant « Stage » de StoryDirector, les outils dont
## StoryRunner mène ses étapes. Propriétaire : E6.
##
## - Les points d'une scène (resolve) : [x, z] posé sur le sol de la carte, « player », un PNJ
##   présent, une place (Life/Places : son premier point) ou un marqueur (Markers), avec un
##   décalage [dx, dz] (est, sud) ; les directions (direction : north, south, east, west, ou vers
##   un point).
## - Le joueur : posé (place_player), mené à pied par un chemin de la navigation avec la vraie
##   physique (walk_player), contrôle pris ou rendu (set_control) ; sa caméra (camera_rig).
## - Le voile des scènes (overlay, fade_overlay, wait_overlay : attentes par sondage, jamais une
##   coroutine d'un nœud de l'interface, qui peut être libéré en pleine scène).
## - Les suiveurs (add_follower : un PNJ suit le joueur à distance, s'arrête s'il est trop loin,
##   reparaît derrière lui après un changement de carte : restage_followers) et les remises au
##   repos différées (idle_later).
## - Les portes fermées jusqu'à un jour (apply_doors) : une sortie de carte (MapExit) qui porte
##   les métadonnées open_from_day (jour d'ouverture) et closed_text_key (« village/maison_close » :
##   le texte de data/texts/village.json, Examinable.lookup) ne mène nulle part avant ce jour ; à sa
##   place, une zone à examiner (enfant ClosedDoor, même invite) lit le texte de la porte close.

## Joueur mené coincé : après STUCK_NUDGE s, des pas de côté ; après STUCK_HOP s, posé au
## point de passage.
const STUCK_NUDGE := 0.4
const STUCK_HOP := 1.6

## Métadonnées d'une sortie fermée jusqu'à un jour ; enfant qui la remplace.
const DOOR_OPEN_META := &"open_from_day"
const DOOR_TEXT_META := &"closed_text_key"
const CLOSED_DOOR := &"ClosedDoor"
const TEXTS_DIR := "res://data/texts/"
## (S2) Pose sans durée (jusqu'à la suivante) : une heure ; portée de la lueur au-delà du cercle.
const POSE_HOLD := 3600.0
const PROPS_LIGHT_REACH := 2.5

## Places de la carte courante (set_map).
var places: LifePlaces = null
## Scène en cours (pour les avertissements).
var scene_label: StringName = &""
## (X-L0) Portes fermées jusqu'à leur jour (mode scénarisé) ; faux : toutes ouvertes (libre,
## StoryPacing.doors_by_day, posé par StoryDirector).
var doors_by_day: bool = true

var _followers: Dictionary = {}
var _idle_at: Dictionary = {}
## (S2) Protagoniste cachée, pose tenue par la scène, images posées (id → nœud de la carte).
var _player_hidden: bool = false
var _posing: bool = false
var _props: Dictionary = {}


## Nouvelle carte : ses places, ses portes fermées.
func set_map(map: Map) -> void:
	places = LifePlaces.read(map) if map != null else null
	apply_doors(map)


## Ferme (avant leur jour, GameState.day) ou rouvre les sorties de map qui portent
## open_from_day ; renvoie le nombre de portes fermées. (X-L0) Sans doors_by_day, les rouvre
## toutes.
func apply_doors(map: Node) -> int:
	var exits := map.get_node_or_null(^"Exits") if map != null else null
	if exits == null:
		return 0
	var closed := 0
	for child: Node in exits.get_children():
		var door := child as MapExit
		if door == null or not door.has_meta(DOOR_OPEN_META):
			continue
		var shut := doors_by_day and GameState.day < int(door.get_meta(DOOR_OPEN_META))
		_set_door_closed(door, shut)
		closed += 1 if shut else 0
	return closed


func _set_door_closed(door: MapExit, shut: bool) -> void:
	var lock := door.get_node_or_null(NodePath(CLOSED_DOOR)) as Examinable
	if shut == (lock != null):
		return
	door.set_deferred(&"monitoring", not shut)
	if door.needs_interaction():
		door.collision_layer = 0 if shut else MapExit.INTERACTABLE_LAYER
		if shut:
			door.remove_from_group(MapExit.INTERACTABLE_GROUP)
		else:
			door.add_to_group(MapExit.INTERACTABLE_GROUP)
	if not shut:
		door.remove_child(lock)
		lock.queue_free()
		return
	var key := str(door.get_meta(DOOR_TEXT_META, ""))
	lock = Examinable.new()
	lock.name = CLOSED_DOOR
	lock.text_key = key
	lock.texts_path = TEXTS_DIR + key.get_slice("/", 0) + ".json"
	lock.prompt = door.prompt
	var holder := door.get_node_or_null(^"CollisionShape3D") as CollisionShape3D
	var box := holder.shape as BoxShape3D if holder != null else null
	if box != null:
		lock.size = box.size
		lock.position = holder.position - Vector3(0.0, box.size.y / 2.0, 0.0)
	door.add_child(lock)


## Une image physique : remises au repos, suiveurs.
func tick(delta: float) -> void:
	_serve_idles(delta)
	_tick_followers()


## Vrai si le joueur est à moins de radius m (au sol) du point spec (resolve).
func player_within(spec: Variant, radius: float) -> bool:
	var body := player()
	if body == null:
		return false
	var at := resolve(spec).origin
	return Vector2(at.x - body.global_position.x, at.z - body.global_position.z).length() <= radius


## Plus de suiveur ni de remise au repos (fin de scène, nouvelle partie).
func clear() -> void:
	for npc_id: StringName in followers():
		remove_follower(npc_id)
	_followers.clear()
	_idle_at.clear()
	if _player_hidden:
		set_player_visible(true)
	release_player_pose()
	clear_props()


## (S2) Cache (false) ou montre la protagoniste (son visuel et son ombre ; le corps reste).
func set_player_visible(on: bool) -> void:
	_player_hidden = not on
	var body := player()
	var visual := body.get_node_or_null(^"Visual") as Node3D if body != null else null
	if visual != null:
		visual.visible = on


## (S2) Vrai si la scène a caché la protagoniste.
func is_player_hidden() -> bool:
	return _player_hidden


## (S2) Tient une pose du joueur (Player.hold_pose) seconds s, ou jusqu'à la pose suivante, une
## marche, le contrôle rendu ou la fin de la scène (0) ; « repos » la relâche.
func hold_player_pose(anim: StringName, seconds: float) -> void:
	var body := player()
	if body == null:
		return
	if anim == StoryRunner.IDLE:
		release_player_pose()
		return
	_posing = seconds <= 0.0
	body.hold_pose(anim, seconds if seconds > 0.0 else POSE_HOLD)


## (S2) Relâche la pose tenue par la scène.
func release_player_pose() -> void:
	var body := player()
	if _posing and body != null:
		body.hold_pose(StoryRunner.IDLE, 0.0)
	_posing = false


## (S2) Pose count images animées (texture : une bande de frames images à fps) sur un cercle de
## radius m autour de at, à lift m du sol, et une lueur (OmniLight3D d'énergie light, color) au
## centre ; sous la carte courante (parties avec elle), jusqu'à clear_props(id).
func add_props(id: StringName, texture: Texture2D, at: Vector3, options: Dictionary) -> Node3D:
	var map := WorldManager.current_map_node()
	if map == null or texture == null:
		return null
	var holder := Node3D.new()
	holder.name = "StoryProps_%s" % id
	map.add_child(holder)
	holder.global_position = at
	var count := maxi(int(options.get("count", 1)), 1)
	var radius := float(options.get("radius", 0.0))
	var lift := float(options.get("lift", 0.0))
	for index: int in count:
		var panel := DecorPanel.new()
		panel.name = "Prop_%d" % index
		panel.texture = texture
		panel.frames = maxi(int(options.get("frames", 1)), 1)
		panel.fps = float(options.get("fps", 0.0))
		panel.soft_alpha = true
		panel.shadow_width = 0.0
		var angle := TAU * float(index) / float(count)
		panel.position = Vector3(cos(angle) * radius, lift, sin(angle) * radius)
		holder.add_child(panel)
	var energy := float(options.get("light", 0.0))
	if energy > 0.0:
		var glow := OmniLight3D.new()
		glow.name = "Glow"
		glow.light_color = options.get("color", Color.WHITE)
		glow.light_energy = energy
		glow.omni_range = radius + PROPS_LIGHT_REACH
		glow.shadow_enabled = false
		glow.position = Vector3(0.0, lift + 0.3, 0.0)
		holder.add_child(glow)
	_props[id] = holder
	return holder


## (S2) Retire les images posées sous id (vide : toutes).
func clear_props(id: StringName = &"") -> void:
	for key: StringName in _props.keys():
		if id.is_empty() or key == id:
			var holder: Node = _props[key]
			if is_instance_valid(holder):
				holder.queue_free()
			_props.erase(key)


## (S2) Nœud des images posées sous id (null : aucune).
func props(id: StringName) -> Node3D:
	var holder: Node3D = _props.get(id)
	return holder if is_instance_valid(holder) else null


## Le joueur (null sans partie).
func player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


## La caméra du joueur (null sans partie).
func camera_rig() -> Node:
	var body := player()
	return body.get_node_or_null(^"CameraRig") if body != null else null


## Le voile des scènes (HUD/StoryOverlay ; null sans partie).
func overlay() -> Node:
	return get_tree().get_first_node_in_group(&"story_overlay")


## Fondu du voile (couleur, opacité, durée) et son attente ; coroutine.
func fade_overlay(color: Color, alpha: float, time: float) -> void:
	var overlay_node := overlay()
	if overlay_node != null:
		overlay_node.call(&"fade_to", color, alpha, time)
	await wait_overlay()


## Attend la fin du fondu ou du carton du voile (coroutine) ; s'arrête si le voile disparaît ou
## si stop_when devient vrai (le voile est alors posé tout de suite).
func wait_overlay(stop_when: Callable = Callable()) -> void:
	var overlay_node := overlay()
	while is_instance_valid(overlay_node) and overlay_node.is_inside_tree():
		if not bool(overlay_node.call(&"is_busy")):
			return
		if stop_when.is_valid() and bool(stop_when.call()):
			return
		await get_tree().process_frame


## Rend (true) ou prend (false) le contrôle au joueur.
func set_control(on: bool) -> void:
	var body := player()
	if on:
		release_player_pose()
	if body != null:
		body.set_story_hold(not on)


## Point d'une scène dans le monde : [x, z] (sur le sol de la carte), « player », un PNJ présent,
## une place (Life/Places, son premier point) ou un marqueur (Markers) ; offset [dx, dz] ajouté
## (est, sud). Regard : le −Z de la place ou du marqueur, sinon le nord.
func resolve(spec: Variant, offset: Variant = null) -> Transform3D:
	var map := WorldManager.current_map_node()
	var body := player()
	var at := Transform3D.IDENTITY
	if spec is Array and (spec as Array).size() == 2:
		var origin := map.global_position if map != null else Vector3.ZERO
		at.origin = origin + Vector3(float(spec[0]), 0.0, float(spec[1]))
		at.origin = _grounded(at.origin)
	elif spec is String or spec is StringName:
		var name_id := StringName(str(spec))
		var actor := LifeDirector.actor(name_id)
		if name_id == StoryData.PLAYER and body != null:
			at.origin = body.global_position
		elif actor != null:
			at.origin = actor.position()
		elif places != null and places.has(name_id):
			at = places.point(name_id, 0)
		elif map != null and map.marker(name_id) != null:
			at = map.marker(name_id).global_transform
			at.origin = _grounded(at.origin)
		else:
			push_warning("StoryStage : place inconnue %s (%s)" % [name_id, scene_label])
			at.origin = body.global_position if body != null else Vector3.ZERO
	if offset is Array and (offset as Array).size() == 2:
		at.origin = _grounded(at.origin + Vector3(float(offset[0]), 0.0, float(offset[1])))
	return at


## Direction au sol : north, south, east, west, ou vers un point (resolve) depuis from.
func direction(spec: Variant, from: Vector3) -> Vector3:
	if spec == null:
		return Vector3.ZERO
	if StoryData.DIRECTIONS.has(str(spec)):
		return StoryData.DIRECTIONS[str(spec)]
	var toward := resolve(spec).origin - from
	toward.y = 0.0
	return toward.normalized() if toward.length_squared() > 0.0001 else Vector3.ZERO


## Pose le joueur en at (Vector3.INF : sur place) tourné vers facing (ZERO : inchangé).
func place_player(at: Vector3, facing: Vector3 = Vector3.ZERO) -> void:
	var body := player()
	if body == null:
		return
	if at != Vector3.INF:
		body.global_position = WorldManager.ground_position(at, body)
		body.velocity = Vector3.ZERO
		body.reset_physics_interpolation()
	if facing != Vector3.ZERO:
		body.set_aim_direction(facing, at != Vector3.INF)


## Mène le joueur à pied jusqu'à target (chemin de la navigation, vraie physique) ; coroutine.
## (X-L2) stop_when devient vrai (scène passée) : la marche cesse, le joueur est posé au but.
func walk_player(
	target: Vector3, gait: StringName = &"marche", stop_when: Callable = Callable()
) -> void:
	var body := player()
	if body == null:
		return
	var was_held := body.is_story_held()
	body.set_story_hold(true)
	var waypoints := PackedVector3Array()
	var nav := ensure_nav()
	if nav != null and nav.ready:
		waypoints = route(body.global_position, nav.find_path(body.global_position, target))
	waypoints.append(target)
	var speed := body.run_speed if gait == &"course" else body.walk_speed
	var waited := 0.0
	var stuck := 0.0
	var index := 0
	while (
		index < waypoints.size()
		and waited < StoryRunner.WALK_TIMEOUT
		and is_instance_valid(body)
		and not (stop_when.is_valid() and bool(stop_when.call()))
	):
		var last := index == waypoints.size() - 1
		var toward := waypoints[index] - body.global_position
		toward.y = 0.0
		var reach := StoryRunner.ARRIVE_DISTANCE if last else StoryRunner.PASS_DISTANCE
		if toward.length() <= reach:
			index += 1
			continue
		var heading := toward.normalized()
		if stuck > STUCK_NUDGE:
			# Coincé contre un angle (montant de porte, meuble) : un pas de côté vers le chemin.
			var side := Vector3(-heading.z, 0.0, heading.x)
			heading = (
				(heading * 0.4 + side * (1.0 if int(stuck * 2.0) % 2 == 0 else -1.0)).normalized()
			)
		body.story_drive = heading * speed
		var before := body.global_position
		await get_tree().physics_frame
		if not is_instance_valid(body):
			return
		if not get_tree().paused:
			var step := get_physics_process_delta_time()
			waited += step
			var moved := Vector2(
				body.global_position.x - before.x, body.global_position.z - before.z
			)
			stuck = stuck + step if moved.length() < speed * step * 0.25 else 0.0
			if stuck > STUCK_HOP:
				# Toujours coincé : la scène pose le joueur au point de passage (sans contrôle).
				place_player(waypoints[index])
				stuck = 0.0
	if not is_instance_valid(body):
		return
	body.story_drive = Vector3.ZERO
	if index < waypoints.size():
		place_player(target)
	body.set_story_hold(was_held)


## Chemin praticable par le joueur (vraie physique) à partir d'un chemin de la navigation :
## points écartés des murs (clear_point) et, dedans, chaque passage d'une pièce à l'autre
## franchi par le milieu de la porte (le chemin lissé des PNJ frôle les montants).
func route(start: Vector3, path: PackedVector3Array) -> PackedVector3Array:
	var result := PackedVector3Array()
	var map := WorldManager.current_map_node()
	var room := map.get_node_or_null(^"Ground") as InteriorRoom if map != null else null
	var previous := start
	for point: Vector3 in path:
		if room != null and room.plan != null:
			result.append_array(_door_crossing(room, previous, point))
		result.append(clear_point(point))
		previous = point
	return result


func _door_crossing(room: InteriorRoom, from: Vector3, to: Vector3) -> PackedVector3Array:
	var crossing := PackedVector3Array()
	var local_from := room.to_local(from)
	var local_to := room.to_local(to)
	var room_from := room.room_at(local_from.x, local_from.z)
	var room_to := room.room_at(local_to.x, local_to.z)
	if room_from == room_to or room_from.is_empty() or room_to.is_empty():
		return crossing
	for door: Dictionary in room.plan.doors:
		if not door.has("axis") or not door.has("line"):
			continue
		var center := InteriorLayout.opening_center(door)
		var across := (
			Vector3.BACK if int(door["axis"]) == InteriorRoom.HORIZONTAL else Vector3.RIGHT
		)
		var before := center - across * 0.5
		var after := center + across * 0.5
		var pair := [room.room_at(before.x, before.z), room.room_at(after.x, after.z)]
		if not (pair.has(room_from) and pair.has(room_to)):
			continue
		if pair[0] != room_from:
			across = -across
		crossing.append(room.to_global(center - across * 0.7))
		crossing.append(room.to_global(center + across * 0.7))
		return crossing
	return crossing


## Un point de passage où le corps du joueur tient sans toucher un mur ni un meuble (la
## navigation des PNJ, sans physique, frôle les murs d'un quart de case ; le joueur, plus
## large, s'y accrocherait) : le point lui-même, sinon le plus proche libre à 0,25 ou 0,5 m.
func clear_point(point: Vector3) -> Vector3:
	var body := player()
	if body == null or not body.is_inside_tree():
		return point
	var space := body.get_world_3d().direct_space_state
	var shape := SphereShape3D.new()
	shape.radius = 0.45
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 1
	for reach: float in [0.0, 0.25, 0.5]:
		for degrees: float in [0.0, 90.0, 180.0, 270.0, 45.0, 135.0, 225.0, 315.0]:
			var candidate := (
				point + Vector3.FORWARD.rotated(Vector3.UP, deg_to_rad(degrees)) * reach
			)
			query.transform = Transform3D(Basis.IDENTITY, candidate + Vector3.UP * 0.9)
			var blocked := false
			for hit: Dictionary in space.intersect_shape(query, 8):
				if hit["collider"] is StaticBody3D:
					blocked = true
					break
			if not blocked:
				return candidate
			if reach == 0.0:
				break
	return point


## La navigation de la carte courante, construite tout de suite au besoin (null sans carte).
func ensure_nav() -> LifeNav:
	if LifeDirector.current_map() == null:
		return null
	if LifeDirector.nav() == null or not LifeDirector.nav().ready:
		LifeDirector.build_nav_now()
	return LifeDirector.nav()


## Un PNJ suit le joueur à distance m, sans le gêner (corps hors de la couche 1) ; il s'arrête
## au-delà de stop_beyond m (sans lumière, il ne voit rien) ; jusqu'à unfollow ou la fin de la
## scène, d'une carte à l'autre.
func add_follower(
	npc_id: StringName, distance: float, stop_beyond: float, gait: StringName
) -> void:
	_followers[npc_id] = {"distance": distance, "stop_beyond": stop_beyond, "gait": gait}
	ensure_nav()


func remove_follower(npc_id: StringName) -> void:
	_followers.erase(npc_id)
	var actor := LifeDirector.actor(npc_id)
	if actor != null and is_instance_valid(actor.npc) and not actor.is_moving():
		actor.npc.set_moving(false)


## Suiveurs en cours (ids).
func followers() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_followers.keys())
	return ids


## Remet un PNJ au repos dans seconds s (étape anim avec durée, sans attente).
func idle_later(npc_id: StringName, seconds: float) -> void:
	_idle_at[npc_id] = seconds


func _serve_idles(delta: float) -> void:
	for npc_id: StringName in _idle_at.keys():
		_idle_at[npc_id] = float(_idle_at[npc_id]) - delta
		if float(_idle_at[npc_id]) <= 0.0:
			_idle_at.erase(npc_id)
			var actor := LifeDirector.actor(npc_id)
			if actor != null:
				actor.play(&"repos")


func _tick_followers() -> void:
	var body := player()
	if body == null or _followers.is_empty() or WorldManager.is_transitioning():
		return
	for npc_id: StringName in _followers:
		var actor := LifeDirector.actor(npc_id)
		if actor == null or not is_instance_valid(actor.npc):
			continue
		# Un suiveur ne barre jamais le passage au joueur (corps hors de la couche 1).
		actor.npc.set_moving(true)
		var settings: Dictionary = _followers[npc_id]
		# Sa tenue, qu'il garde d'une carte à l'autre (restage_followers).
		settings["outfit"] = actor.outfit
		var keep: float = settings["distance"]
		var offset := actor.position() - body.global_position
		offset.y = 0.0
		var distance := offset.length()
		if distance > float(settings["stop_beyond"]):
			if actor.is_moving():
				actor.stop()
				actor.play(&"repos")
			actor.face(-offset)
		elif distance > keep + 0.8:
			var goal := body.global_position + offset.normalized() * keep
			if not actor.is_moving() or actor.goal().distance_to(goal) > 1.2:
				actor.walk_to(goal, -offset, settings["gait"], Callable())
		elif not actor.is_moving():
			actor.face(-offset)


## Après un changement de carte en pleine scène : les suiveurs reparaissent derrière le joueur.
func restage_followers() -> void:
	var body := player()
	if body == null:
		return
	var back := -body.aim_direction()
	var rank := 1
	for npc_id: StringName in _followers:
		var settings: Dictionary = _followers[npc_id]
		var at := _grounded(body.global_position + back * float(settings["distance"]) * rank)
		var actor := LifeDirector.stage(npc_id, at, -back)
		var outfit := StringName(settings.get("outfit", &""))
		if actor != null and not outfit.is_empty() and is_instance_valid(actor.npc):
			actor.outfit = outfit
			actor.npc.set_outfit(actor.data.load_outfit(outfit))
		rank += 1
	ensure_nav()


func _grounded(point: Vector3) -> Vector3:
	var body := player()
	return WorldManager.ground_position(point + Vector3.UP * 0.5, body) if body != null else point
