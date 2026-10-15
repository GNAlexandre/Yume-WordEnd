class_name GameBall
extends Node3D
## (E8) Le ballon des petites : une balle physique simple, faite à la main (pas de RigidBody3D :
## les résultats ne dépendent ni du moteur physique ni de la plateforme, donc identiques dans le
## navigateur, et le jeu peut la faire avancer plus vite que le temps réel dans les tests).
## Propriétaire : E8. Chiffres : data/games/ballon.json, section « ball ».
##
## - Un sol (ground_y : la hauteur du terrain), une hauteur au-dessus de lui (height), une vitesse
##   au sol (velocity : x, z) et une vitesse verticale (vertical_speed). Pesanteur ; rebond sur le
##   sol (le rebond s'éteint sous rest_bounce_speed), puis roulement qui freine (roll_friction).
## - Des murs : un rectangle (walls) où la balle rebondit (wall_bounce), percé de buts (goals) :
##   une ouverture sur le mur nord ou sud, de largeur et de hauteur données, avec un fond ; la
##   balle qui passe la ligne dans l'ouverture, sous la barre, émet entered_goal. Au-dessus de la
##   barre, elle rebondit comme sur un mur.
## - Frappes : kick(direction, vitesse, lift) (le pied d'une petite ou du joueur) ; launch_to(point,
##   durée) (le ballon envoyé haut à deux mains : il retombe au point voulu).
## - Image : le panneau du ballon (assets/hd2d/props/ball.png, 32 px = 0,33 m) debout sur son
##   ancre, et une ombre au sol qui reste sur le terrain pendant que la balle monte.
## La balle ne se fait pas avancer toute seule tant que auto_step est faux : le jeu appelle step().

## La balle a touché le sol (vitesse verticale d'impact, m/s).
signal bounced(impact_speed: float)
## La balle a heurté un mur : côté (&"west", &"east", &"north", &"south"), point (x, z).
signal wall_hit(side: StringName, at: Vector3, speed: float)
## La balle est entrée dans un but (id du but).
signal entered_goal(goal_id: StringName)
## La balle a été frappée (par qui : l'id de celui qui frappe, &"" sinon).
signal kicked(by: StringName)

## Image du ballon du jeu : une balle claire, lisible sur l'herbe sèche (chiffres : ball/image,
## ball/size_m, ball/shadow_radius de data/games/ballon.json).
const DEFAULT_IMAGE := "res://assets/hd2d/interior/props/ball_white.png"
## Image du ballon posé dans le décor (assets/hd2d/props/ball.png) : voir hide_decor_ball().
const DECOR_IMAGE := "res://assets/hd2d/props/ball.png"
const MAX_SUBSTEP := 1.0 / 120.0
## Vitesse horizontale (m/s) sous laquelle la balle qui roule s'arrête.
const STOP_SPEED := 0.12
## Frottement des filets, en multiples de celui de l'herbe.
const NET_DRAG := 3.0

## La balle se fait avancer toute seule à chaque image physique (un ballon seul, une démonstration).
@export var auto_step: bool = false
## Hauteur du terrain (m).
var ground_y: float = 0.0
## Hauteur de la balle au-dessus du sol (m).
var height: float = 0.0
## Vitesse au sol (x, z ; y reste nul) et vitesse verticale (m/s).
var velocity: Vector3 = Vector3.ZERO
var vertical_speed: float = 0.0
## Murs : rectangle (x, z) où la balle reste ; Rect2() : pas de mur.
var walls: Rect2 = Rect2()
## Buts : [{id, side (&"north" ou &"south"), x_min, x_max, height, depth}] : ouverture dans le mur
## de ce côté.
var goals: Array[Dictionary] = []
## Dernier à l'avoir frappée.
var last_kicker: StringName = &""
## But où la balle se trouve (id), &"" sinon.
var in_goal: StringName = &""

var gravity: float = 9.8
var bounce: float = 0.62
var rest_bounce_speed: float = 0.9
var bounce_slowdown: float = 0.9
var roll_friction: float = 1.4
var wall_bounce: float = 0.55
var goal_back_bounce: float = 0.25
var max_speed: float = 13.0

var _image: Node3D
var _overrides: Dictionary = {}
var _shadow: MeshInstance3D


func _init() -> void:
	name = "Ball"


func _ready() -> void:
	set_physics_process(auto_step)
	_build()
	_sync()


func _physics_process(delta: float) -> void:
	step(delta)


## Retire du décor fondu de la carte (PropBatcher) les ballons posés à moins de radius m de near :
## le plan du champ de l'entrepôt pose un ballon décoratif au rond central, que le ballon du jeu
## remplace (sans cela, il resterait au centre pendant que l'autre roule). N'agit que sur la
## carte instanciée (elle revient telle quelle au rechargement) ; renvoie le nombre de triangles
## retirés. Demande faite au plan des cartes : docs/CONTRACT_REQUESTS.md, « E8 ».
static func hide_decor_ball(map: Node3D, near: Vector3, radius: float = 0.6) -> int:
	var removed := 0
	for node: Node in map.find_children("*", "MeshInstance3D", true, false):
		var instance := node as MeshInstance3D
		var material := instance.material_override as ShaderMaterial if instance != null else null
		if material == null or instance.mesh == null or instance.mesh.get_surface_count() != 1:
			continue
		var image := material.get_shader_parameter(&"albedo_texture") as Texture2D
		if image == null or image.resource_path != DECOR_IMAGE:
			continue
		var arrays := instance.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		if arrays[Mesh.ARRAY_INDEX] != null or vertices.size() % 3 != 0:
			continue
		var keep := PackedInt32Array()
		for first: int in range(0, vertices.size(), 3):
			var middle := (vertices[first] + vertices[first + 1] + vertices[first + 2]) / 3.0
			var at := instance.to_global(middle)
			if Vector2(at.x - near.x, at.z - near.z).length() < radius:
				removed += 1
			else:
				keep.append_array(PackedInt32Array([first, first + 1, first + 2]))
		if keep.size() == vertices.size():
			continue
		var rebuilt := []
		rebuilt.resize(Mesh.ARRAY_MAX)
		for slot: int in [
			Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_TEX_UV, Mesh.ARRAY_TEX_UV2
		]:
			var column: Variant = arrays[slot]
			if column == null or column.size() != vertices.size():
				continue
			var picked: Variant = column.duplicate()
			picked.resize(keep.size())
			for i: int in keep.size():
				picked[i] = column[keep[i]]
			rebuilt[slot] = picked
		var mesh := ArrayMesh.new()
		if keep.size() > 0:
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, rebuilt)
		instance.mesh = mesh if keep.size() > 0 else null
	return removed


## Lit les chiffres de la section « ball » des règles du ballon (overrides : surcharges).
func configure(overrides: Dictionary = {}) -> void:
	_overrides = overrides
	gravity = GameRules.number(&"ballon", "ball/gravity", gravity, overrides)
	bounce = GameRules.number(&"ballon", "ball/bounce", bounce, overrides)
	rest_bounce_speed = GameRules.number(
		&"ballon", "ball/rest_bounce_speed", rest_bounce_speed, overrides
	)
	bounce_slowdown = GameRules.number(
		&"ballon", "ball/bounce_slowdown", bounce_slowdown, overrides
	)
	roll_friction = GameRules.number(&"ballon", "ball/roll_friction", roll_friction, overrides)
	wall_bounce = GameRules.number(&"ballon", "ball/wall_bounce", wall_bounce, overrides)
	goal_back_bounce = GameRules.number(
		&"ballon", "ball/goal_back_bounce", goal_back_bounce, overrides
	)
	max_speed = GameRules.number(&"ballon", "ball/max_speed", max_speed, overrides)


## Pose la balle au sol en `at` (x, z ; la hauteur du terrain est ground_y), immobile.
func place(at: Vector3) -> void:
	position.x = at.x
	position.z = at.z
	height = 0.0
	velocity = Vector3.ZERO
	vertical_speed = 0.0
	in_goal = &""
	_sync()


## Position de la balle au sol (x, ground_y, z).
func ground_position() -> Vector3:
	return Vector3(position.x, ground_y, position.z)


## Vitesse horizontale (m/s).
func speed() -> float:
	return velocity.length()


## Vrai si la balle bouge (roule, rebondit, vole).
func is_moving() -> bool:
	return velocity.length() > STOP_SPEED or height > 0.01 or absf(vertical_speed) > 0.05


## Frappe : part dans la direction (au sol) à speed m/s, lift m/s vers le haut.
func kick(direction: Vector3, speed_value: float, lift: float = 0.0, by: StringName = &"") -> void:
	var flat := Vector3(direction.x, 0.0, direction.z)
	if flat.length_squared() < 0.0001:
		return
	velocity = flat.normalized() * minf(speed_value, max_speed)
	vertical_speed = lift
	last_kicker = by
	kicked.emit(by)


## Envoyée en cloche : retombe en `target` (x, z) au bout de flight_time s (le ballon lancé haut
## à deux mains, qui retombe au hasard). Sans frottement de l'air, la chute est exacte.
func launch_to(target: Vector3, flight_time: float, by: StringName = &"") -> void:
	var time := maxf(flight_time, 0.2)
	velocity = Vector3((target.x - position.x) / time, 0.0, (target.z - position.z) / time)
	velocity = velocity.limit_length(max_speed)
	vertical_speed = gravity * time * 0.5
	last_kicker = by
	kicked.emit(by)


## Où sera la balle (x, ground_y, z) dans t s si elle roule : sert à courir vers elle.
func predict(seconds: float) -> Vector3:
	var speed_now := velocity.length()
	if speed_now < STOP_SPEED:
		return ground_position()
	var stop_time := speed_now / maxf(roll_friction, 0.01)
	var time := minf(seconds, stop_time)
	var travelled := speed_now * time - 0.5 * roll_friction * time * time
	var at := ground_position() + velocity.normalized() * travelled
	if walls.has_area():
		at.x = clampf(at.x, walls.position.x, walls.end.x)
		at.z = clampf(at.z, walls.position.y, walls.end.y)
	return at


## Fait avancer la balle de delta s (en petits pas, pour que les rebonds restent justes).
func step(delta: float) -> void:
	var count := maxi(1, ceili(delta / MAX_SUBSTEP))
	var sub := delta / count
	for _i: int in count:
		_substep(sub)
	_sync()


func _substep(dt: float) -> void:
	var flying := height > 0.0 or vertical_speed > 0.0
	if flying:
		vertical_speed -= gravity * dt
		height += vertical_speed * dt
		if height <= 0.0:
			height = 0.0
			var impact := -vertical_speed
			if impact > rest_bounce_speed:
				vertical_speed = impact * bounce
				velocity *= bounce_slowdown
				bounced.emit(impact)
			else:
				vertical_speed = 0.0
	else:
		var now := velocity.length()
		if now > 0.0:
			# Les filets freinent trois fois plus que l'herbe.
			var drag := roll_friction * (NET_DRAG if in_goal != &"" else 1.0)
			var slower := maxf(now - drag * dt, 0.0)
			velocity = velocity * (slower / now) if slower > STOP_SPEED * 0.5 else Vector3.ZERO
	position.x += velocity.x * dt
	position.z += velocity.z * dt
	_collide()


func _collide() -> void:
	if not walls.has_area():
		return
	var west := walls.position.x
	var east := walls.end.x
	var north := walls.position.y
	var south := walls.end.y
	if position.x < west:
		_bounce_wall(&"west", Vector2(west, position.z))
	elif position.x > east:
		_bounce_wall(&"east", Vector2(east, position.z))
	for goal: Dictionary in goals:
		_collide_goal(goal)
	if _inside_goal():
		return
	if position.z < north:
		_bounce_wall(&"north", Vector2(position.x, north))
	elif position.z > south:
		_bounce_wall(&"south", Vector2(position.x, south))


## Le but : ouverture de l'un des murs nord ou sud ; passé la ligne, la balle est dans les filets.
func _collide_goal(goal: Dictionary) -> void:
	var north_side: bool = goal["side"] == &"north"
	var line: float = walls.position.y if north_side else walls.end.y
	var depth := float(goal["depth"])
	var inward := -1.0 if north_side else 1.0
	var beyond := (position.z - line) * inward
	var in_mouth: bool = position.x >= float(goal["x_min"]) and position.x <= float(goal["x_max"])
	var under_bar: bool = height < float(goal["height"])
	if in_goal == goal["id"]:
		# Dans les filets : côtés et fond.
		if position.x < float(goal["x_min"]):
			position.x = float(goal["x_min"])
			velocity.x = absf(velocity.x) * goal_back_bounce
		elif position.x > float(goal["x_max"]):
			position.x = float(goal["x_max"])
			velocity.x = -absf(velocity.x) * goal_back_bounce
		if beyond > depth:
			position.z = line + inward * depth
			velocity.z = -velocity.z * goal_back_bounce
		elif beyond < 0.0:
			in_goal = &""
		return
	if beyond > 0.0 and in_mouth and under_bar:
		in_goal = goal["id"]
		entered_goal.emit(goal["id"])


func _inside_goal() -> bool:
	return in_goal != &""


func _bounce_wall(side: StringName, at: Vector2) -> void:
	var impact := velocity.length()
	match side:
		&"west":
			position.x = walls.position.x
			velocity.x = absf(velocity.x) * wall_bounce
		&"east":
			position.x = walls.end.x
			velocity.x = -absf(velocity.x) * wall_bounce
		&"north":
			position.z = walls.position.y
			velocity.z = absf(velocity.z) * wall_bounce
		&"south":
			position.z = walls.end.y
			velocity.z = -absf(velocity.z) * wall_bounce
	wall_hit.emit(side, Vector3(at.x, ground_y, at.y), impact)


func _build() -> void:
	if _image != null:
		return
	var path := str(GameRules.value(&"ballon", "ball/image", DEFAULT_IMAGE, _overrides))
	var size_m := GameRules.number(&"ballon", "ball/size_m", 0.4, _overrides)
	var texture := load(path) as Texture2D
	var panel := DecorPanel.new()
	panel.texture = texture
	if texture != null:
		panel.pixels_per_meter = float(texture.get_width()) / maxf(size_m, 0.05)
	# Pas d'ombre propre (DecorPanel) : celle de la balle reste au sol, sous elle.
	panel.shadow_width = 0.0
	panel.name = "Image"
	_image = panel
	add_child(_image)
	var radius := GameRules.number(&"ballon", "ball/shadow_radius", 0.26, _overrides)
	_shadow = CombatFx.make_shadow(radius)
	_shadow.name = "Shadow"
	add_child(_shadow)


func _sync() -> void:
	position.y = ground_y + height
	if _shadow != null:
		var shrink := clampf(1.0 - height / 4.0, 0.45, 1.0)
		_shadow.position = Vector3(0.0, -height + CombatFx.SHADOW_LIFT, 0.0)
		_shadow.scale = Vector3(shrink, 1.0, shrink)
