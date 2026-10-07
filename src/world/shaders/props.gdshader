// Décors de l'île fondus par PropBatcher (src/world/prop_batcher.gd, materials/toon.tres) :
// couleur de sommet (l'albedo sRGB du matériau d'origine), surface mate à peine marbrée (pierre,
// bois, enduit), éclairage cel discret et léger liseré de lumière (cel.gdshaderinc). Un albedo
// d'alpha < 0,75 marque un feuillage : touffes de feuilles claires et sombres (bruit 3D dans le
// repère du monde). Compatible Compatibility / WebGL 2.
shader_type spatial;

#include "res://src/world/shaders/cel.gdshaderinc"

// Contraste des touffes de feuillage et du marbrage des autres surfaces.
uniform float leaf_contrast = 0.5;
uniform float grain_contrast = 0.14;

varying vec3 world_pos;

float hash3(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float noise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	vec3 u = f * f * (3.0 - 2.0 * f);
	float a = mix(hash3(i), hash3(i + vec3(1.0, 0.0, 0.0)), u.x);
	float b = mix(hash3(i + vec3(0.0, 1.0, 0.0)), hash3(i + vec3(1.0, 1.0, 0.0)), u.x);
	float c = mix(hash3(i + vec3(0.0, 0.0, 1.0)), hash3(i + vec3(1.0, 0.0, 1.0)), u.x);
	float d = mix(hash3(i + vec3(0.0, 1.0, 1.0)), hash3(i + vec3(1.0, 1.0, 1.0)), u.x);
	return mix(mix(a, b, u.y), mix(c, d, u.y), u.z);
}

void vertex() {
	// Comme vertex_color_is_srgb des StandardMaterial3D : couleur sRGB → linéaire si le rendu
	// travaille en linéaire.
	if (!OUTPUT_IS_SRGB) {
		COLOR.rgb = mix(
				pow((COLOR.rgb + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)),
				COLOR.rgb * (1.0 / 12.92),
				lessThan(COLOR.rgb, vec3(0.04045)));
	}
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 c = COLOR.rgb;
	float n = noise3(world_pos * 1.7);
	if (COLOR.a < 0.75) {
		float clumps = n * 0.6 + noise3(world_pos * 4.3 + vec3(7.1)) * 0.4;
		c *= 1.0 + leaf_contrast * (clumps - 0.55);
	} else {
		c *= 1.0 + grain_contrast * (n - 0.5);
	}
	ALBEDO = c;
	ROUGHNESS = 0.85;
}
