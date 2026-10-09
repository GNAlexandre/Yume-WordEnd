@tool
class_name GroundDecal
extends Node3D
## (H9) Décalque au sol HD-2D (docs/ASSETS_HD2D_MONDE.md, sections 3.3 et 5) : ce qui est posé à
## plat sur le sol (feuilles, flaques, fissures, ombres de feuillage, taches de soleil, brume),
## image vue de dessus à pixels_per_meter px par mètre, ancre au centre (origine du nœud), haut
## de l'image au nord. Racine possible d'une scène de décor de src/world/props/ ; sans collision.
##
## - Couché sur le relief de l'île : le mesh reprend exactement les triangles du sol sous lui
##   (IslandTerrain.triangles_in, découpés au bord du décalque), leurs normales comprises : il
##   reçoit la lumière comme le sol ; follow_ground faux : à plat à la hauteur du nœud. (E2) Sur
##   une carte extérieure, ce sont les triangles de son sol en relief (MapGround.triangles_in : le
##   nœud « Ground » de la carte qui porte le décalque).
## - Rotation libre autour de Y et échelle (x, z) du nœud, flip_h : la même image varie.
## - Jamais de scintillement : le shader tire le décalque vers la caméra (au-dessus du sol), plus
##   par couche (layer : les plus hautes dessus) et d'une part propre à l'exemplaire (UV2) ; les
##   décalques doux (soft_alpha : mélange au lieu d'alpha découpé) sont dessinés sous les ombres
##   des panneaux et sous les personnages, dans l'ordre des couches (priorité de rendu).
## - Fondu par image par le PropBatcher de la zone (material_override, un matériau par image,
##   teinte et, pour un décalque doux, couche).
## L'enfant interne « Mesh » est recréé au chargement (aussi dans l'éditeur) et quand le nœud
## bouge, en coordonnées du monde (top_level) : seules les données ci-dessous sont enregistrées.

const HARD_SHADER := preload("res://src/world/shaders/ground_decal.gdshader")
const SOFT_SHADER := preload("res://src/world/shaders/ground_decal_soft.gdshader")
## Couche la plus haute.
const MAX_LAYER := 7
## Priorité de rendu d'un décalque doux de couche 0 (+ couche) : sous les ombres des panneaux
## (DecorPanel.shadow_material, -1) et sous les personnages (0).
const SOFT_PRIORITY := -9

## Matériaux partagés : clé (image, teinte, doux, couche d'un doux) → WeakRef du ShaderMaterial
## ((E1) références faibles, comme DecorPanel : une carte quittée libère ses images).
static var _materials: Dictionary = {}

## Image du décalque (vue de dessus, fond transparent, bord irrégulier).
@export var texture: Texture2D:
	set(value):
		texture = value
		_queue_rebuild()
## Densité de l'image (px par mètre).
@export var pixels_per_meter: float = DecorPanel.PIXELS_PER_METER:
	set(value):
		pixels_per_meter = maxf(value, 1.0)
		_queue_rebuild()
## Alpha doux (ombres de feuillage, taches de soleil, brume) : mélange au lieu d'alpha découpé.
@export var soft_alpha: bool = false:
	set(value):
		soft_alpha = value
		_queue_rebuild()
## Teinte multipliée ; son alpha règle l'opacité d'un décalque doux.
@export var tint: Color = Color.WHITE:
	set(value):
		tint = value
		_queue_rebuild()
## Image retournée gauche-droite.
@export var flip_h: bool = false:
	set(value):
		flip_h = value
		_queue_rebuild()
## Ordre de dessin des décalques superposés (0 à MAX_LAYER, les plus hautes dessus).
@export_range(0, 7) var layer: int = 0:
	set(value):
		layer = clampi(value, 0, MAX_LAYER)
		_queue_rebuild()
## Suivre le relief de l'île (sinon à plat, à la hauteur du nœud).
@export var follow_ground: bool = true:
	set(value):
		follow_ground = value
		_queue_rebuild()

var _mesh: MeshInstance3D
var _queued: bool = false


func _ready() -> void:
	# Déplacé (dans l'éditeur, ou en jeu avant que la scène ne se fige) : recouché sur le sol.
	set_notify_transform(true)
	rebuild()


## Taille de l'image dans le monde (m), avant l'échelle du nœud.
func size_m() -> Vector2:
	if texture == null:
		return Vector2.ZERO
	return Vector2(texture.get_size()) / pixels_per_meter


## Recrée le mesh couché sur le sol à partir des données (dans l'arbre seulement).
func rebuild() -> void:
	_queued = false
	if _mesh == null:
		_mesh = MeshInstance3D.new()
		_mesh.name = &"Mesh"
		_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_mesh.top_level = true
		add_child(_mesh, false, Node.INTERNAL_MODE_FRONT)
	_mesh.visible = texture != null and is_inside_tree()
	if not _mesh.visible:
		_mesh.mesh = null
		return
	_mesh.global_transform = Transform3D.IDENTITY
	_mesh.mesh = draped_mesh()
	_mesh.material_override = material_for(texture, tint, soft_alpha, layer)


## Mesh du décalque en coordonnées du monde : les triangles du sol sous lui, découpés à son bord
## (ou un rectangle à plat), UV de l'image, UV2 = (part de l'exemplaire, couche).
func draped_mesh() -> ArrayMesh:
	var size := size_m()
	var center := global_position
	var axis_x := Vector2(global_basis.x.x, global_basis.x.z) * size.x
	var axis_z := Vector2(global_basis.z.x, global_basis.z.z) * size.y
	var frame := Transform2D(axis_x, axis_z, Vector2(center.x, center.z)).affine_inverse()
	var corners: Array[Vector2] = []
	for corner: Vector2 in [Vector2(-0.5, -0.5), Vector2(0.5, -0.5), Vector2(-0.5, 0.5)]:
		corners.append(Vector2(center.x, center.z) + axis_x * corner.x + axis_z * corner.y)
	corners.append(Vector2(center.x, center.z) + axis_x * 0.5 + axis_z * 0.5)
	var points := PackedVector3Array()
	var normals := PackedVector3Array()
	if follow_ground:
		var bounds := Rect2(corners[0], Vector2.ZERO)
		for corner in corners:
			bounds = bounds.expand(corner)
		var ground := _ground_triangles(bounds)
		points = ground[0]
		normals = ground[1]
	else:
		# Nord-ouest, nord-est, sud-ouest, sud-est : deux triangles comme ceux du sol.
		for k: int in [0, 1, 2, 1, 3, 2]:
			points.append(Vector3(corners[k].x, center.y, corners[k].y))
			normals.append(Vector3.UP)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var extra := Vector2(DecorPanel.phase_at(center), float(layer))
	for n in range(0, points.size(), 3):
		var polygon := _clip_triangle(points, normals, n, frame)
		for k in range(1, polygon.size() - 1):
			for corner: Array in [polygon[0], polygon[k], polygon[k + 1]]:
				var at := corner[2] as Vector2
				var u := 1.0 - (at.x + 0.5) if flip_h else at.x + 0.5
				st.set_normal(corner[1])
				st.set_uv(Vector2(u, at.y + 0.5))
				st.set_uv2(extra)
				st.add_vertex(corner[0])
	return st.commit()


## (E2) Triangles du sol sous bounds (plan x, z du monde) : ceux du sol en relief (MapGround) de la
## carte qui porte le décalque, sinon ceux de l'île (IslandTerrain) ; [sommets, normales].
func _ground_triangles(bounds: Rect2) -> Array[PackedVector3Array]:
	var node := get_parent()
	while node != null:
		var ground := node.get_node_or_null(^"Ground") as MapGround
		if ground != null:
			var offset := ground.global_position
			var local := Rect2(bounds.position - Vector2(offset.x, offset.z), bounds.size)
			var found := ground.triangles_in(local)
			var points: PackedVector3Array = found[0]
			for n in points.size():
				points[n] += offset
			return [points, found[1]]
		node = node.get_parent()
	return IslandTerrain.triangles_in(bounds)


## Matériau partagé d'une image (ground_decal.gdshader ou, doux, ground_decal_soft.gdshader, à
## la priorité de sa couche).
static func material_for(
	image: Texture2D, color: Color = Color.WHITE, soft: bool = false, soft_layer: int = 0
) -> Material:
	var key := "%s|%s|%d" % [DecorPanel.image_key(image), color.to_html(), int(soft)]
	if soft:
		key += "|%d" % soft_layer
	var material := DecorPanel.cached_material(_materials, key) as ShaderMaterial
	if material == null:
		material = ShaderMaterial.new()
		material.shader = SOFT_SHADER if soft else HARD_SHADER
		material.set_shader_parameter(&"albedo_texture", image)
		material.set_shader_parameter(&"tint", color)
		if soft:
			material.render_priority = SOFT_PRIORITY + soft_layer
		_materials[key] = weakref(material)
	return material


## Triangle n du sol découpé au rectangle du décalque (coordonnées locales u, v de -0,5 à 0,5) :
## polygone convexe de sommets [position, normale, (u, v)], dans le sens du triangle.
static func _clip_triangle(
	points: PackedVector3Array, normals: PackedVector3Array, n: int, frame: Transform2D
) -> Array[Array]:
	var polygon: Array[Array] = []
	for k in 3:
		var p := points[n + k]
		polygon.append([p, normals[n + k], frame * Vector2(p.x, p.z)])
	for edge: Vector3 in [
		Vector3(1.0, 0.0, 0.5),
		Vector3(-1.0, 0.0, 0.5),
		Vector3(0.0, 1.0, 0.5),
		Vector3(0.0, -1.0, 0.5)
	]:
		polygon = _clip(polygon, Vector2(edge.x, edge.y), edge.z)
		if polygon.is_empty():
			break
	return polygon


## Garde la part du polygone où dot(axis, uv) ≤ limit (Sutherland-Hodgman), en interpolant
## position, normale et uv sur les arêtes coupées.
static func _clip(polygon: Array[Array], axis: Vector2, limit: float) -> Array[Array]:
	var kept: Array[Array] = []
	for k in polygon.size():
		var a: Array = polygon[k]
		var b: Array = polygon[(k + 1) % polygon.size()]
		var da := axis.dot(a[2] as Vector2) - limit
		var db := axis.dot(b[2] as Vector2) - limit
		if da <= 0.0:
			kept.append(a)
		if (da <= 0.0) != (db <= 0.0):
			var t := da / (da - db)
			(
				kept
				. append(
					[
						(a[0] as Vector3).lerp(b[0] as Vector3, t),
						(a[1] as Vector3).lerp(b[1] as Vector3, t).normalized(),
						(a[2] as Vector2).lerp(b[2] as Vector2, t),
					]
				)
			)
	return kept


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		_queue_rebuild()


func _queue_rebuild() -> void:
	if _queued or not is_inside_tree():
		return
	_queued = true
	rebuild.call_deferred()
