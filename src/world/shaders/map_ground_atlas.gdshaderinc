// Lecture de l'atlas du sol (assets/hd2d/ground/atlas/ground_atlas.png, 27 tuiles de 4 m,
// IslandTerrain.GROUND_LAYERS) pour le sol en relief des cartes (map_ground.gdshader) et ses faces
// (map_ground_cliff.gdshader) : mêmes règles que le sol de l'île (terrain.gdshader) — de près,
// pixels nets dont seule la frontière est lissée ; de loin, mipmaps (atlas recalculé en jeu par
// IslandTerrain.mipmapped_atlas) lues au niveau tiré des dérivées continues, deux échantillons le
// long de l'axe étiré ; une tuile absente retombe sur sa tuile d'origine (FALLBACK). Compatible
// Compatibility / WebGL 2.

const int GROUND_LAYER_COUNT = 27;
const int GROUND_FALLBACK[GROUND_LAYER_COUNT] = int[](0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 0, 2, 3, 2, 2, 1, 4, 5, 0, 3, 10, 6, 7, 3, 9);
const float GROUND_ATLAS_COLUMNS = 4.0;

uniform sampler2D ground_atlas : source_color, filter_linear_mipmap, repeat_disable;
// Taille d'une tuile (m) : 384 px à 96 px par mètre ; mipmap la plus floue lue.
uniform float tile_meters = 4.0;
uniform float tile_pixels = 384.0;
uniform float max_lod = 6.0;

// Rangées de l'atlas, lues dans sa taille (3 pour 12 tuiles, 7 pour 27).
float ground_rows() {
	return max(floor(float(textureSize(ground_atlas, 0).y) / tile_pixels + 0.5), 1.0);
}

// Tuile lue à la place de layer : elle-même si l'atlas l'a, sinon sa tuile d'origine.
int ground_resolve(int layer, float rows) {
	int count = min(int(GROUND_ATLAS_COLUMNS * rows), GROUND_LAYER_COUNT);
	int clamped = clamp(layer, 0, GROUND_LAYER_COUNT - 1);
	return clamped < count ? clamped : GROUND_FALLBACK[clamped];
}

// Variante _b d'une tuile (elle-même si elle n'en a pas) : grass, forest_floor, path_dirt,
// grass_dry, flagstone, cobble, sand, rock.
int ground_variant(int layer) {
	if (layer == 0) { return 12; }
	if (layer == 2) { return 13; }
	if (layer == 3) { return 14; }
	if (layer == 1) { return 17; }
	if (layer == 4) { return 18; }
	if (layer == 5) { return 19; }
	if (layer == 6) { return 23; }
	if (layer == 7) { return 24; }
	return layer;
}

// Un échantillon de la tuile de l'atlas qui commence à cell_origin, au pixel d'image texel (replié
// sur la tuile), dans la mipmap lod, avec une marge pour ne jamais déborder sur la voisine.
vec3 ground_tap(vec2 texel, vec2 cell_origin, float lod, float rows) {
	float margin = 0.75 * exp2(ceil(lod));
	vec2 wrapped = clamp(mod(texel, tile_pixels), vec2(margin), vec2(tile_pixels - margin));
	vec2 uv = (cell_origin + wrapped / tile_pixels) / vec2(GROUND_ATLAS_COLUMNS, rows);
	return textureLod(ground_atlas, uv, lod).rgb;
}

// Couleur de la tuile layer (déjà résolue) au pixel d'image texel ; texel_dx, texel_dy : empreinte
// du pixel d'écran en pixels d'image.
vec3 ground_color(int layer, vec2 texel, vec2 texel_dx, vec2 texel_dy, float rows) {
	vec2 cell_origin = vec2(mod(float(layer), GROUND_ATLAS_COLUMNS), floor(float(layer) / GROUND_ATLAS_COLUMNS));
	float along_x = length(texel_dx);
	float along_y = length(texel_dy);
	float major = max(along_x, along_y);
	float minor = min(along_x, along_y);
	if (major <= 1.0) {
		vec2 width = clamp(abs(texel_dx) + abs(texel_dy), vec2(0.001), vec2(1.0));
		vec2 sharp = floor(texel) + 0.5 + clamp((fract(texel) - 0.5) / width, -0.5, 0.5);
		return ground_tap(sharp, cell_origin, 0.0, rows);
	}
	float lod = min(log2(max(max(minor, major * 0.5), 1.0)), max_lod);
	vec2 half_step = (along_x > along_y ? texel_dx : texel_dy) * 0.25;
	return 0.5
			* (ground_tap(texel - half_step, cell_origin, lod, rows)
					+ ground_tap(texel + half_step, cell_origin, lod, rows));
}

float ground_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float ground_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = ground_hash(i);
	float b = ground_hash(i + vec2(1.0, 0.0));
	float c = ground_hash(i + vec2(0.0, 1.0));
	float d = ground_hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Seuil de tramage d'un pixel d'art (0..1) : bruit blanc entier, stable.
float ground_cell_threshold(vec2 cell) {
	uvec2 q = uvec2(ivec2(cell) + ivec2(65536));
	uint h = (q.x * 1597334677u) ^ (q.y * 3812015801u);
	h = (h ^ (h >> 16u)) * 2246822519u;
	h = h ^ (h >> 13u);
	return float(h >> 8u) / 16777216.0;
}

// Bruit du pixel d'écran (interleaved gradient noise, 0..1).
float ground_screen_noise(vec2 pixel) {
	return fract(52.9829189 * fract(dot(pixel, vec2(0.06711056, 0.00583715))));
}
