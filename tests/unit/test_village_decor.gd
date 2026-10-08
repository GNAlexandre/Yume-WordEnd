extends GutTest
## (Lot H2) Le décor de l'entrepôt des fées (src/world/zones/village/village.tscn), dans l'île
## sans le contenu des emplacements (tests/stubs/l2_island_fixture.gd) :
##
## - collisions : l'entrepôt, son aile, la remise, le puits, les lampes, les poteaux du linge et
##   les caisses arrêtent le joueur ; la palissade ferme la cour sauf aux quatre portails ; les
##   chemins jusqu'aux portails et l'abord de chaque PNJ (depuis le centre de la cour, comme les
##   tests de la vraie partie) sont libres ;
## - occlusion : depuis la caméra de sa conversation, aucun pixel opaque du décor ne cache un
##   PNJ ; en marchant dans la cour, aucun PNJ à l'écran ne reste caché plus d'une seconde de
##   marche ; on ne passe plus derrière le L de l'entrepôt ; le décor qui passe devant le joueur
##   (un arbre, le porche, les draps) s'efface autour de lui (see_through.gd), sans matériau ni
##   draw call de plus ;
## - (P2) formats du cahier n° 2 : les décalques au sol, le premier plan et la fumée (alpha doux)
##   gardent leur shader ; la lisière derrière la palissade nord est une toile de fond qui
##   s'efface tout entière quand on sort au nord ; les bandes animées (le linge) comptent dans
##   l'occlusion par toutes leurs images.
##
## Les places elles-mêmes (sol, dégagement, accès) restent vérifiées par
## test_world_story_spots.gd.

const FIXTURE := preload("res://tests/stubs/l2_island_fixture.gd")
const PLAYER_STUB := preload("res://tests/stubs/player_stub.tscn")
const NPC_PLACEMENTS := preload("res://src/npc/placements/village.tscn")
const CAMERA_RIG := preload("res://src/player/camera_rig.tscn")
const SeeThrough := preload("res://src/world/zones/village/see_through.gd")
const PANEL_SHADER := preload("res://src/world/shaders/panel.gdshader")
## (P2) Shaders des formats qui gardent le leur (décalques, premier plan, alpha doux).
const OWN_SHADERS: Array[Shader] = [
	GroundDecal.HARD_SHADER,
	GroundDecal.SOFT_SHADER,
	DecorPanel.FOREGROUND_SHADER,
	DecorPanel.SOFT_SHADER,
]
## (P2) Ce qui ne cache rien : les décalques (au sol) et l'alpha doux (mélangé, sur le toit).
const HIDES_NOTHING: Array[Shader] = [
	GroundDecal.HARD_SHADER, GroundDecal.SOFT_SHADER, DecorPanel.SOFT_SHADER
]
## (P2) Images de la lisière nord (toile de fond) ; les toiles de fond sont au nord de -z.
const BACKDROP_IMAGE := "treeline_autumn"
const BACKDROP_SOUTH := 12.0
## (P2) Case (m) du rangement des triangles du décor pour les rayons d'occlusion.
const BUCKET := 4.0
## Capsule du joueur (player.tscn) et marche franchie.
const PLAYER_RADIUS := 0.35
const PLAYER_HEIGHT := 1.5
const STEP_UP := 0.2
## Distances d'où l'on aborde un PNJ (m) : test_act1_side_quests.gd (1,6) et test_m2_quest.gd
## (3) ; Ithea, adossée au puits, s'aborde depuis la margelle (1,6 seulement).
const TALK_NEAR := 1.6
const TALK_FAR := 3.0
const BY_THE_WELL: Array[String] = ["Ithea"]
## Points de chaque PNJ vus par la caméra : hauteurs (m, du plus petit, Almita, 0,95 m) et
## demi-largeur du corps.
const NPC_HEIGHTS: Array[float] = [0.25, 0.55, 0.85]
const NPC_HALF_WIDTH := 0.25
## Palissade : à 21,2 m du centre ; ouverture libre des portails (de part et d'autre du chemin)
## et début des modules après le poteau.
const FENCE := 21.2
const GATE_OPENING := 1.2
const FENCE_FROM := 2.4
## Marche dans la cour : pas des relevés (m) et plus longue traversée où un PNJ à l'écran peut
## rester caché (une seconde à walk_speed, player.gd : 4 m/s).
const WALK_STEP := 1.0
const HIDDEN_WALK_LIMIT := 4.0
## Part centrale de l'écran (en angle) où l'on suit un PNJ : au bord du cadre, sous le panneau de
## quête ou au ras de la palissade, il revient au centre dès qu'on marche vers lui.
const VIEW_SHARE := 0.8
## Allées relevées : lignes est-ouest (z) et nord-sud (x) qui balaient la cour, jusqu'à la
## palissade (local au village).
const WALK_ROWS: Array[float] = [-17.0, -13.0, -8.0, -4.0, 0.0, 4.0, 8.0, 12.0, 16.0, 19.5]
const WALK_COLUMNS: Array[float] = [-17.0, -12.0, -8.0, -4.0, 0.0, 4.0, 8.0, 12.0, 16.0, 20.0]
const WALK_FROM := -20.5
const WALK_TO := 20.5
## Derrière le tronc du grand arbre (local au village) : le décor y cache le joueur.
const BEHIND_THE_TREE := Vector3(11.0, 0.0, -14.6)
## Couloirs fermés derrière le L de l'entrepôt (local au village) : un point dans chacun.
const BEHIND_WAREHOUSE: Array[Vector3] = [Vector3(-11.0, 0.0, -20.1), Vector3(-20.1, 0.0, -6.0)]
## Obstacles du décor : point (local au village) → nœud attendu dans le chemin du collisionneur.
const BLOCKERS := {
	"WarehouseMain": Vector3(-11.0, 0.0, -15.0),
	"WarehouseWing": Vector3(-16.0, 0.0, -6.5),
	"ToolShed": Vector3(17.0, 0.0, -17.3),
	"Well": Vector3(0.0, 0.0, 0.0),
	"ArmoryDoor": Vector3(-13.6, 0.0, -1.6),
	"ClimbingTree": Vector3(11.0, 0.0, -13.0),
	"Lamps": Vector3(-5.5, 0.0, -8.7),
	"LaundryLines": Vector3(7.5, 0.0, 5.4),
	"PlayGoals": Vector3(-12.75, 0.0, 13.9),
}

var _island: Node3D
var _village: Node3D
var _space: PhysicsDirectSpaceState3D
var _ground: Node
## Position (monde) de chaque PNJ du fichier d'emplacement, par nom de nœud.
var _npcs: Dictionary[String, Vector3] = {}
## Caméra du joueur : tangage (rad), distance et hauteur du point visé (camera_rig.tscn).
var _pitch := 0.0
var _distance := 0.0
var _focus_height := 0.0
## Demi-angles de la part centrale du champ de la caméra (rad) : vertical, horizontal (16:9).
var _half_fov := 0.0
var _half_hfov := 0.0
## Triangles opaques possibles du décor fondu : sommets (monde), UV, image de chaque triangle.
var _vertices := PackedVector3Array()
var _uvs := PackedVector2Array()
var _triangle_images: Array[Image] = []
var _triangle_names: Array[String] = []
## (P2) Images de la bande de chaque triangle (1 : image fixe), boîte de chaque triangle,
## triangles rangés par case du plan (x, z), dernier rayon qui a vu chaque triangle.
var _triangle_frames := PackedInt32Array()
var _low := PackedVector3Array()
var _high := PackedVector3Array()
var _buckets: Dictionary[Vector2i, PackedInt32Array] = {}
var _stamp := PackedInt32Array()
var _ray := 0


func before_all() -> void:
	_island = FIXTURE.island()
	add_child(_island)
	await wait_physics_frames(2)
	_village = _island.get_node(^"Zones/village") as Node3D
	_space = _island.get_world_3d().direct_space_state
	_ground = _island.get_node(^"Ground")
	var placements := NPC_PLACEMENTS.instantiate() as Node3D
	for child: Node in placements.get_children():
		if child is Npc:
			_npcs[String(child.name)] = _village.to_global((child as Node3D).position)
	placements.free()
	var rig := CAMERA_RIG.instantiate()
	_pitch = deg_to_rad(float(rig.get(&"pitch_deg")))
	_distance = float(rig.get(&"distance"))
	_focus_height = float(rig.get(&"focus_height"))
	_half_fov = deg_to_rad(float(rig.get(&"fov_deg"))) / 2.0 * VIEW_SHARE
	_half_hfov = atan(tan(deg_to_rad(float(rig.get(&"fov_deg"))) / 2.0) * 16.0 / 9.0) * VIEW_SHARE
	rig.free()
	_collect_panels()


func after_all() -> void:
	_island.free()


# --- Collisions ---------------------------------------------------------------------------------


func test_buildings_and_yard_props_block_the_player() -> void:
	for label: String in BLOCKERS:
		var hits := _decor_at(_village.to_global(BLOCKERS[label] as Vector3))
		assert_false(hits.is_empty(), "%s arrête le joueur" % label)
		assert_true(
			hits.any(func(path: String) -> bool: return path.contains(label)),
			"%s : collision du bon décor (%s)" % [label, ", ".join(hits)]
		)


func test_palisade_closes_the_yard_except_at_the_gates() -> void:
	var sides: Array[Vector3] = [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]
	for outward: Vector3 in sides:
		var along := Vector3(absf(outward.z), 0.0, absf(outward.x))
		var t := -FENCE + 0.4
		while t <= FENCE - 0.4:
			var on_fence := outward * FENCE + along * t + Vector3.UP * 0.8
			var from := _village.to_global(on_fence - outward * 0.8)
			var query := PhysicsRayQueryParameters3D.create(from, from + outward * 1.6, 1)
			var hit := _space.intersect_ray(query)
			if absf(t) <= GATE_OPENING:
				assert_true(hit.is_empty(), "portail %s ouvert en %.1f" % [outward, t])
			elif absf(t) >= FENCE_FROM:
				assert_false(hit.is_empty(), "palissade %s fermée en %.1f" % [outward, t])
			t += 0.5


func test_paths_to_the_gates_and_the_well_are_open() -> void:
	var sides: Array[Vector3] = [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]
	for outward: Vector3 in sides:
		_assert_open(outward * 9.0, outward * 23.0, "chemin %s jusqu'au portail" % outward)
	var spawn := (_village.get_node(^"Spawn") as Node3D).position
	_assert_open(Vector3(spawn.x, 0.0, spawn.z), Vector3(0.0, 0.0, 1.6), "du Spawn au puits")


func test_every_npc_can_be_approached_from_the_yard() -> void:
	assert_eq(_npcs.size(), 8, "les huit PNJ de l'entrepôt")
	for npc: String in _npcs:
		var at := _village.to_local(_npcs[npc])
		at.y = 0.0
		var away := Vector3(-at.x, 0.0, -at.z).normalized()
		var reach := TALK_NEAR if npc in BY_THE_WELL else TALK_FAR
		# Jusqu'au contact : capsule du joueur contre celle du PNJ (0,35 + 0,35 m).
		var stop := at + away * (PLAYER_RADIUS * 2.0 + 0.05)
		_assert_open(at + away * reach, stop, "abord de %s depuis %.1f m" % [npc, reach])


func test_the_back_of_the_warehouse_is_closed() -> void:
	# Le couloir derrière le corps principal et celui derrière l'aile sont libres de décor, mais
	# on n'y entre ni par l'est (nord du chemin nord) ni par le sud (ouest du chemin ouest).
	for inside: Vector3 in BEHIND_WAREHOUSE:
		assert_true(_decor_at(_village.to_global(inside)).is_empty(), "couloir %s" % inside)
	var closures := {
		"BackFence nord-est": [Vector3(-1.5, 0.0, -20.1), Vector3(-5.0, 0.0, -20.1)],
		"BackFence sud-ouest": [Vector3(-20.1, 0.0, -1.0), Vector3(-20.1, 0.0, -4.0)],
	}
	for label: String in closures:
		var ends: Array = closures[label]
		var from: Vector3 = ends[0]
		var to: Vector3 = ends[1]
		var blocked := false
		var steps := ceili(from.distance_to(to) / 0.1)
		for i in steps + 1:
			if not _decor_at(_village.to_global(from.lerp(to, float(i) / steps))).is_empty():
				blocked = true
				break
		assert_true(blocked, "%s ferme le couloir" % label)


# --- Occlusion ----------------------------------------------------------------------------------


func test_no_decor_hides_an_npc_from_the_dialogue_camera() -> void:
	assert_gt(_triangle_images.size(), 200, "décor fondu du village relevé")
	for npc: String in _npcs:
		var at := _npcs[npc]
		var local := _village.to_local(at)
		var away := Vector3(-local.x, 0.0, -local.z).normalized()
		for reach: float in [TALK_NEAR, TALK_FAR]:
			var player := Vector3(at.x, 0.0, at.z) + _village.global_basis * away * reach
			var camera := _camera_for(player)
			var hidden: Array[String] = []
			for height: float in NPC_HEIGHTS:
				for side: float in [-NPC_HALF_WIDTH, 0.0, NPC_HALF_WIDTH]:
					var point := Vector3(at.x + side, height, at.z)
					if _opaque_between(camera, point):
						hidden.append("%.2f/%.2f" % [side, height])
			assert_true(
				hidden.is_empty(),
				"%s visible (joueur à %.1f m) ; caché en %s" % [npc, reach, ", ".join(hidden)]
			)


func test_no_npc_stays_hidden_while_walking_the_yard() -> void:
	# La caméra suit le joueur : on la place au-dessus de chaque pas des allées qui balaient la
	# cour ; un PNJ à l'écran dont l'axe du corps est caché par le décor ne doit pas le rester
	# plus de HIDDEN_WALK_LIMIT m de marche d'affilée.
	var walks: Array[PackedVector3Array] = []
	for z: float in WALK_ROWS:
		walks.append(_walk(Vector3(WALK_FROM, 0.0, z), Vector3(WALK_TO, 0.0, z)))
	for x: float in WALK_COLUMNS:
		walks.append(_walk(Vector3(x, 0.0, WALK_FROM), Vector3(x, 0.0, WALK_TO)))
	var samples := 0
	var failures: Array[String] = []
	for walk: PackedVector3Array in walks:
		var runs: Dictionary[String, float] = {}
		var worst: Dictionary[String, String] = {}
		for step: Vector3 in walk:
			var reachable := _reachable(step)
			var camera := Vector3.ZERO
			if reachable:
				samples += 1
				camera = _camera_for(_village.to_global(step))
			for npc: String in _npcs:
				var occluder := _npc_hidden(camera, _npcs[npc]) if reachable else ""
				if occluder.is_empty():
					runs[npc] = 0.0
					continue
				runs[npc] = runs.get(npc, 0.0) + WALK_STEP
				if runs[npc] >= HIDDEN_WALK_LIMIT and not worst.has(npc):
					worst[npc] = "%s par %s, joueur en %s" % [npc, occluder, step]
		failures.append_array(worst.values())
	assert_gt(samples, 500, "pas relevés dans la cour")
	assert_true(failures.is_empty(), "PNJ cachés en marchant : %s" % ", ".join(failures))


func test_decor_fades_around_the_player_behind_the_climbing_tree() -> void:
	var see_through := _village.get_node(^"SeeThrough")
	var materials: Array[ShaderMaterial] = see_through.call(&"materials")
	assert_gt(materials.size(), 15, "un matériau à découpe par image du village")
	var shader := materials[0].shader
	assert_ne(shader, PANEL_SHADER, "shader des panneaux augmenté")
	var uniforms: Array[String] = []
	for uniform: Dictionary in shader.get_shader_uniform_list():
		uniforms.append(String(uniform["name"]))
	assert_has(uniforms, "see_through_center", "le shader à découpe compile")
	for uniform: Dictionary in PANEL_SHADER.get_shader_uniform_list():
		assert_has(uniforms, String(uniform["name"]), "uniforme du panneau gardé")
	# Tout le décor en panneaux du village a sa découpe ; pas un matériau de plus. (P2) Les
	# décalques, le premier plan et l'alpha doux gardent leur shader (et sont bien là).
	var kept := {}
	for child: Node in _village.get_node(^"Geometry").get_children():
		var batch := child as MeshInstance3D
		if batch == null or not (batch.material_override is ShaderMaterial):
			continue
		var own := (batch.material_override as ShaderMaterial).shader
		if own in OWN_SHADERS:
			kept[own] = true
			assert_does_not_have(materials, batch.material_override, "%s : son shader" % batch.name)
			continue
		assert_has(materials, batch.material_override, "%s : découpe" % batch.name)
	for own: Shader in OWN_SHADERS:
		assert_true(kept.has(own), "%s gardé tel quel" % own.resource_path.get_file())
	# Derrière le grand arbre (au nord de son tronc), le joueur est caché par lui ; la découpe
	# le suit.
	var player := add_child_autofree(PLAYER_STUB.instantiate()) as Node3D
	player.global_position = _village.to_global(BEHIND_THE_TREE)
	await wait_process_frames(2)
	var body := player.global_position + Vector3.UP * 0.75
	assert_true(_opaque_between(_camera_for(player.global_position), body), "arbre devant")
	for material: ShaderMaterial in materials:
		assert_eq(material.get_shader_parameter(&"see_through_strength"), 1.0)
		var center: Vector3 = material.get_shader_parameter(&"see_through_center")
		assert_almost_eq(center, body, Vector3.ONE * 0.01, "découpe sur le joueur")
	remove_child(player)
	await wait_process_frames(2)
	assert_eq(materials[0].get_shader_parameter(&"see_through_strength"), 0.0, "sans joueur")


func test_see_through_code_is_added_to_the_panel_shader() -> void:
	var code := "shader_type spatial;\nvoid fragment() {\n\t// {\n\tif (true) { ALPHA = 1.0; }\n}\n"
	var injected: String = SeeThrough.inject(code)
	assert_string_contains(injected, '#include "res://src/world/zones/village/')
	assert_true(injected.ends_with("\t}\n}\n"), "effacement à la fin de fragment()")
	assert_string_contains(injected, "if (true) { ALPHA = 1.0; }\n\tif (see_through_amount")
	assert_eq(SeeThrough.inject("shader_type spatial;\nvoid vertex() {}\n"), "", "sans fragment")
	assert_ne(SeeThrough.inject(PANEL_SHADER.code), "", "panel.gdshader se prête à l'ajout")


func test_treeline_is_a_backdrop_that_fades_when_leaving_north() -> void:
	# La lisière derrière la palissade nord et les arbres du bord nord cacheraient les bois sur
	# 15 m quand on sort par le portail nord (ils sont alors entre la caméra et le joueur) :
	# toiles de fond, ils s'effacent tout entiers au-delà de la palissade. Les autres images
	# gardent la seule découpe autour du joueur.
	var see_through := _village.get_node(^"SeeThrough")
	var materials: Array[ShaderMaterial] = see_through.call(&"materials")
	var backdrop_images: Array[Texture2D] = see_through.get(&"backdrop_textures")
	var line := _village.to_global(Vector3(0.0, 0.0, -FENCE)).z
	var backdrops: Array[String] = []
	for material: ShaderMaterial in materials:
		var image := material.get_shader_parameter(&"albedo_texture") as Texture2D
		var flag: Variant = material.get_shader_parameter(&"see_through_backdrop")
		var backdrop := flag != null and float(flag) > 0.0
		assert_almost_eq(
			float(material.get_shader_parameter(&"see_through_backdrop_line")), line, 0.01
		)
		if image != null and image in backdrop_images:
			backdrops.append(image.resource_path.get_file().get_basename())
			assert_true(backdrop, "%s : toile de fond" % image.resource_path.get_file())
		else:
			assert_false(backdrop, "%s : découpe seule" % material)
	assert_has(backdrops, BACKDROP_IMAGE + "_a", "lisière d'automne")
	assert_has(backdrops, BACKDROP_IMAGE + "_b", "lisière d'automne, autre dessin")
	var uniforms: Array[String] = []
	for uniform: Dictionary in materials[0].shader.get_shader_uniform_list():
		uniforms.append(String(uniform["name"]))
	assert_has(uniforms, "see_through_backdrop", "le shader à toile de fond compile")
	# Les toiles de fond ne servent qu'au bord nord, au-delà de la cour.
	var stack: Array[Node] = [_village.get_node(^"Geometry")]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		stack.append_array(node.get_children(true))
		if node is DecorPanel and (node as DecorPanel).texture in backdrop_images:
			var at := _village.to_local((node as Node3D).global_position)
			assert_lt(at.z, -BACKDROP_SOUTH, "%s : au bord nord (%s)" % [node.name, at])
	# La lisière est au nord de la palissade, sans collision, et laisse le chemin nord ouvert.
	var panels := 0
	for child: Node in _village.get_node(^"Geometry/Treeline").get_children(true):
		var panel := child as DecorPanel
		if panel == null:
			continue
		panels += 1
		var local := _village.to_local(panel.global_position)
		assert_lt(local.z, -FENCE, "lisière derrière la palissade nord")
		assert_null(panel.get_node_or_null(^"Collision"), "lisière sans collision")
		assert_gt(absf(local.x) - panel.size_m().x / 2.0, 2.0, "chemin nord entre les lisières")
	assert_gt(panels, 2, "lisière continue de part et d'autre du portail")


# --- Outils -------------------------------------------------------------------------------------


## Chemins des décors (couche world, hors sol) qui touchent une capsule de joueur debout en `at`.
func _decor_at(at: Vector3) -> Array[String]:
	var capsule := CapsuleShape3D.new()
	capsule.radius = PLAYER_RADIUS
	capsule.height = PLAYER_HEIGHT
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = 1
	query.transform = Transform3D(
		Basis.IDENTITY, Vector3(at.x, at.y + STEP_UP + PLAYER_HEIGHT / 2.0, at.z)
	)
	var paths: Array[String] = []
	for hit: Dictionary in _space.intersect_shape(query, 8):
		if hit["collider"] != _ground:
			paths.append(String((hit["collider"] as Node).get_path()))
	return paths


## Aucun décor sur le segment (local au village), capsule posée tous les 0,25 m.
func _assert_open(from: Vector3, to: Vector3, label: String) -> void:
	var steps := maxi(ceili(from.distance_to(to) / 0.25), 1)
	var blocked: Array[String] = []
	for i in steps + 1:
		var hits := _decor_at(_village.to_global(from.lerp(to, float(i) / steps)))
		for path: String in hits:
			if not path in blocked:
				blocked.append(path)
	assert_true(blocked.is_empty(), "%s libre (%s)" % [label, ", ".join(blocked)])


## Pas de WALK_STEP m de from à to (local au village).
func _walk(from: Vector3, to: Vector3) -> PackedVector3Array:
	var points := PackedVector3Array()
	var steps := ceili(from.distance_to(to) / WALK_STEP)
	for i in steps + 1:
		points.append(from.lerp(to, float(i) / steps))
	return points


## Vrai si le joueur peut se tenir en `at` (local au village) : hors du décor et hors des
## couloirs fermés derrière le L de l'entrepôt.
func _reachable(at: Vector3) -> bool:
	if (at.x < -18.8 and at.z < -2.6) or (at.z < -18.8 and at.x < -3.4):
		return false
	return _decor_at(_village.to_global(at)).is_empty()


## Image du décor qui cache l'axe du corps du PNJ en `at` (monde) à toutes les hauteurs relevées,
## quand il est dans la part centrale de l'écran de la caméra en `camera` ; "" s'il est visible
## ou hors de cette part.
func _npc_hidden(camera: Vector3, at: Vector3) -> String:
	var forward := Vector3(0.0, -sin(_pitch), -cos(_pitch))
	var up := Vector3(0.0, cos(_pitch), -sin(_pitch))
	var head := Vector3(at.x, NPC_HEIGHTS[NPC_HEIGHTS.size() - 1], at.z) - camera
	var depth := head.dot(forward)
	if depth <= 0.0:
		return ""
	if absf(atan2(head.dot(up), depth)) > _half_fov or absf(atan2(head.x, depth)) > _half_hfov:
		return ""
	var occluder := ""
	for height: float in NPC_HEIGHTS:
		var t := _occluder(camera, Vector3(at.x, height, at.z))
		if t < 0:
			return ""
		occluder = _triangle_names[t]
	return occluder


## Position de la caméra quand le joueur est en `player` (sans avance ni verrouillage).
func _camera_for(player: Vector3) -> Vector3:
	var back := Vector3(0.0, sin(_pitch), cos(_pitch))
	return player + Vector3.UP * _focus_height + back * _distance


## Relève les triangles des panneaux fondus du village (pas les ombres au sol, ni les décalques
## et l'alpha doux) et leur image.
func _collect_panels() -> void:
	var images := {}
	for child: Node in _village.get_node(^"Geometry").get_children():
		var batch := child as MeshInstance3D
		if batch == null or batch.mesh == null:
			continue
		if not (batch.material_override is ShaderMaterial):
			continue
		var material := batch.material_override as ShaderMaterial
		if material.shader in HIDES_NOTHING:
			continue
		var texture := material.get_shader_parameter(&"albedo_texture") as Texture2D
		if texture == null:
			continue
		if not images.has(texture):
			images[texture] = texture.get_image()
		var image: Image = images[texture]
		var frames_value: Variant = material.get_shader_parameter(&"frames")
		var frames := maxi(roundi(float(frames_value)), 1) if frames_value != null else 1
		var arrays := batch.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var xform := batch.global_transform
		for v in vertices.size():
			_vertices.append(xform * vertices[v])
			_uvs.append(uvs[v])
		for _t in range(0, vertices.size(), 3):
			_triangle_images.append(image)
			_triangle_names.append(texture.resource_path.get_file().get_basename())
			_triangle_frames.append(frames)
	# Boîte de chaque triangle et rangement par case du plan.
	_stamp.resize(_triangle_images.size())
	_stamp.fill(-1)
	for t in _triangle_images.size():
		var a := _vertices[t * 3]
		var b := _vertices[t * 3 + 1]
		var c := _vertices[t * 3 + 2]
		var low := a.min(b).min(c)
		var high := a.max(b).max(c)
		_low.append(low)
		_high.append(high)
		for i in range(floori(low.x / BUCKET), floori(high.x / BUCKET) + 1):
			for k in range(floori(low.z / BUCKET), floori(high.z / BUCKET) + 1):
				var key := Vector2i(i, k)
				if not _buckets.has(key):
					_buckets[key] = PackedInt32Array()
				_buckets[key].append(t)


## Vrai si un pixel opaque du décor est sur le segment caméra → point, à plus de 0,3 m du point.
func _opaque_between(from: Vector3, to: Vector3) -> bool:
	return _occluder(from, to) >= 0


## Triangle du décor dont un pixel opaque est sur le segment caméra → point (à plus de 0,3 m du
## point), -1 sinon.
func _occluder(from: Vector3, to: Vector3) -> int:
	var direction := (to - from).normalized()
	var limit := from.distance_to(to) - 0.3
	var low := from.min(to)
	var high := from.max(to)
	_ray += 1
	for i in range(floori(low.x / BUCKET), floori(high.x / BUCKET) + 1):
		for k in range(floori(low.z / BUCKET), floori(high.z / BUCKET) + 1):
			for t: int in _buckets.get(Vector2i(i, k), PackedInt32Array()):
				if _stamp[t] == _ray:
					continue
				_stamp[t] = _ray
				var box_low := _low[t]
				var box_high := _high[t]
				if (
					box_high.x < low.x
					or box_low.x > high.x
					or box_high.y < low.y
					or box_low.y > high.y
					or box_high.z < low.z
					or box_low.z > high.z
				):
					continue
				var hit: Variant = Geometry3D.ray_intersects_triangle(
					from, direction, _vertices[t * 3], _vertices[t * 3 + 1], _vertices[t * 3 + 2]
				)
				if hit == null or from.distance_to(hit as Vector3) > limit:
					continue
				if _alpha_at(t, hit as Vector3) >= 0.5:
					return t
	return -1


## Opacité de l'image du triangle t au point p (coordonnées barycentriques, UV répétées).
func _alpha_at(t: int, p: Vector3) -> float:
	var a := _vertices[t * 3]
	var v0 := _vertices[t * 3 + 1] - a
	var v1 := _vertices[t * 3 + 2] - a
	var v2 := p - a
	var d00 := v0.dot(v0)
	var d01 := v0.dot(v1)
	var d11 := v1.dot(v1)
	var d20 := v2.dot(v0)
	var d21 := v2.dot(v1)
	var denom := d00 * d11 - d01 * d01
	if absf(denom) < 1e-9:
		return 0.0
	var v := (d11 * d20 - d01 * d21) / denom
	var w := (d00 * d21 - d01 * d20) / denom
	var uv := _uvs[t * 3] * (1.0 - v - w) + _uvs[t * 3 + 1] * v + _uvs[t * 3 + 2] * w
	var image := _triangle_images[t]
	var y := clampi(floori(fposmod(uv.y, 1.0) * image.get_height()), 0, image.get_height() - 1)
	# (P2) Bande animée : l'opacité la plus forte de ses images à cette place.
	var frames := _triangle_frames[t]
	var alpha := 0.0
	for frame in frames:
		var u := (float(frame) + fposmod(uv.x, 1.0)) / frames
		var x := clampi(floori(u * image.get_width()), 0, image.get_width() - 1)
		alpha = maxf(alpha, image.get_pixel(x, y).a)
	return alpha
