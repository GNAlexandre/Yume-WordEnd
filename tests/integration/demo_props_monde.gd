extends Node3D
## Démo du lot P0 (scènes de décor du cahier n° 2, docs/ASSETS_HD2D_MONDE.md) : l'île seule (sol,
## relief, ciel, mer de nuages), sans ses zones, et un exemplaire de chaque famille posé sur le sol
## avec sa scène de src/world/props/ (tools/hd2d_scenes.py), telle que la pose les placera :
##   foret    : lisière, arbres de chaque espèce, plantes, rochers, souches, décalques de sous-bois
##              (feuilles, mousse, racines, ombre de feuillage, taches de soleil), roseaux et herbe
##              qui ondulent, premier plan, terrain d'entraînement, feuilles qui tombent ;
##   cour     : objets de la vie, clôture en modules, linge qui flotte, potager, marelle ;
##   bourg    : cinq maisons du bourg avec leurs flancs, cheminée qui fume, lucarne, lierre,
##              enseignes, gouttière, auvent, escalier ; le marché devant (fontaine animée, étals,
##              guirlande, lampadaires) ;
##   maisons  : les cinq maisons du port avec leurs flancs, vapeur du four, lanternes ;
##   port     : le passeur et le Barocupot à 96 px/m, hélices sur les moyeux ; objets du quai ;
##   helice   : gros plan sur les hélices du Barocupot ;
##   couchant : ruines, sacs de sable, épave, fanion et manche à air animés, cloche, brasero,
##              congères ;
##   ciel     : nuages, îles lointaines, île n° 53, dirigeables en vol, brume, rais de lumière,
##              racines et cascade sous la lèvre, oiseaux.
## Les vues sont celles de la caméra du jeu (tangage 32°, champ 30°), plus loin pour les bâtiments
## et les navires. Les décors sont fondus par image comme dans une zone (PropBatcher, cases de
## 32 m) : les draw calls mesurés sont ceux de la pose. F6 dans l'éditeur. Captures :
##   P0_VIEW=<vue> tools/screenshot.sh res://tests/integration/demo_props_monde.tscn \
##     build/shots/p0_<vue>.png 40
## Draw calls et primitives de l'image mesurée sont écrits dans le journal (« P0 vue … »).

const ISLAND := preload("res://src/world/island.tscn")
const VISUAL := preload("res://src/visuals/character_visual.tscn")
const PROPS_DIR := "res://src/world/props"
const LEAF := preload("res://assets/hd2d/anim/falling_leaf_gold.png")
const BIRDS := preload("res://assets/hd2d/anim/birds_flock.png")
## Vues : point visé, distance (m), tangage (°), champ (°).
const VIEWS := {
	"foret": [Vector3(0.0, 2.0, -50.0), 31.0, 30.0, 30.0],
	"cour": [Vector3(0.0, 0.8, 2.0), 22.0, 32.0, 30.0],
	"bourg": [Vector3(-32.0, 2.5, 26.0), 36.0, 26.0, 30.0],
	"maisons": [Vector3(32.0, 4.0, 21.0), 54.0, 20.0, 30.0],
	"port": [Vector3(0.0, 3.0, 50.0), 44.0, 22.0, 30.0],
	"helice": [Vector3(8.5, 4.5, 46.0), 16.0, 6.0, 30.0],
	"passeur": [Vector3(-11.4, 2.4, 48.0), 10.0, 6.0, 30.0],
	"couchant": [Vector3(-51.0, 0.8, 2.0), 24.0, 32.0, 30.0],
	"ciel": [Vector3(0.0, 0.0, -90.0), 30.0, 14.0, 45.0],
}
## Vues qui montrent les étiquettes d'un autre lieu.
const LABEL_SITE := {"helice": "port", "passeur": "port"}
## Image à laquelle les mesures sont écrites.
const MEASURE_FRAME := 30

var _view := ""
## Lieu en cours de construction : seules ses étiquettes s'affichent dans sa vue.
var _site := ""
var _frames := 0
var _island: Node3D
## Décors posés, fondus par image à leur entrée dans l'arbre (comme le nœud Geometry d'une zone).
var _decor: PropBatcher


func _ready() -> void:
	_view = OS.get_environment("P0_VIEW")
	if not VIEWS.has(_view):
		_view = "foret"
	_island = ISLAND.instantiate() as Node3D
	for zone: Node in _island.get_node(^"Zones").get_children():
		zone.free()
	add_child(_island)
	_decor = PropBatcher.new()
	_decor.name = "Decor"
	_decor.cell_size = 32.0
	_site = "foret"
	_forest(VIEWS["foret"][0])
	_site = "cour"
	_yard(VIEWS["cour"][0])
	_site = "bourg"
	_street(VIEWS["bourg"][0])
	_site = "maisons"
	_harbor_houses(Vector3(32.0, 0.0, 26.0))
	_site = "port"
	_port(Vector3(0.0, 0.0, 50.0))
	_site = "couchant"
	_sunset(VIEWS["couchant"][0])
	_site = "ciel"
	_sky()
	add_child(_decor)
	_camera(VIEWS[_view])


func _process(_delta: float) -> void:
	_frames += 1
	if _frames == MEASURE_FRAME:
		print(
			(
				"P0 vue %s : %d draw calls, %d primitives"
				% [
					_view,
					Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
					Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
				]
			)
		)


# --- Forêt --------------------------------------------------------------------------------------


func _forest(focus: Vector3) -> void:
	var c := Vector3(focus.x, 0.0, focus.z)
	_label("lisière", _row(["forest_wall_a"], c + Vector3(0.0, 0.0, -10.0)) + Vector3.UP * 9.0)
	var trees: Array[String] = [
		"oak_a", "beech_a", "maple_a", "birch_a", "pine_small_a", "willow", "dead_tree_a"
	]
	_label("arbres", _row(trees, c + Vector3(0.0, 0.0, -5.0), -1.6) + Vector3.UP * 8.0)
	_row(["pine_tall_b", "sapling_a", "maple_c", "birch_b"], c + Vector3(-1.0, 0.0, -7.5), 1.5)
	var plants: Array[String] = [
		"bush_b",
		"fern_a",
		"grass_clump_a",
		"wildflowers_a",
		"mushroom_cep",
		"heather",
		"myosotis_b",
		"cattails",
		"reeds_sway",
		"grass_sway",
		"fern_d",
		"berry_bush_b"
	]
	_label("plantes", _row(plants, c + Vector3(-2.0, 0.0, -1.0), 0.15) + Vector3.UP * 2.0)
	var rocks: Array[String] = ["boulder_a", "rock_small_a", "boulder_b", "stump_b", "fallen_tree"]
	_label("rochers, souches", _row(rocks, c + Vector3(1.0, 0.0, 2.0), 0.4) + Vector3.UP * 2.6)
	var training: Array[String] = ["training_dummy", "target_board", "cairn", "old_telescope"]
	_row(training, c + Vector3(-7.0, 0.0, 5.0), 0.6)
	var decals: Array[String] = [
		"leaves_gold_a", "moss_patch_a", "roots_a", "puddle_a", "branches_b", "pebbles_a"
	]
	_label("décalques", _row(decals, c + Vector3(3.0, 0.0, 5.5), 0.3) + Vector3.UP * 0.6)
	_prop("canopy_shadow_a", c + Vector3(-3.0, 0.0, -3.0))
	_prop("sun_dapple", c + Vector3(-2.0, 0.0, -2.5))
	_prop("fg_fern", c + Vector3(-4.0, 0.0, 9.0))
	_prop("fg_trunk_a", c + Vector3(7.5, 0.0, 8.0))
	_fairy(c + Vector3(1.0, 0.0, 4.0))
	var leaves := AmbientSprites.new()
	leaves.texture = LEAF
	leaves.frames = 8
	leaves.fps = 10.0
	leaves.count = 40
	leaves.random_seed = 4
	add_child(leaves)


# --- Cour ---------------------------------------------------------------------------------------


func _yard(focus: Vector3) -> void:
	var c := Vector3(focus.x, 0.0, focus.z)
	var back: Array[String] = [
		"firewood_pile",
		"rain_barrel",
		"garden_tools",
		"scarecrow",
		"kids_table",
		"crate_stack",
		"bench_b",
		"wheelbarrow"
	]
	_label("objets de la cour", _row(back, c + Vector3(0.0, 0.0, -3.0), 0.4) + Vector3.UP * 2.6)
	var front: Array[String] = [
		"stump_axe",
		"laundry_basket",
		"toys_a",
		"toys_b",
		"bucket",
		"watering_can",
		"flower_pots",
		"bench_stone",
		"sack_apples"
	]
	_row(front, c + Vector3(-1.0, 0.0, 0.5), 0.35)
	_label(
		"clôture (modules)",
		(
			_row(["fence_low", "fence_low", "fence_low"], c + Vector3(5.0, 0.0, 3.5), 0.0)
			+ Vector3.UP * 1.2
		)
	)
	_label(
		"linge animé",
		_prop("laundry_wave", c + Vector3(-5.0, 0.0, -6.5)).position + Vector3.UP * 2.6
	)
	var decals: Array[String] = ["garden_bed", "chalk_hopscotch", "chalk_drawings", "footprints"]
	_label("potager, craie", _row(decals, c + Vector3(-3.0, 0.0, 4.5), 0.5) + Vector3.UP * 0.6)
	_row(["grass_edge_a", "grass_edge_b", "grass_edge_a"], c + Vector3(3.0, 0.0, 6.5), 0.0)


# --- Bourg : maisons, détails, marché -------------------------------------------------------------


func _street(focus: Vector3) -> void:
	var c := Vector3(focus.x, 0.0, focus.z)
	var houses: Array[String] = [
		"house_timber_a", "house_timber_b", "clockmaker", "house_narrow", "butcher"
	]
	var row := _row_nodes(houses, c + Vector3(0.0, 0.0, -6.0), 3.0)
	_label("maisons du bourg (flancs)", c + Vector3(0.0, 9.5, -6.0))
	var timber := row[1] as Building
	_on_roof("chimney_brick", timber, -1.5)
	_put("chimney_smoke", _roof_point(timber, -1.5) + Vector3.UP * 1.9)
	_on_roof("dormer_tiles", timber, 1.6)
	_on_facade("window_box", row[1] as Building, 1.6, 3.4)
	_on_facade("ivy_wall_a", row[0] as Building, -1.6, 0.0)
	_on_facade("wall_lantern", row[2] as Building, 1.3, 1.8)
	_on_facade("hanging_sign_key", row[2] as Building, -2.0, 2.3)
	_on_facade("drainpipe", row[3] as Building, 1.85, 0.0)
	_on_facade("cafe_door_bell", row[3] as Building, -0.4, 2.3)
	_on_facade("awning_green", row[4] as Building, 0.0, 2.2)
	_on_facade("ivy_wall_b", row[4] as Building, -1.5, 3.2)
	var narrow := row[3] as Building
	var stairs := Vector3(narrow.footprint.x / 2.0 + 1.2, 0.0, narrow.footprint.y / 2.0 - 0.6)
	_put("outdoor_stairs", narrow.position + stairs)
	var market: Array[String] = [
		"market_stall_fruit",
		"fountain_water",
		"market_stall_cloth",
		"cafe_table",
		"barrel_group",
		"hand_cart",
		"notice_board",
		"bread_rack",
		"book_cart",
		"menu_slate",
		"planter_long",
		"crate_apples",
		"broom_bucket",
		"sacks_pile",
		"pigeons"
	]
	_label("marché", _row(market, c + Vector3(0.0, 0.0, 2.5), 0.3) + Vector3.UP * 3.0)
	var lamp_left := _prop("street_lamp_double", c + Vector3(-12.0, 0.0, 5.5))
	_prop("street_lamp_double", c + Vector3(-6.5, 0.0, 5.5))
	_put("bunting_wave", lamp_left.position + Vector3(2.75, 2.2, 0.0))
	_row(["cracks_a", "puddle_b", "drain_grate", "cart_ruts"], c + Vector3(5.0, 0.0, 6.0), 0.6)


# --- Maisons du port ------------------------------------------------------------------------------


func _harbor_houses(focus: Vector3) -> void:
	var c := Vector3(focus.x, 0.0, focus.z)
	var houses: Array[String] = [
		"inn", "harbor_office", "port_hangar", "boiler_workshop", "house_stone_b"
	]
	var row := _row_nodes(houses, c + Vector3(0.0, 0.0, -6.0), 2.5)
	_label("maisons du port (flancs)", c + Vector3(0.0, 10.0, -6.0))
	_on_roof("chimney_stone", row[0] as Building, 2.5)
	_on_roof("dormer_slate", row[0] as Building, -2.0)
	_on_facade("wall_lantern", row[0] as Building, -1.6, 2.0)
	_on_facade("wall_lantern", row[0] as Building, 1.6, 2.0)
	_on_facade("hanging_sign_propeller", row[1] as Building, 1.9, 2.4)
	var boiler := row[3] as Building
	_put("furnace_steam", boiler.position + Vector3(-1.2, 0.0, boiler.footprint.y / 2.0 + 1.0))
	_put("warehouse_roof_deck", _roof_point(row[2] as Building, 0.0))


# --- Port : navires et quai -----------------------------------------------------------------------


func _port(center: Vector3) -> void:
	var ferry := _prop("airship_ferry", center + Vector3(-13.0, 0.6, -2.0))
	var baro := _prop("airship_barocupot", center + Vector3(8.0, 0.6, -4.0))
	_label("passeur, hélice sur le moyeu", ferry.position + Vector3(0.0, 6.3, 0.0))
	_label("Barocupot, deux hélices", baro.position + Vector3(0.0, 9.8, 0.0))
	_prop("mooring_tower", center + Vector3(22.0, 0.0, -1.0))
	var quay: Array[String] = [
		"cargo_net",
		"crystal_crates",
		"fuel_barrels",
		"rope_coil",
		"steam_pipes",
		"workbench",
		"luggage",
		"ticket_booth",
		"dock_lamp",
		"pallet_sacks",
		"chain_pile",
		"tool_rack",
		"propeller_spare"
	]
	_label("quai", _row(quay, center + Vector3(0.0, 0.0, 4.0), 0.35) + Vector3.UP * 3.0)
	_row(["oil_stain", "rust_streak"], center + Vector3(-6.0, 0.0, 6.5), 1.0)


# --- Couchant -----------------------------------------------------------------------------------


func _sunset(focus: Vector3) -> void:
	var c := Vector3(focus.x, 0.0, focus.z)
	var ruins: Array[String] = [
		"ruined_wall_b", "ruined_arch", "ruined_wall_c", "broken_pillar", "cart_wreck"
	]
	_label(
		"ruines du poste de guet", _row(ruins, c + Vector3(0.0, 0.0, -5.0), 0.3) + Vector3.UP * 4.0
	)
	var front: Array[String] = [
		"sandbags",
		"garde_crate",
		"broken_spears",
		"dead_shrub_a",
		"wind_grass_a",
		"wind_rock_d",
		"dead_shrub_b",
		"wind_grass_b",
		"lone_tree_b"
	]
	_row(front, c + Vector3(0.0, 0.0, -0.5), 0.3)
	_label("fanion, manche à air, cloche, brasero", c + Vector3(-3.0, 4.6, 3.0))
	_row(
		["pennant_wave", "windsock_wave", "vigil_bell_ring", "brazier_fire"],
		c + Vector3(-6.0, 0.0, 3.0),
		0.8
	)
	var decals: Array[String] = [
		"sand_drift_a", "ring_stone_flat_a", "ring_stone_flat_b", "ring_stone_flat_c", "cracks_b"
	]
	_row(decals, c + Vector3(4.0, 0.0, 4.0), 0.4)
	_row(["edge_rocks_a", "edge_grass"], c + Vector3(5.0, 0.0, 7.0), 0.5)


# --- Ciel et bord -------------------------------------------------------------------------------


func _sky() -> void:
	var edge := IslandTerrain.edge_point(-PI / 2.0)
	var lip := Vector3(edge.x, 0.0, edge.y)
	# Ce qui pend sous la lèvre, posé au-delà du bord pour que la caméra le voie par-dessus.
	_prop("edge_waterfall", lip + Vector3(-5.0, 0.0, -9.0))
	_prop("edge_roots", lip + Vector3(3.0, 0.0, -9.0))
	_prop("floating_rock_b", lip + Vector3(8.0, -9.0, -12.0))
	_prop("floating_rock_c", lip + Vector3(-12.0, -12.0, -16.0))
	_prop("mist_band", lip + Vector3(0.0, -14.0, -22.0))
	_prop("light_shaft_a", lip + Vector3(-7.0, 0.0, 6.0))
	_prop("light_shaft_b", lip + Vector3(9.0, 0.0, 5.0))
	_prop("cloud_a", lip + Vector3(-28.0, 2.0, -70.0))
	_prop("cloud_b", lip + Vector3(10.0, 8.0, -90.0))
	_prop("cloud_c", lip + Vector3(30.0, -2.0, -60.0))
	_prop("cloud_d", lip + Vector3(-5.0, -10.0, -110.0))
	_prop("cloud_e", lip + Vector3(-45.0, 6.0, -120.0))
	_prop("airship_far_a", lip + Vector3(-12.0, 12.0, -80.0))
	_prop("airship_far_b", lip + Vector3(22.0, 16.0, -70.0))
	_prop("airship_far_c", lip + Vector3(40.0, 4.0, -150.0))
	_prop("airship_far_d", lip + Vector3(2.0, 20.0, -60.0))
	_prop("distant_island_d", lip + Vector3(-60.0, -30.0, -200.0))
	_prop("distant_island_e", lip + Vector3(10.0, -32.0, -230.0))
	_prop("distant_island_f", lip + Vector3(70.0, -28.0, -210.0))
	_prop("island_53", lip + Vector3(-110.0, -36.0, -260.0))
	_prop("horizon_islands", lip + Vector3(0.0, -40.0, -320.0))
	var birds := AmbientSprites.new()
	birds.texture = BIRDS
	birds.frames = 6
	birds.fps = 10.0
	birds.motion = AmbientSprites.Motion.CROSS
	birds.count = 5
	birds.area = Vector3(40.0, 6.0, 20.0)
	birds.lift = 6.0
	birds.speed = 4.0
	birds.random_seed = 6
	add_child(birds)


# --- Outils -------------------------------------------------------------------------------------


## Scène de décor posée sur le sol (at.y : hauteur au-dessus du sol).
func _prop(prop: String, at: Vector3) -> Node3D:
	return _put(prop, Vector3(at.x, at.y + _ground(at.x, at.z), at.z))


## Scène de décor posée à une place du monde.
func _put(prop: String, at: Vector3) -> Node3D:
	var node := (load("%s/%s.tscn" % [PROPS_DIR, prop]) as PackedScene).instantiate() as Node3D
	node.position = at
	_decor.add_child(node)
	return node


func _ground(x: float, z: float) -> float:
	return maxf(IslandTerrain.height_at(x, z), 0.0)


## Largeur d'un décor (m) : image d'un panneau ou d'un décalque, emprise d'un bâtiment.
func _width(node: Node3D) -> float:
	if node is Building:
		return (node as Building).footprint.x
	if node is GroundDecal:
		return (node as GroundDecal).size_m().x
	if node is DecorPanel:
		return (node as DecorPanel).size_m().x
	return 1.0


## Décors côte à côte (gap m entre deux, négatif : ils se chevauchent), centrés sur center ;
## renvoie le haut du milieu de la rangée (pour l'étiquette).
func _row(props: Array[String], center: Vector3, gap: float = 0.3) -> Vector3:
	_row_nodes(props, center, gap)
	return Vector3(center.x, _ground(center.x, center.z), center.z)


func _row_nodes(props: Array[String], center: Vector3, gap: float) -> Array[Node3D]:
	var nodes: Array[Node3D] = []
	var total := 0.0
	for prop: String in props:
		var node := _prop(prop, center)
		nodes.append(node)
		total += _width(node)
	total += gap * (props.size() - 1)
	var x := center.x - total / 2.0
	for node: Node3D in nodes:
		var w := _width(node)
		node.position = Vector3(x + w / 2.0, center.y + _ground(x + w / 2.0, center.z), center.z)
		x += w + gap
	return nodes


## Point du pan de toit sud d'un bâtiment long, à mi-pente, x m de son milieu.
func _roof_point(building: Building, x: float) -> Vector3:
	var half := building.footprint.y / 2.0
	var y := (building.wall_height + building.ridge_height) / 2.0
	return building.position + Vector3(x, y, half / 2.0)


## Panneau posé au pied d'une cheminée ou d'une lucarne, sur le pan de toit sud.
func _on_roof(prop: String, building: Building, x: float) -> Node3D:
	return _put(prop, _roof_point(building, x))


## Panneau plaqué contre la façade sud, x m de son milieu, à y m du sol.
func _on_facade(prop: String, building: Building, x: float, y: float) -> Node3D:
	var front := building.footprint.y / 2.0 + Building.FACADE_GAP
	return _put(prop, building.position + Vector3(x, y, front))


func _camera(view: Array) -> void:
	var camera := Camera3D.new()
	camera.fov = view[3]
	camera.far = 1500.0
	var tilt := Basis(Vector3.RIGHT, deg_to_rad(-float(view[2])))
	var target: Vector3 = view[0]
	target.y += _ground(target.x, target.z)
	camera.transform = Transform3D(tilt, target + tilt.z * float(view[1]))
	add_child(camera)
	camera.make_current()


## La fée (planche du skin par défaut), dans le groupe du joueur : l'échelle, et le premier plan
## qui s'efface autour d'elle.
func _fairy(at: Vector3) -> void:
	var fairy := Node3D.new()
	fairy.name = "Fairy"
	fairy.add_to_group(DecorPanel.PLAYER_GROUP)
	fairy.position = Vector3(at.x, _ground(at.x, at.z), at.z)
	add_child(fairy)
	var visual := VISUAL.instantiate() as CharacterVisual
	fairy.add_child(visual)
	visual.set_skin(SkinRegistry.default_skin())
	visual.play(&"repos")


func _label(text: String, at: Vector3) -> void:
	if _site != _view and LABEL_SITE.get(_view, "") != _site:
		return
	var label := Label3D.new()
	label.text = text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.pixel_size = 0.016
	label.font_size = 28
	label.outline_size = 8
	label.modulate = Color(1.0, 0.97, 0.88)
	label.render_priority = 10
	label.outline_render_priority = 9
	label.position = at
	add_child(label)
