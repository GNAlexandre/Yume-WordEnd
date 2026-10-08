extends Node
## Découpe du décor du village autour du joueur (Lot H2) : aucun panneau ni bâtiment ne le cache,
## même derrière un arbre, le porche ou les draps. Nœud « SeeThrough » de village.tscn, placé
## après « Geometry » : à son _ready, le PropBatcher a déjà fondu le décor en meshes « Batch… ».
## Chaque matériau de panneau de ces meshes (src/world/shaders/panel.gdshader, H5) est remplacé
## par une copie dont le shader est panel.gdshader augmenté de la découpe
## (see_through.gdshaderinc) : autant de matériaux qu'avant, pas un draw call de plus. À chaque
## image, le centre de la découpe suit le corps du joueur (groupe « player ») ; le décor plus
## proche de la caméra que lui s'efface en trame dans une ellipse autour de lui.
##
## Le shader est construit au lancement à partir du code de panel.gdshader : il en suit les
## changements (lumière, lueur). Si ce code n'a plus de fonction fragment, push_error et pas de
## découpe (les tests le voient).

const PANEL_SHADER := preload("res://src/world/shaders/panel.gdshader")
## Référencé ici pour qu'il parte dans l'export avec le script (le shader l'inclut par son chemin).
const INCLUDE := preload("res://src/world/zones/village/see_through.gdshaderinc")
## Ligne ajoutée à la fin de la fonction fragment du panneau.
const CUT_CODE := (
	"\tif (see_through_amount(VERTEX, VIEW_MATRIX) > see_through_dither(FRAGCOORD.xy)) {\n"
	+ "\t\tALPHA = 0.0;\n\t}\n"
)

static var _shader: Shader

## Nœud du décor fondu (PropBatcher) dont les matériaux reçoivent la découpe.
@export var geometry_path: NodePath = ^"../Geometry"
## Hauteur du centre de la découpe au-dessus des pieds du joueur (m).
@export var center_height: float = 0.75
## Demi-largeur et demi-hauteur de l'ellipse (m) : le corps et l'épée.
@export var cut_size: Vector2 = Vector2(0.8, 1.1)
## Profondeur (m) devant le joueur sur laquelle la découpe s'installe.
@export var cut_depth: float = 0.35

var _materials: Array[ShaderMaterial] = []
var _player: Node3D
var _center: Vector3 = Vector3.INF
var _strength: float = -1.0


func _ready() -> void:
	var geometry := get_node_or_null(geometry_path)
	if geometry != null:
		convert_materials(geometry)
	_apply(Vector3.ZERO, 0.0)


func _process(_delta: float) -> void:
	var player := _find_player()
	if player == null:
		_apply(Vector3.ZERO, 0.0)
	else:
		_apply(player.global_position + Vector3.UP * center_height, 1.0)


## Remplace les matériaux de panneau des meshes fondus de geometry par leur copie à découpe ;
## renvoie le nombre de matériaux copiés.
func convert_materials(geometry: Node) -> int:
	var copies := {}
	for child: Node in geometry.get_children():
		var mesh := child as MeshInstance3D
		if mesh == null:
			continue
		var source := mesh.material_override as ShaderMaterial
		if source == null or source.shader != PANEL_SHADER:
			continue
		if not copies.has(source):
			var copy := see_through_material(source)
			copies[source] = copy
			_materials.append(copy)
		mesh.material_override = copies[source]
	return copies.size()


## Matériaux à découpe de ce village (pour les tests).
func materials() -> Array[ShaderMaterial]:
	return _materials.duplicate()


## Copie à découpe d'un matériau de panneau : mêmes uniformes, shader see_through_shader().
static func see_through_material(source: ShaderMaterial) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = see_through_shader()
	material.render_priority = source.render_priority
	for uniform: Dictionary in source.shader.get_shader_uniform_list():
		var uniform_name := StringName(uniform["name"])
		var value: Variant = source.get_shader_parameter(uniform_name)
		if value != null:
			material.set_shader_parameter(uniform_name, value)
	return material


## Shader des panneaux à découpe (construit une fois à partir de panel.gdshader).
static func see_through_shader() -> Shader:
	if _shader == null:
		var code := inject(PANEL_SHADER.code)
		if code.is_empty():
			push_error("SeeThrough : panel.gdshader sans fonction fragment, pas de découpe")
			return PANEL_SHADER
		_shader = Shader.new()
		_shader.code = code
	return _shader


## Code d'un shader de panneau augmenté de la découpe : l'inclusion avant la fonction fragment,
## l'effacement à sa fin ; "" si le code n'a pas de fonction fragment.
static func inject(source: String) -> String:
	var start := source.find("void fragment()")
	if start < 0:
		return ""
	var close := _closing_brace(source, source.find("{", start))
	if close < 0:
		return ""
	return (
		source.substr(0, start)
		+ '#include "%s"\n\n' % INCLUDE.resource_path
		+ source.substr(start, close - start)
		+ CUT_CODE
		+ source.substr(close)
	)


## Indice de l'accolade qui ferme celle de `open` (commentaires ignorés) ; -1 sinon.
static func _closing_brace(source: String, open: int) -> int:
	if open < 0:
		return -1
	var depth := 0
	var i := open
	while i < source.length():
		if source.substr(i, 2) == "//":
			i = source.find("\n", i)
			if i < 0:
				return -1
		elif source.substr(i, 2) == "/*":
			i = source.find("*/", i)
			if i < 0:
				return -1
			i += 1
		elif source[i] == "{":
			depth += 1
		elif source[i] == "}":
			depth -= 1
			if depth == 0:
				return i
		i += 1
	return -1


func _apply(center: Vector3, strength: float) -> void:
	if center == _center and strength == _strength:
		return
	_center = center
	_strength = strength
	for material: ShaderMaterial in _materials:
		material.set_shader_parameter(&"see_through_center", center)
		material.set_shader_parameter(&"see_through_size", cut_size)
		material.set_shader_parameter(&"see_through_depth", cut_depth)
		material.set_shader_parameter(&"see_through_strength", strength)


func _find_player() -> Node3D:
	if _player == null or not is_instance_valid(_player) or not _player.is_inside_tree():
		_player = get_tree().get_first_node_in_group(&"player") as Node3D
	return _player
