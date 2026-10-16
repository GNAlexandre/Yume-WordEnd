@tool
class_name ShipStrip
extends DecorPanel
## (E7) Panneau d'un navire piloté par le code : une bande animée dont l'image est choisie par le
## navire (rotor qui ralentit, trappe qui s'ouvre, bras d'ancrage qui se referme), et une opacité
## pour les images à alpha doux (projecteur, ombre dans les nuages). Propriétaire : E7.
##
## Le shader des panneaux (panel_core.gdshaderinc) prend l'image d'une bande dans la phase de
## l'exemplaire (UV2.x) quand fps vaut 0 : strip_phase() renvoie ici le milieu de l'image voulue,
## et changer d'image ne change que le mesh (partagé par taille et par phase), sans reconstruire
## le panneau ni toucher à son orientation (le roulis du navire, son parent, est gardé).
## Jamais sous Geometry : le PropBatcher fondrait le mesh et figerait l'image.

## Image affichée de la bande (0 .. frames − 1).
@export var frame: int = 0:
	set(value):
		frame = posmod(value, maxi(frames, 1))
		_show_frame()
## Vitesse de défilement (images par seconde) quand le navire fait tourner la bande (rotors) ;
## 0 : la bande reste sur son image.
@export var speed: float = 0.0
## Opacité (images à alpha doux seulement : soft_alpha) ; le panneau a alors son propre matériau.
@export_range(0.0, 1.0) var opacity: float = 1.0:
	set(value):
		opacity = clampf(value, 0.0, 1.0)
		_apply_opacity()

## Lueur propre (glow > 0) : couleur qui s'allume et tolérance (DecorPanel.set_glow_rule) ;
## le projecteur, blanc, s'allume tout entier (le soir, la lumière du moment ne le ternit pas).
@export var glow_color: Color = DecorPanel.GLOW_COLOR:
	set(value):
		glow_color = value
		_queue_rebuild()
@export_range(0.01, 1.0, 0.005) var glow_tolerance: float = DecorPanel.GLOW_TOLERANCE:
	set(value):
		glow_tolerance = value
		_queue_rebuild()

var _clock: float = 0.0
var _own_material: ShaderMaterial


## Phase de l'exemplaire : le milieu de l'image affichée (le shader prend floor(phase × frames)).
func strip_phase() -> float:
	return (float(frame) + 0.5) / float(maxi(frames, 1))


func rebuild() -> void:
	super.rebuild()
	_own_material = null
	if _quad != null and texture != null and glow > 0.0:
		_quad.material_override = material_for(
			displayed_texture(),
			tint,
			glow,
			frames,
			fps,
			foreground,
			soft_alpha,
			glow_color,
			glow_tolerance
		)
	_apply_opacity()


## Fait défiler la bande de delta s à speed images par seconde (appelé par le navire, à l'image
## physique : un panneau sans premier plan n'a pas de _process).
func advance(delta: float) -> void:
	if speed <= 0.0 or frames < 2:
		return
	_clock += delta * speed
	if _clock >= 1.0:
		var steps := floori(_clock)
		_clock -= steps
		frame = frame + steps


func _show_frame() -> void:
	if _quad == null or texture == null or frames < 2:
		return
	_quad.mesh = panel_mesh(size_m(), flip_h != view_flipped(), strip_phase(), depth_offset)


func _apply_opacity() -> void:
	if _quad == null or texture == null or not soft_alpha:
		return
	if _own_material == null:
		var shared := _quad.material_override as ShaderMaterial
		if shared == null:
			return
		if is_equal_approx(opacity, 1.0):
			return
		_own_material = shared.duplicate() as ShaderMaterial
		_quad.material_override = _own_material
	_own_material.set_shader_parameter(&"tint", Color(tint, tint.a * opacity))
	_quad.visible = opacity > 0.001
