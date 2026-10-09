// Faces verticales du sol en relief d'une carte (MapGround, src/world/map_ground.gd) : falaises,
// talus, murets, contremarches et joues des escaliers et des rampes, rideau de roche sous la côte ;
// un draw call. UV : (m le long de la face, m sous son arête haute) ; UV2.x : style
// (MapGroundData.Face : 0 talus de terre, 1 roche, 2 muret, 3 tuile de l'atlas) ; UV2.y : tuile de
// l'atlas (style 3) ou hauteur de la face (m, ombre à son pied).
// - Roche : la lèvre (lip.png, le premier mètre), la falaise (cliff.png), puis le dessous de l'île
//   (underside.png) qui se fond en profondeur dans la brume, comme la roche de l'île
//   (rock.gdshader).
// - Talus : bank_earth.png sur le premier mètre (herbe qui déborde, terre et racines), puis la
//   terre de potager de l'atlas.
// - Muret : wall_stone_b.png (2 m), chaperon plus clair.
// - Tuile de l'atlas : la matière de la marche, un peu plus sombre.
// Images « nettes mais lissées » (pixel_art.gdshaderinc). Compatible Compatibility / WebGL 2.
shader_type spatial;
render_mode specular_disabled;

#include "res://src/world/shaders/hd2d_light.gdshaderinc"
#include "res://src/world/shaders/pixel_art.gdshaderinc"
#include "res://src/world/shaders/map_ground_atlas.gdshaderinc"

const int EARTH = 0;
const int ROCK = 1;
const int WALL = 2;

uniform sampler2D lip_texture : source_color, filter_linear, repeat_enable;
uniform sampler2D cliff_texture : source_color, filter_linear, repeat_enable;
uniform sampler2D underside_texture : source_color, filter_linear, repeat_enable;
uniform sampler2D bank_texture : source_color, filter_linear, repeat_enable;
uniform sampler2D wall_texture : source_color, filter_linear, repeat_enable;
// Hauteur de la lèvre et du talus (m), côté de l'image du muret (m).
uniform float lip_meters = 1.0;
uniform float bank_meters = 1.0;
uniform float wall_meters = 2.0;
// Tuile de l'atlas sous le talus (terre de potager), assombrissement des contremarches.
uniform int soil_layer = 22;
uniform float riser_shade = 0.7;
// Profondeur (m sous l'arête) où la falaise devient le dessous de l'île ; brume du dessous.
uniform float underside_depth = 16.0;
uniform vec4 depth_tint : source_color = vec4(0.51, 0.46, 0.61, 1.0);
uniform float depth_fade = 48.0;
// Ombre au pied d'une face (lumière restante, hauteur en m).
uniform float foot_shadow = 0.78;
uniform float foot_height = 0.35;

float bayer(vec2 cell) {
	vec2 c = mod(cell, 4.0);
	int i = int(c.x) + int(c.y) * 4;
	int m[16] = int[16](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return (float(m[i]) + 0.5) / 16.0;
}

void fragment() {
	vec2 meters = UV;
	// Dérivées hors des branches.
	vec2 meters_dx = dFdx(meters);
	vec2 meters_dy = dFdy(meters);
	vec2 tile_dx = meters_dx / tile_meters;
	vec2 tile_dy = meters_dy / tile_meters;
	int style = int(UV2.x + 0.5);
	float t = bayer(floor(meters * 48.0));
	vec3 c;
	if (style == ROCK) {
		if (meters.y < lip_meters) {
			vec2 lip_scale = vec2(1.0 / tile_meters, 1.0 / lip_meters);
			c = pixel_art_grad(lip_texture, meters * lip_scale, meters_dx * lip_scale, meters_dy * lip_scale).rgb;
		} else if (smoothstep(underside_depth - 3.0, underside_depth + 3.0, meters.y) > t) {
			c = pixel_art_grad(underside_texture, meters / tile_meters, tile_dx, tile_dy).rgb;
		} else {
			c = pixel_art_grad(cliff_texture, meters / tile_meters, tile_dx, tile_dy).rgb;
		}
		float fog = floor(smoothstep(4.0, depth_fade, meters.y) * 4.0 + t) / 4.0;
		c = mix(c, depth_tint.rgb, fog * 0.8);
	} else if (style == EARTH) {
		vec2 bank_scale = vec2(1.0 / tile_meters, 1.0 / bank_meters);
		vec3 bank = pixel_art_grad(bank_texture, meters * bank_scale, meters_dx * bank_scale, meters_dy * bank_scale).rgb;
		vec2 texel = fract(meters / tile_meters) * tile_pixels;
		float rows = ground_rows();
		vec3 soil = ground_color(ground_resolve(soil_layer, rows), texel, meters_dx / tile_meters * tile_pixels, meters_dy / tile_meters * tile_pixels, rows);
		c = meters.y < bank_meters ? bank : soil * 0.9;
	} else if (style == WALL) {
		vec2 wall_scale = vec2(1.0 / wall_meters);
		c = pixel_art_grad(wall_texture, meters * wall_scale, meters_dx * wall_scale, meters_dy * wall_scale).rgb;
		// Chaperon : le haut du mur, plus clair, liseré sombre dessous.
		if (meters.y < 0.06) {
			c = c * 1.18;
		} else if (meters.y < 0.09) {
			c = c * 0.7;
		}
	} else {
		vec2 texel = fract(meters / tile_meters) * tile_pixels;
		float rows = ground_rows();
		int layer = ground_resolve(int(UV2.y + 0.5), rows);
		c = ground_color(layer, texel, meters_dx / tile_meters * tile_pixels, meters_dy / tile_meters * tile_pixels, rows) * riser_shade;
	}
	if (style != 3 && UV2.y > 0.0) {
		float above_foot = UV2.y - meters.y;
		c *= mix(foot_shadow, 1.0, smoothstep(0.0, foot_height, above_foot + (t - 0.5) * 0.06));
	}
	ALBEDO = c;
	ROUGHNESS = 1.0;
}
