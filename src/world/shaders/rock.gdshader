// Roche de l'île flottante (IslandRock, src/world/island_rock.gd) : lèvre de pierre gris-bleu,
// couche de terre et de racines, puis falaise et dessous de l'île en strates claires et sombres
// qui se fondent, en profondeur, dans le bleu de la brume du dessous (perspective aérienne).
// Normales lissées (mesh), éclairage cel discret comme le sol (cel.gdshaderinc).
// Compatible Compatibility / WebGL 2. COLOR.r = 1 : racine.
shader_type spatial;
render_mode cull_disabled;

#define CEL_NO_RIM
#include "res://src/world/shaders/cel.gdshaderinc"

uniform vec4 lip_stone : source_color = vec4(0.6, 0.61, 0.6, 1.0);
uniform vec4 earth : source_color = vec4(0.36, 0.28, 0.2, 1.0);
uniform vec4 stone_light : source_color = vec4(0.58, 0.59, 0.6, 1.0);
uniform vec4 stone_dark : source_color = vec4(0.4, 0.42, 0.45, 1.0);
uniform vec4 stone_warm : source_color = vec4(0.55, 0.5, 0.44, 1.0);
uniform vec4 depth_tint : source_color = vec4(0.52, 0.6, 0.72, 1.0);
uniform vec4 root_color : source_color = vec4(0.27, 0.2, 0.15, 1.0);

varying vec3 world_pos;
varying float root;

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

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	root = COLOR.r;
}

void fragment() {
	float y = world_pos.y;
	vec2 xz = world_pos.xz;
	// Strates : bandes claires et sombres, ondulées autour de l'île, veinées de pierre plus chaude
	// (bruits lus en x et en z : pas de couture autour de l'île).
	float wave = 1.3 * sin(xz.x * 0.07) + 1.1 * sin(xz.y * 0.05 + 1.3);
	float band = 0.5 + 0.5 * sin((y + wave) * 1.05);
	float grain = 0.5 * (noise(vec2(xz.x * 0.6, y * 1.6)) + noise(vec2(xz.y * 0.6 + 17.0, y * 1.6)));
	float veins = 0.5 * (noise(vec2(xz.x * 0.12, y * 0.35)) + noise(vec2(xz.y * 0.12 + 5.0, y * 0.35)));
	vec3 c = mix(stone_light.rgb, stone_dark.rgb, smoothstep(0.3, 0.7, band) * 0.75);
	c = mix(c, stone_warm.rgb, smoothstep(0.5, 0.7, veins) * 0.5);
	c *= 0.9 + 0.2 * grain;
	// Sous le sol : la lèvre de pierre (40 cm), puis la terre aux racines (jusqu'à −1,7 m).
	float soil = 1.0 - smoothstep(-2.0, -1.4, y);
	c = mix(earth.rgb, c, soil);
	c = mix(c, lip_stone.rgb * (0.92 + 0.12 * grain), smoothstep(-0.55, -0.35, y));
	// En profondeur, la roche se fond dans le bleu de l'air sous l'île.
	c = mix(c, depth_tint.rgb, (1.0 - smoothstep(-46.0, -12.0, y)) * 0.65);
	ALBEDO = mix(c, root_color.rgb, root);
	ROUGHNESS = 0.9;
}
