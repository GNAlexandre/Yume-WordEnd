@tool
class_name InteriorPanel
extends DecorPanel
## (E3) Meuble ou objet d'intérieur : un DecorPanel (même image, même ancre, même ombre, même
## collision dans l'enfant « Collision ») dont le matériau est celui des intérieurs
## (InteriorRoom.panel_material, interior_panel.gdshader) : il prend la lumière de la pièce
## (fenêtres, lampes) et se coupe avec les murs. Quand la coupe d'InteriorRoom passe au nord de
## son bord sud (l'image, posée à image_offset), il n'est plus dessiné qu'au-dessous de
## cut_height ; la même coupe suit aussi le z du joueur à l’intérieur de sa pièce. Les meubles
## d’une même image se fondent en un draw call (PropBatcher : coordonnée de coupe et cut_height
## dans UV2 des sommets). Racine des scènes de meubles de src/world/props/ (tools/hd2d_interior.py
## scenes) : le nœud est au milieu de l'emprise, l'image au bord sud (image_offset.z = la moitié
## de la profondeur), la boîte de collision sur l'emprise.
##
## Ni bande animée, ni premier plan, ni décalage vers la caméra : frames, fps, foreground et
## depth_offset sont sans effet ici.
##
## (I1) Vues : comme tout DecorPanel, un meuble tourné vers l'est, l'ouest ou le nord montre sa vue
## de flanc, de dos ou par le pied quand elle existe (DecorPanel.facing). L'image de la vue prend
## la place de la face : même bord sud (image_offset, posé par ce qui pose le meuble), mêmes
## règles de coupe ; occluder_triangles et size_m parlent de l'image affichée.

## Hauteur gardée quand la coupe passe (m) : les tables, bancs et lits restent entiers, les
## armoires et rayonnages ne montrent que leur bas.
@export_range(0.0, 4.0) var cut_height: float = InteriorRoom.PROP_CUT_HEIGHT:
	set(value):
		cut_height = maxf(value, 0.0)
		_queue_rebuild()
## (T2) Décalage vers le sud de la coordonnée de coupe (m) : un meuble adossé au mur sud de sa
## pièce (placard, étagère, lits superposés) se coupe avec ce mur (cut_offset jusqu'au delà de sa
## ligne) au lieu de cacher le joueur qui se tient dans la pièce ; 0 : coupé à son image.
@export_range(0.0, 4.0) var cut_offset: float = 0.0:
	set(value):
		cut_offset = maxf(value, 0.0)
		_queue_rebuild()


func rebuild() -> void:
	super.rebuild()
	if texture == null:
		return
	_quad.mesh = InteriorRoom.panel_mesh(size_m(), cut_z(), cut_height, flip_h != view_flipped())
	_quad.material_override = InteriorRoom.furniture_material(displayed_texture(), glow, tint)


## z (monde) du bord sud du meuble : le plan de son image, sa coordonnée de coupe.
func front_z() -> float:
	if is_inside_tree():
		return global_position.z + image_offset.z * global_basis.get_scale().z
	return position.z + image_offset.z * scale.z


## (T2) z (monde) de la coordonnée de coupe : le bord sud, plus cut_offset.
func cut_z() -> float:
	return front_z() + cut_offset


## Rectangle de l'image dans le monde (deux triangles) tel qu'il se dessine quand la coupe
## d'InteriorRoom est à cut_line (z du monde) : entier, ou sous cut_height ; (T2) tourné comme le
## nœud si keep_orientation (le grand miroir sur un mur ouest).
func occluder_triangles(cut_line: float) -> PackedVector3Array:
	var size := size_m() * Vector2(global_basis.get_scale().x, global_basis.get_scale().y)
	var top := size.y
	var furniture_line := cut_line
	var material := _quad.material_override as ShaderMaterial if _quad != null else null
	if material != null:
		furniture_line = minf(cut_line, float(material.get_shader_parameter(&"furniture_cut_line")))
	if cut_z() >= furniture_line - InteriorRoom.CUT_MARGIN:
		top = minf(top, cut_height)
	var base := global_position + image_offset * global_basis.get_scale()
	var along := global_basis.x.normalized() if keep_orientation else Vector3.RIGHT
	var left := base - along * size.x / 2.0
	var right := base + along * size.x / 2.0
	var up := Vector3.UP * top
	return PackedVector3Array([left, right, right + up, left, right + up, left + up])
