// Sol en relief d'une carte extérieure (MapGround, src/world/map_ground.gd) : un draw call pour
// tout le sol (terrasses, côte, rampes, marches). La matière de chaque point se lit dans l'image
// des matières de la carte (material_map : un indice par pixel, materials_scale pixels par m) et
// sa tuile dans la table des matières (material_table) ; les tuiles viennent de l'atlas du sol de
// l'île (map_ground_atlas.gdshaderinc), à 96 px par mètre.
// - Bords des matières douces : la lecture se décale d'un bruit lisse (warp m) et d'un tramage par
//   pixel d'art (jitter m) : un bord irrégulier en pixels d'art, comme les masques tramés du sol de
//   l'île. Une matière « sharp » (pavés, dalles, planches) garde le bord net de sa case.
// - Alternance des tuiles _b par grandes plaques ; bordure posée en deçà du bord d'une matière qui
//   en a une (sentier bordé de pierres) ; eau qui ondule.
// - Lèvre de pierre au bord du vide (UV.x : distance approchée au vide, posée par le builder).
// - Ombres des falaises : ombre portée vers l'opposé du soleil (marche dans l'image des paliers,
//   height_map) et ombre de contact au pied d'une face.
// - De loin (un pixel d'art plus petit qu'un pixel d'écran), moyenne de quatre tirages : pas de
//   scintillement. Compatible Compatibility / WebGL 2.
shader_type spatial;
render_mode specular_disabled;

#include "res://src/world/shaders/hd2d_light.gdshaderinc"
#include "res://src/world/shaders/map_ground_atlas.gdshaderinc"

// Drapeaux de la table des matières (rangée 0, canal vert).
const int FLAG_VARIANT = 1;
const int FLAG_SHARP = 2;
const int FLAG_RIPPLE = 4;
const int FLAG_BORDER = 8;
const int ROCK = 7;

// Indice de matière par pixel (R8) ; table : rangée 0 (tuile, drapeaux, tuile de bordure,
// largeur de bordure en cm), rangée 1 (teinte / 2), rangée 2 (teinte de bordure / 2) ; paliers par
// case (R8 : 0 vide, 255 escalier ou rampe, sinon palier + 64).
uniform sampler2D material_map : filter_nearest, repeat_disable;
uniform sampler2D material_table : filter_nearest, repeat_disable;
uniform sampler2D height_map : filter_nearest, repeat_disable;
uniform float materials_scale = 1.0;
uniform float level_height = 0.5;
// Pixels d'art par mètre du tramage des bords.
uniform float art_pixels = 48.0;
// Bord irrégulier des matières douces : amplitude du bruit lisse et du tramage (m).
uniform float warp = 0.5;
uniform float jitter = 0.16;
// Direction du soleil (vers lui), lumière restante dans l'ombre des falaises et au pied des faces.
uniform vec3 toward_sun = vec3(-0.900073, 0.34202, 0.269984);
uniform float cliff_shadow = 0.72;
uniform float contact_shadow = 0.78;

varying vec3 map_pos;
varying float coast;

void vertex() {
	map_pos = VERTEX;
	coast = UV.x;
}

int material_at(vec2 p) {
	ivec2 size = textureSize(material_map, 0);
	ivec2 c = clamp(ivec2(floor(p * materials_scale)), ivec2(0), size - 1);
	return int(texelFetch(material_map, c, 0).r * 255.0 + 0.5);
}

vec4 material_row(int index, int row) {
	return texelFetch(material_table, ivec2(index, row), 0);
}

bool has_flag(vec4 head, int bit) {
	return (int(head.g * 255.0 + 0.5) & bit) != 0;
}

// Palier de la case sous p (m ; -1000 : vide, 1000 : escalier ou rampe).
float level_at(vec2 p) {
	ivec2 size = textureSize(height_map, 0);
	float v = texelFetch(height_map, clamp(ivec2(floor(p)), ivec2(0), size - 1), 0).r * 255.0;
	if (v < 0.5) {
		return -1000.0;
	}
	if (v > 254.5) {
		return 1000.0;
	}
	return (v - 64.0) * level_height;
}

// Décalage de la lecture des matières au point p : bruit lisse plus tramage du pixel d'art cell.
vec2 edge_offset(vec2 p, vec2 cell, float salt) {
	vec2 smooth_part = vec2(ground_noise(p * 0.9 + vec2(3.7, 1.9)), ground_noise(p * 0.9 + vec2(8.3, 5.1)));
	vec2 grain = vec2(ground_cell_threshold(cell + vec2(salt, 0.0)), ground_cell_threshold(cell + vec2(17.0, salt)));
	return (smooth_part - 0.5) * 2.0 * warp + (grain - 0.5) * 2.0 * jitter;
}

// Tuile et teinte du point p pour un tirage (décalage offset, seuil t de l'alternance).
int pick(vec2 p, vec2 offset, float t, out vec3 tint, out bool ripple) {
	int raw = material_at(p);
	int index = material_at(p + offset);
	vec4 head = material_row(index, 0);
	vec2 at = p + offset;
	if (index != raw) {
		vec4 raw_head = material_row(raw, 0);
		if (has_flag(raw_head, FLAG_SHARP) || has_flag(head, FLAG_SHARP)) {
			index = raw;
			head = raw_head;
			at = p;
		}
	}
	if (has_flag(head, FLAG_SHARP)) {
		at = p;
	}
	int layer = int(head.r * 255.0 + 0.5);
	tint = material_row(index, 1).rgb * 2.0;
	ripple = has_flag(head, FLAG_RIPPLE);
	if (has_flag(head, FLAG_BORDER)) {
		float width = head.a * 2.55 * (0.8 + 0.4 * t);
		if (material_at(at + vec2(width, 0.0)) != index || material_at(at - vec2(width, 0.0)) != index
				|| material_at(at + vec2(0.0, width)) != index || material_at(at - vec2(0.0, width)) != index) {
			layer = int(head.b * 255.0 + 0.5);
			tint = material_row(index, 2).rgb * 2.0;
			ripple = false;
			return layer;
		}
	}
	if (has_flag(head, FLAG_VARIANT)) {
		float patches = 0.7 * ground_noise(p * 0.12 + vec2(5.1, 3.7)) + 0.3 * ground_noise(p * 0.37 + vec2(1.9, 6.2));
		if (smoothstep(0.47, 0.53, patches) > t) {
			layer = ground_variant(layer);
		}
	}
	return layer;
}

// Lumière laissée par les falaises au point p (hauteur y) : ombre portée et ombre de contact.
float cliff_light(vec2 p, float y, vec2 cell) {
	float here = level_at(p);
	if (here < -999.0 || here > 999.0) {
		return 1.0;
	}
	float light = 1.0;
	// Ombre de contact : une case voisine plus haute, à moins d'un demi-mètre.
	vec2 f = fract(p);
	vec4 near = vec4(f.x, 1.0 - f.x, f.y, 1.0 - f.y);
	vec2 sides[4] = vec2[](vec2(-1.0, 0.0), vec2(1.0, 0.0), vec2(0.0, -1.0), vec2(0.0, 1.0));
	for (int k = 0; k < 4; k++) {
		float other = level_at(p + sides[k]);
		if (other > here + 0.01 && other < 999.0) {
			light = min(light, mix(contact_shadow, 1.0, smoothstep(0.0, 0.55, near[k])));
		}
	}
	// Ombre portée : marche vers le soleil dans l'image des paliers.
	vec2 sun = normalize(toward_sun.xz + vec2(0.0001));
	float rise = toward_sun.y / max(length(toward_sun.xz), 0.0001);
	float start = ground_cell_threshold(cell) * 0.35;
	for (int k = 1; k <= 8; k++) {
		float d = start + float(k) * 0.6;
		float other = level_at(p + sun * d);
		if (other < 999.0 && other > y + d * rise + 0.02) {
			return min(light, cliff_shadow);
		}
	}
	return light;
}

void fragment() {
	vec2 ground_dx = dFdx(map_pos.xz);
	vec2 ground_dy = dFdy(map_pos.xz);
	float art_per_pixel = max(length(ground_dx), length(ground_dy)) * art_pixels;
	vec2 cell = floor(map_pos.xz * art_pixels);
	vec2 texel = fract(map_pos.xz / tile_meters) * tile_pixels;
	vec2 texel_dx = ground_dx / tile_meters * tile_pixels;
	vec2 texel_dy = ground_dy / tile_meters * tile_pixels;
	float rows = ground_rows();
	float far = smoothstep(0.75, 2.0, art_per_pixel);
	bool blended = ground_screen_noise(FRAGCOORD.xy + vec2(29.0, 13.0)) < far;
	vec2 p = blended ? map_pos.xz : (cell + 0.5) / art_pixels;
	// Lèvre de pierre au bord du vide (0,2 à 1,3 m, par plaques).
	float lip = 0.2 + 1.0 * smoothstep(0.5, 0.8, ground_noise(p * 0.27 + vec2(5.7, 1.3)));
	lip += 0.3 * (ground_noise(p * 0.47 + vec2(7.3, 1.1)) - 0.5);
	bool on_lip = coast - 0.5 * (ground_noise(p * 1.7 + vec2(2.4, 9.3)) - 0.5) < lip;
	vec3 tint;
	bool ripple;
	vec3 c = vec3(0.0);
	if (on_lip) {
		c = ground_color(ground_resolve(ROCK, rows), texel, texel_dx, texel_dy, rows) * 0.92;
	} else if (blended) {
		float shift = ground_screen_noise(FRAGCOORD.xy);
		int last = -1;
		vec3 last_color = vec3(0.0);
		for (int i = 0; i < 4; i++) {
			float t = (float(i) + shift) * 0.25;
			vec2 offset = edge_offset(p, cell, float(i) * 31.0);
			int layer = ground_resolve(pick(p, offset, t, tint, ripple), rows);
			if (layer != last) {
				last_color = ground_color(layer, texel, texel_dx, texel_dy, rows);
				last = layer;
			}
			c += last_color * tint * 0.25;
		}
	} else {
		float t = ground_cell_threshold(cell);
		int layer = ground_resolve(pick(p, edge_offset(p, cell, 0.0), t, tint, ripple), rows);
		vec2 at = texel;
		if (ripple) {
			at += vec2(sin(TIME * 1.7 + map_pos.z * 3.1), cos(TIME * 1.3 + map_pos.x * 2.7)) * 1.5;
		}
		c = ground_color(layer, at, texel_dx, texel_dy, rows) * tint;
	}
	ALBEDO = c * cliff_light(map_pos.xz, map_pos.y, cell);
	ROUGHNESS = 1.0;
}
