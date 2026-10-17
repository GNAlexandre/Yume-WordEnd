@tool
class_name DecorPanel
extends Node3D
## Décor HD-2D en panneau : une image debout (docs/ASSETS_HD2D.md, section 7) posée sur son ancre
## (milieu du bord bas = origine du nœud), à PIXELS_PER_METER px par mètre, tournée vers le sud
## (la caméra fixe regarde le nord) quelle que soit l'orientation du nœud, avec son ombre douce
## au sol. Racine des scènes de src/world/props/ ; la collision (enfant « Collision »,
## StaticBody3D de la couche 1) reste dans la scène et garde l'orientation du nœud. Propriétaire :
## L2 (monde).
##
## Les enfants « Quad » et « Shadow » sont internes, recréés au chargement (aussi dans l'éditeur) :
## seules les données ci-dessous sont enregistrées. Matériaux et meshes sont partagés par image,
## pour que le PropBatcher de la zone fonde tous les panneaux d'une même image en un draw call.
##
## (I1) Vues d'un meuble (docs/ASSETS_HD2D_ILE68.md, section 2.7) : un panneau se tourne toujours
## vers le sud, donc un meuble adossé à un mur est ou ouest, ou tourné, n'aurait que sa face. Son
## orientation (facing : south, east, west, north ; sinon celle du nœud : sa face est son +Z)
## choisit l'image : <nom>_side (de flanc, face tournée vers l'est) pour l'est, retournée pour
## l'ouest ; <nom>_back (de dos), ou <nom>_foot (lit vu par le pied), pour le nord ; la face pour
## le sud, et pour toute vue que la livraison n'a pas encore. Les vues se trouvent par leur nom, à
## côté de l'image de face (view_texture) ; la collision (enfant « Collision ») suit la rotation
## du nœud : ce qui pose le meuble (tools/interior_maps.py) le tourne quand la vue existe.
##
## (H9) Formats du cahier n° 2 (docs/ASSETS_HD2D_MONDE.md, sections 3.4 et 3.7) :
## - bande animée (frames > 1) : images côte à côte, la taille du panneau est celle d'une image ;
##   l'image change dans le shader (TIME, fps), décalée d'une phase tirée de la position du
##   panneau (strip_phase), portée par UV2.x des sommets : le PropBatcher fond toujours tous les
##   panneaux d'une même image en un draw call, animés compris ; l'animation continue en pause ;
## - flip_h : image retournée (variantes de PropScatter) ;
## - depth_offset : le panneau est dessiné comme s'il était depth_offset m plus près de la caméra
##   (UV2.y, sans bouger à l'écran) : cheminée, lucarne, lierre, enseigne posés contre un mur ou
##   sur un pan de toit passent devant lui sans scintiller ;
## - foreground : premier plan, qui s'efface en trame autour du joueur quand il passe devant lui
##   (panel_foreground.gdshader ; centre posé à chaque image par update_foreground).
##
## (RD) Rendu de la profondeur :
## - genre (DecorGenre : arbre, lisière, buisson, herbe, roseau, rocher, clôture, mur, poteau,
##   objet), tiré de la catégorie de la scène (metadata/hd2d_category) ou du nom de l'image ;
##   current_genre() ;
## - ombre peinte (enfant interne « Shadow », panel_shadow.gdshader, un matériau pour toutes) : un
##   cœur sombre au pied, à la taille du panneau (shadow_width × shadow_depth : ovale, ou bande pour
##   une clôture, un mur, une lisière), et une traîne à l'opposé du soleil, longue d'une part de la
##   hauteur de l'image selon le genre (Atmosphere en règle la direction et la longueur) ;
## - vent : la cime d'un arbre, d'une herbe, d'un roseau, d'une haie se balance (wind_px du
##   matériau, d'après le genre et la hauteur de l'image) ; jamais un bâtiment ni un objet ;
## - tone : variation de luminosité et de teinte de l'exemplaire (± part ; PropScatter la tire
##   par position), portée par les sommets du mesh fondu (le PropBatcher la lit dans la méta
##   TONE_META du quad) : un matériau par image, pas un de plus.

## Densité des images du monde (Chtholly : 1,5 m = 144 px).
const PIXELS_PER_METER := 96.0
const PANEL_SHADER := preload("res://src/world/shaders/panel.gdshader")
## (H9) Variante de premier plan, qui s'efface devant le joueur.
const FOREGROUND_SHADER := preload("res://src/world/shaders/panel_foreground.gdshader")
## Variante à alpha doux (soft_alpha : fumée, vapeur, cascade, nuages, brume, rais de lumière).
const SOFT_SHADER := preload("res://src/world/shaders/panel_soft.gdshader")
## (QO) Lueur propre par défaut (panel_core.gdshaderinc : glow_color, glow_tolerance) : la couleur
## de l'image qu'allume le réglage par défaut du shader (1 ; 0,9 ; 0,65), soit #FFCA63 une fois
## ramenée de la puissance 1/2,2 (glow_shader_color), et la distance au-delà de laquelle un pixel
## reste éteint. GLOW_LIFT : puissance appliquée par le shader au pixel lu.
const GLOW_LIFT := 1.0 / 2.2
const GLOW_COLOR := Color(1.0, 0.7931, 0.3876)
const GLOW_TOLERANCE := 0.12
## (RD) Ombre peinte (cœur au pied et traîne à l'opposé du soleil), un matériau pour toutes.
const SHADOW_SHADER := preload("res://src/world/shaders/panel_shadow.gdshader")
## Hauteur de l'ombre au-dessus du sol (m) : pas de scintillement avec le sol.
const SHADOW_LIFT := 0.04
## (RD) Formes de l'ombre (panel_shadow.gdshader) : cœur ovale, cœur en bande, traîne ronde,
## traîne d'un décor long (parallélogramme).
const SHADOW_CORE := 0
const SHADOW_STRIP := 1
const SHADOW_TAIL := 2
const SHADOW_TAIL_LONG := 3
## (RD) Profondeur de la bande au pied d'un décor long (m) et longueur maximale d'une traîne (m).
const SHADOW_STRIP_DEPTH := 0.9
const SHADOW_TAIL_MAX := 6.0
## (RD) Méta du quad : code de la variation de teinte (tone_code), lu par le PropBatcher.
const TONE_META := &"hd2d_tone"
## (RD) Niveaux de la variation codée (panel_core.gdshaderinc : TONE_LEVELS, TONE_BRIGHT,
## TONE_HUE_LEVELS, TONE_HUE).
const TONE_LEVELS := 25
const TONE_BRIGHT := 0.06
const TONE_HUE_LEVELS := 13
const TONE_HUE := 0.03
## (H9) Pas de la phase des bandes animées (une phase sur PHASE_STEPS) : peu de meshes différents.
const PHASE_STEPS := 32
## (H9) Hauteur du centre de l'effacement du premier plan au-dessus des pieds du joueur (m).
const FOREGROUND_HEIGHT := 0.8
## (H9) Groupe du joueur (PLAN.md section 3, conventions).
const PLAYER_GROUP := &"player"
## (I1) Orientations d'un meuble : où regarde sa face.
const FACING_SOUTH := &"south"
const FACING_EAST := &"east"
const FACING_WEST := &"west"
const FACING_NORTH := &"north"
const FACINGS: Array[StringName] = [FACING_SOUTH, FACING_EAST, FACING_WEST, FACING_NORTH]
## (I1) Vues et suffixes de leur image : de flanc, de dos, par le pied (lit).
const VIEW_FRONT := &"front"
const VIEW_SIDE := &"side"
const VIEW_BACK := &"back"
const VIEW_FOOT := &"foot"

## Matériaux partagés : clé (image, teinte, lueur) → WeakRef du ShaderMaterial. (E1) Références
## faibles : un matériau vit tant qu'un décor s'en sert, puis il part avec son image ; une carte
## quittée libère ainsi ses images (un cache fort les gardait toutes, de toutes les cartes
## visitées). Clé de l'image : son chemin (stable d'un chargement à l'autre), son RID sans chemin.
static var _materials: Dictionary = {}
## Meshes partagés : clé (taille) → QuadMesh ; (H9) clé (taille, retournement, phase, décalage)
## → ArrayMesh.
static var _quads: Dictionary = {}
static var _panel_meshes: Dictionary = {}
## (H9) Matériaux de premier plan ((E1) WeakRef), et image où leur centre a été posé pour la
## dernière fois.
static var _foreground_materials: Array[WeakRef] = []
static var _foreground_frame: int = -1
## Panneaux de premier plan dans l'arbre : seul le premier a un _process (un appel par image au
## lieu d'un par panneau, plusieurs centaines dans l'île posée) ; s'il quitte l'arbre, le
## suivant prend le relais.
static var _foreground_panels: Array[Node] = []
## (I1) Chemin de la vue d'une image : clé « chemin|vue » → chemin de l'image de la vue, ou ""
## quand elle n'existe pas (des chaînes seulement : les textures restent à ResourceLoader).
static var _view_paths: Dictionary = {}
static var _shadow_material: ShaderMaterial
## (RD) Meshes d'ombre : clé (tailles, forme, opacités) → WeakRef de l'ArrayMesh.
static var _shadow_meshes: Dictionary = {}

## Image du panneau (PNG à fond transparent, collée au bord bas).
@export var texture: Texture2D:
	set(value):
		texture = value
		_queue_rebuild()
## Densité de l'image (px par mètre) : 96 dans le monde, moins pour le décor lointain.
@export var pixels_per_meter: float = PIXELS_PER_METER:
	set(value):
		pixels_per_meter = maxf(value, 1.0)
		_queue_rebuild()
## Largeur de l'ombre au sol, en fraction de la largeur de l'image (0 : pas d'ombre).
@export_range(0.0, 2.0) var shadow_width: float = 0.8:
	set(value):
		shadow_width = value
		_queue_rebuild()
## Profondeur de l'ombre en fraction de sa largeur.
@export_range(0.05, 2.0) var shadow_depth: float = 0.4:
	set(value):
		shadow_depth = value
		_queue_rebuild()
## Le panneau garde l'orientation du nœud au lieu de se tourner vers le sud (rare : un panneau
## posé de profil).
@export var keep_orientation: bool = false:
	set(value):
		keep_orientation = value
		_queue_rebuild()
## (I1) Où regarde la face du meuble : south, east, west ou north ; vide : d'après la rotation du
## nœud (sa face est son +Z : tourné d'un quart de tour vers l'est, il regarde l'est). Choisit la
## vue (<nom>_side, <nom>_back, <nom>_foot) quand son image existe, sans quoi la face reste.
@export var facing: StringName = &"":
	set(value):
		facing = value
		_queue_rebuild()
## Décalage de l'image par rapport à l'ancre (m, repère du monde ; l'ombre reste à l'ancre) : un
## belvédère dont l'image est posée au fond de sa plateforme, pour qu'on se tienne devant.
@export var image_offset: Vector3 = Vector3.ZERO:
	set(value):
		image_offset = value
		_queue_rebuild()
## Teinte multipliée (variante de couleur sans nouvelle image).
@export var tint: Color = Color.WHITE:
	set(value):
		tint = value
		_queue_rebuild()
## Lueur propre des pixels couleur cristal (lanternes, fenêtres), 0 : aucune.
@export_range(0.0, 4.0) var glow: float = 0.0:
	set(value):
		glow = value
		_queue_rebuild()
## (H9) Bande animée : nombre d'images côte à côte dans texture (1 : image fixe).
@export_range(1, 64) var frames: int = 1:
	set(value):
		frames = maxi(value, 1)
		_queue_rebuild()
## (H9) Cadence de la bande (images par seconde) ; 0 : chaque exemplaire garde l'image de sa phase.
@export_range(0.0, 60.0) var fps: float = 0.0:
	set(value):
		fps = maxf(value, 0.0)
		_queue_rebuild()
## (H9) Image retournée gauche-droite.
@export var flip_h: bool = false:
	set(value):
		flip_h = value
		_queue_rebuild()
## (H9) Décalage vers la caméra (m) : un panneau posé contre un mur ou sur un pan de toit passe
## devant lui (0,05 à 0,1 suffisent).
@export_range(0.0, 1.0) var depth_offset: float = 0.0:
	set(value):
		depth_offset = maxf(value, 0.0)
		_queue_rebuild()
## (H9) Premier plan : s'efface en trame autour du joueur quand il passe devant lui.
@export var foreground: bool = false:
	set(value):
		foreground = value
		_queue_rebuild()
## (RD) Variation de l'exemplaire : luminosité (x) et teinte (y, part du tour), de −0,06 à 0,06
## et de −0,03 à 0,03 ; posée par PropScatter, portée par le mesh fondu (TONE_META).
@export var tone: Vector2 = Vector2.ZERO:
	set(value):
		tone = value
		_queue_rebuild()
## (RD) Genre du décor (DecorGenre) ; vide : d'après la catégorie de la scène ou le nom de l'image.
@export var genre: StringName = &"":
	set(value):
		genre = value
		_queue_rebuild()
## Alpha doux : la transparence de l'image est mélangée (dégradés de la fumée, de la brume, des
## nuages, des rais de lumière) au lieu d'être découpée à 0,5 (panel_soft.gdshader). Sans effet
## sur un panneau de premier plan, qui garde sa trame.
@export var soft_alpha: bool = false:
	set(value):
		soft_alpha = value
		_queue_rebuild()

var _quad: MeshInstance3D
var _shadow: MeshInstance3D
var _queued: bool = false
## (I1) Vue affichée (texture, retournement, nom), choisie par resolve_view().
var _view_texture: Texture2D
var _view_flip: bool = false
var _view_name: StringName = VIEW_FRONT


func _ready() -> void:
	rebuild()


## Taille du panneau dans le monde (m) : celle de l'image à pixels_per_meter ; (H9) d'une seule
## image pour une bande animée.
func size_m() -> Vector2:
	if texture == null:
		return Vector2.ZERO
	var shown := displayed_texture()
	var image := Vector2(shown.get_size()) / Vector2(frames, 1.0)
	return image / pixels_per_meter


## (I1) Image réellement dessinée : celle de la vue choisie par l'orientation (la face sans vue).
func displayed_texture() -> Texture2D:
	resolve_view()
	return _view_texture if _view_texture != null else texture


## (I1) Vue affichée : VIEW_FRONT, VIEW_SIDE, VIEW_BACK ou VIEW_FOOT.
func view_name() -> StringName:
	resolve_view()
	return _view_name


## (I1) La vue est-elle retournée gauche-droite (flanc d'un meuble qui regarde l'ouest) ?
func view_flipped() -> bool:
	resolve_view()
	return _view_flip


## (I1) Orientation effective : facing s'il est posé, sinon celle du nœud (sa face est son +Z).
func current_facing() -> StringName:
	if facing != &"":
		return facing
	return facing_of(global_basis.z if is_inside_tree() else basis.z)


## (I1) Orientation d'une face qui regarde dans la direction front (repère du monde) : le quart de
## tour le plus proche, south pour une direction verticale.
static func facing_of(front: Vector3) -> StringName:
	var flat := Vector2(front.x, front.z)
	if flat.length_squared() < 0.0001:
		return FACING_SOUTH
	if absf(flat.y) >= absf(flat.x):
		return FACING_SOUTH if flat.y >= 0.0 else FACING_NORTH
	return FACING_EAST if flat.x > 0.0 else FACING_WEST


## (I1) Image de la vue view (VIEW_SIDE, VIEW_BACK, VIEW_FOOT) d'une image de face, posée à côté
## d'elle sous le nom <nom>_<vue>.png ; null quand elle n'existe pas.
static func view_texture(base: Texture2D, view: StringName) -> Texture2D:
	if base == null or base.resource_path.is_empty():
		return null
	var key := "%s|%s" % [base.resource_path, view]
	if not _view_paths.has(key):
		var path := (
			"%s_%s.%s"
			% [base.resource_path.get_basename(), view, base.resource_path.get_extension()]
		)
		_view_paths[key] = path if ResourceLoader.exists(path) else ""
	var found: String = _view_paths[key]
	return load(found) as Texture2D if not found.is_empty() else null


## (I1) Choisit la vue d'après l'orientation : l'est prend le flanc, l'ouest le flanc retourné, le
## nord le dos (ou le pied d'un lit), le sud la face ; une vue absente laisse la face. Rien n'est
## changé pour une bande animée ni pour un panneau qui garde l'orientation de son nœud.
func resolve_view() -> void:
	_view_texture = texture
	_view_flip = false
	_view_name = VIEW_FRONT
	if texture == null or frames > 1 or keep_orientation:
		return
	var wanted: Array[StringName] = []
	match current_facing():
		FACING_EAST:
			wanted = [VIEW_SIDE]
		FACING_WEST:
			wanted = [VIEW_SIDE]
			_view_flip = true
		FACING_NORTH:
			wanted = [VIEW_BACK, VIEW_FOOT]
	for view in wanted:
		var found := view_texture(texture, view)
		if found != null:
			_view_texture = found
			_view_name = view
			return
	_view_flip = false


## (H9) Phase de la bande animée de ce panneau (0..1, par pas de 1 / PHASE_STEPS), tirée de sa
## position : stable d'un lancement à l'autre, différente d'un panneau à son voisin.
func strip_phase() -> float:
	return phase_at(global_position if is_inside_tree() else position)


## (H9) Phase tirée d'une position (m, au centimètre près).
static func phase_at(at: Vector3) -> float:
	var key := Vector3i((at * 100.0).round())
	return float(posmod(hash(key), PHASE_STEPS)) / PHASE_STEPS


## Recrée le panneau et son ombre à partir des données.
func rebuild() -> void:
	_queued = false
	if _quad == null:
		_quad = _internal_mesh(&"Quad")
		_shadow = _internal_mesh(&"Shadow")
	var size := size_m()
	_quad.visible = texture != null
	_shadow.visible = texture != null and shadow_width > 0.0
	_set_foreground_active(foreground and texture != null and not Engine.is_editor_hint())
	if texture == null:
		return
	var phase := strip_phase() if frames > 1 else 0.0
	var kind := current_genre()
	_quad.mesh = panel_mesh(size, flip_h != view_flipped(), phase, depth_offset)
	_quad.material_override = material_for(
		displayed_texture(),
		tint,
		glow,
		frames,
		fps,
		foreground,
		soft_alpha,
		GLOW_COLOR,
		GLOW_TOLERANCE,
		wind_pixels(kind, size.y * pixels_per_meter),
		float(DecorGenre.settings(kind)["wind_from"])
	)
	if tone.is_zero_approx():
		_quad.remove_meta(TONE_META)
	else:
		_quad.set_meta(TONE_META, tone_code(tone))
	_shadow.material_override = shadow_material()
	if not is_inside_tree():
		_shadow.mesh = null
		return
	var scale_world := global_basis.get_scale()
	_quad.global_basis = global_basis if keep_orientation else Basis.from_scale(scale_world)
	_quad.global_position = global_position + image_offset * scale_world
	_shadow.mesh = shadow_mesh_for(size * Vector2(scale_world.x, scale_world.y), kind)
	_shadow.visible = _shadow.mesh != null
	_shadow.global_transform = Transform3D(
		Basis.IDENTITY, global_position + Vector3.UP * SHADOW_LIFT
	)


## (RD) Genre du décor : genre s'il est posé, sinon celui de sa catégorie de scène
## (metadata/hd2d_category) ou du nom de son image (DecorGenre.of).
func current_genre() -> StringName:
	if genre != &"":
		return genre
	var category := StringName(str(get_meta(&"hd2d_category", "")))
	return DecorGenre.of(texture.resource_path if texture != null else "", category)


## (RD) Déplacement du haut de l'image au vent (px de l'image) pour un genre et une image de
## height_px px de haut : 0 si le genre ne bouge pas.
static func wind_pixels(kind: StringName, height_px: float) -> float:
	if not DecorGenre.is_windy(kind):
		return 0.0
	var settings := DecorGenre.settings(kind)
	return minf(float(settings["wind"]) * height_px, float(settings["wind_max"]))


## (RD) Code d'une variation (luminosité, teinte) pour la partie entière de UV2.x
## (panel_core.gdshaderinc, panel_tone) : 0 sans variation.
static func tone_code(value: Vector2) -> int:
	if value.is_zero_approx():
		return 0
	var bright := roundi((clampf(value.x / TONE_BRIGHT, -1.0, 1.0) * 0.5 + 0.5) * (TONE_LEVELS - 1))
	var hue := roundi((clampf(value.y / TONE_HUE, -1.0, 1.0) * 0.5 + 0.5) * (TONE_HUE_LEVELS - 1))
	return 1 + bright + hue * TONE_LEVELS


## (RD) Variation décodée d'un code (tone_code ; jumeau de panel_tone du shader).
static func tone_from_code(code: int) -> Vector2:
	if code <= 0:
		return Vector2.ZERO
	var c := code - 1
	var bright := float(c % TONE_LEVELS) / (TONE_LEVELS - 1) * 2.0 - 1.0
	var hue := float(floori(float(c) / TONE_LEVELS)) / (TONE_HUE_LEVELS - 1) * 2.0 - 1.0
	return Vector2(bright * TONE_BRIGHT, hue * TONE_HUE)


## (RD) Mesh de l'ombre d'un panneau de taille size (m, échelle comprise) d'un genre : un cœur
## au pied (shadow_width × shadow_depth de la largeur ; bande pour un décor long) et une traîne
## d'une part de la hauteur (DecorGenre), vers l'est (le shader la tourne vers l'opposé du
## soleil) ; null sans ombre.
func shadow_mesh_for(size: Vector2, kind: StringName) -> ArrayMesh:
	if shadow_width <= 0.0 or size.x <= 0.0:
		return null
	var settings := DecorGenre.settings(kind)
	var width := size.x * shadow_width
	var tail := minf(size.y * float(settings["tail"]), SHADOW_TAIL_MAX)
	return shadow_shape(
		width,
		width * shadow_depth,
		tail,
		width * float(settings["tail_width"]),
		bool(settings["long"]),
		Vector2(float(settings["core_alpha"]), float(settings["tail_alpha"]))
	)


## (RD) Mesh d'ombre partagé : cœur de width × depth m (bande de SHADOW_STRIP_DEPTH m de profondeur
## pour un décor long, dont la traîne est un parallélogramme de toute sa largeur) et traîne de
## tail m de long et tail_width m de large ; alphas : opacités du cœur (x) et de la traîne (y).
## Les sommets de la traîne portent dans UV2 leur écart à l'ancre (le long de la traîne, en
## travers), et sont posés pour une traîne vers l'est.
static func shadow_shape(
	width: float, depth: float, tail: float, tail_width: float, long: bool, alphas: Vector2
) -> ArrayMesh:
	var key := (
		"%.2f|%.2f|%.2f|%.2f|%d|%.2f|%.2f"
		% [width, depth, tail, tail_width, int(long), alphas.x, alphas.y]
	)
	var cached := _shadow_meshes.get(key) as WeakRef
	if cached != null and cached.get_ref() != null:
		return cached.get_ref() as ArrayMesh
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var uv2s := PackedVector2Array()
	var half := width / 2.0
	var core_level := roundi(clampf(alphas.x, 0.0, 1.0) * 20.0)
	var tail_level := roundi(clampf(alphas.y, 0.0, 1.0) * 20.0)
	var none: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
	if long:
		# Bande : du devant (sud, v = 0) à un tiers derrière le pied (nord, v = 1).
		var front := SHADOW_STRIP_DEPTH
		var back := -SHADOW_STRIP_DEPTH / 3.0
		var strip: Array[Vector3] = [
			Vector3(-half, 0, front),
			Vector3(half, 0, front),
			Vector3(half, 0, back),
			Vector3(-half, 0, back)
		]
		_shadow_quad(vertices, uvs, uv2s, strip, SHADOW_STRIP, core_level, none)
	else:
		var d := depth / 2.0
		var oval: Array[Vector3] = [
			Vector3(-half, 0, d), Vector3(half, 0, d), Vector3(half, 0, -d), Vector3(-half, 0, -d)
		]
		_shadow_quad(vertices, uvs, uv2s, oval, SHADOW_CORE, core_level, none)
	if tail > 0.05 and tail_level > 0:
		var w := half if long else tail_width / 2.0
		var offsets: Array[Vector2] = [
			Vector2(0.0, -w), Vector2(tail, -w), Vector2(tail, w), Vector2(0.0, w)
		]
		var corners: Array[Vector3] = []
		for o in offsets:
			# Décor long : l'écart en travers reste le long de x (sa largeur) ; sinon il tourne
			# avec la traîne (le sud quand elle va vers l'est).
			corners.append(Vector3(o.x + o.y, 0.0, 0.0) if long else Vector3(o.x, 0.0, o.y))
		_shadow_quad(
			vertices,
			uvs,
			uv2s,
			corners,
			SHADOW_TAIL_LONG if long else SHADOW_TAIL,
			tail_level,
			offsets
		)
	var normals := PackedVector3Array()
	normals.resize(vertices.size())
	normals.fill(Vector3.UP)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_TEX_UV2] = uv2s
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_shadow_meshes[key] = weakref(mesh)
	return mesh


## (RD) Ajoute un quadrilatère d'ombre (coins dans l'ordre des UV (0,0), (1,0), (1,1), (0,1)) de
## la forme shape et de l'opacité level (sur 20), avec les écarts à l'ancre de ses coins (UV2).
static func _shadow_quad(
	vertices: PackedVector3Array,
	uvs: PackedVector2Array,
	uv2s: PackedVector2Array,
	corners: Array[Vector3],
	shape: int,
	level: int,
	offsets: Array[Vector2]
) -> void:
	var corner_uvs: Array[Vector2] = [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
	for k: int in [0, 1, 2, 0, 2, 3]:
		vertices.append(corners[k])
		uvs.append(corner_uvs[k] + Vector2(2.0 * shape, 2.0 * level))
		uv2s.append(offsets[k])


## Mesh du panneau de taille size (m), ancre au milieu du bord bas, face vers +Z.
static func quad_mesh(size: Vector2) -> QuadMesh:
	var key := "%.4f|%.4f" % [size.x, size.y]
	if not _quads.has(key):
		var mesh := QuadMesh.new()
		mesh.size = size
		mesh.center_offset = Vector3(0.0, size.y / 2.0, 0.0)
		_quads[key] = mesh
	return _quads[key]


## (H9) Mesh d'un panneau de taille size (m), ancre au milieu du bord bas, face vers +Z, image
## retournée si flip, phase de bande animée (UV2.x) et décalage vers la caméra (UV2.y, m) ;
## partagé : le QuadMesh de quad_mesh() quand rien de cela ne sert.
static func panel_mesh(
	size: Vector2, flip: bool = false, phase: float = 0.0, offset: float = 0.0
) -> Mesh:
	if not flip and phase == 0.0 and offset == 0.0:
		return quad_mesh(size)
	var key := "%.4f|%.4f|%d|%.4f|%.3f" % [size.x, size.y, int(flip), phase, offset]
	if not _panel_meshes.has(key):
		var half := size.x / 2.0
		var corners: Array[Vector3] = [
			Vector3(-half, 0.0, 0.0),
			Vector3(half, 0.0, 0.0),
			Vector3(half, size.y, 0.0),
			Vector3(-half, size.y, 0.0),
		]
		var left := 1.0 if flip else 0.0
		var corner_uvs: Array[Vector2] = [
			Vector2(left, 1.0),
			Vector2(1.0 - left, 1.0),
			Vector2(1.0 - left, 0.0),
			Vector2(left, 0.0)
		]
		var vertices := PackedVector3Array()
		var uvs := PackedVector2Array()
		for k: int in [0, 2, 1, 0, 3, 2]:
			vertices.append(corners[k])
			uvs.append(corner_uvs[k])
		var normals := PackedVector3Array()
		normals.resize(6)
		normals.fill(Vector3.BACK)
		var uv2s := PackedVector2Array()
		uv2s.resize(6)
		uv2s.fill(Vector2(phase, offset))
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_TEX_UV] = uvs
		arrays[Mesh.ARRAY_TEX_UV2] = uv2s
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		_panel_meshes[key] = mesh
	return _panel_meshes[key]


## Matériau partagé d'une image (panel.gdshader : nearest, alpha découpé, éclairage plat) ;
## (H9) bande animée de frame_count images à frame_rate images par seconde, premier plan
## (panel_foreground.gdshader) ; alpha doux (panel_soft.gdshader), sauf au premier plan.
static func material_for(
	image: Texture2D,
	color: Color = Color.WHITE,
	glow_amount: float = 0.0,
	frame_count: int = 1,
	frame_rate: float = 0.0,
	in_foreground: bool = false,
	soft: bool = false,
	glow_color: Color = GLOW_COLOR,
	glow_tolerance: float = GLOW_TOLERANCE,
	wind_px: float = 0.0,
	wind_from: float = 1.0
) -> Material:
	var blended := soft and not in_foreground
	var key := "%s|%s|%.2f" % [image_key(image), color.to_html(), glow_amount]
	if wind_px > 0.0:
		key += "|w%.2f|%.2f" % [wind_px, wind_from]
	if frame_count > 1 or in_foreground or blended:
		key += "|%d|%.3f|%d|%d" % [frame_count, frame_rate, int(in_foreground), int(blended)]
	var custom_glow := (
		not glow_color.is_equal_approx(GLOW_COLOR)
		or not is_equal_approx(glow_tolerance, GLOW_TOLERANCE)
	)
	if custom_glow:
		key += "|%s|%.3f" % [glow_color.to_html(false), glow_tolerance]
	var material := cached_material(_materials, key) as ShaderMaterial
	if material == null:
		material = ShaderMaterial.new()
		material.shader = (
			FOREGROUND_SHADER if in_foreground else (SOFT_SHADER if blended else PANEL_SHADER)
		)
		material.set_shader_parameter(&"albedo_texture", image)
		material.set_shader_parameter(&"tint", color)
		material.set_shader_parameter(&"hd2d_relief", 0.0)
		material.set_shader_parameter(&"glow_strength", glow_amount)
		if custom_glow:
			set_glow_rule(material, glow_color, glow_tolerance)
		if frame_count > 1:
			material.set_shader_parameter(&"frames", float(frame_count))
			material.set_shader_parameter(&"fps", frame_rate)
		if in_foreground:
			_foreground_materials.append(weakref(material))
		if wind_px > 0.0:
			material.set_shader_parameter(&"wind_px", wind_px)
			material.set_shader_parameter(&"wind_from", wind_from)
		if blended:
			# (RD) Mélangé, dessiné après le flou de l'écran : il se floute lui-même.
			DepthFocus.register(material)
		_materials[key] = weakref(material)
	return material


## (QO) Couleur de lueur telle que le shader la compare (panel_core.gdshaderinc) à partir d'une
## couleur de l'image : le rendu Compatibility lit l'image telle quelle, sans la convertir en
## linéaire (constaté sur les façades de l'entrepôt), et le shader élève le pixel lu à la
## puissance 1/2,2 ; on élève la couleur de la même façon pour comparer ce qui se compare.
static func glow_shader_color(image_color: Color) -> Vector4:
	return Vector4(
		pow(image_color.r, GLOW_LIFT),
		pow(image_color.g, GLOW_LIFT),
		pow(image_color.b, GLOW_LIFT),
		1.0
	)


## (QO) Pose la règle de lueur propre d'un matériau de panneau : couleur de l'image (sRGB, celle
## des carreaux) et tolérance (distance, après élévation à la puissance 1/2,2).
static func set_glow_rule(
	material: ShaderMaterial, glow_color: Color, glow_tolerance: float
) -> void:
	material.set_shader_parameter(&"glow_color", glow_shader_color(glow_color))
	material.set_shader_parameter(&"glow_tolerance", glow_tolerance)


## (QO) Jumeau sur le processeur de la lueur propre de panel_core.gdshaderinc : part (0..1) dont
## s'allume un pixel de l'image (couleur sRGB, telle que dans le fichier) sous une règle de lueur.
## Sert aux tests (les carreaux s'allument, le torchis non).
static func glow_weight(
	pixel: Color, glow_color: Color = GLOW_COLOR, glow_tolerance: float = GLOW_TOLERANCE
) -> float:
	var lifted := glow_shader_color(pixel)
	var rule := glow_shader_color(glow_color)
	var offset := Vector3(lifted.x - rule.x, lifted.y - rule.y, lifted.z - rule.z)
	return 1.0 - smoothstep(glow_tolerance * 5.0 / 12.0, glow_tolerance, offset.length())


## (E1) Clé d'une image dans les caches de matériaux : son chemin, ou son RID si elle n'en a pas
## (image faite à l'exécution).
static func image_key(image: Texture2D) -> String:
	return image.resource_path if not image.resource_path.is_empty() else str(image.get_rid())


## (E1) Matériau encore vivant d'un cache de références faibles (null sinon ; l'entrée morte est
## retirée).
static func cached_material(cache: Dictionary, key: String) -> Material:
	var ref: WeakRef = cache.get(key)
	if ref == null:
		return null
	var material := ref.get_ref() as Material
	if material == null:
		cache.erase(key)
	return material


## (H9) Pose le centre de l'effacement des panneaux de premier plan sur le corps du joueur (groupe
## « player »), une fois par image quel que soit le nombre de panneaux ; sans joueur, rien ne
## s'efface. Appelé à chaque image par le premier panneau de premier plan de l'arbre.
static func update_foreground(tree: SceneTree) -> void:
	var frame := Engine.get_process_frames()
	if frame == _foreground_frame:
		return
	_foreground_frame = frame
	var player := tree.get_first_node_in_group(PLAYER_GROUP) as Node3D
	var strength := 0.0
	var center := Vector3.ZERO
	if player != null:
		strength = 1.0
		center = displayed_transform(player).origin + Vector3.UP * FOREGROUND_HEIGHT
	for index in range(_foreground_materials.size() - 1, -1, -1):
		var material := _foreground_materials[index].get_ref() as ShaderMaterial
		if material == null:
			_foreground_materials.remove_at(index)
			continue
		material.set_shader_parameter(&"foreground_center", center)
		material.set_shader_parameter(&"foreground_strength", strength)


## (H9) Place affichée d'un nœud qui bouge à l'image physique (joueur, caméra) : lissée entre
## deux images physiques quand le lissage physique est actif, sinon sa place.
static func displayed_transform(node: Node3D) -> Transform3D:
	if node.is_physics_interpolated_and_enabled():
		return node.get_global_transform_interpolated()
	return node.global_transform


## (RD) Matériau partagé des ombres peintes (panel_shadow.gdshader : mélangé, non éclairé, sous
## les panneaux et les personnages) ; Atmosphere y pose le soleil (set_shadow_sun, par
## AtmosphereRig.apply), la caméra la mise au point (DepthFocus).
static func shadow_material() -> ShaderMaterial:
	if _shadow_material == null:
		_shadow_material = ShaderMaterial.new()
		_shadow_material.shader = SHADOW_SHADER
		_shadow_material.render_priority = -1
		DepthFocus.register(_shadow_material)
	return _shadow_material


## (RD) Pose le soleil sur les ombres peintes : direction (plan du sol x, z) où partent les ombres
## (à l'opposé du soleil), allongement de la traîne, force de la traîne et du cœur (0..1).
static func set_shadow_sun(away: Vector2, length: float, tail: float, core: float) -> void:
	var material := shadow_material()
	var direction := away.normalized() if away.length_squared() > 0.0001 else Vector2.RIGHT
	material.set_shader_parameter(&"sun_away", direction)
	material.set_shader_parameter(&"sun_length", length)
	material.set_shader_parameter(&"tail_strength", tail)
	material.set_shader_parameter(&"core_strength", core)


func _process(_delta: float) -> void:
	if foreground:
		update_foreground(get_tree())


func _internal_mesh(node_name: StringName) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance, false, Node.INTERNAL_MODE_FRONT)
	return instance


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and Engine.is_editor_hint():
		_queue_rebuild()
	elif what == NOTIFICATION_EXIT_TREE:
		_set_foreground_active(false)
	elif what == NOTIFICATION_ENTER_TREE and _quad != null:
		_set_foreground_active(foreground and texture != null and not Engine.is_editor_hint())


## Inscrit (ou retire) ce panneau parmi ceux de premier plan ; seul le premier inscrit traite
## l'image (_process), le suivant prend le relais quand il part.
func _set_foreground_active(active: bool) -> void:
	var index := _foreground_panels.find(self)
	if active and is_inside_tree():
		if index < 0:
			_foreground_panels.append(self)
	elif index >= 0:
		_foreground_panels.remove_at(index)
		if index == 0 and not _foreground_panels.is_empty():
			_foreground_panels[0].set_process(true)
	set_process(not _foreground_panels.is_empty() and _foreground_panels[0] == self)


func _queue_rebuild() -> void:
	if _queued or not is_inside_tree():
		return
	_queued = true
	rebuild.call_deferred()
