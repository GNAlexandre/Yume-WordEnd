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

## Places de la carte courante (set_map).
var places: LifePlaces = null
## Scène en cours (pour les avertissements).
var scene_label: StringName = &""

var _followers: Dictionary = {}
var _idle_at: Dictionary = {}


## Nouvelle carte : ses places.
func set_map(map: Map) -> void:
	places = LifePlaces.read(map) if map != null else null


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
	_followers.clear()
	_idle_at.clear()


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
func walk_player(target: Vector3, gait: StringName = &"marche") -> void:
	var body := player()
	if body == null:
		return
	var was_held := body.is_story_held()
	body.set_story_hold(true)
	var waypoints := PackedVector3Array()
	var nav := ensure_nav()
	if nav != null and nav.ready:
		waypoints = nav.find_path(body.global_position, target)
	waypoints.append(target)
	var speed := body.run_speed if gait == &"course" else body.walk_speed
	var waited := 0.0
	var index := 0
	while (
		index < waypoints.size() and waited < StoryRunner.WALK_TIMEOUT and is_instance_valid(body)
	):
		var last := index == waypoints.size() - 1
		var toward := waypoints[index] - body.global_position
		toward.y = 0.0
		var reach := StoryRunner.ARRIVE_DISTANCE if last else StoryRunner.PASS_DISTANCE
		if toward.length() <= reach:
			index += 1
			continue
		body.story_drive = toward.normalized() * speed
		await get_tree().physics_frame
		if not get_tree().paused:
			waited += get_physics_process_delta_time()
	if not is_instance_valid(body):
		return
	body.story_drive = Vector3.ZERO
	if index < waypoints.size():
		place_player(target)
	body.set_story_hold(was_held)


## La navigation de la carte courante, construite tout de suite au besoin (null sans carte).
func ensure_nav() -> LifeNav:
	if LifeDirector.current_map() == null:
		return null
	if LifeDirector.nav() == null or not LifeDirector.nav().ready:
		LifeDirector.build_nav_now()
	return LifeDirector.nav()


## Un PNJ suit le joueur à distance m (il s'arrête au-delà de stop_beyond m : sans lumière, il
## ne voit rien) jusqu'à unfollow ou la fin de la scène, d'une carte à l'autre.
func add_follower(
	npc_id: StringName, distance: float, stop_beyond: float, gait: StringName
) -> void:
	_followers[npc_id] = {"distance": distance, "stop_beyond": stop_beyond, "gait": gait}
	ensure_nav()


func remove_follower(npc_id: StringName) -> void:
	_followers.erase(npc_id)


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
		var settings: Dictionary = _followers[npc_id]
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
		LifeDirector.stage(npc_id, at, -back)
		rank += 1
	ensure_nav()


func _grounded(point: Vector3) -> Vector3:
	var body := player()
	return WorldManager.ground_position(point + Vector3.UP * 0.5, body) if body != null else point
