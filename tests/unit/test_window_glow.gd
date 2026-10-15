extends GutTest
## (QO) Lueur des fenêtres par bâtiment (docs/QUALITE.md, QC-02) : Building.window_glow_color et
## window_glow_tolerance, passées au shader des panneaux (panel_core.gdshaderinc : glow_color,
## glow_tolerance) pour la façade et les flancs. On compte, sur les images livrées, les pixels qui
## s'allument (DecorPanel.glow_weight, jumeau du shader) :
## - les carreaux des façades de l'entrepôt (lot R1, #FCD069 à #FCE18F) s'allument ;
## - le café garde la règle par défaut (sa façade de nuit est commandée : cahier n° 5, R0.9) ;
## - le torchis ocre des chaumières, qui garde la règle par défaut (#FFCA63 à 0,12), reste éteint.

const WAREHOUSES: Array[String] = [
	"res://src/world/props/warehouse_front_a.tscn",
	"res://src/world/props/warehouse_front_b.tscn",
]
const CAFE := "res://src/world/props/cafe_village.tscn"
const COTTAGES: Array[String] = [
	"res://src/world/props/cottage_thatch_a.tscn",
	"res://src/world/props/cottage_thatch_b.tscn",
	"res://src/world/props/cottage_thatch_c.tscn",
]
## Un pixel sur STEP dans chaque sens (les images font jusqu'à 1728 × 960 px).
const STEP := 2


func test_warehouse_panes_light_up_at_night() -> void:
	for path: String in WAREHOUSES:
		var building := _building(path)
		for texture: Texture2D in [building.facade, building.side_facade]:
			var panes := _panes(texture)
			var lit := _mean_glow(texture, building, true)
			assert_gt(panes, 1000, "%s : des carreaux clairs" % texture.resource_path)
			assert_gt(lit, 0.45, "%s : les carreaux s'allument" % texture.resource_path)
			# La règle par défaut (#FFCA63) laissait à demi éteints les carreaux plus clairs de
			# l'aile ouest (warehouse_front_a) : le défaut QC-02.
			if texture.resource_path.contains("front_a"):
				var before := _mean_glow_with(
					texture, DecorPanel.GLOW_COLOR, DecorPanel.GLOW_TOLERANCE
				)
				assert_lt(before, 0.4, "%s : à demi éteints avant" % texture.resource_path)
				assert_gt(lit, before + 0.25, "%s : bien plus allumés" % texture.resource_path)
			# Hors des carreaux clairs, seuls leurs bords plus sombres s'allument un peu.
			assert_lt(
				_mean_glow(texture, building, false),
				0.005,
				"%s : ni le bois ni la pierre" % texture.resource_path
			)
		building.free()


func test_cafe_keeps_the_default_rule() -> void:
	# Une règle propre à ses lampes de vitrine en faisait des taches blanches bruitées : le café garde
	# la règle par défaut, en attendant sa façade de nuit (cahier n° 5, R0.9 ; QC-16).
	var building := _building(CAFE)
	assert_true(
		building.window_glow_color.is_equal_approx(DecorPanel.GLOW_COLOR), "couleur par défaut"
	)
	assert_almost_eq(building.window_glow_tolerance, DecorPanel.GLOW_TOLERANCE, 0.0001, "tolérance")
	building.free()


func test_cottage_daub_stays_dark() -> void:
	for path: String in COTTAGES:
		var building := _building(path)
		assert_true(
			building.window_glow_color.is_equal_approx(DecorPanel.GLOW_COLOR),
			"%s : règle par défaut" % path
		)
		for texture: Texture2D in [building.facade, building.side_facade]:
			var opaque := _opaque(texture)
			var lit := _count_lit(texture, building)
			assert_lt(
				float(lit) / opaque, 0.005, "%s : le torchis reste éteint" % texture.resource_path
			)
		building.free()


func test_facade_and_sides_carry_the_glow_rule() -> void:
	var building := _building(WAREHOUSES[1])
	add_child(building)
	for child_name: String in ["Facade", "Sides"]:
		var mesh := building.get_node(NodePath(child_name)) as MeshInstance3D
		var material := mesh.material_override as ShaderMaterial
		assert_not_null(material, child_name)
		if material == null:
			continue
		# Élevée à la puissance 1/2,2, comme le pixel lu par le shader.
		var rule: Variant = material.get_shader_parameter(&"glow_color")
		assert_typeof(rule, TYPE_VECTOR4, "%s : couleur en Vector4" % child_name)
		var wanted := DecorPanel.glow_shader_color(building.window_glow_color)
		assert_true((rule as Vector4).is_equal_approx(wanted), "%s : couleur" % child_name)
		assert_almost_eq(
			float(material.get_shader_parameter(&"glow_tolerance")),
			building.window_glow_tolerance,
			0.0001,
			"%s : tolérance" % child_name
		)
	# Les chaumières gardent le matériau par défaut, partagé avec les autres images.
	var default_material := DecorPanel.material_for(building.facade, Color.WHITE, 0.6)
	assert_ne(
		default_material,
		(building.get_node(^"Facade") as MeshInstance3D).material_override,
		"une règle propre : un autre matériau"
	)
	building.free()


func _building(path: String) -> Building:
	var building := (load(path) as PackedScene).instantiate() as Building
	assert_not_null(building, path)
	return building


func _image(texture: Texture2D) -> Image:
	var image := texture.get_image()
	if image.is_compressed():
		image.decompress()
	return image


## Carreau clair et chaud (comme build/qc/glow_sim.py) : luminance > 0,72, rouge − bleu > 0,2.
static func _is_pane(c: Color) -> bool:
	return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b > 0.72 and c.r - c.b > 0.2


func _panes(texture: Texture2D) -> int:
	var image := _image(texture)
	var count := 0
	for y in range(0, image.get_height(), STEP):
		for x in range(0, image.get_width(), STEP):
			var c := image.get_pixel(x, y)
			if c.a >= 0.5 and _is_pane(c):
				count += 1
	return count


func _opaque(texture: Texture2D) -> int:
	var image := _image(texture)
	var count := 0
	for y in range(0, image.get_height(), STEP):
		for x in range(0, image.get_width(), STEP):
			if image.get_pixel(x, y).a >= 0.5:
				count += 1
	return count


## Lueur moyenne des carreaux (panes vrai) ou des autres pixels, sous la règle du bâtiment.
func _mean_glow(texture: Texture2D, building: Building, panes: bool) -> float:
	var image := _image(texture)
	var total := 0.0
	var count := 0
	for y in range(0, image.get_height(), STEP):
		for x in range(0, image.get_width(), STEP):
			var c := image.get_pixel(x, y)
			if c.a < 0.5 or _is_pane(c) != panes:
				continue
			total += DecorPanel.glow_weight(
				c, building.window_glow_color, building.window_glow_tolerance
			)
			count += 1
	return total / maxf(count, 1.0)


func _mean_glow_with(texture: Texture2D, color: Color, tolerance: float) -> float:
	var image := _image(texture)
	var total := 0.0
	var count := 0
	for y in range(0, image.get_height(), STEP):
		for x in range(0, image.get_width(), STEP):
			var c := image.get_pixel(x, y)
			if c.a >= 0.5 and _is_pane(c):
				total += DecorPanel.glow_weight(c, color, tolerance)
				count += 1
	return total / maxf(count, 1.0)


## Pixels allumés à plus de 30 % sous la règle du bâtiment.
func _count_lit(texture: Texture2D, building: Building) -> int:
	var image := _image(texture)
	var count := 0
	for y in range(0, image.get_height(), STEP):
		for x in range(0, image.get_width(), STEP):
			var c := image.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var w := DecorPanel.glow_weight(
				c, building.window_glow_color, building.window_glow_tolerance
			)
			if w > 0.3:
				count += 1
	return count
