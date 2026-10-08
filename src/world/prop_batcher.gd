class_name PropBatcher
extends Node3D
## Décor statique d'une zone (nœud « Geometry ») : au lancement, fond les meshes de tous ses
## descendants (panneaux DecorPanel, murs, toits et façades des Building, ombres au sol) en un
## mesh par matériau, c'est-à-dire par image : un draw call par image et par case. Chaque matériau
## peut être découpé en cases de cell_size m pour que la caméra écarte le décor hors champ. Les
## collisions des décors ne bougent pas. Dans l'éditeur, rien n'est fondu. Propriétaire : L2.
##
## Sont fondus les MeshInstance3D visibles à une surface qui portent un material_override (tous
## les décors HD-2D) ; les autres restent tels quels. Les meshes fondus s'appellent « Batch… ».

## Triangles à plat de chaque mesh fondu : [sommets, normales, UV], calculés une fois par mesh.
static var _soups: Dictionary = {}

## Côté (m) des cases du découpage, dans le repère du nœud ; 0 : une seule case.
@export_range(0.0, 200.0) var cell_size: float = 0.0


class _Lot:
	var material: Material
	var cell: Vector2i
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()


func _ready() -> void:
	if not Engine.is_editor_hint():
		batch()


## Fond les meshes des descendants ; renvoie le nombre de meshes créés.
func batch() -> int:
	var lots: Dictionary = {}
	var order: Array[String] = []
	var instances: Array[MeshInstance3D] = []
	_collect(self, instances)
	var inverse := global_transform.affine_inverse()
	for instance in instances:
		var xform := inverse * instance.global_transform
		var cell := Vector2i.ZERO
		if cell_size > 0.0:
			var at := inverse * instance.global_position
			cell = Vector2i(floori(at.x / cell_size), floori(at.z / cell_size))
		var key := "%s/%s" % [instance.material_override.get_instance_id(), cell]
		var lot: _Lot = lots.get(key)
		if lot == null:
			lot = _Lot.new()
			lot.material = instance.material_override
			lot.cell = cell
			lots[key] = lot
			order.append(key)
		_append(lot, instance.mesh, xform)
		instance.mesh = null
		instance.visible = false
	var index := 0
	for key in order:
		add_child(_mesh_instance(lots[key], index))
		index += 1
	return order.size()


func _collect(node: Node, out: Array[MeshInstance3D]) -> void:
	for child: Node in node.get_children(true):
		var instance := child as MeshInstance3D
		if (
			instance != null
			and instance.mesh != null
			and instance.mesh.get_surface_count() == 1
			and instance.material_override != null
			and instance.is_visible_in_tree()
		):
			out.append(instance)
		_collect(child, out)


## Ajoute au lot les triangles du mesh placés par xform.
static func _append(lot: _Lot, mesh: Mesh, xform: Transform3D) -> void:
	var soup := _soup(mesh)
	lot.vertices.append_array(xform * (soup[0] as PackedVector3Array))
	var normal_basis := Transform3D(xform.basis.inverse().transposed(), Vector3.ZERO)
	var normals := normal_basis * (soup[1] as PackedVector3Array)
	for n in normals.size():
		normals[n] = normals[n].normalized()
	lot.normals.append_array(normals)
	lot.uvs.append_array(soup[2])


## Triangles à plat du mesh (sans index) : sommets, normales, UV.
static func _soup(mesh: Mesh) -> Array:
	if _soups.has(mesh):
		return _soups[mesh]
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = (
		arrays[Mesh.ARRAY_TEX_UV] if arrays[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
	)
	var indices: PackedInt32Array = (
		arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	)
	if indices.is_empty():
		indices = PackedInt32Array(range(vertices.size()))
	var flat_vertices := PackedVector3Array()
	var flat_normals := PackedVector3Array()
	var flat_uvs := PackedVector2Array()
	for index in indices:
		flat_vertices.append(vertices[index])
		flat_normals.append(normals[index] if index < normals.size() else Vector3.UP)
		flat_uvs.append(uvs[index] if index < uvs.size() else Vector2.ZERO)
	var soup := [flat_vertices, flat_normals, flat_uvs]
	_soups[mesh] = soup
	return soup


func _mesh_instance(lot: _Lot, index: int) -> MeshInstance3D:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = lot.vertices
	arrays[Mesh.ARRAY_NORMAL] = lot.normals
	arrays[Mesh.ARRAY_TEX_UV] = lot.uvs
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var node := MeshInstance3D.new()
	node.name = "Batch%d_%d_%d" % [index, lot.cell.x, lot.cell.y]
	node.mesh = mesh
	node.material_override = lot.material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node
