extends Node3D
## Signes avant l'attaque d'un Timere (lot H7), nœud « Telegraph » de enemy.tscn, piloté par
## enemy.gd pendant l'état windup. La caméra fixe regarde le nord : ce qui doit se lire « où » se
## pose au sol, ce qui doit se lire « quand » se voit au-dessus du Timere.
##
## - strike() : zone exacte de la Hitbox du coup qui vient (cercle au sol, bord net, à la portée
##   réelle) ; son remplissage grandit jusqu'au bord à l'instant où l'animation part ;
## - rush() : couloir de la charge du Timere bondissant (direction verrouillée, longueur et
##   largeur réelles), chevrons vers l'avant ;
## - un éclat au-dessus de la tête (petit, grand, moyen, puis grand juste avant le coup).
## Coordonnées locales au Timere (sa racine ne tourne pas : axes du monde).

const RING := "danger_ring"
const FILL := "danger_fill"
const LANE := "rush_lane"
const GLINT := "glint"
## Taille de l'image du couloir (m) : 48 × 192 px à 96 px/m.
const LANE_IMAGE := Vector2(0.5, 2.0)
## Le remplissage part de cette fraction du rayon.
const FILL_START := 0.2

## Taille de l'éclat (× 96 px/m).
@export var glint_size: float = 1.3

var _mode: StringName = &""
var _progress: float = 0.0
var _diameter: float = 1.0
var _lane_direction: Vector3 = Vector3.ZERO
var _lane_size: Vector2 = Vector2.ZERO
var _ring: MeshInstance3D
var _fill: MeshInstance3D
var _lane: MeshInstance3D
var _glint: AnimatedSprite3D


func _ready() -> void:
	_fill = CombatFx.make_decal(FILL, Vector2.ONE, Color.WHITE, "Fill")
	_ring = CombatFx.make_decal(RING, Vector2.ONE, Color.WHITE, "Ring")
	# Le bord se voit même sous le joueur qui s'y tient (il est dans la portée) ; le
	# remplissage reste sous les corps.
	_ring.material_override = CombatFx.ground_material(RING, Color.WHITE, -1, true)
	_lane = CombatFx.make_decal(LANE, LANE_IMAGE, Color.WHITE, "Lane")
	_glint = CombatFx.make_sprite(GLINT, glint_size)
	_glint.name = "Glint"
	_glint.no_depth_test = true
	_glint.render_priority = 2
	for node: Node3D in [_fill, _ring, _lane, _glint]:
		add_child(node)
	clear()


## Zone d'un coup au contact : cercle de rayon radius (m) centré en center (local, au sol) ;
## éclat en glint_at (local).
func strike(center: Vector3, radius: float, glint_at: Vector3) -> void:
	_mode = &"strike"
	_diameter = 2.0 * maxf(radius, 0.05)
	var appearing := not _ring.visible
	var ground := Vector3(center.x, CombatFx.GROUND_LIFT, center.z)
	_ring.position = ground + Vector3.UP * 0.004
	_ring.scale = Vector3(_diameter, 1.0, _diameter)
	_fill.position = ground
	_ring.visible = true
	_fill.visible = true
	_lane.visible = false
	_show_glint(glint_at)
	set_progress(_progress)
	if appearing:
		_settle([_ring, _fill, _glint])


## Couloir d'une charge : direction (sol), longueur et largeur (m) depuis le Timere.
func rush(direction: Vector3, length: float, width: float, glint_at: Vector3) -> void:
	var flat := Vector3(direction.x, 0.0, direction.z)
	if flat.length_squared() < 0.0001:
		return
	flat = flat.normalized()
	_mode = &"rush"
	var appearing := not _lane.visible
	_lane_direction = flat
	_lane_size = Vector2(width, length)
	var size := Vector3(width / LANE_IMAGE.x, 1.0, length / LANE_IMAGE.y)
	_lane.transform = Transform3D(
		Basis.looking_at(flat, Vector3.UP) * Basis.from_scale(size),
		flat * length * 0.5 + Vector3.UP * CombatFx.GROUND_LIFT
	)
	_lane.visible = true
	_ring.visible = false
	_fill.visible = false
	_show_glint(glint_at)
	set_progress(_progress)
	if appearing:
		_settle([_lane, _glint])


## Avancement de la préparation (0..1) : remplissage de la zone, image de l'éclat.
func set_progress(ratio: float) -> void:
	_progress = clampf(ratio, 0.0, 1.0)
	if _mode == &"strike":
		var fill := _diameter * lerpf(FILL_START, 1.0, _progress)
		_fill.scale = Vector3(fill, 1.0, fill)
	if _glint.visible:
		_glint.frame = glint_frame(_progress)


## Image de l'éclat à l'avancement ratio : petit, grand, moyen, puis grand juste avant le coup.
static func glint_frame(ratio: float) -> int:
	if ratio < 0.2:
		return 0
	if ratio < 0.55:
		return 1
	if ratio < 0.85:
		return 2
	return 1


## Efface tous les signes.
func clear() -> void:
	_mode = &""
	_progress = 0.0
	for node: Node3D in [_fill, _ring, _lane, _glint]:
		node.visible = false


## &"strike", &"rush" ou &"" (rien d'affiché).
func mode() -> StringName:
	return _mode


func _show_glint(at: Vector3) -> void:
	_glint.pixel_size = CombatFx.PIXEL_SIZE * glint_size
	_glint.position = at
	_glint.visible = true


## Signes déplacés puis montrés dans la même image physique : sans remise à zéro du lissage
## physique (project.godot), ils seraient dessinés en train de glisser depuis leur ancienne place
## (la zone du coup d'avant, ou les pieds du Timere) pendant un pas de physique. Seulement quand
## ils apparaissent : pendant la préparation, strike() est rappelé à chaque pas de physique pour
## suivre la cible, et le cercle doit alors rester lissé entre deux pas.
static func _settle(nodes: Array[Node3D]) -> void:
	for node: Node3D in nodes:
		if node.is_inside_tree():
			node.reset_physics_interpolation()


## Avancement courant (0..1).
func progress() -> float:
	return _progress


## Rayon de la zone affichée (m).
func zone_radius() -> float:
	return _diameter * 0.5


## Centre de la zone affichée (local, au sol).
func zone_center() -> Vector3:
	return Vector3(_fill.position.x, 0.0, _fill.position.z)


## Couloir de charge affiché : direction (sol, unitaire), largeur et longueur (m).
func lane_direction() -> Vector3:
	return _lane_direction


func lane_size() -> Vector2:
	return _lane_size
