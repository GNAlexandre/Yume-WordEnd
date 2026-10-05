class_name ChargeWave
extends Node3D
## Onde de la charge magique (src/combat/charge_wave.tscn). Propriétaire : L4.
##
## Lancée par PlayerCombat (launch()) : avance à attack.speed dans le plan du sol ; sa Hitbox
## (charge_wave, équipe &"player") reste active tout le vol et touche chaque Hurtbox une fois,
## traverse si attack.pierces (sinon disparaît au premier coup) ; libérée après attack.range_m
## ou attack.duration. Largeur : attack.width_m. Maillage et lumière s'estompent en fin de vol.

## Part de la fin du vol pendant laquelle l'onde s'estompe (0..1).
@export var fade_tail: float = 0.35

var _direction: Vector3 = Vector3.FORWARD
var _traveled: float = 0.0
var _life: float = 0.0
var _launched: bool = false

@onready var hitbox: Hitbox = $Hitbox
@onready var _mesh: MeshInstance3D = $Mesh
@onready var _glow: OmniLight3D = $Glow
@onready var _glow_energy: float = _glow.light_energy


func _ready() -> void:
	hitbox.hit_landed.connect(_on_hit_landed)
	var data := hitbox.attack
	if data == null or data.width_m <= 0.0:
		return
	var box := (hitbox.get_node(^"CollisionShape3D") as CollisionShape3D).shape as BoxShape3D
	if box != null:
		box.size.x = data.width_m
	var quad := _mesh.mesh as QuadMesh
	if quad != null and quad.size.x > 0.0:
		_mesh.scale.x = data.width_m / quad.size.x


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


## Distance parcourue depuis le lancement, en mètres.
func traveled() -> float:
	return _traveled


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
	var material := _mesh.material_override as ShaderMaterial
	if material != null:
		material.set_shader_parameter(&"fade", fade)
	_glow.light_energy = _glow_energy * fade


func _on_hit_landed(_hurtbox: Hurtbox) -> void:
	if hitbox.attack != null and not hitbox.attack.pierces:
		_launched = false
		hitbox.deactivate()
		queue_free()
