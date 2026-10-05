// Onde de la charge magique (src/combat/charge_wave.tscn) : croissant lumineux, cœur blanc et
// bords bleus comme les arcs de jeu.js. Compatible WebGL 2 (renderer Compatibility) : non
// éclairé, transparent, sans texture. Le maillage (QuadMesh face à +Z, subdivisé en largeur)
// est courbé : les pointes traînent derrière (+Z), le centre mène l'onde vers -Z.
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 core_color : source_color = vec4(0.91, 0.97, 1.0, 1.0);
uniform vec4 edge_color : source_color = vec4(0.35, 0.66, 0.9, 1.0);
// Recul des pointes (m) et demi-largeur du maillage (m).
uniform float bend = 0.55;
uniform float half_width = 1.0;
// 1 en vol, 0 à la fin de course (réglé par charge_wave.gd).
uniform float fade : hint_range(0.0, 1.0) = 1.0;

void vertex() {
	float u = clamp(VERTEX.x / half_width, -1.0, 1.0);
	VERTEX.z += bend * u * u;
}

void fragment() {
	vec2 p = vec2(UV.x * 2.0 - 1.0, 1.0 - UV.y * 2.0);
	float span = clamp(1.0 - p.x * p.x, 0.0, 1.0);
	// Arche « ⌒ » qui s'affine vers les pointes.
	float center = 0.3 * span - 0.15;
	float half_thickness = 0.55 * pow(span, 0.6) + 0.03;
	float d = abs(p.y - center) / half_thickness;
	float band = 1.0 - smoothstep(0.35, 1.0, d);
	float core = 1.0 - smoothstep(0.0, 0.45, d);
	float tips = 1.0 - smoothstep(0.8, 1.0, abs(p.x));
	float shimmer = 0.85 + 0.15 * sin(TIME * 30.0 + p.x * 7.0);
	ALBEDO = mix(edge_color.rgb, core_color.rgb, core);
	ALPHA = clamp(band * tips * shimmer * fade, 0.0, 1.0);
}
