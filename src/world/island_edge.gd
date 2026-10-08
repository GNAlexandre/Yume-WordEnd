@tool
class_name IslandEdge
extends RefCounted
## (B1) Le bord de l'île flottante n° 68 (docs/lore/MONDE.md, section 2.8) : une côte de roche
## naturelle, la même pour le sol et sa collision (IslandTerrain), la roche et la barrière
## (IslandRock) et le shader du sol (terrain.gdshader).
##
## Un rayon par angle (forme étoilée autour du centre de l'île), tiré du tracé d'origine
## (superellipse, encoche du quai, avancée du Couchant ; base_radius), qui n'avance qu'au-dehors,
## sauf dans deux anses où rien n'est posé (COVES) :
##
## - grandes avancées : caps et éperon (CAPES), replat devant la ruine du Couchant (LEDGES) ;
## - ondulations moyennes : de COAST_FLOOR à COAST_FLOOR + COAST_SWING m au-delà du tracé, menées
##   par un bruit de Fourier et une onde modulée (aucun motif ne se répète) ;
## - ébréchures de la lèvre : bruit de Fourier fin et ligne brisée (0,5 à 1 m sur 2 à 4 m) ;
## - le quai (PORT_SECTOR) garde le tracé d'origine, net et droit ; la cascade du ruisseau tombe
##   au fond d'une ravine (WATERFALL_ANGLE, au bout du lit) ;
## - jamais au-delà du carré de ±EDGE_LIMIT m (murs Walls à ±80 m).
##
## Le tout est cuit une fois dans une table de EDGE_SAMPLES rayons (table) et sa pente ; la texture
## du shader (texture) porte les mêmes nombres, interpolés de la même façon (_sample) : une seule
## forme (tests/unit/test_world_edge.gd le vérifie).

## Tracé d'origine du bord : rayon moyen de la superellipse (puissance 4), encoche du quai au
## sud, avancée du Couchant à l'ouest. La côte en part (base_radius) ; le quai le garde.
const EDGE_RADIUS := 74.5
const BAY_DEPTH := 6.0
const WEST_BULGE := 2.5
## Le bord ne sort jamais du carré de ±EDGE_LIMIT m (murs Walls à ±80 m, grille de ±80 m).
const EDGE_LIMIT := 79.2
## Rayons de la table du bord, sur le tour (angle atan2(z, x) de 0 à TAU, interpolation
## linéaire) ; même table dans le shader du sol (texture() : rayon, pente dR/dθ).
const EDGE_SAMPLES := 2048
## Le port : secteur (degrés, angle atan2(z, x)) où le bord reste le tracé d'origine (le quai
## est un ouvrage, net et droit, x de −33 à 33), passage (degrés) à la côte naturelle de part et
## d'autre.
const PORT_SECTOR := Vector2(63.5, 116.5)
const PORT_RAMP := 6.0
## La cascade : angle du point du bord où arrive le lit du ruisseau (terrain.gdshader,
## STREAM ; ce point ne bouge pas) et demi-largeur (radians) de la ravine, entre deux caps.
const WATERFALL_ANGLE := -2.3532
const WATERFALL_GULLY := 0.03
## Demi-largeur (radians) de la lèvre lisse où tombe la cascade (pas d'ébréchure sous l'eau).
const WATERFALL_LIP := 0.012
## Côte naturelle, en mètres au-delà du tracé d'origine : fond des creux (COAST_FLOOR) et
## ampleur des ondulations moyennes (COAST_SWING), qu'un bruit de Fourier (COAST_BANDS : k de 4 à
## 45) et une onde modulée (COAST_WAVE) font passer de l'un à l'autre en 6 à 14 m de côte, sans
## jamais se répéter ; petites ébréchures de 0,5 à 1 m sur 2 à 4 m (dernière bande, k de 46 à
## 150). Bandes : (k min, k max, écart type en m, graine) ; poids des deux premières dans
## l'ondulation : COAST_WEIGHTS (bande large, bande moyenne, onde modulée).
const COAST_FLOOR := 0.6
const COAST_SWING := 2.2
const COAST_BANDS: Array[Vector4] = [
	Vector4(4.0, 12.0, 1.0, 11.0),
	Vector4(13.0, 45.0, 1.0, 23.0),
	Vector4(46.0, 150.0, 0.18, 37.0),
]
## Ébréchures anguleuses de la lèvre : ligne brisée, un sommet tous les CHIP_SPACING m de bord
## (tirés entre x et y), écart tiré dans ±CHIP_DEPTH m.
const CHIP_SPACING := Vector2(1.5, 3.5)
const CHIP_DEPTH := 0.45
const COAST_WEIGHTS := Vector3(0.5, 0.7, 1.5)
## Onde modulée : nombre d'ondes au tour, puis (ampleur, fréquence, phase) de trois modulations
## de phase (le pas de l'onde varie de 22 à 46 ondes au tour).
const COAST_WAVE := 34.0
const COAST_WAVE_MODULATIONS: Array[Vector3] = [
	Vector3(2.0, 2.0, 0.4),
	Vector3(0.7, 7.0, 1.9),
	Vector3(0.25, 13.0, 0.7),
]
## Caps et éperon : (angle en degrés, demi-largeur en degrés, avancée en m, raideur du
## profil, 2 : arrondi, 1,5 : pointu).
const CAPES: Array[Vector4] = [
	Vector4(-52.0, 3.0, 8.0, 1.5),  # éperon nord-est, vers le nord-nord-est
	Vector4(-30.0, 3.0, 2.5, 2.0),  # cap de la côte est, sous l'éperon
	Vector4(-124.0, 3.0, 4.0, 2.0),  # cap à l'est de la cascade
	Vector4(-148.0, 4.0, 4.5, 2.0),  # cap à l'ouest de la cascade
	Vector4(126.0, 2.5, 3.0, 2.0),  # cap au sortir du port, à l'ouest
	Vector4(140.0, 3.5, 5.0, 1.8),  # cap du sud-ouest
	Vector4(28.0, 4.0, 4.5, 2.0),  # cap du sud-est
	Vector4(55.0, 2.5, 3.0, 2.0),  # cap au sortir du port, à l'est
]
## Replats : le fond des creux remonte (angle en degrés, demi-largeur en degrés, hauteur en m),
## sans gonfler les caps contre les murs ; devant le poste de guet du Couchant, sa ruine reste à 3 m
## du vide.
const LEDGES: Array[Vector3] = [
	Vector3(180.5, 3.0, 1.6),
]
## Anses, seulement là où rien n'est posé à 6 m du tracé d'origine : (angle en degrés,
## demi-largeur en degrés, profondeur en m sous le fond des creux).
const COVES: Array[Vector3] = [
	Vector3(44.0, 6.0, 2.6),  # anse du sud-est
	Vector3(157.5, 6.0, 2.4),  # anse du sud du Couchant
]

## Table du bord, calculée une fois : rayon et pente dR/dθ (float 32 bits, comme la texture du
## shader), les mêmes sans les ébréchures (côte lissée : relief, normales lissées), écart maximal
## de la côte lissée au-delà du bord, longueurs cumulées du bord depuis l'angle 0 (EDGE_SAMPLES
## + 1 valeurs), texture du shader.
static var _radius := PackedFloat32Array()
static var _slope := PackedFloat32Array()
static var _smooth := PackedFloat32Array()
static var _smooth_slope := PackedFloat32Array()
static var _excess := 0.0
static var _arc := PackedFloat64Array()
static var _texture: ImageTexture = null


## Rayon (m, distance au centre de l'île) du bord dans la direction angle = atan2(z, x) (sud =
## +π/2, ouest = π) : table du bord interpolée, comme dans terrain.gdshader.
static func radius(angle: float) -> float:
	_ensure()
	return _sample(_radius, angle)


## Distance (m, approchée au premier ordre) du point au bord : > 0 sur l'île, < 0 dans le vide.
## Écart radial au bord divisé par la pente de la côte : la vraie distance près du bord, flancs
## des caps compris (même calcul dans terrain.gdshader). exact_distance() donne la distance
## exacte.
static func distance(x: float, z: float) -> float:
	_ensure()
	var angle := atan2(z, x)
	var rim := _sample(_radius, angle)
	var slope := _sample(_slope, angle) / rim
	return (rim - sqrt(x * x + z * z)) / sqrt(1.0 + slope * slope)


## Rayon (m) de la côte lissée, sans les petites ébréchures de la lèvre (falaise, relief).
static func smooth_radius(angle: float) -> float:
	_ensure()
	return _sample(_smooth, angle)


## Point (x, z) du bord dans la direction angle = atan2(z, x).
static func point(angle: float) -> Vector2:
	return Vector2.from_angle(angle) * radius(angle)


## Normale (unitaire, vers le vide) du bord dans la direction angle ; smooth : celle de la côte
## lissée, sans les ébréchures (barrière, cascade, falaise).
static func normal(angle: float, smooth := false) -> Vector2:
	_ensure()
	var rim := _sample(_smooth if smooth else _radius, angle)
	var slope := _sample(_smooth_slope if smooth else _slope, angle)
	var radial := Vector2.from_angle(angle)
	# orthogonal() vaut −dû/dθ : n = û − (R'/R) dû/dθ.
	return (radial + radial.orthogonal() * (slope / rim)).normalized()


## Distance exacte (m) du point au bord, au tracé de la table (> 0 sur l'île) : pour vérifier
## une marge (décor, PNJ, objet à 1 ou 3 m du vide). Plus lente que distance().
static func exact_distance(x: float, z: float) -> float:
	_ensure()
	var guess := distance(x, z)
	var angle := atan2(z, x)
	var center := roundi(fposmod(angle / TAU, 1.0) * EDGE_SAMPLES)
	var reach := (absf(guess) + 6.0) / maxf(sqrt(x * x + z * z), 20.0)
	var window := clampi(ceili(reach / TAU * EDGE_SAMPLES), 6, EDGE_SAMPLES >> 2)
	var p := Vector2(x, z)
	var best := INF
	var previous := _table_point(center - window)
	for offset in range(-window + 1, window + 1):
		var current := _table_point(center + offset)
		best = minf(
			best, Geometry2D.get_closest_point_to_segment(p, previous, current).distance_to(p)
		)
		previous = current
	return best if guess > 0.0 else -best


## Rayons de la table du bord (EDGE_SAMPLES valeurs, angle TAU · i / EDGE_SAMPLES).
static func table() -> PackedFloat32Array:
	_ensure()
	return _radius


## Texture du shader du sol : EDGE_SAMPLES × 1, deux flottants par texel (rayon, pente
## dR/dθ), lus sans filtre (texelFetch) et interpolés comme _sample().
static func texture() -> ImageTexture:
	_ensure()
	if _texture == null:
		var data := PackedFloat32Array()
		data.resize(EDGE_SAMPLES * 2)
		for i in EDGE_SAMPLES:
			data[i * 2] = _radius[i]
			data[i * 2 + 1] = _slope[i]
		var image := Image.create_from_data(
			EDGE_SAMPLES, 1, false, Image.FORMAT_RGF, data.to_byte_array()
		)
		_texture = ImageTexture.create_from_image(image)
	return _texture


## Longueur (m) du bord, en suivant la table, de l'angle −π/2 (le nord, couture des textures
## de la roche) à angle, dans le sens des angles croissants (est, sud, ouest).
static func arc(angle: float) -> float:
	_ensure()
	var north := _arc_at(-PI / 2.0)
	return fposmod(_arc_at(angle) - north, length())


## Tour complet du bord (m).
static func length() -> float:
	_ensure()
	return _arc[EDGE_SAMPLES]


## Tracé d'origine du bord (rayon en m dans la direction angle) : superellipse de puissance
## 4, un peu ondulée, encoche du quai, avancée du Couchant.
static func base_radius(angle: float) -> float:
	var c := cos(angle)
	var s := sin(angle)
	return _base_norm_radius(angle) / sqrt(sqrt(c * c * c * c + s * s * s * s))


## Tracé d'origine en norme 4 (rayon de la superellipse dans la direction angle).
static func _base_norm_radius(angle: float) -> float:
	var norm := EDGE_RADIUS
	norm += 1.2 * sin(3.0 * angle + 0.4) + 0.8 * sin(5.0 * angle + 2.1)
	norm += 0.4 * sin(9.0 * angle + 0.7)
	var bay := angle_difference(angle, PI / 2.0) / 0.32
	var bulge := angle_difference(angle, PI) / 0.45
	return norm - BAY_DEPTH * exp(-bay * bay) + WEST_BULGE * exp(-bulge * bulge)


## Distance (m, approchée) au tracé d'origine, comme le mesurait l'ancien edge_distance() :
## le relief s'efface toujours vers lui, les zones gardent leurs hauteurs.
static func base_distance(x: float, z: float) -> float:
	var x2 := x * x
	var z2 := z * z
	return _base_norm_radius(atan2(z, x)) - sqrt(sqrt(x2 * x2 + z2 * z2))


## Valeur de la values en angle (interpolation linéaire entre deux rayons voisins).
static func _sample(values: PackedFloat32Array, angle: float) -> float:
	var u := fposmod(angle / TAU, 1.0) * EDGE_SAMPLES
	var i := floori(u)
	var f := u - i
	i = posmod(i, EDGE_SAMPLES)
	return lerpf(values[i], values[(i + 1) % EDGE_SAMPLES], f)


## Point (x, z) de la table d'indice i (replié sur le tour).
static func _table_point(i: int) -> Vector2:
	var k := posmod(i, EDGE_SAMPLES)
	return Vector2.from_angle(TAU * k / EDGE_SAMPLES) * _radius[k]


## Longueur cumulée du bord depuis l'angle 0 jusqu'à angle (dans [0, TAU[).
static func _arc_at(angle: float) -> float:
	var u := fposmod(angle / TAU, 1.0) * EDGE_SAMPLES
	var i := mini(floori(u), EDGE_SAMPLES - 1)
	return lerpf(_arc[i], _arc[i + 1], u - i)


## Calcule la table du bord une fois (la forme ne dépend que des constantes).
static func _ensure() -> void:
	if not _radius.is_empty():
		return
	var bands: Array[PackedFloat64Array] = []
	for band: Vector4 in COAST_BANDS:
		bands.append(_band_coefficients(band))
	var count := EDGE_SAMPLES
	var rough_table := PackedFloat32Array()
	var smooth_table := PackedFloat32Array()
	rough_table.resize(count)
	smooth_table.resize(count)
	var knots := _chip_knots()
	var knot := 0
	for i in count:
		var angle := TAU * i / count
		while knots[knot + 2] <= angle:
			knot += 2
		var base := base_radius(angle)
		var limit := EDGE_LIMIT / maxf(absf(cos(angle)), absf(sin(angle)))
		var low := COAST_FLOOR + _angle_bumps(LEDGES, angle) - _angle_bumps(COVES, angle)
		var high := minf(low + COAST_SWING, limit - base - 0.9)
		var wave := (
			COAST_WEIGHTS.x * _fourier(bands[0], angle)
			+ COAST_WEIGHTS.y * _fourier(bands[1], angle)
			+ COAST_WEIGHTS.z * _wave(angle)
		)
		var offset := low + (high - low) * (0.5 + 0.5 * tanh(wave)) + _capes(angle)
		offset *= _gully_window(angle, WATERFALL_GULLY)
		# Les ébréchures continuent dans la ravine, sauf sur le mètre où tombe la cascade.
		var chip := lerpf(
			knots[knot + 1],
			knots[knot + 3],
			(angle - knots[knot]) / (knots[knot + 2] - knots[knot])
		)
		var chips := (_fourier(bands[2], angle) + chip) * _gully_window(angle, WATERFALL_LIP)
		var keep := _port_window(angle)
		# Jamais en deçà du tracé d'origine, sauf dans les anses (minimum adouci, retourné).
		var inner := base - _angle_bumps(COVES, angle)
		var rough := -_soft_min(-_soft_min(base + offset + chips, limit - 0.2, 0.5), -inner, 0.1)
		var smoothed := _soft_min(base + offset, limit - 0.2, 0.5)
		rough_table[i] = base + keep * (rough - base)
		smooth_table[i] = base + keep * (smoothed - base)
	_slope = _slopes(rough_table)
	_smooth_slope = _slopes(smooth_table)
	_smooth = smooth_table
	var excess := 0.0
	for i in count:
		excess = maxf(excess, smooth_table[i] - rough_table[i])
	_excess = maxf(excess - (IslandTerrain.RIM_FLAT - IslandTerrain.RIM_FLAT_SURE), 0.0)
	_arc = PackedFloat64Array()
	_arc.resize(count + 1)
	var previous := Vector2(rough_table[0], 0.0)
	for i in range(1, count + 1):
		var k := i % count
		var corner := Vector2.from_angle(TAU * k / count) * rough_table[k]
		_arc[i] = _arc[i - 1] + previous.distance_to(corner)
		previous = corner
	# En dernier : la table pleine annonce que tout est prêt.
	_radius = rough_table


## Sommets des ébréchures anguleuses : (angle, écart) à la suite, de 0 à TAU compris (le dernier
## reprend l'écart du premier).
static func _chip_knots() -> PackedFloat64Array:
	var knots := PackedFloat64Array()
	var angle := 0.0
	var k := 0
	while angle < TAU:
		knots.append_array(PackedFloat64Array([angle, CHIP_DEPTH * (2.0 * _hash(k, 41.0) - 1.0)]))
		var spacing := lerpf(CHIP_SPACING.x, CHIP_SPACING.y, _hash(43.0, k))
		angle += spacing / base_radius(angle)
		k += 1
	knots.append_array(PackedFloat64Array([TAU, knots[1]]))
	return knots


## Pente dR/dθ de la values (différences centrées).
static func _slopes(values: PackedFloat32Array) -> PackedFloat32Array:
	var count := values.size()
	var slopes := PackedFloat32Array()
	slopes.resize(count)
	var step := TAU / count
	for i in count:
		slopes[i] = (values[(i + 1) % count] - values[posmod(i - 1, count)]) / (2.0 * step)
	return slopes


## Coefficients (k, amplitude, phase) d'une bande de bruit de Fourier (k min, k max, écart type,
## graine) : spectre en 1/k, amplitudes et phases tirées de la graine, écart type ramené au voulu.
static func _band_coefficients(band: Vector4) -> PackedFloat64Array:
	var coefficients := PackedFloat64Array()
	var energy := 0.0
	for k in range(int(band.x), int(band.y) + 1):
		var amplitude := band.x / k * (0.55 + 0.9 * _hash(k, band.w))
		coefficients.append_array(PackedFloat64Array([k, amplitude, TAU * _hash(band.w, k)]))
		energy += amplitude * amplitude / 2.0
	var factor := band.z / sqrt(energy)
	for n in range(1, coefficients.size(), 3):
		coefficients[n] *= factor
	return coefficients


static func _fourier(coefficients: PackedFloat64Array, angle: float) -> float:
	var value := 0.0
	for n in range(0, coefficients.size(), 3):
		value += coefficients[n + 1] * sin(coefficients[n] * angle + coefficients[n + 2])
	return value


## Onde modulée de la côte (−1..1) : son pas varie le long du tour.
static func _wave(angle: float) -> float:
	var phase := COAST_WAVE * angle
	for modulation: Vector3 in COAST_WAVE_MODULATIONS:
		phase += modulation.x * sin(modulation.y * angle + modulation.z)
	return sin(phase)


static func _capes(angle: float) -> float:
	var total := 0.0
	for cape: Vector4 in CAPES:
		var x := absf(angle_difference(angle, deg_to_rad(cape.x))) / deg_to_rad(cape.y)
		total += cape.z * exp(-pow(x, cape.w))
	return total


## Somme de bosses en cloche (angle en degrés, demi-largeur en degrés, hauteur) en angle.
static func _angle_bumps(bumps: Array[Vector3], angle: float) -> float:
	var total := 0.0
	for bump: Vector3 in bumps:
		var x := angle_difference(angle, deg_to_rad(bump.x)) / deg_to_rad(bump.y)
		total += bump.z * exp(-x * x)
	return total


## 0 dans le secteur du port (tracé d'origine), 1 au-delà du passage.
static func _port_window(angle: float) -> float:
	var degrees := fposmod(rad_to_deg(angle), 360.0)
	if degrees >= PORT_SECTOR.x and degrees <= PORT_SECTOR.y:
		return 0.0
	var gap := minf(
		absf(angle_difference(angle, deg_to_rad(PORT_SECTOR.x))),
		absf(angle_difference(angle, deg_to_rad(PORT_SECTOR.y)))
	)
	return smoothstep(0.0, deg_to_rad(PORT_RAMP), gap)


## 0 au point de la cascade (tracé d'origine), 1 au-delà de width (radians).
static func _gully_window(angle: float, width: float) -> float:
	var x := angle_difference(angle, WATERFALL_ANGLE) / width
	return 1.0 - exp(-x * x)


## Minimum adouci de a et b (rayon k m) : jamais plus que min(a, b), sans angle vif.
static func _soft_min(a: float, b: float, k: float) -> float:
	var low := minf(a, b)
	return low - k * log(exp((low - a) / k) + exp((low - b) / k))


## Bruit stable dans [0, 1[ tiré de deux nombres.
static func _hash(a: float, b: float) -> float:
	var n := sin(a * 12.9898 + b * 78.233) * 43758.5453
	return n - floorf(n)


## Distance (m) au bord de la côte lissée, diminuée de son plus grand écart au-delà du bord
## (moins RIM_FLAT − RIM_FLAT_SURE) : jamais plus que l'écart radial au vrai bord augmenté de ce
## reste ; sert à effacer le relief vers la lèvre (plat sur RIM_FLAT_SURE m au moins).
static func _smooth_distance(x: float, z: float) -> float:
	_ensure()
	var angle := atan2(z, x)
	var rim := _sample(_smooth, angle)
	var slope := _sample(_smooth_slope, angle) / rim
	return (rim - sqrt(x * x + z * z)) / sqrt(1.0 + slope * slope) - _excess


## Distance (m) qui efface le relief vers la lèvre (IslandTerrain.land_height) : la plus petite
## de la distance au tracé d'origine (le relief s'efface comme avant ; les avancées de la côte
## sont plates) et de la distance à la côte lissée (les anses). Au vrai bord, ébréchures comprises,
## elle reste sous IslandTerrain.RIM_FLAT sur RIM_FLAT_SURE m au moins.
static func fade_distance(x: float, z: float) -> float:
	return minf(base_distance(x, z), _smooth_distance(x, z))
