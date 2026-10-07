// Touffes d'herbe de l'île (IslandGrass, src/world/grass.gd, materials/grass.tres) : brins plus
// sombres au pied, plus clairs à la pointe, teinte de la touffe (couleur d'instance, sRGB) ;
// normales vers le ciel : éclairés comme le sol (éclairage cel sans liseré) ; léger balancement
// au vent d'ouest ; entre fade.x et fade.y m de la caméra, les touffes s'aplatissent jusqu'au
// sol (la case disparaît ensuite sans à-coup). Compatible Compatibility / WebGL 2.
shader_type spatial;
render_mode cull_disabled, world_vertex_coords;

#define CEL_NO_RIM
#include "res://src/world/shaders/cel.gdshaderinc"

// Direction du vent (x, z), amplitude du balancement à la pointe (m), fondu (m).
uniform vec2 wind = vec2(1.0, 0.25);
uniform float sway = 0.07;
uniform vec2 fade = vec2(22.0, 32.0);
// Teinte du pied et de la pointe (multiplient la couleur de la touffe).
uniform vec3 root_shade = vec3(0.78, 0.8, 0.7);
uniform vec3 tip_shade = vec3(1.15, 1.12, 0.98);

varying float tip;

void vertex() {
	if (!OUTPUT_IS_SRGB) {
		COLOR.rgb = mix(
				pow((COLOR.rgb + vec3(0.055)) * (1.0 / 1.055), vec3(2.4)),
				COLOR.rgb * (1.0 / 12.92),
				lessThan(COLOR.rgb, vec3(0.04045)));
	}
	tip = UV.y;
	vec3 root = MODEL_MATRIX[3].xyz;
	float grow = 1.0 - smoothstep(fade.x, fade.y, distance(root, CAMERA_POSITION_WORLD));
	float phase = TIME * 1.6 + dot(root.xz, vec2(0.23, 0.17));
	float bend = (0.6 * sin(phase) + 0.4 * sin(phase * 2.3 + 1.7)) * sway * UV.y * UV.y;
	VERTEX.y = root.y + (VERTEX.y - root.y) * grow;
	VERTEX.xz += normalize(wind) * bend * grow;
}

void fragment() {
	ALBEDO = COLOR.rgb * mix(root_shade, tip_shade, tip);
	ROUGHNESS = 1.0;
}
