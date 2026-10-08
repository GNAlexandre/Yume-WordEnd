class_name ChargeWave
extends Node3D
## Onde de la charge magique (src/combat/charge_wave.tscn). Propriétaire : L4 (H7 pour l'image).
##
## Lancée par PlayerCombat (launch()) : avance à attack.speed dans le plan du sol ; sa Hitbox
## (charge_wave, équipe &"player") reste active tout le vol et touche chaque Hurtbox une fois,
## traverse si attack.pierces (sinon disparaît au premier coup) ; libérée après attack.range_m
## ou attack.duration. Largeur : attack.width_m.
##
## (H7) En pixel art à 96 px/m, lisible depuis la caméra fixe quelle que soit sa direction :
## « Mesh » est sa trace au sol (fx/wave_trace.png, l'empreinte exacte de la Hitbox, 2 m de
## large) ; « Sprite » est le croissant debout (fx/wave.png, deux images qui scintillent), face à
## la caméra et tourné pour que sa bosse pointe à l'écran là où l'onde file, aussi large à
## l'écran que la trace (une onde vers l'est se voit donc entière, et non par la tranche).
## Trace, croissant et lumière s'estompent en fin de vol.

## Part de la fin du vol pendant laquelle l'onde s'estompe (0..1).
@export var fade_tail: float = 0.35
## Scintillement du croissant (images par seconde).
@export var flicker_rate: float = 12.0

var _direction: Vector3 = Vector3.FORWARD
var _traveled: float = 0.0
var _life: float = 0.0
var _launched: bool = false
var _width: float = 2.0

@onready var hitbox: Hitbox = $Hitbox
@onready var _mesh: MeshInstance3D = $Mesh
@onready var _sprite: Sprite3D = $Sprite
@onready var _glow: OmniLight3D = $Glow
@onready var _glow_energy: float = _glow.light_energy


func _ready() -> void:
	hitbox.hit_landed.connect(_on_hit_landed)
	var data := hitbox.attack
	if data == null or data.width_m <= 0.0:
		return
	_width = data.width_m
	var box := (hitbox.get_node(^"CollisionShape3D") as CollisionShape3D).shape as BoxShape3D
	if box != null:
		box.size.x = data.width_m
	var plane := _mesh.mesh as PlaneMesh
	if plane != null and plane.size.x > 0.0:
		_mesh.scale.x = data.width_m / plane.size.x


## Lance l'onde vers direction (ramenée à l'horizontale) ; source = l'attaquant transmis aux
## cibles (le joueur : le recul les éloigne de lui).
func launch(direction: Vector3, source: Node3D) -> void:
	direction.y = 0.0
	if direction.length_squared() > 0.0001:
		_direction = direction.normalized()
	global_basis = Basis.looking_at(_direction, Vector3.UP)
	hitbox.source = source
	hitbox.activate()
	_launched = true
	_orient_sprite()


## Distance parcourue depuis le lancement, en mètres.
func traveled() -> float:
	return _traveled


## Direction de vol (sol, unitaire).
func travel_direction() -> Vector3:
	return _direction


func _process(_delta: float) -> void:
	if _launched:
		_orient_sprite()


func _physics_process(delta: float) -> void:
	var data := hitbox.attack
	if not _launched or data == null:
		return
	# Fin de course testée avant d'avancer : la Hitbox traite encore, à cette image, les
	# chevauchements de la dernière position.
	var done := _traveled >= data.range_m or (data.duration > 0.0 and _life >= data.duration)
	if done or data.speed <= 0.0:
		_launched = false
		queue_free()
		return
	var step := data.speed * delta
	global_position += _direction * step
	_traveled += step
	_life += delta
	var progress := _traveled / data.range_m if data.range_m > 0.0 else 0.0
	if data.duration > 0.0:
		progress = maxf(progress, _life / data.duration)
	var fade := clampf((1.0 - progress) / maxf(fade_tail, 0.01), 0.0, 1.0)
	var material := _mesh.material_override as StandardMaterial3D
	if material != null:
		material.albedo_color.a = fade
	_sprite.modulate.a = fade
	_sprite.frame = int(_life * flicker_rate) % maxi(1, _sprite.hframes)
	_glow.light_energy = _glow_energy * fade


## Croissant face à la caméra, bosse vers la direction de vol vue à l'écran, de la largeur de
## l'onde vue à l'écran (une largeur nord-sud est écrasée par l'inclinaison de la caméra).
func _orient_sprite() -> void:
	var camera := get_viewport().get_camera_3d() if is_inside_tree() else null
	if camera == null:
		return
	var across := Vector3(-_direction.z, 0.0, _direction.x) * _width
	var span := CombatFx.screen_length(camera, across)
	var image_width := _sprite.texture.get_width() / maxf(1.0, _sprite.hframes) * _sprite.pixel_size
	var stretch := clampf(span / maxf(image_width, 0.01), 0.35, 1.5)
	var facing := CombatFx.facing_basis(camera, _direction)
	_sprite.global_basis = Basis(facing.x * stretch, facing.y, facing.z)


func _on_hit_landed(_hurtbox: Hurtbox) -> void:
	if hitbox.attack != null and not hitbox.attack.pierces:
		_launched = false
		hitbox.deactivate()
		queue_free()
