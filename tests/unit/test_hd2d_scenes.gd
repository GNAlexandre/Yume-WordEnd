extends GutTest
## (P0) Scènes de décor du cahier n° 2 (docs/ASSETS_HD2D_MONDE.md), faites par
## tools/hd2d_scenes.py d'après sa table des catégories (tools/hd2d_scenes.json) : chaque image du
## manifeste qui se pose dans le monde a sa scène src/world/props/<nom>.tscn, qui se charge, pointe
## sur son image, au bon format (panneau animé à la cadence du manifeste, décalque doux ou net,
## lointain à sa densité, premier plan, détail de mur ou de toit décalé vers la caméra, bâtiment
## avec son flanc) ; ce qui bloque a sa collision (couche 1), ce qu'on traverse n'en a pas ; chaque
## flanc a la taille du contrat de son bâtiment ; les hélices des navires sont sur les moyeux
## dessinés ; les sprites qui volent n'ont pas de scène (textures d'AmbientSprites).
## tools/hd2d_scenes.py check fait les mêmes vérifications sur le texte des scènes.

const MANIFEST := "res://tools/hd2d_manifest.json"
const TABLE := "res://tools/hd2d_scenes.json"
const PROPS_DIR := "res://src/world/props"
## Genres du manifeste qui peuvent demander une scène.
const SCENE_KINDS: Array[String] = ["panel", "anim", "decal", "facade"]
const META := &"hd2d_category"
const PPM := 96.0
## Moyeux dessinés sur le flanc des navires, mesurés dans les images livrées (px depuis le coin
## haut gauche : centre du bout de l'axe de cuivre) ; les hélices s'y posent à 0,1 m près.
const HUBS := {
	"airship_ferry": [Vector2(853.0, 499.0)],
	"airship_barocupot": [Vector2(789.0, 827.0), Vector2(1613.0, 833.0)],
}
const HUB_TOLERANCE := 0.1
## Petits objets : image de 0,6 m de haut au plus (58 px) ; au-delà, un objet de la vie bloque.
const SMALL_OBJECT_M := 0.61

var _manifest: Dictionary = {}
var _table: Dictionary = {}
## Images du cahier n° 2 qui peuvent demander une scène : [entrée, catégorie].
var _plan: Array = []
var _by_key: Dictionary = {}


func before_all() -> void:
	_manifest = _json(MANIFEST)
	_table = _json(TABLE)
	for entry: Dictionary in _manifest.get("images", []):
		_by_key[_key(entry)] = entry
		if entry.has("lot") and String(entry["kind"]) in SCENE_KINDS:
			_plan.append([entry, _category(entry)])


func _json(path: String) -> Dictionary:
	var json := JSON.new()
	assert_eq(json.parse(FileAccess.get_file_as_string(path)), OK, "%s lisible" % path)
	return json.data if json.data is Dictionary else {}


## Chemin de l'image sous assets/hd2d/, sans extension (« props/oak_a »).
func _key(entry: Dictionary) -> String:
	return String(entry["path"]).trim_prefix("assets/hd2d/").get_basename()


func _name(entry: Dictionary) -> String:
	return String(entry["path"]).get_file().get_basename()


## Première catégorie de la table dont un motif nomme l'image (vide : aucune).
func _category(entry: Dictionary) -> Dictionary:
	var key := _key(entry)
	for category: Dictionary in _table.get("categories", []):
		for pattern: String in category["match"]:
			if key.match(pattern):
				return category
	return {}


## Taille d'une image (une image de la bande) dans le monde (m).
func _image_m(entry: Dictionary) -> Vector2:
	var size := Vector2(float(entry["size"][0]), float(entry["size"][1]))
	return size / float(entry.get("ppm", PPM))


func _scene_path(entry: Dictionary) -> String:
	return "%s/%s.tscn" % [PROPS_DIR, _name(entry)]


## Les scènes attendues : [entrée, catégorie, instance] (instances à libérer par l'appelant).
func _instances() -> Array:
	var out := []
	for item: Array in _plan:
		var category: Dictionary = item[1]
		if category.is_empty() or String(category["scene"]) == "none":
			continue
		var packed := load(_scene_path(item[0])) as PackedScene
		if packed != null:
			out.append([item[0], category, packed.instantiate()])
	return out


func _free_all(instances: Array) -> void:
	for item: Array in instances:
		(item[2] as Node).free()


func test_table_names_every_image() -> void:
	assert_gt(_plan.size(), 250, "les images du cahier n° 2 qui se posent")
	var problems: Array[String] = []
	var names := {}
	for item: Array in _plan:
		var category: Dictionary = item[1]
		if category.is_empty():
			problems.append("%s : aucune catégorie" % _key(item[0]))
		elif String(category["scene"]) != "none":
			var label := _name(item[0])
			if names.has(label):
				problems.append("%s : nom de scène déjà pris" % _key(item[0]))
			names[label] = true
	assert_true(problems.is_empty(), "; ".join(problems))
	assert_gt(names.size(), 240, "scènes attendues")


func test_every_expected_scene_loads_and_points_on_its_image() -> void:
	var problems: Array[String] = []
	var count := 0
	for item: Array in _plan:
		var category: Dictionary = item[1]
		if category.is_empty() or String(category["scene"]) == "none":
			continue
		count += 1
		if not ResourceLoader.exists(_scene_path(item[0])):
			problems.append("%s absente" % _scene_path(item[0]))
	var instances := _instances()
	assert_eq(instances.size(), count, "chaque scène se charge")
	for item: Array in instances:
		var entry: Dictionary = item[0]
		var category: Dictionary = item[1]
		var node: Node = item[2]
		var image := "res://" + String(entry["path"])
		var texture: Texture2D = null
		match String(category["scene"]):
			"panel", "ship":
				if node is DecorPanel:
					texture = (node as DecorPanel).texture
			"decal":
				if node is GroundDecal:
					texture = (node as GroundDecal).texture
			"building":
				if node is Building:
					texture = (node as Building).facade
		if texture == null:
			problems.append("%s : racine %s sans image" % [_name(entry), category["scene"]])
		elif texture.resource_path != image:
			problems.append("%s : %s au lieu de %s" % [_name(entry), texture.resource_path, image])
		if String(node.get_meta(META, "")) != String(category["id"]):
			problems.append("%s : catégorie %s attendue" % [_name(entry), category["id"]])
	_free_all(instances)
	assert_true(problems.is_empty(), "; ".join(problems))


func test_panels_and_decals_have_the_format_of_the_manifest() -> void:
	var problems: Array[String] = []
	var animated := 0
	var soft := 0
	for item: Array in _instances():
		var entry: Dictionary = item[0]
		var category: Dictionary = item[1]
		var label := _name(entry)
		var panel := item[2] as DecorPanel
		var decal := item[2] as GroundDecal
		if decal != null:
			if decal.soft_alpha != bool(entry.get("soft_alpha", false)):
				problems.append("%s : soft_alpha" % label)
			soft += int(decal.soft_alpha)
			var layer := int(category.get("decal", {}).get("layer", 0))
			if decal.layer != layer:
				problems.append("%s : couche %d attendue" % [label, layer])
		elif panel != null and String(category["scene"]) == "panel":
			problems.append_array(_panel_problems(entry, category, panel))
			if String(entry["kind"]) == "anim":
				animated += 1
		(item[2] as Node).free()
	assert_true(problems.is_empty(), "; ".join(problems))
	assert_gt(animated, 10, "bandes animées posées")
	assert_gt(soft, 5, "décalques doux")


func _panel_problems(entry: Dictionary, category: Dictionary, panel: DecorPanel) -> Array[String]:
	var problems: Array[String] = []
	var label := _name(entry)
	var frames := int(entry.get("frames", 1))
	if panel.frames != frames or not is_equal_approx(panel.fps, float(entry.get("fps", 0.0))):
		problems.append(
			"%s : %d images à %s images/s attendues" % [label, frames, entry.get("fps")]
		)
	if not is_equal_approx(panel.pixels_per_meter, float(entry.get("ppm", PPM))):
		problems.append("%s : densité %s attendue" % [label, entry.get("ppm", PPM)])
	if not panel.size_m().is_equal_approx(_image_m(entry)):
		problems.append("%s : taille %s" % [label, panel.size_m()])
	var settings: Dictionary = category.get("panel", {})
	if panel.foreground != bool(settings.get("foreground", false)):
		problems.append("%s : premier plan" % label)
	if not is_equal_approx(panel.shadow_width, float(settings.get("shadow_width", 0.8))):
		problems.append("%s : ombre %s" % [label, panel.shadow_width])
	if not is_equal_approx(panel.depth_offset, float(settings.get("depth_offset", 0.0))):
		problems.append("%s : décalage vers la caméra %s" % [label, panel.depth_offset])
	var height := _image_m(entry).y
	var offset := 0.0
	if String(category.get("image_anchor", "")) == "top":
		offset = -height
	elif String(entry.get("anchor", "")) == "center":
		offset = -height / 2.0
	if absf(panel.image_offset.y - offset) > 0.002 or panel.image_offset.x != 0.0:
		problems.append("%s : origine (image_offset %s)" % [label, panel.image_offset])
	return problems


func test_collisions_follow_the_category() -> void:
	var problems: Array[String] = []
	var blocking := 0
	for item: Array in _instances():
		var entry: Dictionary = item[0]
		var category: Dictionary = item[1]
		var node: Node = item[2]
		var label := _name(entry)
		var body := node.get_node_or_null(^"Collision") as StaticBody3D
		var blocks := String(category["scene"]) == "building" or category.get("collision") != null
		if not blocks:
			if body != null:
				problems.append("%s : on le traverse (catégorie %s)" % [label, category["id"]])
		elif body == null:
			problems.append("%s : collision attendue (catégorie %s)" % [label, category["id"]])
		else:
			blocking += 1
			if body.collision_layer != 1 or body.collision_mask != 0:
				problems.append("%s : couche 1, masque 0" % label)
			problems.append_array(_shape_problems(entry, body))
		node.free()
	assert_true(problems.is_empty(), "; ".join(problems))
	assert_gt(blocking, 100, "décors qui bloquent")


## Les formes tiennent dans la largeur de l'image (ou l'emprise d'un bâtiment) et posent sur le
## sol.
func _shape_problems(entry: Dictionary, body: StaticBody3D) -> Array[String]:
	var problems: Array[String] = []
	var width := _image_m(entry).x + 0.01
	var shapes := body.find_children("*", "CollisionShape3D", false, false)
	if shapes.is_empty():
		problems.append("%s : collision sans forme" % _name(entry))
	for child: Node in shapes:
		var shape := child as CollisionShape3D
		var extent := 0.0
		var height := 0.0
		if shape.shape is BoxShape3D:
			extent = (shape.shape as BoxShape3D).size.x
			height = (shape.shape as BoxShape3D).size.y
		elif shape.shape is CylinderShape3D:
			extent = (shape.shape as CylinderShape3D).radius * 2.0
			height = (shape.shape as CylinderShape3D).height
		else:
			problems.append("%s : forme simple attendue" % _name(entry))
			continue
		if absf(shape.position.x) + extent / 2.0 > width / 2.0:
			problems.append("%s : forme plus large que l'image" % _name(entry))
		if absf(shape.position.y - height / 2.0) > 0.01:
			problems.append("%s : forme posée au sol" % _name(entry))
	return problems


## Petits objets (on les traverse) et objets de la vie (ils bloquent) : la limite de hauteur
## écrite dans la table.
func test_small_objects_and_blocking_objects_by_height() -> void:
	var small := 0
	var objects := 0
	for item: Array in _plan:
		var category: Dictionary = item[1]
		var id := String(category.get("id", ""))
		var height := _image_m(item[0]).y
		if id == "small_object":
			small += 1
			assert_lte(height, SMALL_OBJECT_M, "%s : petit objet" % _name(item[0]))
		elif id.begins_with("object"):
			objects += 1
			assert_gt(height, SMALL_OBJECT_M, "%s : objet qui bloque" % _name(item[0]))
	assert_gt(small, 5, "petits objets")
	assert_gt(objects, 20, "objets qui bloquent")


func test_every_side_is_the_flank_of_its_building_at_contract_size() -> void:
	var problems: Array[String] = []
	var count := 0
	for entry: Dictionary in _manifest.get("images", []):
		if String(entry["kind"]) != "side":
			continue
		count += 1
		var label := _name(entry).trim_suffix("_side")
		var path := "%s/%s.tscn" % [PROPS_DIR, label]
		var packed := load(path) as PackedScene if ResourceLoader.exists(path) else null
		var building := packed.instantiate() as Building if packed != null else null
		if building == null:
			problems.append("%s : bâtiment absent" % path)
			continue
		var side := building.side_facade
		if side == null or side.resource_path != "res://" + String(entry["path"]):
			problems.append("%s : side_facade = %s attendu" % [label, entry["path"]])
		else:
			var gap := (building.side_size_m() - building.side_contract_size()).abs()
			if gap.x > 0.011 or gap.y > 0.011:
				problems.append(
					(
						"%s : flanc de %s m, contrat %s m"
						% [label, building.side_size_m(), building.side_contract_size()]
					)
				)
		var shape := String(entry.get("roof", ""))
		if shape != ("eaves" if building.gable_front else "gable"):
			problems.append("%s : flanc %s pour ce toit" % [label, shape])
		building.free()
	assert_eq(count, 19, "flancs des 9 bâtiments existants et des 10 nouveaux")
	assert_true(problems.is_empty(), "; ".join(problems))


## Les dix maisons de la section 9.2 : façade, matières, emprise et hauteurs de la table.
func test_new_buildings_follow_section_9_2() -> void:
	var buildings: Dictionary = _table.get("buildings", {})
	var found := 0
	for label: String in buildings:
		if label.begins_with("_"):
			continue
		found += 1
		var data: Dictionary = buildings[label]
		var building := (load("%s/%s.tscn" % [PROPS_DIR, label]) as PackedScene).instantiate()
		assert_true(building is Building, "%s : Building" % label)
		if not building is Building:
			building.free()
			continue
		var b := building as Building
		var facade_m := Vector2(b.facade.get_size()) / PPM
		assert_eq(b.gable_front, String(data["type"]) == "pignon", "%s : type" % label)
		assert_almost_eq(
			b.footprint, Vector2(facade_m.x, float(data["depth"])), Vector2.ONE * 0.01, label
		)
		assert_almost_eq(b.wall_height, float(data["wall"]), 0.01, "%s : mur" % label)
		assert_almost_eq(b.ridge_height, float(data["ridge"]), 0.01, "%s : faîtage" % label)
		var wall := "res://assets/hd2d/buildings/materials/%s.png" % data["wall_texture"]
		var roof := "res://assets/hd2d/buildings/materials/%s.png" % data["roof_texture"]
		assert_eq(b.wall_texture.resource_path, wall, "%s : matière des murs" % label)
		assert_eq(b.roof_texture.resource_path, roof, "%s : matière du toit" % label)
		b.free()
	assert_eq(found, 10, "les dix maisons du bourg et du port")


func test_ship_propellers_sit_on_the_drawn_hubs() -> void:
	for ship: String in HUBS:
		var node := (load("%s/%s.tscn" % [PROPS_DIR, ship]) as PackedScene).instantiate()
		var hull := node as DecorPanel
		assert_not_null(hull, "%s : DecorPanel" % ship)
		if hull == null:
			node.free()
			continue
		assert_eq(hull.pixels_per_meter, PPM, "%s : à quai, 96 px par mètre" % ship)
		var image := Vector2(hull.texture.get_size())
		var propellers: Array[DecorPanel] = []
		for child: Node in hull.get_children():
			if child is DecorPanel:
				propellers.append(child as DecorPanel)
		var hubs: Array = HUBS[ship]
		assert_eq(propellers.size(), hubs.size(), "%s : une hélice par moyeu" % ship)
		var strip := "res://assets/hd2d/anim/%s_propeller.png" % ship
		for propeller in propellers:
			assert_eq(propeller.texture.resource_path, strip, "%s : bande de l'hélice" % ship)
			assert_eq(propeller.frames, 4, "%s : 4 images" % ship)
			assert_eq(propeller.fps, 12.0, "%s : 12 images/s" % ship)
			assert_gt(propeller.depth_offset, 0.0, "%s : devant la coque" % ship)
			assert_eq(propeller.shadow_width, 0.0, "%s : sans ombre" % ship)
			# L'image de l'hélice est centrée sur son moyeu : une demi-image au-dessus de l'ancre.
			var hub := propeller.position + Vector3.UP * propeller.size_m().y / 2.0
			var nearest := INF
			for drawn: Vector2 in hubs:
				var want := Vector3((drawn.x - image.x / 2.0) / PPM, (image.y - drawn.y) / PPM, 0.0)
				nearest = minf(nearest, hub.distance_to(want))
			assert_lt(
				nearest, HUB_TOLERANCE, "%s : hélice %s sur un moyeu" % [ship, propeller.name]
			)
		node.free()


func test_flying_sprites_have_no_scene() -> void:
	var count := 0
	for item: Array in _plan:
		var category: Dictionary = item[1]
		if String(category.get("scene", "")) == "none":
			count += 1
			assert_false(
				ResourceLoader.exists(_scene_path(item[0])), "%s : pas de scène" % _name(item[0])
			)
	assert_eq(count, 7, "oiseaux, deux feuilles, papillon, lucioles et deux hélices")
