// Sol HD-2D de l'île flottante (mesh de IslandTerrain, src/world/terrain.gd) : tuiles de pixel
// art (assets/hd2d/ground/, réunies dans ground_atlas.png par tools/hd2d_assets.py) répétées à
// 96 px par mètre et choisies par zone et par masque (chemins, cour, rue, marais, cercle de
// veille… : docs/lore/MONDE.md, section 2). Chaque pixel d'art prend UNE tuile : les bords des
// masques sont calculés au centre du pixel d'art et tramés (ordre de Bayer), comme du pixel art
// dessiné, sans mélange flou. Filtrage au plus proche voisin. Compatible Compatibility / WebGL 2.
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

uniform sampler2D ground_atlas : source_color, filter_nearest, repeat_disable;
// Taille d'une tuile (m) : 384 px à 96 px par mètre.
uniform float tile_meters = 4.0;
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

// Seuil de tramage ordonné 4 × 4 du pixel d'art (0..1).
float bayer(vec2 cell) {
	vec2 c = mod(cell, 4.0);
	int i = int(c.x) + int(c.y) * 4;
	int m[16] = int[16](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return (float(m[i]) + 0.5) / 16.0;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 cell = floor(world_pos.xz * art_pixels);
	vec2 p = (cell + 0.5) / art_pixels;
	float h = world_pos.y;
	float t = bayer(cell);
	float n1 = noise(p * 0.11);
	float n2 = noise(p * 0.47 + vec2(7.3, 1.1));
	float n3 = noise(p * 1.7 + vec2(2.4, 9.3));
	// Couche de base et assombrissement doux (tint) par masque.
	int layer = GRASS;
	vec3 tint = vec3(1.0);
	// Herbe sèche par grandes taches.
	if (smoothstep(0.55, 0.85, n1) * 0.7 > t) { layer = GRASS_DRY; }
	// Les bois du marais : sous-bois et feuilles mortes.
	float forest = 1.0 - smoothstep(-33.0, -25.0, p.y + 3.0 * (n2 - 0.5));
	if (forest > t) { layer = FOREST_FLOOR; }
	// Terrain d'entraînement : herbe rase piétinée.
	float field = 1.0 - smoothstep(13.5, 15.5, distance(p, vec2(0.0, -51.0)) + 1.5 * n1);
	if (field > t) { layer = GRASS; tint = vec3(0.95, 0.94, 0.86); }
	// Le marais : tourbe et mares d'eau sombre au ras du sol.
	vec2 m = (p - vec2(-32.0, -56.0)) / vec2(10.0, 8.0);
	float marsh = 1.0 - smoothstep(0.8, 1.15, length(m) + 0.3 * (n1 - 0.5));
	if (marsh > t) { layer = PEAT; }
	float pools = smoothstep(0.58, 0.68, noise(p * 0.3 + vec2(3.1, 8.7))) * smoothstep(0.3, 0.7, marsh);
	if (pools > t) { layer = WATER; }
	// Le ruisseau et ses berges.
	float stream = stream_distance(p) + 0.25 * (n2 - 0.5);
	if (1.0 - smoothstep(1.15, 1.6, stream) > t) { layer = MUD; }
	if (1.0 - smoothstep(0.75, 0.95, stream) > t) { layer = WATER; }
	// La colline des étoiles : herbe haute dorée.
	float hill = 1.0 - smoothstep(19.0, 23.0, distance(p, hill_center) + 2.0 * n1);
	if (hill * 0.9 > t) { layer = GRASS_DRY; }
	// Le bord du Couchant : pierre claire à nu, sable sur les dunes.
	vec2 q = (p - arena_center) / vec2(1.0, 1.2);
	float lobe = atan(q.y, q.x);
	float shape = length(q) + 2.5 * sin(lobe * 3.0 + 0.7) + 1.5 * sin(lobe * 5.0 + 2.0);
	float couchant = 1.0 - smoothstep(25.0, 28.5, shape);
	if (couchant > t) {
		float drift = max(smoothstep(0.25, 0.9, h), smoothstep(0.45, 0.7, n1 + 0.2 * n2));
		layer = drift > t ? SAND : ROCK;
	}
	// Le cercle de veille : vieilles dalles à demi ensablées, anneau de pierres sombres à 12 m.
	float arena = distance(p, arena_center);
	if (1.0 - smoothstep(arena_radius - 0.6, arena_radius - 0.3, arena) > t) {
		layer = smoothstep(0.5, 0.8, noise(p * 0.35 + vec2(2.0, 5.0))) > t ? SAND : FLAGSTONE;
	}
	float ring_angle = atan(p.y - arena_center.y, p.x - arena_center.x) * 18.0 / PI;
	float ring_stone = smoothstep(0.08, 0.16, abs(fract(ring_angle) - 0.5));
	float ring = (1.0 - smoothstep(0.28, 0.38, abs(arena - arena_radius))) * ring_stone;
	if (ring > t) { layer = ROCK; tint = vec3(0.62, 0.6, 0.66); }
	// Chemins de terre battue ; dans les bois, vieilles dalles envahies de sous-bois.
	float path = 1.0 - smoothstep(path_half_width - 0.25, path_half_width + 0.25, path_distance(p) + 0.3 * (n3 - 0.5));
	if (path * (1.0 - 0.75 * couchant) > t) {
		layer = forest > 0.5 ? (n2 > 0.62 ? FOREST_FLOOR : FLAGSTONE) : PATH_DIRT;
	}
	// La cour de l'entrepôt : terre battue et vieilles dalles, bordure de pierres.
	float yard = length(p);
	if (1.0 - smoothstep(plaza_radius - 0.3, plaza_radius + 0.1, yard + 0.4 * (n3 - 0.5)) > t) {
		layer = smoothstep(0.42, 0.6, noise(p * 0.3 + vec2(9.0, 4.0))) > t ? FLAGSTONE : PATH_DIRT;
	}
	if (1.0 - smoothstep(0.2, 0.34, abs(yard - plaza_radius + 0.3)) > t) {
		layer = ROCK;
		tint = vec3(0.7, 0.68, 0.72);
	}
	// L'aire de jeux boueuse et le potager.
	if (1.0 - smoothstep(3.0, 3.8, distance(p, vec2(-12.0, 11.0)) + 0.8 * n2) > t) { layer = MUD; }
	vec2 garden = abs(p - vec2(13.0, -4.0)) - vec2(2.6, 1.6);
	if (max(garden.x, garden.y) < 0.0) { layer = MUD; tint = vec3(0.8, 0.74, 0.7); }
	// La rue du Port : pavés ; la place du marché : dalles.
	vec2 street = abs(p - vec2(0.0, 45.0)) - vec2(34.0, 2.0);
	if (max(street.x, street.y) < 0.0) { layer = COBBLE; }
	if (1.0 - smoothstep(6.0, 6.6, distance(p, vec2(-23.0, 50.0)) + 0.6 * n2) > t) { layer = FLAGSTONE; }
	// Le quai : bord de l'île plaqué de tôle rivetée.
	float quay = (1.0 - step(32.5, abs(p.x))) * step(58.9, p.y + 0.4 * sin(p.x * 0.31));
	if (quay > 0.5) { layer = METAL; }
	// La lèvre de pierre, nette et ébréchée, sur le dernier mètre avant le vide.
	float edge = edge_distance(p);
	if (edge - 0.45 * n2 < 0.9 && quay < 0.5) { layer = ROCK; tint = vec3(0.92); }
	// Échantillon : la tuile répétée tous les tile_meters, au plus proche voisin.
	vec2 tile_uv = clamp(fract(world_pos.xz / tile_meters), vec2(0.5 / 384.0), vec2(1.0 - 0.5 / 384.0));
	vec2 cell_origin = vec2(mod(float(layer), ATLAS_COLUMNS), floor(float(layer) / ATLAS_COLUMNS));
	vec2 uv = (cell_origin + tile_uv) / vec2(ATLAS_COLUMNS, ATLAS_ROWS);
	vec3 c = texture(ground_atlas, uv).rgb * tint;
	// Petites fleurs de myosotis sur la colline (pixels d'art bleus semés par touffes).
	float bloom_patch = smoothstep(0.55, 0.8, noise(p * 0.2 + vec2(11.0, 2.0)));
	if (hill > 0.5 && h > 0.3 && hash(cell) > 0.985 - 0.04 * bloom_patch && bloom_patch > 0.2) {
		c = vec3(0.5, 0.61, 0.81);
	}
	ALBEDO = c;
	ROUGHNESS = 1.0;
}
