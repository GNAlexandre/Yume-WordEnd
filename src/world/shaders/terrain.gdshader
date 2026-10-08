// Sol HD-2D de l'île flottante (mesh de IslandTerrain, src/world/terrain.gd) : tuiles de pixel
// art (assets/hd2d/ground/, réunies dans ground_atlas.png par tools/hd2d_assets.py) répétées à
// 96 px par mètre et choisies par zone et par masque (chemins, cour, rue, marais, cercle de
// veille… : docs/lore/MONDE.md, section 2). Chaque pixel d'art prend UNE tuile : les bords des
// masques sont calculés au centre du pixel d'art et tramés (ordre de Bayer), comme du pixel art
// dessiné, sans mélange flou. Compatible Compatibility / WebGL 2.
// (H5) Filtrage sans moiré : de près, pixels nets dont seule la frontière est lissée sur un pixel
// d'écran ; de loin, mipmaps (atlas recalculé par terrain.gd, sans mélange entre tuiles) lues
// par textureLod au niveau tiré des dérivées continues de la position (le saut de fract() et
// d'une case de l'atlas à l'autre ne trace pas de couture), deux échantillons le long de l'axe
// étiré par la perspective (anisotrope fait main : le filtrage anisotrope du pilote, avec ces
// sauts, débordait sur les cases voisines). Tramage des masques : de près, un seuil par pixel
// d'art tiré d'un bruit (pas de grille de points comme l'ordre de Bayer) ; de loin, quand un pixel
// d'art devient plus petit qu'un pixel d'écran, plus de tramage : la moyenne de quatre seuils
// (masques lus à la position continue), soit un mélange en paliers fins, sans grain ni
// scintillement ; entre les deux, un fondu. Les fleurs d'un pixel s'effacent au loin.
// Les uniformes de forme sont recopiés de terrain.gd au lancement ; edge_distance() est la même.
shader_type spatial;
render_mode specular_disabled;

#include "res://src/world/shaders/hd2d_light.gdshaderinc"

// Ordre des tuiles dans l'atlas (GROUND_LAYERS de tools/hd2d_assets.py), 4 par rangée.
const int GRASS = 0;
const int GRASS_DRY = 1;
const int FOREST_FLOOR = 2;
const int PATH_DIRT = 3;
const int FLAGSTONE = 4;
const int COBBLE = 5;
const int SAND = 6;
const int ROCK = 7;
const int PEAT = 8;
const int WATER = 9;
const int MUD = 10;
const int METAL = 11;
const float ATLAS_COLUMNS = 4.0;
const float ATLAS_ROWS = 3.0;

uniform sampler2D ground_atlas : source_color, filter_linear_mipmap, repeat_disable;
// Taille d'une tuile (m) : 384 px à 96 px par mètre.
uniform float tile_meters = 4.0;
uniform float tile_pixels = 384.0;
// Niveau de mipmap le plus flou (les tuiles de 384 px ne se mélangent pas jusqu'au niveau 7).
uniform float max_lod = 6.0;
// Pixels d'art par mètre du tramage des bords (deux pixels d'image par pixel d'art).
uniform float art_pixels = 48.0;

uniform float edge_radius = 74.5;
uniform float bay_depth = 6.0;
uniform float west_bulge = 2.5;
uniform vec2 arena_center = vec2(-51.0, 0.0);
uniform float arena_radius = 12.0;
uniform float plaza_radius = 9.0;
uniform vec2 hill_center = vec2(52.0, -3.0);
uniform float hill_height = 8.0;
uniform float path_half_width = 1.5;

// Chemins (3 m de large) : segments (x1, z1, x2, z2) en coordonnées de l'île (MONDE.md, 2.7).
const int PATH_COUNT = 25;
const vec4 PATHS[PATH_COUNT] = {
	vec4(0.0, -9.0, 0.0, -24.0), vec4(0.0, -24.0, 1.5, -33.0), vec4(1.5, -33.0, 0.0, -37.5),
	vec4(1.0, -30.0, -8.0, -38.0), vec4(-8.0, -38.0, -15.0, -46.0),
	vec4(-15.0, -46.0, -19.0, -51.5),
	vec4(-9.0, 0.0, -24.0, 0.0), vec4(-24.0, 0.0, -31.0, 1.0), vec4(-31.0, 1.0, -37.0, 0.0),
	vec4(9.0, 0.0, 24.0, 0.0), vec4(24.0, 0.0, 31.0, -1.5), vec4(31.0, -1.5, 38.0, -10.0),
	vec4(38.0, -10.0, 42.0, 4.0), vec4(42.0, 4.0, 47.0, -8.0), vec4(47.0, -8.0, 50.5, -4.0),
	vec4(0.0, 9.0, 0.0, 24.0), vec4(0.0, 24.0, 1.5, 33.0), vec4(1.5, 33.0, 1.0, 43.5),
	vec4(1.0, 46.5, 1.5, 55.0), vec4(1.5, 55.0, 2.0, 60.0),
	vec4(-34.0, 45.0, -40.0, 37.0), vec4(-40.0, 37.0, -41.0, 26.0),
	vec4(-41.0, 26.0, -46.0, 15.0), vec4(34.0, 45.0, 40.0, 33.0), vec4(40.0, 33.0, 44.0, 19.0)
};
// Ruisseau : du pied nord de la colline au bord nord-ouest (cascade), par le marais.
const int STREAM_COUNT = 13;
const vec2 STREAM[STREAM_COUNT] = {
	vec2(40.0, -22.0), vec2(36.0, -30.0), vec2(30.0, -38.0), vec2(24.0, -46.0),
	vec2(16.0, -64.0), vec2(5.0, -70.0), vec2(-8.0, -69.0), vec2(-17.0, -64.0),
	vec2(-24.0, -60.0), vec2(-32.0, -56.0), vec2(-42.0, -57.5), vec2(-52.0, -60.0),
	vec2(-62.5, -62.5)
};

varying vec3 world_pos;

float wrap_angle(float a) {
	return mod(a + PI, TAU) - PI;
}

float edge_distance(vec2 p) {
	float x2 = p.x * p.x;
	float z2 = p.y * p.y;
	float norm = sqrt(sqrt(x2 * x2 + z2 * z2));
	float angle = atan(p.y, p.x);
	float radius = edge_radius + 1.2 * sin(3.0 * angle + 0.4) + 0.8 * sin(5.0 * angle + 2.1);
	radius += 0.4 * sin(9.0 * angle + 0.7);
	float bay = wrap_angle(angle - PI * 0.5) / 0.32;
	float bulge = wrap_angle(angle - PI) / 0.45;
	radius += -bay_depth * exp(-bay * bay) + west_bulge * exp(-bulge * bulge);
	return radius - norm;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float segment_distance(vec2 p, vec2 a, vec2 b) {
	vec2 ab = b - a;
	float t = clamp(dot(p - a, ab) / dot(ab, ab), 0.0, 1.0);
	return length(p - a - ab * t);
}

float path_distance(vec2 p) {
	float best = 1e6;
	for (int i = 0; i < PATH_COUNT; i++) {
		best = min(best, segment_distance(p, PATHS[i].xy, PATHS[i].zw));
	}
	return best;
}

float stream_distance(vec2 p) {
	float best = 1e6;
	for (int i = 0; i < STREAM_COUNT - 1; i++) {
		best = min(best, segment_distance(p, STREAM[i], STREAM[i + 1]));
	}
	return best;
}

// Seuil de tramage d'un pixel d'art (0..1) : bruit blanc entier, stable (pas de sin()).
float cell_threshold(vec2 cell) {
	uvec2 q = uvec2(ivec2(cell) + ivec2(65536));
	uint h = (q.x * 1597334677u) ^ (q.y * 3812015801u);
	h = (h ^ (h >> 16u)) * 2246822519u;
	h = h ^ (h >> 13u);
	return float(h >> 8u) / 16777216.0;
}

// Bruit du pixel d'écran (interleaved gradient noise, 0..1) : décale les seuils du mélange.
float screen_noise(vec2 pixel) {
	return fract(52.9829189 * fract(dot(pixel, vec2(0.06711056, 0.00583715))));
}

// Masques du sol en un point (0..1, sauf les drapeaux), calculés une fois par pixel ; la tuile
// et sa teinte se choisissent ensuite pour un seuil (pick_layer).
struct Masks {
	float dry;
	float forest;
	float field;
	float marsh;
	float pools;
	float bank;
	float water;
	float hill;
	float couchant;
	float drift;
	float arena;
	float arena_sand;
	float ring;
	float path;
	int path_layer;
	float yard;
	float yard_flag;
	float rim;
	float playground;
	bool garden;
	bool street;
	float market;
	bool quay;
	bool edge;
};

// Tuile choisie pour le seuil t (les masques se recouvrent dans cet ordre) ; tint : son
// assombrissement doux.
int pick_layer(Masks m, float t, out vec3 tint) {
	int layer = GRASS;
	tint = vec3(1.0);
	if (m.dry > t) { layer = GRASS_DRY; }
	if (m.forest > t) { layer = FOREST_FLOOR; }
	if (m.field > t) { layer = GRASS; tint = vec3(0.95, 0.94, 0.86); }
	if (m.marsh > t) { layer = PEAT; }
	if (m.pools > t) { layer = WATER; }
	if (m.bank > t) { layer = MUD; }
	if (m.water > t) { layer = WATER; }
	if (m.hill > t) { layer = GRASS_DRY; }
	if (m.couchant > t) { layer = m.drift > t ? SAND : ROCK; }
	if (m.arena > t) { layer = m.arena_sand > t ? SAND : FLAGSTONE; }
	if (m.ring > t) { layer = ROCK; tint = vec3(0.62, 0.6, 0.66); }
	if (m.path > t) { layer = m.path_layer; }
	if (m.yard > t) { layer = m.yard_flag > t ? FLAGSTONE : PATH_DIRT; }
	if (m.rim > t) { layer = ROCK; tint = vec3(0.7, 0.68, 0.72); }
	if (m.playground > t) { layer = MUD; }
	if (m.garden) { layer = MUD; tint = vec3(0.8, 0.74, 0.7); }
	if (m.street) { layer = COBBLE; }
	if (m.market > t) { layer = FLAGSTONE; }
	if (m.quay) { layer = METAL; }
	if (m.edge) { layer = ROCK; tint = vec3(0.92); }
	return layer;
}

// Masques du sol au point p (m, plan du sol), à la hauteur h.
Masks ground_masks(vec2 p, float h) {
	Masks m;
	float n1 = noise(p * 0.11);
	float n2 = noise(p * 0.47 + vec2(7.3, 1.1));
	float n3 = noise(p * 1.7 + vec2(2.4, 9.3));
	// Herbe sèche par grandes taches.
	m.dry = smoothstep(0.55, 0.85, n1) * 0.7;
	// Les bois du marais : sous-bois et feuilles mortes.
	m.forest = 1.0 - smoothstep(-33.0, -25.0, p.y + 3.0 * (n2 - 0.5));
	// Terrain d'entraînement : herbe rase piétinée.
	m.field = 1.0 - smoothstep(13.5, 15.5, distance(p, vec2(0.0, -51.0)) + 1.5 * n1);
	// Le marais : tourbe et mares d'eau sombre au ras du sol.
	vec2 marsh_p = (p - vec2(-32.0, -56.0)) / vec2(10.0, 8.0);
	m.marsh = 1.0 - smoothstep(0.8, 1.15, length(marsh_p) + 0.3 * (n1 - 0.5));
	m.pools = smoothstep(0.58, 0.68, noise(p * 0.3 + vec2(3.1, 8.7))) * smoothstep(0.3, 0.7, m.marsh);
	// Le ruisseau et ses berges.
	float stream = stream_distance(p) + 0.25 * (n2 - 0.5);
	m.bank = 1.0 - smoothstep(1.15, 1.6, stream);
	m.water = 1.0 - smoothstep(0.75, 0.95, stream);
	// La colline des étoiles : herbe haute dorée.
	m.hill = (1.0 - smoothstep(19.0, 23.0, distance(p, hill_center) + 2.0 * n1)) * 0.9;
	// Le bord du Couchant : pierre claire à nu, sable sur les dunes.
	vec2 q = (p - arena_center) / vec2(1.0, 1.2);
	float lobe = atan(q.y, q.x);
	float shape = length(q) + 2.5 * sin(lobe * 3.0 + 0.7) + 1.5 * sin(lobe * 5.0 + 2.0);
	m.couchant = 1.0 - smoothstep(25.0, 28.5, shape);
	m.drift = max(smoothstep(0.25, 0.9, h), smoothstep(0.45, 0.7, n1 + 0.2 * n2));
	// Le cercle de veille : vieilles dalles à demi ensablées, anneau de pierres sombres à 12 m.
	float arena = distance(p, arena_center);
	m.arena = 1.0 - smoothstep(arena_radius - 0.6, arena_radius - 0.3, arena);
	m.arena_sand = smoothstep(0.5, 0.8, noise(p * 0.35 + vec2(2.0, 5.0)));
	float ring_angle = atan(p.y - arena_center.y, p.x - arena_center.x) * 18.0 / PI;
	float ring_stone = smoothstep(0.08, 0.16, abs(fract(ring_angle) - 0.5));
	m.ring = (1.0 - smoothstep(0.28, 0.38, abs(arena - arena_radius))) * ring_stone;
	// Chemins de terre battue ; dans les bois, vieilles dalles envahies de sous-bois.
	float path = 1.0 - smoothstep(path_half_width - 0.25, path_half_width + 0.25, path_distance(p) + 0.3 * (n3 - 0.5));
	m.path = path * (1.0 - 0.75 * m.couchant);
	m.path_layer = m.forest > 0.5 ? (n2 > 0.62 ? FOREST_FLOOR : FLAGSTONE) : PATH_DIRT;
	// La cour de l'entrepôt : terre battue et vieilles dalles, bordure de pierres.
	float yard = length(p);
	m.yard = 1.0 - smoothstep(plaza_radius - 0.3, plaza_radius + 0.1, yard + 0.4 * (n3 - 0.5));
	m.yard_flag = smoothstep(0.42, 0.6, noise(p * 0.3 + vec2(9.0, 4.0)));
	m.rim = 1.0 - smoothstep(0.2, 0.34, abs(yard - plaza_radius + 0.3));
	// L'aire de jeux boueuse et le potager.
	m.playground = 1.0 - smoothstep(3.0, 3.8, distance(p, vec2(-12.0, 11.0)) + 0.8 * n2);
	vec2 garden = abs(p - vec2(13.0, -4.0)) - vec2(2.6, 1.6);
	m.garden = max(garden.x, garden.y) < 0.0;
	// La rue du Port : pavés ; la place du marché : dalles.
	vec2 street = abs(p - vec2(0.0, 45.0)) - vec2(34.0, 2.0);
	m.street = max(street.x, street.y) < 0.0;
	m.market = 1.0 - smoothstep(6.0, 6.6, distance(p, vec2(-23.0, 50.0)) + 0.6 * n2);
	// Le quai : bord de l'île plaqué de tôle rivetée.
	m.quay = (1.0 - step(32.5, abs(p.x))) * step(58.9, p.y + 0.4 * sin(p.x * 0.31)) > 0.5;
	// La lèvre de pierre, nette et ébréchée, sur le dernier mètre avant le vide.
	m.edge = edge_distance(p) - 0.45 * n2 < 0.9 && !m.quay;
	return m;
}

// Un échantillon de la tuile de l'atlas qui commence à cell_origin, au pixel d'image texel
// (replié sur la tuile), dans la mipmap lod. Marge au bord de la case d'un peu plus d'un
// demi-pixel du niveau supérieur (le filtre trilinéaire le lit aussi) : le filtre ne déborde
// jamais sur la tuile voisine de l'atlas.
vec3 ground_tap(vec2 texel, vec2 cell_origin, float lod) {
	float margin = 0.75 * exp2(ceil(lod));
	vec2 wrapped = clamp(mod(texel, tile_pixels), vec2(margin), vec2(tile_pixels - margin));
	vec2 uv = (cell_origin + wrapped / tile_pixels) / vec2(ATLAS_COLUMNS, ATLAS_ROWS);
	return textureLod(ground_atlas, uv, lod).rgb;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

// Couleur de la tuile layer au pixel d'image texel : de près, pixel net à la frontière lissée ;
// de loin, deux échantillons le long de l'axe étiré, dans la mipmap de la moitié de l'empreinte.
vec3 ground_color(int layer, vec2 texel, vec2 texel_dx, vec2 texel_dy) {
	vec2 cell_origin = vec2(mod(float(layer), ATLAS_COLUMNS), floor(float(layer) / ATLAS_COLUMNS));
	float along_x = length(texel_dx);
	float along_y = length(texel_dy);
	float major = max(along_x, along_y);
	float minor = min(along_x, along_y);
	if (major <= 1.0) {
		vec2 width = clamp(abs(texel_dx) + abs(texel_dy), vec2(0.001), vec2(1.0));
		vec2 sharp = floor(texel) + 0.5 + clamp((fract(texel) - 0.5) / width, -0.5, 0.5);
		return ground_tap(sharp, cell_origin, 0.0);
	}
	float lod = min(log2(max(max(minor, major * 0.5), 1.0)), max_lod);
	vec2 half_step = (along_x > along_y ? texel_dx : texel_dy) * 0.25;
	return 0.5
			* (ground_tap(texel - half_step, cell_origin, lod)
					+ ground_tap(texel + half_step, cell_origin, lod));
}

void fragment() {
	// Empreinte d'un pixel d'écran sur le sol (m), calculée avant tout branchement.
	vec2 ground_dx = dFdx(world_pos.xz);
	vec2 ground_dy = dFdy(world_pos.xz);
	// Pixels d'art par pixel d'écran, sur l'axe le plus étiré.
	float art_per_pixel = max(length(ground_dx), length(ground_dy)) * art_pixels;
	vec2 cell = floor(world_pos.xz * art_pixels);
	float h = world_pos.y;
	// Tuile répétée tous les tile_meters ; empreinte du pixel d'écran en pixels d'image, d'après
	// les dérivées continues de la position (pas celles de fract()).
	vec2 texel = fract(world_pos.xz / tile_meters) * tile_pixels;
	vec2 texel_dx = ground_dx / tile_meters * tile_pixels;
	vec2 texel_dy = ground_dy / tile_meters * tile_pixels;
	// Part du mélange lointain : 0 tant qu'un pixel d'art couvre presque un pixel d'écran, 1 au-delà
	// de deux pixels d'art par pixel d'écran.
	float far = smoothstep(0.75, 2.0, art_per_pixel);
	// De près, masques au centre du pixel d'art (bords nets en pixels d'art) ; de loin, à la
	// position continue (bords sans escalier qui scintille).
	vec2 p = far > 0.0 ? world_pos.xz : (cell + 0.5) / art_pixels;
	Masks m = ground_masks(p, h);
	vec3 tint;
	vec3 c = vec3(0.0);
	if (far < 1.0) {
		int layer = pick_layer(m, cell_threshold(cell), tint);
		c = ground_color(layer, texel, texel_dx, texel_dy) * tint * (1.0 - far);
	}
	if (far > 0.0) {
		// Moyenne de quatre seuils décalés par le bruit du pixel d'écran : un mélange en paliers
		// fins ; une tuile déjà lue n'est pas relue.
		float jitter = screen_noise(FRAGCOORD.xy);
		vec3 blend = vec3(0.0);
		int last = -1;
		vec3 last_color = vec3(0.0);
		for (int i = 0; i < 4; i++) {
			int layer = pick_layer(m, (float(i) + jitter) * 0.25, tint);
			if (layer != last) {
				last_color = ground_color(layer, texel, texel_dx, texel_dy);
				last = layer;
			}
			blend += last_color * tint;
		}
		c += blend * 0.25 * far;
	}
	// Petites fleurs de myosotis sur la colline (pixels d'art bleus semés par touffes), tant
	// qu'un pixel d'art reste visible (sinon, des points qui clignotent).
	vec2 cell_center = (cell + 0.5) / art_pixels;
	float bloom_patch = smoothstep(0.55, 0.8, noise(cell_center * 0.2 + vec2(11.0, 2.0)));
	bool flower = hash(cell) > 0.985 - 0.04 * bloom_patch && bloom_patch > 0.2;
	if (m.hill > 0.45 && h > 0.3 && flower && art_per_pixel < 1.6) {
		c = vec3(0.5, 0.61, 0.81);
	}
	ALBEDO = c;
	ROUGHNESS = 1.0;
}
