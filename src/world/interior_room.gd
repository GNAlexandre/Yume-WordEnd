@tool
class_name InteriorRoom
extends StaticBody3D
## (E3) Le nœud Ground des cartes intérieures (docs/REFONTE.md, section 7.1) : un étage d'un
## bâtiment, décrit par son agencement (layout : data/maps/<map_id>/interior.json, lu par
## InteriorLayout ; format et mode d'emploi : PLAN.md, « Intérieurs »), bâti en images comme dans
## Octopath Traveler, vu par la caméra fixe qui regarde le nord :
## - sols : tuiles floor_* de 4 × 4 m, répétées sans raccord ;
## - murs : bandes wall_* de 4 × 3 m (plinthe et corniche), raccordées le long du mur ; le mur
##   nord d'une pièce est vu de face, les murs est et ouest de biais ; dessus des murs en wallcut_*;
## - coupe : tout ce qui est au sud de la première limite de pièce au sud du joueur (murs,
##   cloisons, portes, fenêtres, meubles InteriorPanel) n'est dessiné que sous sa hauteur de coupe
##   (CUT_HEIGHT pour les murs, qui ne montrent que leur épaisseur au ras du sol ;
##   PROP_CUT_HEIGHT pour les meubles) : le mur sud de la pièce du joueur n'est jamais dessiné et
##   rien ne le cache. La coupe glisse d'une limite à l'autre (CUT_SPEED) ; collisions inchangées ;
## - portes, fenêtres, éléments de mur : panneaux posés PANEL_GAP m devant le mur ;
## - pas de plafond ; collisions (couche 1) : le sol, les murs, les linteaux ;
## - lumière : chaud et plus sombre que dehors (préréglage « interieur » de la carte,
##   src/world/materials/lighting_interieur.tres), plus deux cartes de lumière vues de dessus,
##   bornées à leur pièce : le jour des fenêtres (flaques douces devant elles) et les lampes (halo
##   autour d'elles), ajoutées par interior_core.gdshaderinc aux sols, aux murs et aux panneaux ;
##   aucune ombre portée, aucune lumière du moteur : rien ne coûte un draw call de plus ;
## - un draw call par matière (sol, mur, dessus de mur, image de panneau), plus le vide autour.
## Moment de la journée (E9) : set_daylight(teinte, énergie), set_lamps(énergie), ou
## apply_phase(phase), appelée sur EventBus.day_phase_changed (PHASES).
## Enfants internes (meshes « Floor_… », « Walls_… », « Tops_… », « Panel_… », « Void », formes de
## collision) recréés au chargement, aussi dans l'éditeur (sans coupe).

const SHADER := preload("res://src/world/shaders/interior.gdshader")
const PANEL_SHADER := preload("res://src/world/shaders/interior_panel.gdshader")
const HORIZONTAL := InteriorLayout.HORIZONTAL
const NO_CUT := InteriorLayout.NO_CUT
## Une tuile de sol et une bande de mur couvrent 4 m ; la bande fait 3 m de haut.
const FLOOR_SPAN := 4.0
const WALL_SPAN := 4.0
const WALL_IMAGE_HEIGHT := 3.0
## Hauteurs gardées par la coupe (m) : murs (leur épaisseur au ras du sol), meubles.
const CUT_HEIGHT := 0.15
const PROP_CUT_HEIGHT := 1.0
## Ce qui est à moins de CUT_MARGIN m au nord de la ligne de coupe est coupé aussi (le poteau
## de l'angle, le bout des cloisons).
const CUT_MARGIN := 0.3
## Colonne de coupe : un mur nord-sud dont la ligne passe à moins de COLUMN_HALF m du joueur
## (il est dans une porte de ce mur) est coupé de COLUMN_FRONT à COLUMN_FRONT + COLUMN_LENGTH m
## au sud de lui (au-delà, le regard de la caméra passe au-dessus des murs).
const COLUMN_HALF := 0.33
const COLUMN_FRONT := 0.3
const COLUMN_LENGTH := 4.5
## Vitesse du glissement de la coupe (m/s) ; au-delà de CUT_SNAP m, elle saute.
const CUT_SPEED := 14.0
const CUT_SNAP := 9.0
## Écart des panneaux devant la face du mur (m).
const PANEL_GAP := 0.02
## Cartes de lumière : texels par mètre, échelle des valeurs (RGBA8 : valeur / LIGHT_SCALE).
const LIGHT_TEXELS := 4
const LIGHT_SCALE := 2.0
## Flaque de jour devant une fenêtre : intensité, profondeur (m), élargissement des bords (m).
const WINDOW_POOL := 0.85
const WINDOW_DEPTH := 3.6
const WINDOW_SPREAD := 0.9
## Halo d'une lampe d'énergie 1 en son centre.
const LAMP_POOL := 1.2
## Vide autour du bâtiment : marge (m) et couleur.
const VOID_MARGIN := 60.0
const VOID_COLOR := Color(0.055, 0.043, 0.04)
## Part du relief dans l'éclairage (hd2d_light.gdshaderinc).
const FLOOR_RELIEF := 0.5
const WALL_RELIEF := 0.6
## Lueur des vitres et des lampes de mur.
const WINDOW_GLOW := 0.5
const GLOWS := {"wallitem_wall_lamp": 1.6}
## Ce que suit la lueur d'un panneau (panel_material) : rien, le jour, les lampes.
const GLOW_STEADY := 0
const GLOW_DAYLIGHT := 1
const GLOW_LAMPS := 2
const PLAYER_GROUP := &"player"
## Parties du mesh des murs (UV2.y) : face, dessus d'un mur entier, dessus d'un mur coupé.
const PART_FACE := 0.0
const PART_TOP := 1.0
const PART_LOW := 2.0
## Moment de la journée (EventBus.day_phase_changed) : [teinte du jour, énergie des fenêtres,
## énergie des lampes].
const PHASES := {
	&"morning": [Color(1.0, 0.97, 0.9), 1.25, 0.3],
	&"day": [Color(1.0, 0.93, 0.8), 1.0, 0.6],
	&"evening": [Color(1.0, 0.68, 0.45), 0.6, 1.0],
	&"night": [Color(0.5, 0.6, 0.95), 0.2, 1.25],
}

## Matériaux des panneaux, partagés par image (portes, fenêtres, éléments, meubles InteriorPanel :
## le PropBatcher fond les meubles d'une même image en un draw call) et meshes des meubles, en
## références faibles (WeakRef, comme les caches de DecorPanel) : rien ne reste d'une carte
## quittée ; uniformes partagés par la pièce chargée (cartes de lumière, coupe), oubliés quand
## elle part.
static var _panel_materials: Dictionary = {}
static var _panel_meshes: Dictionary = {}
static var _shared: Dictionary = {}
## Pièce qui a posé les uniformes partagés en dernier (son instance_id).
static var _shared_owner: int = 0

## Agencement de l'étage (data/maps/<map_id>/interior.json).
@export var layout: JSON:
	set(value):
		layout = value
		_queue_rebuild()
## Coupe au sud du joueur (dans l'éditeur, jamais).
@export var cut_enabled: bool = true
@export_group("Lumière")
## Teinte et énergie du jour qui entre par les fenêtres, énergie des lampes.
@export var window_tint: Color = Color(1.0, 0.93, 0.8):
	set(value):
		window_tint = value
		_set_uniform(&"window_tint", value)
@export_range(0.0, 4.0) var window_energy: float = 1.0:
	set(value):
		window_energy = value
		_set_uniform(&"window_energy", value)
@export_range(0.0, 4.0) var lamp_energy: float = 1.0:
	set(value):
		lamp_energy = value
		_set_uniform(&"lamp_energy", value)

## Agencement lu (null sans layout).
var plan: InteriorLayout

var _materials: Array[ShaderMaterial] = []
var _surfaces: Array[MeshInstance3D] = []
var _window_image: Image
var _lamp_image: Image
var _window_texture: ImageTexture
var _lamp_texture: ImageTexture
var _cut_shown: float = NO_CUT
var _column: Vector4 = Vector4(-NO_CUT, -NO_CUT, 0.0, 0.0)
var _queued: bool = false


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	rebuild()
	if not Engine.is_editor_hint():
		EventBus.day_phase_changed.connect(apply_phase)
	set_process(not Engine.is_editor_hint())


func _exit_tree() -> void:
	# La pièce part : les meubles (matériaux partagés) n'ont plus ni lumière ni coupe, et le cache
	# ne retient plus ses cartes de lumière (sauf si une autre pièce a déjà pris la place).
	if _shared_owner != get_instance_id():
		return
	for key: StringName in [&"window_light", &"lamp_light"]:
		share_uniform(key, null)
	share_uniform(&"cut_line", NO_CUT)
	_shared.clear()


func _process(delta: float) -> void:
	var target := cut_target()
	var shown := _cut_shown
	if target >= NO_CUT or shown >= NO_CUT or absf(target - shown) > CUT_SNAP:
		shown = target
	else:
		shown = move_toward(shown, target, CUT_SPEED * delta)
	if shown != _cut_shown:
		_cut_shown = shown
		_set_uniform(&"cut_line", shown)
	var column := Vector4(-NO_CUT, -NO_CUT, 0.0, 0.0)
	var player := _player()
	if player != null and cut_enabled:
		var at := to_local(DecorPanel.displayed_transform(player).origin)
		column = Vector4(at.x, at.z, COLUMN_HALF, COLUMN_LENGTH)
	if column != _column:
		_column = column
		for material in _materials:
			material.set_shader_parameter(&"cut_column", column)


## Ligne de coupe voulue (z du monde) pour le joueur, NO_CUT sans joueur ni limite au sud.
func cut_target() -> float:
	var player := _player()
	if not cut_enabled or plan == null or player == null:
		return NO_CUT
	var line := plan.cut_line_at(to_local(DecorPanel.displayed_transform(player).origin))
	if line >= NO_CUT:
		return NO_CUT
	return to_global(Vector3(0.0, 0.0, line)).z


func _player() -> Node3D:
	if not is_inside_tree():
		return null
	return get_tree().get_first_node_in_group(PLAYER_GROUP) as Node3D


## Ligne de coupe dessinée (z du monde).
func cut_line() -> float:
	return _cut_shown


## Pose la coupe sans glisser (arrivée sur la carte, téléportation).
func snap_cut() -> void:
	_cut_shown = cut_target()
	_set_uniform(&"cut_line", _cut_shown)


# --- Moment de la journée (E9) -------------------------------------------------------------


## Jour qui entre par les fenêtres : teinte et énergie (0 : nuit noire).
func set_daylight(tint: Color, energy: float) -> void:
	window_tint = tint
	window_energy = energy


## Énergie des lampes, cheminées et fourneaux de la carte.
func set_lamps(energy: float) -> void:
	lamp_energy = energy


## Réglage d'un moment de la journée (PHASES ; inconnu : sans effet).
func apply_phase(phase: StringName) -> void:
	if not PHASES.has(phase):
		return
	var values: Array = PHASES[phase]
	set_daylight(values[0] as Color, float(values[1]))
	set_lamps(float(values[2]))


# --- Construction ----------------------------------------------------------------------------


## Recrée tout à partir de layout.
func rebuild() -> void:
	_queued = false
	_clear()
	plan = null
	if layout == null:
		return
	plan = InteriorLayout.from_data(layout.data)
	for problem: String in plan.problems:
		push_error("InteriorRoom %s : %s" % [layout.resource_path, problem])
	if plan.map_size == Vector2i.ZERO:
		return
	_build_light_maps()
	_build_floors()
	_build_walls()
	_build_panels()
	_build_void()
	_build_collisions()
	var uniforms := _light_uniforms()
	for key: StringName in uniforms:
		_set_uniform(key, uniforms[key])
	_set_uniform(&"cut_line", _cut_shown)


## Meshes visibles de la pièce (un par matière).
func surfaces() -> Array[MeshInstance3D]:
	return _surfaces.duplicate()


# --- Requêtes (comme MapGround, lot E2 ; x et z dans le repère de la carte) ----------------------


## Hauteur du sol (m) : un étage est plat, à la hauteur du nœud.
func height_at(_x: float, _z: float) -> float:
	return global_position.y


## Matière du sol (nom de l'image floor_*), &"" hors des pièces.
func material_at(x: float, z: float) -> StringName:
	var index := plan.cell(floori(x), floori(z)) if plan != null else -1
	return StringName(plan.rooms[index]["floor"]) if index >= 0 else &""


## Pièce sous un point, &"" hors des pièces.
func room_at(x: float, z: float) -> StringName:
	return plan.room_at(Vector3(x, 0.0, z)) if plan != null else &""


## Vrai dans une pièce, hors de l'épaisseur des murs (les meubles, dans Geometry, n'y sont pas).
func is_walkable(x: float, z: float) -> bool:
	if room_at(x, z).is_empty():
		return false
	for piece: Dictionary in plan.pieces:
		if float(piece["y0"]) > 0.0:
			continue
		var box := plan.piece_box(piece)
		if x > box.position.x - 0.001 and x < box.end.x + 0.001:
			if z > box.position.z - 0.001 and z < box.end.z + 0.001:
				return false
	return true


## Centre d'une porte au sol (repère du monde), Vector3.INF si elle n'existe pas.
func door_position(id: StringName) -> Vector3:
	var opening := plan.door(id) if plan != null else {}
	if opening.is_empty():
		return Vector3.INF
	return to_global(InteriorLayout.opening_center(opening))


## Triangles (repère du monde) des murs et des linteaux tels qu'ils se dessinent quand la coupe
## est à cut_world (z du monde ; NO_CUT : rien de coupé), comme interior.gdshader : ce qui est au
## sud de cut_world - CUT_MARGIN ne monte qu'à CUT_HEIGHT, de même que les murs nord-sud dans la
## colonne de coupe d'un joueur en player (repère du monde). Pour vérifier que rien ne cache le
## joueur ; les portes, fenêtres et éléments sont posés sur ces murs (ils ne cachent rien de
## plus), les meubles ont InteriorPanel.occluder_triangles.
func occluder_triangles(cut_world: float, player: Vector3 = Vector3.INF) -> PackedVector3Array:
	var out := PackedVector3Array()
	if plan == null:
		return out
	var threshold := to_local(Vector3(0.0, 0.0, cut_world - CUT_MARGIN)).z
	var at := to_local(player) if player.is_finite() else Vector3.INF
	for piece: Dictionary in plan.pieces:
		var box := plan.piece_box(piece)
		var parts: Array[AABB] = []
		if int(piece["axis"]) == HORIZONTAL:
			var cut := float(piece["line"]) >= threshold
			parts.append(_clip_box(box, CUT_HEIGHT if cut else INF))
		else:
			# Mur nord-sud : coupé au sud du seuil, et dans la colonne du joueur.
			var column := at.is_finite() and absf(float(piece["line"]) - at.x) < COLUMN_HALF
			var from := at.z + COLUMN_FRONT if column else INF
			var marks: Array[float] = [box.position.z, box.end.z]
			for mark: float in [threshold, from, from + COLUMN_LENGTH]:
				if mark > box.position.z and mark < box.end.z:
					marks.append(mark)
			marks.sort()
			for i in marks.size() - 1:
				var middle := (marks[i] + marks[i + 1]) / 2.0
				var cut := middle >= threshold or (middle > from and middle < from + COLUMN_LENGTH)
				var slice := box
				slice.position.z = marks[i]
				slice.size.z = marks[i + 1] - marks[i]
				parts.append(_clip_box(slice, CUT_HEIGHT if cut else INF))
		for part in parts:
			if part.size.x > 0.0 and part.size.y > 0.0 and part.size.z > 0.0:
				out.append_array(_box_triangles(part))
	return out


static func _clip_box(box: AABB, top: float) -> AABB:
	var clipped := box
	clipped.size.y = minf(box.end.y, top) - box.position.y
	return clipped


func _box_triangles(box: AABB) -> PackedVector3Array:
	var out := PackedVector3Array()
	var corners: Array[Vector3] = []
	for i in 8:
		corners.append(to_global(box.get_endpoint(i)))
	# Faces de la boîte (indices de get_endpoint : bit 0 = z, bit 1 = y, bit 2 = x).
	for face: Array in [
		[0, 1, 3, 2], [4, 5, 7, 6], [0, 2, 6, 4], [1, 3, 7, 5], [0, 1, 5, 4], [2, 3, 7, 6]
	]:
		for k: int in [0, 1, 2, 0, 2, 3]:
			out.append(corners[int(face[k])])
	return out


func _clear() -> void:
	for child: Node in get_children(true):
		if child.get_meta(&"interior_internal", false):
			remove_child(child)
			child.free()
	_surfaces.clear()
	_materials.clear()
	# Les nouveaux matériaux recevront la colonne de coupe à la prochaine image.
	_column = Vector4(-NO_CUT, -NO_CUT, 0.0, 0.0)


func _internal(node: Node, node_name: String) -> void:
	node.name = node_name
	node.set_meta(&"interior_internal", true)
	add_child(node, false, Node.INTERNAL_MODE_FRONT)


func _surface_material(texture_name: String, relief: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter(&"albedo_texture", load(InteriorLayout.image_path(texture_name)))
	material.set_shader_parameter(&"hd2d_relief", relief)
	material.set_shader_parameter(&"cut_height", CUT_HEIGHT)
	material.set_shader_parameter(&"cut_margin", CUT_MARGIN)
	_materials.append(material)
	return material


func _add_mesh(node_name: String, mesh: Mesh, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_internal(instance, node_name)
	_surfaces.append(instance)
	return instance


## Sols : un mesh par matière, les rectangles de ses pièces, tuiles de 4 m alignées sur la carte.
func _build_floors() -> void:
	var tools: Dictionary = {}
	for room: Dictionary in plan.rooms:
		var key := String(room["floor"])
		if not tools.has(key):
			tools[key] = _begin()
		var st: SurfaceTool = tools[key]
		for rect: Rect2i in room["rects"]:
			var p := Vector3(rect.position.x, 0.0, rect.position.y)
			var size := Vector3(rect.size.x, 0.0, rect.size.y)
			var corners: Array[Vector3] = [
				p + Vector3(0.0, 0.0, size.z),
				p + Vector3(size.x, 0.0, size.z),
				p + Vector3(size.x, 0.0, 0.0),
				p,
			]
			var uvs: Array[Vector2] = []
			for corner in corners:
				uvs.append(Vector2(corner.x, corner.z) / FLOOR_SPAN)
			_quad(st, corners, uvs, Vector3.UP, [0.0, 0.0, 0.0, 0.0], PART_FACE)
	for key: String in tools:
		var st: SurfaceTool = tools[key]
		_add_mesh("Floor_" + key, st.commit(), _surface_material(key, FLOOR_RELIEF))


static func _begin() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


## Quadrilatère corners (bas gauche, bas droite, haut droite, haut gauche vus de face), sa normale,
## ses UV, et UV2 = (coordonnée de coupe de chaque coin, partie).
static func _quad(
	st: SurfaceTool,
	corners: Array[Vector3],
	uvs: Array[Vector2],
	normal: Vector3,
	cuts: Array,
	part: float
) -> void:
	for k: int in [0, 2, 1, 0, 3, 2]:
		st.set_normal(normal)
		st.set_uv(uvs[k])
		st.set_uv2(Vector2(float(cuts[k]), part))
		st.add_vertex(corners[k])


## Murs : faces, tranches aux portes et dessus (entier en haut, coupé au ras du sol) de chaque
## morceau ; faces et tranches dans le mesh de la matière de la pièce qu'elles regardent, dessus
## dans celui du wallcut.
func _build_walls() -> void:
	var walls: Dictionary = {}
	var tops: Dictionary = {}
	for piece: Dictionary in plan.pieces:
		_wall_piece(piece, walls, tops)
	for key: String in walls:
		var st: SurfaceTool = walls[key]
		_add_mesh("Walls_" + key, st.commit(), _surface_material(key, WALL_RELIEF))
	for key: String in tops:
		var st: SurfaceTool = tops[key]
		_add_mesh("Tops_" + key, st.commit(), _surface_material(key, WALL_RELIEF))


func _room_image(low: int, high: int, key: String, prefer_high: bool) -> String:
	var first := high if prefer_high else low
	var second := low if prefer_high else high
	var index := first if first >= 0 else second
	return String(plan.rooms[index][key])


## Mesh de la tranche d'un bout de morceau tournée vers normal : la matière de la pièce qu'elle
## regarde (celle du côté « high » si c'est le vide).
func _end_tool(
	walls: Dictionary, piece: Dictionary, corner: Vector3, normal: Vector3
) -> SurfaceTool:
	var line := float(piece["line"])
	var probe := corner + normal * 0.3
	var room := -1
	for side: float in [0.1, -0.1]:
		var at := probe
		if int(piece["axis"]) == HORIZONTAL:
			at.z = line + side
		else:
			at.x = line + side
		if room < 0:
			room = plan.cell(floori(at.x), floori(at.z))
	if room < 0:
		return _tool(walls, _room_image(int(piece["low"]), int(piece["high"]), "wall", true))
	return _tool(walls, String(plan.rooms[room]["wall"]))


static func _tool(tools: Dictionary, key: String) -> SurfaceTool:
	if not tools.has(key):
		tools[key] = _begin()
	return tools[key]


func _wall_piece(piece: Dictionary, walls: Dictionary, tops: Dictionary) -> void:
	var box := plan.piece_box(piece)
	var low := int(piece["low"])
	var high := int(piece["high"])
	var horizontal := int(piece["axis"]) == HORIZONTAL
	var lo := box.position
	var hi := box.end
	var top := hi.y
	# Faces côté « high » (sud ou est) et côté « low » (nord ou ouest), tranches au bord des
	# portes ; coupe : la ligne d'un mur est-ouest, le z de chaque sommet d'un mur nord-sud.
	var high_wall := _tool(walls, _room_image(low, high, "wall", true))
	var low_wall := _tool(walls, _room_image(low, high, "wall", false))
	var cut := float(piece["line"]) + global_position.z if horizontal else NAN
	var sw := Vector3(lo.x, lo.y, hi.z)
	var se := Vector3(hi.x, lo.y, hi.z)
	var nw := Vector3(lo.x, lo.y, lo.z)
	var ne := Vector3(hi.x, lo.y, lo.z)
	# Partie dans UV2.y ; un mur nord-sud y ajoute sa ligne (colonne de coupe : part_code()).
	var code := part_code(PART_FACE, -1 if horizontal else int(piece["line"]))
	# Les deux bouts : tranche au bord d'une porte, ou bout d'un poteau d'angle (le bout sud d'une
	# cloison qui touche le mur du couloir fait partie de la face de ce mur).
	if horizontal:
		_face(high_wall, sw, se, top, Vector3.BACK, cut, code)
		_face(low_wall, nw, ne, top, Vector3.FORWARD, cut, code)
		_face(_end_tool(walls, piece, nw, Vector3.LEFT), nw, sw, top, Vector3.LEFT, cut, code)
		_face(_end_tool(walls, piece, ne, Vector3.RIGHT), ne, se, top, Vector3.RIGHT, cut, code)
	else:
		_face(high_wall, ne, se, top, Vector3.RIGHT, cut, code)
		_face(low_wall, nw, sw, top, Vector3.LEFT, cut, code)
		_face(_end_tool(walls, piece, nw, Vector3.FORWARD), nw, ne, top, Vector3.FORWARD, cut, code)
		_face(_end_tool(walls, piece, sw, Vector3.BACK), sw, se, top, Vector3.BACK, cut, code)
	var caps := _tool(tops, _room_image(low, high, "wallcut", true))
	_cap(caps, lo, hi, top, horizontal, cut, code + PART_TOP)
	if lo.y < CUT_HEIGHT:
		_cap(caps, lo, hi, CUT_HEIGHT, horizontal, cut, code + PART_LOW)


## Code de partie (UV2.y des murs) : la partie (PART_*), plus 4 × (ligne + 1) pour un mur
## nord-sud (ligne x de la carte, entière), que la colonne de coupe reconnaît.
static func part_code(part: float, north_south_line: int) -> float:
	return part + (4.0 * (north_south_line + 1) if north_south_line >= 0 else 0.0)


## Face verticale entre les points p et q du bas, jusqu'à la hauteur top, tournée vers normal ;
## UV : la bande de 4 × 3 m alignée sur la carte (u de gauche à droite vu de face) ; coupe : cut
## (mur est-ouest), ou le z de chaque sommet (NAN : mur nord-sud).
func _face(
	st: SurfaceTool, p: Vector3, q: Vector3, top: float, normal: Vector3, cut: float, code: float
) -> void:
	var right := (-normal).cross(Vector3.UP)
	var a := p if p.dot(right) <= q.dot(right) else q
	var b := q if p.dot(right) <= q.dot(right) else p
	var corners: Array[Vector3] = [a, b, Vector3(b.x, top, b.z), Vector3(a.x, top, a.z)]
	var uvs: Array[Vector2] = []
	var cuts := []
	for corner in corners:
		uvs.append(Vector2(corner.dot(right) / WALL_SPAN, 1.0 - corner.y / WALL_IMAGE_HEIGHT))
		cuts.append(cut if not is_nan(cut) else corner.z + global_position.z)
	_quad(st, corners, uvs, normal, cuts, code)


## Dessus d'un morceau à la hauteur y : la bande wallcut le long du mur (0,25 m de travers).
func _cap(
	st: SurfaceTool, lo: Vector3, hi: Vector3, y: float, horizontal: bool, cut: float, part: float
) -> void:
	var corners: Array[Vector3] = [
		Vector3(lo.x, y, hi.z),
		Vector3(hi.x, y, hi.z),
		Vector3(hi.x, y, lo.z),
		Vector3(lo.x, y, lo.z)
	]
	var uvs: Array[Vector2] = []
	var cuts := []
	for corner in corners:
		if horizontal:
			uvs.append(Vector2(corner.x / WALL_SPAN, (corner.z - lo.z) / (hi.z - lo.z)))
		else:
			uvs.append(Vector2(corner.z / WALL_SPAN, (corner.x - lo.x) / (hi.x - lo.x)))
		cuts.append(cut if not is_nan(cut) else corner.z + global_position.z)
	_quad(st, corners, uvs, Vector3.UP, cuts, part)


## Portes (les deux faces), fenêtres et éléments de mur (la face de leur pièce) : un mesh par image.
func _build_panels() -> void:
	var tools: Dictionary = {}
	for opening: Dictionary in plan.doors:
		if String(opening["image"]).is_empty():
			continue
		var texture := load(InteriorLayout.image_path(opening["image"])) as Texture2D
		var size := Vector2(texture.get_size()) / InteriorLayout.PIXELS_PER_METER
		for face: int in [1, -1]:
			_wall_panel(tools, opening, face, 0.0, size)
	for placed: Dictionary in plan.windows + plan.wall_items:
		_wall_panel(tools, placed, int(placed["face"]), float(placed["bottom"]), placed["size"])
	for key: String in tools:
		var st: SurfaceTool = tools[key]
		var texture := load(InteriorLayout.image_path(key)) as Texture2D
		var window := key.begins_with("window_")
		var glow := float(GLOWS.get(key, WINDOW_GLOW if window else 0.0))
		var follows := GLOW_DAYLIGHT if window else GLOW_LAMPS
		_add_mesh("Panel_" + key, st.commit(), panel_material(texture, glow, Color.WHITE, follows))


func _wall_panel(
	tools: Dictionary, placed: Dictionary, face: int, bottom: float, size: Vector2
) -> void:
	var st := _tool(tools, String(placed["image"]))
	var line := float(placed["line"])
	var center := float(placed["center"])
	var off := plan.wall_thickness / 2.0 + PANEL_GAP
	var corners: Array[Vector3] = []
	var normal: Vector3
	var along: Array[float] = [center - size.x / 2.0, center + size.x / 2.0]
	if int(placed["axis"]) == HORIZONTAL:
		var z := line + off * face
		normal = Vector3.BACK * face
		if face < 0:
			along.reverse()
		for k: int in [0, 1, 1, 0]:
			corners.append(Vector3(along[k], 0.0, z))
	else:
		var x := line + off * face
		normal = Vector3.RIGHT * face
		if face > 0:
			along.reverse()
		for k: int in [0, 1, 1, 0]:
			corners.append(Vector3(x, 0.0, along[k]))
	for k: int in [0, 1]:
		corners[k].y = bottom
	for k: int in [2, 3]:
		corners[k].y = bottom + size.y
	var uvs: Array[Vector2] = [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
	var cuts := []
	for corner in corners:
		var cut := line if int(placed["axis"]) == HORIZONTAL else corner.z
		cuts.append(cut + global_position.z)
	for k in 6:
		var index: int = [0, 2, 1, 0, 3, 2][k]
		st.set_normal(normal)
		st.set_uv(uvs[index])
		st.set_uv2(Vector2(float(cuts[index]), CUT_HEIGHT))
		st.add_vertex(corners[index])


## Le vide autour du bâtiment : un sol sombre, non éclairé.
func _build_void() -> void:
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(plan.map_size) + Vector2.ONE * VOID_MARGIN * 2.0
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = VOID_COLOR
	var instance := _add_mesh("Void", mesh, material)
	instance.position = Vector3(plan.map_size.x / 2.0, -0.02, plan.map_size.y / 2.0)


## Collisions (couche 1) : une dalle sous toute la carte, une boîte par morceau de mur.
func _build_collisions() -> void:
	var slab := BoxShape3D.new()
	slab.size = Vector3(plan.map_size.x + 20.0, 1.0, plan.map_size.y + 20.0)
	_shape(slab, Vector3(plan.map_size.x / 2.0, -0.5, plan.map_size.y / 2.0), "Floor")
	var index := 0
	for piece: Dictionary in plan.pieces:
		var box := plan.piece_box(piece)
		var shape := BoxShape3D.new()
		shape.size = box.size
		_shape(shape, box.get_center(), "Wall%d" % index)
		index += 1


func _shape(shape: Shape3D, at: Vector3, node_name: String) -> void:
	var node := CollisionShape3D.new()
	node.shape = shape
	node.position = at
	_internal(node, node_name)


# --- Lumière ---------------------------------------------------------------------------------


## Cartes de lumière (jour des fenêtres, lampes), bornées à la pièce de chaque source.
func _build_light_maps() -> void:
	var size := plan.map_size * LIGHT_TEXELS
	var day := PackedFloat32Array()
	day.resize(size.x * size.y * 3)
	var lamps := day.duplicate()
	for placed: Dictionary in plan.windows:
		_window_pool(day, size, placed)
	for lamp: Dictionary in plan.lights:
		_lamp_pool(lamps, size, lamp)
	_window_image = _light_image(day, size)
	_lamp_image = _light_image(lamps, size)
	_window_texture = ImageTexture.create_from_image(_window_image)
	_lamp_texture = ImageTexture.create_from_image(_lamp_image)


func _light_uniforms() -> Dictionary:
	var origin := global_position
	return {
		&"window_light": _window_texture,
		&"lamp_light": _lamp_texture,
		&"light_rect":
		Vector4(origin.x, origin.z, 1.0 / float(plan.map_size.x), 1.0 / float(plan.map_size.y)),
		&"window_tint": window_tint,
		&"window_energy": window_energy,
		&"lamp_energy": lamp_energy,
		&"light_scale": LIGHT_SCALE,
		&"light_height": plan.wall_height,
		&"floor_y": origin.y,
		&"cut_margin": CUT_MARGIN,
	}


static func _light_image(values: PackedFloat32Array, size: Vector2i) -> Image:
	var bytes := PackedByteArray()
	bytes.resize(size.x * size.y * 4)
	for i in size.x * size.y:
		for c in 3:
			bytes[i * 4 + c] = clampi(roundi(values[i * 3 + c] / LIGHT_SCALE * 255.0), 0, 255)
		bytes[i * 4 + 3] = 255
	return Image.create_from_data(size.x, size.y, false, Image.FORMAT_RGBA8, bytes)


## Texels (rectangle) d'une région de la carte, bornés à la carte.
static func _texels(region: Rect2, size: Vector2i) -> Rect2i:
	var start := Vector2i((region.position * LIGHT_TEXELS).floor()).clamp(Vector2i.ZERO, size)
	var end := Vector2i((region.end * LIGHT_TEXELS).ceil()).clamp(Vector2i.ZERO, size)
	return Rect2i(start, end - start)


func _add_light(values: PackedFloat32Array, size: Vector2i, texel: Vector2i, light: Color) -> void:
	var i := (texel.y * size.x + texel.x) * 3
	values[i] += light.r
	values[i + 1] += light.g
	values[i + 2] += light.b


## Flaque de jour devant une fenêtre : sur le sol de sa pièce, plus faible en s'éloignant du mur,
## plus large que la fenêtre et de plus en plus floue.
func _window_pool(values: PackedFloat32Array, size: Vector2i, placed: Dictionary) -> void:
	var room := plan.room_index(placed["room"])
	var horizontal := int(placed["axis"]) == HORIZONTAL
	var face := float(placed["face"])
	var wall := float(placed["line"]) + face * plan.wall_thickness / 2.0
	var half := (placed["size"] as Vector2).x / 2.0
	var center := float(placed["center"])
	var reach := half + WINDOW_SPREAD * 3.0
	var region := Rect2(
		center - reach, minf(wall, wall + face * WINDOW_DEPTH), 2.0 * reach, WINDOW_DEPTH
	)
	if not horizontal:
		region = Rect2(
			minf(wall, wall + face * WINDOW_DEPTH), center - reach, WINDOW_DEPTH, 2.0 * reach
		)
	var texels := _texels(region, size)
	for ty in range(texels.position.y, texels.end.y):
		for tx in range(texels.position.x, texels.end.x):
			var at := (Vector2(tx, ty) + Vector2.ONE * 0.5) / LIGHT_TEXELS
			if plan.cell(floori(at.x), floori(at.y)) != room:
				continue
			var depth := ((at.y if horizontal else at.x) - wall) * face
			var aside := absf((at.x if horizontal else at.y) - center)
			if depth < 0.0:
				continue
			var edge := half + WINDOW_SPREAD * (0.5 + depth * 0.4)
			var across := 1.0 - smoothstep(half, edge, aside)
			var fade := 1.0 - smoothstep(0.0, WINDOW_DEPTH, depth)
			_add_light(values, size, Vector2i(tx, ty), Color.WHITE * WINDOW_POOL * across * fade)


## Halo d'une lampe sur le sol de sa pièce.
func _lamp_pool(values: PackedFloat32Array, size: Vector2i, lamp: Dictionary) -> void:
	var at_lamp := lamp["at"] as Vector2
	var radius := float(lamp["radius"])
	var light := (lamp["color"] as Color) * float(lamp["energy"])
	var texels := _texels(Rect2(at_lamp - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), size)
	for ty in range(texels.position.y, texels.end.y):
		for tx in range(texels.position.x, texels.end.x):
			var at := (Vector2(tx, ty) + Vector2.ONE * 0.5) / LIGHT_TEXELS
			if plan.cell(floori(at.x), floori(at.y)) != int(lamp["room"]):
				continue
			var f := clampf(1.0 - at.distance_to(at_lamp) / radius, 0.0, 1.0)
			if f > 0.0:
				_add_light(values, size, Vector2i(tx, ty), light * (f * f * LAMP_POOL))


## Lumière ajoutée en un point de la carte (repère local), comme le shader : fenêtres (teinte et
## énergie du jour) et lampes ; noir hors de la carte.
func light_at(local: Vector3) -> Color:
	if plan == null or _window_image == null:
		return Color.BLACK
	var texel := Vector2i((Vector2(local.x, local.z) * LIGHT_TEXELS).floor())
	if not Rect2i(Vector2i.ZERO, _window_image.get_size()).has_point(texel):
		return Color.BLACK
	var day := _window_image.get_pixelv(texel) * window_tint * window_energy
	var lamps := _lamp_image.get_pixelv(texel) * lamp_energy
	var total := (day + lamps) * LIGHT_SCALE
	total.a = 1.0
	return total


# --- Uniformes partagés et matériaux des panneaux ----------------------------------------------


func _set_uniform(key: StringName, value: Variant) -> void:
	for material in _materials:
		material.set_shader_parameter(key, value)
	if is_inside_tree() and plan != null:
		_shared_owner = get_instance_id()
		share_uniform(key, value)


## Pose un uniforme des intérieurs sur tous les matériaux de panneaux partagés (et ceux à venir).
static func share_uniform(key: StringName, value: Variant) -> void:
	_shared[key] = value
	for cache_key: String in _panel_materials.keys():
		var material := DecorPanel.cached_material(_panel_materials, cache_key)
		if material != null:
			material.set_shader_parameter(key, value)


## Matériau partagé d'une image de panneau d'intérieur (interior_panel.gdshader), avec la lumière
## et la coupe de la pièce chargée ; sa lueur suit le jour (GLOW_DAYLIGHT : vitres), les lampes
## (GLOW_LAMPS : appliques, fourneau) ou rien (GLOW_STEADY).
static func panel_material(
	texture: Texture2D, glow: float = 0.0, tint: Color = Color.WHITE, follows: int = GLOW_LAMPS
) -> ShaderMaterial:
	var key := "%s|%.2f|%s|%d" % [DecorPanel.image_key(texture), glow, tint.to_html(), follows]
	var material := DecorPanel.cached_material(_panel_materials, key) as ShaderMaterial
	if material == null:
		material = ShaderMaterial.new()
		material.shader = PANEL_SHADER
		material.set_shader_parameter(&"albedo_texture", texture)
		material.set_shader_parameter(&"tint", tint)
		material.set_shader_parameter(&"hd2d_relief", 0.0)
		material.set_shader_parameter(&"glow_strength", glow)
		material.set_shader_parameter(&"glow_follows", float(follows))
		for shared_key: StringName in _shared:
			material.set_shader_parameter(shared_key, _shared[shared_key])
		_panel_materials[key] = weakref(material)
	return material


## Mesh d'un panneau d'intérieur de taille size (m), ancre au milieu du bord bas, face vers +Z ;
## UV2 = (coordonnée de coupe : z du monde, hauteur gardée par la coupe).
static func panel_mesh(size: Vector2, cut: float, keep: float) -> ArrayMesh:
	var key := "%.4f|%.4f|%.3f|%.3f" % [size.x, size.y, cut, keep]
	var ref: WeakRef = _panel_meshes.get(key)
	var mesh := ref.get_ref() as ArrayMesh if ref != null else null
	if mesh == null:
		var st := _begin()
		var half := size.x / 2.0
		var corners: Array[Vector3] = [
			Vector3(-half, 0.0, 0.0),
			Vector3(half, 0.0, 0.0),
			Vector3(half, size.y, 0.0),
			Vector3(-half, size.y, 0.0),
		]
		var uvs: Array[Vector2] = [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
		for k: int in [0, 2, 1, 0, 3, 2]:
			st.set_normal(Vector3.BACK)
			st.set_uv(uvs[k])
			st.set_uv2(Vector2(cut, keep))
			st.add_vertex(corners[k])
		mesh = st.commit()
		_panel_meshes[key] = weakref(mesh)
	return mesh


func _queue_rebuild() -> void:
	if _queued or not is_inside_tree():
		return
	_queued = true
	rebuild.call_deferred()
