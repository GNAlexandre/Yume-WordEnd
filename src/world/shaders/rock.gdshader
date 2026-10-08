// Roche HD-2D de l'île flottante (IslandRock, src/world/island_rock.gd) : textures de pixel art
// à 96 px par mètre (assets/hd2d/cliff/) le long du bord. UV.x : mètres le long du tour de l'île ;
// UV.y : mètres sous le sol. La lèvre (lip.png, le premier mètre), la falaise (cliff.png), puis le
// dessous de l'île (underside.png) qui se fond, en profondeur, dans la couleur de la brume. Les
// passages se font par pixel d'art tramé, sans mélange flou. Compatible Compatibility / WebGL 2.
// (H5) Images « nettes mais lissées » (pixel_art.gdshaderinc) : la falaise vue de biais ne
// scintille plus.
shader_type spatial;
render_mode cull_disabled, specular_disabled;

#include "res://src/world/shaders/hd2d_light.gdshaderinc"
#include "res://src/world/shaders/pixel_art.gdshaderinc"

uniform sampler2D lip_texture : source_color, filter_linear, repeat_enable;
uniform sampler2D cliff_texture : source_color, filter_linear, repeat_enable;
uniform sampler2D underside_texture : source_color, filter_linear, repeat_enable;
// Taille d'une texture (m) : 384 px à 96 px par mètre ; hauteur de la lèvre (m).
uniform float tile_meters = 4.0;
uniform float lip_meters = 1.0;
// Profondeur (m) où la falaise devient le dessous de l'île.
uniform float underside_depth = 16.0;
// Brume du dessous : couleur et profondeur où elle couvre tout.
uniform vec4 depth_tint : source_color = vec4(0.51, 0.46, 0.61, 1.0);
uniform float depth_fade = 48.0;

float bayer(vec2 cell) {
	vec2 c = mod(cell, 4.0);
	int i = int(c.x) + int(c.y) * 4;
	int m[16] = int[16](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return (float(m[i]) + 0.5) / 16.0;
}

void fragment() {
	vec2 meters = UV;
	// Dérivées hors des branches (pixel_art_grad).
	vec2 meters_dx = dFdx(meters);
	vec2 meters_dy = dFdy(meters);
	vec2 tile_dx = meters_dx / tile_meters;
	vec2 tile_dy = meters_dy / tile_meters;
	vec2 lip_scale = vec2(1.0 / tile_meters, 1.0 / lip_meters);
	vec2 cell = floor(meters * 48.0);
	float t = bayer(cell);
	vec3 c;
	if (meters.y < lip_meters) {
		vec2 lip_uv = meters * lip_scale;
		c = pixel_art_grad(lip_texture, lip_uv, meters_dx * lip_scale, meters_dy * lip_scale).rgb;
	} else if (smoothstep(underside_depth - 3.0, underside_depth + 3.0, meters.y) > t) {
		c = pixel_art_grad(underside_texture, meters / tile_meters, tile_dx, tile_dy).rgb;
	} else {
		c = pixel_art_grad(cliff_texture, meters / tile_meters, tile_dx, tile_dy).rgb;
	}
	// Brume en paliers tramés (quatre niveaux) : perspective aérienne sans dégradé flou.
	float fog = floor(smoothstep(4.0, depth_fade, meters.y) * 4.0 + t) / 4.0;
	c = mix(c, depth_tint.rgb, fog * 0.8);
	ALBEDO = c;
	ROUGHNESS = 1.0;
}
