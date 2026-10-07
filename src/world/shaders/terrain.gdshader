// Couleurs du sol de l'île flottante (mesh de IslandTerrain, src/world/terrain.gd), au pixel :
// herbe d'automne, sous-bois et feuilles mortes, marais et ruisseau, terrain d'entraînement,
// cour de l'entrepôt, aire de jeux boueuse, chemins (terre battue, vieilles dalles dans les
// bois), pierre à nu et sable pâle du Couchant, cercle de veille et son anneau de pierres
// sombres, pavés de la rue du Port, place du marché, quai de tôle rivetée, herbe dorée et
// myosotis de la colline, lèvre de pierre au bord (docs/lore/MONDE.md, section 2). Palette
// naturelle un peu désaturée (herbe vert-jaune, terre ocre, roche gris-bleu), éclairage cel
// discret sans liseré (cel.gdshaderinc).
// Compatible Compatibility / WebGL 2. Les uniformes de forme sont recopiés de terrain.gd au
// lancement ; edge_distance() est la même que dans terrain.gd.
shader_type spatial;

#define CEL_NO_RIM
#include "res://src/world/shaders/cel.gdshaderinc"

uniform vec4 grass : source_color = vec4(0.47, 0.58, 0.27, 1.0);
uniform vec4 grass_dry : source_color = vec4(0.64, 0.6, 0.33, 1.0);
uniform vec4 forest_floor : source_color = vec4(0.3, 0.34, 0.2, 1.0);
uniform vec4 leaf_rust : source_color = vec4(0.55, 0.3, 0.16, 1.0);
uniform vec4 leaf_gold : source_color = vec4(0.66, 0.5, 0.22, 1.0);
uniform vec4 trampled : source_color = vec4(0.55, 0.57, 0.33, 1.0);
uniform vec4 peat : source_color = vec4(0.25, 0.25, 0.17, 1.0);
uniform vec4 marsh_water : source_color = vec4(0.22, 0.3, 0.31, 1.0);
uniform vec4 stream_water : source_color = vec4(0.4, 0.53, 0.58, 1.0);
uniform vec4 stone : source_color = vec4(0.6, 0.61, 0.6, 1.0);
uniform vec4 stone_dark : source_color = vec4(0.41, 0.43, 0.45, 1.0);
uniform vec4 sand : source_color = vec4(0.76, 0.69, 0.53, 1.0);
uniform vec4 path_dirt : source_color = vec4(0.58, 0.48, 0.33, 1.0);
uniform vec4 flagstone : source_color = vec4(0.58, 0.58, 0.56, 1.0);
uniform vec4 yard_earth : source_color = vec4(0.6, 0.5, 0.36, 1.0);
uniform vec4 mud : source_color = vec4(0.4, 0.32, 0.23, 1.0);
uniform vec4 soil : source_color = vec4(0.32, 0.24, 0.17, 1.0);
uniform vec4 cobble : source_color = vec4(0.52, 0.52, 0.51, 1.0);
uniform vec4 metal : source_color = vec4(0.42, 0.45, 0.49, 1.0);
uniform vec4 myosotis : source_color = vec4(0.44, 0.56, 0.84, 1.0);

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

// Dallage en quinconce : (distance au joint la plus proche, teinte de la dalle dans [0, 1[).
vec2 tiles(vec2 p, float size, float offset) {
	vec2 q = p / size;
	q.x += floor(q.y) * offset;
	vec2 f = fract(q);
	float joint = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y)) * size;
	return vec2(joint, hash(floor(q)));
}

// Plaques de pierre irrégulières (cellules de Voronoï) : (distance au joint, teinte de la plaque).
vec2 cells(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float d1 = 8.0;
	float d2 = 8.0;
	float tint = 0.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = vec2(hash(i + g), hash(i + g + vec2(3.7, 9.2)));
			float d = length(g + 0.1 + 0.8 * o - f);
			if (d < d1) {
				d2 = d1;
				d1 = d;
				tint = hash(i + g + vec2(1.3, 6.1));
			} else if (d < d2) {
				d2 = d;
			}
		}
	}
	return vec2((d2 - d1) * 0.5, tint);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz;
	float h = world_pos.y;
	float edge = edge_distance(p);
	float n1 = noise(p * 0.11);
	float n2 = noise(p * 0.47 + vec2(7.3, 1.1));
	// Herbe d'automne, plus sèche par grandes taches.
	vec3 c = mix(grass.rgb, grass_dry.rgb, smoothstep(0.45, 0.85, n1) * 0.55);
	c *= 0.94 + 0.12 * n2;
	// Les bois du marais : sous-bois et feuilles mortes rousses et dorées.
	float forest = 1.0 - smoothstep(-31.0, -25.0, p.y);
	vec3 litter = mix(forest_floor.rgb, leaf_rust.rgb, smoothstep(0.55, 0.8, n1) * 0.5);
	litter = mix(litter, leaf_gold.rgb, smoothstep(0.62, 0.85, n2) * 0.4);
	c = mix(c, litter, forest);
	// Terrain d'entraînement et champ de ballon : herbe rase piétinée.
	float field = distance(p, vec2(0.0, -51.0));
	c = mix(c, trampled.rgb * (0.93 + 0.1 * n2), 1.0 - smoothstep(13.5, 15.5, field + 1.5 * n1));
	// Le marais : tourbe et mares d'eau sombre au ras du sol.
	vec2 m = (p - vec2(-32.0, -56.0)) / vec2(10.0, 8.0);
	float marsh = 1.0 - smoothstep(0.8, 1.15, length(m) + 0.3 * (n1 - 0.5));
	c = mix(c, peat.rgb * (0.9 + 0.2 * n2), marsh);
	float pools = smoothstep(0.6, 0.66, noise(p * 0.3 + vec2(3.1, 8.7)));
	c = mix(c, marsh_water.rgb, pools * smoothstep(0.3, 0.7, marsh));
	// Le ruisseau, ses berges de terre ; reflets qui coulent.
	float stream = stream_distance(p) + 0.25 * (n2 - 0.5);
	float shimmer = 0.5 + 0.5 * sin(dot(p, vec2(0.7, 0.45)) * 2.2 - TIME * 2.4);
	c = mix(c, soil.rgb, 1.0 - smoothstep(1.15, 1.6, stream));
	c = mix(c, stream_water.rgb * (0.92 + 0.14 * shimmer), 1.0 - smoothstep(0.75, 0.95, stream));
	// La colline des étoiles : herbe haute dorée, semée par taches de petites fleurs de myosotis
	// (points d'une dizaine de centimètres, fondus en teinte moyenne au loin : pas de scintillement).
	float hill = 1.0 - smoothstep(19.0, 23.0, distance(p, hill_center) + 2.0 * n1);
	c = mix(c, grass_dry.rgb * (0.95 + 0.1 * n2), hill * 0.7);
	float bloom_patch = smoothstep(0.55, 0.8, noise(p * 0.2 + vec2(11.0, 2.0)));
	vec2 bloom_cell = floor(p * 3.0);
	vec2 bloom_jitter = vec2(hash(bloom_cell), hash(bloom_cell + vec2(5.2, 1.3)));
	float bloom_dist = length(fract(p * 3.0) - 0.25 - 0.5 * bloom_jitter);
	float blur = max(fwidth(p.x * 3.0), 0.001);
	float bloom = 1.0 - smoothstep(0.17 - blur, 0.17 + blur, bloom_dist);
	bloom *= step(0.4, hash(bloom_cell + vec2(9.1, 4.7)));
	bloom = mix(bloom, 0.08, clamp(blur * 2.0 - 0.5, 0.0, 1.0));
	c = mix(c, myosotis.rgb, bloom * bloom_patch * hill * smoothstep(0.3, 2.0, h));
	// Le bord du Couchant : pierre claire à nu en plaques, sable pâle sur les dunes.
	vec2 q = (p - arena_center) / vec2(1.0, 1.2);
	float lobe = atan(q.y, q.x);
	float shape = length(q) + 2.5 * sin(lobe * 3.0 + 0.7) + 1.5 * sin(lobe * 5.0 + 2.0);
	float couchant = 1.0 - smoothstep(25.0, 28.5, shape);
	if (couchant > 0.0) {
		vec2 plates = cells(p / 2.6 + vec2(0.3 * n2));
		vec3 bare = mix(stone.rgb, stone_dark.rgb, 0.15 + 0.4 * plates.y);
		bare *= 0.94 + 0.12 * n2;
		bare = mix(stone_dark.rgb * 0.8, bare, smoothstep(0.015, 0.05, plates.x));
		float drift = max(smoothstep(0.25, 0.9, h), smoothstep(0.55, 0.75, n1 + 0.2 * n2));
		c = mix(c, mix(bare, sand.rgb * (0.95 + 0.08 * n2), drift), couchant);
	}
	// Le cercle de veille : vieilles dalles à demi ensablées, anneau de pierres sombres à 12 m.
	float arena = distance(p, arena_center);
	vec2 slabs = tiles(p, 1.6, 0.5);
	vec3 floor_c = mix(flagstone.rgb, stone.rgb, slabs.y * 0.5);
	floor_c = mix(stone_dark.rgb, floor_c, smoothstep(0.03, 0.08, slabs.x));
	floor_c = mix(floor_c, sand.rgb, smoothstep(0.45, 0.8, noise(p * 0.35 + vec2(2.0, 5.0))));
	c = mix(c, floor_c, 1.0 - smoothstep(arena_radius - 0.6, arena_radius - 0.3, arena));
	float ring_angle = atan(p.y - arena_center.y, p.x - arena_center.x) * 18.0 / PI;
	float ring_stone = smoothstep(0.08, 0.16, abs(fract(ring_angle) - 0.5));
	float ring = (1.0 - smoothstep(0.28, 0.38, abs(arena - arena_radius))) * ring_stone;
	c = mix(c, stone_dark.rgb * (0.85 + 0.2 * n2), ring);
	// Chemins de terre battue ; dans les bois, vieilles dalles envahies d'herbe.
	float path = 1.0 - smoothstep(path_half_width - 0.2, path_half_width + 0.2, path_distance(p));
	vec2 old = tiles(p, 0.9, 0.5);
	vec3 woods_path = mix(flagstone.rgb * (0.85 + 0.2 * old.y), litter, 1.0 - smoothstep(0.02, 0.06, old.x));
	woods_path = mix(woods_path, forest_floor.rgb, smoothstep(0.6, 0.8, n2) * 0.6);
	vec3 path_c = mix(path_dirt.rgb * (0.92 + 0.12 * n2), woods_path, forest);
	c = mix(c, path_c, path * (1.0 - 0.75 * couchant));
	// La cour de l'entrepôt : terre battue et vieilles dalles, bordure de pierres.
	float yard = length(p);
	vec2 yard_tiles = tiles(p, 1.1, 0.5);
	vec3 yard_c = yard_earth.rgb * (0.9 + 0.15 * n2);
	float flags = smoothstep(0.42, 0.6, noise(p * 0.3 + vec2(9.0, 4.0)));
	vec3 old_flags = mix(flagstone.rgb * (0.88 + 0.2 * yard_tiles.y), yard_c, 1.0 - smoothstep(0.02, 0.06, yard_tiles.x));
	yard_c = mix(yard_c, old_flags, flags);
	c = mix(c, yard_c, 1.0 - smoothstep(plaza_radius - 0.2, plaza_radius, yard));
	c = mix(c, stone_dark.rgb, 1.0 - smoothstep(0.22, 0.36, abs(yard - plaza_radius + 0.3)));
	// L'aire de jeux boueuse (sud-ouest de la cour) et le potager (terre en sillons).
	float play = 1.0 - smoothstep(3.0, 3.8, distance(p, vec2(-12.0, 11.0)) + 0.8 * n2);
	c = mix(c, mud.rgb * (0.9 + 0.2 * n1), play);
	vec2 garden = abs(p - vec2(13.0, -4.0)) - vec2(2.6, 1.6);
	float furrows = 0.85 + 0.15 * sin(p.y * 9.0);
	c = mix(c, soil.rgb * furrows, 1.0 - smoothstep(0.0, 0.2, max(garden.x, garden.y)));
	// La rue du Port : pavés ; la place du marché : dalles.
	vec2 street = abs(p - vec2(0.0, 45.0)) - vec2(34.0, 2.0);
	float street_mask = 1.0 - smoothstep(0.0, 0.25, max(street.x, street.y));
	vec2 cobbles = tiles(p, 0.42, 0.5);
	vec3 cobble_c = mix(cobble.rgb * (0.85 + 0.25 * cobbles.y), stone_dark.rgb * 0.8, 1.0 - smoothstep(0.02, 0.05, cobbles.x));
	c = mix(c, cobble_c, street_mask);
	float market = 1.0 - smoothstep(6.0, 6.6, distance(p, vec2(-23.0, 50.0)) + 0.6 * n2);
	vec2 market_tiles = tiles(p, 1.2, 0.5);
	vec3 market_c = mix(flagstone.rgb * (0.88 + 0.18 * market_tiles.y), stone_dark.rgb, 1.0 - smoothstep(0.02, 0.06, market_tiles.x));
	c = mix(c, market_c, market);
	// Le quai : bord de l'île plaqué de tôle rivetée, du port jusqu'au vide.
	float quay = (1.0 - smoothstep(32.0, 33.0, abs(p.x))) * smoothstep(58.6, 59.2, p.y + 0.4 * sin(p.x * 0.31));
	vec2 sheets = tiles(p + vec2(0.5, 0.0), 2.0, 0.0);
	vec3 quay_c = metal.rgb * (0.88 + 0.16 * sheets.y);
	quay_c = mix(quay_c * 0.7, quay_c, smoothstep(0.03, 0.07, sheets.x));
	float rivets = 1.0 - smoothstep(0.04, 0.07, length(fract(p * 2.5) - 0.5));
	quay_c = mix(quay_c, quay_c * 0.65, rivets * (1.0 - smoothstep(0.12, 0.2, sheets.x)));
	c = mix(c, quay_c, quay);
	// La lèvre de pierre, nette et un peu ébréchée, sur le dernier mètre avant le vide.
	float lip = 1.0 - smoothstep(0.7, 1.1, edge - 0.45 * n2);
	c = mix(c, mix(stone.rgb * (0.92 + 0.12 * n1), metal.rgb * 0.7, quay), lip);
	ALBEDO = c;
	ROUGHNESS = 0.6;
}
