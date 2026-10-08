@tool
class_name SkyDrift
extends Node3D
## (H9) Ciel qui dérive (docs/ASSETS_HD2D_MONDE.md, sections 3.8, 13 et 14) : des panneaux
## lointains (nuages, îles, dirigeables en vol, à 48 ou 24 px par mètre) glissent lentement
## d'ouest en est le long de l'axe x du nœud, sur des trajets de span m centrés sur lui, à des
## reculs (vers le nord, −z) et des hauteurs tirés dans distance_range et height_range, et
## reviennent en boucle. Le nœud se pose loin au nord de l'île, là où regarde la caméra, plus bas
## que le sol (on voit le ciel au-dessus de la mer de nuages par-delà le bord nord).
##
## Coût négligeable : tout le mouvement est dans le shader (sky_drift.gdshader, TIME) ; un mesh
## fixe par image (un draw call), écarté par la caméra hors champ (boîte du trajet entier). Pas de
## collision. Le matériau est porté par le mesh (pas en material_override) : un PropBatcher
## parent (nœud Decor de l'île) ne le fond pas. Enfants internes « Drift<n> », recréés au
## chargement (aussi dans l'éditeur, où les voyageurs dérivent déjà).

const SHADER := preload("res://src/world/shaders/sky_drift.gdshader")

## Images des voyageurs, tirées tour à tour (un draw call par image différente ; une image
## répétée dans la liste revient plus souvent).
@export var textures: Array[Texture2D] = []:
	set(value):
		textures = value
		_queue_rebuild()
## Densité des images (px par mètre) : 48 pour les nuages, 24 pour les dirigeables en vol.
@export var pixels_per_meter: float = 48.0:
	set(value):
		pixels_per_meter = maxf(value, 1.0)
		_queue_rebuild()
## Nombre de voyageurs.
@export_range(0, 64) var count: int = 6:
	set(value):
		count = value
		_queue_rebuild()
## Longueur du trajet d'ouest en est (m), centré sur le nœud ; chacun revient en boucle.
@export var span: float = 600.0:
	set(value):
		span = maxf(value, 1.0)
		_queue_rebuild()
## Fondu aux deux bouts du trajet (m).
@export var fade: float = 40.0:
	set(value):
		fade = maxf(value, 0.0)
		_queue_rebuild()
## Recul de chaque voyageur vers le nord (m, −z du nœud) : entre x et y.
@export var distance_range: Vector2 = Vector2(0.0, 60.0):
	set(value):
		distance_range = value
		_queue_rebuild()
## Hauteur de chaque voyageur (m, y du nœud) : entre x et y.
@export var height_range: Vector2 = Vector2(-8.0, 8.0):
	set(value):
		height_range = value
		_queue_rebuild()
## Vitesse vers l'est (m/s) : entre x et y.
@export var speed_range: Vector2 = Vector2(1.0, 3.0):
	set(value):
		speed_range = value
		_queue_rebuild()
## Échelle de chaque voyageur : entre x et y.
@export var scale_range: Vector2 = Vector2.ONE:
	set(value):
		scale_range = value
		_queue_rebuild()
## Teinte multipliée (son alpha : opacité).
@export var tint: Color = Color.WHITE:
	set(value):
		tint = value
		_queue_rebuild()
## Graine des tirages.
@export var random_seed: int = 0:
	set(value):
		random_seed = value
		_queue_rebuild()

var _meshes: Array[MeshInstance3D] = []
var _queued: bool = false


func _ready() -> void:
	rebuild()


## Recrée un mesh par image à partir des données.
func rebuild() -> void:
	_queued = false
	for node in _meshes:
		if is_instance_valid(node):
			remove_child(node)
			node.queue_free()
	_meshes.clear()
	# Tour à tour dans textures (une image répétée y revient plus souvent), un mesh par image.
	var turns: Array[Texture2D] = []
	var images: Array[Texture2D] = []
	for source: Texture2D in textures:
		if source != null:
			turns.append(source)
			if not source in images:
				images.append(source)
	if images.is_empty() or count <= 0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = random_seed
	var tools: Array[SurfaceTool] = []
	for _k in images.size():
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		tools.append(st)
	var low := Vector3(-span / 2.0, INF, INF)
	var high := Vector3(span / 2.0, -INF, -INF)
	for i in count:
		var image := turns[i % turns.size()]
		var size := Vector2(image.get_size()) / pixels_per_meter
		size *= rng.randf_range(scale_range.x, scale_range.y)
		var at := Vector3(
			0.0,
			rng.randf_range(height_range.x, height_range.y),
			-rng.randf_range(distance_range.x, distance_range.y)
		)
		var travel := Vector2(rng.randf() * span, rng.randf_range(speed_range.x, speed_range.y))
		_add_quad(tools[images.find(image)], at, size, travel)
		low = Vector3(low.x, minf(low.y, at.y), minf(low.z, at.z))
		high = Vector3(high.x, maxf(high.y, at.y + size.y), maxf(high.z, at.z))
	var bounds := AABB(low - Vector3(32.0, 0.0, 1.0), high - low + Vector3(64.0, 0.0, 2.0))
	for k in images.size():
		var mesh := tools[k].commit()
		if mesh.get_surface_count() == 0:
			continue
		var material := ShaderMaterial.new()
		material.shader = SHADER
		material.set_shader_parameter(&"albedo_texture", images[k])
		material.set_shader_parameter(&"tint", tint)
		material.set_shader_parameter(&"span", span)
		material.set_shader_parameter(&"fade", fade)
		material.set_shader_parameter(&"hd2d_relief", 0.0)
		mesh.surface_set_material(0, material)
		var node := MeshInstance3D.new()
		node.name = "Drift%d" % k
		node.mesh = mesh
		node.custom_aabb = bounds
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node, false, Node.INTERNAL_MODE_FRONT)
		_meshes.append(node)


## Meshes des images (un par image), pour les tests.
func meshes() -> Array[MeshInstance3D]:
	return _meshes.duplicate()


## Position x (m, le long du trajet) d'un voyageur parti de start à speed m/s, au temps time (s) :
## celle que calcule sky_drift.gdshader.
static func drift_x(start: float, speed: float, time: float, length: float) -> float:
	return fposmod(start + time * speed, length) - length / 2.0


## Quad d'un voyageur, debout face au sud, ancre au milieu du bord bas en at.
static func _add_quad(st: SurfaceTool, at: Vector3, size: Vector2, travel: Vector2) -> void:
	var half := size.x / 2.0
	var corners: Array[Vector3] = [
		at + Vector3(-half, 0.0, 0.0),
		at + Vector3(half, 0.0, 0.0),
		at + Vector3(half, size.y, 0.0),
		at + Vector3(-half, size.y, 0.0),
	]
	var uvs: Array[Vector2] = [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
	for k: int in [0, 2, 1, 0, 3, 2]:
		st.set_normal(Vector3.BACK)
		st.set_uv(uvs[k])
		st.set_uv2(travel)
		st.add_vertex(corners[k])


func _queue_rebuild() -> void:
	if _queued or not is_inside_tree():
		return
	_queued = true
	rebuild.call_deferred()
