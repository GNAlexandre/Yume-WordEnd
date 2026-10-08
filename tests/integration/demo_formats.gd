extends Node3D
## Démo du lot H9 (formats du décor du cahier n° 2, docs/ASSETS_HD2D_MONDE.md sections 3 et 17) :
## l'île seule (sol, roche, ciel, mer de nuages, ciel qui dérive du nœud Decor), sans ses zones,
## et au bord nord des bois, vu par une caméra comme celle du jeu, chaque format avec des images
## faites à l'exécution (aucun fichier du cahier n° 2 n'est lu) :
##   - sol : atlas de 27 tuiles fabriqué ici (les 12 livrées, puis des _b et des matières teintées
##     pour qu'on les voie) : alternance des _b, feuilles mortes, mousse, lit du ruisseau ;
##   - bandes animées (fanions, phases différentes), décalques durs et doux superposés (l'un sur
##     la pente d'une butte), flancs d'un bâtiment long (pignon) et d'un pignon (gouttereau),
##     variantes et retournement (PropScatter), tronc de premier plan qui s'efface devant la fée,
##     nuages qui dérivent, feuilles qui tombent et oiseaux.
## F6 dans l'éditeur. Capture (H9_DEMO_VIEW=sky : caméra presque à l'horizontale) :
##   tools/screenshot.sh res://tests/integration/demo_formats.tscn \
##     build/shots/h9_demo_formats.png 60

const ISLAND := preload("res://src/world/island.tscn")
const VISUAL := preload("res://src/visuals/character_visual.tscn")
const ATLAS := preload("res://assets/hd2d/ground/atlas/ground_atlas.png")
const WALL := preload("res://assets/hd2d/buildings/materials/wall_planks.png")
const ROOF := preload("res://assets/hd2d/buildings/materials/roof_slate.png")
## Où se tient la fée (au bord nord des bois, à l'est du ruisseau) ; la caméra du jeu la cadre.
const FOCUS := Vector3(30.0, 0.0, -63.0)
const PITCH_DEG := 32.0
const FOV_DEG := 30.0
const DISTANCE := 21.0
## Teintes des matières fabriquées pour la démo (tuiles 12 à 26 de l'atlas).
const OVERLAYS := {
	&"leaf_litter": Color(0.9, 0.5, 0.15, 0.3),
	&"moss": Color(0.3, 0.42, 0.15, 0.4),
	&"meadow_flowers": Color(0.95, 0.85, 0.45, 0.25),
	&"gravel": Color(0.62, 0.6, 0.58, 0.5),
	&"garden_soil": Color(0.22, 0.13, 0.08, 0.5),
	&"planks": Color(0.55, 0.36, 0.2, 0.5),
	&"stream_bed": Color(0.6, 0.85, 0.85, 0.4),
}

var _island: Node3D


func _ready() -> void:
	_island = ISLAND.instantiate() as Node3D
	for zone: Node in _island.get_node(^"Zones").get_children():
		zone.free()
	add_child(_island)
	_ground()
	_camera()
	_fairy()
	_buildings()
	_strips()
	_decals()
	_variants()
	_foreground()
	_sky()
	_lives()


func _at(x: float, z: float) -> Vector3:
	return Vector3(FOCUS.x + x, IslandTerrain.height_at(FOCUS.x + x, FOCUS.z + z), FOCUS.z + z)


# --- Sol à 27 tuiles --------------------------------------------------------------------------


## Le sol lit un atlas de 27 tuiles fait ici (matériau à part : terrain.tres n'est pas touché).
func _ground() -> void:
	var tile := IslandTerrain.ATLAS_TILE
	var source := ATLAS.get_image()
	if source.is_compressed():
		source.decompress()
	source.convert(Image.FORMAT_RGBA8)
	var count := IslandTerrain.GROUND_LAYERS.size()
	var rows := ceili(float(count) / IslandTerrain.ATLAS_COLUMNS)
	var atlas := Image.create(
		tile * IslandTerrain.ATLAS_COLUMNS, tile * rows, false, Image.FORMAT_RGBA8
	)
	for index in count:
		var layer := IslandTerrain.GROUND_LAYERS[index]
		var origin := IslandTerrain.GROUND_LAYERS.find(IslandTerrain.ground_layer(layer, 12))
		var cell := Image.create(tile, tile, false, Image.FORMAT_RGBA8)
		cell.blit_rect(source, _cell_rect(origin), Vector2i.ZERO)
		if index >= 12:
			if String(layer).ends_with("_b"):
				# Autre dessin, mêmes couleurs : la tuile retournée, un peu plus claire ici.
				cell.flip_x()
				cell.flip_y()
				cell.adjust_bcs(1.18, 1.0, 1.1)
			else:
				var overlay := Image.create(tile, tile, false, Image.FORMAT_RGBA8)
				overlay.fill(OVERLAYS.get(layer, Color(1.0, 1.0, 1.0, 0.0)))
				cell.blend_rect(overlay, Rect2i(0, 0, tile, tile), Vector2i.ZERO)
		atlas.blit_rect(cell, Rect2i(0, 0, tile, tile), _cell_rect(index).position)
	var material := IslandTerrain.MATERIAL.duplicate() as ShaderMaterial
	var texture := ImageTexture.create_from_image(IslandTerrain.mipmapped_image(atlas))
	material.set_shader_parameter(&"ground_atlas", texture)
	for child: Node in _island.get_node(^"Ground").get_children(true):
		if child.name == &"Mesh":
			(child as MeshInstance3D).material_override = material


func _cell_rect(index: int) -> Rect2i:
	var tile := IslandTerrain.ATLAS_TILE
	var column := index % IslandTerrain.ATLAS_COLUMNS
	var row := floori(float(index) / IslandTerrain.ATLAS_COLUMNS)
	return Rect2i(column * tile, row * tile, tile, tile)


# --- Caméra et fée ----------------------------------------------------------------------------


func _camera() -> void:
	var camera := Camera3D.new()
	camera.fov = FOV_DEG
	camera.far = 1500.0
	var pitch := PITCH_DEG
	if OS.get_environment("H9_DEMO_VIEW") == "sky":
		pitch = 12.0
	var tilt := Basis(Vector3.RIGHT, deg_to_rad(-pitch))
	var target := _at(0.0, 0.0) + Vector3.UP * 0.8
	camera.transform = Transform3D(tilt, target + tilt.z * DISTANCE)
	add_child(camera)
	camera.make_current()


## La fée (planche du skin par défaut), dans le groupe du joueur : le premier plan s'efface
## autour d'elle.
func _fairy() -> void:
	var fairy := Node3D.new()
	fairy.name = "Fairy"
	fairy.add_to_group(DecorPanel.PLAYER_GROUP)
	fairy.position = _at(0.0, 0.0)
	add_child(fairy)
	var visual := VISUAL.instantiate() as CharacterVisual
	fairy.add_child(visual)
	visual.set_skin(SkinRegistry.default_skin())
	visual.play(&"repos")
	_label("fée (premier plan effacé)", _at(0.0, 0.0) + Vector3.UP * 2.2)


# --- Bâtiments : flancs ------------------------------------------------------------------------


func _buildings() -> void:
	# Toit long : flanc en pignon (profondeur × faîtage), vu à l'est.
	var long := Building.new()
	long.footprint = Vector2(5.0, 4.0)
	long.wall_height = 3.0
	long.ridge_height = 4.5
	long.wall_texture = WALL
	long.roof_texture = ROOF
	long.facade = _facade(480, 288, false)
	long.side_facade = _side(384, 432, 288)
	long.position = _at(-8.0, -4.0)
	add_child(long)
	_label("flanc pignon (toit long)", long.global_position + Vector3(3.2, 5.0, 0.0))
	# Pignon en façade : flanc gouttereau (profondeur × mur), vu à l'ouest (retourné).
	var gable := Building.new()
	gable.footprint = Vector2(4.0, 5.0)
	gable.wall_height = 3.0
	gable.ridge_height = 5.0
	gable.gable_front = true
	gable.wall_texture = WALL
	gable.roof_texture = ROOF
	gable.facade = _facade(384, 480, true)
	gable.side_facade = _side(480, 288, 288)
	gable.position = _at(8.5, -5.0)
	add_child(gable)
	_label("flanc gouttereau (pignon), retourné", gable.global_position + Vector3(-3.0, 5.5, 0.0))
	# Petits panneaux de toit et de mur, posés sur la surface, décalés vers la caméra.
	var chimney := _panel_node(_chimney(), long.global_position + Vector3(1.4, 3.75, 1.0))
	chimney.depth_offset = 0.08
	chimney.shadow_width = 0.0
	var sign_board := _panel_node(_sign(), gable.global_position + Vector3(0.0, 2.2, 2.5 + 0.03))
	sign_board.depth_offset = 0.06
	sign_board.shadow_width = 0.0


# --- Bandes animées ---------------------------------------------------------------------------


func _strips() -> void:
	var banner := _banner_strip(6)
	for k in 4:
		var flag := _panel_node(banner, _at(3.5 + k * 1.3, 2.2 + 0.3 * (k % 2)))
		flag.frames = 6
		flag.fps = 6.0
	_label("bandes animées (phases)", _at(5.5, 2.2) + Vector3.UP * 2.0)


# --- Décalques ------------------------------------------------------------------------------------


func _decals() -> void:
	var shadow := GroundDecal.new()
	shadow.texture = _soft_blob(Color(0.24, 0.16, 0.26), 72, 8, 0.65, 9)
	shadow.soft_alpha = true
	shadow.layer = 1
	shadow.position = _at(-4.0, 1.5)
	add_child(shadow)
	var dapple := GroundDecal.new()
	dapple.texture = _soft_blob(Color(1.0, 0.9, 0.65), 48, 8, 0.5, 4)
	dapple.soft_alpha = true
	dapple.layer = 2
	dapple.position = _at(-3.0, 2.0)
	add_child(dapple)
	var leaves := _leaves(288, 192, 3)
	for spot: Vector3 in [Vector3(-6.0, 0.0, 3.5), Vector3(-2.5, 0.0, 0.5)]:
		var pile := GroundDecal.new()
		pile.texture = leaves
		pile.position = _at(spot.x, spot.z)
		pile.rotation.y = spot.x
		add_child(pile)
	# Sur la pente de la butte (bosse de 1,2 m au nord-est), tournée et retournée.
	var slope := GroundDecal.new()
	slope.texture = _leaves(240, 240, 11)
	slope.flip_h = true
	slope.tint = Color(1.0, 0.85, 0.75)
	slope.position = _at(6.2, 2.4)
	slope.rotation.y = 0.6
	add_child(slope)
	_label("décalques durs et doux", _at(-4.0, 1.5) + Vector3.UP * 1.2)


# --- Variantes ----------------------------------------------------------------------------------


func _variants() -> void:
	var scatter := PropScatter.new()
	scatter.follow_ground = true
	scatter.prop = _bush_scene(0)
	var variants: Array[PackedScene] = [_bush_scene(1), _bush_scene(2)]
	scatter.variants = variants
	scatter.random_flip = true
	scatter.scale_range = Vector2(0.85, 1.15)
	scatter.random_seed = 9
	var points := PackedVector3Array()
	for k in 11:
		points.append(Vector3(FOCUS.x - 8.5 + k * 1.6, 0.0, FOCUS.z + 5.6 + 0.6 * (k % 3)))
	scatter.points = points
	add_child(scatter)
	_label("variantes et retournement", _at(-1.0, 6.0) + Vector3.UP * 1.6)


# --- Premier plan -------------------------------------------------------------------------------


func _foreground() -> void:
	var trunk := _panel_node(_trunk(), _at(0.0, 7.5))
	trunk.foreground = true
	trunk.shadow_width = 0.3
	var fern := _panel_node(_fern(), _at(-1.5, 9.0))
	fern.foreground = true
	fern.shadow_width = 0.0


# --- Ciel ---------------------------------------------------------------------------------------


func _sky() -> void:
	var clouds := SkyDrift.new()
	var images: Array[Texture2D] = [_cloud(31), _cloud(32)]
	clouds.textures = images
	clouds.pixels_per_meter = 24.0
	clouds.count = 6
	clouds.span = 160.0
	clouds.fade = 20.0
	clouds.distance_range = Vector2(0.0, 25.0)
	clouds.height_range = Vector2(-3.0, 3.0)
	clouds.speed_range = Vector2(2.0, 4.0)
	clouds.random_seed = 3
	clouds.position = Vector3(FOCUS.x, -33.0, FOCUS.z - 80.0)
	add_child(clouds)
	_label("ciel qui dérive", Vector3(FOCUS.x - 2.0, -2.0, FOCUS.z - 16.0))


# --- Petites vies -------------------------------------------------------------------------------


func _lives() -> void:
	var leaves := AmbientSprites.new()
	leaves.texture = _leaf_strip(8)
	leaves.frames = 8
	leaves.fps = 10.0
	leaves.count = 70
	leaves.area = Vector3(24.0, 7.0, 16.0)
	leaves.speed = 0.7
	leaves.sway = 0.6
	leaves.random_seed = 5
	add_child(leaves)
	var birds := AmbientSprites.new()
	birds.texture = _bird_strip(4)
	birds.frames = 4
	birds.fps = 8.0
	birds.motion = AmbientSprites.Motion.CROSS
	birds.count = 7
	birds.area = Vector3(30.0, 3.0, 8.0)
	birds.lift = 6.0
	birds.speed = 4.0
	birds.random_seed = 6
	add_child(birds)


# --- Outils -------------------------------------------------------------------------------------


func _panel_node(texture: Texture2D, at: Vector3) -> DecorPanel:
	var panel := DecorPanel.new()
	panel.texture = texture
	panel.position = at
	add_child(panel)
	return panel


func _label(text: String, at: Vector3) -> void:
	var label := Label3D.new()
	label.text = text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.pixel_size = 0.012
	label.font_size = 28
	label.outline_size = 8
	label.modulate = Color(1.0, 0.97, 0.88)
	label.render_priority = 10
	label.outline_render_priority = 9
	label.position = at
	add_child(label)


func _texture(image: Image) -> ImageTexture:
	return ImageTexture.create_from_image(image)


## Façade simple : mur, fenêtres couleur cristal (elles luisent), porte ; triangle d'un pignon.
func _facade(w: int, h: int, gable: bool) -> ImageTexture:
	var image := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var wall_top := 288 if gable else 0
	for y in h:
		var half := w / 2.0
		if gable and h - y > wall_top:
			half = w / 2.0 * float(y) / float(h - wall_top)
		image.fill_rect(
			Rect2i(roundi(w / 2.0 - half), y, roundi(half * 2.0), 1), Color(0.5, 0.38, 0.29)
		)
	for k in 2:
		var x := roundi(w * (0.2 + 0.45 * k))
		image.fill_rect(Rect2i(x, h - 220, 70, 80), Color(0.25, 0.18, 0.14))
		image.fill_rect(Rect2i(x + 6, h - 214, 58, 68), Color(1.0, 0.9, 0.65))
	image.fill_rect(Rect2i(roundi(w / 2.0 - 40), h - 190, 80, 190), Color(0.33, 0.22, 0.16))
	image.fill_rect(Rect2i(0, h - 30, w, 30), Color(0.55, 0.53, 0.5))
	return _texture(image)


## Flanc : mur jusqu'à wall px, pignon au-dessus (si h > wall), une bande rouge à gauche (l'angle
## sud : retournée, elle passe à droite vue de l'ouest), une fenêtre.
func _side(w: int, h: int, wall: int) -> ImageTexture:
	var image := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		var half := w / 2.0
		if h - y > wall:
			half = w / 2.0 * float(y) / float(h - wall)
		image.fill_rect(
			Rect2i(roundi(w / 2.0 - half), y, roundi(half * 2.0), 1), Color(0.44, 0.34, 0.27)
		)
	image.fill_rect(Rect2i(0, h - wall, 24, wall), Color(0.68, 0.29, 0.24))
	image.fill_rect(Rect2i(roundi(w * 0.55), h - 210, 72, 80), Color(1.0, 0.9, 0.65))
	image.fill_rect(Rect2i(0, h - 30, w, 30), Color(0.55, 0.53, 0.5))
	return _texture(image)


func _chimney() -> ImageTexture:
	var image := Image.create(48, 96, false, Image.FORMAT_RGBA8)
	image.fill_rect(Rect2i(6, 10, 36, 86), Color(0.62, 0.3, 0.24))
	image.fill_rect(Rect2i(2, 4, 44, 8), Color(0.35, 0.36, 0.4))
	return _texture(image)


func _sign() -> ImageTexture:
	var image := Image.create(58, 38, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.36, 0.25, 0.17))
	image.fill_rect(Rect2i(6, 6, 46, 26), Color(0.8, 0.66, 0.35))
	return _texture(image)


## Fanion qui claque : mât immobile, drapeau dont l'ondulation avance d'une image à l'autre.
func _banner_strip(frames: int) -> ImageTexture:
	var w := 48
	var h := 144
	var image := Image.create(w * frames, h, false, Image.FORMAT_RGBA8)
	for k in frames:
		image.fill_rect(Rect2i(k * w + 4, 4, 4, h - 4), Color(0.3, 0.22, 0.16))
		for x in 36:
			var wave := roundi(5.0 * sin(TAU * (float(x) / 24.0 - float(k) / frames)) * x / 36.0)
			image.fill_rect(Rect2i(k * w + 8 + x, 10 + wave, 1, 26), Color(0.68, 0.29, 0.24))
	return _texture(image)


## Tache douce (alpha continu) : bruit de valeur à faible résolution agrandi en bilinéaire.
func _soft_blob(
	color: Color, size: int, zoom: int, opacity: float, seed_value: int, stretch: float = 1.0
) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var w := roundi(size * stretch)
	var image := Image.create(w, size, false, Image.FORMAT_RGBA8)
	var holes: Array[Vector3] = []
	for _k in 7:
		holes.append(Vector3(rng.randf() * w, rng.randf() * size, rng.randf_range(2.0, 6.0)))
	for y in size:
		for x in w:
			var d := Vector2((x - w / 2.0) / (w / 2.0), (y - size / 2.0) / (size / 2.0)).length()
			var a := clampf(1.0 - d, 0.0, 1.0) * 1.6
			for hole in holes:
				if Vector2(x - hole.x, y - hole.y).length() < hole.z:
					a *= 0.35
			image.set_pixel(x, y, Color(color, clampf(a, 0.0, 1.0) * opacity))
	image.resize(w * zoom, size * zoom, Image.INTERPOLATE_BILINEAR)
	return _texture(image)


## Nuage (alpha doux) : bouffées rondes, sommet pêche éclairé, base lavande, bord estompé.
func _cloud(seed_value: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var w := 128
	var h := 48
	var puffs: Array[Vector3] = []
	for k in 6:
		var x := 20.0 + k * 17.0 + rng.randf_range(-5.0, 5.0)
		var radius := rng.randf_range(10.0, 20.0)
		puffs.append(Vector3(x, h - radius - 2.0, radius))
	var image := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var inside := -INF
			for puff in puffs:
				inside = maxf(inside, 1.0 - Vector2(x - puff.x, y - puff.y).length() / puff.z)
			if inside <= 0.0:
				continue
			var lit := Color(1.0, 0.9, 0.8).lerp(Color(0.5, 0.42, 0.62), float(y) / h)
			image.set_pixel(x, y, Color(lit, clampf(inside * 3.0, 0.0, 0.92)))
	image.resize(w * 4, h * 4, Image.INTERPOLATE_NEAREST)
	return _texture(image)


## Tas de feuilles (alpha 0 ou 255) : petites taches or et rouille, denses au centre.
func _leaves(w: int, h: int, seed_value: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var image := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var colors: Array[Color] = [
		Color(0.8, 0.58, 0.27), Color(0.66, 0.35, 0.23), Color(0.9, 0.75, 0.3), Color(0.5, 0.3, 0.2)
	]
	for _k in floori(w * h / 40.0):
		var r := Vector2(rng.randfn(0.0, 0.3), rng.randfn(0.0, 0.3))
		if r.length() > 0.95:
			continue
		var x := roundi(w / 2.0 + r.x * w / 2.0)
		var y := roundi(h / 2.0 + r.y * h / 2.0)
		image.fill_rect(Rect2i(x, y, 6, 4), colors[rng.randi() % colors.size()])
	return _texture(image)


## Buisson : trois formes (rond, large, haut), lumière à gauche (on voit le retournement).
func _bush_scene(variant: int) -> PackedScene:
	var sizes: Array[Vector2i] = [Vector2i(96, 80), Vector2i(144, 72), Vector2i(80, 120)]
	var size := sizes[variant]
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var greens: Array[Color] = [
		Color(0.5, 0.55, 0.25), Color(0.62, 0.42, 0.2), Color(0.35, 0.45, 0.3)
	]
	for y in size.y:
		for x in size.x:
			var p := Vector2((x - size.x / 2.0) / (size.x / 2.0), (size.y - y) / float(size.y))
			if p.x * p.x + (p.y - 0.5) * (p.y - 0.5) * 4.0 < 1.0:
				var light := 1.25 if p.x < -0.35 else 1.0
				image.set_pixel(x, y, greens[variant] * light)
	var panel := DecorPanel.new()
	panel.texture = _texture(image)
	var scene := PackedScene.new()
	scene.pack(panel)
	panel.free()
	return scene


## Tronc de premier plan, sombre et contrasté (2 × 10 m).
func _trunk() -> ImageTexture:
	var image := Image.create(48, 240, false, Image.FORMAT_RGBA8)
	image.fill_rect(Rect2i(10, 0, 28, 240), Color(0.2, 0.14, 0.12))
	image.fill_rect(Rect2i(14, 0, 6, 240), Color(0.3, 0.21, 0.16))
	image.fill_rect(Rect2i(4, 228, 40, 12), Color(0.17, 0.12, 0.1))
	image.resize(192, 960, Image.INTERPOLATE_NEAREST)
	return _texture(image)


func _fern() -> ImageTexture:
	var image := Image.create(72, 48, false, Image.FORMAT_RGBA8)
	for k in 7:
		var x := 6 + k * 10
		image.fill_rect(Rect2i(x, 10 + (k % 3) * 6, 5, 38 - (k % 3) * 6), Color(0.16, 0.22, 0.14))
	image.resize(288, 192, Image.INTERPOLATE_NEAREST)
	return _texture(image)


## Feuille qui tournoie : ellipse or qui tourne et s'aplatit d'une image à l'autre.
func _leaf_strip(frames: int) -> ImageTexture:
	var image := Image.create(16 * frames, 16, false, Image.FORMAT_RGBA8)
	for k in frames:
		var angle := TAU * k / frames
		var squash := absf(cos(angle)) * 0.7 + 0.3
		for y in 16:
			for x in 16:
				var p := Vector2(x - 7.5, y - 7.5).rotated(angle)
				if (p.x / 6.0) ** 2 + (p.y / (3.0 * squash)) ** 2 < 1.0:
					image.set_pixel(k * 16 + x, y, Color(0.85, 0.6, 0.22))
	return _texture(image)


## Oiseau en vol vers la droite : ailes hautes, à plat, basses, à plat.
func _bird_strip(frames: int) -> ImageTexture:
	var image := Image.create(32 * frames, 16, false, Image.FORMAT_RGBA8)
	var lift: Array[int] = [-5, 0, 4, 0]
	for k in frames:
		image.fill_rect(Rect2i(k * 32 + 12, 7, 10, 3), Color(0.2, 0.18, 0.22))
		for x in 10:
			var y := 8 + roundi(lift[k % lift.size()] * (1.0 - x / 10.0))
			image.fill_rect(Rect2i(k * 32 + 12 - x, y, 1, 2), Color(0.2, 0.18, 0.22))
			image.fill_rect(Rect2i(k * 32 + 21 + x, y, 1, 2), Color(0.2, 0.18, 0.22))
	return _texture(image)
