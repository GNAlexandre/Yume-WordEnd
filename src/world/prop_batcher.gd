class_name PropBatcher
extends Node3D
## Décor statique d'une zone (nœud « Geometry ») : au lancement, regroupe les MeshInstance3D de
## tous ses descendants (y compris les décors posés par PropScatter) en un MultiMeshInstance3D
## par mesh partagé de src/world/props/meshes/ : un draw call par forme et par zone, couleur
## par instance (albedo du matériau d'origine). Les collisions des décors ne bougent pas.
##
## Sont regroupés les meshes à une surface dont le matériau est un StandardMaterial3D (ou
## absent) ; les autres (ShaderMaterial…) restent tels quels. Un matériau non éclairé
## (shading_mode = UNSHADED : fenêtres, lanternes) passe dans le lot « glow ».
## Dans l'éditeur, rien n'est regroupé : on voit et on déplace les décors un par un.

const TOON := preload("res://src/world/materials/toon.tres")
const GLOW := preload("res://src/world/materials/glow.tres")

## Variation de luminosité par instance (0 = aucune), pour que les copies ne soient pas
## identiques ; tirée de la position, donc stable.
@export_range(0.0, 0.3) var color_jitter: float = 0.06


class _Lot:
	var mesh: Mesh
	var unshaded: bool
	var shadow: GeometryInstance3D.ShadowCastingSetting
	var transforms: Array[Transform3D] = []
	var colors: PackedColorArray = PackedColorArray()


func _ready() -> void:
	batch()


## Regroupe les meshes des descendants ; renvoie le nombre de MultiMeshInstance3D créés.
func batch() -> int:
	var lots: Dictionary[String, _Lot] = {}
	var instances: Array[MeshInstance3D] = []
	_collect(self, instances)
	var inverse := global_transform.affine_inverse()
	for instance in instances:
		var material := _source_material(instance)
		var unshaded := material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED
		var key := "%d/%s/%d" % [instance.mesh.get_instance_id(), unshaded, instance.cast_shadow]
		var lot: _Lot = lots.get(key)
		if lot == null:
			lot = _Lot.new()
			lot.mesh = instance.mesh
			lot.unshaded = unshaded
			lot.shadow = instance.cast_shadow
			lots[key] = lot
		var xform := inverse * instance.global_transform
		lot.transforms.append(xform)
		lot.colors.append(_jittered(material.albedo_color, xform.origin))
		instance.mesh = null
	for lot: _Lot in lots.values():
		add_child(_multimesh_instance(lot))
	return lots.size()


func _collect(node: Node, out: Array[MeshInstance3D]) -> void:
	for child: Node in node.get_children(true):
		var instance := child as MeshInstance3D
		if (
			instance != null
			and instance.mesh != null
			and instance.mesh.get_surface_count() == 1
			and instance.is_visible_in_tree()
			and _source_material(instance) != null
		):
			out.append(instance)
		_collect(child, out)


## Matériau effectif de la surface 0 : StandardMaterial3D, défaut blanc si aucun, null sinon.
static func _source_material(instance: MeshInstance3D) -> StandardMaterial3D:
	var material := instance.material_override
	if material == null:
		material = instance.get_surface_override_material(0)
	if material == null:
		material = instance.mesh.surface_get_material(0)
	if material == null:
		return StandardMaterial3D.new()
	return material as StandardMaterial3D


func _jittered(color: Color, origin: Vector3) -> Color:
	var noise := sin(origin.x * 12.9898 + origin.z * 78.233 + origin.y * 3.71) * 43758.5453
	var factor := 1.0 + color_jitter * (2.0 * (noise - floorf(noise)) - 1.0)
	return Color(color.r * factor, color.g * factor, color.b * factor, color.a)


func _multimesh_instance(lot: _Lot) -> MultiMeshInstance3D:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = lot.mesh
	multimesh.instance_count = lot.transforms.size()
	for i in lot.transforms.size():
		multimesh.set_instance_transform(i, lot.transforms[i])
		multimesh.set_instance_color(i, lot.colors[i])
	var node := MultiMeshInstance3D.new()
	node.name = "Batch_%s" % lot.mesh.resource_path.get_file().get_basename()
	node.multimesh = multimesh
	node.material_override = GLOW if lot.unshaded else TOON
	node.cast_shadow = lot.shadow
	return node
