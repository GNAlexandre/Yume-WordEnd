@tool
class_name InteriorPanel
extends DecorPanel
## (E3) Meuble ou objet d'intérieur : un DecorPanel (même image, même ancre, même ombre, même
## collision dans l'enfant « Collision ») dont le matériau est celui des intérieurs
## (InteriorRoom.panel_material, interior_panel.gdshader) : il prend la lumière de la pièce
## (fenêtres, lampes) et se coupe avec les murs. Quand la coupe d'InteriorRoom passe au nord de
## son bord sud (l'image, posée à image_offset), il n'est plus dessiné qu'au-dessous de
## cut_height : un meuble au sud du joueur ne le cache jamais. Les meubles d'une même image se
## fondent en un draw call (PropBatcher : la coordonnée de coupe et cut_height voyagent dans UV2
## des sommets). Racine des scènes de meubles de src/world/props/ (tools/hd2d_interior.py
## scenes) : le nœud est au milieu de l'emprise, l'image au bord sud (image_offset.z = la moitié
## de la profondeur), la boîte de collision sur l'emprise.
##
## Ni bande animée, ni premier plan, ni décalage vers la caméra : frames, fps, foreground et
## depth_offset sont sans effet ici.

## Hauteur gardée quand la coupe passe (m) : les tables, bancs et lits restent entiers, les
## armoires et rayonnages ne montrent que leur bas.
@export_range(0.0, 4.0) var cut_height: float = InteriorRoom.PROP_CUT_HEIGHT:
	set(value):
		cut_height = maxf(value, 0.0)
		_queue_rebuild()


func rebuild() -> void:
	super.rebuild()
	if texture == null:
		return
	_quad.mesh = InteriorRoom.panel_mesh(size_m(), front_z(), cut_height)
	_quad.material_override = InteriorRoom.panel_material(texture, glow, tint)


## z (monde) du bord sud du meuble : le plan de son image, sa coordonnée de coupe.
func front_z() -> float:
	if is_inside_tree():
		return global_position.z + image_offset.z * global_basis.get_scale().z
	return position.z + image_offset.z * scale.z


## Rectangle de l'image dans le monde (deux triangles) tel qu'il se dessine quand la coupe
## d'InteriorRoom est à cut_line (z du monde) : entier, ou sous cut_height.
func occluder_triangles(cut_line: float) -> PackedVector3Array:
	var size := size_m() * Vector2(global_basis.get_scale().x, global_basis.get_scale().y)
	var top := size.y
	if front_z() >= cut_line - InteriorRoom.CUT_MARGIN:
		top = minf(top, cut_height)
	var base := global_position + image_offset * global_basis.get_scale()
	var left := base + Vector3.LEFT * size.x / 2.0
	var right := base + Vector3.RIGHT * size.x / 2.0
	var up := Vector3.UP * top
	return PackedVector3Array([left, right, right + up, left, right + up, left + up])
