class_name PropBatcher
extends Node3D
## Décor statique d'une zone (nœud « Geometry ») : au lancement, fond les MeshInstance3D de tous
## ses descendants (y compris les décors posés par PropScatter) en quelques meshes à couleurs de
## sommets, un par famille : éclairé qui projette une ombre, éclairé sans ombre, « glow » non
## éclairé (fenêtres, cristaux). Chaque famille peut être découpée en cases de cell_size m pour
## que la caméra et la carte d'ombre écartent le décor hors champ. Couleur de chaque copie =
## albedo de son matériau d'origine (± color_jitter). Les collisions des décors ne bougent pas.
##
## Sont fondus les meshes à une surface dont le matériau est un StandardMaterial3D (ou absent) ;
## les autres (ShaderMaterial…) restent tels quels. Un matériau non éclairé (shading_mode =
## UNSHADED) passe dans la famille « glow ». Une copie en miroir (déterminant négatif) garde ses
## faces vers l'extérieur. Dans l'éditeur, rien n'est fondu : on voit et on déplace les décors
## un par un.
##
## Avant l'acte 1, un MultiMeshInstance3D par mesh unité et par zone : une dizaine de draw calls
## par zone (trois passes chacun) ; fondu, trois par zone et par case.

const TOON := preload("res://src/world/materials/toon.tres")
const GLOW := preload("res://src/world/materials/glow.tres")

## Matériau blanc des meshes sans matériau.
static var _default_material := StandardMaterial3D.new()
## Triangles à plat de chaque mesh fondu : [sommets, normales, sommets en miroir, normales en
## miroir], calculés une fois par mesh.
static var _soups: Dictionary = {}

## Variation de luminosité par copie (0 = aucune), pour que les copies ne soient pas
## identiques ; tirée de la position, donc stable.
@export_range(0.0, 0.3) var color_jitter: float = 0.06
## Côté (m) des cases du découpage, dans le repère du nœud ; 0 : une seule case.
@export_range(0.0, 200.0) var cell_size: float = 0.0


class _Lot:
	var unshaded: bool
	var shadow: GeometryInstance3D.ShadowCastingSetting
	var cell: Vector2i
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()


func _ready() -> void:
	batch()


## Fond les meshes des descendants ; renvoie le nombre de meshes créés.
func batch() -> int:
	var lots: Dictionary[String, _Lot] = {}
	var instances: Array[MeshInstance3D] = []
	_collect(self, instances)
	var inverse := global_transform.affine_inverse()
	for instance in instances:
		var material := _source_material(instance)
		var unshaded := material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED
		var xform := inverse * instance.global_transform
		var cell := Vector2i.ZERO
		if cell_size > 0.0:
			cell = Vector2i(floori(xform.origin.x / cell_size), floori(xform.origin.z / cell_size))
		var key := "%s/%d/%s" % [unshaded, instance.cast_shadow, cell]
		var lot: _Lot = lots.get(key)
		if lot == null:
			lot = _Lot.new()
			lot.unshaded = unshaded
			lot.shadow = instance.cast_shadow
			lot.cell = cell
			lots[key] = lot
		_append(lot, instance.mesh, xform, _jittered(material.albedo_color, xform.origin))
		instance.mesh = null
	for lot: _Lot in lots.values():
		add_child(_mesh_instance(lot))
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


## Ajoute au lot les triangles du mesh placés par xform, d'une seule couleur.
static func _append(lot: _Lot, mesh: Mesh, xform: Transform3D, color: Color) -> void:
	var soup := _soup(mesh)
	var mirrored := xform.basis.determinant() < 0.0
	var vertices: PackedVector3Array = soup[2] if mirrored else soup[0]
	var normals: PackedVector3Array = soup[3] if mirrored else soup[1]
	lot.vertices.append_array(xform * vertices)
	lot.normals.append_array(
		Transform3D(xform.basis.inverse().transposed(), Vector3.ZERO) * normals
	)
	var colors := PackedColorArray()
	colors.resize(vertices.size())
	colors.fill(color)
	lot.colors.append_array(colors)


## Triangles à plat du mesh (sans index), et les mêmes en ordre inverse pour les copies en
## miroir.
static func _soup(mesh: Mesh) -> Array:
	if _soups.has(mesh):
		return _soups[mesh]
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	if indices.is_empty():
		indices = PackedInt32Array(range(vertices.size()))
	var flat_vertices := PackedVector3Array()
	var flat_normals := PackedVector3Array()
	var mirror_vertices := PackedVector3Array()
	var mirror_normals := PackedVector3Array()
	for n in range(0, indices.size() - 2, 3):
		for k: int in [0, 1, 2]:
			var index := indices[n + k]
			var mirror := indices[n + [0, 2, 1][k]]
			flat_vertices.append(vertices[index])
			flat_normals.append(normals[index])
			mirror_vertices.append(vertices[mirror])
			mirror_normals.append(normals[mirror])
	var soup := [flat_vertices, flat_normals, mirror_vertices, mirror_normals]
	_soups[mesh] = soup
	return soup


## Matériau effectif de la surface 0 : StandardMaterial3D, défaut blanc si aucun, null sinon.
static func _source_material(instance: MeshInstance3D) -> StandardMaterial3D:
	var material := instance.material_override
	if material == null:
		material = instance.get_surface_override_material(0)
	if material == null:
		material = instance.mesh.surface_get_material(0)
	if material == null:
		return _default_material
	return material as StandardMaterial3D


func _jittered(color: Color, origin: Vector3) -> Color:
	var noise := sin(origin.x * 12.9898 + origin.z * 78.233 + origin.y * 3.71) * 43758.5453
	var factor := 1.0 + color_jitter * (2.0 * (noise - floorf(noise)) - 1.0)
	return Color(color.r * factor, color.g * factor, color.b * factor, color.a)


func _mesh_instance(lot: _Lot) -> MeshInstance3D:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = lot.vertices
	arrays[Mesh.ARRAY_NORMAL] = lot.normals
	arrays[Mesh.ARRAY_COLOR] = lot.colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var node := MeshInstance3D.new()
	node.name = (
		"Batch%s%s_%d_%d"
		% [
			"_glow" if lot.unshaded else "",
			"_no_shadow" if lot.shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF else "",
			lot.cell.x,
			lot.cell.y,
		]
	)
	node.mesh = mesh
	node.material_override = GLOW if lot.unshaded else TOON
	node.cast_shadow = lot.shadow
	return node
