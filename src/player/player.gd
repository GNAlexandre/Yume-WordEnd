class_name Player
extends CharacterBody3D
## Joueur : nœud unique du groupe "player" (PLAN.md sections 3 et 4). Propriétaire : L1.
##
## Structure figée de player.tscn (d'autres lots s'en servent ; noms et chemins inchangés) :
## CollisionShape3D, Visual (CharacterVisual), Combat (PlayerCombat) et son enfant SwordHitbox
## (Hitbox, équipe &"player"), Health (5 PV et 1,2 s d'invincibilité, valeurs de L4), Hurtbox
## (équipe &"player", health = ../Health), CameraRig (camera_rig.tscn). Ajout L1 :
## InteractionArea (Area3D, masque 6 + 7) tournée vers la visée comme Combat.
##
## À chaque image physique, read_commands() lit les actions du Lot 0 et tick() les applique
## (les tests appellent tick() avec des commandes fabriquées) :
## - déplacement relatif à la caméra (move_direction ; (HD-2D) la caméra fixe regarde le nord :
##   haut de l'écran = nord, commandes relatives à l'écran), marche ou course avec accélération et
##   décélération, saut (appui retenu, délai de grâce), gravité, pentes jusqu'à 45° ;
## - rien ne bouge pendant Combat.is_busy() ni entre dialogue_started et dialogue_ended ;
##   attack() et charge_begin() quand Combat est libre, attack() aussi pendant un coup
##   d'épée (Combat le garde pour enchaîner), charge_release() toujours (c'est lui qui termine
##   la charge) ; rien pendant un dialogue ;
## - visée : cible verrouillée ou dernière direction de déplacement ; Combat tourne pour que
##   son −Z pointe vers elle (épée, onde) ; Visual.set_facing quand Combat est libre ;
## - interaction : interactable le plus proche dans le cône frontal ;
##   EventBus.interaction_available(invite) quand l'invite change ("" : plus rien) ; interact
##   passe avant jump quand une invite est affichée (bouton A de la manette) ;
## - verrouillage (lock_target) : ennemi vivant le plus proche, exposé par locked_target() et
##   cadré par la caméra ; perdu si la cible meurt, quitte le groupe ou s'éloigne trop ;
## - souris : clic gauche = attack, clic droit maintenu = charge (MOUSE_ACTIONS, envoyés comme
##   les boutons tactiles, en InputEventAction) ; le joueur se tourne d'abord vers le point du sol
##   sous le pointeur, sauf s'il a une cible verrouillée. Seuls les clics que l'interface n'a pas
##   pris arrivent ici, jamais la souris émulée par le tactile (ses contrôles ont leurs boutons).
## Comportements du Lot 0 conservés : skin de GameState (et skin_changed), recul sur
## Hurtbox.hit_taken, GameState.position tenue à jour au sol, animations repos / marche /
## course seulement quand Combat.is_busy() est faux. Réapparition (player_respawned) :
## vitesse et recul à zéro, verrou levé, caméra recalée sur le joueur.

## Script de la caméra, pour typer camera_rig sans ajouter de classe globale.
const CameraRigScript := preload("res://src/player/camera_rig.gd")
## Vitesse horizontale sous laquelle le joueur est au repos (m/s).
const IDLE_SPEED := 0.3
## Un interactable plus proche que cette distance (m) compte même hors du cône frontal.
const NEAR_RADIUS := 0.6
## Boutons de la souris et action qu'ils tiennent.
const MOUSE_ACTIONS: Dictionary[int, StringName] = {
	MOUSE_BUTTON_LEFT: &"attack",
	MOUSE_BUTTON_RIGHT: &"charge",
}

@export_group("Déplacement")
## Vitesse de marche (m/s, easter egg : 72 px/s).
@export var walk_speed: float = 4.0
## Vitesse de course (m/s), action run maintenue (Maj) ou lancée à la manette (L3).
@export var run_speed: float = 7.0
## Accélération au sol (m/s²).
@export var acceleration: float = 45.0
## Décélération au sol, aussi pour les demi-tours (m/s²) : pas de glisse.
@export var deceleration: float = 60.0
## Accélération et décélération en l'air (m/s²).
@export var air_acceleration: float = 18.0

@export_group("Saut et gravité")
## Vitesse verticale au départ du saut (m/s) : environ 1 m de haut avec gravity_scale 1,5.
@export var jump_velocity: float = 5.4
## Multiplicateur de la gravité du monde (saut plus nerveux).
@export var gravity_scale: float = 1.5
## Délai après avoir quitté le sol pendant lequel le saut reste possible (s).
@export var coyote_time: float = 0.1
## Un appui sur saut juste avant d'atterrir est retenu pendant ce délai (s).
@export var jump_buffer_time: float = 0.12

@export_group("Recul")
## Amortissement du recul (m/s perdus par seconde).
@export var knockback_damping: float = 12.0

@export_group("Interaction et verrouillage")
## Ouverture du cône frontal où l'on cherche un interactable (degrés).
@export_range(10.0, 360.0) var interact_cone_deg: float = 120.0
## Rayon de recherche d'une cible à verrouiller (m).
@export var lock_radius: float = 12.0
## Distance au-delà de laquelle le verrou est perdu (m).
@export var lock_break_distance: float = 16.0

var _move_velocity: Vector3 = Vector3.ZERO
var _knockback: Vector3 = Vector3.ZERO
var _aim: Vector3 = Vector3.FORWARD
var _running: bool = false
var _run_latched: bool = false
var _was_moving: bool = false
var _was_busy: bool = false
var _coyote_left: float = 0.0
var _jump_buffer_left: float = 0.0
var _in_dialogue: bool = false
var _wait_release: bool = false
var _interactable: Node3D
var _prompt: String = ""
var _lock_target: Node3D
## Boutons de la souris dont l'action est tenue (relâchés s'ils le sont hors de portée).
var _mouse_held: Dictionary[int, bool] = {}
## Visée vers le pointeur au dernier clic, appliquée à l'image suivante (ZERO : aucune).
var _pointer_aim: Vector3 = Vector3.ZERO

@onready var visual: CharacterVisual = $Visual
@onready var combat: PlayerCombat = $Combat
@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var camera_rig: CameraRigScript = $CameraRig
@onready var interaction_area: Area3D = $InteractionArea


## Commandes d'une image physique : lues par read_commands(), fabriquées par les tests.
class Commands:
	extends RefCounted
	## Déplacement (Input.get_vector) : x vers la droite, y vers l'arrière, longueur ≤ 1.
	var move: Vector2 = Vector2.ZERO
	## Course maintenue (action run).
	var run: bool = false
	## Appui sur jump dans cette image, et jump maintenu.
	var jump: bool = false
	var jump_held: bool = false
	## Appui sur interact dans cette image, et interact maintenu.
	var interact: bool = false
	var interact_held: bool = false
	## Appui sur attack dans cette image.
	var attack: bool = false
	## charge maintenue, appuyée et relâchée dans cette image.
	var charge: bool = false
	var charge_pressed: bool = false
	var charge_released: bool = false
	## Appui sur lock_target dans cette image.
	var lock: bool = false


func _ready() -> void:
	visual.set_skin(_current_skin())
	EventBus.skin_changed.connect(_on_skin_changed)
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_ended.connect(_on_dialogue_ended)
	EventBus.player_respawned.connect(_on_player_respawned)
	hurtbox.hit_taken.connect(_on_hit_taken)
	_apply_aim()


func _physics_process(delta: float) -> void:
	_release_lost_mouse_buttons()
	tick(delta, read_commands())


func _unhandled_input(event: InputEvent) -> void:
	# Manette : un appui sur L3 lance la course jusqu'à l'arrêt (le maintenir en inclinant le
	# stick est inconfortable) ; au clavier, Maj se maintient.
	if event is InputEventJoypadButton and event.is_action_pressed(&"run"):
		_run_latched = true
	var click := event as InputEventMouseButton
	if click != null and click.device != InputEvent.DEVICE_ID_EMULATION:
		if handle_mouse_button(click.button_index, click.pressed, click.position):
			get_viewport().set_input_as_handled()


## Clic de souris au point `at` de la fenêtre : tient ou relâche l'action du bouton
## (MOUSE_ACTIONS) et, à l'appui, retient la visée vers le sol sous le pointeur. True si le clic
## est pris. Rien pendant un dialogue ni après la mort ; un relâchement sans appui pris est ignoré.
func handle_mouse_button(button: int, pressed: bool, at: Vector2) -> bool:
	var action: StringName = MOUSE_ACTIONS.get(button, &"")
	if action == &"":
		return false
	if pressed:
		if _in_dialogue or health.is_dead():
			return false
		_pointer_aim = pointer_direction(at)
		_mouse_held[button] = true
	elif not _mouse_held.erase(button):
		return false
	_send_action(action, pressed)
	return true


## Direction horizontale (unitaire) du joueur vers le point du sol, à sa hauteur, sous le point
## `at` de la fenêtre ; ZERO sans caméra ou si le rayon ne coupe pas ce plan.
func pointer_direction(at: Vector2) -> Vector3:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return Vector3.ZERO
	var origin := camera.project_ray_origin(at)
	var normal := camera.project_ray_normal(at)
	if absf(normal.y) < 0.0001:
		return Vector3.ZERO
	var distance := (global_position.y - origin.y) / normal.y
	if distance <= 0.0:
		return Vector3.ZERO
	var offset := origin + normal * distance - global_position
	offset.y = 0.0
	return offset.normalized() if offset.length_squared() > 0.0001 else Vector3.ZERO


## Un bouton relâché pendant que le jeu ne recevait pas l'événement (pause, interface) : son
## action est relâchée ici, sinon la charge resterait tenue.
func _release_lost_mouse_buttons() -> void:
	for button: int in _mouse_held.keys():
		if not Input.is_mouse_button_pressed(button as MouseButton):
			_mouse_held.erase(button)
			_send_action(MOUSE_ACTIONS[button], false)


static func _send_action(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)


## Commandes de l'image courante, lues dans les actions d'entrée du Lot 0.
static func read_commands() -> Commands:
	var commands := Commands.new()
	commands.move = Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	commands.run = Input.is_action_pressed(&"run")
	commands.jump = Input.is_action_just_pressed(&"jump")
	commands.jump_held = Input.is_action_pressed(&"jump")
	commands.interact = Input.is_action_just_pressed(&"interact")
	commands.interact_held = Input.is_action_pressed(&"interact")
	commands.attack = Input.is_action_just_pressed(&"attack")
	commands.charge = Input.is_action_pressed(&"charge")
	commands.charge_pressed = Input.is_action_just_pressed(&"charge")
	commands.charge_released = Input.is_action_just_released(&"charge")
	commands.lock = Input.is_action_just_pressed(&"lock_target")
	return commands


## Direction de déplacement dans le plan du sol pour l'entrée input (Input.get_vector : x à
## droite, y vers l'arrière) vue d'une caméra de base camera_basis. Sa longueur est celle de
## input (au plus 1) : un stick à moitié incliné donne une demi-vitesse.
static func move_direction(input: Vector2, camera_basis: Basis) -> Vector3:
	var strength := minf(input.length(), 1.0)
	if strength < 0.001:
		return Vector3.ZERO
	var forward := Vector3(-camera_basis.z.x, 0.0, -camera_basis.z.z)
	if forward.length_squared() < 0.0001:
		# Caméra à la verticale : le haut de l'image donne l'avant.
		forward = Vector3(camera_basis.y.x, 0.0, camera_basis.y.z)
	if forward.length_squared() < 0.0001:
		forward = Vector3.FORWARD
	forward = forward.normalized()
	var right := forward.cross(Vector3.UP)
	return (right * input.x - forward * input.y).normalized() * strength


## Ce que déclenche un appui : &"interact" quand une invite est affichée (prioritaire : le
## bouton A de la manette sert aussi au saut), sinon &"jump" si jump est appuyé, sinon &"".
static func resolve_press(
	interact_pressed: bool, jump_pressed: bool, prompt_shown: bool
) -> StringName:
	if interact_pressed and prompt_shown:
		return &"interact"
	if jump_pressed:
		return &"jump"
	return &""


## Interactable d'un nœud détecté : le premier nœud du groupe "interactable" en remontant
## depuis node (lui compris), s'il implémente get_prompt() et interact() ; null sinon.
static func resolve_interactable(node: Node) -> Node3D:
	var current := node
	while current != null:
		if current.is_in_group(&"interactable"):
			var valid := (
				current is Node3D
				and current.has_method(&"get_prompt")
				and current.has_method(&"interact")
			)
			return current as Node3D if valid else null
		current = current.get_parent()
	return null


## Le plus proche des candidats situés dans le cône frontal (ouverture cone_deg autour de
## facing, dans le plan du sol) ; un candidat à moins de NEAR_RADIUS compte toujours.
static func pick_interactable(
	origin: Vector3, facing: Vector3, candidates: Array[Node3D], cone_deg: float
) -> Node3D:
	var flat_facing := Vector3(facing.x, 0.0, facing.z).normalized()
	var min_dot := cos(deg_to_rad(cone_deg * 0.5))
	var best: Node3D = null
	var best_distance := INF
	for candidate: Node3D in candidates:
		var offset := candidate.global_position - origin
		offset.y = 0.0
		var distance := offset.length()
		var in_cone := (
			flat_facing == Vector3.ZERO or offset.normalized().dot(flat_facing) >= min_dot
		)
		if (in_cone or distance <= NEAR_RADIUS) and distance < best_distance:
			best = candidate
			best_distance = distance
	return best


## Cible de verrouillage : l'ennemi verrouillable (is_lockable) le plus proche de origin, à au
## plus radius mètres ; null s'il n'y en a pas.
static func pick_lock_target(origin: Vector3, candidates: Array[Node], radius: float) -> Node3D:
	var best: Node3D = null
	var best_distance := radius
	for candidate: Node in candidates:
		if not is_lockable(candidate):
			continue
		var distance := (candidate as Node3D).global_position.distance_to(origin)
		if distance <= best_distance:
			best = candidate as Node3D
			best_distance = distance
	return best


## Ennemi vivant : Node3D dans l'arbre et dans le groupe "enemies" (un ennemi mort le quitte),
## pas en cours de libération, et dont le Health enfant (s'il existe) n'est pas mort.
static func is_lockable(node: Node) -> bool:
	if not node is Node3D or not node.is_inside_tree() or node.is_queued_for_deletion():
		return false
	if not node.is_in_group(&"enemies"):
		return false
	var node_health := node.get_node_or_null(^"Health") as Health
	return node_health == null or not node_health.is_dead()


## Applique une image de commandes. Appelé par _physics_process ; les tests l'appellent avec
## des commandes fabriquées (après set_physics_process(false)).
func tick(delta: float, commands: Commands) -> void:
	var dead := health.is_dead()
	var busy := combat.is_busy() or dead
	var frozen := busy or _in_dialogue
	_filter_after_dialogue(commands)
	_update_lock(commands.lock and not _in_dialogue, dead)
	var direction := Vector3.ZERO
	if not frozen:
		direction = move_direction(commands.move, _camera_basis())
	_update_running(commands)
	_update_move_velocity(direction, frozen, delta)
	_update_aim(direction)
	if _pointer_aim != Vector3.ZERO:
		# Clic de souris : le coup part vers le pointeur, même en marchant (pas pendant un coup
		# ou une charge, ni avec une cible verrouillée).
		if not frozen and _lock_target == null:
			_aim = _pointer_aim
			visual.set_facing(_aim)
		_pointer_aim = Vector3.ZERO
	_apply_aim()
	var press := &""
	if not frozen:
		press = resolve_press(commands.interact, commands.jump, not _prompt.is_empty())
	if press == &"interact" and is_instance_valid(_interactable):
		_interact_with(_interactable)
	elif press == &"jump":
		_jump_buffer_left = jump_buffer_time
	_update_vertical(frozen, delta)
	velocity.x = _move_velocity.x + _knockback.x
	velocity.z = _move_velocity.z + _knockback.z
	_knockback = _knockback.move_toward(Vector3.ZERO, knockback_damping * delta)
	move_and_slide()
	if is_on_floor():
		GameState.position = global_position
	_forward_combat(commands, busy)
	if not combat.is_busy() and not health.is_dead():
		_animate()
	_refresh_interaction(not _in_dialogue and not health.is_dead())
	camera_rig.lock_target = locked_target()
	camera_rig.follow_velocity = _move_velocity
	_was_busy = busy


## Ennemi verrouillé, ou null. Pour la caméra et le HUD.
func locked_target() -> Node3D:
	return _lock_target if is_instance_valid(_lock_target) else null


## Direction de visée (horizontale, unitaire) : vers la cible verrouillée, sinon la dernière
## direction de déplacement. Combat.−Z pointe dans cette direction.
func aim_direction() -> Vector3:
	return _aim


## Oriente le joueur vers direction (visée, Combat, visuel) ; camera_behind replace aussi la
## caméra derrière lui (après une téléportation, pour une capture…).
func set_aim_direction(direction: Vector3, camera_behind: bool = false) -> void:
	var flat := Vector3(direction.x, 0.0, direction.z)
	if flat.length_squared() < 0.0001:
		return
	_aim = flat.normalized()
	_apply_aim()
	if camera_behind:
		camera_rig.snap_behind(_aim)
	visual.set_facing(_aim)


## Interactable dont l'invite est affichée, ou null.
func current_interactable() -> Node3D:
	return _interactable if is_instance_valid(_interactable) else null


## Invite d'interaction affichée ("" : aucune), telle qu'émise dans interaction_available.
func current_prompt() -> String:
	return _prompt


## true entre EventBus.dialogue_started et dialogue_ended.
func is_in_dialogue() -> bool:
	return _in_dialogue


## true si le joueur court (run maintenue, ou course lancée à la manette).
func is_running() -> bool:
	return _running


# Après un dialogue, l'appui qui l'a fermé (interact, ou A = jump à la manette) ne doit ni le
# relancer ni faire sauter : interact et jump sont ignorés jusqu'à leur relâchement.
func _filter_after_dialogue(commands: Commands) -> void:
	if not _wait_release:
		return
	if commands.interact or commands.jump or commands.interact_held or commands.jump_held:
		commands.interact = false
		commands.jump = false
	else:
		_wait_release = false


func _update_lock(toggle: bool, dead: bool) -> void:
	if dead or not _lock_still_valid():
		_lock_target = null
	if not toggle or dead:
		return
	if _lock_target != null:
		_lock_target = null
		return
	var enemies := get_tree().get_nodes_in_group(&"enemies")
	_lock_target = pick_lock_target(global_position, enemies, lock_radius)
	if _lock_target == null:
		# Sans cible : la caméra fixe ne tourne pas (recenter_behind est sans effet en HD-2D).
		camera_rig.recenter_behind(_aim)


func _lock_still_valid() -> bool:
	if not is_instance_valid(_lock_target) or not is_lockable(_lock_target):
		return false
	return _lock_target.global_position.distance_to(global_position) <= lock_break_distance


func _update_running(commands: Commands) -> void:
	var moving := commands.move != Vector2.ZERO
	if _was_moving and not moving:
		_run_latched = false
	_was_moving = moving
	_running = commands.run or _run_latched


func _update_move_velocity(direction: Vector3, frozen: bool, delta: float) -> void:
	if frozen:
		_move_velocity = Vector3.ZERO
		return
	var target := direction * (run_speed if _running else walk_speed)
	var rate := deceleration
	if not is_on_floor():
		rate = air_acceleration
	elif target != Vector3.ZERO and target.dot(_move_velocity) >= 0.0:
		rate = acceleration
	_move_velocity = _move_velocity.move_toward(target, rate * delta)


func _update_aim(direction: Vector3) -> void:
	if _lock_target != null:
		var offset := _lock_target.global_position - global_position
		offset.y = 0.0
		if offset.length_squared() > 0.0025:
			_aim = offset.normalized()
	elif direction.length_squared() > 0.0001:
		_aim = Vector3(direction.x, 0.0, direction.z).normalized()


func _apply_aim() -> void:
	var yaw := atan2(-_aim.x, -_aim.z)
	combat.rotation.y = yaw
	interaction_area.rotation.y = yaw


func _update_vertical(frozen: bool, delta: float) -> void:
	if is_on_floor():
		_coyote_left = coyote_time
	else:
		_coyote_left = maxf(0.0, _coyote_left - delta)
		velocity += get_gravity() * gravity_scale * delta
	if _jump_buffer_left <= 0.0:
		return
	if not frozen and _coyote_left > 0.0:
		velocity.y = jump_velocity
		_jump_buffer_left = 0.0
		_coyote_left = 0.0
	else:
		_jump_buffer_left = maxf(0.0, _jump_buffer_left - delta)


func _forward_combat(commands: Commands, busy: bool) -> void:
	if commands.charge_released:
		combat.charge_release()
	if _in_dialogue:
		return
	if busy:
		# Un appui pendant un coup d'épée passe à Combat (L4), qui le garde pour enchaîner le
		# coup suivant ; pendant la charge, l'onde, les dégâts ou la mort, rien ne passe.
		if commands.attack and combat.current_state() == &"attack":
			combat.attack()
		return
	if commands.attack:
		combat.attack()
	elif commands.charge_pressed or (commands.charge and _was_busy):
		# Charge maintenue pendant une attaque : elle démarre dès que Combat est libre (jeu.js).
		combat.charge_begin()


func _animate() -> void:
	var speed := Vector2(_move_velocity.x, _move_velocity.z).length()
	if speed < IDLE_SPEED:
		visual.play(&"repos")
	elif _running and speed > walk_speed + IDLE_SPEED:
		# Course au stick à moitié incliné : pas plus vite qu'une marche, donc « marche ».
		visual.play(&"course")
	else:
		visual.play(&"marche")
	visual.set_facing(_aim)


func _refresh_interaction(enabled: bool) -> void:
	var found: Node3D = null
	if enabled:
		found = pick_interactable(
			global_position, _aim, _detected_interactables(), interact_cone_deg
		)
	_interactable = found
	var prompt := str(found.call(&"get_prompt")) if found != null else ""
	if prompt != _prompt:
		_prompt = prompt
		EventBus.interaction_available.emit(prompt)


func _detected_interactables() -> Array[Node3D]:
	var detected: Array[Node3D] = []
	for area: Area3D in interaction_area.get_overlapping_areas():
		detected.append(area)
	for body: Node3D in interaction_area.get_overlapping_bodies():
		detected.append(body)
	var result: Array[Node3D] = []
	for node: Node3D in detected:
		var interactable := resolve_interactable(node)
		if (
			interactable != null
			and not interactable.is_queued_for_deletion()
			and not result.has(interactable)
		):
			result.append(interactable)
	return result


func _interact_with(target: Node3D) -> void:
	if target.is_queued_for_deletion():
		return
	if _lock_target == null:
		var offset := target.global_position - global_position
		offset.y = 0.0
		if offset.length_squared() > 0.0025:
			_aim = offset.normalized()
			_apply_aim()
	target.call(&"interact", self)


func _camera_basis() -> Basis:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		camera = camera_rig.camera
	return camera.global_basis


func _current_skin() -> SkinData:
	var skin := SkinRegistry.get_skin(GameState.skin_id)
	return skin if skin != null else SkinRegistry.default_skin()


func _on_skin_changed(_skin_id: StringName) -> void:
	visual.set_skin(_current_skin())


func _on_hit_taken(attack: AttackData, source: Node3D) -> void:
	if source == null:
		return
	var away := global_position - source.global_position
	away.y = 0.0
	if away.length_squared() > 0.0001:
		_knockback = away.normalized() * attack.knockback


func _on_dialogue_started(_npc_id: StringName) -> void:
	_in_dialogue = true
	_move_velocity = Vector3.ZERO
	_refresh_interaction(false)


func _on_dialogue_ended(_npc_id: StringName) -> void:
	_in_dialogue = false
	_wait_release = true


func _on_player_respawned() -> void:
	velocity = Vector3.ZERO
	_move_velocity = Vector3.ZERO
	_knockback = Vector3.ZERO
	_jump_buffer_left = 0.0
	_lock_target = null
	camera_rig.lock_target = null
	camera_rig.follow_velocity = Vector3.ZERO
	camera_rig.snap_behind(_aim)
